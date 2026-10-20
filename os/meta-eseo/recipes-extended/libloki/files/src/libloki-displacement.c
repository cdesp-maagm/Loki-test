
#include "libloki.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

/// @addtogroup gLokiDisplacement
/// @{

/// Représentation d'un calculateur de déplacement.
struct LokiDisplacement {
    /// La dernière ellipse calculée, après lissage.
    LokiEllipse ellipse;
    /// Le filtre adaptatif d'estimation des paramètres de l'ellipse.
    LokiEllipseEstimator *estimator;
    /// Le filtre passe-bas de suppression du déplacement fictif.
    LokiFIRFilter *filter;
    /// Périodicité du calcul des paramètres de l'ellipse.
    unsigned estimator_throttle;
    /// Compteur pour l'activation du calcul des paramètres de l'ellipse.
    unsigned estimator_cnt;
    /// La phase précédente, pour le déroulage de phase.
    float phi_prev;
    /// La phase après filtrage du déplacement fictif.
    float phi_filt;
    /// La phase de référence correspondant à un déplacement nul.
    float phi_ref;
    /// Le nombre de tours effectués lors du déroulage de phase.
    int32_t phi_turns;
    /// L'angle précédent de l'ellipse, pour détecter les sauts de pi/2.
    float alpha_prev;
    /// L'angle de référence pour corriger l'angle de l'ellipse en cas de saut.
    float alpha_ref;
    /// Le facteur de conversion d'angle en distance.
    float scale;
    /// Les coefficients a des filtres de lissage des paramètres de l'ellipse.
    float iir_a[3];
    /// Les coefficients b des filtres de lissage des paramètres de l'ellipse.
    float iir_b[3];
};

LokiDisplacement *LokiDisplacement_new(LokiEllipseEstimator *estimator, LokiFIRFilter *filter, unsigned throttle, float scale, float tau[static 3], float sampling_frequency) {
    LokiDisplacement *self = calloc(1, sizeof(LokiDisplacement));
    if (!self) {
        return NULL;
    }

    self->estimator_throttle = throttle;
    self->estimator_cnt      = 0;
    self->scale              = scale;
    self->estimator          = estimator;
    self->filter             = filter;

    for (size_t i = 0; i < 3; i ++) {
        const float ts = tau[i] * sampling_frequency;
        self->iir_a[i] = ts   / (ts + 1);
        self->iir_b[i] = 1.0f / (ts + 1);
    }

    return self;
}

LokiDisplacement *LokiDisplacement_clone(const LokiDisplacement *other) {
    LokiDisplacement *self = calloc(1, sizeof(LokiDisplacement));
    if (!self) {
        return NULL;
    }

    memcpy(self, other, sizeof(LokiDisplacement));

    self->estimator = LokiEllipseEstimator_clone(other->estimator);
    self->filter    = LokiFIRFilter_clone(other->filter);
    if (!self->estimator || !self->filter) {
        LokiDisplacement_del(self);
        return NULL;
    }

    return self;
}

bool LokiDisplacement_work(LokiDisplacement *self, float x, float y, float *x_norm, float *y_norm, float *out) {
    // Calcul des paramètres de l'ellipse et de l'angle courant.
    self->estimator_cnt ++;
    if (self->estimator_cnt >= self->estimator_throttle) {
        LokiEllipseEstimator_work(self->estimator, x, y);
        self->estimator_cnt = 0;
    }

    LokiEllipse ellipse;
    LokiEllipse_set_from_coeffs(&ellipse, LokiEllipseEstimator_get_state(self->estimator));

    // Éviter les sauts entre -pi/2 et +pi/2 lorsque l'ellipse est presque verticale.
    float dalpha = ellipse.alpha - self->alpha_prev;
    self->alpha_prev = ellipse.alpha;

    if (dalpha > M_PI_2 || dalpha < -M_PI_2) {
        self->alpha_ref = M_PI - self->alpha_ref;
    }

    ellipse.alpha += self->alpha_ref;

    // Lisser les paramètres de l'ellipse.
    const float *const a = self->iir_a;
    const float *const b = self->iir_b;
    self->ellipse.A     = a[0] * self->ellipse.A     + b[0] * ellipse.A;
    self->ellipse.B     = a[0] * self->ellipse.B     + b[0] * ellipse.B;
    self->ellipse.xc    = a[1] * self->ellipse.xc    + b[1] * ellipse.xc;
    self->ellipse.yc    = a[1] * self->ellipse.yc    + b[1] * ellipse.yc;
    self->ellipse.alpha = a[2] * self->ellipse.alpha + b[2] * ellipse.alpha;

    // Calculer la phase courante.
    float phi = LokiEllipse_get_angle(&self->ellipse, x, y, x_norm, y_norm);

    // Dérouler la phase pour éviter les discontinuités au passage de -pi à +pi.
    float dphi = phi - self->phi_prev;
    self->phi_prev = phi;

    if (dphi > M_PI) {
        self->phi_turns --;
    }
    else if (dphi < -M_PI) {
        self->phi_turns ++;
    }

    phi += M_PI * 2 * self->phi_turns;

    // Filtrage passe-bas pour éliminer le déplacement fictif.
    if (LokiFIRFilter_work(self->filter, phi, &phi)) {
        // Mémoriser la dernière valeur filtrée, pour utilisation comme
        // référence dans LokiDisplacement_reset.
        self->phi_filt = phi;
        // Calculer le déplacement et affecter l'échantillon de destination.
        *out = (phi - self->phi_ref) * self->scale;
        return true;
    }

    return false;
}

void LokiDisplacement_reset(LokiDisplacement *self) {
    self->phi_turns = 0;
    self->phi_ref   = self->phi_filt;
    LokiFIRFilter_reset(self->filter);
}

LokiEllipse *LokiDisplacement_get_ellipse(LokiDisplacement *self) {
    return &self->ellipse;
}

void LokiDisplacement_del(LokiDisplacement *self) {
    if (!self) {
        return;
    }

    if (self->estimator) {
        LokiEllipseEstimator_del(self->estimator);
    }

    if (self->filter) {
        LokiFIRFilter_del(self->filter);
    }

    free(self);
}

/// @file libloki-displacement.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
