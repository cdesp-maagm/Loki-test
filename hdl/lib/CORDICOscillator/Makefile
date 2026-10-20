
MODULE = CORDICOscillator

# Fichiers sources communs.
COMMON_SRC = \
	../fixed_pkg/src/fixed_pkg.vhd \
	../fixed_pkg/src/fixed_pkg_RTL.vhd \
	src/$(MODULE).vhd

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = RTL

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	build/tb/$(MODULE)Testbench_cfg.vhd \
	build/tb/CORDIC_pkg.vhd \
	../CORDIC/src/CORDIC.vhd \
	../CORDIC/src/CORDIC_Simulation.vhd \
	src/$(MODULE)_$(TEST_ARCH).vhd \
	tb/$(MODULE)Testbench.vhd

# --------------------------------------------
# Synthèse des exemples
# --------------------------------------------

IMPL_SRC = $(COMMON_SRC) \
	build/examples/$(MODULE)Example_cfg.vhd \
	build/examples/CORDIC_pkg.vhd \
	../CORDIC/src/CORDIC.vhd \
	../CORDIC/src/CORDIC_RTL.vhd \
	src/$(MODULE)_RTL.vhd \
	examples/$(MODULE)Example.vhd

IMPL_SCRIPT = examples/$(MODULE)Example.tcl

include ../scripts/common.make
