
#include "libloki-benchmarks.h"
#include "libloki-benchmarks-arguments.h"

#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <libloki.h>

static inline void do_not_optimize(void *ptr) {
    asm volatile("" : : "g"(ptr) : "memory");
}

static float random_float(void) {
    return (double)random() / (double)RAND_MAX;
}

static float *new_random_float_array(size_t length) {
    float *res = malloc(length * sizeof(float));
    if (res) {
        for (size_t i = 0; i < length; i ++) {
            res[i] = random_float();
        }
    }
    return res;
}

static int LokiBenchmarks_run_nlms(LokiBenchmarks *self) {
    return 0;
}

static int LokiBenchmarks_run_rls(LokiBenchmarks *self) {
    int err = 0;

    // Allouer et initialiser les données et le filtre
    float *buffer_x = new_random_float_array(self->buffer_length);
    float *buffer_y = new_random_float_array(self->buffer_length);
    float radius = random_float();
    float *params = new_random_float_array(2);
    LokiRLS *filter = LokiRLS_new(radius, params);
    if (!buffer_x || !buffer_y || !filter) {
        err = ENOMEM;
        goto LokiBenchmarks_run_rls_end;
    }

    // Exécuter le filtre
    clock_t begin = clock();

    for (unsigned i = 0; i < self->iterations; i ++) {
        for (size_t j = 0; j < self->buffer_length; j ++) {
            LokiRLS_work(filter, buffer_x[i], buffer_y[i]);
        }
    }

    clock_t end = clock();
    double time_spent  = (double)(end - begin) / CLOCKS_PER_SEC;
    double sample_freq = floor((double)self->iterations * (double)self->buffer_length / time_spent);

    fprintf(stderr, "Total time: %lf sec. Max sample frequency: %lf Hz\n", time_spent, sample_freq);

LokiBenchmarks_run_rls_end:
    LokiRLS_del(filter);
    if (buffer_x) {
        free(buffer_x);
    }
    if (buffer_y) {
        free(buffer_y);
    }

    return err;
}

static int LokiBenchmarks_run_fir(LokiBenchmarks *self) {
    int err = 0;

    // Allouer et initialiser les données et le filtre
    float *coeffs = new_random_float_array(self->fir_length);
    float *buffer = new_random_float_array(self->buffer_length);
    LokiFIRFilter *filter = LokiFIRFilter_new(coeffs, self->fir_length, self->fir_decimation);

    if (!coeffs || !buffer || !filter) {
        err = ENOMEM;
        goto LokiBenchmarks_run_fir_end;
    }

    // Exécuter le filtre
    float out;

    clock_t begin = clock();

    for (unsigned i = 0; i < self->iterations; i ++) {
        for (size_t j = 0; j < self->buffer_length; j ++) {
            LokiFIRFilter_work(filter, buffer[i], &out);
            do_not_optimize(&out);
        }
    }

    clock_t end = clock();
    double time_spent  = (double)(end - begin) / CLOCKS_PER_SEC;
    double sample_freq = floor((double)self->iterations * (double)self->buffer_length / time_spent);

    fprintf(stderr, "Total time: %lf sec. Max sample frequency: %lf Hz\n", time_spent, sample_freq);

LokiBenchmarks_run_fir_end:
    LokiFIRFilter_del(filter);
    if (coeffs) {
        free(coeffs);
    }
    if (buffer) {
        free(buffer);
    }

    return err;
}

int main(int argc, char *argv[]) {
    LokiBenchmarks self = {
        .function_name  = DEFAULT_FUNCTION_NAME,
        .iterations     = DEFAULT_ITERATIONS,
        .buffer_length  = DEFAULT_BUFFER_LENGTH,
        .fir_length     = DEFAULT_FIR_LENGTH,
        .fir_decimation = DEFAULT_FIR_DECIMATION
    };

    int err = LokiBenchmarks_parse_args(&self, argc, argv);
    if (err) {
        return err;
    }

    if (!strcmp(self.function_name, "nlms")) {
        return LokiBenchmarks_run_nlms(&self);
    }
    else if (!strcmp(self.function_name, "rls")) {
        return LokiBenchmarks_run_rls(&self);
    }
    else if (!strcmp(self.function_name, "fir")) {
        return LokiBenchmarks_run_fir(&self);
    }
    else {
        fprintf(stderr, "Unsupported function name: %s\n", self.function_name);
        return EINVAL;
    }
}
