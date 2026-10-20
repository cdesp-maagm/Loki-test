
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

architecture Slow of Divider is
    signal dividend_neg_reg, divisor_neg_reg : boolean;
    signal divisor_reg                       : sfixed(s_dividend_i'left + s_divisor_i'length - 2 downto s_dividend_i'right - s_divisor_i'length + 1);
    signal quotient_reg                      : sfixed(s_dividend_i'left - s_divisor_i'right downto s_dividend_i'right - s_divisor_i'left);
    signal remainder_reg                     : sfixed(s_dividend_i'left downto divisor_reg'right);

    constant INDEX_MAX                       : integer := quotient_reg'length - 2;
    signal index_reg                         : integer range 0 to INDEX_MAX;

    type State_t is (IDLE, BUSY, DONE);
    signal state_reg                         : State_t;
begin
    -- -------------------------------------------------------------------------
    -- Gérer l'état du calcul et l'indice de l'itération courante.
    -- -------------------------------------------------------------------------

    p_state_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_reg <= IDLE;
            else
                case state_reg is
                    when IDLE =>
                        if s_valid_i = '1' then
                            state_reg <= BUSY;
                        end if;
                    when BUSY =>
                        if index_reg = INDEX_MAX then
                            state_reg <= DONE;
                        end if;
                    when DONE =>
                        if m_ready_i = '1' then
                            state_reg <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process p_state_reg;

    p_index_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if state_reg = BUSY and index_reg /= INDEX_MAX then
                index_reg <= index_reg + 1;
            else
                index_reg <= 0;
            end if;
        end if;
    end process p_index_reg;


    -- -------------------------------------------------------------------------
    -- Effectuer le calcul de la division bit par bit.
    -- -------------------------------------------------------------------------

    p_quotient_remainder_divisor_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            case state_reg is
                when IDLE =>
                    if s_valid_i = '1' then
                        quotient_reg <= (others => '0');

                        -- La valeur initiale du reste est la valeur absolue du dividende.
                        remainder_reg    <= resize(abs s_dividend_i, remainder_reg);
                        dividend_neg_reg <= is_negative(s_dividend_i);
                        divisor_neg_reg  <= is_negative(s_divisor_i);

                        -- Copier la valeur absolue du diviseur dans divisor_reg, alignée à gauche.
                        divisor_reg <= (others => '0');
                        divisor_reg(divisor_reg'left downto divisor_reg'left - s_divisor_i'length + 1) <= abs s_divisor_i;
                    end if;

                when BUSY =>
                    quotient_reg(quotient_reg'left downto quotient_reg'right + 1) <= quotient_reg(quotient_reg'left - 1 downto quotient_reg'right);
                    if remainder_reg >= divisor_reg then
                        quotient_reg(quotient_reg'right) <= '1';
                        remainder_reg <= resize(remainder_reg - divisor_reg, remainder_reg);
                    else
                        quotient_reg(quotient_reg'right) <= '0';
                    end if;
                    divisor_reg <= divisor_reg srl 1;

                when others =>
            end case;
        end if;
    end process p_quotient_remainder_divisor_reg;

    -- -------------------------------------------------------------------------
    -- Gestion des sorties.
    -- -------------------------------------------------------------------------

    p_quotient_remainder_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if state_reg = DONE then
                if dividend_neg_reg xor divisor_neg_reg then
                    m_quotient_o <= resize(-quotient_reg, m_quotient_o'left, m_quotient_o'right);
                else
                    m_quotient_o <= resize(quotient_reg, m_quotient_o'left, m_quotient_o'right);
                end if;

                if dividend_neg_reg then
                    m_remainder_o <= resize(-remainder_reg, m_remainder_o'left, m_remainder_o'right);
                else
                    m_remainder_o <= resize(remainder_reg, m_remainder_o'left, m_remainder_o'right);
                end if;
            end if;
        end if;
    end process p_quotient_remainder_o;

    p_m_valid_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            case state_reg is
                when IDLE | BUSY =>
                    m_valid_o <= '0';
                when DONE =>
                    m_valid_o <= not m_ready_i;
            end case;
        end if;
    end process p_m_valid_o;

    s_ready_o <= s_valid_i and not reset_i when state_reg = IDLE else '0';
end Slow;
