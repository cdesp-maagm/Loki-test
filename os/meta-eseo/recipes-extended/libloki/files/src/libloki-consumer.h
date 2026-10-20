/**
 * @ingroup ggLokiInterconnect
 * @defgroup gLokiConsumer Exemple de consommateur
 *
 * Ce module fournit une implémentation de référence d'un consommateur qui
 * lit les données dans une @ref gLokiFIFO "FIFO" et qui ne les utilise pas.
 *
 * Il peut être utilisé comme *bouchon* en sortie d'une FIFO dont les données
 * ne sont pas utilisées.
 *
 * Il peut aussi servir d'exemple de référence pour construire d'autres consommateurs
 */

/// @{

#ifndef LIBLOKI_CONSUMER_H_
#define LIBLOKI_CONSUMER_H_

#include "libloki-fifo.h"

/// Le type consommateur.
typedef struct LokiConsumer LokiConsumer;

/** Construire un consommateur.
 *
 * @return Un nouveau consommateur.
 */
LokiConsumer *LokiConsumer_new(void);

/** Démarrer un consommateur.
 *
 * Cette fonction est non bloquante.
 * Elle crée un nouveau thread qui consomme les données d'une FIFO.
 *
 * @param self Le consommateur à démarrer.
 * @param in La FIFO à lire.
 * @param cid Le numéro de consommateur pour la FIFO.
 * @return Le code d'erreur retourné par `pthread_create`.
 */
int LokiConsumer_start(LokiConsumer *self, LokiFIFO *in, size_t cid);

/** Arrêter un consommateur.
 *
 * Cette fonction arrête le thread démarré par #LokiConsumer_start
 * pour le même consommateur.
 *
 * @param self Le consommateur à arrêter.
 */
void LokiConsumer_stop(LokiConsumer *self);

/** Détruire un consommateur.
 *
 * Désallouer la mémoire allouée par #LokiConsumer_new.
 *
 * @param self Le consommateur à détruire.
 */
void LokiConsumer_del(LokiConsumer *self);

#endif

/// @file libloki-consumer.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
