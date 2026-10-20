
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package BMP390_pkg is

    constant BMP390_SPI_FREQUENCY   : positive := 1e6;
    constant BMP390_STARTUP_TIME_MS : positive := 2;

    constant BMP390_CHANNELS : positive := 2;

    constant BMP390_DATA_WIDTH : positive := 24;
    subtype BMP390Data_t is unsigned(BMP390_DATA_WIDTH - 1 downto 0);
    type BMP390DataArray_t is array(0 to BMP390_CHANNELS - 1) of BMP390Data_t;

    constant BMP390_WRITE : std_logic := '0';
    constant BMP390_READ  : std_logic := '1';

    subtype BMP390RegisterAddress_t is std_logic_vector(6 downto 0);
    subtype BMP390RegisterData_t    is std_logic_vector(7 downto 0);

    constant BMP390_CHIP_ID_REG       : BMP390RegisterAddress_t := "0000000";
    constant BMP390_ERR_REG           : BMP390RegisterAddress_t := "0000010";
    constant BMP390_STATUS_REG        : BMP390RegisterAddress_t := "0000011";
    constant BMP390_NVM_PAR_T1_REG    : BMP390RegisterAddress_t := "0110001";
    constant BMP390_NVM_PAR_T3_REG    : BMP390RegisterAddress_t := "0110101";
    constant BMP390_NVM_PAR_P1_REG    : BMP390RegisterAddress_t := "0110110";
    constant BMP390_NVM_PAR_P3_REG    : BMP390RegisterAddress_t := "0111010";
    constant BMP390_NVM_PAR_P6_REG    : BMP390RegisterAddress_t := "0111110";
    constant BMP390_NVM_PAR_P9_REG    : BMP390RegisterAddress_t := "1000010";
    constant BMP390_FIFO_CONFIG_1_REG : BMP390RegisterAddress_t := "0010111";
    constant BMP390_IF_CONF_REG       : BMP390RegisterAddress_t := "0011010";
    constant BMP390_PW_CTRL_REG       : BMP390RegisterAddress_t := "0011011";
    constant BMP390_OSR_REG           : BMP390RegisterAddress_t := "0011100";
    constant BMP390_ODR_REG           : BMP390RegisterAddress_t := "0011101";
    constant BMP390_CONFIG_REG        : BMP390RegisterAddress_t := "0011111";
    constant BMP390_CMD_REG           : BMP390RegisterAddress_t := "1111110";

    constant BMP390_CHIP_ID               : BMP390RegisterData_t := x"60";
    constant BMP390_FIFO_CONFIG_1_DISABLE : BMP390RegisterData_t := x"02"; -- Par défaut
    constant BMP390_IF_CONF_SPI4          : BMP390RegisterData_t := x"00"; -- Par défaut
    constant BMP390_PW_CTRL_FORCED_ALL_ON : BMP390RegisterData_t := x"13";
    constant BMP390_OSR_PX32_TX2          : BMP390RegisterData_t := x"0D";
    constant BMP390_ODR_12P5_HZ           : BMP390RegisterData_t := x"04";
    constant BMP390_CONFIG_IIR1           : BMP390RegisterData_t := x"02";
    constant BMP390_CMD_SOFT_RESET        : BMP390RegisterData_t := x"B6";
    constant BMP390_DUMMY                 : BMP390RegisterData_t := x"00";

    constant BMP390_NVM_WORDS : positive := 6;

    subtype BMP390NVMData_t is std_logic_vector(31 downto 0);
    type BMP390NVMDataArray_t is array(0 to BMP390_NVM_WORDS - 1) of BMP390NVMData_t;

end BMP390_pkg;
