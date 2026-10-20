
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.CORDICAngleExample_cfg.all;

entity CORDICAngleExample is
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        s_valid_i : in  std_logic;
        s_ready_o : out std_logic;
        s_x_i     : in  std_logic_vector(EX_COORD_WIDTH - 1 downto 0);
        s_y_i     : in  std_logic_vector(EX_COORD_WIDTH - 1 downto 0);
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_angle_o : out std_logic_vector(EX_ANGLE_WIDTH - 1 downto 0)
    );
end CORDICAngleExample;

architecture RTL of CORDICAngleExample is
    signal m_angle  : sfixed(2 downto 3 - EX_ANGLE_WIDTH);
    signal s_x, s_y : sfixed(1 downto 2 - EX_COORD_WIDTH);
begin
    s_x       <= sfixed(s_x_i);
    s_y       <= sfixed(s_y_i);
    m_angle_o <= to_std_logic_vector(m_angle);

    cordic_inst : entity work.CORDICAngle(RTL)
        generic map(
            ROTATIONS_PER_CYCLE => EX_ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            s_valid_i => s_valid_i,
            s_ready_o => s_ready_o,
            s_x_i     => s_x,
            s_y_i     => s_y,
            m_valid_o => m_valid_o,
            m_ready_i => m_ready_i,
            m_angle_o => m_angle
        );
end RTL;
