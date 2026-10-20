
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BMP390_pkg.all;

entity BMP390 is
    generic(
        CLK_FREQUENCY : positive
    );
    port (
        clk_i     : in std_logic;
        reset_i   : in std_logic;
        enable_i  : in std_logic;
        data_o    : out BMP390DataArray_t;
        valid_o   : out std_logic;
        ready_i   : in std_logic;
        missing_o : out std_logic;
        status_o  : out std_logic_vector(15 downto 0);

        nvm_data_o : out BMP390NVMDataArray_t;

        -- Interface SPI
        spi_miso_i : in std_logic;
        spi_mosi_o : out std_logic;
        spi_sck_o  : out std_logic;
        spi_cs_n_o : out std_logic
    );
end BMP390;

architecture RTL of BMP390 is
    constant STARTUP_TIMER_MAX : positive := CLK_FREQUENCY * BMP390_STARTUP_TIME_MS / 1000;
    signal startup_timer_reg : natural range 0 to STARTUP_TIMER_MAX;

    -- Pour simplifier, tous les timings des trames SPI seront réglés sur la durée d'un bit,
    -- y compris le temps d'attente au démarrage du BMP390.
    constant SPI_TIMER_MAX            : positive := CLK_FREQUENCY / BMP390_SPI_FREQUENCY - 1;
    constant SPI_TIMER_HALF           : positive := CLK_FREQUENCY / BMP390_SPI_FREQUENCY / 2 - 1;
    constant SPI_SETUP_HOLD_TIMER_MAX : positive := SPI_TIMER_HALF;
    signal spi_timer_reg    : natural range 0 to SPI_TIMER_MAX;

    signal spi_sck_reg, spi_miso_reg : std_logic;

    type State_t is (STARTUP, SPI_START, SPI_SETUP, SPI_TRANSFER, SPI_HOLD, SPI_DESELECT, SPI_SAMPLE);
    signal state_reg : State_t;

    constant SPI_BASE_LENGTH        : positive := 16; -- R/W+Addr, Data
    constant SPI_READ_LENGTH_SINGLE : positive := 8;
    constant SPI_READ_LENGTH_NVM    : positive := 32;
    constant SPI_READ_LENGTH_MEAS   : positive := 64; -- Error, Status, Pressure, Temperature

    constant SPI_READ_LENGTH_MAX : positive := SPI_READ_LENGTH_MEAS;
    constant BIT_INDEX_MAX       : natural := SPI_BASE_LENGTH + SPI_READ_LENGTH_MAX - 1;
    signal bit_index_reg         : natural range 0 to BIT_INDEX_MAX;

    subtype SPIWriteData_t is std_logic_vector(SPI_BASE_LENGTH     - 1 downto 0);
    subtype SPIReadData_t  is std_logic_vector(SPI_READ_LENGTH_MAX - 1 downto 0);

    type SPIFrame_t is record
        data        : SPIWriteData_t;
        start_index : positive range SPI_BASE_LENGTH - 1 to BIT_INDEX_MAX;
    end record;

    type SPIFrameArray_t is array(natural range <>) of SPIFrame_t;

    constant SPI_FRAMES : SPIFrameArray_t(0 to 13) := (
        -- Lire le registre CHIP_ID (0x00) pour vérifier la présence du capteur.
        (BMP390_READ  & BMP390_CHIP_ID_REG    & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_SINGLE - 1),
        -- Attendre que le capteur soit prêt à recevoir une commande (STATUS.cmd_rdy = '1')
        (BMP390_READ  & BMP390_STATUS_REG     & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_SINGLE - 1),
        -- Réinitialiser le capteur (soft reset)
        (BMP390_WRITE & BMP390_CMD_REG        & BMP390_CMD_SOFT_RESET,        SPI_BASE_LENGTH - 1),
        -- Lire les paramètres de calibration de la température et de la pression.
        (BMP390_READ  & BMP390_NVM_PAR_T1_REG & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_NVM    - 1),
        (BMP390_READ  & BMP390_NVM_PAR_T3_REG & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_SINGLE - 1),
        (BMP390_READ  & BMP390_NVM_PAR_P1_REG & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_NVM    - 1),
        (BMP390_READ  & BMP390_NVM_PAR_P3_REG & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_NVM    - 1),
        (BMP390_READ  & BMP390_NVM_PAR_P6_REG & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_NVM    - 1),
        (BMP390_READ  & BMP390_NVM_PAR_P9_REG & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_NVM    - 1),
        -- Configurer le capteur.
        (BMP390_WRITE & BMP390_OSR_REG        & BMP390_OSR_PX32_TX2,          SPI_BASE_LENGTH - 1),
        (BMP390_WRITE & BMP390_ODR_REG        & BMP390_ODR_12P5_HZ,           SPI_BASE_LENGTH - 1),
--        (BMP390_WRITE & BMP390_CONFIG_REG     & BMP390_CONFIG_IIR1,           SPI_BASE_LENGTH - 1),
        -- Démarrer une mesure en mode forcé
        (BMP390_WRITE & BMP390_PW_CTRL_REG    & BMP390_PW_CTRL_FORCED_ALL_ON, SPI_BASE_LENGTH - 1),
        -- Attendre la fin de l'acquisition (retour en mode sleep)
        (BMP390_READ  & BMP390_PW_CTRL_REG    & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_SINGLE - 1),
        -- Lire les registres d'état et les valeurs de température et de pression (ERR, STATUS, DATA0 à DATA5).
        (BMP390_READ  & BMP390_ERR_REG        & BMP390_DUMMY,                 SPI_BASE_LENGTH + SPI_READ_LENGTH_MEAS   - 1)
    );

    signal step_reg       : natural range SPI_FRAMES'range;
    signal spi_buffer_reg : SPIReadData_t;
    alias  spi_wdata_reg  : std_logic_vector is spi_buffer_reg(SPIReadData_t'left downto SPIReadData_t'length - SPIWriteData_t'length);

    signal nvm_par_t1_reg, nvm_par_t2_reg   : std_logic_vector(15 downto 0);
    signal nvm_par_t3_reg                   : std_logic_vector(7 downto 0);
    signal nvm_par_p1_reg, nvm_par_p2_reg   : std_logic_vector(15 downto 0);
    signal nvm_par_p3_reg, nvm_par_p4_reg   : std_logic_vector(7 downto 0);
    signal nvm_par_p5_reg, nvm_par_p6_reg   : std_logic_vector(15 downto 0);
    signal nvm_par_p7_reg, nvm_par_p8_reg   : std_logic_vector(7 downto 0);
    signal nvm_par_p9_reg                   : std_logic_vector(15 downto 0);
    signal nvm_par_p10_reg, nvm_par_p11_reg : std_logic_vector(7 downto 0);
begin
    p_state_reg: process(clk_i)
        variable spi_wdata : SPIWriteData_t;
        variable cmd_busy : boolean;
        variable acq_busy : boolean;
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_reg         <= STARTUP;
                startup_timer_reg <= 0;
                spi_timer_reg     <= 0;
                step_reg          <= 0;
                data_o            <= (others =>(others => '0'));
                spi_sck_reg       <= '0';
                missing_o         <= '0';

                nvm_par_t1_reg    <= (15 => '1', others => '0');
                nvm_par_t2_reg    <= (15 => '1', others => '0');
                nvm_par_t3_reg    <= (7  => '1', others => '0');
                nvm_par_p1_reg    <= (15 => '1', others => '0');
                nvm_par_p2_reg    <= (15 => '1', others => '0');
                nvm_par_p3_reg    <= (7  => '1', others => '0');
                nvm_par_p4_reg    <= (7  => '1', others => '0');
                nvm_par_p5_reg    <= (15 => '1', others => '0');
                nvm_par_p6_reg    <= (15 => '1', others => '0');
                nvm_par_p7_reg    <= (7  => '1', others => '0');
                nvm_par_p8_reg    <= (7  => '1', others => '0');
                nvm_par_p9_reg    <= (15 => '1', others => '0');
                nvm_par_p10_reg   <= (7  => '1', others => '0');
                nvm_par_p11_reg   <= (7  => '1', others => '0');
            else
                spi_wdata := SPI_FRAMES(step_reg).data;
                case state_reg is
                    when STARTUP =>
                        if startup_timer_reg < STARTUP_TIMER_MAX then
                            startup_timer_reg <= startup_timer_reg + 1;
                        elsif enable_i = '1' then
                            startup_timer_reg <= 0;
                            state_reg         <= SPI_START;
                        end if;

                    when SPI_START =>
                        spi_timer_reg <= 0;
                        bit_index_reg <= SPI_FRAMES(step_reg).start_index;
                        spi_sck_reg   <= '0';
                        -- Copier la commande SPI courante dans le buffer d'envoi.
                        spi_wdata_reg <= spi_wdata;
                        state_reg     <= SPI_SETUP;

                    when SPI_SETUP =>
                        if spi_timer_reg < SPI_SETUP_HOLD_TIMER_MAX then
                            spi_timer_reg <= spi_timer_reg + 1;
                        else
                            spi_timer_reg  <= 0;
                            state_reg <= SPI_TRANSFER;
                        end if;

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
                                state_reg <= SPI_HOLD;
                            end if;
                        end if;

                    when SPI_HOLD =>
                        if spi_timer_reg < SPI_SETUP_HOLD_TIMER_MAX then
                            spi_timer_reg <= spi_timer_reg + 1;
                        else
                            spi_timer_reg  <= 0;
                            state_reg <= SPI_DESELECT;
                        end if;

                    -- Désactiver la broche CS du BMP390 pendant la durée d'un bit.
                    when SPI_DESELECT =>
                        if spi_timer_reg < SPI_TIMER_MAX then
                            spi_timer_reg <= spi_timer_reg + 1;
                        elsif step_reg = 0 and spi_buffer_reg(7 downto 0) /= BMP390_CHIP_ID then
                            -- Le capteur est marqué comme absent si la lecture du registre
                            -- CHIP_ID retourne une valeur incorrecte.
                            -- La machine à états est bloquée jusqu'au prochain reset.
                            missing_o <= '1';
                        elsif step_reg < SPI_FRAMES'high then
                            -- Enregistrer les paramètres de compensation de la mesure de pression.
                            case spi_wdata(14 downto 8) is
                                when BMP390_NVM_PAR_T1_REG =>
                                    nvm_par_t1_reg <= spi_buffer_reg(23 downto 16) & spi_buffer_reg(31 downto 24);
                                    nvm_par_t2_reg <= spi_buffer_reg(7  downto 0)  & spi_buffer_reg(15 downto 8);
                                when BMP390_NVM_PAR_T3_REG =>
                                    nvm_par_t3_reg <= spi_buffer_reg(7  downto 0);
                                when BMP390_NVM_PAR_P1_REG =>
                                    nvm_par_p1_reg <= spi_buffer_reg(23 downto 16) & spi_buffer_reg(31 downto 24);
                                    nvm_par_p2_reg <= spi_buffer_reg(7  downto 0)  & spi_buffer_reg(15 downto 8);
                                when BMP390_NVM_PAR_P3_REG =>
                                    nvm_par_p3_reg <= spi_buffer_reg(31 downto 24);
                                    nvm_par_p4_reg <= spi_buffer_reg(23 downto 16);
                                    nvm_par_p5_reg <= spi_buffer_reg(7 downto 0) & spi_buffer_reg(15 downto 8);
                                when BMP390_NVM_PAR_P6_REG =>
                                    nvm_par_p6_reg <= spi_buffer_reg(23 downto 16) & spi_buffer_reg(31 downto 24);
                                    nvm_par_p7_reg <= spi_buffer_reg(15 downto 8);
                                    nvm_par_p8_reg <= spi_buffer_reg(7  downto 0);
                                when BMP390_NVM_PAR_P9_REG =>
                                    nvm_par_p9_reg  <= spi_buffer_reg(23 downto 16) & spi_buffer_reg(31 downto 24);
                                    nvm_par_p10_reg <= spi_buffer_reg(15 downto 8);
                                    nvm_par_p11_reg <= spi_buffer_reg(7  downto 0);
                                when others =>
                            end case;

                            -- Réexécuter la même trame SPI si
                            -- * Le registre STATUS indique que le capteur est en train d'exécuter une commande.
                            -- * Le registre PWR_CTRL indique que le capteur n'est pas en mode sleep.
                            cmd_busy := spi_wdata(14 downto 8) = BMP390_STATUS_REG and spi_buffer_reg(4) = '0';
                            acq_busy := spi_wdata(15 downto 8) = BMP390_READ & BMP390_PW_CTRL_REG and spi_buffer_reg(5 downto 4) /= "00";
                            if not cmd_busy and not acq_busy then
                                step_reg <= step_reg + 1;
                            end if;

                            -- Démarrer une nouvelle trame SPI.
                            -- Après un soft reset, retourner à l'état STARTUP sans remettre à zéro step_reg.
                            if spi_wdata(14 downto 8) = BMP390_CMD_REG then
                                state_reg <= STARTUP;
                            else
                                state_reg <= SPI_START;
                            end if;
                        else
                            -- À la fin d'une commande de lecture des résultats de conversion,
                            -- mémoriser la température et la pression.
                            -- Les octets ont été lus en mode little-endian.
                            -- La température est en binaire décalé.
                            -- La sortie status_o reçoit le contenu des registres ERR_REG et STATUS du BMP390.
                            data_o <= (
                                unsigned(std_logic_vector'(spi_buffer_reg(7  downto 0)  & spi_buffer_reg(15 downto 8)  & spi_buffer_reg(23 downto 16))),
                                unsigned(std_logic_vector'(spi_buffer_reg(31 downto 24) & spi_buffer_reg(39 downto 32) & spi_buffer_reg(47 downto 40)))
                            );
                            status_o <= spi_buffer_reg(63 downto 48);

                            -- Aller attendre la fin de la période d'échantillonnage
                            -- avant de redémarrer une conversion.
                            step_reg  <= step_reg - 2;
                            state_reg <= SPI_SAMPLE;
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
    spi_cs_n_o <= '0' when state_reg >= SPI_SETUP and state_reg <= SPI_HOLD else '1';

    nvm_data_o <= (
        std_logic_vector'(nvm_par_t1_reg & nvm_par_t2_reg),
        std_logic_vector'(x"000000"      & nvm_par_t3_reg),
        std_logic_vector'(nvm_par_p1_reg & nvm_par_p2_reg),
        std_logic_vector'(nvm_par_p3_reg & nvm_par_p4_reg  & nvm_par_p5_reg),
        std_logic_vector'(nvm_par_p6_reg & nvm_par_p7_reg  & nvm_par_p8_reg),
        std_logic_vector'(nvm_par_p9_reg & nvm_par_p10_reg & nvm_par_p11_reg)
    );
end RTL;
