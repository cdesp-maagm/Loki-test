/// @defgroup ggLokiRecording Enregistrement et transmission de données
/// @{

/**
 * @defgroup gLokiRecorder Enregistrement de séries temporelles
 *
 * Ce module délègue les opérations de mise en forme et d'écriture à une
 * implémentation de l'interface @ref gLokiFormatter "LokiFormatter".
 */

/// @{

#ifndef LIBLOKI_RECORDER_H_
#define LIBLOKI_RECORDER_H_

#include "libloki-fifo.h"

/// Représentation d'un enregistreur de séries temporelles.
typedef struct LokiRecorder LokiRecorder;

/** Construire un enregistreur de séries temporelles.
 *
 * @param filename Le nom de base des fichiers de destination (sans extension).
 * @param filetype Le format des fichiers de destination ("raw" ou "mseed").
 * @param max_channels Le nombre maximal de voies que cet enregistreur peut traiter.
 * @param channels Un masque indiquant les voies à traiter.
 * @param sample_size La taille d'un échantillon, en octets.
 * @param sampling_frequency La fréquence d'échantillonnage, en Hz.
 * @param duration La durée totale d'enregistrement, 0 pour enregistrer indéfiniment.
 * @param duration_per_file La durée approximative d'enregistrement par fichier. La durée effective dépend de la taille des paquets de données.
 * @param config Une configuration à passer au formateur correspondant au format de fichier choisi.
 * @return Un nouvel enregistreur.
 */
LokiRecorder *LokiRecorder_new(const char *filename, const char *filetype, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency, float duration, float duration_per_file, void *config);

/** Lire le nom des fichiers gérés par un enregistreur.
 *
 * @param self L'enregistreur à interroger.
 * @return Le nom de base des fichiers de destination.
 */
char *LokiRecorder_get_filename(const LokiRecorder *self);

/** Lire le nombre de voies gérées par un enregistreur.
 *
 * @param self L'enregistreur à interroger.
 * @return Le nombre de voies à enregistrer.
 */
size_t LokiRecorder_get_channel_count(const LokiRecorder *self);

/** Démarrer l'enregistrement.
 *
 * Cette fonction est non bloquante.
 * Elle démarre un thread qui lit les données d'une FIFO et les enregistre.
 *
 * @param self L'enregistreur à démarrer.
 * @param in La FIFO de données à enregistrer.
 * @param cid Le numéro de consommateur de cette instance dans la FIFO.
 * @return Le code d'erreur de `pthread_create`.
 */
int LokiRecorder_start(LokiRecorder *self, LokiFIFO *in, size_t cid);

/** Lire l'état d'un enregistreur.
 *
 * @param self L'enregistreur à interroger.
 * @return true si l'enregistrement est en cours.
 */
bool LokiRecorder_is_recording(LokiRecorder *self);

/** Attendre la fin de l'enregistrement.
 *
 * Cette fonction bloque le thread courant jusqu'à ce que l'enregistrement
 * en cours se termine.
 *
 * @param self L'enregistreur à attendre.
 */
void LokiRecorder_wait(LokiRecorder *self);

/** Arrêter l'enregistrement.
 *
 * Interrompt l'exécution du thread démarré par la fonction #LokiRecorder_start.
 *
 * @param self L'enregistreur à arrêter.
 */
void LokiRecorder_stop(LokiRecorder *self);

/** Détruire un enregistreur.
 *
 * @param self L'enregistreur à détruire.
 */
void LokiRecorder_del(LokiRecorder *self);

#endif

/// @}
/// @}

/// @ingroup gLokiRecorder
/// @file libloki-recorder.h
/// @author Guillaume Savaton
/// @copyright ESEO
