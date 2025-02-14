*Adam Korczynski, 14-02-2025, adaptive logistic regression with AUC and Gini;
*Data from: https://archive.ics.uci.edu/dataset/94/spambase;


*[1] Start CAS session and assign user libarary CASUSER to the session;
*cas mySession sessopts=(caslib=casuser);

*[2] Associate library with CASUSER CASLIB using CAS engine;
*libname myCas cas caslib=casuser;

*Load do CAS lib;
data /*mycas.*/junkmail;
 set sashelp.junkmail;
 y=class;
run;

*Test for spam
This example concerns a study on classifying whether an e-mail is junk e-mail (coded as 1) or not (coded as 0).;

proc adaptivereg data=/*mycas.*/junkmail seed=10359 ; 
model y (event='1')= Address Addresses CS CapAvg All Bracket Business CapLong CapTotal 
	Conference Credit Email HP Mail Original Parts Receive Data Direct Exclamation 
	Font HPL Dollar Free Internet Lab Make
	Our People Remove Meeting Money Over Pound Report 
	PM Project Edu George Labs Order Paren RE 
	Semicolon Table Technology Telnet _000 _1999 _85 
	Will _415 You _650 _3D 
 / additive dist=binomial maxbasis=40 fast(k=20); 
partition fraction(test=0.33) ; 
output out=spamout p(ilink);
run;



*Split to train and test;
data out_train01;
 set spamout;
 where _role_='TRAIN';
run;

data out_test01;
 set spamout;
 where _role_='TEST';
run;


*Get cut-offs;
%let step=0.01;

data index00;
 do _c=&step. to 1 by &step.;
  output;
 end;
run;
data index01;
 set index00;
 i+1;
run;

data _templ;
 y=0;_predc=0;
 output;
 y=0;_predc=1;
 output;
 y=1;_predc=0;
 output;
 y=1;_predc=1;
 output;
run;

%macro calculateC001(InDs=/*Input dataset*/, OtDs=/*Output dataset*/,label=/*Data label*/);

proc sql noprint;
 select count(*) into :_ctot from index01;
quit;
%put &_ctot.;

%do i=1 %to &_ctot.;

proc sql noprint;
 select _c into :_c_iter from index01 where i=&i.;
quit;
%put &_c_iter.;

 data ad_pred01;
      set &InDs.;
      c=&_c_iter.;
      if pred>=c then _predc=1; 
      else _predc=0;
run;

proc freq data=ad_pred01 noprint;
 *tables y / out=g01;
 tables c*y*_predc  / out=g01;
run;


proc sql;
 create table g02 as select
   a.y as ytempl
 ,a._predc as _predctempl
 ,b.*
 from _templ a left join g01 b on (a.y=b.y and a._predc=b._predc)
;
quit;

data g03;
 set g02;
 if ((ytempl=0 and _predctempl=0) or (ytempl=1 and _predctempl=1)) and missing(_predc) then do;
   y=ytempl;
  _predc=_predctempl;
   c=&_c_iter.;
   count=0;
 end;
run;

proc sql;
 create table g04 as select
   *
   ,sum(count) as _sum
   ,count / calculated _sum as ratio
 from g03
 group by y;
quit;

data g05;
 set g04;
 if _predc=0 & y=0 then type='_spec_orig';
 else if _predc=1 & y=1 then type='_sens';
 where (_predc=0 & y=0) or (_predc=1 & y=1);
run;


proc transpose data=g05 out=g06 /*(rename=(col1=_spec_orig col2=_sens))*/;
 var ratio;
 by c;
 id type;
run;

data g07;
 set g06;
 i=&i.;
 _spec=1-_spec_orig;
run;

%if &i.=1 %then %do;
 data g08;
  set g07;
 run;
%end;

%else %do;
 data g08;
  set g08 g07;
 run;
%end;

%end;

proc sort data=g08 out=g10;
 by _spec ;
run;

data g11;
 set g10 end=last;
 output;
 if last then do;
  if _spec<1 then do;
    _spec_orig=0;
   _spec=1;
   _sens=1;
   i=101;
   output;
  end;
 end;
run;

proc sort data=g11 out=g12;
 by descending _spec ;
run;

data g13;
 set g12;
 next_spec=lag(_spec);
 next_sens=lag(_sens);
run;

proc sort data=g13 out=g14;
 by _spec next_spec;
run;

data g15;
 set g14;
 h=next_spec-_spec;
 a=_sens;
 b=next_sens;
run;

data g16;
 set g15;
 p=(a+b)*h/2;
run;

data g17;
 set g16 end=last;
 sum+p;
 if last then do;
  auc=sum;
  gini=2*auc-1;
    *call symputx("auc_&label.",auc);
    *call symputx("gini_&label.",gini);
 end;
run;

data &OtDs.;
 set g17;
run;


%mend calculateC001;
%calculateC001(InDs=out_train01,OtDs=train_out,label=train);
%calculateC001(InDs=out_test01,OtDs=test_out,label=test);


*Join train and test data;
proc sql;
 create table w01 as select
 a.*
,b._spec as _spec_test
,b._sens as _sens_test
,b.sum as _sum_test
,b.auc as auc_test
,b.gini as gini_test
from train_out a left join test_out b on (a.i=b.i);
quit;

data _null_;
 set w01;
 if ^missing(auc) then do;
    call symputx("AUC_train",round(auc,0.001));
    call symputx("AUC_test",round(auc_test,0.001));

    call symputx("gini_train",round(gini,0.001));
    call symputx("gini_test",round(gini_test,0.001));
 end;
run;

*Roc curve;
ods graphics on / width=1200 height=1000;
proc sgplot data=w01;
 series x=_spec y=_sens / name="train" legendlabel="Train" lineattrs=(color=green);
  series x=_spec_test y=_sens_test / name="test" legendlabel="Test" lineattrs=(color=red);
 xaxis label="1-specificity" min=0 max=1;
 yaxis label="sensitivity" min=0 max=1;;
 keylegend "train" "test";
 inset "Gini_train = &gini_train." "AUC_train = &AUC_train." / textattrs=(color=green size=14)  position=bottom ;
 inset "Gini_test = &gini_test." "AUC_test = &AUC_test." / textattrs=(color=red size=14) position=bottomright;
 where i<=100;
run;


