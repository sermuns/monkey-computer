"""
Parse the tileset image as a flat list of palette indices,
then write it to the tile ROM.
"""

from PIL import Image
import re, sys
import array_manip as am

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

    # # save tileset as an image
    # tileset_image = Image.new("P", (120, 120))
    # tileset_image.putdata(tileset)
    # # add some colors to the palette
    # tileset_image.putpalette([0, 0, 0, 255, 255, 255, 255, 0, 0])
    # tileset_image.save("tileset.png")

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
        element_pattern=r'\s*".*",?'
    )

    # find start linenum of tile_rom
    tile_rom_start, tile_rom_end = am.find_array_start_end_index(
        lines=file_lines,
        array_start_pattern=tile_rom_start_pattern
    )
    
    # write the tile_rom
    NUM_COLORS_PER_LINE = 12
    lines_written = 0
    for i in range(len(tileset)):

        # add comment every 12 lines
        if i % NUM_COLORS_PER_LINE == 0:
            tile_rom_lines.insert(i+1, f"        -- {i//NUM_COLORS_PER_LINE}\n")
            comment_line = True

        colors_in_line = tileset[i*NUM_COLORS_PER_LINE:(i+1)*NUM_COLORS_PER_LINE]
        if len(colors_in_line) == 0:
            # replace last comma in lines with ''
            tile_rom_lines[i] = tile_rom_lines[i].replace(',\n', '\n')
            break # end of tileset
        new_line = create_tile_rom_line(colors_in_line)
        tile_rom_lines.insert(i+1+comment_line, new_line)
        lines_written += 1

    # clear tile rom in file_lines
    file_lines[tile_rom_start:tile_rom_end+1] = []

    # insert the tile_rom_lines back into file_lines
    for i, line in enumerate(tile_rom_lines):
        file_lines.insert(tile_rom_start+i+1, line)

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

    # write tileset to a temp image
    tileset_image = Image.new("P", (10, 10))

    # Write the tileset to the tile ROM
    write_tile_rom(tileset, palette, tile_rom_file)
    
if __name__ == "__main__":
    main()

