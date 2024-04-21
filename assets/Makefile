.PHONY: clean
BUILD_DIR = $(CURDIR)/build


all: frames sprites

clean:
	@rm -rf $(BUILD_DIR)

create_build_dir:
	@mkdir -p $(BUILD_DIR)

frames: create_build_dir
	@libresprite -b $(CURDIR)/tiles.aseprite --save-as $(BUILD_DIR)/frame.png > /dev/null

sprites:
	@python slice_grid.py $(BUILD_DIR)/frame1.png $(BUILD_DIR)
	@python slice_grid.py $(BUILD_DIR)/frame2.png $(BUILD_DIR)
	@python slice_grid.py $(BUILD_DIR)/frame3.png $(BUILD_DIR)
	@python slice_grid.py $(BUILD_DIR)/frame4.png $(BUILD_DIR)

hex:
	@python png_to_hex.py $(BUILD_DIR)/sprite1_frame1.png