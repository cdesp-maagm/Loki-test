
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package body float_pkg is

    type boundary_type is (normal, infinity, zero, denormal);

    function gen_expon_base(exponent_width : natural) return signed is
        variable result : signed(exponent_width-1 downto 0);
    begin
        result                   := (others => '1');
        result(exponent_width-1) := '0';
        return result;
    end gen_expon_base;

    function log2(a : real) return integer is
        variable y : real;
        variable n : integer := 0;
    begin
        if a = 1.0 or a = 0.0 then
            return 0;
        end if;

        y := a;
        if(a > 1.0) then
            while y >= 2.0 loop
                y := y / 2.0;
                n := n + 1;
            end loop;
            return n;
        end if;

        -- O < y < 1
        while y < 1.0 loop
            y := y * 2.0;
            n := n - 1;
        end loop;
        return n;
    end log2;

    procedure test_boundary(arg : real;  fraction_width : natural; exponent_width : natural; btype : out boundary_type; log2i : out integer) is
        constant expon_base  : signed(exponent_width-1 downto 0) := gen_expon_base(exponent_width);
        constant exp_min     : signed(12 downto 0) := -(resize(expon_base, 13)) + 1;
        constant exp_ext_min : signed(12 downto 0) := exp_min - fraction_width;
        variable log2arg     : integer;
    begin
        -- Note that the argument is always an absolute value at this point.
        log2arg := log2(arg);
        if arg = 0.0 then
            btype := zero;
        elsif exponent_width > 11 then      -- Exponent for Real is 11 (64 bit)
            btype := normal;
        else
            if log2arg < to_integer(exp_min) then
                if log2arg < to_integer(exp_ext_min) then
                    btype := zero;
                else
                    btype := denormal;
                end if;
            elsif exponent_width < 11 then
                if log2arg > to_integer(expon_base)+1 then
                    btype := infinity;
                else
                    btype := normal;
                end if;
            else
                btype := normal;
            end if;
        end if;
        log2i := log2arg;
    end procedure test_boundary;

    function to_float(arg : real; exponent_width : natural := float_exponent_width; fraction_width : natural := float_fraction_width) return float is
        variable result     : float(exponent_width downto -fraction_width);
        variable arg_real   : real;         -- Real version of argument
        variable validfp    : boundary_type;      -- Check for valid results
        variable exp        : integer;      -- Integer version of exponent
        variable expon      : unsigned(exponent_width - 1 downto 0);
        constant expon_base : signed(exponent_width-1 downto 0) := gen_expon_base(exponent_width);
        variable fract      : unsigned(fraction_width-1 downto 0);
        variable frac       : real;          -- Real version of fraction
        constant roundfrac  : real := 2.0 ** (-2 - fract'high);  -- used for rounding
    begin
        result   := (others => '0');
        arg_real := arg;

        if arg_real < 0.0 then
            result(exponent_width) := '1';
            arg_real               := -arg_real;
        end if;

        test_boundary(arg            => arg_real,
                      fraction_width => fraction_width,
                      exponent_width => exponent_width,
                      btype          => validfp,
                      log2i          => exp);

        if validfp = infinity then
            result(exponent_width - 1 downto 0) := (others => '1');
        elsif validfp /= zero then
            if validfp = denormal then
                expon := (others => '0');
                frac  := arg_real * (2.0 ** (to_integer(expon_base)-1));
            else                              -- Number less than 1. "normal" number
                expon := unsigned(to_signed(exp-1, exponent_width));
                expon(exponent_width-1) := not expon(exponent_width-1);
                frac := (arg_real / 2.0 ** exp) - 1.0;  -- Number less than 1.
            end if;

            for i in 0 to fract'high loop
                if frac >= 2.0 ** (-1 - i) then
                    fract(fract'high - i) := '1';
                    frac := frac - 2.0 ** (-1 - i);
                else
                    fract(fract'high - i) := '0';
                end if;
            end loop;

            if frac > roundfrac or (frac = roundfrac and fract(0) = '1') then
                if and(fract) = '1' then
                    expon := expon + 1;
                    fract := (others => '0');
                else
                    fract := fract + 1;
                end if;
            end if;

            result(exponent_width-1 downto 0) := float(expon);
            result(-1 downto -fraction_width) := float(fract);
        end if;

        return result;
    end function to_float;

    function to_std_logic_vector(arg : float) return std_logic_vector is
        constant res : float(arg'length - 1 downto 0) := arg;
    begin
        return std_logic_vector(res);
    end to_std_logic_vector;

end float_pkg;
