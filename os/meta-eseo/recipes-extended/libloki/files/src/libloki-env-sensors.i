
%nodefaultctor LokiEnvSensors;
%nodefaultdtor LokiEnvSensors;

struct LokiEnvSensors {};

%extend LokiEnvSensors {
    LokiEnvSensors() {
        return LokiEnvSensors_new();
    }

    ~LokiEnvSensors() {
        LokiEnvSensors_del($self);
    }

    void restart();

    size_t get_sample_size() {
        return sizeof(LokiEnvSensorsSample);
    }

    uint32_t get_clk_frequency();
    size_t get_channels();

    float get_sampling_frequency();
    void set_sampling_frequency(float freq);

    uint32_t get_packet_length_max();
    uint32_t get_packet_length();

    float get_scaling_factor(size_t channel);
    void set_scaling_factor(size_t channel, float scale);

    float get_last_data(size_t channel);

    int start_streaming(int32_t channels, bool raw, LokiFIFO *out);
    void stop_streaming();
    void force_stop();
    bool is_streaming();
}
