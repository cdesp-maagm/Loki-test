
#include "libloki-benchmarks-arguments.h"
#include <stdlib.h>
#include <string.h>
#include <argp.h>

const char *argp_program_version = "libloki-benchmarks 1.0";
const char *argp_program_bug_address = "<guillaume.savaton@eseo.fr>";

static char LokiBenchmarks_doc[] = "Benchmarks for libloki signal processing functions";
static char LokiBenchmarks_args_doc[] = "FILE";

static struct argp_option LokiBenchmarks_opts[] = {
    {"function",                 'f', "STR",   0, "The function to run (nlms|rls|fir)"},
    {"iterations",               'i', "INT",   0, "The number of input buffers to process"},
    {"buffer-length",            'l', "INT",   0, "The length of the input buffer to use (in samples)"},
    {"fir-length",               'L', "INT",   0, "The length of the FIR filter to run"},
    {"fir-decimation",           'd', "INT",   0, "The decimation factor of the FIR filter to run"},
    {0}
};

static int parse_long(long *dest, const char *opt, const char *src) {
    char *endptr;
    *dest = strtol(src, &endptr, 0);

    if (*endptr) {
        fprintf(stderr, "Expected integer value for '%s', found: '%s'", opt, src);
        return EINVAL;
    }
    if (errno == ERANGE) {
        fprintf(stderr, "Integer value out of range for '%s': '%s'", opt, src);
        return errno;
    }
    return 0;
}

static error_t LokiBenchmarks_parse_arguments(int key, char *arg, struct argp_state *state) {
    LokiBenchmarks *self = state->input;

    float f;
    long i;

    int err = 0;

    switch (key) {
        case 'f':
            self->function_name = arg;
            break;

        case 'i':
            err = parse_long(&i, "iterations", arg);
            if (!err) {
                self->iterations = i;
            }
            break;

        case 'l':
            err = parse_long(&i, "buffer-length", arg);
            if (!err) {
                self->buffer_length = i;
            }
            break;

        case 'L':
            err = parse_long(&i, "fir-length", arg);
            if (!err) {
                self->fir_length = i;
            }
            break;

        case 'd':
            err = parse_long(&i, "fir-decimation", arg);
            if (!err) {
                self->fir_decimation = i;
            }
            break;

        case ARGP_KEY_ARG:
            argp_usage(state);
            break;

        case ARGP_KEY_END:
            break;

        default:
            err = ARGP_ERR_UNKNOWN;
    }

    return err;
}

static struct argp LokiBenchmarks_arguments = {
    LokiBenchmarks_opts,
    LokiBenchmarks_parse_arguments,
    LokiBenchmarks_args_doc,
    LokiBenchmarks_doc
};

int LokiBenchmarks_parse_args(LokiBenchmarks *self, int argc, char *argv[]) {
    return argp_parse(&LokiBenchmarks_arguments, argc, argv, 0, NULL, self);
}
