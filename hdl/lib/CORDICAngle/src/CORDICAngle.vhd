
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

entity CORDICAngle is
    generic(
        ROTATIONS_PER_CYCLE : positive := 1
    );
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        s_valid_i : in  std_logic;
        s_ready_o : out std_logic;
        s_x_i     : in  sfixed;
        s_y_i     : in  sfixed;
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_angle_o : out sfixed
    );
begin
    assert m_angle_o'left >= 2
        report "La partie entière d'un angle en radians nécessite au moins 3 bits"
        severity error;
end CORDICAngle;
