
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.LokiModem_pkg.all;
use work.LokiModem_cfg.all;
use work.LokiModemTestbench_cfg.all;
use work.Oscillator_pkg.all;

entity LokiModemTestbench is
end LokiModemTestbench;

architecture Simulation of LokiModemTestbench is
    subtype Gain_t is sfixed(TB_MOD_GAIN_INTEGER_WIDTH - 1 downto -TB_MOD_GAIN_FRACTIONAL_WIDTH);
    subtype Phase_t is sfixed(TB_MOD_PHASE_INTEGER_WIDTH - 1 downto -TB_MOD_PHASE_FRACTIONAL_WIDTH);
    subtype Power_t is sfixed(TB_DEMOD_POWER_INTEGER_WIDTH - 1 downto -TB_DEMOD_POWER_FRACTIONAL_WIDTH);
    type PowerArray_t is array(0 to TB_DEMOD_CHANNELS - 1) of Power_t;

    constant OSC1_STEP : integer := TB_OSC1_WAVE_FREQUENCY / MOD_OSC1_WAVE_FREQUENCY_MIN;
    constant OSC1_GAIN : Gain_t := to_sfixed(TB_OSC1_GAIN, Gain_t'left, Gain_t'right);

    constant OSC2_STEP : integer := TB_OSC2_WAVE_FREQUENCY / MOD_OSC2_WAVE_FREQUENCY_MIN;
    constant OSC2_GAIN : Gain_t := to_sfixed(TB_OSC2_GAIN, Gain_t'left, Gain_t'right);

    constant OSC3_STEP : integer := TB_OSC2_WAVE_FREQUENCY / DEMOD_MIXING_OSC_WAVE_FREQUENCY_MIN;
    constant OSC3_DELAY0 : integer := TB_SENSOR_DELAY * OSC3_STEP;

    constant CLK_PERIOD : time := 1 sec / TB_CLK_FREQUENCY;
    constant MOD_CYCLES_PER_SAMPLE   : positive := TB_CLK_FREQUENCY / MOD_SAMPLE_FREQUENCY_REF;
    constant DEMOD_CYCLES_PER_SAMPLE : positive := TB_CLK_FREQUENCY / DEMOD_SAMPLE_FREQUENCY_REF;

    signal clk, reset : std_logic := '0';
    signal resetn : std_logic := '1';

    -- Interface esclave AXI.
    signal modem_s_axi_awaddr  : std_logic_vector(TB_AXI_ADDR_WIDTH - 1 downto 0)     := (others => '0');
    signal modem_s_axi_awprot  : std_logic_vector(2 downto 0)                         := (others => '0');
    signal modem_s_axi_awvalid : std_logic                                            := '0';
    signal modem_s_axi_awready : std_logic;
    signal modem_s_axi_wdata   : std_logic_vector(TB_AXI_DATA_WIDTH - 1 downto 0)     := (others => '0');
    signal modem_s_axi_wstrb   : std_logic_vector(TB_AXI_DATA_WIDTH / 8 - 1 downto 0) := (others => '0');
    signal modem_s_axi_wvalid  : std_logic                                            := '0';
    signal modem_s_axi_wready  : std_logic;
    signal modem_s_axi_bresp   : std_logic_vector(1 downto 0);
    signal modem_s_axi_bvalid  : std_logic;
    signal modem_s_axi_bready  : std_logic                                            := '0';
    signal modem_s_axi_araddr  : std_logic_vector(TB_AXI_ADDR_WIDTH - 1 downto 0)     := (others => '0');
    signal modem_s_axi_arprot  : std_logic_vector(2 downto 0)                         := (others => '0');
    signal modem_s_axi_arvalid : std_logic                                            := '0';
    signal modem_s_axi_arready : std_logic;
    signal modem_s_axi_rdata   : std_logic_vector(TB_AXI_DATA_WIDTH - 1 downto 0);
    signal modem_s_axi_rresp   : std_logic_vector(1 downto 0);
    signal modem_s_axi_rvalid  : std_logic;
    signal modem_s_axi_rready  : std_logic                                            := '0';

    -- Interface maître AXI stream.
    signal modem_m_axis_tvalid  : std_logic;
    signal modem_m_axis_tdata   : std_logic_vector(TB_AXIS_DATA_WIDTH - 1 downto 0);
    signal modem_m_axis_tstrb   : std_logic_vector(TB_AXIS_DATA_WIDTH / 8 - 1 downto 0);
    signal modem_m_axis_tkeep   : std_logic_vector(TB_AXIS_DATA_WIDTH / 8 - 1 downto 0);
    signal modem_m_axis_tlast   : std_logic;
    signal modem_m_axis_tready  : std_logic := '0';

    -- Entrées/sorties analogiques.
    signal modem_dac_m_valid_ready : std_logic;
    signal modem_dac_m_data        : std_logic_vector(TB_MOD_PHASE_INTEGER_WIDTH + TB_MOD_PHASE_FRACTIONAL_WIDTH - 1 downto 0);
    signal modem_adc_s_valid       : std_logic := '1';
    signal modem_adc_s_data        : std_logic_vector(TB_DEMOD_POWER_INTEGER_WIDTH + TB_DEMOD_POWER_FRACTIONAL_WIDTH - 1 downto 0);
    signal modem_adc_s_channel     : natural range 0 to TB_DEMOD_CHANNELS - 1;

    signal sensor_s_phase : Phase_t;
    signal sensor_m_power : PowerArray_t;
begin
    clk <= not clk after CLK_PERIOD / 2;
    reset <= '1', '0' after CLK_PERIOD;
    resetn <= '0', '1' after CLK_PERIOD;

    modem_s_axi_wstrb <= (others => '1');

    modem_inst : entity work.LokiModem
        generic map(
            S_AXI_ADDR_WIDTH             => TB_AXI_ADDR_WIDTH,
            S_AXI_DATA_WIDTH             => TB_AXI_DATA_WIDTH,
            M_AXIS_DATA_WIDTH            => TB_AXIS_DATA_WIDTH,
            CLK_FREQUENCY                => TB_CLK_FREQUENCY,
            MOD_GAIN_INTEGER_WIDTH       => TB_MOD_GAIN_INTEGER_WIDTH,
            MOD_GAIN_FRACTIONAL_WIDTH    => TB_MOD_GAIN_FRACTIONAL_WIDTH,
            MOD_PHASE_INTEGER_WIDTH      => TB_MOD_PHASE_INTEGER_WIDTH,
            MOD_PHASE_FRACTIONAL_WIDTH   => TB_MOD_PHASE_FRACTIONAL_WIDTH,
            MOD_OFFSET_BINARY            => false,
            DEMOD_MIXERLESS              => TB_DEMOD_MIXERLESS,
            DEMOD_CHANNELS               => TB_DEMOD_CHANNELS,
            DEMOD_CHANNEL_OUTPUT_WIDTH   => TB_DEMOD_CHANNEL_OUTPUT_WIDTH,
            DEMOD_POWER_INTEGER_WIDTH    => TB_DEMOD_POWER_INTEGER_WIDTH,
            DEMOD_POWER_FRACTIONAL_WIDTH => TB_DEMOD_POWER_FRACTIONAL_WIDTH,
            DEMOD_XY_INTEGER_WIDTH       => TB_DEMOD_XY_INTEGER_WIDTH,
            DEMOD_XY_FRACTIONAL_WIDTH    => TB_DEMOD_XY_FRACTIONAL_WIDTH,
            DEMOD_OFFSET_BINARY          => false
        )
        port map(
            s_axi_aclk      => clk,
            s_axi_aresetn   => resetn,
            s_axi_awaddr    => modem_s_axi_awaddr,
            s_axi_awprot    => modem_s_axi_awprot,
            s_axi_awvalid   => modem_s_axi_awvalid,
            s_axi_awready   => modem_s_axi_awready,
            s_axi_wdata     => modem_s_axi_wdata,
            s_axi_wstrb     => modem_s_axi_wstrb,
            s_axi_wvalid    => modem_s_axi_wvalid,
            s_axi_wready    => modem_s_axi_wready,
            s_axi_bresp     => modem_s_axi_bresp,
            s_axi_bvalid    => modem_s_axi_bvalid,
            s_axi_bready    => modem_s_axi_bready,
            s_axi_araddr    => modem_s_axi_araddr,
            s_axi_arprot    => modem_s_axi_arprot,
            s_axi_arvalid   => modem_s_axi_arvalid,
            s_axi_arready   => modem_s_axi_arready,
            s_axi_rdata     => modem_s_axi_rdata,
            s_axi_rresp     => modem_s_axi_rresp,
            s_axi_rvalid    => modem_s_axi_rvalid,
            s_axi_rready    => modem_s_axi_rready,
            m_axis_aclk     => clk,
            m_axis_aresetn  => resetn,
            m_axis_tvalid   => modem_m_axis_tvalid,
            m_axis_tdata    => modem_m_axis_tdata,
            m_axis_tstrb    => modem_m_axis_tstrb,
            m_axis_tkeep    => modem_m_axis_tkeep,
            m_axis_tlast    => modem_m_axis_tlast,
            m_axis_tready   => modem_m_axis_tready,
            dac_m_valid_o   => modem_dac_m_valid_ready,
            dac_m_ready_i   => modem_dac_m_valid_ready,
            dac_m_data_o    => modem_dac_m_data,
            adc_s_valid_i   => modem_adc_s_valid,
            adc_s_data_i    => modem_adc_s_data,
            adc_s_channel_o => modem_adc_s_channel,
            pps_i           => '0',
            gpio_i          => (others => '0')
        );

    sensor_gen : for i in 0 to TB_DEMOD_CHANNELS - 1 generate
        sensor_inst : entity work.DisplacementSensor
            generic map(
                DELAY                  => (i + 1) * TB_SENSOR_DELAY,
                DEFAULT_WAVELENGTH     => TB_WAVELENGTH,
                DEPTH                  => TB_SENSOR_DEPTH,
                SAMPLE_FREQUENCY       => real(MOD_SAMPLE_FREQUENCY_REF),
                DISPLACEMENT_FILENAME  => TB_DISPLACEMENT_FILENAME,
                DISPLACEMENT_FREQUENCY => TB_DISPLACEMENT_FREQUENCY * real(i + 1),
                DISPLACEMENT_AMPLITUDE => TB_DISPLACEMENT_AMPLIUDE,
                POWER_FACTOR           => TB_POWER_FACTOR,
                POWER_CONTRAST         => TB_POWER_CONTRAST
            )
            port map(
                s_phase_i => sensor_s_phase,
                m_power_o => sensor_m_power(i)
            );
    end generate sensor_gen;

    sensor_s_phase <= sfixed(modem_dac_m_data);

    modem_adc_s_data <= to_std_logic_vector(sensor_m_power(modem_adc_s_channel));

    p_m_axis_tready : process
    begin
        if modem_m_axis_tvalid /= '1' then
            wait until modem_m_axis_tvalid = '1';
        end if;

        while modem_m_axis_tvalid = '1' loop
            modem_m_axis_tready <= '0';

            for i in 1 to TB_CYCLES_BEFORE_READY loop
                wait until rising_edge(clk);
            end loop;

            modem_m_axis_tready <= '1';

            wait until rising_edge(clk) or modem_m_axis_tvalid = '0';
        end loop;

        if TB_RESET_READY then
            for i in 1 to TB_CYCLES_AFTER_READY loop
                wait until rising_edge(clk);
                exit when modem_m_axis_tvalid = '1';
            end loop;
            modem_m_axis_tready <= '0';
        end if;
    end process p_m_axis_tready;

    p_slave : process
        variable total_decimation        : positive;
        variable sample_count            : positive;
        variable sample_count_per_channel : integer_vector(0 to TB_DEMOD_CHANNELS - 1);

        file csv                         : text open write_mode is "build/tb/LokiModemTestbench_out.csv";
        variable csv_line                : line;
        variable progress, progress_prev : integer := 0;
        variable start_time              : time;
        variable xy_cycles_per_sample    : positive;

        variable seq, seq_prev           : natural;
        variable channel, channel_prev   : integer range 0 to TB_DEMOD_CHANNELS - 1;
        variable x, y                    : sfixed(TB_DEMOD_XY_INTEGER_WIDTH - 1 downto -TB_DEMOD_XY_FRACTIONAL_WIDTH);

        procedure axi_write(reg : integer; data : std_logic_vector) is
        begin
            wait until rising_edge(clk);
            modem_s_axi_awvalid <= '1';
            modem_s_axi_awaddr  <= std_logic_vector(to_unsigned(reg * 4, TB_AXI_DATA_WIDTH));
            modem_s_axi_wvalid  <= '1';
            modem_s_axi_wdata   <= data;
            wait until rising_edge(clk) and modem_s_axi_wready = '1';
            modem_s_axi_awvalid <= '0';
            modem_s_axi_wvalid  <= '0';
        end axi_write;

        procedure axi_write(reg : integer; data : integer) is
        begin
            axi_write(reg, std_logic_vector(to_unsigned(data, TB_AXI_DATA_WIDTH)));
        end axi_write;

        procedure axi_write(reg : integer; data : sfixed) is
        begin
            axi_write(reg, to_std_logic_vector(resize(data, TB_AXI_DATA_WIDTH + data'right - 1, data'right)));
        end axi_write;

        procedure axi_write(reg : Register_t; data : std_logic_vector) is
        begin
            axi_write(Register_t'pos(reg), data);
        end axi_write;

        procedure axi_write(reg : Register_t; data : integer) is
        begin
            axi_write(Register_t'pos(reg), data);
        end axi_write;

        procedure axi_write(reg : Register_t; data : sfixed) is
        begin
            axi_write(Register_t'pos(reg), data);
        end axi_write;
    begin
        if TB_DEMOD_MIXERLESS then
            xy_cycles_per_sample := DEMOD_CYCLES_PER_SAMPLE * DEMOD_MIXERLESS_LOWPASS_DECIMATION * DEMOD_MIXERLESS_BANDPASS_DECIMATION;
        else
            xy_cycles_per_sample := DEMOD_CYCLES_PER_SAMPLE * DEMOD_MIXING_LOWPASS1_DECIMATION * DEMOD_MIXING_LOWPASS2_DECIMATION;
        end if;

        wait until reset = '0';

        -- Configuration du module LokiModem
        axi_write(REG_MOD_CYCLES_PER_SAMPLE, MOD_CYCLES_PER_SAMPLE);
        axi_write(REG_MOD_OSC1_STEP,  OSC1_STEP);
        axi_write(REG_MOD_OSC1_GAIN,  OSC1_GAIN);
        axi_write(REG_MOD_OSC2_STEP,  OSC2_STEP);
        axi_write(REG_MOD_OSC2_GAIN,  OSC2_GAIN);
        axi_write(REG_DEMOD_OSC_STEP, OSC3_STEP);
        axi_write(REG_MOD_OFFSET, 0);
        axi_write(REG_DEMOD_CYCLES_PER_SAMPLE, DEMOD_CYCLES_PER_SAMPLE);
        for i in 0 to TB_DEMOD_CHANNELS - 1 loop
            if TB_DEMOD_MIXERLESS then
                axi_write(REG_DEMOD_CHANNEL_CFG + 4 * i,     TB_DEMOD_LOWPASS_DELAY_X);
                axi_write(REG_DEMOD_CHANNEL_CFG + 4 * i + 1, TB_DEMOD_LOWPASS_DELAY_Y);
                axi_write(REG_DEMOD_CHANNEL_CFG + 4 * i + 2, TB_DEMOD_BANDPASS_DELAY_Y);
                axi_write(REG_DEMOD_CHANNEL_CFG + 4 * i + 3, TB_DEMOD_BANDPASS_DELAY_Y);
            else
                axi_write(REG_DEMOD_CHANNEL_CFG + 4 * i,     i * OSC3_DELAY0 * 2 + work.LokiModem_Mixing_osc3_pkg.LOOKUP_TABLE'high);
                axi_write(REG_DEMOD_CHANNEL_CFG + 4 * i + 1, i * OSC3_DELAY0);
            end if;
        end loop;
        axi_write(REG_CONTROL, 1);

        if TB_DEMOD_MIXERLESS then
            total_decimation := DEMOD_MIXERLESS_LOWPASS_DECIMATION * DEMOD_MIXERLESS_BANDPASS_DECIMATION;
        else
            total_decimation := DEMOD_MIXING_LOWPASS1_DECIMATION * DEMOD_MIXING_LOWPASS2_DECIMATION;
        end if;

        sample_count := TB_DEMOD_CHANNELS * DEMOD_SAMPLE_FREQUENCY_REF * TB_OSC1_PERIODS / TB_OSC1_WAVE_FREQUENCY / total_decimation;
        sample_count_per_channel := (others => 0);

        for k in 0 to sample_count - 1 loop
            wait until rising_edge(clk) and modem_m_axis_tvalid = '1' and modem_m_axis_tready = '1';

            seq     := to_integer(unsigned(modem_m_axis_tdata(modem_m_axis_tdata'high downto x'length + y'length + TB_DEMOD_CHANNEL_OUTPUT_WIDTH)));
            channel := to_integer(unsigned(modem_m_axis_tdata(x'length + y'length + TB_DEMOD_CHANNEL_OUTPUT_WIDTH - 1 downto x'length + y'length)));
            x       := sfixed(modem_m_axis_tdata(x'length + y'length - 1 downto y'length));
            y       := sfixed(modem_m_axis_tdata(y'length - 1 downto 0));

            sample_count_per_channel(channel) := sample_count_per_channel(channel) + 1;

            if k = 0 then
                start_time := now;
            end if;
            
            progress := (k + 1) * 100 / sample_count;
            if progress /= progress_prev then
                report "Progress " & integer'image(progress);
                progress_prev := progress;

                if k > 0 then
                    report "Sample period: average=" & time'image((now - start_time) * TB_DEMOD_CHANNELS / k) &
                           " expected=" & time'image(CLK_PERIOD * xy_cycles_per_sample );
                end if;
            end if;

            if k > 0 then
                -- if channel = 0 then
                --     assert seq = seq_prev + 1 or (seq = 0 and seq_prev > 0)
                --         report "Valeur inattendue pour seq : " & integer'image(seq) & " prec : " & integer'image(seq_prev)
                --         severity error;
                -- else
                --     assert seq = seq_prev
                --         report "Valeur inattendue pour seq : " & integer'image(seq) & " prec : " & integer'image(seq_prev)
                --         severity error;
                -- end if;

                assert (channel > 0 and channel = channel_prev + 1) or (channel = 0 and channel_prev = TB_DEMOD_CHANNELS - 1)
                    report "Valeur inattendue pour channel : " & integer'image(channel) & " prec : " & integer'image(channel_prev)
                    severity error;
            end if;

            seq_prev     := seq;
            channel_prev := channel;

            write(csv_line, seq);
            write(csv_line, string'(","));
            write(csv_line, channel);
            write(csv_line, string'(","));
            write(csv_line, to_real(x));
            write(csv_line, string'(","));
            write(csv_line, to_real(y));
            writeline(csv, csv_line);
        end loop;

        for c in sample_count_per_channel'range loop
            report "Voie " & integer'image(c) & " : " & integer'image(sample_count_per_channel(c)) & " échantillons";
        end loop;
        report "Total attendu : " & integer'image(sample_count);

        finish;
    end process p_slave;
end Simulation;
