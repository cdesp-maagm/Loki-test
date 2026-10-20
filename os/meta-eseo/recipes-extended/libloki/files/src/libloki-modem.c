
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

#include <loki-modem-regs.h>
#include <loki-device-ioctl.h>
#include "libloki.h"

/// @addtogroup gLokiModem
/// @{

/// Représentation des périphériques modulateur et démodulateur.
struct LokiModem {
    /// Le fichier représentant le périphérique qui gère le modem.
    FILE *file;
    /// Le numéro du fichier représentant le périphérique qui gère le modem.
    int fileno;
    /// Indicateur de demande d'arrêt d'acquisition.
    volatile bool stop_request;
    /// La FIFO de sortie des données démodulées.
    LokiFIFO *out;
    /// Conserver les données démodulées brutes (entiers sans mise à l'échelle).
    bool raw;
    /// Un masque indiquant les voies à traiter, -1 pour toutes les voies.
    int32_t stream_channels;
    /// Le thread démarré par LokiModem_start_streaming.
    pthread_t thread;
    /// Faut-il simuler les capteurs logiciellement ?
    bool simulate;
    /// Le numéro de la voie courante pendant une simulation logicielle des capteurs.
    uint32_t sim_channel;
    /// La phase courante du déplacement fictif pendant une simulation logicielle des capteurs.
    float sim_osc1_phase;
    /// La phase courante correspondant au déplacement réel pendant une simulation logicielle des capteurs.
    float sim_disp_phase;
    /// La fréquence d'horloge du circuit modem.
    uint32_t clk_frequency;
    /// La fréquence d'échantillonnage de référence en sortie du modulateur.
    uint32_t mod_sample_frequency_ref;
    /// Le nombre maximal de périodes d'horloge par échantillon en sortie du modulateur.
    uint32_t mod_cycles_per_sample_max;
    /// Le nombre de périodes d'horloge de référence par échantillon en sortie du modulateur.
    float mod_cycles_per_sample_ref;
    /// La fréquence minimale du premier oscillateur du modulateur pour la fréquence d'échantillonnage de référence, en Hz.
    uint32_t mod_osc1_wave_frequency_min;
    /// La fréquence minimale du second oscillateur du modulateur pour la fréquence d'échantillonnage de référence, en Hz.
    uint32_t mod_osc2_wave_frequency_min;
    /// Le nombre de bits de la partie entière de l'amplitude de sortie du modulateur.
    uint32_t mod_gain_integer_width;
    /// Le nombre de bits de la partie fractionnaire de l'amplitude de sortie du modulateur.
    uint32_t mod_gain_fractional_width;
    /// La résolution du réglage d'amplitude en sortie du modulateur.
    float mod_gain_res;
    /// L'amplitude maximale de sortie du modulateur, en mA.
    float mod_phase_amplitude_max;
    /// Le nombre de bits de la partie entière de la valeur de sortie du modulateur.
    uint32_t mod_phase_integer_width;
    /// Le nombre de bits de la partie fractionnaire de la valeur de sortie du modulateur.
    uint32_t mod_phase_fractional_width;
    /// La résolution du réglage d'offset en sortie du modulateur.
    float mod_offset_res;
    /// Le courant moyen maximal applicable en sortie du modulateur.
    float mod_dc_value_max;
    /// Le nombre de bits pour représenter le courant moyen en sortie du modulateur.
    uint32_t mod_dc_value_width;
    /// La résolution du réglage du courant moyen en sortie du modulateur.
    float mod_dc_value_res;
    /// Le nombre de bits pour représenter le gain de l'amplificateur de sortie du modulateur.
    uint32_t mod_pga_gain_width;
    /// Le gain maximal de l'amplificateur en sortie du modulateur.
    uint32_t mod_pga_gain_max;
    /// Le démodulateur fonctionne-t-il par décimation ?
    bool demod_mixerless;
    /// Le nombre de voies d'entrée du démodulateur.
    uint32_t demod_channels;
    /// Le nombre de bits pour représenter le numéro de voie dans un échantillon brut produit par le démodulateur.
    uint32_t demod_channel_output_width;
    /// Le masque binaire pour lire le numéro de voie dans un échantillon démodulé.
    uint32_t demod_channel_mask;
    /// Le nombre de bits de la partie entière des échantillons en entrée du démodulateur.
    uint32_t demod_power_integer_width;
    /// Le nombre de bits de la partie fractionnaire des échantillons en entrée du démodulateur.
    uint32_t demod_power_fractional_width;
    /// La valeur maximale des échantillons en entrée du démodulateur.
    float demod_power_max;
    /// La fréquence d'échantillonnage de référence en entrée du démodulateur.
    uint32_t demod_sample_frequency_ref;
    /// Le nombre maximal de périodes d'horloge par échantillon en entrée du démodulateur.
    uint32_t demod_cycles_per_sample_max;
    /// Le nombre de périodes d'horloge de référence par échantillon en entrée du démodulateur.
    float demod_cycles_per_sample_ref;
    /// La fréquence minimale de l'oscillateur du démodulateur pour la fréquence d'échantillonnage de référence, en Hz.
    uint32_t demod_osc_wave_frequency_min;
    /// Le facteur de décimation du premier étage de filtrage dans le démodulateur.
    uint32_t demod_fir1_decimation;
    /// Le nombre de coefficients du premier étage de filtrage dans le démodulateur.
    uint32_t demod_fir1_length;
    /// Le facteur de décimation du second étage de filtrage dans le démodulateur.
    uint32_t demod_fir2_decimation;
    /// Le nombre de coefficients du second étage de filtrage dans le démodulateur.
    uint32_t demod_fir2_length;
    /// La bande passante de sortie du second étage de filtrage dans le démodulateur.
    uint32_t demod_fir2_bandwidth;
    /// Le nombre de bits de la partie entière des échantillons de chaque composante X (I) ou Y (Q) du signal démodulé.
    uint32_t demod_xy_integer_width;
    /// Le nombre de bits de la partie fractionnaire des échantillons de chaque composante X (I) ou Y (Q) du signal démodulé.
    uint32_t demod_xy_fractional_width;
    /// Le nombre total de bits d'un échantillon de chaque composante X (I) ou Y (Q) du signal démodulé.
    uint32_t demod_xy_width;
    /// Le masque binaire pour lire une composante X (I) ou Y (Q) d'un échantillon du signal démodulé.
    uint32_t demod_xy_mask;
    /// Le masque binaire pour lire le bit de signe d'une composante X (I) ou Y (Q) d'un échantillon du signal démodulé.
    uint32_t demod_xy_sign_mask;
    /// La valeur maximale d'un échantillon pour une composante X (I) ou Y (Q) du signal démodulé.
    float demod_xy_max;
};

/// Le type brut d'un échantillon démodulé transféré par DMA.
typedef uint64_t LokiDMASample;

/** Lire un registre du circuit de modulation/démodulation.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le circuit
 * modem à travers le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 * @param reg Le numéro du registre à lire.
 * @return La valeur du registre.
 */
static inline uint32_t LokiModem_get_reg(const LokiModem *self, LokiModemRegister reg) {
    LokiRegisterQuery query = {.reg = reg};
    int err = ioctl(self->fileno, LOKI_IOCTL_REG_READ, &query);
    if (err) {
        fprintf(stderr, "LokiModem_get_reg: ioctl returned %d\n", err);
        return 0;
    }
    return query.value;
}

/** Affecter un registre du circuit de modulation/démodulation.
 *
 * Cette fonction utilise la fonction `ioctl` pour agir sur le circuit
 * modem d'acquisition à travers le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 * @param reg Le numéro du registre à modifier.
 * @param value La nouvelle valeur du registre.
 */
static inline void LokiModem_set_reg(const LokiModem *self, LokiModemRegister reg, uint32_t value) {
    LokiRegisterQuery query = {.reg = reg, .value = value};
    int err = ioctl(self->fileno, LOKI_IOCTL_REG_WRITE, &query);
    if (err) {
        fprintf(stderr, "LokiModem_set_reg: ioctl returned %d\n", err);
    }
}

/** Demander au circuit de modulation/démodulation de démarrer les transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour agir sur le circuit
 * modem à travers le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 */
static inline void LokiModem_dma_start(const LokiModem *self) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_START);
    if (err) {
        fprintf(stderr, "LokiModem_dma_start: ioctl returned %d\n", err);
    }
}

/** Demander au circuit de modulation/démodulation d'arrêter les transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour agir sur le circuit
 * modem à travers le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 */
static inline void LokiModem_dma_stop(const LokiModem *self) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_STOP);
    if (err) {
        fprintf(stderr, "LokiModem_dma_stop: ioctl returned %d\n", err);
    }
}

/** Lire l'état des transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 */
static inline bool LokiModem_dma_is_streaming(const LokiModem *self) {
    bool res;
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_IS_STREAMING, &res);
    if (err) {
        fprintf(stderr, "LokiModem_dma_is_streaming: ioctl returned %d\n", err);
        return false;
    }
    return res;
}

/** Lire la date de démarrage des transferts DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 * @param res Un pointeur vers le résultat.
 */
static inline void LokiModem_dma_get_start_time(const LokiModem *self, struct timespec *res) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_START_TIME, res);
    if (err) {
        fprintf(stderr, "LokiModem_dma_get_start_time: ioctl returned %d\n", err);
    }
}

/** Lire la date du dernier transfert DMA.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 * @param res Un pointeur vers le résultat.
 */
static inline void LokiModem_dma_get_packet_time(const LokiModem *self, struct timespec *res) {
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_PACKET_TIME, res);
    if (err) {
        fprintf(stderr, "LokiModem_dma_get_packet_time: ioctl returned %d\n", err);
    }
}

/** Lire le nombre de paquets DMA perdus.
 *
 * Cette fonction utilise la fonction `ioctl` pour interroger le module noyau `loki-modem`.
 *
 * @param self Le modem courant.
 * @return Le nombre de transferts DMA dont les données ont été écrasées avant traitement.
 */
static inline unsigned LokiModem_dma_get_dropped_packets(const LokiModem *self) {
    unsigned res = 0;
    int err = ioctl(self->fileno, LOKI_IOCTL_DMA_DROPPED_PACKETS, &res);
    if (err) {
        fprintf(stderr, "LokiModem_dma_get_dropped_packets: ioctl returned %d\n", err);
    }
    return res;
}

/** Mettre à l'échelle une composante X (I) ou Y (Q) d'un échantillon démodulé.
 *
 * @param self Le modem courant.
 * @param xy La valeur à mettre à l'échelle.
 * @return La valeur mise à l'échelle.
 */
static inline float LokiModem_scale_xy(const LokiModem *self, float xy) {
    return ldexpf(xy, -self->demod_xy_fractional_width);
}

/** Mettre à l'échelle une valeur d'entrée du démodulateur.
 *
 * @param self Le modem courant.
 * @param p La valeur à mettre à l'échelle.
 * @return La valeur mise à l'échelle.
 */
static inline float LokiModem_scale_power(const LokiModem *self, float p) {
    return ldexpf(p, -self->demod_power_fractional_width);
}

LokiModem *LokiModem_new(void) {
    LokiModem *self = calloc(1, sizeof(LokiModem));
    if (!self) {
        return NULL;
    }

    self->file = fopen("/dev/loki-modem", "r");
    if (!self->file) {
        fprintf(stderr, "LokiModem_new: failed to open file /dev/loki-modem (error: %d, %s)\n", errno, strerror(errno));
        LokiModem_del(self);
        return NULL;
    }

    self->fileno = fileno(self->file);

    self->clk_frequency                = LokiModem_get_reg(self, LOKI_MODEM_REG_CLK_FREQUENCY);
    self->mod_sample_frequency_ref     = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_SAMPLE_FREQUENCY_REF);
    self->mod_cycles_per_sample_max    = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE_MAX);
    self->mod_osc1_wave_frequency_min  = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OSC1_WAVE_FREQUENCY_MIN);
    self->mod_osc2_wave_frequency_min  = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OSC2_WAVE_FREQUENCY_MIN);
    self->mod_gain_integer_width       = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_GAIN_INTEGER_WIDTH);
    self->mod_gain_fractional_width    = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_GAIN_FRACTIONAL_WIDTH);

    union {
        uint32_t u;
        float f;
    } mod_phase_amplitude_max, mod_dc_value_max;

    mod_phase_amplitude_max.u          = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_PHASE_AMPLITUDE_MAX);
    self->mod_phase_amplitude_max      = mod_phase_amplitude_max.f;
    self->mod_phase_integer_width      = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_PHASE_INTEGER_WIDTH);
    self->mod_phase_fractional_width   = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_PHASE_FRACTIONAL_WIDTH);
    mod_dc_value_max.u                 = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_DC_VALUE_MAX);
    self->mod_dc_value_max             = mod_dc_value_max.f;
    self->mod_dc_value_width           = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_DC_VALUE_WIDTH);
    self->mod_pga_gain_width           = LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_PGA_GAIN_WIDTH);
    self->demod_mixerless              = !!(LokiModem_get_reg(self, LOKI_MODEM_REG_CONTROL) & LOKI_MODEM_REG_CONTROL_MIXERLESS_SHIFTED_MASK);
    self->demod_channels               = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CHANNELS);
    self->demod_channel_output_width   = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CHANNEL_OUTPUT_WIDTH);
    self->demod_power_integer_width    = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_POWER_INTEGER_WIDTH);
    self->demod_power_fractional_width = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_POWER_FRACTIONAL_WIDTH);
    self->demod_sample_frequency_ref   = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_SAMPLE_FREQUENCY_REF);
    self->demod_cycles_per_sample_max  = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE_MAX);
    self->demod_osc_wave_frequency_min = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_OSC_WAVE_FREQUENCY_MIN);
    self->demod_fir1_decimation        = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_FIR1_DECIMATION);
    self->demod_fir1_length            = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_FIR1_LENGTH);
    self->demod_fir2_decimation        = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_FIR2_DECIMATION);
    self->demod_fir2_length            = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_FIR2_LENGTH);
    self->demod_fir2_bandwidth         = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_FIR2_BANDWIDTH);
    self->demod_xy_integer_width       = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_XY_INTEGER_WIDTH);
    self->demod_xy_fractional_width    = LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_XY_FRACTIONAL_WIDTH);

    self->demod_channel_mask           = (1 << self->demod_channel_output_width) - 1;

    self->mod_cycles_per_sample_ref    = (float)self->clk_frequency / self->mod_sample_frequency_ref;
    self->mod_gain_res                 = self->mod_phase_amplitude_max / (1 << (self->mod_gain_integer_width  + self->mod_gain_fractional_width  - 1) - 1);
    self->mod_offset_res               = self->mod_phase_amplitude_max / (1 << (self->mod_phase_integer_width + self->mod_phase_fractional_width - 1) - 1);
    self->mod_dc_value_res             = self->mod_dc_value_max / ((1 << self->mod_dc_value_width) - 1);
    self->mod_pga_gain_max             = (1 << self->mod_pga_gain_width) - 1;
    self->demod_power_max              = LokiModem_scale_power(self, ((1 << (self->demod_power_integer_width + self->demod_power_fractional_width - 1))) - 1);
    self->demod_cycles_per_sample_ref  = (float)self->clk_frequency / self->demod_sample_frequency_ref;
    self->demod_xy_max                 = LokiModem_scale_xy(self, ((1 << (self->demod_xy_integer_width + self->demod_xy_fractional_width - 1))) - 1);
    self->demod_xy_width               = self->demod_xy_integer_width + self->demod_xy_fractional_width;
    self->demod_xy_mask                = (1 << self->demod_xy_width) - 1;
    self->demod_xy_sign_mask           = 1 << (self->demod_xy_width - 1);

    if (!LokiModem_is_streaming(self)) {
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

        uint32_t packet_len_min = page_size / a;
        uint32_t packet_len_max = LokiModem_get_demod_packet_length_max(self);
        packet_len_max -= packet_len_max % packet_len_min;

        uint32_t packet_len = self->demod_channels * packet_len_min;
        if (packet_len > packet_len_max) {
            packet_len = packet_len_max;
        }

        LokiModem_set_reg(self, LOKI_MODEM_REG_DEMOD_PACKET_LENGTH, packet_len);
    }

    return self;
}

void LokiModem_del(LokiModem *self) {
    if (!self) {
        return;
    }

    if (self->file) {
        fclose(self->file);
    }

    free(self);
}

uint32_t LokiModem_get_clk_frequency(const LokiModem *self) {
    return self->clk_frequency;
}

float LokiModem_get_mod_sampling_frequency(const LokiModem *self) {
    return (float)self->clk_frequency / LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE);
}

void LokiModem_set_mod_sampling_frequency(const LokiModem *self, float freq) {
    // Cette fonction doit préserver la fréquence des oscillateurs.
    float osc1_freq = LokiModem_get_mod_osc1_wave_frequency(self);
    float osc2_freq = LokiModem_get_mod_osc2_wave_frequency(self);
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE, roundf((float)self->clk_frequency / freq));
    LokiModem_set_mod_osc1_wave_frequency(self, osc1_freq);
    LokiModem_set_mod_osc2_wave_frequency(self, osc2_freq);
}

float LokiModem_get_mod_osc1_wave_frequency_res(const LokiModem *self) {
    return (float)self->mod_osc1_wave_frequency_min * self->mod_cycles_per_sample_ref / LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE);
}

float LokiModem_get_mod_osc1_wave_frequency_max(const LokiModem *self) {
    return LokiModem_get_mod_sampling_frequency(self) / 4;
}

float LokiModem_get_mod_osc1_wave_frequency(const LokiModem *self) {
    return LokiModem_get_mod_osc1_wave_frequency_res(self) * LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OSC1_STEP);
}

void LokiModem_set_mod_osc1_wave_frequency(const LokiModem *self, float freq) {
    float ref_freq = freq * LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE) / self->mod_cycles_per_sample_ref;
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_OSC1_STEP, roundf(ref_freq / self->mod_osc1_wave_frequency_min));
}

float LokiModem_get_mod_osc1_gain_res(const LokiModem *self) {
    return self->mod_gain_res;
}

float LokiModem_get_mod_osc1_gain_max(const LokiModem *self) {
    return self->mod_phase_amplitude_max;
}

float LokiModem_get_mod_osc1_gain(const LokiModem *self) {
    return (float)LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OSC1_GAIN) * self->mod_gain_res;
}

void LokiModem_set_mod_osc1_gain(const LokiModem *self, float gain) {
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_OSC1_GAIN, roundf(gain / self->mod_gain_res));
}

float LokiModem_get_mod_osc2_wave_frequency_res(const LokiModem *self) {
    return (float)self->mod_osc2_wave_frequency_min * self->mod_cycles_per_sample_ref / LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE);
}

float LokiModem_get_mod_osc2_wave_frequency_max(const LokiModem *self) {
    return LokiModem_get_mod_sampling_frequency(self) / 4;
}

float LokiModem_get_mod_osc2_wave_frequency(const LokiModem *self) {
    return LokiModem_get_mod_osc2_wave_frequency_res(self) * LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OSC2_STEP);
}

void LokiModem_set_mod_osc2_wave_frequency(const LokiModem *self, float freq) {
    float ref_freq = freq * LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE) / self->mod_cycles_per_sample_ref;
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_OSC2_STEP, roundf(ref_freq / self->mod_osc2_wave_frequency_min));
}

float LokiModem_get_mod_osc2_gain_res(const LokiModem *self) {
    return self->mod_gain_res;
}

float LokiModem_get_mod_osc2_gain_max(const LokiModem *self) {
    return self->mod_phase_amplitude_max;
}

float LokiModem_get_mod_osc2_gain(const LokiModem *self) {
    return (float)LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OSC2_GAIN) * self->mod_gain_res;
}

void LokiModem_set_mod_osc2_gain(const LokiModem *self, float gain) {
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_OSC2_GAIN, roundf(gain / self->mod_gain_res));
}

float LokiModem_get_demod_osc_wave_frequency_res(const LokiModem *self) {
    if (self->demod_mixerless) {
        return 0.0f;
    }
    return (float)self->demod_osc_wave_frequency_min * self->demod_cycles_per_sample_ref / LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE);
}

float LokiModem_get_demod_osc_wave_frequency_max(const LokiModem *self) {
    if (self->demod_mixerless) {
        return 0.0f;
    }
    return LokiModem_get_demod_sampling_frequency(self) / 4;
}

float LokiModem_get_demod_osc_wave_frequency(const LokiModem *self) {
    if (self->demod_mixerless) {
        return 0.0f;
    }
    return LokiModem_get_demod_osc_wave_frequency_res(self) * LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_OSC_STEP);
}

void LokiModem_set_demod_osc_wave_frequency(const LokiModem *self, float freq) {
    if (self->demod_mixerless) {
        return;
    }
    float ref_freq = freq * LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE) / self->demod_cycles_per_sample_ref;
    LokiModem_set_reg(self, LOKI_MODEM_REG_DEMOD_OSC_STEP, roundf(ref_freq / self->demod_osc_wave_frequency_min));
}

float LokiModem_get_mod_offset_res(const LokiModem *self) {
    return self->mod_offset_res;
}

float LokiModem_get_mod_offset_max(const LokiModem *self) {
    return self->mod_phase_amplitude_max;
}

float LokiModem_get_mod_offset(const LokiModem *self) {
    return (float)(int32_t)LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_OFFSET) * self->mod_offset_res;
}

void LokiModem_set_mod_offset(const LokiModem *self, float offset) {
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_OFFSET, roundf(offset / self->mod_offset_res));
}

float LokiModem_get_mod_dc_value_res(const LokiModem *self) {
    return self->mod_dc_value_res;
}

float LokiModem_get_mod_dc_value_max(const LokiModem *self) {
    return self->mod_dc_value_max;
}

float LokiModem_get_mod_dc_value(const LokiModem *self) {
    return (float)LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_DC_VALUE) * self->mod_dc_value_res;
}

void LokiModem_set_mod_dc_value(const LokiModem *self, float dc_value) {
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_DC_VALUE, roundf(dc_value / self->mod_dc_value_res));
}

uint32_t LokiModem_get_mod_pga_gain_max(const LokiModem *self) {
    return self->mod_pga_gain_max;
}

uint32_t LokiModem_get_mod_pga_gain(const LokiModem *self) {
    return LokiModem_get_reg(self, LOKI_MODEM_REG_MOD_PGA_GAIN);
}

void LokiModem_set_mod_pga_gain(const LokiModem *self, uint32_t gain) {
    LokiModem_set_reg(self, LOKI_MODEM_REG_MOD_PGA_GAIN, gain);
}

uint32_t LokiModem_get_demod_channels(const LokiModem *self) {
    return self->demod_channels;
}

uint32_t LokiModem_get_demod_decimation(const LokiModem *self) {
    return self->demod_fir1_decimation * self->demod_fir2_decimation;
}

float LokiModem_get_demod_bandwidth(const LokiModem *self) {
    return (float)self->demod_fir2_bandwidth * self->demod_cycles_per_sample_ref / LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE);
}

float LokiModem_get_demod_sampling_frequency(const LokiModem *self) {
    return (float)self->clk_frequency / LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE);
}

void LokiModem_set_demod_sampling_frequency(const LokiModem *self, float freq) {
    float osc_freq;
    if (!self->demod_mixerless) {
        // Cette fonction doit préserver la fréquence de l'oscillateur.
        osc_freq = LokiModem_get_demod_osc_wave_frequency(self);
    }

    LokiModem_set_reg(self, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE, roundf((float)self->clk_frequency / freq));

    if (!self->demod_mixerless) {
        LokiModem_set_demod_osc_wave_frequency(self, osc_freq);
    }
}

float LokiModem_get_demod_xy_sampling_frequency(const LokiModem *self) {
    return LokiModem_get_demod_sampling_frequency(self) / self->demod_fir1_decimation / self->demod_fir2_decimation;
}

void LokiModem_set_demod_xy_sampling_frequency(const LokiModem *self, float freq) {
    LokiModem_set_demod_sampling_frequency(self, freq * self->demod_fir1_decimation * self->demod_fir2_decimation);
}

uint32_t LokiModem_get_demod_delay_x_max(const LokiModem *self, uint32_t channel) {
    if (self->demod_mixerless) {
        return self->demod_fir2_decimation * self->demod_fir1_decimation - 1;
    }
    else {
        return self->demod_sample_frequency_ref / self->demod_osc_wave_frequency_min - 1;
    }
}

float LokiModem_get_demod_phase_x_max(const LokiModem *self, uint32_t channel) {
    const uint32_t delay_max = LokiModem_get_demod_delay_x_max(self, channel);
    return 360.0f * delay_max / (delay_max + 1);
}

float LokiModem_get_demod_phase_x_res(const LokiModem *self, uint32_t channel) {
    const uint32_t delay_max = LokiModem_get_demod_delay_x_max(self, channel);
    return 360.0f / (delay_max + 1);
}

uint32_t LokiModem_get_demod_delay_x(const LokiModem *self, uint32_t channel) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    uint32_t lowpass_delay_x  = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_LOWPASS_X);
    if (self->demod_mixerless) {
        return lowpass_delay_x;
    }
    uint32_t bandpass_delay_x = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_BANDPASS_X);
    return lowpass_delay_x + bandpass_delay_x * self->demod_fir1_decimation;
}

float LokiModem_get_demod_phase_x(const LokiModem *self, uint32_t channel) {
    const uint32_t delay     = LokiModem_get_demod_delay_x(self, channel);
    const uint32_t delay_max = LokiModem_get_demod_delay_x_max(self, channel);
    return 360.0f * delay / (delay_max + 1);
}

void LokiModem_set_demod_delay_x(const LokiModem *self, uint32_t channel, uint32_t delay) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    if (self->demod_mixerless) {
        LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_LOWPASS_X,  delay % self->demod_fir1_decimation);
        LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_BANDPASS_X, delay / self->demod_fir1_decimation);
    }
    else {
        LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_LOWPASS_X,  delay);
    }
}

void LokiModem_set_demod_phase_x(const LokiModem *self, uint32_t channel, float phase) {
    // delay_range needs to be signed for the % operation below.
    const int32_t delay_range = LokiModem_get_demod_delay_x_max(self, channel) + 1;
    const int32_t delay = (int32_t)roundf(phase * delay_range / 360.0f) % delay_range;
    LokiModem_set_demod_delay_x(self, channel, delay >= 0 ? delay : delay + delay_range);
}

uint32_t LokiModem_get_demod_delay_y_max(const LokiModem *self, uint32_t channel) {
    if (self->demod_mixerless) {
        return self->demod_fir2_decimation * self->demod_fir1_decimation - 1;
    }
    else {
        return self->demod_sample_frequency_ref / self->demod_osc_wave_frequency_min - 1;
    }
}

float LokiModem_get_demod_phase_y_max(const LokiModem *self, uint32_t channel) {
    const uint32_t delay_max = LokiModem_get_demod_delay_y_max(self, channel);
    return 360.0f * delay_max / (delay_max + 1);
}

float LokiModem_get_demod_phase_y_res(const LokiModem *self, uint32_t channel) {
    const uint32_t delay_max = LokiModem_get_demod_delay_y_max(self, channel);
    return 360.0f / (delay_max + 1);
}

uint32_t LokiModem_get_demod_delay_y(const LokiModem *self, uint32_t channel) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    uint32_t lowpass_delay_y  = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_LOWPASS_Y);
    if (self->demod_mixerless) {
        return lowpass_delay_y;
    }
    uint32_t bandpass_delay_y = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_BANDPASS_Y);
    return lowpass_delay_y + bandpass_delay_y * self->demod_fir1_decimation;
}

float LokiModem_get_demod_phase_y(const LokiModem *self, uint32_t channel) {
    const uint32_t delay     = LokiModem_get_demod_delay_y(self, channel);
    const uint32_t delay_max = LokiModem_get_demod_delay_y_max(self, channel);
    return 360.0f * delay / (delay_max + 1);
}

void LokiModem_set_demod_delay_y(const LokiModem *self, uint32_t channel, uint32_t delay) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    if (self->demod_mixerless) {
        LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_LOWPASS_Y,  delay % self->demod_fir1_decimation);
        LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_BANDPASS_Y, delay / self->demod_fir1_decimation);
    }
    else {
        LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_DELAY_LOWPASS_Y,  delay);
    }
}

void LokiModem_set_demod_phase_y(const LokiModem *self, uint32_t channel, float phase) {
    // delay_range needs to be signed for the % operation below.
    const int32_t delay_range = LokiModem_get_demod_delay_y_max(self, channel) + 1;
    const int32_t delay = (int32_t)roundf(phase * delay_range / 360.0f) % delay_range;
    LokiModem_set_demod_delay_y(self, channel, delay >= 0 ? delay : delay + delay_range);
}

/// Le paramètre *Vernier* pour le réglage du gain de l'amplificateur AD8370.
#define AD8370_VERNIER 0.055744
/// Le paramètre *PreGain* pour le réglage du gain de l'amplificateur AD8370.
#define AD8370_PREGAIN 7.079458
/// Le facteur appliqué au code de gain dans le mode *High Gain* de l'amplificateur AD8370.
#define AD8370_HIGH_GAIN_FACTOR (AD8370_VERNIER * AD8370_PREGAIN)
/// Le nombre de bits du code de gain de l'amplificateur AD8370.
#define AD8370_GAIN_CODE_SIZE 7
/// La valeur maximale du code de gain de l'amplificateur AD8370.
#define AD8370_GAIN_CODE_MAX ((1 << AD8370_GAIN_CODE_SIZE) - 1)
/// Le gain maximal de l'amplificateur AD8370 en mode *Low Gain*.
#define AD8370_LOW_GAIN_MAX (AD8370_GAIN_CODE_MAX * AD8370_VERNIER)
/// Le gain maximal de l'amplificateur AD8370 en mode *High Gain*.
#define AD8370_HIGH_GAIN_MAX (AD8370_GAIN_CODE_MAX * AD8370_HIGH_GAIN_FACTOR)

/// Représentation du mot de contrôle du gain pour l'amplificateur AD8370.
typedef union {
    /// La valeur brute du mot de contrôle.
    uint8_t raw;
    /// Les champs du mot de contrôle.
    struct {
        /// Le code de gain.
        unsigned gain_code : AD8370_GAIN_CODE_SIZE;
        /// Le bit d'activation du mode *High Gain*.
        unsigned high_gain : 1;
    };
} AD8370ControlWord;

float LokiModem_get_demod_pga_gain_max(const LokiModem *self, uint32_t channel) {
    return AD8370_HIGH_GAIN_MAX;
}

float LokiModem_get_demod_pga_gain(const LokiModem *self, uint32_t channel) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    AD8370ControlWord control_word = {
        .raw = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_PGA_GAIN)
    };
    float gain = AD8370_VERNIER * control_word.gain_code;
    if (control_word.high_gain) {
        gain *= AD8370_PREGAIN;
    }
    return gain;
}

void LokiModem_set_demod_pga_gain(const LokiModem *self, uint32_t channel, float gain) {
    if (gain < 0) {
        gain = 0;
    }
    else if (gain > AD8370_HIGH_GAIN_MAX) {
        gain = AD8370_HIGH_GAIN_MAX;
    }

    AD8370ControlWord control_word = {
        .high_gain = gain > AD8370_LOW_GAIN_MAX
    };

    control_word.gain_code = gain / (control_word.high_gain ? AD8370_HIGH_GAIN_FACTOR : AD8370_VERNIER);

    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    LokiModem_set_reg(self, base + LOKI_MODEM_REG_DEMOD_PGA_GAIN, control_word.raw);
}

float LokiModem_get_demod_adc_min_ratio(const LokiModem *self, uint32_t channel) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    int32_t value = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_ADC_MIN);
    return LokiModem_scale_power(self, value) / self->demod_power_max;
}

float LokiModem_get_demod_adc_max_ratio(const LokiModem *self, uint32_t channel) {
    uint32_t base = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + channel * LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT;
    int32_t value = LokiModem_get_reg(self, base + LOKI_MODEM_REG_DEMOD_ADC_MAX);
    return LokiModem_scale_power(self, value) / self->demod_power_max;
}

uint32_t LokiModem_get_demod_packet_length_max(const LokiModem *self) {
    return LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_PACKET_LENGTH_MAX);
}

uint32_t LokiModem_get_demod_packet_length(const LokiModem *self) {
    return LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_PACKET_LENGTH);
}

bool LokiModem_get_demod_mixerless(const LokiModem *self) {
    return self->demod_mixerless;
}

bool LokiModem_get_demod_bypass(const LokiModem *self) {
    uint32_t value = LokiModem_get_reg(self, LOKI_MODEM_REG_CONTROL) & LOKI_MODEM_REG_CONTROL_BYPASS_SHIFTED_MASK;
    return !!value;
}

void LokiModem_set_demod_bypass(const LokiModem *self, bool bypass) {
    uint32_t value = LokiModem_get_reg(self, LOKI_MODEM_REG_CONTROL);
    if (bypass) {
        value |= LOKI_MODEM_REG_CONTROL_BYPASS_SHIFTED_MASK;
    }
    else {
        value &= ~LOKI_MODEM_REG_CONTROL_BYPASS_SHIFTED_MASK;
    }
    LokiModem_set_reg(self, LOKI_MODEM_REG_CONTROL, value);
}

bool LokiModem_get_test_mode(const LokiModem *self) {
    uint32_t value = LokiModem_get_reg(self, LOKI_MODEM_REG_CONTROL) & LOKI_MODEM_REG_CONTROL_TEST_MODE_SHIFTED_MASK;
    return !!value;
}

void LokiModem_set_test_mode(const LokiModem *self, bool test_mode) {
    uint32_t value = LokiModem_get_reg(self, LOKI_MODEM_REG_CONTROL);
    if (test_mode) {
        value |= LOKI_MODEM_REG_CONTROL_TEST_MODE_SHIFTED_MASK;
    }
    else {
        value &= ~LOKI_MODEM_REG_CONTROL_TEST_MODE_SHIFTED_MASK;
    }
    LokiModem_set_reg(self, LOKI_MODEM_REG_CONTROL, value);
}

void LokiModem_restart(const LokiModem *self) {
    uint32_t value = LokiModem_get_reg(self, LOKI_MODEM_REG_CONTROL);
    value |= LOKI_MODEM_REG_CONTROL_RESTART_SHIFTED_MASK;
    LokiModem_set_reg(self, LOKI_MODEM_REG_CONTROL, value);
}

uint32_t LokiModem_get_adc_sample_count(const LokiModem *self) {
    return LokiModem_get_reg(self, LOKI_MODEM_REG_ADC_SAMPLE_COUNT);
}

uint32_t LokiModem_get_dac_sample_count(const LokiModem *self) {
    return LokiModem_get_reg(self, LOKI_MODEM_REG_DAC_SAMPLE_COUNT);
}

uint32_t LokiModem_get_demod_sample_count(const LokiModem *self) {
    return LokiModem_get_reg(self, LOKI_MODEM_REG_DEMOD_SAMPLE_COUNT);
}

/** Lire un numéro de paquet dans un échantillon DMA brut.
 *
 * @param self Le modem courant.
 * @param raw_item L'échantillon brut à inspecter.
 * @return Le numéro de paquet de cet échantillon.
 */
static inline uint32_t LokiModem_get_packet_index(const LokiModem *self, LokiDMASample raw_item) {
    return raw_item >> (self->demod_xy_width * 2 + self->demod_channel_output_width);
}

/** Affecter les champs d'un échantillon de sortie du démodulateur.
 *
 * @param self Le modem courant.
 * @param item Un pointeur vers l'échantillon de sortie à compléter.
 * @param raw_item L'échantillon DMA brut.
 */
static void LokiModem_set_packet_item(const LokiModem *self, LokiModemSample *item, LokiDMASample raw_item) {
    // Lire la valeur de l'échantillon, alignée à droite en complément à deux.
    // Effectuer l'extension du bit de signe.
    int32_t y_raw = raw_item & self->demod_xy_mask;
    raw_item >>= self->demod_xy_width;

    if (y_raw & self->demod_xy_sign_mask) {
        y_raw |= ~self->demod_xy_mask;
    }
    else {
        y_raw &= self->demod_xy_mask;
    }

    int32_t x_raw = raw_item & self->demod_xy_mask;
    raw_item >>= self->demod_xy_width;

    if (x_raw & self->demod_xy_sign_mask) {
        x_raw |= ~self->demod_xy_mask;
    }
    else {
        x_raw &= self->demod_xy_mask;
    }

    // Convertir les coordonnées en flottants si nécessaire.
    if (self->raw) {
        item->x_raw = x_raw;
        item->y_raw = y_raw;
    }
    else {
        item->x = LokiModem_scale_xy(self, x_raw);
        item->y = LokiModem_scale_xy(self, y_raw);
    }

    // Lire le numéro de la voie.
    item->channel = raw_item & self->demod_channel_mask;
}

// TODO Rendre ces valeurs configurables

/// La fréquence du déplacement en mode simulation de capteurs, en Hz.
#define SIMULATED_DISP_WAVE_FREQUENCY 0.2
/// L'amplitude du déplacement en mode simulation de capteurs, en radians.
#define SIMULATED_DISP_AMPLITUDE (M_PI / 10)
/// Le demi-grand axe de l'ellipse en mode simulation de capteurs.
#define SIMULATED_ELLIPSE_A 0.1
/// Le demi-petit axe de l'ellipse en mode simulation de capteurs.
#define SIMULATED_ELLIPSE_B 0.15
/// L'angle de rotation de l'ellipse en mode simulation de capteurs.
#define SIMULATED_ELLIPSE_ANGLE (M_PI / 6)
/// La coordonnée X du centre de l'ellipse en mode simulation de capteurs.
#define SIMULATED_ELLIPSE_XC 0.01
/// La coordonnée Y du centre de l'ellipse en mode simulation de capteurs.
#define SIMULATED_ELLIPSE_YC 0.02

/** Affecter les champs d'un échantillon de sortie du démodulateur en mode simulation de capteurs.
 *
 * @param self Le modem courant.
 * @param item Un pointeur vers l'échantillon de sortie à compléter.
 */
static void LokiModem_set_simulated_item(LokiModem *self, LokiModemSample *item) {
    item->channel = self->sim_channel;
    float phi = LokiModem_get_mod_osc1_gain(self) * cosf(self->sim_osc1_phase) * M_PI / self->mod_phase_amplitude_max +
                SIMULATED_DISP_AMPLITUDE          * cosf(self->sim_disp_phase);
    float x = SIMULATED_ELLIPSE_A * cosf(phi);
    float y = SIMULATED_ELLIPSE_B * sinf(phi);
    float c = cosf(SIMULATED_ELLIPSE_ANGLE);
    float s = sinf(SIMULATED_ELLIPSE_ANGLE);
    item->x = SIMULATED_ELLIPSE_XC + x * c - y * s;
    item->y = SIMULATED_ELLIPSE_YC + y * c + x * s;

    // Passer à la voie suivante.
    // En revenant à la voie 0, mettre à jour les phases des sinusoïdes simulées.
    self->sim_channel ++;
    if (self->sim_channel == self->demod_channels) {
        self->sim_channel = 0;
        self->sim_osc1_phase += M_PI * 2 * LokiModem_get_mod_osc1_wave_frequency(self) / LokiModem_get_demod_xy_sampling_frequency(self);
        if (self->sim_osc1_phase >= M_PI) {
            self->sim_osc1_phase -= M_PI * 2;
        }
        self->sim_disp_phase += M_PI * 2 * SIMULATED_DISP_WAVE_FREQUENCY / LokiModem_get_demod_xy_sampling_frequency(self);
        if (self->sim_disp_phase >= M_PI) {
            self->sim_disp_phase -= M_PI * 2;
        }
    }
}

/** Utiliser la fonction `mmap` pour accéder aux données DMA.
 *
 * Commenter cette ligne pour utiliser `fread`.
 */
#define USE_MMAP

/** Traiter un tableau d'échantillons issu d'un transfert DMA.
 *
 * Cette fonction est exécutée dans un thread démarré par #LokiModem_start_streaming.
 * Elle se termine lorsqu'une demande d'arrêt est émise par #LokiModem_stop_streaming.
 *
 * Si la constante `USE_MMAP` est définie, elle s'appuie sur la fonction `mmap`
 * pour se synchroniser avec le pilote du circuit modem et accéder au tampon de
 * données de chaque transfert en mode *zero-copy*.
 * Si la constante `USE_MMAP` n'est pas définie, la fonction `fread` est utilisée.
 *
 * Cette fonction remplit la FIFO de sortie avec des paquets d'échantillons
 * convertis par la fonction #LokiModem_set_packet_item.
 *
 * @param ptr Le modem courant.
 */
static void *LokiModem_work(void *ptr) {
    LokiModem *self = ptr;

    pthread_setname_np(self->thread, "LokiModem");

    // Obtenir un pointeur vers le buffer courant des échantillons mise en forme.
    const size_t out_length = LokiPacket_get_length(self->out, sizeof(LokiModemSample));
    LokiPacket *out_packet  = LokiFIFO_get_producer_item(self->out);
    if (!out_packet) {
        return NULL;
    }
    LokiModemSample *out_ptr = (LokiModemSample*)out_packet->buffer;
    LokiModemSample *out_end = out_ptr + out_length;

    // Avec la fonction fread, allouer un buffer de données.
    // Avec l'accès par mmap, le buffer est fourni par le pilote.
    const size_t in_length = LokiModem_get_demod_packet_length(self);
    #ifndef USE_MMAP
        LokiDMASample *in_buffer = calloc(in_length, sizeof(LokiDMASample));
        LokiDMASample *in_end    = in_buffer + in_length;
    #else
        size_t in_length_bytes = in_length * sizeof(LokiDMASample);
    #endif

    // Calculer la durée d'un paquet d'entrée, en nanosecondes.
    double in_period_ns = 1.0e9 * in_length / self->demod_channels / LokiModem_get_demod_xy_sampling_frequency(self);

    // Calculer le modulo du compteur de paquets du FPGA.
    const uint32_t packet_count_mod = 1 << (sizeof(LokiDMASample) * 8 - self->demod_channel_output_width - self->demod_xy_width * 2);

    bool first_packet = true;
    uint32_t packet_index_prev = 0;
    LokiTimestamp in_timestamp;

    // Démarrer l'acquisition.
    LokiModem_dma_start(self);

    while (!self->stop_request) {
        // Lire un buffer d'échantillons en provenance du DMA.
        #ifndef USE_MMAP
            if (fread(in_buffer, sizeof(LokiDMASample), in_length, self->file) != in_length) {
                fprintf(stderr, "LokiModem_work: read failed (error: %d, %s)\n", errno, strerror(errno));
                break;
            }
        #else
            // Accès au buffer DMA en mode zero-copy.
            LokiDMASample *in_buffer = mmap(NULL, in_length_bytes, PROT_READ, MAP_PRIVATE, self->fileno, 0);
            if (in_buffer == MAP_FAILED) {
                fprintf(stderr, "LokiModem_work: mmap failed (error: %d, %s)\n", errno, strerror(errno));
                break;
            }
            LokiDMASample *in_end = in_buffer + in_length;
        #endif

        // Attendre le paquet numéro 0 pour commencer.
        uint32_t packet_index = LokiModem_get_packet_index(self, *in_buffer);

        // Prendre pour référence temporelle la date du premier paquet.
        // Les dates des autres paquets seront calculées en fonction du nombre d'échantillons.
        if (first_packet && !packet_index) {
            struct timespec ts;
            LokiModem_dma_get_packet_time(self, &ts);
            in_timestamp = LokiTime_to_timestamp(ts) - in_period_ns;
        }

        if (!first_packet || !packet_index) {
            // Calculer le timestamp du paquet d'entrée, en nanosecondes,
            // en utilisant le numéro de paquet fourni par le FPGA.
            int32_t packet_interval = packet_index - packet_index_prev;
            if (packet_interval < 0) {
                fprintf(stderr, "LokiModem_work: packet index rollover (%u -> %u).\n", packet_index_prev, packet_index);
                packet_interval += packet_count_mod;
            }

            if (packet_interval < 0) {
                fprintf(stderr, "LokiModem_work: packet index overlap (%u -> %u, %u).\n", packet_index_prev, packet_index, -packet_interval);
            }
            else if (packet_interval > 1) {
                fprintf(stderr, "LokiModem_work: packet index gap (%u -> %u, %u).\n", packet_index_prev, packet_index, packet_interval);
                //goto LokiModem_work_continue;
            }

            packet_index_prev = packet_index;
            first_packet = false;

            in_timestamp += round(in_period_ns * packet_interval);

            // En commençant un nouveau paquet de sortie, copier la date du paquet d'entrée.
            if (out_ptr == (LokiModemSample*)out_packet->buffer) {
                out_packet->timestamp = in_timestamp;
            }

            LokiDMASample *in_ptr = in_buffer;
            while (in_ptr != in_end && !self->stop_request) {
                LokiDMASample in = *in_ptr ++;

                LokiModemSample s;
                if (self->simulate) {
                    LokiModem_set_simulated_item(self, &s);
                }
                else {
                    LokiModem_set_packet_item(self, &s, in);
                }

                // Produire l'échantillon en sortie si la voie correspondante
                // est activée dans le masque des voies à traiter.
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
                        out_ptr = (LokiModemSample*)out_packet->buffer;
                        out_end = out_ptr + out_length;
                    }
                }
            }
        }

    LokiModem_work_continue:
        #ifdef USE_MMAP
            munmap(in_buffer, in_length_bytes);
        #endif
    }

    #ifndef USE_MMAP
        free(in_buffer);
    #endif

    LokiModem_dma_stop(self);
}

int LokiModem_start_streaming(LokiModem *self, int32_t channels, bool simulate, bool raw, LokiFIFO *out) {
    if (LokiModem_is_streaming(self)) {
        return EBUSY;
    }
    self->stop_request    = false;
    self->out             = out;
    self->simulate        = simulate;
    self->sim_channel     = 0;
    self->sim_osc1_phase  = 0;
    self->sim_disp_phase  = 0;
    self->raw             = raw;
    self->stream_channels = channels;
    return pthread_create(&self->thread, NULL, LokiModem_work, self);
}

void LokiModem_stop_streaming(LokiModem *self) {
    if (self->stop_request) {
        return;
    }
    self->stop_request = true;
    LokiFIFO_abort(self->out);
    pthread_join(self->thread, NULL);
}

void LokiModem_force_stop(const LokiModem *self) {
    LokiModem_dma_stop(self);
}

bool LokiModem_is_streaming(const LokiModem *self) {
    return LokiModem_dma_is_streaming(self);
}

unsigned LokiModem_get_dropped_packets(const LokiModem *self) {
    return LokiModem_dma_get_dropped_packets(self);
}

void LokiModem_print_config(const LokiModem *self) {
    printf(
        "Clock frequency:               %u Hz\n"
        "Modulator:\n"
        "  Reference sample frequency:  %u samples/sec\n"
        "  Current sample frequency:    %f samples/sec\n"
        "  Oscillator 1:\n"
        "    Wave frequency resolution: %f Hz\n"
        "    Wave frequency max:        %f Hz\n"
        "    Wave frequency:            %f Hz\n"
        "    Gain resolution:           %f\n"
        "    Gain max:                  %f\n"
        "    Gain:                      %f\n"
        "  Oscillator 2:\n"
        "    Wave frequency resolution: %f Hz\n"
        "    Wave frequency max:        %f Hz\n"
        "    Wave frequency:            %f Hz\n"
        "    Gain resolution:           %f\n"
        "    Gain max:                  %f\n"
        "    Gain:                      %f\n"
        "  Output:\n"
        "    Resolution:                %f\n"
        "    Max:                       %f\n"
        "    Offset:                    %f\n"
        "  DC value:\n"
        "    Resolution:                %f\n"
        "    Max:                       %f\n"
        "    Offset:                    %f\n"
        "  PGA gain:                    %u\n"
        "Demodulator:\n"
        "  Bypass:                      %s\n"
        "  Channels:                    %u\n"
        "  Input sample frequency:      %f samples/sec\n"
        "  Input resolution:            %f\n"
        "  Input max:                   %f\n"
        "  Output sample frequency:     %f samples/sec\n"
        "  Output resolution:           %f\n"
        "  Output max:                  %f\n"
        "  Oscillator:                  %s\n"
        "    Wave frequency resolution: %f Hz\n"
        "    Wave frequency max:        %f Hz\n"
        "    Wave frequency:            %f Hz\n"
        "  Filter 1:\n"
        "    Length:                    %u\n"
        "    Decimation:                %u\n"
        "  Filter 2:\n"
        "    Length:                    %u\n"
        "    Decimation:                %u\n"
        "DMA interface:\n"
        "  Packet length max:           %u samples/transfer\n"
        "  Packet length:               %u samples/transfer\n",
        self->clk_frequency,
        // Modulator
        self->mod_sample_frequency_ref,
        LokiModem_get_mod_sampling_frequency(self),
        LokiModem_get_mod_osc1_wave_frequency_res(self),
        LokiModem_get_mod_osc1_wave_frequency_max(self),
        LokiModem_get_mod_osc1_wave_frequency(self),
        LokiModem_get_mod_osc1_gain_res(self),
        LokiModem_get_mod_osc1_gain_max(self),
        LokiModem_get_mod_osc1_gain(self),
        LokiModem_get_mod_osc2_wave_frequency_res(self),
        LokiModem_get_mod_osc2_wave_frequency_max(self),
        LokiModem_get_mod_osc2_wave_frequency(self),
        LokiModem_get_mod_osc2_gain_res(self),
        LokiModem_get_mod_osc2_gain_max(self),
        LokiModem_get_mod_osc2_gain(self),
        LokiModem_get_mod_offset_res(self),
        LokiModem_get_mod_offset_max(self),
        LokiModem_get_mod_offset(self),
        LokiModem_get_mod_dc_value_res(self),
        LokiModem_get_mod_dc_value_max(self),
        LokiModem_get_mod_dc_value(self),
        LokiModem_get_mod_pga_gain(self),
        // Demodulator
        LokiModem_get_demod_bypass(self) ? "Yes" : "No",
        self->demod_channels,
        LokiModem_get_demod_sampling_frequency(self),
        LokiModem_scale_power(self, 1),
        self->demod_power_max,
        LokiModem_get_demod_xy_sampling_frequency(self),
        LokiModem_scale_xy(self, 1),
        self->demod_xy_max,
        self->demod_mixerless ? "No" : "Yes",
        LokiModem_get_demod_osc_wave_frequency_res(self),
        LokiModem_get_demod_osc_wave_frequency_max(self),
        LokiModem_get_demod_osc_wave_frequency(self),
        self->demod_fir1_length,
        self->demod_fir1_decimation,
        self->demod_fir2_length,
        self->demod_fir2_decimation,
        LokiModem_get_demod_packet_length_max(self),
        LokiModem_get_demod_packet_length(self)
    );
}

/// @file libloki-modem.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
