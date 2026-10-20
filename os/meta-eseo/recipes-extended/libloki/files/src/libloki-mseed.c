
#include "libloki.h"

#include <stdlib.h>
#include <libmseed.h>
#include <math.h>

/// @addtogroup gLokiMSeed
/// @{

/// Configuration d'un formateur de séries temporelles miniSEED.
struct LokiMSeedConfig {
    /// Faut-il enregistrer chaque voie dans un fichier séparé ?
    bool separate_channels;
    /// L'identifiant de station de l'interrogateur.
    char *station;
    /// L'identifiant de localisation de l'interrogateur.
    char *location;
    /// L'identifiant de réseau de l'interrogateur.
    char *network;
    /// Faut-il considérer les valeurs brutes des échantillons ?
    bool raw;
    /// Faut-il utiliser l'algorithme de compression STEIM2 ?
    bool steim2;
    /// Un tableau de nom de voies.
    char *channel_names;
};

LokiMSeedConfig *LokiMSeedConfig_new(bool separate_channels, const char *station, const char *location, const char *network, bool raw, bool steim2, const char *channel_names) {
    LokiMSeedConfig *self = calloc(1, sizeof(LokiMSeedConfig));
    if (!self) {
        return NULL;
    }

    self->separate_channels = separate_channels;
    self->station           = strdup(station);
    self->location          = strdup(location);
    self->network           = strdup(network);
    self->raw               = raw;
    self->steim2            = steim2;
    self->channel_names     = strdup(channel_names);

    if (!self->station || !self->location || !self->network || !self->channel_names) {
        LokiMSeedConfig_del(self);
        return NULL;
    }

    // Dans la liste des nom de voies, remplacer les virgules par des fins de chaîne.
    for (size_t i = 0; i < strlen(channel_names); i++) {
        if (channel_names[i] == ',') {
            self->channel_names[i] = 0;
        }
    }

    return self;
}

void LokiMSeedConfig_del(LokiMSeedConfig *self) {
    if (!self) {
        return;
    }

    if (self->station) {
        free(self->station);
    }

    if (self->location) {
        free(self->location);
    }

    if (self->network) {
        free(self->network);
    }

    if (self->channel_names) {
        free(self->channel_names);
    }

    free(self);
}

/// Type des échantillons attendus par #LokiMSeed_work.
typedef struct {
    /// Le numéro de voie.
    uint32_t channel;
    /// La valeur de l'échantillon.
    union {
        int32_t value_raw;
        float   value;
    };
    // D'autres données non utilisées ici.
} LokiMSeedInputSample;

/// Type des échantillons passés à la bibliothèque `libmseed`.
typedef union {
    /// Valeur d'un échantillon entier.
    int32_t i;
    /// Valeur d'un échantillon flottant.
    float   f;
} LokiMSeedOutputSample;

/// Représentation d'un formateur de séries temporelles miniSEED.
struct LokiMSeed {
    /// La configuration d'enregistrement à utiliser.
    LokiMSeedConfig *config;
    /// Buffer d'échantillons préalloué, sans numéro de voie ni numéro de séquence.
    LokiMSeedOutputSample *buffer;
    /// Record MiniSEED préalloué pour toutes les écritures.
    MSRecord *msr;
};

LokiMSeed *LokiMSeed_new(LokiMSeedConfig *config) {
    LokiMSeed *self = calloc(1, sizeof(LokiMSeed));
    self->config = config;

    // Initialiser un record MiniSEED.
    self->msr = msr_init(NULL);
    if (!self->msr) {
        LokiMSeed_del(self);
        return NULL;
    }

    strncpy(self->msr->station,  config->station,  5);
    strncpy(self->msr->location, config->location, 2);
    strncpy(self->msr->network,  config->network,  2);
    self->msr->dataquality = 'R'; // TODO
    self->msr->sampletype  = config->steim2 ? 'i' : 'f';

    return self;
}

/// Le nombre maximal de caractères représentant le nom de la voie.
#define CHANNEL_NAME_LEN 4

/// Le format du suffixe du nom de fichier: "_{n°de voie}.mseed"
#define MSEED_FILENAME_SUFFIX_LEN (CHANNEL_NAME_LEN + 7)

/// La longueur d'un record miniSEED.
#define MSEED_RECLEN 512

void LokiMSeed_work(LokiMSeed *self, const char *filename, LokiTimestamp timestamp, bool file_change, void *data, size_t length, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency) {
    // Allouer le buffer des déplacements au premier appel.
    if (!self->buffer) {
        self->buffer = calloc(length, sizeof(LokiMSeedOutputSample));
        if (!self->buffer) {
            return;
        }
        self->msr->samprate    = sampling_frequency;
        self->msr->datasamples = self->buffer;
    }

    const bool raw               = self->config->raw;
    const bool steim2            = self->config->steim2;
    const bool separate_channels = self->config->separate_channels;
  bool overwrite = file_change;

    const size_t filename_len    = strlen(filename);
    char *actual_filename        = calloc(filename_len + CHANNEL_NAME_LEN + 1, 1);
    char *filename_suffix        = actual_filename + filename_len - 6;
    strcpy(actual_filename, filename);

    const flag encoding  = steim2 ? DE_STEIM2 : DE_FLOAT32;
    const flag byteorder = 1; // big-endian (requis pour le codage Steim2)

    char *name = self->config->channel_names;

    for (size_t c = 0; c < max_channels; c ++) {
        if (!(channels & (1 << c))) {
            continue;
        }

        // Collecter les données pour la voie c
        size_t actual_length = 0;
        uint8_t *ptr_end = (uint8_t*)data + length * sample_size;
        for (uint8_t *ptr = data; ptr != ptr_end; ptr += sample_size) {
            const LokiMSeedInputSample *const sample = (LokiMSeedInputSample*)ptr;
            if (sample->channel != c) {
                continue;
            }

            if (!steim2) {
                self->buffer[actual_length].f = sample->value;
            }
            else if (raw) {
                self->buffer[actual_length].i = sample->value_raw;
            }
            else {
                self->buffer[actual_length].i = roundf(sample->value);
            }
            actual_length ++;
        }

        strncpy(self->msr->channel, name, 3);
        name += strlen(name) + 1;

        self->msr->starttime  = timestamp / 1000;
        self->msr->numsamples = self->msr->samplecnt = actual_length;

        // Écriture de l'enregistrement dans le fichier de destination.
        // overwrite=file_change, reclen=512, verbose=false
        if (separate_channels) {
            snprintf(filename_suffix, MSEED_FILENAME_SUFFIX_LEN, "_%zu.mseed", c);
	/*PhM* correctif ecriture dans un seul fichier ( evite l'ecrasement du packet de voie 0 à n-1) */
            overwrite = file_change; 
        }else{	 
		overwrite = (file_change && (c==0));

        }
        /***********************************************************************************************/
        if (msr_writemseed(self->msr, actual_filename, overwrite, MSEED_RECLEN, encoding, byteorder, false) < 0) {
            fprintf(stderr, "LokiMSeed_work: msr_writemseed failed to write to '%s'\n", actual_filename);
        }
    }
}

void LokiMSeed_close(LokiMSeed *self) {
    if (self->buffer) {
        free(self->buffer);
        self->buffer = NULL;
    }
}

void LokiMSeed_del(LokiMSeed *self) {
    if (!self) {
        return;
    }

    if (self->msr) {
        self->msr->datasamples = NULL;
        msr_free(&self->msr);
    }

    free(self);
}

LokiClass_implementation(LokiFormatter, LokiMSeed,
    LokiClass_define_method(LokiMSeed, new)
    LokiClass_define_method(LokiMSeed, work)
    LokiClass_define_method(LokiMSeed, close)
    LokiClass_define_method(LokiMSeed, del)
);

/// @file libloki-mseed.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
