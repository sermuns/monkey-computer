# Variables
GHDL=ghdl
GHDLFLAGS=
GHDLRUNFLAGS=
WORKDIR=work
SOURCES=uprogCPU.vhd uprogCPU_tb.vhd pMem.vhd uMem.vhd
TESTBENCH=uprogCPU_tb

# Default target : elaborate testbench
all: $(TESTBENCH)

# Elaborate testbench
$(TESTBENCH): $(SOURCES)
	$(GHDL) -i --workdir=$(WORKDIR) --work=work $^
	$(GHDL) -m --workdir=$(WORKDIR) --work=work $@

# Run testbench
run: $(TESTBENCH)
	$(GHDL) -r --workdir=$(WORKDIR) --work=work $(TESTBENCH) $(GHDLRUNFLAGS)

# Clean up
clean:
	$(GHDL) --clean --workdir=$(WORKDIR)