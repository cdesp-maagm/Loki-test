
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package LTC2984_pkg is

    constant LTC2984_SPI_FREQUENCY : positive := 1e6;

    constant LTC2984_WRITE : std_logic_vector(7 downto 0)  := x"02";
    constant LTC2984_READ  : std_logic_vector(7 downto 0)  := x"03";

    subtype LTC2984RegisterAddress_t is std_logic_vector(15 downto 0);
    constant LTC2984_CMD_STATUS_REG     : LTC2984RegisterAddress_t := x"0000";
    constant LTC2984_TEMP_RESULT_REG    : LTC2984RegisterAddress_t := x"0010";
    constant LTC2984_EEPROM_KEY_REG     : LTC2984RegisterAddress_t := x"00B0";
    constant LTC2984_EEPROM_RESULT_REG  : LTC2984RegisterAddress_t := x"00D0";
    constant LTC2984_MULT_CHAN_MASK_REG : LTC2984RegisterAddress_t := x"00F4";

    subtype LTC2984RegisterData_t is std_logic_vector(31 downto 0);
    constant LTC2984_CMD_START_EEPROM_READ : LTC2984RegisterData_t := x"96000000";
    constant LTC2984_CMD_START_CONV_ALL    : LTC2984RegisterData_t := x"80000000";
    constant LTC2984_EEPROM_KEY            : LTC2984RegisterData_t := x"A53C0F5A";
    constant LTC2984_MULT_CHAN_MASK_ALL    : LTC2984RegisterData_t := x"000FFFFF";
    constant LTC2984_DUMMY                 : LTC2984RegisterData_t := x"00000000";
    
    constant LTC2984_CHANNELS : positive := 20;

    constant LTC2984_DATA_WIDTH : positive := 24;
    subtype LTC2984Data_t is signed(LTC2984_DATA_WIDTH - 1 downto 0);
    type LTC2984DataArray_t is array(0 to LTC2984_CHANNELS - 1) of LTC2984Data_t;

end LTC2984_pkg;
