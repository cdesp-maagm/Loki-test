
library ieee;
use ieee.std_logic_1164.all;

entity AD8370 is
    generic(
        CLK_FREQUENCY  : positive;
        SCLK_FREQUENCY : positive range 1 to 20e6;
        CHANNELS       : positive := 1;
        GAIN_WIDTH     : positive := 8
    );
    port(
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        s_gains_i   : in  std_logic_vector(GAIN_WIDTH * CHANNELS - 1 downto 0);
        m_sclk_o    : out std_logic;
        m_ltch_n_o  : out std_logic_vector(CHANNELS - 1 downto 0);
        m_sdata_o   : out std_logic
    );
end AD8370;

architecture RTL of AD8370 is
    subtype Gain_t is std_logic_vector(GAIN_WIDTH - 1 downto 0);
    type GainArray_t is array(0 to CHANNELS - 1) of Gain_t;
    signal gains          : GainArray_t;
    signal gains_reg      : GainArray_t := (others => (others => '0'));

    signal m_sclk_reg : std_logic := '0';
    signal busy_reg, done : boolean;

    signal channel_reg    : natural range 0 to CHANNELS - 1;

    constant TIMER_HALF   : integer := CLK_FREQUENCY / SCLK_FREQUENCY / 2 - 1;
    constant TIMER_MAX    : integer := CLK_FREQUENCY / SCLK_FREQUENCY - 1;
    signal timer_reg      : natural range 0 to TIMER_MAX;

    signal index_reg      : natural range 0 to GAIN_WIDTH - 1 := GAIN_WIDTH - 1;
begin
    -- Séparer le vecteur des gains en un tableau.
    gains_gen : for i in 0 to CHANNELS - 1 generate
        gains(i) <= s_gains_i((i + 1) * GAIN_WIDTH - 1 downto i * GAIN_WIDTH);
    end generate;

    -- Déterminer le numéro de la prochaine voie à traiter.
    p_busy_channel_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or done then
                busy_reg    <= false;
                m_ltch_n_o  <= (others => '1');
            elsif not busy_reg then
                for i in 0 to CHANNELS - 1 loop
                    if gains(i) /= gains_reg(i) then
                        gains_reg(i)  <= gains(i);
                        channel_reg   <= i;
                        busy_reg      <= true;
                        m_ltch_n_o(i) <= '0';
                        exit;
                    end if;
                end loop;
            end if;
        end if;
    end process p_busy_channel_reg;

    done <= timer_reg = TIMER_MAX and index_reg = 0;

    p_timer_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or timer_reg = TIMER_MAX then
                timer_reg <= 0;
            elsif busy_reg then
                timer_reg <= timer_reg + 1;
            end if;
        end if;
    end process p_timer_reg;

    p_index_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or done then
                index_reg <= GAIN_WIDTH - 1;
            elsif timer_reg = TIMER_MAX then
                index_reg <= index_reg - 1;
            end if;
        end if;
    end process p_index_reg;

    p_m_sclk_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                m_sclk_reg <= '0';
            elsif timer_reg = TIMER_MAX or timer_reg = TIMER_HALF then
                m_sclk_reg <= not m_sclk_reg;
            end if;
        end if;
    end process p_m_sclk_o;

    m_sclk_o  <= m_sclk_reg;
    m_sdata_o <= gains_reg(channel_reg)(index_reg);
end RTL;
