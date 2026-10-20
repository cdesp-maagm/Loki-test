
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

entity DelayLine is
    generic(
        LENGTH : positive
    );
    port(
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        enable_i : in  std_logic;
        data_i   : in  sfixed;
        data_o   : out sfixed
    );
end DelayLine;
