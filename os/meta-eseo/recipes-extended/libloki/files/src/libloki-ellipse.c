
#include "libloki-ellipse.h"

#include <math.h>
#include <complex.h>

/// @addtogroup gLokiEllipseEstimator
/// @{

void LokiEllipse_set_from_coeffs(LokiEllipse *self, const LokiEllipseEquation coeffs) {
    float a   = coeffs[0];
    float b   = coeffs[1];
    float c   = 1.0f - a;
    float d   = coeffs[2];
    float e   = coeffs[3];
    float f   = coeffs[4];

    float ac  = a * c;
    float ae  = a * e;
    float cma = c - a;
    float b2  = b * b;
    float bd  = b * d;
    float be  = b * e;
    float cd  = c * d;

    float b2m4ac  = b2 - ac * 4;
    float samcpb2 = sqrtf(cma * cma + b2) / 2;
    float A0      = 0.5f + samcpb2; // 0.5 == (a + c) / 2
    float B0      = 0.5f - samcpb2; // 0.5 == (a + c) / 2
    float xc      = (cd * 2 - be) / b2m4ac;
    float yc      = (ae * 2 - bd) / b2m4ac;
    float df      = a * xc * xc + b * xc * yc + c * yc * yc - f;

    // FIXME Est-il utile de calculer alpha sachant que par la suite, on recalcule son cos et son sin?
    self->alpha = atan2f(-b, cma) / 2;
    self->xc    = xc;
    self->yc    = yc;
    self->A     = sqrtf(fabsf(df / B0));
    self->B     = sqrtf(fabsf(df / A0));
}

void LokiEllipse_get_coeffs(const LokiEllipse *self, LokiEllipseEquation coeffs) {
    float A2         = self->A * self->A;
    float B2         = self->B * self->B;
    float cos_alpha  = cosf(self->alpha);
    float sin_alpha  = sinf(self->alpha);
    float cos_alpha2 = cos_alpha * cos_alpha;
    float sin_alpha2 = sin_alpha * sin_alpha;
    float xc2        = self->xc * self->xc;
    float yc2        = self->yc * self->yc;
    float K          = A2 + B2;

    coeffs[0] = (A2 * sin_alpha2 + B2 * cos_alpha2) / K;
    coeffs[1] = (B2 - A2) * sin_alpha * cos_alpha * 2 / K;
    coeffs[2] = -coeffs[0] * self->xc * 2 - coeffs[1] * self->yc;
    coeffs[3] = (coeffs[0] - 1) * self->yc * 2 - coeffs[1] * self->xc;
    coeffs[4] = coeffs[0] * xc2 + coeffs[1] * self->xc * self->yc + (1.0f - coeffs[0]) * yc2 - A2 * B2 / K;
}

void LokiEllipse_get_point(const LokiEllipse *self, float theta, float *x, float *y) {
    complex float z = (self->A * cosf(theta)) + I * (self->B * sinf(theta));
    z *= cosf(self->alpha) + I * sinf(self->alpha);

    *x = self->xc + crealf(z);
    *y = self->yc + cimagf(z);
}

float LokiEllipse_get_angle(const LokiEllipse *self, float x, float y, float *x_norm, float *y_norm) {
    complex float z  = x + I * y;
    // Translation pour recentrer l'ellipse autour de (0, 0).
    z -= self->xc + I * self->yc;
    // Rotation pour aligner le grand axe sur l'axe horizontal.
    z *= cosf(self->alpha) - I * sinf(self->alpha);
    // Normalisation pour transformer l'ellipse en un cercle unité.
    *x_norm = x = crealf(z) / self->A;
    *y_norm = y = cimagf(z) / self->B;
    // Calcul de l'angle.
    return atan2f(y, x);
}

/// @file libloki-ellipse.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
