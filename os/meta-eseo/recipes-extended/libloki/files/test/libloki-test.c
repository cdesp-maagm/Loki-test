
#include <math.h>
#include <stddef.h>
#include <stdarg.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdbool.h>
#include <stdio.h>

#include <libloki-common.h>
#include <libloki-ellipse.h>
#include <libloki-nlms.h>
#include <libloki-rls.h>
#include <libloki-fir.h>

#define EPSILON 1e-5f

static inline bool eqf(float a, float b) {
    return fabsf(a - b) < EPSILON;
}

static void LokiEllipse_coeffs_test(void **state) {
    const float A[]     = {1, 2};
    const float B[]     = {1};
    const float xc[]    = {-0.3, 0, 0.3};
    const float yc[]    = {-0.4, 0, 0.4};
    const float alpha[] = {0, M_PI * 0.25, M_PI * 0.5, M_PI * 0.75};

    for (int iA = 0; iA < LEN(A); iA ++) {
        for (int iB = 0; iB < LEN(B); iB ++) {
            for (int ixc = 0; ixc < LEN(xc); ixc ++) {
                for (int iyc = 0; iyc < LEN(yc); iyc ++) {
                    for (int ialpha = 0; ialpha < LEN(alpha); ialpha ++) {
                        LokiEllipse ref = {A[iA], B[iB], xc[ixc], yc[iyc], alpha[ialpha]};
                        float coeffs[5];
                        LokiEllipse_get_coeffs(&ref, coeffs);

                        LokiEllipse res;
                        LokiEllipse_set_from_coeffs(&res, coeffs);
                        // Si l'angle est négatif, effectuer une rotation de pi.
                        if (res.alpha < 0) {
                            res.alpha += M_PI;
                        }

                        // Vérifier que l'ellipse reconstruite est identique à
                        // l'ellipse de référence.
                        assert_true(eqf(res.A,  ref.A));
                        assert_true(eqf(res.B,  ref.B));
                        assert_true(eqf(res.xc, ref.xc));
                        assert_true(eqf(res.yc, ref.yc));

                        // Si les axes ont la même longueur, on accepte n'importe quel angle.
                        if (ref.A != ref.B) {
                            assert_true(eqf(res.alpha, ref.alpha));
                        }
                    }
                }
            }
        }
    }
}

static void LokiEllipse_point_angle_test(void **state) {
    LokiEllipse ref = {2, 1, -0.3, 0.4, M_PI * 0.25};
    float step = M_PI / 180;

    for (float theta_ref = -M_PI + step; theta_ref < M_PI; theta_ref += step) {
        float x, y;
        LokiEllipse_get_point(&ref, theta_ref, &x, &y);
        float theta = LokiEllipse_get_angle(&ref, x, y);

        assert_true(eqf(theta, theta_ref));
    }
}

static void LokiNLMS_test(void **state) {
    const LokiEllipse ref = {1.5, 0.75, 0.25, 0.5, 1};
    const float radius = 1.0f;

    const float params[] = {0.02, 0.01};
    LokiNLMS *nlms = LokiNLMS_new(radius, params);
    for (int i = 0; i < 100; i ++) {
        for (float theta = -M_PI; theta < M_PI; theta += M_PI / 90) {
            float x, y;
            LokiEllipse_get_point(&ref, theta, &x, &y);
            LokiNLMS_work(nlms, x, y);
        }
    }

    // Calcul des paramètres de l'ellipse reconstruite.
    LokiEllipse res;
    LokiEllipse_set_from_coeffs(&res, LokiNLMS_get_state(nlms));

    LokiNLMS_del(nlms);

    // Vérifier que l'ellipse reconstruite est identique à
    // l'ellipse de référence.
    assert_true(eqf(res.A,  ref.A));
    assert_true(eqf(res.B,  ref.B));
    assert_true(eqf(res.xc, ref.xc));
    assert_true(eqf(res.yc, ref.yc));

    // Si les axes ont la même longueur, on accepte n'importe quel angle.
    if (ref.A != ref.B) {
        assert_true(eqf(res.alpha, ref.alpha));
    }
}

static void LokiRLS_test(void **state) {
    const LokiEllipse ref = {1.5, 0.75, 0.25, 0.5, 1};
    const float radius = 1.0f;

    const float params[] = {0.99, 0.1};
    LokiRLS *rls = LokiRLS_new(radius, params);
    for (int i = 0; i < 100; i ++) {
        for (float theta = -M_PI; theta < M_PI; theta += M_PI / 90) {
            float x, y;
            LokiEllipse_get_point(&ref, theta, &x, &y);
            LokiRLS_work(rls, x, y);
        }
    }

    // Calcul des paramètres de l'ellipse reconstruite.
    LokiEllipse res;
    LokiEllipse_set_from_coeffs(&res, LokiRLS_get_state(rls));

    LokiRLS_del(rls);

    // Vérifier que l'ellipse reconstruite est identique à
    // l'ellipse de référence.
    assert_true(eqf(res.A,  ref.A));
    assert_true(eqf(res.B,  ref.B));
    assert_true(eqf(res.xc, ref.xc));
    assert_true(eqf(res.yc, ref.yc));

    // Si les axes ont la même longueur, on accepte n'importe quel angle.
    if (ref.A != ref.B) {
        assert_true(eqf(res.alpha, ref.alpha));
    }
}

static void LokiFIRFilter_test(void **state) {
    const float coeffs[] = {0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5};
    const float x[]     = {0.1,  0.2, 0.1, 0.3,  0.2, 0.3, 0.2, 0.4, 0.3,  0.4, 0.3,  0.5, 0.1,  0.2, 0.1, 0.3,  0.2, 0.3, 0.2, 0.4, 0.3,  0.4, 0.3,  0.5};
    const float y_ref[] = {0.05, 0.2, 0.4, 0.75, 1.2, 1.8, 2.5, 3.4, 4.45, 5.7, 6.55, 7.05, 8.05, 8.0, 8.4, 8.3, 8.7, 8.05, 7.85, 7.15, 6.95, 5.7, 6.55, 7.05};

    for (int decimation = 1; decimation <= LEN(coeffs); decimation ++) {
        // Si le nombre de coefficients n'est pas multiple de decimation,
        // la sortie sera retardée.
        LokiFIRFilter *filter = LokiFIRFilter_new(coeffs, LEN(coeffs), decimation);
        int offset = LokiFIRFilter_get_actual_length(filter) - LEN(coeffs);
        for (int i = 0; i < LEN(x); i ++) {
            float y;
            if (LokiFIRFilter_work(filter, x[i], &y) && i >= offset) {
                assert_true(eqf(y, y_ref[i - offset]));
            }
        }

        LokiFIRFilter_del(filter);
    }
}

static void LokiFIRFilter_kaiser_bessel_test(void **state) {
    const float fs = 44100;
    const float fa = 6000;
    const float fb = 14000;
    const float att = 60;
    const size_t length = 31;

    const float coeffs[] = {
        -0.000541, 0.000977, 0.003605, -0.000695, 0.000166, 0.001073, -0.022747, -0.014091,
        0.032312, 0.012168, 0.018258, 0.083745, -0.080396, -0.264571, 0.049418, 0.362812,
        0.049418, -0.264571, -0.080396, 0.083745, 0.018258, 0.012168, 0.032312, -0.014091,
        -0.022747, 0.001073, 0.000166, -0.000695, 0.003605, 0.000977, -0.000541};

    LokiFIRFilter *filter = LokiFIRFilter_new_kaiser_bessel(fs, fa, fb, att, length, 1);
    int offset = LokiFIRFilter_get_actual_length(filter) - length;

    for (size_t i = 0; i < length + offset; i ++) {
        float x = i == 0 ? 1.0f : 0.0f;
        float y;
        if (LokiFIRFilter_work(filter, x, &y)) {
            if (i >= offset) {
                assert_true(eqf(y, coeffs[i - offset]));
            }
        }
    }
    LokiFIRFilter_del(filter);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(LokiEllipse_coeffs_test),
        cmocka_unit_test(LokiEllipse_point_angle_test),
        cmocka_unit_test(LokiNLMS_test),
        cmocka_unit_test(LokiRLS_test),
        cmocka_unit_test(LokiFIRFilter_test),
        cmocka_unit_test(LokiFIRFilter_kaiser_bessel_test),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
