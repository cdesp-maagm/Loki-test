
architecture RTL of LokiModulator is
    -- La valeur courante du compteur de temps pour l'échantillonnage des oscillateurs.
    signal timer_reg : natural range 0 to CYCLES_PER_SAMPLE_MAX - 1;
    signal timer_next : positive range 1 to CYCLES_PER_SAMPLE_MAX;
    signal last_cycle : boolean;

    signal osc1_steps : integer_vector(0 to 0);
    signal osc2_steps : integer_vector(0 to 0);
    constant OSC_DELAYS : integer_vector(0 to 0) := (others => 0);

    signal osc_m_ready, osc1_m_valid, osc2_m_valid : std_logic;
    signal osc1_m_cos, osc1_m_sin : SinCosArray_t(0 to 0);
    signal osc2_m_cos, osc2_m_sin : SinCosArray_t(0 to 0);
begin
    timer_next <= timer_reg + 1;
    last_cycle <= timer_next = CYCLES_PER_SAMPLE_MAX or timer_next = cycles_per_sample_i;

    p_timer_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' or osc_m_ready = '1' then
                timer_reg <= 0;
            elsif not last_cycle then
                timer_reg <= timer_next;
            end if;
        end if;
    end process p_timer_reg;

    osc1_inst : entity work.Oscillator
        generic map(
            CHANNELS     => 1,
            LOOKUP_TABLE => LOOKUP_TABLE_1
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            restart_i => restart_i,
            steps_i   => osc1_steps,
            delays_i  => OSC_DELAYS,
            m_valid_o => osc1_m_valid,
            m_ready_i => osc_m_ready,
            m_cos_o   => osc1_m_cos,
            m_sin_o   => osc1_m_sin
        );

    osc1_steps(0) <= step1_i;

    osc2_inst : entity work.Oscillator
        generic map(
            CHANNELS     => 1,
            LOOKUP_TABLE => LOOKUP_TABLE_2
        )
        port map(
            clk_i     => clk_i,
            reset_i   => reset_i,
            restart_i => restart_i,
            steps_i   => osc2_steps,
            delays_i  => OSC_DELAYS,
            m_valid_o => osc2_m_valid,
            m_ready_i => osc_m_ready,
            m_cos_o   => osc2_m_cos,
            m_sin_o   => osc2_m_sin
        );

    osc2_steps(0)  <= step2_i;

    -- On ne bloque pas les oscillateurs lorsque l'interface maître est en attente.
    osc_m_ready <= osc1_m_valid and osc2_m_valid when last_cycle else '0';

    p_m_valid_phase_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                m_valid_o <= '0';
                m_phase_o <= to_sfixed(0, m_phase_o'left, m_phase_o'right);
            elsif osc_m_ready = '1' then
                m_valid_o <= '1';
                m_phase_o <= resize(gain1_i * osc1_m_sin(0) + gain2_i * osc2_m_sin(0), m_phase_o'left, m_phase_o'right);
            elsif m_ready_i = '1' then
                m_valid_o <= '0';
            end if;
        end if;
    end process p_m_valid_phase_o;
end RTL;
