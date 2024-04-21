import os, sys
from PIL import Image

def png_to_hex(image_path):
    """
    Given an image, return an array of hexadecimal values representing
    the color of each pixel in the image. 
    """

    # Load the image
    image = Image.open(image_path)

    # Get the size of the image
    width, height = image.size

    assert width == height == 12, 'Image is not square or 12x12'

    # Get the pixel data
    pixels = image.load()

    # Convert each pixel to hex
    hex_values = []
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            if a < 100: # Transparent enough
                r = g = b = 255 # MAKE IT COMPLETELY WHITE => TRANSPARENT

            # Map to 4-bit color
            r = r // 16
            g = g // 16
            b = b // 16
            a = a // 16

            # Add to the list
            hex_values.append(f'{r:x}{g:x}{b:x}')

    return hex_values


def hex_to_png(hex_values):
    """
    Given an array of hexadecimal values, retrn an image from the values.
    """

    # Use hex_values to create an image
    new_image = Image.new('RGB', (12, 12))

    # Get the pixel data
    pixels = new_image.load()
    
    # Convert each hex value to RGB
    for y in range(12):
        for x in range(12):
            hex_value = hex_values.pop(0)
            r = int(hex_value[0], 16) * 16
            g = int(hex_value[1], 16) * 16
            b = int(hex_value[2], 16) * 16

            pixels[x, y] = (r, g, b)

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

    hex_values = png_to_hex(image_path)

    # to vhdl
    vhdl_array_elements = hex_values_to_vhdl_array_elements(hex_values)
    print(vhdl_array_elements)

    # test show file
    # new_image = hex_to_png(hex_values)
    # new_image.show('new_image.png')

    
if __name__ == '__main__':
    main()