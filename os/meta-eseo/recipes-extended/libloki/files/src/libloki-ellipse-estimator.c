
#include <stdlib.h>
#include <string.h>

#include "libloki-ellipse-estimator.h"

/// @addtogroup gLokiEllipseEstimator
/// @{

/// Représentation d'un filtre d'estimation des paramètres d'une ellipse.
struct LokiEllipseEstimator {
    /// Les données spécifiques à l'implémentation de l'estimateur.
    void *instance;
    /** L'implémentation des méthodes de cet estimateur.
     *
     * Les pointeurs vers les méthodes seront copiés ici pour éviter un niveau
     * d'indirection supplémentaire et réduire la durée d'un appel de méthode.
     */
    LokiEllipseEstimatorInterface impl;
};

LokiEllipseEstimator *LokiEllipseEstimator_new(float initial_radius, const float params[]) {
    return NULL;
}

LokiEllipseEstimator *LokiEllipseEstimator_new_with_implementation(const LokiEllipseEstimatorInterface *impl, float initial_radius, const float params[]) {
    LokiEllipseEstimator *self = calloc(1, sizeof(LokiEllipseEstimator));
    if (!self) {
        return NULL;
    }

    self->instance = impl->new(initial_radius, params);
    if (!self->instance) {
        LokiEllipseEstimator_del(self);
        return NULL;
    }

    memcpy(&self->impl, impl, sizeof(LokiEllipseEstimatorInterface));

    return self;
}

LokiEllipseEstimator *LokiEllipseEstimator_clone(const LokiEllipseEstimator *other) {
    LokiEllipseEstimator *self = calloc(1, sizeof(LokiEllipseEstimator));
    if (!self) {
        return NULL;
    }

    memcpy(self, other, sizeof(LokiEllipseEstimator));

    self->instance = self->impl.clone(other->instance);
    if (!self->instance) {
        LokiEllipseEstimator_del(self);
        return NULL;
    }

    return self;
}

void LokiEllipseEstimator_work(LokiEllipseEstimator *self, float x, float y) {
    self->impl.work(self->instance, x, y);
}

float *LokiEllipseEstimator_get_state(LokiEllipseEstimator *self) {
    return self->impl.get_state(self->instance);
}

void LokiEllipseEstimator_del(LokiEllipseEstimator *self) {
    if (!self) {
        return;
    }

    self->impl.del(self->instance);
    free(self);
}

/// @file libloki-ellipse-estimator.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
