
library ieee;
use ieee.std_logic_1164.all;

entity StreamController is
    port(
        -- L'horloge globale du système.
        clk_i     : in  std_logic;
        -- La commande de réinitialisation.
        reset_i   : in  std_logic;
        -- Interface esclave, indicateur de donnée valide en entrée.
        s_valid_i : in  std_logic_vector;
        -- Interface esclave, acquittement de la donnée en entrée.
        s_ready_o : out std_logic;
        -- Interface maître, indicateur de donnée valide en sortie.
        m_valid_o : out std_logic;
        -- Interface maître, acquittement de la donnée en sortie.
        m_ready_i : in  std_logic
    );
end StreamController;

architecture RTL of StreamController is
    signal s_valid, s_ready, m_valid_reg : std_logic;
begin
    -- La transaction côté esclave est valide lorsque tous les bus maîtres sont valides.
    s_valid <= and(s_valid_i);

    -- La fin de transaction côté esclave a lieu dans l'une de situations suivantes :
    -- 1. Donnée valide en entrée et pas de transfert en cours en sortie.
    -- 2. Donnée valide en entrée et fin de transfert en sortie.
    s_ready <= (s_valid and not m_valid_reg) or
               (s_valid and m_valid_reg and m_ready_i);

    p_m_valid_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                m_valid_reg <= '0';
            elsif s_ready = '1' then
                m_valid_reg <= '1';
            elsif m_ready_i = '1' then
                m_valid_reg <= '0';
            end if;
        end if;
    end process p_m_valid_reg;

    s_ready_o <= s_ready;
    m_valid_o <= m_valid_reg;
end RTL;
