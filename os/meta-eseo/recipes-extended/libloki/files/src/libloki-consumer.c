
/// Permettre l'utilisation de la fonction `pthread_setname_np` pour modifier le nom d'un thread.
#define _GNU_SOURCE

#include "libloki.h"

#include <math.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <signal.h>
#include <inttypes.h>

/// @addtogroup gLokiConsumer
/// @{

/// Définition d'un consommateur.
struct LokiConsumer {
    /// La FIFO lue par ce consommateur.
    LokiFIFO *in;
    /// Le numéro de consommateur pour la FIFO.
    size_t cid;
    /// Indicateur de demande d'arrêt.
    volatile bool stop_request;
    /// Le thread démarré par #LokiConsumer_start.
    pthread_t thread;
};

LokiConsumer *LokiConsumer_new(void) {
    LokiConsumer *self = calloc(1, sizeof(LokiConsumer));
    if (!self) {
        return NULL;
    }

    return self;
}

/** Lire les données de la FIFO.
 *
 * Cette fonction est exécutée dans un thread démarré par #LokiConsumer_start.
 * Elle consomme les données de la FIFO jusqu'à la demande d'arrêt par #LokiConsumer_stop.
 *
 * @param ptr Le consommateur courant.
 */
static void *LokiConsumer_work(void *ptr) {
    LokiConsumer *self = ptr;

    pthread_setname_np(self->thread, "Consumer");

    while (!self->stop_request) {
        if (!LokiFIFO_get_consumer_item(self->in, self->cid)) {
            break;
        }
        LokiFIFO_pull(self->in, self->cid);
    }
}

int LokiConsumer_start(LokiConsumer *self, LokiFIFO *in, size_t cid) {
    self->in = in;
    self->cid = cid;
    self->stop_request = false;
    return pthread_create(&self->thread, NULL, LokiConsumer_work, self);
}

void LokiConsumer_stop(LokiConsumer *self) {
    if (self->stop_request) {
        return;
    }
    self->stop_request = true;
    LokiFIFO_abort(self->in);
    pthread_join(self->thread, NULL);
}

void LokiConsumer_del(LokiConsumer *self) {
    if (!self) {
        return;
    }

    free(self);
}

/// @file libloki-consumer.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
