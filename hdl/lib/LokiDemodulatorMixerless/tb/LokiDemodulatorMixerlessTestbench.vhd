
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.LokiDemodulatorMixerlessTestbench_cfg.all;
use work.Oscillator_pkg.all;

entity LokiDemodulatorMixerlessTestbench is
end LokiDemodulatorMixerlessTestbench;

architecture Simulation of LokiDemodulatorMixerlessTestbench is
    subtype Phase_t is sfixed(TB_PHASE_INTEGER_WIDTH - 1 downto -TB_PHASE_FRACTIONAL_WIDTH);

    constant OSC1_STEP : integer := TB_OSC1_WAVE_FREQUENCY / TB_OSC1_WAVE_FREQUENCY_MIN;
    constant OSC1_GAIN : Phase_t := to_sfixed(TB_OSC1_GAIN, Phase_t'left, Phase_t'right);

    constant OSC2_STEP : integer := TB_OSC2_WAVE_FREQUENCY / TB_OSC2_WAVE_FREQUENCY_MIN;
    constant OSC2_GAIN : Phase_t := to_sfixed(TB_OSC2_GAIN, Phase_t'left, Phase_t'right);

    constant CLK_PERIOD              : time    := 1 sec / TB_CLK_FREQUENCY;
    constant MOD_CYCLES_PER_SAMPLE   : integer := TB_CLK_FREQUENCY / TB_MOD_SAMPLE_FREQUENCY;
    constant DEMOD_CYCLES_PER_SAMPLE : integer := TB_CLK_FREQUENCY / TB_DEMOD_SAMPLE_FREQUENCY;
    constant XY_CYCLES_PER_SAMPLE    : integer := DEMOD_CYCLES_PER_SAMPLE * TB_LOWPASS_DECIMATION * TB_BANDPASS_DECIMATION;

    constant SAMPLE_COUNT : integer := TB_CHANNELS * TB_DEMOD_SAMPLE_FREQUENCY * TB_OSC1_PERIODS / TB_OSC1_WAVE_FREQUENCY / TB_LOWPASS_DECIMATION / TB_BANDPASS_DECIMATION;
    -- constant SAMPLE_COUNT : integer := TB_CHANNELS * TB_DEMOD_SAMPLE_FREQUENCY * 5               / TB_OSC1_WAVE_FREQUENCY / TB_LOWPASS_DECIMATION / TB_BANDPASS_DECIMATION;

    signal clk, reset : std_logic := '0';

    signal restart : std_logic := '0';
    signal mod_m_valid : std_logic;
    signal mod_m_phase : Phase_t;

    subtype Power_t is sfixed(TB_POWER_INTEGER_WIDTH - 1 downto -TB_POWER_FRACTIONAL_WIDTH);
    type PowerArray_t is array(0 to TB_CHANNELS - 1) of Power_t;
    signal sensor_s_phase_reg : Phase_t;
    signal sensor_m_power : PowerArray_t := (others => to_sfixed(0, Power_t'left, Power_t'right));

    signal demod_s_valid, demod_s_ready, demod_s_last : std_logic;
    signal demod_s_channel_reg, demod_s_channel_next : natural range 0 to TB_CHANNELS - 1;
    signal demod_s_power_reg : Power_t;
    signal demod_m_valid, demod_m_last : std_logic;
    signal demod_m_ready : std_logic := '0';
    signal demod_m_channel : natural range 0 to TB_CHANNELS - 1;
    signal demod_m_x, demod_m_y : sfixed(TB_DEMOD_INTEGER_WIDTH - 1 downto -TB_DEMOD_FRACTIONAL_WIDTH);

begin
    clk <= not clk after CLK_PERIOD / 2;
    reset <= '1', '0' after CLK_PERIOD;

    mod_inst : entity work.LokiModulator
        generic map(
            CYCLES_PER_SAMPLE_MAX => MOD_CYCLES_PER_SAMPLE,
            LOOKUP_TABLE_1        => work.LokiDemodulatorMixerlessTestbench_osc1_pkg.LOOKUP_TABLE,
            LOOKUP_TABLE_2        => work.LokiDemodulatorMixerlessTestbench_osc2_pkg.LOOKUP_TABLE
        )
        port map(
            clk_i               => clk,
            reset_i             => reset,
            cycles_per_sample_i => MOD_CYCLES_PER_SAMPLE,
            restart_i           => restart,
            step1_i             => OSC1_STEP,
            step2_i             => OSC2_STEP,
            gain1_i             => OSC1_GAIN,
            gain2_i             => OSC2_GAIN,
            m_valid_o           => mod_m_valid,
            m_ready_i           => mod_m_valid,
            m_phase_o           => mod_m_phase
        );

    p_sensor_s_phase_reg : process(clk)
    begin
        if rising_edge(clk) then
            if mod_m_valid = '1' then
                sensor_s_phase_reg <= mod_m_phase;
            end if;
        end if;
    end process p_sensor_s_phase_reg;

    sensor_gen : for i in 0 to TB_CHANNELS - 1 generate
        sensor_inst : entity work.DisplacementSensor
            generic map(
                DELAY                  => TB_SENSOR_DELAY,
                DEFAULT_WAVELENGTH     => TB_WAVELENGTH,
                DEPTH                  => TB_SENSOR_DEPTH,
                SAMPLE_FREQUENCY       => real(TB_MOD_SAMPLE_FREQUENCY),
                DISPLACEMENT_FILENAME  => TB_DISPLACEMENT_FILENAME,
                DISPLACEMENT_FREQUENCY => TB_DISPLACEMENT_FREQUENCY * real(i + 1),
                DISPLACEMENT_AMPLITUDE => TB_DISPLACEMENT_AMPLIUDE,
                POWER_FACTOR           => TB_POWER_FACTOR,
                POWER_CONTRAST         => TB_POWER_CONTRAST
            )
            port map(
                s_phase_i => sensor_s_phase_reg,
                m_power_o => sensor_m_power(i)
            );
    end generate sensor_gen;

    p_demod_s_channel_power_reg : process(clk)
    begin
        if rising_edge(clk) then
            if demod_s_ready = '1' then
                demod_s_channel_reg <= demod_s_channel_next;
                demod_s_power_reg   <= sensor_m_power(demod_s_channel_next);
            end if;
        end if;
    end process p_demod_s_channel_power_reg;

    demod_s_valid        <= '1';
    demod_s_last         <= '1' when demod_s_channel_reg = TB_CHANNELS - 1 else '0';
    demod_s_channel_next <=  0  when demod_s_channel_reg = TB_CHANNELS - 1 else demod_s_channel_reg + 1;

    demod_inst : entity work.LokiDemodulatorMixerless
        generic map(
            CHANNELS                => TB_CHANNELS,
            CYCLES_PER_SAMPLE_MAX   => DEMOD_CYCLES_PER_SAMPLE,
            LOWPASS_PARALLELISM     => TB_LOWPASS_PARALLELISM,
            LOWPASS_GAIN_BITS       => work.LokiDemodulatorMixerlessTestbench_lowpass_pkg.GAIN_BITS,
            LOWPASS_COEFFICIENTS    => work.LokiDemodulatorMixerlessTestbench_lowpass_pkg.COEFFICIENTS,
            BANDPASS_PARALLELISM    => TB_BANDPASS_PARALLELISM,
            BANDPASS_X_GAIN_BITS    => work.LokiDemodulatorMixerlessTestbench_bandpassX_pkg.GAIN_BITS,
            BANDPASS_X_COEFFICIENTS => work.LokiDemodulatorMixerlessTestbench_bandpassX_pkg.COEFFICIENTS,
            BANDPASS_Y_GAIN_BITS    => work.LokiDemodulatorMixerlessTestbench_bandpassY_pkg.GAIN_BITS,
            BANDPASS_Y_COEFFICIENTS => work.LokiDemodulatorMixerlessTestbench_bandpassY_pkg.COEFFICIENTS
        )
        port map(
            clk_i                => clk,
            reset_i              => reset,
            cycles_per_sample_i  => DEMOD_CYCLES_PER_SAMPLE,
            s_valid_i            => demod_s_valid,
            s_ready_o            => demod_s_ready,
            s_last_i             => demod_s_last,
            s_channel_i          => demod_s_channel_reg,
            s_lowpass_delay_x_i  => TB_LOWPASS_DELAY_X,
            s_lowpass_delay_y_i  => TB_LOWPASS_DELAY_Y,
            s_bandpass_delay_x_i => TB_BANDPASS_DELAY_X,
            s_bandpass_delay_y_i => TB_BANDPASS_DELAY_Y,
            s_power_i            => demod_s_power_reg,
            m_valid_o            => demod_m_valid,
            m_ready_i            => demod_m_ready,
            m_last_o             => demod_m_last,
            m_channel_o          => demod_m_channel,
            m_x_o                => demod_m_x,
            m_y_o                => demod_m_y
        );

    p_slave : process
        file csv : text open write_mode is "build/tb/LokiDemodulatorMixerlessTestbench_out.csv";
        variable csv_line : line;
        variable progress, progress_prev : integer := 0;
        variable start_time : time;
    begin
--        wait until reset = '0';
        wait for CLK_PERIOD * 30;
        wait until rising_edge(clk);

        restart <= '1';

        wait until rising_edge(clk);

        restart <= '0';

        for k in 0 to SAMPLE_COUNT - 1 loop
            wait until rising_edge(clk) and demod_m_valid = '1';

            if k = 0 then
                start_time := now;
            end if;

            progress := (k + 1) * 100 / SAMPLE_COUNT;
            if progress /= progress_prev then
                report "Progress " & integer'image(progress);
                progress_prev := progress;

                if k > 0 then
                    report "Sample period: average=" & time'image((now - start_time) * TB_CHANNELS / k) &
                           " expected=" & time'image(CLK_PERIOD * XY_CYCLES_PER_SAMPLE );
                end if;
            end if;

            write(csv_line, demod_m_channel);
            write(csv_line, string'(","));
            write(csv_line, to_real(demod_m_x));
            write(csv_line, string'(","));
            write(csv_line, to_real(demod_m_y));
            writeline(csv, csv_line);

            demod_m_ready <= '1';

            wait until rising_edge(clk);

            demod_m_ready <= '0';
        end loop;

        finish;
    end process p_slave;
end Simulation;
