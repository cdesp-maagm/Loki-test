
# ------------------------------------------------------------------------------
# XADC
# ------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports xadc*]
set_property PACKAGE_PIN C20     [get_ports xadc0_p_i]
set_property PACKAGE_PIN B20     [get_ports xadc0_n_i]
set_property PACKAGE_PIN E17     [get_ports xadc1_p_i]
set_property PACKAGE_PIN D18     [get_ports xadc1_n_i]

# ------------------------------------------------------------------------------
# GPIO
# ------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports sw_i]
set_property PACKAGE_PIN G14     [get_ports sw_i]

set_property IOSTANDARD LVCMOS33 [get_ports gps*]
set_property PACKAGE_PIN L16     [get_ports gps_clk1pps_i]
set_property PACKAGE_PIN K17     [get_ports gps_clk10m_i]
set_property PACKAGE_PIN H16     [get_ports gps_clk30m72_i]
set_property PACKAGE_PIN J18     [get_ports gps_tstamp_o]

# ------------------------------------------------------------------------------
# Convertisseur numérique/analogique AD9767 (Interleaved mode)
# ------------------------------------------------------------------------------

set_property IOSTANDARD  LVCMOS33 [get_ports dac_m_*]

set_property SLEW        FAST     [get_ports dac_m_*_o]
set_property DRIVE       8        [get_ports dac_m_*_o]
set_property PACKAGE_PIN J20      [get_ports dac_m_clk_o]
set_property PACKAGE_PIN F20      [get_ports dac_m_reset_o]
set_property PACKAGE_PIN G18      [get_ports dac_m_sel_o]
set_property PACKAGE_PIN G19      [get_ports dac_m_write_o]

set_property SLEW        SLOW     [get_ports dac_m_data_o]
set_property DRIVE       4        [get_ports dac_m_data_o]

set_property PACKAGE_PIN G20      [get_ports {dac_m_data_o[0]}]
set_property PACKAGE_PIN H20      [get_ports {dac_m_data_o[1]}]
set_property PACKAGE_PIN K14      [get_ports {dac_m_data_o[2]}]
set_property PACKAGE_PIN H15      [get_ports {dac_m_data_o[3]}]
set_property PACKAGE_PIN J14      [get_ports {dac_m_data_o[4]}]
set_property PACKAGE_PIN G15      [get_ports {dac_m_data_o[5]}]
set_property PACKAGE_PIN N15      [get_ports {dac_m_data_o[6]}]
set_property PACKAGE_PIN L14      [get_ports {dac_m_data_o[7]}]
set_property PACKAGE_PIN N16      [get_ports {dac_m_data_o[8]}]
set_property PACKAGE_PIN L15      [get_ports {dac_m_data_o[9]}]
set_property PACKAGE_PIN M14      [get_ports {dac_m_data_o[10]}]
set_property PACKAGE_PIN K16      [get_ports {dac_m_data_o[11]}]
set_property PACKAGE_PIN M15      [get_ports {dac_m_data_o[12]}]
set_property PACKAGE_PIN J16      [get_ports {dac_m_data_o[13]}]

# ------------------------------------------------------------------------------
# Convertisseurs analogique/numérique LTC2325.
# ------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS25 [get_ports adc*_o]
set_property IOSTANDARD LVDS_25  [get_ports adc*_p]
set_property IOSTANDARD LVDS_25  [get_ports adc*_n]

set_property PACKAGE_PIN U19 [get_ports adc0_m_convert_n_o]
set_property PACKAGE_PIN R18 [get_ports adc0_m_sclk_i_p]
set_property PACKAGE_PIN T17 [get_ports adc0_m_sclk_i_n]
set_property PACKAGE_PIN P20 [get_ports adc0_m_sclk_o_p]
set_property PACKAGE_PIN N20 [get_ports adc0_m_sclk_o_n]
set_property PACKAGE_PIN P16 [get_ports {adc0_m_sdata_i_p[0]}]
set_property PACKAGE_PIN P15 [get_ports {adc0_m_sdata_i_n[0]}]
set_property PACKAGE_PIN W19 [get_ports {adc0_m_sdata_i_p[1]}]
set_property PACKAGE_PIN W18 [get_ports {adc0_m_sdata_i_n[1]}]
set_property PACKAGE_PIN W16 [get_ports {adc0_m_sdata_i_p[2]}]
set_property PACKAGE_PIN V16 [get_ports {adc0_m_sdata_i_n[2]}]
set_property PACKAGE_PIN W20 [get_ports {adc0_m_sdata_i_p[3]}]
set_property PACKAGE_PIN V20 [get_ports {adc0_m_sdata_i_n[3]}]

set_property PACKAGE_PIN U15 [get_ports adc1_m_convert_n_o]
set_property PACKAGE_PIN Y18 [get_ports adc1_m_sclk_i_p]
set_property PACKAGE_PIN Y19 [get_ports adc1_m_sclk_i_n]
set_property PACKAGE_PIN N17 [get_ports adc1_m_sclk_o_p]
set_property PACKAGE_PIN P18 [get_ports adc1_m_sclk_o_n]
set_property PACKAGE_PIN N18 [get_ports {adc1_m_sdata_i_p[0]}]
set_property PACKAGE_PIN P19 [get_ports {adc1_m_sdata_i_n[0]}]
set_property PACKAGE_PIN T20 [get_ports {adc1_m_sdata_i_p[1]}]
set_property PACKAGE_PIN U20 [get_ports {adc1_m_sdata_i_n[1]}]
set_property PACKAGE_PIN R16 [get_ports {adc1_m_sdata_i_p[2]}]
set_property PACKAGE_PIN R17 [get_ports {adc1_m_sdata_i_n[2]}]
set_property PACKAGE_PIN V17 [get_ports {adc1_m_sdata_i_p[3]}]
set_property PACKAGE_PIN V18 [get_ports {adc1_m_sdata_i_n[3]}]

# ------------------------------------------------------------------------------
# Amplificateurs
# ------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports mod_pga_gain_o]
set_property PACKAGE_PIN K19     [get_ports {mod_pga_gain_o[0]}]
set_property PACKAGE_PIN M17     [get_ports {mod_pga_gain_o[1]}]
set_property PACKAGE_PIN M18     [get_ports {mod_pga_gain_o[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports demod_pga*]
set_property PACKAGE_PIN F19     [get_ports demod_pga_m_sclk_o]
set_property PACKAGE_PIN G17     [get_ports demod_pga_m_sdata_o]
set_property PACKAGE_PIN E18     [get_ports {demod_pga_m_ltch_n_o[0]}]
set_property PACKAGE_PIN F16     [get_ports {demod_pga_m_ltch_n_o[1]}]
set_property PACKAGE_PIN E19     [get_ports {demod_pga_m_ltch_n_o[2]}]
set_property PACKAGE_PIN F17     [get_ports {demod_pga_m_ltch_n_o[3]}]
