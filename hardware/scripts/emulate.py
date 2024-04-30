"""
Reads initial state of video memory, then reads each instruction and updates the video memory accordingly.
Video memory is visualised using pygame. The VGA output is effectively emulated.
"""

import sys
import time
import os
import numpy as np
import struct
from PIL import Image
from PIL import ImageOps
from PIL import ImageEnhance

import array_manip as am
import re

os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame

# Constants
SURFACE_WIDTH_PX = 640
SURFACE_HEIGHT_PX = 480
MAP_SIZE_PX = SURFACE_HEIGHT_PX

MAP_SIZE_TILES = 10

SCALE = 1.5

CLK_FREQ = 25e6

CONSTANTS = {}

def parse_vmem(vmem_lines):
    """
    Parse the VHDL array elements into a 10x10 numpy array.
    """

    VMEM_FIELD_WIDTH = 6

    flat_vmem = []

    for i, line in enumerate(vmem_lines):
        # Match all fields in the line (e.g. b"000000_000000_000000_000000"
        fields = re.findall(rf'\d{{{VMEM_FIELD_WIDTH}}}', line)
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

    palette_array = am.extract_vhdl_array(tile_rom_lines, r'\s*CONSTANT\s*palette_rom.*')
    palette_elements = am.get_vhdl_array_elements(palette_array,
                                                  element_pattern=r'\d+ => x"\w+"')

    palette = []

    for elem in palette_elements:
        # Extract the 3-digit hex values
        palette += [re.search(r'"(\w+)"', elem).group(1)]
        
    return palette


def init_main_memory(pmem_lines):
    """
    Initialise the main memory with the contents of pMem.vhd
    """

    mem_array = am.extract_vhdl_array(pmem_lines, r'.*:.*p_mem_type.*:=.*')
    mem_elements = am.get_vhdl_array_elements(lines=mem_array,
                                              element_pattern=r'[\+\w\s]+\s*=>\s*b"[\d_]+"'
                                              )

    global CONSTANTS
    CONSTANTS = am.parse_constants(pmem_lines)

    main_memory = np.zeros(2**16, dtype=np.uint32)
    for elem in mem_elements:
        # Extract the 32-bit hex values
        groups = re.search(r'\s*(.*)\s*=>\s*b"(.*)".*', elem)
        if not groups:
            raise ValueError(f"Invalid memory element {elem}")

        addr = groups.group(1)
        # Replace any constants and resolve arithmetic expressions
        for c in CONSTANTS:
            addr = addr.replace(c, str(CONSTANTS[c]))

        # Remove leading zeroes from addr
        addr = re.sub(r'\b0*(\d+)', r'\1', addr)

        # Evaluate arithmetic expressions
        try:
            addr = str(eval(addr))
        except Exception as e:
            raise ValueError(f"Invalid address: {addr}") from e

        # Convert to integer
        try:
            addr = int(addr)
        except ValueError as e:
            raise ValueError(f"Invalid address: {addr}") from e

        val = int(groups.group(2), 2)

        main_memory[addr] = val

    return main_memory


def read_tile_rom(tile_rom_lines):
    """
    Read the tile ROM from lines of tile_rom.vhd
    """

    tile_rom_array = am.extract_vhdl_array(tile_rom_lines, r'\s*CONSTANT.*tile_rom_type\s*:=')
    tile_rom_elements = am.get_vhdl_array_elements(lines=tile_rom_array,
                                                   element_pattern=r'\d+'
                                                   )

    # Flatten the list comprehension to create a flat list of elements
    tile_rom = []
    for elem in tile_rom_elements:
        tile_rom += [int(re.search(r'\d+', elem).group(0), 2)] 

    return np.array(tile_rom, dtype=np.uint8)


def draw_tile():
    pass


def get_tile(tile_type, tile_rom, palette):
    """
    Get the tile from the tile ROM.
    """

    TILE_SIZE = 12 # 12x12 macropixels in tile

    tile = np.zeros((TILE_SIZE, TILE_SIZE), dtype=np.uint8)

    # Get the tile from the tile ROM
    tile_data = tile_rom[tile_type * TILE_SIZE**2: (tile_type + 1) * TILE_SIZE**2]

    for i, palette_index in enumerate(tile_data):
        row = i // TILE_SIZE
        col = i % TILE_SIZE
        tile[row, col] = palette_index

    # Create a surface from the tile
    surface = pygame.Surface((TILE_SIZE, TILE_SIZE))

    for row in range(TILE_SIZE):
        for col in range(TILE_SIZE):
            palette_index = tile[row, col]
            # Create r,g,b tuple from the 3-digit hex value
            color = tuple(int(palette[palette_index][i], 16)*16 for i in range(3))
            surface.set_at((col, row), color)

    return surface


def get_map_surface(main_memory, tile_rom, palette):
    """
    Draw the map from video memory to a surface, return it.
    """

    VMEM_START = CONSTANTS['VMEM_START']
    VMEM_FIELD_BIT_WIDTH = 6

    surface = pygame.Surface((MAP_SIZE_TILES, MAP_SIZE_TILES))

    for row in range(MAP_SIZE_TILES):
        for col in range(MAP_SIZE_TILES):
            id = row*MAP_SIZE_TILES + col
            vmem_row = bin(main_memory[VMEM_START + id // 4])[2:].zfill(24)
            vmem_row_fields = re.findall(rf'\d{{{VMEM_FIELD_BIT_WIDTH}}}', vmem_row)
            current_tile_type = int(vmem_row_fields[id % 4],2)

            tile = get_tile(
                tile_type=current_tile_type,
                tile_rom=tile_rom,
                palette=palette
            )

            surface.blit(tile, (col, row))

    return surface


if __name__ == "__main__":
    # initialise main memory from pMem.vhd
    pmem_lines = open('pMem.vhd').readlines()
    main_memory = init_main_memory(pmem_lines)

    # get tile_rom and palette from tile_rom.vhd
    tile_rom_lines = open('tile_rom.vhd').readlines()
    palette = read_palette(tile_rom_lines)
    tile_rom = read_tile_rom(tile_rom_lines)

    # initialise pygame
    pygame.init()
    screen = pygame.display.set_mode((SCALE*SURFACE_WIDTH_PX, SCALE*SURFACE_HEIGHT_PX))
    clock = pygame.time.Clock()

    # Create a surface to draw on
    surface = pygame.Surface((SURFACE_WIDTH_PX, SURFACE_HEIGHT_PX))
    surface.fill((0, 0, 0))

    # Wait until user closes the window
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()

        # Get grid map surface
        map_surface = get_map_surface(main_memory, tile_rom, palette)

        # Scale it to fit the screen
        scaled_map_surface = pygame.transform.scale(map_surface, (SCALE*MAP_SIZE_PX, SCALE*MAP_SIZE_PX))

        # Draw the map surface on the main surface
        surface.blit(scaled_map_surface, (0, 0))

        # Update the screen
        main_surface = pygame.transform.scale(surface, (SCALE*SURFACE_WIDTH_PX, SCALE*SURFACE_HEIGHT_PX))
        screen.blit(main_surface, (0, 0))
        pygame.display.flip()

        clock.tick(60)
    


