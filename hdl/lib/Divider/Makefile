
MODULE = Divider

# Fichiers sources communs.
COMMON_SRC = \
	../fixed_pkg/src/fixed_pkg.vhd \
	../fixed_pkg/src/fixed_pkg_RTL.vhd \
	src/$(MODULE).vhd \

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = Slow

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	build/tb/$(MODULE)Testbench_cfg.vhd \
	src/$(MODULE)_$(TEST_ARCH).vhd \
	tb/$(MODULE)Testbench.vhd

# Les données de test.
TEST_DATA = build/tb/$(MODULE)Testbench_in.csv

include ../scripts/common.make
