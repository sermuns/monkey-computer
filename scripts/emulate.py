#!/usr/bin/env python3

# includes pygame and enum
from emulation_config import *

import threading
import sys
import numpy as np
import re
import easygui

import utils
import array_manip as am
from machine import Machine


# Global variables
CONSTANTS = {}
PALETTE = []
window_scale = 1

# Constants
FPS = 60
SURFACE_WIDTH_PX = 640
SURFACE_HEIGHT_PX = 480
# With MENU implemented, map tile size is unsymmetrical can not use (MAP_SIZE_TILES = 10)
MAP_SIZE_X_TILES = 13
MAP_SIZE_Y_TILES = 10
# With MENU implemented, map tile size is unsymmetrical can not use (MAP_SIZE_PX = SURFACE_HEIGHT_PX)
MAP_SIZE_X_PX = (
    MAP_SIZE_X_TILES * 12 * 4
)  # ( amount of tiles x axis*amount of macropixels x axis*macropixel size)
MAP_SIZE_y_PX = (
    MAP_SIZE_Y_TILES * 12 * 4
)  # ( amount of tiles y axis*amount of macropixels y axis*macropixel size)
TILE_SIZE_PX = 48  # Commented out (MAP_SIZE_PX // MAP_SIZE_TILES) because it should not be dependent on neither of them
FONT_PATH = os.path.join("scripts", "fonts", "jetbrainsmono.ttf")


DEBUG_ASSEMBLY_FILE = "path.s"  # change this to which file you want to debug


def parse_vmem(vmem_lines: list) -> np.ndarray:
    """
    Parse the VHDL array elements into a 10x10 numpy array.
    """

    VMEM_FIELD_WIDTH = 6

    flat_vmem = []

    for i, line in enumerate(vmem_lines):
        # Match all fields in the line (e.g. b"000000_000000_000000_000000"
        fields = re.findall(rf"\d{{{VMEM_FIELD_WIDTH}}}", line)
        # Parse each field into a 6-bit integer
        flat_vmem += [int(field, 2) for field in fields]

    vmem = np.zeros((10, 10), dtype=np.uint8)
    for i, val in enumerate(flat_vmem):
        vmem[i // 10, i % 10] = val
    return vmem


def read_palette(tile_rom_lines: list) -> list:
    """
    Read the palette from lines of tile_rom.vhd
    """

    palette_array = am.extract_vhdl_array(
        tile_rom_lines, r"\s*CONSTANT\s*palette_rom.*"
    )
    palette_elements = am.get_vhdl_array_elements(
        palette_array, element_pattern=r'\d+ => x"\w+"'
    )

    palette = []

    for elem in palette_elements:
        # Extract the 3-digit hex values
        hex_color = re.search(r'x"(\w+)"', elem).group(1)
        # Convert to 0-255 r,g,b values
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
        palette.append((r, g, b))

    return palette


def read_tile_rom(tile_rom_lines: list) -> np.ndarray:
    """
    Read the tile ROM from lines of tile_rom.vhd
    """

    tile_rom_array = am.extract_vhdl_array(
        tile_rom_lines, r"\s*CONSTANT.*tile_rom_type\s*:="
    )
    tile_rom_elements = am.get_vhdl_array_elements(
        lines=tile_rom_array, element_pattern=r"\d+"
    )

    # Flatten the list comprehension to create a flat list of elements
    tile_rom = []
    for elem in tile_rom_elements:
        tile_rom += [int(re.search(r"\d+", elem).group(0), 2)]

    return np.array(tile_rom, dtype=np.uint8)


def get_tile(tile_type: int, tile_rom: list) -> pg.Surface:
    """
    Get tile appearance from tile ROM, use the values from it to fetch
    real colors from the palette.
    """

    TILE_SIZE_MACROPIXELS = TILE_SIZE_PX // 4  # 12x12 macropixels per tile

    surface = pg.Surface((TILE_SIZE_MACROPIXELS, TILE_SIZE_MACROPIXELS))

    # Get the tile from the tile ROM
    tile_data = tile_rom[
        tile_type
        * TILE_SIZE_MACROPIXELS**2 : (tile_type + 1)
        * TILE_SIZE_MACROPIXELS**2
    ]

    # Map the palette indices to colors
    tile_colors = []
    for palette_index in tile_data:
        tile_colors.append(PALETTE[palette_index])

    for y in range(TILE_SIZE_MACROPIXELS):
        for x in range(TILE_SIZE_MACROPIXELS):
            color = tile_colors[y * TILE_SIZE_MACROPIXELS + x]
            surface.set_at((x, y), color)
    return pg.transform.scale(surface, (TILE_SIZE_PX, TILE_SIZE_PX))


def get_map_surface(machine, tile_rom):
    """
    Draw the map from video memory to a surface, return it.
    """

    VMEM = machine.sections["VMEM"].start

    surface = pg.Surface(
        (MAP_SIZE_X_TILES * TILE_SIZE_PX, MAP_SIZE_Y_TILES * TILE_SIZE_PX)
    )

    for y in range(MAP_SIZE_Y_TILES):
        for x in range(MAP_SIZE_X_TILES):
            id = y * MAP_SIZE_X_TILES + x
            vmem_row = machine.memory[VMEM + id]
            current_tile_type = utils.get_decimal_int(vmem_row)
            if current_tile_type > tile_rom.size // 144:
                raise ValueError(
    f"""
    VMEM contains too big tile type {current_tile_type} at address VMEM+{id} (x={x}, y={y}).
    Tile ROM only has {tile_rom.size // 144} tiles.
    """
                )

            tile = get_tile(current_tile_type, tile_rom)
            tile_pos = (x * TILE_SIZE_PX, y * TILE_SIZE_PX)
            surface.blit(tile, tile_pos)

    return surface


def handle_args():
    """
    Handle command line arguments
    """

    if len(sys.argv) < 2:
        print("Usage: python emulate.py <assembly_file.s> <args>")
        sys.exit(1)

    if sys.argv[1] == "--debug":
        sys.argv[1] = DEBUG_ASSEMBLY_FILE

    for arg in sys.argv[1:]:
        if "--scale=" in arg:
            global window_scale
            window_scale = int(arg.split("=")[1])

    asm_file_name = sys.argv[1]

    return asm_file_name


def blit_textlines_to_surface(target_surface, text_lines, font):
    """
    Blit text lines to a surface
    """

    # If text_lines is a string, convert it to a list with one element
    if isinstance(text_lines, str):
        text_lines = [text_lines]

    # Calculate the height of the font
    font_height = font.get_height()
    padding_x = 15 * window_scale
    padding_y = 10 * window_scale

    for i, line in enumerate(text_lines):

        # horizontal line spanning the width of the screen
        if line == "-":
            color = "white"
            start_pos = (padding_x, 10 * window_scale + padding_y + i * font_height)
            end_pos = (
                target_surface.get_width() - padding_x,
                10 * window_scale + padding_y + i * font_height,
            )
            line_width = window_scale

            pg.draw.line(target_surface, color, start_pos, end_pos, line_width)
            continue

        # breakpoint
        if ";b" in line:
            color = "brown"
        else:
            color = "white"

        # bold
        if line.startswith("<b>"):
            line = line[3:]
            font.set_bold(True)
        else:
            font.set_bold(False)

        # Render the line of text
        text = font.render(line, True, color)

        # Calculate the position of the text
        textpos = text.get_rect()
        textpos.topleft = (padding_x, padding_y + i * font_height)

        # Blit the text onto the debug_surface
        target_surface.blit(text, textpos)


def create_register_lines(machine):
    """
    Create a list of lines with the register values
    """

    register_lines = []
    register_line = ""
    for register, value in machine.registers.items():
        register_line += f"{register:4}:{value:10}  "
        if len(register_line) > 40:
            register_lines.append(register_line)
            register_line = ""

    # Append the last line if it has less than 3 registers
    if register_line:
        register_lines.append(register_line)

    return register_lines


def get_nearest_lines(machine, pc_value):
    """
    Get lines above and below the current line
    """

    nearest_lines = []
    NUM_NEAR_LINES = 4

    # Get lines above, at, and below the current line
    for i in range(pc_value - NUM_NEAR_LINES, pc_value + NUM_NEAR_LINES + 1):
        if not 0 <= i < len(machine.memory):
            nearest_lines.append("")
            continue

        line = machine.memory[i]

        nearest_line = f"{i:3}:\u3000{line}"
        if i == pc_value:
            # Add the "->" marker for the current line
            nearest_line = f"->{nearest_line}"
        else:
            nearest_line = f"\u3000{nearest_line}"
        nearest_lines.append(nearest_line)

    return nearest_lines


def get_debug_pane(machine, surface_size):
    """
    Return surface with various debug information
    printed as text
    """

    debug_surface = pg.Surface(surface_size).convert_alpha()
    debug_surface.fill((0, 0, 0, 150))  # semi-transparent background

    # Create a separate surface for the background
    background_surface = pg.Surface(surface_size).convert_alpha()

    # Fill the background surface with white color
    background_surface.fill((0, 0, 0, 50))
    font = pg.font.Font(FONT_PATH, window_scale * FONT_SIZE)

    # Create a list of text lines to display
    debug_text_lines = []

    # --- REGISTERS ---
    debug_text_lines += ["<b>Registers"]
    debug_text_lines += create_register_lines(machine)

    # -- NEAREST LINES ---
    pc_value = machine.registers["PC"]

    debug_text_lines += ["", "<b>Nearest lines", "-"]
    debug_text_lines += get_nearest_lines(machine, pc_value)
    debug_text_lines += ["-", ""]

    # --- ALU FLAGS ---
    debug_text_lines += ["<b>ALU flags"]
    flags_line = ""
    for flag, value in machine.flags.items():
        flags_line += f"{flag}:{value} "

    debug_text_lines += [flags_line]

    blit_textlines_to_surface(debug_surface, debug_text_lines, font)

    # Draw a border around the debug_surface
    border_color = "white"
    border_width = -1  # no border
    pg.draw.rect(debug_surface, border_color, debug_surface.get_rect(), border_width)

    return debug_surface


def update_screen(screen, machine, show_debug_pane, cursor_position):
    """
    Redraw the screen with the current state of the machine
    """

    # Clear the screen
    screen.fill("black")

    small_surface = pg.Surface(
        (
            SURFACE_WIDTH_PX,
            SURFACE_HEIGHT_PX,
        )
    )

    # Draw game map
    map_surface = get_map_surface(machine, TILE_ROM)
    small_surface.blit(map_surface, (0, 0))
    scaled_surface = pg.transform.scale_by(small_surface, window_scale)
    screen.blit(scaled_surface, (0, 0))

    # Draw cursor
    tile_size_screen_px = TILE_SIZE_PX * window_scale
    cursor_tile_x = cursor_position[0] // tile_size_screen_px
    cursor_tile_y = cursor_position[1] // tile_size_screen_px
    if 0 <= cursor_tile_x < MAP_SIZE_X_TILES and 0 <= cursor_tile_y < MAP_SIZE_Y_TILES:
        cursor_rect = pg.Rect(
            cursor_tile_x * tile_size_screen_px,
            cursor_tile_y * tile_size_screen_px,
            tile_size_screen_px,
            tile_size_screen_px,
        )
        pg.draw.rect(screen, "grey", cursor_rect, window_scale)
        tile_pos_text = f"{cursor_tile_y * MAP_SIZE_X_TILES + cursor_tile_x}({cursor_tile_x}, {cursor_tile_y})"
        tiletype_text = f"type={utils.get_decimal_int(machine.memory[machine.sections['VMEM'].start + cursor_tile_y * MAP_SIZE_X_TILES + cursor_tile_x])}"
        textlines = f"{tile_pos_text}, {tiletype_text}"

        font = pg.font.Font(FONT_PATH, window_scale * FONT_SIZE)
        blit_textlines_to_surface(screen, textlines, font)

    # Debug pane
    if show_debug_pane:
        debug_width = window_scale * SURFACE_WIDTH_PX
        debug_height = window_scale * SURFACE_HEIGHT_PX
        debug_surface = get_debug_pane(machine, (debug_width, debug_height))
        # place at the right side of the screen
        placement_pos = (screen.get_width() - debug_width, 0)
        screen.blit(debug_surface, placement_pos)

    # Draw play or pause button
    draw_play_or_pause_button(screen, machine.running_free)

    pg.display.flip()


def draw_play_or_pause_button(screen, running_free):
    """
    Draw play or pause button in the top right corner
    """

    button_size = 20 * window_scale
    button_pos = (screen.get_width() - button_size, 0)

    # Create a new surface with the same size as the button
    button_surface = pg.Surface((button_size, button_size))

    # Draw the button on the new surface
    if running_free:
        pg.draw.rect(button_surface, "green", button_surface.get_rect())
    else:
        pg.draw.rect(button_surface, "red", button_surface.get_rect())

    # Draw the play or pause symbol on the new surface
    if running_free:
        pg.draw.polygon(
            button_surface,
            "black",
            [
                (5 * window_scale, 5 * window_scale),
                (5 * window_scale, 15 * window_scale),
                (15 * window_scale, 10 * window_scale),
            ],
        )
    else:
        pg.draw.rect(
            button_surface,
            "black",
            pg.Rect(
                5 * window_scale,
                5 * window_scale,
                3 * window_scale,
                10 * window_scale,
            ),
        )
        pg.draw.rect(
            button_surface,
            "black",
            pg.Rect(
                12 * window_scale,
                5 * window_scale,
                3 * window_scale,
                10 * window_scale,
            ),
        )

    # Set the transparency of the surface
    button_surface.set_alpha(128)  # 128 out of 255 for 50% transparency

    # Blit the surface onto the screen
    screen.blit(button_surface, button_pos)


def create_screen(width: int, height: int) -> pg.Surface:
    """
    Create a pg screen with the given width and height.
    Use the global PYGAME_FLAGS constant.
    """

    screen = pg.display.set_mode((width, height), PYGAME_FLAGS)

    return screen


if __name__ == "__main__":
    # change the working directory to the root of the project
    utils.change_dir_to_root()

    # get tile_rom and palette from tile_rom.vhd
    tile_rom_lines = open(TILE_ROM_FILE).readlines()
    PALETTE = read_palette(tile_rom_lines)
    TILE_ROM = read_tile_rom(tile_rom_lines)

    # find which assembly file to emulate
    asm_file_name = handle_args()

    # create machine object
    machine = Machine(asm_file_name)

    show_debug_pane = False  # show machine state on screen

    # initialise pg
    pg.init()
    screen = pg.display.set_mode(
        (window_scale * SURFACE_WIDTH_PX, window_scale * SURFACE_HEIGHT_PX),
        PYGAME_FLAGS,
    )
    pg.display.set_caption(WINDOW_TITLE)
    cursor_position = (-1, -1)
    update_screen(screen, machine, show_debug_pane, cursor_position)

    clock = pg.time.Clock()

    # Start a new thread that will run machine fast whenever `running_free` is True
    # This is done to prevent the main thread from being blocked by the machine
    thread = threading.Thread(target=machine.run_fast)
    thread.daemon = True
    thread.start()

    while True:
        update_screen(screen, machine, show_debug_pane, cursor_position)
        # clock.tick(FPS)
        for event in pg.event.get():
            if event.type == pg.QUIT:
                sys.exit()
            elif event.type == pg.KEYDOWN:

                # handle in-game keypresses
                if event.key not in KEYBINDINGS:
                    machine.register_keypress(event.key)
                    continue

                emulation_event = KEYBINDINGS.get(event.key)

                if emulation_event is None:
                    continue
                elif emulation_event == EmulationEvent.reset:
                    machine.reset()
                elif emulation_event == EmulationEvent.quit:
                    sys.exit()
                elif emulation_event == EmulationEvent.interact_with_memory:
                    # show easygui prompt to input desired memory address to show
                    desired_address = easygui.enterbox("Enter memory address to show:")
                    if not desired_address:
                        continue  # user cancelled
                    try:
                        desired_address = utils.get_decimal_int(desired_address)
                        memory_value = machine.get_from_memory(desired_address)
                        easygui.msgbox(
                            f"Memory address {desired_address} contains value {memory_value}"
                        )
                    except Exception as e:
                        easygui.msgbox(f"Error: {e}")
                elif emulation_event == EmulationEvent.show_debug_pane:
                    show_debug_pane = not show_debug_pane
                elif emulation_event == EmulationEvent.pause:
                    machine.toggle_pause()
                elif emulation_event == EmulationEvent.step:
                    machine.execute_next_instruction()
                elif emulation_event == EmulationEvent.continue_to_breakpoint:
                    machine.continue_to_breakpoint()
                else:
                    utils.ERROR(f"Unhandled emulation event: {emulation_event}")

            elif event.type == pg.MOUSEBUTTONDOWN:
                if event.button != 1:
                    continue
                cursor_position = event.pos
