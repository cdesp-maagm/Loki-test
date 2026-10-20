
package LokiModem_pkg is

    -- -------------------------------------------------------------------------
    -- Plan d'adressage.
    -- -------------------------------------------------------------------------

    type Register_t is (
        REG_CLK_FREQUENCY,                -- Constant, en lecture seule
        REG_CONTROL,                      -- Bit 0 avec remise à zéro automatique
        REG_DAC_SAMPLE_COUNT,             -- Variable, en lecture seule
        REG_ADC_SAMPLE_COUNT,             -- Variable, en lecture seule
        REG_CLKMON_SECONDS,
        REG_CLKMON_DELTA,
        REG_GPIO,

        REG_MOD_SAMPLE_FREQUENCY_REF,     -- Constant, en lecture seule
        REG_MOD_CYCLES_PER_SAMPLE_MAX,    -- Constant, en lecture seule
        REG_MOD_OSC1_WAVE_FREQUENCY_MIN,  -- Constant, en lecture seule
        REG_MOD_OSC2_WAVE_FREQUENCY_MIN,  -- Constant, en lecture seule
        REG_MOD_GAIN_INTEGER_WIDTH,       -- Constant, en lecture seule
        REG_MOD_GAIN_FRACTIONAL_WIDTH,    -- Constant, en lecture seule
        REG_MOD_PHASE_AMPLITUDE_MAX,      -- Constant, en lecture seule
        REG_MOD_PHASE_INTEGER_WIDTH,      -- Constant, en lecture seule
        REG_MOD_PHASE_FRACTIONAL_WIDTH,   -- Constant, en lecture seule
        REG_MOD_CYCLES_PER_SAMPLE,
        REG_MOD_OSC1_STEP,
        REG_MOD_OSC1_GAIN,
        REG_MOD_OSC2_STEP,
        REG_MOD_OSC2_GAIN,
        REG_MOD_OFFSET,
        REG_MOD_DC_VALUE_MAX,             -- Constant, en lecture seule
        REG_MOD_DC_VALUE_WIDTH,           -- Constant, en lecture seule
        REG_MOD_DC_VALUE,
        REG_MOD_PGA_GAIN_WIDTH,           -- Constant, en lecture seule
        REG_MOD_PGA_GAIN,

        REG_DEMOD_CHANNELS,                   -- Constant, en lecture seule
        REG_DEMOD_CHANNEL_OUTPUT_WIDTH,       -- Constant, en lecture seule
        REG_DEMOD_POWER_INTEGER_WIDTH,        -- Constant, en lecture seule
        REG_DEMOD_POWER_FRACTIONAL_WIDTH,     -- Constant, en lecture seule
        REG_DEMOD_SAMPLE_FREQUENCY_REF,       -- Constant, en lecture seule
        REG_DEMOD_CYCLES_PER_SAMPLE_MAX,      -- Constant, en lecture seule
        REG_DEMOD_OSC_WAVE_FREQUENCY_MIN,     -- Constant, en lecture seule
        REG_DEMOD_FIR1_DECIMATION,            -- Constant, en lecture seule
        REG_DEMOD_FIR1_LENGTH,                -- Constant, en lecture seule
        REG_DEMOD_FIR1_BANDWIDTH,             -- Constant, en lecture seule
        REG_DEMOD_FIR2_DECIMATION,            -- Constant, en lecture seule
        REG_DEMOD_FIR2_LENGTH,                -- Constant, en lecture seule
        REG_DEMOD_FIR2_BANDWIDTH,             -- Constant, en lecture seule
        REG_DEMOD_XY_INTEGER_WIDTH,           -- Constant, en lecture seule
        REG_DEMOD_XY_FRACTIONAL_WIDTH,        -- Constant, en lecture seule
        REG_DEMOD_PACKET_LENGTH_MAX,          -- Constant, en lecture seule
        REG_DEMOD_SAMPLE_COUNT,               -- Variable, en lecture seule
        REG_DEMOD_CYCLES_PER_SAMPLE,
        REG_DEMOD_OSC_STEP,                   -- Seulement en mode "mixing"
        REG_DEMOD_PACKET_LENGTH
    );

    constant REG_DEMOD_CHANNEL_CFG : positive := Register_t'pos(Register_t'high) + 1;

    type DemodChannelConfigRegister_t is (
        REG_DEMOD_DELAY_LOWPASS_X,
        REG_DEMOD_DELAY_LOWPASS_Y,
        REG_DEMOD_DELAY_BANDPASS_X,
        REG_DEMOD_DELAY_BANDPASS_Y,
        REG_DEMOD_PGA_GAIN,
        REG_DEMOD_ADC_MIN,
        REG_DEMOD_ADC_MAX
    );

    constant REG_DEMOD_CHANNEL_CFG_COUNT : positive := DemodChannelConfigRegister_t'pos(DemodChannelConfigRegister_t'high) + 1;

end LokiModem_pkg;
