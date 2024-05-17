# util.mk
# Common make file utilities for TSEA83

# Version 2.0
# 2024-01-23
# Use make utilities to keep track of changed files and the need to run targets

# Version 1.0
# 2023-11-29
# Initial working version (without using make file utilities)

# Anders Nilsson

# Any Makefile including this utility should define the following variables:
# VHD : a list of space separated VHDL files in the project
# XDC : a Xilinx design constraints file
# TBF : a test bench file

# The default shell for make, /bin/sh, does not work for some commands in this file, use /bin/bash as deault instead
SHELL=/bin/bash

# Set Vivado working folder
WORK=work

# Set Modelsim simdir
SIMDIR=simdir

# Extract testbench base name (without extension)
TBF_BASE=$(shell echo "$(TBF)" | sed 's/\.[^.]*$$//')

# Extract top module (the first file) from list of (space separeated) VHD files
TOP_MODULE=$(shell echo "$(VHD)" | sed 's/ .*//')

# Create DCP file name (design check point) from top module base name
#DCP_NAME=$(shell echo "$(TOP_MODULE)" | sed 's/\.[^.]*$$/\.cdp/')
DCP_NAME=synth.dcp

# Create BIT file name from top module base name
BIT_NAME=$(shell echo "$(TOP_MODULE)" | sed 's/\.[^.]*$$/\.bit/')

# Set target FPGA (Basys3)
PART=xc7a35ticpg236-1L

# Set bin folder
BIN=$(shell pwd)

.PHONY: help
help	:
	@echo "Make utilities, Version 2.0"
	@echo "Command syntax: make [help|synth|bit|prog|sim|clean]"
	@echo "help:	Show this help"
	@echo "synth:	Synthesize project VHDL files into design checkpoint"
	@echo "bit:	Use design checkpoint to create bit file"
	@echo "prog:	Program bit file into FPGA board (must be connected and powered)"
	@echo "sim:	Start and simulate project in Modelsim simulator"
	@echo "clean:	Clean project (remove all files created by make)"

compile:
	mkdir -p $(SIMDIR)
	$(eval VHDS := $(shell for i in $(VHD); do echo "../$$i"; done))
	cd $(SIMDIR); vcom -2008 $(VHDS)

.PHONY:	synth
synth	: $(WORK)/$(DCP_NAME)

$(WORK)/$(DCP_NAME)	: $(VHD)
	mkdir -p $(WORK)
	cd $(WORK); vivado -mode batch -source $(BIN)/build.tcl -notrace -journal vivado_synth.jou -log vivado_synth.log -tclargs synth $(VHD) $(XDC)

.PHONY:	bit
bit	: $(WORK)/$(BIT_NAME)

$(WORK)/$(BIT_NAME)	: $(WORK)/$(DCP_NAME)
	mkdir -p $(WORK)
	cd $(WORK); vivado -mode batch -source $(BIN)/build.tcl -notrace -journal vivado_bit.jou -log vivado_bit.log -tclargs bit $(VHD) $(XDC)

.PHONY:	prog
prog	: $(WORK)/$(BIT_NAME)
	mkdir -p $(WORK)
	cd $(WORK); vivado -mode batch -source $(BIN)/build.tcl -notrace -journal vivado_prog.jou -log vivado_prog.log -tclargs prog $(VHD) $(XDC)


.PHONY:	sim
sim	: $(VHD) $(TBF) compile
	cp dofile $(SIMDIR)/dofile
	cd $(SIMDIR); vcom -2008 ../$(TBF)
	cd $(SIMDIR); vsim -voptargs=+acc -L work $(TBF_BASE) -do dofile

.PHONY:	clean
clean	:
	rm -rf $(WORK) $(SIMDIR) *~ 
