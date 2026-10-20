
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.CORDICAngleTestbench_cfg.all;

entity CORDICAngleTestbench is
end CORDICAngleTestbench;

architecture Simulation of CORDICAngleTestbench is
    signal clk, reset, s_valid : std_logic := '0';
    signal m_ready             : std_logic := '0';
    signal s_ready, m_valid    : std_logic;
    signal s_x, s_y            : sfixed(TB_COORD_INTEGER_WIDTH - 1 downto -TB_COORD_FRACTIONAL_WIDTH);
    signal m_angle             : sfixed(2 downto -CORDIC_ANGLE_FRACTIONAL_WIDTH);
    signal m_angle_real        : real;
    signal terminate           : boolean   := false;

    constant ERROR_MAX : real := 2.0 ** (-minimum(TB_COORD_FRACTIONAL_WIDTH, CORDIC_ANGLE_FRACTIONAL_WIDTH));
begin
    cordic_angle_inst : entity work.CORDICAngle
        generic map(
            ROTATIONS_PER_CYCLE => TB_ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i     => clk,
            reset_i   => reset,
            s_valid_i => s_valid,
            s_ready_o => s_ready,
            s_x_i     => s_x,
            s_y_i     => s_y,
            m_valid_o => m_valid,
            m_ready_i => m_ready,
            m_angle_o => m_angle
        );

    clk   <= not clk after TB_CLK_PERIOD / 2;
    reset <= '1', '0' after TB_CLK_PERIOD;

    p_master : process
        file csv                            : text open read_mode is "build/tb/CORDICAngleTestbench_in.csv";
        variable csv_line                   : line;
        variable angle_real, x_real, y_real : real;
    begin
        while not endfile(csv) loop
            wait until rising_edge(clk) and reset = '0';

            readline(csv, csv_line);

            read(csv_line, x_real);
            read(csv_line, y_real);
            read(csv_line, angle_real);

            s_x     <= to_sfixed(x_real, s_x'left, s_x'right);
            s_y     <= to_sfixed(y_real, s_y'left, s_y'right);
            s_valid <= '1';

            wait until rising_edge(clk) and s_ready = '1';

            m_angle_real <= angle_real;

            s_valid <= '0';
        end loop;

        terminate <= true;
        wait;
    end process p_master;

    p_slave : process
        variable success      : natural := 0;
        variable err, err_max : real    := 0.0;
        variable count        : natural := 0;
    begin
        wait until rising_edge(clk) and reset = '0';

        while not terminate loop
            wait until rising_edge(clk) and m_valid = '1';

            err := abs(to_real(m_angle) - m_angle_real);
            while err > MATH_PI loop
                err := err - MATH_2_PI;
            end loop;

            err_max := maximum(err_max, err);

            count := count + 1;

            if err <= ERROR_MAX then
                success := success + 1;
            else
                report "Sortie incorrecte. x="        & real'image(to_real(s_x))  &
                                         " y="        & real'image(to_real(s_y))  &
                                         " angle="    & real'image(to_real(m_angle)) &
                                         " (attendu " & to_string(m_angle_real) &
                                         " erreur= "  & real'image(err) & ")"
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
