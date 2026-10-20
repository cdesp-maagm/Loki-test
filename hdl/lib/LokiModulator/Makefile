
MODULE = LokiModulator

# Fichiers sources communs.
COMMON_SRC = \
	../fixed_pkg/src/fixed_pkg.vhd \
	../StreamController/src/StreamController.vhd

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = RTL

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	../fixed_pkg/src/fixed_pkg_Simulation.vhd \
	build/tb/$(MODULE)Testbench_cfg.vhd \
	build/tb/Oscillator_pkg.vhd \
	build/tb/$(MODULE)Testbench_osc1_pkg.vhd \
	build/tb/$(MODULE)Testbench_osc2_pkg.vhd \
	../Oscillator/src/Oscillator.vhd \
	../Oscillator/src/Oscillator_Simulation.vhd \
	../DelayLine/src/DelayLine.vhd \
	../DelayLine/src/DelayLine_ShiftRegisters.vhd \
	../DisplacementSensor/src/DisplacementSensor.vhd \
	../DisplacementSensor/src/DisplacementSensor_Simulation.vhd \
	src/$(MODULE).vhd \
	src/$(MODULE)_$(TEST_ARCH).vhd \
	tb/$(MODULE)Testbench.vhd

include ../scripts/common.make
