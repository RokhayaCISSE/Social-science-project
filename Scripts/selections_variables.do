												  ************************************
												 *       TP SOCIAL DATA SCIENCE     *
												************************************

global chemin "C:\Users\gnint\OneDrive\Bureau\project_social_science\Raw_data\Fichiers_Menage&Individus\"


**********************Chargez la section 0 *********************************
****************************************************************************

 
use "$chemin\s00_me_SEN2021.dta" , clear

** creer l'identifiant unique des ménages
egen menage_id = group(grappe menage)
duplicates list menage_id // vérifier l'existence des doublons

** voir si un menage est enqueté sur deux vagues
gen vague1 = (vague == 1)
gen vague2 = (vague == 2)
tab vague1 vague2  // c'est bon

** Combien y a-t-il d'observations ? 

tab grappe // nbre de grappe

tab s00q08 // nbre de ménage + ménage de remplacement

tab s00q09 // motif de perte

tab s00q07d // menage enqueté en 2019

tab s00q08 s00q07d // menage enqueté en 2019 sans remplacement

** milieu de residence
codebook s00q04




**********************Chargez la section 1; caractéristique sociodémagraphiques des ménages *********************************
**************************************************************

use "$chemin\s01_me_SEN2021.dta" , clear

describe

** creer l'identifiant unique des individus
egen menage_id = group(grappe menage)
egen individu_id = group(grappe menage s01q00a)
duplicates list individu_id

** variable age


*** age à partir de la date de naissance

codebook s01q03c // on a 20,046 NA

count if s01q03c==. & s01q04a==. // dont 15202 n'ont pas déclaré leur age

// en effet ces individus (15202) sont ceux qui n'ont plus dans le ménages au moments de l'enquête:

 tab s01q00aa, missing

// on les supprime car aucune info par la suite dans cette section
 
 drop if s01q00aa==2
 
 // traitement des 4844 restants : on fait fois à la date de naissance
		
		// pour les NA de date de naissance on remplace par l'info de l'age


gen age= s01q04a 

replace age= 2022- s01q03c +1 if s01q03c!=.  

codebook age 
 
*** recherche de la coherence de l'age



 
**** en utilisant le lien avec le CM

//Étape 1 : Créer une variable qui garde l'âge du CM
gen age_cm = . 
bysort s01q02: replace age_cm = age if s01q02 == 1

//Étape 2 : Propager l'âge du CM aux enfants (lienn == 3)
bysort menage_id (s01q02): replace age_cm = age_cm[_n-1] if s01q02 == 3

// Étape 3 : Vérifier si l'âge de l'enfant est supérieur à celui du CM
gen enfant_plus_age = (age > age_cm) & s01q02 == 3

//Étape 4 : Filtrer les résultats

codebook enfant_plus_age // il n'ya pas d'enfnat du CM qui soit plus agé que le CM




**** en regardant si son père est dans le ménage s01q22 s01q23 

codebook s01q22 // 24103 vivent avec leur père

* Étape 1 : Créer une copie de la base pour l'auto-jointure
preserve

* Ne garder que les individus qui sont des pères (c'est-à-dire ceux dont l'ID peut être utilisé pour lier aux enfants)
keep if s01q22 == 1  // Ne garder que ceux dont le père est présent
keep menage_id s01q00a age  // Garder seulement les variables nécessaires

* Renommer pour préparer la jointure
rename s01q00a s01q23   // On renomme pour que s01q23 corresponde à l'ID du père
rename age age_pere        // On renomme l'âge pour éviter les conflits lors du merge

* Sauvegarder temporairement cette base des pères
tempfile fathers
save `fathers'

restore  // Revenir à la base initiale

* Étape 2 : Faire une jointure pour récupérer l'âge du père

preserve
merge m:1 menage_id s01q23 using `fathers', keep(match master) nogen

* Étape 3 : Comparer l'âge de l'enfant avec celui du père
*drop enfant_plus_age_pere
gen enfant_plus_age_pere = (age > age_pere) if s01q29 == 1

* Étape 4 : Afficher les cas où l'enfant est plus âgé que son père
codebook enfant_plus_age_pere // il n'ya pas d'enfant avec son père dans le ménage qui le dépasse en age

/// le plus jeune papa à 15 ans 
restore







**** en regardant si sa mère est dans le ménage s01q29 s01q30

codebook s01q29 // 24103 vivent avec leur mère


* Étape 1 : Créer une copie de la base pour l'auto-jointure
preserve

* Ne garder que les individus qui sont des mères (c'est-à-dire ceux dont l'ID peut être utilisé pour lier aux enfants)
keep if s01q29 == 1  // Ne garder que ceux dont le mère est présent
keep menage_id s01q00a age  // Garder seulement les variables nécessaires

* Renommer pour préparer la jointure
rename s01q00a s01q30   // On renomme pour que s01q30 corresponde à l'ID du père
rename age age_mere        // On renomme l'âge pour éviter les conflits lors du merge

* Sauvegarder temporairement cette base des mères
tempfile mothers
save `mothers'

restore  // Revenir à la base initiale

* Étape 2 : Faire une jointure pour récupérer l'âge du père

preserve
merge m:1 menage_id s01q30 using `mothers', keep(match master) nogen

* Étape 3 : Comparer l'âge de l'enfant avec celui du père
//drop enfant_plus_age_mere
gen enfant_plus_age_mere = (age > age_mere) if s01q29 == 1

* Étape 4 : Afficher les cas où l'enfant est plus âgé que sa mère
codebook enfant_plus_age_mere // il n'ya pas d'enfant avec sa mère dans le ménage qui le dépasse en age

/// la plus jeune maman à 13 ans 
restore




















********************************************************************************************************************************************
********************************************************************

** selection des individus dans la base
********************************************************************************************************************************************
*********************************************************************



 
 
 
 
 **********************Chargez la section 1*********************************

*********************** recuperer les variables dans la section 0 *****
preserve  // Sauvegarde temporaire de l'état initial


use "$chemin\ehcvm_ponderations_SEN2021.dta", clear

keep grappe menage poids
* Sauvegarde temporaire
tempfile sectionPOIDS_temp
save `sectionPOIDS_temp'

use "$chemin\s00_me_SEN2021.dta", clear


* Garder uniquement les variables nécessaires pour le merge

keep grappe menage s00q01 s00q02 s00q04 s00q07b s00q08  // region, dept, milieu de residence,  y vivre depuis moins de 5 ans, resultat interview

merge 1:1 grappe menage using `sectionPOIDS_temp'
* Sauvegarde temporaire
tempfile section0_temp
save `section0_temp'

restore  // Retourne à l'état initial



/***** recuperer les infos sur le pere dans la section 2 et section emploi (4a)pour completer son niveau d'instruction et sa csp dans la section 1

rester dans la section 1 et recuper la situation mat du pere quand il est dans le foyer ainsi que celui de la mère. et aussi une variable de controle est ce que le conjoint vit il dans le ménage pour chaque conjoint. Aussi recuperer ces information pour le CM  
****/




preserve

/////////////////////////// PERE SECTION 2

use "$chemin\s02_me_SEN2021.dta",clear
keep grappe menage s01q00a s02q29 s02q33
* Sauvegarde temporaire de la base de la section 2
tempfile section2_temp
save `section2_temp', replace

use "$chemin\s01_me_SEN2021.dta", clear
keep grappe menage s01q00a s01q07 s01q08 s01q23 s01q25


merge m:1 grappe menage s01q00a using `section2_temp'
// pour merger les deux bases

drop _merge

tempfile section1_info_pere_temp
save `section1_info_pere_temp'


* Dupliquer la base pour isoler les pères

use `section1_info_pere_temp', clear
keep grappe menage s01q00a s01q07 s01q08 s02q29  s02q33 // On garde seulement les variables nécessaires
rename s01q00a s01q23  // Renommer pour fusionner correctement
rename s01q07 s01q07_pere   // Renommer pour éviter conflits
rename s01q08 s01q08_pere   // Renommer pour éviter conflits
rename s02q29 s02q29_pere   // Renommer pour éviter conflits
rename s02q33 s02q33_pere // pour controle apres
save "$chemin\temp_pere.dta", replace


use `section1_info_pere_temp', clear
* Fusionner pour récupérer le niveau d'étude du père
merge m:1 grappe menage s01q23 using "$chemin\temp_pere.dta"

decode s01q25, gen(s01q25_label)
decode s02q29_pere, gen(s02q29_pere_label)

* Mettre à jour s01q25 avec le niveau d’étude du père
replace s01q25_label = s02q29_pere_label if _merge == 3 & s02q29_pere != .

drop if missing(s01q00a)


//encode s01q25_label, gen(s01q25_corrected)
drop s01q25
rename s01q25_label s01q25

keep grappe menage s01q00a s01q07_pere s01q08_pere s01q25 s02q33_pere
tempfile section2_pere_temp
save `section2_pere_temp', replace





/////////////////////////// MERE SECTION 2



use "$chemin\s01_me_SEN2021.dta", clear
keep grappe menage s01q00a s01q07 s01q08 s01q30 s01q32


merge m:1 grappe menage s01q00a using `section2_temp'

drop _merge

tempfile section1_info_mere_temp
save `section1_info_mere_temp'

use `section1_info_mere_temp', clear

* Dupliquer la base pour isoler les mères

keep grappe menage s01q00a s01q07 s01q08 s02q29  s02q33 // On garde seulement les variables nécessaires
rename s01q00a s01q30  // Renommer pour fusionner correctement
rename s01q07 s01q07_mere   // Renommer pour éviter conflits
rename s01q08 s01q08_mere   // Renommer pour éviter conflits
rename s02q29 s02q29_mere   // Renommer pour éviter conflits
rename s02q33 s02q33_mere // pour controle apres
save "$chemin\temp_mere.dta", replace

use `section1_info_mere_temp', clear
* Fusionner pour récupérer le niveau d'étude du mère IIIIK
merge m:1 grappe menage s01q30 using "$chemin\temp_mere.dta"

decode s01q32, gen(s01q32_label)
decode s02q29_mere, gen(s02q29_mere_label)

* Mettre à jour s01q25 avec le niveau d’étude du père
replace s01q32_label = s02q29_mere_label if _merge == 3 & s02q29_mere != .

drop if missing(s01q00a)


//encode s01q25_label, gen(s01q25_corrected)
drop s01q32
rename s01q32_label s01q32

keep grappe menage s01q00a s01q07_mere s01q08_mere s01q32 s02q33_mere
tempfile section2_mere_temp
save `section2_mere_temp', replace


/////////////////////////// PERE SECTION 4A



use "$chemin\s04a_me_SEN2021.dta",clear
keep grappe menage s01q00a s04q18b // juste pour la CSP
* Sauvegarde temporaire
tempfile section4a_temp
save `section4a_temp', replace

use "$chemin\s01_me_SEN2021.dta", clear
keep grappe menage s01q00a s01q23 s01q27


merge m:1 grappe menage s01q00a using `section4a_temp'

drop _merge

tempfile section4_info_pere_temp
save `section4_info_pere_temp'


* Dupliquer la base pour isoler les pères

use `section4_info_pere_temp', clear
keep grappe menage s01q00a s04q18b // On garde seulement les variables nécessaires
rename s01q00a s01q23  // Renommer pour fusionner correctement
rename s04q18b s04q18b_pere   // Renommer pour éviter conflits

save "$chemin\temp_pere.dta", replace


use `section4_info_pere_temp', clear
* Fusionner pour récupérer le niveau d'étude du père
merge m:1 grappe menage s01q23 using "$chemin\temp_pere.dta"

decode s01q27, gen(s01q27_label)
decode s04q18b_pere, gen(s04q18b_pere_label)

* Mettre à jour s01q25 avec le niveau d’étude du père
replace s01q27_label = s04q18b_pere_label if _merge == 3 

drop if missing(s01q00a)


//encode s01q27_label, gen(s01q27_corrected)
drop s01q27
rename s01q27_label s01q27

keep grappe menage s01q00a s01q27 
tempfile section4a_pere_temp
save `section4a_pere_temp', replace


/////////////////////////// MERE SECTION 4



use "$chemin\s01_me_SEN2021.dta", clear
keep grappe menage s01q00a s01q30 s01q32 s01q34


merge m:1 grappe menage s01q00a using `section4a_temp'

drop _merge

tempfile section4_info_mere_temp
save `section4_info_mere_temp'

* Dupliquer la base pour isoler les mères

use `section4_info_mere_temp', clear
keep grappe menage s01q00a s04q18b // On garde seulement les variables nécessaires
rename s01q00a s01q30  // Renommer pour fusionner correctement
rename s04q18b s04q18b_mere   // Renommer pour éviter conflits

save "$chemin\temp_mere.dta", replace

use `section4_info_mere_temp', clear

* Fusionner pour récupérer le niveau d'étude du mère
merge m:1 grappe menage s01q30 using "$chemin\temp_mere.dta"

decode s01q34, gen(s01q34_label)
decode s04q18b_mere, gen(s04q18b_mere_label)

* Mettre à jour s01q34 avec le niveau d’étude du mère
replace s01q34_label = s04q18b_mere_label if _merge == 3 

drop if missing(s01q00a)


//encode s01q27_label, gen(s01q27_corrected)
drop s01q34
rename s01q34_label s01q34

keep grappe menage s01q00a s01q34 
tempfile section4a_mere_temp
save `section4a_mere_temp', replace




******************* recupererles variables faut dans la section 1 ****




use "$chemin\s01_me_SEN2021.dta", clear
* Créer menage_id
egen menage_id = group(grappe menage)
egen individu_id = group(grappe menage s01q00a)

* suppression des ind qui ne sont pas dans le menages au moment de l'enquête : on les supprime car aucune info par la suite dans cette section
 
 drop if s01q00aa==2
 
* creation de la var age
 gen age= s01q04a 

replace age= 2022- s01q03c +1 if s01q03c!=.

* creation age du cm
gen age_cm = . 
bysort s01q02: replace age_cm = age if s01q02 == 1
bysort menage_id (s01q02): replace age_cm = age_cm[_n-1] if s01q02 != 1

* creation sit mat du cm
decode s01q07, gen(s01q07_label)
gen s01q07_cm = ""
bysort s01q02: replace s01q07_cm = s01q07_label if s01q02 == 1
bysort menage_id (s01q02): replace s01q07_cm = s01q07_cm[_n-1] if s01q02 != 1

* creation sit mat du cm
decode s01q08, gen(s01q08_label)
gen s01q08_cm = ""
bysort s01q02: replace s01q08_cm = s01q08_label if s01q02 == 1
bysort menage_id (s01q02): replace s01q08_cm = s01q08_cm[_n-1] if s01q02 != 1


//NB: ON REVIENDRA SI LA SIT MAT DU PERE OU DE LA MERE EST INTERESSANTE  s01q07 s01q08


* conserver les var qui interessent

keep grappe menage s01q00a menage_id individu_id s01q01 s01q02 age age_cm s01q05 s01q07 s01q08 s01q07_cm s01q08_cm s01q14 s01q15 s01q22 s01q23 s01q24 s01q26 s01q29 s01q30 s01q31 s01q33 




* Réaliser le merge avec la base des ménages
//merge m:1 menage_id using `section0_temp' `section2_mere_temp' `section4a_mere_temp' `section2_pere_temp' `section4a_pere_temp'
 
//mon pb commence ici essaye de voir comment tout lier
merge m:1 grappe menage s01q00a using `section2_mere_temp', nogen
merge m:1 grappe menage s01q00a using `section4a_mere_temp', nogen
merge m:1 grappe menage s01q00a using `section2_pere_temp', nogen
merge m:1 grappe menage s01q00a using `section4a_pere_temp', nogen
merge m:1 grappe menage using `section0_temp', nogen

* Vérifier les résultats
//tab _merge

keep if inrange(age, 6, 25)

save "$chemin\sectionO1_select.dta", replace

restore  // Retourne à l'état initial


































/*
***** recuperer les infos sur le Mere dans la section 2 et section emploi pour complter son niveau d'instruction et sa csp dans la section 1****




/////////////////////////// MERE SECTION 2

preserve

use "$chemin\s02_me_SEN2021.dta",clear
keep grappe menage s01q00a s02q29 s02q33
* Sauvegarde temporaire
tempfile section2_temp
save `section2_temp', replace

use "$chemin\s01_me_SEN2021.dta", clear
keep grappe menage s01q00a s01q30 s01q32


merge m:1 grappe menage s01q00a using `section2_temp'

drop _merge

tempfile section1_info_mere_temp
save `section1_info_mere_temp'

use `section1_info_mere_temp', clear

* Dupliquer la base pour isoler les mères

keep grappe menage s01q00a s02q29  s02q33 // On garde seulement les variables nécessaires
rename s01q00a s01q30  // Renommer pour fusionner correctement
rename s02q29 s02q29_mere   // Renommer pour éviter conflits
rename s02q33 s02q33_mere // pour controle apres
save "$chemin\temp_mere.dta", replace

use `section1_info_mere_temp', clear
* Fusionner pour récupérer le niveau d'étude du mère IIIIK
merge m:1 grappe menage s01q30 using "$chemin\temp_mere.dta"

decode s01q32, gen(s01q32_label)
decode s02q29_mere, gen(s02q29_mere_label)

* Mettre à jour s01q25 avec le niveau d’étude du père
replace s01q32_label = s02q29_mere_label if _merge == 3 & s02q29_mere != .

drop if missing(s01q00a)


//encode s01q25_label, gen(s01q25_corrected)
drop s01q32
rename s01q32_label s01q32

keep grappe menage s01q00a s01q32 s02q33_mere
tempfile section2_mere_temp
save `section2_mere_temp', replace
restore



/////////////////////////// MERE SECTION 4


preserve

use "$chemin\s04a_me_SEN2021.dta",clear
keep grappe menage s01q00a s04q18b // juste pour la CSP
* Sauvegarde temporaire
tempfile section4a_temp
save `section4a_temp', replace

use "$chemin\s01_me_SEN2021.dta", clear
keep grappe menage s01q00a s01q30 s01q32 s01q34


merge m:1 grappe menage s01q00a using `section4a_temp'

drop _merge

tempfile section4_info_mere_temp
save `section4_info_mere_temp'

* Dupliquer la base pour isoler les mères

use `section4_info_mere_temp', clear
keep grappe menage s01q00a s04q18b // On garde seulement les variables nécessaires
rename s01q00a s01q30  // Renommer pour fusionner correctement
rename s04q18b s04q18b_mere   // Renommer pour éviter conflits

save "$chemin\temp_mere.dta", replace

use `section4_info_mere_temp', clear

* Fusionner pour récupérer le niveau d'étude du mère
merge m:1 grappe menage s01q30 using "$chemin\temp_mere.dta"

decode s01q34, gen(s01q34_label)
decode s04q18b_mere, gen(s04q18b_mere_label)

* Mettre à jour s01q34 avec le niveau d’étude du mère
replace s01q34_label = s04q18b_mere_label if _merge == 3 

drop if missing(s01q00a)


//encode s01q27_label, gen(s01q27_corrected)
drop s01q34
rename s01q34_label s01q34

keep grappe menage s01q00a s01q34 
tempfile section4a_mere_temp
save `section4a_mere_temp', replace
restore













******************* recupererles variables faut dans la section 1 ****






preserve  // Sauvegarde temporaire de l'état initial

use "$chemin\s01_me_SEN2021.dta", clear
* Créer menage_id
egen menage_id = group(grappe menage)
egen individu_id = group(grappe menage s01q00a)

* suppression des ind qui ne sont pas dans le menages au moment de l'enquête : on les supprime car aucune info par la suite dans cette section
 
 drop if s01q00aa==2
 
* creation de la var age
 gen age= s01q04a 

replace age= 2022- s01q03c +1 if s01q03c!=.

* creation age du cm
gen age_cm = . 
bysort s01q02: replace age_cm = age if s01q02 == 1
bysort menage_id (s01q02): replace age_cm = age_cm[_n-1] if s01q02 != 1

* creation sit mat du cm

gen sitmat_cm = . 
bysort s01q02: replace sitmat_cm = s01q07 if s01q02 == 1
bysort menage_id (s01q02): replace sitmat_cm = sitmat_cm[_n-1] if s01q02 != 1









//NB: ON REVIENDRA SI LA SIT MAT DU PERE OU DE LA MERE EST INTERESSANTE  s01q07 s01q08


* conserver les var qui interessent

keep menage_id individu_id s01q01 s01q02 age age_cm s01q05 s01q07 s01q08 s01q14 s01q15 s01q22 s01q23 s01q24 s01q26 s01q29 s01q30 s01q31 s01q33 




* Réaliser le merge avec la base des ménages
//merge m:1 menage_id using `section0_temp' `section2_mere_temp' `section4a_mere_temp' `section2_pere_temp' `section4a_pere_temp'
 
mon pb commence ici essaye de voir comment tout lier
merge m:1 grappe menage s01q00a using `section2_mere_temp', nogen
merge m:1 menage_id using section4a_mere_temp, nogen
merge m:1 menage_id using section2_pere_temp, nogen
merge m:1 menage_id using section4a_pere_temp, nogen
merge m:1 menage_id using `section0_temp', nogen

* Vérifier les résultats
tab _merge

keep if inrange(age, 6, 25)

save "$chemin\sectionO1_select.dta", replace

restore  // Retourne à l'état initial




*/




















 **********************Chargez la section 2*********************************
 
 

preserve  // Sauvegarde temporaire de l'état initial

use "$chemin\sectionO1_select.dta", clear

* Garder uniquement les variables nécessaires pour le merge

keep grappe menage s01q00a age // n'oubli pas d'enlever l'age apres

* Sauvegarde temporaire
tempfile section01_temp
save `section01_temp'

restore  // Retourne à l'état initial


 

preserve  // Sauvegarde temporaire de l'état initial
use "$chemin\s02_me_SEN2021.dta", clear
* Créer menage_id
egen menage_id = group(grappe menage)
egen individu_id = group(grappe menage s01q00a)

keep grappe menage s01q00a menage_id individu_id s02q00 s02q01__1 s02q01__2 s02q01__3 s02q02__1 s02q02__2 s02q02__3 s02q02a__1 s02q02a__2 s02q02a__3 s02q03 s02q04 s02q04_autre s02q04b s02q05 s02q06 s02q07 s02q08 s02q09 s02q09_autre s02q10 s02q11 s02q11_autre s02q12 s02q12a s02q13 s02q13_autre s02q14 s02q16 s02q20 s02q21 s02q22 s02q23 s02q24 s02q25 s02q26 s02q27 s02q28 s02q29 s02q30 s02q30_autre s02q31 s02q32 s02q33 s02q33


* Réaliser le merge avec la section 1 pour recuperer l'age
merge 1:1 grappe menage s01q00a using `section01_temp'

keep if inrange(age, 6, 25)


save "$chemin\section2_select.dta", replace

restore












****************** la suite *****************
												

*** Cette partie est dédiée à la sélection des variables utiles à notre analyse subséquente.
*** Les premieres parties sur l'identification et les caractéristiques sociodémographiques ont été sélectionnées avant. 
*** Ce script concerne les sections 4(revenus individuels de l'emploi principal et secondaire) 5 (revenus individuels hors emploi), 6 (épargne), 7b (consommations alimentaires), 9a-f (consommations non alimentaires), 11 (logement), 12 (avoirs), 13 (transferts)
*** Au terme de l'exploration des donnnées, nous avons conclu que les variables de revenu étaient de faible qualité à cause de la quantité des valeurs manquantes, des emplois informels et d'indisponibilité des bulletins de salaire. Nous nous tournerons donc vers la création d'un indice économique pour évaluer le niveau financier des ménages



** Définition du répertoire de travail 
	
global chemin "C:\Users\LENOVO\Desktop\ENSAE_PARIS\3A\TP_SDS\Data"	




**********************Chargez la section 1; caractéristique sociodémagraphiques des ménages pour recupérer l'age et la taille du ménage *************
**************************************************************

                                                     *  CREATION DE LA VARIABLE AGE * 

       ** Base des caractéristiques démographiques **

use "$chemin\Input\s01_me_SEN2021.dta" , clear

describe

** creer l'identifiant unique des individus

egen menage_id = group(grappe menage)

egen individu_id = group(grappe menage s01q00a)

duplicates list individu_id

** variable age

*** age à partir de la date de naissance

codebook s01q03c // on a 20,046 NA

count if s01q03c==. & s01q04a==. // dont 15202 n'ont pas déclaré leur age

// en effet ces individus (15202) sont ceux qui n'ont plus dans le ménages au moments de l'enquête:

 tab s01q00aa, missing

// on les supprime car aucune info par la suite dans cette section
 
 drop if s01q00aa==2
 
 // traitement des 4844 restants : on fait fois à la date de naissance
		
		// pour les NA de date de naissance on remplace par l'info de l'age


gen age= s01q04a 

replace age= 2022- s01q03c +1 if s01q03c!=.  

codebook age

preserve

* Garder les informations intéressantes 

keep grappe menage s01q00a age 

* Sauvegarde temporaire 
save "$chemin\Temp\age.dta" , replace

restore 

                                         *  CREATION DE LA VARIABLE TAILLE DU MENAGE * 

bysort menage_id: egen taille = total(!missing(menage_id))

* Garder les informations intéressantes 
keep grappe menage taille 

* Supprimer les doublons
duplicates drop

* Sauvegarde temporaire 
save "$chemin\Temp\taille.dta" , replace





**********************Chargez la section 4; revenus individuels de l'emploi principal *********************************
**************************************************************




************************** Dans cette partie, nous sommes surtout intéressés par les revenus individuels des parents si ceux-ci sont presents dans le ménage, ceux du chef de ménage et celui total/moyen du ménage (afin de voir si le CM est le principal pourvoyeur)

** Importer la base de travail
use  "$chemin\Input\s04b_me_SEN2021.dta" , clear


****** Même si ce script n'est pas destiné au controle de coherence, comme à terme de celle-ci, seules les informations utiles seront maintenues, nous allons effectuer quelques controles avant suppression des données inutiles pour nous rassurer de la fiabilité de la donnée 

** liste des variables
ds

** nombre d'observations
count

** check for duplicates
duplicates list grappe menage s01q00a
duplicates list

** Niveau de réponse du salaire 
codebook s04q43

** calculs des revenus annuels 
// Selon la fréquence de paiement, semaine, mois, annee... et lenombre de mois de travail sur l'année , on peut estimer le revenu sur l'année

* salaire principal
gen salaire= s04q43*s04q32*4 if s04q43_unite == 1 
replace salaire= s04q43*s04q32 if s04q43_unite == 2
replace salaire = s04q43*s04q32/3 if s04q43_unite == 3
replace salaire = s04q43*s04q32/12 if s04q43_unite == 4 

* primes
gen primes= s04q45*s04q32*4 if s04q45_unite == 1 
replace primes= s04q45*s04q32 if s04q45_unite == 2
replace primes = s04q45*s04q32/3 if s04q45_unite == 3
replace primes = s04q45*s04q32/12 if s04q45_unite == 4 

* autres avantages (indemnites)	
gen avantages= s04q47*s04q32*4 if s04q47_unite == 1 
replace avantages= s04q47*s04q32 if s04q47_unite == 2
replace avantages = s04q47*s04q32/3 if s04q47_unite == 3
replace avantages = s04q47*s04q32/12 if s04q47_unite == 4 

** Faire la somme, verifier s'il n y a pas certains qui n'ont pas renseigné le salaire principal mais l'ont fait pour les primes, ceux la sont remplacés par des valeurs manquantes

* Salaire principal total
egen salaire_tot = rowtotal(salaire primes avantages), missing

* Verifier et remplacer les salaires manquants
br if salaire_tot != . & salaire == .
replace salaire_tot = . if salaire == .

** Quelques chiffres

 // Secteur d'activité
decode s04q31, gen(s04q31_label)
ta s04q31_label
 // Pourcentage de salariés
decode s04q39, gen(s04q39_label)
ta s04q39_label
 // Distribution des salaires
twoway (kdensity salaire_tot) (hist salaire_tot, bin(30) percent color("128 0 0")), title("Distribution du salaire")
 // Quelques stats
su salaire_tot, detail

** Indicateur de fiabilité : les gens qui ont un emploi formel et qui dispose d'un bulletin de salaire, le niveau de valeurs manquantes et les incohérences internes

 // Proportions de missing values 
display "Pourcentage de valeurs manquantes pour le salaire: " (100 * sum(missing(salaire_tot)) / _N) "%" // Très peu de valeurs manquantes

 // Vérifier que ces valeurs sont manquantes de facon aléatoire (les riches pourraient cacher leur revenu, les pauvres aussi, ceux ci potentiellement pourraient correspondre à certaines catégories socioprofessionnelles)

 // Ceux qui disposent d'un bulletin de salaire
display "Pourcentage de ceux justifiant d'un bulletin de salaire: " (100 * sum(s04q42 == 1) / _N) "%"  // Aucun ne dispose d'un bulletin de salaire

 // Ceux qui travaillent dans un milieu formel
 display "Pourcentage de ceux évoluant dans un milieu formel: " (100 * sum(s04q39a == 1) / _N) "%"   // Moins de 1% des entreprises ont une comptabilité formelle

 // Quelques controles de coherences 
 
* verifier que les non salariés n'ont pas indiqué des salaires
count if s04q39>6 & salaire_tot != . &  salaire_tot != 0 // 46 non salariés ont reporté un salaire non nulle

* on recree la variable salariée
gen salarie = (s04q39>6 & salaire_tot != . &  salaire_tot != 0) | (s04q39<=6)

* verifier l'age de ceux qui reportent des salaires non manquantes

preserve
// Exporter l'age
merge 1:1 grappe menage s01q00a using "$chemin\Temp\age.dta", keep(match master) nogen 
// Garder les salaires renseignés
drop if salaire_tot == .
// Voir les stats d'age des salariés
codebook age, detail // Les repondants ont bien entre 6 et plus
// Garder les salaires renseignés
drop if salaire_tot == 0
// Voir les stats d'age des salariés
codebook age, detail // Les repondants ont bien entre 6 et plus
br if age < 15 // 3,751 jeunes de moins de 15 ans sont employés 
ta s04q39_label // Les trois quarts de ceux-ci travaillent comme des ouvriers ou des manoeuvres 
// Remarque : l'age reste quand meme trop bas pour certains pour etre réaliste
restore

*********************************** Conclusions ********************************************
* La qualité de cette variable est relativement bonne mais présente quelques limites liées aux emplois informels 

* garder les variables utiles  (salaire, emploi pour les controles de cohérence)
keep grappe menage s01q00a salaire_tot salarie s04q31 s04q39

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_emploi.dta" , replace



************************** Nous pouvons maintenant passer à la sélection

use  "$chemin\Input\s01_me_SEN2021.dta" , clear
*********** Récupération du salaire du pere ******************



** Garder dans la base sociodémographique uniquement ceux qui ont indiqué la présence du pere dans le ménage

codebook s01q22  // Voir la présence du pere dans le ménage

* Ne garder que les individus dont le pere habite dans le ménage
keep if s01q22 == 1

* garder les variables utiles  (id, identifiant du pere)
keep grappe menage s01q00a s01q23

* Les garder dans un fichier temporaire 
tempfile fathers
save `fathers'

** Recuperation du salaire du pere dans la section 4 (des revenus de l'emploi principal)

* importer ladite section
use  "$chemin\Input\s04b_me_SEN2021.dta" , clear

* garder les variables utiles  (salaire, emploi pour les controles de cohérence)
keep grappe menage s01q00a s04q31 s04q32 s04q39 s04q42 s04q43 s04q43_unite

rename s01q00a s01q23
rename s04q31 s04q31_pere
rename s04q32 s04q32_pere
rename s04q39 s04q39_pere
rename s04q42 s04q42_pere
rename s04q43 s04q43_pere
rename s04q43_unite s04q43_unite_pere

save "$chemin\Temp\revenu_emploi_pere.dta" , replace
use `fathers', clear

* Fusioner avec la base contenant que les enfants dont le pere est présent
merge m:1 grappe menage s01q23 using "$chemin\Temp\revenu_emploi_pere.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only matched observations and unmatched master observations after merging. 
// Dans ce cas, les observations du master sont celles relatives au salariat.

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_emploi_pere.dta" , replace

*********** Récupération du salaire de la mere ******************

use "$chemin\Input\s01_me_SEN2021.dta" , clear


** Garder dans la base sociodémographique uniquement ceux qui ont indiqué la présence de la mere dans le ménage

codebook s01q29  // Voir la présence de la mere dans le ménage

* Ne garder que les individus dont la mere habite dans le ménage
keep if s01q29 == 1

* garder les variables utiles  (id, identifiant de la mere)
keep grappe menage s01q00a s01q30

* Les garder dans un fichier temporaire 
tempfile mothers
save `mothers'

** Recuperation du salaire de la mere dans la section 4 (des revenus de l'emploi principal)

* importer ladite section
use  "$chemin\Input\s04b_me_SEN2021.dta" , clear

* garder les variables utiles  (salaire, emploi pour les controles de cohérence)
keep grappe menage s01q00a s04q31 s04q32 s04q39 s04q42 s04q43 s04q43_unite

rename s01q00a s01q30
rename s04q31 s04q31_mere
rename s04q32 s04q32_mere
rename s04q39 s04q39_mere
rename s04q42 s04q42_mere
rename s04q43 s04q43_mere
rename s04q43_unite s04q43_unite_mere

save "$chemin\Temp\revenu_emploi_mere.dta" , replace
use `mothers', clear

* Fusioner avec la base contenant que les enfants dont la mere est présent
merge m:1 grappe menage s01q30 using "$chemin\Temp\revenu_emploi_mere.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_emploi_mere.dta" , replace

*********** Récupération du salaire du CM ******************

use "$chemin\Input\s01_me_SEN2021.dta" , clear

* Variable donnant l'info du lien de parenté avec le CM
codebook s01q02

* Vérifier si l'indice du CM est toujours comme c'est censé l'être 
ta s01q02 s01q00a // Ce n'est pas toujours le cas, nous allons devoir créer une variable afin de récuperer l'indice du CM comme pour les parents

* Ajouter la variable précisant l'indice du CM
gen indice_cm = s01q00a if s01q02 == 1

* Propager cet indice à l'ensemble des membres du ménage
bysort grappe (menage): replace indice_cm = indice_cm[_n-1] if missing(indice_cm)

* garder les variables utiles  (id, identifiant du CM)
keep grappe menage indice_cm indice

duplicates drop

bysort grappe menage (indice_cm): gen indice = _n
drop if indice >= 2

* Les garder dans un fichier temporaire 
tempfile CM
save `CM'

** Recuperation du salaire du CM dans la section 4 (des revenus de l'emploi principal)

* importer ladite section
use  "$chemin\Input\s04b_me_SEN2021.dta" , clear

* garder les variables utiles  (salaire, emploi pour les controles de cohérence)
keep grappe menage s01q00a s04q31 s04q32 s04q39 s04q42 s04q43 s04q43_unite

rename s01q00a indice_cm
rename s04q31 s04q31_CM
rename s04q32 s04q32_CM
rename s04q39 s04q39_CM
rename s04q42 s04q42_CM
rename s04q43 s04q43_CM
rename s04q43_unite s04q43_unite_CM

save "$chemin\Temp\revenu_emploi_CM.dta" , replace
use `CM', clear

* Fusioner avec la base contenant que les enfants dont la mere est présent
merge m:1 grappe menage indice_cm using "$chemin\Temp\revenu_emploi_CM.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

// Dans ce cas, les observations du master sont celles relatives au salariat.

* Garder les variables utiles
keep grappe menage *_CM

* Supprimer les doublons
duplicates drop

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_emploi_CM.dta" , replace

*********** Récupération du salaire total et par tete du ménage ******************

* importer ladite section
use  "$chemin\Temp\revenu_emploi.dta" , clear

* ajouter la taille du ménage
merge m:1 grappe menage using "$chemin\Temp\taille.dta", keep(match master) nogen 

* calculer salaire total par ménage
collapse (sum) salaire_tot, by(grappe menage taille)
 
* garder les variables utiles  (juste les salaires)
keep grappe menage taille salaire_tot 

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_emploi_men.dta" , replace

*********** Fusion des informations sur les parents, le CM et le ménage dans son ensemble  ***************

* importer la liste des
use "$chemin\Temp\age.dta" , clear

* fusionner les informations à partir des identifiants
merge m:1 grappe menage using "$chemin\Temp\revenu_emploi_men.dta", keep(match master) nogen //

merge m:1 grappe menage using "$chemin\Temp\revenu_emploi_CM.dta", keep(match master) nogen  //

merge m:1 grappe menage s01q00a using "$chemin\Temp\revenu_emploi_pere.dta", keep(match master) nogen //

merge m:1 grappe menage s01q00a using "$chemin\Temp\revenu_emploi_mere.dta", keep(match master) nogen //

merge 1:1 grappe menage s01q00a using "$chemin\Temp\revenu_emploi.dta", keep(match master) nogen //

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_emploi.dta" , replace

save "$chemin\Final\section04b_select.dta" , replace

*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6, 25)


* Enregistrer les informations de la base
save "$chemin\Final\revenu_emploi.dta",replace

save "$chemin\Temp\section04_select.dta" , replace



**********************Chargez la section 5; revenus individuels hors emploi *******************************
**************************************************************








************************** Dans cette partie, nous sommes surtout intéressés par les revenus individuels des parents si ceux-ci sont presents dans le ménage, ceux du chef de ménage et celui total/moyen du ménage (afin de voir si le CM est le principal pourvoyeur)

** Importer la base de travail
use  "$chemin\Input\s05_me_SEN2021.dta" , clear

****** Même si ce script n'est pas destiné au controle de coherence, comme à terme de celle-ci, seules les informations utiles seront maintenues, nous allons effectuer quelques controles avant suppression des données inutiles pour nous rassurer de la fiabilité de la donnée 

** liste des variables
ds

** nombre d'observations
count

** check for duplicates
duplicates list grappe menage s01q00a
duplicates list

** Nombre d'individus ayant recu les différents types d'aides 
codebook s05q01 // pension de retraite

codebook s05q03 // pension de veuvage

codebook s05q05 // pension d'invalidité

codebook s05q07 // pension alimentaire

codebook s05q09 // revenus de loyers 

codebook s05q11 // revenus mobiliers et financiers

codebook s05q13 // autres revenus

** Distribution des revenus
twoway (kdensity s05q02) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des pensions de retraite")
twoway (kdensity s05q04) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des pensions de veuvage")
twoway (kdensity s05q06) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des pensions d'invalidité")
twoway (kdensity s05q08) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des pensions alimentaires")
twoway (kdensity s05q10) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des revenus de loyers")
twoway (kdensity s05q12) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des revenus mobiliers et financiers")
twoway (kdensity s05q14) (hist s05q01, bin(30) percent color("128 0 0")), title("Distribution des autres revenus")

 // Quelques controles de coherences pour nous rassurer de la variable en général 
 
* verifier que ceux qui ont dit non n'ont pas indiqué de revenus 
count if s05q01 == 2 & s05q02 != .
count if s05q03 == 2 & s05q04 != .
count if s05q05 == 2 & s05q06 != .
count if s05q07 == 2 & s05q08 != .
count if s05q09 == 2 & s05q10 != .
count if s05q11 == 2 & s05q12 != .
count if s05q13 == 2 & s05q14 != .  // Pas d'incohérences

* verifier l'age de ceux qui reportent des salaires non manquantes

preserve
// Exporter l'age
merge 1:1 grappe menage s01q00a using "$chemin\Temp\age.dta", keep(match master) nogen 
// Garder les salaires renseignés
egen all_missing = rowmiss(s05q02 s05q04 s05q06 s05q08 s05q10 s05q12 s05q14)
drop if all_missing == 7

// Voir les stats d'age des receveurs de pension
bysort s05q01 : su age, detail // entre 54 et 98 ans, age moyen de 71 ans pour la retraite
bysort s05q03: su age, detail  // entre 42 et 93 ans, age moyen de 69 ans pour le veuvage
bysort s05q05 : su age, detail // entre 23 et 77 ans, age moyen de 55 ans pour l'invalidité
bysort s05q07 : su age, detail // entre 26 et 64 ans, age moyen de 44 ans pour la pension alimentaire
bysort s05q09 : su age, detail // entre 28 et 92 , age moyen de 59 ans pour le patrimoine et autres
bysort s05q11 : su age, detail // entre 20 et 80 ans, age moyen de 52  ans pour le patrimoine et autres
bysort s05q13 : su age, detail // entre 17 et 98 ans, age moyen de 45 ans pour le patrimoine et autres

restore

* verifier que ceux qui ont déclaré ces revenus sont legit (ex ceux qui ont recu les pension de retraite sont bien des retraités)

 // Veuvage 
 
	 /// recuperer la situation matrimoniale
 preserve
	 * Importer la base de travail
	use  "$chemin\Input\s01_me_SEN2021.dta" , clear
	 * Garder les variables utiles 
	keep grappe menage s01q00a s01q07
	 * Enregistrement temporaire
	tempfile sit_mat
	save `sit_mat'
 restore
	 
	 /// Fusion 
	merge 1:1 grappe menage s01q00a using `sit_mat', keep(match master) nogen 

	 /// Tabulations pour voir la situation matrimoniale des veufs
  ta s05q03 s01q07  // La plupart sont bien des veufs, il ya des mariés (mais cela peut sagir dun veuvage passé)

 // Retraité
 
 	 /// recuperer la cause d'inactivité déclarée
 preserve
	 * Importer la base de travail
	use  "$chemin\Input\s04a_me_SEN2021.dta" , clear
	 * Garder les variables utiles 
	keep grappe menage s01q00a s04q18
	 * Enregistrement temporaire
	tempfile cause_inac
	save `cause_inac'
 restore
	 
	/// Fusion 
	merge 1:1 grappe menage s01q00a using `cause_inac', keep(match master) nogen 

	 /// Tabulations pour voir la cause d'inactivité des 7 derniers jours
  ta s05q01 s04q18  // Les réponses sont cohérentes
  
  drop s04q18 s01q07
 save  "$chemin\Temp\revenu_hemploi.dta" , replace
	 

*********************************** Conclusions  **************************
*Dans l'ensemble, aucune incohérence n'a été relevée. 

************************** Nous pouvons maintenant passer à la sélection


*********** Récupération du salaire du pere ******************


use  "$chemin\Input\s01_me_SEN2021.dta" , clear
** Garder dans la base sociodémographique uniquement ceux qui ont indiqué la présence du pere dans le ménage

codebook s01q22  // Voir la présence du pere dans le ménage

* Ne garder que les individus dont le pere habite dans le ménage
keep if s01q22 == 1

* garder les variables utiles  (id, identifiant du pere)
keep grappe menage s01q00a s01q23

* Les garder dans un fichier temporaire 
tempfile fathers
save `fathers'

** Recuperation du salaire du pere dans la section 5

* importer ladite section
use  "$chemin\Input\s05_me_SEN2021.dta" , clear

* renommer les variables pour eviter les confusions
rename s01q00a s01q23
foreach var of varlist s05* {
    rename `var' `var'_pere
}


save "$chemin\Temp\revenu_hemploi_pere.dta" , replace
use `fathers', clear

* Fusioner avec la base contenant que les enfants dont le pere est présent
merge m:1 grappe menage s01q23 using "$chemin\Temp\revenu_hemploi_pere.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_hemploi_pere.dta" , replace

*********** Récupération du salaire de la mere ******************

use "$chemin\Input\s01_me_SEN2021.dta" , clear


** Garder dans la base sociodémographique uniquement ceux qui ont indiqué la présence de la mere dans le ménage

codebook s01q29  // Voir la présence de la mere dans le ménage

* Ne garder que les individus dont la mere habite dans le ménage
keep if s01q29 == 1

* garder les variables utiles  (id, identifiant de la mere)
keep grappe menage s01q00a s01q30

* Les garder dans un fichier temporaire 
tempfile mothers
save `mothers'

** Recuperation du revenu hors emploi de la mere dans la section 5

* importer ladite section
use  "$chemin\Input\s05_me_SEN2021.dta" , clear


* renommer les variables pour eviter les confusions
rename s01q00a s01q30
foreach var of varlist s05* {
    rename `var' `var'_mere
}


save "$chemin\Temp\revenu_hemploi_mere.dta" , replace
use `mothers', clear

* Fusioner avec la base contenant que les enfants dont la mere est présent
merge m:1 grappe menage s01q30 using "$chemin\Temp\revenu_hemploi_mere.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_hemploi_mere.dta" , replace

*********** Récupération du salaire du CM ******************

use "$chemin\Input\s01_me_SEN2021.dta" , clear

* Variable donnant l'info du lien de parenté avec le CM
codebook s01q02

* Vérifier si l'indice du CM est toujours comme c'est censé l'être 
ta s01q02 s01q00a // Ce n'est pas toujours le cas, nous allons devoir créer une variable afin de récuperer l'indice du CM comme pour les parents

* Ajouter la variable précisant l'indice du CM
gen indice_cm = s01q00a if s01q02 == 1

* Propager cet indice à l'ensemble des membres du ménage
bysort grappe (menage): replace indice_cm = indice_cm[_n-1]  if missing(indice_cm)

* garder les variables utiles  (id, identifiant du CM)
keep grappe menage indice_cm

* Les garder dans un fichier temporaire 
tempfile CM
save `CM'

** Recuperation du revenu hors emploi du CM dans la section 5

* importer ladite section
use  "$chemin\Input\s05_me_SEN2021.dta" , clear

* renommer les variables pour eviter les confusions
rename s01q00a indice_cm
foreach var of varlist s05* {
    rename `var' `var'_CM
}

save "$chemin\Temp\revenu_hemploi_CM.dta" , replace
use `CM', clear

* Fusioner avec la base contenant les CM
merge m:1 grappe menage indice_cm using "$chemin\Temp\revenu_hemploi_CM.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

* Garder les variables utiles
keep grappe menage indice_cm *_CM


* Supprimer les doublons
duplicates drop

bysort grappe menage (indice_cm): gen indice = _n
drop if indice >= 2

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_hemploi_CM.dta" , replace

*********** Récupération du salaire total et par tete du ménage ******************

* importer ladite section
use "$chemin\Temp\revenu_hemploi.dta" , clear

* ajouter la taille du ménage
merge m:1 grappe menage using "$chemin\Temp\taille.dta", keep(match master) nogen 

* calculer salaire total par ménage
collapse (sum) s05q02 s05q04 s05q06 s05q08 s05q10 s05q12 s05q14, by(grappe menage taille)
 
* garder les variables utiles  (juste les salaires)
keep grappe menage taille s05* 

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_hemploi_men.dta" , replace

*********** Fusion des informations sur les parents, le CM et le ménage dans son ensemble  ***************

* importer la liste des
use "$chemin\Temp\age.dta" , clear

* fusionner les informations à partir des identifiants
merge m:1 grappe menage using "$chemin\Temp\revenu_hemploi_men.dta", keep(match master) nogen //

merge m:1 grappe menage using "$chemin\Temp\revenu_hemploi_CM.dta", keep(match master) nogen  //

merge m:1 grappe menage s01q00a using "$chemin\Temp\revenu_hemploi_pere.dta", keep(match master) nogen //

merge m:1 grappe menage s01q00a using "$chemin\Temp\revenu_hemploi_mere.dta", keep(match master) nogen //

* Enregistrer les informations de la base
save "$chemin\Temp\revenu_hemploi.dta" , replace


*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6,25)

* Enregistrer les informations de la base
save "$chemin\Final\revenu_hemploi.dta",replace

save "$chemin\Final\section05_select.dta",replace

*** Ce script concerne les sections 4(revenus individuels de l'emploi principal et secondaire) 5 (revenus individuels hors emploi), 6 (épargne), 7b (consommations alimentaires), 9a-f (consommations non alimentaires), 11 (logement), 12 (avoirs), 13 (transferts)


**********************Chargez la section 6; épargnes *********************************
**************************************************************


************************** Dans cette partie, nous sommes surtout intéressés par les revenus individuels des parents si ceux-ci sont presents dans le ménage, ceux du chef de ménage et celui total/par tete du ménage (afin de voir si le CM est le principal pourvoyeur)

** Importer la base de travail
use  "$chemin\Input\s06_me_SEN2021.dta" , clear

****** Même si ce script n'est pas destiné au controle de coherence, comme à terme de celle-ci, seules les informations utiles seront maintenues, nous allons effectuer quelques controles avant suppression des données inutiles pour nous rassurer de la fiabilité de la donnée 

** liste des variables
ds

** nombre d'observations
count

** check for duplicates
duplicates list grappe menage s01q00a
duplicates list

** proportion des épargnants
codebook s06q02 // 4231 individus ont épargné de l'argent


** statistiques des emprunts 
 * proportion de ceux qui ont demandé du crédit récent
  codebook s06q03 // 759 ont demandé un crédit

 * proportion de ceux qui ont obtenu du crédit récent
  codebook s06q05 // 606 ont obtenu le crédit
  
 * proportion de ceux qui n'ont pas fini de rembourser un crédit
  codebook s06q09 // 966 ont bénéficié d'un crédit qui n'a pas été totalement remboursé
  ta s06q10 // Nombre de crédits pas encore remboursé : 79% ont pris un seul crédit
  
  ta s06q09 s06q10 // !!! présence d'incohérences :  il ya des individus qui ont dit avoir emprunté mais pourtant ont 0 crédit et d'autres qu'ont reporté ne pas être emprunteurs pour ensuite déclarer un nombre de crédit non nul
  
 * principal utilisation du crédit 
  decode s06q11, gen(s06q11_label)
  ta s06q11_label    // moins de 2% ont utilisé ce crédit pour des dépenses d'éducation.
  
 * montant moyen du crédit non remboursé
  su s06q14,d

** selection des variables utiles
keep grappe menage s01q00a s06q02 s06q03 s06q05 s06q09 s06q10 s06q14

save "$chemin\Temp\epargne.dta",replace

*********** récuperer l'age *******************

* importer l'age
use "$chemin\Temp\age.dta" , clear

* fusionner les informations à partir des identifiants
merge 1:m grappe menage using "$chemin\Temp\epargne.dta", keep(match master) nogen //


*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6,25)

* Enregistrer les informations de la base
save "$chemin\Final\epargne.dta",replace



**********************Chargez la section 7b; consommations alimentaires *********************************
**************************************************************

** Importer la base de travail
use  "$chemin\Input\s07b_me_SEN2021.dta" , clear

** Avant de selectionner et faire la somme (pour que ce ne soit pas trop lourd sur R) les variables utiles , vérifier que le skip a bien été respecté
count if s07bq02  == 2 & (s07bq03a != . | s07bq03b != . | s07bq04 != . | s07bq05 != . | s07bq06 != . | s07bq07a != . | s07bq07b != . | s07bq07c != . | s07bq08 != . ) // Les skips ont été bien respectés


** Vérifier vite fait que les quantités consommées sont rationnelles et que la partie issue d'autoconsommation ou autre est bien inférieure à celle totale
 
  // Statistiques des quantités consommées globalement
  su s07bq03a, d  // Pas de valeurs extremes ou etranges
  
  // Vérifier que l'autoconsommation est inférieure à la totalement
   egen double autconsom = rowtotal(s07bq04 s07bq05), missing // créer la variable d'autoconsommation
   count if s07bq03a < autconsom  // Les autoconsommations sont bien inférieures à la quantité totale

** Verifier que si la quantité totale est superieure à celle issue d'autoconsommation ou de cadeaux ou autre (cela voudrait que la différence a été achetée) , la personne reponde hier ou dans les 7 derniers jours pour la derniere date d'achat
count if s07bq03a > autconsom  // Pour 201 080 observations, la quantité totale est strictement supérieure
ta s07bq06 if s07bq03a > autconsom // La plupart des produits ont effectivement été achetés hier ou sur les 7 derniers jours, seuls 10% ont été acheté il ya plus longtemps pour consommation récente.

** Si tout ceci est fiable, calculer le cout total de la consommation sur les 7 jours (ceci permettra d'avoir une estimation de la consommation alimentaire totale sous deux hypothèses, la premiere que cette consommation reflete la consommation mensuelle et donc annuelle (forte hypothese !!!), la seconde est que les consommation qui datent de plus de 7 jours sont rares et ne font pas vraiment parti des habitudes du ménage)

gen meme_taille = (s07bq07b == s07bq03b & s07bq03c == s07bq07c) // vérifier que les unités sont les memes
gen cout_conso_recente= s07bq03a/s07bq07a*s07bq08 if meme_taille == 1 & s07bq07a!=0 // calculer du cout des biens de consommation fréquents

 su cout_conso_recente, d       // Vérifier que ces couts sont rationnels : la valeur moyenne est à 1kg, 90% à moins de 10 kg, tout est ok. 
 
collapse (sum) cout_conso_recente, by(grappe menage) // calculer les couts totaux 


*******  Fusionner avec la base age **********
preserve 

* Importation de la base age
use "$chemin\Temp\age.dta" , clear		
* Fichier temporaire
tempfile age
save `age'								

restore 

merge 1:m grappe menage using  `age', keep(match master) nogen //


*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6, 25)

* Enregistrer les informations de la base
save "$chemin\Final\conso_al.dta",replace

save "$chemin\Final\section07b_select.dta",replace

**********************Chargez la section 9a-f; consommations non alimentaires *********************************
**************************************************************

******* section a : Fetes et cérémonies lors des 12 derniers mois 

** Importer la base de travail
use  "$chemin\Input\s09a_me_SEN2021.dta" , clear

** Voir les niveaux de consommation
codebook s09aq02 // 28299 consommations à diverses fêtes

** Vérifier que les skips sont respectés 
count if s09aq02 == 2 & (s09aq03!=. | s09aq04!=. | s09aq05!=. | s09aq06!=. | s09aq07!=. )  // tout est ok

** Vérifier que les valeurs reportées sont globalement réalistes

	// Détecter les valeurs étranges
	codebook s09aq03 // RAS
	codebook s09aq04 // RAS
	codebook s09aq05 //RAS
	codebook s09aq06  // RAS
	codebook s09aq07 // RAS
	
** Calculer les dépenses totales pour cette section
egen int depenses_nal_a = rowtotal(s09aq03 s09aq04 s09aq05 s09aq06 s09aq07), missing
   // Vérifier que ceux qui ont dit n'ont pas de dépenses totales nulles 
     su depenses_nal_a, d // Valeurs normales mais présence de dépenses nulles..
     ta s09aq02 if depenses_nal_a == 0 // Pour 1247 observations, les dépenses sont nulles malgré qu'il en ait reporté
	 replace  depenses_nal_a = .  if depenses_nal_a == 0 // Remplacer ces valeurs par manquantes
   
collapse (sum) depenses_nal_a, by(grappe menage) // calculer les couts totaux 

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal_a.dta",replace

******* section b

** Importer la base de travail
use  "$chemin\Input\s09b_me_SEN2021.dta" , clear

** Voir les niveaux de consommation
codebook s09bq02 // 20859 consommations

** Vérifier que les skips sont respectés 
count if s09bq02 == 2 & (s09bq03!=. )  // tout est ok

** Vérifier que les valeurs reportées sont globalement réalistes

	// Détecter les valeurs étranges
	codebook s09bq03 // RAS
	
** Renommer la variable
rename s09bq03 depenses_nal_b


** Conso totale par ménage    
collapse (sum) depenses_nal_b, by(grappe menage) // calculer les couts totaux 

   // Vérifier que ceux qui ont dit n'ont pas de dépenses totales nulles 
     su depenses_nal_b, d // Valeurs normales 
	  count if depenses_nal_b == 0 // 35 valeurs nulles enregistrées
	  replace  depenses_nal_b = .  if depenses_nal_b == 0 // Remplacer ces valeurs par manquantes

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal_b.dta",replace

******* section c

** Importer la base de travail
use  "$chemin\Input\s09c_me_SEN2021.dta" , clear

** Voir les niveaux de consommation
codebook s09cq02 // 34977 consommations

** Vérifier que les skips sont respectés 
count if s09cq02 == 2 & (s09cq03!=. )  // tout est ok

** Vérifier que les valeurs reportées sont globalement réalistes

	// Détecter les valeurs étranges
	codebook s09cq03 // RAS
	
** Renommer la variable
rename s09cq03 depenses_nal_c


** Conso totale par ménage    
collapse (sum) depenses_nal_c, by(grappe menage) // calculer les couts totaux 

   // Vérifier que ceux qui ont dit n'ont pas de dépenses totales nulles 
     su depenses_nal_c, d // Valeurs normales mais présence de dépenses nulles..
	 count if depenses_nal_c == 0 // 35 valeurs nulles enregistrées
	  replace  depenses_nal_c = .  if depenses_nal_c == 0 // Remplacer ces valeurs par manquantes
   

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal_c.dta",replace

******* section d

** Importer la base de travail
use  "$chemin\Input\s09d_me_SEN2021.dta" , clear

** Voir les niveaux de consommation
codebook s09dq02 // 21584 consommations

** Vérifier que les skips sont respectés 
count if s09dq02 == 2 & (s09dq03!=. )  // tout est ok

** Vérifier que les valeurs reportées sont globalement réalistes

	// Détecter les valeurs étranges
	codebook s09dq03 // RAS
	
** Renommer la variable
rename s09dq03 depenses_nal_d


** Conso totale par ménage    
collapse (sum) depenses_nal_d, by(grappe menage) // calculer les couts totaux 

   // Vérifier que ceux qui ont dit n'ont pas de dépenses totales nulles 
     su depenses_nal_d, d // Valeurs normales mais présence de dépenses nulles..
	 count if depenses_nal_d == 0 // 431 valeurs nulles enregistrées
	  replace  depenses_nal_d = .  if depenses_nal_d == 0 // Remplacer ces valeurs par manquantes
   

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal_d.dta",replace

******* section e

** Importer la base de travail
use  "$chemin\Input\s09e_me_SEN2021.dta" , clear

** Voir les niveaux de consommation
codebook s09eq02 // 36302 consommations

** Vérifier que les skips sont respectés 
count if s09eq02 == 2 & (s09eq03!=. )  // tout est ok

** Vérifier que les valeurs reportées sont globalement réalistes

	// Détecter les valeurs étranges
	codebook s09eq03 // RAS
	
** Renommer la variable
rename s09eq03 depenses_nal_e


** Conso totale par ménage    
collapse (sum) depenses_nal_e, by(grappe menage) // calculer les couts totaux 

   // Vérifier que ceux qui ont dit n'ont pas de dépenses totales nulles 
     su depenses_nal_e, d // Valeurs normales mais présence de dépenses nulles..
	 count if depenses_nal_e == 0 // 368 valeurs nulles enregistrées
	  replace  depenses_nal_e = .  if depenses_nal_e == 0 // Remplacer ces valeurs par manquantes
   

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal_e.dta",replace

******* section f

** Importer la base de travail
use  "$chemin\Input\s09f_me_SEN2021.dta" , clear

** Voir les niveaux de consommation
codebook s09fq02 //  29,894 consommations

** Vérifier que les skips sont respectés 
count if s09fq02 == 2 & (s09fq03!=. )  // tout est ok

** Vérifier que les valeurs reportées sont globalement réalistes

	// Détecter les valeurs étranges
	codebook s09fq03 // RAS
	
** Renommer la variable
rename s09fq03 depenses_nal_f


** Conso totale par ménage    
collapse (sum) depenses_nal_f, by(grappe menage) // calculer les couts totaux 

   // Vérifier que ceux qui ont dit n'ont pas de dépenses totales nulles 
     su depenses_nal_f, d // Valeurs normales mais présence de dépenses nulles liés à la somme
	 count if depenses_nal_f == 0 // 681 valeurs nulles enregistrées
	  replace  depenses_nal_f = .  if depenses_nal_f == 0 // Remplacer ces valeurs par manquantes
   

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal_f.dta",replace


******* fusion des sections avec l'age ***********
** Importer la base de travail
use  "$chemin\Temp\age.dta" , clear

** Fusions 
merge m:1 grappe menage using "$chemin\Final\conso_nal_a.dta", keep(match master) nogen //
merge m:1 grappe menage using "$chemin\Final\conso_nal_b.dta", keep(match master) nogen //
merge m:1 grappe menage using "$chemin\Final\conso_nal_c.dta", keep(match master) nogen //
merge m:1 grappe menage using "$chemin\Final\conso_nal_d.dta", keep(match master) nogen //
merge m:1 grappe menage using "$chemin\Final\conso_nal_e.dta", keep(match master) nogen //
merge m:1 grappe menage using "$chemin\Final\conso_nal_f.dta", keep(match master) nogen //


******* selection de la population d'age et enregistrement ************

*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6, 25)

* Enregistrer les informations de la base
save "$chemin\Final\conso_nal.dta",replace

save "$chemin\Final\section09a-f_select.dta",replace
**********************Chargez la section 11; logement *********************************
**************************************************************

** Importer la base de travail
use  "$chemin\Input\s11_me_SEN2021.dta" , clear

** Quelques chiffres
     ta s11q01  // Type de logement 
	 ta s11q04  // Statut d'occupation			
     ta s11q18  // Principal matériau de construction
	 ta s11q19  // Matériau du toit
	 ta s11q20  // Matériau du sol
	 ta s11q21  // Eau courante								
	 ta s11q37  // Source d'éclairage
	 ta s11q54  // Type de sanitaire
 
	 
** Garder les variables utiles 
keep grappe menage s11q01 s11q04 s11q18 s11q19 s11q20 s11q21 s11q37 s11q54

*******  Fusionner avec la base age **********
preserve 

* Importation de la base age
use "$chemin\Temp\age.dta" , clear		
* Fichier temporaire
tempfile age
save `age'								

restore 

merge 1:m grappe menage using  `age', keep(match master) nogen //


*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6, 25)

* Enregistrer les informations de la base
save "$chemin\Final\logement.dta",replace

save "$chemin\Final\section11_select.dta",replace

**********************Chargez la section 12; avoirs *********************************
**************************************************************

** Importer la base de travail
use  "$chemin\Input\s12_me_SEN2021.dta" , clear

** Quelques stats 
ds 
count  // 320 400 enregistrements
bysort s12q01 : ta s12q02

** garder les variables utiles  on garde uniquement les variables liées à la possession ou non d'un bien
keep grappe menage s12q01 s12q02 s12q00
	
*******  Fusionner avec la base age **********
preserve 

* Importation de la base age
use "$chemin\Temp\age.dta" , clear		
* Fichier temporaire
tempfile age
save `age'								

restore 

merge m:m grappe menage using  `age', keep(match master) nogen //


*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6, 25)

* Enregistrer les informations de la base
save "$chemin\Final\avoirs.dta",replace

save "$chemin\Final\section12_select.dta",replace


**********************Chargez la section 13; transferts *********************************
**************************************************************

** Importer la base de travail
use  "$chemin\Input\s13_2_me_SEN2021.dta" , clear

** description de la base
count  // 10665 observations enregistrées
ds 

preserve 

** importer la base de travail 
use  "$chemin\Input\s13_1_me_SEN2021.dta" , clear

** recuperer les variables de filtre de la section suivante
keep grappe menage s13q02 s13q04 s13q05 s13q06 s13q07 s13q08

** fichier temporaire				
tempfile transferts
save `transferts'								

restore 

** recuperer les variables de filtre de la section suivante
merge m:1 grappe menage using `transferts',  nogen //

** quelques stats 
 count   // Combien bénéficient de transferts
ta s13q12 // qui a envoyé l'argent 
ta s13q19   // lieu de résidence de l'expéditeur
ta s13q20 // principal motif du transfert

** calcul du montant du transfert annuel
gen transferts= s13q22a*12 if s13q22b == 1 
replace transferts= s13q22a*4 if s13q22b == 2
replace transferts = s13q22a*2 if s13q22b == 3
replace transferts = s13q22a if s13q22b == 4 
replace transferts = s13q22a if s13q22b == 5	

** garder les variables utiles 
keep grappe menage s13q11 s13q12 s13q19 s13q20 transferts s13q02 s13q04 s13q05 s13q06 s13q07 s13q08

* Enregistrer les informations de la base
save "$chemin\Temp\transferts.dta",replace


************************** Nous pouvons maintenant passer à la sélection


*********** Récupération du salaire du pere ******************

use  "$chemin\Input\s01_me_SEN2021.dta" , clear

** Garder dans la base sociodémographique uniquement ceux qui ont indiqué la présence du pere dans le ménage

codebook s01q22  // Voir la présence du pere dans le ménage

* Ne garder que les individus dont le pere habite dans le ménage
keep if s01q22 == 1

* garder les variables utiles  (id, identifiant du pere)
keep grappe menage s01q00a s01q23

* Les garder dans un fichier temporaire 
tempfile fathers
save `fathers'

** Recuperation des transferts du pere dans la section 13

* importer ladite section 
use  "$chemin\Temp\transferts.dta" , clear

* garder les variables utiles 
keep grappe menage s13q11 s13q12 s13q19 s13q20 transferts

rename s13q11 s01q23
rename s13q12 s13q12_pere
rename s13q19 s13q19_pere
rename s13q20 s13q20_pere
rename transferts transferts_pere

save "$chemin\Temp\revenu_transferts_pere.dta" , replace
use `fathers', clear

* Fusioner avec la base contenant les peres
merge m:m grappe menage s01q23 using "$chemin\Temp\revenu_transferts_pere.dta", keep(match master) nogen  

duplicates drop grappe menage s01q23, force

* Enregistrer les informations de la base
save "$chemin\Temp\transferts_pere.dta" , replace

*********** Récupération du salaire de la mere ******************

use "$chemin\Input\s01_me_SEN2021.dta" , clear


** Garder dans la base sociodémographique uniquement ceux qui ont indiqué la présence de la mere dans le ménage

codebook s01q29  // Voir la présence de la mere dans le ménage

* Ne garder que les individus dont la mere habite dans le ménage
keep if s01q29 == 1

* garder les variables utiles  (id, identifiant de la mere)
keep grappe menage s01q00a s01q30

* Les garder dans un fichier temporaire 
tempfile mothers
save `mothers'

** Recuperation des transferts de la mere dans la section 13 

* importer ladite section 
use  "$chemin\Temp\transferts.dta" , clear

* garder les variables utiles 
keep grappe menage s13q11 s13q12 s13q19 s13q20 transferts

rename s13q11 s01q30
rename s13q12 s13q12_mere
rename s13q19 s13q19_mere
rename s13q20 s13q20_mere
rename transferts transferts_mere

save "$chemin\Temp\revenu_transferts_mere.dta" , replace
use `mothers', clear

* Fusioner avec la base contenant les meres
merge m:m grappe menage s01q30 using "$chemin\Temp\revenu_transferts_mere.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

duplicates drop grappe menage s01q30, force

* Enregistrer les informations de la base
save "$chemin\Temp\transferts_mere.dta" , replace

*********** Récupération du salaire du CM ******************

use "$chemin\Input\s01_me_SEN2021.dta" , clear

* Variable donnant l'info du lien de parenté avec le CM
codebook s01q02

* Vérifier si l'indice du CM est toujours comme c'est censé l'être 
ta s01q02 s01q00a // Ce n'est pas toujours le cas, nous allons devoir créer une variable afin de récuperer l'indice du CM comme pour les parents

* Ajouter la variable précisant l'indice du CM
gen indice_cm = s01q00a if s01q02 == 1

* Propager cet indice à l'ensemble des membres du ménage
bysort grappe (menage): replace indice_cm = indice_cm[_n-1]  if missing(indice_cm)

* garder les variables utiles  (id, identifiant du CM)
keep grappe menage indice_cm indice

* Supprimer les doublons
duplicates drop

bysort grappe menage (indice_cm): gen indice = _n
drop if indice >= 2

drop indice 

* Les garder dans un fichier temporaire 
tempfile CM
save `CM'

** Recuperation du salaire du CM dans la section 4 (des revenus de l'emploi principal)

* importer ladite section 
use  "$chemin\Temp\transferts.dta" , clear

* garder les variables utiles 
keep grappe menage s13q11 s13q12 s13q19 s13q20 transferts

rename s13q11 indice_cm
rename s13q12 s13q12_cm
rename s13q19 s13q19_cm
rename s13q20 s13q20_cm
rename transferts transferts_cm

save "$chemin\Temp\revenu_transferts_CM.dta" , replace
use `CM', clear

* Fusioner avec la base contenant les CM
merge m:m grappe menage indice_cm using "$chemin\Temp\revenu_transferts_CM.dta", keep(match master) nogen  // Using keep(match master) specifies keeping only 

duplicates drop grappe menage indice_cm, force

* Enregistrer les informations de la base
save "$chemin\Temp\transferts_cm.dta" , replace

*********** Récupération du salaire total et par tete du ménage ******************

* importer ladite section
use  "$chemin\Temp\transferts.dta" , clear

* ajouter la taille du ménage
merge m:1 grappe menage using "$chemin\Temp\taille.dta", keep(match master) nogen 

* calculer salaire total par ménage
collapse (sum) transferts, by(grappe menage taille)
 
* garder les variables utiles  (juste les salaires)
keep grappe menage taille transferts

rename transferts transferts_men

* Enregistrer les informations de la base
save "$chemin\Temp\transferts_men.dta" , replace

*********** Fusion des informations sur les parents, le CM et le ménage dans son ensemble  ***************

* importer la liste des
use "$chemin\Temp\age.dta" , clear

* fusionner les informations à partir des identifiants
merge m:1 grappe menage using "$chemin\Temp\transferts_men.dta", keep(match master) nogen //

merge m:1 grappe menage using "$chemin\Temp\transferts_cm.dta", keep(match master) nogen  //

merge m:1 grappe menage s01q00a using "$chemin\Temp\transferts_pere.dta", keep(match master) nogen //

merge m:1 grappe menage s01q00a using "$chemin\Temp\transferts_mere.dta", keep(match master) nogen //

* Enregistrer les informations de la base
save "$chemin\Temp\transferts.dta" , replace

*******  Fusionner avec la base age **********
preserve 

* Importation de la base age
use "$chemin\Temp\age.dta" , clear		
* Fichier temporaire
tempfile age
save `age'								

restore 

merge 1:m grappe menage s01q00a using  `age', keep(match master) nogen //


*********** Inclusion de la population des 6 à 25 ans  *********************

* garder la bonne tranche d'âge
keep if inrange(age, 6, 25)

* Enregistrer les informations de la base
save "$chemin\Final\transferts.dta",replace

* Enregistrer les informations de la base
save "$chemin\Final\section13_select.dta",replace


*************************************  Nous allons conclure par rapport au choix définitif des variables, nous avons plusieurs bases comprenant des informations liés aux revenus et à la capacité financiere du ménage. *************************************************************************


// Peut-on se fier au revenu?

// Revenus de l'emploi
use "$chemin\Final\section04b_select.dta" , clear

gen info_mere = !missing(salaire_mere)
gen info_pere = !missing(salaire_pere)
gen info_CM   = !missing(salaire_CM)
gen info_tot  = !missing(salaire_total)

gen config = ""
replace config = "Mère seule"       if info_mere & !info_pere & !info_CM & !info_tot
replace config = "Père seul"        if !info_mere & info_pere & !info_CM & !info_tot
replace config = "Deux parents"     if info_mere & info_pere & !info_CM & !info_tot
replace config = "Ménage seul"      if !info_mere & !info_pere & !info_CM & info_tot
replace config = "Chef seul"        if !info_mere & !info_pere & info_CM & !info_tot
replace config = "Mère + total"     if info_mere & !info_pere & !info_CM & info_tot
replace config = "Père + total"     if !info_mere & info_pere & !info_CM & info_tot
replace config = "Parents + total"  if info_mere & info_pere & !info_CM & info_tot
replace config = "Tous disponibles" if info_mere & info_pere & info_CM & info_tot
replace config = "Aucune info"      if !info_mere & !info_pere & !info_CM & !info_tot

// Pour toutes les autres configurations restantes
replace config = "Autres combinaisons" if config == ""

tab config, missing

//La majorité des observations (66,5 %) ne disposent d’aucune information sur le salaire, ce qui reflète une forte proportion de données manquantes. Environ 18,7 % ont uniquement le salaire total du ménage, sans détail individuel.
//Les cas où l’on dispose à la fois des salaires parentaux et du total sont très rares (moins de 1 %). Les autres combinaisons partielles représentent environ 9,4 %.
//Globalement, la faible disponibilité des données individuelles limite les possibilités d’analyse détaillée sur la contribution de chaque parent au revenu du ménage.








