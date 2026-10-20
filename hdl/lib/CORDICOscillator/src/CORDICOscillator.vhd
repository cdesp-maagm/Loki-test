
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

entity CORDICOscillator is
    generic(
        ROTATIONS_PER_CYCLE : positive := 1
    );
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        step_i    : in  sfixed;
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_cos_o   : out sfixed;
        m_sin_o   : out sfixed
    );
begin
    assert m_cos_o'left >= 1 and m_sin_o'left >= 1
        report "La partie entière d'un cosinus ou d'un sinus nécessite au moins 2 bits"
        severity error;
end CORDICOscillator;
