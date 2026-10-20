
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.CORDICOscillatorExample_cfg.all;

entity CORDICOscillatorExample is
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        step_i    : in  std_logic_vector(EX_STEP_WIDTH - 1 downto 0);
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_cos_o   : out std_logic_vector(EX_COORD_WIDTH - 1 downto 0);
        m_sin_o   : out std_logic_vector(EX_COORD_WIDTH - 1 downto 0)
    );
end CORDICOscillatorExample;

architecture RTL of CORDICOscillatorExample is
    signal step  : sfixed(2 downto 3 - step_i'length);
    signal m_cos : sfixed(1 downto 2 - m_cos_o'length);
    signal m_sin : sfixed(1 downto 2 - m_sin_o'length);
begin
    step    <= sfixed(step_i);
    m_cos_o <= to_std_logic_vector(m_cos);
    m_sin_o <= to_std_logic_vector(m_sin);

    oscillator_inst : entity work.CORDICOscillator(RTL)
        generic map(
            ROTATIONS_PER_CYCLE => EX_ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            step_i    => step,
            m_valid_o => m_valid_o,
            m_ready_i => m_ready_i,
            m_cos_o   => m_cos,
            m_sin_o   => m_sin
        );
end RTL;
