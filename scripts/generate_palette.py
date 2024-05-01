from PIL import Image


def generate_possible_colors(bits):
    """
    Return list of all possible hex colors with the given amount of bits per
    color channel.
    """

    # Calculate the number of possible hues per channel
    hues = 2**bits

    # Create a list of possible colors
    colors = []
    for r in range(hues):
        for g in range(hues):
            for b in range(hues):
                # map to 8-bit color
                r_mapped = int(round(r/(hues-1) * 255)) if hues > 1 else 0
                g_mapped = int(round(g/(hues-1) * 255)) if hues > 1 else 0
                b_mapped = int(round(b/(hues-1) * 255)) if hues > 1 else 0

                # Convert to hex
                r_hex = hex(r_mapped)[2:].zfill(2)
                g_hex = hex(g_mapped)[2:].zfill(2)
                b_hex = hex(b_mapped)[2:].zfill(2)

                # Concatenate the hex values
                colors.append(f'{r_hex}{g_hex}{b_hex}')

    # sort the list by hue
    colors.sort()

    return colors


def sort_by_hue(colors, starting_hue=0):
    """
    Given a list of hex colors, return a list of colors sorted by hue.
    """

    # Create a list of tuples with the hue and the color
    hues = []
    for color in colors:
        r = int(color[:2], 16)
        g = int(color[2:4], 16)
        b = int(color[4:], 16)

        # Calculate the hue
        max_color = max(r, g, b)
        min_color = min(r, g, b)

        if max_color == min_color:
            hue = 0
        elif max_color == r:
            hue = (g - b) / (max_color - min_color)
        elif max_color == g:
            hue = 2 + (b - r) / (max_color - min_color)
        else:
            hue = 4 + (r - g) / (max_color - min_color)

        # Shift the hue by the starting hue
        hue = (hue + starting_hue) % 6

        hues.append((hue, color))

    # Sort the list by hue
    hues.sort()

    # Return the sorted colors
    return [color for hue, color in hues]


def save_to_image(palette, image_name):
    """
    Given a list of hex colors, save them to a flat image.
    """

    # save to an image with height 1px and width equal to the number of colors
    image = Image.new('RGB', (len(palette), 1))

    # fill with the colors
    pixels = image.load()

    for i, color in enumerate(palette):
        r = int(color[:2], 16)
        g = int(color[2:4], 16)
        b = int(color[4:], 16)

        pixels[i, 0] = (r, g, b)

    image.save(image_name)


def move_black_and_white_to_front(palette):
    """
    Given a list of hex colors, move the black and white colors to the front.
    """

    # remove the black and white colors
    palette.remove('000000')
    palette.remove('ffffff')

    # move them to the front
    palette.insert(0, '000000')
    palette.insert(0, 'ffffff')

    return palette


def get_list_of_colors(image_name: str) -> list:
    """
    Given an image, return a list of all present colors in hex format.
    """

    # Load the image
    image = Image.open(image_name)

    # Get the size of the image
    width, height = image.size

    # Get the pixel data
    pixels = image.load()

    # Create a set of unique colors
    colors = set()

    # Add each color to the set
    for x in range(width):
        for y in range(height):
            pixel = pixels[x, y]
            # convert to hex
            r_hex = hex(pixel[0])[2:].zfill(2)
            g_hex = hex(pixel[1])[2:].zfill(2)
            b_hex = hex(pixel[2])[2:].zfill(2)

            colors.add(f'{r_hex}{g_hex}{b_hex}')

    return list(colors)


def print_vhdl_formatted(palette):
    """
    Given a list of hex colors, print them in a VHDL formatted list.
    """

    for i, color in enumerate(palette):
        if i == len(palette) - 1:
            print(f'        {i} => X"{color}"')
            return

        print(f'        {i} => X"{color}",')


if __name__ == '__main__':
    colors_in_tileset = []

    colors_in_tileset = get_list_of_colors('tileset.png')

    colors_in_tileset = list(set(colors_in_tileset))  # remove duplicates

    if len(colors_in_tileset) > 32:
        raise ValueError("Too many colors in the frames")

    colors_in_tileset = sort_by_hue(colors_in_tileset)
    colors_in_tileset = move_black_and_white_to_front(colors_in_tileset)

    # print_vhdl_formatted(colors_in_frames)
    save_to_image(colors_in_tileset, 'palette.png')
