
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;

entity Oscillator is
    generic(
        CHANNELS     : positive;
        LOOKUP_TABLE : SinCosArray_t
    );
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        restart_i : in  std_logic;
        steps_i   : in  integer_vector(0 to CHANNELS - 1);
        delays_i  : in  integer_vector(0 to CHANNELS - 1);
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_cos_o   : out SinCosArray_t(0 to CHANNELS - 1);
        m_sin_o   : out SinCosArray_t(0 to CHANNELS - 1)
    );
end Oscillator;
