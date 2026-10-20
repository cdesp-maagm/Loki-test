/**
 * @ingroup ggLokiRecording
 * @defgroup gLokiSocketServer Serveur de données sur socket Unix
 *
 * Ce module est utilisé dans la communication des données de déplacement
 * par WebSockets.
 */
/// @{

#ifndef LIBLOKI_SOCKET_SERVER_H_
#define LIBLOKI_SOCKET_SERVER_H_

#include "libloki-fifo.h"

/// Le nombre maximum de connexions simultanées acceptées par un serveur.
#define LIBLOKI_SOCKET_SERVER_CONNECTIONS 3

/// Représentation d'un serveur de données.
typedef struct LokiSocketServer LokiSocketServer;

/** Construire un serveur de données.
 *
 * @param filename Le nom de fichier à utiliser pour représenter la socket Unix dans le système de fichiers.
 * @return Un nouveau serveur.
 */
LokiSocketServer *LokiSocketServer_new(const char *filename);

/** Démarrer un serveur.
 *
 * Cette fonction est non bloquante.
 * Elle démarre deux threads: un pour traiter les paquets de données d'entrée,
 * l'autre pour gérer les connexions des clients et leur transmettre les données
 * aux clients.
 *
 * @param self Le serveur à démarrer.
 * @param in La FIFO contenant les données à transmettre.
 * @param cid Le numéro de consommateur de ce serveur dans sa FIFO d'entrée.
 * @return Le code d'erreur retournée par `pthread_create`.
 */
int LokiSocketServer_start(LokiSocketServer *self, LokiFIFO *in, size_t cid);

/** Lire l'état du serveur.
 *
 * @param self Le serveur à interroger.
 * @return true si le serveur est démarré.
 */
bool LokiSocketServer_is_streaming(LokiSocketServer *self);

/** Arrêter un serveur.
 *
 * Interrompt l'exécution des threads démarrés par la fonction #LokiSocketServer_start.
 *
 * @param self Le serveur à arrêter.
 */
void LokiSocketServer_stop(LokiSocketServer *self);

/** Détruire un serveur.
 *
 * @param self Le serveur à détruire.
 */
void LokiSocketServer_del(LokiSocketServer *self);

#endif

/// @file libloki-socket-server.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
