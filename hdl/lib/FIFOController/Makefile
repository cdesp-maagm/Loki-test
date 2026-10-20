
MODULE = FIFOController

# Fichiers sources communs.
COMMON_SRC = \
	src/$(MODULE).vhd

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = RTL

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	test/$(MODULE)Testbench.vhd

include ../scripts/common.make
