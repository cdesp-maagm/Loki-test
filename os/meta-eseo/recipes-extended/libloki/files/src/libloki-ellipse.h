/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiEllipse Représentation et manipulation d'ellipses
 *
 * Type de donnée et fonctions permettant de manipuler
 * des ellipses sous différentes représentations.
 */

/// @{

#ifndef LIBLOKI_ELLIPSE_H_
#define LIBLOKI_ELLIPSE_H_

/// Structure de données représentant une ellipse.
typedef struct {
    /// Le demi-grand axe de l'ellipse.
    float A;
    /// Le demi-petit axe de l'ellipse.
    float B;
    /// La coordonnée X du centre de l'ellipse.
    float xc;
    /// La coordonnée Y du centre de l'ellipse.
    float yc;
    /// L'angle entre le grand axe et l'axe horizontal.
    float alpha;
} LokiEllipse;

/// Tableau des coefficients de l'équation d'une ellipse en coordonnées cartésiennes.
typedef float LokiEllipseEquation[5];

/** Affecter les paramètres d'une ellipse en fonction des coefficients de son équation.
 *
 * L'équation de l'ellipse est considérée comme normalisée avec $a + c = 1$.
 *
 * @param self L'ellipse à calculer.
 * @param coeffs Les coefficients (a, b, d, e, f) de l'équation.
 */
void LokiEllipse_set_from_coeffs(LokiEllipse *self, const LokiEllipseEquation coeffs);

/** Calculer les coefficients de l'équation d'une ellipse.
 *
 * Les coefficients sont normalisés de telle sorte que $a + c = 1$.
 * Le résultat ne contient que les coefficients (a, b, d, e, f).
 *
 * @param self L'ellipse de référence.
 * @param coeffs Le tableau de destination.
 */
void LokiEllipse_get_coeffs(const LokiEllipse *self, LokiEllipseEquation coeffs);

/** Calculer les coordonnées d'un point d'une ellipse.
 *
 * @param self L'ellipse de référence.
 * @param theta La coordonnée du point sur l'ellipse, en radians.
 * @param x Un pointeur vers la coordonnée X calculée pour ce point.
 * @param y Un pointeur vers la coordonnée Y calculée pour ce point.
 */
void LokiEllipse_get_point(const LokiEllipse *self, float theta, float *x, float *y);

/** Calculer l'angle correspondant à un point d'une ellipse.
 *
 * Cette fonction calcule également les coordonées d'un point du cercle unité
 * correspondant au point de l'ellipse passé en argument.
 *
 * @param self L'ellipse de référence.
 * @param x La coordonnée X d'un point de l'ellipse.
 * @param y La coordonnée Y d'un point de l'ellipse.
 * @param x_norm Un pointeur vers l'emplacement où écrire la coordonnée X du point ramené sur le cercle unité.
 * @param y_norm Un pointeur vers l'emplacement où écrire la coordonnée Y du point ramené sur le cercle unité.
 * @return L'angle.
 */
float LokiEllipse_get_angle(const LokiEllipse *self, float x, float y, float *x_norm, float *y_norm);

#endif

/// @file libloki-ellipse.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
