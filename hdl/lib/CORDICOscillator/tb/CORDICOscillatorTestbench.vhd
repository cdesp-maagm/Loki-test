
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.CORDIC_pkg.all;
use work.CORDICOscillatorTestbench_cfg.all;

entity CORDICOscillatorTestbench is
end CORDICOscillatorTestbench;

architecture Simulation of CORDICOscillatorTestbench is
    constant ANGLE_STEP : Angle_t := to_sfixed(MATH_2_PI * real(TB_WAVE_FREQUENCY) / real(TB_SAMPLE_FREQUENCY), Angle_t'left, Angle_t'right);
    constant SAMPLE_COUNT : integer := TB_PERIODS * TB_SAMPLE_FREQUENCY / TB_WAVE_FREQUENCY;

    signal clk, reset, m_ready : std_logic := '0';
    signal m_valid : std_logic;
    signal m_cos, m_sin : sfixed(TB_COORD_INTEGER_WIDTH - 1 downto -TB_COORD_FRACTIONAL_WIDTH);

    constant ERROR_MAX : real := 1.0e-6;
begin
    oscillator_inst : entity work.CORDICOscillator
        generic map(
            ROTATIONS_PER_CYCLE => TB_ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i     => clk,
            reset_i   => reset,
            step_i    => ANGLE_STEP,
            m_valid_o => m_valid,
            m_ready_i => m_ready,
            m_cos_o   => m_cos,
            m_sin_o   => m_sin
        );

    clk <= not clk after TB_CLK_PERIOD / 2;
    reset <= '1', '0' after TB_CLK_PERIOD;

    p_slave : process
        file csv                                      : text open write_mode is "build/tb/CORDICOscillatorTestbench_out.csv";
        variable csv_line                             : line;
        variable cos_real, sin_real, cos_ref, sin_ref : real;
        variable cos_err, sin_err, err_max            : real;
        variable phi                                  : real := 0.0;
        variable success                              : natural;
    begin
        wait until reset = '0';

        for k in 0 to SAMPLE_COUNT - 1 loop
            wait until rising_edge(clk) and m_valid = '1';

            cos_real := to_real(m_cos);
            sin_real := to_real(m_sin);

            phi := MATH_2_PI * real(k) * real(TB_WAVE_FREQUENCY) / real(TB_SAMPLE_FREQUENCY);

            cos_ref := cos(phi);
            sin_ref := sin(phi);

            write(csv_line, cos_real);
            write(csv_line, string'(","));
            write(csv_line, sin_real);
            write(csv_line, string'(","));
            write(csv_line, cos_ref);
            write(csv_line, string'(","));
            write(csv_line, sin_ref);
            writeline(csv, csv_line);

            cos_err := abs(cos_real - cos_ref);
            sin_err := abs(sin_real - sin_ref);

            err_max := maximum(err_max, maximum(cos_err, sin_err));

            if cos_err <= ERROR_MAX and sin_err <= ERROR_MAX then
                success := success + 1;
            else
                report "Sortie incorrecte. angle="       & real'image(phi) &
                                         " cos="         & real'image(cos_real)  &
                                         " (attendu "    & real'image(cos_ref) &
                                         " erreur= "     & real'image(cos_err) & ")" &
                                         " sin="         & real'image(sin_real)  &
                                         " (attendu "    & real'image(sin_ref) &
                                         " erreur= "     & real'image(sin_err) & ")"
                    severity error;
            end if;

            m_ready <= '1';

            wait until rising_edge(clk);

            m_ready <= '0';

            wait for 1 sec / TB_SAMPLE_FREQUENCY - TB_CLK_PERIOD;
        end loop;

        report "Succès " & integer'image(success) & " / " & integer'image(SAMPLE_COUNT) & " ; Erreur max = " & real'image(err_max);

        finish;
    end process p_slave;
end Simulation;
