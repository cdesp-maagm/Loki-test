
%nodefaultctor LokiRecorder;
%nodefaultdtor LokiRecorder;

struct LokiRecorder {};

%extend LokiRecorder {
    LokiRecorder(const char *filename, const char *filetype, size_t max_channels, int32_t channels, size_t sample_size, float sampling_frequency, float duration, float duration_per_file, void *config = NULL) {
        return LokiRecorder_new(filename, filetype, max_channels, channels, sample_size, sampling_frequency, duration, duration_per_file, config);
    }

    ~LokiRecorder() {
        LokiRecorder_del($self);
    }

    int start(LokiFIFO *in, size_t cid=0);
    bool is_recording();
    void wait();
    void stop();
    char *get_filename();
    size_t get_channel_count();
}

%nodefaultctor LokiMSeedConfig;
%nodefaultdtor LokiMSeedConfig;

struct LokiMSeedConfig {};

%extend LokiMSeedConfig {
    LokiMSeedConfig(bool separate_channels, const char *station, const char *location, const char *network, bool raw, bool steim2, const char *channel_names) {
        return LokiMSeedConfig_new(separate_channels, station, location, network, raw, steim2, channel_names);
    }

    ~LokiMSeedConfig() {
        LokiMSeedConfig_del($self);
    }
}
