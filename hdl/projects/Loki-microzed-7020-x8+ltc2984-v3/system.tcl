
set vhdl08_files "
    $build_dir/LokiModem_cfg.vhd
    $build_dir/Oscillator_pkg.vhd
    $build_dir/LokiModem_osc1_pkg.vhd
    $build_dir/LokiModem_osc2_pkg.vhd
    $build_dir/LokiModem_Mixing_osc3_pkg.vhd
    $build_dir/FIRFilter_pkg.vhd
    $build_dir/LokiModem_Mixerless_lowpass_pkg.vhd
    $build_dir/LokiModem_Mixerless_bandpassX_pkg.vhd
    $build_dir/LokiModem_Mixerless_bandpassY_pkg.vhd
    $build_dir/LokiModem_Mixing_lowpass1_pkg.vhd
    $build_dir/LokiModem_Mixing_lowpass2_pkg.vhd
    $lib_dir/AXISlave/src/AXISlave.vhd
    $lib_dir/fixed_pkg/src/fixed_pkg.vhd
    $lib_dir/fixed_pkg/src/fixed_pkg_RTL.vhd
    $lib_dir/float_pkg/src/float_pkg.vhd
    $lib_dir/float_pkg/src/float_pkg_RTL.vhd
    $lib_dir/Oscillator/src/Oscillator.vhd
    $lib_dir/Oscillator/src/Oscillator_RTL.vhd
    $lib_dir/LokiModulator/src/LokiModulator.vhd
    $lib_dir/LokiModulator/src/LokiModulator_RTL.vhd
    $lib_dir/StreamController/src/StreamController.vhd
    $lib_dir/FIFOController/src/FIFOController.vhd
    $lib_dir/DelayLine/src/DelayLine.vhd
    $lib_dir/DelayLine/src/DelayLine_ShiftRegisters.vhd
    $lib_dir/FIRFilter/src/FIRFilter.vhd
    $lib_dir/FIRFilter/src/FIRFilter_RTL.vhd
    $lib_dir/LokiDemodulatorMixerless/src/LokiDemodulatorMixerless.vhd
    $lib_dir/LokiDemodulatorMixerless/src/LokiDemodulatorMixerless_RTL.vhd
    $lib_dir/LokiDemodulator/src/Mixer_RTL.vhd
    $lib_dir/LokiDemodulator/src/LokiDemodulator.vhd
    $lib_dir/LokiDemodulator/src/LokiDemodulator_RTL.vhd
    $lib_dir/LTC2325/src/LTC2325_pkg.vhd
    $lib_dir/LTC2325/src/LTC2325_RTL.vhd
    $lib_dir/LTC2984/src/LTC2984_pkg.vhd
    $lib_dir/LTC2984/src/LTC2984_RTL.vhd
    $lib_dir/BMP390/src/BMP390_pkg.vhd
    $lib_dir/BMP390/src/BMP390_RTL.vhd
    $lib_dir/LokiSensors/src/LokiSensors_pkg.vhd
    $lib_dir/AD8370/src/AD8370_RTL.vhd
    $lib_dir/InputSynchronizer/src/InputSynchronizer.vhd
	$lib_dir/ClockMonitor/src/ClockMonitor.vhd
    $lib_dir/LokiModem/src/LokiModem_pkg.vhd
    $lib_dir/LokiModem/src/LokiModem.vhd
    $lib_dir/LokiModem/src/LokiModem_RTL.vhd
"

set vhdl_files "
    $vhdl08_files
    $project_dir/Loki_cfg.vhd
    $project_dir/Loki.vhd
    $lib_dir/LokiSensors/src/LokiSensors_RTL.vhd
"

set xdc_files "
    $project_dir/io.xdc
"

add_files -norecurse $vhdl_files

if {[string trim $xdc_files] != ""} {
    add_files -norecurse $xdc_files
}

if {[string trim $vhdl08_files] != ""} {
    set_property file_type {VHDL 2008} [get_files $vhdl08_files]
}

set_property PROCESSING_ORDER LATE [get_files $xdc_files]

# ------------------------------------------------------------------------------
# Identification du FPGA et de la carte.
# ------------------------------------------------------------------------------

source "$boards_dir/microzed-7020.tcl"

# ------------------------------------------------------------------------------
# Générateur d'horloge
# ------------------------------------------------------------------------------

set clk50 [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk50]

set_property CONFIG.PRIM_IN_FREQ.VALUE_SRC USER $clk50
set_property -dict {
    CONFIG.PRIM_IN_FREQ               10.000
    CONFIG.JITTER_OPTIONS             UI
    CONFIG.CLKIN1_UI_JITTER           0.005
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 50.000
    CONFIG.USE_LOCKED                 true
    CONFIG.USE_RESET                  false
} $clk50

create_bd_port -dir I gps_clk10m_i
set_property CONFIG.FREQ_HZ 10000000 [get_bd_ports gps_clk10m_i]

connect /clk50/clk_in1 gps_clk10m_i

set pl_clk /clk50/clk_out1

# ------------------------------------------------------------------------------
# Processing System
# ------------------------------------------------------------------------------

set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
    make_external "FIXED_IO, DDR"
    apply_board_preset 1
    Master Disable
    Slave Disable
}  $ps7

# Configurer l'horloge de la logique programmable à 50 MHz.
#
# Activer les interfaces :
# - HP0         : DMA (modem).
# - HP1         : DMA (LTC2325).
# - I2C0        : EEPROM pour adresse MAC
# - I2C1        : capteur de température
# - UART0       : module GPS
#
# Ces interfaces sont déjà activées dans les presets de la carte :
# - UART1 : UART sur USB
# - GPIO0 : activation de l'alimentation de la partie analogique
# - GPIO9 : reset GPS
set_property -dict {
    CONFIG.PCW_USE_M_AXI_GP0            1
    CONFIG.PCW_USE_S_AXI_HP0            1
    CONFIG.PCW_USE_S_AXI_HP1            1

    CONFIG.PCW_USE_FABRIC_INTERRUPT     1
    CONFIG.PCW_IRQ_F2P_INTR             1

    CONFIG.PCW_EN_RST0_PORT             1
    CONFIG.PCW_EN_CLK0_PORT             1
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ 50

    CONFIG.PCW_I2C0_PERIPHERAL_ENABLE   1
    CONFIG.PCW_I2C0_I2C0_IO             {MIO 10 .. 11}

    CONFIG.PCW_I2C1_PERIPHERAL_ENABLE   1
    CONFIG.PCW_I2C1_I2C1_IO             {MIO 12 .. 13}

    CONFIG.PCW_UART0_PERIPHERAL_ENABLE  1
    CONFIG.PCW_UART0_UART0_IO           {MIO 14 .. 15}

    CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE    1
    CONFIG.PCW_GPIO_EMIO_GPIO_IO        32

    CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ  50
} $ps7

connect /ps7/m_axi_gp0_aclk $pl_clk
connect /ps7/s_axi_hp0_aclk $pl_clk
connect /ps7/s_axi_hp1_aclk $pl_clk

set irq_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 irq_concat]
set_property CONFIG.NUM_PORTS 3 $irq_concat
connect /ps7/irq_f2p /irq_concat/dout

# ------------------------------------------------------------------------------
# Module AXI Modem
# ------------------------------------------------------------------------------

set modem [create_bd_cell -type module -reference Loki modem]

axi_connect /ps7/M_AXI_GP0 /modem/S_AXI

set_property -dict {
    RANGE  4K
    OFFSET 0x41220000
} [get_bd_addr_segs /ps7/Data/SEG_modem_reg0]

connect /modem/m_axis_aresetn /modem/s_axi_aresetn
connect /modem/m_axis_aclk $pl_clk

# Le bloc rst_clk50_50M a été créé automatiquement
# Son entrée locked est déjà reliée à la sortie dcm_locked du générateur d'horloge.
connect /rst_clk50_50M/ext_reset_in /ps7/fclk_reset0_n

# ------------------------------------------------------------------------------
# DAC
# ------------------------------------------------------------------------------

# Le DAC est piloté par des signaux avec différents déphasages :
#
# dac_m_clk_o : horloge du DAC (IQCLK), 50 MHz
# Elle est déphasée de 180° par rapport à l'horloge principale,
# ce qui permet d'avoir des données stables sur ses fronts montants.
#
# dac_m_write_o : commande d'écriture du DAC (IQWRT), 50 MHz
# Elle est déphasée de 30° (1,66 ns) par rapport à dac_m_clk_o,
# ce qui permet de respecter largement la contrainte de délai de 500 ps imposée
# lorsque le DAC est alimenté en 3,3V (cf datasheet).
#
# dac_m_clk_i : horloge de mise à jour des données du DAC, 50 MHz
# Cette horloge commande la mise à jour des signaux dac_m_data_o et dac_m_sel_o (IQSEL)
# qui doivent être en retard d'au moins 1,5 ns par rapport à dac_m_write_o.
# Ce délai est largement respecté en configurant un déphasage de 90° par rapport
# à l'horloge principale (5 ns).

set dac_pll [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 dac_pll]
set_property CONFIG.PRIM_IN_FREQ.VALUE_SRC USER $dac_pll
set_property -dict {
    CONFIG.PRIM_IN_FREQ               50
    CONFIG.CLKOUT2_USED               true
    CONFIG.CLKOUT3_USED               true
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 50
    CONFIG.CLKOUT1_REQUESTED_PHASE    180
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 50
    CONFIG.CLKOUT2_REQUESTED_PHASE    210
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ 50
    CONFIG.CLKOUT3_REQUESTED_PHASE    90
    CONFIG.RESET_TYPE                 ACTIVE_LOW
    CONFIG.CLKIN1_JITTER_PS           200.0
    CONFIG.MMCM_DIVCLK_DIVIDE         1
    CONFIG.MMCM_CLKFBOUT_MULT_F       21.000
    CONFIG.MMCM_CLKIN1_PERIOD         20.000
    CONFIG.MMCM_CLKIN2_PERIOD         10.0
    CONFIG.MMCM_CLKOUT0_DIVIDE_F      21.000
    CONFIG.MMCM_CLKOUT0_PHASE         180.000
    CONFIG.MMCM_CLKOUT1_DIVIDE        21
    CONFIG.MMCM_CLKOUT1_PHASE         210.000
    CONFIG.MMCM_CLKOUT2_DIVIDE        21
    CONFIG.MMCM_CLKOUT2_PHASE         90.000
    CONFIG.NUM_OUT_CLKS               3
    CONFIG.RESET_PORT                 resetn
    CONFIG.CLKOUT1_JITTER             187.143
    CONFIG.CLKOUT1_PHASE_ERROR        164.344
    CONFIG.CLKOUT2_JITTER             187.143
    CONFIG.CLKOUT2_PHASE_ERROR        164.344
    CONFIG.CLKOUT3_JITTER             187.143
    CONFIG.CLKOUT3_PHASE_ERROR        164.344
} $dac_pll

connect /dac_pll/resetn  /modem/m_axis_aresetn
connect /dac_pll/clk_in1 $pl_clk

create_bd_port -dir O dac_m_reset_o
connect /modem/dac_m_reset_o dac_m_reset_o

create_bd_port -dir O dac_m_clk_o
connect /dac_pll/clk_out1 dac_m_clk_o

create_bd_port -dir O dac_m_write_o
connect /dac_pll/clk_out2 dac_m_write_o

connect /dac_pll/clk_out3 /modem/dac_m_clk_i

create_bd_port -dir O -from 13 -to 0 dac_m_data_o
connect /modem/dac_m_data_o dac_m_data_o

create_bd_port -dir O dac_m_sel_o
connect /modem/dac_m_sel_o dac_m_sel_o

# ------------------------------------------------------------------------------
# ADC
# ------------------------------------------------------------------------------

create_bd_port -dir O adc0_m_convert_n_o
create_bd_port -dir I adc0_m_sclk_i_p
create_bd_port -dir I adc0_m_sclk_i_n
create_bd_port -dir O adc0_m_sclk_o_p
create_bd_port -dir O adc0_m_sclk_o_n
create_bd_port -dir I -from 3 -to 0 adc0_m_sdata_i_p
create_bd_port -dir I -from 3 -to 0 adc0_m_sdata_i_n

create_bd_port -dir O adc1_m_convert_n_o
create_bd_port -dir I adc1_m_sclk_i_p
create_bd_port -dir I adc1_m_sclk_i_n
create_bd_port -dir O adc1_m_sclk_o_p
create_bd_port -dir O adc1_m_sclk_o_n
create_bd_port -dir I -from 3 -to 0 adc1_m_sdata_i_p
create_bd_port -dir I -from 3 -to 0 adc1_m_sdata_i_n

connect /modem/adc0_m_convert_n_o adc0_m_convert_n_o

# Les paires différentielles du convertisseur 0 (ADA) ont été inversées
# pour faciliter le routage.
# La sortie des buffers est rétablie dans Loki.
diff_in  1 adc0_m_sclk_i_n  adc0_m_sclk_i_p  /modem/adc0_m_sclk_i
diff_out 1 adc0_m_sclk_o_n  adc0_m_sclk_o_p  /modem/adc0_m_sclk_o
diff_in  4 adc0_m_sdata_i_n adc0_m_sdata_i_p /modem/adc0_m_sdata_i

connect /modem/adc1_m_convert_n_o adc1_m_convert_n_o

diff_in  1 adc1_m_sclk_i_p  adc1_m_sclk_i_n  /modem/adc1_m_sclk_i
diff_out 1 adc1_m_sclk_o_p  adc1_m_sclk_o_n  /modem/adc1_m_sclk_o
diff_in  4 adc1_m_sdata_i_p adc1_m_sdata_i_n /modem/adc1_m_sdata_i

# ------------------------------------------------------------------------------
# Capteurs de température et de pression (LTC2984, BMP390)
# ------------------------------------------------------------------------------

set sensors [create_bd_cell -type module -reference LokiSensors sensors]

axi_connect /ps7/M_AXI_GP0 /sensors/S_AXI

set_property -dict {
    RANGE  4K
    OFFSET 0x41240000
} [get_bd_addr_segs /ps7/Data/SEG_sensors_reg0]

connect /sensors/m_axis_aresetn /sensors/s_axi_aresetn
connect /sensors/m_axis_aclk $pl_clk

create_bd_port -dir I spi_miso_i
connect /sensors/spi_miso_i spi_miso_i

create_bd_port -dir O spi_mosi_o
connect /sensors/spi_mosi_o spi_mosi_o

create_bd_port -dir O spi_sck_o
connect /sensors/spi_sck_o spi_sck_o

create_bd_port -dir O -from 1 -to 0 spi_cs_n_o
connect /sensors/spi_cs_n_o spi_cs_n_o

# ------------------------------------------------------------------------------
# XADC
# ------------------------------------------------------------------------------

set xadc [create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc]
set_property -dict {
    CONFIG.INTERFACE_SELECTION          Enable_AXI
    CONFIG.XADC_STARUP_SELECTION        channel_sequencer
    CONFIG.SEQUENCER_MODE               Continuous
    CONFIG.ADC_CONVERSION_RATE          100
    CONFIG.OT_ALARM                     false
    CONFIG.USER_TEMP_ALARM              false
    CONFIG.VCCINT_ALARM                 false
    CONFIG.VCCAUX_ALARM                 false
    CONFIG.ENABLE_VCCPINT_ALARM         false
    CONFIG.ENABLE_VCCPAUX_ALARM         false
    CONFIG.ENABLE_VCCDDRO_ALARM         false
    CONFIG.CHANNEL_ENABLE_TEMPERATURE   true
    CONFIG.CHANNEL_ENABLE_VCCINT        true
    CONFIG.CHANNEL_ENABLE_VP_VN         false
    CONFIG.CHANNEL_ENABLE_VAUXP0_VAUXN0 true
    CONFIG.CHANNEL_ENABLE_VAUXP1_VAUXN1 true
    CONFIG.AVERAGE_ENABLE_TEMPERATURE   false
    CONFIG.BIPOLAR_VAUXP0_VAUXN0        true
    CONFIG.BIPOLAR_VAUXP1_VAUXN1        true
    CONFIG.ENABLE_RESET                 false
} $xadc

axi_connect /ps7/M_AXI_GP0 /xadc/S_AXI_LITE
create_bd_port -dir I xadc0_p_i
create_bd_port -dir I xadc0_n_i
create_bd_port -dir I xadc1_p_i
create_bd_port -dir I xadc1_n_i
connect /xadc/vauxp0 /xadc0_p_i
connect /xadc/vauxn0 /xadc0_n_i
connect /xadc/vauxp1 /xadc1_p_i
connect /xadc/vauxn1 /xadc1_n_i
connect /xadc/ip2intc_irpt /irq_concat/In2

set_property OFFSET 0x41250000 [get_bd_addr_segs /ps7/Data/SEG_xadc_Reg]

# ------------------------------------------------------------------------------
# DMA (modem)
# ------------------------------------------------------------------------------

set dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma]

# La fonction scatter-gather est nécessaire pour bénéficier du mode cyclique
# dans le pilote Linux.
# C_SG_LENGTH_WIDTH détermine la taille maximum d'un paquet d'échantillons
# (cf DEMOD_PACKET_LENGTH_MAX).
set_property -dict {
    CONFIG.C_PRMRY_IS_ACLK_ASYNC      1
    CONFIG.C_INCLUDE_MM2S             0
    CONFIG.C_INCLUDE_SG               1
    CONFIG.C_SG_INCLUDE_STSCNTRL_STRM 0
    CONFIG.C_SG_LENGTH_WIDTH          16
} $dma

connect /dma/m_axi_s2mm_aclk $pl_clk
connect /dma/m_axi_sg_aclk   $pl_clk

# Sans le module ILA, on peut connecter l'interface AXI stream en une commande :
connect /modem/M_AXIS /dma/S_AXIS_S2MM

# L'ajout du module ILA exige de connecter chaque signal séparément.
# Réserver ces connexions pour une image de debug car cela contraint
# l'interface AXI stream du DMA en 32 bits (non modifiable manuellement).
# connect /modem/m_axis_tvalid /dma/s_axis_s2mm_tvalid
# connect /modem/m_axis_tdata  /dma/s_axis_s2mm_tdata
# connect /modem/m_axis_tkeep  /dma/s_axis_s2mm_tkeep
# connect /modem/m_axis_tlast  /dma/s_axis_s2mm_tlast
# connect /modem/m_axis_tready /dma/s_axis_s2mm_tready

axi_connect /ps7/M_AXI_GP0  /dma/S_AXI_LITE
axi_connect /dma/M_AXI_SG   /ps7/S_AXI_HP0
axi_connect /dma/M_AXI_S2MM /ps7/S_AXI_HP0 -intc /axi_smc

set_property CONFIG.NUM_MI 1 [get_bd_cells /axi_smc]

set_property OFFSET 0x41210000 [get_bd_addr_segs /ps7/Data/SEG_dma_Reg]

connect /dma/s2mm_introut /irq_concat/In0

# ------------------------------------------------------------------------------
# DMA (LTC2984)
# ------------------------------------------------------------------------------

set dma_ext [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma_ext]

# La fonction scatter-gather est nécessaire pour bénéficier du mode cyclique
# dans le pilote Linux.
# C_SG_LENGTH_WIDTH détermine la taille maximum d'un paquet d'échantillons
# (cf PACKET_LENGTH_MAX).
set_property -dict {
    CONFIG.C_PRMRY_IS_ACLK_ASYNC      1
    CONFIG.C_INCLUDE_MM2S             0
    CONFIG.C_INCLUDE_SG               1
    CONFIG.C_SG_INCLUDE_STSCNTRL_STRM 0
    CONFIG.C_SG_LENGTH_WIDTH          16
} $dma_ext

connect /dma_ext/m_axi_s2mm_aclk $pl_clk
connect /dma_ext/m_axi_sg_aclk   $pl_clk

connect /sensors/M_AXIS /dma_ext/S_AXIS_S2MM

axi_connect /ps7/M_AXI_GP0      /dma_ext/S_AXI_LITE
axi_connect /dma_ext/M_AXI_SG   /ps7/S_AXI_HP1
axi_connect /dma_ext/M_AXI_S2MM /ps7/S_AXI_HP1 -intc /axi_smc_1

set_property CONFIG.NUM_MI 1 [get_bd_cells /axi_smc_1]

set_property OFFSET 0x41230000 [get_bd_addr_segs /ps7/Data/SEG_dma_ext_Reg]

connect /dma_ext/s2mm_introut /irq_concat/In1

# ------------------------------------------------------------------------------
# GPIO, PGA
# ------------------------------------------------------------------------------

create_bd_port -dir I sw_i
connect sw_i /modem/sw_i

create_bd_port -dir O -from 2 -to 0 mod_pga_gain_o
connect mod_pga_gain_o /modem/mod_pga_gain_o

create_bd_port -dir O demod_pga_m_sclk_o
connect demod_pga_m_sclk_o /modem/demod_pga_m_sclk_o

create_bd_port -dir O demod_pga_m_sdata_o
connect demod_pga_m_sdata_o /modem/demod_pga_m_sdata_o

create_bd_port -dir O -from 7 -to 0 demod_pga_m_ltch_n_o
connect demod_pga_m_ltch_n_o /modem/demod_pga_m_ltch_n_o

create_bd_port -dir I gps_clk1pps_i
connect gps_clk1pps_i /modem/gps_clk1pps_i

connect gps_clk10m_i /modem/gps_clk10m_i

create_bd_port -dir I gps_clk30m72_i
connect gps_clk30m72_i /modem/gps_clk30m72_i

create_bd_port -dir O gps_tstamp_o
connect gps_tstamp_o /modem/gps_tstamp_o

connect /modem/ps7_gpio_o /ps7/GPIO_I
connect /modem/ps7_gpio_i /ps7/GPIO_O

# ------------------------------------------------------------------------------
# Horloges
# ------------------------------------------------------------------------------

create_bd_port -dir I sync_10M_i
connect sync_10M_i /modem/sync_10M_i

create_bd_port -dir O sync_10M_o
connect sync_10M_o /modem/sync_10M_o

# ------------------------------------------------------------------------------
# Debug par JTAG
# ------------------------------------------------------------------------------

# set ila [create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila]
#
# set_property -dict {
#     CONFIG.C_NUM_OF_PROBES 4
#     CONFIG.C_ENABLE_ILA_AXI_MON false
#     CONFIG.C_MONITOR_TYPE Native
#     CONFIG.C_DATA_DEPTH 65536
# } $ila
#
# connect /ila/probe0 /modem/m_axis_tvalid
# connect /ila/probe1 /modem/m_axis_tready
# connect /ila/probe2 /modem/m_axis_tlast
# connect /ila/probe3 /dma/s2mm_introut
# connect /ila/clk    /modem/m_axis_aclk
