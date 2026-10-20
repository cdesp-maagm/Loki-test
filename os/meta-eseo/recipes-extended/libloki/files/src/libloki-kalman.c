
#include "libloki-kalman.h"
#include "libloki-ellipse.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/// @addtogroup gLokiKalman
/// @{

/// Représentation d'un filtre de Kalman.
struct LokiKalman {
    /// La puissance du bruit de sortie du filtre.
    float rv;
    /// La puissance du bruit d'état du filtre.
    float rw;
    /// La matrice de covariance de l'erreur d'estimation.
    float P[5][5];
    /// Les coefficients de l'équation de l'ellipse.
    LokiEllipseEquation state;
};

LokiKalman *LokiKalman_new(float initial_radius, const float params[static 3]) {
    LokiKalman * self = calloc(1, sizeof(LokiKalman));
    if (!self) {
        return NULL;
    }

    fprintf(stderr, "LokiKalman_new: creating Kalman filter with Rv=%f Rw=%f P=%f\n", params[0], params[1], params[2]);

    self->rv = params[0];
    self->rw = params[1];

    self->state[0] = 0.5f;
    self->state[4] = -initial_radius * initial_radius / 2;

    for (size_t i = 0; i < 5; i ++) {
        self->P[i][i] = params[2];
    }

    return self;
}

LokiKalman *LokiKalman_clone(const LokiKalman *other) {
    LokiKalman * self = calloc(1, sizeof(LokiKalman));
    if (!self) {
        return NULL;
    }

    memcpy(self, other, sizeof(LokiKalman));

    return self;
}

float *LokiKalman_get_state(LokiKalman *self) {
    return self->state;
}

void LokiKalman_work(LokiKalman *self, float x, float y) {
    const float out  = -y * y;
    const float in[] = {x * x + out, x * y, x, y, 1.0f};

    // Copies locales de l'état du filtre.
    float (* const P)[5] = self->P;
    float *const state   = self->state;
    float rw             = self->rw;

    // Dans les calculs suivants, on tient compte du fait que in[4] = 1

    // Calcul de l'erreur courante :
    // epsilon = out - in * state
    float epsilon = out - state[4];
    for (size_t i = 0; i < 4; i ++) {
        epsilon -= in[i] * state[i];
    }

    // Calcul du produits L = P * in'
    float L[5];
    for (size_t i = 0; i < 5; i ++) {
        L[i] = P[i][4];
        for (size_t j = 0; j < 4; j ++) {
            L[i] += P[i][j] * in[j];
        }
    }

    // Calcul du dénominateur K = Rv + in * P * in'
    float K = self->rv + L[4];
    for (size_t i = 0; i < 4; i ++) {
        K += in[i] * L[i];
    }

    // Normalisation du vecteur L et mise à jour de l'état.
    float K_inv = 1.0f / K;
    for (size_t i = 0; i < 5; i ++) {
        L[i] *= K_inv;
        state[i] += epsilon * L[i];
    }

    // Calcul de J = I - L * in
    float J[5][5];
    for (size_t i = 0; i < 5; i ++) {
        J[i][i] = 1.0f - L[i] * in[i];
        for (size_t j = i + 1; j < 5; j ++) {
            J[i][j] = -L[i] * in[j];
            J[j][i] = -L[j] * in[i];
        }
    }

    // Mise à jour de la matrice P_next = J * P + Rw
    float P_next[5][5];
    for (size_t i = 0; i < 5; i ++) {
        for (size_t j = 0; j < 5; j ++) {
            P_next[i][j] = J[i][0] * P[0][j];
            for (size_t k = 1; k < 5; k ++) {
                P_next[i][j] += J[i][k] * P[k][j];
            }
        }
        P_next[i][i] += rw;
    }

    // Cette boucle est plus rapide que memcpy(P, P_next, sizeof(P_next)).
    // Il est possible que le compilateur optimise le graphe flot de données
    // sans passer par l'allocation du tableau P_next.
    for (size_t i = 0; i < 5; i ++) {
        for (size_t j = 0; j < 5; j ++) {
            P[i][j] = P_next[i][j];
        }
    }
}

void LokiKalman_del(LokiKalman *self) {
    if (!self) {
        return;
    }
    free(self);
}

LokiClass_implementation(LokiEllipseEstimator, LokiKalman,
    LokiClass_set_attribute(params_length, 3)
    LokiClass_define_method(LokiKalman, new)
    LokiClass_define_method(LokiKalman, clone)
    LokiClass_define_method(LokiKalman, work)
    LokiClass_define_method(LokiKalman, get_state)
    LokiClass_define_method(LokiKalman, del)
);

/// @file libloki-kalman.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
