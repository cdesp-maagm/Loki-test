
#include "libloki-nlms.h"
#include "libloki-ellipse.h"

#include <stdlib.h>
#include <string.h>

/// @addtogroup gLokiNLMS
/// @{

/// Correction des poids du filtre pour éviter une division par zéro.
#define NLMS_NU 1.0e-30f

/// Représentattion d'un filtre NLMS.
struct LokiNLMS {
    /// Le facteur d'apprentissage du filtre LMS.
    float mu;
    /// Le coefficient du filtre passe-bas de mise à jour des poids.
    float alpha;
    /// Les coefficients de l'équation de l'ellipse.
    LokiEllipseEquation state;
    /// Les poids de normalisation du filtre LMS.
    float weights[5];
};

LokiNLMS *LokiNLMS_new(float initial_radius, const float params[static 2]) {
    LokiNLMS * self = calloc(1, sizeof(LokiNLMS));
    if (!self) {
        return NULL;
    }

    self->mu      = params[0];
    self->alpha   = params[1];

    self->state[0] = 0.5f;
    self->state[4] = -initial_radius * initial_radius / 2;

    return self;
}

LokiNLMS *LokiNLMS_clone(const LokiNLMS *other) {
    LokiNLMS * self = calloc(1, sizeof(LokiNLMS));
    if (!self) {
        return NULL;
    }

    memcpy(self, other, sizeof(LokiNLMS));

    return self;
}

float *LokiNLMS_get_state(LokiNLMS *self) {
    return self->state;
}

void LokiNLMS_work(LokiNLMS *self, float x, float y) {
    float out = -y * y;
    float in[] = {x * x + out, x * y, x, y, 1};

    // Calcul de l'erreur courante :
    // epsilon = out - in * state
    float epsilon = out;
    for (size_t i = 0; i < LEN(in); i ++) {
        epsilon -= in[i] * self->state[i];
    }

    // Mise à jour des facteurs de normalisation
    // en utilisant un filtre IIR du premier ordre.
    // Mise à jour des coefficients par descente de gradient.
    float alpha   = self->alpha;
    float umalpha = 1.0f - alpha;
    float m       = self->mu * epsilon;
    for (size_t i = 0; i < LEN(in); i ++) {
        self->weights[i] = umalpha * self->weights[i] + alpha * in[i] * in[i];
        self->state[i] += m * in[i] / (self->weights[i] + NLMS_NU);
    }
}

void LokiNLMS_del(LokiNLMS *self) {
    if (!self) {
        return;
    }
    free(self);
}

LokiClass_implementation(LokiEllipseEstimator, LokiNLMS,
    LokiClass_set_attribute(params_length, 2)
    LokiClass_define_method(LokiNLMS, new)
    LokiClass_define_method(LokiNLMS, clone)
    LokiClass_define_method(LokiNLMS, work)
    LokiClass_define_method(LokiNLMS, get_state)
    LokiClass_define_method(LokiNLMS, del)
);

/// @file libloki-nlms.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
