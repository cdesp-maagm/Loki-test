
/// Permettre l'utilisation de la fonction `pthread_setname_np` pour modifier le nom d'un thread.
#define _GNU_SOURCE

#include "libloki.h"

#include <math.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <signal.h>
#include <inttypes.h>

/// @addtogroup gLokiRecorder
/// @{

/// Représentation d'un enregistreur de séries temporelles.
struct LokiRecorder {
    /// Le nom de base des fichiers de destination (sans extension).
    char *filename;
    /// Le format des fichiers de destination ("raw" ou "mseed").
    char *filetype;
    /// Le formateur à utiliser pour écrire dans les fichiers.
    LokiFormatter *formatter;
    /// Le nombre maximal de voies que cet enregistreur peut traiter.
    size_t max_channels;
    /// Un masque indiquant quelles voies enregistrer.
    int32_t channels;
    /// Le nombre de voies à enregistrer.
    size_t channel_count;
    /// La fréquence d'échantillonnage, en Hz.
    float sampling_frequency;
    /// La taille d'un échantillon, en octets.
    size_t sample_size;
    /// Le nombre total d'échantillons à enregistrer toutes voies confondues, 0 pour enregistrer indéfiniment.
    size_t sample_count;
    /// Le nombre total d'échantillons à enregistrer par fichier toutes voies confondues, 0 pour tout enregistrer dans un seul fichier.
    size_t sample_count_per_file;
    /// Faut-il produire plusieurs fichiers (true si sample_count_per_file > 0)
    bool multifile;
    /// La FIFO contenant les données à enregistrer.
    LokiFIFO *in;
    /// Le numéro de consommateur de cette instance dans la FIFO.
    size_t cid;
    /// Indicateur de demande d'arrêt de l'enregistrement.
    volatile bool stop_request;
    /// Indicateur d'enregistrement en cours.
    bool is_recording;
    /// Un mutex pour gérer les accès concurrents à l'état de l'enregistrement.
    pthread_mutex_t mutex;
    /// Variable conditionnelle activée en fin d'enregistrement.
    pthread_cond_t recording_done;
    /// Le thread qui lit les données de la FIFO et les enregistre.
    pthread_t thread;
};

/// La liste des noms de formateurs supportés.
static const char *const LokiRecorder_formatter_names[] = {
    "raw", "mseed"
};

/// La liste des implémentations de formateurs supportées.
static const LokiFormatterInterface *const LokiRecorder_formatter_impls[] = {
    &LokiRawClass, &LokiMSeedClass
};

/// Longueur de chaîne à allouer pour mettre en forme la date et l'heure d'un fichier ("_YYYYmmddTHHMMSS").
#define FILENAME_SUFFIX_DATE_LEN 16

/// Longueur de chaîne à allouer pour mettre en forme le nombre de millisecondes de la date d'un fichier (".mmmZ.").
#define FILENAME_SUFFIX_MSEC_LEN 6

/// Longueur de chaîne à allouer pour mettre en forme la date complète d'un fichier.
#define FILENAME_SUFFIX_LEN (FILENAME_SUFFIX_DATE_LEN + FILENAME_SUFFIX_MSEC_LEN)

/** Affecter un formateur à un enregistreur.
 *
 * Cette fonction recherche une implémentation de formateur correspondant au
 * type mentionné dans l'enregistreur.
 * Il instancie un formateur en lui passant en paramètre une configuration.
 *
 * @param self L'enregistreur à configurer.
 * @param config La configuration de formateur à appliquer.
 */
static void LokiRecorder_set_formatter(LokiRecorder *self, void *config) {
    LokiFormatterInterface *impl = LokiRecorder_formatter_impls[0];
    for (size_t i = 1; i < LEN(LokiRecorder_formatter_names); i ++) {
        if (!strcmp(LokiRecorder_formatter_names[i], self->filetype)) {
            impl = LokiRecorder_formatter_impls[i];
            break;
        }
    }
    self->formatter = LokiFormatter_new_with_implementation(impl, config);
}

LokiRecorder *LokiRecorder_new(const char *filename, const char *filetype, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency, float duration, float duration_per_file, void *config) {
    LokiRecorder *self = calloc(1, sizeof(LokiRecorder));
    if (!self) {
        return NULL;
    }

    self->filename = calloc(strlen(filename) + strlen(filetype) + FILENAME_SUFFIX_LEN + 1, 1);
    if (!self->filename) {
        LokiRecorder_del(self);
        return NULL;
    }
    strcpy(self->filename, filename);
    self->filetype = strdup(filetype);

    // Compter le nombre de voies activées dans le masque channels.
    self->channel_count = 0;
    for (size_t c = 0; c < max_channels; c ++) {
        if (channels & (1 << c)) {
            self->channel_count ++;
        }
    }

    self->max_channels          = max_channels;
    self->channels              = channels;
    self->sampling_frequency    = sampling_frequency;
    self->sample_size           = sample_size;
    self->sample_count          = self->channel_count * ceilf(duration * sampling_frequency);
    self->multifile             = duration_per_file > 0;
    self->sample_count_per_file = self->multifile ?
        self->channel_count * ceilf(duration_per_file * sampling_frequency) :
        self->sample_count;

    fprintf(stderr, "LokiRecorder_new (%s): will record %zu samples (%zu samples per file)\n", self->filename, self->sample_count, self->sample_count_per_file);

    LokiRecorder_set_formatter(self, config);

    pthread_mutex_init(&self->mutex, NULL);
    pthread_cond_init(&self->recording_done, NULL);

    return self;
}

char *LokiRecorder_get_filename(const LokiRecorder *self) {
    return self->filename;
}

size_t LokiRecorder_get_channel_count(const LokiRecorder *self) {
    return self->channel_count;
}

/** Enregistrer les données.
 *
 * Cette fonction est exécutée dans un thread démarré par la fonction
 * #LokiRecorder_start.
 * Elle reçoit les données de la FIFO d'entrée de l'enregistreur courant
 * et les passe à un formateur qui les enregistre.
 * L'enregistrement se poursuit jusqu'à ce qu'une demande d'arrêt soit effectuée
 * par la fonction #LokiRecorder_stop, ou jusqu'à ce que la durée totale
 * d'enregistrement soit atteinte.
 *
 * @param ptr L'enregistreur courant.
 * @return Rien.
 */
static void *LokiRecorder_work(void *ptr) {
    LokiRecorder *self = ptr;

    pthread_setname_np(self->thread, "LokiRecorder");

    const size_t in_length  = LokiPacket_get_length(self->in,  self->sample_size);

    uint64_t sample_index = 0;
    size_t sample_index_per_file = 0;

    // Obtenir un pointeur vers la date dans le nom de fichier.
    char *filename_suffix_date = self->filename + strlen(self->filename);
    char *filename_suffix_msec = filename_suffix_date + FILENAME_SUFFIX_DATE_LEN;

    // Ce booléen évite de terminer sans avoir écrit un seul paquet.
    bool data_written = false;

    fprintf(stderr, "LokiRecorder_work (%s): starting.\n", self->filename);

    while (!self->stop_request) {
        LokiPacket *in_packet = LokiFIFO_get_consumer_item(self->in, self->cid);
        if (!in_packet) {
            break;
        }
        void *in_ptr = in_packet->buffer;

        bool file_change = sample_index_per_file == 0;

        // Si l'échantillon courant est le premier d'un fichier,
        // construire un nouveau nom de fichier.
        if (file_change) {
            time_t time_sec  = LokiTime_seconds(in_packet->timestamp);
            time_t time_msec = LokiTime_milliseconds(in_packet->timestamp);
            struct tm file_time;
            gmtime_r(&time_sec, &file_time);
            strftime(filename_suffix_date, FILENAME_SUFFIX_DATE_LEN + 1, "_%Y%m%dT%H%M%S", &file_time);
            sprintf(filename_suffix_msec, ".%03luZ.%s", time_msec, self->filetype);
        }

        // Écrire le paquet courant dans le fichier de destination.
        LokiFormatter_work(self->formatter, self->filename, in_packet->timestamp, file_change, in_ptr, in_length, self->max_channels, self->channels, self->sample_size, self->sampling_frequency);
        data_written = true;

        // Mettre à jour le compteur d'échantillons pour le fichier courant.
        // Si le fichier est plein, remettre le compteur à zéro et fermer le fichier.
        sample_index_per_file += in_length;
        if (self->multifile && sample_index_per_file > self->sample_count_per_file) {
            sample_index_per_file = 0;
        }

        LokiFIFO_pull(self->in, self->cid);

        // Mettre à jour le compteur d'échantillons global.
        // Si la durée d'acquisition est atteinte, terminer.
        sample_index += in_length;
        if (data_written && self->sample_count > 0 && sample_index >= self->sample_count) {
            break;
        }
    }

    fprintf(stderr, "LokiRecorder_work (%s): done.\n", self->filename);

    LokiFormatter_close(self->formatter);

    pthread_mutex_lock(&self->mutex);
    self->is_recording = false;
    pthread_cond_signal(&self->recording_done);
    pthread_mutex_unlock(&self->mutex);
}

int LokiRecorder_start(LokiRecorder *self, LokiFIFO *in, size_t cid) {
    self->is_recording = true;
    self->in = in;
    self->cid = cid;
    self->stop_request = false;
    return pthread_create(&self->thread, NULL, LokiRecorder_work, self);
}

bool LokiRecorder_is_recording(LokiRecorder *self) {
    return self->is_recording;
}

/// L'instance de LokiRecorder qui fait l'objet d'une attente par la fonction #LokiRecorder_wait.
static LokiRecorder *LokiRecorder_waiting_instance;

/** Gestionnaire d'événements.
 *
 * Cette fonction est installée comme gestionnaire d'événement par la fonction
 * #LokiRecorder_wait.
 * Elle interrompt l'enregistreur #LokiRecorder_waiting_instance sur
 * réception d'un signal `KILL`, `TERM` ou `INT`.
 *
 * @param signum Le numéro du signal reçu.
 */
static void LokiRecorder_signal_handler(int signum) {
    signal(SIGKILL, SIG_DFL);
    signal(SIGTERM, SIG_DFL);
    signal(SIGINT,  SIG_DFL);
    LokiRecorder_stop(LokiRecorder_waiting_instance);
}

void LokiRecorder_wait(LokiRecorder *self) {
    LokiRecorder_waiting_instance = self;
    signal(SIGKILL, LokiRecorder_signal_handler);
    signal(SIGTERM, LokiRecorder_signal_handler);
    signal(SIGINT,  LokiRecorder_signal_handler);

    pthread_mutex_lock(&self->mutex);
    if (self->is_recording) {
        pthread_cond_wait(&self->recording_done, &self->mutex);
    }
    pthread_mutex_unlock(&self->mutex);
}

void LokiRecorder_stop(LokiRecorder *self) {
    if (self->stop_request) {
        return;
    }
    self->stop_request = true;
    LokiFIFO_abort(self->in);
    pthread_join(self->thread, NULL);
}

void LokiRecorder_del(LokiRecorder *self) {
    if (!self) {
        return;
    }

    if (self->filename) {
        free(self->filename);
    }

    if (self->filetype) {
        free(self->filetype);
    }

    if (self->formatter) {
        LokiFormatter_del(self->formatter);
    }

    free(self);
}

/// @file libloki-recorder.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
