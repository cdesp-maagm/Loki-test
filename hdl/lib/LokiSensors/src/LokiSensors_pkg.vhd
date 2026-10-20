
library ieee;
use ieee.std_logic_1164.all;

use work.LTC2984_pkg.all;
use work.BMP390_pkg.all;

package LokiSensors_pkg is

    constant LOKI_SENSORS_CHANNELS : positive := LTC2984_CHANNELS + BMP390_CHANNELS;

    constant LOKI_SENSORS_DATA_WIDTH : positive := maximum(LTC2984_DATA_WIDTH, BMP390_DATA_WIDTH);
    subtype LokiSensorsData_t is std_logic_vector(LOKI_SENSORS_DATA_WIDTH - 1 downto 0);
    type LokiSensorsDataArray_t is array(0 to LOKI_SENSORS_CHANNELS - 1) of LokiSensorsData_t;

    type Register_t is (
        REG_CLK_FREQUENCY,         -- Constant, en lecture seule
        REG_CHANNELS,              -- Constant, en lecture seule
        REG_CHANNEL_OUTPUT_WIDTH,  -- Constant, en lecture seule
        REG_DATA_WIDTH,            -- Constant, en lecture seule
        REG_CYCLES_PER_SAMPLE_MAX, -- Constant, en lecture seule
        REG_PACKET_LENGTH_MAX,     -- Constant, en lecture seule
        REG_CYCLES_PER_SAMPLE,
        REG_PACKET_LENGTH,
        REG_CONTROL,
        REG_STATUS,                -- En lecture seule
        REG_BMP390_NVM0,           -- En lecture seule
        REG_BMP390_NVM1,           -- En lecture seule
        REG_BMP390_NVM2,           -- En lecture seule
        REG_BMP390_NVM3,           -- En lecture seule
        REG_BMP390_NVM4,           -- En lecture seule
        REG_BMP390_NVM5            -- En lecture seule
    );

    constant REG_LAST_DATA : positive := Register_t'pos(Register_t'high) + 1;
end LokiSensors_pkg;
