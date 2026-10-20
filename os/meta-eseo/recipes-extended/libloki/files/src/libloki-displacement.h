/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiDisplacement Calcul de déplacement
 *
 * Un calculateur de déplacement est composé d'un @ref gLokiEllipseEstimator
 * "filtre adaptatif d'estimation des paramètres d'une ellipse" et d'un
 * @ref gLokiFIRFilter "filtre passe-bas" pour éliminer le déplacement fictif.
 */

/// @{

#ifndef LIBLOKI_DISPLACEMENT_H_
#define LIBLOKI_DISPLACEMENT_H_

#include "libloki-fir.h"
#include "libloki-ellipse-estimator.h"

/// Représentation d'un calculateur de déplacement.
typedef struct LokiDisplacement LokiDisplacement;

/** Construire un calculateur de déplacement.
 *
 * Le facteur d'échelle détermine l'unité de distance utilisée en sortie
 * de #LokiDisplacement_work.
 * On choisira typiquement scale = λ0 / 2πN
 * où λ0 est la longueur d'onde du laser, dans l'unité de mesure de distance
 * souhaitée, et N est le nombre de réflexions.
 *
 * @param estimator Un filtre adaptatif d'estimation d'ellipse.
 * @param filter Un filtre passe-bas pour éliminer le déplacement fictif.
 * @param throttle La périodicité de mise à jour des paramètres de l'ellipse.
 * @param scale Un facteur d'échelle pour la valeur des déplacements calculés.
 * @param tau Les constantes de temps du filtrage des paramètres de l'ellipse, en secondes (0 : axes; 1 : centre; 2 : angle).
 * @param sampling_frequency La fréquence d'échantillonnage, en Hz
 * @return Une instance de LokiDisplacement.
 */
LokiDisplacement *LokiDisplacement_new(LokiEllipseEstimator *estimator, LokiFIRFilter *filter, unsigned throttle, float scale, float tau[static 3], float sampling_frequency);

/** Cloner une instance de LokiDisplacement
 *
 * @param other Une instance de LokiDisplacement à cloner.
 * @return Une copie de other.
 */
LokiDisplacement *LokiDisplacement_clone(const LokiDisplacement *other);

/** Calculer le déplacement courant.
 *
 * Pour un déplacement d et une longueur d'onde λ0, en mètres,
 * cette fonction retourne : scale * 4π / λ0 * d
 *
 * @param self Une instance de LokiDisplacement.
 * @param x La coordonnée X du point courant de l'ellipse.
 * @param y La coordonnée Y du point courant de l'ellipse.
 * @param x_norm La coordonnée X du point courant de l'ellipse, ramené sur le cercle unité.
 * @param y_norm La coordonnée Y du point courant de l'ellipse, ramené sur le cercle unité.
 * @param out Le déplacement calculé.
 * @return true à chaque période de décimation.
 */
bool LokiDisplacement_work(LokiDisplacement *self, float x, float y, float *x_norm, float *y_norm, float *out);

/** Remettre à zéro le déplacement.
 *
 * @param self Une instance de LokiDisplacement.
 */
void LokiDisplacement_reset(LokiDisplacement *self);

/** Retourner la dernière ellipse calculée par cette instance.
 *
 * @param self Une instance de LokiDisplacement.
 * @return un pointeur vers une ellipse.
 */
LokiEllipse *LokiDisplacement_get_ellipse(LokiDisplacement *self);

/** Détruire une instance de LokiDisplacement.
 *
 * @param self L'instance de LokiDisplacement à détruire.
 */
void LokiDisplacement_del(LokiDisplacement *self);

#endif

/// @file libloki-displacement.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
