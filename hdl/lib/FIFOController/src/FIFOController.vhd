
library ieee;
use ieee.std_logic_1164.all;

entity FIFOController is
    generic(
        LENGTH : positive
    );
    port(
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        s_valid_i    : in  std_logic;
        s_ready_o    : out std_logic;
        m_valid_o    : out std_logic;
        m_ready_i    : in  std_logic;
        read_index_o : out natural range 0 to LENGTH
    );
end FIFOController;

architecture RTL of FIFOController is
    signal s_ready, m_valid : std_logic;
    signal reading          : std_logic;
    signal read_index_reg   : natural range 0 to LENGTH;
begin
    -- La sortie est valide quand la FIFO est non vide ou quand
    -- une valeur est disponible en entrée.
    m_valid   <= '1' when read_index_reg > 0 else s_valid_i;
    m_valid_o <= m_valid;

    reading   <= m_valid and m_ready_i;

    -- Acquitter l'entrée quand la FIFO n'est pas pleine
    -- ou quand une lecture a lieu simultanément.
    s_ready   <= s_valid_i when read_index_reg < LENGTH else
                 s_valid_i and reading;
    s_ready_o <= s_ready;

    -- L'indice 0 indique que la FIFO est vide et que la donnée d'entrée
    -- doit être directement copiée sur la sortie en cas d'écriture et de
    -- lecture simultanées.
    -- Incrémenter l'indice si une écriture a lieu, mais pas de lecture.
    -- Décrémenter l'indice si une lecture a lieu, mais pas d'écriture.
    p_count_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                read_index_reg <= 0;
            elsif s_ready = '1' and reading = '0' then
                read_index_reg <= read_index_reg + 1;
            elsif s_ready = '0' and reading = '1' then
                read_index_reg <= read_index_reg - 1;
            end if;
        end if;
    end process p_count_reg;

    read_index_o <= read_index_reg;
end RTL;
