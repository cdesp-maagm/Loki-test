
#ifndef LIBLOKI_BENCHMARKS_H_
#define LIBLOKI_BENCHMARKS_H_

#include <stddef.h>

#define DEFAULT_FUNCTION_NAME  "nlms"
#define DEFAULT_ITERATIONS     1000
#define DEFAULT_BUFFER_LENGTH  1024
#define DEFAULT_FIR_LENGTH     128
#define DEFAULT_FIR_DECIMATION 1

typedef struct {
    char *function_name;
    unsigned iterations;
    size_t buffer_length;
    size_t fir_length;
    unsigned fir_decimation;
} LokiBenchmarks;

#endif
