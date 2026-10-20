
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.FIRFilter_pkg.all;

entity FIRFilter is
    generic(
        PARALLELISM     : positive;
        CHANNELS        : positive;
        GAIN_BITS       : natural;
        MAX_TAP_WIDTH   : positive := 18;
        MAX_COEFF_WIDTH : positive := 25;
        COEFFICIENTS    : CoefficientMatrix_t
    );
    port(
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        s_valid_i   : in  std_logic;
        s_last_i    : in  std_logic;
        s_ready_o   : out std_logic;
        s_channel_i : in  natural range 0 to CHANNELS - 1;
        s_data_i    : in  sfixed;
        m_valid_o   : out std_logic;
        m_last_o    : out std_logic;
        m_ready_i   : in  std_logic;
        m_channel_o : out natural range 0 to CHANNELS - 1;
        m_data_o    : out sfixed
    );
begin
    assert COEFFICIENTS'length(2) mod PARALLELISM = 0
        report "Valeur incorrecte pour le paramètre PARALLELISM"
        severity failure;
end FIRFilter;
