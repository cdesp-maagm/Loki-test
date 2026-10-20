/**
 * @ingroup ggLokiCommon
 * @defgroup gLokiNeon Support des fonctions intrinsics ARM NEON
 *
 * Sur les architectures ARM qui supportent les instructions SIMD NEON,
 * ce fichier inclut directement l'en-tête `arm_neon.h` officiel.
 *
 * Pour les autres architectures, ce fichier fournit des implémentations en C
 * standard de quelques fonctions intrinsics pour les types flottants 32 bits.
 * Cela permet, par exemple, de tester sur PC une fonction destinée à un
 * processeur ARM.
 */

/// @{

#ifndef LIBLOKI_NEON_H_
#define LIBLOKI_NEON_H_

#ifdef __ARM_NEON

#include <arm_neon.h>

#else

/// Vecteur de deux nombres flottants 32 bits.
typedef struct {
    /// Les éléments de ce vecteur.
    float val[2];
} float32x2_t;

/// Vecteur de quatre nombres flottants 32 bits.
typedef union {
    /// Les éléments de ce vecteur.
    float val[4];
    /// Décomposition d'un vecteur en deux moitiés.
    struct {
        /// Un vecteur contenant les deux premiers éléments de ce vecteur.
        float32x2_t low;
        /// Un vecteur contenant les deux derniers éléments de ce vecteur.
        float32x2_t high;
    };
} float32x4_t;

/** Additionner deux vecteurs.
 *
 * @param a Le premier opérande.
 * @param b Le second opérande.
 * @return Un vecteur obtenu en additionnant `a` et `b` terme à terme.
 */
static inline float32x2_t vadd_f32(float32x2_t a, float32x2_t b) {
    a.val[0] += b.val[0];
    a.val[1] += b.val[1];
    return a;
}

/** Lire un élément d'un vecteur.
 *
 * @param a Le vecteur à inspecter.
 * @param i L'indice de l'élément à lire.
 * @return L'élément d'indice `i` dans `a`.
 */
static inline float vget_lane_f32(float32x2_t a, size_t i) {
    return a.val[i];
}

/** Construire un vecteur.
 *
 * @param a La valeur des éléments.
 * @return Un vecteur dont tous les éléments sont égaux à `a`.
 */
static inline float32x4_t vmovq_n_f32(float a) {
    return (float32x4_t) {
        .val = {a, a, a, a}
    };
}

/** Lire un vecteur en mémoire.
 *
 * @param a Un pointeur vers la région à lire.
 * @return Un vecteur des éléments pointés par `a`.
 */
static inline float32x4_t vld1q_f32(const float *a) {
    return *(float32x4_t*)a;
}

/** Lire la première moitié d'un vecteur.
 *
 * @param a Le vecteur à décomposer.
 * @return Un vecteur contenant la première moitié de `a`.
 */
static inline float32x2_t vget_low_f32(float32x4_t a) {
    return a.low;
}

/** Lire la seconde moitié d'un vecteur.
 *
 * @param a Le vecteur à décomposer.
 * @return Un vecteur contenant la seconde moitié de `a`.
 */
static inline float32x2_t vget_high_f32(float32x4_t a) {
    return a.high;
}

/** Remplacer un élément d'un vecteur avec une valeur lue en mémoire.
 *
 * @param a Un pointeur vers la valeur à lire.
 * @param b Le vecteur à modifier.
 * @param i L'indice de l'élément à remplacer.
 * @return Une copie de `b` dont un élément a été modifié.
 */
static inline float32x4_t vld1q_lane_f32(const float *a, float32x4_t b, size_t i) {
    b.val[i] = *a;
    return b;
}

/** Multiplier deux vecteurs terme à terme.
 *
 * @param a Le premier opérande.
 * @param b Le second opérande.
 * @return Un vecteur obtenu en calculant le produit de `a` et `b` terme à terme.
 */
static inline float32x4_t vmulq_f32(float32x4_t a, float32x4_t b) {
    for (size_t i = 0; i < 4; i ++) {
        a.val[i] *= b.val[i];
    }
    return a;
}

/** Calculer le résultat d'une multiplication-accumulation sur des vecteurs.
 *
 * @param a La valeur courante de l'accumulateur.
 * @param b Le premier opérande de la multiplication.
 * @param c Le second opérande de la multiplication.
 * @return La nouvelle valeur de l'accumulateur.
 */
static inline float32x4_t vmlaq_f32(float32x4_t a, float32x4_t b, float32x4_t c) {
    for (size_t i = 0; i < 4; i ++) {
        a.val[i] += b.val[i] * c.val[i];
    }
    return a;
}

#endif

#endif

/// @file libloki-neon.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
