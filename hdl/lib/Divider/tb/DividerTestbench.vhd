
library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use std.env.all; -- GHDL

use work.fixed_pkg.all;
use work.DividerTestbench_cfg.all;

entity DividerTestbench is
end DividerTestbench;

architecture Simulation of DividerTestbench is
    signal clk, reset, s_valid, m_ready      : std_logic := '0';
    signal s_ready, m_valid                  : std_logic;
    signal terminate                         : boolean   := false;

    constant QUOTIENT_INTEGER_WIDTH          : integer   := TB_DIVIDEND_INTEGER_WIDTH + TB_DIVISOR_FRACTIONAL_WIDTH;
    constant QUOTIENT_FRACTIONAL_WIDTH       : integer   := TB_DIVIDEND_FRACTIONAL_WIDTH + TB_DIVISOR_INTEGER_WIDTH - 1;
    constant REMAINDER_INTEGER_WIDTH         : integer   := TB_DIVIDEND_INTEGER_WIDTH;
    constant REMAINDER_FRACTIONAL_WIDTH      : integer   := TB_DIVIDEND_FRACTIONAL_WIDTH + TB_DIVISOR_INTEGER_WIDTH + TB_DIVISOR_FRACTIONAL_WIDTH - 1;

    signal s_dividend                        : sfixed(TB_DIVIDEND_INTEGER_WIDTH - 1 downto -TB_DIVIDEND_FRACTIONAL_WIDTH);
    signal s_divisor                         : sfixed(TB_DIVISOR_INTEGER_WIDTH - 1 downto -TB_DIVISOR_FRACTIONAL_WIDTH);
    signal m_quotient                        : sfixed(QUOTIENT_INTEGER_WIDTH - 1 downto -QUOTIENT_FRACTIONAL_WIDTH);
    signal m_remainder                       : sfixed(REMAINDER_INTEGER_WIDTH - 1 downto -REMAINDER_FRACTIONAL_WIDTH);
    signal m_quotient_real, m_remainder_real : real;

    constant ERROR_QUOTIENT_MAX              : real      := 2.0 ** (-(QUOTIENT_FRACTIONAL_WIDTH + 1));
    constant ERROR_REMAINDER_MAX             : real      := 2.0 ** (-(REMAINDER_FRACTIONAL_WIDTH + 1));
begin
    divider_ints : entity work.Divider
        port map(
            clk_i         => clk,
            reset_i       => reset,
            s_valid_i     => s_valid,
            s_ready_o     => s_ready,
            s_dividend_i  => s_dividend,
            s_divisor_i   => s_divisor,
            m_valid_o     => m_valid,
            m_ready_i     => m_ready,
            m_quotient_o  => m_quotient,
            m_remainder_o => m_remainder
        );

    clk <= not clk after TB_CLK_PERIOD / 2;
    reset <= '1', '0' after TB_CLK_PERIOD;

    p_master : process
        file csv : text open read_mode is "build/tb/DividerTestbench_in.csv";
        variable csv_line : line;
        variable dividend_real, divisor_real, quotient_real, remainder_real : real;
    begin
        while not endfile(csv) loop
            wait until rising_edge(clk) and reset = '0';

            readline(csv, csv_line);

            read(csv_line, dividend_real);
            read(csv_line, divisor_real);
            read(csv_line, quotient_real);
            read(csv_line, remainder_real);

            s_dividend <= to_sfixed(dividend_real, s_dividend);
            s_divisor  <= to_sfixed(divisor_real,  s_divisor);
            s_valid    <= '1';

            wait until rising_edge(clk) and s_ready = '1';

            m_quotient_real  <= quotient_real;
            m_remainder_real <= remainder_real;

            s_valid <= '0';
        end loop;

        terminate <= true;
        wait;
    end process p_master;

    p_slave : process
        variable success                                                          : natural := 0;
        variable quotient_err, remainder_err, quotient_err_max, remainder_err_max : real    := 0.0;
        variable count                                                            : natural := 0;
    begin
        wait until rising_edge(clk) and reset = '0';

        while not terminate loop
            wait until rising_edge(clk) and m_valid = '1';

            quotient_err := abs(to_real(m_quotient) - m_quotient_real);
            remainder_err := abs(to_real(m_remainder) - m_remainder_real);

            quotient_err_max := maximum(quotient_err_max, quotient_err);
            remainder_err_max := maximum(remainder_err_max, remainder_err);

            count := count + 1;

            if quotient_err <= ERROR_QUOTIENT_MAX and remainder_err <= ERROR_REMAINDER_MAX then
                success := success + 1;
            else
                report "Sortie incorrecte. dividend="    & real'image(to_real(s_dividend)) &
                                         " divisor="     & real'image(to_real(s_divisor)) &
                                         " quotient="    & real'image(to_real(m_quotient)) &
                                         " (attendu "    & to_string(m_quotient_real) &
                                         " erreur= "     & real'image(quotient_err) & ")" &
                                         " remainder="   & real'image(to_real(m_remainder)) &
                                         " (attendu "    & to_string(m_remainder_real) &
                                         " erreur= "     & real'image(remainder_err) & ")"
                    severity error;
            end if;

            m_ready <= '1';

            wait until rising_edge(clk);

            m_ready <= '0';
        end loop;

        report "Succès " & integer'image(success) & " / " & integer'image(count) &
            " ; Erreur max quotient= " & real'image(quotient_err_max) &
            " remainder=" & real'image(remainder_err_max);

        finish;
    end process p_slave;
end Simulation;
