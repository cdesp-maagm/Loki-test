/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiKalman Filtre de Kalman
 *
 * Estimation des paramètres d'une ellipse par filtrage de Kalman.
 * Ce module implémente l'interface @ref gLokiEllipseEstimator "LokiEllipseEstimator".
 */

/// @{

#ifndef LIBLOKI_KALMAN_H_
#define LIBLOKI_KALMAN_H_

#include "libloki-ellipse-estimator.h"

/// Représentation d'un filtre de Kalman.
typedef struct LokiKalman LokiKalman;

/** Construire un nouveau filtre de Kalman.
 *
 * @param initial_radius Le rayon initial de l'ellipse estimée.
 * @param params Les puissances de bruit Rv et Rw, et la valeur initiale à affecter dans la matrice P.
 * @return Un nouveau filtre de Kalman.
 */
LokiKalman *LokiKalman_new(float initial_radius, const float params[static 3]);

/** Construire un clone d'un filtre de Kalman.
 *
 * @param other Le filtre de Kalman à cloner.
 * @return Un nouveau filtre de Kalman.
 */
LokiKalman *LokiKalman_clone(const LokiKalman *other);

/** Mettre à jour les paramètres de l'ellipse pour une nouvelle paire de coordonnées.
 *
 * Cette fonction met à jour l'état interne du filtre et les paramètres de
 * l'ellipse de destination.
 *
 * @param self Le filtre de Kalman à exécuter.
 * @param x La coordonnée X du point courant.
 * @param y La coordonnée Y du point courant.
 */
void LokiKalman_work(LokiKalman *self, float x, float y);

/** Retourner l'état courant du filtre.
 *
 * @param self Un filtre de Kalman.
 * @return Le vecteur d'état du filtre.
 */
float *LokiKalman_get_state(LokiKalman *self);

/** Détruire un filtre de Kalman.
 *
 * @param self Le filtre à détruire.
 */
void LokiKalman_del(LokiKalman *self);

LokiClass_declare_implementation(LokiEllipseEstimator, LokiKalman);

#endif

/// @file libloki-kalman.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
