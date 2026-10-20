
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.DelayLineExamples_cfg.all;

entity DelayLineRAMExample is
    port(
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        enable_i : in  std_logic;
        data_i   : in  std_logic_vector(EX_DATA_WIDTH - 1 downto 0);
        data_o   : out std_logic_vector(EX_DATA_WIDTH - 1 downto 0)
    );
end DelayLineRAMExample;

architecture RTL of DelayLineRAMExample is
    signal data_i_sf, data_o_sf : sfixed(EX_INTEGER_WIDTH - 1 downto -EX_FRACTIONAL_WIDTH);
begin
    data_i_sf <= sfixed(data_i);
    data_o    <= to_std_logic_vector(data_o_sf);

    delay_inst : entity work.DelayLine(RAM)
        generic map(
            LENGTH => EX_LENGTH
        )
        port map(
            clk_i    => clk_i,
            reset_i  => reset_i,
            enable_i => enable_i,
            data_i   => data_i_sf,
            data_o   => data_o_sf
        );
end RTL;
