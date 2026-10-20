
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;

architecture Simulation of DisplacementSensor is
    constant USE_FILE_SOURCE : boolean                 := DISPLACEMENT_FILENAME'length > 0;
    constant SAMPLE_PERIOD   : time                    := 1.0 sec / SAMPLE_FREQUENCY;
    constant DELAY_TIME      : time                    := 1.0 sec * DELAY / SAMPLE_FREQUENCY;
    constant OFFSET          : real                    := MATH_2_PI * real(DEPTH);
    constant GAIN            : real                    := 2.0 * MATH_2_PI / DEFAULT_WAVELENGTH;
    constant VELOCITY        : real                    := MATH_2_PI * DISPLACEMENT_FREQUENCY;
    signal sample_count      : real                    := 0.0;
    signal m_power           : sfixed(m_power_o'range) := to_sfixed(0, m_power_o'left, m_power_o'right);
begin
    p_m_power_o : process
        file src_file                     : text;
        variable src_line                 : line;
        variable disp, num, den, power, t : real;
    begin
        if USE_FILE_SOURCE then
            report "Using displacement data file: " & DISPLACEMENT_FILENAME;
            file_open(src_file, DISPLACEMENT_FILENAME, read_mode);
        end if;
        loop
            wait for SAMPLE_PERIOD;

            t := sample_count / SAMPLE_FREQUENCY;
            if USE_FILE_SOURCE then
                readline(src_file, src_line);
                read(src_line, disp);
            else
                disp := DISPLACEMENT_AMPLITUDE * cos(VELOCITY * t);
            end if;
            num          := OFFSET + GAIN * disp;
            den          := 1.0 - to_real(s_phase_i) / OFFSET;
            power        := POWER_FACTOR * (1.0 + POWER_CONTRAST * cos(num / den));
            m_power      <= to_sfixed(power, m_power_o'left, m_power_o'right);
            sample_count <= sample_count + 1.0;
        end loop;
    end process p_m_power_o;

    m_power_o <= transport m_power after DELAY_TIME;
end Simulation;
