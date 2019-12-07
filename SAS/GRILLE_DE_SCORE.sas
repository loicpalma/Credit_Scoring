/*************************************************************************************/
/*****																		     *****/
/*****						PROJET SCORING RCI BANK                              *****/ 
/*****					        GRILLE DE SCORE                                  *****/ 
/*****																			 *****/
/*************************************************************************************/

/* Création de la grille de score */

data Modalites;
set Modalites(keep=class value);
if class=" " then manquant="1";
run;

proc iml;
use Modalites;
read all var{class value manquant} into toto;
close toto;

n=nrow(toto);

do i=2 to n;
if toto[i,3]="1" then toto[i,1]=toto[i-1,1];
end;
idvar={'Variable' 'Modalite' 'COntrole'};

create Modalites2 from toto[colname=idvar];
append from toto;
close;
quit;

proc sql;
create table Parametres_def_V1 as
select t1.Variable,
t1.Modalite,
t2.Estimate
from modalites2 as t1
left join Parametres_V1 as t2
on t1.Modalite=t2.ClassVal0 and t1.variable=t2.variable;
quit;


data Parametres_def_V1;
set Parametres_def_V1;
if estimate=. then estimate=0;
run;



/* Calcul des scores associées à chaque modalité */



/*Indiquer les variables conservées dans la proc logistique */

%let liste_var= produit   ETAT_CIVIL  ind_fch_fcc MODE_HABI
           secteur_   copot_   duree_cl age2 pc_appo2   anc_emp2 IND_CLI_RNVA ; 

/* MACRO */

%macro grille(Table_estimee=);
%let j=1;
%let sum_min=0;
%let sum_max=0;

%do %while(%scan(&liste_var.,&j," ")^=);

%let var=%scan(&liste_var.,&j," ");
data s_&var.;
set &table_estimee(where=(Variable="&var.")); 
run;

proc sql ;
create table g_&var as 
select Variable,
Modalite,
Estimate,
min(Estimate) as Min_coef,
max(Estimate) as Max_coef
from s_&var.;
quit;

proc sql noprint;
select min(estimate) into: min from s_&var. ;
select max(estimate) into: max from s_&var.;
quit;

%let sum_min=%sysevalf(&sum_min+&min); 
%let sum_max=%sysevalf(&sum_max+&max);
%Let j = %eval(&j. + 1) ;
%end;


data grille;
set g_:;
run;

data defaut_grille(keep=variable Modalite score) ;
length variable $50.;
set grille;
score= 100*(abs(estimate-max_coef))/(%sysevalf(&sum_max-&sum_min));
run;
%mend;



%grille(table_estimee=Parametres_def_V1);

proc print data=defaut_grille;run;


/* supprimer table */

proc datasets lib=work nolist nowarn;
delete g_:;
run;

proc datasets lib=work nolist nowarn;
delete s_:;
run;

proc sql;
	drop table work.grille;
	drop table work.modalites2;
	drop table work.modalites;
	drop table work.PARAMETRES_DEF_V1;
quit;


%let liste_var2=age2 anc_emp2 bdf_cote copot_ CSP  duree_cl   ETAT_CIVIL  
                fichage ind_fch_fcc part_loyer2 pc_appo2 produit secteur_ mode_habi ;




%macro grille2;
%let j=1;


%do %while(%scan(&liste_var2.,&j," ")^=);

%let var=%scan(&liste_var2.,&j," ");

ods output CrossTabFreqs=freq;
proc freq data=df3 ;
	table &var.*we18
			/ nofreq nocol;
run;

data freq (drop=we18 _type_ rowpercent &var. );
	length variable $50 modalite $50;
	set freq (keep=&var. percent rowpercent _type_ we18) ;
	where _type_="10" or (RowPercent is not missing and we18=1);
	retain def 0;
	variable="&var.";
	modalite=&var.;
	if rowpercent ne . then def=rowpercent;
	if rowpercent=. then output;
	format def comma6.2;
run;

proc append base=freq2 data=freq force;
run;

%Let j = %eval(&j. + 1) ;
%end;

%mend;

%grille2;



proc sort data=freq2 presorted;
	by variable;
run;

proc sort data=defaut_grille presorted;
	by variable;
run;

data defaut_grille2;
    length variable $50 modalite $50;
	merge freq2 (drop=modalite) defaut_grille;
	by variable;
run;

proc print data=defaut_grille2;run;






