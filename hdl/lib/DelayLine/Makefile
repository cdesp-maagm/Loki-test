
MODULE = DelayLine

# Fichiers sources communs.
COMMON_SRC = \
	../fixed_pkg/src/fixed_pkg.vhd \
	../fixed_pkg/src/fixed_pkg_RTL.vhd \
	src/$(MODULE).vhd \
	src/$(MODULE)_ShiftRegisters.vhd \
	src/$(MODULE)_RAM.vhd \

# --------------------------------------------
# Simulation
# --------------------------------------------

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	test/$(MODULE)Testbench_cfg.vhd \
	test/$(MODULE)Testbench.vhd

# --------------------------------------------
# Synthèse des exemples
# --------------------------------------------

IMPL_SRC = $(COMMON_SRC) \
	examples/$(MODULE)Examples_cfg.vhd \
	examples/$(MODULE)RAMExample.vhd \
	examples/$(MODULE)ShiftRegistersExample.vhd

IMPL_SCRIPT = examples/$(MODULE)Examples.tcl

include ../scripts/common.make
