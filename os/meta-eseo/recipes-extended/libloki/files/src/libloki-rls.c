
#include "libloki-rls.h"
#include "libloki-ellipse.h"

#include <stdlib.h>
#include <string.h>

/// @addtogroup gLokiRLS
/// @{

/// Représentation d'un filtre RLS.
struct LokiRLS {
    /// Le facteur d'oubli du filtre.
    float lambda;
    /// L'inverse du facteur d'oubli du filtre.
    float lambda_inv;
    /// L'inverse de la matrice de covariance du signal d'entrée.
    float P[5][5];
    /// Les coefficients de l'équation de l'ellipse.
    LokiEllipseEquation state;
};

LokiRLS *LokiRLS_new(float initial_radius, const float params[static 2]) {
    LokiRLS * self = calloc(1, sizeof(LokiRLS));
    if (!self) {
        return NULL;
    }

    self->lambda     = params[0];
    self->lambda_inv = 1.0f / self->lambda;

    self->state[0] = 0.5f;
    self->state[4] = -initial_radius * initial_radius / 2;

    for (size_t i = 0; i < 5; i ++) {
        self->P[i][i] = params[1];
    }

    return self;
}

LokiRLS *LokiRLS_clone(const LokiRLS *other) {
    LokiRLS * self = calloc(1, sizeof(LokiRLS));
    if (!self) {
        return NULL;
    }

    memcpy(self, other, sizeof(LokiRLS));

    return self;
}

float *LokiRLS_get_state(LokiRLS *self) {
    return self->state;
}

void LokiRLS_work(LokiRLS *self, float x, float y) {
    const float out  = -y * y;
    const float in[] = {x * x + out, x * y, x, y, 1.0f};

    // Copies locales de l'état du filtre.
    float (* const P)[5]   = self->P;
    float *const state     = self->state;
    const float lambda_inv = self->lambda_inv;

    // Dans les calculs suivants, on tient compte du fait que in[4] = 1

    // Calcul de l'erreur courante :
    // epsilon = out - in * state
    float epsilon = out - state[4];
    for (size_t i = 0; i < 4; i ++) {
        epsilon -= in[i] * state[i];
    }

    // Calcul du produits G = P * in'
    float G[5];
    for (size_t i = 0; i < 5; i ++) {
        G[i] = P[i][4];
        for (size_t j = 0; j < 4; j ++) {
            G[i] += P[i][j] * in[j];
        }
    }

    // Calcul du facteur de normalisation K = lambda + in * P * in'
    float K = self->lambda + G[4];
    for (size_t i = 0; i < 4; i ++) {
        K += in[i] * G[i];
    }

    // Normalisation du vecteur G et mise à jour de l'état.
    float K_inv = 1.0f / K;
    for (size_t i = 0; i < 5; i ++) {
        G[i] *= K_inv;
        state[i] += epsilon * G[i];
    }

    // Calcul de J = I - G * in
    float J[5][5];
    for (size_t i = 0; i < 5; i ++) {
        J[i][i] = 1.0f - G[i] * in[i];
        for (size_t j = i + 1; j < 5; j ++) {
            J[i][j] = -G[i] * in[j];
            J[j][i] = -G[j] * in[i];
        }
    }

    // Mise à jour de la matrice P_next = J * P / lambda
    float P_next[5][5];
    for (size_t i = 0; i < 5; i ++) {
        for (size_t j = 0; j < 5; j ++) {
            P_next[i][j] = J[i][0] * P[0][j];
            for (size_t k = 1; k < 5; k ++) {
                P_next[i][j] += J[i][k] * P[k][j];
            }
            P_next[i][j] *= lambda_inv;
        }
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

void LokiRLS_del(LokiRLS *self) {
    if (!self) {
        return;
    }
    free(self);
}

LokiClass_implementation(LokiEllipseEstimator, LokiRLS,
    LokiClass_set_attribute(params_length, 2)
    LokiClass_define_method(LokiRLS, new)
    LokiClass_define_method(LokiRLS, clone)
    LokiClass_define_method(LokiRLS, work)
    LokiClass_define_method(LokiRLS, get_state)
    LokiClass_define_method(LokiRLS, del)
);

/// @file libloki-rls.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
