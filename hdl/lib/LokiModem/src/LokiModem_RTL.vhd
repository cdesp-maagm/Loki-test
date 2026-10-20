
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.float_pkg.all;
use work.fixed_pkg.all;
use work.Oscillator_pkg.all;
use work.LokiModem_pkg.all;
use work.LokiModem_cfg.all;

architecture RTL of LokiModem is
    alias modem_clk                              : std_logic is m_axis_aclk;
    signal modem_reset                           : std_logic;

    -- La commande de redémarrage des oscillateurs (accessible par l'interface AXI)
    signal restart_reg                           : std_logic;

    -- Le nombre d'échantillons traités par voie depuis le dernier restart (accessible par l'interface AXI)
    signal adc_sample_count_reg                  : natural;
    signal dac_sample_count_reg                  : natural;
    signal demod_sample_count_reg                : natural;

    -- La valeur moyenne du courant dans la diode laser.
    signal mod_dc_value_reg                      : std_logic_vector(MOD_DC_VALUE_WIDTH - 1 downto 0);

    signal mod_pga_gain_reg                      : std_logic_vector(MOD_PGA_GAIN_WIDTH - 1 downto 0);

    -- Le réglage de la fréquence d'échantillonnage du modulateur (accessible par l'interface AXI)
    signal mod_cycles_per_sample_reg             : positive range 1 to MOD_CYCLES_PER_SAMPLE_MAX;

    -- Les pas de progression des oscillateurs (accessibles par l'interface AXI).
    signal mod_step1_reg                         : natural range 0 to work.LokiModem_osc1_pkg.LOOKUP_TABLE'high;
    signal mod_step2_reg                         : natural range 0 to work.LokiModem_osc2_pkg.LOOKUP_TABLE'high;

    -- Le facteur appliqué aux sorties des oscillateurs pour la commande de la
    -- longueur d'onde du laser (accessible par l'interface AXI).
    signal mod_gain1_reg, mod_gain2_reg          : sfixed(S_AXI_DATA_WIDTH - MOD_GAIN_FRACTIONAL_WIDTH - 1 downto -MOD_GAIN_FRACTIONAL_WIDTH);
    signal mod_gain1, mod_gain2                  : sfixed(MOD_GAIN_INTEGER_WIDTH - 1 downto -MOD_GAIN_FRACTIONAL_WIDTH);

    -- La commande de modulation de longueur d'onde du laser.
    signal mod_m_phase                           : sfixed(MOD_PHASE_INTEGER_WIDTH - 1 downto -MOD_PHASE_FRACTIONAL_WIDTH);

    -- La composante continue à ajouter à la sortie du modulateur.
    signal mod_offset_reg                        : sfixed(S_AXI_DATA_WIDTH - MOD_PHASE_FRACTIONAL_WIDTH - 1 downto -MOD_PHASE_FRACTIONAL_WIDTH) := to_sfixed(0, S_AXI_DATA_WIDTH - MOD_PHASE_FRACTIONAL_WIDTH - 1, -MOD_PHASE_FRACTIONAL_WIDTH);

    -- La puissance mesurée par la diode laser.
    subtype ADCPower_t is sfixed(DEMOD_POWER_INTEGER_WIDTH - 1 downto -DEMOD_POWER_FRACTIONAL_WIDTH);
    type ADCPowerArray_t is array(0 to DEMOD_CHANNELS - 1) of ADCPower_t;
    signal adc_s_power_reg                       : ADCPower_t;

    constant DEMOD_ADC_MIN_MAX_FREQUENCY         : positive := 50;
    constant DEMOD_ADC_MIN_MAX_COUNT_MAX         : natural := CLK_FREQUENCY / DEMOD_ADC_MIN_MAX_FREQUENCY - 1;
    signal demod_adc_min_max_count_reg           : natural range 0 to DEMOD_ADC_MIN_MAX_COUNT_MAX;
    signal demod_adc_local_min_reg               : ADCPowerArray_t;
    signal demod_adc_local_max_reg               : ADCPowerArray_t;
    signal demod_adc_min_reg                     : ADCPowerArray_t;
    signal demod_adc_max_reg                     : ADCPowerArray_t;

    -- Le réglage de la fréquence d'échantillonnage du démodulateur (accessible par l'interface AXI)
    signal demod_cycles_per_sample_reg           : positive range 1 to DEMOD_CYCLES_PER_SAMPLE_MAX;

    -- Démodulateur (mixerless). Les délais en entrée des filtres du démodulateur (accessibles par l'interface AXI).
    signal demod_lowpass_delays_x_reg            : integer_vector(0 to DEMOD_CHANNELS - 1) := (others => 0);
    signal demod_lowpass_delays_y_reg            : integer_vector(0 to DEMOD_CHANNELS - 1) := (others => 0);
    signal demod_bandpass_delays_x_reg           : integer_vector(0 to DEMOD_CHANNELS - 1) := (others => 0);
    signal demod_bandpass_delays_y_reg           : integer_vector(0 to DEMOD_CHANNELS - 1) := (others => 0);

    -- Démodulateur (mixerless). Le délais appliqués au filtre pour le canal courant.
    signal demod_s_lowpass_delay_x               : natural range 0 to DEMOD_MIXERLESS_LOWPASS_DECIMATION - 1;
    signal demod_s_lowpass_delay_y               : natural range 0 to DEMOD_MIXERLESS_LOWPASS_DECIMATION - 1;
    signal demod_s_bandpass_delay_x              : natural range 0 to DEMOD_MIXERLESS_BANDPASS_DECIMATION - 1;
    signal demod_s_bandpass_delay_y              : natural range 0 to DEMOD_MIXERLESS_BANDPASS_DECIMATION - 1;

    -- Démodulateur (mixing). Le pas de progression de l'oscillateur.
    signal demod_osc_step_reg                    : natural range 0 to work.LokiModem_Mixing_osc3_pkg.LOOKUP_TABLE'high;

    -- Démodulateur (mixing). Les déphasages des oscillateurs pour chaque voie et chaque bande de fréquence.
    -- Ce signal contient une copies des registres demod_lowpass_delays_[xy]_reg
    signal demod_osc_delays                      : integer_vector(0 to 2 * DEMOD_CHANNELS - 1);

    -- La commande de désactivation du démodulateur pour accéder aux échantillons bruts.
    signal demod_bypass_reg                      : std_logic;

    -- Commande de passage en mode test.
    signal test_mode_reg                         : std_logic;

    -- Signal de test du DAC.
    signal dac_test_reg                          : unsigned(dac_m_data_o'length - 1 downto 0);

    -- Les coordonnées des points de l'ellipse après démodulation.
    signal demod_m_x, demod_m_y                  : sfixed(DEMOD_XY_INTEGER_WIDTH - 1 downto -DEMOD_XY_FRACTIONAL_WIDTH);

    -- Les signaux de synchronisation du bus d'entrée du démodulateur.
    signal adc_s_ready, adc_s_last               : std_logic;
    signal adc_s_channel_reg, adc_s_channel_next : natural range 0 to DEMOD_CHANNELS - 1;
    signal demod_s_ready, demod_s1_ready         : std_logic;

    signal bypass_m_valid_reg                    : std_logic;
    signal bypass_m_ready                        : std_logic;
    signal bypass_m_last_reg                     : std_logic;
    signal bypass_m_data_reg                     : std_logic_vector(m_axis_tdata'range);

    -- Les signaux de synchronisation du bus de sortie du démodulateur.
    signal demod_m_valid                         : std_logic;
    signal demod_m_ready                         : std_logic;
    signal demod_m_last                          : std_logic;
    signal demod_m_channel                       : natural range 0 to DEMOD_CHANNELS - 1;

    constant DEMOD_PACKET_COUNT_FIELD_WIDTH      : positive := m_axis_tdata'length - DEMOD_CHANNEL_OUTPUT_WIDTH - demod_m_x'length - demod_m_y'length;
    constant DEMOD_PACKET_COUNT_MAX              : natural := 2 ** DEMOD_PACKET_COUNT_FIELD_WIDTH - 1;
    signal demod_packet_count_reg                : natural range 0 to DEMOD_PACKET_COUNT_MAX;
    signal demod_packet_length_reg               : positive range 1 to DEMOD_PACKET_LENGTH_MAX;
    signal demod_packet_sample_count_reg         : natural range 0 to DEMOD_PACKET_LENGTH_MAX - 1;

    type DemodPGAGainArray_t is array(0 to DEMOD_CHANNELS - 1) of std_logic_vector(DEMOD_PGA_GAIN_WIDTH - 1 downto 0);
    signal demod_pga_gains_reg                   : DemodPGAGainArray_t;

    -- Les signaux de commande d'accès aux registres par l'interfaces AXI.
    signal axi_raddr, axi_waddr                  : std_logic_vector(7 downto 0);
    signal axi_wren, axi_rden                    : std_logic;

    signal clkmon_seconds                        : integer range 0 to CLKMON_SECONDS_MAX;
    signal clkmon_delta                          : integer range -CLKMON_DELTA_MAX to CLKMON_DELTA_MAX;
    signal clkmon_reset, clkmon_reset_reg        : std_logic;
begin
    -- Les blocs LokiModulator et LokiDemodulator ont un reset actif au niveau haut.
    -- On réutilise le reset de l'interface maître AXI stream, actif au niveau bas.
    modem_reset <= not m_axis_aresetn;

    -- -------------------------------------------------------------------------
    -- Modulateur
    -- -------------------------------------------------------------------------

    -- Les gains des oscillateurs du modulateur sont configurés par deux
    -- registres accessibles par l'interface esclave AXI.
    -- Ajuster la taille des valeurs de gains.
    mod_gain1 <= resize(mod_gain1_reg, mod_gain1);
    mod_gain2 <= resize(mod_gain2_reg, mod_gain2);

    -- Instance du modulateur.
    -- L'interface M0 pilote la sortie analogique.
    -- L'interface M1 pilote le démodulateur.
    mod_inst : entity work.LokiModulator
        generic map(
            CYCLES_PER_SAMPLE_MAX => MOD_CYCLES_PER_SAMPLE_MAX,
            LOOKUP_TABLE_1        => work.LokiModem_osc1_pkg.LOOKUP_TABLE,
            LOOKUP_TABLE_2        => work.LokiModem_osc2_pkg.LOOKUP_TABLE
        )
        port map(
            clk_i               => modem_clk,
            reset_i             => modem_reset,
            cycles_per_sample_i => mod_cycles_per_sample_reg,
            restart_i           => restart_reg,
            step1_i             => mod_step1_reg,
            step2_i             => mod_step2_reg,
            gain1_i             => mod_gain1,
            gain2_i             => mod_gain2,
            m_valid_o           => dac_m_valid_o,
            m_ready_i           => dac_m_ready_i,
            m_phase_o           => mod_m_phase
        );

    p_dac_test_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' then
                dac_test_reg <= (others => '0');
                -- dac_test_reg <= (0 => '1', others => '0');
            elsif test_mode_reg = '1' and dac_m_ready_i = '1' then
                dac_test_reg <= dac_test_reg + 1;
                -- dac_test_reg <= dac_test_reg(dac_test_reg'high - 1 downto 0) & dac_test_reg(dac_test_reg'high);
            end if;
        end if;
    end process p_dac_test_reg;

    -- Convertir la sortie du modulateur en binaire décalé si nécessaire,
    -- selon le format accepté par le DAC.
    p_dac_m_data_o : process(all)
        variable phase_offset : sfixed(mod_m_phase'range);
    begin
        if test_mode_reg = '1' then
            dac_m_data_o <= std_logic_vector(dac_test_reg);
        else
            phase_offset := resize(mod_m_phase + mod_offset_reg, phase_offset);
            dac_m_data_o <= to_std_logic_vector(phase_offset);
            if MOD_OFFSET_BINARY then
                dac_m_data_o(dac_m_data_o'high) <= not phase_offset(phase_offset'high);
            end if;
        end if;
    end process p_dac_m_data_o;

    -- Ce module ne fournit pas de mécanisme de contrôle du DAC.
    -- Le moule principale peut utiliser la période d'échantillonnage du modulateur
    -- pour générer une horloge à destination du DAC.
    dac_m_period_o <= mod_cycles_per_sample_reg;

    -- Compteur d'échantillons à destination du DAC.
    p_dac_sample_count_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' then
                dac_sample_count_reg <= 0;
            elsif dac_m_ready_i = '1' then
                dac_sample_count_reg <= dac_sample_count_reg + 1;
            end if;
        end if;
    end process p_dac_sample_count_reg;

    dac_m_dc_value_o <= mod_dc_value_reg;

    mod_pga_gain_o <= mod_pga_gain_reg;

    -- -------------------------------------------------------------------------
    -- Démodulateur
    -- -------------------------------------------------------------------------

    -- Passer au canal suivant à chaque fois que le démodulateur
    -- a traité l'échantillon du canal courant.
    p_adc_s_channel_power_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if adc_s_valid_i = '1' and adc_s_ready = '1' then
                adc_s_channel_reg <= adc_s_channel_next;
                adc_s_power_reg   <= sfixed(adc_s_data_i);
                if DEMOD_OFFSET_BINARY then
                    adc_s_power_reg(adc_s_power_reg'high) <= not adc_s_data_i(adc_s_data_i'high);
                end if;
            end if;
        end if;
    end process p_adc_s_channel_power_reg;

    -- Mémoriser les valeurs min et max de l'entrée
    p_demod_adc_min_max_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' or demod_adc_min_max_count_reg = DEMOD_ADC_MIN_MAX_COUNT_MAX then
                demod_adc_min_max_count_reg <= 0;
                demod_adc_local_min_reg <= (others => (others => '0'));
                demod_adc_local_max_reg <= (others => (others => '0'));
                for c in 0 to DEMOD_CHANNELS - 1 loop
                    demod_adc_min_reg(c) <= demod_adc_local_min_reg(c);
                    demod_adc_max_reg(c) <= demod_adc_local_max_reg(c);
                end loop;
            else
                demod_adc_min_max_count_reg <= demod_adc_min_max_count_reg + 1;
                if adc_s_valid_i = '1' and adc_s_ready = '1' then
                    if adc_s_power_reg < demod_adc_local_min_reg(adc_s_channel_reg) then
                        demod_adc_local_min_reg(adc_s_channel_reg) <= adc_s_power_reg;
                    end if;
                    if adc_s_power_reg > demod_adc_local_max_reg(adc_s_channel_reg) then
                        demod_adc_local_max_reg(adc_s_channel_reg) <= adc_s_power_reg;
                    end if;
                end if;
            end if;
        end if;
    end process p_demod_adc_min_max_reg;

    adc_s_last         <= '1' when adc_s_channel_reg = DEMOD_CHANNELS - 1 else '0';
    adc_s_channel_next <=  0  when adc_s_channel_reg = DEMOD_CHANNELS - 1 else adc_s_channel_reg + 1;
    adc_s_channel_o    <= adc_s_channel_next;

    -- Instance du démodulateur.
    -- L'interface S0 reçoit les échantillons de l'entrée analogique.
    -- L'interface S1 reçoit les sinusoïdes générées par le modulateur (interface M1 du modulateur).
    -- L'interface maître produit les échantillons I et Q démodulés.
    demod_gen : if DEMOD_CHANNELS = 0 generate
        adc_s_ready     <= '0';
        demod_m_valid   <= '0';
        demod_m_last    <= '0';
        demod_m_channel <= 0;
        demod_m_x       <= to_sfixed(0, demod_m_x);
        demod_m_y       <= to_sfixed(0, demod_m_y);
    elsif DEMOD_MIXERLESS generate
        demod_s_lowpass_delay_x  <= demod_lowpass_delays_x_reg(adc_s_channel_reg);
        demod_s_lowpass_delay_y  <= demod_lowpass_delays_y_reg(adc_s_channel_reg);
        demod_s_bandpass_delay_x <= demod_bandpass_delays_x_reg(adc_s_channel_reg);
        demod_s_bandpass_delay_y <= demod_bandpass_delays_y_reg(adc_s_channel_reg);

        demod_inst : entity work.LokiDemodulatorMixerless
            generic map(
                CHANNELS                => DEMOD_CHANNELS,
                CYCLES_PER_SAMPLE_MAX   => DEMOD_CYCLES_PER_SAMPLE_MAX,
                LOWPASS_PARALLELISM     => DEMOD_MIXERLESS_LOWPASS_PARALLELISM,
                LOWPASS_GAIN_BITS       => work.LokiModem_Mixerless_lowpass_pkg.GAIN_BITS,
                LOWPASS_COEFFICIENTS    => work.LokiModem_Mixerless_lowpass_pkg.COEFFICIENTS,
                BANDPASS_PARALLELISM    => DEMOD_MIXERLESS_BANDPASS_PARALLELISM,
                BANDPASS_X_GAIN_BITS    => work.LokiModem_Mixerless_bandpassX_pkg.GAIN_BITS,
                BANDPASS_X_COEFFICIENTS => work.LokiModem_Mixerless_bandpassX_pkg.COEFFICIENTS,
                BANDPASS_Y_GAIN_BITS    => work.LokiModem_Mixerless_bandpassY_pkg.GAIN_BITS,
                BANDPASS_Y_COEFFICIENTS => work.LokiModem_Mixerless_bandpassY_pkg.COEFFICIENTS
            )
            port map(
                clk_i                => modem_clk,
                reset_i              => modem_reset,
                cycles_per_sample_i  => demod_cycles_per_sample_reg,
                s_valid_i            => adc_s_valid_i,
                s_ready_o            => adc_s_ready,
                s_last_i             => adc_s_last,
                s_channel_i          => adc_s_channel_reg,
                s_lowpass_delay_x_i  => demod_s_lowpass_delay_x,
                s_lowpass_delay_y_i  => demod_s_lowpass_delay_y,
                s_bandpass_delay_x_i => demod_s_bandpass_delay_x,
                s_bandpass_delay_y_i => demod_s_bandpass_delay_y,
                s_power_i            => adc_s_power_reg,
                m_valid_o            => demod_m_valid,
                m_ready_i            => demod_m_ready,
                m_last_o             => demod_m_last,
                m_channel_o          => demod_m_channel,
                m_x_o                => demod_m_x,
                m_y_o                => demod_m_y
            );
    else generate
        demod_osc_delays_gen: for c in 0 to DEMOD_CHANNELS - 1 generate
            demod_osc_delays(c * 2)     <= demod_lowpass_delays_x_reg(c);
            demod_osc_delays(c * 2 + 1) <= demod_lowpass_delays_y_reg(c);
        end generate demod_osc_delays_gen;

        demod_inst : entity work.LokiDemodulator
            generic map(
                CHANNELS                => DEMOD_CHANNELS,
                CYCLES_PER_SAMPLE_MAX   => DEMOD_CYCLES_PER_SAMPLE_MAX,
                LOOKUP_TABLE            => work.LokiModem_Mixing_osc3_pkg.LOOKUP_TABLE,
                LOWPASS1_PARALLELISM    => DEMOD_MIXING_LOWPASS1_PARALLELISM,
                LOWPASS1_GAIN_BITS      => work.LokiModem_Mixing_lowpass1_pkg.GAIN_BITS,
                LOWPASS1_COEFFICIENTS   => work.LokiModem_Mixing_lowpass1_pkg.COEFFICIENTS,
                LOWPASS2_PARALLELISM    => DEMOD_MIXING_LOWPASS2_PARALLELISM,
                LOWPASS2_GAIN_BITS      => work.LokiModem_Mixing_lowpass2_pkg.GAIN_BITS,
                LOWPASS2_COEFFICIENTS   => work.LokiModem_Mixing_lowpass2_pkg.COEFFICIENTS
            )
            port map(
                clk_i               => modem_clk,
                reset_i             => modem_reset,
                cycles_per_sample_i => demod_cycles_per_sample_reg,
                osc_step_i          => demod_osc_step_reg,
                osc_delays_i        => demod_osc_delays,
                restart_i           => restart_reg,
                s_valid_i           => adc_s_valid_i,
                s_ready_o           => adc_s_ready,
                s_last_i            => adc_s_last,
                s_channel_i         => adc_s_channel_reg,
                s_power_i           => adc_s_power_reg,
                m_valid_o           => demod_m_valid,
                m_ready_i           => demod_m_ready,
                m_last_o            => demod_m_last,
                m_channel_o         => demod_m_channel,
                m_x_o               => demod_m_x,
                m_y_o               => demod_m_y
            );
    end generate demod_gen;

    adc_s_ready_o <= adc_s_ready;

    -- Compteur d'échantillons en provenance de l'ADC.
    p_adc_sample_count_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' then
                adc_sample_count_reg <= 0;
            elsif adc_s_valid_i = '1' and adc_s_ready = '1' and adc_s_last = '1' then
                adc_sample_count_reg <= adc_sample_count_reg + 1;
            end if;
        end if;
    end process p_adc_sample_count_reg;

    -- Compteur d'échantillons produits par le démodulateur.
    p_demod_sample_count_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' then
                demod_sample_count_reg <= 0;
            elsif demod_m_valid = '1' and demod_m_ready = '1' and demod_m_last = '1' then
                demod_sample_count_reg <= demod_sample_count_reg + 1;
            end if;
        end if;
    end process p_demod_sample_count_reg;

    -- Compteur de paquets produits par le démodulateur.
    p_demod_packet_sample_count_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' then
                demod_packet_sample_count_reg <= 0;
                demod_packet_count_reg        <= 0;
            elsif (demod_bypass_reg = '0' and demod_m_valid  = '1'     and demod_m_ready  = '1') or
                  (demod_bypass_reg = '1' and bypass_m_valid_reg = '1' and bypass_m_ready = '1') then
                if demod_packet_sample_count_reg >= demod_packet_length_reg - 1 then
                    demod_packet_sample_count_reg <= 0;
                    if demod_packet_count_reg = DEMOD_PACKET_COUNT_MAX then
                        demod_packet_count_reg <= 0;
                    else
                        demod_packet_count_reg <= demod_packet_count_reg + 1;
                    end if;
                else
                    demod_packet_sample_count_reg <= demod_packet_sample_count_reg + 1;
                end if;
            end if;
        end if;
    end process p_demod_packet_sample_count_reg;

    adc_s_period_o <= demod_cycles_per_sample_reg;

    demod_pga_gains_gen : for i in 0 to DEMOD_CHANNELS - 1 generate
        demod_pga_gains_o((i + 1) * DEMOD_PGA_GAIN_WIDTH - 1 downto i * DEMOD_PGA_GAIN_WIDTH) <= demod_pga_gains_reg(i);
    end generate;

    -- -------------------------------------------------------------------------
    -- Transmission des résultats par l'interface maître AXI stream.
    -- -------------------------------------------------------------------------

    -- Gestion du bypass du démodulateur.
    p_bypass_reg : process(modem_clk)
    begin
        if rising_edge(modem_clk) then
            if modem_reset = '1' or restart_reg = '1' then
                bypass_m_valid_reg <= '0';
            elsif adc_s_valid_i = '1' and adc_s_ready = '1' then
                bypass_m_valid_reg <= '1';
                bypass_m_data_reg  <= std_logic_vector(to_unsigned(demod_packet_count_reg, DEMOD_PACKET_COUNT_FIELD_WIDTH)) &
                                      std_logic_vector(to_unsigned(adc_s_channel_reg, DEMOD_CHANNEL_OUTPUT_WIDTH)) &
                                      std_logic_vector(to_unsigned(0, demod_m_x'length)) &
                                      to_std_logic_vector(resize(adc_s_power_reg, demod_m_y));
                bypass_m_last_reg  <= '1' when demod_packet_sample_count_reg >= demod_packet_length_reg - 1 else '0';
            elsif bypass_m_ready = '1' then
                bypass_m_valid_reg <= '0';
            end if;
        end if;
    end process p_bypass_reg;

    p_m_axis : process(all)
    begin
        if demod_bypass_reg = '0' then
            m_axis_tvalid  <= demod_m_valid;
            m_axis_tdata   <= std_logic_vector(to_unsigned(demod_packet_count_reg, DEMOD_PACKET_COUNT_FIELD_WIDTH)) &
                              std_logic_vector(to_unsigned(demod_m_channel, DEMOD_CHANNEL_OUTPUT_WIDTH)) &
                              to_std_logic_vector(demod_m_x) &
                              to_std_logic_vector(demod_m_y);
            m_axis_tlast   <= '1' when demod_packet_sample_count_reg >= demod_packet_length_reg - 1 else '0';
            demod_m_ready  <= m_axis_tready;
            bypass_m_ready <= bypass_m_valid_reg;
        else
            m_axis_tvalid  <= bypass_m_valid_reg;
            m_axis_tdata   <= bypass_m_data_reg;
            m_axis_tlast   <= bypass_m_last_reg;
            demod_m_ready  <= demod_m_valid;
            bypass_m_ready <= m_axis_tready;
        end if;
    end process p_m_axis;

    m_axis_tstrb <= (others => '1');
    m_axis_tkeep <= (others => '1');

    -- -------------------------------------------------------------------------
    -- Module de surveillance de l'horloge.
    -- -------------------------------------------------------------------------

    clkmon_inst : entity work.ClockMonitor
        generic map(
            CLK_FREQUENCY => CLK_FREQUENCY,
            SECONDS_MAX   => CLKMON_SECONDS_MAX,
            DELTA_MAX     => CLKMON_DELTA_MAX
        )
        port map(
            clk_i     => modem_clk,
            reset_i   => clkmon_reset,
            pps_i     => pps_i,
            seconds_o => clkmon_seconds,
            delta_o   => clkmon_delta
        );

    clkmon_reset <= modem_reset or clkmon_reset_reg;

    -- -------------------------------------------------------------------------
    -- Accès aux registres de configuration par l'interface esclave AXI.
    -- -------------------------------------------------------------------------

    p_s_axi_rdata : process(s_axi_aclk) is
        variable addr          : natural range 0 to 2 ** axi_waddr'length - 1;
        variable reg_id        : Register_t;
        variable delay_channel : natural range 0 to DEMOD_CHANNELS - 1;
        variable delay_reg_id  : DemodChannelConfigRegister_t;

        function to_std_logic(a : boolean) return std_logic is
        begin
            if a then
                return '1';
            else
                return '0';
            end if;
        end to_std_logic;

        procedure bus_read(a : integer) is
        begin
            s_axi_rdata <= std_logic_vector(to_signed(a, s_axi_rdata'length));
        end bus_read;

        procedure bus_read(a : sfixed) is
        begin
            s_axi_rdata <= to_std_logic_vector(resize(a, s_axi_rdata'left + a'right, a'right));
        end bus_read;

        procedure bus_read(a : real) is
        begin
            s_axi_rdata <= to_std_logic_vector(to_float(a));
        end bus_read;

        function if_mixerless(a, b : natural) return natural is
        begin
            if DEMOD_MIXERLESS then
                return a;
            else
                return b;
            end if;
        end if_mixerless;
    begin
        if rising_edge (s_axi_aclk) then
            if s_axi_aresetn = '0' then
                s_axi_rdata <= (others => '0');
            elsif axi_rden = '1' then
                s_axi_rdata <= (others => '0');
                addr := to_integer(unsigned(axi_raddr));
                if addr <= Register_t'pos(Register_t'high) then
                    reg_id := Register_t'val(addr);
                    case reg_id is
                        when REG_CLK_FREQUENCY                => bus_read(CLK_FREQUENCY);
                        when REG_CONTROL                      => s_axi_rdata <= (0      => restart_reg,
                                                                                 1      => demod_bypass_reg,
                                                                                 2      => to_std_logic(DEMOD_MIXERLESS),
                                                                                 3      => test_mode_reg,
                                                                                 others => '0');
                        when REG_DAC_SAMPLE_COUNT             => bus_read(dac_sample_count_reg);
                        when REG_ADC_SAMPLE_COUNT             => bus_read(adc_sample_count_reg);

                        when REG_MOD_SAMPLE_FREQUENCY_REF     => bus_read(MOD_SAMPLE_FREQUENCY_REF);
                        when REG_MOD_CYCLES_PER_SAMPLE_MAX    => bus_read(MOD_CYCLES_PER_SAMPLE_MAX);
                        when REG_MOD_OSC1_WAVE_FREQUENCY_MIN  => bus_read(MOD_OSC1_WAVE_FREQUENCY_MIN);
                        when REG_MOD_OSC2_WAVE_FREQUENCY_MIN  => bus_read(MOD_OSC2_WAVE_FREQUENCY_MIN);
                        when REG_MOD_GAIN_INTEGER_WIDTH       => bus_read(MOD_GAIN_INTEGER_WIDTH);
                        when REG_MOD_GAIN_FRACTIONAL_WIDTH    => bus_read(MOD_GAIN_FRACTIONAL_WIDTH);
                        when REG_MOD_PHASE_AMPLITUDE_MAX      => bus_read(MOD_PHASE_AMPLITUDE_MAX);
                        when REG_MOD_PHASE_INTEGER_WIDTH      => bus_read(MOD_PHASE_INTEGER_WIDTH);
                        when REG_MOD_PHASE_FRACTIONAL_WIDTH   => bus_read(MOD_PHASE_FRACTIONAL_WIDTH);
                        when REG_MOD_CYCLES_PER_SAMPLE        => bus_read(mod_cycles_per_sample_reg);
                        when REG_MOD_OSC1_STEP                => bus_read(mod_step1_reg);
                        when REG_MOD_OSC1_GAIN                => bus_read(mod_gain1_reg);
                        when REG_MOD_OSC2_STEP                => bus_read(mod_step2_reg);
                        when REG_MOD_OSC2_GAIN                => bus_read(mod_gain2_reg);
                        when REG_MOD_OFFSET                   => bus_read(mod_offset_reg);
                        when REG_MOD_DC_VALUE_MAX             => bus_read(MOD_DC_VALUE_MAX);
                        when REG_MOD_DC_VALUE_WIDTH           => bus_read(MOD_DC_VALUE_WIDTH);
                        when REG_MOD_DC_VALUE                 => s_axi_rdata(MOD_DC_VALUE_WIDTH - 1 downto 0) <= mod_dc_value_reg;
                        when REG_MOD_PGA_GAIN_WIDTH           => bus_read(MOD_PGA_GAIN_WIDTH);
                        when REG_MOD_PGA_GAIN                 => s_axi_rdata(MOD_PGA_GAIN_WIDTH - 1 downto 0) <= mod_pga_gain_reg;
                        when REG_DEMOD_CHANNELS               => bus_read(DEMOD_CHANNELS);
                        when REG_DEMOD_CHANNEL_OUTPUT_WIDTH   => bus_read(DEMOD_CHANNEL_OUTPUT_WIDTH);
                        when REG_DEMOD_POWER_INTEGER_WIDTH    => bus_read(DEMOD_POWER_INTEGER_WIDTH);
                        when REG_DEMOD_POWER_FRACTIONAL_WIDTH => bus_read(DEMOD_POWER_FRACTIONAL_WIDTH);
                        when REG_DEMOD_SAMPLE_FREQUENCY_REF   => bus_read(DEMOD_SAMPLE_FREQUENCY_REF);
                        when REG_DEMOD_CYCLES_PER_SAMPLE_MAX  => bus_read(DEMOD_CYCLES_PER_SAMPLE_MAX);
                        when REG_DEMOD_OSC_WAVE_FREQUENCY_MIN => bus_read(if_mixerless(0, DEMOD_MIXING_OSC_WAVE_FREQUENCY_MIN));
                        when REG_DEMOD_FIR1_DECIMATION        => bus_read(if_mixerless(DEMOD_MIXERLESS_LOWPASS_DECIMATION, DEMOD_MIXING_LOWPASS1_DECIMATION));
                        when REG_DEMOD_FIR1_LENGTH            => bus_read(if_mixerless(DEMOD_MIXERLESS_LOWPASS_DECIMATION * work.LokiModem_Mixerless_lowpass_pkg.COEFFICIENTS'length(2),
                                                                                       DEMOD_MIXING_LOWPASS1_DECIMATION   * work.LokiModem_Mixing_lowpass1_pkg.COEFFICIENTS'length(2)));
                        when REG_DEMOD_FIR1_BANDWIDTH         => bus_read(if_mixerless(DEMOD_MIXERLESS_LOWPASS_CUTOFF_FREQUENCY_HIGH - DEMOD_MIXERLESS_LOWPASS_CUTOFF_FREQUENCY_LOW,
                                                                                       DEMOD_MIXING_LOWPASS1_CUTOFF_FREQUENCY_HIGH   - DEMOD_MIXING_LOWPASS1_CUTOFF_FREQUENCY_LOW));
                        when REG_DEMOD_FIR2_DECIMATION        => bus_read(if_mixerless(DEMOD_MIXERLESS_BANDPASS_DECIMATION, DEMOD_MIXING_LOWPASS2_DECIMATION));
                        when REG_DEMOD_FIR2_LENGTH            => bus_read(if_mixerless(DEMOD_MIXERLESS_BANDPASS_DECIMATION * work.LokiModem_Mixerless_bandpassX_pkg.COEFFICIENTS'length(2),
                                                                                       DEMOD_MIXING_LOWPASS2_DECIMATION * work.LokiModem_Mixing_lowpass2_pkg.COEFFICIENTS'length(2)));
                        when REG_DEMOD_FIR2_BANDWIDTH         => bus_read(if_mixerless(DEMOD_MIXERLESS_BANDPASS_X_CUTOFF_FREQUENCY_HIGH - DEMOD_MIXERLESS_BANDPASS_X_CUTOFF_FREQUENCY_LOW,
                                                                                       DEMOD_MIXING_LOWPASS2_CUTOFF_FREQUENCY_HIGH   - DEMOD_MIXING_LOWPASS2_CUTOFF_FREQUENCY_LOW));
                        when REG_DEMOD_XY_INTEGER_WIDTH       => bus_read(DEMOD_XY_INTEGER_WIDTH);
                        when REG_DEMOD_XY_FRACTIONAL_WIDTH    => bus_read(DEMOD_XY_FRACTIONAL_WIDTH);
                        when REG_DEMOD_PACKET_LENGTH_MAX      => bus_read(DEMOD_PACKET_LENGTH_MAX);
                        when REG_DEMOD_SAMPLE_COUNT           => bus_read(demod_sample_count_reg);
                        when REG_DEMOD_CYCLES_PER_SAMPLE      => bus_read(demod_cycles_per_sample_reg);
                        when REG_DEMOD_OSC_STEP               => bus_read(demod_osc_step_reg);
                        when REG_DEMOD_PACKET_LENGTH          => bus_read(demod_packet_length_reg);
                        when REG_CLKMON_SECONDS               => bus_read(clkmon_seconds);
                        when REG_CLKMON_DELTA                 => bus_read(clkmon_delta);
                        when REG_GPIO                         => s_axi_rdata(GPIO_WIDTH - 1 downto 0) <= gpio_i;
                        when others                           =>
                    end case;
                elsif addr >= REG_DEMOD_CHANNEL_CFG and addr < REG_DEMOD_CHANNEL_CFG + REG_DEMOD_CHANNEL_CFG_COUNT * DEMOD_CHANNELS then
                    delay_channel := (addr - REG_DEMOD_CHANNEL_CFG) / REG_DEMOD_CHANNEL_CFG_COUNT;
                    delay_reg_id     := DemodChannelConfigRegister_t'val((addr - REG_DEMOD_CHANNEL_CFG) mod REG_DEMOD_CHANNEL_CFG_COUNT);
                    case delay_reg_id is
                        when REG_DEMOD_DELAY_LOWPASS_X  => bus_read(demod_lowpass_delays_x_reg(delay_channel));
                        when REG_DEMOD_DELAY_LOWPASS_Y  => bus_read(demod_lowpass_delays_y_reg(delay_channel));
                        when REG_DEMOD_DELAY_BANDPASS_X => bus_read(demod_bandpass_delays_x_reg(delay_channel));
                        when REG_DEMOD_DELAY_BANDPASS_Y => bus_read(demod_bandpass_delays_y_reg(delay_channel));
                        when REG_DEMOD_PGA_GAIN         => s_axi_rdata(DEMOD_PGA_GAIN_WIDTH - 1 downto 0) <= demod_pga_gains_reg(delay_channel);
                        when REG_DEMOD_ADC_MIN          => bus_read(demod_adc_min_reg(delay_channel));
                        when REG_DEMOD_ADC_MAX          => bus_read(demod_adc_max_reg(delay_channel));
                        when others                     =>
                    end case;
                end if;
            end if;
        end if;
    end process p_s_axi_rdata;

    p_axi_reg : process(s_axi_aclk)
        variable addr          : natural range 0 to 2 ** axi_waddr'length - 1;
        variable reg_id        : Register_t;
        variable delay_channel : natural range 0 to DEMOD_CHANNELS - 1;
        variable delay_reg_id  : DemodChannelConfigRegister_t;

        function from_bus(data : std_logic_vector; a, b : integer) return integer is
            variable v : natural := to_integer(unsigned(data));
        begin
            if v < a then
                return a;
            elsif v > b then
                return b;
            else
                return v;
            end if;
        end from_bus;
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                restart_reg                 <= '0';
                clkmon_reset_reg            <= '0';
                test_mode_reg               <= '0';
                mod_cycles_per_sample_reg   <= CLK_FREQUENCY / MOD_SAMPLE_FREQUENCY_REF;
                mod_step1_reg               <= 0;
                mod_gain1_reg               <= to_sfixed(0, mod_gain1_reg);
                mod_step2_reg               <= 0;
                mod_gain2_reg               <= to_sfixed(0, mod_gain2_reg);
                demod_bypass_reg            <= '0';
                demod_cycles_per_sample_reg <= CLK_FREQUENCY / DEMOD_SAMPLE_FREQUENCY_REF;
                demod_lowpass_delays_x_reg  <= (others => 0);
                demod_lowpass_delays_y_reg  <= (others => 0);
                demod_bandpass_delays_x_reg <= (others => 0);
                demod_bandpass_delays_y_reg <= (others => 0);
                demod_packet_length_reg     <= DEMOD_PACKET_LENGTH_MAX;
                demod_pga_gains_reg         <= (others => (others => '0'));
            elsif axi_wren = '1' then
                addr := to_integer(unsigned(axi_waddr));
                if addr <= Register_t'pos(Register_t'high) then
                    reg_id := Register_t'val(addr);
                    case reg_id is
                        when REG_CONTROL                 => restart_reg                 <= s_axi_wdata(0);
                                                            demod_bypass_reg            <= s_axi_wdata(1);
                                                            test_mode_reg               <= s_axi_wdata(3);
                        when REG_MOD_CYCLES_PER_SAMPLE   => mod_cycles_per_sample_reg   <= from_bus(s_axi_wdata, 1, MOD_CYCLES_PER_SAMPLE_MAX);
                        when REG_MOD_OSC1_STEP           => mod_step1_reg               <= from_bus(s_axi_wdata, 0, work.LokiModem_osc1_pkg.LOOKUP_TABLE'high);
                        when REG_MOD_OSC1_GAIN           => mod_gain1_reg               <= sfixed(s_axi_wdata);
                        when REG_MOD_OSC2_STEP           => mod_step2_reg               <= from_bus(s_axi_wdata, 0, work.LokiModem_osc2_pkg.LOOKUP_TABLE'high);
                        when REG_MOD_OSC2_GAIN           => mod_gain2_reg               <= sfixed(s_axi_wdata);
                        when REG_MOD_OFFSET              => mod_offset_reg              <= sfixed(s_axi_wdata);
                        when REG_MOD_DC_VALUE            => mod_dc_value_reg            <= s_axi_wdata(MOD_DC_VALUE_WIDTH - 1 downto 0);
                        when REG_MOD_PGA_GAIN            => mod_pga_gain_reg            <= s_axi_wdata(MOD_PGA_GAIN_WIDTH - 1 downto 0);
                        when REG_DEMOD_CYCLES_PER_SAMPLE => demod_cycles_per_sample_reg <= from_bus(s_axi_wdata, 1, DEMOD_CYCLES_PER_SAMPLE_MAX);
                        when REG_DEMOD_OSC_STEP          => demod_osc_step_reg          <= from_bus(s_axi_wdata, 0, work.LokiModem_Mixing_osc3_pkg.LOOKUP_TABLE'high);
                        when REG_DEMOD_PACKET_LENGTH     => demod_packet_length_reg     <= from_bus(s_axi_wdata, 1, DEMOD_PACKET_LENGTH_MAX);
                        when REG_CLKMON_SECONDS          => clkmon_reset_reg            <= '1';
                        when REG_CLKMON_DELTA            => clkmon_reset_reg            <= '1';
                        when REG_GPIO                    => gpio_o                      <= s_axi_wdata(GPIO_WIDTH - 1 downto 0);
                        when others                      =>
                    end case;
                elsif addr >= REG_DEMOD_CHANNEL_CFG and addr < REG_DEMOD_CHANNEL_CFG + REG_DEMOD_CHANNEL_CFG_COUNT * DEMOD_CHANNELS then
                    delay_channel := (addr - REG_DEMOD_CHANNEL_CFG) / REG_DEMOD_CHANNEL_CFG_COUNT;
                    delay_reg_id  := DemodChannelConfigRegister_t'val((addr - REG_DEMOD_CHANNEL_CFG) mod REG_DEMOD_CHANNEL_CFG_COUNT);
                    case delay_reg_id is
                        when REG_DEMOD_DELAY_LOWPASS_X  => demod_lowpass_delays_x_reg(delay_channel)  <= to_integer(unsigned(s_axi_wdata));
                        when REG_DEMOD_DELAY_LOWPASS_Y  => demod_lowpass_delays_y_reg(delay_channel)  <= to_integer(unsigned(s_axi_wdata));
                        when REG_DEMOD_DELAY_BANDPASS_X => demod_bandpass_delays_x_reg(delay_channel) <= to_integer(unsigned(s_axi_wdata));
                        when REG_DEMOD_DELAY_BANDPASS_Y => demod_bandpass_delays_y_reg(delay_channel) <= to_integer(unsigned(s_axi_wdata));
                        when REG_DEMOD_PGA_GAIN         => demod_pga_gains_reg(delay_channel)         <= s_axi_wdata(DEMOD_PGA_GAIN_WIDTH - 1 downto 0);
                        when others                     =>
                    end case;
                end if;
            else
                -- Remise à zéro automatique au cycle suivant l'écriture.
                restart_reg      <= '0';
                clkmon_reset_reg <= '0';
            end if;
        end if;
    end process p_axi_reg;

    -- -------------------------------------------------------------------------
    -- Gestion de l'interface esclave AXI.
    -- -------------------------------------------------------------------------

    axi_slave : entity work.AXISlave(RTL)
        generic map(
            S_AXI_DATA_WIDTH => S_AXI_DATA_WIDTH,
            S_AXI_ADDR_WIDTH => S_AXI_ADDR_WIDTH
        )
        port map(
            s_axi_aclk    => s_axi_aclk,
            s_axi_aresetn => s_axi_aresetn,
            s_axi_awaddr  => s_axi_awaddr,
            s_axi_awvalid => s_axi_awvalid,
            s_axi_awready => s_axi_awready,
            s_axi_wvalid  => s_axi_wvalid,
            s_axi_wready  => s_axi_wready,
            s_axi_bresp   => s_axi_bresp,
            s_axi_bvalid  => s_axi_bvalid,
            s_axi_bready  => s_axi_bready,
            s_axi_araddr  => s_axi_araddr,
            s_axi_arvalid => s_axi_arvalid,
            s_axi_arready => s_axi_arready,
            s_axi_rresp   => s_axi_rresp,
            s_axi_rvalid  => s_axi_rvalid,
            s_axi_rready  => s_axi_rready,
            reg_raddr_o   => axi_raddr,
            reg_waddr_o   => axi_waddr,
            reg_wren_o    => axi_wren,
            reg_rden_o    => axi_rden
        );
end RTL;
