
library ieee;
use ieee.std_logic_1164.all;
use work.fixed_pkg.all;

use work.CORDIC_pkg.all;

architecture Simulation of CORDIC is
begin
    process
        -- Le nombre d'itérations dépend du nombre de bits de la partie
        -- fractionnaire de l'angle.
        constant INDEX_MAX : positive := minimum(CORDIC_ANGLES'high, -s_angle_i'right);
        constant ITERATIONS : positive := INDEX_MAX + 1;

        -- La matrice de rotation sans facteur d'échelle a un gain total
        -- d'environ 1.64. Les coordonnées du vecteur tournant seront comprises
        -- entre -1.64 et 1.64.
        variable cos_reg, x_next, delta_x : sfixed(1 downto m_cos_o'right - INDEX_MAX);
        variable sin_reg, y_next, delta_y : sfixed(1 downto m_sin_o'right - INDEX_MAX);

        variable angle_reg : Angle_t;
    begin
        -- IDLE
        s_ready_o <= '0';
        m_valid_o <= '0';

        wait until rising_edge(clk_i) and s_valid_i = '1' and reset_i = '0';

        -- IDLE --> BUSY
        s_ready_o <= '1';

        -- Si l'angle est supérieur à pi/2 en valeur absolue, effectuer une
        -- symétrie par rapport à l'origine du repère.
        if s_angle_i > CORDIC_PI_OVER_2 then
            cos_reg   := resize(-CORDIC_SCALING, cos_reg);
            angle_reg := resize(s_angle_i - CORDIC_PI, angle_reg);
        elsif s_angle_i < -CORDIC_PI_OVER_2 then
            cos_reg   := resize(-CORDIC_SCALING, cos_reg);
            angle_reg := resize(s_angle_i + CORDIC_PI, angle_reg);
        else
            cos_reg   := resize(CORDIC_SCALING, cos_reg);
            angle_reg := resize(s_angle_i, angle_reg);
        end if;
        sin_reg := to_sfixed(0, sin_reg);

        -- BUSY
        for index_reg in 0 to INDEX_MAX loop
            if index_reg mod ROTATIONS_PER_CYCLE = 0 then
                wait until rising_edge(clk_i);
            end if;

            s_ready_o <= '0';

            -- Effectuer une rotation du vecteur courant avec l'angle
            -- de référence CORDIC_ANGLES(index_reg).
            -- Multiplier par la tangente de cet angle revient à décaler
            -- vers la droite de index_reg bits.
            delta_x := sin_reg sra index_reg;
            delta_y := cos_reg sra index_reg;

            -- Choisir le sens de rotation en fonction du signe de l'angle restant.
            if is_positive_or_zero(angle_reg) then
                -- Angle positif => tourner dans le sens positif.
                -- Diminuer l'angle restant.
                x_next    := cos_reg - delta_x;
                y_next    := sin_reg + delta_y;
                angle_reg := angle_reg - CORDIC_ANGLES(index_reg);
            else
                -- Angle négatif => tourner dans le sens négatif.
                -- Augmenter l'angle restant.
                x_next    := cos_reg + delta_x;
                y_next    := sin_reg - delta_y;
                angle_reg := angle_reg + CORDIC_ANGLES(index_reg);
            end if;

            cos_reg := x_next;
            sin_reg := y_next;
        end loop;

        wait until rising_edge(clk_i);

        -- DONE
        m_cos_o <= resize(cos_reg, m_cos_o'left, m_cos_o'right);
        m_sin_o <= resize(sin_reg, m_sin_o'left, m_sin_o'right);
        m_valid_o <= '1';

        wait until rising_edge(clk_i) and m_ready_i = '1';
    end process;
end Simulation;
