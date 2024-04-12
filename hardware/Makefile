.PHONY: clean alu_wave cpu_wave

WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
FLAGS = --std=08 --workdir=$(WORKDIR)

# try to compile all files
all:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  cpu"
	@echo "  cpu_tb"
	@echo "  cpu_wave"
	@echo "  alu_test"
	@echo "  alu_wave"

# remove work
clean:
	@rm -rf $(WORKDIR) $(WAVEDIR)

cpu: parse_umem preprocess
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) src/alu.vhd src/uMem.vhd src/pMem.vhd src/cpu.vhd 

cpu_tb: cpu
	@ghdl -a $(FLAGS) src/cpu_tb.vhd
	@ghdl -e $(FLAGS) cpu_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(FLAGS) cpu_tb --wave=$(WAVEDIR)/cpu_tb.ghw

cpu_wave: cpu_tb
	@if ! pgrep -x "gtkwave" > /dev/null; then \
		gtkwave -a $(SAVEDIR)/cpu_tb_save.gtkw $(WAVEDIR)/cpu_tb.ghw & \
	fi

parse_umem:
	@python parse_mem.py src/uMem.vhd
 
preprocess:
	@python preprocess.py

# ALU
alu_test:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) src/alu.vhd src/alu_tb.vhd 
	@ghdl -e $(FLAGS) ALU_ent_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(FLAGS) ALU_ent_tb --wave=$(WAVEDIR)/alu_tb.ghw

alu_wave: alu_test
	@gtkwave -a $(SAVEDIR)/alu_test_save.gtkw $(WAVEDIR)/alu_tb.ghw