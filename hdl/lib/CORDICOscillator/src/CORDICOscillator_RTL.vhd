
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.CORDIC_pkg.all;

architecture RTL of CORDICOscillator is
    signal cordic_s_ready : std_logic;
    signal cordic_s_angle_reg : Angle_t;
begin
    p_cordic_angle_reg : process(clk_i)
        variable cordic_angle_next : FullAngle_t;
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                cordic_s_angle_reg <= to_sfixed(0, cordic_s_angle_reg);
            elsif cordic_s_ready = '1' then
                cordic_angle_next := resize(cordic_s_angle_reg, cordic_angle_next) + step_i;
                if cordic_angle_next > CORDIC_PI then
                    cordic_angle_next := cordic_angle_next - CORDIC_2PI;
                end if;
                cordic_s_angle_reg <= resize(cordic_angle_next, cordic_s_angle_reg);
            end if;
        end if;
    end process p_cordic_angle_reg;

    cordic_inst : entity work.CORDIC
        generic map(
            ROTATIONS_PER_CYCLE => ROTATIONS_PER_CYCLE
        )
        port map(
            clk_i => clk_i,
            reset_i => reset_i,
            s_valid_i => '1',
            s_ready_o => cordic_s_ready,
            s_angle_i => cordic_s_angle_reg,
            m_valid_o => m_valid_o,
            m_ready_i => m_ready_i,
            m_cos_o => m_cos_o,
            m_sin_o => m_sin_o
        );
end RTL;
