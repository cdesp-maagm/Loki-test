-- Library UNISIM;
-- use UNISIM.vcomponents.all;
--
-- -- <-----Cut code below this line and paste into the architecture body---->
--
--    -- DSP48E1: 48-bit Multi-Functional Arithmetic Block
--    --          Artix-7
--    -- Xilinx HDL Language Template, version 2018.1
--
--    DSP48E1_inst : DSP48E1
--    generic map (
--       -- Feature Control Attributes: Data Path Selection
--       A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
--       B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
--       USE_DPORT => FALSE,                -- Select D port usage (TRUE or FALSE)
--       USE_MULT => "MULTIPLY",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
--       USE_SIMD => "ONE48",               -- SIMD selection ("ONE48", "TWO24", "FOUR12")
--       -- Pattern Detector Attributes: Pattern Detection Configuration
--       AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
--       MASK => X"3fffffffffff",           -- 48-bit mask value for pattern detect (1=ignore)
--       PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
--       SEL_MASK => "MASK",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
--       SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
--       USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
--       -- Register Control Attributes: Pipeline Register Configuration
--       ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
--       ADREG => 1,                        -- Number of pipeline stages for pre-adder (0 or 1)
--       ALUMODEREG => 1,                   -- Number of pipeline stages for ALUMODE (0 or 1)
--       AREG => 1,                         -- Number of pipeline stages for A (0, 1 or 2)
--       BCASCREG => 1,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
--       BREG => 1,                         -- Number of pipeline stages for B (0, 1 or 2)
--       CARRYINREG => 1,                   -- Number of pipeline stages for CARRYIN (0 or 1)
--       CARRYINSELREG => 1,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
--       CREG => 1,                         -- Number of pipeline stages for C (0 or 1)
--       DREG => 1,                         -- Number of pipeline stages for D (0 or 1)
--       INMODEREG => 1,                    -- Number of pipeline stages for INMODE (0 or 1)
--       MREG => 1,                         -- Number of multiplier pipeline stages (0 or 1)
--       OPMODEREG => 1,                    -- Number of pipeline stages for OPMODE (0 or 1)
--       PREG => 1                          -- Number of pipeline stages for P (0 or 1)
--    )
--    port map (
--       -- Cascade: 30-bit (each) output: Cascade Ports
--       ACOUT => ACOUT,                   -- 30-bit output: A port cascade output
--       BCOUT => BCOUT,                   -- 18-bit output: B port cascade output
--       CARRYCASCOUT => CARRYCASCOUT,     -- 1-bit output: Cascade carry output
--       MULTSIGNOUT => MULTSIGNOUT,       -- 1-bit output: Multiplier sign cascade output
--       PCOUT => PCOUT,                   -- 48-bit output: Cascade output
--       -- Control: 1-bit (each) output: Control Inputs/Status Bits
--       OVERFLOW => OVERFLOW,             -- 1-bit output: Overflow in add/acc output
--       PATTERNBDETECT => PATTERNBDETECT, -- 1-bit output: Pattern bar detect output
--       PATTERNDETECT => PATTERNDETECT,   -- 1-bit output: Pattern detect output
--       UNDERFLOW => UNDERFLOW,           -- 1-bit output: Underflow in add/acc output
--       -- Data: 4-bit (each) output: Data Ports
--       CARRYOUT => CARRYOUT,             -- 4-bit output: Carry output
--       P => P,                           -- 48-bit output: Primary data output
--       -- Cascade: 30-bit (each) input: Cascade Ports
--       ACIN => ACIN,                     -- 30-bit input: A cascade data input
--       BCIN => BCIN,                     -- 18-bit input: B cascade input
--       CARRYCASCIN => CARRYCASCIN,       -- 1-bit input: Cascade carry input
--       MULTSIGNIN => MULTSIGNIN,         -- 1-bit input: Multiplier sign input
--       PCIN => PCIN,                     -- 48-bit input: P cascade input
--       -- Control: 4-bit (each) input: Control Inputs/Status Bits
--       ALUMODE => ALUMODE,               -- 4-bit input: ALU control input
--       CARRYINSEL => CARRYINSEL,         -- 3-bit input: Carry select input
--       CLK => CLK,                       -- 1-bit input: Clock input
--       INMODE => INMODE,                 -- 5-bit input: INMODE control input
--       OPMODE => OPMODE,                 -- 7-bit input: Operation mode input
--       -- Data: 30-bit (each) input: Data Ports
--       A => A,                           -- 30-bit input: A data input
--       B => B,                           -- 18-bit input: B data input
--       C => C,                           -- 48-bit input: C data input
--       CARRYIN => CARRYIN,               -- 1-bit input: Carry input signal
--       D => D,                           -- 25-bit input: D data input
--       -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
--       CEA1 => CEA1,                     -- 1-bit input: Clock enable input for 1st stage AREG
--       CEA2 => CEA2,                     -- 1-bit input: Clock enable input for 2nd stage AREG
--       CEAD => CEAD,                     -- 1-bit input: Clock enable input for ADREG
--       CEALUMODE => CEALUMODE,           -- 1-bit input: Clock enable input for ALUMODE
--       CEB1 => CEB1,                     -- 1-bit input: Clock enable input for 1st stage BREG
--       CEB2 => CEB2,                     -- 1-bit input: Clock enable input for 2nd stage BREG
--       CEC => CEC,                       -- 1-bit input: Clock enable input for CREG
--       CECARRYIN => CECARRYIN,           -- 1-bit input: Clock enable input for CARRYINREG
--       CECTRL => CECTRL,                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
--       CED => CED,                       -- 1-bit input: Clock enable input for DREG
--       CEINMODE => CEINMODE,             -- 1-bit input: Clock enable input for INMODEREG
--       CEM => CEM,                       -- 1-bit input: Clock enable input for MREG
--       CEP => CEP,                       -- 1-bit input: Clock enable input for PREG
--       RSTA => RSTA,                     -- 1-bit input: Reset input for AREG
--       RSTALLCARRYIN => RSTALLCARRYIN,   -- 1-bit input: Reset input for CARRYINREG
--       RSTALUMODE => RSTALUMODE,         -- 1-bit input: Reset input for ALUMODEREG
--       RSTB => RSTB,                     -- 1-bit input: Reset input for BREG
--       RSTC => RSTC,                     -- 1-bit input: Reset input for CREG
--       RSTCTRL => RSTCTRL,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
--       RSTD => RSTD,                     -- 1-bit input: Reset input for DREG and ADREG
--       RSTINMODE => RSTINMODE,           -- 1-bit input: Reset input for INMODEREG
--       RSTM => RSTM,                     -- 1-bit input: Reset input for MREG
--       RSTP => RSTP                      -- 1-bit input: Reset input for PREG
--    );
--
--    -- End of DSP48E1_inst instantiation

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fixed_pkg.all;
use work.FIRFilter_pkg.all;

entity MultiplyAccumulate is
    port(
        clk_i           : in  std_logic;
        a_i, b_i, acc_i : in  sfixed;
        acc_o           : out sfixed
    );
end MultiplyAccumulate;

architecture RTL of MultiplyAccumulate is
    signal a                : signed(a_i'length - 1 downto 0);
    signal b                : signed(b_i'length - 1 downto 0);
    signal acc, product_reg : signed(acc_i'length - 1 downto 0);
begin
    a   <= to_signed(a_i);
    b   <= to_signed(b_i);
    acc <= to_signed(acc_i);

    p_product_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            product_reg <= a * b;
        end if;
    end process p_product_reg;

    acc_o <= sfixed(product_reg + acc);
end RTL;

architecture RTL of FIRFilter is
    constant MAC_COEFF_LEFT    : integer := Coefficient_t'left + GAIN_BITS;
    constant MAC_COEFF_RIGHT   : integer := MAC_COEFF_LEFT - MAX_COEFF_WIDTH + 1;
    constant TAP_LEFT          : integer := s_data_i'left;
    constant TAP_RIGHT         : integer := TAP_LEFT - MAX_TAP_WIDTH + 1;
    constant ACC_LEFT          : integer := TAP_LEFT + MAC_COEFF_LEFT + 1;
    constant ACC_RIGHT         : integer := TAP_RIGHT + MAC_COEFF_RIGHT;
    constant ACC_TO_FIFO_LEFT  : integer := s_data_i'left + GAIN_BITS;
    constant ACC_TO_FIFO_RIGHT : integer := ACC_TO_FIFO_LEFT - m_data_o'length + 1;

    subtype MacCoeff_t is sfixed(MAC_COEFF_LEFT downto MAC_COEFF_RIGHT);
    type MacCoeffArray_t is array(natural range <>) of MacCoeff_t;

    subtype Tap_t is sfixed(TAP_LEFT downto TAP_RIGHT);
    type TapArray_t is array(natural range<>) of Tap_t;

    subtype Acc_t is sfixed(ACC_LEFT downto ACC_RIGHT);
    type AccArray_t is array(natural range <>) of Acc_t;

    type FIFOData_t is record
        data    : sfixed(m_data_o'range);
        channel : integer range 0 to CHANNELS - 1;
        last    : std_logic;
    end record FIFOData_t;

    type FIFODataArray_t is array(0 to CHANNELS) of FIFOData_t;

    type State_t is (IDLE, BUSY, STALLED);

    signal s_ready                        : std_logic;

    constant TAPS_PER_STEP                : positive := COEFFICIENTS'length(2);
    signal tap_index_reg                  : integer range 0 to TAPS_PER_STEP - PARALLELISM;
    signal sample_restart, sample_done    : boolean;

    constant DECIMATION                   : integer := COEFFICIENTS'length(1);
    signal phase_reg                      : integer range 0 to DECIMATION - 1;
    signal sample_ready                   : boolean;

    signal channel_reg                    : integer range 0 to CHANNELS - 1;
    signal last_reg                       : std_logic;

    signal tap0                           : Tap_t;
    signal taps                           : TapArray_t(0 to TAPS_PER_STEP - 1) := (others => to_sfixed(0, TAP_LEFT, TAP_RIGHT));
    signal delay_enable                   : std_logic;

    signal mac_acc                        : AccArray_t(0 to PARALLELISM);
    signal mac_a                          : MacCoeffArray_t(0 to PARALLELISM - 1);
    signal mac_b                          : TapArray_t(0 to PARALLELISM - 1);

    alias acc_reg                         : Acc_t is mac_acc(0);
    alias acc_next                        : Acc_t is mac_acc(PARALLELISM);
    signal partial_reg                    : AccArray_t(0 to CHANNELS - 1) := (others => to_sfixed(0, ACC_LEFT, ACC_RIGHT));

    signal state_reg                      : State_t;

    signal fifo_s_valid_reg, fifo_s_ready : std_logic;
    signal fifo_s_channel_reg             : integer range 0 to CHANNELS - 1;
    signal fifo_s_data_reg                : sfixed(m_data_o'range);
    signal fifo_s_last_reg                : std_logic;

    signal fifo_stalled                   : std_logic;
    signal fifo_data_reg                  : FIFODataArray_t := (others => ((others => '0'), 0, '0'));
    signal fifo_read_index                : natural range fifo_data_reg'range;
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
                            -- Un nouvel échantillon est disponible.
                            -- Commencer le traitement dans l'état BUSY.
                            state_reg <= BUSY;
                        end if;

                    when BUSY =>
                        if sample_ready and fifo_stalled = '1' then
                            -- Lorsqu'un échantillon de sortie est prêt, si la
                            -- FIFO est pleine, attendre son déblocage dans
                            -- l'état STALLED.
                            state_reg <= STALLED;
                        elsif sample_restart and s_valid_i = '0' then
                            -- En revenant au premier coefficient de sous-filtre,
                            -- je suis prêt à accepter un nouvel échantillon.
                            -- Retourner en attente si aucun échantillon n'est
                            -- disponible.
                            state_reg <= IDLE;
                        end if;

                    when STALLED =>
                        if fifo_stalled = '0' then
                            -- Une place s'est libérée dans la FIFO de sortie.
                            -- Le dernier échantillon de sortie sera écrit.
                            -- Passer dans l'état BUSY ou IDLE en fonction de la
                            -- disponibilité d'un nouvel échantillon en entrée.
                            if s_valid_i = '1' then
                                state_reg <= BUSY;
                            else
                                state_reg <= IDLE;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process p_state_reg;

    -- Gestion de l'acquittement des données d'entrée.
    -- s_ready est actif lorsque toutes les conditions suivantes sont vérifiées :
    -- une donnée est disponible en entrée ; le filtre est en attente d'un
    -- échantillon ou a fini de traiter l'échantillon précédent ; au moment de
    -- produire un échantillon de sortie, la FIFO de sortie n'est pas bloquée.
    p_s_ready : process(all)
    begin
        case state_reg is
            when IDLE =>
                -- En attente d'un nouvel échantillon,
                -- acquitter immédiatement.
                s_ready <= s_valid_i;

            when BUSY =>
                if sample_ready then
                    -- Lorsqu'un échantillon de sortie est prêt, les échantillons
                    -- d'entrée son acceptés seulement si la FIFO de sortie n'est
                    -- pas pleine.
                    s_ready <= s_valid_i and not fifo_stalled;
                elsif sample_restart then
                    -- En revenant au premier coefficient de sous-filtre,
                    -- je suis prêt à accepter un nouvel échantillon.
                    s_ready <= s_valid_i;
                else
                    -- Les échantillons sont mis en attente tant que le calcul
                    -- pour l'échantillon courant n'est pas terminé.
                    s_ready <= '0';
                end if;

            when STALLED =>
                -- Acquitter le prochain échantillon lorsque la FIFO se débloque.
                s_ready <= s_valid_i and not fifo_stalled;
        end case;
    end process p_s_ready;

    s_ready_o <= s_ready;

    -- Indice du coefficient de filtre courant.
    -- Les coefficients et les échantillons précédents sont chargés un cycle avant
    -- les opérations de calcul qui les traitent (cf p_coeffs_taps_reg).
    -- tap_index_reg est incrémenté dès que l'on accepte un nouvel échantillon,
    -- puis à chaque cycle d'horloge dans l'état BUSY jusqu'à ce qu'il revienne
    -- à zéro pour préparer le calcul sur l'échantillon suivant.
    p_tap_index_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if s_ready = '1' or (state_reg = BUSY and tap_index_reg > 0 and tap_index_reg < TAPS_PER_STEP - PARALLELISM) then
                tap_index_reg <= tap_index_reg + PARALLELISM;
            else
                tap_index_reg <= 0;
            end if;
        end if;
    end process p_tap_index_reg;

    -- Indicateur de fin de traitement d'un échantillon dans l'état BUSY.
    sample_done <= state_reg = BUSY and tap_index_reg = TAPS_PER_STEP - PARALLELISM;

    -- Indicateur de retour au premier coefficient de sous-filtre dans l'état BUSY.
    sample_restart <= state_reg = BUSY and tap_index_reg = 0;

    -- Indice du sous-filtre courant dans la décomposition polyphase du filtre.
    -- phase_reg est mis à jour lorsque le filtre traite un échantillon du dernier
    -- canal (last_reg) et a atteint le dernier coefficient du sous-filtre courant.
    p_phase_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                phase_reg <= 0;
            elsif last_reg = '1' and sample_done then
                if phase_reg = DECIMATION - 1 then
                    phase_reg <= 0;
                else
                    phase_reg <= phase_reg + 1;
                end if;
            end if;
        end if;
    end process p_phase_reg;

    -- Indicateur de fin de calcul d'un échantillon de sortie.
    -- sample_ready est actif au moment du retour au premier coefficient de
    -- sous-filtre (sample_restart). Comme le signal phase_reg est utilisé avec
    -- un cycle d'horloge d'avance pour le préchargement des coefficients et
    -- échantillons dans p_coeffs_taps_reg, il est déjà revenu à zéro lorsque
    -- l'échantillon du dernier canal se présente (last_reg).
    sample_ready <= sample_restart and ((last_reg = '0' and phase_reg = DECIMATION - 1) or (last_reg = '1' and phase_reg = 0));

    -- -------------------------------------------------------------------------
    -- Mémorisation des échantillons.
    -- -------------------------------------------------------------------------

    tap0 <= resize(s_data_i, TAP_LEFT, TAP_RIGHT);

    p_data_channel_last_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if s_ready = '1' then
                taps(0)     <= tap0;
                channel_reg <= s_channel_i;
                last_reg    <= s_last_i;
            end if;
        end if;
    end process p_data_channel_last_reg;

    -- Les échantillons de tous les canaux sont insérés dans la même ligne
    -- à retard. Cela fonctionne à condition que les canaux soient toujours
    -- présentés dans le même ordre.
    -- La ligne à retard est découpée en tronçons de DECIMATION échantillons par
    -- canal, ce qui donne accès uniquement aux TAPS_PER_STEP échantillons utiles
    -- à chaque pas de calcul.
    delay_gen: for t in 0 to TAPS_PER_STEP - 2 generate
        delay_inst : entity work.DelayLine(ShiftRegisters)
            generic map(
                LENGTH => DECIMATION * CHANNELS
            )
            port map(
                clk_i    => clk_i,
                reset_i  => reset_i,
                enable_i => delay_enable,
                data_i   => taps(t),
                data_o   => taps(t + 1)
            );
    end generate delay_gen;

    delay_enable <= '1' when sample_done else '0';

    -- -------------------------------------------------------------------------
    -- Filtrage.
    -- -------------------------------------------------------------------------

    mac_gen : for i in 0 to PARALLELISM - 1 generate
        mac_a(i) <= resize(COEFFICIENTS(phase_reg, tap_index_reg + i), MAC_COEFF_LEFT, MAC_COEFF_RIGHT);
        mac_b(i) <= tap0 when i = 0 and s_ready = '1' else taps(tap_index_reg + i);

        mac_inst : entity work.MultiplyAccumulate
            port map(
                clk_i => clk_i,
                a_i   => mac_a(i),
                b_i   => mac_b(i),
                acc_i => mac_acc(i),
                acc_o => mac_acc(i + 1)
            );
    end generate;

    p_acc_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if s_ready = '1' then
                acc_reg <= partial_reg(s_channel_i);
            elsif state_reg = BUSY then
                acc_reg <= acc_next;
            end if;
        end if;
    end process p_acc_reg;

    -- Mémorisation du résultat des multiplications-accumulations effectuées
    -- dans la période d'horloge courante.
    -- Il y a un registre accumulateur par canal. Ce registre est remis à zéro
    -- à la fin du calcul d'un échantillon de sortie. Si la FIFO est pleine,
    -- la remise à zéro est différée jusqu'à ce que la FIFO soit débloquée.
    p_partial_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if sample_ready then
                partial_reg(channel_reg) <= to_sfixed(0, acc_next);
            elsif sample_restart then
                partial_reg(channel_reg) <= acc_next;
            end if;
        end if;
    end process p_partial_reg;

    -- -------------------------------------------------------------------------
    -- FIFO de sortie.
    -- -------------------------------------------------------------------------

    -- La FIFO reçoit les échantillons filtrés, les numéros de canal et les
    -- indicateurs de fin de paquet (last_reg).
    -- Si la FIFO n'est pas pleine, un nouvel élément est inséré dès qu'un
    -- échantillon est disponible (sample_ready). La valeur de l'échantillon
    -- est alors prise directement dans le signal acc_next sans attendre qu'elle
    -- soit rangée dans acc_reg.
    -- Si la FIFO est pleine au moment où l'échantillon est disponible,
    -- c'est la valeur du registre acc_reg qui est insérée au moment où la FIFO
    -- se débloque.
    p_fifo_s_data_channel_last_reg : process(clk_i)
        variable acc : Acc_t;
    begin
        if rising_edge(clk_i) then
            if sample_ready then
                acc := acc_next;
            else
                acc := acc_reg;
            end if;
            if (sample_ready or state_reg = STALLED) and fifo_stalled = '0' then
                fifo_s_data_reg    <= acc(ACC_TO_FIFO_LEFT downto ACC_TO_FIFO_RIGHT);
                fifo_s_channel_reg <= channel_reg;
                fifo_s_last_reg    <= last_reg;
            end if;
        end if;
    end process p_fifo_s_data_channel_last_reg;

    -- Indicateur de validité des données en entrée de la FIFO.
    -- fifo_s_valid_reg est activé dès qu'un échantillon de sortie est prêt.
    -- Il reste actif tant que la FIFO est pleine.
    -- Il revient à zéro lorsque le contrôleur de FIFO acquitte sa donnée d'entrée.
    p_fifo_s_valid_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                fifo_s_valid_reg <= '0';
            elsif sample_ready or state_reg = STALLED then
                fifo_s_valid_reg <= '1';
            elsif fifo_s_valid_reg = '1' then
                fifo_s_valid_reg <= not fifo_s_ready;
            end if;
        end if;
    end process p_fifo_s_valid_reg;

    fifo_inst : entity work.FIFOController
        generic map(
            LENGTH => CHANNELS
        )
        port map(
            clk_i        => clk_i,
            reset_i      => reset_i,
            s_valid_i    => fifo_s_valid_reg,
            s_ready_o    => fifo_s_ready,
            m_valid_o    => m_valid_o,
            m_ready_i    => m_ready_i,
            read_index_o => fifo_read_index
        );

    -- La FIFO est bloquée lorsqu'une donnée est présente à son entrée et n'est
    -- pas encore acquittée.
    fifo_stalled <= fifo_s_valid_reg and not fifo_s_ready;

    fifo_data_reg(0) <= (fifo_s_data_reg, fifo_s_channel_reg, fifo_s_last_reg);

    p_fifo_data_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if fifo_s_ready = '1' then
                fifo_data_reg(1 to fifo_data_reg'high) <= fifo_data_reg(0 to fifo_data_reg'high - 1);
            end if;
        end if;
    end process p_fifo_data_reg;

    m_data_o    <= fifo_data_reg(fifo_read_index).data;
    m_channel_o <= fifo_data_reg(fifo_read_index).channel;
    m_last_o    <= fifo_data_reg(fifo_read_index).last;
end RTL;
