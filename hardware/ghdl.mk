.PHONY: help clean %.ghw

WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
SCRIPTDIR = scripts
GHDL_FLAGS = --std=08 --workdir=$(WORKDIR) 

# can be compiled in any order
STANDALONE_MODULES = alu.vhd uMem.vhd pMem.vhd tile_rom.vhd
# these rely on other modules, and must be compiled in this order
DEPENDENT_MODULES = vga_motor.vhd cpu.vhd main.vhd

ALL_MODULES = $(STANDALONE_MODULES) $(DEPENDENT_MODULES)
SRC_DIR = 
SOURCE_FILES = $(addprefix $(SRC_DIR),$(ALL_MODULES))

# try to compile all files
help:
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":"}; {printf " \033[36m%-30s\033[0m\n", $$1}'

parse_umem:
	@python $(SCRIPTDIR)/parse_mem.py uMem.vhd
 
preprocess:
	@python $(SCRIPTDIR)/preprocess.py -q

clean:
	@rm -rf $(WORKDIR) $(WAVEDIR)

compile: $(WORKDIR)
	@ghdl -a $(GHDL_FLAGS) $(SOURCE_FILES)

$(WORKDIR):
	@mkdir -p $(WORKDIR)

all: parse_umem preprocess compile ## Should be used to compile all files

%_tb.vhd: all
	@ghdl -a $(GHDL_FLAGS) src/$@
	@ghdl -e $(GHDL_FLAGS) $*_tb
	@mkdir -p $(WAVEDIR)
# Allow for simulation to fail
	-@ghdl -r $(GHDL_FLAGS) $*_tb --wave=$(WAVEDIR)/$*_tb.ghw --ieee-asserts=disable-at-0

%.ghw: ## Launch wave in GTKWave, if not already running
	@if ! pgrep -x "gtkwave" > /dev/null; then \
		gtkwave -a $(SAVEDIR)/$*.gtkw $(WAVEDIR)/$*.ghw & \
	fi

gtk: all cpu_tb.vhd cpu_tb.ghw ## Simulate, then launch wave

assemble: ## Assemble a program from src/masm into pMem.vhd
	@if [ -z $(prog) ]; then \
		echo "ERROR: No program given. Usage: make assemble prog=<name of program (without extension .masm) in src/masm>"; \
		exit 1; \
	fi
	@python3 $(SCRIPTDIR)/assembler.py $(prog)

sim_video: video_tb.vhd video_tb.ghw ## Simulate the video module
