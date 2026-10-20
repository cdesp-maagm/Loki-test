
#include "libloki.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

/// @addtogroup gLokiRaw
/// @{

/// Représentation d'un formateur de données brutes.
struct LokiRaw {
    /// Le numéro du fichier de destination.
    int out;
};

LokiRaw *LokiRaw_new(void *config) {
    // L'objet config est ignoré
    LokiRaw *self = calloc(1, sizeof(LokiRaw));
    self->out = -1;
    return self;
}

void LokiRaw_work(LokiRaw *self, const char *filename, LokiTimestamp timestamp, bool file_change, void *data, size_t length, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency) {
    if (file_change) {
        if (self->out >= 0) {
            close(self->out);
        }
        self->out = open(filename, O_CREAT | O_WRONLY, 0644);
        if (self->out < 0) {
            fprintf(stderr, "LokiRaw_work: failed to create file %s (%s)\n", filename, strerror(errno));
        }
    }

    if (self->out < 0) {
        return;
    }

    size_t count = sample_size * length;
    if (write(self->out, data, count) != count) {
        fprintf(stderr, "LokiRaw_work: write error (%s)\n", strerror(errno));
    }
}

void LokiRaw_close(LokiRaw *self) {
    if (self->out >= 0) {
        close(self->out);
        self->out = -1;
    }
}

void LokiRaw_del(LokiRaw *self) {
    if (!self) {
        return;
    }

    LokiRaw_close(self);


    free(self);
}

LokiClass_implementation(LokiFormatter, LokiRaw,
    LokiClass_define_method(LokiRaw, new)
    LokiClass_define_method(LokiRaw, work)
    LokiClass_define_method(LokiRaw, close)
    LokiClass_define_method(LokiRaw, del)
);

/// @file libloki-raw.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
