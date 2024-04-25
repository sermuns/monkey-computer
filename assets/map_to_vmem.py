"""
Parse a map file from Tiled and export it as VHDL array elements into
video memory file.
"""

import xml.etree.ElementTree as ET
import sys
import re

VMEM_HEIGHT = 25  # currently 25 lines in pMem.vhd


def read_tmx_file(file_path):
    """
    Read a TMX file and return the root element
    """
    tree = ET.parse(file_path)
    root = tree.getroot()
    return root


def get_final_map(layers):
    """
    Get the final layer of the map by combining all the layers:
    Begin from the topmost layer, if a cell is empty (value 0)
    let the next layer overwrite it.
    """
    # the final map
    map = []

    # get tiles from each layer, begin with the top layer
    # whenever a tile 0 is found, it means that the cell is empty, so we can allow
    # for the next layer to overwrite it
    for layer in layers[::-1]:
        data = layer.find("data")
        rows = data.text.split("\n")
        rows = [row.removesuffix(",")
                for row in rows if row != ""]  # remove empty rows
        rows = [[int(tile) for tile in row.split(",")] for row in rows]

        # add the tiles to the map
        for i, row in enumerate(rows):
            # new row
            if i >= len(map):
                map.append(row)
                continue

            # check if the cell is empty
            for j, tile in enumerate(row):
                if map[i][j] == 0:  # can overwrite
                    map[i][j] = tile

    return map


def create_vmem_line(index: int, tiles: list) -> str:
    """
    Create a correct VHDL line for the video memory.
    Every tiletype is represented as unsigned 6-bit integer.
    Each line only fits 4 tiles.
    """

    if len(tiles) > 4:
        raise ValueError("Too many tiles in a line")

    line = f"        VMEM_START + {index:02} => b\""

    for tile in tiles:
        if tile > 2**6 - 1:
            raise ValueError(f"Tile {tile} is too big")
        line += f"{tile:06b}_"

    line = line.removesuffix("_")
    line += "\",\n"

    return line


def write_to_vmem(map, vmem_file):
    """
    Write a map (matrix of tile-types) to the vmem file
    """

    with open(vmem_file, "r") as f:
        vmem_lines = f.readlines()

    # find the line where the map starts
    start_line = 0
    for i, line in enumerate(vmem_lines):
        if re.match(r'\s*VMEM_START\s*=>\s*b.*', line):
            start_line = i
            break

    # clear previous contents of VMEM
    vmem_lines[start_line:start_line+VMEM_HEIGHT] = []

    # get flat map
    flat_map = [tile for row in map for tile in row]

    # write the map to the vmem file
    for i in range(0, VMEM_HEIGHT):
        vmem_line = create_vmem_line(i, flat_map[4*i:4*i+4])
        vmem_lines.insert(start_line+i, vmem_line)

    with open(vmem_file, "w") as f:
        f.writelines(vmem_lines)


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--debug":
        # for debugging purposes
        sys.argv = ["map_to_vmem.py", "map.tmx", "../hardware/src/pMem.vhd"]
    elif len(sys.argv) != 3:
        print("Usage: python map_to_vmem.py <map.tmx> <pmem.vhd>")
        sys.exit(1)

    # unpack the arguments
    _, map_file, vmem_file = sys.argv

    # get the root element
    root = read_tmx_file(map_file)
    # get the layers
    layers = root.findall("layer")
    # get the final map
    map = get_final_map(layers)

    # write the map to the vmem file
    write_to_vmem(map, vmem_file)


if __name__ == '__main__':
    main()
