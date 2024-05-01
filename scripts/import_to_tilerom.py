"""
Parse the tileset image as a flat list of palette indices,
then write it to the tile ROM.
"""

from PIL import Image
import re, sys
import numpy as np
import array_manip as am

def parse_tileset_image(image_file: str, palette: list) -> list:
    """
    Parse the tileset image and list of lists of palette indices.

    Each list in the returned list is a flat list representation (colors, palette indices)
    of a tile.
    """

    TRANSPARENT_INDEX = 1

    # Open the image
    with Image.open(image_file) as img:
        data = list(img.getdata())

    # Convert the image data to a flat list of palette indices
    palette_indices = []
    for pixel in data:
        # Get the RGB values
        r, g, b, a = pixel

        if a < 128: # transparent pixel
            palette_indices.append(TRANSPARENT_INDEX)
            continue

        # Convert the RGB values to a hex color string
        hex_color = f"{r:02x}{g:02x}{b:02x}"

        # Check if the color is in the palette
        if hex_color not in palette:
            raise ValueError(f"Color {hex_color} not found in palette")

        # Get the index of the color
        try:
            index = palette.index(hex_color)
        except ValueError:
            print(f"Color {hex_color} from tileset not found in palette")
            sys.exit(1)

        # Add the index to the tileset
        palette_indices.append(index)

    palette_indices_matrix = np.array(
        palette_indices,
        dtype=np.uint8
        ).reshape(12*10, 12*10)

    # Convert the palette indices to a list of lists
    tileset = []
    for y in range(10):
        for x in range(10):
            tile = palette_indices_matrix[y*12:y*12+12, x*12:x*12+12].flatten()
            if all(color == TRANSPARENT_INDEX for color in tile):
                continue # skip completely black/empty tiles
            tileset.append(tile.tolist())
    
    return tileset


def read_palette(palette_file: str) -> list:
    """
    Read the palette image and return a list of hex colors.
    """
    # Load the palette image
    palette_image = Image.open(palette_file)

    # Get the size of the palette image
    width, height = palette_image.size

    if height != 1:
        raise ValueError("Palette image must be 1 pixel high")

    # Get the pixel data
    pixels = palette_image.load()

    # Create a list of hex colors
    palette = []

    # Add each color to the list
    for x in range(width):
        pixel = pixels[x, 0]
        # Convert to hex
        r_hex = hex(pixel[0])[2:].zfill(2)
        g_hex = hex(pixel[1])[2:].zfill(2)
        b_hex = hex(pixel[2])[2:].zfill(2)

        palette.append(f"{r_hex}{g_hex}{b_hex}")

    return palette


def create_palette_rom_line(index: int, hex_color: str) -> str:
    """
    Create a correct VHDL line for the palette ROM.
    Every color is represented as a 6-digit hex value.
    """
    line = f"        {index:02} => x\"{hex_color}\",\n"
    return line


def create_tile_rom_line(tile_appearance: list) -> str:
    """
    Create a correct VHDL line for the tile ROM.
    Every tile is represented as a 5-bit integer representing
    the index of the color in the palette.    

    Every line consists of 12 array elements (hex colors)
    """
    
    if len(tile_appearance) != 12:
        raise ValueError(f"Wrong number of colors in a line: {len(tile_appearance)}")

    line = ""
    for color in tile_appearance:
        if color > 2**5 - 1:
            raise ValueError(f"Color {color} is too wide")
        line += f'"{color:05b}", '

    final_line = f"        {line.strip()}\n"
    return final_line


def write_tile_rom(tileset: list, palette: list, tile_rom_file: str):
    """
    Given a tileset and palette, write it into the tile ROM file.
    """

    if len(palette) > 32:
        raise ValueError("Too many colors in the palette")
    
    file_lines = open(tile_rom_file, 'r').readlines()
        
    # get the palette array
    palette_rom_start_pattern = r'\s*CONSTANT palette_rom.*:=.*'
    palette_rom_array_lines = am.extract_vhdl_array(
        lines=file_lines,
        array_start_pattern=palette_rom_start_pattern
    )

    # clear previous contents of palette ROM
    palette_rom_array_lines = am.clear_vhdl_array(
        lines=palette_rom_array_lines,
        element_pattern=r'\s*\d+\s*=>.*,?\n'
    )

    # write the palette_rom
    palette_start, _ = am.find_array_start_end_index(
        lines=file_lines,
        array_start_pattern=palette_rom_start_pattern
    )
    for i, color in enumerate(palette):
        line = create_palette_rom_line(i, color)

        if i == len(palette)-1: # last line, no comma
            line = line.replace(',\n', '\n')

        palette_rom_array_lines.insert(i+1, line) 
            
    # insert the palette_rom_array_lines back into tile_rom_lines    
    file_lines[palette_start:palette_start+len(palette_rom_array_lines)] = palette_rom_array_lines

    # get the tile_rom array
    tile_rom_start_pattern = r'\s*CONSTANT tile_rom_data.*:=.*'
    tile_rom_lines = am.extract_vhdl_array(
        lines=file_lines,
        array_start_pattern=tile_rom_start_pattern
    )
    
    # clear previous contents of tile ROM
    tile_rom_lines = am.clear_vhdl_array(
        lines=tile_rom_lines,
        element_pattern=r'\s*".*",?',
        remove_comments=True
    )

    # find start linenum of tile_rom
    tile_rom_start, tile_rom_end = am.find_array_start_end_index(
        lines=file_lines,
        array_start_pattern=tile_rom_start_pattern
    )
    
    # write the tile_rom
    NUM_COLORS_PER_LINE = 12
    for i in range(len(tileset)):
        # append index
        tile_rom_lines.insert(-1, f"        -- {i}\n")
        tile_appearance = tileset[i]
        for j in range(NUM_COLORS_PER_LINE):
            layer = tile_appearance[12*j:12*(j+1)]
            new_line = create_tile_rom_line(layer)
            tile_rom_lines.insert(-1, new_line)
            

    tile_rom_lines[-2] = tile_rom_lines[-2].replace(',\n', '\n')
    # clear tile rom in file_lines
    file_lines[tile_rom_start:tile_rom_end+1] = []

    # insert the tile_rom_lines back into file_lines
    for i, line in enumerate(tile_rom_lines):
        file_lines.insert(tile_rom_start+i, line)

    with open(tile_rom_file, 'w') as f:
        f.writelines(file_lines)

def main():
    if len(sys.argv) < 2:
        sys.argv.append("hardware/tile_rom.vhd")
    if len(sys.argv) < 3:
        sys.argv.append("assets/palette.png")
    if len(sys.argv) < 4:
        sys.argv.append("assets/tileset.png")

    _, tile_rom_file, palette_file, tileset_file = sys.argv

    # Get the hex palette
    palette = read_palette(palette_file)

    # Parse the tileset image
    tileset = parse_tileset_image(tileset_file, palette)

    # Write the tileset to the tile ROM
    write_tile_rom(tileset, palette, tile_rom_file)
    
if __name__ == "__main__":
    main()

