
library ieee;
use ieee.std_logic_1164.all;

architecture Stub of AXIStreamTransceiver is
    signal axi_reg0, axi_reg1, axi_reg2, axi_reg3 : std_logic_vector(S_AXI_DATA_WIDTH - 1 downto 0);
    signal axi_reg_raddr, axi_reg_waddr : std_logic_vector(1 downto 0);
    signal axi_reg_wren, axi_reg_rden : std_logic;

    -- Signaux internes pour la gestion des interfaces AXI stream.
    constant AXI_STREAM_LOOPBACK : boolean := false;
    signal s_axis_tready_reg : std_logic;
    signal m_axis_tvalid_reg : std_logic;
begin
    -- -------------------------------------------------------------------------
    -- Exemple d'accès aux données par l'interface esclave AXI.
    -- -------------------------------------------------------------------------

    p_axi_reg : process (s_axi_aclk)
        variable l, r : integer;
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                axi_reg0 <= (others => '0');
                axi_reg1 <= (others => '0');
                axi_reg2 <= (others => '0');
                axi_reg3 <= (others => '0');
            elsif axi_reg_wren = '1' then
                for i in 0 to S_AXI_DATA_WIDTH / 8 - 1 loop
                    if s_axi_wstrb(i) = '1' then
                        r := i * 8;
                        l := r + 7;
                        case axi_reg_waddr is
                            when b"00" => axi_reg0(l downto r) <= s_axi_wdata(l downto r);
                            when b"01" => axi_reg1(l downto r) <= s_axi_wdata(l downto r);
                            when b"10" => axi_reg2(l downto r) <= s_axi_wdata(l downto r);
                            when b"11" => axi_reg3(l downto r) <= s_axi_wdata(l downto r);
                            when others =>
                        end case;
                    end if;
                end loop;
            end if;
        end if;
    end process p_axi_reg;

    p_s_axi_rdata : process(s_axi_aclk)
    begin
        if rising_edge (s_axi_aclk) then
            if s_axi_aresetn = '0' then
                s_axi_rdata  <= (others => '0');
            elsif axi_reg_rden = '1' then
                case axi_reg_raddr is
                    when b"00"  => s_axi_rdata <= axi_reg0;
                    when b"01"  => s_axi_rdata <= axi_reg1;
                    when b"10"  => s_axi_rdata <= axi_reg2;
                    when b"11"  => s_axi_rdata <= axi_reg3;
                    when others => s_axi_rdata <= (others => '0');
                end case;
            end if;
        end if;
    end process p_s_axi_rdata;

    -- -------------------------------------------------------------------------
    -- Gestion des interfaces AXI stream
    -- -------------------------------------------------------------------------

    axis_loopback : if AXI_STREAM_LOOPBACK generate
        s_axis_tready <= m_axis_tready;
        m_axis_tvalid <= s_axis_tvalid;
        m_axis_tstrb  <= s_axis_tstrb;
        m_axis_tdata  <= s_axis_tdata;
        m_axis_tlast  <= s_axis_tlast;
    end generate axis_loopback;

    axis_registered : if not AXI_STREAM_LOOPBACK generate
        -- Cet exemple suppose que les interfaces maître et esclave ont la même horloge.
        p_axis : process(s_axis_aclk)
        begin
            if rising_edge(s_axis_aclk) then
                if s_axis_aresetn = '0' then
                    s_axis_tready_reg <= '0';
                    m_axis_tvalid_reg <= '0';
                else
                    -- Si l'interface esclave n'est pas en train d'acquitter
                    -- et l'interface esclave a une donnée valide
                    -- et l'interface maître n'a pas de transfert en cours,
                    -- acquitter,
                    -- démarrer un transfert sur l'interface maître.
                    if s_axis_tready_reg = '0' and s_axis_tvalid = '1' and m_axis_tvalid_reg = '0' then
                        s_axis_tready_reg <= '1';
                        m_axis_tvalid_reg <= '1';
                        m_axis_tstrb <= s_axis_tstrb;
                        m_axis_tdata <= s_axis_tdata;
                        m_axis_tlast <= s_axis_tlast;
                    else
                        s_axis_tready_reg <= '0';
                    end if;

                    -- Si l'interface maître a un transfert en cours
                    -- et l'interface maître reçoit un acquittement,
                    -- terminer le transfert.
                    if m_axis_tvalid_reg = '1' and m_axis_tready = '1' then
                        m_axis_tvalid_reg <= '0';
                    end if;
                end if;
            end if;
        end process p_axis;

        s_axis_tready <= s_axis_tready_reg;
        m_axis_tvalid <= m_axis_tvalid_reg;
    end generate axis_registered;

    -- -------------------------------------------------------------------------
    -- Gestion de l'interface esclave AXI.
    -- -------------------------------------------------------------------------

    axi_slave : entity work.AXISlave(RTL)
        generic map(
            S_AXI_DATA_WIDTH => S_AXI_DATA_WIDTH,
            S_AXI_ADDR_WIDTH => S_AXI_ADDR_WIDTH
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
            reg_raddr_o   => axi_reg_raddr,
            reg_waddr_o   => axi_reg_waddr,
            reg_wren_o    => axi_reg_wren,
            reg_rden_o    => axi_reg_rden
        );
end Stub;
