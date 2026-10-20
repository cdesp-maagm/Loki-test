/**
 * @ingroup ggLokiRecording
 * @defgroup gLokiFormatter Interface pour la mise en forme de séries temporelles
 *
 * Définition des méthodes communes pour enregistrer des séries temporelles.
 */

/// @{

#ifndef LIBLOKI_FORMATTER_H_
#define LIBLOKI_FORMATTER_H_

#include "libloki-class.h"
#include "libloki-time.h"

#include <stdbool.h>
#include <stddef.h>
#include <inttypes.h>

/// Représentation d'un formateur de séries temporelles.
typedef struct LokiFormatter LokiFormatter;

/** Construire un nouveau formateur de séries temporelles.
 *
 * @param config Une configuration pour le nouveau formateur.
 * @return Une instance de LokiFormatter.
 */
LokiFormatter *LokiFormatter_new(void *config);

/** Enregistrer un paquet de données.
 *
 * Cette fonction délègue à une implémentation de l'interface LokiFormatter.
 *
 * @param self L'instance à utiliser.
 * @param filename Le nom du fichier de destination.
 * @param timestamp La date du paquet de données.
 * @param file_change Faut-il ouvrir un nouveau fichier de destination ou poursuivre le fichier précédent ?
 * @param data Les données à écrire.
 * @param length Le nombre d'échantillons à écrire.
 * @param max_channels Le nombre maximal de voies à traiter.
 * @param channels Un masque indiquant les voies à traiter.
 * @param sample_size La taille d'un échantillon, en octets.
 * @param sampling_frequency La fréquence d'échantillonage.
 */
void LokiFormatter_work(LokiFormatter *self, const char *filename, LokiTimestamp timestamp, bool file_change, void *data, size_t length, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency);

/** Fermer un formateur de séries temporelles.
 *
 * Cette fonction ferme le dernier fichier ouvert.
 * Elle doit être appelée à la fin de l'enregistrement.
 *
 * @param self L'instance à fermer.
 */
void LokiFormatter_close(LokiFormatter *self);

/** Détruire de mise en forme de séries temporelles.
 *
 * @param self L'instance à détruire.
 */
void LokiFormatter_del(LokiFormatter *self);

LokiClass_interface(LokiFormatter,
    LokiClass_method(LokiFormatter, new)
    LokiClass_method(LokiFormatter, work)
    LokiClass_method(LokiFormatter, close)
    LokiClass_method(LokiFormatter, del)
);

/** Construire un nouveau formateur de séries temporelles avec une implémentation donnée.
 *
 * @param impl L'implémentation de LokiFormatter à utiliser.
 * @param config Une configuration pour le nouveau formateur.
 * @return Une instance de LokiFormatter.
 */
LokiFormatter *LokiFormatter_new_with_implementation(const LokiFormatterInterface *impl, void *config);

#endif

/// @file libloki-formatter.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
