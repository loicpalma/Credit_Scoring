/*************************************************************************************/
/*****																		     *****/
/*****						PROJET SCORING RCI BANK                              *****/ 
/*****					PROGRAMME AUTOMATIQUE PERMETTANT                         *****/
/*****                        LA DISCRETISATION                                  *****/ 
/*****																			 *****/
/*************************************************************************************/


%let liste1=DUREE  PC_APPO  age mt_rev   anc_emp ;

%let liste2=WE18;

%let base=df;

data table_cible;
	set &base. (keep=&liste1 &liste2) ;
	poids=1;
run;

/***************************************/
/*             MACRO DECOUP            */
/***************************************/

%macro min(a,b,c,d);

  data ess;
    x1=&a;
    x2=&b;
    x3=&c;

  data _null_;
    set ess;
    d=min(x1,x2,x3);
    call symput("&d",left(put(d,8.)));
  run;

%mend;


* Debut de la macro principale *;

%macro decoup(tab_in,x,z,fz,w,nbquant,nbcmax,pc_seuil,form);

  *** Poids;
  data &tab_in; set &tab_in; poids=1; run;

  data ess2;
    x=&nbquant;
    x=int(1000000/x)/10000;
    call symput('dec',left(put(x,10.4)));
  run;

  proc univariate data=&tab_in noprint;
    var &x;
    output out=ZZBORNES pctlpts = 0 to 100 by &dec pctlpre = limit;
  run;

  * Transposition de la table ZZBORNES *;

  proc transpose data=ZZBORNES out=ZZBORNES prefix=borne; run;

   data ZZBORNES (drop=borne1);
     retain test egal;
     set ZZBORNES (keep=borne1);
     borneinf=lag(borne1);
     bornesup=borne1;
     if _n_=1 then do;
       test='non';
       egal=1;
     end;

     else if egal=0 and bornesup=borneinf then do;
       test='non';
       egal=0;
     end;

     else do;
       test='oui';
       if borneinf ne bornesup then egal=1;
       else egal=0;
     end;

     data ZZBORNES (drop=test );
       set ZZBORNES;
       if test='non' then delete;
     run;

     data ZZBORNES ;
       set ZZBORNES nobs=x;
       if _n_=1 then call symput("nbfin",left(put(x,8.)));
       lag_egal=lag(egal);
       if _n_=1 then lag_egal=1;
     run;


  * Determination du nombre maximal de classes dans le decoupage optimal *;

  %local nbcsup nbdec;

  * valeur a ne pas depasser pour nbcmax *;
  %let nbcsup=8;

  %min(%eval(&nbcmax),%eval(&nbfin),%eval(&nbcsup),nbdec);

  * Creation des variables macro associees aux bornes inf et sup *;

  data _null_;
    set ZZBORNES;
    %do i=1 %to &nbfin;
      if _N_ = &i then do;
        call symput("inf&i",left(borneinf));
        call symput("sup&i",left(bornesup));
        call symput("l_ega&i",left(put(lag_egal,1.)));
        call symput("ega&i",left(put(egal,1.)));
      end;
    %end;
  run;

  * Creation du format associe au decoupage fin *;

  proc format;
    value formfin
       %if &ega1=0  %then %do;
         &inf1=1
       %end;

       %else %do;
         low-<&sup1=1
       %end;

       %do k=2 %to %eval(&nbfin-1);
         %if &&l_ega&k=0  %then %do;
           &&inf&k<-<&&sup&k=&k
         %end;

         %else %if &&ega&k=0  %then %do;
           &&inf&k=&k
         %end;

         %else %do;
           &&inf&k-<&&sup&k=&k
         %end;
       %end;

     %if &&l_ega&nbfin=0  %then %do;
       &&inf&nbfin<-high=&nbfin
     %end;

     %else %do;
       &&inf&nbfin-high=&nbfin
     %end;
     ;
  run;

  proc freq data=&tab_in;
    format &x formfin.
         %if %length(&fz) ne 0 %then %do;
           &z &fz..
         %end;
    ;

    weight &w;
    table &z*&x / out=ZZFIN noprint;
  run;

  * Modification du format de x dans la table ZZFIN *;

  data ZZFIN;
    set ZZFIN;
    if percent=. then delete;

  data ZZFIN;
    retain &z(0);
    set ZZFIN (rename=(&z=y));
    %if %length(&fz) ne 0 %then %do;
      u=put(y,&fz..);
    %end;

    %else %do;
      u=y;
    %end;

    lag=lag(u);
    if u ne lag then &z=&z+1;
    po=put(&x,formfin.);
    poi=input(po,8.);
  run;

***********************************;
* Recherche du meilleur decoupage *;
***********************************;

PROC IML;

  * Lecture des tables utiles *;
    use ZZFIN;
    read all var {poi} into x;
    read all var {&z} into z;
    read all var {count} into n;
    use ZZBORNES;
    read all var {borneinf} into bfinfin;
    read all var {bornesup} into bfsupin;
    read all var {lag_egal} into legal;
    read all var {egal} into egal;

  * Calcul du tableau croise fin de depart *;
    mx=max(x);
    mz=max(z);
    tabfin=j(mx,mz,0);
    do i=1 to nrow(x);
      tabfin[x[i],z[i]]=n[i];
    end;

  * Calcul de la loi marginale en z *;
    ntot=tabfin[+,+];
    loi_z=tabfin[+,];


    dec=j(1,%eval(&nbcsup+1),0);
    dec_opt=j(1,%eval(&nbdec+1),0);
    bornesup=j(1,%eval(&nbcsup),0);
    treel=j(mx,mz,0);
    loi_x=j(1,mx,0);
    tindep=j(%eval(&nbdec),mz,0);
    chi2_opt=j(%eval(&nbdec-1),5,0);
    chi2=j(1,1,0);
    test=j(1,1,0);
    y=j(1,1,0);
    depart=j(1,1,0);
    yui=j(1,1,0);
    i11=j(1,1,0);
    varname={'infe' 'infin' 'supe' 'supin'};
    chi2name={'nb_classe' 'chi2' 'pearson' 'tschuprow' 'cramer'};
    tre=j(1,1,0);
    tre=&pc_seuil*ntot/100;
    if &nbquant=&nbfin then do;
       if &pc_seuil*&nbquant=100 then
             tre=ntot/&nbquant;
       else tre=(int(&pc_seuil*&nbquant/100)+1)/&nbquant*ntot;
    end;

 * Calcul du tableau reel treel et de la loi marginale en x *;
    do i=1 to mx;
       loi_x[i]=0;
       do j=1 to mz;
          treel[i,j]=0;
       end;
       do k=1 to i;
          do j=1 to mz;
             treel[i,j]=treel[i,j]+tabfin[k,j];
             loi_x[i]=loi_x[i]+tabfin[k,j];
          end;
       end;
    end;

 * Boucle sur differentes combinaisons de classes fines *;
    do nbc=2 to %eval(&nbdec);
         if nbc>2 then do;
            do i=(nbc-1) to 2 by -1;
               bornesup[i]=bornesup[i-1];
            end;
         end;
         if nbc=2 then depart=mx;
                  else depart=bornesup[2]-1;
         y=ntot-tre*(nbc-1);
         do i=depart to 2 by -1;
           if ((loi_x[i]<=y)) then  do;
              yui=i;
              i=2;
           end;
         end;
         bornesup[1]=min(yui,mx-nbc+1);
         do i=1 to mx;
            if (loi_x[i]>=tre) then  do;
               yui=i;
               i=mx;
            end;
            i11=yui;
         end;
      do i1=i11 to bornesup[1];
        dec[2]=i1;
        if nbc>2 then do;
            do i=(i1+1) to mx;
              if ((loi_x[i] - loi_x[i1])>=tre) then  do;
                 yui=i;
                 i=mx;
              end;
            end;
            i11=yui;
            end;
        else do ;
             i11=i1+1;
             bornesup[2]=i1+1;
        end;
        do i2=i11 to bornesup[2];
          dec[3]=i2;
          if nbc>3 then do;
              do i=(i2+1) to mx;
                if ((loi_x[i] - loi_x[i2])>=tre) then  do;
                   yui=i;
                   i=mx;
                end;
              end;
              i11=yui;
              end;
          else do ;
               i11=i2+1;
               bornesup[3]=i2+1;
          end;
          do i3=i11 to bornesup[3];
            dec[4]=i3;
            if nbc>4 then do;
                do i=(i3+1) to mx;
                  if ((loi_x[i] - loi_x[i3])>=tre) then  do;
                     yui=i;
                     i=mx;
                  end;
                end;
                i11=yui;
                end;
            else do ;
                 i11=i3+1;
                 bornesup[4]=i3+1;
            end;
            do i4=i11 to bornesup[4];
              dec[5]=i4;
              if nbc>5 then do;
                  do i=(i4+1) to mx;
                    if ((loi_x[i] - loi_x[i4])>=tre) then  do;
                       yui=i;
                       i=mx;
                    end;
                  end;
                  i11=yui;
                  end;
              else do ;
                   i11=i4+1;
                   bornesup[5]=i4+1;
              end;
              do i5=i11 to bornesup[5];
                dec[6]=i5;
                if nbc>6 then do;
                    do i=(i5+1) to mx;
                      if ((loi_x[i] - loi_x[i5])>=tre) then  do;
                         yui=i;
                         i=mx;
                      end;
                   end;
                    i11=yui;
                    end;
                else do ;
                     i11=i5+1;
                     bornesup[6]=i5+1;
                end;
                do i6=i11 to bornesup[6];
                 dec[7]=i6;
                  if nbc>7 then do;
                      do i=(i6+1) to mx;
                        if ((loi_x[i] - loi_x[i6])>=tre) then  do;
                           yui=i;
                           i=mx;
                        end;
                      end;
                      i11=yui;
                      end;
                  else do ;
                       i11=i6+1;
                       bornesup[7]=i6+1;
                  end;
                  do i7=i11 to bornesup[7];
                     dec[8]=i7;
                     dec[nbc+1]=mx;

                     * Calcul du tableau independant tindep[i,j] *;
                     do i=1 to nbc;
                         do j=1 to mz;
                           if i=1 then tindep[i,j]=(loi_x[dec[2]])*loi_z[j]/ntot;
                           else if i=nbc then tindep[i,j]=(loi_x[mx]-loi_x[dec[i]])*loi_z[j]/ntot;
                                else tindep[i,j]=(loi_x[dec[i+1]]-loi_x[dec[i]])*loi_z[j]/ntot;
                          end;
                     end;

                     * Calcul du chi2 *;
                     chi2=0;
                     do i=1 to nbc;
                         do j=1 to mz;
                            if i=1 then chi2=chi2+((treel[dec[2],j]-tindep[i,j])##2)/tindep[i,j];
                            else if i=nbc then chi2=chi2+((treel[mx,j]-treel[dec[i],j]-tindep[i,j])##2)/tindep[i,j];
                                else chi2=chi2+((treel[dec[i+1],j]-treel[dec[i],j]-tindep[i,j])##2)/tindep[i,j];
                         end;
                     end;

                     * Si meilleur chi2 alors stockage des caracteristiques *;
                     if chi2>chi2_opt[nbc-1,2] then do;
                       chi2_opt[nbc-1,2]=chi2;
                       do i=1 to nbc+1;
                         dec_opt[i]=dec[i];
                       end;
                     end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;


* Calculs d indicateurs statistiques  : pearson tschuprow cramer *;
    chi2_opt[nbc-1,1]=nbc;
	chi2_opt[nbc-1,3]=sqrt(chi2_opt[nbc-1,2]/(ntot+chi2_opt[nbc-1,2]));
	chi2_opt[nbc-1,4]=sqrt(chi2_opt[nbc-1,2]/(ntot*sqrt((nbc-1)*(mz-1))));
    chi2_opt[nbc-1,5]=nbc-1; if mz<nbc then chi2_opt[nbc-1,5]=mz-1;
	chi2_opt[nbc-1,5]=sqrt(chi2_opt[nbc-1,2]/(ntot*chi2_opt[nbc-1,5]));


      bornes=j(nbc,4,0);
      do i=1 to nbc;
        bornes[i,1]=bfinfin[dec_opt[i]+1];
        if legal[dec_opt[i]+1]=0 then bornes[i,2]=1;
                                 else bornes[i,2]=0;
        bornes[i,3]=bfsupin[dec_opt[i+1]];
        if egal[dec_opt[i+1]]=0 then bornes[i,4]=0;
                                 else bornes[i,4]=1;
      end;
      if nbc=2 then do;
        create ZZBOR2 from bornes[colname=varname];
        append from bornes;
        close ZZBOR2;
      end;
      if nbc=3 then do;
        create ZZBOR3 from bornes[colname=varname];
        append from bornes;
        close ZZBOR3;
      end;
      if nbc=4 then do;
        create ZZBOR4 from bornes[colname=varname];
        append from bornes;
        close ZZBOR4;
      end;
      if nbc=5 then do;
        create ZZBOR5 from bornes[colname=varname];
        append from bornes;
        close ZZBOR5;
     end;
      if nbc=6 then do;
        create ZZBOR6 from bornes[colname=varname];
        append from bornes;
        close ZZBOR6;
      end;
      if nbc=7 then do;
        create ZZBOR7 from bornes[colname=varname];
        append from bornes;
        close ZZBOR7;
      end;
      if nbc=8 then do;
        create ZZBOR8 from bornes[colname=varname];
        append from bornes;
        close ZZBOR8;
      end;
    end;

  * fin de la boucle sur nbc *;

* Creation d une table SAS contenant les indicateurs statistiques *;
    create ZZSTAT from chi2_opt[colname=chi2name];
    append from chi2_opt;
    close ZZSTAT;
  QUIT;

* fin de IML *;

* Impression des statistisques de comparaison *;
  proc print data=ZZSTAT noobs;
  title1 "MEILLEUR(S) DECOUPAGE(S) DE LA VARIABLE &x";
  title2 "NOMBRE DE QUANTILES = &nbquant";
  title3 "POURCENTAGE SEUIL PAR CLASSE = &pc_seuil %";  run;  title;

  * Construction des formats associes aux meilleurs decoupages *;
  %do i=2 %to %eval(&nbdec);

  * Creation des variables macro associees aux bornes inf et sup *;
    data _null_;
      set ZZBOR&i;
      if infe=supe then egal=0;
                   else egal=1;
      poi=lag(egal);
      if _n_=1 then lag_ega=1;
               else lag_ega=poi;
      %do j=1 %to %eval(&i);
        if _N_ = &j then do;
          call symput("infe&j",left(infe));
          call symput("supe&j",left(supe));
          call symput("infin&j",left(put(infin,1.)));
          call symput("supin&j",left(put(supin,1.)));
        end;
      %end;
    run;

  * Creation des formats associes au decoupage optimal avec les bornes *;
  proc format library=work;
   value &form.&i.a
       %if &supin1=0  %then %do;
                         low-&supe1="<-%left(%trim(&supe1))"
                            %end;
                      %else %do;
                         low-<&supe1="<-<%left(%trim(&supe1))"
                            %end;
     %do k=2 %to %eval(&i-1);
        %if &&infin&k=0 and &&supin&k=0 %then %do;
			&&infe&k-&&supe&k="%left(%trim(&&infe&k))-%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=0 and &&supin&k=1 %then %do;
			&&infe&k-<&&supe&k="%left(%trim(&&infe&k))-<%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=1 and &&supin&k=0 %then %do;
			&&infe&k<-&&supe&k="%left(%trim(&&infe&k))<-%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=1 and &&supin&k=1 %then %do;
			&&infe&k<-<&&supe&k="%left(%trim(&&infe&k))<-<%left(%trim(&&supe&k))"
            %end;
     %end;
     %if &&infin&i=0  %then %do;
            &&infe&i-high="%left(%trim(&&infe&i))-<"
          %end;
     %else %do;
            &&infe&i<-high="%left(%trim(&&infe&i))<-<" 
		  %end;
     ;
 run;
 proc format library=work;
   value formopt
       %if &supin1=0  %then %do;
                         	low-&supe1="<-%left(%trim(&supe1))"
                            %end;
                      %else %do;
                         	low-<&supe1="<-<%left(%trim(&supe1))"
                            %end;
     %do k=2 %to %eval(&i-1);
        %if &&infin&k=0 and &&supin&k=0 %then %do;
			&&infe&k-&&supe&k="%left(%trim(&&infe&k))-%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=0 and &&supin&k=1 %then %do;
			&&infe&k-<&&supe&k="%left(%trim(&&infe&k))-<%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=1 and &&supin&k=0 %then %do;
			&&infe&k<-&&supe&k="%left(%trim(&&infe&k))<-%left(%trim(&&supe&k))"
            %end;
       %if &&infin&k=1 and &&supin&k=1 %then %do;
			&&infe&k<-<&&supe&k="%left(%trim(&&infe&k))<-<%left(%trim(&&supe&k))"
            %end;
     %end;
     %if &&infin&i=0  %then %do;
         &&infe&i-high="%left(%trim(&&infe&i))-<"
         %end;
     %else %do;
         &&infe&i<-high="%left(%trim(&&infe&i))<-<"     %end;
     ;
 run;

* Creation du format pour le codage en variable modale *;
 proc format library=work;
   value &form.&i.c
       %if &supin1=0  %then %do;
                         	low-&supe1=&form.1
                            %end;
                      %else %do; 
							low-<&supe1=&form.1
                            %end;
     %do k=2 %to %eval(&i-1);
        %if &&infin&k=0 and &&supin&k=0 %then %do;
                     &&infe&k-&&supe&k=&form.&k
            %end;
        %if &&infin&k=0 and &&supin&k=1 %then %do;
                     &&infe&k-<&&supe&k=&form.&k
            %end;
        %if &&infin&k=1 and &&supin&k=0 %then %do;
                     &&infe&k<-&&supe&k=&form.&k
            %end;
        %if &&infin&k=1 and &&supin&k=1 %then %do;
                     &&infe&k<-<&&supe&k=&form.&k
            %end;
     %end;

     %if &&infin&i=0  %then %do;
            &&infe&i-high=&form.&i
          %end;
     %else %do;
            &&infe&i<-high=&form.&i     %end;
     ;
 run;

* Creation du format associe a la variable modale *;
 proc format library=work;
   value &form.&i.n
      %if &supin1=0  %then %do;
                         1="<-%left(%trim(&supe1))"
                            %end;
                      %else %do;
                         1="<-<%left(%trim(&supe1))"
                            %end;
     %do k=2 %to %eval(&i-1);
        %if &&infin&k=0 and &&supin&k=0 %then %do;
            &k="%left(%trim(&&infe&k))-%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=0 and &&supin&k=1 %then %do;
            &k="%left(%trim(&&infe&k))-<%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=1 and &&supin&k=0 %then %do;
            &k="%left(%trim(&&infe&k))<-%left(%trim(&&supe&k))"
            %end;
        %if &&infin&k=1 and &&supin&k=1 %then %do;
            &k="%left(%trim(&&infe&k))<-<%left(%trim(&&supe&k))"
            %end;
     %end;
     %if &&infin&i=0  %then %do;
          &i="%left(%trim(&&infe&i))-<"
          %end;
     %else %do;
          &i="%left(%trim(&&infe&i))<-<"
     %end;
     ;
 run;

* Creation du tableau croise associe au meilleur decoupage *;
 proc freq data=&tab_in;
      format &x formopt.
         %if %length(&fz) ne 0 %then %do;
             &z &fz..
         %end;
      ;
      weight &w;
      table &x*&z / chisq;
 run;

* Nettoyage de la table des bornes et du format *;
    proc datasets lib=work memtype=(data catalog) nolist;
    *  delete FORMATS / memtype=catalog; *;
        delete ZZBOR&i / memtype=data;
    run;
  %end;

* Nettoyage des tables temporaires *;
  proc datasets lib=work memtype=data nolist;
    delete ZZBORNES  ZZFIN ZZSTAT ess ess2;
  quit;

%mend;



***********************************************;
*                 MACRO DECMRH              *;
***********************************************;

*** Attention definir une macro liste contenant les variables quanti à decouper;

%macro decmrh(tab_in,vbquanti,z,fz,w,nbquant,clas,pc_seuil,form);

*** NOMBRE DE VARIABLES EXPLICATIVES ET MACROS VARIABLES;

data temp1; set &tab_in(keep=&vbquanti obs=1); run;

proc transpose data=temp1 out=temp2 prefix=v; var &vbquanti; run;

data _null_;
  set temp2 end=fin;
  call symput ('var'!!left(_n_),_name_);
  if fin then call symput('nbc',left(_n_));
run;

* Recherche des decoupages optimaux pour chaque variable *;

 %do ut=1 %to &nbc;
    %decoup(&tab_in,&&var&ut,&z,&fz,&w,&nbquant,&clas,&pc_seuil,&form);
 %end;


%mend decmrh;




/*************************/
/* LANCEMENT DE LA MACRO */
/*************************/

%decmrh(df,&liste1,we18,,poids,20,4,5,form);

title;

/* suppression table inutile */

proc sql;
	drop table work.temp1;
	drop table work.temp2;
	drop table work.TABLE_CIBLE;
quit;
