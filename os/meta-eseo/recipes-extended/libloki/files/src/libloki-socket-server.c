
/// Permettre l'utilisation de la fonction `pthread_setname_np` pour modifier le nom d'un thread.
#define _GNU_SOURCE

#include "libloki.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include <pthread.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

/// @addtogroup gLokiSocketServer
/// @{

/// Représentation d'un serveur de données.
struct LokiSocketServer {
    /// Le nom de fichier à utiliser pour représenter la socket Unix dans le système de fichiers.
    char *filename;
    /// La FIFO contenant les données à transmettre.
    LokiFIFO *in;
    /// Le numéro de consommateur de ce serveur dans sa FIFO d'entrée.
    size_t cid;
    /// Indicateur de demande d'arrêt du serveur.
    volatile bool stop_request;
    /// Le serveur est-il en service ?
    bool is_streaming;
    /// Le thread de réception des données.
    pthread_t receiver_thread;
    /// Le thread qui gère les connexions des clients et transmet les données.
    pthread_t server_thread;
    /// Un mutex pour gérer les accès concurrents au paquet de données courant.
    pthread_mutex_t mutex;
    /// Le dernier paquet de données reçu.
    void *data;
    /// La taille totale d'un paquet de données, en octets.
    size_t data_size;
    /// Indicateur de présence d'un nouveau paquet à transmettre.
    bool has_data;
    /// Variable conditionnelle pour débloquer le thread serveur lorsqu'un nouveau paquet est disponible.
    pthread_cond_t has_data_cond;
};

LokiSocketServer *LokiSocketServer_new(const char *filename) {
    LokiSocketServer *self = calloc(1, sizeof(LokiSocketServer));
    if (!self) {
        return NULL;
    }

    self->filename = strdup(filename);
    if (!self->filename) {
        LokiSocketServer_del(self);
        return NULL;
    }

    pthread_mutex_init(&self->mutex, NULL);
    pthread_cond_init(&self->has_data_cond, NULL);

    return self;
}

/** Recevoir les données d'entrée.
 *
 * Cette fonction est exécutée dans un thread démarré par #LokiSocketServer_start.
 * Elle consomme les données de la FIFO d'entrée jusqu'à la demande d'arrêt
 * par #LokiSocketServer_stop.
 *
 * @param ptr Le serveur courant.
 * @return Rien.
 */
static void *LokiSocketServer_receive(void *ptr) {
    LokiSocketServer *self = ptr;

    pthread_setname_np(self->receiver_thread, "LokiSocketRecv");

    self->data_size = LokiPacket_get_length(self->in,  1);

    while (!self->stop_request) {
        // Lire un paquet de données.
        LokiPacket *in_packet = LokiFIFO_get_consumer_item(self->in, self->cid);
        if (!in_packet) {
            break;
        }

        // Si une connexion est ouverte, indiquer la disponibilité
        // des données au thread serveur.
        pthread_mutex_lock(&self->mutex);
        self->data = in_packet->buffer;
        self->has_data = true;
        pthread_cond_signal(&self->has_data_cond);
        pthread_mutex_unlock(&self->mutex);

        LokiFIFO_pull(self->in, self->cid);
    }

    self->is_streaming = false;
}

/** Gérer les connexions et transmettre les données aux clients.
 *
 * Cette fonction est exécutée dans un thread démarré par #LokiSocketServer_start.
 * Elle crée une socket Unix et transmet les données reçues jusqu'à la demande d'arrêt
 * par #LokiSocketServer_stop.
 *
 * @param ptr Le serveur courant.
 * @return Rien.
 */
static void *LokiSocketServer_serve(void *ptr) {
    LokiSocketServer *self = ptr;

    pthread_setname_np(self->server_thread, "LokiSocketServe");

    // Créer une socket.
    int sock = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK, 0);
    bool has_file  = false;
    bool listening = false;
    int conn[LIBLOKI_SOCKET_SERVER_CONNECTIONS];
    bool status[LIBLOKI_SOCKET_SERVER_CONNECTIONS] = {false};
    size_t accept_index = 0;

    if (sock < 0) {
        fprintf(stderr, "LokiSocketServer_serve (%s): socket creation failed (%s).\n", self->filename, strerror(errno));
    }
    else {
        // Attacher cette socket à un nom de fichier.
        struct sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        strncpy(addr.sun_path, self->filename, sizeof(addr.sun_path) - 1);
        has_file = !bind(sock, (struct sockaddr*)&addr, sizeof(addr));
        if (!has_file) {
            fprintf(stderr, "LokiSocketServer_serve (%s): failed to bind socket (%s).\n", self->filename, strerror(errno));
        }
        else {
            // En cas de succès, écouter les demandes de connexion.
            listening = !listen(sock, 1);
            if (!listening) {
                fprintf(stderr, "LokiSocketServer_serve (%s): failed to start listening on socket (%s).\n", self->filename, strerror(errno));
            }
        }
    }

    while (!self->stop_request) {
        pthread_mutex_lock(&self->mutex);
        if (!self->has_data) {
            pthread_cond_wait(&self->has_data_cond, &self->mutex);
        }
        if (self->stop_request) {
            break;
        }
        const char *data = self->data;
        self->has_data = false;
        pthread_mutex_unlock(&self->mutex);

        if (!listening) {
            continue;
        }

        // Vérifier si une demande de connexion est présente en file d'attente.
        // La socket est non bloquante.
        if (accept_index < LIBLOKI_SOCKET_SERVER_CONNECTIONS) {
            conn[accept_index] = accept(sock, NULL, NULL);
            if (conn[accept_index] >= 0) {
                fprintf(stderr, "LokiSocketServer_serve (%s): accepting connection %zu/%zu.\n", self->filename, accept_index, LIBLOKI_SOCKET_SERVER_CONNECTIONS);
                // Marquer la connexion comme établie et chercher un slot libre
                // pour la prochaine connexion.
                status[accept_index] = true;
                for (accept_index = 0; accept_index < LIBLOKI_SOCKET_SERVER_CONNECTIONS && status[accept_index]; accept_index ++);
            }
        }

        // Pour chaque connexion ouverte, transmettre le paquet au client.
        for (size_t i = 0; i < LIBLOKI_SOCKET_SERVER_CONNECTIONS; i ++) {
            if (!status[i]) {
                continue;
            }

            const char* remaining_data = data;
            size_t remaining_size      = self->data_size;
            while (remaining_size > 0) {
                ssize_t sz = write(conn[i], remaining_data, remaining_size);
                if (sz >= 0) {
                    remaining_size -= sz;
                    remaining_data += sz;
                }
                else if (errno != EINTR) {
                    fprintf(stderr, "LokiSocketServer_serve (%s): write error on connection %zu (%s).\n", self->filename, i, strerror(errno));
                    status[i] = false;
                    accept_index = i;
                    break;
                }
            }
        }
    }

    if (sock >= 0) {
        close(sock);
    }

    if (has_file) {
        unlink(self->filename);
    }
}

int LokiSocketServer_start(LokiSocketServer *self, LokiFIFO *in, size_t cid) {
    self->is_streaming = true;
    self->in           = in;
    self->cid          = cid;
    self->stop_request = false;
    int err = pthread_create(&self->receiver_thread, NULL, LokiSocketServer_receive, self);
    if (err) {
        return err;
    }
    return pthread_create(&self->server_thread, NULL, LokiSocketServer_serve, self);
}

bool LokiSocketServer_is_streaming(LokiSocketServer *self) {
    return self->is_streaming;
}

void LokiSocketServer_stop(LokiSocketServer *self) {
    if (self->stop_request) {
        return;
    }
    self->stop_request = true;

    // Débloquer le thread de réception.
    LokiFIFO_abort(self->in);

    // Débloquer le thread serveur.
    pthread_mutex_lock(&self->mutex);
    pthread_cond_signal(&self->has_data_cond);
    pthread_mutex_unlock(&self->mutex);

    // Attendre la terminaison normale des deux threads.
    pthread_join(self->receiver_thread, NULL);
    pthread_join(self->server_thread, NULL);
}

void LokiSocketServer_del(LokiSocketServer *self) {
    if (!self) {
        return;
    }

    if (self->filename) {
        free(self->filename);
    }

    free(self);
}

/// @file libloki-socket-server.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
