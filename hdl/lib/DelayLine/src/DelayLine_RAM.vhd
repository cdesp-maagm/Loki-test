
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

architecture RAM of DelayLine is
    subtype RamData_t is std_logic_vector(data_o'length - 1 downto 0);
    signal data_to_ram, data_from_ram, data_from_ram_reg : RamData_t := (others => '0');

    type RamDataArray_t is array(0 to LENGTH - 1) of RamData_t;
    signal data_reg : RamDataArray_t := (others => (others => '0'));

    signal address_reg, address_next : integer range 0 to LENGTH - 1;
begin
    address_next <= 0 when address_reg = LENGTH - 1 else address_reg + 1;

    p_address_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                address_reg <= 0;
            elsif enable_i = '1' then
                address_reg <= address_next;
            end if;
        end if;
    end process p_address_reg;

    -- Ce processus sera synthétisé par un bloc de RAM avec un port en lecture
    -- et un port en écriture.
    -- Le registre data_from_ram_reg est facultatif mais il permet de réduire les
    -- risques de problèmes de timing.
    p_data_reg : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if enable_i = '1' then
                data_reg(address_reg) <= data_to_ram;
                data_from_ram_reg     <= data_reg(address_next);
            end if;
            data_from_ram <= data_from_ram_reg;
        end if;
    end process p_data_reg;

    data_to_ram <= to_std_logic_vector(resize(data_i, data_o'left, data_o'right));
    data_o      <= sfixed(data_from_ram);
end RAM;
