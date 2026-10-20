
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.env.all; -- GHDL

use std.textio.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;
use work.OscillatorTestbench_pkg.all;
use work.OscillatorTestbench_cfg.all;

entity OscillatorTestbench is
end OscillatorTestbench;

architecture Simulation of OscillatorTestbench is
    constant SAMPLE_COUNT               : integer                              := TB_PERIODS * TB_SAMPLE_FREQUENCY / maximum(TB_WAVE_FREQUENCY, TB_WAVE_FREQUENCY_MIN);
    constant LOOKUP_STEPS               : integer_vector(0 to TB_CHANNELS - 1) := (others => TB_WAVE_FREQUENCY / TB_WAVE_FREQUENCY_MIN);
    signal delays                       : integer_vector(0 to TB_CHANNELS - 1);

    signal clk, reset, restart, m_ready : std_logic                         := '0';
    signal m_valid                      : std_logic;
    signal m_cos, m_sin                 : SinCosArray_t(0 to TB_CHANNELS - 1);

    constant ERROR_MAX                  : real                              := 2.0 ** (-OSC_SIN_COS_FRACTIONAL_WIDTH);
begin
    osc_gen : for i in 0 to TB_CHANNELS - 1 generate
        delays(i) <= 4 * i * LOOKUP_TABLE'high / TB_CHANNELS;
    end generate osc_gen;

    oscillator_inst : entity work.Oscillator
        generic map(
            CHANNELS     => TB_CHANNELS,
            LOOKUP_TABLE => LOOKUP_TABLE
        )
        port map(
            clk_i     => clk,
            reset_i   => reset,
            restart_i => restart,
            steps_i   => LOOKUP_STEPS,
            delays_i  => delays,
            m_valid_o => m_valid,
            m_ready_i => m_ready,
            m_cos_o   => m_cos,
            m_sin_o   => m_sin
        );

    clk <= not clk after TB_CLK_PERIOD / 2;
    reset <= '1', '0' after TB_CLK_PERIOD;

    p_slave : process
        variable cos_real, sin_real, cos_expected, sin_expected : real;
        variable cos_err, sin_err, err_max                      : real;
        variable phi                                            : real := 0.0;
        variable success                                        : natural;
        file csv                                                : text open write_mode is "build/tb/OscillatorTestbench_out.csv";
        variable csv_line                                       : line;
    begin
        wait until reset = '0';

        restart <= '1';

        wait until rising_edge(clk);

        restart <= '0';

        for k in 0 to SAMPLE_COUNT - 1 loop
            wait until rising_edge(clk) and m_valid = '1';

            for i in 0 to TB_CHANNELS - 1 loop
                cos_real := to_real(m_cos(i));
                sin_real := to_real(m_sin(i));

                phi := MATH_2_PI * real(k * LOOKUP_STEPS(i) - delays(i)) * real(TB_WAVE_FREQUENCY_MIN) / real(TB_SAMPLE_FREQUENCY);

                cos_expected := cos(phi);
                sin_expected := sin(phi);

                write(csv_line, cos_real);
                write(csv_line, string'(","));
                write(csv_line, cos_expected);
                write(csv_line, string'(","));
                write(csv_line, sin_real);
                write(csv_line, string'(","));
                write(csv_line, sin_expected);
                if i < TB_CHANNELS - 1 then
                    write(csv_line, string'(","));
                end if;

                cos_err := abs(cos_real - cos_expected);
                sin_err := abs(sin_real - sin_expected);

                err_max := maximum(err_max, maximum(cos_err, sin_err));

                if cos_err <= ERROR_MAX and sin_err <= ERROR_MAX then
                    success := success + 1;
                else
                    report "Sortie incorrecte. osc="      & integer'image(i) &
                                             " angle="    & real'image(phi) &
                                             " cos="      & real'image(cos_real)  &
                                             " (attendu " & real'image(cos_expected) &
                                             " erreur= "  & real'image(cos_err) & ")" &
                                             " sin="      & real'image(sin_real)  &
                                             " (attendu " & real'image(sin_expected) &
                                             " erreur= "  & real'image(sin_err) & ")"
                        severity error;
                end if;
            end loop;
            writeline(csv, csv_line);

            m_ready <= '1';

            wait until rising_edge(clk);

            m_ready <= '0';

            wait for 1 sec / TB_SAMPLE_FREQUENCY - TB_CLK_PERIOD;
        end loop;

        report "Succès " & integer'image(success) & " / " & integer'image(SAMPLE_COUNT * m_cos'length) & " ; Erreur max = " & real'image(err_max);

        finish;
    end process p_slave;
end Simulation;
