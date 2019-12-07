%let path=C:\Users\mikew\OneDrive\Documents\GitHub\scoring;
libname scoring "&path";



options validvarname=v7;

proc import datafile="&path.\format_projet.xlsx"
            dbms=excel
            out=format_num replace;
			getnames=yes;
			sheet=num;
run;

proc import datafile="&path.\format_projet.xlsx"
            dbms=excel
            out=format_char replace;
			getnames=yes;
			sheet=char;
run;


data format_char;
	set work.format_char;
run;

data format_num;
	set work.format_num;
run;