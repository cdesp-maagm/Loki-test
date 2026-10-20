
#include "libloki-formatter.h"

#include <stdlib.h>
#include <string.h>

/// @addtogroup gLokiFormatter
/// @{

/// Représentation d'un formateur de séries temporelles.
struct LokiFormatter {
    /// Les données spécifiques à l'implémentation du formateur.
    void *instance;
    /** L'implémentation des méthodes de ce formateur.
     *
     * Les pointeurs vers les méthodes seront copiés ici pour éviter un niveau
     * d'indirection supplémentaire et réduire la durée d'un appel de méthode.
     */
    LokiFormatterInterface impl;
};

LokiFormatter * LokiFormatter_new(void *config) {
    return NULL;
}

LokiFormatter *LokiFormatter_new_with_implementation(const LokiFormatterInterface *impl, void *config) {
    LokiFormatter *self = calloc(1, sizeof(LokiFormatter));
    if (!self) {
        return NULL;
    }

    self->instance = impl->new(config);
    if (!self->instance) {
        LokiFormatter_del(self);
        return NULL;
    }

    memcpy(&self->impl, impl, sizeof(LokiFormatterInterface));

    return self;
}

void LokiFormatter_work(LokiFormatter *self, const char *filename, LokiTimestamp timestamp, bool file_change, void *data, size_t length, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency) {
    self->impl.work(self->instance, filename, timestamp, file_change, data, length, max_channels, channels, sample_size, sampling_frequency);
}

void LokiFormatter_close(LokiFormatter *self) {
    self->impl.close(self->instance);
}

void LokiFormatter_del(LokiFormatter *self) {
    if (!self) {
        return;
    }

    self->impl.del(self->instance);
    free(self);
}

/// @file libloki-formatter.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
