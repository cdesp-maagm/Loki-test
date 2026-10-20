
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.Oscillator_pkg.all;

architecture Simulation of Oscillator is
begin
    process
        variable lut_cos, lut_sin         : SinCos_t;
        variable index_reg                : integer_vector(0 to CHANNELS - 1);
        variable index_next               : integer range -LOOKUP_TABLE'high to 2 * LOOKUP_TABLE'high;
        variable cos_neg_reg, sin_neg_reg : boolean_vector(0 to CHANNELS - 1);
    begin
        wait until rising_edge(clk_i);

        if restart_i = '1' then
            for i in 0 to CHANNELS - 1 loop
                assert delays_i(i) <= 4 * LOOKUP_TABLE'high
                    report "Valeur incorrecte pour delays_i"
                    severity error;
                if delays_i(i) <= LOOKUP_TABLE'high then
                    index_reg(i)   := delays_i(i);
                    cos_neg_reg(i) := false;
                    sin_neg_reg(i) := true;
                elsif delays_i(i) <= 2 * LOOKUP_TABLE'high then
                    index_reg(i)   := 2 * LOOKUP_TABLE'high - delays_i(i);
                    cos_neg_reg(i) := true;
                    sin_neg_reg(i) := true;
                elsif delays_i(i) <= 3 * LOOKUP_TABLE'high then
                    index_reg(i)   := delays_i(i) - 2 * LOOKUP_TABLE'high;
                    cos_neg_reg(i) := true;
                    sin_neg_reg(i) := false;
                else
                    index_reg(i)   := 4 * LOOKUP_TABLE'high - delays_i(i);
                    cos_neg_reg(i) := false;
                    sin_neg_reg(i) := false;
                end if;
            end loop;
        elsif m_ready_i = '1' then
            for i in 0 to CHANNELS - 1 loop
                assert steps_i(i) <= LOOKUP_TABLE'high
                    report "Valeur incorrecte pour steps_i"
                    severity error;

                if cos_neg_reg(i) xor sin_neg_reg(i) then
                    index_next := index_reg(i) - steps_i(i);
                else
                    index_next := index_reg(i) + steps_i(i);
                end if;

                if index_next < 0 then
                    index_reg(i)   := -index_next;
                    sin_neg_reg(i) := not sin_neg_reg(i);
                elsif index_next > LOOKUP_TABLE'high then
                    index_reg(i)   := 2 * LOOKUP_TABLE'high - index_next;
                    cos_neg_reg(i) := not cos_neg_reg(i);
                else
                    index_reg(i)   := index_next;
                end if;
            end loop;
        end if;

        if restart_i = '1' or m_ready_i = '1' then
            m_valid_o <= '0';

            for i in 0 to CHANNELS - 1 loop
                wait until rising_edge(clk_i);

                lut_sin := LOOKUP_TABLE(index_reg(i));
                lut_cos := LOOKUP_TABLE(LOOKUP_TABLE'high - index_reg(i));

                if sin_neg_reg(i) then
                    m_sin_o(i) <= resize(-lut_sin, SinCos_t'left, SinCos_t'right);
                else
                    m_sin_o(i) <= resize(lut_sin, SinCos_t'left, SinCos_t'right);
                end if;

                if cos_neg_reg(i) then
                    m_cos_o(i) <= resize(-lut_cos, SinCos_t'left, SinCos_t'right);
                else
                    m_cos_o(i) <= resize(lut_cos, SinCos_t'left, SinCos_t'right);
                end if;
            end loop;

            m_valid_o <= '1';
        end if;
    end process;
end Simulation;
