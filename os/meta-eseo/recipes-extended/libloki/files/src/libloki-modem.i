
%nodefaultctor LokiModem;
%nodefaultdtor LokiModem;

struct LokiModem {};

%extend LokiModem {
    LokiModem() {
        return LokiModem_new();
    }

    ~LokiModem() {
        LokiModem_del($self);
    }

    size_t get_sample_size() {
        return sizeof(LokiModemSample);
    }

    uint32_t get_clk_frequency();

    float get_mod_sampling_frequency();
    void set_mod_sampling_frequency(float freq);

    float get_mod_osc1_wave_frequency_res();
    float get_mod_osc1_wave_frequency_max();
    float get_mod_osc1_wave_frequency();
    void set_mod_osc1_wave_frequency(float freq);

    float get_mod_osc1_gain_res();
    float get_mod_osc1_gain_max();
    float get_mod_osc1_gain();
    void set_mod_osc1_gain(float gain);

    float get_mod_osc2_wave_frequency_res();
    float get_mod_osc2_wave_frequency_max();
    float get_mod_osc2_wave_frequency();
    void set_mod_osc2_wave_frequency(float freq);

    float get_mod_osc2_gain_res();
    float get_mod_osc2_gain_max();
    float get_mod_osc2_gain();
    void set_mod_osc2_gain(float gain);

    float get_demod_osc_wave_frequency_res();
    float get_demod_osc_wave_frequency_max();
    float get_demod_osc_wave_frequency();
    void set_demod_osc_wave_frequency(float freq);

    uint32_t get_mod_pga_gain_max();
    uint32_t get_mod_pga_gain();
    void set_mod_pga_gain(uint32_t gain);

    float get_mod_offset_res();
    float get_mod_offset_max();
    float get_mod_offset();
    void set_mod_offset(float offset);

    float get_mod_dc_value_res();
    float get_mod_dc_value_max();
    float get_mod_dc_value();
    void set_mod_dc_value(float dc_value);

    uint32_t get_demod_channels();

    uint32_t get_demod_decimation();
    float get_demod_bandwidth();

    float get_demod_sampling_frequency();
    void set_demod_sampling_frequency(float freq);

    float get_demod_xy_sampling_frequency();
    void set_demod_xy_sampling_frequency(float freq);

    uint32_t get_demod_delay_x_max(uint32_t channel);
    uint32_t get_demod_delay_x(uint32_t channel);
    void set_demod_delay_x(uint32_t channel, uint32_t delay);

    float get_demod_phase_x_max(uint32_t channel);
    float get_demod_phase_x_res(uint32_t channel);
    float get_demod_phase_x(uint32_t channel);
    void set_demod_phase_x(uint32_t channel, float phase);

    uint32_t get_demod_delay_y_max(uint32_t channel);
    uint32_t get_demod_delay_y(uint32_t channel);
    void set_demod_delay_y(uint32_t channel, uint32_t delay);

    float get_demod_phase_y_max(uint32_t channel);
    float get_demod_phase_y_res(uint32_t channel);
    float get_demod_phase_y(uint32_t channel);
    void set_demod_phase_y(uint32_t channel, float phase);

    float get_demod_pga_gain_max(uint32_t channel);
    float get_demod_pga_gain(uint32_t channel);
    void set_demod_pga_gain(uint32_t channel, float gain);

    float get_demod_adc_min_ratio(uint32_t channel);
    float get_demod_adc_max_ratio(uint32_t channel);

    uint32_t get_demod_packet_length_max();
    uint32_t get_demod_packet_length();

    bool get_demod_mixerless();

    bool get_demod_bypass();
    void set_demod_bypass(bool bypass);

    bool get_test_mode();
    void set_test_mode(bool test_mode);

    void restart();

    uint32_t get_adc_sample_count();
    uint32_t get_dac_sample_count();
    uint32_t get_demod_sample_count();

    int start_streaming(int32_t channels, bool simulate, bool raw, LokiFIFO *out);
    void stop_streaming();
    void force_stop();
    bool is_streaming();
    unsigned get_dropped_packets();

    void print_config();
}
