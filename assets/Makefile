.PHONY: clean

BUILD_DIR = $(CURDIR)/build
P_MEM_FILE = ../hardware/src/pMem.vhd


clean:
	@rm -rf $(BUILD_DIR)
	@rm -f tileset.png
	@rm -f palette.png

create_build_dir:
	@mkdir -p $(BUILD_DIR)

frames: create_build_dir ## Export all frames from aseprite file
	@libresprite -b $(CURDIR)/tiles.aseprite --save-as $(BUILD_DIR)/frame.png > /dev/null

tileset: frames ## Generate a tileset for Tiled (.tsx)
	@python generate_tileset.py

palette: tileset ## Find all used colors in tileset, and generate a palette image
	@python generate_palette.py

tilerom: palette ## Import the final tileset and palette to `tile_rom.vhd`
	@python import_to_tilerom.py


vmem: ## Import `Tiled` map to vmem
	@python map_to_vmem.py map.tmx $(P_MEM_FILE)