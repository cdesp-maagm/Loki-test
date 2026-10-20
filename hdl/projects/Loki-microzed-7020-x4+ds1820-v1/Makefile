
LIB=../../lib

VHDL_SRC = \
	$(LIB)/fixed_pkg/src/fixed_pkg.vhd \
	$(LIB)/fixed_pkg/src/fixed_pkg_RTL.vhd \
	$(LIB)/float_pkg/src/float_pkg.vhd \
	$(LIB)/float_pkg/src/float_pkg_RTL.vhd \
	build/LokiModem_cfg.vhd \
	build/Oscillator_pkg.vhd \
	build/LokiModem_osc1_pkg.vhd \
	build/LokiModem_osc2_pkg.vhd \
	build/LokiModem_Mixing_osc3_pkg.vhd \
	build/FIRFilter_pkg.vhd \
	build/LokiModem_Mixerless_lowpass_pkg.vhd \
	build/LokiModem_Mixerless_bandpassX_pkg.vhd \
	build/LokiModem_Mixerless_bandpassY_pkg.vhd \
	build/LokiModem_Mixing_lowpass1_pkg.vhd \
	build/LokiModem_Mixing_lowpass2_pkg.vhd \
	$(LIB)/AXISlave/src/AXISlave.vhd \
	$(LIB)/Oscillator/src/Oscillator.vhd \
	$(LIB)/Oscillator/src/Oscillator_RTL.vhd \
	$(LIB)/LokiModulator/src/LokiModulator.vhd \
	$(LIB)/LokiModulator/src/LokiModulator_RTL.vhd \
	$(LIB)/StreamController/src/StreamController.vhd \
	$(LIB)/FIFOController/src/FIFOController.vhd \
	$(LIB)/DelayLine/src/DelayLine.vhd \
	$(LIB)/DelayLine/src/DelayLine_ShiftRegisters.vhd \
	$(LIB)/FIRFilter/src/FIRFilter.vhd \
	$(LIB)/FIRFilter/src/FIRFilter_RTL.vhd \
	$(LIB)/InputSynchronizer/src/InputSynchronizer.vhd \
	$(LIB)/ClockMonitor/src/ClockMonitor.vhd \
	$(LIB)/LokiDemodulatorMixerless/src/LokiDemodulatorMixerless.vhd \
	$(LIB)/LokiDemodulatorMixerless/src/LokiDemodulatorMixerless_RTL.vhd \
	$(LIB)/LokiDemodulator/src/Mixer_RTL.vhd \
	$(LIB)/LokiDemodulator/src/LokiDemodulator.vhd \
	$(LIB)/LokiDemodulator/src/LokiDemodulator_RTL.vhd \
	$(LIB)/LokiModem/src/LokiModem_pkg.vhd \
	$(LIB)/LokiModem/src/LokiModem.vhd \
	$(LIB)/LokiModem/src/LokiModem_RTL.vhd \
	$(LIB)/AD8370/src/AD8370_RTL.vhd \
	$(LIB)/LTC2325/src/LTC2325_pkg.vhd \
	$(LIB)/LTC2325/src/LTC2325_RTL.vhd \
	$(LIB)/DS1820/src/ow_bit.vhd \
    $(LIB)/DS1820/src/ow_byte.vhd \
    $(LIB)/DS1820/src/ow_idram.vhd \
    $(LIB)/DS1820/src/ow_search.vhd \
    $(LIB)/DS1820/src/ow_temp.vhd \
    $(LIB)/DS1820/src/ow_mstr.vhd \
    $(LIB)/DS1820/src/ds1820_mstr.vhd \
	$(LIB)/DS1820/src/DS1820_pkg.vhd \
	$(LIB)/DS1820/src/DS1820_AXI_RTL.vhd \
	Loki_cfg.vhd \
	Loki.vhd

SRC = \
	system.tcl \
	io.xdc \
	$(VHDL_SRC)

MAIN = Loki

include ../scripts/common.make
