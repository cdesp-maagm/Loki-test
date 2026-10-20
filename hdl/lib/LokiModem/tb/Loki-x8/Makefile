
MODULE = LokiModem

# Fichiers sources communs.
COMMON_SRC = \
	../../../AXISlave/src/AXISlave.vhd \
	../../../float_pkg/src/float_pkg.vhd \
	../../../fixed_pkg/src/fixed_pkg.vhd

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = RTL

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	../../../fixed_pkg/src/fixed_pkg_Simulation.vhd \
	../../../float_pkg/src/float_pkg_RTL.vhd \
	build/$(MODULE)_cfg.vhd \
	build/Oscillator_pkg.vhd \
	build/$(MODULE)_osc1_pkg.vhd \
	build/$(MODULE)_osc2_pkg.vhd \
	build/$(MODULE)_Mixing_osc3_pkg.vhd \
	build/FIRFilter_pkg.vhd \
	build/$(MODULE)_Mixerless_lowpass_pkg.vhd \
	build/$(MODULE)_Mixerless_bandpassX_pkg.vhd \
	build/$(MODULE)_Mixerless_bandpassY_pkg.vhd \
	build/$(MODULE)_Mixing_lowpass1_pkg.vhd \
	build/$(MODULE)_Mixing_lowpass2_pkg.vhd \
	../../../Oscillator/src/Oscillator.vhd \
	../../../Oscillator/src/Oscillator_RTL.vhd \
	../../../LokiModulator/src/LokiModulator.vhd \
	../../../LokiModulator/src/LokiModulator_RTL.vhd \
	../../../DelayLine/src/DelayLine.vhd \
	../../../DelayLine/src/DelayLine_ShiftRegisters.vhd \
	../../../StreamController/src/StreamController.vhd \
	../../../FIFOController/src/FIFOController.vhd \
	../../../FIRFilter/src/FIRFilter.vhd \
	../../../FIRFilter/src/FIRFilter_Simulation.vhd \
	../../../InputSynchronizer/src/InputSynchronizer.vhd \
	../../../ClockMonitor/src/ClockMonitor.vhd \
	../../../LokiDemodulatorMixerless/src/LokiDemodulatorMixerless.vhd \
	../../../LokiDemodulatorMixerless/src/LokiDemodulatorMixerless_RTL.vhd \
	../../../LokiDemodulator/src/Mixer_RTL.vhd \
	../../../LokiDemodulator/src/LokiDemodulator.vhd \
	../../../LokiDemodulator/src/LokiDemodulator_RTL.vhd \
	../../../DisplacementSensor/src/DisplacementSensor.vhd \
	../../../DisplacementSensor/src/DisplacementSensor_Simulation.vhd \
	../../src/$(MODULE).vhd \
	../../src/$(MODULE)_pkg.vhd \
	../../src/$(MODULE)_$(TEST_ARCH).vhd \
	build/$(MODULE)Testbench_cfg.vhd \
	../$(MODULE)Testbench.vhd

include ../../../scripts/common.make
