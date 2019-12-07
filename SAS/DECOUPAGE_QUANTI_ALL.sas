/*************************************************************************************/
/*****																		     *****/
/*****						PROJET SCORING RCI BANK                              *****/ 
/*****							DISCRETISATION                                   *****/ 
/*****																			 *****/
/*************************************************************************************/


/* RECODAGE DES VARIABLES QUANTI EN QUALI SELON LE PROGRAMME DE DECOUPAGE  */

data df2 (drop=duree pc_appo age mt_rev part_loyer anc_emp temps mt_dmd age_veh mt_charges );
	set df;

	*recodage duree;

	if duree < 60 then duree_cl="1";
	else duree_cl="2";

	* recodage pc_appo;

	if pc_appo < 20 then pc_appo2="1";
	else if 20 <= pc_appo < 35 then pc_appo2="2";
	else pc_appo2="3";
	
	* Recodage age;


	if age <=43 then age2="1";
	else if 43 < age < 58 then age2="2";
	else age2="3";

	* recodage mt_rev;

	if mt_rev < 300000 then mt_rev2="1";
	else mt_rev2="2";

	* recodage part_loyer;

	if part_loyer < 1.20 then part_loyer2="1";
	else if 1.20 <= part_loyer < 1.80 then part_loyer2="2";
	else part_loyer2="3";

	* recodage anc_emp;
	
	if anc_emp < 48 then anc_emp2="1";
	else if 48 <= anc_emp < 144 then anc_emp2="2";
	else anc_emp2="3";

	* label;

	label DUREE_cl="Projected duration of financing"
		  PC_APPO2="Percent contribution"
		  age2="Customer age"
		  MT_REV2="Amount of monthly income"
		  part_loyer2="Share of maturity"
		  anc_emp2="Seniority of the job";

run;


/* format sur les nouvelles variables */

proc format;
	value $duree_cl "1"="Below 5 years"
	              "2"="More than 5 years"
				  ;
	value $appo_cl "1"="Financial contribution below 20%"
	               "2"="Financial contribution between 20 and 35%"
				   "3"="Financial contribution bigger than 35%";
    value $age_cl "1"="Below 43 years old"
	             
				  "2"="Between 43 and  57 years old"
	              "3"="More than 57 years old";
    value $rev_cl "1"="Income below 3000 euros"
				  "2"="Income bigger than 3000 euros";
	value $loy_cl "1"="Below 1.20%"
	              "2"="Between 1.20 and 1.80%"
				  "3"="More than 1.80%";
	value $emp_cl "1"="Below 4 years"
	              "2"="Between 4 and 12 years"
	              "3"="More than 12 years";
	
run;


%macro valid(table,var);

proc freq data=&table noprint ;
  table &var.*we18/ outpct out=temp;
  *format &var. &format..;
run;

proc gchart data=temp;
  vbar3d &var. / sumvar=pct_row ;
  where we18 eq 1;
  title "Taux de défaut selon la variable &var.";
run;
quit;

proc freq data=&table;
  table &var.*we18 / chisq ;
 *format &var. &format..;
run;

proc delete data=temp; run;
%mend valid;

%valid(df2,duree_cl);
%valid(df2,pc_appo2);
%valid(df2,mt_rev2);
%valid(df2,age2);
%valid(df2,part_loyer2);
%valid(df2,anc_emp2);


/* STABILITE EN RISQUE */

%macro risque(table,var,form,label);

data work2;
	set &table. (keep=date_gest we18 &var.);
	quarter=put(date_gest,yyq.);
run;

proc sort data=work2;
	by quarter &var.;	
run;

data work2;
	set work2;
	by quarter &var.; 
	retain nb_cont 0 nb_df 0;

	if  first.&var.=1 then do;
		nb_cont=0;
		nb_df=0;
	end;

	nb_cont=nb_cont+1;
	if we18=1 then nb_df=nb_df+1;
    
	if last.&var. then do;
		pct=nb_df/nb_cont;
		output;
	end;

	label quarter="Quarter of the date of entry into management" pct="Percentage of contracts in defaults" ;
run;

proc sgplot data=work2;
    title "Stability in risk for the variable &label.";
	series x=quarter y=pct / group=&var.;
	label;
	format &var. &form..;
run;

%mend;

%macro volume(table,var,class,form,label);

data work2;
	set &table. (keep=date_gest we18 &var.);
	quarter=put(date_gest,yyq.);
run;

proc sort data=work2;
	by quarter &var.;	
run;

%if &class.=2 %then %do;

data work5;
	set work2;
	by quarter &var.; 
	retain nb_cont 0 nb_cont1 0 nb_cont2 0 ;

	if  first.quarter=1 then do;
		nb_cont1=0;
		nb_cont2=0;
		nb_cont=0;
	end;

	nb_cont=nb_cont+1;
	if &var.=1 then nb_cont1=nb_cont1+1;
	else nb_cont2=nb_cont2+1;;
    
	if last.quarter then do;
		pct1=nb_cont1/nb_cont;
		pct2=nb_cont2/nb_cont;
		output;
	end;

    label quarter="Quarter of the date of entry into management"
	      pct1="Class 1"
          pct2="Class 2" ;
run;

proc sgplot data=work5;
    title "Stability in volume for the variable &label.";
	series x=quarter y=pct1 ;
	series x=quarter y=pct2 ;
	format &var. &form..;	
	yaxis label = "Percentage of contracts per class";
run;

%end;

%else %if &class.=3 %then %do;

data work3;
	set work2;
	by quarter &var.; 
	retain nb_cont 0 nb_cont1 0 nb_cont2 0 nb_cont3 0;

	if  first.quarter=1 then do;
		nb_cont1=0;
		nb_cont2=0;
		nb_cont3=0;
		nb_cont=0;
	end;

	nb_cont=nb_cont+1;
	if &var.=1 then nb_cont1=nb_cont1+1;
	else if &var.=2 then nb_cont2=nb_cont2+1;
	else nb_cont3=nb_cont3+1;;
    
	if last.quarter then do;
		pct1=nb_cont1/nb_cont;
		pct2=nb_cont2/nb_cont;
		pct3=nb_cont3/nb_cont;
		output;
	end;

   
    label quarter="Quarter of the date of entry into management"
	      pct1="Class 1"
          pct2="Class 2" 
		  pct3="Class 3";
run;

proc sgplot data=work3;
    title "Stability in volume for the variable &label.";
	series x=quarter y=pct1 ;
	series x=quarter y=pct2 ;
	series x=quarter y=pct3 ;
	format &var. &form..;
	yaxis label = "Percentage of contracts per class";
run;

%end;

%else %do;

data work4;
	set work2;
	by quarter &var.; 
	retain nb_cont 0 nb_cont1 0 nb_cont2 0 nb_cont3 0 nb_cont4 0;

	if  first.quarter=1 then do;
		nb_cont1=0;
		nb_cont2=0;
		nb_cont3=0;
		nb_cont4=0;
		nb_cont=0;
	end;

	nb_cont=nb_cont+1;
	if &var.=1 then nb_cont1=nb_cont1+1;
	else if &var.=2 then nb_cont2=nb_cont2+1;
	else if &var.=3 then nb_cont3=nb_cont3+1;
	else if &var.=4 then nb_cont4=nb_cont4+1;
    
	if last.quarter then do;
		pct1=nb_cont1/nb_cont;
		pct2=nb_cont2/nb_cont;
		pct3=nb_cont3/nb_cont;
		pct4=nb_cont4/nb_cont;
		output;
	end;

    
    label quarter="Quarter of the date of entry into management"
	      pct1="Class 1"
          pct2="Class 2" 
		  pct3="Class 3"
		  pct4="Class 4";
run;

proc sgplot data=work4;
    title "Stability in volume for the variable &label.";
	series x=quarter y=pct1 ;
	series x=quarter y=pct2 ;
	series x=quarter y=pct3 ;
	series x=quarter y=pct4 ;
	format &var. &form..;
	yaxis label = "Percentage of contracts per class";
run;

%end;

%mend;

%risque(df2,duree_cl,$duree_cl,Projected duration of financing);
%risque(df2,age2,$age_cl,Customer age);
%risque(df2,pc_appo2,$appo_cl,Percent contribution);
%risque(df2,mt_rev2,$rev_cl,Amount of monthly income);
%risque(df2,part_loyer2,$loy_cl,Share of maturity);
%risque(df2,anc_emp2,$emp_cl,Seniority of the job);

%volume(df2,duree_cl,2,$duree_cl,Projected duration of financing);
%volume(df2,age2,3,$age_cl,Customer age);
%volume(df2,pc_appo2,3,$appo_cl,Percent contribution);
%volume(df2,mt_rev2,2,$rev_cl,Amount of monthly income);
%volume(df2,part_loyer2,3,$loy_cl,Share of maturity);
%volume(df2,anc_emp2,3,$emp_cl,Seniority of the job);


/* AVANT MODIFICATION données par le programme  */

data df4;
	set df;

	*recodage duree;

	if duree < 48 then duree_cl="1";
	else if 48 <= duree < 60 then duree_cl="2";
	else duree_cl="3"; 

	* recodage pc_appo;

	if pc_appo < 20 then pc_appo2="1";
	else if 20 <= pc_appo < 35 then pc_appo2="2";
	else pc_appo2="3";

	* Recodage age;

	if age <43 then age2="1";
	else if 43 <= age < 54 then age2="2";
	else age2="3";

	* recodage mt_rev;

	if mt_rev < 250000 then mt_rev2="1";
	else if 250000 <= mt_rev < 613867 then mt_rev2="2";
	else mt_rev2="3";	

	* recodage part_loyer;

	if part_loyer < 1.21 then part_loyer2="1";
	else if 1.21 <= part_loyer < 1.78 then part_loyer2="2";
	else part_loyer2="3";

	* recodage anc_emp;

	if anc_emp < 37 then anc_emp2="1";
	else if 37 <= anc_emp < 144 then anc_emp2="2";
	else anc_emp2="3";

	label DUREE_cl="Projected duration of financing"
		  PC_APPO2="Percent contribution"
		  age2="Customer age"
		  MT_REV2="Amount of monthly income"
		  part_loyer2="Share of maturity"
		  anc_emp2="Seniority of the job";

run;

* format sur les anciennes variables;

proc format;
	value $duree_clb "1"="Below 4 years"
	              "2"="Between 4 and 5 years"
				  "3"="More than 5 years"
				  ;
	value $appo_clb "1"="Financial contribution below 20%"
	               "2"="Financial contribution between 20 and 35%"
				   "3"="Financial contribution bigger than 35%";
    value $age_clb "1"="Below 43 years old"
				  "2"="Between 43 and  54 years old"
	              "3"="More than 54 years old";
    value $rev_clb "1"="Income below 2500 euros"
	              "2"="Income between 2500 and 6138.67 euros"
				  "3"="Income bigger than 6138.67 euros";
	value $loy_clb "1"="Below 1.21%"
	              "2"="Between 1.21 and 1.78%"
				  "3"="More than 1.78%";
	value $emp_clb "1"="Below 37 months"
	              "2"="Between 37 and 146 months"
	              "3"="More than 146 months";
	
run;

%risque(df4,duree_cl,$duree_clb,Projected duration of financing);
%risque(df4,age2,$age_clb,Customer age);
%risque(df4,pc_appo2,$appo_clb,Percent contribution);
%risque(df4,mt_rev2,$rev_clb,Amount of monthly income);
%risque(df4,part_loyer2,$loy_clb,Share of maturity);
%risque(df4,anc_emp2,$emp_clb,Seniority of the job);

%volume(df4,duree_cl,3,$duree_clb,Projected duration of financing);
%volume(df4,age2,3,$age_clb,Customer age);
%volume(df4,pc_appo2,3,$appo_clb,Percent contribution);
%volume(df4,mt_rev2,3,$rev_clb,Amount of monthly income);
%volume(df4,part_loyer2,3,$loy_clb,Share of maturity);
%volume(df4,anc_emp2,3,$emp_clb,Seniority of the job);


/* V DE CRAMER SUR LES NOUVELLES VARIABLES QUALITATIVES */

ods output ChiSq=ChiSq;
proc freq data=df2;
  tables (ty_pp genre_veh produit QUAL_VEH IND_CLI_RNVA ETAT_CIVIL CSP ind_fch_fcc
           secteur_ fichage imp_reg copot_ pan_dir_ bdf_cote duree_cl age2 pc_appo2 mt_rev2 part_loyer2 anc_emp2)*we18 / chisq;
run;
ods select all;

data ChiSq3 (drop=DF Statistic);
	set ChiSq;
	where Statistic="Khi-2";
run;

data ChiSq2(keep=Table abs_V_Cramer) ;
  set ChiSq;
  where Statistic like '%Cramer%';
  abs_V_Cramer = ABS(Value);
run;

proc sort data=ChiSq2; by table; run;
proc sort data=ChiSq3; by table; run;

data ChiSq4;
	merge ChiSq3 ChiSq2;
	by table;
run;

proc sort data=ChiSq4; by descending abs_V_Cramer ; run;

proc format;
	value $variable copot_="Payment behaviour"
	                secteur_="Activity area"
				    CSP="Social-professional class"
				    imp_reg="Number outstanding payments"
				    ETAT_CIVIL="Civil status code"
				    genre_veh="Type of Vehicule"
				    pan_dir_="PAN leader"
				    fichage="Filing indicator"
				    ind_fch_fcc="FCC record indicator"
				    bdf_cote="Rating of the Banque de France"
				    ty_pp="Physical person vehicule usage code"
				    produit="Product type"
				    QUAL_VEH="Quality of the vehicule "
				    IND_CLI_RNVA="Renewing customer indicator"
                    duree_cl="Projected duration of financing"
		            pc_appo2="Percent contribution"
		            age2="Customer age"
		            mt_rev2="Amount of monthly income"
		            part_loyer2="Share of maturity"
		            anc_emp2="Seniority of the job";;
run;

data Select_quali (drop=table);
  length Variable $32.;
  set ChiSq4;
  Variable = SCAN(Table,2) ; /* SCAN(Table,2) = 2e mot de la variable "Table" */
  label Value="Statistic" Prob="P-value" abs_V_Cramer="V-Cramer";
run;


ODS EXCEL FILE="C:\Users\mikew\OneDrive\Documents\GitHub\scoring\vcramer.xlsx" 
;
proc print data=select_quali label noobs;
	format variable $variable.;
run;
ODS EXCEL CLOSE;

/* supprimer table */

proc sql;
  drop table work.work2;
  drop table work.work5;
  drop table work.work3;
  drop table work.df4;
  drop table work.ChiSq4;
  drop table work.ChiSq3;
  drop table work.ChiSq2;
  drop table work.ChiSq;
  drop table work.select_quali;
quit;

proc freq data=df2;
	table csp;
run;

proc freq data=df2;
	table etat_civil;
run;


