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

from array_manip import extract_vhdl_array, get_vhdl_array_elements
import re

os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame

# Constants
SURFACE_WIDTH = 640
SURFACE_HEIGHT = 480

MAP_SIZE = SURFACE_HEIGHT

SCALE = 1.5

CLK_FREQ = 25e6

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

    palette_array = extract_vhdl_array(tile_rom_lines, r'\s*CONSTANT\s*palette_rom.*')
    palette_elements = get_vhdl_array_elements(palette_array)

    palette = []

    for elem in palette_elements:
        # Extract the 3-digit hex values
        palette += [re.search(r'"(\w+)"', elem).group(1)]
        
    return palette


def get_appearance_of_tile(tiletype, palette, tile_rom_data):
    """
    Get the appearance of a tile given its tiletype and the palette.
    """
    appearance = []
    tiletype = int(tiletype)
    


if __name__ == "__main__":
    mem_lines = open('pMem.vhd').readlines()
    mem_array = extract_vhdl_array(mem_lines, r'\s*CONSTANT\s*p_mem_init.*:=.*')
    mem_elements = get_vhdl_array_elements(mem_array)
    vmem_elements = [elem for elem in mem_elements if re.match(r'\s*VMEM_START.*', elem)]
    vmem = parse_vmem(vmem_elements)

    tile_rom_lines = open('tile_rom.vhd').readlines()
    palette = read_palette(tile_rom_lines)

    # Initialise pygame
    pygame.init()
    screen = pygame.display.set_mode((SCALE*SURFACE_WIDTH, SCALE*SURFACE_HEIGHT))
    clock = pygame.time.Clock()

    # Create a surface to draw on
    surface = pygame.Surface((SURFACE_WIDTH, SURFACE_HEIGHT))
    surface.fill((0, 0, 0))

    # Wait until user closes the window
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()

        # Update the screen
        scaled_surface = pygame.transform.scale(surface, (SCALE*SURFACE_WIDTH, SCALE*SURFACE_HEIGHT))
        screen.blit(scaled_surface, (0, 0))
        pygame.display.flip()

        clock.tick(60)
    


