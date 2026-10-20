
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

entity DisplacementSensor is
    generic(
        DELAY                  : natural;
        DEFAULT_WAVELENGTH     : real;
        DEPTH                  : integer;
        SAMPLE_FREQUENCY       : real;
        DISPLACEMENT_FILENAME  : string := "";
        DISPLACEMENT_AMPLITUDE : real   := 0.0;
        DISPLACEMENT_FREQUENCY : real   := 0.0;
        POWER_FACTOR           : real;
        POWER_CONTRAST         : real
    );
    port(
        s_phase_i : in  sfixed;
        m_power_o : out sfixed
    );
end DisplacementSensor;
