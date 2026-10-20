
library ieee;
use ieee.std_logic_1164.all;

entity AXIStreamTransceiver is
    generic(
        S_AXI_ADDR_WIDTH : integer := 32;
        S_AXI_DATA_WIDTH : integer := 32;
        S_AXIS_DATA_WIDTH : integer := 32;
        M_AXIS_DATA_WIDTH : integer := 32
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
        m_axis_tlast   : out std_logic;
        m_axis_tready  : in  std_logic;

        -- Interface esclave AXI stream.
        s_axis_aclk    : in  std_logic;
        s_axis_aresetn : in  std_logic;
        s_axis_tready  : out std_logic;
        s_axis_tdata   : in  std_logic_vector(S_AXIS_DATA_WIDTH - 1 downto 0);
        s_axis_tstrb   : in  std_logic_vector(S_AXIS_DATA_WIDTH / 8 -1 downto 0);
        s_axis_tlast   : in  std_logic;
        s_axis_tvalid  : in  std_logic
    );
end AXIStreamTransceiver;
