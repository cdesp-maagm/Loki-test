
MODULE = LTC2325

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = RTL

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	src/$(MODULE)_pkg.vhd \
	src/$(MODULE)_$(TEST_ARCH).vhd \
	test/$(MODULE)Testbench.vhd

include ../scripts/common.make
