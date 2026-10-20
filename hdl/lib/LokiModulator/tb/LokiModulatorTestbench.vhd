
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.LokiModulatorTestbench_cfg.all;
use work.Oscillator_pkg.all;

entity LokiModulatorTestbench is
end LokiModulatorTestbench;

architecture Simulation of LokiModulatorTestbench is
    subtype Phase_t is sfixed(TB_PHASE_INTEGER_WIDTH - 1 downto -TB_PHASE_FRACTIONAL_WIDTH);

    constant OSC1_STEP : integer := TB_OSC1_WAVE_FREQUENCY / TB_OSC1_WAVE_FREQUENCY_MIN;
    constant OSC1_GAIN : Phase_t := to_sfixed(TB_OSC1_GAIN, Phase_t'left, Phase_t'right);

    constant OSC2_STEP : integer := TB_OSC2_WAVE_FREQUENCY / TB_OSC2_WAVE_FREQUENCY_MIN;
    constant OSC2_GAIN : Phase_t := to_sfixed(TB_OSC2_GAIN, Phase_t'left, Phase_t'right);

    constant CLK_PERIOD : time := 1 sec / TB_CLK_FREQUENCY;
    constant CYCLES_PER_SAMPLE : integer := TB_CLK_FREQUENCY / TB_SAMPLE_FREQUENCY;

    constant SAMPLE_COUNT : integer := TB_SAMPLE_FREQUENCY * TB_OSC1_PERIODS / TB_OSC1_WAVE_FREQUENCY;

    signal clk, reset : std_logic := '0';

    signal mod_restart : std_logic := '0';
    signal mod_m_valid : std_logic;
    signal mod_m_phase : Phase_t;

    signal sensor_m_power : sfixed(TB_POWER_INTEGER_WIDTH - 1 downto -TB_POWER_FRACTIONAL_WIDTH);
begin
    clk <= not clk after CLK_PERIOD / 2;
    reset <= '1', '0' after CLK_PERIOD;

    mod_inst : entity work.LokiModulator
        generic map(
            CYCLES_PER_SAMPLE_MAX => CYCLES_PER_SAMPLE,
            LOOKUP_TABLE_1        => work.LokiModulatorTestbench_osc1_pkg.LOOKUP_TABLE,
            LOOKUP_TABLE_2        => work.LokiModulatorTestbench_osc2_pkg.LOOKUP_TABLE
        )
        port map(
            clk_i               => clk,
            reset_i             => reset,
            cycles_per_sample_i => CYCLES_PER_SAMPLE,
            restart_i           => mod_restart,
            step1_i             => OSC1_STEP,
            step2_i             => OSC2_STEP,
            gain1_i             => OSC1_GAIN,
            gain2_i             => OSC2_GAIN,
            m_valid_o           => mod_m_valid,
            m_ready_i           => mod_m_valid,
            m_phase_o           => mod_m_phase
        );

    sensor_inst : entity work.DisplacementSensor
        generic map(
            DELAY => TB_SENSOR_DELAY,
            DEFAULT_WAVELENGTH => TB_WAVELENGTH,
            DEPTH => TB_SENSOR_DEPTH,
            SAMPLE_FREQUENCY => real(TB_SAMPLE_FREQUENCY),
            DISPLACEMENT_FREQUENCY => TB_DISPLACEMENT_FREQUENCY,
            DISPLACEMENT_AMPLITUDE => TB_DISPLACEMENT_AMPLIUDE,
            POWER_FACTOR => TB_POWER_FACTOR,
            POWER_CONTRAST => TB_POWER_CONTRAST
        )
        port map(
            s_phase_i => mod_m_phase,
            m_power_o => sensor_m_power
        );

    p_slave : process
        file csv : text open write_mode is "build/tb/LokiModulatorTestbench_out.csv";
        variable csv_line : line;
        variable progress, progress_prev : integer := 0;
    begin
        wait until reset = '0';

        mod_restart <= '1';

        wait until rising_edge(clk);

        mod_restart <= '0';

        for k in 0 to SAMPLE_COUNT - 1 loop
            wait until rising_edge(clk) and mod_m_valid = '1';

            progress := (k + 1) * 100 / SAMPLE_COUNT;
            if progress /= progress_prev then
                report "Progress " & integer'image(progress);
                progress_prev := progress;
            end if;

            write(csv_line, to_real(mod_m_phase));
            write(csv_line, string'(","));

            wait for CLK_PERIOD / 2;

            write(csv_line, to_real(sensor_m_power));
            writeline(csv, csv_line);
        end loop;

        finish;
    end process p_slave;
end Simulation;
