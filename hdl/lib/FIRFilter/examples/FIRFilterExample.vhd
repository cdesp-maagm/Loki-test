
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.FIRFilter_pkg.all;
use work.FIRFilterExample_cfg.all;
use work.FIRFilterExample_pkg.all;

entity FIRFilterExample is
    port(
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        s_valid_i   : in  std_logic;
        s_last_i    : in  std_logic;
        s_ready_o   : out std_logic;
        s_channel_i : in  integer range 0 to EX_CHANNELS - 1;
        s_data_i    : in  std_logic_vector(EX_DATA_INTEGER_WIDTH + EX_DATA_FRACTIONAL_WIDTH - 1 downto 0);
        m_valid_o   : out std_logic;
        m_last_o    : out std_logic;
        m_ready_i   : in  std_logic;
        m_channel_o : out integer range 0 to EX_CHANNELS - 1;
        m_data_o    : out std_logic_vector(EX_DATA_INTEGER_WIDTH + EX_DATA_FRACTIONAL_WIDTH + GAIN_BITS - 1 downto 0)
    );
end FIRFilterExample;

architecture RTL of FIRFilterExample is
    signal s_data : sfixed(EX_DATA_INTEGER_WIDTH - 1 downto -EX_DATA_FRACTIONAL_WIDTH);
    signal m_data : sfixed(EX_DATA_INTEGER_WIDTH + GAIN_BITS - 1 downto -EX_DATA_FRACTIONAL_WIDTH);
begin
    s_data <= sfixed(s_data_i);
    m_data_o <= to_std_logic_vector(m_data);

    filter_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => EX_PARALLELISM,
            CHANNELS     => EX_CHANNELS,
            GAIN_BITS    => GAIN_BITS,
            COEFFICIENTS => COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => s_valid_i,
            s_ready_o   => s_ready_o,
            s_last_i    => s_last_i,
            s_channel_i => s_channel_i,
            s_data_i    => s_data,
            m_valid_o   => m_valid_o,
            m_ready_i   => m_ready_i,
            m_last_o    => m_last_o,
            m_channel_o => m_channel_o,
            m_data_o    => m_data
        );
end RTL;
