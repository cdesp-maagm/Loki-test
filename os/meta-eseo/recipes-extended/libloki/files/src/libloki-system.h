
/// @defgroup ggLokiComputation Calcul de déplacement
/// @{

/**
 * @defgroup gLokiSystem Gestion des acquisitions et du calcul de déplacement
 *
 * Un système rassemble un @ref gLokiModem "modem" et un @ref gLokiDisplacement "calculateur de déplacement".
 */

/// @{

#ifndef LIBLOKI_SYSTEM_H_
#define LIBLOKI_SYSTEM_H_

#include "libloki-modem.h"
#include "libloki-fifo.h"
#include "libloki-ellipse-estimator.h"

/// Représentation d'un échantillon en sortie d'une instance de LokiSystem.
typedef struct {
    /// La voie d'entrée sur lequel l'échantillon a été reçu.
    uint32_t channel;
    /// La valeur de l'échantillon.
    float value;
    /// La coordonnée X du point courant de l'ellipse, ramené sur le cercle unité.
    float x_norm;
    /// La coordonnée Y du point courant de l'ellipse, ramené sur le cercle unité.
    float y_norm;
} LokiSystemSample;

/// Paramètres de configuration d'une instance de LokiSystem.
typedef struct LokiSystemConfig LokiSystemConfig;

/** Construire une configuration pour une instance de LokiSystem.
 *
 * @return Une instance de LokiSystemConfig.
 */
LokiSystemConfig * LokiSystemConfig_new(void);

/** Détruire une configuration pour une instance de LokiSystem.
 *
 * @param self L'instance de LokiSystemConfig à détruire.
 */
void LokiSystemConfig_del(LokiSystemConfig *self);

/** Lire l'état d'activation de la simulation des capteurs de déplacement.
 *
 * Le paramètre `simulate` active un mode de simulation des capteurs de déplacement
 * dans le système à configurer.
 *
 * @param self Une configuration à interroger.
 * @return true si la configuration prévoit une simulation des capteurs de déplacement.
 */
bool LokiSystemConfig_get_simulate(LokiSystemConfig *self);

/** Activer ou désactiver la simulation des capteurs de déplacement.
 *
 * Le paramètre `simulate` active un mode de simulation des capteurs de déplacement
 * dans le système à configurer.
 *
 * @param self Une configuration à modifier.
 * @param value true pour indiquer qu'il faut simuler les capteurs de déplacement.
 */
void LokiSystemConfig_set_simulate(LokiSystemConfig *self, bool value);

/** Lire le temps d'attente au démarrage.
 *
 * Le paramètre `skip` définit le nombre de secondes d'attente avant de commencer
 * à remplir la FIFO des données de déplacement.
 *
 * @param self Une configuration à interroger.
 * @return Le temps d'attente, en secondes.
 */
float LokiSystemConfig_get_skip(LokiSystemConfig *self);

/** Affecter un temps d'attente au démarrage.
 *
 * Le paramètre `skip` définit le nombre de secondes d'attente avant de commencer
 * à remplir la FIFO des données de déplacement.
 *
 * @param self Une configuration à modifier.
 * @param value Le nouveau temps d'attente, en secondes.
 */
void LokiSystemConfig_set_skip(LokiSystemConfig *self, float value);

/** Lire le facteur d'échelle de déplacement.
 *
 * Le résultat est calculé en fonction des paramètres de longueur d'onde,
 * nombre de réflexions, indice de la cavité, unité de distance.
 *
 * @param self La configuration à interroger.
 * @return La valeur du facteur d'échelle de déplacement.
 */
float LokiSystemConfig_get_scale(LokiSystemConfig *self);

/** Lire la longueur d'onde de la diode laser.
 *
 * @param self La configuration à interroger.
 * @return La longueur d'onde de la diode laser, en nm.
 */
float LokiSystemConfig_get_wavelength(LokiSystemConfig *self);

/** Écrire la longueur d'onde de la diode laser.
 *
 * @param self La configuration à modifier.
 * @param value La nouvelle longueur d'onde de la diode laser, en nm.
 */
void LokiSystemConfig_set_wavelength(LokiSystemConfig *self, float value);

/** Lire le nombre de réflexions supposé.
 *
 * @param self La configuration à interroger.
 * @return Le nombre de réflexions.
 */
unsigned LokiSystemConfig_get_reflections(LokiSystemConfig *self);

/** Écrire le nombre de réflexions supposé.
 *
 * @param self La configuration à modifier.
 * @param value Le nouveau nombre de réflexions.
 */
void LokiSystemConfig_set_reflections(LokiSystemConfig *self, unsigned value);

/** Lire l'indice de la cavité de Fabry-Pérot.
 *
 * @param self La configuration à interroger.
 * @return Le nombre de réflexions.
 */
float LokiSystemConfig_get_cavity_index(LokiSystemConfig *self);

/** Écrire l'indice de la cavité de Fabry-Pérot.
 *
 * @param self La configuration à modifier.
 * @param value Le nouvel indice de la cavité de Fabry-Pérot.
 */
void LokiSystemConfig_set_cavity_index(LokiSystemConfig *self, float value);

/** Lire l'unité du déplacement calculé.
 *
 * @param self La configuration à interroger.
 * @return Le préfixe de l'unité de déplacement ('p', 'n' 'u', 'm').
 */
char LokiSystemConfig_get_distance_unit(LokiSystemConfig *self);

/** Écrire l'unité du déplacement calculé.
 *
 * @param self La configuration à modifier.
 * @param value Le nouveau préfixe de l'unité de déplacement ('p', 'n' 'u', 'm').
 */
void LokiSystemConfig_set_distance_unit(LokiSystemConfig *self, char value);

/** Lire le nom de l'estimateur de paramètres d'ellipse.
 *
 * @param self La configuration à interroger.
 * @return Le nom du filtre d'estimation.
 */
const char *LokiSystemConfig_get_estimator_name(LokiSystemConfig *self);

/** Affecter un nom de l'estimateur de paramètres d'ellipse.
 *
 * @param self La configuration à modifier.
 * @param name Le nom du filtre d'estimation à utiliser.
 */
void LokiSystemConfig_set_estimator_name(LokiSystemConfig *self, const char *name);

/** Lire le rayon initial à utiliser lors de l'estimation des paramètres d'ellipse.
 *
 * @param self La configuration à interroger.
 * @return Le rayon initial.
 */
float LokiSystemConfig_get_estimator_initial_radius(LokiSystemConfig *self);

/** Affecter un rayon initial à utiliser lors de l'estimation des paramètres d'ellipse.
 *
 * @param self La configuration à modifier.
 * @param value Le rayon initial.
 */
void LokiSystemConfig_set_estimator_initial_radius(LokiSystemConfig *self, float value);

/** Lire le nombre de paramètres du filtre d'estimation des paramètres de l'ellipse.
 *
 * @param self La configuration à interroger.
 * @return Le nombre de paramètres.
 */
size_t LokiSystemConfig_get_estimator_params_length(LokiSystemConfig *self);

/** Lire les paramètres du filtre d'estimation des paramètres de l'ellipse.
 *
 * Les paramètres se présentent sous la forme d'un tableau dont la longueur
 * est accessible à l'aide de la fonction #LokiSystemConfig_get_estimator_params_length.
 *
 * @param self La configuration à interroger.
 * @return Un tableau de paramètres.
 */
float *LokiSystemConfig_get_estimator_params(LokiSystemConfig *self);

/** Affecter des paramètres pour le filtre d'estimation des paramètres de l'ellipse.
 *
 * Les paramètres se présentent sous la forme d'un tableau dont la longueur
 * doit être égale à la valeur retournée par la fonction
 * #LokiSystemConfig_get_estimator_params_length.
 *
 * @param self La configuration à modifier.
 * @param value Un tableau de paramètres.
 */
void LokiSystemConfig_set_estimator_params(LokiSystemConfig *self, const float *value);

/** Lire la bande passante du filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à interroger.
 * @return La bande passante du filtre, en Hz.
 */
float LokiSystemConfig_get_filter_bandwidth(LokiSystemConfig *self);

/** Affecter un bande passante pour le filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à modifier.
 * @param value La bande passante du filtre, en Hz.
 */
void LokiSystemConfig_set_filter_bandwidth(LokiSystemConfig *self, float value);

/** Lire l'atténuation du filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à interroger.
 * @return L'atténuation, en dB.
 */
float LokiSystemConfig_get_filter_attenuation(LokiSystemConfig *self);

/** Affecter une atténuation pour le filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à modifier.
 * @param value L'atténuation, en dB.
 */
void LokiSystemConfig_set_filter_attenuation(LokiSystemConfig *self, float value);

/** Lire la longueur du filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à interroger.
 * @return Le nombre de coefficients du filtre.
 */
size_t LokiSystemConfig_get_filter_length(LokiSystemConfig *self);

/** Affecter une longueur au filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à modifier.
 * @param value Le nombre de coefficients du filtre.
 */
void LokiSystemConfig_set_filter_length(LokiSystemConfig *self, size_t value);

/** Lire le facteur de décimation du filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à interroger.
 * @return Le facteur de décimation du filtre.
 */
size_t LokiSystemConfig_get_filter_decimation(LokiSystemConfig *self);

/** Affecter un facteur de décimation au filtre d'élimination du déplacement fictif.
 *
 * @param self La configuration à modifier.
 * @param value Le facteur de décimation du filtre.
 */
void LokiSystemConfig_set_filter_decimation(LokiSystemConfig *self, size_t value);

/** Lire la longueur du tableau de constantes de temps pour le filtrage des paramètres de l'ellipse.
 *
 * @param self La configuration à interroger.
 * @return Le nombre de constantes de temps.
 */
size_t LokiSystemConfig_get_time_constants_length(LokiSystemConfig *self);

/** Lire le tableau de constantes de temps pour le filtrage des paramètres de l'ellipse.
 *
 * La longueur de ce tableau peut être connue en appelant la fonction
 * #LokiSystemConfig_get_time_constants_length.
 *
 * @param self La configuration à interroger.
 * @return Le tableau de constantes de temps.
 */
float *LokiSystemConfig_get_time_constants(LokiSystemConfig *self);

/** Affecter un tableau de constantes de temps pour le filtrage des paramètres de l'ellipse.
 *
 * La longueur de ce tableau doit être égale à la valeur retournée par la fonction
 * #LokiSystemConfig_get_time_constants_length.
 *
 * @param self La configuration à interroger.
 * @param value Le nombre de constantes de temps.
 */
void LokiSystemConfig_set_time_constants(LokiSystemConfig *self, const float *value);

/// Représentation d'un système d'acquisition et de calcul de déplacement.
typedef struct LokiSystem LokiSystem;

/** Construire un nouveau système.
 *
 * @param config La configuration à utiliser.
 * @param modem Le modem à utliser, `NULL` pour en instancier un nouveau.
 * @return Une nouvelle instance de LokiSystem.
 */
LokiSystem *LokiSystem_new(LokiSystemConfig *config, LokiModem *modem);

/** Détruire un système.
 *
 * @param self Le système à détruire.
 */
void LokiSystem_del(LokiSystem *self);

/** Lire la configuration d'un système.
 *
 * @param self Le système à interroger.
 * @return La configuration attachée à ce système.
 */
LokiSystemConfig *LokiSystem_get_config(const LokiSystem *self);

/** Lire le modem utilisé par ce système.
 *
 * @param self Le système à interroger.
 * @return Le modem attaché à ce système.
 */
LokiModem *LokiSystem_get_modem(const LokiSystem *self);

/** Lire la fréquence d'échantillonnage en sortie de ce système.
 *
 * @param self Le système à interroger.
 * @return La fréquence d'échantillonnage du signal de déplacement.
 */
float LokiSystem_get_sampling_frequency(const LokiSystem *self);

/** Mettre à zéro le déplacement calculé.
 *
 * @param self Le système à modifier.
 * @see LokiDisplacement_reset
 */
void LokiSystem_displacement_reset(LokiSystem *self);

/** Démarrer l'acquisition et le traitement.
 *
 * Cette fonction est non bloquante.
 * Elle crée un nouveau thread pour le traitement des données en provenance
 * du modem et démarre celui-ci.
 *
 * @param self Le système à démarrer.
 * @param channels Un masque indiquant les voies à traiter, -1 pour toutes les voies.
 * @param modem_out La FIFO qui recevra les données de sortie du démodulateur.
 * @param disp_out La FIFO qui recevra les valeurs de déplacement.
 * @param cid Le numéro de consommateur de ce système pour la FIFO `modem_out`.
 * @return Le code d'erreur retourné par #LokiModem_start_streaming
 */
int LokiSystem_start_streaming(LokiSystem *self, int32_t channels, LokiFIFO *modem_out, LokiFIFO *disp_out, size_t cid);

/** Arrêter l'acquisition et le traitement.
 *
 * Interrompt l'exécution du thread lancé par la fonction #LokiSystem_start_streaming.
 *
 * @param self Le système à arrêter.
 */
void LokiSystem_stop_streaming(LokiSystem *self);

/** Lire l'état de l'acquisition.
 *
 * @param self Le système à interroger.
 * @return true si l'acquisition est en cours.
 */
bool LokiSystem_is_streaming(LokiSystem *self);

/** Lire la dernière ellipse estimée.
 *
 * @param self Le système à interroger.
 * @param channel La voie à observer.
 * @return La dernière ellipse estimée pour cette voie.
 */
LokiEllipse *LokiSystem_get_ellipse(LokiSystem *self, size_t channel);

#endif

/// @}
/// @}

/// @ingroup gLokiSystem
/// @file libloki-system.h
/// @author Guillaume Savaton
/// @copyright ESEO
