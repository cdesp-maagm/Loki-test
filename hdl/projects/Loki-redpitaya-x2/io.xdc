
# ------------------------------------------------------------------------------
# Convertisseur numérique/analogique DAC1401D125HL (Interleaved mode)
# ------------------------------------------------------------------------------

set_property IOSTANDARD  LVCMOS33 [get_ports dac_m_*_o]
set_property SLEW        FAST     [get_ports dac_m_*_o]
set_property DRIVE       8        [get_ports dac_m_*_o]
set_property PACKAGE_PIN M17      [get_ports dac_m_write_o]
set_property PACKAGE_PIN M18      [get_ports dac_m_clk_o]
set_property PACKAGE_PIN N16      [get_ports dac_m_sel_o]
set_property PACKAGE_PIN N15      [get_ports dac_m_reset_o]

set_property IOSTANDARD  LVCMOS33 [get_ports {dac_m_data_o[*]}]
set_property SLEW        SLOW     [get_ports {dac_m_data_o[*]}]
set_property DRIVE       4        [get_ports {dac_m_data_o[*]}]
set_property PACKAGE_PIN M19      [get_ports {dac_m_data_o[0]}]
set_property PACKAGE_PIN M20      [get_ports {dac_m_data_o[1]}]
set_property PACKAGE_PIN L19      [get_ports {dac_m_data_o[2]}]
set_property PACKAGE_PIN L20      [get_ports {dac_m_data_o[3]}]
set_property PACKAGE_PIN K19      [get_ports {dac_m_data_o[4]}]
set_property PACKAGE_PIN J19      [get_ports {dac_m_data_o[5]}]
set_property PACKAGE_PIN J20      [get_ports {dac_m_data_o[6]}]
set_property PACKAGE_PIN H20      [get_ports {dac_m_data_o[7]}]
set_property PACKAGE_PIN G19      [get_ports {dac_m_data_o[8]}]
set_property PACKAGE_PIN G20      [get_ports {dac_m_data_o[9]}]
set_property PACKAGE_PIN F19      [get_ports {dac_m_data_o[10]}]
set_property PACKAGE_PIN F20      [get_ports {dac_m_data_o[11]}]
set_property PACKAGE_PIN D20      [get_ports {dac_m_data_o[12]}]
set_property PACKAGE_PIN D19      [get_ports {dac_m_data_o[13]}]

# ------------------------------------------------------------------------------
# LEDs
# ------------------------------------------------------------------------------

set_property IOSTANDARD  LVCMOS33 [get_ports {led_o[*]}]
set_property SLEW        SLOW     [get_ports {led_o[*]}]
set_property DRIVE       4        [get_ports {led_o[*]}]
set_property PACKAGE_PIN F16      [get_ports {led_o[0]}]
set_property PACKAGE_PIN F17      [get_ports {led_o[1]}]
set_property PACKAGE_PIN G15      [get_ports {led_o[2]}]
set_property PACKAGE_PIN H15      [get_ports {led_o[3]}]
set_property PACKAGE_PIN K14      [get_ports {led_o[4]}]
set_property PACKAGE_PIN G14      [get_ports {led_o[5]}]
set_property PACKAGE_PIN J15      [get_ports {led_o[6]}]
set_property PACKAGE_PIN J14      [get_ports {led_o[7]}]

# ------------------------------------------------------------------------------
# Convertisseur analogique/numérique LTC2145CUP-14
# ------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS18        [get_ports {adc_s0_data_i[*]}]
# set_property IOB TRUE                   [get_ports {adc_s0_data_i[*]}]
# set_property PACKAGE_PIN V17            [get_ports {adc_s0_data_i[-2]}]
# set_property PACKAGE_PIN U17            [get_ports {adc_s0_data_i[-1]}]
set_property PACKAGE_PIN Y17            [get_ports {adc_s0_data_i[0]}]
set_property PACKAGE_PIN W16            [get_ports {adc_s0_data_i[1]}]
set_property PACKAGE_PIN Y16            [get_ports {adc_s0_data_i[2]}]
set_property PACKAGE_PIN W15            [get_ports {adc_s0_data_i[3]}]
set_property PACKAGE_PIN W14            [get_ports {adc_s0_data_i[4]}]
set_property PACKAGE_PIN Y14            [get_ports {adc_s0_data_i[5]}]
set_property PACKAGE_PIN W13            [get_ports {adc_s0_data_i[6]}]
set_property PACKAGE_PIN V12            [get_ports {adc_s0_data_i[7]}]
set_property PACKAGE_PIN V13            [get_ports {adc_s0_data_i[8]}]
set_property PACKAGE_PIN T14            [get_ports {adc_s0_data_i[9]}]
set_property PACKAGE_PIN T15            [get_ports {adc_s0_data_i[10]}]
set_property PACKAGE_PIN V15            [get_ports {adc_s0_data_i[11]}]
set_property PACKAGE_PIN T16            [get_ports {adc_s0_data_i[12]}]
set_property PACKAGE_PIN V16            [get_ports {adc_s0_data_i[13]}]

set_property IOSTANDARD LVCMOS18        [get_ports {adc_s1_data_i[*]}]
# set_property IOB TRUE                   [get_ports {adc_s1_data_i[*]}]
# set_property PACKAGE_PIN T17            [get_ports {adc_s1_data_i[-2]}]
# set_property PACKAGE_PIN R16            [get_ports {adc_s1_data_i[-1]}]
set_property PACKAGE_PIN R18            [get_ports {adc_s1_data_i[0]}]
set_property PACKAGE_PIN P16            [get_ports {adc_s1_data_i[1]}]
set_property PACKAGE_PIN P18            [get_ports {adc_s1_data_i[2]}]
set_property PACKAGE_PIN N17            [get_ports {adc_s1_data_i[3]}]
set_property PACKAGE_PIN R19            [get_ports {adc_s1_data_i[4]}]
set_property PACKAGE_PIN T20            [get_ports {adc_s1_data_i[5]}]
set_property PACKAGE_PIN T19            [get_ports {adc_s1_data_i[6]}]
set_property PACKAGE_PIN U20            [get_ports {adc_s1_data_i[7]}]
set_property PACKAGE_PIN V20            [get_ports {adc_s1_data_i[8]}]
set_property PACKAGE_PIN W20            [get_ports {adc_s1_data_i[9]}]
set_property PACKAGE_PIN W19            [get_ports {adc_s1_data_i[10]}]
set_property PACKAGE_PIN Y19            [get_ports {adc_s1_data_i[11]}]
set_property PACKAGE_PIN W18            [get_ports {adc_s1_data_i[12]}]
set_property PACKAGE_PIN Y18            [get_ports {adc_s1_data_i[13]}]

set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports adc_clk_*_i]
set_property PACKAGE_PIN U18            [get_ports adc_clk_p_i]
set_property PACKAGE_PIN U19            [get_ports adc_clk_n_i]

# L'horloge de l'ADC a une fréquence de 125 MHz.
# Temps de setup : 4 ns (demi-periode) - 0.6 ns (DATA to CLKOUT skew)
create_clock -period 8.000 -name adc_clkIn [get_ports adc_clk_p_i]
set_input_delay -clock adc_clkIn 3.400     [get_ports {adc_s0_data_i[*]}]
set_input_delay -clock adc_clkIn 3.400     [get_ports {adc_s1_data_i[*]}]

# Imposer la période de l'horloge en sortie des buffers :
# le fichier de contraintes du buffer affecte 10 ns par défaut
# et ne tient pas compte de la période d'horloge en enrée.
current_instance system_bd_i/adc_clk_buf/U0
create_clock -period 8.000 [get_ports -scoped_to_current_instance IBUF_OUT]

set_false_path -from [get_clocks adc_clkIn] -to [get_clocks clk_fpga_0]

set_property IOSTANDARD  LVCMOS18       [get_ports {adc_clk_o[*]}]
set_property SLEW        FAST           [get_ports {adc_clk_o[*]}]
set_property DRIVE       8              [get_ports {adc_clk_o[*]}]
set_property PACKAGE_PIN N20            [get_ports {adc_clk_o[0]}]
set_property PACKAGE_PIN P20            [get_ports {adc_clk_o[1]}]

set_property IOSTANDARD  LVCMOS18       [get_ports adc_cdcs_o]
set_property SLEW        FAST           [get_ports adc_cdcs_o]
set_property DRIVE       8              [get_ports adc_cdcs_o]
set_property PACKAGE_PIN V18            [get_ports adc_cdcs_o]

# ------------------------------------------------------------------------------
# Sorties de debug et synchro externe.
# ------------------------------------------------------------------------------

set_property PACKAGE_PIN G17 [get_ports {probe_o[0]}]
set_property PACKAGE_PIN G18 [get_ports {probe_o[1]}]
set_property PACKAGE_PIN H16 [get_ports {probe_o[2]}]
set_property PACKAGE_PIN H17 [get_ports {probe_o[3]}]
set_property PACKAGE_PIN J18 [get_ports {probe_o[4]}]
set_property PACKAGE_PIN H18 [get_ports {probe_o[5]}]
set_property PACKAGE_PIN K17 [get_ports {probe_o[6]}]
set_property PACKAGE_PIN K18 [get_ports {probe_o[7]}]
set_property PACKAGE_PIN L14 [get_ports {probe_o[8]}]
set_property PACKAGE_PIN L15 [get_ports {probe_o[9]}]
set_property PACKAGE_PIN L16 [get_ports {probe_o[10]}]
set_property PACKAGE_PIN L17 [get_ports {probe_o[11]}]
set_property PACKAGE_PIN K16 [get_ports {probe_o[12]}]
set_property PACKAGE_PIN J16 [get_ports {probe_o[13]}]
set_property PACKAGE_PIN M14 [get_ports {probe_o[14]}]
set_property PACKAGE_PIN M15 [get_ports {probe_o[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {probe_o[*]}]
set_property SLEW       FAST     [get_ports {probe_o[*]}]
