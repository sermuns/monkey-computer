.PHONY: clean alu_test alu_test_gtk

FILES = src/*
WORKDIR = work
WAVEDIR = wave
WAVEFILE = $(WAVEDIR)/ALU_ent_tb.ghw
FLAGS = --std=08 --workdir=$(WORKDIR)

all:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) $(FILES)

clean:
	@rm -rf $(WORKDIR)

alu_test:
	@mkdir -p $(WORKDIR)
	@ghdl -a $(FLAGS) src/alu.vhd src/alu_tb.vhd 
	@ghdl -e $(FLAGS) ALU_ent_tb
	@mkdir -p $(WAVEDIR)
	@ghdl -r $(FLAGS) ALU_ent_tb --wave=$(WAVEFILE)

alu_test_gtk: alu_test
	@gtkwave -a src/alu_test_save.gtkw $(WAVEFILE)