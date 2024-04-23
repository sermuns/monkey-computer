import os, sys
from PIL import Image

BINARY_WIDTH = 3

def png_to_bin(image_path):
    """
    Given an image, return an array of binary values representing
    the color of each pixel in the image. 
    """

    # Load the image
    image = Image.open(image_path)

    # Get the size of the image
    width, height = image.size

    assert width == height == 12, 'Image is not square or 12x12'

    # Get the pixel data
    pixels = image.load()

    # Convert each pixel to binary
    binary_values = []
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            if a < 100: # Transparent enough
                r = g = b = 255 # MAKE IT COMPLETELY WHITE => TRANSPARENT

            # Map to 3-bit color
            r = int(round(r/255 * (2**BINARY_WIDTH - 1)))
            g = int(round(g/255 * (2**BINARY_WIDTH - 1)))
            b = int(round(b/255 * (2**BINARY_WIDTH - 1)))

            # Convert to binary
            r_binary = bin(r)[2:].zfill(BINARY_WIDTH)
            g_binary = bin(g)[2:].zfill(BINARY_WIDTH)
            b_binary = bin(b)[2:].zfill(BINARY_WIDTH)

            # Concatenate the binary values
            binary_values.append(f'{r_binary}{g_binary}{b_binary}')

    print(binary_values)
    return binary_values


def bin_to_image(bin_values):
    """
    Given an array of binary values representing the color of each pixel in an image,
    return a new image.
    """
    
    # Create a new image
    new_image = Image.new('RGB', (12, 12))

    # Load the pixel data
    pixels = new_image.load()

    # Convert each binary value to RGB
    for i, binary_value in enumerate(bin_values):
        r_binary = binary_value[:BINARY_WIDTH]
        g_binary = binary_value[BINARY_WIDTH:2*BINARY_WIDTH]
        b_binary = binary_value[2*BINARY_WIDTH:]

        r = int(r_binary, 2) * 255 // (2**BINARY_WIDTH - 1)
        g = int(g_binary, 2) * 255 // (2**BINARY_WIDTH - 1)
        b = int(b_binary, 2) * 255 // (2**BINARY_WIDTH - 1)

        pixels[i % 12, i // 12] = (r, g, b)

    return new_image

def hex_values_to_vhdl_array_elements(hex_values):
    """
    Given an array of hexadecimal values, return a string that can be pasted
    into a VHDL file as an array of elements.
    Two hex values are combined into a single element, separated by a _.
    """
    
    # Create the string
    vhdl_array_elements = ''
    for i, hex_value in enumerate(hex_values):
        if i % 2 == 0:
            vhdl_array_elements += f'x"{hex_value}'
        else: # second 
            vhdl_array_elements += f'_{hex_value}",\n'

    return vhdl_array_elements

def main():
    if len(sys.argv) != 2:
        print('Usage: python png_to_hex.py <image_path>')
        sys.exit(1)

    image_path = sys.argv[1]

    bin_values = png_to_bin(image_path)

    # to vhdl
    # vhdl_array_elements = hex_values_to_vhdl_array_elements(bin_values)
    # print(vhdl_array_elements)

    # test show file
    new_image = bin_to_image(bin_values)
    new_image.show('new_image.png')

    
if __name__ == '__main__':
    main()