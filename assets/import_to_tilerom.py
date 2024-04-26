"""
Parse the tileset image as a flat list of palette indices,
then write it to the tile ROM.
"""

from PIL import Image
import re

def parse_tileset_image(image_file: str, palette: list) -> list:
    """
    Parse the tileset image as a flat list of palette indices.
    """
    # Open the image
    with Image.open(image_file) as img:
        # Convert the image to RGB
        img = img.convert("RGB")
        # Get the image data
        data = list(img.getdata())

    # Convert the image data to a flat list of palette indices
    tileset = []
    for pixel in data:
        # Get the RGB values
        r, g, b = pixel

        # Convert the RGB values to a hex color string
        hex_color = f"{r:02x}{g:02x}{b:02x}"

        # Check if the color is in the palette
        if hex_color not in palette:
            raise ValueError(f"Color {hex_color} not found in palette")

        # Get the index of the color
        index = palette.index(hex_color)

        # Add the index to the tileset
        tileset.append(index)

    return tileset


def read_palette(palette_image_name: str) -> list:
    """
    Read the palette image and return a list of hex colors.
    """
    # Load the palette image
    palette_image = Image.open(palette_image_name)

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

def create_tile_rom_line(colors: list) -> str:
    """
    Create a correct VHDL line for the tile ROM.
    Every tile is represented as a 5-bit integer representing
    the index of the color in the palette.    

    Every line consists of 12 array elements (hex colors)
    """
    
    if len(colors) != 12:
        raise ValueError(f"Wrong number of colors in a line: {len(colors)}")

    line = ""
    for color in colors:
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
    elif len(palette) < 32:
        print("Warning: palette has less than 32 colors, padding with undefined")
        [palette.append("UUUUUU") for _ in range(32 - len(palette))]
    
    with open(tile_rom_file, 'r') as f:
        tile_rom_lines = f.readlines()

    # find start linenum of palette_rom
    palette_start = 0
    for i, line in enumerate(tile_rom_lines):
        if re.match(r'\s*CONSTANT palette_rom.*:=.*', line):
            palette_start = i
            break

    # find end linenum of palette_rom
    palette_height = 0
    for i, line in enumerate(tile_rom_lines[palette_start:]):
        if re.match(r'\s*\);\s*', line):
            palette_height = i
            break

    # clear previous contents of palette ROM
    tile_rom_lines[palette_start+1:palette_start+palette_height] = []

    # write the palette_rom
    for i, color in enumerate(palette):
        line = create_palette_rom_line(i, color)
        if i == 31: # last line, no comma
            line = line.replace(',\n', '\n')

        tile_rom_lines.insert(palette_start+i+1, line) 
            

    # find start linenum of tile_rom
    tile_rom_start = 0
    for i, line in enumerate(tile_rom_lines):
        if re.match(r'\s*CONSTANT tile_rom.*:=.*', line):
            tile_rom_start = i + 1
            break

    # find end of tile_rom
    tile_rom_height = 0
    for i, line in enumerate(tile_rom_lines[tile_rom_start:]):
        if re.match(r'\s*\);\s*', line):
            tile_rom_height = i
            break

    # clear previous contents of tile ROM
    tile_rom_lines[tile_rom_start:tile_rom_start+tile_rom_height] = []
    
    # write the tile_rom
    NUM_COLORS_PER_LINE = 12
    lines_written = 0
    for i, tile in enumerate(tileset):
        if i % 12 == 0:
            tile_rom_lines.insert(tile_rom_start+i, f'        -- {i // 12}\n')
        colors_in_line = tileset[i*NUM_COLORS_PER_LINE:i*NUM_COLORS_PER_LINE+NUM_COLORS_PER_LINE]
        if len(colors_in_line) == 0:
            break # end of tileset
        tile_rom_lines.insert(tile_rom_start+i+1, create_tile_rom_line(colors_in_line))
        lines_written += 1

        # if i % 12 == 0:
        #     tile_rom_lines.insert(tile_start+i+1, '\n')

    # # add others undefined
    # others_line = f'\n       OTHERS => (OTHERS => 'U')\n'
    # tile_rom_lines.insert(tile_rom_start+lines_written+1, others_line) 


    with open(tile_rom_file, 'w') as f:
        f.writelines(tile_rom_lines)

def main():
    # Get the hex palette
    palette = read_palette("palette.png")

    # Parse the tileset image
    tileset = parse_tileset_image("tileset.png", palette)

    # Write the tileset to the tile ROM
    write_tile_rom(tileset, palette, "../hardware/src/tile_rom.vhd")
    
if __name__ == "__main__":
    main()

