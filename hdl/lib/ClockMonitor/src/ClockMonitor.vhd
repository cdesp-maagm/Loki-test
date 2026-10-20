
library ieee;
use ieee.std_logic_1164.all;

entity ClockMonitor is
    generic(
        CLK_FREQUENCY : positive;
        SECONDS_MAX   : positive;
        DELTA_MAX     : positive
    );
    port(
        clk_i     : in  std_logic;
        reset_i   : in  std_logic;
        pps_i     : in  std_logic;
        seconds_o : out integer range 0 to SECONDS_MAX;
        delta_o   : out integer range -DELTA_MAX to DELTA_MAX
    );
end ClockMonitor;

architecture RTL of ClockMonitor is
    signal pps_reg                   : std_logic_vector(0 to 1);
    signal busy_reg, tick            : std_logic;
    signal seconds_reg, seconds_next : integer range 0 to SECONDS_MAX;
    signal clk_counter_reg, delta    : integer range -DELTA_MAX to CLK_FREQUENCY + DELTA_MAX - 1;
begin
    pps_sync_inst : entity work.InputSynchronizer
        generic map(
            WIDTH => 1
        )
        port map(
            clk_i     => clk_i,
            data_i(0) => pps_i,
            data_o(0) => pps_reg(0)
        );

    p_pps_reg1 : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                pps_reg(1) <= '1';
            else
                pps_reg(1) <= pps_reg(0);
            end if;
        end if;
    end process p_pps_reg1;

    tick <= pps_reg(0) and not pps_reg(1);

    p_busy_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                busy_reg <= '0';
            elsif tick = '1' then
                busy_reg <= '1';
            end if;
        end if;
    end process p_busy_reg;

    seconds_next <= seconds_reg + 1 when seconds_reg < SECONDS_MAX else seconds_reg;

    p_seconds_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                seconds_reg <= 0;
            elsif busy_reg = '1' and tick = '1' then
                seconds_reg <= seconds_next;
            end if;
        end if;
    end process p_seconds_reg;

    p_clk_counter_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                clk_counter_reg <= 0;
            elsif busy_reg = '1' then
                if tick = '1' then
                    clk_counter_reg <= delta;
                elsif clk_counter_reg < CLK_FREQUENCY + DELTA_MAX - 1 then
                    clk_counter_reg <= clk_counter_reg + 1;
                end if;
            end if;
        end if;
    end process p_clk_counter_reg;

    delta <= -DELTA_MAX when clk_counter_reg <= CLK_FREQUENCY - DELTA_MAX - 1 else
             clk_counter_reg + 1 - CLK_FREQUENCY;

    p_delta_seconds_o : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                delta_o   <= 0;
                seconds_o <= 0;
            elsif busy_reg = '1' and tick = '1' and delta /= -DELTA_MAX and delta /= DELTA_MAX then
                delta_o   <= delta;
                seconds_o <= seconds_next;
            end if;
        end if;
    end process p_delta_seconds_o;
end RTL;
