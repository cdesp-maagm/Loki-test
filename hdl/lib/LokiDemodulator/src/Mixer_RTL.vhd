
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;

entity Mixer is
    generic(
        CHANNELS : positive
    );
    port(
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        s0_valid_i   : in  std_logic;
        s0_ready_o   : out std_logic;
        s0_last_i    : in  std_logic;
        s0_channel_i : in  natural range 0 to CHANNELS - 1;
        s0_power_i   : in  sfixed;
        s1_valid_i   : in  std_logic;
        s1_ready_o   : out std_logic;
        s1_cos_i     : in  SinCosArray_t(0 to 2 * CHANNELS - 1);
        m_valid_o    : out std_logic;
        m_ready_i    : in  std_logic;
        m_last_o     : out std_logic;
        m_channel_o  : out natural range 0 to CHANNELS - 1;
        m_x_o        : out sfixed;
        m_y_o        : out sfixed
    );
end Mixer;

architecture RTL of Mixer is
    signal s_valid : std_logic_vector(0 to 1);
    signal s_ready : std_logic;
begin
    s_valid <= s0_valid_i & s1_valid_i;

    s0_ready_o <= s_ready;
    s1_ready_o <= s_ready and s0_last_i;

    stream_inst : entity work.StreamController
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            s_valid_i => s_valid,
            s_ready_o => s_ready,
            m_valid_o => m_valid_o,
            m_ready_i => m_ready_i
        );

    p_last_channel_x_y_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if s_ready = '1' then
                m_last_o    <= s0_last_i;
                m_channel_o <= s0_channel_i;
                m_x_o       <= resize(s0_power_i * s1_cos_i(s0_channel_i * 2),     m_x_o'left, m_x_o'right);
                m_y_o       <= resize(s0_power_i * s1_cos_i(s0_channel_i * 2 + 1), m_y_o'left, m_y_o'right);
            end if;
        end if;
    end process p_last_channel_x_y_o;
end RTL;
