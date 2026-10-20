/**
 * @ingroup ggLokiRecording
 * @defgroup gLokiRaw Enregistrement de séries temporelles brutes
 *
 * Ce module implémente l'interface @ref gLokiFormatter "LokiFormatter".
 */

/// @{

#ifndef LIBLOKI_RAW_H_
#define LIBLOKI_RAW_H_

#include "libloki-formatter.h"

/// Représentation d'un formateur de données brutes.
typedef struct LokiRaw LokiRaw;

/** Construire un formateur de données brutes.
 *
 * @param config La configuration à appliquer (inutilisée pour ce format).
 * @return Un nouveau formateur de données brutes.
 */
LokiRaw *LokiRaw_new(void *config);

/** Enregistrer un paquet de données.
 *
 * @param self Le formateur de données brutes à utiliser.
 * @param filename Le nom du fichier de destination.
 * @param timestamp La date du paquet de données (inutilisée pour ce format).
 * @param file_change Faut-il ouvrir un nouveau fichier de destination ou poursuivre le fichier précédent ?
 * @param data Les données à écrire.
 * @param length Le nombre d'échantillons à écrire.
 * @param max_channels Le nombre maximal de voies à traiter.
 * @param channels Un masque indiquant les voies à traiter.
 * @param sample_size La taille d'un échantillon, en octets.
 * @param sampling_frequency La fréquence d'échantillonage (inutilisée pour ce format).
 */
void LokiRaw_work(LokiRaw *self, const char *filename, LokiTimestamp timestamp, bool file_change, void *data, size_t length, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency);

/** Fermer un formateur de données brutes.
 *
 * Cette fonction ferme le dernier fichier ouvert.
 * Elle doit être appelée à la fin de l'enregistrement.
 *
 * @param self Le formateur à fermer.
 */
void LokiRaw_close(LokiRaw *self);

/** Détruire un formateur de données brutes.
 *
 * @param self Le formateur à détruire.
 */
void LokiRaw_del(LokiRaw *self);

LokiClass_declare_implementation(LokiFormatter, LokiRaw);

#endif

/// @file libloki-raw.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
