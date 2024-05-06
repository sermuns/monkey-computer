"""
Reads initial state of video memory, then reads each instruction and updates the video memory accordingly.
Video memory is visualised using pygame. The VGA output is effectively emulated.
"""

import sys
import os
import numpy as np
import array_manip as am
import re
import utils

os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "hide"
import pygame

# File paths
PMEM_FILE = "hardware/pMem.vhd"
TILE_ROM_FILE = "hardware/tile_rom.vhd"

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


def init_main_memory(pmem_lines):
    """
    Initialise the main memory with the contents of pMem.vhd
    """

    mem_array = am.extract_vhdl_array(pmem_lines, r".*:.*p_mem_type.*:=.*")
    mem_elements = am.get_vhdl_array_elements(
        lines=mem_array, element_pattern=r'[\+\w\s]+\s*=>\s*b"[\d_]+"'
    )

    global CONSTANTS
    CONSTANTS = am.parse_constants(pmem_lines)

    main_memory = np.zeros(2**16, dtype=np.uint32)
    for elem in mem_elements:
        # Extract the 32-bit hex values
        groups = re.search(r'\s*(.+)\s*=>\s*b"(.*)".*', elem)
        if not groups:
            raise ValueError(f"Invalid memory element {elem}")

        addr = groups.group(1)
        # Replace any constants and resolve arithmetic expressions
        for c in CONSTANTS:
            addr = addr.replace(c, str(CONSTANTS[c]))

        # Remove leading zeroes from addr
        addr = re.sub(r"\b0*(\d+)", r"\1", addr)

        # Evaluate arithmetic expressions
        try:
            addr = eval(addr)
        except Exception as e:
            raise ValueError(
                f"Unable to evaluate address arithmetically: {addr}"
            ) from e

        # Convert to integer
        try:
            addr = int(addr)
        except ValueError as e:
            raise ValueError(f"Unable to parse address as integer: {addr}") from e

        val = int(groups.group(2), 2)

        main_memory[addr] = val

    return main_memory


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


def get_map_surface(main_memory, tile_rom):
    """
    Draw the map from video memory to a surface, return it.
    """

    VMEM = CONSTANTS["VMEM"]
    VMEM_FIELD_BIT_WIDTH = 6

    surface = pygame.Surface((MAP_SIZE_PX, MAP_SIZE_PX))

    for y in range(MAP_SIZE_TILES):
        for x in range(MAP_SIZE_TILES):
            id = y * MAP_SIZE_TILES + x
            vmem_row = bin(main_memory[VMEM + id // 4])[2:].zfill(24)
            vmem_row_fields = re.findall(rf"\d{{{VMEM_FIELD_BIT_WIDTH}}}", vmem_row)
            current_tile_type = int(vmem_row_fields[id % 4], 2)

            tile = get_tile(current_tile_type, tile_rom)

            surface.blit(tile, (x * TILE_SIZE_PX, y * TILE_SIZE_PX))

    return surface


if __name__ == "__main__":
    # change the working directory to the root of the project
    utils.chdir_to_root()

    # initialise main memory from pMem.vhd
    pmem_lines = open(PMEM_FILE).readlines()
    main_memory = init_main_memory(pmem_lines)

    # get tile_rom and palette from tile_rom.vhd
    tile_rom_lines = open(TILE_ROM_FILE).readlines()
    PALETTE = read_palette(tile_rom_lines)
    TILE_ROM = read_tile_rom(tile_rom_lines)

    # initialise pygame
    pygame.init()
    screen = pygame.display.set_mode(
        (SCALE * SURFACE_WIDTH_PX, SCALE * SURFACE_HEIGHT_PX)
    )
    clock = pygame.time.Clock()

    # Create a surface to draw on
    surface = pygame.Surface((SURFACE_WIDTH_PX, SURFACE_HEIGHT_PX))
    surface.fill((0, 0, 0))  # fill with black

    # Wait until user closes the window
    while True:
        events = pygame.event.get()
        for event in events:
            if event.type == pygame.QUIT:
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key in {pygame.K_ESCAPE, pygame.K_q}:
                    sys.exit()

        # Get grid map surface
        map_surface = get_map_surface(main_memory, TILE_ROM)

        # Draw the map surface on the main surface
        surface.blit(map_surface, (0, 0))
        final_surface = pygame.transform.scale_by(surface, SCALE)

        # Update the screen
        screen.blit(final_surface, (0, 0))
        pygame.display.flip()

        clock.tick(60)
