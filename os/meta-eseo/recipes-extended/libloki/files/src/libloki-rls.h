/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiRLS Filtre RLS
 *
 * Estimation des paramètres d'une ellipse par filtrage *Recursive Least Squares*.
 * Ce module implémente l'interface @ref gLokiEllipseEstimator "LokiEllipseEstimator".
 */

/// @{

#ifndef LIBLOKI_RLS_H_
#define LIBLOKI_RLS_H_

#include "libloki-ellipse-estimator.h"

/// Représentation d'un filtre RLS.
typedef struct LokiRLS LokiRLS;

/** Construire un nouveau filtre RLS.
 *
 * @param initial_radius Le rayon initial de l'ellipse estimée.
 * @param params Le facteur d'oubli du filtre et la valeur initiale à affecter dans la matrice P.
 * @return Un nouveau filtre RLS.
 */
LokiRLS *LokiRLS_new(float initial_radius, const float params[static 2]);

/** Construire un clone d'un filtre RLS.
 *
 * @param other Le filtre RLS à cloner.
 * @return Un nouveau filtre RLS.
 */
LokiRLS *LokiRLS_clone(const LokiRLS *other);

/** Mettre à jour les paramètres de l'ellipse pour une nouvelle paire de coordonnées.
 *
 * Cette fonction met à jour l'état interne du filtre et les paramètre de
 * l'ellipse de destination.
 *
 * @param self Le filtre RLS à exécuter.
 * @param x La coordonnée X du point courant.
 * @param y La coordonnée Y du point courant.
 */
void LokiRLS_work(LokiRLS *self, float x, float y);

/** Retourner l'état courant du filtre.
 *
 * @param self Un filtre RLS.
 * @return Le vecteur d'état du filtre.
 */
float *LokiRLS_get_state(LokiRLS *self);

/** Détruire un filtre RLS.
 *
 * @param self Le filtre à détruire.
 */
void LokiRLS_del(LokiRLS *self);

LokiClass_declare_implementation(LokiEllipseEstimator, LokiRLS);

#endif

/// @file libloki-rls.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
