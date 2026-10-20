
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.FIRFilter_pkg.all;

architecture SimulationSingleCycle of FIRFilter is
    signal s_ready                                 : std_logic       := '0';

    signal fifo_s_valid, fifo_s_ready, fifo_s_last : std_logic       := '0';
    signal fifo_s_channel                          : integer range 0 to CHANNELS - 1;
    signal fifo_s_data                             : sfixed(m_data_o'range);

    type FIFOData_t is record
        data                                       : sfixed(m_data_o'range);
        channel                                    : integer range 0 to CHANNELS - 1;
        last                                       : std_logic;
    end record FIFOData_t;
    type FIFODataArray_t is array(0 to CHANNELS) of FIFOData_t;
    signal fifo_data_reg                           : FIFODataArray_t := (others => ((others => '0'), 0, '0'));
    signal fifo_read_index                         : natural range 0 to CHANNELS;
begin
    s_ready   <= s_valid_i and (not fifo_s_valid or fifo_s_ready);
    s_ready_o <= s_ready;

    process
        constant DECIMATION : integer := COEFFICIENTS'length(1);
        variable phase : natural range 0 to DECIMATION - 1;

        constant TAPS_PER_STEP : positive := COEFFICIENTS'length(2);

        subtype Tap_t is sfixed(s_data_i'range);
        variable tap : Tap_t;

        type DelayArray_t is array(0 to CHANNELS - 1, 0 to DECIMATION - 1, 0 to TAPS_PER_STEP - 2) of Tap_t;
        variable delay_line : DelayArray_t := (others => (others => (others => to_sfixed(0, Tap_t'left, Tap_t'right))));

        subtype Acc_t is sfixed(s_data_i'left + GAIN_BITS downto s_data_i'right + Coefficient_t'right);
        type AccArray_t is array(0 to CHANNELS - 1) of Acc_t;
        variable acc : AccArray_t := (others => to_sfixed(0, Acc_t'left, Acc_t'right));
    begin
        wait until rising_edge(clk_i);

        if fifo_s_ready = '1' then
            fifo_s_valid <= '0';
        end if;

        if s_ready = '1' then
            -- Calculer la sortie partielle du filtre pour l'échantillon courant.
            for tap_index in 0 to TAPS_PER_STEP - 1 loop
                if tap_index = 0 then
                    tap := s_data_i;
                else
                    tap := delay_line(s_channel_i, phase, tap_index - 1);
                end if;
                acc(s_channel_i) := resize(acc(s_channel_i) + COEFFICIENTS(phase, tap_index) * tap, Acc_t'left, Acc_t'right);
            end loop;

            -- Décaler les échantillons mémorisés.
            for i in TAPS_PER_STEP - 2 downto 1 loop
                delay_line(s_channel_i, phase, i) := delay_line(s_channel_i, phase, i - 1);
            end loop;
            delay_line(s_channel_i, phase, 0) := s_data_i;

            if phase = DECIMATION - 1 then
                fifo_s_data    <= acc(s_channel_i)(Acc_t'left downto Acc_t'left - fifo_s_data'length + 1);
                fifo_s_channel <= s_channel_i;
                fifo_s_last    <= s_last_i;
                fifo_s_valid   <= '1';

                acc(s_channel_i) := to_sfixed(0, Acc_t'left, Acc_t'right);
            end if;

            if s_last_i = '1' then
                if phase = DECIMATION - 1 then
                    phase := 0;
                else
                    phase := phase + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- Barrière pour éviter les blocages.
    -- -------------------------------------------------------------------------

    fifo_inst : entity work.FIFOController
        generic map(
            LENGTH => CHANNELS
        )
        port map(
            clk_i        => clk_i,
            reset_i      => reset_i,
            s_valid_i    => fifo_s_valid,
            s_ready_o    => fifo_s_ready,
            m_valid_o    => m_valid_o,
            m_ready_i    => m_ready_i,
            read_index_o => fifo_read_index
        );

    fifo_data_reg(0) <= (fifo_s_data, fifo_s_channel, fifo_s_last);

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
end SimulationSingleCycle;
