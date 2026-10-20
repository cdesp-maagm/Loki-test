
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;

entity Divider is
    port(
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        s_valid_i     : in  std_logic;
        s_ready_o     : out std_logic;
        s_dividend_i  : in  sfixed;
        s_divisor_i   : in  sfixed;
        m_valid_o     : out std_logic;
        m_ready_i     : in  std_logic;
        m_quotient_o  : out sfixed;
        m_remainder_o : out sfixed
    );
begin
    assert m_quotient_o'left >= s_dividend_i'left - s_divisor_i'right
        report "La largeur de la partie entière du quotient peut être insuffisante."
        severity warning;
end Divider;
