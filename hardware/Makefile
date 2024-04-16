.PHONY: clean alu_wave cpu_wave

WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
SCRIPTDIR = scripts
GHDL_FLAGS = --std=08 --workdir=$(WORKDIR)

# try to compile all files
all:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  cpu"
	@echo "  cpu_tb"
	@echo "  cpu_wave"
	@echo "  alu_test"
	@echo "  alu_wave"

parse_umem:
	@python $(SCRIPTDIR)/parse_mem.py src/uMem.vhd
 
preprocess:
	@python $(SCRIPTDIR)/preprocess.py -q

clean:
	@rm -rf $(WORKDIR) $(WAVEDIR)

cpu_compile:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(GHDL_FLAGS) src/alu.vhd src/uMem.vhd src/pMem.vhd src/cpu.vhd src/main.vhd

cpu: parse_umem preprocess cpu_compile

cpu_tb: cpu
	@ghdl -a $(GHDL_FLAGS) src/cpu_tb.vhd
	@ghdl -e $(GHDL_FLAGS) cpu_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(GHDL_FLAGS) cpu_tb --wave=$(WAVEDIR)/cpu_tb.ghw

cpu_wave: cpu_tb
	@if ! pgrep -x "gtkwave" > /dev/null; then \
		gtkwave -a $(SAVEDIR)/cpu_tb_save.gtkw $(WAVEDIR)/cpu_tb.ghw & \
	fi

# assemble the argument `file` and input into pMem.vhd
assemble:
	@if [ -z $(prog) ]; then \
		echo "ERROR: No program given. Usage: make assemble prog=<name of program (without extension .masm) in src/masm>"; \
		exit 1; \
	fi
	@python3 $(SCRIPTDIR)/assembler.py src/masm/$(prog)

#ALU
alu_test:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(GHDL_FLAGS) src/alu.vhd src/alu_tb.vhd 
	@ghdl -e $(GHDL_FLAGS) ALU_ent_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(GHDL_FLAGS) ALU_ent_tb --wave=$(WAVEDIR)/alu_tb.ghw

alu_wave: alu_test
	@gtkwave -a $(SAVEDIR)/alu_test_save.gtkw $(WAVEDIR)/alu_tb.ghw