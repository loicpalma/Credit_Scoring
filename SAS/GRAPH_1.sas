/*************************************************************************************/
/*****																		     *****/
/*****							CREATION DES GRAPHIQUES                          *****/ 
/*****			EVOLUTION DES CONTRATS EN DEFAUT MOIS ET TRIMESTRE               *****/                       
/*****																			 *****/
/*************************************************************************************/

proc sort data=df;
	by date_gest;
run;


data work (drop=mt_dmd nb_def_mois nb_cont_mois we18);
	set df (keep=date_gest MT_DMD WE18);
	by date_gest;
	retain nb_cont_mois 0 nb_def_mois 0 mt_mois 0;
	if first.date_gest=1 then do;
    	nb_cont_mois=0 ;
		nb_def_mois=0 ;
		mt_mois=0;
	end;
	nb_cont_mois+1;
	mt_mois=mt_mois+mt_dmd;
	if we18=1 then nb_def_mois+1;
	if last.date_gest=1 then do;
		percent=(nb_def_mois/nb_cont_mois);
		mt_mois=mt_mois/100;
		output;
	end;
	format percent PERCENT6.2;

	label percent="Default rate during the month"
	      mt_mois="Amount of loans (in €)";
run;

ods graphics / height=400px width=1200px;


proc sgplot data=work;
	title "Default rate evolution between January 2012 and August 2017";
	vbar date_gest / response= mt_mois fillattrs=(color="VLIGB " )  ;
	vline date_gest / response=percent y2axis lineattrs=(color=CXFF0000 thickness=1.5);
	y2axis min=0 label='Defaults contracts rate per month' values=(0 to 0.1 by 0.01 );
	xaxis fitpolicy=rotate display=(nolabel);
	format date_gest monyy.;
run;



/***** LOIC A VERIFIER PAR MICKAEL *****/

data work.table;
	set df (keep=date_gest MT_DMD WE18);
	quarter = put(date_gest,YYQ.);
run;

proc sort data = work.table presorted;
by quarter;
run;

data work_quarter;
	set work.table (keep=date_gest MT_DMD WE18 quarter);
	by quarter;
	retain somme 0 nb_cont 0 nb_def 0;
	if first.quarter=1 then do;
	somme = 0 ;
    nb_cont = 0;
	nb_def = 0;
	end;
	somme = somme + mt_dmd;
	nb_cont +1;
	if WE18=1 then do;
	nb_def + 1;
	end;
	if last.quarter=1 then do;
	moyenne_quarter = somme / nb_cont;
	default_mean = nb_def / nb_cont;
	output;
	end;
	format default_mean PERCENT6.2;
	
	label default_mean="Default rate during the quarter"
	      moyenne_quarter="Amount of loans (in €)";
run;


proc sgplot data=work_quarter;
	label moyenne_quarter = "Amount of loans (in €)"
 default_mean = "Default rate during the quarter";
	title "Default rate evolution between January 2012 and August 2017";
	vbar quarter / response= moyenne_quarter fillattrs=(color="VLIGB " ) name = "Amount of loans (in €)" ;
	vline quarter / response=default_mean y2axis lineattrs=(color=CXFF0000 thickness=1.5) name = "Default rate during the quarter";
	yaxis min=0 label = "Amount of loans (in €)";
	y2axis min=0 label='Defaults contracts rate per quarter' values=(0 to 0.1 by 0.01 );
	xaxis fitpolicy=rotate display=(nolabel);
run;

/* supprimer base inutile */

proc delete data = work.work;
run;

proc delete data = work.table;
run;

proc delete data = work_quarter;
run;