
library ieee;
use ieee.std_logic_1164.all;

use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.DelayLineTestbench_cfg.all;

entity DelayLineTestbench is
end DelayLineTestbench;

architecture Simulation of DelayLineTestbench is
    signal clk_i, reset_i, enable_i         : std_logic := '0';
    signal data_i, shift_data_o, ram_data_o : sfixed(TB_DATA_HIGH downto TB_DATA_LOW);
    constant DATA_MIN                       : integer   := -2 ** (TB_DATA_HIGH - 1);
    constant DATA_MAX                       : integer   := 2 ** (TB_DATA_HIGH - 1) - 1;
begin

    delay_line_shift_inst : entity work.DelayLine(ShiftRegisters)
        generic map(
            LENGTH => TB_LENGTH
        )
        port map(
            clk_i    => clk_i,
            reset_i  => reset_i,
            enable_i => enable_i,
            data_i   => data_i,
            data_o   => shift_data_o
        );

    delay_line_ram_inst : entity work.DelayLine(RAM)
        generic map(
            LENGTH => TB_LENGTH
        )
        port map(
            clk_i    => clk_i,
            reset_i  => reset_i,
            enable_i => enable_i,
            data_i   => data_i,
            data_o   => ram_data_o
        );

    clk_i   <= not clk_i after TB_CLK_PERIOD / 2;
    reset_i <= '1', '0' after TB_CLK_PERIOD;

    p_data_i : process
    begin
        data_i <= to_sfixed(0, data_i'left, data_i'right);

        wait until rising_edge(clk_i) and reset_i = '0';

        for i in DATA_MIN to DATA_MAX loop
            data_i   <= to_sfixed(i, data_i);
            enable_i <= '1';

            wait for TB_CLK_PERIOD;

            enable_i <= '0';

            wait for TB_CLK_PERIOD * (TB_PERIODS_PER_SAMPLE - 1);
        end loop;

        finish;
    end process p_data_i;

    p_compare : process(clk_i)
    begin
        if rising_edge(clk_i) and data_i - DATA_MIN > TB_LENGTH and enable_i = '1' then
            assert ram_data_o = shift_data_o
                report "Valeurs différentes: data(RAM)="   & to_string(ram_data_o)
                    & " data(Shift)=" & to_string(shift_data_o)
                severity error;

            assert ram_data_o = data_i - TB_LENGTH
                report "Valeur incorrecte: data_o=" & to_string(ram_data_o)
                    & " attendu=" & to_string(data_i)
                severity error;
        end if;
    end process p_compare;
end Simulation;
