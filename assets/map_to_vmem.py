"""
Parse a map file from Tiled and export it as a VHDL array
"""

import xml.etree.ElementTree as ET


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
        rows = [row.removesuffix(",") for row in rows if row != ""] # remove empty rows
        rows = [[int(tile) for tile in row.split(",")] for row in rows]

        # add the tiles to the map
        for i, row in enumerate(rows):
            # new row
            if i >= len(map):
                map.append(row)
                continue

            # check if the cell is empty
            for j, tile in enumerate(row):
                if map[i][j] == 0: # can overwrite
                    map[i][j] = tile

    return map


def main():
    # get the root element
    root = read_tmx_file("map.tmx")
    # get the layers
    layers = root.findall("layer")
    # get the final map
    map = get_final_map(layers)
    print(map)

if __name__ == '__main__':
    main()