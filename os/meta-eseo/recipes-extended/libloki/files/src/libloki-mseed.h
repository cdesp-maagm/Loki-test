/**
 * @ingroup ggLokiRecording
 * @defgroup gLokiMSeed Enregistrement de séries temporelles au format miniSEED
 *
 * Ce module implémente l'interface @ref gLokiFormatter "LokiFormatter". Il s'appuie sur la bibliothèque `libmseed` de l'IRIS.
 */

/// @{

#ifndef LIBLOKI_MSEED_H_
#define LIBLOKI_MSEED_H_

#include "libloki-formatter.h"

/// Configuration d'un formateur de séries temporelles miniSEED.
typedef struct LokiMSeedConfig LokiMSeedConfig;

/** Construire une configuration d'enregistrement de données au format miniSEED.
 *
 * @param separate_channels Faut-il enregistrer chaque voie dans un fichier séparé ?
 * @param station L'identifiant de station de l'interrogateur.
 * @param location L'identifiant de localisation de l'interrogateur.
 * @param network L'identifiant de réseau de l'interrogateur.
 * @param raw Faut-il utiliser les valeurs brutes des échantillons ?
 * @param steim2 Faut-il utiliser l'algorithme de compression STEIM2 ?
 * @param channel_names Un tableau de nom de voies.
 * @return Une nouvelle configuration d'enregistrement au format miniSEED.
 */
LokiMSeedConfig *LokiMSeedConfig_new(bool separate_channels, const char *station, const char *location, const char *network, bool raw, bool steim2, const char *channel_names);

/** Détruire une configuration d'enregistrement de données au format miniSEED.
 *
 * @param self La configuration à détruire.
 */
void LokiMSeedConfig_del(LokiMSeedConfig *self);

/// Représentation d'un formateur de séries temporelles miniSEED.
typedef struct LokiMSeed LokiMSeed;

/** Construire un formateur de séries temporelles miniSEED.
 *
 * @param config La configuration à appliquer.
 * @return Un nouveau formateur de séries temporelles miniSEED.
 */
LokiMSeed *LokiMSeed_new(LokiMSeedConfig *config);

/** Enregistrer un paquet de données au format miniSEED.
 *
 * Cette fonction attend un tableau d'échantillons dont les éléments ont un type
 * de la forme :
 *
 * ```c
 * struct Sample {
 *     uint32_t channel;
 *     float value;
 *     ... // Autres données spécifiques
 * }
 * ```
 *
 * On doit avoir `sample_size == sizeof(struct Sample)`
 *
 * @param self Le formateur de séries temporelles miniSEED.
 * @param filename Le nom du fichier de destination.
 * @param timestamp La date du paquet de données (inutilisée pour ce format).
 * @param file_change Faut-il ouvrir un nouveau fichier de destination ou poursuivre le fichier précédent ?
 * @param data Les données à écrire.
 * @param length Le nombre d'échantillons à écrire.
 * @param max_channels Le nombre maximal de voies que ce formateur peut traiter.
 * @param channels Un masque indiquant les voies à traiter.
 * @param sample_size La taille d'un échantillon, en octets.
 * @param sampling_frequency La fréquence d'échantillonage (inutilisée pour ce format).
 */
void LokiMSeed_work(LokiMSeed *self, const char *filename, LokiTimestamp timestamp, bool file_change, void *data, size_t length, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency);

/** Fermer un formateur de séries temporelles miniSEED.
 *
 * Cette fonction ferme le dernier fichier ouvert.
 * Elle doit être appelée à la fin de l'enregistrement.
 *
 * @param self Le formateur à fermer.
 */
void LokiMSeed_close(LokiMSeed *self);

/** Détruire un formateur de séries temporelles miniSEED.
 *
 * @param self Le formateur à détruire.
 */
void LokiMSeed_del(LokiMSeed *self);

LokiClass_declare_implementation(LokiFormatter, LokiMSeed);

#endif

/// @file libloki-mseed.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
