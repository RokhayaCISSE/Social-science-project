				*****************************************************************
			   *                     SOCIAL SCIENCE PROJECT                    *
			  *       NOUBOUSSI MARIMAR                                       *                                      
			 *       CISSE Rokhaya                                           *
			*                                                              *
		   *     MODELISATION DE L'EVOLUTION DU RISQUE D'ABANDON          *
		  ****************************************************************
  
  /// Importation des données 
  
use "C:\Users\LENOVO\Downloads\base_final_type_formation.dta" ,clear
   
  /// Preparation des donnees

* Remplacer "Non déterminée" quand c mal ecrit
replace  Niveau_etude_mere = "Non déterminée" if  Niveau_etude_mere == "Non déternimé"

* Créer un identifiant unique pour chaque individu
gen id = _n

* Stocker la durée dans une variable "duree"
gen duree = duree_etude_avant_abandon

* Passer les données en format long (une ligne par période par individu)
expand duree
bysort id (duree): gen periode = _n

* Créer une variable indiquant l'événement (abandon à cette période)
gen fail = (periode == duree)

* Vérification de la structure
list id duree periode fail in 1/10

* Histogramme de la durée avant l'abandon
summarize duree
local max_duree = r(max)
histogram duree, frequency title("Distribution de la durée d'étude avant abandon") ///
    xlabel(0(1)`max_duree') ylabel(, angle(0)) ///
    legend(off)
	
  /// Vizualisations

* Spécification de l'événement et du temps
stset duree, failure(fail)

* Courbe de survie Kaplan-Meier
sts graph, ///
    title("Courbe de survie - Abandon scolaire") ///
    ylabel(0(0.1)1, angle(0)) ///
    xlabel(0(1)13) ///
    legend(off)
	
  /// Selection des variables potentielles de risques
  
* Vizualisations ***************************

* --- Recode par les labels pour les variables spécifiques
local vars presence_pere region wealth_index_ACM_q milieu_residence sexe_cm sexe

foreach var of local vars {
    decode `var', gen(`var'_label)
}


* --- Préparation des Variables
local categorical_vars presence_pere_label region_label Niveau_etude_pere Niveau_etude_mere ///
                       Csp_pere Csp_mere Csp_cm Niveau_etude_cm wealth_index_ACM_q_label ///
                       milieu_residence_label sit_mat_cm sexe_cm_label sexe_label periode

* --- Définir la durée et l'événement
stset duree, failure(fail)

* --- Liste pour enregistrer les graphiques
local graph_list ""

foreach var of local categorical_vars {
    display "===================================="
    display "Kaplan-Meier pour : `var'"
    
    * --- Récupérer les modalités (valeurs distinctes)
    levelsof `var', local(modalities)

    * --- Initialiser la légende propre
    local legend_labels ""
    local i = 1
    foreach mod of local modalities {
        local legend_labels `legend_labels' label(`i' "`mod'")
        local ++i
    }

    * --- Tracer le graphique avec légende propre (multi-lignes)
    * --- Si la variable est Csp_cm, Csp_pere ou Csp_mere, on applique un style optimisé
    if inlist("`var'", "Csp_cm", "Csp_pere", "Csp_mere", "region") {
        sts graph, by(`var') ///
            ylabel(0(0.1)1, angle(0)) ///
            xlabel(0(1)13) ///
            title("") ///
            legend(on rows(4) cols(2) size(vsmall)) ///
            legend(`legend_labels') ///
	       xtitle("Durée (en années)") /// <- Libellé de l'axe X
        ytitle("Probabilité de survie (%)") /// <- Libellé de l'axe Y
		       plotregion(fcolor(none)) /// <- Supprimer le fond
        graphregion(fcolor(white)) /// <- Fond blanc
            name(`var'_km, replace)
    }
    else {
        sts graph, by(`var') ///
            ylabel(0(0.1)1, angle(0)) ///
            xlabel(0(1)13) ///
            title("") ///
            legend(on rows(3) cols(2) size(small)) ///
            legend(`legend_labels') ///
		       xtitle("Durée (en années)") /// <- Libellé de l'axe X
        ytitle("Probabilité de survie (%)") /// <- Libellé de l'axe Y
		       plotregion(fcolor(none)) /// <- Supprimer le fond
        graphregion(fcolor(white)) /// <- Fond blanc
            name(`var'_km, replace)
    }
    
    * --- Ajouter le graphique à la liste
    local graph_list `graph_list' `var'_km
}

* --- Combinaison des Graphiques en un seul affichage
graph combine `graph_list', ///
    title("Courbes de survie combinées") ///
    cols(3) ///
    iscale(0.9)
	
//L'analyse des courbes de survie Kaplan-Meier révèle des différences notables dans la probabilité de survie selon plusieurs caractéristiques socio-économiques, géographiques et familiales. Les résultats montrent que le niveau d'éducation des parents influence significativement la survie. Les enfants dont le père ou la mère possède un niveau d'éducation supérieur présentent une probabilité de survie plus élevée, tandis que ceux dont les parents ont un niveau primaire ou aucun diplôme enregistrent une décroissance plus rapide des courbes. Cette tendance est également observée au niveau de la catégorie socioprofessionnelle (CSP) des parents : les enfants issus de familles où le père ou la mère est cadre ou employé de bureau affichent une survie plus importante par rapport à ceux dont les parents sont agriculteurs, ouvriers ou sans emploi.

//Sur le plan géographique, les courbes Kaplan-Meier montrent une différence marquée entre les régions. Les enfants vivant dans les régions de Dakar et Thiès présentent une probabilité de survie plus élevée que ceux résidant dans les régions de Kolda, Kaffrine ou Tambacounda. Par ailleurs, les enfants habitant en milieu urbain affichent une meilleure persistance par rapport à ceux vivant en milieu rural, les courbes étant bien distinctes tout au long de la période d'analyse.

//L'analyse met également en évidence l'impact de la situation matrimoniale du chef de ménage sur la survie. Les enfants issus de ménages monogames ou dirigés par un chef de ménage célibataire présentent une survie plus élevée par rapport à ceux provenant de ménages polygames, dont les courbes déclinent plus rapidement. Enfin, l'indice de richesse (Wealth Index ACM) révèle une forte corrélation avec la probabilité de survie : les quintiles les plus élevés montrent une meilleure persistance, alors que les quintiles les plus faibles enregistrent une décroissance rapide.

//Les différences entre les sexes apparaissent relativement faibles, avec un léger avantage en termes de survie pour les filles par rapport aux garçons, mais les courbes évoluent de manière parallèle, suggérant un écart limité. Globalement, les courbes restent distinctes et parallèles pour la plupart des variables analysées, suggérant une certaine stabilité des différences au fil du temps.


* --- Création de la variable region2
gen region2 = ""
replace region2 = "DAKAR" if region_label == "DAKAR"
replace region2 = "ZIGUINCHOR" if region_label == "ZIGUINCHOR"
replace region2 = "AUTRES REGIONS" if region_label != "DAKAR" & region_label != "ZIGUINCHOR"

* --- Vérification
tabulate region2

* --- Création de la variable d'interaction zone
gen zone = region2 + " - " + milieu_residence_label

* --- Vérification
tabulate zone

* --- Définir la durée et l'événement
stset duree, failure(fail)

* --- Tracer le graphique Kaplan-Meier pour la variable zone
sts graph, by(zone) ///
    ylabel(0(0.1)1, angle(0)) ///
    xlabel(0(1)13) ///
    xtitle("Durée (en années)") ///
    ytitle("Probabilité de survie (%)") ///
    title("Courbe de survie Kaplan-Meier par Zone") ///
    legend(on rows(3) cols(2) size(vsmall)) ///
    plotregion(fcolor(none)) /// <- Supprimer le fond
    graphregion(fcolor(white)) /// <- Fond blanc
    name(zone_km, replace)
	
/// Cette courbe Kaplan-Meier justifie l'importance de l'interaction entre la région et le milieu de résidence. L'analyse séparée de ces deux variables aurait masqué les écarts importants observés. Par exemple, un enfant vivant en milieu rural à Ziguinchor n'a pas la même probabilité de survie qu'un enfant en milieu rural à Dakar ou dans les Autres Régions. L'interaction région-milieu de résidence permet donc de mieux capter les disparités géographiques.

* Tests ***************************

local categorical_vars presence_pere region Niveau_etude_pere Niveau_etude_mere ///
                       Csp_pere Csp_mere Csp_cm Niveau_etude_cm wealth_index_ACM_q ///
                       milieu_residence sit_mat_cm sexe_cm sexe periode
					   
* Boucle pour tester chaque variable catégorielle
foreach var of local categorical_vars {
    display "===================================="
    display "Log-Rank Test pour la variable : `var'"
    sts test `var'
}

xtile age_groupe = age_cm, nq(4) // Création de 4 groupes d'âge
sts test age_groupe


//Tous les facteurs analysés, à l'exception de la variable sexe, présentent des différences de survie statistiquement significatives. Cela confirme les observations faites avec les courbes Kaplan-Meier. L'effet des caractéristiques socio-économiques, géographiques et familiales est bien réel et mérite d'être approfondi dans un modèle pour quantifier l'effet de chaque variable.



// Dans le cadre de l'analyse des déterminants de l'abandon scolaire, plusieurs modèles de durée discrète ont été testés afin de capturer au mieux le risque de décrochage au cours du temps. 

*****************************************************
*         ESTIMATION DES MODÈLES DISCRETS           *
*****************************************************

* --- Conversion des variables texte en variables numériques catégorielles
encode Niveau_etude_pere, gen(NivEtuPere_num)
encode Niveau_etude_mere, gen(NivEtuMere_num)
encode Csp_pere, gen(CspPere_num)
encode Csp_mere, gen(CspMere_num)
encode Csp_cm, gen(CspCM_num)
encode Niveau_etude_cm, gen(NivEtuCM_num)
encode sit_mat_cm, gen(SitMatCM_num)
encode zone, gen(zone_num)

* --- Définir le modèle de survie pour Stata (discret)
stset duree, failure(fail)

* --- Modèle 1 : Cloglog avec interaction et niveaux de référence affichés
cloglog fail i.presence_pere  i.region i.milieu_residence ///
       i.NivEtuPere_num i.NivEtuMere_num ///
       i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num i.wealth_index_ACM_q ///
       i.SitMatCM_num i.sexe_cm i.sexe ///
       c.age_cm c.age_cm#c.age_cm ///
       i.periode [pweight=poids], vce(cluster id) allbaselevels

* Enregistrer le modèle
estimates store cloglog_model


* --- Modèle 2 : Logit avec interaction et niveaux de référence affichés
logit fail i.presence_pere  i.region i.milieu_residence ///
       i.NivEtuPere_num i.NivEtuMere_num ///
       i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num i.wealth_index_ACM_q ///
       i.sexe_cm i.sexe ///
       c.age_cm c.age_cm#c.age_cm ///
       i.periode [pweight=poids], vce(cluster id) allbaselevels

* Enregistrer le modèle
estimates store logit_model


* --- Modèle 3 : Probit avec interaction et niveaux de référence affichés
probit fail i.presence_pere i.region i.milieu_residence  i.region#i.milieu_residence ///
       i.NivEtuPere_num i.NivEtuMere_num ///
       i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num i.wealth_index_ACM_q ///
       i.SitMatCM_num i.sexe_cm i.sexe ///
       c.age_cm c.age_cm#c.age_cm ///
       i.periode [pweight=poids], vce(cluster id) allbaselevels

* Enregistrer le modèle
estimates store probit_model


*****************************************************
*            COMPARAISON DES MODÈLES                *
*****************************************************
esttab cloglog_model logit_model probit_model  ///
    using "comparaison_modeles_interaction.rtf", replace ///
    stats(ll bic aic, labels("Log-Likelihood" "BIC" "AIC")) ///
    title("Comparaison des Modèles - Abandon Scolaire avec Interaction")
	
/// Le modèle Cloglog est le plus performant en termes de AIC et BIC.

*****************************************************
*            COMPARAISON GRAPHIQUE                  *
*****************************************************

* Prédire le score linéaire (Xβ) sans transformation
predict xb_cloglog if e(sample), xb

* Appliquer la transformation Cloglog pour obtenir les probabilités
gen p_cloglog = 1 - exp(-exp(xb_cloglog))


* --- Restauration du modèle Logit et prédiction
estimates restore logit_model
predict p_logit if e(sample), pr

* --- Restauration du modèle Probit et prédiction
estimates restore probit_model
predict p_probit if e(sample), pr

* Calcul de l'AUC pour chaque modèle
roctab fail p_cloglog
di "AUC - Cloglog: " _roc_auc
roctab fail p_logit
di "AUC - Logit: " _roc_auc
roctab fail p_probit
di "AUC - Probit: " _roc_auc


   /// Verification des hypothèses du modèle

* --- Estimation du modèle Cloglog avec interactions temporelles
cloglog fail i.presence_pere##i.periode i.region##i.milieu_residence ///
       i.NivEtuPere_num##i.periode i.NivEtuMere_num##i.periode ///
       i.CspPere_num##i.periode i.CspMere_num##i.periode ///
       i.NivEtuCM_num##i.periode i.wealth_index_ACM_q##i.periode ///
       i.SitMatCM_num##i.periode i.sexe_cm##i.periode i.sexe##i.periode ///
       c.age_cm##i.periode c.age_cm#c.age_cm ///
       [pweight=poids], vce(cluster id) allbaselevels
	///
	
cloglog fail i.presence_pere##i.periode i.region##i.milieu_residence ///
       i.NivEtuPere_num##i.periode i.NivEtuMere_num##i.periode ///
       i.CspPere_num##i.periode i.CspMere_num##i.periode ///
       i.NivEtuCM_num##i.periode i.wealth_index_ACM_q##i.periode ///
       i.SitMatCM_num##i.periode i.sexe_cm##i.periode i.sexe##i.periode ///
       c.age_cm##i.periode c.age_cm#c.age_cm ///
       [pweight=poids], vce(cluster id) allbaselevels
	///
	
* ----------------------------- Ajuster le modèle logistique


/// Choisir entre un modele logistique avec les constantes par periode ou sans celles-ci

* --- Ajuster le modèle avec constante pour chaque période
logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels

* Sauvegarder les résultats du modèle avec période
estimates store model_with_period

* --- Ajuster le modèle sans constante pour chaque période
* Ajuster le modèle logistique avec interaction entre region et milieu_residence
logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm [pweight=poids], or vce(cluster id) allbaselevels


* Sauvegarder les résultats du modèle sans période
estimates store model_without_period

* --- Comparer les AIC et BIC pour les deux modèles
estat ic
estimates restore model_with_period
estat ic
estimates restore model_without_period
estat ic

/// Choisir entre un modele logistique avec ou sans interactions entre milieu de residence et region

* --- Ajuster le modèle sans interactions
logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels

* Sauvegarder les résultats du modèle avec période
estimates store model_with_interaction

* --- Ajuster le modèle avec interactions
* Ajuster le modèle logistique avec interaction entre region et milieu_residence
logit fail i.presence_pere i.region#i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels


* Sauvegarder les résultats du modèle sans interaction
estimates store model_without_interaction

* --- Comparer les AIC et BIC pour les deux modèles
estat ic
estimates restore model_with_interaction
estat ic
estimates restore model_without_interaction
estat ic

/// Evaluation du modele de duree logistique

logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels

*  --- Probabilité d'abandon scolaire

* Prédire la probabilité d'abandon scolaire
predict prob_abandon, pr

* Afficher les premières prédictions
list prob_abandon in 1/10

* Vérifier la multicolinéarité en calculant les VIF
vif, uncentered

* Générer les prédictions de probabilité
predict prob_abandon, pr

* Tracer la courbe ROC avec le modèle ajusté
roctab fail prob_abandon

* Générer les prédictions de probabilité (si ce n'est pas déjà fait)
gen predicted_class = (prob_abandon >= 0.5)

* Diagnostic
gen TP = (fail == 1 & predicted_class == 1)  // True Positives
gen FP = (fail == 0 & predicted_class == 1)  // False Positives
gen TN = (fail == 0 & predicted_class == 0)  // True Negatives
gen FN = (fail == 1 & predicted_class == 0)  // False Negatives


count if TP == 1
scalar TP_count = r(N)  // count of True Positives

count if FP == 1
scalar FP_count = r(N)  // count of False Positives

count if TN == 1
scalar TN_count = r(N)  // count of True Negatives

count if FN == 1
scalar FN_count = r(N)  // count of False Negatives

* Accuracy
gen accuracy = (TP_count + TN_count) / _N

* Precision
gen precision = TP_count / (TP_count + FP_count)

* Recall (Sensitivity)
gen recall = TP_count / (TP_count + FN_count)

* F1-Score
gen f1_score = 2 * (precision * recall) / (precision + recall)

* Specificity (True Negative Rate)
gen specificity = TN_count / (TN_count + FP_count)

* Resultats
di "Accuracy = " accuracy
di "Precision = " precision
di "Recall = " recall
di "F1-Score = " f1_score
di "Specificity = " specificity


* Hosmer-Lemeshow test 
svyset [pweight=poids]

* Fit la  regression 
svy: logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode, or allbaselevels

* Hosmer-Lemeshow test 
estat gof  // L'hypothese nulle nest pas rejetee

/// Vizualisations des risques moyens

** Les risques moyens 
margins periode, atmeans

marginsplot, xdimension(periode) ytitle("Log(Hazard)") ///
    title("Évolution du risque moyen par période") ///
    ylabel(, grid) xlabel(, valuelabel) ///
    graphregion(color(white)) /// Enlever le fond bleu
    addplot(line 6 9 11, lcolor(black) lwidth(medium)) 

		
 *********************         On s'interesse maintenant aux transitions entre les différents niveaux scolaires    *******************************
 
 use "C:\Users\LENOVO\Downloads\base_final_type_formation.dta" ,clear
   
  /// Preparation des donnees

* Remplacer "Non déterminée" quand c mal ecrit
replace  Niveau_etude_mere = "Non déterminée" if  Niveau_etude_mere == "Non déternimé"

* Créer un identifiant unique pour chaque individu
gen id = _n

 * Créer des catégories ordinales pour le niveau d'éducation
gen niveau_etude_num = .
replace niveau_etude_num = 0 if Niveau_etude_enfant == "Aucun"
replace niveau_etude_num = 1 if Niveau_etude_enfant == "Maternelle"
replace niveau_etude_num = 2 if Niveau_etude_enfant == "Primaire"
replace niveau_etude_num = 3 if Niveau_etude_enfant == "Secondaire 1er cycle"
replace niveau_etude_num = 4 if Niveau_etude_enfant == "Secondaire 2e cycle"

* Stocker la durée dans une variable "duree"
gen duree = niveau_etude_num

* Passer les données en format long (une ligne par période par individu)
expand duree
bysort id (duree): gen periode = _n

* Créer une variable indiquant l'événement (abandon à cette période)
gen fail = (periode == duree)

* --- Conversion des variables texte en variables numériques catégorielles
encode Niveau_etude_pere, gen(NivEtuPere_num)
encode Niveau_etude_mere, gen(NivEtuMere_num)
encode Csp_pere, gen(CspPere_num)
encode Csp_mere, gen(CspMere_num)
encode Csp_cm, gen(CspCM_num)
encode Niveau_etude_cm, gen(NivEtuCM_num)
encode sit_mat_cm, gen(SitMatCM_num)

* --- Ajuster le modèle avec constante pour chaque période
* --- Ajuster le modèle sans interactions
logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels

* Sauvegarder les résultats du modèle avec période
estimates store model_with_interaction

* --- Ajuster le modèle avec interactions
* Ajuster le modèle logistique avec interaction entre region et milieu_residence
logit fail i.presence_pere i.region#i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels


* Sauvegarder les résultats du modèle sans interaction
estimates store model_without_interaction

* --- Comparer les AIC et BIC pour les deux modèles
estat ic
estimates restore model_with_interaction
estat ic
estimates restore model_without_interaction
estat ic

/// Evaluation du modele de duree logistique

logit fail i.presence_pere i.region i.milieu_residence ///
    i.NivEtuPere_num i.NivEtuMere_num ///
    i.CspPere_num i.CspMere_num i.CspCM_num i.NivEtuCM_num ///
    i.wealth_index_ACM_q i.sexe_cm i.sexe ///
    c.age_cm c.age_cm#c.age_cm i.periode [pweight=poids], or vce(cluster id) allbaselevels

*  --- Probabilité d'abandon scolaire

* Prédire la probabilité d'abandon scolaire
predict prob_abandon, pr

* Afficher les premières prédictions
list prob_abandon in 1/10

* Vérifier la multicolinéarité en calculant les VIF
vif, uncentered

* Générer les prédictions de probabilité
predict prob_abandon, pr

* Tracer la courbe ROC avec le modèle ajusté
roctab fail prob_abandon, graph

* Générer les prédictions de probabilité (si ce n'est pas déjà fait)
gen predicted_class = (prob_abandon >= 0.5)

* Diagnostic
gen TP = (fail == 1 & predicted_class == 1)  // True Positives
gen FP = (fail == 0 & predicted_class == 1)  // False Positives
gen TN = (fail == 0 & predicted_class == 0)  // True Negatives
gen FN = (fail == 1 & predicted_class == 0)  // False Negatives


count if TP == 1
scalar TP_count = r(N)  // count of True Positives

count if FP == 1
scalar FP_count = r(N)  // count of False Positives

count if TN == 1
scalar TN_count = r(N)  // count of True Negatives

count if FN == 1
scalar FN_count = r(N)  // count of False Negatives

* Accuracy
gen accuracy = (TP_count + TN_count) / _N

* Precision
gen precision = TP_count / (TP_count + FP_count)

* Recall (Sensitivity)
gen recall = TP_count / (TP_count + FN_count)

* F1-Score
gen f1_score = 2 * (precision * recall) / (precision + recall)

* Specificity (True Negative Rate)
gen specificity = TN_count / (TN_count + FP_count)

* Resultats
di "Accuracy = " accuracy
di "Precision = " precision
di "Recall = " recall
di "F1-Score = " f1_score
di "Specificity = " specificity

** Les risques moyens 
margins periode, atmeans

marginsplot, xdimension(periode) ytitle("Log(Hazard)") ///
    title("Évolution du risque moyen par niveau d'études") ///
    ylabel(, grid) xlabel(1 "Maternelle" 2 "Primaire" 3 "Secondaire 1er cycle", valuelabel angle(45)) ///
    graphregion(color(white)) ///
    addplot(line 6 9 11, lcolor(black) lwidth(medium))
	
margins region, atmeans

marginsplot, xdimension(region) ytitle("Log(Hazard)") ///
    title("Risque moyen selon la région") ///
    ylabel(, grid) xlabel(, valuelabel angle(45)) ///
    graphregion(color(white)) /// Enlever le fond bleu
    addplot(line 6 9 11, lcolor(black) lwidth(medium))
	
margins presence_pere, atmeans

marginsplot, xdimension(presence_pere) ytitle("Log(Hazard)") ///
    title("Risque moyen selon la présence du père") ///
    ylabel(, grid) xlabel(, valuelabel) ///
    graphregion(color(white)) /// Enlever le fond bleu
    addplot(line 6 9 11, lcolor(black) lwidth(medium)) 
	
margins NivEtuCM_num, atmeans

marginsplot, xdimension(NivEtuCM_num) ytitle("Log(Hazard)") ///
    title("Risque moyen selon le niveau d'instruction du CM") ///
    ylabel(, grid) xlabel(, valuelabel angle(45)) ///
    graphregion(color(white)) /// Enlever le fond bleu
    addplot(line 6 9 11, lcolor(black) lwidth(medium)) 
	
margins CspCM_num, atmeans

marginsplot, xdimension(CspCM_num) ytitle("Log(Hazard)") ///
    title("Risque moyen selon la catégorie socioprofessionnelle du CM") ///
    ylabel(, grid) xlabel(, valuelabel angle(45)) /// 
    graphregion(color(white)) /// Enlever le fond bleu
    addplot(line 6 9 11, lcolor(black) lwidth(medium))
 

 





