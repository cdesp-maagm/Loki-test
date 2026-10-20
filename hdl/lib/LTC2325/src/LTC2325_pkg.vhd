
library ieee;
use ieee.std_logic_1164.all;

package LTC2325_pkg is

    constant LTC2325_DATA_WIDTH : positive := 16;
    subtype LTC2325Data_t is std_logic_vector(LTC2325_DATA_WIDTH - 1 downto 0);
    type LTC2325DataArray_t is array(natural range <>) of LTC2325Data_t;

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
end LTC2325_pkg;
