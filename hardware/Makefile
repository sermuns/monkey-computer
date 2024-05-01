# Files in the project. Make sure the first file is the top module
VHD = main.vhd cpu.vhd alu.vhd tile_rom.vhd vga_motor.vhd pMem.vhd uMem.vhd

# Design constraints file
XDC = Basys3.xdc

# Testbench file
TBF = cpu_tb.vhd

.PHONY: emulate
emulate:
	@python scripts/emulate.py

# Include Makefile utilities
include util.mk
