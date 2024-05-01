"""
Create a flat tileset (.tsx file for Tiled) from the built images from `tiles.asesprite`
"""

from PIL import Image

TILE_SIZE = 12  # all tiles are 12x12 pixels


def get_tile(x: int, y: int, image: Image) -> Image:
    """
    Get tile from image at x, y
    """
    return image.crop((x * TILE_SIZE, y * TILE_SIZE, x * TILE_SIZE + TILE_SIZE, y * TILE_SIZE + TILE_SIZE))


def get_frames_for_tile(x: int, y: int, frames: list) -> list:
    """
    Get all animation frames for a tile at x, y
    """
    return [get_tile(x, y, frame) for frame in frames]


def create_flat_tileset(frames) -> list:
    """
    Return a flat tileset as a list of tile images
    """
    tiles = []  # list of all tiles as they should appear

    # grass tile
    tiles += [get_tile(x=4, y=4, image=frames[0])]

    # monkey 1
    tiles += get_frames_for_tile(x=1, y=0, frames=frames)

    # monkey 2
    tiles += get_frames_for_tile(x=2, y=0, frames=frames)
    
    # monkey 3
    tiles += get_frames_for_tile(x=3, y=0, frames=frames)

    # monkey 4
    tiles += get_frames_for_tile(x=4, y=0, frames=frames)

    # monkey 5
    tiles += get_frames_for_tile(x=5, y=0, frames=frames)
    
    # monkey 6
    tiles += get_frames_for_tile(x=6, y=0, frames=frames)
    
    # road
    tiles += [get_tile(x=2, y=7, image=frames[0])]

    # balloon yellow
    tiles += get_frames_for_tile(x=0, y=0, frames=frames)

    # balloon green
    tiles += get_frames_for_tile(x=0, y=1, frames=frames)

    # balloon pink
    tiles += get_frames_for_tile(x=0, y=2, frames=frames)
    

    return tiles


def main():
    frames = [Image.open(f"build/frame{i+1}.png") for i in range(4)]

    tiles = create_flat_tileset(frames)

    # write flat_tileset to a 10x10 grid image
    final_tileset = Image.new("RGBA", (TILE_SIZE * 10, TILE_SIZE * 10))

    # paste all tiles to final_tileset
    for i, tile in enumerate(tiles):
        x, y = i % 10, i // 10
        final_tileset.paste(tile, (x * TILE_SIZE, y * TILE_SIZE))

    final_tileset.save("tileset.png")


if __name__ == "__main__":
    main()
