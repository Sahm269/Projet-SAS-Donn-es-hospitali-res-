options validvarname=any;

/* Dossier contenant les codes SAS */
/* %let code_path=/home/u63636319/Hopital/Code/; */
/* %include "&code_path/sortem.sas"; */

/* Dossier contenant les données hopital */
%let file_path=/home/u63636319/Hopital/Donnees;

/* Dossier SAS Studio où vont être sauvegarder les tables après import */
libname donnees "/home/u63636319/Hopital/Donnees/";

/* 1°) Importez les données et familiarisez-vous avec les données.  */
%macro import_tables(annee);

libname DATA&annee. XLSX "&file_path/Hospi_&annee..xlsx";

data DATA&annee._Etablissement; 
	set DATA&annee..Etablissement; 
	run;

data DATA&annee._Lit_Places; 
	set DATA&annee.."Lits et Places"n;
	run;

proc sort data=DATA&annee._lit_places; by finess; run;

proc transpose data=DATA&annee._Lit_Places out=DATA&annee._Lit_Places(drop=_NAME_ keep=finess CI_AC1 CI_AC6 CI_AC8) ;
	by finess;
	id Indicateur;
	var Valeur;
	run;

data DATA&annee._Activite_Globale;
	set DATA&annee.."Activité Globale"n (keep=finess CI_A3 CI_A6 CI_A11 CI_A9 CI_E6 CI_RH5 P3 P10 P11 RH1 RH6 RH9);
	run;

proc sort data=DATA&annee._Etablissement;    by finess; run;
proc sort data=DATA&annee._Lit_Places;       by finess; run;
proc sort data=DATA&annee._Activite_Globale; by finess; run;

data donnees.DATA&annee.;
	merge DATA&annee._Etablissement 
		  DATA&annee._Lit_Places 
		  DATA&annee._Activite_Globale;
	by finess;
	run;
	
data donnees.DATA&annee.;
	set donnees.DATA&annee. (keep=finess rs	cat	taille_MCO taille_M taille_C taille_O CI_AC1 CI_AC6 CI_AC8 CI_A3 CI_A6 CI_A11 CI_A9 CI_E6 CI_RH5 P3 P10 P11 RH1 RH6 RH9
							 rename=(CI_AC1=_CI_AC1 CI_AC6=_CI_AC6 CI_AC8=_CI_AC8 CI_A3=_CI_A3 CI_A6=_CI_A6 CI_A11=_CI_A11 CI_A9=_CI_A9  CI_E6=_CI_E6  CI_RH5=_CI_RH5  P3=_P3  P10=_P10  P11=_P11  RH1=_RH1  RH6=_RH6 RH9=_RH9));
	array vars_prefix_int {9} _CI_AC1 _CI_AC6 _CI_AC8 _CI_A3 _CI_A6 _CI_A11 _CI_A9 _CI_E6 _RH1;
	array vars_int {9} CI_AC1 CI_AC6 CI_AC8 CI_A3 CI_A6 CI_A11 CI_A9 CI_E6 RH1/* que des integers */; 
	* CI_RH5 4.2 P3 4.3 P10 4.2 P11 4.2 RH6 2.1/* que des nombre à virgues */;
  
	do i=1 to dim(vars_prefix_int);
			vars_int{i} = input(vars_prefix_int{i}, 7.);
			if vars_int{i}=. then vars_int{i}=0;
	end;
	
    /* OBLIGATOIRE IF ELSE CAR SAS EST CODE AVEC LE CUL*/
    /* Si juste input numx4.2 alors 24 devient 0.24 et 18.52 devient 18.52*/
   

	if find(_CI_RH5,',') then CI_RH5 = input(compress(CI_RH5), numx4.2);
	                     else CI_RH5 = input(compress(_P10), numx2.);
	if find(_P3,',')     then P3     = input(compress(_P3), numx4.3);
	                     else P3     = input(compress(_P3), numx1.);
	if find(_P10,',')    then P10    = input(compress(_P10), numx5.2);
	                     else P10    = input(compress(_P10), numx3.);
	if find(_P11,',')    then P11    = input(compress(_P11), numx4.2);
	                     else P11    = input(compress(_P11), numx2.);
	if find(_RH6,',')    then RH6    = input(compress(_RH6), numx4.1);
	                     else RH6    = input(compress(_RH6), numx3.);
	if find(_RH9,',')    then RH9    = input(compress(_RH9), numx3.1);
	                     else RH9    = input(compress(_RH9), numx2.);


	CI_AC1_6_8 = CI_AC1+CI_AC6+CI_AC8; /* Nombre de lit installées médecine+chirurgie+obstétrie */
	
	annee=&annee.;
	
/* 	7°) Les deux premiers caractères du N° finess correspondent au département. Indiquez le nombre */
/*      d’établissement par catégorie (cat) par région. */
	departement=substr(finess,1,2);
	length region $20;
	if departement in ('01','03','07','15','26','38','42','43','63','69','73','74') then region = "Auvergne-Rhône-Alpes";
	if departement in ('75','77','78','91','92','93','94','95') then region = "Île-de-France" ;
	if departement in ('04','05','06','13','83','84') then region = "Provence-Alpes-Côte d'Azur";
	if departement in ('16','17','19','23','24','33','40','47','64','79','86','87') then region = "Nouvelle-Aquitaine";
	if departement in ('09','11','12','30','31','32','34','46','48','65','66','81','82') then region = "Occitanie";
	if departement in ('08','10','51','52','54','55','57','67','68','88') then region = "Grand Est";
	if departement in ('44','49','53','72','85') then region = "Pays de la Loire";
	if departement in ('21','25','39','58','70','71','89','90') then region = "Bourgogne-Franche-Comté";
	if departement in ('18','28','36','37','41','45') then region = "Centre-Val de Loire";
	if departement in ('22','29','35','56') then region = "Bretagne";
	if departement in ('14','27','50','61','76') then region = "Normandie";
	if departement in ('02','59','60','62','80') then region =" Hauts-de-France";

	drop _: i;
	run;
	
%mend import_tables;

%import_tables(annee=2017);
%import_tables(annee=2018);
%import_tables(annee=2019);

/* Supprimer la work pour ne garder que les tables dans donnees */
proc datasets library=work kill nolist;
	quit;

/* 3°) En 2019, existe-il des établissements nouveaux ou non présents par rapport à 2018 et / ou 2017 ? */
data nouveaux_etablissements_2018 
	 nouveaux_etablissements_2019;
	 merge donnees.data2017(keep=finess in=A) 
	       donnees.data2018(keep=finess in=B) 
	       donnees.data2019(keep=finess in=C);
	 by finess;
	 if B and not A then output nouveaux_etablissements_2018;
	 if C and not B then output nouveaux_etablissements_2019;
	 run;
	 
/* 4°) Est-ce que certains établissements ont changé de taille (taille_MCO , taille_M, Taille_C et taille_O) */
/*     sur la période 2017-2019 ? */
data changement_taille_2018 
	 changement_taille_2019;
	 merge donnees.data2017(keep=finess taille_MCO taille_M taille_C taille_O rename=(taille_MCO=taille_MCO_2017 taille_M=taille_M_2017 taille_C=taille_C_2017 taille_O=taille_O_2017)) 
	       donnees.data2018(keep=finess taille_MCO taille_M taille_C taille_O rename=(taille_MCO=taille_MCO_2018 taille_M=taille_M_2018 taille_C=taille_C_2018 taille_O=taille_O_2018)) 
	       donnees.data2019(keep=finess taille_MCO taille_M taille_C taille_O rename=(taille_MCO=taille_MCO_2019 taille_M=taille_M_2019 taille_C=taille_C_2019 taille_O=taille_O_2019));
	 by finess;
	 if taille_MCO_2017 NE taille_MCO_2018
	 OR taille_M_2017 NE taille_M_2018
	 OR taille_C_2017 NE taille_C_2018
	 OR taille_O_2017 NE taille_O_2018
	 then output changement_taille_2018;
	 
	 if taille_MCO_2019 NE taille_MCO_2018
	 OR taille_M_2019 NE taille_M_2018
	 OR taille_C_2019 NE taille_C_2018
	 OR taille_O_2019 NE taille_O_2018
	 then output changement_taille_2019;
	 run;

/* Est-ce que des établissements ont changé d’activité ? */
data changement_activite_2018 
	 changement_activite_2019;
	 merge donnees.data2017(keep=finess cat rename=(cat=cat_2017)) 
	       donnees.data2018(keep=finess cat rename=(cat=cat_2018)) 
	       donnees.data2019(keep=finess cat rename=(cat=cat_2019));
	 by finess;
	 if cat_2017 NE cat_2018
	 then output changement_activite_2018;
	 
	 if cat_2019 NE cat_2018
	 then output changement_activite_2019;
	 run;


/* 5°) A l’aide du nombre de lits, essayez de déterminer quels sont les seuils qui ont été utilisés pour */
/*     constituer les variables taille_M, taille_C et taille_O (variables catégorielles). Justifiez votre */
/*     raisonnement. */
%macro stats_taille(var_nb_lit, taille);

PROC SORT DATA=donnees.DATA2017 out=DATA2017_sorted_cat; BY &taille. ; RUN;

PROC MEANS DATA=DATA2017_sorted_cat NOPRINT;
VAR &var_nb_lit.;
BY &taille.;
OUTPUT OUT=min_max_place_&taille. (drop=_TYPE_ _FREQ_);
RUN;

%mend stats_taille;

%stats_taille(var_nb_lit=CI_AC1_6_8,taille=taille_MCO); /* Nombre de lit installées médecine+chirurgie+obstétrie */
%stats_taille(var_nb_lit=CI_AC1,taille=taille_M);       /* Nombre de lit installées médecine */
%stats_taille(var_nb_lit=CI_AC6,taille=taille_C);       /* Nombre de lit installées chirurgie */
%stats_taille(var_nb_lit=CI_AC8,taille=taille_O);       /* Nombre de lit installées obstétrie */
/* En ayant le minimum et maximum de chaque catégorie cela nous permet de distinger les bornes constituant les tailles.*/


/* 6°) Indiquez dans un tableau croisé par catégorie d’établissement (cat) et par année, le nombre */
/*     d’établissement, le nombre de lits en MCO en détaillant par Médecine / Chirurgie / Obstétrique. */
DATA donnees.All_DATA;
	set donnees.data2017 donnees.data2018 donnees.data2019;
	run;
	
PROC SORT DATA=donnees.All_DATA out=All_DATA_sorted; BY cat annee; RUN;

PROC TABULATE data=All_DATA_sorted;
	class cat annee;
	var CI_AC1_6_8 CI_AC1 CI_AC6 CI_AC8;
	table cat * annee, (CI_AC1_6_8 CI_AC1 CI_AC6 CI_AC8)  * (N sum);
	label CI_AC1_6_8="Nb lit MCO" CI_AC1="Nb lit M" CI_AC6="Nb lit C" CI_AC8="Nb lit O" cat="Catégorie" annee="Année";
	run;


/* 	7°) Les deux premiers caractères du N° finess correspondent au département. Indiquez le nombre */
/*      d’établissement par catégorie (cat) par région. */
PROC SORT DATA=donnees.data2017 out=DATA2017_sorted; BY cat region; RUN;

PROC TABULATE data=DATA2017_sorted;
	class cat region;
	table cat * region, N;
	run;

/* 8°) Indiquez dans un tableau le nombre d’accouchement, le nombre de lit d’obstétrique par catégorie */
/*     d’établissement (cat) et par niveau de maternité. */
/*     Ce tableau n’a de sens que pour les établissements pratiquant des actes d’obstétrique */
PROC SORT DATA=donnees.All_DATA out=All_DATA_sorted; BY cat annee CI_E6; RUN;

PROC TABULATE data=All_DATA_sorted (where=(CI_A11 > 0));
	class cat annee CI_E6;
	var CI_A11 CI_AC8;
	table cat * CI_E6 * annee, (CI_A11 CI_AC8)  * (sum);
	label CI_AC8="Nombre de lit installées en obstétrie" CI_A11="Nombre d'accouchements" CI_E6="Niveau de maternité" cat="Catégorie" annee="Année";
	run;

/* Quels sont les 5 établissements avec la plus forte activité d’obstétrique ? */
proc sql outobs=5;
create table top5_etablissement as
select finess,rs, sum(CI_A11) as total_accouchement
from All_DATA_sorted
group by finess, rs
order by 3 desc;
quit;

/* 9°) Résumez les indicateurs de la question 8 par région. Indiquez également le nombre min et max */
/*     d’accouchement. */
PROC SORT DATA=donnees.All_DATA out=All_DATA_sorted; BY region annee CI_E6; RUN;

PROC TABULATE data=All_DATA_sorted (where=(CI_A11 > 0));
	class region annee;
	var CI_A11 CI_AC8;
	table region * annee, (CI_A11 CI_AC8)  * (sum min max);
	label CI_AC8="Nombre de lit installées en obstétrie" CI_A11="Nombre d'accouchements" CI_E6="Niveau de maternité" cat="Catégorie" annee="Année";
	run;

*##############################################;
/* Scoring */
/* 10°) A l’aide de variables présentes dans le fichier essayez de calculer un score de « qualité » pour les */
/*      accouchements (obstétrique) afin de classer les établissements. Justifiez le calcul de votre score et */
/*      proposez une interprétation de votre score. */

*Score = 
(<Nombre de sages-femmes par obstétricien> (RH6) - min <Nombre de sages-femmes par obstétricien> (RH6)) / (max <Nombre de sages-femmes par obstétricien> (RH6) - min <Nombre de sages-femmes par obstétricien> (RH6))
+
(<lits en obtetrique> (CI_AC8) - min <lits en obtetrique> (CI_AC8)) / (max <lits en obtetrique> (CI_AC8) - min <lits en obtetrique> (CI_AC8))
+
(max( <turn-over global>(RH9)) -  <turn-over global>(RH9))/ (max( <turn-over global>(RH9)) - min( <turn-over global>(RH9))
;

/* RH7 non ajouté par manque de données */
/* (max <nb d'heures moyen travaillé> (RH7) - <nb d'heures moyen travaillé> (RH7))/(max <nb d'heures moyen travaillé> (RH7) - min <nb d'heures moyen travaillé> (RH7)) */
/* proc sql;  */

/* %global RH7_max RH7_min; */
/* 	SELECT max(RH7), min(RH7) INTO :RH7_max, :RH7_min FROM donnees.All_DATA; */
/* RH7 n'est pas renseigné dans les données */


proc sql; 
%global RH6_max RH6_min;
	SELECT max(RH6), min(RH6) INTO :RH6_max, :RH6_min FROM donnees.All_DATA;
quit;

proc sql; 
%global CI_AC8_max CI_AC8_min;
	SELECT max(CI_AC8), min(CI_AC8) INTO :CI_AC8_max, :CI_AC8_min FROM donnees.All_DATA;
quit;

proc sql; 
%global RH9_max RH9_min;
	SELECT max(RH9), min(RH9) INTO :RH9_max, :RH9_min FROM donnees.All_DATA;
quit;


proc sort data=donnees.all_data(keep=finess rs annee region RH6 CI_AC8 RH9) out= All_DATA_sorted;
	by finess annee;
run;

data scoring;
	set All_DATA_sorted;

	score_RH6    = (RH6 - &RH6_min) / (&RH6_max - &RH6_min);
	score_CI_AC8 = (CI_AC8 - &CI_AC8_min) / (&CI_AC8_max - &CI_AC8_min);
	score_RH9    = (&RH9_max - RH9) / (&RH9_max - &RH9_min);
	
	score = score_RH6 + score_CI_AC8 + score_RH9;
	
	drop RH6 CI_AC8 RH9;
run;


/* A l’aide de votre score, indiquez quels sont les 5 meilleurs et 5 moins bons établissements. */
/* 5 meilleurs établissements */
proc sql outobs=5;
create table top5_etablissement_scoring as
select finess, rs, avg(score) as moy_score
from scoring
group by finess, rs
order by 3 desc;
quit;

/* 5 pires établissements */
proc sql outobs=5;
create table top5_etablissement_scoring as
select finess, rs, avg(score) as moy_score
from scoring
where score ne .
group by finess, rs
order by 3;
quit;


/* 11°) Etudiez la stabilité de votre score sur les années 2017, 2018 et 2019. Par exemple, constatez-vous */
/*      que les établissements qui ont un score qui n’est pas stable s’accompagne de changement dans les */
/*      activités et les structures ? De même, une stabilité dans le score doit se traduire par une stabilité dans */
/*      les activités et les structures. Donnez des exemples concrets */
proc sort data=scoring out=evolution_scoring(where=(score ne .) keep=finess rs annee score);
	by finess rs annee;
run;

data evolution_brutale_scoring;
	merge evolution_scoring(where=(annee=2017) keep=finess score annee rename=(score=score_2017) in=A)
		  evolution_scoring(where=(annee=2018) keep=finess score annee rename=(score=score_2018) in=B)
		  evolution_scoring(where=(annee=2019) keep=finess score annee rename=(score=score_2019) in=C);
	by finess;
	if abs(score_2017-score_2018) > 0.2 or abs(score_2018-score_2019) > 0.2;
run;

proc sort data=donnees.all_data;
	by finess;
run;

/* Récupérer toutes les infos concernant les établissements ayant un fort écart de score */
data evolution_brutale_scoring;
	merge evolution_brutale_scoring(in=A)
		  donnees.all_data(in=B);
	by finess;
	if A and B;
run;

/* Récupérer toutes les infos concernant les établissements n'ayant pas un fort écart de score */
data evolution_normale_scoring;
	merge evolution_brutale_scoring(drop=score_2017 score_2018 score_2019 in=A)
		  donnees.all_data(in=B);
	by finess;
	if B and not A;
run;

/* 12°) Calculez votre score par région et par année. Précisez comment vous passez d’un score calculé */
/* par établissement à un score calculé par région / année. Existe-il des différences entre les régions ? */
/* Quelles sont les limites de votre score ? Indiquez comment pourriez-vous l’améliorer ? */

proc sort data=scoring;
	by region annee;
run;

PROC TABULATE data=scoring (where=(score ne .));
	class region annee;
	var score;
	table region * annee , (score)  * (mean);
	run;
