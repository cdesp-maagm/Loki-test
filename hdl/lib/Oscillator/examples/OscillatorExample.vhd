
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;
use work.OscillatorExample_cfg.all;
use work.OscillatorExample_pkg.all;

entity OscillatorExample is
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        restart_i : in  std_logic;
        steps_i   : in  integer_vector(0 to EX_CHANNELS - 1);
        delays_i  : in  integer_vector(0 to EX_CHANNELS - 1);
        m_valid_o : out std_logic;
        m_ready_i : in  std_logic;
        m_cos0_o  : out std_logic_vector(SinCos_t'length - 1 downto 0);
        m_sin0_o  : out std_logic_vector(SinCos_t'length - 1 downto 0);
        m_cos1_o  : out std_logic_vector(SinCos_t'length - 1 downto 0);
        m_sin1_o  : out std_logic_vector(SinCos_t'length - 1 downto 0)
    );
end OscillatorExample;

architecture RTL of OscillatorExample is
    signal m_cos, m_sin : SinCosArray_t(0 to 1);
begin
    m_cos0_o <= to_std_logic_vector(m_cos(0));
    m_sin0_o <= to_std_logic_vector(m_sin(0));
    m_cos1_o <= to_std_logic_vector(m_cos(1));
    m_sin1_o <= to_std_logic_vector(m_sin(1));

    oscillator_inst : entity work.Oscillator(RTL)
        generic map(
            CHANNELS     => EX_CHANNELS,
            LOOKUP_TABLE => LOOKUP_TABLE
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            restart_i => restart_i,
            steps_i   => steps_i,
            delays_i  => delays_i,
            m_valid_o => m_valid_o,
            m_ready_i => m_ready_i,
            m_cos_o   => m_cos,
            m_sin_o   => m_sin
        );
end RTL;
