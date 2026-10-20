
/// Permettre l'utilisation de la fonction `pthread_setname_np` pour modifier le nom d'un thread.
#define _GNU_SOURCE

#include "libloki.h"
#include "libloki-system-defaults.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pthread.h>
#include <errno.h>

/// @addtogroup gLokiSystem
/// @{

// Uncomment this line to enable malloc monitoring (see libloki-hooks)
// #define DEBUG_MALLOC

/// Les paramètres de configuration d'un système d'acquisition et de traitement.
struct LokiSystemConfig {
    /// Faut-il simuler les capteurs de déplacement ?
    bool simulate;
    /// Le délai d'attente avant d'alimenter la FIFO de sortie, en secondes.
    float skip;
    /// La longueur d'onde de la diode laser, en nm.
    float wavelength;
    /// Le nombre de réflexions supposé.
    unsigned reflections;
    /// L'indice optique de la cavité.
    float cavity_index;
    /// Unité de distance.
    char distance_unit;
    /// Le filtre adaptatif pour l'estimation des paramètres de l'ellipse.
    LokiEllipseEstimatorInterface *estimator_impl;
    /// La périodicité de mise à jour des paramètres de l'ellipse, en échantillons.
    unsigned estimator_throttle;
    /// Le rayon initial à utiliser dans le filtre d'estimation.
    float estimator_initial_radius;
    /// Le tableau des paramètres de l'estimateur.
    float *estimator_params;
    /// La bande passante du filtre d'élimination du déplacement fictif, en Hz.
    float filter_bandwidth;
    /// L'atténuation du filtre d'élimination du déplacement fictif, en dB.
    float filter_attenuation;
    /// Le nombre de coefficients du filtre d'élimination du déplacement fictif.
    size_t filter_length;
    /// Le facteur de décimation du filtre d'élimination du déplacement fictif.
    size_t filter_decimation;
    /// Les constantes de temps des filtres de lissage des paramètres de l'ellipse.
    float time_constants[3];
};

/// Les noms des filtres adaptatifs supportés pour l'estimation des paramètres de l'ellipse.
static const char *const LokiSystemConfig_estimator_names[] = {
    "rls", "nlms", "kalman"
};

/// Les implémentations des filtres adaptatifs supportés pour l'estimation des paramètres de l'ellipse.
static const LokiEllipseEstimatorInterface *const LokiSystemConfig_estimator_impls[] = {
    &LokiRLSClass, &LokiNLMSClass, &LokiKalmanClass
};

LokiSystemConfig * LokiSystemConfig_new(void) {
    LokiSystemConfig *self = calloc(1, sizeof(LokiSystemConfig));
    if (!self) {
        return NULL;
    }

    self->simulate                 = LOKI_SYSTEM_DEFAULT_SIMULATE;
    self->skip                     = LOKI_SYSTEM_DEFAULT_SKIP;
    self->wavelength               = LOKI_SYSTEM_DEFAULT_WAVELENGTH;
    self->reflections              = LOKI_SYSTEM_DEFAULT_REFLECTIONS;
    self->cavity_index             = LOKI_SYSTEM_DEFAULT_CAVITY_INDEX;
    self->distance_unit            = LOKI_SYSTEM_DEFAULT_DISTANCE_UNIT;
    self->estimator_impl           = &LOKI_SYSTEM_DEFAULT_ESTIMATOR_IMPL;
    self->estimator_throttle       = LOKI_SYSTEM_DEFAULT_ESTIMATOR_THROTTLE;
    self->estimator_initial_radius = LOKI_SYSTEM_DEFAULT_ESTIMATOR_INITIAL_RADIUS;
    self->filter_bandwidth         = LOKI_SYSTEM_DEFAULT_FILTER_BANDWIDTH;
    self->filter_attenuation       = LOKI_SYSTEM_DEFAULT_FILTER_ATTENUATION;
    self->filter_length            = LOKI_SYSTEM_DEFAULT_FILTER_LENGTH;
    self->filter_decimation        = LOKI_SYSTEM_DEFAULT_FILTER_DECIMATION;

    for (size_t i = 0; i < LEN(self->time_constants); i ++) {
        self->time_constants[i] = LOKI_SYSTEM_DEFAULT_IIR_TAU;
    }

    float estimator_params[] = LOKI_SYSTEM_DEFAULT_ESTIMATOR_PARAMS;
    self->estimator_params = calloc(self->estimator_impl->params_length, sizeof(float));
    if (!self->estimator_params) {
        LokiSystemConfig_del(self);
        return NULL;
    }
    for (size_t i = 0; i < self->estimator_impl->params_length && i < LEN(estimator_params); i ++) {
        self->estimator_params[i] = estimator_params[i];
    }

    return self;
}

void LokiSystemConfig_del(LokiSystemConfig *self) {
    if (!self) {
        return;
    }
    free(self);
}

float LokiSystemConfig_get_skip(LokiSystemConfig *self) {
    return self->skip;
}

void LokiSystemConfig_set_skip(LokiSystemConfig *self, float value) {
    self->skip = value;
}

bool LokiSystemConfig_get_simulate(LokiSystemConfig *self) {
    return self->simulate;
}

void LokiSystemConfig_set_simulate(LokiSystemConfig *self, bool value) {
    self->simulate = value;
}

float LokiSystemConfig_get_scale(LokiSystemConfig *self) {
    float w = self->wavelength;
    float d = M_PI * 4 * self->reflections * self->cavity_index;
    switch (self->distance_unit) {
        case 'p': w *=    1000; break;
        case 'u': d *=    1000; break;
        case 'm': d *= 1000000; break;
    }
    return w / d;
}

float LokiSystemConfig_get_wavelength(LokiSystemConfig *self) {
    return self->wavelength;
}

void LokiSystemConfig_set_wavelength(LokiSystemConfig *self, float value) {
    self->wavelength = value;
}

unsigned LokiSystemConfig_get_reflections(LokiSystemConfig *self) {
    return self->reflections;
}

void LokiSystemConfig_set_reflections(LokiSystemConfig *self, unsigned value) {
    self->reflections = value;
}

float LokiSystemConfig_get_cavity_index(LokiSystemConfig *self) {
    return self->cavity_index;
}

void LokiSystemConfig_set_cavity_index(LokiSystemConfig *self, float value) {
    self->cavity_index = value;
}

char LokiSystemConfig_get_distance_unit(LokiSystemConfig *self) {
    return self->distance_unit;
}

void LokiSystemConfig_set_distance_unit(LokiSystemConfig *self, char value) {
    self->distance_unit = value;
}

float *LokiSystemConfig_get_time_constants(LokiSystemConfig *self) {
	return self->time_constants;
}

size_t LokiSystemConfig_get_time_constants_length(LokiSystemConfig *self) {
    return LEN(self->time_constants);
}

void LokiSystemConfig_set_time_constants(LokiSystemConfig *self, const float *value) {
    for (size_t i = 0; i < LEN(self->time_constants); i ++) {
        self->time_constants[i] = value[i];
    }
}

const char *LokiSystemConfig_get_estimator_name(LokiSystemConfig *self) {
    for (size_t i = 0; i < LEN(LokiSystemConfig_estimator_names); i ++) {
        if (LokiSystemConfig_estimator_impls[i] == self->estimator_impl) {
            return LokiSystemConfig_estimator_names[i];
        }
    }
    return "undefined";
}

void LokiSystemConfig_set_estimator_name(LokiSystemConfig *self, const char *name) {
    for (size_t i = 0; i < LEN(LokiSystemConfig_estimator_names); i ++) {
        if (!strcmp(LokiSystemConfig_estimator_names[i], name)) {
            self->estimator_impl = LokiSystemConfig_estimator_impls[i];
            return;
        }
    }
    self->estimator_impl = NULL;
}

unsigned LokiSystemConfig_get_estimator_throttle(LokiSystemConfig *self) {
	return self->estimator_throttle;
}

void LokiSystemConfig_set_estimator_throttle(LokiSystemConfig *self, unsigned value) {
    self->estimator_throttle = value;
}

float LokiSystemConfig_get_estimator_initial_radius(LokiSystemConfig *self) {
	return self->estimator_initial_radius;
}

void LokiSystemConfig_set_estimator_initial_radius(LokiSystemConfig *self, float value) {
    self->estimator_initial_radius = value;
}

float *LokiSystemConfig_get_estimator_params(LokiSystemConfig *self) {
	return self->estimator_params;
}

size_t LokiSystemConfig_get_estimator_params_length(LokiSystemConfig *self) {
	return self->estimator_impl->params_length;
}

void LokiSystemConfig_set_estimator_params(LokiSystemConfig *self, const float *value) {
    if (self->estimator_params) {
        free(self->estimator_params);
    }
    self->estimator_params = calloc(self->estimator_impl->params_length, sizeof(float));
    if (self->estimator_params) {
        memcpy(self->estimator_params, value, self->estimator_impl->params_length * sizeof(float));
    }
}

float LokiSystemConfig_get_filter_bandwidth(LokiSystemConfig *self) {
    return self->filter_bandwidth;
}

void LokiSystemConfig_set_filter_bandwidth(LokiSystemConfig *self, float value) {
    self->filter_bandwidth = value;
}

float LokiSystemConfig_get_filter_attenuation(LokiSystemConfig *self) {
    return self->filter_attenuation;
}

void LokiSystemConfig_set_filter_attenuation(LokiSystemConfig *self, float value) {
    self->filter_attenuation = value;
}

size_t LokiSystemConfig_get_filter_length(LokiSystemConfig *self) {
    return self->filter_length;
}

void LokiSystemConfig_set_filter_length(LokiSystemConfig *self, size_t value) {
    self->filter_length = value;
}

size_t LokiSystemConfig_get_filter_decimation(LokiSystemConfig *self) {
    return self->filter_decimation;
}

void LokiSystemConfig_set_filter_decimation(LokiSystemConfig *self, size_t value) {
    self->filter_decimation = value;
}

/// Représentation d'un système d'acquisition et de traitement.
struct LokiSystem {
    /// La configuration de ce système.
    LokiSystemConfig *config;
    /// Le nombre de voies prises en charge par ce système.
    size_t channels;
    /// Ce système a-t-il construit sa propre instance de LokiModem ?
    bool has_own_modem;
    /// Le modem utilisé par ce système.
    LokiModem *modem;
    /// Un tableau de calculateurs de déplacement.
    LokiDisplacement **disp;
    /// Indicateur de demande d'arrêt de l'acquisition.
    volatile bool stop_request;
    /// Une acquisition est-elle en cours ?
    bool is_streaming;
    /// Le thread de traitement.
    pthread_t thread;
    /// La FIFO des données démodulées (alimentée par le modem).
    LokiFIFO *in;
    /// La FIFO des déplacements (alimentée par ce système).
    LokiFIFO *out;
    /// Le numéro de consommateur de ce système pour la FIFO des données démodulées.
    size_t cid;
    /// Un mutex pour gérer les accès concurrents au calculateur du déplacement.
    pthread_mutex_t mutex;
};

LokiSystem *LokiSystem_new(LokiSystemConfig *config, LokiModem *modem) {
    #ifdef DEBUG_MALLOC
        fprintf(stderr, "LokiSystem_new: Starting memory allocation monitoring\n");
        LokiHooks_init();
    #endif

    // Vérifier les paramètres de configuration.
    if (!config->estimator_impl) {
        return NULL;
    }

    LokiSystem *self = calloc(1, sizeof(LokiSystem));
    if (!self) {
        return NULL;
    }

    self->config = config;

    // Initialiser et configurer le modem
    self->has_own_modem = modem == NULL;
    self->modem = self->has_own_modem ? LokiModem_new() : modem;
    if (!self->modem) {
        LokiSystem_del(self);
        return NULL;
    }

    self->channels = LokiModem_get_demod_channels(self->modem);

    // Initialiser la chaîne de traitement du signal logiciel.
    self->disp = calloc(self->channels, sizeof(LokiDisplacement*));
    if (!self->disp) {
        LokiSystem_del(self);
        return NULL;
    }

    LokiEllipseEstimator *estimator = LokiEllipseEstimator_new_with_implementation(config->estimator_impl, config->estimator_initial_radius, config->estimator_params);
    LokiFIRFilter *filter = LokiFIRFilter_new_kaiser_bessel(LokiModem_get_demod_xy_sampling_frequency(self->modem), 0, config->filter_bandwidth, config->filter_attenuation, config->filter_length, config->filter_decimation);

    float scale = LokiSystemConfig_get_scale(config);
    float sampling_frequency = LokiModem_get_demod_xy_sampling_frequency(self->modem);

    for (size_t c = 0; c < self->channels; c ++) {
        self->disp[c] = c == 0 ?
            LokiDisplacement_new(estimator, filter, config->estimator_throttle, scale, config->time_constants, sampling_frequency) :
            LokiDisplacement_clone(self->disp[0]);
        if (!self->disp[c]) {
            LokiSystem_del(self);
            return NULL;
        }
    }

    pthread_mutex_init(&self->mutex, NULL);

    return self;
}

LokiSystemConfig *LokiSystem_get_config(const LokiSystem *self) {
    return self->config;
}

LokiModem *LokiSystem_get_modem(const LokiSystem *self) {
    return self->modem;
}

float LokiSystem_get_sampling_frequency(const LokiSystem *self) {
    return LokiModem_get_demod_xy_sampling_frequency(self->modem) / self->config->filter_decimation;
}

void LokiSystem_displacement_reset(LokiSystem *self) {
    pthread_mutex_lock(&self->mutex);
    for (size_t channel = 0; channel < self->channels; channel ++) {
        LokiDisplacement_reset(self->disp[channel]);
    }
    pthread_mutex_unlock(&self->mutex);
}

/** Calculer le déplacement à partir des données démodulées.
 *
 * Cette fonction est exécutée dans un thread démarré par #LokiSystem_start_streaming.
 * Elle consomme les données de la FIFO d'entrée et alimente la FIFO de sortie,
 * jusqu'à la demande d'arrêt par #LokiConsumer_stop.
 *
 * @param ptr Le système courant.
 * @return Rien.
 */
static void *LokiSystem_work(void *ptr) {
    LokiSystem *self = ptr;

    pthread_setname_np(self->thread, "LokiSystem");

    // La taille des buffers de données dans les FIFOs d'entrée et de sortie, en échantillons.
    const size_t in_length  = LokiPacket_get_length(self->in,  sizeof(LokiModemSample));
    const size_t out_length = LokiPacket_get_length(self->out, sizeof(LokiSystemSample));

    // Références vers le premier paquet et le premier échantillon de la FIFO des déplacements,
    // qui ne progresse pas à la même vitesse que la FIFO des échantillons du modem.
    LokiPacket *out_packet = LokiFIFO_get_producer_item(self->out);
    if (!out_packet) {
        goto LokiSystem_work_end;
    }
    LokiSystemSample *out_ptr = (LokiSystemSample*)out_packet->buffer;
    LokiSystemSample *out_end = out_ptr + out_length;

    // Calculer la durée d'un paquet d'entrée, en nanosecondes.
    const size_t channels = self->channels;
    double in_period_ns = 1.0e9 * in_length / channels / LokiModem_get_demod_xy_sampling_frequency(self->modem);

    // Préparer un tableau avec l'indice de l'échantillon courant pour chaque voie.
    uint64_t skip = self->config->skip * LokiSystem_get_sampling_frequency(self);
    uint64_t *sample_index = calloc(channels, sizeof(uint64_t));
    if (!sample_index) {
        goto LokiSystem_work_end;
    }

    // Préparer des tableaux pour mémoriser les points de l'ellipse normalisée.
    const size_t decimation = self->config->filter_decimation;
    float *xy_norm = calloc(channels * decimation * 2, sizeof(float));
    if (!xy_norm) {
        goto LokiSystem_work_end;
    }
    float **xy_start = calloc(channels * 4, sizeof(float*));
    if (!xy_start) {
        goto LokiSystem_work_end;
    }

    float **xy_end   = xy_start + channels;
    float **xy_read  = xy_start + channels * 2;
    float **xy_write = xy_start + channels * 3;
    for (size_t c = 0; c < channels; c ++) {
        xy_start[c] = xy_read[c] = xy_write[c] = xy_norm + (c * decimation * 2);
        xy_end[c]   = xy_start[c] + (decimation * 2);
    }

    while (!self->stop_request) {
        LokiPacket *in_packet = LokiFIFO_get_consumer_item(self->in, self->cid);
        if (!in_packet) {
            break;
        }
        LokiModemSample *in_ptr = (LokiModemSample*)in_packet->buffer;
        const LokiModemSample *const in_end = in_ptr + in_length;

        // En commençant un nouveau paquet de sortie, copier la date du paquet d'entrée.
        if (out_ptr == (LokiSystemSample*)out_packet->buffer) {
            out_packet->timestamp = in_packet->timestamp;
        }

        // Calculer les déplacements, remplir les FIFO de sortie.
        while (in_ptr != in_end && !self->stop_request) {
            LokiModemSample in = *in_ptr ++;

            if (in.channel >= channels) {
                continue;
            }

            pthread_mutex_lock(&self->mutex);
            float d;
            bool has_disp = LokiDisplacement_work(self->disp[in.channel], in.x, in.y, xy_write[in.channel], xy_write[in.channel] + 1, &d);
            pthread_mutex_unlock(&self->mutex);

            xy_write[in.channel] += 2;
            if (xy_write[in.channel] == xy_end[in.channel]) {
                xy_write[in.channel] = xy_start[in.channel];
            }

            if (has_disp) {
                sample_index[in.channel] ++;

                // Ne pas remplir le buffer de sortie tant que le nombre
                // d'échantillons à omettre n'est pas atteint.
                if (sample_index[in.channel] < skip) {
                    continue;
                }

                // Remettre à zéro le déplacement courant avant d'enregistrer.
                if (sample_index[in.channel] == skip) {
                    LokiDisplacement_reset(self->disp[in.channel]);
                    d = 0;
                }

                *out_ptr ++ = (LokiSystemSample) {
                    .channel = in.channel,
                    .value   = d,
                    .x_norm  = xy_read[in.channel][0],
                    .y_norm  = xy_read[in.channel][1]
                };

                xy_read[in.channel] += 2;
                if (xy_read[in.channel] == xy_end[in.channel]) {
                    xy_read[in.channel] = xy_start[in.channel];
                }

                if (out_ptr == out_end) {
                    LokiFIFO_push(self->out);
                    out_packet = LokiFIFO_get_producer_item(self->out);
                    if (!out_packet) {
                        goto LokiSystem_work_end;
                    }
                    if (in_ptr != in_end) {
                        out_packet->timestamp = in_packet->timestamp + round(in_period_ns * (in_ptr - (LokiModemSample*)in_packet->buffer) / in_length);
                    }
                    out_ptr = (LokiSystemSample*)out_packet->buffer;
                    out_end = out_ptr + out_length;
                }
            }
        }

        LokiFIFO_pull(self->in, self->cid);
    }

LokiSystem_work_end:
    LokiModem_stop_streaming(self->modem);

    if (self->stop_request) {
        fprintf(stderr, "LokiSystem_work: complete\n");
    }
    else {
        fprintf(stderr, "LokiSystem_work: aborted\n");
    }

    if (sample_index) {
        free(sample_index);
    }
    if (xy_norm) {
        free(xy_norm);
    }
    if (xy_start) {
        free(xy_start);
    }

    self->is_streaming = false;
}

int LokiSystem_start_streaming(LokiSystem *self, int32_t channels, LokiFIFO *modem_out, LokiFIFO *disp_out, size_t cid) {
    if (self->is_streaming) {
        return EBUSY;
    }

    self->in = modem_out;
    self->cid = cid;
    self->out = disp_out;
    self->stop_request = false;
    self->is_streaming = true;

    if (disp_out) {
        int err = pthread_create(&self->thread, NULL, LokiSystem_work, self);
        if (err) {
            return err;
        }
    }

    LokiModem_restart(self->modem);

    return LokiModem_start_streaming(self->modem, channels, self->config->simulate, false, modem_out);
}

void LokiSystem_stop_streaming(LokiSystem *self) {
    if (self->stop_request) {
        return;
    }
    self->stop_request = true;
    if (self->out) {
        LokiFIFO_abort(self->in);
        LokiFIFO_abort(self->out);
        pthread_join(self->thread, NULL);
    }
    // Si le thread n'a pas été démarré, il faut
    // désactiver cet indicateur ici.
    self->is_streaming = false;
}

bool LokiSystem_is_streaming(LokiSystem *self) {
    return self->is_streaming;
}

LokiEllipse *LokiSystem_get_ellipse(LokiSystem *self, size_t channel) {
    return LokiDisplacement_get_ellipse(self->disp[channel]);
}

void LokiSystem_del(LokiSystem *self) {
    if (!self) {
        return;
    }

    if (self->has_own_modem) {
        LokiModem_del(self->modem);
    }

    // Les instances de LokiEllipseEstimator et LokiFIRFilter créées dans le
    // constructeur sont détruites par LokiDisplacement_del pour c == 0.
    if (self->disp) {
        for (size_t c = 0; c < self->channels; c ++) {
            LokiDisplacement_del(self->disp[c]);
        }
        free(self->disp);
    }

    free(self);
}

/// @file libloki-system.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
