/*************************************************************************************/
/*****																		     *****/
/*****						PROJET SCORING RCI BANK                              *****/ 
/*****							PROC LOGISTIC                                    *****/ 
/*****																			 *****/
/*************************************************************************************/

/* CREATION ECHANTILLON TRAIN ET TEST */

proc sort data=df2 out=df3 (drop=imp_reg ty_pp);
	by we18;
run;

/* Création du Subsample 11% de défaut */

proc surveyselect data=df3 out=subsample (drop=NumberHits ExpectedHits SamplingWeight)  method=urs sampsize=(10080 1260) seed=25196  outhits;
	strata we18;
run;



proc export data=subsample
			outfile="C:\Users\mikew\Desktop\subsample_df.csv"
			dbms=csv replace ;
			delimiter=',';
run;

/* IMPORTATION BASE DE DONNEES */

proc import file="C:\Users\mikew\Desktop\df_smote.csv"
            out=smote
			dbms=dlm replace;
			delimiter=",";
run;

proc contents data=smote;run;
/**/

proc surveyselect data=smote
                  outall                
                  samprate=.75  
                  out = logistic
                  method = srs  
                  seed = 435 ;  
                  strata we18;                              
run ;

data train (drop=selected SelectionProb SamplingWeight) test (drop=selected SelectionProb SamplingWeight);
	set logistic;
	if Selected=1 then output train;
	else output test;
run;


/* ESTIMATION PROC LOGISTIC */


*ods output ParameterEstimates=Parametres_V1; 	/* Table avec les paramètres estimées */
*ods output ClassLevelInfo=Modalites; 			/* Table avec les différentes modalités de chaque variables */

proc logistic data=train;
class  
      genre_veh produit QUAL_VEH IND_CLI_RNVA ETAT_CIVIL CSP ind_fch_fcc mode_habi
           secteur_ fichage  copot_ pan_dir_ bdf_cote duree_cl age2 pc_appo2 mt_rev2 part_loyer2 anc_emp2
/param=ref;
model we18(event="1")= genre_veh produit QUAL_VEH IND_CLI_RNVA ETAT_CIVIL CSP ind_fch_fcc mode_habi
           secteur_ fichage  copot_ pan_dir_ bdf_cote duree_cl age2 pc_appo2 mt_rev2 part_loyer2 anc_emp2 / noint selection=stepwise   ;
score data=test out=prev outroc=rocstats fitstat;
run;

/*
La meilleure régression logistique selon la méthode stepwise conserve les variables suivantes:
  produit  ETAT_CIVIL CSP ind_fch_fcc secteur_ fichage  copot_   duree_cl age2 pc_appo2  part_loyer2 anc_emp2 bdf_cote

*/

/* Meilleure régression logistique */

/* smote */

ods output ParameterEstimates=Parametres_V1; 	/* Table avec les paramètres estimées */
ods output ClassLevelInfo=Modalites; 			/* Table avec les différentes modalités de chaque variables */
proc logistic data=train;
class    genre_veh produit QUAL_VEH IND_CLI_RNVA  CSP ind_fch_fcc mode_habi
           secteur_ fichage  copot_ pan_dir_ bdf_cote duree_cl age2 pc_appo2  part_loyer2 anc_emp2
          /param=ref;
model we18(event="1")=  genre_veh produit QUAL_VEH IND_CLI_RNVA  CSP ind_fch_fcc mode_habi
           secteur_ fichage  copot_ pan_dir_ bdf_cote duree_cl age2 pc_appo2  part_loyer2 anc_emp2 / noint    ;
score data=test out=prev outroc=rocstats fitstat;
run;


/* df3 */

*ods output ParameterEstimates=Parametres_V1; 	/* Table avec les paramètres estimées */
*ods output ClassLevelInfo=Modalites; 			/* Table avec les différentes modalités de chaque variables */
/*
proc logistic data=train;
class anc_emp2 bdf_cote copot_ CSP duree_cl ETAT_CIVIL fichage IND_CLI_RNVA
      ind_fch_fcc MODE_HABI part_loyer2 pc_appo2 produit QUAL_VEH secteur_ 
/param=ref;
model we18(event="1")=  anc_emp2 bdf_cote copot_ CSP duree_cl ETAT_CIVIL fichage IND_CLI_RNVA
      ind_fch_fcc MODE_HABI part_loyer2 pc_appo2 produit QUAL_VEH secteur_  / noint    ;
score data=test out=prev outroc=rocstats fitstat;
run;
*/

/* subsample */

*ods output ParameterEstimates=Parametres_V1; 	/* Table avec les paramètres estimées */
*ods output ClassLevelInfo=Modalites; 			/* Table avec les différentes modalités de chaque variables */
/*
proc logistic data=train;
class age2 anc_emp2  copot_ CSP duree_cl ETAT_CIVIL fichage 
      ind_fch_fcc MODE_HABI part_loyer2 pc_appo2   secteur_ 
/param=ref;
model we18(event="1")= age2 anc_emp2  copot_ CSP duree_cl ETAT_CIVIL fichage 
      ind_fch_fcc MODE_HABI part_loyer2 pc_appo2   secteur_  / noint    ;
score data=test out=prev outroc=rocstats fitstat;
run;
*/

* 9.5 Choix du cutoff (seuil de probabilité);
* ------------------------------------------;
data rocstats;
  set rocstats;
  specif=1-_1mspec_;
run;

goption reset=global;
title height=2 "Courbe de sensibilite et de specificite";
        legend1 frame
        across=1
            mode=protect
            position=(top left)
        offset=(15 cm, -1.5 cm);
axis1 label=none order=(0 to 1 by 0.2) width=1 value=(h=1);
axis2 label=none order=(0 to 1 by 0.1) width=1 value=(h=1) label=("Seuil de probabilite");

proc gplot data=rocstats;
  symbol1 value=none i=join color=blue;
  symbol2 value=none i=join color=red;
  plot (specif _sensit_)*_prob_ / overlay legend=legend1 haxis=axis2 vaxis=axis1 ;
run;
quit;                   * Résultat : Cutoff=0.02;


* 9.6 Matrice de confusion pour un seuil de proba s = 0.02 ;
* -------------------------------------------------------- ;
data prev;
  set prev;
  if P_1>0.02 then predicted=1;
    else predicted=0;
run;

proc freq data=prev;
  tables we18*predicted;
run;


* 9.7 Construction de la courbe ROC;
* ---------------------------------;
data rocstats; set rocstats;
  temp=_1mspec_;
run;

proc gplot data=rocstats;
  symbol1 i=join v=none c=blue;
  symbol2 i=join v=none c=blue;
  title 'Courbe ROC';
  plot (_sensit_ temp)*_1mspec_ / overlay vaxis=0 to 1 by .1 cframe=ligr;
  run;
  quit;

/* table à supprimer */

proc sql;
  drop table work.logistic;
  drop table work.prev;
  drop table work.rocstats;
quit;