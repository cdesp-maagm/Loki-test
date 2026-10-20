
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Loki_cfg.all;
use work.LTC2325_pkg.all;

entity Loki is
    generic(
        S_AXI_ADDR_WIDTH  : positive := 32;
        S_AXI_DATA_WIDTH  : positive := 32;
        M_AXIS_DATA_WIDTH : positive := 64;
        PS7_GPIO_WIDTH    : positive := 32
    );
    port(
        -- Interface esclave AXI.
        s_axi_aclk         : in  std_logic;
        s_axi_aresetn      : in  std_logic;
        s_axi_awaddr       : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot       : in  std_logic_vector(2 downto 0);
        s_axi_awvalid      : in  std_logic;
        s_axi_awready      : out std_logic;
        s_axi_wdata        : in  std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_wstrb        : in  std_logic_vector(S_AXI_DATA_WIDTH / 8 - 1 downto 0);
        s_axi_wvalid       : in  std_logic;
        s_axi_wready       : out std_logic;
        s_axi_bresp        : out std_logic_vector(1 downto 0);
        s_axi_bvalid       : out std_logic;
        s_axi_bready       : in  std_logic;
        s_axi_araddr       : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot       : in  std_logic_vector(2 downto 0);
        s_axi_arvalid      : in  std_logic;
        s_axi_arready      : out std_logic;
        s_axi_rdata        : out std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_rresp        : out std_logic_vector(1 downto 0);
        s_axi_rvalid       : out std_logic;
        s_axi_rready       : in  std_logic;

        -- Interface maître AXI stream.
        m_axis_aclk        : in  std_logic;
        m_axis_aresetn     : in  std_logic;
        m_axis_tvalid      : out std_logic;
        m_axis_tdata       : out std_logic_vector(M_AXIS_DATA_WIDTH - 1 downto 0);
        m_axis_tstrb       : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tkeep       : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tlast       : out std_logic;
        m_axis_tready      : in  std_logic;

        -- Sorties analogiques.
        dac_m_reset_o      : out std_logic;
        dac_m_clk_i        : in std_logic;
        dac_m_data_o       : out std_logic_vector(MOD_DAC_DATA_WIDTH - 1 downto 0);
        dac_m_sel_o        : out std_logic;

        mod_pga_gain_o     : out std_logic_vector(MOD_PGA_GAIN_WIDTH - 1 downto 0);

        -- Entrées analogiques.
        adc0_m_convert_n_o : out std_logic;
        adc0_m_sclk_i      : in  std_logic;
        adc0_m_sclk_o      : out std_logic;
        adc0_m_sdata_i     : in  std_logic_vector(DEMOD_CHANNELS - 1 downto 0);

        demod_pga_m_sclk_o    : out std_logic;
        demod_pga_m_ltch_n_o  : out std_logic_vector(DEMOD_CHANNELS - 1 downto 0);
        demod_pga_m_sdata_o   : out std_logic;

        -- GPIO
        ps7_gpio_i     : in std_logic_vector(PS7_GPIO_WIDTH - 1 downto 0);
        ps7_gpio_o     : out std_logic_vector(PS7_GPIO_WIDTH - 1 downto 0);

        sw_i           : in std_logic;

        gps_clk1pps_i  : in std_logic;
        gps_clk10m_i   : in std_logic;
        gps_clk30m72_i : in std_logic;
        gps_tstamp_o   : out std_logic;

        gpio_o         : out std_logic_vector(1 downto 0);

        sync_dac_o      : out std_logic;
        sync_adc_o      : out std_logic;
        sync_10M_o      : out std_logic
    );
end Loki;

architecture RTL of Loki is
    signal dac_m_data, dac_m_data_reg : std_logic_vector(dac_m_data_o'range);
    signal dac_m_sel_reg              : std_logic;
    signal dac_m_valid_ready          : std_logic;
    signal dac_m_period               : natural range 0 to MOD_CYCLES_PER_SAMPLE_MAX;
    signal dac_m_dc_value             : std_logic_vector(dac_m_data_o'range);

    signal reset                      : std_logic;

    signal adc0_m_sclk                : std_logic;
    signal adc0_m_sdata               : std_logic_vector(adc0_m_sdata_i'range);
    signal adc_m_data, adc_m_data_reg : LTC2325DataArray_t(0 to DEMOD_CHANNELS - 1);
    signal adc_m_valid, adc_m_ready   : std_logic;

    signal adc_s_ready_counter_reg      : natural range 0 to DEMOD_CHANNELS - 1;
    signal adc_s_channel                : natural range 0 to DEMOD_CHANNELS - 1;
    signal adc_s_valid_reg, adc_s_ready : std_logic;
    signal adc_s_data                   : std_logic_vector(DEMOD_ADC_DATA_WIDTH - 1 downto 0);
    signal adc_s_period                 : natural range 0 to DEMOD_CYCLES_PER_SAMPLE_MAX;

    signal gpio_to_modem              : std_logic_vector(GPIO_WIDTH - 1 downto 0);
    signal gpio_from_modem            : std_logic_vector(GPIO_WIDTH - 1 downto 0);

    signal demod_pga_gains            : std_logic_vector(DEMOD_PGA_GAIN_WIDTH * DEMOD_CHANNELS - 1 downto 0);

    constant TIMER_10M_MAX : integer := CLK_FREQUENCY / 10e6 - 1;
    signal timer_dac_reg : natural range 0 to MOD_CYCLES_PER_SAMPLE_MAX - 1;
    signal timer_adc_reg : natural range 0 to DEMOD_CYCLES_PER_SAMPLE_MAX - 1;
    signal timer_10M_reg : natural range 0 to TIMER_10M_MAX;
    signal sync_dac_reg, sync_adc_reg, sync_10M_reg : std_logic;
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
            MOD_PGA_GAIN_WIDTH           => MOD_PGA_GAIN_WIDTH,
            DEMOD_MIXERLESS              => DEMOD_MIXERLESS,
            DEMOD_CHANNELS               => DEMOD_CHANNELS,
            DEMOD_CHANNEL_OUTPUT_WIDTH   => DEMOD_CHANNEL_OUTPUT_WIDTH,
            DEMOD_CYCLES_PER_SAMPLE_MAX  => DEMOD_CYCLES_PER_SAMPLE_MAX,
            DEMOD_POWER_INTEGER_WIDTH    => DEMOD_POWER_INTEGER_WIDTH,
            DEMOD_POWER_FRACTIONAL_WIDTH => DEMOD_POWER_FRACTIONAL_WIDTH,
            DEMOD_XY_INTEGER_WIDTH       => DEMOD_XY_INTEGER_WIDTH,
            DEMOD_XY_FRACTIONAL_WIDTH    => DEMOD_XY_FRACTIONAL_WIDTH,
            DEMOD_PACKET_LENGTH_MAX      => DEMOD_PACKET_LENGTH_MAX,
            DEMOD_OFFSET_BINARY          => DEMOD_OFFSET_BINARY,
            DEMOD_PGA_GAIN_WIDTH         => DEMOD_PGA_GAIN_WIDTH,
            CLKMON_SECONDS_MAX           => CLKMON_SECONDS_MAX,
            CLKMON_DELTA_MAX             => CLKMON_DELTA_MAX
        )
        port map(
            s_axi_aclk         => s_axi_aclk,
            s_axi_aresetn      => s_axi_aresetn,
            s_axi_awaddr       => s_axi_awaddr,
            s_axi_awprot       => s_axi_awprot,
            s_axi_awvalid      => s_axi_awvalid,
            s_axi_awready      => s_axi_awready,
            s_axi_wdata        => s_axi_wdata,
            s_axi_wstrb        => s_axi_wstrb,
            s_axi_wvalid       => s_axi_wvalid,
            s_axi_wready       => s_axi_wready,
            s_axi_bresp        => s_axi_bresp,
            s_axi_bvalid       => s_axi_bvalid,
            s_axi_bready       => s_axi_bready,
            s_axi_araddr       => s_axi_araddr,
            s_axi_arprot       => s_axi_arprot,
            s_axi_arvalid      => s_axi_arvalid,
            s_axi_arready      => s_axi_arready,
            s_axi_rdata        => s_axi_rdata,
            s_axi_rresp        => s_axi_rresp,
            s_axi_rvalid       => s_axi_rvalid,
            s_axi_rready       => s_axi_rready,
            m_axis_aclk        => m_axis_aclk,
            m_axis_aresetn     => m_axis_aresetn,
            m_axis_tvalid      => m_axis_tvalid,
            m_axis_tdata       => m_axis_tdata,
            m_axis_tstrb       => m_axis_tstrb,
            m_axis_tkeep       => m_axis_tkeep,
            m_axis_tlast       => m_axis_tlast,
            m_axis_tready      => m_axis_tready,
            dac_m_valid_o      => dac_m_valid_ready,
            dac_m_ready_i      => dac_m_valid_ready,
            dac_m_data_o       => dac_m_data,
            dac_m_period_o     => dac_m_period,
            dac_m_dc_value_o   => dac_m_dc_value,
            adc_s_valid_i      => adc_s_valid_reg,
            adc_s_ready_o      => adc_s_ready,
            adc_s_data_i       => adc_s_data,
            adc_s_channel_o    => adc_s_channel,
            adc_s_period_o     => adc_s_period,
            mod_pga_gain_o     => mod_pga_gain_o,
            demod_pga_gains_o  => demod_pga_gains,
            pps_i              => gps_clk1pps_i,
            gpio_i             => gpio_to_modem,
            gpio_o             => gpio_from_modem
        );

    -- -------------------------------------------------------------------------
    -- Pilotage du convertisseur numérique/analogique.
    -- -------------------------------------------------------------------------

    -- Le reset du DAC est en logique positive.
    dac_m_reset_o <= not m_axis_aresetn;

    -- La sortie du DAC est en binaire décalé.
    -- Le bit de signe est géré par LokiModem.
    p_dac_m_data_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if dac_m_valid_ready = '1' then
                dac_m_data_reg <= dac_m_data;
            end if;
        end if;
    end process p_dac_m_data_reg;

    p_dac_m_data_o : process(dac_m_clk_i)
    begin
        if rising_edge(dac_m_clk_i) then
            if m_axis_aresetn = '0' then
                dac_m_data_o  <= (dac_m_data_o'high => '0', others => '1');
                dac_m_sel_reg <= '0';
            elsif dac_m_sel_reg = '0' then
                dac_m_data_o  <= dac_m_data_reg;
                dac_m_sel_reg <= '1';
            else
                dac_m_data_o  <= dac_m_dc_value;
                dac_m_sel_reg <= '0';
            end if;
        end if;
    end process p_dac_m_data_o;

    dac_m_sel_o <= dac_m_sel_reg;

    -- -------------------------------------------------------------------------
    -- Pilotage des convertisseurs analogique/numérique.
    -- -------------------------------------------------------------------------

    reset <= not s_axi_aresetn;

    -- Les paires différentielles du convertisseur 0 peuvent être inversées
    -- pour faciliter le routage.
    adc0_m_sclk_o <= not adc0_m_sclk    when DEMOD_ADC_INVERT_DIFF else adc0_m_sclk;
    adc0_m_sdata  <= not adc0_m_sdata_i when DEMOD_ADC_INVERT_DIFF else adc0_m_sdata_i;

    adc_inst : entity work.LTC2325
        generic map(
            CHANNELS          => DEMOD_CHANNELS,
            CLK_FREQUENCY     => CLK_FREQUENCY,
            ADC_CLK_FREQUENCY => ADC_CLK_FREQUENCY
        )
        port map(
            clk_i             => s_axi_aclk,
            reset_i           => reset,
            adc_m_convert_n_o => adc0_m_convert_n_o,
            adc_m_sclk_o      => adc0_m_sclk,
            adc_m_sdata_i     => adc0_m_sdata,
            m_data_o          => adc_m_data,
            m_valid_o         => adc_m_valid,
            m_ready_i         => adc_m_ready
        );

    -- Mémoriser les données de toutes les voies à la fin d'une acquisition.
    p_adc_m_data_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if adc_m_valid = '1' and adc_m_ready = '1' then
                adc_m_data_reg <= adc_m_data;
            end if;
        end if;
    end process p_adc_m_data_reg;

    -- Sélectionner la donnée parallèle correspondant à la voie demandée.
    adc_s_data <= adc_m_data_reg(adc_s_channel);

    -- Compter le nombre de voies lues par cycle d'acquisition.
    p_adc_s_ready_counter_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if reset = '1' then
                adc_s_ready_counter_reg <= 0;
            elsif adc_s_valid_reg = '1' and adc_s_ready = '1' then
                if adc_s_ready_counter_reg = DEMOD_CHANNELS - 1 then
                    adc_s_ready_counter_reg <= 0;
                else
                    adc_s_ready_counter_reg <= adc_s_ready_counter_reg + 1;
                end if;
            end if;
        end if;
    end process p_adc_s_ready_counter_reg;

    -- Déclencher une nouvelle conversion lorsque toutes les voies ont été lues.
    adc_m_ready <= adc_m_valid and not adc_s_valid_reg when adc_s_ready_counter_reg = 0 else '0';

    -- Indiquer la disponibilité des données lorsqu'une acquisition se termine
    -- et tant que la dernière voie n'a pas été lue.
    p_adc_s_valid_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if reset = '1' then
                adc_s_valid_reg <= '0';
            elsif adc_m_ready = '1' then
                adc_s_valid_reg <= '1';
            elsif adc_s_valid_reg = '1' and adc_s_ready = '1' and adc_s_ready_counter_reg = DEMOD_CHANNELS - 1 then
                adc_s_valid_reg <= '0';
            end if;
        end if;
    end process p_adc_s_valid_reg;

    -- -------------------------------------------------------------------------
    -- Amplificateurs des voies optiques d'entrée.
    -- -------------------------------------------------------------------------

    demod_pga : entity work.AD8370
        generic map(
            CLK_FREQUENCY  => CLK_FREQUENCY,
            SCLK_FREQUENCY => DEMOD_PGA_SCLK_FREQUENCY,
            CHANNELS       => DEMOD_CHANNELS,
            GAIN_WIDTH     => DEMOD_PGA_GAIN_WIDTH
        )
        port map(
            clk_i      => s_axi_aclk,
            reset_i    => reset,
            s_gains_i  => demod_pga_gains,
            m_sclk_o   => demod_pga_m_sclk_o,
            m_ltch_n_o => demod_pga_m_ltch_n_o,
            m_sdata_o  => demod_pga_m_sdata_o
        );

    -- -------------------------------------------------------------------------
    -- GPIO.
    -- -------------------------------------------------------------------------

    gpio_to_modem <= (0 => sw_i, others => '0');
    gpio_o        <= gpio_from_modem(gpio_o'range);

    ps7_gpio_o <= (0 => gps_clk1pps_i, others => '0');

    -- TODO
    gps_tstamp_o <= '0';

    -- -------------------------------------------------------------------------
    -- Génération d'horloges.
    -- -------------------------------------------------------------------------

    p_timer_10M_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' or timer_10M_reg = TIMER_10M_MAX then
                timer_10M_reg <= 0;
            else
                timer_10M_reg <= timer_10M_reg + 1;
            end if;
        end if;
    end process p_timer_10M_reg;

    p_timer_dac_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' or timer_dac_reg >= dac_m_period - 1 then
                timer_dac_reg <= 0;
            else
                timer_dac_reg <= timer_dac_reg + 1;
            end if;
        end if;
    end process p_timer_dac_reg;

    p_timer_adc_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' or timer_adc_reg >= adc_s_period - 1 then
                timer_adc_reg <= 0;
            else
                timer_adc_reg <= timer_adc_reg + 1;
            end if;
        end if;
    end process p_timer_adc_reg;

    p_clk_dac_adc_10M_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                sync_dac_reg <= '0';
                sync_adc_reg <= '0';
                sync_10M_reg <= '0';
            else
                if timer_dac_reg = dac_m_period / 2 - 1 or timer_dac_reg >= dac_m_period - 1 then
                    sync_dac_reg <= not sync_dac_reg;
                end if;
                if timer_adc_reg = adc_s_period / 2 - 1 or timer_adc_reg >= adc_s_period - 1 then
                    sync_adc_reg <= not sync_adc_reg;
                end if;
                if timer_10M_reg = TIMER_10M_MAX / 2 or timer_10M_reg = TIMER_10M_MAX then
                    sync_10M_reg <= not sync_10M_reg;
                end if;
            end if;
        end if;
    end process p_clk_dac_adc_10M_reg;

    sync_dac_o <= sync_dac_reg;
    sync_adc_o <= sync_adc_reg;
    sync_10M_o <= sync_10M_reg;
end RTL;
