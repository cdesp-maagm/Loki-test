
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

entity CORDIC is
    generic(
        ROTATIONS_PER_CYCLE : positive := 1
    );
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        s_valid_i : in  std_logic;
        s_ready_o : out std_logic;
        s_angle_i : in  sfixed;
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_cos_o   : out sfixed;
        m_sin_o   : out sfixed
    );
end CORDIC;
