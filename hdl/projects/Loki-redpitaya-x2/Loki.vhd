
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Loki_cfg.all;

entity Loki is
    generic(
        S_AXI_ADDR_WIDTH            : integer  := 32;
        S_AXI_DATA_WIDTH            : integer  := 32;
        M_AXIS_DATA_WIDTH           : integer  := 64
    );
    port(
        -- Interface esclave AXI.
        s_axi_aclk     : in std_logic;
        s_axi_aresetn  : in std_logic;
        s_axi_awaddr   : in std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot   : in std_logic_vector(2 downto 0);
        s_axi_awvalid  : in std_logic;
        s_axi_awready  : out std_logic;
        s_axi_wdata    : in std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_wstrb    : in std_logic_vector(S_AXI_DATA_WIDTH / 8 - 1 downto 0);
        s_axi_wvalid   : in std_logic;
        s_axi_wready   : out std_logic;
        s_axi_bresp    : out std_logic_vector(1 downto 0);
        s_axi_bvalid   : out std_logic;
        s_axi_bready   : in std_logic;
        s_axi_araddr   : in std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot   : in std_logic_vector(2 downto 0);
        s_axi_arvalid  : in std_logic;
        s_axi_arready  : out std_logic;
        s_axi_rdata    : out std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_rresp    : out std_logic_vector(1 downto 0);
        s_axi_rvalid   : out std_logic;
        s_axi_rready   : in std_logic;

        -- Interface maître AXI stream.
        m_axis_aclk    : in std_logic;
        m_axis_aresetn : in std_logic;
        m_axis_tvalid  : out std_logic;
        m_axis_tdata   : out std_logic_vector(M_AXIS_DATA_WIDTH - 1 downto 0);
        m_axis_tstrb   : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tkeep   : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tlast   : out std_logic;
        m_axis_tready  : in std_logic;

        -- Sorties analogiques.
        dac_m_data_o   : out std_logic_vector(MOD_DAC_DATA_WIDTH - 1 downto 0);
        dac_m_clk_o    : out std_logic;
        dac_m_write_o  : out std_logic;
        dac_m_sel_o    : out std_logic;
        dac_m_reset_o  : out std_logic;

        -- Entrées analogiques (full rate).
        adc_s0_valid_i : in std_logic;
        adc_s0_ready_o : out std_logic;
        adc_s0_data_i  : in std_logic_vector(DEMOD_ADC_DATA_WIDTH - 1 downto 0);

        adc_s1_valid_i : in std_logic;
        adc_s1_ready_o : out std_logic;
        adc_s1_data_i  : in std_logic_vector(DEMOD_ADC_DATA_WIDTH - 1 downto 0);

        adc_clk_o      : out std_logic_vector(1 downto 0);
        adc_cdcs_o     : out std_logic;

        probe_o        : out std_logic_vector(15 downto 0)
    );
end Loki;

architecture RTL of Loki is
    subtype ADCData_t is std_logic_vector(adc_s0_data_i'range);

    signal dac_m_data, dac_m_data_reg       : std_logic_vector(dac_m_data_o'range);
    signal dac_m_valid_ready, dac_m_sel_reg : std_logic;
    signal dac_m_period                     : natural range 0 to MOD_CYCLES_PER_SAMPLE_MAX;
    signal dac_m_dc_value                   : std_logic_vector(dac_m_data_o'range);

    signal adc_s_channel                    : natural range 0 to DEMOD_CHANNELS - 1;
    signal adc_s_valid, adc_s_ready         : std_logic;
    signal adc_s_data                       : ADCData_t;
    signal adc_s_period                     : natural range 0 to DEMOD_CYCLES_PER_SAMPLE_MAX;

    signal dac_timer_reg                    : natural range 0 to MOD_CYCLES_PER_SAMPLE_MAX - 1;
    signal dac_timer_next                   : positive range 1 to MOD_CYCLES_PER_SAMPLE_MAX;
    signal dac_cycle, dac_half              : boolean;

    signal adc_timer_reg                    : natural range 0 to DEMOD_CYCLES_PER_SAMPLE_MAX - 1;
    signal adc_timer_next                   : positive range 1 to DEMOD_CYCLES_PER_SAMPLE_MAX;
    signal adc_cycle, adc_half              : boolean;
begin
    modem_inst : entity work.LokiModem
        generic map(
            S_AXI_ADDR_WIDTH             => S_AXI_ADDR_WIDTH,
            S_AXI_DATA_WIDTH             => S_AXI_DATA_WIDTH,
            M_AXIS_DATA_WIDTH            => M_AXIS_DATA_WIDTH,
            CLK_FREQUENCY                => CLK_FREQUENCY,
            MOD_CYCLES_PER_SAMPLE_MAX    => MOD_CYCLES_PER_SAMPLE_MAX,
            MOD_DC_VALUE_MAX             => MOD_DC_VALUE_MAX,
            MOD_DC_VALUE_WIDTH           => MOD_DAC_DATA_WIDTH,
            MOD_GAIN_INTEGER_WIDTH       => MOD_GAIN_INTEGER_WIDTH,
            MOD_GAIN_FRACTIONAL_WIDTH    => MOD_GAIN_FRACTIONAL_WIDTH,
            MOD_PHASE_AMPLITUDE_MAX      => MOD_PHASE_AMPLITUDE_MAX,
            MOD_PHASE_INTEGER_WIDTH      => MOD_PHASE_INTEGER_WIDTH,
            MOD_PHASE_FRACTIONAL_WIDTH   => MOD_PHASE_FRACTIONAL_WIDTH,
            MOD_OFFSET_BINARY            => MOD_OFFSET_BINARY,
            DEMOD_MIXERLESS              => DEMOD_MIXERLESS,
            DEMOD_CHANNELS               => DEMOD_CHANNELS,
            DEMOD_CHANNEL_OUTPUT_WIDTH   => DEMOD_CHANNEL_OUTPUT_WIDTH,
            DEMOD_CYCLES_PER_SAMPLE_MAX  => DEMOD_CYCLES_PER_SAMPLE_MAX,
            DEMOD_POWER_INTEGER_WIDTH    => DEMOD_POWER_INTEGER_WIDTH,
            DEMOD_POWER_FRACTIONAL_WIDTH => DEMOD_POWER_FRACTIONAL_WIDTH,
            DEMOD_XY_INTEGER_WIDTH       => DEMOD_XY_INTEGER_WIDTH,
            DEMOD_XY_FRACTIONAL_WIDTH    => DEMOD_XY_FRACTIONAL_WIDTH,
            DEMOD_PACKET_LENGTH_MAX      => DEMOD_PACKET_LENGTH_MAX,
            DEMOD_OFFSET_BINARY          => DEMOD_OFFSET_BINARY
        )
        port map(
            s_axi_aclk       => s_axi_aclk,
            s_axi_aresetn    => s_axi_aresetn,
            s_axi_awaddr     => s_axi_awaddr,
            s_axi_awprot     => s_axi_awprot,
            s_axi_awvalid    => s_axi_awvalid,
            s_axi_awready    => s_axi_awready,
            s_axi_wdata      => s_axi_wdata,
            s_axi_wstrb      => s_axi_wstrb,
            s_axi_wvalid     => s_axi_wvalid,
            s_axi_wready     => s_axi_wready,
            s_axi_bresp      => s_axi_bresp,
            s_axi_bvalid     => s_axi_bvalid,
            s_axi_bready     => s_axi_bready,
            s_axi_araddr     => s_axi_araddr,
            s_axi_arprot     => s_axi_arprot,
            s_axi_arvalid    => s_axi_arvalid,
            s_axi_arready    => s_axi_arready,
            s_axi_rdata      => s_axi_rdata,
            s_axi_rresp      => s_axi_rresp,
            s_axi_rvalid     => s_axi_rvalid,
            s_axi_rready     => s_axi_rready,
            m_axis_aclk      => m_axis_aclk,
            m_axis_aresetn   => m_axis_aresetn,
            m_axis_tvalid    => m_axis_tvalid,
            m_axis_tdata     => m_axis_tdata,
            m_axis_tstrb     => m_axis_tstrb,
            m_axis_tkeep     => m_axis_tkeep,
            m_axis_tlast     => m_axis_tlast,
            m_axis_tready    => m_axis_tready,
            dac_m_valid_o    => dac_m_valid_ready,
            dac_m_ready_i    => dac_m_valid_ready,
            dac_m_data_o     => dac_m_data,
            dac_m_period_o   => dac_m_period,
            dac_m_dc_value_o => dac_m_dc_value,
            adc_s_valid_i    => adc_s_valid,
            adc_s_ready_o    => adc_s_ready,
            adc_s_data_i     => adc_s_data,
            adc_s_channel_o  => adc_s_channel,
            adc_s_period_o   => adc_s_period,
            pps_i            => '0',
            gpio_i           => (others => '0')
        );

    -- -------------------------------------------------------------------------
    -- Pilotage du convertisseur numérique/analogique.
    -- -------------------------------------------------------------------------

    -- Le reset du DAC est en logique positive.
    dac_m_reset_o <= not m_axis_aresetn;

    -- Le DAC est piloté à 50 MHz (25 MHz par voie).
    -- On inverse l'horloge de telle sorte que les données soient stables sur
    -- les fronts montants de dac_m_clk_o.
    dac_m_clk_o   <= not m_axis_aclk;
    dac_m_write_o <= not m_axis_aclk;

    -- Sélectionner alternativement les deux voies du DAC.
    p_dac_m_sel_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            dac_m_sel_reg <= not dac_m_sel_reg;
        end if;
    end process p_dac_m_sel_reg;

    dac_m_sel_o <= dac_m_sel_reg;

    -- La sortie du DAC est en binaire décalé avec une pente négative.
    -- Le bit de signe est géré par LokiModem.
    p_dac_m_data_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if dac_m_valid_ready = '1' then
                dac_m_data_reg <= not dac_m_data;
            end if;
        end if;
    end process p_dac_m_data_reg;

    -- Sur la RedPitaya, la sortie du DAC est inversée.
    -- La pente est rétablie en inversant dac_m_data_o.
    p_dac_m_data_o : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' then
                dac_m_data_o <= (dac_m_data_o'high => '0', others => '1');
            elsif dac_m_sel_reg = '0' then
                dac_m_data_o <= not dac_m_data_reg;
            else
                dac_m_data_o <= not dac_m_dc_value;
            end if;
        end if;
    end process p_dac_m_data_o;

    -- -------------------------------------------------------------------------
    -- Pilotage des convertisseurs analogique/numérique.
    -- -------------------------------------------------------------------------

    -- Désactiver la génération de l'horloge vers l'ADC.
    -- Activer la stabilisation du rapport cyclique de l'horloge de l'ADC.
    adc_clk_o  <= "10";
    adc_cdcs_o <= '1';

    process (adc_s_channel, adc_s0_data_i, adc_s0_valid_i, adc_s1_data_i, adc_s1_valid_i, adc_s_ready)
    begin
        if adc_s_channel = 0 then
            adc_s_data     <= adc_s0_data_i;
            adc_s_valid    <= adc_s0_valid_i;
            adc_s0_ready_o <= adc_s_ready;
            adc_s1_ready_o <= '0';
        else
            adc_s_data     <= adc_s1_data_i;
            adc_s_valid    <= adc_s1_valid_i;
            adc_s0_ready_o <= '0';
            adc_s1_ready_o <= adc_s_ready;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- Sorties de debug et de synchronisation externe
    -- -------------------------------------------------------------------------

    dac_timer_next <= dac_timer_reg + 1;
    dac_cycle      <= dac_timer_next >= dac_m_period;
    dac_half       <= dac_timer_next  = dac_m_period / 2;

    p_dac_timer_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or dac_cycle then
                dac_timer_reg <= 0;
            else
                dac_timer_reg <= dac_timer_next;
            end if;
        end if;
    end process p_dac_timer_reg;

    p_probe_o_0 : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or dac_cycle then
                probe_o(0) <= '0';
            elsif dac_half then
                probe_o(0) <= '1';
            end if;
        end if;
    end process p_probe_o_0;

    adc_timer_next <= adc_timer_reg + 1;
    adc_cycle      <= adc_timer_next >= adc_s_period;
    adc_half       <= adc_timer_next  = adc_s_period / 2;

    p_adc_timer_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or adc_cycle then
                adc_timer_reg <= 0;
            else
                adc_timer_reg <= adc_timer_next;
            end if;
        end if;
    end process p_adc_timer_reg;

    p_probe_o_1 : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or adc_cycle then
                probe_o(1) <= '0';
            elsif adc_half then
                probe_o(1) <= '1';
            end if;
        end if;
    end process p_probe_o_1;

    probe_o(15 downto 2) <= (others => 'Z');
end RTL;
