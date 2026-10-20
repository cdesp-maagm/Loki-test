
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.LTC2984_pkg.all;

entity LTC2984 is
    generic(
        CLK_FREQUENCY : positive
    );
    port(
        clk_i      : in std_logic;
        reset_i    : in std_logic;
        enable_i   : in std_logic;
        data_o     : out LTC2984DataArray_t;
        valid_o    : out std_logic;
        ready_i    : in std_logic;
        missing_o  : out std_logic;
        status_o   : out std_logic_vector(7 downto 0);

        -- Interface SPI
        spi_miso_i : in std_logic;
        spi_mosi_o : out std_logic;
        spi_sck_o  : out std_logic;
        spi_cs_n_o : out std_logic
    );
end LTC2984;

architecture RTL of LTC2984 is
    -- Pour simplifier, tous les timings des trames SPI seront réglés sur la durée d'un bit,
    -- y compris le temps d'attente au démarrage du LTC2984.
    constant SPI_TIMER_MAX  : positive := CLK_FREQUENCY / LTC2984_SPI_FREQUENCY - 1;
    constant SPI_TIMER_HALF : positive := CLK_FREQUENCY / LTC2984_SPI_FREQUENCY / 2 - 1;
    signal spi_timer_reg    : natural range 0 to SPI_TIMER_MAX;

    signal spi_sck_reg, spi_miso_reg : std_logic;

    signal channel_reg : natural range 0 to LTC2984_CHANNELS - 1;

    type State_t is (STARTUP, SPI_START, SPI_TRANSFER, SPI_DESELECT, SPI_SAMPLE);
    signal state_reg : State_t;

    constant SPI_FRAME_LENGTH_MIN : positive := 32;
    constant SPI_FRAME_LENGTH_MAX : positive := 56;

    signal bit_index_reg : natural range 0 to SPI_FRAME_LENGTH_MAX - 1;

    subtype SPIFrameData_t is std_logic_vector(SPI_FRAME_LENGTH_MAX - 1 downto 0);

    type SPIFrame_t is record
        data : SPIFrameData_t;
        start_index : positive range SPI_FRAME_LENGTH_MIN - 1 to SPI_FRAME_LENGTH_MAX - 1;
    end record;

    type SPIFrameArray_t is array(natural range <>) of SPIFrame_t;

    constant SPI_FRAMES : SPIFrameArray_t(0 to 8) := (
        -- Attendre que le LTC2984 soit prêt.
        (LTC2984_READ  & LTC2984_CMD_STATUS_REG     & LTC2984_DUMMY,                 SPI_FRAME_LENGTH_MIN-1),
        -- Déverrouiller l'EEPROM.
        (LTC2984_WRITE & LTC2984_EEPROM_KEY_REG     & LTC2984_EEPROM_KEY,            SPI_FRAME_LENGTH_MAX-1),
        -- Démarrer la lecture de l'EEPROM.
        (LTC2984_WRITE & LTC2984_CMD_STATUS_REG     & LTC2984_CMD_START_EEPROM_READ, SPI_FRAME_LENGTH_MIN-1),
        -- Attendre la fin de la lecture.
        (LTC2984_READ  & LTC2984_CMD_STATUS_REG     & LTC2984_DUMMY,                 SPI_FRAME_LENGTH_MIN-1),
        -- Lire le code de retour de l'EEPROM.
        (LTC2984_READ  & LTC2984_EEPROM_RESULT_REG  & LTC2984_DUMMY,                 SPI_FRAME_LENGTH_MIN-1),
        -- Autoriser toutes les voies.
        (LTC2984_WRITE & LTC2984_MULT_CHAN_MASK_REG & LTC2984_MULT_CHAN_MASK_ALL,    SPI_FRAME_LENGTH_MAX-1),
        -- Démarrer une conversion sur toutes les voies.
        (LTC2984_WRITE & LTC2984_CMD_STATUS_REG     & LTC2984_CMD_START_CONV_ALL,    SPI_FRAME_LENGTH_MIN-1),
        -- Attendre la fin de la conversion.
        (LTC2984_READ  & LTC2984_CMD_STATUS_REG     & LTC2984_DUMMY,                 SPI_FRAME_LENGTH_MIN-1),
        -- Lire les résultats de la conversion.
        (LTC2984_READ  & LTC2984_TEMP_RESULT_REG    & LTC2984_DUMMY,                 SPI_FRAME_LENGTH_MAX-1)
    );

    signal step_reg       : natural range SPI_FRAMES'range;
    signal spi_buffer_reg : SPIFrameData_t;
begin
    p_state_reg : process(clk_i)
        variable spi_wdata : SPIFrameData_t;
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_reg     <= STARTUP;
                spi_timer_reg <= 0;
                step_reg      <= 0;
                data_o        <= (others => (others => '0'));
                channel_reg   <= 0;
                spi_sck_reg   <= '0';
                missing_o     <= '0';
            else
                spi_wdata := SPI_FRAMES(step_reg).data;
                case state_reg is
                    -- Attendre le délai de démarrage du LTC2984.
                    -- Lorsque le délai est terminé, attendre que le consommateur soit prêt
                    -- pour démarrer les transferts SPI.
                    when STARTUP =>
                        if spi_timer_reg < SPI_TIMER_MAX then
                            spi_timer_reg <= spi_timer_reg + 1;
                        elsif enable_i = '1' then
                            state_reg <= SPI_START;
                        end if;

                    when SPI_START =>
                        spi_timer_reg  <= 0;
                        bit_index_reg  <= SPI_FRAMES(step_reg).start_index;
                        spi_sck_reg    <= '0';
                        -- Copier la commande SPI courante dans le buffer d'envoi.
                        -- Ajouter le numéro de la voie courante à l'adresse (0 pour les commandes où il n'est pas utilisé).
                        spi_buffer_reg <= spi_wdata(55 downto 48) &
                                          std_logic_vector(unsigned(spi_wdata(47 downto 34)) + to_unsigned(channel_reg, 14)) &
                                          spi_wdata(33 downto 0);
                        state_reg      <= SPI_TRANSFER;

                    -- Effectuer un transfert SPI.
                    when SPI_TRANSFER =>
                        if spi_timer_reg < SPI_TIMER_MAX then
                            if spi_timer_reg = SPI_TIMER_HALF then
                                -- À la moitié d'une période bit, produire un front montant sur l'horloge SPI.
                                spi_sck_reg <= '1';
                                -- Mémoriser le bit reçu sur l'entrée SPI.
                                spi_miso_reg <= spi_miso_i;
                            end if;
                            spi_timer_reg <= spi_timer_reg + 1;
                        else
                            spi_timer_reg <= 0;
                            -- À la fin d'une période bit, remettre l'horloge SPI à zéro.
                            spi_sck_reg <= '0';
                            -- Décaler les bits à transmettre et insérer le dernier bit reçu dans le registre à décalage.
                            spi_buffer_reg <= spi_buffer_reg(spi_buffer_reg'left - 1 downto 0) & spi_miso_reg;
                            -- Passer au bit suivant ou terminer la trame en cours.
                            if bit_index_reg > 0 then
                                bit_index_reg <= bit_index_reg - 1;
                            else
                                state_reg <= SPI_DESELECT;
                            end if;
                        end if;

                    -- Désactiver la broche CS du LTC2984 pendant la durée d'un bit.
                    when SPI_DESELECT =>
                        if spi_timer_reg < SPI_TIMER_MAX then
                            spi_timer_reg <= spi_timer_reg + 1;
                        elsif step_reg = 0 and spi_buffer_reg(7 downto 6) /= "10" and spi_buffer_reg(7 downto 6) /= "01" then
                            -- Le capteur est marqué comme absent si :
                            -- * La commande courante est la première lecture du registre d'état du LTC2984
                            -- * et le registre d'état a une valeur invalide.
                            -- La machine à états est bloquée jusqu'au prochain reset.
                            missing_o <= '1';
                        elsif step_reg < SPI_FRAMES'high then
                            -- Passer à la commande suivante si :
                            -- * La commande courante n'est pas une lecture du registre d'état du LTC2984
                            -- * ou le registre d'état indique une fin d'opération (initialisation, EEPROM ou conversion).
                            if spi_wdata(55 downto 32) /= LTC2984_READ & LTC2984_CMD_STATUS_REG or spi_buffer_reg(7 downto 6) = "01" then
                                step_reg <= step_reg + 1;
                            end if;
                            -- Mémoriser le code de retour après lecture de l'EEPROM.
                            if spi_wdata(55 downto 32) = LTC2984_READ & LTC2984_EEPROM_RESULT_REG then
                                status_o <= spi_buffer_reg(status_o'range);
                            end if;
                            -- Démarrer une nouvelle trame SPI.
                            state_reg <= SPI_START;
                        else
                            -- À la fin d'une commande de lecture des résultats de conversion,
                            -- mémoriser la température.
                            data_o(channel_reg) <= signed(spi_buffer_reg(LTC2984Data_t'range));
                            if channel_reg < LTC2984_CHANNELS - 1 then
                                -- Aller lire la température pour la voie suivante.
                                channel_reg <= channel_reg + 1;
                                state_reg   <= SPI_START;
                            else
                                -- Aller attendre la fin de la période d'échantillonnage
                                -- avant de redémarrer une conversion.
                                channel_reg <= 0;
                                step_reg    <= step_reg - 2;
                                state_reg   <= SPI_SAMPLE;
                            end if;
                        end if;

                    -- Attendre la lecture de la donnée par le consommateur.
                    when SPI_SAMPLE =>
                        if ready_i = '1' then
                            state_reg <= SPI_START;
                        end if;
                end case;
            end if;
        end if;
    end process p_state_reg;

    valid_o <= '1' when state_reg = SPI_SAMPLE else '0';

    -- Transferts SPI.
    spi_mosi_o <= spi_buffer_reg(spi_buffer_reg'left);
    spi_sck_o  <= spi_sck_reg;
    spi_cs_n_o <= '0' when state_reg = SPI_TRANSFER else '1';
end RTL;

