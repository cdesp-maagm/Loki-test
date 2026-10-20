
set vhdl08_files ""

set vhdl_files "
    $vhdl08_files
    $lib_dir/AXISlave/src/AXISlave.vhd
    $lib_dir/AXIStreamTransceiver/src/AXIStreamTransceiver.vhd
    $lib_dir/AXIStreamTransceiver/src/AXIStreamTransceiver_Stub.vhd
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

# Activer les interfaces esclaves HP0 et HP1 pour le DMA.
set_property -dict {
    CONFIG.PCW_USE_M_AXI_GP0        1
    CONFIG.PCW_USE_S_AXI_HP0        1
    CONFIG.PCW_USE_S_AXI_HP1        1

    CONFIG.PCW_USE_FABRIC_INTERRUPT 1
    CONFIG.PCW_IRQ_F2P_INTR         1
} $ps7

# Le noeud clk représentera l'horloge de tout le système.
connect /ps7/fclk_clk0 /clk

# Créer des lignes d'interruption pour le DMA.
set irq_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 irq_concat]

set_property -dict {
    CONFIG.NUM_PORTS 2
} $irq_concat

connect /ps7/irq_f2p /irq_concat/dout

# ------------------------------------------------------------------------------
# Module AXI stream transceiver
# ------------------------------------------------------------------------------

set transceiver [create_bd_cell -type module -reference AXIStreamTransceiver transceiver]

axi_connect /ps7/M_AXI_GP0 /transceiver/S_AXI

set_property -dict {
    RANGE  4K
    OFFSET 0x41220000
} [get_bd_addr_segs /ps7/Data/SEG_transceiver_reg0]

set transceiver_reset [get_bd_nets -of_objects [get_bd_pins /transceiver/s_axi_aresetn]]

# ------------------------------------------------------------------------------
# DMA
# ------------------------------------------------------------------------------

set dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma]

set_property -dict {
    CONFIG.C_INCLUDE_SG               0
    CONFIG.C_SG_INCLUDE_STSCNTRL_STRM 0
    CONFIG.C_SG_LENGTH_WIDTH          16
} $dma

axi_connect /ps7/M_AXI_GP0  /dma/S_AXI_LITE
axi_connect /dma/M_AXI_MM2S /ps7/S_AXI_HP0
axi_connect /dma/M_AXI_S2MM /ps7/S_AXI_HP1

set_property OFFSET 0x41210000 [get_bd_addr_segs /ps7/Data/SEG_dma_Reg]

connect /dma/mm2s_introut /irq_concat/in0
connect /dma/s2mm_introut /irq_concat/in1

connect /transceiver/M_AXIS         /dma/S_AXIS_S2MM
connect /transceiver/m_axis_aclk    /clk
connect /transceiver/m_axis_aresetn $transceiver_reset

connect /transceiver/S_AXIS         /dma/M_AXIS_MM2S
connect /transceiver/s_axis_aclk    /clk
connect /transceiver/s_axis_aresetn $transceiver_reset

# ------------------------------------------------------------------------------
# LEDs
# ------------------------------------------------------------------------------

create_bd_port -dir O -from 7 -to 0 led_o

connect /ps7/gpio_o /led_o
