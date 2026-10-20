
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
    $lib_dir/LTC2984/src/LTC2984_pkg.vhd
    $lib_dir/LTC2984/src/LTC2984_RTL.vhd
    $lib_dir/BMP390/src/BMP390_pkg.vhd
    $lib_dir/BMP390/src/BMP390_RTL.vhd
    $lib_dir/LokiSensors/src/LokiSensors_pkg.vhd
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

source "$boards_dir/redpitaya.tcl"

# ------------------------------------------------------------------------------
# Processing System
# ------------------------------------------------------------------------------

set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
    make_external "FIXED_IO, DDR"
    apply_board_preset 0
    Master Disable
    Slave Disable
}  $ps7

set_property -dict $redpitaya_preset $ps7

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
    CONFIG.PCW_I2C0_I2C0_IO             {MIO 50 .. 51}

    CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ  50
} $ps7

set irq_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 irq_concat]
set_property CONFIG.NUM_PORTS 2 $irq_concat
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
connect /modem/m_axis_aclk    /modem/s_axi_aclk

create_bd_port -dir O -from 13 -to 0 dac_m_data_o
connect /modem/dac_m_data_o dac_m_data_o

create_bd_port -dir O dac_m_clk_o
connect /modem/dac_m_clk_o dac_m_clk_o

create_bd_port -dir O dac_m_write_o
connect /modem/dac_m_write_o dac_m_write_o

create_bd_port -dir O dac_m_sel_o
connect /modem/dac_m_sel_o /dac_m_sel_o

create_bd_port -dir O dac_m_reset_o
connect /modem/dac_m_reset_o /dac_m_reset_o

create_bd_port -dir O -from 15 -to 0 probe_o
connect /modem/probe_o probe_o

# ------------------------------------------------------------------------------
# Horloge ADC
# ------------------------------------------------------------------------------

create_bd_port -dir O -from 1 -to 0 adc_clk_o
connect /modem/adc_clk_o adc_clk_o

create_bd_port -dir O adc_cdcs_o
connect /modem/adc_cdcs_o /adc_cdcs_o

set adc_clk_buf [create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 adc_clk_buf]
set_property CONFIG.C_BUF_TYPE IBUFDS $adc_clk_buf

create_bd_port -dir I adc_clk_p_i
connect /adc_clk_buf/ibuf_ds_p /adc_clk_p_i

create_bd_port -dir I adc_clk_n_i
connect /adc_clk_buf/ibuf_ds_n /adc_clk_n_i

# ------------------------------------------------------------------------------
# Données ADC (full rate : 14 bits par voie)
# ------------------------------------------------------------------------------

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 one
set one /one/dout

create_bd_port -dir I -from 13 -to 0 adc_s0_data_i

set clk_conv_a [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 clk_conv_a]

set_property CONFIG.TDATA_NUM_BYTES 2 $clk_conv_a

connect /clk_conv_a/s_axis_aclk    /adc_clk_buf/ibuf_out
connect /clk_conv_a/s_axis_aresetn $one
connect /clk_conv_a/s_axis_tvalid  $one
connect /clk_conv_a/s_axis_tdata   /adc_s0_data_i

connect /clk_conv_a/m_axis_aclk    /modem/m_axis_aclk
connect /clk_conv_a/m_axis_aresetn $one
connect /clk_conv_a/m_axis_tvalid  /modem/adc_s0_valid_i
connect /clk_conv_a/m_axis_tready  /modem/adc_s0_ready_o
connect /clk_conv_a/m_axis_tdata   /modem/adc_s0_data_i

create_bd_port -dir I -from 13 -to 0 adc_s1_data_i

set clk_conv_b [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 clk_conv_b]

set_property CONFIG.TDATA_NUM_BYTES 2 $clk_conv_b

connect /clk_conv_b/s_axis_aclk    /adc_clk_buf/ibuf_out
connect /clk_conv_b/s_axis_aresetn $one
connect /clk_conv_b/s_axis_tvalid  $one
connect /clk_conv_b/s_axis_tdata   /adc_s1_data_i

connect /clk_conv_b/m_axis_aclk    /modem/m_axis_aclk
connect /clk_conv_b/m_axis_aresetn $one
connect /clk_conv_b/m_axis_tvalid  /modem/adc_s1_valid_i
connect /clk_conv_b/m_axis_tready  /modem/adc_s1_ready_o
connect /clk_conv_b/m_axis_tdata   /modem/adc_s1_data_i

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
connect /sensors/m_axis_aclk /modem/m_axis_aclk

connect /sensors/spi_miso_i $one

# ------------------------------------------------------------------------------
# DMA (modem)
# ------------------------------------------------------------------------------

set dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma]

# La fonction scatter-gather est nécessaire pour bénéficier du mode cyclique
# dans le pilote Linux.
# C_SG_LENGTH_WIDTH détermine la taille maximum d'un paquet d'échantillons
# (cf DEMOD_PACKET_LENGTH_MAX).
set_property -dict {
    CONFIG.C_PRMRY_IS_ACLK_ASYNC      0
    CONFIG.C_INCLUDE_MM2S             0
    CONFIG.C_INCLUDE_SG               1
    CONFIG.C_SG_INCLUDE_STSCNTRL_STRM 0
    CONFIG.C_SG_LENGTH_WIDTH          16
} $dma

connect /modem/M_AXIS /dma/S_AXIS_S2MM

axi_connect /ps7/M_AXI_GP0  /dma/S_AXI_LITE
axi_connect /dma/M_AXI_SG   /ps7/S_AXI_HP0
axi_connect /dma/M_AXI_S2MM /ps7/S_AXI_HP0 -intc /axi_smc

set_property CONFIG.NUM_MI 1 [get_bd_cells /axi_smc]

set_property OFFSET 0x41210000 [get_bd_addr_segs /ps7/Data/SEG_dma_Reg]

connect /dma/s2mm_introut /irq_concat/In0

# ------------------------------------------------------------------------------
# DMA (sensors)
# ------------------------------------------------------------------------------

set dma_ext [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma_ext]

# La fonction scatter-gather est nécessaire pour bénéficier du mode cyclique
# dans le pilote Linux.
# C_SG_LENGTH_WIDTH détermine la taille maximum d'un paquet d'échantillons
# (cf PACKET_LENGTH_MAX).
set_property -dict {
    CONFIG.C_PRMRY_IS_ACLK_ASYNC      0
    CONFIG.C_INCLUDE_MM2S             0
    CONFIG.C_INCLUDE_SG               1
    CONFIG.C_SG_INCLUDE_STSCNTRL_STRM 0
    CONFIG.C_SG_LENGTH_WIDTH          16
} $dma_ext

connect /sensors/M_AXIS /dma_ext/S_AXIS_S2MM

axi_connect /ps7/M_AXI_GP0      /dma_ext/S_AXI_LITE
axi_connect /dma_ext/M_AXI_SG   /ps7/S_AXI_HP1
axi_connect /dma_ext/M_AXI_S2MM /ps7/S_AXI_HP1 -intc /axi_smc_1

set_property CONFIG.NUM_MI 1 [get_bd_cells /axi_smc_1]

set_property OFFSET 0x41230000 [get_bd_addr_segs /ps7/Data/SEG_dma_ext_Reg]

connect /dma_ext/s2mm_introut /irq_concat/In1

# ------------------------------------------------------------------------------
# LEDs
# ------------------------------------------------------------------------------

create_bd_port -dir O -from 7 -to 0 led_o

connect /ps7/gpio_o /led_o
