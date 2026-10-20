
/// @defgroup ggLokiAcquisition Acquisition
/// @{

/**
 * @defgroup gLokiModem Pilotage des composants modulateur et démodulateur
 *
 * Ce module fournit une API en espace utilisateur pour accéder aux composants
 * modulateur et démodulateur du FPGA.

 * Il s'appuie sur un module noyau Linux à travers les interfaces IOCTL et MMAP.
 * Ce module noyau implémente les mécanismes de plus bas niveau pour l'accès au
 * matériel (registres, DMA).
 */

/// @{

#ifndef LIBLOKI_MODEM_H_
#define LIBLOKI_MODEM_H_

#include "libloki-fifo.h"

#include <stdint.h>
#include <stdbool.h>
#include <sys/types.h>

/// Représentation des périphériques modulateur et démodulateur.
typedef struct LokiModem LokiModem;

/// Données retournées par le démodulateur pour un échantillon.
typedef struct {
    /// La voie d'entrée sur lequel l'échantillon a été reçu.
    uint32_t channel;
    /// La composante X de l'échantillon.
    union {
        /// La composante X de l'échantillon, en virgule flottante.
        float x;
        /// La composante X de l'échantillon, en virgule fixe.
        int32_t x_raw;
    };
    /// La composante Y de l'échantillon.
    union {
        /// La composante Y de l'échantillon, en virgule flottante après mise à l'échelle.
        float y;
        /// La composante Y de l'échantillon, en virgule fixe.
        int32_t y_raw;
    };
} LokiModemSample;

/** Construire un nouveau modem.
 *
 * @return Une instance de LokiModem.
 */
LokiModem *LokiModem_new(void);

/** Détruire un modem.
 *
 * @param self Le modem à détruire.
 */
void LokiModem_del(LokiModem *self);

/** Lire la fréquence d'horloge du circuit d'acquisition.
 *
 * @param self Le modem à interroger.
 * @return La fréquence d'horloge, en Hz.
 */
uint32_t LokiModem_get_clk_frequency(const LokiModem *self);

/** Lire la fréquence d'échantillonnage en sortie du modulateur.
 *
 * @param self Le modem à interroger.
 * @return La fréquence d'échantillonnage, en Hz.
 */
float LokiModem_get_mod_sampling_frequency(const LokiModem *self);

/** Affecter une fréquence d'échantillonnage en sortie du modulateur.
 *
 * Cette fonction préserve les fréquences réglées précédemment pour les
 * oscillateurs Fm1 et Fm2 du modulateur.
 *
 * @param self Le modem à modifier.
 * @param freq La fréquence d'échantillonnage, en Hz.
 */
void LokiModem_set_mod_sampling_frequency(const LokiModem *self, float freq);

/** Lire le pas de réglage de la fréquence du signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * La fréquence de l'oscillateur est toujours un multiple de cette valeur.
 *
 * @param self Le modem à interroger.
 * @return La résolution du réglage de la fréquence du signal, en Hz.
 */
float LokiModem_get_mod_osc1_wave_frequency_res(const LokiModem *self);

/** Lire la fréquence maximale supportée pour le signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * @param self Le modem à interroger.
 * @return La fréquence maximale du signal, en Hz.
 */
float LokiModem_get_mod_osc1_wave_frequency_max(const LokiModem *self);

/** Lire la fréquence du signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * @param self Le modem à interroger.
 * @return La fréquence du signal, en Hz.
 */
float LokiModem_get_mod_osc1_wave_frequency(const LokiModem *self);

/** Affecter une fréquence au signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * @param self Le modem à modifier.
 * @param freq La fréquence du signal, en Hz.
 */
void LokiModem_set_mod_osc1_wave_frequency(const LokiModem *self, float freq);

/** Lire le pas de réglage de l'amplitude du signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * L'amplitude du signal est toujours un multiple de cette valeur.
 *
 * @param self Le modem à interroger.
 * @return La résolution du réglage de l'amplitude du signal, en mA.
 */
float LokiModem_get_mod_osc1_gain_res(const LokiModem *self);

/** Lire l'amplitude maximale supportée pour le signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * @param self Le modem à interroger.
 * @return L'amplitude maximale du signal, en mA.
 */
float LokiModem_get_mod_osc1_gain_max(const LokiModem *self);

/** Lire l'amplitude du signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * @param self Le modem à interroger.
 * @return L'amplitude du signal, en mA.
 */
float LokiModem_get_mod_osc1_gain(const LokiModem *self);

/** Affecter une amplitude au signal en sortie du premier oscillateur du modulateur (Fm1).
 *
 * @param self Le modem à modifier.
 * @param gain L'amplitude du signal, en mA.
 */
void LokiModem_set_mod_osc1_gain(const LokiModem *self, float gain);

/** Lire le pas de réglage de la fréquence du signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * La fréquence de l'oscillateur est toujours un multiple de cette valeur.
 *
 * @param self Le modem à interroger.
 * @return La résolution du réglage de la fréquence du signal, en Hz.
 */
float LokiModem_get_mod_osc2_wave_frequency_res(const LokiModem *self);

/** Lire la fréquence maximale supportée pour le signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * @param self Le modem à interroger.
 * @return La fréquence maximale du signal, en Hz.
 */
float LokiModem_get_mod_osc2_wave_frequency_max(const LokiModem *self);

/** Lire la fréquence du signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * @param self Le modem à interroger.
 * @return La fréquence du signal, en Hz.
 */
float LokiModem_get_mod_osc2_wave_frequency(const LokiModem *self);

/** Affecter une fréquence au signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * @param self Le modem à modifier.
 * @param freq La fréquence du signal, en Hz.
 */
void LokiModem_set_mod_osc2_wave_frequency(const LokiModem *self, float freq);

/** Lire le pas de réglage de l'amplitude du signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * L'amplitude du signal est toujours un multiple de cette valeur.
 *
 * @param self Le modem à interroger.
 * @return La résolution du réglage de l'amplitude du signal, en mA.
 */
float LokiModem_get_mod_osc2_gain_res(const LokiModem *self);

/** Lire l'amplitude maximale supportée pour le signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * @param self Le modem à interroger.
 * @return L'amplitude maximale du signal, en mA.
 */
float LokiModem_get_mod_osc2_gain_max(const LokiModem *self);

/** Lire l'amplitude du signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * @param self Le modem à interroger.
 * @return L'amplitude du signal, en mA.
 */
float LokiModem_get_mod_osc2_gain(const LokiModem *self);

/** Affecter une amplitude au signal en sortie du second oscillateur du modulateur (Fm2).
 *
 * @param self Le modem à modifier.
 * @param gain L'amplitude du signal, en mA.
 */
void LokiModem_set_mod_osc2_gain(const LokiModem *self, float gain);

/** Lire le pas de réglage de la fréquence du signal en sortie de l'oscillateur du démodulateur (Fm2).
 *
 * La fréquence de l'oscillateur est toujours un multiple de cette valeur.
 *
 * @param self Le modem à interroger.
 * @return La résolution du réglage de la fréquence du signal, en Hz.
 */
float LokiModem_get_demod_osc_wave_frequency_res(const LokiModem *self);

/** Lire la fréquence maximale supportée pour le signal en sortie de l'oscillateur du démodulateur (Fm2).
 *
 * @param self Le modem à interroger.
 * @return La fréquence maximale du signal, en Hz.
 */
float LokiModem_get_demod_osc_wave_frequency_max(const LokiModem *self);

/** Lire la fréquence du signal en sortie de l'oscillateur du démodulateur (Fm2).
 *
 * @param self Le modem à interroger.
 * @return La fréquence du signal, en Hz.
 */
float LokiModem_get_demod_osc_wave_frequency(const LokiModem *self);

/** Affecter une fréquence au signal en sortie de l'oscillateur du démodulateur (Fm2).
 *
 * @param self Le modem à modifier.
 * @param freq La fréquence du signal, en Hz.
 */
void LokiModem_set_demod_osc_wave_frequency(const LokiModem *self, float freq);

/** Lire le pas de réglage de l'offset en sortie du modulateur.
 *
 * @param self Le modem à interroger.
 * @return La résolution de l'offset, en mA.
 */
float LokiModem_get_mod_offset_res(const LokiModem *self);

/** Lire l'offset maximal supporté en sortie du modulateur.
 *
 * @param self Le modem à interroger.
 * @return L'offset maximal, en mA.
 */
float LokiModem_get_mod_offset_max(const LokiModem *self);

/** Lire l'offset en sortie du modulateur.
 *
 * @param self Le modem à interroger.
 * @return L'offset courant, en mA.
 */
float LokiModem_get_mod_offset(const LokiModem *self);

/** Affecter un offset en sortie du modulateur.
 *
 * @param self Le modem à modifier.
 * @param offset Le nouvel offset, en mA.
 */
void LokiModem_set_mod_offset(const LokiModem *self, float offset);

/** Lire le pas de réglage du courant moyen de commande de la diode laser.
 *
 * @param self Le modem à interroger.
 * @return La résolution du courant moyen, en mA.
 */
float LokiModem_get_mod_dc_value_res(const LokiModem *self);

/** Lire le courant moyen maximal supporté pour la commande de la diode laser.
 *
 * @param self Le modem à interroger.
 * @return Le courant moyen maximal, en mA.
 */
float LokiModem_get_mod_dc_value_max(const LokiModem *self);

/** Lire le courant moyen de commande de la diode laser.
 *
 * @param self Le modem à interroger.
 * @return Le courant moyen, en mA.
 */
float LokiModem_get_mod_dc_value(const LokiModem *self);

/** Affecter un courant moyen de commande de la diode laser.
 *
 * @param self Le modem à modifier.
 * @param dc_value Le nouveau courant moyen, en mA.
 */
void LokiModem_set_mod_dc_value(const LokiModem *self, float dc_value);

/** Lire le gain maximal de l'amplificateur de sortie.
 *
 * @param self Le modem à interroger.
 * @return Le gain maximal.
 */
uint32_t LokiModem_get_mod_pga_gain_max(const LokiModem *self);

/** Lire le gain de l'amplificateur de sortie.
 *
 * @param self Le modem à interroger.
 * @return La valeur courante du gain.
 */
uint32_t LokiModem_get_mod_pga_gain(const LokiModem *self);

/** Affecter un gain à l'amplificateur de sortie.
 *
 * @param self Le modem à modifier.
 * @param gain Le nouveau gain.
 */
void LokiModem_set_mod_pga_gain(const LokiModem *self, uint32_t gain);

/** Lire le nombre de voies du démodulateur.
 *
 * @param self Le modem à interroger.
 * @return Le nombre de voies.
 */
uint32_t LokiModem_get_demod_channels(const LokiModem *self);

/** Lire le facteur de décimation des filtres du démodulateur.
 *
 * Il s'agit du produit des facteurs de décimation des filtres en cascade
 * dans le démodulateur.
 *
 * @param self Le modem à interroger.
 * @return Le facteur de décimation entre l'entrée et la sortie du démodulateur.
 */
uint32_t LokiModem_get_demod_decimation(const LokiModem *self);

/** Lire la bande passante des filtres du démodulateur.
 *
 * Il s'agit de la bande passante du dernier étage de filtrage passe-bas
 * dans le démodulateur.
 *
 * @param self Le modem à interroger.
 * @return La  bande passange en sortie du démodulateur.
 */
float LokiModem_get_demod_bandwidth(const LokiModem *self);

/** Lire la fréquence d'échantillonnage en entrée du démodulateur.
 *
 * @param self Le modem à interroger.
 * @return La fréquence d'échantillonnage, en Hz.
 */
float LokiModem_get_demod_sampling_frequency(const LokiModem *self);

/** Affecter une fréquence d'échantillonnage en entrée du démodulateur.
 *
 * Cette fonction préserve la fréquence réglée précédemment pour l'oscillateur
 * Fm2 du démodulateur.
 *
 * @param self Le modem à modifier.
 * @param freq La fréquence d'échantillonnage, en Hz.
 */
void LokiModem_set_demod_sampling_frequency(const LokiModem *self, float freq);

/** Lire la fréquence d'échantillonnage en sortie du démodulateur.
 *
 * @param self Le modem à interroger.
 * @return La fréquence d'échantillonnage, en Hz.
 */
float LokiModem_get_demod_xy_sampling_frequency(const LokiModem *self);

/** Affecter une fréquence d'échantillonnage en sortie du démodulateur.
 *
 * Connaissant le facteur de décimation des filtres du démodulateur, cette
 * fonction modifie la fréquence d'échantillonnage en entrée pour atteindre
 * la fréquence souhaitée en sortie.
 *
 * @param self Le modem à modifier.
 * @param freq La fréquence d'échantillonnage, en Hz.
 */
void LokiModem_set_demod_xy_sampling_frequency(const LokiModem *self, float freq);

/** Lire le retard maximal applicable à la composante X (I) du signal démodulé pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le retard maximal, en échantillons.
 */
uint32_t LokiModem_get_demod_delay_x_max(const LokiModem *self, uint32_t channel);

/** Lire le déphasage maximal applicable à la composante X (I) du signal démodulé pour une voie.
 *
 * @see LokiModem_get_demod_delay_x_max
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le déphasage maximal, en degrés.
 */
float LokiModem_get_demod_phase_x_max(const LokiModem *self, uint32_t channel);

/** Lire le pas de réglage du déphasage applicable à la composante X (I) du signal démodulé pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le pas de réglage du déphasage, en degrés.
 */
float LokiModem_get_demod_phase_x_res(const LokiModem *self, uint32_t channel);

/** Lire le retard appliqué à la composante X (I) du signal démodulé pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le retard, en échantillons.
 */
uint32_t LokiModem_get_demod_delay_x(const LokiModem *self, uint32_t channel);

/** Lire le déphasage appliqué à la composante X (I) du signal démodulé pour une voie.
 *
 * @see LokiModem_get_demod_delay_x
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le déphasage, en degrés.
 */
float LokiModem_get_demod_phase_x(const LokiModem *self, uint32_t channel);

/** Affecter un retard à la composante X (I) du signal démodulé pour une voie.
 *
 * @param self Le modem à modifier.
 * @param channel Un numéro de voie.
 * @param delay Le nouveau retard, en échantillons.
 */
void LokiModem_set_demod_delay_x(const LokiModem *self, uint32_t channel, uint32_t delay);

/** Affecter un déphasage à la composante X (I) du signal démodulé pour une voie.
 *
 * @see LokiModem_set_demod_delay_x
 * @param self Le modem à modifier.
 * @param channel Un numéro de voie.
 * @param phase Le nouveau déphasage, en degrés.
 */
void LokiModem_set_demod_phase_x(const LokiModem *self, uint32_t channel, float phase);

/** Lire le retard maximal applicable à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le retard maximal, en échantillons.
 */
uint32_t LokiModem_get_demod_delay_y_max(const LokiModem *self, uint32_t channel);

/** Lire le déphasage maximal applicable à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @see LokiModem_get_demod_delay_y_max
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le déphasage maximal, en degrés.
 */
float LokiModem_get_demod_phase_y_max(const LokiModem *self, uint32_t channel);

/** Lire le pas de réglage du déphasage applicable à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le pas de réglage du déphasage, en degrés.
 */
float LokiModem_get_demod_phase_y_res(const LokiModem *self, uint32_t channel);

/** Lire le retard appliqué à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le retard, en échantillons.
 */
uint32_t LokiModem_get_demod_delay_y(const LokiModem *self, uint32_t channel);

/** Lire le déphasage appliqué à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @see LokiModem_get_demod_delay_y
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le déphasage, en degrés.
 */
float LokiModem_get_demod_phase_y(const LokiModem *self, uint32_t channel);

/** Affecter un retard à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @param self Le modem à modifier.
 * @param channel Un numéro de voie.
 * @param delay Le nouveau retard, en échantillons.
 */
void LokiModem_set_demod_delay_y(const LokiModem *self, uint32_t channel, uint32_t delay);

/** Affecter un déphasage à la composante Y (Q) du signal démodulé pour une voie.
 *
 * @see LokiModem_set_demod_delay_y
 * @param self Le modem à modifier.
 * @param channel Un numéro de voie.
 * @param phase Le nouveau déphasage, en degrés.
 */
void LokiModem_set_demod_phase_y(const LokiModem *self, uint32_t channel, float phase);

/** Lire le gain maximal de l'amplificateur en entrée du démodulateur pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le gain maximal.
 */
float LokiModem_get_demod_pga_gain_max(const LokiModem *self, uint32_t channel);

/** Lire le gain de l'amplificateur en entrée du démodulateur pour une voie.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return Le gain actuel.
 */
float LokiModem_get_demod_pga_gain(const LokiModem *self, uint32_t channel);

/** Affecter un gain à l'amplificateur en entrée du démodulateur pour une voie.
 *
 * @param self Le modem à modifier.
 * @param channel Un numéro de voie.
 * @param gain Le nouveau gain.
 */
void LokiModem_set_demod_pga_gain(const LokiModem *self, uint32_t channel, float gain);

/** Lire la valeur minimale du signal en entrée du démodulateur pour une voie.
 *
 * Cette valeur est mesurée sur une fenêtre glissante gérée dans le FPGA.
 *
 * La valeur retournée est comprise entre -1.0 et 1.0.
 * Les valeurs extrêmes correspondent à la saturation du convertisseur
 * analogique-numérique d'entrée.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return La valeur minimale du signal sur cette voie.
 */
float LokiModem_get_demod_adc_min_ratio(const LokiModem *self, uint32_t channel);

/** Lire la valeur maximale du signal en entrée du démodulateur pour une voie.
 *
 * Cette valeur est mesurée sur une fenêtre glissante gérée dans le FPGA.
 *
 * La valeur retournée est comprise entre -1.0 et 1.0.
 * Les valeurs extrêmes correspondent à la saturation du convertisseur
 * analogique-numérique d'entrée.
 *
 * @param self Le modem à interroger.
 * @param channel Un numéro de voie.
 * @return La valeur maximale du signal sur cette voie.
 */
float LokiModem_get_demod_adc_max_ratio(const LokiModem *self, uint32_t channel);

/** Lire la longueur maximale d'un paquet de données en sortie du démodulateur.
 *
 * Il s'agit du nombre maximal d'échantillons qui sont échangés lors
 * d'un transfert DMA entre le démodulateur et le processeur.
 *
 * @param self Le modem à interroger.
 * @return La longueur maximale des transferts DMA, en échantillons.
 */
uint32_t LokiModem_get_demod_packet_length_max(const LokiModem *self);

/** Lire la longueur d'un paquet de données en sortie du démodulateur.
 *
 * Il s'agit du nombre d'échantillons qui sont échangés lors
 * d'un transfert DMA entre le démodulateur et le processeur.
 *
 * @param self Le modem à interroger.
 * @return La longueur des transferts DMA, en échantillons.
 */
uint32_t LokiModem_get_demod_packet_length(const LokiModem *self);

/** Identifier le type de démodulateur implanté dans le FPGA.
 *
 * Il existe deux implémentations du démodulateur :
 * - une version qui utilise des oscillateurs pour effectuer un décalage en fréquence
 * - une version "mixerless" qui procède par décimation
 *
 * @param self Le modem à interroger.
 * @return true si le démodulateur fonctionne par décimation.
 */
bool LokiModem_get_demod_mixerless(const LokiModem *self);

/** Lire l'état d'activation du démodulateur.
 *
 * En mode "bypass", les données brutes du convertisseur analogique/numérique
 * sont transmises par DMA sans passer par le démodulateur.
 *
 * @param self Le modem à interroger.
 * @return true si le mode bypass est activé.
 */
bool LokiModem_get_demod_bypass(const LokiModem *self);

/** Activer ou désactiver le démodulateur.
 *
 * En mode "bypass", les données brutes du convertisseur analogique/numérique
 * sont transmises par DMA sans passer par le démodulateur.
 *
 * @param self Le modem à interroger.
 * @param bypass true pour utiliser le mode "bypass".
 */
void LokiModem_set_demod_bypass(const LokiModem *self, bool bypass);

/** Lire l'état d'activation du mode de test.
 *
 * En mode "test", la sortie du modulateur est remplacée par un motif qui
 * permet de vérifier les valeurs transmises au convertisseur numérique/analogique.
 *
 * @param self Le modem à interroger.
 * @return true si le mode de test est activé.
 */
bool LokiModem_get_test_mode(const LokiModem *self);

/** Activer ou désactiver le mode de test.
 *
 * En mode "test", la sortie du modulateur est remplacée par un motif qui
 * permet de vérifier les valeurs transmises au convertisseur numérique/analogique.
 *
 * @param self Le modem à interroger.
 * @param test_mode true pour activer le mode de test.
 */
void LokiModem_set_test_mode(const LokiModem *self, bool test_mode);

/** Redémarrer le modem.
 *
 * Cette fonction déclenche une réinitialisation des oscillateurs internes
 * et des compteurs d'échantillons du modem dans le FPGA.
 * Elle doit être appelée à chaque modification des paramètres de modulation,
 * de démodulation ou de communication avec le modem.
 *
 * @param self Le modem à redémarrer.
 */
void LokiModem_restart(const LokiModem *self);

/** Lire le nombre d'échantillons reçus sur une voie ADC en entrée du démodulateur.
 *
 * Ce compteur est remis à zéro à chaque redémarrage du modem.
 *
 * @param self Le modem à interroger.
 * @return Le nombre d'échantillons par voie.
 */
uint32_t LokiModem_get_adc_sample_count(const LokiModem *self);

/** Lire le nombre d'échantillons envoyés sur la sortie DAC du modulateur.
 *
 * Ce compteur est remis à zéro à chaque redémarrage du modem.
 *
 * @param self Le modem à interroger.
 * @return Le nombre d'échantillons.
 */
uint32_t LokiModem_get_dac_sample_count(const LokiModem *self);

/** Lire le nombre d'échantillons produits sur une voie en sortie du démodulateur.
 *
 * Ce compteur est remis à zéro à chaque redémarrage du modem.
 *
 * @param self Le modem à interroger.
 * @return Le nombre d'échantillons démodulés par voie.
 */
uint32_t LokiModem_get_demod_sample_count(const LokiModem *self);

/** Démarrer l'acquisition et le traitement des échantillons démodulés.
 *
 * Cette fonction est non bloquante.
 * Elle crée un nouveau thread qui démarre les transferts par DMA depuis le démodulateur
 * et qui alimente la FIFO de sortie à chaque transfert.
 *
 * @param self Le modem à démarrer.
 * @param channels Un masque indiquant les voies à traiter, -1 pour toutes les voies.
 * @param simulate Faut-il simuler un capteur logiciellement ?
 * @param raw Faut-il conserver les valeurs d'échantillons en virgule fixe ?
 * @param out La FIFO de destination.
 * @return Le code d'erreur retourné par `pthread_create`.
 */
int LokiModem_start_streaming(LokiModem *self, int32_t channels, bool simulate, bool raw, LokiFIFO *out);

/** Arrêter l'acquisition.
 *
 * Interrompt l'exécution du thread démarré par la fonction #LokiModem_start_streaming.
 *
 * @param self Le modem à arrêter.
 */
void LokiModem_stop_streaming(LokiModem *self);

/** Arrêter l'acquisition immédiatement.
 *
 * Interrompt l'exécution du thread lancé par la fonction #LokiModem_start_streaming.
 * Cette fonction force l'arrêt des transferts DMA sans attendre la fin d'un paquet.
 *
 * @param self Le modem à arrêter.
 */
void LokiModem_force_stop(const LokiModem *self);

/** Lire l'état de l'acquisition.
 *
 * @param self Le modem à interroger.
 * @return true si l'acquisition est en cours.
 */
bool LokiModem_is_streaming(const LokiModem *self);

/** Lire le nombre de paquets perdus depuis le début de l'acquisition.
 *
 * Le pilote du modem compte le nombre de paquets qui ont été reçus par
 * transfert DMA, mais qui ont été écrasés avant d'être traités.
 *
 * @param self Le modem à interroger.
 * @return Le nombre de paquets d'échantillons perdus.
 */
unsigned LokiModem_get_dropped_packets(const LokiModem *self);

/** Afficher la configuration d'un modem sur la sortie standard.
 *
 * @param self Le modem à examiner.
 */
void LokiModem_print_config(const LokiModem *self);

#endif

/// @}
/// @}

/// @ingroup gLokiModem
/// @file libloki-modem.h
/// @author Guillaume Savaton
/// @copyright ESEO
