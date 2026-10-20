
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DS1820_pkg is

    constant DS1820_DATA_WIDTH : positive := 16;
    subtype DS1820Data_t is signed(DS1820_DATA_WIDTH - 1 downto 0);
    type DS1820DataArray_t is array(natural range <>) of DS1820Data_t;

    type Register_t is (
        REG_CLK_FREQUENCY,        -- Constant, en lecture seule
        REG_CHANNELS,             -- Constant, en lecture seule
        REG_CHANNEL_OUTPUT_WIDTH, -- Constant, en lecture seule
        REG_DATA_WIDTH,           -- Constant, en lecture seule
        REG_CYCLES_PER_SAMPLE_MAX,-- Constant, en lecture seule
        REG_PACKET_LENGTH_MAX,    -- Constant, en lecture seule
        REG_CYCLES_PER_SAMPLE,
        REG_PACKET_LENGTH,
        REG_STATUS                -- En lecture seule
    );

    constant REG_LAST_DATA : positive := Register_t'pos(Register_t'high) + 1;
end DS1820_pkg;
