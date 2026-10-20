/**
 * @ingroup ggLokiInterconnect
 * @defgroup gLokiTime Types et fonctions de gestion du temps
 *
 * Définition de types *timestamp* et intervalle de temps, et de fonctions de conversion d'unités de temps.
 */

/// @{

#ifndef LIBLOKI_TIME_H_
#define LIBLOKI_TIME_H_

#include <inttypes.h>
#include <time.h>

/// Représentation d'une date, en nanosecondes par rapport à une date de référence.
typedef uint64_t LokiTimestamp;

/// Représentation d'un intervalle de temps, en nanosecondes.
typedef int64_t  LokiTimeDelta;

/// Le nombre d'unités du type LokiTimestamp dans une seconde.
#define TIMESTAMP_SEC 1000000000

/// Le nombre d'unités du type LokiTimestamp dans une milliseconde.
#define TIMESTAMP_MS  1000000

/** Convertir une date en timestamp.
 *
 * @param ts La date à convertir.
 * @return Le timestamp correspondant.
 */
static inline LokiTimestamp LokiTime_to_timestamp(struct timespec ts) {
    return (LokiTimestamp)ts.tv_sec * TIMESTAMP_SEC + (LokiTimestamp)ts.tv_nsec;
}

/** Calculer le nombre total de secondes dans un timestamp.
 *
 * @param timestamp Le timestamp à convertir.
 * @return Le nombre de secondes, arrondi à l'entier inférieur.
 */
static inline time_t LokiTime_seconds(LokiTimestamp timestamp) {
    return timestamp / TIMESTAMP_SEC;
}

/** Calculer le nombre de millisecondes depuis la dernière seconde dans un timestamp.
 *
 * @param timestamp Le timestamp à convertir.
 * @return Le nombre de millisecondes, arrondi à l'entier inférieur.
 */
static inline time_t LokiTime_milliseconds(LokiTimestamp timestamp) {
    return (timestamp / TIMESTAMP_MS) % 1000;
}

/** Calculer le timestamp d'un échantillon dans un signal.
 *
 * @param ref Le timestamp de l'échantillon d'indice 0.
 * @param index L'indice de l'échantillon courant.
 * @param frequency La fréquence d'échantillonnage, en Hz.
 * @return Le timestamp de l'échantillon courant.
 */
static inline LokiTimestamp LokiTime_update(LokiTimestamp ref, size_t index, float frequency) {
    return ref + (LokiTimestamp)TIMESTAMP_SEC * index / frequency;
}

#endif

/// @file libloki-time.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
