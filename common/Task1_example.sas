ods text="*******";
ods text="title: Task 1";
ods text="author: Group 1, First Last Name";
ods text="date: 10/5/2022";
ods text="output: sas output";
ods text="*******";

ods startpage=no;*remove page breaks;

ods text="(*ESC*){style[font_style=italic just=c fontweight=bold fontsize=12pt]
1 Topic}";
ods text="Research question: Is there any relationship between tax inspection and sales of a company?";
ods text="Research hypothsis: Tax inspection is related with the sales of a company.";

ods text="(*ESC*){style[font_style=italic just=c fontweight=bold fontsize=12pt]
2 Target variable description}";

*Filter data;
data mycas.beeps01;
 set mycas.beeps;*keep unchanged;
 where country='Poland';
run;

title1 "Target variable description";
title2 "Histogram of company sales";
proc sgplot data=mycas.beeps01;
 histogram d2;
run;
title1;
title2;

ods select BasicMeasures;/*only select the named output*/
proc univariate data=mycas.beeps01;
 var d2;
run;

ods text="Highly skewed distribution. Presence of missing data indicated by minimum of -9. Target variable 
requires transformation ...";

ods text="(*ESC*){style[font_style=italic just=c fontweight=bold fontsize=12pt]
3  Catgorical predictor description}";
title1 "Tax inspection";
title2 "Frequency table";
proc freq data=mycas.beeps01;
 table j3 / missing;
run;
title1;
title2; 

ods text="Presence of missing data ...";

ods text="(*ESC*){style[font_style=italic just=c fontweight=bold fontsize=12pt]
4  Assessing relationship between target and predictor}";
title1 "Company sales within tax inspection groups";
title2 "Summary statistics";
proc means data=mycas.beeps01;
 var d2;
 class j3 /  missing;
run;


ods text="Comment about relationship between the variables.";