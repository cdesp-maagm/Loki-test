
#include "libloki-fifo.h"

#include <stdlib.h>
#include <pthread.h>

/// @addtogroup gLokiFIFO
/// @{

/// Représentation d'un enregistrement dans une FIFO.
typedef struct LokiFIFORecord LokiFIFORecord;

/** Représentation d'une FIFO.
 *
 * Le contenu de la FIFO est construit comme une liste cirulaire dont les
 * maillons sont de type LokiFIFORecord.
 * Cette liste circulaire n'est pas représentée explicitement dans la structure
 * LokiFIFO. Elle est allouée à la suite du tableau `consumer_records`.
 */
struct LokiFIFO {
    /// La taille d'un élément, en octets.
    size_t item_size;
    /// Le masque binaire indiquant que tous les consommateurs ont lu le dernier élément.
    int all_read;
    /// Faut-il interrompre l'opération en cours.
    volatile bool abort;
    /// Un mutex pour protéger les accès concurrents à la FIFO.
    pthread_mutex_t mutex;
    /// Variable conditionnelle indiquant qu'un élément vient d'être ajouté à la FIFO.
    pthread_cond_t pushed;
    /// Variable conditionnelle indiquant qu'un élément vient d'être retiré de la FIFO.
    pthread_cond_t pulled;
    /// Un pointeur vers le record courant en écriture.
    LokiFIFORecord *producer_record;
    /** Pointeurs vers les records courants en lecture pour chaque consommateur.
     *
     * Ce tableau est alloué dans #LokiFIFO_new selon le nombre de consommateurs.
     */
    LokiFIFORecord *consumer_records[0];
    // Ne rien ajouter ici.
};

/** Représentation d'un enregistrement dans une FIFO.
 *
 * Un enregistrement constitue un maillon dans une liste chaînée circulaire.
 */
struct LokiFIFORecord {
    /// Le masque indiquant l'état de lecture de cet enregistrement par les consommateurs de la FIFO.
    volatile int status;
    /// Un pointeur vers le prochain enregistrement dans la FIFO.
    LokiFIFORecord *next;
    /** Les données logées dans cet enregistrement.
     *
     * La taille effective de ce tableau dépend du champ `item_size` de la FIFO.
     */
    char item[0];
    // Ne rien ajouter ici.
};

LokiFIFO *LokiFIFO_new(size_t item_size, size_t length, size_t consumers) {
    size_t record_size = sizeof(LokiFIFORecord) + item_size;
    LokiFIFO *self = calloc(1, sizeof(LokiFIFO) + length * record_size + consumers * sizeof(LokiFIFORecord*));
    if (!self) {
        return NULL;
    }

    LokiFIFORecord *first_record = (LokiFIFORecord*)(self->consumer_records + consumers);

    self->abort           = false;
    self->item_size       = item_size;
    self->all_read        = (1 << consumers) - 1;
    self->producer_record = first_record;
    for (size_t c = 0; c < consumers; c ++) {
        self->consumer_records[c] = first_record;
    }

    // Initialiser les records comme une liste chaînée circulaire.
    // Marquer tous les éléments comme lus par tous les consommateurs.
    LokiFIFORecord *rec = first_record;
    for (size_t i = 0; i < length; i ++) {
        rec->status = self->all_read;
        rec->next   = i == length - 1 ?
                        first_record :
                        (LokiFIFORecord*)((char*)rec + record_size);
        rec = rec->next;
    }

    pthread_mutex_init(&self->mutex, NULL);
    pthread_cond_init(&self->pushed, NULL);
    pthread_cond_init(&self->pulled, NULL);

    return self;
}

void LokiFIFO_del(LokiFIFO *self) {
    if (!self) {
        return;
    }
    free(self);
}

size_t LokiFIFO_get_item_size(const LokiFIFO *self) {
    return self->item_size;
}

void *LokiFIFO_get_producer_item(LokiFIFO *self) {
    pthread_mutex_lock(&self->mutex);

    // Bloquer tant que l'élément courant n'a pas été lu par tous les consommateurs.
    LokiFIFORecord *rec = self->producer_record;
    while (!self->abort && rec->status != self->all_read) {
        pthread_cond_wait(&self->pulled, &self->mutex);
    }

    // Retourner NULL en cas d'annulation.
    void *item = self->abort ? NULL : rec->item;

    pthread_mutex_unlock(&self->mutex);

    return item;
}

void LokiFIFO_push(LokiFIFO *self) {
    if (self->abort) {
        return;
    }

    pthread_mutex_lock(&self->mutex);

    // Marquer l'élément courant comme non lu.
    self->producer_record->status = 0;

    // Signaler la présence d'un nouvel élément à tous les consommateurs en attente.
    pthread_cond_broadcast(&self->pushed);

    // Passer à l'élément suivant.
    self->producer_record = self->producer_record->next;

    pthread_mutex_unlock(&self->mutex);
}

void *LokiFIFO_get_consumer_item(LokiFIFO *self, size_t cid) {
    pthread_mutex_lock(&self->mutex);

    // Bloquer tant que l'élément courant est marqué comme lu par ce consommateur.
    int mask = 1 << cid;
    LokiFIFORecord *rec = self->consumer_records[cid];
    while (!self->abort && (rec->status & mask)) {
        pthread_cond_wait(&self->pushed, &self->mutex);
    }

    // Retourner NULL en cas d'annulation.
    void *item = self->abort ? NULL : rec->item;

    pthread_mutex_unlock(&self->mutex);

    return item;
}

void LokiFIFO_pull(LokiFIFO *self, size_t cid) {
    if (self->abort) {
        return;
    }

    pthread_mutex_lock(&self->mutex);

    // Marquer l'élément courant comme lu par ce consommateur.
    LokiFIFORecord *rec = self->consumer_records[cid];
    rec->status |= 1 << cid;

    // Signaler qu'une lecture vient d'avoir lieu.
    pthread_cond_signal(&self->pulled);

    // Passer à l'élément suivant.
    self->consumer_records[cid] = rec->next;

    pthread_mutex_unlock(&self->mutex);
}

void LokiFIFO_abort(LokiFIFO *self) {
    pthread_mutex_lock(&self->mutex);
    self->abort = true;
    pthread_cond_signal(&self->pulled);
    pthread_cond_broadcast(&self->pushed);
    pthread_mutex_unlock(&self->mutex);
}

/// @file libloki-fifo.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
