
library ieee;
use ieee.std_logic_1164.all;
use work.fixed_pkg.all;

use work.CORDIC_pkg.all;

architecture RTL of CORDIC is
    -- Le nombre d'itérations dépend du nombre de bits de la partie
    -- fractionnaire de l'angle.
    constant INDEX_MAX : positive := minimum(CORDIC_ANGLES'high, -s_angle_i'right);
    constant INDEX_DONE : positive := INDEX_MAX - INDEX_MAX mod ROTATIONS_PER_CYCLE;
    signal index_reg : integer range 0 to INDEX_MAX;

    -- La matrice de rotation sans facteur d'échelle a un gain total
    -- d'environ 1.64. Les coordonnées du vecteur tournant seront comprises
    -- entre -1.64 et 1.64.
    signal cos_reg : sfixed(1 downto m_cos_o'right - INDEX_MAX);
    signal sin_reg : sfixed(1 downto m_sin_o'right - INDEX_MAX);

    signal angle_reg : Angle_t;

    type State_t is (IDLE, BUSY, DONE);
    signal state_reg : State_t;
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
        variable delta_x    : sfixed(cos_reg'range);
        variable delta_y    : sfixed(sin_reg'range);
        variable index_next : integer range 0 to INDEX_MAX;
        variable angle_next : Angle_t;
        variable cos_next   : sfixed(cos_reg'range);
        variable sin_next   : sfixed(sin_reg'range);
    begin
        if rising_edge(clk_i) then
            case state_reg is
                when IDLE =>
                    if s_valid_i = '1' then
                        -- Lire l'angle initial. S'il est supérieur à pi/2 en
                        -- valeur absolue, effectuer une symétrie par rapport à
                        -- à l'origine du repère.
                        if s_angle_i > CORDIC_PI_OVER_2 then
                            cos_reg   <= resize(-CORDIC_SCALING, cos_reg);
                            angle_reg <= resize(s_angle_i - CORDIC_PI, angle_reg);
                        elsif s_angle_i < -CORDIC_PI_OVER_2 then
                            cos_reg   <= resize(-CORDIC_SCALING, cos_reg);
                            angle_reg <= resize(s_angle_i + CORDIC_PI, angle_reg);
                        else
                            cos_reg   <= resize(CORDIC_SCALING, cos_reg);
                            angle_reg <= resize(s_angle_i, angle_reg);
                        end if;
                        sin_reg <= to_sfixed(0, sin_reg);
                        index_reg <= 0;
                    end if;

                when BUSY =>
                    index_next := index_reg;
                    cos_next   := cos_reg;
                    sin_next   := sin_reg;
                    angle_next := angle_reg;

                    for i in 1 to ROTATIONS_PER_CYCLE loop
                        -- Effectuer une rotation du vecteur courant avec l'angle
                        -- de référence CORDIC_ANGLES(index_next).
                        -- Multiplier par la tangente de cet angle revient à décaler
                        -- vers la droite de index_next bits.
                        delta_x := sin_next sra index_next;
                        delta_y := cos_next sra index_next;

                        angle_ref := CORDIC_ANGLES(index_next);

                        -- Choisir le sens de rotation en fonction du signe de l'angle restant.
                        if is_positive_or_zero(angle_next) then
                            -- Angle positif => tourner dans le sens positif.
                            -- Diminuer l'angle restant.
                            cos_next   := cos_next   - delta_x;
                            sin_next   := sin_next   + delta_y;
                            angle_next := angle_next - angle_ref;
                        else
                            -- Angle négatif => tourner dans le sens négatif.
                            -- Augmenter l'angle restant.
                            cos_next   := cos_next   + delta_x;
                            sin_next   := sin_next   - delta_y;
                            angle_next := angle_next + angle_ref;
                        end if;

                        exit when index_next = INDEX_MAX;
                        index_next := index_next + 1;
                    end loop;

                    index_reg <= index_next;
                    cos_reg   <= cos_next;
                    sin_reg   <= sin_next;
                    angle_reg <= angle_next;

                when others =>
            end case;
        end if;
    end process p_x_y_angle_reg;

    -- -------------------------------------------------------------------------
    -- Gestion des sorties.
    -- -------------------------------------------------------------------------

    p_m_x_y_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                m_cos_o <= to_sfixed(1, m_cos_o'left, m_cos_o'right);
                m_sin_o <= to_sfixed(0, m_sin_o'left, m_sin_o'right);
            elsif state_reg = DONE then
                m_cos_o <= resize(cos_reg, m_cos_o'left, m_cos_o'right);
                m_sin_o <= resize(sin_reg, m_sin_o'left, m_sin_o'right);
            end if;
        end if;
    end process p_m_x_y_o;

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
end RTL;
