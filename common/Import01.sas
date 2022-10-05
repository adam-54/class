

FILENAME REFFILE "&folder./inwest_gosp.csv";

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.IMPORT1;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.IMPORT1; 
RUN;

ods text = "Interpretacja zmiennej 1";

title1 j=l "1 Analiza struktury";
title2 j=l "1.1 Histogramy rozkładu";

ods text= "To jest bardzo długi tekst, który pojawi się w przeglądarce
To jest bardzo długi tekst, który pojawi się w przeglądarce
To jest bardzo długi tekst, który pojawi się w przeglądarce";

proc means data=import1;
 var inwest;
run;

footnote1 j=l "Przypis nr 1";
ods text = "Interpretacja zmiennej 2";
