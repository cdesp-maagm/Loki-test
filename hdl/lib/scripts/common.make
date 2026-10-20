#
# Variables à définir dans le script parent :
#
#   MODULE      - Le nom de l'unité de conception principale
#	TEST_SRC    - La liste des fichiers sources VHDL à simuler.
#	TEST_ENTITY - (optionnel) Le nom de l'entité banc de test à simuler.
#   TEST_DATA   - (optionnel) Le fichier contenant les données de test.
#	IMPL_SRC    - La liste des fichiers sources VHDL à synthétiser.
#   IMPL_SCRIPT - le nom du script de synthèse des exemples.
#   GHDL_FLAGS  - (optionnel) Des options à passer à GHDL en plus des options par défaut.
#

THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

GHDL_FLAGS += \
	--workdir=build \
	--std=08

TEST_ENTITY ?= $(MODULE)Testbench

TEST_BIN = $(shell echo $(TEST_ENTITY) | tr A-Z a-z)

.PHONY: all run wave syn clean

all: $(TEST_BIN)

run: $(TEST_BIN) $(TEST_DATA)
	mkdir -p build/tb
	# Simulation avec Xilinx Xsim. Support incomplet de VHDL2008
	# xvhdl -2008 -work work=build/tb/work $(TEST_SRC)
	# xelab -lib work=build/tb/work work.$(MODULE)Testbench
	# xsim -runall work.$(MODULE)Testbench
	ghdl run $(GHDL_FLAGS) $(TEST_ENTITY) --ieee-asserts=disable-at-0

wave: $(TEST_BIN).ghw

$(TEST_BIN): $(TEST_SRC)
	mkdir -p build/tb
	ghdl analyze $(GHDL_FLAGS) $(TEST_SRC)
	ghdl elaborate $(GHDL_FLAGS) $(TEST_ENTITY)

syn: vivado.log

vivado.log: $(IMPL_SCRIPT) $(IMPL_SRC)
	mkdir -p build
	vivado -mode batch -source $<

build/%.vhd: %.json
	mkdir -p $(shell dirname $@)
	python3 $(THIS_DIR)/json-to-package.py $< > $@

build/%.vhd: %.py
	mkdir -p $(shell dirname $@)
	PYTHONPATH=$(THIS_DIR)/.. python3 -m $(subst /,.,$(basename $<)) > $@

%.ghw: % $(TEST_DATA)
	mkdir -p build/tb
	./$< --wave=$@ --ieee-asserts=disable-at-0

build/%.csv: %.py
	mkdir -p $(shell dirname $@)
	PYTHONPATH=$(THIS_DIR)/.. python3 -m $(subst /,.,$(basename $<)) > $@

clean:
	rm -rf build/* $(TEST_BIN) e~$(TEST_BIN).o *.log *.jou *.ghw .Xil
