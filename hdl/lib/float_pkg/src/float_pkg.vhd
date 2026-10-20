
library ieee;
use ieee.std_logic_1164.all;

package float_pkg is
    type float is array(integer range<>) of std_logic;

    constant float_exponent_width : natural := 8;
    constant float_fraction_width : natural := 23;

    function to_float(arg : real; exponent_width : natural := float_exponent_width; fraction_width : natural := float_fraction_width) return float;
    function to_std_logic_vector(arg : float) return std_logic_vector;

end float_pkg;
