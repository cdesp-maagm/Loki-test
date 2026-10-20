
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;

entity LokiModulator is
    generic(
        CYCLES_PER_SAMPLE_MAX : positive;
        LOOKUP_TABLE_1        : SinCosArray_t;
        LOOKUP_TABLE_2        : SinCosArray_t
    );
    port(
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        cycles_per_sample_i : in  positive range 1 to CYCLES_PER_SAMPLE_MAX;
        restart_i           : in  std_logic;
        step1_i             : in  natural range 0 to LOOKUP_TABLE_1'high;
        step2_i             : in  natural range 0 to LOOKUP_TABLE_2'high;
        gain1_i             : in  sfixed;
        gain2_i             : in  sfixed;
        m_valid_o           : out std_logic;
        m_ready_i           : in  std_logic;
        m_phase_o           : out sfixed
    );
end LokiModulator;
