
MODULE = LokiSensors

# Fichiers sources communs.
COMMON_SRC = \
	../AXISlave/src/AXISlave.vhd \
	../LTC2984/src/LTC2984_pkg.vhd \
	../LTC2984/src/LTC2984_RTL.vhd \
	../BMP390/src/BMP390_pkg.vhd \
	../BMP390/src/BMP390_RTL.vhd \
	src/$(MODULE)_pkg.vhd \
	src/$(MODULE)_RTL.vhd

# --------------------------------------------
# Simulation
# --------------------------------------------

# L'architecture à simuler.
TEST_ARCH = RTL

# Fichiers sources du banc de test.
TEST_SRC = $(COMMON_SRC) \
	test/$(MODULE)Testbench.vhd

include ../scripts/common.make
