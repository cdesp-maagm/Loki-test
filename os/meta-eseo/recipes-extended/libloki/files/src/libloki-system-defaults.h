/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiDefaults Valeurs par défaut des paramètres de calcul de déplacement
 *
 * Constantes utilisées pour la configuration d'un @ref gLokiSystem "LokiSystem".
 */

/// @{

#ifndef LIBLOKI_SYSTEM_DEFAULTS_H_
#define LIBLOKI_SYSTEM_DEFAULTS_H_

#include "libloki.h"
#include <math.h>

/// Ne pas activer le mode de simulation logicielle des capteurs.
#define LOKI_SYSTEM_DEFAULT_SIMULATE                 false

/// Remplir la FIFO des déplacements immédiatement après la réception des premiers échantillons démodulés.
#define LOKI_SYSTEM_DEFAULT_SKIP                     0

/// La longueur d'onde par défaut, 1310 nm.
#define LOKI_SYSTEM_DEFAULT_WAVELENGTH               1310

/// Supposer qu'il n'y a qu'une seule réflexion.
#define LOKI_SYSTEM_DEFAULT_REFLECTIONS              1

/// Supposer un indice de cavité de Fabry-Pérot égal à 1.
#define LOKI_SYSTEM_DEFAULT_CAVITY_INDEX             1.0f

/// Calculer les déplacements en picomètres.
#define LOKI_SYSTEM_DEFAULT_DISTANCE_UNIT            'p';

/// L'implémentation du filtre RLS.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_IMPL_RLS       LokiRLSClass

/// Les paramètres par défaut du filtre RLS.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_PARAMS_RLS     {0.999f, 0.1f}

/// L'implémentation du filtre de Kalman.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_IMPL_KALMAN    LokiKalmanClass

/// Les paramètres par défaut du filtre de Kalman.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_PARAMS_KALMAN  {0.999f, 0.0f, 0.1f}

/// Utiliser un filtre de Kalman.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_IMPL           LOKI_SYSTEM_DEFAULT_ESTIMATOR_IMPL_KALMAN

/// Utiliser les paramètres par défaut du filtre de Kalman.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_PARAMS         LOKI_SYSTEM_DEFAULT_ESTIMATOR_PARAMS_KALMAN

/// La périodicité par défaut du calcul des paramètres de l'ellipse.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_THROTTLE       1

/// Le rayon initial par défaut des ellipses estimées.
#define LOKI_SYSTEM_DEFAULT_ESTIMATOR_INITIAL_RADIUS 1e-3

/// La bande passante par défaut du filtre de suppression du déplacement fictif.
#define LOKI_SYSTEM_DEFAULT_FILTER_BANDWIDTH         250.0f

/// L'atténuation par défaut du filtre de suppression du déplacement fictif.
#define LOKI_SYSTEM_DEFAULT_FILTER_ATTENUATION       60.0f

/// Le nombre de coefficients par défaut du filtre de suppression du déplacement fictif.
#define LOKI_SYSTEM_DEFAULT_FILTER_LENGTH            1000

/// La facteur de décimation par défaut du filtre de suppression du déplacement fictif.
#define LOKI_SYSTEM_DEFAULT_FILTER_DECIMATION        50

/// La constante de temps par défaut des filtres de lissage des paramètres de l'ellipse.
#define LOKI_SYSTEM_DEFAULT_IIR_TAU                  1.0f

#endif

/// @file libloki-system-defaults.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
