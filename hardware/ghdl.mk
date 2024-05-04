WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
SCRIPTDIR = ../scripts
GHDL_FLAGS = --std=08 --workdir=$(WORKDIR) 
SRC_DIR=.

# can be compiled in any order
STANDALONE_MODULES = alu.vhd uMem.vhd pMem.vhd tile_rom.vhd
# these rely on other modules, and must be compiled in this order
DEPENDENT_MODULES = vga_motor.vhd cpu.vhd main.vhd

ALL_MODULES = $(STANDALONE_MODULES) $(DEPENDENT_MODULES)
SOURCE_FILES = $(addprefix $(SRC_DIR)/,$(ALL_MODULES))

.PHONY: ghelp
ghelp:
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":"}; {printf " \033[36m%-30s\033[0m\n", $$1}'

parse_umem:
	@python $(SCRIPTDIR)/parse_mem.py $(SRC_DIR)/uMem.vhd
 
preprocess:
	@python $(SCRIPTDIR)/preprocess.py -q

.PHONY: gclean
gclean:
	rm -rf $(WORKDIR) $(WAVEDIR)

ghdl: $(WORKDIR)
	@ghdl -a $(GHDL_FLAGS) $(SOURCE_FILES)

$(WORKDIR):
	@mkdir -p $(WORKDIR)

gcompile: parse_umem preprocess ghdl

%_tb.vhd: gcompile
	@ghdl -a $(GHDL_FLAGS) $(SRC_DIR)/$@
	@ghdl -e $(GHDL_FLAGS) $*_tb
	@mkdir -p $(WAVEDIR)
# Allow for simulation to fail
	-@ghdl -r $(GHDL_FLAGS) $*_tb --wave=$(WAVEDIR)/$*_tb.ghw --ieee-asserts=disable-at-0 --assert-level=error

.PHONY: %.ghw
%.ghw: ## Launch wave in GTKWave, if not already running
	@if ! pgrep -x "gtkwave" > /dev/null; then \
		gtkwave -a $(SAVEDIR)/$*.gtkw $(WAVEDIR)/$*.ghw > /dev/null & \
	fi

.PHONY: gtkwave
gtkwave: cpu_tb.vhd cpu_tb.ghw ## Simulate, then launch wave


.PHONY: surfer
surfer: cpu_tb.vhd
	@if ! pgrep -x "surfer" > /dev/null; then \
		surfer wave/cpu_tb.ghw -s save/cpu_tb.ron -c command/qol.surfer > /dev/null &
	fi


assemble: ## Assemble a program from src/masm into pMem.vhd
	@if [ -z $(prog) ]; then \
		echo "ERROR: No program given. Usage: make assemble prog=<name of program (without extension) in masm>"; \
		exit 1; \
	fi
	@python3 $(SCRIPTDIR)/assembler.py $(prog)

gsim_video: video_tb.vhd video_tb.ghw ## Simulate the video module
