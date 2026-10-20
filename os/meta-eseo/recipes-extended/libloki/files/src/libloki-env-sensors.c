
// TODO Ajouter les sources XADC et capteur de température I2C

/// Permettre l'utilisation de la fonction `pthread_setname_np` pour modifier le nom d'un thread.
#define _GNU_SOURCE

#include <math.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include <loki-env-sensors-regs.h>
#include <loki-device-ioctl.h>
#include "libloki.h"

/// @addtogroup gLokiEnvSensors
/// @{

/// Représentation de l'interface d'acquisition des capteurs auxiliaires.
struct LokiEnvSensors {
    /// Le fichier représentant le périphérique qui gère les capteurs.
    FILE *file;
    /// Le numéro du fichier représentant le périphérique qui gère les capteurs.
    int fileno;
    /// Indicateur de demande d'arrêt d'acquisition.
    volatile bool stop_request;
    /// La FIFO de sortie de ce module d'acquisition.
    LokiFIFO *out;
    /// Conserver les données brutes (entiers sans mise à l'échelle).
    bool raw;
    /// Un masque indiquant les voies à traiter, -1 pour toutes les voies.
    int32_t stream_channels;
    /// Le thread démarré par LokiEnvSensors_start_streaming.
    pthread_t thread;
    /// La fréquence d'horloge du circuit d'acquisition.
    uint32_t clk_frequency;
    /// Le nombre de voies supportées par le circuit d'acquisition.
    uint32_t channels;
    /// Le nombre maximal de cycles d'horloge par échantillon.
    uint32_t cycles_per_sample_max;
    /// Le nombre de bits représentant le numéro de voie dans un échantillon brut.
    uint32_t channel_output_width;
    /// Le nombre de bits de données dans un échantillon brut.
    uint32_t data_width;
    /// Le masque binaire permettant d'isoler le numéro de voie dans un échantillon brut.
    uint32_t channel_mask;
    /// Le masque binaire permettant d'isoler la valeur d'un échantillon brut.
    uint32_t data_mask;
    /// Le masque binaire permettant d'isoler le bit de signe de la valeur d'un échantillon brut.
    uint32_t data_sign_mask;
    /// La dernière valeur de température lue sur le capteur BMP390 après compensation.
    int64_t bmp390_t_fine;
    /// Le tableau des facteurs d'échelle à appliquer à chaque voie.
    float *scales;
};

/// Le type de donnée brut d'un échantillon passé par transfert DMA.
typedef uint32_t LokiDMASample;

/** Lire un registre du circuit d'acquisition.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le circuit
 * d'acquisition à travers le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 * @param reg Le numéro du registre à lire.
 * @return La valeur du registre.
 */
static inline uint32_t LokiEnvSensors_get_reg(const LokiEnvSensors* self, LokiEnvSensorsRegister reg) {
    LokiRegisterQuery query = {.reg = reg};
    int err = ioctl(self->fileno, LOKI_IOCTL_REG_READ, &query);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_get_reg: ioctl returned %d\n", err);
        return 0;
    }
    return query.value;
}

/** Affecter un registre du circuit d'acquisition.
 *
 * Cette fonction utilise la fonction `ioctl` pour agir sur le circuit
 * d'acquisition à travers le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 * @param reg Le numéro du registre à modifier.
 * @param value La nouvelle valeur du registre.
 */
static inline void LokiEnvSensors_set_reg(const LokiEnvSensors* self, LokiEnvSensorsRegister reg, uint32_t value) {
    LokiRegisterQuery query = {.reg = reg, .value = value};
    int err = ioctl(self->fileno, LOKI_IOCTL_REG_WRITE, &query);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_set_reg: ioctl returned %d\n", err);
    }
}

/** Demander au circuit d'acquisition de démarrer les transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour agir sur le circuit
 * d'acquisition à travers le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 */
static inline void LokiEnvSensors_dma_start(const LokiEnvSensors *self) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_START);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_dma_start: ioctl returned %d\n", err);
    }
}

/** Demander au circuit d'acquisition d'arrêter les transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour agir sur le circuit
 * d'acquisition à travers le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 */
static inline void LokiEnvSensors_dma_stop(const LokiEnvSensors *self) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_STOP);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_dma_stop: ioctl returned %d\n", err);
    }
}

/** Lire l'état des transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 */
static inline bool LokiEnvSensors_dma_is_streaming(const LokiEnvSensors *self) {
    bool res;
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_IS_STREAMING, &res);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_dma_is_streaming: ioctl returned %d\n", err);
        return false;
    }
    return res;
}

/** Lire la date de démarrage des transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 * @param res Un pointeur vers le résultat.
 */
static inline void LokiEnvSensors_dma_get_start_time(const LokiEnvSensors *self, struct timespec *res) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_START_TIME, res);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_dma_get_start_time: ioctl returned %d\n", err);
    }
}

/** Lire la date du dernier transfert DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-env-sensors`.
 *
 * @param self Le module d'acquisition courant.
 * @param res Un pointeur vers le résultat.
 */
static inline void LokiEnvSensors_dma_get_packet_time(const LokiEnvSensors *self, struct timespec *res) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_PACKET_TIME, res);
    if (err) {
        fprintf(stderr, "LokiEnvSensors_dma_get_packet_time: ioctl returned %d\n", err);
    }
}

// Adapté de : https://github.com/hepingood/bmp390
static int32_t LokiEnvSensors_bmp390_compensate_temperature(LokiEnvSensors *self, uint32_t data) { 
    uint32_t nvm_reg0 = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_BMP390_NVM0);
    uint32_t nvm_reg1 = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_BMP390_NVM1);

    uint16_t t1 = nvm_reg0 >> 16;
    uint16_t t2 = nvm_reg0;
    int8_t   t3 = nvm_reg1;

    uint64_t partial_data1 = (uint64_t)data - (uint64_t)t1 * 256;
    int64_t partial_data2 = t2 * partial_data1;
    int64_t partial_data3 = partial_data1 * partial_data1;
    int64_t partial_data4 = partial_data3 * t3;
    int64_t partial_data5 = partial_data2 * 262144 + partial_data4;
    int64_t partial_data6 = partial_data5 / 4294967296U;
    self->bmp390_t_fine = partial_data6;
    return partial_data6 * 25 / 16384;
}

// Adapté de : https://github.com/hepingood/bmp390
static int32_t LokiEnvSensors_bmp390_compensate_pressure(const LokiEnvSensors *self, uint32_t data) {
    uint32_t nvm_reg2 = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_BMP390_NVM2);
    uint32_t nvm_reg3 = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_BMP390_NVM3);
    uint32_t nvm_reg4 = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_BMP390_NVM4);
    uint32_t nvm_reg5 = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_BMP390_NVM5);

    int16_t  p1  = nvm_reg2 >> 16;
    int16_t  p2  = nvm_reg2;
    int8_t   p3  = nvm_reg3 >> 24;
    int8_t   p4  = nvm_reg3 >> 16;
    uint16_t p5  = nvm_reg3;
    uint16_t p6  = nvm_reg4 >> 16;
    int8_t   p7  = nvm_reg4 >> 8;
    int8_t   p8  = nvm_reg4;
    int16_t  p9  = nvm_reg5 >> 16;
    int8_t   p10 = nvm_reg5 >> 8;
    int8_t   p11 = nvm_reg5;

    int64_t t_fine = self->bmp390_t_fine;
    int64_t partial_data1 = t_fine * t_fine;
    int64_t partial_data2 = partial_data1 / 64;
    int64_t partial_data3 = partial_data2 * t_fine / 256;
    int64_t partial_data4 = p8 * partial_data3 / 32;
    int64_t partial_data5 = p7 * partial_data1 * 16;
    int64_t partial_data6 = p6 * t_fine * 4194304;
    int64_t offset = (int64_t)p5 * (int64_t)140737488355328U + partial_data4 + partial_data5 + partial_data6;
    partial_data2 = (int64_t)p4 * partial_data3 / 32;
    partial_data4 = p3 * partial_data1 * 4;
    partial_data5 = ((int64_t)p2 - 16384) * t_fine * 2097152;
    int64_t sensitivity = ((int64_t)p1 - 16384) * (int64_t)70368744177664U + partial_data2 + partial_data4 + partial_data5;
    partial_data1 = sensitivity / 16777216 * data;
    partial_data2 = (int64_t)p10 * t_fine;
    partial_data3 = partial_data2 + 65536 * (int64_t)p9;
    partial_data4 = partial_data3 * data / 8192;
    partial_data5 = partial_data4 * data / 512;
    partial_data6 = (uint64_t)data * (uint64_t)data;
    partial_data2 = (int64_t)p11 * partial_data6 / 65536;
    partial_data3 = partial_data2 * data / 128;
    partial_data4 = offset / 4 + partial_data1 + partial_data5 + partial_data3;
    return (uint64_t)partial_data4 * 25 / 1099511627776U;
}

LokiEnvSensors *LokiEnvSensors_new(void) {
    LokiEnvSensors *self = calloc(1, sizeof(LokiEnvSensors));
    if (!self) {
        return NULL;
    }

    self->file = fopen("/dev/loki-env-sensors", "r");
    if (!self->file) {
        LokiEnvSensors_del(self);
        return NULL;
    }

    self->fileno = fileno(self->file);

    self->clk_frequency         = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_CLK_FREQUENCY);
    self->channels              = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_CHANNELS);
    self->channel_output_width  = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_CHANNEL_OUTPUT_WIDTH);
    self->data_width            = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_DATA_WIDTH);
    self->cycles_per_sample_max = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_CYCLES_PER_SAMPLE_MAX);
    self->channel_mask          = (1 << self->channel_output_width) - 1;
    self->data_mask             = (1 << self->data_width) - 1;
    self->data_sign_mask        = 1 << (self->data_width - 1);

    // Allouer un tableau pour les facteurs de mise à l'échelle,
    // et les initialiser à 1.
    self->scales = calloc(self->channels, sizeof(float));
    if (!self->scales) {
        LokiEnvSensors_del(self);
        return NULL;
    }

    for (size_t i = 0; i < self->channels; i ++) {
        self->scales[i] = 1.0f;
    }

    // Le nombre d'octets d'un transfert DMA doit être multiple de
    // * la taille d'une page mémoire
    // * la taille d'un échantillon
    uint32_t page_size = getpagesize();
    uint32_t a         = page_size;
    uint32_t b         = sizeof(LokiDMASample);
    while (a != b) {
        if (a > b) {
            a -= b;
        }
        if (b > a) {
            b -= a;
        }
    }

    LokiEnvSensors_set_reg(self, LOKI_ENV_SENSORS_REG_PACKET_LENGTH, page_size / a);

    return self;
}

void LokiEnvSensors_del(LokiEnvSensors *self) {
    if (!self) {
        return;
    }

    if (self->file) {
        fclose(self->file);
    }

    if (self->scales) {
        free(self->scales);
    }

    free(self);
}

void LokiEnvSensors_restart(const LokiEnvSensors *self) {
    uint32_t value = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_CONTROL);
    value |= LOKI_ENV_SENSORS_REG_CONTROL_RESTART_SHIFTED_MASK;
    LokiEnvSensors_set_reg(self, LOKI_ENV_SENSORS_REG_CONTROL, value);
}

uint32_t LokiEnvSensors_get_clk_frequency(const LokiEnvSensors *self) {
    return self->clk_frequency;
}

size_t LokiEnvSensors_get_channels(const LokiEnvSensors *self) {
    return self->channels;
}

float LokiEnvSensors_get_sampling_frequency(const LokiEnvSensors *self) {
    return (float)self->clk_frequency / LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_CYCLES_PER_SAMPLE);
}

void LokiEnvSensors_set_sampling_frequency(const LokiEnvSensors *self, float freq) {
    LokiEnvSensors_set_reg(self, LOKI_ENV_SENSORS_REG_CYCLES_PER_SAMPLE, roundf((float)self->clk_frequency / freq));
}

uint32_t LokiEnvSensors_get_packet_length_max(const LokiEnvSensors *self) {
    return LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_PACKET_LENGTH_MAX);
}

uint32_t LokiEnvSensors_get_packet_length(const LokiEnvSensors *self) {
    return LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_PACKET_LENGTH);
}

float LokiEnvSensors_get_scaling_factor(const LokiEnvSensors *self, size_t channel) {
    return self->scales[channel];
}

void LokiEnvSensors_set_scaling_factor(LokiEnvSensors *self, size_t channel, float scale) {
    self->scales[channel] = scale;
}

float LokiEnvSensors_get_last_data(const LokiEnvSensors *self, size_t channel) {
    int32_t value;
    if (channel < self->channels - 2) {
        value = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_LAST_DATA + channel);
    }
    else {
        uint32_t t_raw = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_LAST_DATA + self->channels - 2);
        value = LokiEnvSensors_bmp390_compensate_temperature(self, t_raw);
        if (channel == self->channels - 1) {
            uint32_t p_raw = LokiEnvSensors_get_reg(self, LOKI_ENV_SENSORS_REG_LAST_DATA + channel);
            value = LokiEnvSensors_bmp390_compensate_pressure(self, p_raw);
        }
    }
    return self->scales[channel] * value;
}

/** Lire l'indice d'un paquet reçu.
 *
 * Cette fonction extrait d'un échantillon brut le champ contenant l'indice du paquet.
 *
 * @param self Le module d'acquisition courant.
 * @param raw_item Un échantillon obtenu lors d'un transfert DMA.
 * @return L'indice du paquet contenant cet échantillon.
 */
static inline uint32_t LokiEnvSensors_get_packet_index(const LokiEnvSensors *self, LokiDMASample raw_item) {
    return raw_item >> (self->data_width + self->channel_output_width);
}

/** Convertir un échantillon issu du DMA.
 *
 * Cette fonction extrait les champs contenant le numéro de voie et la valeur
 * de l'échantillon.
 * Elle convertit la valeur en lui appliquant un facteur d'échelle.
 *
 * @param self Le module d'acquisition courant.
 * @param item Un pointeur vers une structure qui contiendra le résultat.
 * @param raw_item Un échantillon obtenu lors d'un transfert DMA.
 */
static void LokiEnvSensors_set_packet_item(const LokiEnvSensors *self, LokiEnvSensorsSample *item, LokiDMASample raw_item) {
    // Lire la valeur de l'échantillon, alignée à droite en complément à deux.
    int32_t data_raw = raw_item & self->data_mask;
    raw_item >>= self->data_width;

    // Lire le numéro de la voie.
    item->channel = raw_item & self->channel_mask;

    // BMP390 : effectuer la compensation des mesures de température et de pression.
    // Autres voies: effectuer l'extension du bit de signe.
    if (item->channel == self->channels - 2) {
        data_raw = LokiEnvSensors_bmp390_compensate_temperature(self, data_raw);
    }
    else if (item->channel == self->channels - 1) {
        data_raw = LokiEnvSensors_bmp390_compensate_pressure(self, data_raw);
    }
    else if (data_raw & self->data_sign_mask) {
        data_raw |= ~self->data_mask;
    }

    // Convertir les coordonnées en flottants si nécessaire.
    if (self->raw) {
        item->data_raw = data_raw;
    }
    else {
        item->data = self->scales[item->channel] * data_raw;
    }
}

/** Utiliser la fonction `mmap` pour accéder aux données DMA.
 *
 * Commenter cette ligne pour utiliser `fread`.
 */
#define USE_MMAP

/** Traiter un tableau d'échantillons issu d'un transfert DMA.
 *
 * Cette fonction est exécutée dans un thread démarré par #LokiEnvSensors_start_streaming.
 * Elle se termine lorsqu'une demande d'arrêt est émise par #LokiEnvSensors_stop_streaming.
 *
 * Si la constante `USE_MMAP` est définie, elle s'appuie sur la fonction `mmap`
 * pour se synchroniser avec le pilote du circuit modem et accéder au tampon de
 * données de chaque transfert en mode *zero-copy*.
 * Si la constante `USE_MMAP` n'est pas définie, la fonction `fread` est utilisée.
 *
 * Cette fonction remplit la FIFO de sortie avec des paquets d'échantillons
 * convertis par la fonction #LokiEnvSensors_set_packet_item.
 *
 * @param ptr Le module d'acquisition courant.
 * @return Rien.
 */
static void *LokiEnvSensors_work(void *ptr) {
    LokiEnvSensors *self = ptr;

    pthread_setname_np(self->thread, "LokiEnvSensors");

    // Obtenir un pointeur vers le buffer courant des échantillons mise en forme.
    const size_t out_length = LokiPacket_get_length(self->out, sizeof(LokiEnvSensorsSample));
    LokiPacket *out_packet  = LokiFIFO_get_producer_item(self->out);
    if (!out_packet) {
        return NULL;
    }
    LokiEnvSensorsSample *out_ptr = (LokiEnvSensorsSample*)out_packet->buffer;
    LokiEnvSensorsSample *out_end = out_ptr + out_length;

    // Avec la fonction fread, allouer un buffer de données.
    // Avec l'accès par mmap, le buffer est fourni par le pilote.
    const size_t in_length = LokiEnvSensors_get_packet_length(self);
    #ifndef USE_MMAP
        LokiDMASample *in_buffer = calloc(in_length, sizeof(LokiDMASample));
        LokiDMASample *in_end    = in_buffer + in_length;
    #else
        size_t in_length_bytes = in_length * sizeof(LokiDMASample);
    #endif

    // Calculer la durée moyenne d'un paquet d'entrée, en nanosecondes.
    double in_period_ns = 1.0e9 * in_length / self->channels / LokiEnvSensors_get_sampling_frequency(self);

    // Calculer le modulo du compteur de paquets du FPGA.
    uint32_t packet_count_mod = 1 << (sizeof(LokiDMASample) * 8 - self->channel_output_width - self->data_width);

    bool first_packet = true;
    uint32_t packet_index_prev = 0;
    LokiTimestamp in_timestamp;

    // Démarrer l'acquisition.
    LokiEnvSensors_dma_start(self);

    while (!self->stop_request) {
        // Lire un buffer d'échantillons en provenance du DMA.
        #ifndef USE_MMAP
            if (fread(in_buffer, sizeof(LokiDMASample), in_length, self->file) != in_length) {
                fprintf(stderr, "LokiEnvSensors_work: read failed (error: %d, %s)\n", errno, strerror(errno));
                break;
            }
        #else
            // Accès au buffer DMA en mode zero-copy.
            // Contrairement à l'acquisition des voies optiques, l'appel à mmap
            // peut bloquer le processus pendant une longue durée.
            // On utilise le timeout pour le débloquer jusqu'au succès.
            LokiDMASample *in_buffer;
            do {
                in_buffer = mmap(NULL, in_length_bytes, PROT_READ, MAP_PRIVATE, self->fileno, 0);
            } while (in_buffer == MAP_FAILED && errno == ETIMEDOUT);

            if (in_buffer == MAP_FAILED) {
                fprintf(stderr, "LokiEnvSensors_work: mmap failed (error: %d, %s)\n", errno, strerror(errno));
                break;
            }

            LokiDMASample *in_end = in_buffer + in_length;
        #endif

        // Attendre le paquet numéro 0 pour commencer.
        uint32_t packet_index = LokiEnvSensors_get_packet_index(self, *in_buffer);

        // Prendre pour référence temporelle la date du premier paquet.
        // Les dates des autres paquets seront calculées en fonction du nombre d'échantillons.
        if (first_packet && !packet_index) {
            struct timespec ts;
            LokiEnvSensors_dma_get_packet_time(self, &ts);
            in_timestamp = LokiTime_to_timestamp(ts) - in_period_ns;
        }

        if (!first_packet || !packet_index) {
            // Calculer le timestamp du paquet d'entrée, en nanosecondes,
            // en utilisant le numéro de paquet fourni par le FPGA.
            int32_t packet_interval = packet_index - packet_index_prev;
            if (packet_interval < 0) {
                fprintf(stderr, "LokiEnvSensors_work: packet index rollover (%u).\n", packet_index);
                packet_interval += packet_count_mod;
            }

            if (packet_interval > 1) {
                fprintf(stderr, "LokiEnvSensors_work: packet index gap (%u -> %u, %u).\n", packet_index_prev, packet_index, packet_interval);
                //goto LokiEnvSensors_work_continue;
            }

            packet_index_prev = packet_index;
            first_packet = false;

            in_timestamp += round(in_period_ns * packet_interval);

            // En commençant un nouveau paquet de sortie, copier la date du paquet d'entrée.
            if (out_ptr == (LokiEnvSensorsSample*)out_packet->buffer) {
                out_packet->timestamp = in_timestamp;
            }

            LokiDMASample *in_ptr = in_buffer;
            while (in_ptr != in_end && !self->stop_request) {
                LokiDMASample in = *in_ptr ++;

                LokiEnvSensorsSample s;
                LokiEnvSensors_set_packet_item(self, &s, in);

                if (self->stream_channels & (1 << s.channel)) {
                    *out_ptr ++ = s;

                    if (out_ptr == out_end) {
                        LokiFIFO_push(self->out);
                        out_packet = LokiFIFO_get_producer_item(self->out);
                        if (!out_packet) {
                            break;
                        }
                        if (in_ptr != in_end) {
                            out_packet->timestamp = in_timestamp + round(in_period_ns * (in_ptr - in_buffer) / in_length);
                        }
                        out_ptr = (LokiEnvSensorsSample*)out_packet->buffer;
                        out_end = out_ptr + out_length;
                    }
                }
            }
        }

    LokiEnvSensors_work_continue:
        #ifdef USE_MMAP
            munmap(in_buffer, in_length_bytes);
        #endif
    }

    #ifndef USE_MMAP
        free(in_buffer);
    #endif

    LokiEnvSensors_dma_stop(self);
}

int LokiEnvSensors_start_streaming(LokiEnvSensors *self, int32_t channels, bool raw, LokiFIFO *out) {
    if (LokiEnvSensors_dma_is_streaming(self)) {
        return EBUSY;
    }
    self->stop_request    = false;
    self->out             = out;
    self->raw             = raw;
    self->stream_channels = channels;
    return pthread_create(&self->thread, NULL, LokiEnvSensors_work, self);
}

void LokiEnvSensors_stop_streaming(LokiEnvSensors *self) {
    if (self->stop_request) {
        return;
    }
    self->stop_request = true;
    LokiFIFO_abort(self->out);
    pthread_join(self->thread, NULL);
}

void LokiEnvSensors_force_stop(const LokiEnvSensors *self) {
    LokiEnvSensors_dma_stop(self);
}

bool LokiEnvSensors_is_streaming(const LokiEnvSensors *self) {
    return LokiEnvSensors_dma_is_streaming(self);
}

/// @file libloki-env-sensors.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
