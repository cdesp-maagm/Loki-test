
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LTC2325_AXI is
    generic(
        S_AXI_ADDR_WIDTH      : positive := 32;
        S_AXI_DATA_WIDTH      : positive := 32;
        M_AXIS_DATA_WIDTH     : positive := 32;
        CHANNELS              : positive := 4;
        CLK_FREQUENCY         : positive := 50e6;  -- TODO paramétrage séparé
        ADC_CLK_FREQUENCY     : positive := 25e6;  -- TODO paramétrage séparé
        CYCLES_PER_SAMPLE_MAX : positive := 50e6;  -- TODO paramétrage séparé
        CYCLES_PER_SAMPLE_REF : positive := 500e3; -- TODO paramétrage séparé
        CHANNEL_OUTPUT_WIDTH  : positive := 2;     -- TODO paramétrage séparé
        PACKET_LENGTH_MAX     : positive := 4095   -- TODO paramétrage séparé
    );
    port(
        -- Interface esclave AXI.
        s_axi_aclk        : in  std_logic;
        s_axi_aresetn     : in  std_logic;
        s_axi_awaddr      : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot      : in  std_logic_vector(2 downto 0);
        s_axi_awvalid     : in  std_logic;
        s_axi_awready     : out std_logic;
        s_axi_wdata       : in  std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_wstrb       : in  std_logic_vector(S_AXI_DATA_WIDTH / 8 - 1 downto 0);
        s_axi_wvalid      : in  std_logic;
        s_axi_wready      : out std_logic;
        s_axi_bresp       : out std_logic_vector(1 downto 0);
        s_axi_bvalid      : out std_logic;
        s_axi_bready      : in  std_logic;
        s_axi_araddr      : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot      : in  std_logic_vector(2 downto 0);
        s_axi_arvalid     : in  std_logic;
        s_axi_arready     : out std_logic;
        s_axi_rdata       : out std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
        s_axi_rresp       : out std_logic_vector(1 downto 0);
        s_axi_rvalid      : out std_logic;
        s_axi_rready      : in  std_logic;

        -- Interface maître AXI stream.
        m_axis_aclk       : in  std_logic;
        m_axis_aresetn    : in  std_logic;
        m_axis_tvalid     : out std_logic;
        m_axis_tdata      : out std_logic_vector(M_AXIS_DATA_WIDTH - 1 downto 0);
        m_axis_tstrb      : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tkeep      : out std_logic_vector(M_AXIS_DATA_WIDTH / 8 - 1 downto 0);
        m_axis_tlast      : out std_logic;
        m_axis_tready     : in  std_logic;

        -- Interface ADC.
        adc_m_convert_n_o : out std_logic;
        adc_m_sclk_i      : in  std_logic;
        adc_m_sclk_o      : out std_logic;
        adc_m_sdata_i     : in  std_logic_vector(CHANNELS - 1 downto 0)
    );
end LTC2325_AXI;

use work.LTC2325_pkg.all;

architecture RTL of LTC2325_AXI is
    signal m_axis_tvalid_reg          : std_logic;

    signal adc_reset                  : std_logic;
    signal adc_m_valid, adc_m_ready   : std_logic;
    signal adc_m_data, adc_m_data_reg : LTC2325DataArray_t(0 to CHANNELS - 1);

    signal reg_raddr, reg_waddr       : std_logic_vector(3 downto 0);
    signal reg_rden, reg_wren         : std_logic;

    constant PACKET_COUNT_FIELD_WIDTH : positive := M_AXIS_DATA_WIDTH - LTC2325_DATA_WIDTH - CHANNEL_OUTPUT_WIDTH;
    constant PACKET_COUNT_MAX         : natural := 2 ** PACKET_COUNT_FIELD_WIDTH - 1;

    signal cycles_per_sample_reg      : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal packet_length_reg          : positive range 1 to PACKET_LENGTH_MAX;
    signal packet_count_reg           : natural range 0 to PACKET_COUNT_MAX;
    signal sample_count_reg           : natural range 0 to PACKET_LENGTH_MAX - 1;
    signal channel_reg                : natural range 0 to CHANNELS - 1;

    signal timer_reg                  : natural range 0 to CYCLES_PER_SAMPLE_MAX - 1;
    signal timer_next                 : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal timer_cycle                : boolean;
begin
    timer_next  <= timer_reg + 1;
    timer_cycle <= timer_next = CYCLES_PER_SAMPLE_MAX or timer_next >= cycles_per_sample_reg;

    p_timer_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' or adc_m_ready = '1' then
                timer_reg <= 0;
            elsif not timer_cycle then
                timer_reg <= timer_next;
            end if;
        end if;
    end process p_timer_reg;

    adc_m_ready <= adc_m_valid when timer_cycle else '0';

    adc_reset <= not m_axis_aresetn;

    adc_inst : entity work.LTC2325
        generic map(
            CHANNELS          => CHANNELS,
            CLK_FREQUENCY     => CLK_FREQUENCY,
            ADC_CLK_FREQUENCY => ADC_CLK_FREQUENCY
        )
        port map(
            clk_i             => m_axis_aclk,
            reset_i           => adc_reset,
            adc_m_convert_n_o => adc_m_convert_n_o,
            adc_m_sclk_o      => adc_m_sclk_o,
            adc_m_sdata_i     => adc_m_sdata_i,
            m_data_o          => adc_m_data,
            m_valid_o         => adc_m_valid,
            m_ready_i         => adc_m_ready
        );

    -- Mémoriser les données de toutes les voies à la fin d'une acquisition.
    p_adc_m_data_reg : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if adc_m_ready = '1' then
                adc_m_data_reg <= adc_m_data;
            end if;
        end if;
    end process p_adc_m_data_reg;

    -- Gérer l'interface AXI stream.
    p_packet_count_reg : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' then
                channel_reg      <= 0;
                sample_count_reg <= 0;
                packet_count_reg <= 0;
            elsif m_axis_tvalid_reg = '1' and m_axis_tready = '1' then
                if channel_reg = CHANNELS - 1 then
                    channel_reg <= 0;
                    if sample_count_reg >= packet_length_reg - 1 then
                        sample_count_reg <= 0;
                        if packet_count_reg = PACKET_COUNT_MAX then
                            packet_count_reg <= 0;
                        else
                            packet_count_reg <= packet_count_reg + 1;
                        end if;
                    else
                        sample_count_reg <= sample_count_reg + 1;
                    end if;
                else
                    channel_reg <= channel_reg + 1;
                end if;
            end if;
        end if;
    end process p_packet_count_reg;

    m_axis_tdata <= std_logic_vector(to_unsigned(packet_count_reg, PACKET_COUNT_FIELD_WIDTH)) &
                    std_logic_vector(to_unsigned(channel_reg, CHANNEL_OUTPUT_WIDTH)) &
                    adc_m_data_reg(channel_reg);

    m_axis_tlast <= '1' when channel_reg = CHANNELS - 1 and sample_count_reg >= packet_length_reg - 1 else '0';

    p_m_axis : process(m_axis_aclk)
    begin
        if rising_edge(m_axis_aclk) then
            if adc_m_ready = '1' then
                m_axis_tvalid_reg <= '1';
            elsif m_axis_tvalid_reg = '1' and m_axis_tready = '1' and channel_reg = CHANNELS - 1 then
                m_axis_tvalid_reg <= '0';
            end if;
        end if;
    end process p_m_axis;

    m_axis_tvalid <= m_axis_tvalid_reg;
    m_axis_tstrb  <= (others => '1');
    m_axis_tkeep  <= (others => '1');

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

        procedure bus_read(a : std_logic_vector) is
        begin
            s_axi_rdata <= std_logic_vector(resize(signed(a), s_axi_rdata'length));
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
                        when REG_CHANNELS              => bus_read(CHANNELS);
                        when REG_CHANNEL_OUTPUT_WIDTH  => bus_read(CHANNEL_OUTPUT_WIDTH);
                        when REG_DATA_WIDTH            => bus_read(LTC2325_DATA_WIDTH);
                        when REG_CYCLES_PER_SAMPLE_MAX => bus_read(CYCLES_PER_SAMPLE_MAX);
                        when REG_PACKET_LENGTH_MAX     => bus_read(PACKET_LENGTH_MAX);
                        when REG_CYCLES_PER_SAMPLE     => bus_read(cycles_per_sample_reg);
                        when REG_PACKET_LENGTH         => bus_read(packet_length_reg);
                        when others                    =>
                    end case;
                elsif addr >= REG_LAST_DATA and addr < REG_LAST_DATA + CHANNELS then
                    bus_read(adc_m_data_reg(addr - REG_LAST_DATA));
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
                cycles_per_sample_reg <= CYCLES_PER_SAMPLE_REF;
                packet_length_reg     <= PACKET_LENGTH_MAX;
            elsif reg_wren = '1' then
                addr := to_integer(unsigned(reg_waddr));
                if addr <= Register_t'pos(Register_t'high) then
                    reg := Register_t'val(addr);
                    case reg is
                        when REG_CYCLES_PER_SAMPLE => cycles_per_sample_reg <= from_bus(s_axi_wdata, 1, CYCLES_PER_SAMPLE_MAX);
                        when REG_PACKET_LENGTH     => packet_length_reg     <= from_bus(s_axi_wdata, 1, PACKET_LENGTH_MAX);
                        when others                =>
                    end case;
                end if;
            end if;
        end if;
    end process p_axi_reg;
end RTL;
