.PHONY: clean alu_test alu_test_gtk

FILES = src/*
WORKDIR = work
WAVEDIR = wave
SAVEDIR = save
WAVEFILE = $(WAVEDIR)/ALU_ent_tb.ghw
FLAGS = --std=08 --workdir=$(WORKDIR)

# try to compile all files
all:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) $(FILES)

# remove work
clean:
	@rm -rf $(WORKDIR)

cpu:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) src/uMem.vhd src/pMem.vhd src/cpu.vhd 

cpu_tb: cpu
	ghdl -a $(FLAGS) src/cpu_tb.vhd
	ghdl -e $(FLAGS) cpu_tb
	ghdl -r $(FLAGS) cpu_tb --wave=$(WAVEDIR)/cpu_tb.ghw

cpu_wave: cpu_tb
	@gtkwave -a $(SAVEDIR)/cpu_test_save.gtkw $(WAVEDIR)/cpu_tb.ghw


# ALU
alu_test:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) src/alu.vhd src/alu_tb.vhd 
	@ghdl -e $(FLAGS) ALU_ent_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(FLAGS) ALU_ent_tb --wave=$(WAVEFILE)

alu_wave: alu_test
	@gtkwave -a $(SAVEDIR)/alu_test_save.gtkw $(WAVEFILE)