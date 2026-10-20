
%nodefaultctor LokiSystemConfig;
%nodefaultdtor LokiSystemConfig;

struct LokiSystemConfig {};

%extend LokiSystemConfig {
    LokiSystemConfig() {
        return LokiSystemConfig_new();
    }

    ~LokiSystemConfig() {
        LokiSystemConfig_del($self);
    }

    bool get_simulate();
    void set_simulate(bool value);
    float get_skip();
    void set_skip(float value);
    float get_scale();

    const char *get_estimator_name();
    void set_estimator_name(const char *name);
    unsigned get_estimator_throttle();
    void set_estimator_throttle(unsigned value);
    float get_estimator_initial_radius();
    void set_estimator_initial_radius(float value);
    float get_wavelength();
    void set_wavelength(float value);
    unsigned get_reflections();
    void set_reflections(unsigned value);
    float get_cavity_index();
    void set_cavity_index(float value);
    char get_distance_unit();
    void set_distance_unit(char value);

    size_t get_estimator_params_length();
    float get_estimator_param(size_t index) {
        if (index < LokiSystemConfig_get_estimator_params_length($self)) {
            return LokiSystemConfig_get_estimator_params($self)[index];
        }
        return 0;
    }
    void set_estimator_param(size_t index, float value) {
        if (index < LokiSystemConfig_get_estimator_params_length($self)) {
            LokiSystemConfig_get_estimator_params($self)[index] = value;
        }
    }

    float get_filter_bandwidth();
    void set_filter_bandwidth(float value);
    float get_filter_attenuation();
    void set_filter_attenuation(float value);
    size_t get_filter_length();
    void set_filter_length(size_t value);
    unsigned get_filter_decimation();
    void set_filter_decimation(unsigned value);

    size_t get_time_constants_length();
    float get_time_constant(size_t index) {
        if (index < LokiSystemConfig_get_time_constants_length($self)) {
            return LokiSystemConfig_get_time_constants($self)[index];
        }
        return 0;
    }
    void set_time_constant(size_t index, float value) {
        if (index < LokiSystemConfig_get_time_constants_length($self)) {
            LokiSystemConfig_get_time_constants($self)[index] = value;
        }
    }
}

%nodefaultctor LokiSystem;
%nodefaultdtor LokiSystem;

struct LokiSystem {};

%extend LokiSystem {
    LokiSystem(LokiSystemConfig *config, LokiModem *modem=NULL) {
        return LokiSystem_new(config, modem);
    }

    ~LokiSystem() {
        LokiSystem_del($self);
    }

    size_t get_sample_size() {
        return sizeof(LokiSystemSample);
    }

    LokiModem *get_modem();
    float get_sampling_frequency();
    void displacement_reset();
    int start_streaming(int32_t channels, LokiFIFO *modem_out, LokiFIFO *disp_out, size_t cid=0);
    void stop_streaming();
    bool is_streaming();
    LokiEllipse *get_ellipse(size_t channel);
}
