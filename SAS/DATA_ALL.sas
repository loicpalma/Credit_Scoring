/*************************************************************************************/
/*****																		     *****/
/*****							DATA EXPLORATION                                 *****/                      
/*****																			 *****/
/*************************************************************************************/

%let path=C:\Users\mikew\Documents\MASTER 2 ESA\S1\SCORING_PROJECT;
libname scoring "&path";

/* IMPORT DES FORMATS */

proc format cntlin=format_char;
run;

proc format cntlin=format_num;
run;

/* BASE DE DONNEES */

data base_formatee;
	set scoring.base_financee_pp;
	format ty_pp $type. 
		   genre_veh $vehi. 
           produit $produit. 
           qual_veh $qual. 
           EVPM_COPOT_PAI_GLB comp. 
           IND_CLI_RNVA $ind.  
           EVPA_PRTC fichagepro. 
           EVPM_COTE cote.
           CSP $csp. 
           ETAT_CIVIL $civil. 
           MODE_HABI $habitation. 
           ind_fch_fcc $fcc.
           copot_ cmppaie. 
           pan_dir_ pan. 
           secteur_ $secact. 
           diag_fch_cli $fichpri.;
	label Ty_pp="Physical Person Vehicle Usage Code"
	      No_cnt_crypte="Identifier of the encrypted contract"
          No_par_crypte="Identifier of the encrypted client"
          date_gest="Month of the date of entry into management"
          dt_dmd="Date of demand"
          WE18="Default indicator"
          DUREE="Projected duration of financing"
          genre_veh="Type of vehicle"
	      MT_DMD="Amount of funding"
          PC_APPO="Percent contribution"
          produit="Product type"
          QUAL_VEH="Quality of the vehicle"
	      AGE_VEH="Age of the vehicle"
          IND_CLI_RNVA="Renewing customer indicator"
          nb_imp_tot="Number of outstanding payments"
          nb_imp_an_0="Number of outstanding payments from the last 12 months"
          EVPM_COPOT_PAI_GLB="Evaluation of the payment behavior"
          EVPA_PRTC="Filing indicator for PROs"
		  EVPM_COTE="Evaluation of the quotation"
          COTE_BDF="Rating of the Banque de France"
          age="Customer age"
          CSP="Socio-professional class"	
          ETAT_CIVIL="Civil status code"
          MODE_HABI= "Code of living mode"	
          mt_sal_men="Amount monthly salary"
          rev_men_autr="Other monthly amount"
          mt_alloc_men="Amount of the monthly allowance"
          nb_pers_chg="Number of dependents"
          MT_REV="Amount of monthly income"
          mt_loy_men_mena="Amount of the monthly rent of the household"
          mt_men_pre_immo="Monthly amount of the mortgage"
          mt_men_eng_mena="Monthly amount various household commitments"
          mt_charges="Amount of charges"
          ind_fch_fcc="FCC record indicator"	
          MT_ECH="Amount of the due date"
          mt_ttc_veh="Price of the vehicle"
          part_loyer="Share of maturity"
	      anc_emp="Seniority of the job"
          copot_="Payment behavior"	
          pan_dir_="PAN leader"
          secteur_="Activity area"
          diag_fch_cli="Filing indicator for PRIs"	
          IND_IMP_REGU="Number of outstanding payments settled over the last 12 months";
run;


/* DETECTION DE DOUBLONS */
/* par identifiant du contrat et du client */

proc sort data=base_formatee out=base nodupkey dupout=doublon;
	by no_par_crypte no_cnt_crypte;
run;

/* plusieurs contrats ont le même identifiant contrat et le même identifiant client */

proc sort data=base_formatee out=base nodup dupout=doublon;
	by no_par_crypte no_cnt_crypte ;
run;

/* pas de doublons dans la base de données */

/*détection valeurs manquantes */

proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;
 
proc freq data=base_formatee; 
format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;

/* distribution des variable quantitatives */

ods graphics on;

proc univariate data=base_formatee;
	*var DUREE MT_DMD PC_APPO AGE_VEH age MT_REV mt_charges part_loyer anc_emp ;
	var age;
	histogram;
run;

ods graphics off;

/* NETTOYAGE BDD */

data df (drop=EVPA_PRTC diag_fch_cli DT_DMD  IND_IMP_REGU DT_DMD2  cote_bdf );
	set base_formatee (drop=mt_sal_men
                                       rev_men_autr
                                       mt_alloc_men
                                       nb_pers_chg
                                       mt_loy_men_mena
                                       mt_men_pre_immo
                                       mt_men_eng_mena
                                       MT_ECH
                                       mt_ttc_veh
                                       nb_imp_tot
                                       nb_imp_an_0
                                       EVPM_COPOT_PAI_GLB
                                       EVPM_COTE);

	length imp_reg $16 ;

/* on enlève toutes les valeurs manquantes */

	if CSP= " " then delete;
	if ETAT_CIVIL= " " then delete;
	if mode_habi=" " then delete;
	if ind_fch_fcc=" " then delete;
	if part_loyer=. then delete;
	if anc_emp=. then delete;


/* création variable période */

	DT_DMD2=datepart(DT_DMD);
	DT_DMD2=intnx("month",DT_DMD2,0,'b');
	temps=intck('month',DT_DMD2,date_gest);
	format DT_DMD2 DDMMYY10.; 

/* création variable fichage qui nous permet de créer une seule variable à partir de EVPA_PRTC et diag_fch_cli  */

	if EVPA_PRTC <5 then fichage= "0";
	else if 5 < EVPA_PRTC < 10 then fichage= "1";
	if diag_fch_cli= "N" then fichage= "0";
	else if diag_fch_cli= "O" then fichage= "1";

/* création de la variable imp_reg */

	if IND_IMP_REGU=9999 then imp_reg="NR";
	else if IND_IMP_REGU=0 then imp_reg="no_imp_reg";
	else imp_reg="at_least_one_reg";

/* cote banque de france : on met 1 si on a une cotation BDF, 0 sinon */

	if COTE_BDF=" " then bdf_cote="0";
	else bdf_cote="1";

/* on enlève tous les pct d'apport > 100% pas logique selon nous */

	if PC_APPO> 100 then delete;

/* pour la variable age => on enlève toute les valeurs en dessous de 18 ans car l'âge minimum légal d'obtention d'un prêt est de 18 ans */

	if age < 18 then delete;

/* pour la variable part_loyer nous observons des valeurs négatives: on les élimine*/

	if part_loyer <0 then delete;

/* on regroupe dans autres toutes les modalités de CSP inférieur à 0.01% */

	if CSP not in ("00", "11", "12" ,"13") then CSP="99";

/* on regroupe dans autres toutes les modalités de CSP inférieur à 0.01% (avec immobilier */

	if secteur_ in ("CDG","FCP", "FEM", "LOA", "MET", "LIM","RPA") then secteur_="ATR";

/* regroupement des état civil */

	if etat_civil in ("M","U") then etat_civil="M";
	else etat_civil="O";

/* regroupement de mode_habi */

	if mode_habi="P" then mode_habi="P";
	else mode_habi="N";


/* nom des labels */

	label imp_reg="Nombre d'impayé régularisé lors des 12 derniers mois"
	      temps="Délai entre la demande de crédit et le début d'entrée en gestion"
		  fichage="Indicateur de fichage pour les privés et les pros"
          bdf_cote="Cote Banque de France";
run;

/* test valeurs manquantes sur notre base DF */

proc freq data=scoring.df; 
format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;



/* supprimer base inutile */

proc delete data = work.base;
run;

proc delete data = work.doublon;
run;

proc delete data = work.base_formatee;
run;




