
library ieee;
use ieee.std_logic_1164.all;

use std.env.all; -- GHDL

use work.fixed_pkg.all;

entity fixedTestbench is
end fixedTestbench;

architecture Simulation of fixedTestbench is
    function compare(a : sfixed; ref : real) return boolean is
        variable epsilon : real := 2.0 ** (-a'right);
        variable ra : real := to_real(a);
    begin
        if ra > ref - epsilon and ra < ref + epsilon then
            return true;
        else
            report "Résultat=" & real'image(ra) & " Attendu=" & real'image(ref)
                severity error;
            return false;
        end if;
    end compare;
begin
    process
        variable ra, rb, rc, rd : real;
        variable a, as : sfixed(4 downto -4);
        variable b : sfixed(2 downto -2);
        variable c : sfixed(maximum(a'left, b'left) downto minimum(a'right, b'right));
        variable d : sfixed(a'left + b'left + 1 downto a'right + b'right);
        variable success : natural;
    begin
        report "---- to_sfixed(integer)";

        success := 0;
        for i in -2 ** a'left to 2 ** a'left -1 loop
            ra := real(i);
            a := to_sfixed(i, a);
            if compare(a, ra) then
                success := success + 1;
            end if;
        end loop;
        report "Succès : " & integer'image(success);

        report "---- to_sfixed(real)";

        success := 0;
        for i in -2 ** (a'length-1) to 2 ** (a'length-1) - 1 loop
            ra := real(i) * 2.0 ** a'right;
            a := to_sfixed(ra, a);
            if compare(a, ra) then
                success := success + 1;
            end if;
        end loop;
        report "Succès : " & integer'image(success);

        report "---- -(sfixed)";

        success := 0;
        for i in -2 ** (a'length-1) + 1 to 2 ** (a'length-1) - 1 loop
            ra := real(i) * 2.0 ** a'right;
            a := to_sfixed(ra, a);
            if compare(-a, -ra) then
                success := success + 1;
            end if;
        end loop;
        report "Succès : " & integer'image(success);

        report "---- sfixed + sfixed";

        success := 0;
        for i in -2 ** (a'length-2) to 2 ** (a'length-2) - 1 loop
            ra := real(i) * 2.0 ** a'right;
            a := to_sfixed(ra, a);
            for j in -2 ** (b'length-2) to 2 ** (b'length-2) - 1 loop
                rb := real(j) * 2.0 ** b'right;
                b := to_sfixed(rb, b);
                rc := ra + rb;
                c := a + b;
                if compare(c, rc) then
                    success := success + 1;
                end if;
            end loop;
        end loop;
        report "Succès : " & integer'image(success);

        report "---- sfixed - sfixed";

        success := 0;
        for i in -2 ** (a'length-2) to 2 ** (a'length-2) - 1 loop
            ra := real(i) * 2.0 ** a'right;
            a := to_sfixed(ra, a);
            for j in -2 ** (b'length-2) to 2 ** (b'length-2) - 1 loop
                rb := real(j) * 2.0 ** b'right;
                b := to_sfixed(rb, b);
                rc := ra - rb;
                c := a - b;
                if compare(c, rc) then
                    success := success + 1;
                end if;
            end loop;
        end loop;
        report "Succès : " & integer'image(success);

        report "---- sfixed * sfixed";

        success := 0;
        for i in -2 ** (a'length-1) to 2 ** (a'length-1) - 1 loop
            ra := real(i) * 2.0 ** a'right;
            a := to_sfixed(ra, a);
            for j in -2 ** (b'length-1) to 2 ** (b'length-1) - 1 loop
                rb := real(j) * 2.0 ** b'right;
                b := to_sfixed(rb, b);
                rd := ra * rb;
                d := a * b;
                if compare(d, rd) then
                    success := success + 1;
                end if;
            end loop;
        end loop;
        report "Succès : " & integer'image(success);

        report "---- sfixed sra natural";

        success := 0;
        for i in -2 ** (a'length-1) to 2 ** (a'length-1) - 1 loop
            ra := real(i) * 2.0 ** a'right;
            a := to_sfixed(ra, a);
            for j in 0 to a'left loop
                as := a sra j;

                if as(as'left) /= a(a'left) then
                    report "Non conservation du bit de signe" severity error;
                elsif to_std_logic_vector(as(a'left - j downto a'right)) /= to_std_logic_vector(a(a'left downto a'right + j)) then
                    report "Erreur de décalage " & to_string(a) & " sra " & integer'image(j) &
                        " = " & to_string(as)
                        severity error;
                else
                    success := success + 1;
                end if;
            end loop;
        end loop;
        report "Succès : " & integer'image(success);

        finish;
    end process;
end Simulation;
