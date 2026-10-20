/**
 * @ingroup ggLokiInterconnect
 * @defgroup gLokiPacket Type paquets d'échantillons
 *
 * Type de données pour la communication de paquets d'échantillons datés entre threads.
 */

/// @{

#ifndef LIBLOKI_PACKET_H_
#define LIBLOKI_PACKET_H_

#include <inttypes.h>

/// Structure d'un paquet d'échantillons échangés entre tâches concurrentes.
typedef struct {
    /// La date de réception du paquet, en microsecondes depuis l'epoch Unix.
    LokiTimestamp timestamp;
    /// Les valeurs d'échantillons. La taille et le type de ce tableau son spécifiés ultérieurement.
    char buffer[0];
    // Ne rien ajouter ici
} LokiPacket;

/** Calculer la taille d'un paquet de données.
 *
 * Le résultat inclut la taille des métadonnées contenues dans le paquet.
 *
 * @param packet_length Le nombre d'échantillons contenus dans le paquet.
 * @param sample_size La taille d'un échantillon, en octets.
 */
static inline size_t LokiPacket_get_fifo_item_size(size_t packet_length, size_t sample_size) {
    return packet_length * sample_size + sizeof(LokiPacket);
}

/** Lire la longueur des paquets supportés par une FIFO.
 *
 * @param fifo La FIFO à interroger.
 * @param sample_size La taille d'un échantillon, en octets.
 * @return Le nombre d'échantillons par paquet dans cette FIFO.
 */
static inline size_t LokiPacket_get_length(LokiFIFO *fifo, size_t sample_size) {
    return (LokiFIFO_get_item_size(fifo) - sizeof(LokiPacket)) / sample_size;
}

#endif

/// @file libloki-packet.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
