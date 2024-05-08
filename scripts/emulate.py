"""
Reads initial state of video memory, then reads each instruction and updates the video memory accordingly.
Video memory is visualised using pg. The VGA output is effectively emulated.
"""

import sys
import os
import numpy as np
import re
from enum import Enum, auto

os.environ["SDL_VIDEO_CENTERED"] = "1"
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "hide"
import pygame as pg

import utils
import array_manip as am
from machine import Machine

# File paths
TILE_ROM_FILE = "hardware/tile_rom.vhd"
MASM_DIR = "masm"
DEBUG_ASSEMBLY_FILE = "loop.s"  # change this to which file you want to debug

# Constants
SURFACE_WIDTH_PX = 640
SURFACE_HEIGHT_PX = 480
MAP_SIZE_PX = SURFACE_HEIGHT_PX
MAP_SIZE_TILES = 10
SCALE = 2
TILE_SIZE_PX = MAP_SIZE_PX // MAP_SIZE_TILES

# Global variables
CONSTANTS = {}
PALETTE = []


# Pygame constants
class EmulationEvent(Enum):
    step = auto()
    reset = auto()
    quit = auto()
    show_machine_state = auto()
    continue_to_breakpoint = auto()


KEYBINDINGS = {
    pg.K_SPACE: EmulationEvent.step,
    pg.K_r: EmulationEvent.reset,
    pg.K_q: EmulationEvent.quit,
    pg.K_ESCAPE: EmulationEvent.quit,
    pg.K_F1: EmulationEvent.show_machine_state,
    pg.K_c: EmulationEvent.continue_to_breakpoint,
}
PYGAME_FLAGS = 0
WINDOW_TITLE = "monkey-emulator🐒"
FONT_PATH = os.path.join("scripts", "fonts", "minecraftia.ttf")


def parse_vmem(vmem_lines):
    """
    Parse the VHDL array elements into a 10x10 numpy array.
    """

    VMEM_FIELD_WIDTH = 6

    flat_vmem = []

    for i, line in enumerate(vmem_lines):
        # Match all fields in the line (e.g. b"000000_000000_000000_000000"
        fields = re.findall(rf"\d{{{VMEM_FIELD_WIDTH}}}", line)
        # Parse each field into a 6-bit integer
        flat_vmem += [int(field, 2) for field in fields]

    vmem = np.zeros((10, 10), dtype=np.uint8)
    for i, val in enumerate(flat_vmem):
        vmem[i // 10, i % 10] = val
    return vmem


def read_palette(tile_rom_lines):
    """
    Read the palette from lines of tile_rom.vhd
    """

    palette_array = am.extract_vhdl_array(
        tile_rom_lines, r"\s*CONSTANT\s*palette_rom.*"
    )
    palette_elements = am.get_vhdl_array_elements(
        palette_array, element_pattern=r'\d+ => x"\w+"'
    )

    palette = []

    for elem in palette_elements:
        # Extract the 3-digit hex values
        hex_color = re.search(r'x"(\w+)"', elem).group(1)
        # Convert to 0-255 r,g,b values
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
        palette.append((r, g, b))

    return palette


def read_tile_rom(tile_rom_lines):
    """
    Read the tile ROM from lines of tile_rom.vhd
    """

    tile_rom_array = am.extract_vhdl_array(
        tile_rom_lines, r"\s*CONSTANT.*tile_rom_type\s*:="
    )
    tile_rom_elements = am.get_vhdl_array_elements(
        lines=tile_rom_array, element_pattern=r"\d+"
    )

    # Flatten the list comprehension to create a flat list of elements
    tile_rom = []
    for elem in tile_rom_elements:
        tile_rom += [int(re.search(r"\d+", elem).group(0), 2)]

    return np.array(tile_rom, dtype=np.uint8)


def get_tile(tile_type: int, tile_rom: list) -> pg.Surface:
    """
    Get tile appearance from tile ROM, use the values from it to fetch
    real colors from the palette.
    """

    TILE_SIZE_MACROPIXELS = TILE_SIZE_PX // 4  # 12x12 macropixels per tile
    COLOR_CHANNELS = 3

    surface = pg.Surface((TILE_SIZE_MACROPIXELS, TILE_SIZE_MACROPIXELS))

    # Get the tile from the tile ROM
    tile_data = tile_rom[
        tile_type
        * TILE_SIZE_MACROPIXELS**2 : (tile_type + 1)
        * TILE_SIZE_MACROPIXELS**2
    ]

    # Map the palette indices to colors
    tile_colors = []
    for palette_index in tile_data:
        tile_colors.append(PALETTE[palette_index])

    for y in range(TILE_SIZE_MACROPIXELS):
        for x in range(TILE_SIZE_MACROPIXELS):
            color = tile_colors[y * TILE_SIZE_MACROPIXELS + x]
            surface.set_at((x, y), color)

    return pg.transform.scale(surface, (TILE_SIZE_PX, TILE_SIZE_PX))


def get_map_surface(machine, tile_rom):
    """
    Draw the map from video memory to a surface, return it.
    """

    VMEM = machine.sections["VMEM"].start
    VMEM_FIELD_BIT_WIDTH = 6

    surface = pg.Surface((MAP_SIZE_PX, MAP_SIZE_PX))

    for y in range(MAP_SIZE_TILES):
        for x in range(MAP_SIZE_TILES):
            id = y * MAP_SIZE_TILES + x
            vmem_row = machine.memory[VMEM + id // 4][2:].zfill(24)
            vmem_row_fields = re.findall(rf"\d{{{VMEM_FIELD_BIT_WIDTH}}}", vmem_row)
            current_tile_type = int(vmem_row_fields[id % 4], 2)

            if current_tile_type > tile_rom.size // 144:
                utils.ERROR(
                    f"Tile type {current_tile_type} is not defined in the tile ROM"
                )

            tile = get_tile(current_tile_type, tile_rom)

            surface.blit(tile, (x * TILE_SIZE_PX, y * TILE_SIZE_PX))

    return surface


def handle_args():
    """
    Handle command line arguments
    """

    if len(sys.argv) != 2:
        print("Usage: python emulate.py <assembly_file.s>")
        sys.exit(1)

    if sys.argv[1] == "--debug":
        sys.argv[1] = DEBUG_ASSEMBLY_FILE

    assembly_file = os.path.join(MASM_DIR, sys.argv[1])

    return assembly_file


def add_text_to_debug_surface(debug_surface, text_lines, font, color=(255, 255, 255)):
    """
    Add arbitrary text lines to the debug_surface.

    Parameters:
    debug_surface (pg.Surface): The surface to add text to.
    text_lines (list of str): The lines of text to add.
    font (pg.font.Font): The font to use for the text.
    color (tuple of int): The color of the text (default is white).
    """

    # Calculate the height of the font
    font_height = font.get_height()

    for i, line in enumerate(text_lines):
        # Render the line of text
        text = font.render(line, True, color)

        # Calculate the position of the text
        textpos = text.get_rect()
        textpos.topleft = (0, i * font_height)

        # Blit the text onto the debug_surface
        debug_surface.blit(text, textpos)


def get_debug_info_surface(machine, surface_size):
    """
    Return surface with various debug information
    printed as text
    """

    debug_surface = pg.Surface(surface_size).convert_alpha()
    debug_surface.fill((0, 0, 0, 0))

    # Create a separate surface for the background
    background_surface = pg.Surface(surface_size).convert_alpha()
    # Fill the background surface with white color
    background_surface.fill((0, 0, 0, 50))
    font = pg.font.Font(FONT_PATH, 15 * SCALE)

    pc_value = machine.registers["PC"]
    current_assembly_line = machine.get_from_memory(pc_value)

    # Add the current assembly line to the debug_surface
    text_lines = [f"PC: {pc_value}", f"{current_assembly_line}"]
    add_text_to_debug_surface(debug_surface, text_lines, font)

    # Draw a border around the debug_surface
    border_color = (255, 255, 255)  # White color
    border_width = 3  # 3 pixels wide
    pg.draw.rect(
        debug_surface, border_color, debug_surface.get_rect(), border_width
    )

    return debug_surface


def update_screen(screen, machine, show_machine_state):
    """
    Update the screen
    """

    # Clear the screen
    screen.fill("black")

    small_surface = pg.Surface((SURFACE_WIDTH_PX, SURFACE_HEIGHT_PX))

    # Draw game map
    map_surface = get_map_surface(machine, TILE_ROM)
    small_surface.blit(map_surface, (0, 0))
    scaled_surface = pg.transform.scale_by(small_surface, SCALE)
    screen.blit(scaled_surface, (0, 0))

    # Print machine state
    if show_machine_state:
        debug_width = SCALE * SURFACE_WIDTH_PX * 0.3
        debug_height = SCALE * SURFACE_HEIGHT_PX
        debug_surface = get_debug_info_surface(machine, (debug_width, debug_height))
        # place at the right side of the screen
        placement_pos = (screen.get_width() - debug_width, 0)
        screen.blit(debug_surface, placement_pos)

    pg.display.flip()


def toggle_machine_state_visibility(screen: pg.Surface, show_machine_state: bool):
    """
    Toggle the visibility of the machine state on the screen
    """

    show_machine_state = not show_machine_state

    # if show_machine_state:
    #     screen = create_screen(
    #         SCALE * SURFACE_WIDTH_PX * 1.3, SCALE * SURFACE_HEIGHT_PX
    #     )
    # else:
    #     screen = create_screen(SCALE * SURFACE_WIDTH_PX, SCALE * SURFACE_HEIGHT_PX)

    return show_machine_state


def create_screen(width: int, height: int) -> pg.Surface:
    """
    Create a pg screen with the given width and height.
    Use the global PYGAME_FLAGS constant.
    """

    screen = pg.display.set_mode((width, height), PYGAME_FLAGS)

    return screen


if __name__ == "__main__":
    # change the working directory to the root of the project
    utils.change_dir_to_root()

    # get tile_rom and palette from tile_rom.vhd
    tile_rom_lines = open(TILE_ROM_FILE).readlines()
    PALETTE = read_palette(tile_rom_lines)
    TILE_ROM = read_tile_rom(tile_rom_lines)

    # find which assembly file to emulate
    assembly_file = handle_args()

    # create machine object
    assembly_lines = open(assembly_file).readlines()
    machine = Machine(assembly_lines)
    show_machine_state = False  # show machine state on screen

    # initialise pg
    pg.init()
    screen = pg.display.set_mode(
        (SCALE * SURFACE_WIDTH_PX, SCALE * SURFACE_HEIGHT_PX), PYGAME_FLAGS
    )
    pg.display.set_caption(WINDOW_TITLE)
    update_screen(screen, machine, show_machine_state)

    clock = pg.time.Clock()

    while True:
        for event in pg.event.get():
            if event.type == pg.QUIT:
                sys.exit()
            elif event.type == pg.KEYDOWN:
                emulation_event = KEYBINDINGS.get(event.key)
                if emulation_event is None:
                    continue
                if emulation_event == EmulationEvent.quit:
                    sys.exit()
                elif emulation_event == EmulationEvent.step:
                    machine.execute_next_instruction()
                elif emulation_event == EmulationEvent.reset:
                    machine = Machine(assembly_lines)  # reset the machine
                elif emulation_event == EmulationEvent.show_machine_state:
                    show_machine_state = toggle_machine_state_visibility(
                        screen, show_machine_state
                    )
                elif emulation_event == EmulationEvent.continue_to_breakpoint:
                    machine.continue_to_breakpoint()

                # update screen regardless of keypress
                update_screen(screen, machine, show_machine_state)
