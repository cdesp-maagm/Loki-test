
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

architecture ShiftRegisters of DelayLine is
    subtype ShiftData_t is sfixed(data_o'range);
    type ShiftDataArray_t is array(0 to LENGTH - 1) of ShiftData_t;
    signal data_reg : ShiftDataArray_t := (others => (others => '0'));
begin
    p_data_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if enable_i = '1' then
                data_reg(1 to data_reg'high) <= data_reg(0 to data_reg'high - 1);
                data_reg(0) <= resize(data_i, data_o'left, data_o'right);
            end if;
        end if;
    end process p_data_reg;

    data_o <= data_reg(data_reg'high);
end ShiftRegisters;
