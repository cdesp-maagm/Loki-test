
library ieee;
use ieee.std_logic_1164.all;

use std.env.all;

entity FIFOControllerTestbench is
end FIFOControllerTestbench;

architecture Simulation of FIFOControllerTestbench is
    constant CLK_PERIOD                  : time                             := 20 ns;
    constant FIFO_LENGTH                 : integer                          := 4;
    constant MASTER_CYCLES_AFTER_S_READY : natural                          := 1;
    constant SLAVE_CYCLES_AFTER_M_VALID  : natural                          := 4;

    signal clk, s_valid, m_ready         : std_logic                        := '0';
    signal reset                         : std_logic                        := '1';
    signal s_ready, m_valid              : std_logic;
    signal read_index                    : natural range 0 to FIFO_LENGTH;

    signal fifo_data_reg                 : integer_vector(0 to FIFO_LENGTH) := (others => 0);

    type SlaveState_t is (SLAVE_IDLE, SLAVE_WAITING, SLAVE_READY);
    signal state_reg, state_next         : SlaveState_t;
    signal count_reg                     : natural range 0 to SLAVE_CYCLES_AFTER_M_VALID - 1;
begin
    clk   <= not clk after CLK_PERIOD / 2;
    reset <= '0'     after CLK_PERIOD;

    fifo_inst : entity work.FIFOController
        generic map(
            LENGTH => FIFO_LENGTH
        )
        port map(
            clk_i        => clk,
            reset_i      => reset,
            s_valid_i    => s_valid,
            s_ready_o    => s_ready,
            m_valid_o    => m_valid,
            m_ready_i    => m_ready,
            read_index_o => read_index
        );

    p_fifo_data_reg : process(clk)
    begin
        if rising_edge(clk) then
            if s_ready = '1' then
                fifo_data_reg(1 to fifo_data_reg'high) <= fifo_data_reg(0 to fifo_data_reg'high - 1);
            end if;
        end if;
    end process p_fifo_data_reg;

    p_master : process
    begin
        wait until rising_edge(clk) and reset = '0';

        for i in 1 to FIFO_LENGTH + 1 loop
            fifo_data_reg(0) <= i;
            s_valid          <= '1';
            wait until rising_edge(clk) and s_ready = '1';

            for j in 1 to MASTER_CYCLES_AFTER_S_READY loop
                s_valid <= '0';
                wait until rising_edge(clk);
            end loop;
        end loop;
    end process p_master;

    p_state_next : process(m_valid, state_reg, count_reg)
    begin
        case state_reg is
            when SLAVE_IDLE =>
                if m_valid = '0' then
                    state_next <= SLAVE_IDLE;
                elsif SLAVE_CYCLES_AFTER_M_VALID = 0 then
                    state_next <= SLAVE_READY;
                else
                    state_next <= SLAVE_WAITING;
                end if;
            when SLAVE_WAITING =>
                if count_reg = SLAVE_CYCLES_AFTER_M_VALID - 1 then
                    state_next <= SLAVE_READY;
                else
                    state_next <= SLAVE_WAITING;
                end if;
            when SLAVE_READY =>
                if m_valid = '0' then
                    state_next <= SLAVE_IDLE;
                elsif SLAVE_CYCLES_AFTER_M_VALID = 0 then
                    state_next <= SLAVE_READY;
                else
                    state_next <= SLAVE_WAITING;
                end if;
        end case;
    end process p_state_next;

    p_state_reg : process(clk)
    begin
        if rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process p_state_reg;

    m_ready <= '1' when state_next = SLAVE_READY else '0';

    p_count_reg : process(clk)
    begin
        if rising_edge(clk) then
            if state_reg = SLAVE_WAITING then
                if count_reg = SLAVE_CYCLES_AFTER_M_VALID - 1 then
                    count_reg <= 0;
                else
                    count_reg <= count_reg + 1;
                end if;
            end if;
        end if;
    end process p_count_reg;

    p_slave : process
        variable fifo_data : integer;
    begin
        for i in 1 to FIFO_LENGTH + 1 loop
            wait until rising_edge(clk) and m_valid = '1' and m_ready = '1';
            fifo_data := fifo_data_reg(read_index);
            assert fifo_data = i
                report "Valeur incorrecte pour fifo_data : " & integer'image(fifo_data) & " attendu : " & integer'image(i)
                severity error;
        end loop;

        finish;
    end process p_slave;
end Simulation;
