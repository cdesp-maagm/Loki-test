
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;

architecture RTL of Oscillator is
    signal osc_reg, osc_reg1        : natural range 0 to CHANNELS - 1;
    signal lut_cos_reg, lut_sin_reg : SinCos_t;
    signal index_reg                : integer_vector(0 to CHANNELS - 1) := (others => 0);
    signal cos_neg_reg, sin_neg_reg : boolean_vector(0 to CHANNELS - 1);

    type State_t is (IDLE, BUSY, DONE);
    signal state_reg                : State_t;
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
                        if restart_i = '1' then
                            state_reg <= BUSY;
                        end if;
                    when BUSY =>
                        if osc_reg1 = m_cos_o'high then
                            state_reg <= DONE;
                        end if;
                    when DONE =>
                        if m_ready_i = '1' then
                            state_reg <= BUSY;
                        end if;
                end case;
            end if;
        end if;
    end process p_state_reg;

    p_osc_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            osc_reg1 <= osc_reg;
            case state_reg is
                when IDLE | DONE =>
                    osc_reg <= 0;
                    osc_reg1 <= 0;
                when BUSY =>
                    if osc_reg < m_cos_o'high then
                        osc_reg <= osc_reg + 1;
                    end if;
            end case;
        end if;
    end process p_osc_reg;

    p_index_sin_neg_cos_neg_reg : process(clk_i)
        variable index_next : integer range -LOOKUP_TABLE'high to 2 * LOOKUP_TABLE'high;
    begin
        if rising_edge(clk_i) then
            if restart_i = '1' then
                for i in 0 to CHANNELS - 1 loop
                    if delays_i(i) <= LOOKUP_TABLE'high then
                        index_reg(i)   <= delays_i(i);
                        cos_neg_reg(i) <= false;
                        sin_neg_reg(i) <= true;
                    elsif delays_i(i) <= 2 * LOOKUP_TABLE'high then
                        index_reg(i)   <= 2 * LOOKUP_TABLE'high - delays_i(i);
                        cos_neg_reg(i) <= true;
                        sin_neg_reg(i) <= true;
                    elsif delays_i(i) <= 3 * LOOKUP_TABLE'high then
                        index_reg(i)   <= delays_i(i) - 2 * LOOKUP_TABLE'high;
                        cos_neg_reg(i) <= true;
                        sin_neg_reg(i) <= false;
                    else
                        index_reg(i)   <= 4 * LOOKUP_TABLE'high - delays_i(i);
                        cos_neg_reg(i) <= false;
                        sin_neg_reg(i) <= false;
                    end if;
                end loop;
            elsif m_ready_i = '1' then
                for i in 0 to CHANNELS - 1 loop
                    if cos_neg_reg(i) xor sin_neg_reg(i) then
                        index_next := index_reg(i) - steps_i(i);
                    else
                        index_next := index_reg(i) + steps_i(i);
                    end if;

                    if index_next < 0 then
                        index_reg(i)   <= -index_next;
                        sin_neg_reg(i) <= not sin_neg_reg(i);
                    elsif index_next > LOOKUP_TABLE'high then
                        index_reg(i)   <= 2 * LOOKUP_TABLE'high - index_next;
                        cos_neg_reg(i) <= not cos_neg_reg(i);
                    else
                        index_reg(i) <= index_next;
                    end if;
                end loop;
            end if;
        end if;
    end process p_index_sin_neg_cos_neg_reg;

    p_lut_sin_cos_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            lut_sin_reg <= LOOKUP_TABLE(index_reg(osc_reg));
            lut_cos_reg <= LOOKUP_TABLE(LOOKUP_TABLE'high - index_reg(osc_reg));
        end if;
    end process p_lut_sin_cos_reg;

    p_cos_sin_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if state_reg = BUSY then
                if sin_neg_reg(osc_reg1) then
                    m_sin_o(osc_reg1) <= resize(-lut_sin_reg, SinCos_t'left, SinCos_t'right);
                else
                    m_sin_o(osc_reg1) <= resize(lut_sin_reg, SinCos_t'left, SinCos_t'right);
                end if;

                if cos_neg_reg(osc_reg1) then
                    m_cos_o(osc_reg1) <= resize(-lut_cos_reg, SinCos_t'left, SinCos_t'right);
                else
                    m_cos_o(osc_reg1) <= resize(lut_cos_reg, SinCos_t'left, SinCos_t'right);
                end if;
            end if;
        end if;
    end process p_cos_sin_o;

    m_valid_o <= '1' when state_reg = DONE else '0';
end RTL;
