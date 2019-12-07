
/*************************************************************************************/
/*****																		     *****/
/*****					 	 PROJET SCORING RCI BANK                             *****/ 
/*****					   GRILLE DE SCORE INDIVIDUELLE                          *****/ 
/*****					     CALCUL DES PERFORMANCES                             *****/
/*****																			 *****/
/*************************************************************************************/

/* CALCUL DU SCORE POUR CHAQUE INDIVIDU PRESENT DANS LA BASE DE DONNEES */

/*
data score1 (drop= no_cnt_crypte no_par_crypte we18 date_gest
				   age2 
                   anc_emp2 
                   bdf_cote
                   copot_
                   CSP
				   duree_cl
                   ETAT_CIVIL
				   fichage
                   genre_veh
                   imp_reg
				   IND_CLI_RNVA
                   ind_fch_fcc	
				   mt_rev2
				   pan_dir_
                   part_loyer2
                   pc_appo2
				   produit
				   QUAL_VEH
				   secteur_
				   ty_pp
);
	
	
	set df3;

	if age2 = "1" then age_1=1; else age_1=0;
	if age2 = "2" then age_2=1; else age_2=0;
	if age2 = "3" then age_3=1; else age_3=0;

   	if anc_emp2 = "1" then anc_emp2_1=1; else anc_emp2_1=0;
	if anc_emp2 = "2" then anc_emp2_2=1; else anc_emp2_2=0;
	if anc_emp2 = "3" then anc_emp2_3=1; else anc_emp2_3=0;
 
	if bdf_cote = "1" then bdf_cote_1=1; else bdf_cote_1=0;
	if bdf_cote = "2" then bdf_cote_2=1; else bdf_cote_2=0;

	if copot_ = 1 then copot_1=1; else copot_1=0;
	if copot_ = 2 then copot_2=1; else copot_2=0;
	if copot_ = 3 then copot_3=1; else copot_3=0;

	if CSP="00" then CSP_1=1; else CSP_1=0;
	if CSP="10" then CSP_2=1; else CSP_2=0;
	if CSP="11" then CSP_3=1; else CSP_3=0;
	if CSP="12" then CSP_4=1; else CSP_4=0;
	if CSP="13" then CSP_5=1; else CSP_5=0;
	if CSP="14" then CSP_6=1; else CSP_6=0;
	if CSP="20" then CSP_7=1; else CSP_7=0;
	if CSP="22" then CSP_8=1; else CSP_8=0;
	if CSP="30" then CSP_9=1; else CSP_9=0;
	if CSP="31" then CSP_10=1; else CSP_10=0;
	if CSP="40" then CSP_11=1; else CSP_11=0;
	if CSP="41" then CSP_12=1; else CSP_12=0;
	if CSP="50" then CSP_13=1; else CSP_13=0;
	if CSP="51" then CSP_14=1; else CSP_14=0;
	if CSP="62" then CSP_15=1; else CSP_15=0;

	if duree_cl = "1" then duree_cl_1=1; else duree_cl_1=0;
	if duree_cl = "2" then duree_cl_2=1; else duree_cl_2=0;
    
	if ETAT_CIVIL="C" then ETAT_CIVIL_1=1; else ETAT_CIVIL_1=0;
	if ETAT_CIVIL="D" then ETAT_CIVIL_2=1; else ETAT_CIVIL_2=0;
	if ETAT_CIVIL="M" then ETAT_CIVIL_3=1; else ETAT_CIVIL_3=0;
	if ETAT_CIVIL="S" then ETAT_CIVIL_4=1; else ETAT_CIVIL_4=0;
	if ETAT_CIVIL="U" then ETAT_CIVIL_5=1; else ETAT_CIVIL_5=0;
	if ETAT_CIVIL="V" then ETAT_CIVIL_6=1; else ETAT_CIVIL_6=0;

	if fichage = "0" then fichage_1=1; else fichage_1=0;
	if fichage = "1" then fichage_2=1; else fichage_2=0;

	if genre_veh = "VP" then genre_veh_1=1; else genre_veh_1=0;
	if genre_veh = "VU" then genre_veh_2=1; else genre_veh_2=0;
	
	if imp_reg="NR" then imp_reg_1=1; else imp_reg_1=0;
	if imp_reg="at_least_one_reg" then imp_reg_2=1; else imp_reg_2=0;
	if imp_reg="no_imp_reg" then imp_reg_3=1; else imp_reg_3=0;

	if IND_CLI_RNVA = "N" then IND_CLI_RNVA_1=1; else IND_CLI_RNVA_1=0;
	if IND_CLI_RNVA = "O" then IND_CLI_RNVA_2=1; else IND_CLI_RNVA_2=0;

    if ind_fch_fcc = "N" then ind_fch_fcc_1=1; else ind_fch_fcc_1=0;
	if ind_fch_fcc = "O" then ind_fch_fcc_2=1; else ind_fch_fcc_2=0;

	if mt_rev2 = "1" then mt_rev2_1=1; else mt_rev2_1=0;
	if mt_rev2 = "2" then mt_rev2_2=1; else mt_rev2_2=0;

	if pan_dir_ = "1" then pan_dir_1=1; else pan_dir_1=0;
	if pan_dir_ = "2" then pan_dir_2=1; else pan_dir_2=0;

	if part_loyer2="1" then part_loyer2_1=1; else part_loyer2_1=0;
	if part_loyer2="2" then part_loyer2_2=1; else part_loyer2_2=0;
	if part_loyer2="3" then part_loyer2_3=1; else part_loyer2_3=0;

	if pc_appo2="1" then pc_appo2_1=1; else pc_appo2_1=0;
	if pc_appo2="2" then pc_appo2_2=1; else pc_appo2_2=0;
	if pc_appo2="3" then pc_appo2_3=1; else pc_appo2_3=0;

	if produit="CB" then produit_1=1; else produit_1=0;
	if produit="CC" then produit_2=1; else produit_2=0;
	if produit="LLD" then produit_3=1; else produit_3=0;

	if QUAL_VEH = "VN" then QUAL_VEH_1=1; else QUAL_VEH_1=0;
	if QUAL_VEH = "VO" then QUAL_VEH_2=1; else QUAL_VEH_2=0;

	if secteur_="AGR" then secteur_1=1; else secteur_1=0;
	if secteur_="ATR" then secteur_2=1; else secteur_2=0;
	if secteur_="BTP" then secteur_3=1; else secteur_3=0;
	if secteur_="CDD" then secteur_4=1; else secteur_4=0;
	if secteur_="CDG" then secteur_5=1; else secteur_5=0;
	if secteur_="EAE" then secteur_6=1; else secteur_6=0;
	if secteur_="FBC" then secteur_7=1; else secteur_7=0;
	if secteur_="FCP" then secteur_8=1; else secteur_8=0;
	if secteur_="FEM" then secteur_9=1; else secteur_9=0;
	if secteur_="HOP" then secteur_10=1; else secteur_10=0;
	if secteur_="HRS" then secteur_11=1; else secteur_11=0;
	if secteur_="LIM" then secteur_12=1; else secteur_12=0;
	if secteur_="LOA" then secteur_13=1; else secteur_13=0;
	if secteur_="MET" then secteur_14=1; else secteur_14=0;
	if secteur_="RPA" then secteur_15=1; else secteur_15=0;
	if secteur_="SCE" then secteur_16=1; else secteur_16=0;
	if secteur_="TRA" then secteur_17=1; else secteur_17=0;

	if ty_pp = "PRI" then ty_pp_1=1; else ty_pp_1=0;
	if ty_pp = "PRO" then ty_pp_2=1; else ty_pp_2=0;
	
	
	run;
*/
data score1 (drop= no_cnt_crypte no_par_crypte we18 date_gest
                   mode_habi
				   age2 
                   anc_emp2 
                   bdf_cote
                   copot_
                   CSP
				   duree_cl
                   ETAT_CIVIL
				   fichage
                   genre_veh
                   imp_reg
				   IND_CLI_RNVA
                   ind_fch_fcc	
				   mt_rev2
				   pan_dir_
                   part_loyer2
                   pc_appo2
				   produit
				   QUAL_VEH
				   secteur_
				   ty_pp
				   poids
);
	
	
	set df3;

	if age2 = "1" then age_1=1; else age_1=0;
	if age2 = "2" then age_2=1; else age_2=0;
	if age2 = "3" then age_3=1; else age_3=0;

   	if anc_emp2 = "1" then anc_emp2_1=1; else anc_emp2_1=0;
	if anc_emp2 = "2" then anc_emp2_2=1; else anc_emp2_2=0;
	if anc_emp2 = "3" then anc_emp2_3=1; else anc_emp2_3=0;

	if copot_ = 1 then copot_1=1; else copot_1=0;
	if copot_ = 3 then copot_2=1; else copot_2=0;
	if copot_ = 2 then copot_3=1; else copot_3=0;

	if duree_cl="1" then duree_cl_1=1; else duree_cl_1=0;
	if duree_cl="2" then duree_cl_2=1; else duree_cl_2=0;

	if ETAT_CIVIL="C" then ETAT_CIVIL_1=1; else ETAT_CIVIL_1=0;
	if ETAT_CIVIL="D" then ETAT_CIVIL_2=1; else ETAT_CIVIL_2=0;
	if ETAT_CIVIL="M" then ETAT_CIVIL_3=1; else ETAT_CIVIL_3=0;
	if ETAT_CIVIL="S" then ETAT_CIVIL_4=1; else ETAT_CIVIL_4=0;
	if ETAT_CIVIL="U" then ETAT_CIVIL_5=1; else ETAT_CIVIL_5=0;
	if ETAT_CIVIL="V" then ETAT_CIVIL_6=1; else ETAT_CIVIL_6=0;
    
	if IND_CLI_RNVA = "N" then IND_CLI_RNVA_1=1; else IND_CLI_RNVA_1=0;
	if IND_CLI_RNVA = "O" then IND_CLI_RNVA_2=1; else IND_CLI_RNVA_2=0;

    if ind_fch_fcc = "N" then ind_fch_fcc_1=1; else ind_fch_fcc_1=0;
	if ind_fch_fcc = "O" then ind_fch_fcc_2=1; else ind_fch_fcc_2=0;

	if MODE_HABI = "N" then MODE_HABI_1=1; else MODE_HABI_1=0;
	if MODE_HABI = "P" then MODE_HABI_2=1; else MODE_HABI_2=0;

	if pc_appo2="1" then pc_appo2_1=1; else pc_appo2_1=0;
	if pc_appo2="2" then pc_appo2_2=1; else pc_appo2_2=0;
	if pc_appo2="3" then pc_appo2_3=1; else pc_appo2_3=0;

	if produit="CC" then produit_1=1; else produit_1=0;
	if produit="CB" then produit_2=1; else produit_2=0;
	if produit="LLD" then produit_3=1; else produit_3=0;

	if secteur_="AGR" then secteur_1=1; else secteur_1=0;
	if secteur_="ATR" then secteur_2=1; else secteur_2=0;
	if secteur_="FBC" then secteur_3=1; else secteur_3=0;
	if secteur_="BTP" then secteur_4=1; else secteur_4=0;
	if secteur_="CDD" then secteur_5=1; else secteur_5=0;
	if secteur_="EAE" then secteur_6=1; else secteur_6=0;
	if secteur_="HOP" then secteur_7=1; else secteur_7=0;
	if secteur_="HRS" then secteur_8=1; else secteur_8=0;
	if secteur_="SCE" then secteur_9=1; else secteur_9=0;
	if secteur_="TRA" then secteur_10=1; else secteur_10=0;
	
	run;	
proc iml;

use score1;
read all into x;
close score1;

use defaut_grille;
read all into y;
close defaut_grille;

z=x*y;

create toto1 from z;
append from z;
close;

quit;

/* SCORE INDIVIDUEL */

data score_ind;
	merge df3 (keep=no_cnt_crypte no_par_crypte we18) toto1 (rename=(COL1=score));
run;

proc sgplot data=score_ind;
  histogram score / group=we18 transparency=0.5;       
  density score / type=normal group=we18; 
run;

proc univariate data=score_ind;
	var score;
run;
/* dix/x */


proc rank data=score_ind descending out=dix_x2 groups=10;
	var score;
run;

proc freq data=dix_x2;
	tables score*we18;
run;


/* cut_off de score inf à 65 */
*%macro gini();

*%do i=0 %to 100;

%let cutoff=30;

data cutoff;
	set score_ind;
	if score<&cutoff. then estime=1;
	else estime=0;
run;

ods output CrossTabFreqs=freq;
proc freq data=cutoff;
	table estime*we18;
run;

/* indice de gini */

data freq (keep=pdm colpercent);
    length pdm 8;
	set freq (keep=estime we18 _type_ colpercent); 
	where estime=1 and we18=0 and _type_="11";
	pdm=&cutoff.;
run; 

proc append base=freq3 data=freq;
run;

*%end;

*%mend;

*%gini;

