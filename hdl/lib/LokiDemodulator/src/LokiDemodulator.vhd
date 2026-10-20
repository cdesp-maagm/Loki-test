
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;
use work.FIRFilter_pkg.all;

entity LokiDemodulator is
    generic(
        CHANNELS              : positive;
        CYCLES_PER_SAMPLE_MAX : positive;
        LOOKUP_TABLE          : SinCosArray_t;
        LOWPASS1_PARALLELISM  : positive;
        LOWPASS1_GAIN_BITS    : natural;
        LOWPASS1_COEFFICIENTS : CoefficientMatrix_t;
        LOWPASS2_PARALLELISM  : positive;
        LOWPASS2_GAIN_BITS    : natural;
        LOWPASS2_COEFFICIENTS : CoefficientMatrix_t
    );
    port(
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        cycles_per_sample_i : in  positive range 1 to CYCLES_PER_SAMPLE_MAX;
        osc_step_i          : in  natural range 0 to LOOKUP_TABLE'high;
        osc_delays_i        : in  integer_vector(0 to 2 * CHANNELS - 1);
        restart_i           : in  std_logic;
        s_valid_i           : in  std_logic;
        s_ready_o           : out std_logic;
        s_last_i            : in  std_logic;
        s_channel_i         : in  natural range 0 to CHANNELS - 1;
        s_power_i           : in  sfixed;
        m_valid_o           : out std_logic;
        m_ready_i           : in  std_logic;
        m_last_o            : out std_logic;
        m_channel_o         : out natural range 0 to CHANNELS - 1;
        m_x_o               : out sfixed;
        m_y_o               : out sfixed
    );
end LokiDemodulator;
