global chemin "C:\Users\gnint\OneDrive\Bureau\project_social_science\Clean_data\"



***** chargement de la base 
use "$chemin\base_final_type_formation.dta" , clear


********************************************************************
******* récuperation des données connexes
**********************************************************************
/* cette partie a pour objectif de recuperer le travail des enfants et également de targer les ménages Agricoles (A + E) et d'autres  en fonction de l'activité principale du CM */

preserve
use "C:\Users\gnint\OneDrive\Bureau\project_social_science\Raw_data\Fichiers_Traitement&AnalysePauvrete\ehcvm_individu_SEN2021.dta", clear


gen type_menage = branch

replace type_menage= 0 if branch==1 | branch==2

replace type_menage= 1 if branch==3 | branch==4

replace type_menage=  2 if branch==5

replace type_menage = 3 if branch >= 6 & !missing(branch)

tab branch type_menage if age<=16, missing 


***** recuperation du type menage
rename numind s01q00a

keep if lien == 1 //"Chef de ménage"
keep grappe menage type_menage 

* Sauvegarder temporairement cette base 
tempfile type_menage_cm
save `type_menage_cm'

***** creation de l avariable travaille enfant

restore  // Revenir à la base initiale



preserve
use "C:\Users\gnint\OneDrive\Bureau\project_social_science\Raw_data\Fichiers_Traitement&AnalysePauvrete\ehcvm_individu_SEN2021.dta", clear


gen type_menage = branch

replace type_menage= 0 if branch==1 | branch==2

replace type_menage= 1 if branch==3 | branch==4

replace type_menage=  2 if branch==5

replace type_menage = 3 if branch >= 6 & !missing(branch)

tab branch type_menage if age<=16, missing 


***** recuperation de l avariable travaille enfant
rename numind s01q00a
rename sexe sexe_new
keep grappe menage s01q00a type_menage sexe_new

rename type_menage type_travail_enfant
* Sauvegarder temporairement cette base 
tempfile type_menage_indicidu
save `type_menage_indicidu'



restore  // Revenir à la base initiale


************** merge des observations recupérées
merge m:1 grappe menage using `type_menage_cm', keep(match master) nogen

merge 1:1 grappe menage s01q00a using `type_menage_indicidu', keep(match master) nogen

************* recodage de la variable travail des enfants
replace type_travail_enfant = 1 if inrange(type_travail_enfant,0,3)
replace type_travail_enfant = 0 if missing(type_travail_enfant)

label define type_travail_enfant 0 "Ne travaille pas" 1 "travaille", modify
label values type_travail_enfant type_travail_enfant
codebook type_travail_enfant





********************************************************************
******* premiere approche : logit multinomiale
**********************************************************************

/* Ici on garde les 3 categories (formelle, non formelle, aucune formation). Et nous testons l'IIA avant de continuer */


*******  variable cible
codebook type_ecole

encode type_ecole, gen (type_ecole1)
codebook type_ecole1
replace type_ecole1=0 if type_ecole1== 1 
replace type_ecole1=1 if type_ecole1== 2 
replace type_ecole1=2 if type_ecole1== 3


label define type_ecole1 0 "Aucune formation" 1 "ecole formelle" 2 "ecole non formelle", modify
label values type_ecole1 type_ecole1
codebook type_ecole1


**** creation de la variable age2 et acte_naissance

replace acte_naissance= 2 if acte_naissance==1

gen age2=age*age

gen age_cm2=age_cm*age_cm


gen lien_cm_2=lien_cm
replace lien_cm_2=0 if lien_cm==1 | lien_cm==3
replace lien_cm_2=1 if lien_cm==2 | lien_cm==4
label define lien_cm_2 0 "Pas enfant" 1 "enfant", modify
label values lien_cm_2 lien_cm_2
codebook lien_cm lien_cm_2
tab lien_cm lien_cm_2

replace sexe = 0 if sexe == 1 
replace sexe=1 if sexe==2
label define sexe 0 "Masculin" 1 "Féminin", modify
label values sexe sexe
tab sexe

**** encodage de certaine variable qualitative

encode Niveau_etude_pere, gen (Niveau_etude_pere_lab)
encode Niveau_etude_mere, gen (Niveau_etude_mere_lab)
encode Niveau_etude_cm, gen (Niveau_etude_cm_lab)
encode Csp_mere, gen (Csp_mere_lab)
encode Csp_pere, gen (Csp_pere_lab)
encode Csp_cm, gen (Csp_cm_lab)
encode sit_mat_cm, gen (sit_mat_cm_lab)


*********** premiere regression sur tous les enfants 6 à 16 ans:


************************* modele simple

mlogit type_ecole1 i.sexe  i.wealth_index_ACM_q age age2   ///
	i.milieu_residence    ///
		 ,  nolog base(1)
		 
*mlogtest, iia

/*
Pour toutes les catégories, les p-values sont inférieures à 0.05, ce qui signifie que l'IIA est rejetée.

*/		 

************************** modele plus complexe

mlogit type_ecole1 i.sexe  i.wealth_index_ACM_q age age2   ///
	i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.lien_cm_2  /// 
		i.Niveau_etude_pere_lab i.sit_mat_cm_lab taille_menage    ///
		 ,  nolog base(1)
		 
**** test des alternatives non pertinenete: un peu biaisé sans pweight

*mlogtest, iia ////// L'hypothèse n'est pas verifé

// Hausman test version 1
//hausman m1 m2, alleqs constant
//suest m1 m2


*********** premiere regression sur tous les enfants de plus de 12 ans:

preserve

keep if age>=12

************************* modele simple

mlogit type_ecole1 i.sexe  i.wealth_index_ACM_q age age2   ///
	i.milieu_residence    ///
		 ,  nolog base(1)
		 
capture mlogtest, iia

/*
Pour toutes les catégories, les chi-deux sont négatifs ce qui signifie que l'IIA est rejetée. Mais le suest test p valeur > 0.05 donc c'est significatif

*/		 

************************** modele plus complexe

mlogit type_ecole1 i.sexe  i.wealth_index_ACM_q age age2   ///
	i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.lien_cm_2  /// 
		i.Niveau_etude_pere_lab i.sit_mat_cm_lab taille_menage    ///
		 ,  nolog base(1)
		 
**** test des alternatives non pertinenete: un peu biaisé sans pweight

capture mlogtest, iia 

////// L'hypothèse n'est pas verifé par les deux

restore

*******************************************************
/* conclusion on laisse le mlogit */
************************************************



********************************************************************
******* deuxième approche : logit binaire
**********************************************************************

/* Ici on garde les 2 categories (scolarisé= formelle, non scolarisé=non formelle ou aucune formation).  */


****creation de variable cible
encode type_ecole, gen(type_ecole2)
codebook type_ecole2
replace type_ecole2=0 if type_ecole2== 1 | type_ecole2 == 3 
replace type_ecole2=1 if type_ecole2== 2 

label define type_ecole2 0 "Non scolarisé" 1 "scolarisé", modify
label values type_ecole2 type_ecole2
codebook type_ecole2

tab type_ecole1 type_ecole2



*********** premiere regression sur tous les enfants 6 à 16 ans:


************************* modele simple


logit type_ecole2 i.sexe, nolog

logit type_ecole2  i.sexe [pweight=poids], nolog

/* mauavais R2 et aussi  coef de la femme> 0 ce qui est étrange */


************************* modele complexe

set showbaselevels on

logit type_ecole2 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.lien_cm_2  /// 
		i.Niveau_etude_pere_lab i.sit_mat_cm_lab taille_menage    ///
		 ,  nolog 

/*   avec et sans poids , on a coef de la femme> 0 ce qui est étrange */

margins, dydx(sexe) at(age=(6(1)16))
marginsplot

/* A tous les ages on constate que par rapport au  garçon les filles ont une prob plus élévé d'etre scolarisé et l'écart se réduit après 10 ans : ce qui est étrange*/


*********** deuxème regression sur tous les enfants 12 à 16 ans:

preserve

keep if age>=12
************************* modele simple


logit type_ecole2 i.sexe, nolog

logit type_ecole2  i.sexe [pweight=poids], nolog

/* mauavais R2 et aussi  coef de la femme> 0 ce qui est étrange */


************************* modele complexe

set showbaselevels on

logit type_ecole2 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.lien_cm_2  /// 
		i.Niveau_etude_pere_lab i.sit_mat_cm_lab taille_menage    ///
		 ,  nolog 

/*   avec et sans poids , on a coef de la femme> 0 ce qui est étrange */

margins, dydx(sexe) at(age=(12(1)16))
marginsplot

/* même Pb que precedemment*/



restore



********************************************************************
******* troisème approche : logit binaire
**********************************************************************

/* Ici on garde les 2 categories (scolarisé= formelle ou non formelle , non scolarisé=aucune formation).

en fait on suspecte que plus jeune les garcons vont en ecole non formelle pas quil ne sont pas inscrit. et c'est déja vu aux niveaux du tableaux. on regresse sur cette nouvelle variable pour voir si les resultats sont diff  */



****creation de variable cible

encode type_ecole, gen(type_ecole3)
codebook type_ecole3
replace type_ecole3=0 if type_ecole3== 1 
replace type_ecole3=1 if type_ecole3== 2 | type_ecole3 == 3 

label define type_ecole3 0 "Non scolarisé" 1 "scolarisé", modify
label values type_ecole3 type_ecole3
codebook type_ecole3

tab type_ecole1 type_ecole3


************************* modele complexe

set showbaselevels on

logit type_ecole3 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.lien_cm_2  /// 
		i.Niveau_etude_pere_lab i.sit_mat_cm_lab taille_menage  [pweight=poids]  ///
		 ,  nolog 

/*   avec et sans poids , on a coef de la femme <0 ce qui est coherent avec la réalité etles stat officielle */

margins, dydx(sexe) at(age=(6(1)16))
marginsplot


***********************************************
/* par conséquent on va utilisé le modele logit emboité*/

***************************************************






********************************************************************
******* quatrième approche : logit binaire emboité
**********************************************************************

//save "$chemin\base_nested_logit.dta", replace




/*nlogitgen nestvar = type_ecole1 (0, 1 | 2)

nlogitgen subnestvar = type_ecole1 (1 , 2)

*/


/*
egen individu_id = group(grappe menage s01q00a)
gen id_long = _n

// 1. Obtenir les modalités uniques de type_ecole1
//levelsof type_ecole1, local(modalites)

// 3. Créer une nouvelle variable qui permet de répéter les lignes pour chaque alternative (copier 3 lignes par individu)
gen id_long = _n
expand 3

// 2. Créer une variable indiquant l'alternative
gen alt = .
replace alt = 0 if type_ecole1 == 0
replace alt = 1 if type_ecole1 == 1
replace alt = 2 if type_ecole1 == 2

label define alt 0 "Aucune formation" 1 "ecole formelle" 2 "ecole non formelle", modify
label values alt alt


keep individu_id



// 4. Créer la variable modalite en fonction des alternatives
bysort individu_id (id_long): replace alt = mod(_n-1, 3)

// 5. Créer la variable choix (qui indique l'alternative choisie)
gen choix = (type_ecole1 == alt)

gen nestvar = .
replace nestvar = 1 if alt == 0  // Nid pour "Aucune formation"
replace nestvar = 2 if alt == 1 | alt == 2  // Nid pour "École formelle" et "École non formelle"

gen subnestvar = .
replace subnestvar = 1 if alt == 1  // Sous-nid pour "École formelle"
replace subnestvar = 2 if alt == 2  // Sous-nid pour "École non formelle"

nlogit choix i.sexe || nestvar:, base(1) case(individu_id) ///
       || subnestvar:, base(1)

codebook nestvar


*/

gen formelle = .
replace formelle = 0 if type_ecole1 == 2  // Nid pour "École non formelle"
replace formelle = 1 if type_ecole1 == 1  // Nid pour "École formelle" et "École non formelle"

label define formelle 0 "École non formelle" 1 "École formelle" , modify
label values formelle formelle 



codebook Niveau_etude_mere_lab 




*************************************************************
************** premier niveau du nested logit **************
***********************************************************


/* deja defini plus haut: ou commencer ici si le haut n'est pas exécuté
****creation de variable cible

encode type_ecole, gen(type_ecole3)
codebook type_ecole3
replace type_ecole3=0 if type_ecole3== 1 
replace type_ecole3=1 if type_ecole3== 2 | type_ecole3 == 3 

label define type_ecole3 0 "Non scolarisé" 1 "scolarisé", modify
label values type_ecole3 type_ecole3
codebook type_ecole3

tab type_ecole1 type_ecole3


gen formelle = .
replace formelle = 0 if type_ecole1 == 2  // Nid pour "École non formelle"
replace formelle = 1 if type_ecole1 == 1  // Nid pour "École formelle" et "École non formelle"

label define formelle 0 "École non formelle" 1 "École formelle" , modify
label values formelle formelle 
	
	
*/
***   Diagnostic
qui glm type_ecole3 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage enfants_6_16 [pweight=poids],   ///
    family(binomial) link(logit) nolog


	

* nous allons analyser les outlier( les observation qui ont un r괩du  tr鳠grand) 
* et les observations influantes qui sont ࡬a fois ab곡nte et qui font changer la pente  (influential)*

/*ici oncherche lesoutliers */
* pour predire le r괩du l'option rs pour dire standar residu de Pearson(pregibon) *

predict residu,res
*tri d'une variable
generate index =_n
label var index " numero d'observation"
graph twoway scatter residu index, yline(-2 2)

*liste des individus qui violent la condition*
list index sexe age if abs(residu)>2  
// on pas d'outliers

* Pour predire les hii de Pregibom (1981) on met en option hat prediction des hii 


qui  logit type_ecole3 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage enfants_6_16  ///
		 ,  nolog 
predict hii,hat // car predict ne prend pas en compte les poids 
graph twoway scatter hii index, yline(-2 2)

* Distance de cook ca coincide avec le dbeta*
predict dcook1, dbeta

label var dcook1 "cook's statistique"
graph twoway scatter dcook index, yline(0) mlabel(index)	
	
list index sexe age if abs(dcook1)>4/20134
display(4/20134)
count if abs(dcook1)>1/10   //4/20134 dection outliers



******** qualité de l'ajustement
replace Niveau_etude_mere_lab = 5 if Niveau_etude_mere_lab == 6
replace Csp_mere_lab = 4 if Csp_mere_lab == 1
************* test de vraisemblance

qui logit type_ecole3 if abs(residu)<2 & dcook1 <1/10 & hii<0.5, nolog // modèle restreint
estimates store m0


qui logit type_ecole3 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Csp_mere_lab  i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage   ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 

est store m1


lrtest m0 m1   // test de rapport de vraisemblance

/* on rejette la nullité globale des coef*/

********************test de nullité de certain coef

testparm i.milieu_residence#i.region
/* les coef sont  stat diff de 0*/

testparm i.lien_cm_2 
/* le coef de lien_cm_2 ne sont pas stat diff de 0*/

testparm taille_menage /* les coef sont  stat diff de 0*/

testparm i.sit_mat_cm_lab /* les coef ne sont pas stat diff de 0*/

testparm i.Niveau_etude_pere_lab /* les coef sont  stat diff de 0*/
testparm i.Niveau_etude_mere_lab /* les coef sont  stat diff de 0*/
testparm i.Niveau_etude_cm_lab /* les coef sont  stat diff de 0*/
testparm i.Csp_pere_lab /* les coef ne sont pas stat diff de 0*/
testparm i.Csp_mere_lab /* les coef sont  stat diff de 0*/
testparm i.acte_naissance /* les coef sont  stat diff de 0*/


**************** comparaison probit logit

set showbaselevels on

qui logit type_ecole3  i.sexe_cm i.sexe i.wealth_index_ACM_q age age2   ///
	 i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Csp_mere_lab  ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
		 taille_menage   ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 
estimates store logitmodel
****** pour apprehend顬e pouvoir explicatif du mod魥 
lstat
*lroc pour voir le pouvoir discriminant selon l'air de la courbe (Long et Freese 2006) 0.9<roc<1 "excellent 0.8<=Roc<90 "Bonne" 0.7<ROC<0.8 "Faible" 0.6<ROC<0.7 " tr鳠Faible" si non "Mauvais*
lroc ,  ytitle("Sensitivité") ///
		 xtitle("1-spécificité") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))
*Pour changer de seuil  lstat,cutoff(seuil)*
*** lsens fait un graph des courbes de sensitivity et specificit 
lsens

**********test de validation de — Pearson or Hosmer–Lemeshow goodness-of-fit test

estat gof // le modele est adequat

estat gof, group(100)
fitstat

qui probit type_ecole3  i.sexe_cm i.sexe i.wealth_index_ACM_q age age2   ///
	 i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Csp_mere_lab  ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
		 taille_menage   ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 

estimates store probitmodel
lstat
lroc
lsens
estat gof // le modele est adequat

estat gof, group(100)
fitstat
estimates stats logitmodel probitmodel

/* logit: meilleur AUC et meilleur classement */
 

***  sortie desresultats

set showbaselevels on


putexcel set resultats_type_ecole_6_16ans, replace

logit type_ecole3  i.sexe_cm i.sexe i.wealth_index_ACM_q age age2   ///
	 i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab 4.Csp_mere_lab  ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
		 taille_menage [pweight=poids]  ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog or
	estimates store scolarisation
putexcel (A1) = etable

************* graphique


* Installer coefplot si besoin :
ssc install coefplot

* Graphique des OR avec IC :
	
coefplot, eform xline(1) drop(_cons) ///
    keep(age age2 2.wealth_index_ACM_q 3.wealth_index_ACM_q 4.wealth_index_ACM_q 5.wealth_index_ACM_q ///
         3.acte_naissance ///
         3.Niveau_etude_mere_lab 4.Niveau_etude_mere_lab 5.Niveau_etude_mere_lab) ///
	 rename( ///
        2.wealth_index = "Revenu : Les pauvres" ///
        age = "Âge" ///
        age2 = "Âge²" ///
        3.acte_naissance = "Acte de naissance : Oui" ///   
        3.Niveau_etude_mere_lab = "Éducation mère : Primaire" ///
    ) ///
    title("Effet (OR) sur la scolarisation") ///
    note("Références : Revenu = Très pauvres | Éducation mère = Aucune") ///
    ylabel(, labsize(medlarge)) ///  
    xlabel(0.5(0.5)6) ///
    graphregion(color(white)) 

	
	
	

coefplot, eform xline(1) drop(_cons) ///
    keep(age age2 2.wealth_index_ACM_q 3.wealth_index_ACM_q 4.wealth_index_ACM_q 5.wealth_index_ACM_q ///
         3.acte_naissance ///
         2.Niveau_etude_mere_lab 3.Niveau_etude_mere_lab 4.Niveau_etude_mere_lab 5.Niveau_etude_mere_lab) ///
    rename( ///
        2.wealth_index_ACM_q = "Revenu : Les pauvres" ///
        3.wealth_index_ACM_q = "Revenu : Les médians" ///
        4.wealth_index_ACM_q = "Revenu : Les aisés" ///
        5.wealth_index_ACM_q = "Revenu : Les plus aisés" ///
        age = "Âge" ///
        age2 = "Âge²" ///
        3.acte_naissance = "Acte de naissance : Oui" ///
        2.Niveau_etude_mere_lab = "Éducation mère : Non déterminé" ///
        3.Niveau_etude_mere_lab = "Éducation mère : Primaire" ///
        4.Niveau_etude_mere_lab = "Éducation mère : Secondaire 1er cycle" ///
        5.Niveau_etude_mere_lab = "Éducation mère : Secondaire 2e cycle" ///
    ) ///
    title("Effet des caractéristiques sur le type d'école choisie") ///
    note("Références : Revenu = Très pauvres | Éducation mère = Aucune") ///
    //ylabel(, labsize(medlarge)) ///
    xlabel(0.5(0.5)6) ///
    graphregion(margin(l+25))








*** effet marginaux

**** effet marginaux moyen
putexcel set effet_marginaux_type_ecole_6_16ans, replace
logit type_ecole3  i.sexe_cm i.sexe i.wealth_index_ACM_q age age2   ///
	 i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab 4.Csp_mere_lab  ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
		 taille_menage [pweight=poids]  ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 
margins, dydx(*)
putexcel (A1) = etable	
	
/* Changement de prob en moyenne ceteris paribus
wealth_index_ACM_q : gradient croissant
 Effet marginal de +0.073 → +0.139 selon le niveau de richesse
 Plus on est aisé, plus la probabilité augmente fortement (effet très significatif).

age & age² :
 age positif (+0.186) mais age² négatif (-0.0073)
 C’est une relation non linéaire : la probabilité augmente avec l’âge, mais à un rythme décroissant.
*/
	

	

**** calcul des effetx marginaux
logit type_ecole3  i.sexe_cm i.sexe i.wealth_index_ACM_q age age2   ///
	 i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab b4.Csp_mere_lab  ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
		 taille_menage [pweight=poids]  ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog
		
		
********* 1. Effets marginaux des variables sociodémographiques


******Sexe de l'enfant (i.sexe) :

margins, dydx(sexe) at(age=(6(1)16))
marginsplot

/*
Tous les effets marginaux sont negatifs et significatifs (p > 0.05), ce qui signifie que les filles ont une probabilité MOINS élevée d'être scolarisées que les garçons, à tous les âges étudiés (6 à 16 ans).

Sur toute la plage des cas testés, le sexe ne semble pas avoir d’effet statistiquement significatif sur la probabilité d’être scolarisé (vs jamais allé à l’école).

L’effet marginal est toujours négatif, ce qui suggère que les filles sont légèrement moins susceptibles d’être scolarisées... mais l’effet est faible et non significatif.
*/

margins sexe,  at(age=(6(1)16))
marginsplot


/*
1.  Progression avec l’âge :
La probabilité d’être scolarisé augmente fortement avec l’âge pour les deux sexes, ce qui est totalement logique : plus un enfant est âgé, plus il a de chances d’avoir été ou d’être à l’école.

2. Différence garçons/filles :
Les deux lignes se superposent presque parfaitement sur toute la plage d’âge.

Les intervalles de confiance se chevauchent complètement, ce qui indique aucune différence statistiquement significative entre garçons et filles dans la probabilité d’être scolarisé, à tous les âges.

*/

margins sexe
marginsplot

/*
 

*/

********** effet marg du Niveau richess
margins, dydx(wealth_index_ACM_q) at(age=(6(1)16))
marginsplot

/*
 1. Effets positifs clairs de la richesse
Tous les niveaux de richesse (du 2ᵉ au 5ᵉ quintile) augmentent la probabilité d’être scolarisé par rapport au groupe de référence (les plus pauvres = 1).

Plus le niveau de richesse est élevé ➤ plus l’effet est grand :

Le quintile 5 (les plus aisés) a l’effet marginal le plus fort sur la scolarisation.

2. Dynamique selon l’âge
L’effet de la richesse augmente au début (jusqu’à ~8-9 ans), puis diminue progressivement avec l’âge.

donc la richesse joue un rôle crucial pour initier la scolarisation, mais son importance diminue avec l’âge (peut-être parce que ceux qui n’étaient pas scolarisés dès le départ ne rattrapent pas).

3. Différences statistiquement significatives
Les barres d’erreur (IC95%) ne se chevauchent pas trop entre les quintiles, surtout autour des âges 7 à 12 ➤ cela indique que les différences entre groupes de richesse sont significatives statistiquement.
*/






******** Âge de l’enfant (age et age²) :

L'effet marginal de l'âge est important car il permet de voir si la scolarisation diminue avec l’âge.

L’effet quadratique (age²) permet de détecter une tendance non linéaire : y a-t-il un âge critique où le risque de non-scolarisation augmente ?

****** Lien avec le chef de ménage (i.lien_cm_2) :

Les enfants qui ne sont pas les enfants biologiques du chef de ménage sont-ils moins scolarisés ?

Effet spécifique pour les orphelins ou les enfants vivant chez un tuteur ?


		
********** milieu de residence

margins milieu_residence
marginsplot
////// mais voici les disparités rrégionales suivant l'âge
margins, dydx(milieu_residence) at(age=(6(1)16))
marginsplot


margins, dydx(milieu_residence)  at(region=(1(1)5))
marginsplot

margins, dydx(milieu_residence) at(age=(6(1)16) region=(1(1)6)) 
marginsplot,  ytitle("Effets marginaux du milieu rural") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))


margins, dydx(milieu_residence) at(age=(6(1)16) region=(7(1)14)) 
marginsplot,  ytitle("Effets marginaux du milieu rural") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))



********** acte de naissance

margins acte_naissance
marginsplot


margins, dydx(acte_naissance) at(age=(6(1)16))
marginsplot

margins, dydx(acte_naissance) at(age=(6(1)16) milieu_residence=(1(1)2))
marginsplot, ytitle("Effets marginaux") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))


****** Csp_pere_lab

margins Csp_pere_lab
marginsplot

margins,  dydx(Csp_pere_lab) // on ne fera rien de ce plot
marginsplot

// ce graph est à revoir

margins, dydx(Csp_mere_lab)

marginsplot, ///
    title("Effets marginaux de la CSP de la mère") ///
    ytitle("Effet marginal") ///
    ylabel(, angle(horizontal)) ///
    recast(bar) ///
    plotopts(fcolor(gs12) lcolor(black)) ///
    graphregion(color(white)) ///
    scheme(s1color)


margins,  dydx(Csp_mere_lab) at(age=(6(1)16) )
marginsplot


***** niveau d'etude







*************************************************************
************** Deuxieme niveau du nested logit **************
***********************************************************

	
***   Diagnostic
qui glm formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage enfants_6_16 [pweight=poids],   ///
    family(binomial) link(logit) nolog


	

* nous allons analyser les outlier( les observation qui ont un r괩du  tr鳠grand) 
* et les observations influantes qui sont ࡬a fois ab곡nte et qui font changer la pente  (influential)*

/*ici oncherche lesoutliers */
* pour predire le r괩du l'option rs pour dire standar residu de Pearson(pregibon) *
drop residu
predict residu,res
*tri d'une variable

graph twoway scatter residu index, yline(-2 2)

*liste des individus qui violent la condition*
 
count if abs(residu)>2  
// on pas d'outliers ce sont les NA du nid 2

* Pour predire les hii de Pregibom (1981) on met en option hat prediction des hii 


qui  logit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage enfants_6_16  ///
		 ,  nolog 
drop hii
predict hii,hat // car predict ne prend pas en compte les poids 
graph twoway scatter hii index, yline(-2 2)

* Distance de cook ca coincide avec le dbeta*
drop dcook1
predict dcook1, dbeta

label var dcook1 "cook's statistique"
graph twoway scatter dcook index, yline(0) mlabel(index)	
	
list index sexe age if abs(dcook1)>4/16265
display(4/16265)
count if abs(dcook1)>1/10   //4/16265 dection outliers
# on a quelques outliers


******** qualité de l'ajustement
// car la cat 5 predit parfaitement eocle formelle
replace sit_mat_cm_lab = 6 if sit_mat_cm_lab == 5


************* test de vraisemblance

qui logit formelle if abs(residu)<2 & dcook1 <1/10 & hii<0.5, nolog // modèle restreint
estimates store m0


qui logit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Csp_mere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage  enfants_6_16 ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 

est store m1


lrtest m0 m1   // test de rapport de vraisemblance

/* on rejette la nullité globale des coef*/

********************test de nullité de certain coef

testparm i.milieu_residence#i.region
/* les coef sont  stat diff de 0*/

testparm i.lien_cm_2 
/* le coef de lien_cm_2  sont  stat diff de 0*/

testparm taille_menage /* les coef sont  stat diff de 0*/
testparm enfants_6_16 /* les coef sont  stat diff de 0*/


testparm i.sit_mat_cm_lab /* les coef  sont  stat diff de 0*/

testparm i.Niveau_etude_pere_lab /* les coef sont  stat diff de 0*/
testparm i.Niveau_etude_mere_lab /* les coef sont  stat diff de 0*/
testparm i.Niveau_etude_cm_lab /* les coef sont  stat diff de 0*/
testparm i.Csp_pere_lab /* les coef  sont  stat diff de 0*/
testparm i.Csp_mere_lab /* les coef sont  stat diff de 0*/
testparm i.acte_naissance /* les coef sont  stat diff de 0*/


**************** comparaison probit logit

set showbaselevels on

qui logit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Csp_mere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage  enfants_6_16 ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 

estimates store logitmodel
****** pour apprehend顬e pouvoir explicatif du mod魥 
lstat  // taux de bon classification 80,54%


*lroc pour voir le pouvoir discriminant selon l'air de la courbe (Long et Freese 2006) 0.9<roc<1 "excellent 0.8<=Roc<90 "Bonne" 0.7<ROC<0.8 "Faible" 0.6<ROC<0.7 " tr鳠Faible" si non "Mauvais*
lroc ,  ytitle("Sensitivité") ///
		 xtitle("1-spécificité") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))
			  // AUC = 0.831
*Pour changer de seuil  lstat,cutoff(seuil)*
*** lsens fait un graph des courbes de sensitivity et specificit 
lsens

**********test de validation de — Pearson or Hosmer–Lemeshow goodness-of-fit test

estat gof // le modele est adequat

estat gof, group(10)
fitstat

qui probit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab i.Csp_mere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage  enfants_6_16 ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 

estimates store probitmodel
lstat // taux de bon classification 80,51%
lroc
lsens
estat gof // le modele est adequat

estat gof, group(100)
fitstat
estimates stats logitmodel probitmodel

/* probit et logit ont les meme performance: meilleur AUC et meilleur classement */
 

***  sortie desresultats

set showbaselevels on


putexcel set resultats_type_ecole_formelle_6_16ans, replace

logit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance b4.Csp_pere_lab b4.Csp_mere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage  enfants_6_16 ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
	[pweight=poids],  nolog or 
	
	estimates store type_formation


putexcel (A1) = etable




************* graphique


* Installer coefplot si besoin :
ssc install coefplot

* Graphique des OR avec IC :
	
coefplot, eform xline(1) drop(_cons) ///
    keep(age age2 2.wealth_index_ACM_q 3.wealth_index_ACM_q 4.wealth_index_ACM_q 5.wealth_index_ACM_q ///
         3.acte_naissance ///
         3.Niveau_etude_mere_lab 4.Niveau_etude_mere_lab 5.Niveau_etude_mere_lab ///
		 2.Niveau_etude_pere_lab 3.Niveau_etude_pere_lab 4.Niveau_etude_pere_lab 5.Niveau_etude_pere_lab ///
		1.sexe   1.lien_cm_2 taille_menage enfants_6_16) ///
	 rename( ///
	 1.lien_cm_2= "Lien avec CM: enfant" ///
		1.sexe="sexe enfant: féminin" ///
        2.wealth_index = "Revenu : Les pauvres" ///
        age = "Âge" ///
        age2 = "Âge²" ///
        3.acte_naissance = "Acte de naissance : Oui" ///   
        3.Niveau_etude_mere_lab = "Éducation mère : Primaire" ///
		2.Niveau_etude_pere_lab = "Éducation père : Primaire" ///
    ) ///
    title("Effet (OR) sur le type de formation") ///
    note("Références : Revenu = Très pauvres | Éducation mère = Aucune") ///
    ylabel(, labsize(medlarge)) ///  
    xlabel(0.5(0.5)6) ///
    graphregion(color(white)) 

codebook Csp_pere_lab

coefplot, eform xline(1) drop(_cons) ///
    keep(1.Csp_pere_lab 3.Csp_pere_lab 6.Csp_pere_lab 5.Csp_pere_lab 7.Csp_pere_lab 8.Csp_pere_lab ///
	 1.Csp_mere_lab 3.Csp_mere_lab 6.Csp_mere_lab 5.Csp_mere_lab 7.Csp_mere_lab 8.Csp_mere_lab) ///
	  rename( ///
	 1.Csp_pere_lab= "CSP du Père: Cadre" ///
	  1.Csp_mere_lab= "CSP de la Mère: Cadre" ///
		) ///
    title("Effet (OR) sur le type de formation") ///
    note("Références : CSP = employeur qualifié") ///
    ylabel(, labsize(medlarge)) ///  
    xlabel(0.5(0.5)6) ///
    graphregion(color(white)) 


	
*********** j'esaaye quelque chose

 coefplot scolarisation type_formation, eform xline(1) drop(_cons) ///
    keep(age age2 2.wealth_index_ACM_q 3.wealth_index_ACM_q 4.wealth_index_ACM_q 5.wealth_index_ACM_q ///
         3.acte_naissance ///
         3.Niveau_etude_mere_lab 4.Niveau_etude_mere_lab 5.Niveau_etude_mere_lab ///
		 2.Niveau_etude_pere_lab 3.Niveau_etude_pere_lab 4.Niveau_etude_pere_lab 5.Niveau_etude_pere_lab ///
		1.sexe   1.lien_cm_2 taille_menage enfants_6_16) ///
	 rename( ///
	 1.lien_cm_2= "Lien avec CM: enfant" ///
		1.sexe="sexe enfant: féminin" ///
        2.wealth_index = "Revenu : Les pauvres" ///
        age = "Âge" ///
        age2 = "Âge²" ///
        3.acte_naissance = "Acte de naissance : Oui" ///   
        3.Niveau_etude_mere_lab = "Éducation mère : Primaire" ///
		2.Niveau_etude_pere_lab = "Éducation père : Primaire" ///
    ) ///
    title("Effet (OR) sur la scolariastion") ///
    note("Références : Revenu = Très pauvres | Éducation mère = Aucune") ///
    ylabel(, labsize(medlarge)) ///  
    xlabel(0.5(0.5)6) ///
    graphregion(color(white)) 


	
	
coefplot scolarisation type_formation, eform xline(1) drop(_cons) ///
    keep(1.Csp_pere_lab 3.Csp_pere_lab 6.Csp_pere_lab 5.Csp_pere_lab 7.Csp_pere_lab 8.Csp_pere_lab ///
	 1.Csp_mere_lab 3.Csp_mere_lab 6.Csp_mere_lab 5.Csp_mere_lab 7.Csp_mere_lab 8.Csp_mere_lab) ///
	  rename( ///
	 1.Csp_pere_lab= "CSP du Père: Cadre" ///
	  1.Csp_mere_lab= "CSP de la Mère: Cadre" ///
		) ///
    title("Effet (OR) sur la scolarisation ") ///
    note("Références : CSP = employeur qualifié") ///
    ylabel(, labsize(medlarge)) ///  
    xlabel(0.5(0.5)6) ///
    graphregion(color(white))

*** effet marginaux

**** effet marginaux moyen
putexcel set effet_marginaux_type_ecole_formelle_6_16ans, replace
logit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab b4.Csp_mere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage  enfants_6_16 ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 
margins, dydx(*)
putexcel (A1) = etable	
	
/* Changement de prob en moyenne ceteris paribus

*/
	

	

**** calcul des effetx marginaux
logit formelle i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
	i.milieu_residence i.region i.milieu_residence##i.region  ///
	i.acte_naissance i.Csp_pere_lab b4.Csp_mere_lab i.Niveau_etude_cm_lab ///
    i.Niveau_etude_mere_lab i.Niveau_etude_pere_lab   /// 
	i.lien_cm_2 i.sit_mat_cm_lab ///
		 taille_menage  enfants_6_16 ///
	if abs(residu)<2 & dcook1 <1/10 & hii<0.5 ///
		 ,  nolog 
		
********* 1. Effets marginaux des variables sociodémographiques


******Sexe de l'enfant (i.sexe) : femme

margins, dydx(sexe) at(age=(6(1)16))
marginsplot, ytitle("Effets marginaux moyens sur le type d'école") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))

/*

*/

margins sexe,  at(age=(6(1)16))
marginsplot


/*


*/

margins sexe
marginsplot

/*
 

*/

********** effet marg du Niveau richess
margins, dydx(wealth_index_ACM_q) at(age=(6(2)16))
marginsplot, ytitle("Effets marginaux moyens sur le type d'école") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))
			  
margins, dydx(wealth_index_ACM_q) at(age=(6(1)16) milieu_residence=(1(1)2))
marginsplot, ytitle("Effets marginaux sur le type de formation") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))

			  
margins, dydx(milieu_residence) at(age=(6(1)16) wealth_index_ACM_q=(1(1)5))
marginsplot, ytitle("Effets marginaux sur le type de formation") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))			  
			  
/*
 
*/






******** Âge de l’enfant (age et age²) :

L'effet marginal de l'âge est important car il permet de voir si la scolarisation diminue avec l’âge.

L’effet quadratique (age²) permet de détecter une tendance non linéaire : y a-t-il un âge critique où le risque de non-scolarisation augmente ?

****** Lien avec le chef de ménage (i.lien_cm_2) :

Les enfants qui ne sont pas les enfants biologiques du chef de ménage sont-ils moins scolarisés ?

Effet spécifique pour les orphelins ou les enfants vivant chez un tuteur ?

margins, dydx(lien_cm_2) at(age=(6(1)16)) region=(1(1)7))
marginsplot

		
********** milieu de residence

margins milieu_residence
marginsplot
////// mais voici les disparités rrégionales suivant l'âge
margins, dydx(milieu_residence) at(age=(6(1)16))
marginsplot


margins, dydx(milieu_residence)  at(region=(1(1)5))
marginsplot

margins, dydx(milieu_residence) at(age=(6(1)16) region=(1(1)7)) 
marginsplot,  ytitle("Effets marginaux du milieu rural") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))


margins, dydx(milieu_residence) at(age=(6(1)16) region=(8(1)14)) 
marginsplot,  ytitle("Effets marginaux du milieu rural") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))



********** acte de naissance

margins acte_naissance
marginsplot


margins, dydx(acte_naissance) at(age=(6(1)16))
marginsplot

margins, dydx(acte_naissance) at(age=(6(1)16) milieu_residence=(1(1)2))
marginsplot, ytitle("Effets marginaux sur le type de formation") ///
              title("") ///
			  graphregion(color(white)) ///
              plotregion(style(none))


****** Csp_pere_lab

margins Csp_pere_lab
marginsplot

margins,  dydx(Csp_pere_lab) // on ne fera rien de ce plot
marginsplot

// ce graph est à revoir

margins, dydx(Csp_mere_lab)

marginsplot, ///
    title("Effets marginaux de la CSP de la mère") ///
    ytitle("Effet marginal") ///
    ylabel(, angle(horizontal)) ///
    recast(bar) ///
    plotopts(fcolor(gs12) lcolor(black)) ///
    graphregion(color(white)) ///
    scheme(s1color)


margins,  dydx(Csp_mere_lab) at(age=(6(1)16) )
marginsplot











































 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 




***III.2 Estimation avec variables explicatives 




glm type_ecole1 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
    i.milieu_residence i.region i.acte_naissance i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab /// 
    i.Csp_mere_lab  i.sit_mat_cm_lab taille_menage i.lien_cm_2 [pweight=poids], ///  
    family(binomial) link(logit) nolog


	
	
*III.3   Diagnostic
* nous allons analyser les outlier( les observation qui ont un r괩du  tr鳠grand) 
* et les observations influantes qui sont ࡬a fois ab곡nte et qui font changer la pente  (influential)*

/*ici oncherche lesoutliers */
* pour predire le r괩du l'option rs pour dire standar residu de Pearson(pregibon) *

predict residu,res
*tri d'une variable
generate index =_n
label var index " numero d'observation"
graph twoway scatter residu index, yline(-2 2)

*liste des individus qui violent la condition*
list index sexe age if abs(residu)>2  
// on pas d'outliers

* Pour predire les hii de Pregibom (1981) on met en option hat prediction des hii 


logit type_ecole1 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
    i.milieu_residence i.region i.acte_naissance i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab /// 
    i.Csp_mere_lab  i.sit_mat_cm_lab taille_menage i.lien_cm_2  ,  nolog  
predict hii,hat
graph twoway scatter hii index, yline(-2 2)

* Distance de cook ca coincide avec le dbeta*
predict dcook1, dbeta

label var dcook1 "cook's statistique"
graph twoway scatter dcook index, yline(0) mlabel(index)	
	

/*  On a pas d'ouliers ici , et jattends pour les individus influents  */

keep if abs(residu)<2 & dcook<0.02

tab Niveau_etude_mere_lab type_ecole1
tab Csp_mere_lab type_ecole1

replace Niveau_etude_mere_lab = 5 if Niveau_etude_mere_lab == 6
replace Csp_mere_lab = 4 if Csp_mere_lab == 1

tab Niveau_etude_mere_lab type_ecole1
tab Csp_mere_lab type_ecole1

logit  type_ecole1 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
    i.milieu_residence i.region i.acte_naissance i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab /// 
    i.Csp_mere_lab  i.sit_mat_cm_lab taille_menage i.lien_cm_2  ,  nolog 



	
**a.1: 

****** pour apprehend顬e pouvoir explicatif du mod魥 
lstat
*** ou encore 
estat classification, cutoff(0.6) // cutoff permetde definirleseuil debon classeùment

*** le seuil par defaut 0.5 pour changer en option cutoff(0.7) par exemple
*On peu effectuer des tests lineair
test age

*lroc pour voir le pouvoir discriminant selon l'air de la courbe (Long et Freese 2006) 0.9<roc<1 "excellent 0.8<=Roc<90 "Bonne" 0.7<ROC<0.8 "Faible" 0.6<ROC<0.7 " tr鳠Faible" si non "Mauvais*
lroc 
*Pour changer de seuil  lstat,cutoff(seuil)*
*** lsens fait un graph des courbes de sensitivity et specificit 
lsens
/*dans ce modèle le modèle a tendance a donné plus de probabilité à la spécificité quala sensitivité.
Ainsi,le modèle a tendance a mieux classé */

**********test de validation de — Pearson or Hosmer–Lemeshow goodness-of-fit test

estat gof

****** nullite des coef
testparm i.sexe i.sexe_cm i.wealth_index_ACM_q age age2 ///
   i.milieu_residence i.region i.acte_naissance ///
   i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab ///
   i.Csp_mere_lab i.sit_mat_cm_lab taille_menage i.lien_cm_2



fitstat
	
*** IIII  sortie desresultats

set showbaselevels on


putexcel set resultats_type_ecole_6_16ans, replace

logit type_ecole1 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
		i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
		i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab /// 
		i.sit_mat_cm_lab taille_menage i.lien_cm_2  [pweight=poids] ///
		if abs(residu)<2 & dcook<0.02 , or nolog 

putexcel (A1) = etable





****** effet marginaux
putexcel set effet_marginaux_type_ecole_6_16ans, replace
qui: logit type_ecole1 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
		i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
		i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab /// 
		i.sit_mat_cm_lab taille_menage i.lien_cm_2  [pweight=poids] ///
		if abs(residu)<2 & dcook<0.02 , or nolog 
margins, dydx(*)
putexcel (A1) = etable	
	

	

	

****calcul des effetx marginaux
logit type_ecole1 i.sexe i.sexe_cm i.wealth_index_ACM_q age age2   ///
		i.milieu_residence##i.region i.acte_naissance i.Csp_mere_lab ///
		i.Niveau_etude_mere_lab i.Niveau_etude_cm_lab i.Niveau_etude_pere_lab /// 
		i.sit_mat_cm_lab taille_menage i.lien_cm_2 [pweight=poids] ///
		if abs(residu)<2 & dcook<0.02  , or nolog 
		

logit type_ecole1 i.sexe i.type_travail_enfant age age2 [pweight=poids],or  

///
		if abs(residu)<2 & dcook<0.02  , or nolog 
		
		
		
********* 1. Effets marginaux des variables sociodémographiques


******Sexe de l'enfant (i.sexe) :

margins, dydx(sexe) at(age=(6(1)16))
marginsplot

/*
Tous les effets marginaux sont positifs et significatifs (p < 0.01), ce qui signifie que les filles ont une probabilité plus élevée d'être scolarisées que les garçons, à tous les âges étudiés (6 à 16 ans).


L'effet est plus fort entre 7 et 9 ans (entre 2,2 et 3,3 points de pourcentage de plus pour les filles).

L'effet diminue progressivement après 10 ans, atteignant seulement 0,8 point de pourcentage à 16 ans.

Interprétation : Entre 6 et 12 ans, l'effet du sexe est plus fort, indiquant que les filles ont un avantage marqué dans l'accès à l'école.
Cet avantage diminue à l’adolescence, ce qui peut suggérer que d'autres facteurs (mariage précoce, travail domestique, etc.) 
"ici pas le mariage précode car la sit mat des enfnats montre que 99% des enfnats sont celibataires"
commencent à jouer un rôle dans la scolarisation des filles.

*/

margins sexe,  at(age=(6(1)16))
marginsplot


/*
À 6 ans : Garçons : 36,2%  Filles : 47,3%
→ Écart de 11,1 points de pourcentage en faveur des filles.

À 12 ans Garçons : 67,7%  Filles : 70,1%
→ L'écart se réduit (2,4 points).

À 16 ans : Garçons : 96,5%  Filles : 97,4%
→ Presque plus de différence (0,9 point).

Interprétation clé :  Les filles ont des prob de scolarisation plus élevés que les garçons à tous les âges, mais l'écart est beaucoup plus marqué chez les plus jeunes.
La tendance se stabilise après 12 ans, où les écarts deviennent très faibles.
Cela suggère que les garçons peuvent être plus vulnérables à la non-scolarisation au début du cycle scolaire (peut-être en raison du travail ou d'autres obligations familiales).

*/

margins sexe
marginsplot

/*
 en moyenne Différence : +6,7 points de pourcentage en faveur des filles

Cette différence est statistiquement significative (p < 0.001).

*/

***************************** effet marg du sexe selon richess
margins, dydx(sexe) at(type_travail_enfant=(0(1)1))
marginsplot







******** Âge de l’enfant (age et age²) :

L'effet marginal de l'âge est important car il permet de voir si la scolarisation diminue avec l’âge.

L’effet quadratique (age²) permet de détecter une tendance non linéaire : y a-t-il un âge critique où le risque de non-scolarisation augmente ?

****** Lien avec le chef de ménage (i.lien_cm_2) :

Les enfants qui ne sont pas les enfants biologiques du chef de ménage sont-ils moins scolarisés ?

Effet spécifique pour les orphelins ou les enfants vivant chez un tuteur ?


		
********** milieu de residence

margins, dydx(milieu_residence) at(age=(6(1)16))
marginsplot


margins milieu_residence,  at(age=(12(1)15))
marginsplot



















***calcul des proba predict
prtab acte_naissance


//logit abo sex_fem sitfam_mar sitfam_celib csp_ouv csp_empl sal age,or
//listcoef age


predict el, xb
graph twoway scatter el age, xlabel(10(2)16) ylabel(-3 .6)


*****

predict p1, xb
predict sep1, stdp
gen ulp1 = p1+1.96*sep1
gen llp1 = p1-1.96*sep1

	
*


set showbaselevels on

fitstat
**fitstat permet dedonnerles critère d'informations
mfx
mfx compute, at (age=25, csp_ouv=1 , sitfam=1)
sum age
* grées cotes des indvidus*
predict pr if e(simple),p
gen ci=pr/(1-pr)
list ci



























