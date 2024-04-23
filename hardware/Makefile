.PHONY: clean

WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
SCRIPTDIR = scripts
GHDL_FLAGS = --std=08 --workdir=$(WORKDIR)

# bigger modules rely on these standalone modules
PREREQUISITE_MODULES = alu.vhd uMem.vhd pMem.vhd tile_rom.vhd

# these modules rely on the above modules
DEPENDENT_MODULES = vga_motor.vhd cpu.vhd main.vhd

ALL_MODULES = $(PREREQUISITE_MODULES) $(DEPENDENT_MODULES)
SOURCE_FILES = $(addprefix src/,$(ALL_MODULES))

# try to compile all files
help:
	@echo "No make target specified, look in the Makefile for possible targets."

parse_umem:
	@python $(SCRIPTDIR)/parse_mem.py src/uMem.vhd
 
preprocess:
	@python $(SCRIPTDIR)/preprocess.py -q

clean:
	@rm -rf $(WORKDIR) $(WAVEDIR)

compile:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(GHDL_FLAGS) $(SOURCE_FILES)

all: parse_umem preprocess compile

test: all
	@ghdl -a $(GHDL_FLAGS) src/cpu_tb.vhd
	@ghdl -e $(GHDL_FLAGS) cpu_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(GHDL_FLAGS) cpu_tb --wave=$(WAVEDIR)/wave.ghw

# only launch gtkwave if it is not already running
wave: test
	@if ! pgrep -x "gtkwave" > /dev/null; then \
		gtkwave -a $(SAVEDIR)/cpu_tb_save.gtkw $(WAVEDIR)/wave.ghw & \
	fi

# assemble the argument `prog` and input into pMem.vhd
assemble:
	@if [ -z $(prog) ]; then \
		echo "ERROR: No program given. Usage: make assemble prog=<name of program (without extension .masm) in src/masm>"; \
		exit 1; \
	fi
	@python3 $(SCRIPTDIR)/assembler.py src/masm/$(prog)