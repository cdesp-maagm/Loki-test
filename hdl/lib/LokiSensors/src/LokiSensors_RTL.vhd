
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LokiSensors is
    generic(
        S_AXI_ADDR_WIDTH      : positive := 32;
        S_AXI_DATA_WIDTH      : positive := 32;
        M_AXIS_DATA_WIDTH     : positive := 32;
        CLK_FREQUENCY         : positive := 50e6;  -- TODO paramétrage séparé
        CYCLES_PER_SAMPLE_MAX : positive := 500e6; -- TODO paramétrage séparé
        CYCLES_PER_SAMPLE_REF : positive := 50e6;  -- TODO paramétrage séparé
        CHANNEL_OUTPUT_WIDTH  : positive := 5;     -- TODO paramétrage séparé
        PACKET_LENGTH_MAX     : positive := 16383  -- TODO paramétrage séparé
    );
    port(
        -- Interface esclave AXI.
        s_axi_aclk     : in  std_logic;
        s_axi_aresetn  : in  std_logic;
        s_axi_awaddr   : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot   : in  std_logic_vector(2 downto 0);
        s_axi_awvalid  : in  std_logic;
        s_axi_awready  : out std_logic;
        s_axi_wdata    : in  std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_wstrb    : in  std_logic_vector(S_AXI_DATA_WIDTH / 8 - 1 downto 0);
        s_axi_wvalid   : in  std_logic;
        s_axi_wready   : out std_logic;
        s_axi_bresp    : out std_logic_vector(1 downto 0);
        s_axi_bvalid   : out std_logic;
        s_axi_bready   : in  std_logic;
        s_axi_araddr   : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot   : in  std_logic_vector(2 downto 0);
        s_axi_arvalid  : in  std_logic;
        s_axi_arready  : out std_logic;
        s_axi_rdata    : out std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_rresp    : out std_logic_vector(1 downto 0);
        s_axi_rvalid   : out std_logic;
        s_axi_rready   : in  std_logic;

        -- Interface maître AXI stream.
        m_axis_aclk    : in  std_logic;
        m_axis_aresetn : in  std_logic;
        m_axis_tvalid  : out std_logic;
        m_axis_tdata   : out std_logic_vector(M_AXIS_DATA_WIDTH - 1 downto 0);
        m_axis_tstrb   : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tkeep   : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tlast   : out std_logic;
        m_axis_tready  : in  std_logic;

        -- Interface SPI
        spi_miso_i     : in std_logic;
        spi_mosi_o     : out std_logic;
        spi_sck_o      : out std_logic;
        spi_cs_n_o     : out std_logic_vector(1 downto 0)
    );
end LokiSensors;

use work.LokiSensors_pkg.all;
use work.LTC2984_pkg.all;
use work.BMP390_pkg.all;

architecture RTL of LokiSensors is
    signal ltc2984_enable             : std_logic;
    signal ltc2984_missing            : std_logic;
    signal ltc2984_data               : LTC2984DataArray_t;
    signal ltc2984_valid              : std_logic;
    signal ltc2984_ready              : std_logic;
    signal ltc2984_status             : std_logic_vector(7 downto 0);
    signal ltc2984_mosi               : std_logic;
    signal ltc2984_sck                : std_logic;
    signal ltc2984_cs_n               : std_logic;

    signal bmp390_enable              : std_logic;
    signal bmp390_missing             : std_logic;
    signal bmp390_data                : BMP390DataArray_t;
    signal bmp390_valid               : std_logic;
    signal bmp390_ready               : std_logic;
    signal bmp390_status              : std_logic_vector(15 downto 0);
    signal bmp390_nvm_data            : BMP390NVMDataArray_t;
    signal bmp390_mosi                : std_logic;
    signal bmp390_sck                 : std_logic;
    signal bmp390_cs_n                : std_logic;

    type State_t is (IDLE, READ_TEMPERATURE, READ_PRESSURE);
    signal state_reg : State_t;

    signal sensor_data_reg            : LokiSensorsDataArray_t;

    signal reset                      : std_logic;
    signal restart_reg                : std_logic;

    signal reg_raddr, reg_waddr       : std_logic_vector(5 downto 0);
    signal reg_rden, reg_wren         : std_logic;

    constant PACKET_COUNT_FIELD_WIDTH : positive := M_AXIS_DATA_WIDTH - LTC2984_DATA_WIDTH - CHANNEL_OUTPUT_WIDTH;
    constant PACKET_COUNT_MAX         : natural  := 2 ** PACKET_COUNT_FIELD_WIDTH - 1;

    signal cycles_per_sample_reg      : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal axis_packet_length_reg     : positive range 1 to PACKET_LENGTH_MAX;
    signal axis_packet_count_reg      : natural range 0 to PACKET_COUNT_MAX;
    signal axis_sample_count_reg      : natural range 0 to PACKET_LENGTH_MAX - 1;
    signal axis_channel_reg           : natural range 0 to LOKI_SENSORS_CHANNELS - 1;

    signal sample_timer_reg           : natural range 0 to CYCLES_PER_SAMPLE_MAX - 1;
    signal sample_timer_next          : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal sample_timer_cycle         : boolean;

    signal m_axis_tvalid_reg          : std_logic;
begin
    reset <= not m_axis_aresetn;

    -- ------------------------------------------------------------------------
    -- Contrôle de l'échantillonnage.
    -- ------------------------------------------------------------------------

    p_state_reg: process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' then
                state_reg <= IDLE;
            else
                case state_reg is
                    when IDLE =>
                        if sample_timer_cycle then
                            state_reg <= READ_TEMPERATURE;
                        end if;

                    when READ_TEMPERATURE =>
                        if ltc2984_valid = '1' or ltc2984_missing = '1' then
                            state_reg <= READ_PRESSURE;
                        end if;

                    when READ_PRESSURE =>
                        if bmp390_valid = '1' or bmp390_missing = '1' then
                            state_reg <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process p_state_reg;

    sample_timer_next  <= sample_timer_reg + 1;
    sample_timer_cycle <= sample_timer_next = CYCLES_PER_SAMPLE_MAX or sample_timer_next >= cycles_per_sample_reg;

    p_sample_timer_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or sample_timer_cycle then
                sample_timer_reg <= 0;
            elsif not sample_timer_cycle then
                sample_timer_reg <= sample_timer_next;
            end if;
        end if;
    end process p_sample_timer_reg;

    -- ------------------------------------------------------------------------
    -- Capteurs de température
    -- ------------------------------------------------------------------------

    ltc2984_enable <= '1' when state_reg = READ_TEMPERATURE else '0';
    ltc2984_ready  <= '1' when state_reg = IDLE and sample_timer_cycle else '0';

    ltc2984_inst : entity work.LTC2984
        generic map(
            CLK_FREQUENCY => CLK_FREQUENCY
        )
        port map(
            clk_i      => m_axis_aclk,
            reset_i    => reset,
            enable_i   => ltc2984_enable,
            data_o     => ltc2984_data,
            valid_o    => ltc2984_valid,
            ready_i    => ltc2984_ready,
            missing_o  => ltc2984_missing,
            status_o   => ltc2984_status,
            spi_miso_i => spi_miso_i,
            spi_mosi_o => ltc2984_mosi,
            spi_sck_o  => ltc2984_sck,
            spi_cs_n_o => ltc2984_cs_n
        );

    -- ------------------------------------------------------------------------
    -- Capteur de pression
    -- ------------------------------------------------------------------------

    bmp390_enable <= '1' when state_reg = READ_PRESSURE else '0';
    bmp390_ready  <= ltc2984_valid when state_reg = READ_TEMPERATURE else '0';

    bmp390_inst : entity work.BMP390
        generic map(
            CLK_FREQUENCY => CLK_FREQUENCY
        )
        port map(
            clk_i      => m_axis_aclk,
            reset_i    => reset,
            enable_i   => bmp390_enable,
            data_o     => bmp390_data,
            valid_o    => bmp390_valid,
            ready_i    => bmp390_ready,
            missing_o  => bmp390_missing,
            status_o   => bmp390_status,
            nvm_data_o => bmp390_nvm_data,
            spi_miso_i => spi_miso_i,
            spi_mosi_o => bmp390_mosi,
            spi_sck_o  => bmp390_sck,
            spi_cs_n_o => bmp390_cs_n
        );

    -- ------------------------------------------------------------------------
    -- Multiplexage du bus SPI
    -- ------------------------------------------------------------------------

    spi_cs_n_o <= (0 => ltc2984_cs_n, 1 => bmp390_cs_n);

    with state_reg select
        spi_mosi_o <= ltc2984_mosi when READ_TEMPERATURE,
                      bmp390_mosi  when READ_PRESSURE,
                      '0'          when others;
    with state_reg select
        spi_sck_o  <= ltc2984_sck  when READ_TEMPERATURE,
                      bmp390_sck   when READ_PRESSURE,
                      '0'          when others;

    -- ------------------------------------------------------------------------
    -- Aggrégation des mesures
    -- ------------------------------------------------------------------------

    -- Les valeurs sont écrasées à chaque période d'échantillonnage
    -- même si elles n'ont pas été consommées à travers l'interface AXI stream.
    p_sensor_data_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' then
                sensor_data_reg <= (others => (others => '0'));
            else
                case state_reg is
                    when READ_TEMPERATURE =>
                        if ltc2984_valid = '1' then
                            for c in 0 to LTC2984_CHANNELS - 1 loop
                                sensor_data_reg(c) <= std_logic_vector(resize(ltc2984_data(c), LOKI_SENSORS_DATA_WIDTH));
                            end loop;
                        end if;
                    when READ_PRESSURE =>
                        if bmp390_valid = '1' then
                            for c in 0 to BMP390_CHANNELS - 1 loop
                                sensor_data_reg(LTC2984_CHANNELS + c) <= std_logic_vector(resize(bmp390_data(c), LOKI_SENSORS_DATA_WIDTH));
                            end loop;
                        end if;
                    when others =>
                end case;
            end if;
        end if;
    end process p_sensor_data_reg;

    -- ------------------------------------------------------------------------
    -- Interface AXI stream
    -- ------------------------------------------------------------------------

    -- Comptage des voies/échantillons/paquets DMA.
    p_packet_count_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or restart_reg = '1' then
                axis_channel_reg      <= 0;
                axis_sample_count_reg <= 0;
                axis_packet_count_reg <= 0;
            elsif m_axis_tvalid_reg = '1' and m_axis_tready = '1' then
                if axis_sample_count_reg >= axis_packet_length_reg - 1 then
                    axis_sample_count_reg <= 0;
                    if axis_packet_count_reg = PACKET_COUNT_MAX then
                        axis_packet_count_reg <= 0;
                    else
                        axis_packet_count_reg <= axis_packet_count_reg + 1;
                    end if;
                else
                    axis_sample_count_reg <= axis_sample_count_reg + 1;
                end if;

                if axis_channel_reg >= LOKI_SENSORS_CHANNELS - 1 then
                    axis_channel_reg <= 0;
                else
                    axis_channel_reg <= axis_channel_reg + 1;
                end if;
            end if;
        end if;
    end process p_packet_count_reg;

    m_axis_tdata <= std_logic_vector(to_unsigned(axis_packet_count_reg, PACKET_COUNT_FIELD_WIDTH)) &
                    std_logic_vector(to_unsigned(axis_channel_reg, CHANNEL_OUTPUT_WIDTH)) &
                    std_logic_vector(sensor_data_reg(axis_channel_reg));

    m_axis_tlast <= '1' when axis_sample_count_reg >= axis_packet_length_reg - 1 else '0';

    -- Gestion des signaux de handshake.
    -- Les données sont valides à la fin de chaque acquisition de la pression.
    p_m_axis : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' then
                m_axis_tvalid_reg <= '0';
            elsif state_reg = READ_PRESSURE and (bmp390_valid = '1' or bmp390_missing = '1') then
                m_axis_tvalid_reg <= '1';
            elsif m_axis_tvalid_reg = '1' and m_axis_tready = '1' and axis_channel_reg >= LOKI_SENSORS_CHANNELS - 1 then
                m_axis_tvalid_reg <= '0';
            end if;
        end if;
    end process p_m_axis;

    m_axis_tvalid <= m_axis_tvalid_reg;
    m_axis_tstrb  <= (others => '1');
    m_axis_tkeep  <= (others => '1');

    -- ------------------------------------------------------------------------
    -- Interface AXI
    -- ------------------------------------------------------------------------

    axi_inst : entity work.AXISlave
        generic map(
            S_AXI_ADDR_WIDTH => S_AXI_ADDR_WIDTH,
            S_AXI_DATA_WIDTH => S_AXI_DATA_WIDTH
        )
        port map(
            s_axi_aclk    => s_axi_aclk,
            s_axi_aresetn => s_axi_aresetn,
            s_axi_awaddr  => s_axi_awaddr,
            s_axi_awvalid => s_axi_awvalid,
            s_axi_awready => s_axi_awready,
            s_axi_wvalid  => s_axi_wvalid,
            s_axi_wready  => s_axi_wready,
            s_axi_bresp   => s_axi_bresp,
            s_axi_bvalid  => s_axi_bvalid,
            s_axi_bready  => s_axi_bready,
            s_axi_araddr  => s_axi_araddr,
            s_axi_arvalid => s_axi_arvalid,
            s_axi_arready => s_axi_arready,
            s_axi_rresp   => s_axi_rresp,
            s_axi_rvalid  => s_axi_rvalid,
            s_axi_rready  => s_axi_rready,
            reg_raddr_o   => reg_raddr,
            reg_waddr_o   => reg_waddr,
            reg_rden_o    => reg_rden,
            reg_wren_o    => reg_wren
        );

    p_s_axi_rdata : process(s_axi_aclk)
        variable addr : natural range 0 to 2 ** reg_raddr'length - 1;
        variable reg  : Register_t;

        procedure bus_read(a : integer) is
        begin
            s_axi_rdata <= std_logic_vector(to_signed(a, s_axi_rdata'length));
        end bus_read;

        procedure bus_read(a : signed) is
        begin
            s_axi_rdata <= std_logic_vector(resize(a, s_axi_rdata'length));
        end bus_read;

        procedure bus_read(a : std_logic_vector) is
        begin
            s_axi_rdata          <= (others => '0');
            s_axi_rdata(a'range) <= a;
        end bus_read;
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                s_axi_rdata <= (others => '0');
            elsif reg_rden = '1' then
                s_axi_rdata <= (others => '0');
                addr := to_integer(unsigned(reg_raddr));
                if addr <= Register_t'pos(Register_t'high) then
                    reg := Register_t'val(addr);
                    case reg is
                        when REG_CLK_FREQUENCY         => bus_read(CLK_FREQUENCY);
                        when REG_CHANNELS              => bus_read(LOKI_SENSORS_CHANNELS);
                        when REG_CHANNEL_OUTPUT_WIDTH  => bus_read(CHANNEL_OUTPUT_WIDTH);
                        when REG_DATA_WIDTH            => bus_read(LOKI_SENSORS_DATA_WIDTH);
                        when REG_CYCLES_PER_SAMPLE_MAX => bus_read(CYCLES_PER_SAMPLE_MAX);
                        when REG_PACKET_LENGTH_MAX     => bus_read(PACKET_LENGTH_MAX);
                        when REG_CYCLES_PER_SAMPLE     => bus_read(cycles_per_sample_reg);
                        when REG_PACKET_LENGTH         => bus_read(axis_packet_length_reg);
                        when REG_CONTROL               => s_axi_rdata <= (0 => restart_reg, others => '0');
                        when REG_STATUS                => s_axi_rdata <= (not bmp390_missing) & (not ltc2984_missing) & "000000" & bmp390_status & ltc2984_status;
                        when others                    => bus_read(bmp390_nvm_data(addr - Register_t'pos(REG_BMP390_NVM0)));
                    end case;
                elsif addr >= REG_LAST_DATA and addr < REG_LAST_DATA + LOKI_SENSORS_CHANNELS then
                    bus_read(sensor_data_reg(addr - REG_LAST_DATA));
                end if;
            end if;
        end if;
    end process p_s_axi_rdata;

    p_axi_reg : process(s_axi_aclk)
        variable addr : natural range 0 to 2 ** reg_waddr'length - 1;
        variable reg  : Register_t;

        function from_bus(data : std_logic_vector; a, b : integer) return integer is
            variable v : natural := to_integer(unsigned(data));
        begin
            if v < a then
                return a;
            elsif v > b then
                return b;
            else
                return v;
            end if;
        end from_bus;
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                restart_reg            <= '0';
                cycles_per_sample_reg  <= CYCLES_PER_SAMPLE_REF;
                axis_packet_length_reg <= PACKET_LENGTH_MAX;
            elsif reg_wren = '1' then
                addr := to_integer(unsigned(reg_waddr));
                if addr <= Register_t'pos(Register_t'high) then
                    reg := Register_t'val(addr);
                    case reg is
                        when REG_CYCLES_PER_SAMPLE => cycles_per_sample_reg  <= from_bus(s_axi_wdata, 1, CYCLES_PER_SAMPLE_MAX);
                        when REG_PACKET_LENGTH     => axis_packet_length_reg <= from_bus(s_axi_wdata, 1, PACKET_LENGTH_MAX);
                        when REG_CONTROL           => restart_reg            <= s_axi_wdata(0);
                        when others                =>
                    end case;
                end if;
            else
                -- Remise à zéro automatique au cycle suivant l'écriture.
                restart_reg <= '0';
            end if;
        end if;
    end process p_axi_reg;
end RTL;
