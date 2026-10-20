
library ieee;
use ieee.std_logic_1164.all;

entity LokiModem is
    generic(
        S_AXI_ADDR_WIDTH             : integer  := 32;
        S_AXI_DATA_WIDTH             : integer  := 32;
        M_AXIS_DATA_WIDTH            : integer  := 64;

        GPIO_WIDTH                   : integer  := 32;

        CLK_FREQUENCY                : positive := 50_000_000;

        -- Configuration du modulateur.
        MOD_CYCLES_PER_SAMPLE_MAX    : positive := 50_000; -- 1 kHz
        MOD_DC_VALUE_MAX             : real     := 1.0;
        MOD_DC_VALUE_WIDTH           : positive := 14;
        MOD_GAIN_INTEGER_WIDTH       : natural  := 4;
        MOD_GAIN_FRACTIONAL_WIDTH    : natural  := 14;
        MOD_PHASE_AMPLITUDE_MAX      : real     := 1.0;
        MOD_PHASE_INTEGER_WIDTH      : natural  := 4;
        MOD_PHASE_FRACTIONAL_WIDTH   : natural  := 12;
        MOD_OFFSET_BINARY            : boolean  := true;
        MOD_PGA_GAIN_WIDTH           : positive := 8;

        -- Configuration du démodulateur.
        DEMOD_MIXERLESS              : boolean  := false;
        DEMOD_CHANNELS               : natural  := 1;
        DEMOD_CHANNEL_OUTPUT_WIDTH   : positive := 1;
        DEMOD_CYCLES_PER_SAMPLE_MAX  : positive := 50_000; -- 1 kHz
        DEMOD_POWER_INTEGER_WIDTH    : natural  := 2;
        DEMOD_POWER_FRACTIONAL_WIDTH : natural  := 14;
        DEMOD_XY_INTEGER_WIDTH       : natural  := 2;
        DEMOD_XY_FRACTIONAL_WIDTH    : natural  := 14;
        DEMOD_OFFSET_BINARY          : boolean  := true;
        DEMOD_PGA_GAIN_WIDTH         : positive := 8;

        DEMOD_PACKET_LENGTH_MAX      : positive := 256;

        CLKMON_SECONDS_MAX           : positive := 31_536_000;
        CLKMON_DELTA_MAX             : positive := 500_000
    );
    port(
        -- Interface esclave AXI.
        s_axi_aclk       : in  std_logic;
        s_axi_aresetn    : in  std_logic;
        s_axi_awaddr     : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot     : in  std_logic_vector(2 downto 0);
        s_axi_awvalid    : in  std_logic;
        s_axi_awready    : out std_logic;
        s_axi_wdata      : in  std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_wstrb      : in  std_logic_vector(S_AXI_DATA_WIDTH / 8 - 1 downto 0);
        s_axi_wvalid     : in  std_logic;
        s_axi_wready     : out std_logic;
        s_axi_bresp      : out std_logic_vector(1 downto 0);
        s_axi_bvalid     : out std_logic;
        s_axi_bready     : in  std_logic;
        s_axi_araddr     : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot     : in  std_logic_vector(2 downto 0);
        s_axi_arvalid    : in  std_logic;
        s_axi_arready    : out std_logic;
        s_axi_rdata      : out std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_rresp      : out std_logic_vector(1 downto 0);
        s_axi_rvalid     : out std_logic;
        s_axi_rready     : in  std_logic;

        -- Interface maître AXI stream.
        m_axis_aclk      : in  std_logic;
        m_axis_aresetn   : in  std_logic;
        m_axis_tvalid    : out std_logic;
        m_axis_tdata     : out std_logic_vector(M_AXIS_DATA_WIDTH - 1 downto 0);
        m_axis_tstrb     : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tkeep     : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tlast     : out std_logic;
        m_axis_tready    : in  std_logic;

        -- Interfaces DAC et ADC.
        dac_m_valid_o     : out std_logic;
        dac_m_ready_i     : in  std_logic;
        dac_m_data_o      : out std_logic_vector(MOD_PHASE_INTEGER_WIDTH + MOD_PHASE_FRACTIONAL_WIDTH - 1 downto 0);
        dac_m_period_o    : out natural range 0 to MOD_CYCLES_PER_SAMPLE_MAX;
        dac_m_dc_value_o  : out std_logic_vector(MOD_DC_VALUE_WIDTH - 1 downto 0);

        adc_s_valid_i     : in  std_logic;
        adc_s_ready_o     : out std_logic;
        adc_s_data_i      : in  std_logic_vector(DEMOD_POWER_INTEGER_WIDTH + DEMOD_POWER_FRACTIONAL_WIDTH - 1 downto 0);
        adc_s_channel_o   : out natural range 0 to DEMOD_CHANNELS - 1;
        adc_s_period_o    : out natural range 0 to DEMOD_CYCLES_PER_SAMPLE_MAX;

        mod_pga_gain_o    : out std_logic_vector(MOD_PGA_GAIN_WIDTH - 1 downto 0);
        demod_pga_gains_o : out std_logic_vector(DEMOD_PGA_GAIN_WIDTH * DEMOD_CHANNELS - 1 downto 0);

        -- Entrée PPS provenant d'un module GPS.
        pps_i             : in  std_logic;

        gpio_i            : in  std_logic_vector(GPIO_WIDTH - 1 downto 0);
        gpio_o            : out std_logic_vector(GPIO_WIDTH - 1 downto 0)
    );
end LokiModem;
