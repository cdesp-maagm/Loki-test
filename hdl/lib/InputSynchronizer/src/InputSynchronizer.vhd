
library ieee;
use ieee.std_logic_1164.all;

-- A synchronizer for input signals, or signals from another clock domain,
-- to prevent metastability effects.
entity InputSynchronizer is
    generic(
        -- The number of bits to synchronize.
        WIDTH : positive
    );
    port(
        -- The global clock signal.
        clk_i  : in  std_logic;
        -- The inputs to synchronize.
        data_i : in  std_logic_vector(WIDTH - 1 downto 0);
        -- A synchronized copy of the inputs.
        data_o : out std_logic_vector(WIDTH - 1 downto 0)
    );
end InputSynchronizer;

architecture RTL of InputSynchronizer is
    -- Intermediate register that will synchronize data_i.
    signal data_i_reg, data_o_reg : std_logic_vector(WIDTH - 1 downto 0);

    -- The ASYNC_REG attribute informs Xilinx Vivado that each flip-flop pair
    -- data_i_reg(i)/data_o_reg(i) should be placed in the same slice.
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of data_i_reg : signal is "true";
    attribute ASYNC_REG of data_o_reg : signal is "true";
begin
    -- This is a simple two-stage delay line.
    p_data_io_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            data_i_reg <= data_i;
            data_o_reg <= data_i_reg;
        end if;
    end process p_data_io_reg;

    data_o <= data_o_reg;
end RTL;
