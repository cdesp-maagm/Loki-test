
#include "libloki-fir.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#ifndef NO_SIMD
#include <libloki-neon.h>
#endif

/// @addtogroup gLokiFIRFilter
/// @{

/// Représentation d'un filtre FIR.
struct LokiFIRFilter {
    /// Ce filtre est-il un clone d'un autre filtre ?
    bool is_clone;
    /// Le tableau des coefficients de ce filtre.
    float *coeffs;
    /// Un pointeur vers la région située après le dernier coefficient de ce filtre.
    float *coeffs_end;
    /// Un pointeur vers le premier coefficient du filtre pour la phase courante.
    float *coeff_ptr;
    /// Le tableau des échantillons d'entrée mémorisés.
    float *samples;
    /// Un pointeur vers la région située après le dernier échantillon mémorisé.
    float *samples_end;
    /// L'indice de l'échantillon courant dans la phase courante.
    size_t sample_index;
    /// Un pointeur vers les échantillons de la phase courante.
    float *phase_ptr;
    /// Le résultat partiel du filtrage.
    float acc;
    /// Le nombre de coefficients de ce filtre.
    size_t length;
    /// Le facteur de décimation de ce filtre.
    size_t decimation;
    /// Le nombre de coefficients par phase.
    size_t phase_length;
};

/** Allouer le tableau des échantillons mémorisés par un filtre FIR.
 *
 * Cette fonction alloue le tableau `samples` du filtre passé en paramètre.
 *
 * @param self Le filtre à allouer.
 */
static inline void LokiFIRFilter_allocate_samples(LokiFIRFilter *self) {
    size_t buffer_length = self->length;
    #ifndef NO_SIMD
        // Si la vectorisation est activée, prévoir 3 échantillons de plus par phase.
        buffer_length += self->decimation * 3;
    #endif
    self->samples     = self->phase_ptr = calloc(buffer_length, sizeof(float));
    self->samples_end = self->samples + buffer_length;
}

LokiFIRFilter *LokiFIRFilter_new(const float *coeffs, size_t length, size_t decimation) {
    LokiFIRFilter * self = calloc(1, sizeof(LokiFIRFilter));
    if (!self) {
        return NULL;
    }

    // Ajuster la longueur du filtre pour qu'elle soit multiple de decimation.
    self->phase_length = length / decimation;
    if (length % decimation) {
        self->phase_length ++;
    }
    #ifndef NO_SIMD
        // Si la vectorisation est activée, la longueur de chaque sous-filtre sera
        // ajustée au multiple de 4 immédiatement supérieur.
        if (self->phase_length % 4) {
            self->phase_length += 4 - self->phase_length % 4;
        }
    #endif

    self->length     = self->phase_length * decimation;
    self->decimation = decimation;

    if (length != self->length) {
        fprintf(stderr, "LokiFIRFilter_new: Filter length was expanded from %zu to %zu\n", length, self->length);
    }

    // Allouer les tableaux des coefficients et des échantillons précédents.
    self->coeffs      = self->coeff_ptr = calloc(self->length, sizeof(float));
    self->coeffs_end  = self->coeffs  + self->length;
    LokiFIRFilter_allocate_samples(self);
    if (!self->coeffs || !self->samples) {
        LokiFIRFilter_del(self);
        return NULL;
    }

    // Ranger les coefficients en les répartissant par phase
    // et en renversant l'ordre des coefficients.
    for (size_t i = 0; i < length; i ++) {
        size_t p = i % decimation;       // Numéro de phase (< decimation)
        size_t q = (i - p) / decimation; // Indice dans la phase (< n)
        self->coeffs[p * self->phase_length + q] = coeffs[length - i - 1];
    }

    return self;
}

LokiFIRFilter *LokiFIRFilter_clone(const LokiFIRFilter *other) {
    LokiFIRFilter * self = calloc(1, sizeof(LokiFIRFilter));
    if (!self) {
        return NULL;
    }

    memcpy(self, other, sizeof(LokiFIRFilter));

    self->is_clone = true;
    LokiFIRFilter_allocate_samples(self);
    if (!self->samples) {
        LokiFIRFilter_del(self);
        return NULL;
    }

    return self;
}

/// Function de Bessel de première espèce, d'ordre 0.
static float bessel0(float x) {
    float d = 0, ds = 1, s = 1;
    do {
        d  += 2;
        ds *= x * x / d / d;
        s  += ds;
    }
    while (ds > s * 1e-6f);
    return s;
}

LokiFIRFilter *LokiFIRFilter_new_kaiser_bessel(float fs, float fa, float fb, float att, size_t length, size_t decimation) {
    // Ajuster la taille du filtre à un nombre impair de coefficients.
    const size_t half_length = (length - 1) / 2;
    length = half_length * 2 + 1;

    // Allouer le tableau des coefficients.
    float *coeffs = calloc(length, sizeof(float));
    if (!coeffs) {
        return NULL;
    }

    // Calculer la partie droite de la réponse impulsionnelle du fitre idéal.
    coeffs[half_length] = (fb - fa) * 2 / fs;
    for (size_t i = 1; i <= half_length; i ++) {
        coeffs[half_length + i] = (sinf(M_PI * 2 * i * fb / fs) - sinf(M_PI * 2 * i * fa / fs)) / i / M_PI;
    }

    // Calculer le facteur de forme de la fenêtre de Kaiser-Bessel.
    float alpha = att < 21 ? 0.0f :
                  att > 50 ? 0.1102f * (att - 8.7f) :
                             0.5842f * powf((att - 21.0f), 0.4f) + 0.07886f * (att - 21.0f);

    // Appliquer la fenêtre sur la réponse idéale.
    float alpha0 = bessel0(alpha);
    for (size_t i = 0; i <= half_length; i ++) {
        coeffs[half_length + i] *= bessel0(alpha * sqrtf(1.0f - (float)(i * i) / half_length / half_length)) / alpha0;
        coeffs[half_length - i] = coeffs[half_length + i];
    }

    LokiFIRFilter *self = LokiFIRFilter_new(coeffs, length, decimation);
    free(coeffs);

    return self;
}

size_t LokiFIRFilter_get_actual_length(LokiFIRFilter *self) {
    return self->length;
}

bool LokiFIRFilter_work(LokiFIRFilter *self, float in, float *out) {
    // Copie locale de l'état du filtre.
    const size_t phase_length     = self->phase_length;
    const size_t decimation       = self->decimation;
    float *phase_ptr              = self->phase_ptr;
    float *const phase_end        = phase_ptr + phase_length;
    size_t sample_index           = self->sample_index;
    float *sample_ptr             = phase_ptr + sample_index;
    float *const samples          = self->samples;
    float *const samples_end      = self->samples_end;
    const float *coeff_ptr        = self->coeff_ptr;
    const float *const coeffs     = self->coeffs;
    const float *const coeffs_end = self->coeffs_end;
    float acc                     = self->acc;

    #ifdef NO_SIMD
        // Version de référence sans vectorisation

        // Insérer le nouvel échantillon dans le tampon de réception.
        *sample_ptr++ = in;

        for (size_t i = 0; i < phase_length; i ++) {
            if (sample_ptr == phase_end) {
                sample_ptr = phase_ptr;
            }

            acc += (*sample_ptr ++) * (*coeff_ptr ++);

            if (coeff_ptr == coeffs_end) {
                coeff_ptr = coeffs;
            }
        }
    #else
        // Vectorisation ARM NEON
        float32x4_t vsamp, vcoeff;
        float32x4_t vacc = vmovq_n_f32(0);

        // Insérer le nouvel échantillon dans le tampon de réception.
        // Les trois premiers échantillons du buffer sont dupliqués en fin
        // de buffer de la phase courante. Cela permet de traiter le buffer
        // par vecteurs de 4 échantillons même si sample_ptr n'est pas aligné
        // sur un multiple de 4.
        if (sample_index < 3) {
            sample_ptr[phase_length] = in;
        }
        *sample_ptr++ = in;

        float *saved_sample_ptr = sample_ptr;

        // Traiter les échantillons par vecteurs de 4 jusqu'à la fin du buffer
        // pour la phase courante.
        while (sample_ptr < phase_end) {
            vsamp  = vld1q_f32(sample_ptr);
            vcoeff = vld1q_f32(coeff_ptr);
            vacc   = vmlaq_f32(vacc, vsamp, vcoeff);

            sample_ptr += 4;
            coeff_ptr  += 4;

            if (coeff_ptr == coeffs_end) {
                coeff_ptr = coeffs;
            }
        }

        // Lorsque la fin du buffer est dépassée, reprendre au début.
        sample_ptr -= phase_length;

        // Traiter les échantillons à partir du début du buffer
        // jusqu'à l'emplacement de départ.
        while (sample_ptr != saved_sample_ptr) {
            vsamp  = vld1q_f32(sample_ptr);
            vcoeff = vld1q_f32(coeff_ptr);
            vacc   = vmlaq_f32(vacc, vsamp, vcoeff);

            sample_ptr += 4;
            coeff_ptr  += 4;

            if (coeff_ptr == coeffs_end) {
                coeff_ptr = coeffs;
            }
        }

        // Calculer la somme des quatre accumulateurs.
        float32x2_t vacc2 = vadd_f32(vget_low_f32(vacc), vget_high_f32(vacc));
        acc += vget_lane_f32(vacc2, 0) + vget_lane_f32(vacc2, 1);

        phase_ptr += 3;
    #endif

    // Passer à la phase suivante dans le tableau des échantillons.
    phase_ptr += phase_length;
    if (phase_ptr == samples_end) {
        phase_ptr = samples;
        sample_index ++;
        if (sample_index == phase_length) {
            sample_index = 0;
        }
    }

    // Lorsqu'on revient au premier coefficient,
    // le calcul d'un échantillon de sortie est terminé.
    bool res = coeff_ptr == coeffs;
    if (res) {
        *out = acc;
        self->acc = 0;
    }
    else {
        self->acc = acc;
    }

    // Mise à jour de l'état du filtre.
    self->phase_ptr    = phase_ptr;
    self->sample_index = sample_index;
    self->coeff_ptr    = (float*)coeff_ptr;

    return res;
}

void LokiFIRFilter_reset(LokiFIRFilter *self) {
    memset(self->samples, 0, (self->samples_end - self->samples) * sizeof(float));
}

void LokiFIRFilter_del(LokiFIRFilter *self) {
    if (!self) {
        return;
    }

    if (!self->is_clone && self->coeffs) {
        free(self->coeffs);
    }

    if (self->samples) {
        free(self->samples);
    }

    free(self);
}

/// @file libloki-fir.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
