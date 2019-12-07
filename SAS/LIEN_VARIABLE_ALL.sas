/* LIEN ENTRE LA VARIABLE CIBLE ET LES VALEURS QUANTITATIVES ET QUALITATIVES */

/* Macro */

%macro quali1(data,var);
proc freq data=&data noprint;
  table &var*WE18 /chisq outpct out=freq_&var /* Table en sortie */;
run;

proc gchart data=freq_&var;
  vbar3d &var / sumvar=pct_row;
  where WE18=1;
  title "Taux de défaut en fonction de la variable &var";
run;
quit;

proc gchart data=&data;
  vbar3d &var / sumvar=WE18;
  title "Nombre de défaut selon la variable &var";
run;
quit;
%mend quali1;

/* VARIABLE QUALITATIVES NOMINALES */

%quali1(df, ty_pp);
%quali1(df, genre_veh);
%quali1(df, produit);
%quali1(df, QUAL_VEH);
%quali1(df, IND_CLI_RNVA);
%quali1(df, ETAT_CIVIL);
%quali1(df, CSP);
%quali1(df, ind_fch_fcc);
%quali1(df, secteur_);
%quali1(df, fichage);
%quali1(df, imp_reg);
%quali1(df, bdf_cote);
%quali1(df, mode_habi);


/* VARIABLE QUALITATIVES ORDINALES */

%quali1(df, copot_);
%quali1(df, pan_dir_);

/* SELECTION V DE CRAMER */

ods output ChiSq=ChiSq;
proc freq data=df;
  tables (ty_pp genre_veh produit QUAL_VEH IND_CLI_RNVA ETAT_CIVIL CSP ind_fch_fcc
           secteur_ fichage imp_reg copot_ pan_dir_ bdf_cote mode_habi)*we18 / chisq;
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


data Select_quali (drop=table);
  length Variable $32.;
  set ChiSq4;
  Variable = SCAN(Table,2) ; /* SCAN(Table,2) = 2e mot de la variable "Table" */
run;

proc format;
	value $variable copot_="Payment behaviour"
	                secteur_="Activity area"
				    CSP="Social-professional class"
				    imp_reg="Number outstanding payments"
				    ETAT_CIVIL="Civil status code"
				    genre_veh="Type of Vehicule"
				    pan_dir_="PAN leader"
				    fichage="Fichage"
				    ind_fch_fcc="FCC record indicator"
				    bdf_cote="Rating of the Banque de France"
				    ty_pp="Physical person vehicule usage code"
				    produit="Product type"
				    QUAL_VEH="Quality of the vehicule "
				    IND_CLI_RNVA="Renewing customer indicator"
                    MODE_HABI="Type of location";
run;



title "Test de Khi-2";
proc print data=Select_quali; 
	format variable $variable. ;
run;
title;
/* peu de dépendances avec le v de cramer */

/* MACRO QUANTI */

/* on va voir si nos variables quantitatives suivent une loi normale ou non */
%macro univ(data,var);
title "DISTRIBUTION OF &VAR" ;
proc univariate data=&data;
  var &var;
  histogram / normal    (l=1 color=red)
              cframe     = ligr
                          cfill      = yellow
              cframeside = ligr
              vaxis      = axis1
              name       = '&VAR';
 
  axis1 label=(a=90 r=0);
run;
title"DISTRIBUTION OF &VAR";
%mend univ;

ods graphics / height=400px width=400px;

%univ(df,DUREE) ;           /* ne suit pas une loi normale*/
%univ(df,MT_DMD);           /* ne suit pas une loi normale*/
%univ(df,PC_APPO);          /* ne suit pas une loi normale*/
%univ(df,AGE_VEH);          /* ne suit pas une loi normale*/
%univ(df,age);              /* ne suit pas une loi normale*/
%univ(df,MT_REV);           /* ne suit pas une loi normale*/
%univ(df,mt_charges);       /* ne suit pas une loi normale*/
%univ(df,part_loyer);       /* ne suit pas une loi normale*/ 
%univ(df,anc_emp);          /* ne suit pas une loi normale*/
%univ(df,temps);            /* ne suit pas une loi normale*/

title;

/* AUCUNE DE NOS VARIABLES QUANTITATIVES NE SUIT UNE LOI NORMALE */
/* DONC NOUS ALLONS FAIRE LE TEST NON PARAMETRIQUE DE WILCOXON / KRUSKALL-WALLIS */

ods output KruskalWallisTest = kruskal;
proc npar1way wilcoxon data=df;
  class we18;
  var DUREE MT_DMD PC_APPO AGE_VEH age mt_rev mt_charges part_loyer anc_emp temps;
run;
ods select all;



proc sort data=kruskal; by descending ChiSquare; run;
proc print data=kruskal; run;

proc export data=kruskal
            outfile="C:\Users\mikew\Documents\MASTER 2 ESA\S1\SCORING_PROJECT\SCORING_ALL\kruskal.xlsx"
			dbms=excel;
run;

/* supprimer base inutile */

proc sql;
  
  drop table work.freq_genre_veh;
  drop table work.freq_produit;
  drop table work.freq_QUAL_VEH;
  drop table work.freq_IND_CLI_RNVA;
  drop table work.freq_ETAT_CIVIL;
  drop table work.freq_CSP;
  drop table work.freq_secteur_;
  drop table work.freq_copot_;
  drop table work.freq_pan_dir_;
  drop table work.freq_ind_fch_fcc;
  drop table work.freq_ty_pp;
  drop table work.freq_fichage;
  drop table work.freq_imp_reg;
  drop table work.freq_bdf_cote;
  drop table work.kruskal;
  drop table work.ChiSq4;
  drop table work.ChiSq3;
  drop table work.ChiSq2;
  drop table work.ChiSq;
  drop table work.select_quali;
  drop table work.freq_mode_habi;
quit;


