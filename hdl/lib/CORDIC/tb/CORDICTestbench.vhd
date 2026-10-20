
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.CORDICTestbench_cfg.all;

entity CORDICTestbench is
end CORDICTestbench;

architecture Simulation of CORDICTestbench is
    signal clk, reset             : std_logic := '0';
    signal s_valid, m_ready       : std_logic := '0';
    signal s_ready, m_valid       : std_logic;
    signal s_angle                : sfixed(2 downto -CORDIC_ANGLE_FRACTIONAL_WIDTH);
    signal m_cos, m_sin           : sfixed(TB_COORD_INTEGER_WIDTH - 1 downto -TB_COORD_FRACTIONAL_WIDTH);
    signal m_cos_real, m_sin_real : real;
    signal terminate              : boolean := false;

    constant ERROR_MAX            : real := 2.0 ** (-minimum(TB_COORD_FRACTIONAL_WIDTH, CORDIC_ANGLE_FRACTIONAL_WIDTH));
begin
    cordic_inst : entity work.CORDIC
        generic map(
            ROTATIONS_PER_CYCLE => TB_ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i     => clk,
            reset_i   => reset,
            s_valid_i => s_valid,
            s_ready_o => s_ready,
            s_angle_i => s_angle,
            m_valid_o => m_valid,
            m_ready_i => m_ready,
            m_cos_o   => m_cos,
            m_sin_o   => m_sin
        );

    clk   <= not clk after TB_CLK_PERIOD / 2;
    reset <= '1', '0' after TB_CLK_PERIOD;

    p_master : process
        file csv                                : text open read_mode is "build/tb/CORDICTestbench_in.csv";
        variable csv_line                       : line;
        variable angle_real, cos_real, sin_real : real;
    begin
        while not endfile(csv) loop
            wait until rising_edge(clk) and reset = '0';

            readline(csv, csv_line);

            read(csv_line, cos_real);
            read(csv_line, sin_real);
            read(csv_line, angle_real);

            s_angle <= to_sfixed(angle_real, s_angle);
            s_valid <= '1';

            wait until rising_edge(clk) and s_ready = '1';

            m_cos_real <= cos_real;
            m_sin_real <= sin_real;

            s_valid <= '0';
        end loop;

        terminate <= true;
        wait;
    end process p_master;

    p_slave : process
        variable success : natural := 0;
        variable cos_err, sin_err, err_max : real := 0.0;
        variable count : natural := 0;
    begin
        wait until rising_edge(clk) and reset = '0';

        while not terminate loop
            wait until rising_edge(clk) and m_valid = '1';

            cos_err := abs(to_real(m_cos) - m_cos_real);
            sin_err := abs(to_real(m_sin) - m_sin_real);

            err_max := maximum(err_max, maximum(cos_err, sin_err));

            count   := count + 1;

            if cos_err <= ERROR_MAX and sin_err <= ERROR_MAX then
                success := success + 1;
            else
                report "Sortie incorrecte. angle="       & to_string(s_angle) &
                                         " x="           & to_string(m_cos)  &
                                         " (attendu "    & to_string(m_cos_real) &
                                         " erreur= "     & real'image(cos_err) & ")" &
                                         " y="           & to_string(m_sin)  &
                                         " (attendu "    & to_string(m_sin_real) &
                                         " erreur= "     & real'image(sin_err) & ")"
                    severity error;
            end if;

            m_ready <= '1';

            wait until rising_edge(clk);

            m_ready <= '0';
        end loop;

        report "Succès " & integer'image(success) & " / " & integer'image(count) & " ; Erreur max = " & real'image(err_max);

        finish;
    end process p_slave;
end Simulation;
