
entity LokiSensorsTestbench is
end LokiSensorsTestbench;

library ieee;
use ieee.std_logic_1164.all;

use std.env.all;

architecture Simulation of LokiSensorsTestbench is
    constant CLK_PERIOD : time := 20 ns;

    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal spi_sck : std_logic;
    signal spi_cs_n : std_logic_vector(1 downto 0);
    signal spi_miso : std_logic := '0';
begin
    clk <= not clk after CLK_PERIOD / 2;
    reset_n <= '1' after CLK_PERIOD;

    sensors_inst : entity work.LokiSensors
        generic map(
            CYCLES_PER_SAMPLE_REF => 5e6
        ) 
        port map(
            s_axi_aclk     => clk,
            s_axi_aresetn  => reset_n,
            s_axi_awaddr   => (others => '0'),
            s_axi_awprot   => (others => '0'),
            s_axi_awvalid  => '0',
            s_axi_wdata    => (others => '0'),
            s_axi_wstrb    => (others => '0'),
            s_axi_wvalid   => '0',
            s_axi_bready   => '0',
            s_axi_araddr   => (others => '0'),
            s_axi_arprot   => (others => '0'),
            s_axi_arvalid  => '0',
            s_axi_rready   => '0',
            m_axis_aclk    => clk,
            m_axis_aresetn => reset_n,
            m_axis_tready  => '0',
            spi_miso_i     => spi_miso,
            spi_sck_o      => spi_sck,
            spi_cs_n_o     => spi_cs_n
        );
    
    p_spi_miso : process
    begin
        wait until falling_edge(spi_sck);
        spi_miso <= not spi_miso;
    end process p_spi_miso;

    process
    begin
        wait for 300 ms;
        finish;
    end process;
    
end Simulation;
