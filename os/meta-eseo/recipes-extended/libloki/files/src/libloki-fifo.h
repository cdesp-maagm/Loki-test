
/// @defgroup ggLokiInterconnect Échange de données entre modules d'acquisition, de traitement et d'enregistrement
/// @{

/**
 * @defgroup gLokiFIFO Structure de données FIFO
 *
 * File d'attente multi-consommateur pour communication entre threads.
 */

/// @{

#ifndef LIBLOKI_FIFO_H
#define LIBLOKI_FIFO_H

#include <stddef.h>
#include <stdbool.h>

/// Représentation d'une FIFO.
typedef struct LokiFIFO LokiFIFO;

/** Créer une FIFO.
 *
 * Cette fonction alloue l'espace nécessaire pour enregistrer
 * des buffers de données.
 *
 * @param item_size La taille d'un élément, en octets.
 * @param length Le nombre d'éléments.
 * @param consumers Le nombre de consommateurs.
 * @return Une nouvelle FIFO.
 */
LokiFIFO *LokiFIFO_new(size_t item_size, size_t length, size_t consumers);

/** Détruire une FIFO.
 *
 * @param self La FIFO à détruire.
 */
void LokiFIFO_del(LokiFIFO *self);

/** Obtenir la taille d'un élément de la FIFO, en octets.
 *
 * @param self La FIFO à interroger.
 * @return La taille d'un élément, en octets.
 */
size_t LokiFIFO_get_item_size(const LokiFIFO *self);

/** Obtenir une référence vers l'élément courant en écriture.
 *
 * Cette fonction retourne un pointeur sur un élément
 * disponible en écriture dans la FIFO.
 * Le producteur peut modifier cet élément et appeler LokiFIFO_push
 * pour valider les modifications.
 *
 * Cette fonction bloque le producteur tant que la FIFO est pleine.
 *
 * @param self La FIFO à interroger.
 * @return Une référence vers un élément disponible en écriture.
 */
void *LokiFIFO_get_producer_item(LokiFIFO *self);

/** Valider l'élément courant en écriture.
 *
 * Avant d'appeler cette fonction, le producteur doit obtenir une référence
 * vers l'élément à écrire en appelant LokiFIFO_get_producer_item.
 * Cette fonction incrémente le niveau courant de la FIFO.
 *
 * @param self La FIFO à modifier.
 */
void LokiFIFO_push(LokiFIFO *self);

/** Obtenir une référence vers l'élément courant en lecture.
 *
 * Cette fonction retourne un pointeur sur un élément
 * disponible en lecture dans la FIFO.
 * Le consommateur peut traiter cet élément et appeler LokiFIFO_pull
 * lorsque le traitement est terminé.
 *
 * Cette fonction bloque le producteur tant que la FIFO est vide.
 *
 * @param self La FIFO à interroger.
 * @param cid L'identifiant du consommateur courant.
 * @return Une référence vers un élément disponible en lecture.
 */
void *LokiFIFO_get_consumer_item(LokiFIFO *self, size_t cid);

/** Libérer l'élément courant en lecture.
 *
 * Avant d'appeler cette fonction, le producteur doit obtenir une référence
 * vers l'élément à lire en appelant LokiFIFO_get_consumer_item.
 * Cette fonction décrémente le niveau courant de la FIFO.
 *
 * Cette fonction bloque le consommateur jusqu'à ce que l'élément courant ait
 * été consommé par tous les consommateurs.
 *
 * @param self La FIFO à modifier.
 * @param cid L'identifiant du consommateur courant.
 */
void LokiFIFO_pull(LokiFIFO *self, size_t cid);

/** Terminer les attentes en cours.
 *
 * @param self La FIFO à interrompre.
 */
void LokiFIFO_abort(LokiFIFO *self);

#endif

/// @}
/// @}

/// @ingroup gLokiFIFO
/// @file libloki-fifo.h
/// @author Guillaume Savaton
/// @copyright ESEO
