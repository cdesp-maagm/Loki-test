/**
 * @ingroup ggLokiAcquisition
 * @defgroup gLokiEnvSensors Acquisition de données provenant des capteurs auxiliaires
 *
 * Ce module fournit une API en espace utilisateur pour accéder aux composants
 * de gestion des capteurs d'environnement interfacés avec le FPGA.
 *
 * Il s'appuie sur un module noyau Linux à travers les interfaces IOCTL et MMAP.
 * Ce module noyau implémente les mécanismes de plus bas niveau pour l'accès au
 * matériel (registres, DMA).
 */

/// @{

#ifndef LIBLOKI_ENV_SENSORS_H_
#define LIBLOKI_ENV_SENSORS_H_

#include <stdint.h>
#include <stdbool.h>
#include <sys/types.h>

/// Représentation des capteurs auxiliaires.
typedef struct LokiEnvSensors LokiEnvSensors;

/// Représentation d'un échantillon en provenance des capteurs auxiliaires.
typedef struct {
    /// Le numéro de la voie sur lequel l'échantillon a été reçu.
    uint32_t channel;
    /// La valeur de l'échantillon.
    union {
        /// La valeur de l'échantillon, en virgule flottante après mise à l'échelle.
        float data;
        /// La valeur de l'échantillon, en virgule fixe.
        int32_t data_raw;
    };
} LokiEnvSensorsSample;

/** Construire un module d'acquisition pour les capteurs auxiliaires.
 *
 * @return Une instance de LokiEnvSensors.
 */
LokiEnvSensors *LokiEnvSensors_new(void);

/** Détruire un module d'acquisition pour les capteurs auxiliaires.
 *
 * @param self Le module à détruire.
 */
void LokiEnvSensors_del(LokiEnvSensors *self);

/** Redémarrer le module d'acquisition pour les capteurs auxiliaires.
 *
 * Cette fonction déclenche une réinitialisation des compteurs
 * d'échantillons du module d'acquisition dans le FPGA.
 *
 * @param self Le module à redémarrer.
 */
void LokiEnvSensors_restart(const LokiEnvSensors *self);

/** Lire la fréquence d'horloge du circuit d'acquisition.
 *
 * @param self Le module d'acquisition à interroger.
 * @return La fréquence d'horloge, en Hz.
 */
uint32_t LokiEnvSensors_get_clk_frequency(const LokiEnvSensors *self);

/** Lire le nombre de voies du circuit d'acquisition.
 *
 * @param self Le module d'acquisition à interroger.
 * @return Le nombre de voies.
 */
size_t LokiEnvSensors_get_channels(const LokiEnvSensors *self);

/** Lire la fréquence d'échantillonnage du circuit d'acquisition.
 *
 * @param self Le module d'acquisition à interroger.
 * @return La fréquence d'échantillonnage, en Hz.
 */
float LokiEnvSensors_get_sampling_frequency(const LokiEnvSensors *self);

/** Affecter une fréquence d'échantillonnage au circuit d'acquisition.
 *
 * @param self Le module d'acquisition à interroger.
 * @param freq La fréquence d'échantillonnage, en Hz.
 */
void LokiEnvSensors_set_sampling_frequency(const LokiEnvSensors *self, float freq);

/** Lire la longueur maximale des paquets DMA.
 *
 * @param self Le module d'acquisition à interroger.
 * @return Le nombre maximal d'échantillons par paquet.
 */
uint32_t LokiEnvSensors_get_packet_length_max(const LokiEnvSensors *self);

/** Lire la longueur courante d'un paquet DMA.
 *
 * @param self Le module d'acquisition à interroger.
 * @return Le nombre d'échantillons par paquet.
 */
uint32_t LokiEnvSensors_get_packet_length(const LokiEnvSensors *self);

/** Lire le facteur de mise à l'échelle des échantillons d'une voie.
 *
 * Ce facteur permet de convertir la valeur numérique brute issue du capteur
 * en une valeur dans une unité de mesure de notre choix.
 *
 * @param self Le module d'acquisition à modifier.
 * @param channel Le numéro de la voie.
 * @return Le facteur d'échelle appliqué à cette voie.
 */
float LokiEnvSensors_get_scaling_factor(const LokiEnvSensors *self, size_t channel);

/** Affecter un facteur de mise à l'échelle des échantillons d'une voie.
 *
 * Ce facteur permet de convertir la valeur numérique brute issue du capteur
 * en une valeur dans une unité de mesure de notre choix.
 *
 * @param self Le module d'acquisition à modifier.
 * @param channel Le numéro de la voie.
 * @param scale Le facteur d'échelle à appliquer à cette voie.
 */
void LokiEnvSensors_set_scaling_factor(LokiEnvSensors *self, size_t channel, float scale);

/** Lire la valeur du dernier échantillon acquis sur une voie.
 *
 * @param self Le module d'acquisition à interroger.
 * @param channel Le numéro de la voie.
 * @return La valeur du dernier échantillon.
 */
float LokiEnvSensors_get_last_data(const LokiEnvSensors *self, size_t channel);

/** Démarrer l'acquisition.
 *
 * Cette fonction est non bloquante.
 * Elle crée un nouveau thread pour la réception des données en provenance
 * du pilote des capteurs.
 *
 * @param self Le module d'acquisition à démarrer.
 * @param channels Un masque indiquant les voies à traiter, -1 pour toutes les voies.
 * @param raw Faut-il conserver les valeurs d'échantillons en virgule fixe ?
 * @param out La FIFO où ranger les échantillons mis à l'échelle.
 * @return Le code d'erreur retourné par `pthread_create`.
 */
int LokiEnvSensors_start_streaming(LokiEnvSensors *self, int32_t channels, bool raw, LokiFIFO *out);

/** Arrêter l'acquisition.
 *
 * Interrompt l'exécution du thread lancé par la fonction #LokiEnvSensors_start_streaming.
 * L'arrêt est effectif à la fin du paquet de données en cours de réception.
 *
 * @param self Le module d'acquisition à arrêter.
 */
void LokiEnvSensors_stop_streaming(LokiEnvSensors *self);

/** Arrêter l'acquisition immédiatement.
 *
 * Interrompt l'exécution du thread lancé par la fonction #LokiEnvSensors_start_streaming.
 * Cette fonction force l'arrêt des transferts DMA sans attendre la fin d'un paquet.
 *
 * @param self Le module d'acquisition à arrêter.
 */
void LokiEnvSensors_force_stop(const LokiEnvSensors *self);

/** Lire l'état de l'acquisition.
 *
 * @param self Le module d'acquisition à interroger.
 * @return true si l'acquisition est en cours.
 */
bool LokiEnvSensors_is_streaming(const LokiEnvSensors *self);

#endif

/// @file libloki-env-sensors.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
