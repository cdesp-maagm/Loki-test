/**
 * @ingroup ggLokiComputation
 * @defgroup gLokiFIRFilter Filtre FIR
 *
 * Implémentation polyphase d'un filtre à réponse impulsionnelle finie.
 */

/// @{

#ifndef LIBLOKI_FIR_H_
#define LIBLOKI_FIR_H_

#include <stdbool.h>
#include <stddef.h>

/// Représentation d'un filtre FIR.
typedef struct LokiFIRFilter LokiFIRFilter;

/** Construire un filtre FIR.
 *
 * Le paramètre `length` indique la longueur souhaitée.
 * Elle peut être augmentée pour que la longueur effective soit multiple
 * du facteur de décimation et de la taille de vecteur utilisée par
 * les instructions SIMD du processeur.
 * Dans ce cas, le tableau de coefficients est complété avec des zéros.
 *
 * @param coeffs Les coefficients du filtre.
 * @param length Le nombre de coefficients.
 * @param decimation Le facteur de décimation.
 * @return Un nouveau filtre FIR.
 */
LokiFIRFilter *LokiFIRFilter_new(const float *coeffs, size_t length, size_t decimation);

/** Construire un clone d'un filtre FIR.
 *
 * Le nouveau filtre possédera les mêmes coefficients et le même facteur de
 * décimation que celui passé en paramètre.
 *
 * @param other Le filtre à cloner.
 * @return Un nouveau filtre FIR.
 */
LokiFIRFilter *LokiFIRFilter_clone(const LokiFIRFilter *other);

/** Construire un filtre FIR en utilisant une fenêtre de Kaiser-Bessel.
 *
 * La méthode de synthèse du filtre est détaillée dans l'article
 * [Window method of FIR filter design](http://www.arc.id.au/FilterDesign.html).
 *
 * Le paramètre `length` indique la longueur souhaitée.
 * Elle peut être augmentée pour satisfaire les contraintes de la méthode de
 * synthèse utilisée, et pour que la longueur effective soit multiple
 * du facteur de décimation et de la taille de vecteur utilisée par
 * les instructions SIMD du processeur.
 * Dans ce cas, le tableau de coefficients est complété avec des zéros.
 *
 * @param fs La fréquence d'échantillonnage.
 * @param fa La fréquence de coupure basse (0 pour un filtre passe-bas).
 * @param fb La fréquence de coupure haute.
 * @param att L'atténuation, en dB.
 * @param length Le nombre de coefficients.
 * @param decimation Le facteur de décimation.
 * @return Un nouveau filtre FIR.
 */
LokiFIRFilter *LokiFIRFilter_new_kaiser_bessel(float fs, float fa, float fb, float att, size_t length, size_t decimation);

/** Exécuter un pas de calcul d'un fitre FIR.
 *
 * Le filtre consomme un échantillon d'entrée, indique si un échantillon de sortie
 * est disponible et le range à l'emplacement indiqué.
 * Si le facteur de décimation de ce filtre est N, il produira un échantillon
 * de sortie tous les N appels.
 *
 * @param self Le filtre à exécuter.
 * @param in L'échantillon d'entrée.
 * @param out Un pointeur vers l'emplacement où ranger l'échantillon de sortie.
 * @return true si l'échantillon de sortie est valide.
 */
bool LokiFIRFilter_work(LokiFIRFilter *self, float in, float *out);

/** Réinitialiser un filtre FIR.
 *
 * Cette fonction remet à zéro l'état du filtre.
 *
 * @param self Le filtre à réinitialiser.
 */
void LokiFIRFilter_reset(LokiFIRFilter *self);

/** Lire la longueur effective d'un filtre FIR.
 *
 * La longueur effective est toujours multiple du facteur de décimation.
 * Elle peut également avoir été ajustée pour satisfaire les contraintes
 * d'une méthode de synthèse de filtre.
 * Pour ces raisons, elle peut différer de la valeur du paramètre `length`
 * fourni à la construction.
 *
 * @param self Le filtre à interroger.
 * @return La longueur du filtre.
 */
size_t LokiFIRFilter_get_actual_length(LokiFIRFilter *self);

/** Détruire un filtre FIR.
 *
 * @param self Le filtre à détruire.
 */
void LokiFIRFilter_del(LokiFIRFilter *self);

#endif

/// @file libloki-fir.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
