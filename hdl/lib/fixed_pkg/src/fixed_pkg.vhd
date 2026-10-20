
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fixed_pkg is
    type sfixed is array(integer range<>) of std_logic;

    function to_signed(arg : sfixed) return signed;
    function to_unsigned(arg : sfixed) return unsigned;

    function to_sfixed(arg : integer; left, right : integer) return sfixed;
    function to_sfixed(arg : integer; ref : sfixed) return sfixed;

    function to_sfixed(arg : real; left, right : integer) return sfixed;
    function to_sfixed(arg : real; ref : sfixed) return sfixed;

    function to_real(arg : sfixed) return real;

    function to_string(arg : sfixed) return string;

    function to_std_logic_vector(arg : sfixed) return std_logic_vector;

    function resize(arg : sfixed; left, right : integer) return sfixed;
    function resize(arg : sfixed; ref : sfixed) return sfixed;

    function is_positive_or_zero(arg : sfixed) return boolean;
    function is_negative(arg : sfixed) return boolean;

    function "abs"(a : sfixed) return sfixed;

    function "-"(a : sfixed) return sfixed;

    function "-"(a, b : sfixed) return sfixed;
    function "-"(a : sfixed; b : integer) return sfixed;

    function "+"(a, b : sfixed) return sfixed;
    function "+"(a : sfixed; b : integer) return sfixed;

    function "*"(a, b : sfixed) return sfixed;
    function "*"(a : sfixed; b : integer) return sfixed;

    function "sra"(a : sfixed; b : natural) return sfixed;
    function "srl"(a : sfixed; b : natural) return sfixed;

    function "="(a, b : sfixed) return boolean;
    function "="(a : sfixed; b : integer) return boolean;

    function "/="(a, b : sfixed) return boolean;
    function "/="(a : sfixed; b : integer) return boolean;

    function ">"(a, b : sfixed) return boolean;
    function ">"(a : sfixed; b : integer) return boolean;

    function ">="(a, b : sfixed) return boolean;
    function ">="(a : sfixed; b : integer) return boolean;

    function "<"(a, b : sfixed) return boolean;
    function "<"(a : sfixed; b : integer) return boolean;

    function "<="(a, b : sfixed) return boolean;
    function "<="(a : sfixed; b : integer) return boolean;
end fixed_pkg;
