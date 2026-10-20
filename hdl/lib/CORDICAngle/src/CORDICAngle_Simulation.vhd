
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.CORDICAngle_pkg.all;

architecture Simulation of CORDICAngle is
begin
    process
        -- Le nombre d'itérations dépend du nombre de bits de la partie
        -- fractionnaire de l'angle.
        constant INDEX_MAX              : positive := minimum(CORDIC_ANGLES'high, -m_angle_o'right);
        constant ITERATIONS             : positive := INDEX_MAX + 1;

        variable x_reg, x_next, delta_x : sfixed(s_x_i'left + 2 downto s_x_i'right - INDEX_MAX);
        variable y_reg, y_next, delta_y : sfixed(s_y_i'left + 2 downto s_y_i'right - INDEX_MAX);

        variable angle_reg              : Angle_t;
        variable mirror_reg             : boolean;
    begin
        -- IDLE
        s_ready_o <= '0';
        m_valid_o <= '0';

        wait until rising_edge(clk_i) and s_valid_i = '1';

        -- IDLE --> BUSY
        s_ready_o <= '1';

        -- Lire les coordonnées initiales et remettre à zéro l'angle calculé.
        x_reg     := resize(s_x_i, x_reg);
        y_reg     := resize(s_y_i, y_reg);
        angle_reg := to_sfixed(0, angle_reg);

        -- Si X est négatif, effectuer une
        -- symétrie par rapport à l'origine.
        if is_negative(s_x_i) then
            x_reg := resize(-s_x_i, x_reg);
            y_reg := resize(-s_y_i, x_reg);
            if is_negative(s_y_i) then
                angle_reg := -CORDIC_PI;
            else
                angle_reg := CORDIC_PI;
            end if;
        end if;

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
            delta_x := y_reg sra index_reg;
            delta_y := x_reg sra index_reg;

            -- Selon le signe de Y, appliquer la rotation
            -- de manière à s'approcher de l'axe horizontal.
            -- Mettre à jour l'angle total.
            if is_positive_or_zero(y_reg) then
                -- Y positif => tourner dans le sens négatif.
                -- L'angle de référence compte positivement dans le total.
                x_next    := x_reg + delta_x;
                y_next    := y_reg - delta_y;
                angle_reg := angle_reg + CORDIC_ANGLES(index_reg);
            else
                -- Y négatif => tourner dans le sens positif.
                -- L'angle de référence compte négativement dans le total.
                x_next    := x_reg - delta_x;
                y_next    := y_reg + delta_y;
                angle_reg := angle_reg - CORDIC_ANGLES(index_reg);
            end if;

            x_reg := x_next;
            y_reg := y_next;
        end loop;

        wait until rising_edge(clk_i);

        -- DONE
        m_angle_o <= resize(angle_reg, m_angle_o'left, m_angle_o'right);
        m_valid_o <= '1';

        wait until rising_edge(clk_i) and m_ready_i = '1';
    end process;
end Simulation;
