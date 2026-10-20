
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.CORDICAngle_pkg.all;

architecture RTL of CORDICAngle is
    type State_t is (IDLE, BUSY, DONE);

    -- Le nombre d'itérations dépend du nombre de bits de la partie
    -- fractionnaire de l'angle.
    constant INDEX_MAX  : positive := minimum(CORDIC_ANGLES'high, -m_angle_o'right);
    constant INDEX_DONE : positive := INDEX_MAX - INDEX_MAX mod ROTATIONS_PER_CYCLE;
    signal index_reg    : integer range 0 to INDEX_MAX;

    signal x_reg        : sfixed(s_x_i'left + 2 downto s_x_i'right - INDEX_MAX);
    signal y_reg        : sfixed(s_y_i'left + 2 downto s_y_i'right - INDEX_MAX);

    signal angle_reg    : Angle_t;

    signal state_reg    : State_t;
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
                        if index_reg = INDEX_DONE then
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

    -- -------------------------------------------------------------------------
    -- Effectuer les rotations successives.
    -- -------------------------------------------------------------------------

    p_x_y_angle_reg : process(clk_i)
        variable angle_ref  : RefAngle_t;
        variable delta_x    : sfixed(x_reg'range);
        variable delta_y    : sfixed(y_reg'range);
        variable index_next : integer range 0 to INDEX_MAX;
        variable angle_next : Angle_t;
        variable x_next     : sfixed(x_reg'range);
        variable y_next     : sfixed(x_reg'range);
    begin
        if rising_edge(clk_i) then
            case state_reg is
                when IDLE =>
                    if s_valid_i = '1' then
                        -- Lire les coordonnées initiales et remettre à zéro
                        -- l'angle calculé.
                        -- Si X est négatif, effectuer une
                        -- symétrie par rapport à l'origine du repère.
                        if is_positive_or_zero(s_x_i) then
                            x_reg     <= resize(s_x_i, x_reg);
                            y_reg     <= resize(s_y_i, y_reg);
                            angle_reg <= to_sfixed(0, angle_reg);
                        else
                            x_reg <= resize(-s_x_i, x_reg);
                            y_reg <= resize(-s_y_i, y_reg);
                            if is_negative(s_y_i) then
                                angle_reg <= -CORDIC_PI;
                            else
                                angle_reg <= CORDIC_PI;
                            end if;
                        end if;
                        index_reg <= 0;
                    end if;

                when BUSY =>
                    index_next := index_reg;
                    x_next     := x_reg;
                    y_next     := y_reg;
                    angle_next := angle_reg;

                    for i in 1 to ROTATIONS_PER_CYCLE loop
                        -- Effectuer une rotation du vecteur courant avec l'angle
                        -- de référence CORDIC_ANGLES(index_next).
                        -- Multiplier par la tangente de cet angle revient à décaler
                        -- vers la droite de index_next bits.
                        delta_x := y_next sra index_next;
                        delta_y := x_next sra index_next;

                        angle_ref := CORDIC_ANGLES(index_next);

                        -- Selon le signe de Y, appliquer la rotation
                        -- de manière à s'approcher de l'axe horizontal.
                        -- Mettre à jour l'angle total.
                        if is_positive_or_zero(y_next) then
                            -- Y positif => tourner dans le sens négatif.
                            -- L'angle de référence compte positivement dans le total.
                            x_next     := x_next + delta_x;
                            y_next     := y_next - delta_y;
                            angle_next := angle_next + CORDIC_ANGLES(index_next);
                        else
                            -- Y négatif => tourner dans le sens positif.
                            -- L'angle de référence compte négativement dans le total.
                            x_next     := x_next - delta_x;
                            y_next     := y_next + delta_y;
                            angle_next := angle_next - CORDIC_ANGLES(index_next);
                        end if;

                        exit when index_next = INDEX_MAX;
                        index_next := index_next + 1;
                    end loop;

                    index_reg <= index_next;
                    x_reg     <= x_next;
                    y_reg     <= y_next;
                    angle_reg <= angle_next;

                when others =>
            end case;
        end if;
    end process p_x_y_angle_reg;

    -- -------------------------------------------------------------------------
    -- Gestion des sorties.
    -- -------------------------------------------------------------------------

    p_m_angle_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if state_reg = DONE then
                m_angle_o <= resize(angle_reg, m_angle_o'left, m_angle_o'right);
            end if;
        end if;
    end process p_m_angle_o;

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

    s_ready_o <= s_valid_i when state_reg = IDLE else '0';
end RTL;
