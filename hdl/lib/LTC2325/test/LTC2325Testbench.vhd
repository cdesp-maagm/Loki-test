
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.LTC2325_pkg.all;

use std.env.all;

entity LTC2325Testbench is
end LTC2325Testbench;

architecture Simulation of LTC2325Testbench is
    constant CLK_FREQUENCY : integer := 50e6;

    constant ADC_CHANNELS : integer := 4;
    constant ADC_DATA_WIDTH : integer := 16;
    constant ADC_CLK_FREQUENCY : integer := 25e6;

    constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;
    constant SAMPLE_FREQUENCY : integer := ADC_CLK_FREQUENCY / 20;
    constant SAMPLE_PERIOD : time := 1 sec / SAMPLE_FREQUENCY;

    constant TIME_SCLK_TO_SCLKOUT : time := 4 ns;
    constant TIME_SDATA_VALID     : time := 3 ns;

    constant ITERATIONS : integer := 16;

    signal clk                         : std_logic := '0';
    signal reset                       : std_logic;
    signal adc_m_convert_n, adc_m_sclk : std_logic;
    signal adc_m_sclkout               : std_logic;
    signal adc_m_sdata                 : std_logic_vector(0 to ADC_CHANNELS - 1);
    signal adc_m_data                  : LTC2325DataArray_t(0 to ADC_CHANNELS - 1);
    signal adc_m_valid                 : std_logic;
    signal adc_m_ready                 : std_logic := '0';
begin
    clk <= not clk after CLK_PERIOD / 2;
    reset <= '1', '0' after CLK_PERIOD;

    adc_inst : entity work.LTC2325
        generic map(
            CHANNELS          => ADC_CHANNELS,
            CLK_FREQUENCY     => CLK_FREQUENCY,
            ADC_CLK_FREQUENCY => ADC_CLK_FREQUENCY
        )
        port map(
            clk_i             => clk,
            reset_i           => reset,
            adc_m_convert_n_o => adc_m_convert_n,
            adc_m_sclk_o      => adc_m_sclk,
            adc_m_sdata_i     => adc_m_sdata,
            m_data_o          => adc_m_data,
            m_valid_o         => adc_m_valid,
            m_ready_i         => adc_m_ready
        );

    adc_m_sclkout <= transport adc_m_sclk after TIME_SCLK_TO_SCLKOUT;

    process
        variable nvec, cvec : unsigned(ADC_DATA_WIDTH / 2 - 1 downto 0);
    begin
        for n in 1 to ITERATIONS loop
            nvec := to_unsigned(n, nvec'length);

            wait until falling_edge(adc_m_convert_n);
            wait for TIME_SDATA_VALID;

            for i in cvec'range loop
                for c in 0 to ADC_CHANNELS - 1 loop
                    cvec := to_unsigned(c, cvec'length);
                    adc_m_sdata(c) <= cvec(i);
                end loop;
                wait until falling_edge(adc_m_sclkout);
            end loop;

            for i in nvec'range loop
                adc_m_sdata <= (others => nvec(i));
                wait until falling_edge(adc_m_sclkout);
            end loop;
        end loop;

        finish;
    end process;

    process
        variable previous_sample_time : time := 0 ns;
    begin
        for n in 1 to ITERATIONS loop
            wait until rising_edge(clk) and adc_m_valid = '1' and now - previous_sample_time >= SAMPLE_PERIOD;
            previous_sample_time := now;
            adc_m_ready <= '1';
            wait until rising_edge(clk);
            adc_m_ready <= '0';
        end loop;
    end process;
end Simulation;
