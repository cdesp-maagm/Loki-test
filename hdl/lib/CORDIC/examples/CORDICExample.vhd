
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.CORDICExample_cfg.all;

entity CORDICExample is
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        s_valid_i : in  std_logic;
        s_ready_o : out std_logic;
        s_angle_i : in  std_logic_vector(EX_ANGLE_WIDTH - 1 downto 0);
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_cos_o   : out std_logic_vector(EX_COORD_WIDTH - 1 downto 0);
        m_sin_o   : out std_logic_vector(EX_COORD_WIDTH - 1 downto 0)
    );
end CORDICExample;

architecture RTL of CORDICExample is
    signal s_angle      : sfixed(2 downto 3 - EX_ANGLE_WIDTH);
    signal m_cos, m_sin : sfixed(1 downto 2 - EX_COORD_WIDTH);
begin
    s_angle <= sfixed(s_angle_i);
    m_cos_o <= to_std_logic_vector(m_cos);
    m_sin_o <= to_std_logic_vector(m_sin);

    cordic_inst : entity work.CORDIC(RTL)
        generic map(
            ROTATIONS_PER_CYCLE => EX_ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            s_valid_i => s_valid_i,
            s_ready_o => s_ready_o,
            s_angle_i => s_angle,
            m_valid_o => m_valid_o,
            m_ready_i => m_ready_i,
            m_cos_o   => m_cos,
            m_sin_o   => m_sin
        );
end RTL;
