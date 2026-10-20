
library ieee;
use ieee.std_logic_1164.all;

--
-- Fréquence d'échantillonnage
--
-- L'intervalle de temps entre deux conversions est déterminé par :
-- * la durée typique de l'impulsion sur le signal CNV : 30 ns
-- * la durée de la communication : Nbits / Fsck
--
-- Les valeurs ci-dessous sont données pour Nbits = 16.
--
-- La conversion proprement dite dure 170 ns max mais s'effectue en
-- parallèle avec la communication série.
-- On peut redémarrer une conversion immédiatement après le dernier front
-- montant de adc_m_sclk_o. Cependant, dans les tableaux ci-dessous, on
-- suppose que CNV remonte au dernier front descendant.
--
-- Fsck (MHz) | Fsmax (MHz)
-- -----------|------------
--  100       | 5,26
--   50       | 2,85
--   25       | 1,49
--   20       | 1,20
--   12,5     | 0,763
--   10       | 0,613
--
-- Fréquence d'horloge série
--
-- Si on souhaite éviter l'utilisation de plusieurs domaines d'horloge, on
-- désactivera l'horloge série CLKOUT de l'ADC. On échantillonnera les données
-- aux moments où se produisent les fronts montants de adc_m_sclk_o.
--
-- En mode "single data rate", après chaque front descendant de adc_m_sclk_o,
-- les données série sont valides au bout d'une durée max de 4,5 ns.
-- La fréquence d'horloge série doit donc être nettement inférieure à 100 MHz
-- (5 ns entre les fronts de adc_m_sclk_o) pour respecter le temps de prépositionnement
-- des données avant leur mémorisation.
--
-- Avec une fréquence Fsck de 50 MHz, la donnée est stable au moins 5,5 ns avant
-- le front montant de adc_m_sclk_o.
--
-- TODO Ajouter une contrainte de temps dans le fichier XDC entre adc_m_sclk_o
--      et adc_m_sdata_i.

use work.LTC2325_pkg.all;

entity LTC2325 is
    generic(
        CHANNELS          : positive;
        CLK_FREQUENCY     : positive;
        ADC_CLK_FREQUENCY : positive range 1 to 50e6
    );
    port(
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;

        adc_m_convert_n_o : out std_logic;
        adc_m_sclk_o      : out std_logic;
        adc_m_sdata_i     : in  std_logic_vector(CHANNELS - 1 downto 0);

        m_data_o          : out LTC2325DataArray_t(0 to CHANNELS - 1);
        m_valid_o         : out std_logic;
        m_ready_i         : in  std_logic
    );
end LTC2325;

architecture RTL of LTC2325 is
    type State_t is (ACQUIRE, CONVERT, VALID);
    signal state_reg         : State_t;

    signal adc_m_sclk_reg    : std_logic := '0';
    signal done              : boolean;

    -- La durée typique de l'impulsion sur la sortie convert_n est 30 ns.
    -- La durée maximum de conversion est 170 ns.
    -- Ici, on arrondit le résultat à l'entier inférieur pour déterminer
    -- la valeur maximale du compteur timer_reg.
    constant PULSE_TIMER_MAX : positive := CLK_FREQUENCY * 3 / 1e8;
    constant BIT_TIMER_HALF  : natural := CLK_FREQUENCY / ADC_CLK_FREQUENCY / 2- 1;
    constant BIT_TIMER_MAX   : natural := CLK_FREQUENCY / ADC_CLK_FREQUENCY - 1;
    signal timer_reg         : natural range 0 to maximum(PULSE_TIMER_MAX, BIT_TIMER_MAX);
    signal index_reg         : natural range 0 to LTC2325_DATA_WIDTH - 1;

    signal m_data_reg        : LTC2325DataArray_t(0 to CHANNELS - 1);
begin
    p_state_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_reg <= ACQUIRE;
            else
                case state_reg is
                    when ACQUIRE =>
                        if timer_reg = PULSE_TIMER_MAX then
                            state_reg <= CONVERT;
                        end if;
                    when CONVERT =>
                        if done then
                            state_reg <= VALID;
                        end if;
                    when VALID =>
                        if m_ready_i = '1' then
                            state_reg <= ACQUIRE;
                        end if;
                end case;
            end if;
        end if;
    end process p_state_reg;

    done <= timer_reg = BIT_TIMER_MAX and index_reg = LTC2325_DATA_WIDTH - 1;

    adc_m_convert_n_o <= '1' when state_reg = ACQUIRE else '0';

    p_timer_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                timer_reg <= 0;
            else
                case state_reg is
                    when ACQUIRE =>
                        if timer_reg = PULSE_TIMER_MAX then
                            timer_reg <= 0;
                        else
                            timer_reg <= timer_reg + 1;
                        end if;
                    when CONVERT =>
                        if timer_reg = BIT_TIMER_MAX then
                            timer_reg <= 0;
                        else
                            timer_reg <= timer_reg + 1;
                        end if;
                    when others =>
                end case;
            end if;
        end if;
    end process p_timer_reg;

    p_index_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                index_reg <= 0;
            elsif state_reg = CONVERT and timer_reg = BIT_TIMER_MAX then
                if index_reg = LTC2325_DATA_WIDTH - 1 then
                    index_reg <= 0;
                else
                    index_reg <= index_reg + 1;
                end if;
            end if;
        end if;
    end process p_index_reg;

    p_adc_m_sclk_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or state_reg /= CONVERT then
                adc_m_sclk_reg <= '0';
            elsif timer_reg = BIT_TIMER_HALF or timer_reg = BIT_TIMER_MAX then
                adc_m_sclk_reg <= not adc_m_sclk_reg;
            end if;
        end if;
    end process p_adc_m_sclk_reg;

    adc_m_sclk_o <= adc_m_sclk_reg;

    p_data_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if state_reg = CONVERT and timer_reg = BIT_TIMER_HALF then
                for c in 0 to CHANNELS - 1 loop
                    m_data_reg(c) <= m_data_reg(c)(LTC2325_DATA_WIDTH - 2 downto 0) & adc_m_sdata_i(c);
                end loop;
            end if;
        end if;
    end process p_data_reg;

    m_data_o  <= m_data_reg;
    m_valid_o <= '1' when state_reg = VALID else '0';
end RTL;
