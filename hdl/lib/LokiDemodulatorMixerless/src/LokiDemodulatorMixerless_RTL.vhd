
architecture RTL of LokiDemodulatorMixerless is
    signal timer_reg                                  : natural range 0 to CYCLES_PER_SAMPLE_MAX - 1;
    signal timer_next                                 : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal last_cycle                                 : boolean;

    signal sampler_s_valid_reg, sampler_s_ready       : std_logic;
    signal sampler_s_valid                            : std_logic_vector(0 to 1);
    signal sampler_m_valid                            : std_logic;
    signal sampler_m_ready                            : std_logic;
    signal sampler_m_last                             : std_logic;
    signal sampler_m_power                            : sfixed(s_power_i'range);
    signal sampler_m_channel                          : natural range 0 to CHANNELS - 1;

    constant LOWPASS_DECIMATION                       : positive := LOWPASS_COEFFICIENTS'length(1);
    type SamplerDataArray_t is array(0 to CHANNELS - 1, 0 to LOWPASS_DECIMATION - 1) of sfixed(sampler_m_power'range);
    signal sampler_m_power_reg                        : SamplerDataArray_t := (others => (others => to_sfixed(0, sampler_m_power)));

    signal lowpass_x_s_data, lowpass_y_s_data         : sfixed(sampler_m_power'range);

    signal lowpass_x_m_valid                          : std_logic;
    signal lowpass_x_m_last                           : std_logic;
    signal lowpass_x_m_ready                          : std_logic;
    signal lowpass_x_m_channel                        : natural range 0 to 2 * CHANNELS - 1;
    signal lowpass_x_m_data                           : sfixed(s_power_i'left + LOWPASS_GAIN_BITS downto s_power_i'right);

    signal lowpass_y_m_valid                          : std_logic;
    signal lowpass_y_m_last                           : std_logic;
    signal lowpass_y_m_ready                          : std_logic;
    signal lowpass_y_m_channel                        : natural range 0 to 2 * CHANNELS - 1;
    signal lowpass_y_m_data                           : sfixed(s_power_i'left + LOWPASS_GAIN_BITS downto s_power_i'right);

    type LowpassDelayArray_t is array(0 to CHANNELS - 1) of natural range 0 to LOWPASS_DECIMATION - 1;
    signal lowpass_delay_x_reg, lowpass_delay_y_reg   : LowpassDelayArray_t;
    signal lowpass_delay_x, lowpass_delay_y           : natural range 0 to LOWPASS_DECIMATION - 1;

    constant BANDPASS_DECIMATION                      : positive := BANDPASS_X_COEFFICIENTS'length(1);
    type LowpassDataArray_t is array(0 to CHANNELS - 1, 0 to BANDPASS_DECIMATION - 1) of sfixed(lowpass_x_m_data'range);
    signal lowpass_x_m_data_reg, lowpass_y_m_data_reg : LowpassDataArray_t := (others => (others => to_sfixed(0, lowpass_x_m_data)));

    type BandpassDelayArray_t is array(0 to CHANNELS - 1) of natural range 0 to BANDPASS_DECIMATION - 1;
    signal bandpass_delay_x_reg, bandpass_delay_y_reg : BandpassDelayArray_t;
    signal bandpass_delay_x, bandpass_delay_y         : natural range 0 to BANDPASS_DECIMATION - 1;

    signal bandpass_x_s_data, bandpass_y_s_data       : sfixed(lowpass_x_m_data'range);
begin
    -- -------------------------------------------------------------------------
    -- Échantillonnage.
    -- -------------------------------------------------------------------------

    timer_next <= timer_reg + 1;
    last_cycle <= timer_next = CYCLES_PER_SAMPLE_MAX or timer_next = cycles_per_sample_i;

    p_timer_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or last_cycle then
                timer_reg <= 0;
            else
                timer_reg <= timer_next;
            end if;
        end if;
    end process p_timer_reg;

    p_sampler_s_valid_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if last_cycle then
                sampler_s_valid_reg <= '1';
            elsif sampler_s_ready = '1' and s_last_i = '1' then
                sampler_s_valid_reg <= '0';
            end if;
        end if;
    end process p_sampler_s_valid_reg;

    sampler_s_valid <= s_valid_i & sampler_s_valid_reg;

    sampler_inst : entity work.StreamController
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            s_valid_i => sampler_s_valid,
            s_ready_o => sampler_s_ready,
            m_valid_o => sampler_m_valid,
            m_ready_i => sampler_m_ready
        );

    s_ready_o <= sampler_s_ready;

    p_sampler_data_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if sampler_s_ready = '1' then
                sampler_m_last                    <= s_last_i;
                sampler_m_channel                 <= s_channel_i;
                sampler_m_power                   <= s_power_i;
                lowpass_delay_x_reg(s_channel_i)  <= s_lowpass_delay_x_i;
                lowpass_delay_y_reg(s_channel_i)  <= s_lowpass_delay_y_i;
                bandpass_delay_x_reg(s_channel_i) <= s_bandpass_delay_x_i;
                bandpass_delay_y_reg(s_channel_i) <= s_bandpass_delay_y_i;
            end if;
        end if;
    end process p_sampler_data_reg;

    -- -------------------------------------------------------------------------
    -- Filtrage.
    -- -------------------------------------------------------------------------

    p_sampler_m_power_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if sampler_m_ready = '1' then
                for i in 1 to LOWPASS_DECIMATION - 2 loop
                    sampler_m_power_reg(sampler_m_channel, i) <= sampler_m_power_reg(sampler_m_channel, i - 1);
                end loop;
                sampler_m_power_reg(sampler_m_channel, 0) <= sampler_m_power;
            end if;
        end if;
    end process p_sampler_m_power_reg;

    lowpass_delay_x   <= lowpass_delay_x_reg(sampler_m_channel);
    lowpass_delay_y   <= lowpass_delay_y_reg(sampler_m_channel);
    lowpass_x_s_data <= sampler_m_power when lowpass_delay_x = 0 else sampler_m_power_reg(sampler_m_channel, lowpass_delay_x - 1);
    lowpass_y_s_data <= sampler_m_power when lowpass_delay_y = 0 else sampler_m_power_reg(sampler_m_channel, lowpass_delay_y - 1);

    -- Par contrainte, les filtres passe-bas ont le même nombre de coefficients
    -- et la même décimation.
    -- Seul lowpass_x_inst gère les signaux de synchronisation avec l'échantillonnage.
    lowpass_x_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => LOWPASS_PARALLELISM,
            CHANNELS     => CHANNELS,
            GAIN_BITS    => LOWPASS_GAIN_BITS,
            COEFFICIENTS => LOWPASS_COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => sampler_m_valid,
            s_last_i    => sampler_m_last,
            s_ready_o   => sampler_m_ready,
            s_channel_i => sampler_m_channel,
            s_data_i    => lowpass_x_s_data,
            m_valid_o   => lowpass_x_m_valid,
            m_last_o    => lowpass_x_m_last,
            m_ready_i   => lowpass_x_m_ready,
            m_channel_o => lowpass_x_m_channel,
            m_data_o    => lowpass_x_m_data
        );

    lowpass_y_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => LOWPASS_PARALLELISM,
            CHANNELS     => CHANNELS,
            GAIN_BITS    => LOWPASS_GAIN_BITS,
            COEFFICIENTS => LOWPASS_COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => sampler_m_valid,
            s_last_i    => sampler_m_last,
            s_ready_o   => open, -- Géré par lowpass_x_inst
            s_channel_i => sampler_m_channel,
            s_data_i    => lowpass_y_s_data,
            m_valid_o   => lowpass_y_m_valid,
            m_last_o    => lowpass_y_m_last,
            m_ready_i   => lowpass_y_m_ready,
            m_channel_o => lowpass_y_m_channel,
            m_data_o    => lowpass_y_m_data
        );

    p_lowpass_xy_m_data_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if lowpass_x_m_ready = '1' then
                for i in 1 to BANDPASS_DECIMATION - 2 loop
                    lowpass_x_m_data_reg(lowpass_x_m_channel, i) <= lowpass_x_m_data_reg(lowpass_x_m_channel, i - 1);
                end loop;
                lowpass_x_m_data_reg(lowpass_x_m_channel, 0) <= lowpass_x_m_data;
            end if;
            if lowpass_y_m_ready = '1' then
                for i in 1 to BANDPASS_DECIMATION - 2 loop
                    lowpass_y_m_data_reg(lowpass_y_m_channel, i) <= lowpass_y_m_data_reg(lowpass_y_m_channel, i - 1);
                end loop;
                lowpass_y_m_data_reg(lowpass_y_m_channel, 0) <= lowpass_y_m_data;
            end if;
        end if;
    end process p_lowpass_xy_m_data_reg;

    bandpass_delay_x  <= bandpass_delay_x_reg(lowpass_x_m_channel);
    bandpass_delay_y  <= bandpass_delay_y_reg(lowpass_y_m_channel);
    bandpass_x_s_data <= lowpass_x_m_data when bandpass_delay_x = 0 else lowpass_x_m_data_reg(lowpass_x_m_channel, bandpass_delay_x - 1);
    bandpass_y_s_data <= lowpass_y_m_data when bandpass_delay_y = 0 else lowpass_y_m_data_reg(lowpass_y_m_channel, bandpass_delay_y - 1);

    -- Par contrainte, les filtres passe-bandes ont le même nombre de
    -- coefficients et la même décimation.
    -- Seul bandpass_x_inst gère les signaux de synchronisation avec l'interface
    -- maître du démodulateur.
    bandpass_x_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => BANDPASS_PARALLELISM,
            CHANNELS     => CHANNELS,
            GAIN_BITS    => BANDPASS_X_GAIN_BITS,
            COEFFICIENTS => BANDPASS_X_COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => lowpass_x_m_valid,
            s_last_i    => lowpass_x_m_last,
            s_ready_o   => lowpass_x_m_ready,
            s_channel_i => lowpass_x_m_channel,
            s_data_i    => bandpass_x_s_data,
            m_valid_o   => m_valid_o,
            m_last_o    => m_last_o,
            m_ready_i   => m_ready_i,
            m_channel_o => m_channel_o,
            m_data_o    => m_x_o
        );

    bandpass_y_inst : entity work.FIRFilter
        generic map(
            PARALLELISM  => BANDPASS_PARALLELISM,
            CHANNELS     => CHANNELS,
            GAIN_BITS    => BANDPASS_Y_GAIN_BITS,
            COEFFICIENTS => BANDPASS_Y_COEFFICIENTS
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            s_valid_i   => lowpass_y_m_valid,
            s_last_i    => lowpass_y_m_last,
            s_ready_o   => lowpass_y_m_ready,
            s_channel_i => lowpass_y_m_channel,
            s_data_i    => bandpass_y_s_data,
            m_valid_o   => open, -- Géré par bandpass_x_inst.
            m_last_o    => open, -- Géré par bandpass_x_inst.
            m_ready_i   => m_ready_i,
            m_channel_o => open, -- Géré par bandpass_x_inst.
            m_data_o    => m_y_o
        );
end RTL;
