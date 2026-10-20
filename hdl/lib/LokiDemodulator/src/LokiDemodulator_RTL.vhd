
architecture RTL of LokiDemodulator is
    subtype FIRData_t is sfixed(m_x_o'range);

    signal osc_timer_reg                              : natural range 0 to CYCLES_PER_SAMPLE_MAX - 1;
    signal osc_timer_next                             : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal osc_last_cycle                             : boolean;

    signal osc_steps                                  : integer_vector(0 to 2 * CHANNELS - 1);
    signal osc_m_ready, osc_m_valid                   : std_logic;
    signal osc_m_cos, osc_m_sin                       : SinCosArray_t(0 to 2 * CHANNELS - 1);

    signal mixer_s1_valid_reg, mixer_s1_ready         : std_logic;
    signal mixer_s1_cos_reg                           : SinCosArray_t(0 to 2 * CHANNELS - 1);
    signal mixer_m_valid, mixer_m_ready, mixer_m_last : std_logic;
    signal mixer_m_channel                            : natural range 0 to CHANNELS - 1;
    signal mixer_m_x, mixer_m_y                       : FIRData_t;

    signal fir1_is_y_reg                              : boolean;
    signal fir1_s_last, fir1_s_ready                  : std_logic;
    signal fir1_m_valid, fir1_m_last, fir1_m_ready    : std_logic;
    signal fir1_s_channel, fir1_m_channel             : natural range 0 to 2 * CHANNELS - 1;
    signal fir1_s_data, fir1_m_data                   : FIRData_t;

    signal fir2_is_y                                  : boolean;
    signal fir2_m_valid, fir2_m_ready                 : std_logic;
    signal fir2_m_channel                             : natural range 0 to 2 * CHANNELS - 1;
    signal fir2_m_data                                : FIRData_t;
begin
    -- -------------------------------------------------------------------------
    -- Oscillateurs.
    -- -------------------------------------------------------------------------

    osc_timer_next <= osc_timer_reg + 1;
    osc_last_cycle <= osc_timer_next = CYCLES_PER_SAMPLE_MAX or osc_timer_next >= cycles_per_sample_i;

    p_osc_timer_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or osc_m_ready = '1' then
                osc_timer_reg <= 0;
            elsif not osc_last_cycle then
                osc_timer_reg <= osc_timer_next;
            end if;
        end if;
    end process p_osc_timer_reg;

    osc_inst : entity work.Oscillator
        generic map(
            CHANNELS     => 2 * CHANNELS,
            LOOKUP_TABLE => LOOKUP_TABLE
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            restart_i => restart_i,
            steps_i   => osc_steps,
            delays_i  => osc_delays_i,
            m_valid_o => osc_m_valid,
            m_ready_i => osc_m_ready,
            m_cos_o   => osc_m_cos,
            m_sin_o   => osc_m_sin
        );

    osc_gen : for i in 0 to CHANNELS - 1 generate
        osc_steps(2 * i)     <= osc_step_i * 2;
        osc_steps(2 * i + 1) <= osc_step_i;
    end generate osc_gen;

    -- On ne bloque pas les oscillateurs lorsque l'interface maître est en attente.
    osc_m_ready <= osc_m_valid when osc_last_cycle else '0';

    p_mixer_s_valid_sin_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                mixer_s1_valid_reg <= '0';
            elsif osc_m_ready = '1' then
                mixer_s1_valid_reg <= '1';
                mixer_s1_cos_reg   <= osc_m_cos;
            elsif mixer_s1_ready = '1' then
                mixer_s1_valid_reg <= '0';
            end if;
        end if;
    end process p_mixer_s_valid_sin_reg;

    -- -------------------------------------------------------------------------
    -- Translation en fréquence.
    -- -------------------------------------------------------------------------

    mixer_inst : entity work.Mixer
        generic map(
            CHANNELS => CHANNELS
        )
        port map(
            clk_i        => clk_i,
            reset_i      => reset_i,
            s0_valid_i   => s_valid_i,
            s0_ready_o   => s_ready_o,
            s0_last_i    => s_last_i,
            s0_channel_i => s_channel_i,
            s0_power_i   => s_power_i,
            s1_valid_i   => mixer_s1_valid_reg,
            s1_ready_o   => mixer_s1_ready,
            s1_cos_i     => mixer_s1_cos_reg,
            m_valid_o    => mixer_m_valid,
            m_ready_i    => mixer_m_ready,
            m_last_o     => mixer_m_last,
            m_channel_o  => mixer_m_channel,
            m_x_o        => mixer_m_x,
            m_y_o        => mixer_m_y
        );

    -- -------------------------------------------------------------------------
    -- Filtrage.
    -- -------------------------------------------------------------------------

    -- Alterner X et Y pour chaque voie.
    p_fir1_is_y_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                fir1_is_y_reg <= false;
            elsif fir1_s_ready = '1' then
                fir1_is_y_reg <= not fir1_is_y_reg;
            end if;
        end if;
    end process p_fir1_is_y_reg;

    mixer_m_ready  <= fir1_s_ready            when fir1_is_y_reg else '0';
    fir1_s_last    <= mixer_m_last            when fir1_is_y_reg else '0';
    fir1_s_channel <= mixer_m_channel * 2 + 1 when fir1_is_y_reg else mixer_m_channel * 2;
    fir1_s_data    <= mixer_m_y               when fir1_is_y_reg else mixer_m_x;

    fir1_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => LOWPASS1_PARALLELISM,
            CHANNELS     => 2 * CHANNELS,
            GAIN_BITS    => LOWPASS1_GAIN_BITS,
            COEFFICIENTS => LOWPASS1_COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => mixer_m_valid,
            s_last_i    => fir1_s_last,
            s_ready_o   => fir1_s_ready,
            s_channel_i => fir1_s_channel,
            s_data_i    => fir1_s_data,
            m_valid_o   => fir1_m_valid,
            m_last_o    => fir1_m_last,
            m_ready_i   => fir1_m_ready,
            m_channel_o => fir1_m_channel,
            m_data_o    => fir1_m_data
        );

    fir2_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => LOWPASS2_PARALLELISM,
            CHANNELS     => 2 * CHANNELS,
            GAIN_BITS    => LOWPASS2_GAIN_BITS,
            COEFFICIENTS => LOWPASS2_COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => fir1_m_valid,
            s_last_i    => fir1_m_last,
            s_ready_o   => fir1_m_ready,
            s_channel_i => fir1_m_channel,
            s_data_i    => fir1_m_data,
            m_valid_o   => fir2_m_valid,
            m_last_o    => m_last_o,
            m_ready_i   => fir2_m_ready,
            m_channel_o => fir2_m_channel,
            m_data_o    => fir2_m_data
        );

    -- Acquitter la sortie du filtre numéro 2 :
    -- * tout de suite si la valeur de sortie est une composante X,
    -- * lorsque le consommateur acquitte si la valeur de sortie est une composante Y.
    fir2_is_y    <= fir2_m_channel mod 2 = 1;
    fir2_m_ready <= m_ready_i when fir2_is_y else fir2_m_valid;

    -- La donnée de sortie est valide lorsque le filtre produit une valeur Y.
    m_valid_o <= fir2_m_valid when fir2_is_y else '0';

    -- Mémoriser la composante X dès qu'elle sort du filtre 2.
    p_m_x_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if fir2_m_ready = '1' and not fir2_is_y then
                m_x_o <= fir2_m_data;
            end if;
        end if;
    end process p_m_x_o;

    m_channel_o <= fir2_m_channel / 2;
    m_y_o       <= fir2_m_data;
end RTL;
