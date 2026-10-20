
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.FIRFilter_pkg.all;

entity LokiDemodulatorMixerless is
    generic(
        CHANNELS                : positive;
        CYCLES_PER_SAMPLE_MAX   : positive;
        LOWPASS_PARALLELISM     : positive;
        LOWPASS_GAIN_BITS       : natural;
        LOWPASS_COEFFICIENTS    : CoefficientMatrix_t;
        BANDPASS_PARALLELISM    : positive;
        BANDPASS_X_GAIN_BITS    : natural;
        BANDPASS_X_COEFFICIENTS : CoefficientMatrix_t;
        BANDPASS_Y_GAIN_BITS    : natural;
        BANDPASS_Y_COEFFICIENTS : CoefficientMatrix_t
    );
    port(
        clk_i                 : in  std_logic;
        reset_i               : in  std_logic;
        cycles_per_sample_i   : in  positive range 1 to CYCLES_PER_SAMPLE_MAX;
        s_valid_i             : in  std_logic;
        s_ready_o             : out std_logic;
        s_last_i              : in  std_logic;
        s_channel_i           : in  natural range 0 to CHANNELS - 1;
        s_lowpass_delay_x_i   : in  natural range LOWPASS_COEFFICIENTS'range(1);
        s_lowpass_delay_y_i   : in  natural range LOWPASS_COEFFICIENTS'range(1);
        s_bandpass_delay_x_i  : in  natural range BANDPASS_X_COEFFICIENTS'range(1);
        s_bandpass_delay_y_i  : in  natural range BANDPASS_X_COEFFICIENTS'range(1);
        s_power_i             : in  sfixed;
        m_valid_o             : out std_logic;
        m_ready_i             : in  std_logic;
        m_last_o              : out std_logic;
        m_channel_o           : out natural range 0 to CHANNELS - 1;
        m_x_o                 : out sfixed;
        m_y_o                 : out sfixed
    );
begin
    assert BANDPASS_X_COEFFICIENTS'length(1) = BANDPASS_Y_COEFFICIENTS'length(1) and
           BANDPASS_X_COEFFICIENTS'length(2) = BANDPASS_Y_COEFFICIENTS'length(2)
        report "Bandpass filters for X and Y must have the same number of coefficients and the same decimation"
        severity failure;
end LokiDemodulatorMixerless;
