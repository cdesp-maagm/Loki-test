
library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.FIRFilter_pkg.all;
use work.FIRFilterTestbench_cfg.all;
use work.FIRFilterTestbench_pkg.all;

entity FIRFilterTestbench is
end FIRFilterTestbench;

architecture Simulation of FIRFilterTestbench is
    constant ERROR_MAX                          : real      := 2.0 ** (-TB_DATA_FRACTIONAL_WIDTH);
    constant BUFFER_LENGTH                      : integer   := 1024;

    signal clk, reset, s_valid, s_last, m_ready : std_logic := '0';
    signal s_ready, m_valid, m_last             : std_logic;
    signal s_channel, m_channel                 : natural;
    signal s_data, m_data                       : sfixed(TB_DATA_INTEGER_WIDTH - 1 downto -TB_DATA_FRACTIONAL_WIDTH);
    signal m_ref_data_real                      : real_vector(0 to BUFFER_LENGTH - 1);
    signal m_ref_channel                        : integer_vector(0 to BUFFER_LENGTH - 1);
    signal terminate                            : boolean   := false;
    signal error_marker                         : std_logic := '0';
begin
    filter_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => TB_PARALLELISM,
            CHANNELS     => TB_CHANNELS,
            GAIN_BITS    => GAIN_BITS,
            COEFFICIENTS => COEFFICIENTS
        )
        port map(
            clk_i       => clk,
            reset_i     => reset,
            s_valid_i   => s_valid,
            s_last_i    => s_last,
            s_ready_o   => s_ready,
            s_channel_i => s_channel,
            s_data_i    => s_data,
            m_valid_o   => m_valid,
            m_last_o    => m_last,
            m_ready_i   => m_ready,
            m_channel_o => m_channel,
            m_data_o    => m_data
        );

    clk <= not clk after TB_CLK_PERIOD / 2;
    reset <= '1', '0' after TB_CLK_PERIOD;

    p_master : process
        file csv                          : text open read_mode is "build/tb/FIRFilterTestbench_in.csv";
        variable csv_line                  : line;
        variable channel                  : integer;
        variable s_data_real, m_data_real : real;
        variable phase                    : natural range 0 to TB_DECIMATION - 1;
        variable index                    : natural range 0 to BUFFER_LENGTH - 1;
    begin
        loop
            wait until rising_edge(clk) and reset = '0';

            readline(csv, csv_line);
            read(csv_line, channel);
            read(csv_line, s_data_real);
            read(csv_line, m_data_real);

            if phase = TB_DECIMATION - 1 then
                m_ref_data_real(index) <= m_data_real;
                m_ref_channel(index)   <= channel;

                if index = BUFFER_LENGTH - 1 then
                    index := 0;
                else
                    index := index + 1;
                end if;
            end if;

            if channel = TB_CHANNELS - 1 then
                if phase = TB_DECIMATION - 1 then
                    phase := 0;
                else
                    phase := phase + 1;
                end if;
            end if;

            s_channel <= channel;
            s_data <= to_sfixed(s_data_real, s_data);
            if channel = TB_CHANNELS - 1 then
                s_last <= '1';
            else
                s_last <= '0';
            end if;

            s_valid <= '1';

            wait until rising_edge(clk) and s_ready = '1';

            s_valid <= '0';

            exit when endfile(csv);

            for i in 1 to TB_CYCLES_AFTER_S_READY loop
                wait until rising_edge(clk);
            end loop;
        end loop;

        terminate <= true;
        wait;
    end process p_master;


    p_slave : process
        file csv              : text open write_mode is "build/tb/FIRFilterTestbench_out.csv";
        variable csv_line     : line;
        variable err, err_max : real := 0.0;
        variable index        : natural range 0 to BUFFER_LENGTH - 1;
    begin
        wait until rising_edge(clk) and reset = '0';

        loop
            wait until rising_edge(clk) and m_valid = '1';

            write(csv_line, m_channel);
            write(csv_line, ' ');
            write(csv_line, to_real(m_data));
            writeline(csv, csv_line);

            assert m_channel = m_ref_channel(index)
                report "Canal incorrect : m_channel_o=" & integer'image(m_channel)
                    & " attendu " & integer'image(m_ref_channel(index))
                severity error;

            err := abs(to_real(m_data) - m_ref_data_real(index));
            err_max := maximum(err, err_max);

            if err > ERROR_MAX then
                report "Sortie incorrecte sur le canal " & integer'image(m_channel)
                    & " : m_data_o="                     & real'image(to_real(m_data))
                    & " attendu "                        & real'image(m_ref_data_real(index))
                    & " erreur "                         & real'image(err)
                    severity error;
                error_marker <= '1';
            end if;

            if index = BUFFER_LENGTH - 1 then
                index := 0;
            else
                index := index + 1;
            end if;

            for i in 1 to TB_CYCLES_AFTER_M_VALID loop
                wait until rising_edge(clk);
            end loop;

            m_ready <= '1';

            wait until rising_edge(clk);

            error_marker <= '0';
            m_ready <= '0';

            exit when terminate and m_last = '1';
        end loop;

        report "Erreur max : " & real'image(err_max);

        finish;
    end process p_slave;
end Simulation;
