
library ieee;
use ieee.std_logic_1164.all;

entity AXISlave is
    generic(
        S_AXI_ADDR_WIDTH  : integer;
        S_AXI_DATA_WIDTH  : integer
    );
    port(
        s_axi_aclk    : in  std_logic;
        s_axi_aresetn : in  std_logic;
        s_axi_awaddr  : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;
        s_axi_bresp   : out std_logic_vector(1 downto 0);
        s_axi_bvalid  : out std_logic;
        s_axi_bready  : in  std_logic;
        s_axi_araddr  : in  std_logic_vector(S_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;
        s_axi_rresp   : out std_logic_vector(1 downto 0);
        s_axi_rvalid  : out std_logic;
        s_axi_rready  : in  std_logic;

        reg_raddr_o   : out std_logic_vector;
        reg_waddr_o   : out std_logic_vector;
        reg_rden_o    : out std_logic;
        reg_wren_o    : out std_logic
    );
end AXISlave;

architecture RTL of AXISlave is
    constant ADDR_LSB  : integer := S_AXI_DATA_WIDTH / 32 + 1;

    signal awready_reg : std_logic;
    signal wready_reg  : std_logic;
    signal bvalid_reg  : std_logic;
    signal arready_reg : std_logic;
    signal rvalid_reg  : std_logic;
begin
    p_awready_aw_en_awaddr_reg : process (s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                awready_reg <= '0';
            elsif awready_reg = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' then
                awready_reg <= '1';
                reg_waddr_o <= s_axi_awaddr(ADDR_LSB + reg_waddr_o'left downto ADDR_LSB);
            else
                awready_reg <= '0';
            end if;
        end if;
    end process p_awready_aw_en_awaddr_reg;

    s_axi_awready <= awready_reg;

    p_wready_reg : process (s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                wready_reg <= '0';
            elsif wready_reg = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' then
                wready_reg <= '1';
            else
                wready_reg <= '0';
            end if;
        end if;
    end process p_wready_reg;

    s_axi_wready <= wready_reg;

    p_bvalid_bresp_reg : process (s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                bvalid_reg <= '0';
            elsif awready_reg = '1' and s_axi_awvalid = '1' and wready_reg = '1' and s_axi_wvalid = '1' and bvalid_reg = '0' then
                bvalid_reg <= '1';
            elsif s_axi_bready = '1' and bvalid_reg = '1' then
                bvalid_reg <= '0';
            end if;
        end if;
    end process p_bvalid_bresp_reg;

    s_axi_bvalid <= bvalid_reg;
    s_axi_bresp  <= "00";

    p_arready_araddr_reg : process (s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                arready_reg <= '0';
            elsif arready_reg = '0' and s_axi_arvalid = '1' then
                arready_reg <= '1';
                reg_raddr_o <= s_axi_araddr(ADDR_LSB + reg_raddr_o'left downto ADDR_LSB);
            else
                arready_reg <= '0';
            end if;
        end if;
    end process p_arready_araddr_reg;

    s_axi_arready <= arready_reg;

    p_rvalid_rresp_reg : process (s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                rvalid_reg <= '0';
            elsif arready_reg = '1' and s_axi_arvalid = '1' and rvalid_reg = '0' then
                rvalid_reg <= '1';
            elsif rvalid_reg = '1' and s_axi_rready = '1' then
                rvalid_reg <= '0';
            end if;
        end if;
    end process p_rvalid_rresp_reg;

    s_axi_rvalid <= rvalid_reg;
    s_axi_rresp  <= "00";

    reg_wren_o <= wready_reg and s_axi_wvalid and awready_reg and s_axi_awvalid;
    reg_rden_o <= arready_reg and s_axi_arvalid and not rvalid_reg;
end RTL;
