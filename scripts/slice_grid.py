from PIL import Image
import os, sys

def slice_spritesheet(image_path, output_dir):
    """
    Given an image "spritesheet" that contains 10x10 square sprites, each 12x12
    in size, slice the spritesheet into individual sprites and save them to the
    output directory.

    Skip sprites that are completely transparent.
    """

    TILES = 10

    # Get image name without extension
    image_basename = os.path.basename(image_path).split('.')[0]

    # Load the image
    spritesheet = Image.open(image_path)

    # Get the size of the spritesheet
    sheet_width, sheet_height = spritesheet.size

    assert sheet_width == sheet_height, 'Spritesheet is not square'

    # Calculate the size of each sprite
    sprite_width = sheet_width // TILES
    sprite_height = sheet_height // TILES

    assert sprite_width == sprite_height == 12, 'Sprites are not 12x12'

    # Slice the spritesheet into individual sprites
    sprite_id = 0
    for row in range(TILES):
        for col in range(TILES):
            x = col * sprite_width
            y = row * sprite_height
            sprite = spritesheet.crop((x, y, x + sprite_width, y + sprite_height))

            # Skip sprites that are completely transparent
            if sprite.getbbox() is None:
                continue

            sprite_id += 1
            sprite.save(os.path.join(output_dir, f'sprite{sprite_id}_{image_basename}.png'))

def main():
    if len(sys.argv) != 3:
        print('Usage: python slice_grid.py <image_path> <output_dir>')
        sys.exit(1)

    image_path = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    slice_spritesheet(image_path, output_dir)
    
if __name__ == '__main__':
    main()