WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
SCRIPTDIR = ../scripts
GHDL_FLAGS = --std=08 --workdir=$(WORKDIR)
GHDL_RUN_FLAGS = --ieee-asserts=disable-at-0 --assert-level=error 

SRC_DIR=.

# can be compiled in any order
STANDALONE_MODULES = alu.vhd uMem.vhd pMem.vhd tile_rom.vhd kbd_enc.vhd
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
	python $(SCRIPTDIR)/parse_umem.py
 
preprocess:
	python $(SCRIPTDIR)/preprocess.py -q

.PHONY: gclean
gclean:
	rm -rf $(WORKDIR) $(WAVEDIR)

.PHONY: ghdl
ghdl: $(WORKDIR)
	ghdl -a $(GHDL_FLAGS) $(SOURCE_FILES)

$(WORKDIR):
	@mkdir -p $(WORKDIR)

.PHONY: gcompile
gcompile: parse_umem preprocess ghdl

.PHONY: test
test: gcompile
	@ghdl -a $(GHDL_FLAGS) $(SRC_DIR)/cpu_tb.vhd
	@ghdl -e $(GHDL_FLAGS) cpu_tb
	@mkdir -p $(WAVEDIR)
# If stime is not defined, print error
ifeq ($(stime),)
	$(error $(shell echo -e '\033[1;31mstoptime not defined.\033[0m Run `make test stime=1000ns` to run simulation for 1000 ns'))
endif
	-@ghdl -r $(GHDL_FLAGS) cpu_tb --wave=$(WAVEDIR)/cpu_tb.ghw $(GHDL_RUN_FLAGS) --stop-time=$(stime)

.PHONY: surfer
surfer:
	@if ! pgrep -x "surfer" > /dev/null; then \
		surfer wave/cpu_tb.ghw -s save/cpu_tb.ron -c command/qol.surfer > /dev/null & \
	fi

.PHONY: %.s
%.s: ## Assemble, then insert into program memory
	python $(SCRIPTDIR)/assembler.py $*.s