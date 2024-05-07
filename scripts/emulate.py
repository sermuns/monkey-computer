"""
Reads initial state of video memory, then reads each instruction and updates the video memory accordingly.
Video memory is visualised using pygame. The VGA output is effectively emulated.
"""

import sys
import os
import numpy as np
import re

os.environ["SDL_VIDEO_CENTERED"] = "1"
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "hide"
import pygame

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
SCALE = 3
TILE_SIZE_PX = MAP_SIZE_PX // MAP_SIZE_TILES

# Global variables
CONSTANTS = {}
PALETTE = []

# Pygame constants
KEYBINDINGS = {
    pygame.K_SPACE: "step",
    pygame.K_r: "reset",
    pygame.K_q: "quit",
    pygame.K_ESCAPE: "quit",
    pygame.K_F1: "show_machine_state",
}
PYGAME_FLAGS = 0
WINDOW_TITLE = "monkey-emulator🐒"


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


def get_tile(tile_type: int, tile_rom: list) -> pygame.Surface:
    """
    Get tile appearance from tile ROM, use the values from it to fetch
    real colors from the palette.
    """

    TILE_SIZE_MACROPIXELS = TILE_SIZE_PX // 4  # 12x12 macropixels per tile
    COLOR_CHANNELS = 3

    surface = pygame.Surface((TILE_SIZE_MACROPIXELS, TILE_SIZE_MACROPIXELS))

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

    return pygame.transform.scale(surface, (TILE_SIZE_PX, TILE_SIZE_PX))


def get_map_surface(machine, tile_rom):
    """
    Draw the map from video memory to a surface, return it.
    """

    VMEM = machine.sections["VMEM"].start
    VMEM_FIELD_BIT_WIDTH = 6

    surface = pygame.Surface((MAP_SIZE_PX, MAP_SIZE_PX))

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


def update_screen(screen, machine, show_machine_state):
    """
    Update the screen
    """

    temp_surface = pygame.Surface((SURFACE_WIDTH_PX, SURFACE_HEIGHT_PX))

    # Draw game map
    map_surface = get_map_surface(machine, TILE_ROM)
    temp_surface.blit(map_surface, (0, 0))
    scaled_surface = pygame.transform.scale_by(temp_surface, SCALE)
    screen.blit(scaled_surface, (0, 0))

    # Print machine state
    if show_machine_state:
        font_path = os.path.join('scripts','fonts', 'minecraftia.ttf')
        font = pygame.font.Font(font_path, SCALE*15)
        text = font.render('SCORE IS CURRENTLY', 0, (255, 255, 255))
        textpos = text.get_rect()
        textpos.right = screen.get_size()[0]
        screen.blit(text, textpos)

    pygame.display.flip()


def toggle_machine_state_visibility(screen: pygame.Surface, show_machine_state: bool):
    """
    Toggle the visibility of the machine state on the screen
    """

    show_machine_state = not show_machine_state

    if show_machine_state:
        screen = create_screen(SCALE*SURFACE_WIDTH_PX*1.3, SCALE*SURFACE_HEIGHT_PX)
    else:
        screen = create_screen(SCALE*SURFACE_WIDTH_PX, SCALE*SURFACE_HEIGHT_PX)

    return show_machine_state

def create_screen(width: int, height: int) -> pygame.Surface:
    """
    Create a pygame screen with the given width and height.
    Use the global PYGAME_FLAGS constant.
    """

    screen = pygame.display.set_mode((width, height), PYGAME_FLAGS)

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

    # initialise pygame
    pygame.init()
    screen = pygame.display.set_mode(
        (SCALE * SURFACE_WIDTH_PX, SCALE * SURFACE_HEIGHT_PX), PYGAME_FLAGS
    )
    pygame.display.set_caption(WINDOW_TITLE)
    update_screen(screen, machine, show_machine_state)

    clock = pygame.time.Clock()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                key_event = KEYBINDINGS.get(event.key)
                if key_event == "quit":
                    sys.exit()
                elif key_event == "step":
                    machine.execute_next_instruction()
                elif key_event == "reset":
                    machine = Machine(assembly_lines)  # reset the machine
                elif key_event == "show_machine_state":
                    show_machine_state = toggle_machine_state_visibility(screen, show_machine_state)

                update_screen(
                    screen, machine, show_machine_state
                )  # update the screen on keypress
