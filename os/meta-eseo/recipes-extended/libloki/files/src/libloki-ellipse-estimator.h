/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiEllipseEstimator Interface d'un filtre adaptatif pour estimer les paramètres d'une ellipse
 *
 * Définition des méthodes communes pour estimer les paramètres d'une ellipse au
 * cours de la réception d'une série de points.
 */

/// @{

#ifndef LIBLOKI_ELLIPSE_ESTIMATOR_H_
#define LIBLOKI_ELLIPSE_ESTIMATOR_H_

#include "libloki-class.h"

#include <stddef.h>

/// Représentation d'un filtre d'estimation des paramètres d'une ellipse.
typedef struct LokiEllipseEstimator LokiEllipseEstimator;

/** Construire un estimateur.
 *
 * @param initial_radius Le rayon initial de l'ellipse estimée.
 * @param params Les paramètres de cet estimateur (selon l'implémentation).
 * @return Un nouvel estimateur.
 */
LokiEllipseEstimator *LokiEllipseEstimator_new(float initial_radius, const float params[]);

/** Construire un clone d'un estimateur.
 *
 * Le nouvel estimateur aura la même implémentation et les mêmes paramètres
 * que l'original.
 *
 * @param other L'estimateur à cloner.
 * @return Un nouvel estimateur.
 */
LokiEllipseEstimator *LokiEllipseEstimator_clone(const LokiEllipseEstimator *other);

/** Mettre à jour les paramètres de l'ellipse pour une nouvelle paire de coordonnées.
 *
 * Cette fonction met à jour l'état interne du filtre et les paramètres de
 * l'ellipse de destination.
 *
 * @param self L'estimateur à exécuter.
 * @param x La coordonnée X du point courant.
 * @param y La coordonnée Y du point courant.
 */
void LokiEllipseEstimator_work(LokiEllipseEstimator *self, float x, float y);

/** Retourner l'état courant de l'estimateur.
 *
 * @param self Un estimateur.
 * @return Le vecteur d'état de cet estimateur.
 */
float *LokiEllipseEstimator_get_state(LokiEllipseEstimator *self);

/** Détruire un estimateur.
 *
 * @param self L'estimateur à détruire.
 */
void LokiEllipseEstimator_del(LokiEllipseEstimator *self);

LokiClass_interface(LokiEllipseEstimator,
    LokiClass_attribute(size_t params_length)
    LokiClass_method(LokiEllipseEstimator, new)
    LokiClass_method(LokiEllipseEstimator, clone)
    LokiClass_method(LokiEllipseEstimator, work)
    LokiClass_method(LokiEllipseEstimator, get_state)
    LokiClass_method(LokiEllipseEstimator, del)
);

/** Construire un estimateur avec une implémentation donnée.
 *
 * @param impl L'implémentation de LokiEllipseEstimator à utiliser.
 * @param initial_radius Le rayon initial de l'ellipse estimée.
 * @param params Les paramètres de cet estimateur (selon l'implémentation).
 * @return Un nouvel estimateur.
 */
LokiEllipseEstimator *LokiEllipseEstimator_new_with_implementation(const LokiEllipseEstimatorInterface *impl, float initial_radius, const float params[]);

#endif

/// @file libloki-ellipse-estimator.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
