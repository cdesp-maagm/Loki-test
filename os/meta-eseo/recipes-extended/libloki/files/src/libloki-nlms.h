/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiNLMS Filtre NLMS
 *
 * Estimation des paramètres d'une ellipse par filtrage *Normalized Least Mean Squares*.
 * Ce module implémente l'interface @ref gLokiEllipseEstimator "LokiEllipseEstimator".
 */

/// @{

#ifndef LIBLOKI_NLMS_H_
#define LIBLOKI_NLMS_H_

#include "libloki-ellipse-estimator.h"

/// Représentattion d'un filtre NLMS.
typedef struct LokiNLMS LokiNLMS;

/** Construire un nouveau filtre NLMS.
 *
 * @param initial_radius Le rayon initial de l'ellipse estimée.
 * @param params Le facteur d'apprentissage du filtre LMS et le coefficients du filtre de mise à jour des facteur de normalisation.
 * @return Un nouveau filtre NLMS.
 */
LokiNLMS *LokiNLMS_new(float initial_radius, const float params[static 2]);

/** Construire un clone d'un filtre NLMS.
 *
 * @param other Le filtre NLMS à cloner.
 * @return Un nouveau filtre NLMS.
 */
LokiNLMS *LokiNLMS_clone(const LokiNLMS *other);

/** Mettre à jour les paramètres de l'ellipse pour une nouvelle paire de coordonnées.
 *
 * Cette fonction met à jour l'état interne du filtre et les paramètre de
 * l'ellipse de destination.
 *
 * @param self Le filtre NLMS à exécuter.
 * @param x La coordonnée X du point courant.
 * @param y La coordonnée Y du point courant.
 */
void LokiNLMS_work(LokiNLMS *self, float x, float y);

/** Retourner l'état courant du filtre.
 *
 * @param self Un filtre NLMS.
 * @return Le vecteur d'état du filtre.
 */
float *LokiNLMS_get_state(LokiNLMS *self);

/** Détruire un filtre NLMS.
 *
 * @param self Le filtre à détruire.
 */
void LokiNLMS_del(LokiNLMS *self);

LokiClass_declare_implementation(LokiEllipseEstimator, LokiNLMS);

#endif

/// @file libloki-nlms.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
