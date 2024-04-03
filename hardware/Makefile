.PHONY: clean

FILES = src/*
WORKDIR = work

all:
	@mkdir -p $(WORKDIR)
	@ghdl -a --workdir=$(WORKDIR) $(FILES)

clean:
	@rm -rf $(WORKDIR)
