
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
LIB_DIR := $(THIS_DIR)/../../lib

GHDL_FLAGS += \
	--workdir=build \
	--std=08

all: build/boot.bin build/system.dts

build/system_prj.xpr: $(SRC)
	mkdir -p build
	vivado -mode batch -source $(THIS_DIR)/project.tcl

build/system.bit: build/system_prj.xpr
	vivado -mode batch -source $(THIS_DIR)/bitstream.tcl

build/sdk/fsbl/Release/fsbl.elf: build/system.bit
	rm -rf build/sdk
	xsdk -batch -source $(THIS_DIR)/fsbl.tcl

build/boot.bin: boot.bif build/sdk/fsbl/Release/fsbl.elf
	bootgen -w -image $< -o $@

build/system.dts: build/system.bit
	hsi -mode batch -source $(THIS_DIR)/dts.tcl

build/%.vhd: %.json
	mkdir -p $(shell dirname $@)
	python3 $(LIB_DIR)/scripts/json-to-package.py $< > $@

build/%.vhd: %.py
	mkdir -p $(shell dirname $@)
	PYTHONPATH=$(LIB_DIR) python3 -m $(subst /,.,$(basename $<)) > $@

check: $(VHDL_SRC)
	mkdir -p build
	ghdl -a $(GHDL_FLAGS) $(VHDL_SRC)
	ghdl -e $(GHDL_FLAGS) $(MAIN)

clean:
	rm -rf build/* *.jou *.log .Xil *.str
