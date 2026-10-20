
MODULE = fixed

# Fichiers sources communs.
COMMON_SRC = \
	src/$(MODULE)_pkg.vhd \

# --------------------------------------------
# Simulation
# --------------------------------------------

ARCH = Simulation

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	src/$(MODULE)_pkg_$(ARCH).vhd \
	test/$(MODULE)Testbench.vhd

include ../scripts/common.make
