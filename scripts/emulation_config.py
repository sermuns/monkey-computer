import os

os.environ["SDL_VIDEO_CENTERED"] = "1"
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "hide"
import pygame as pg

from enum import Enum, auto

PYGAME_FLAGS = 0
WINDOW_TITLE = "monkey-emulator🐒"
FONT_SIZE = 16

# File paths
TILE_ROM_FILE = os.path.join("hardware", "tile_rom.vhd")
MASM_DIR = "masm"


class EmulationEvent(Enum):
    step = auto()
    reset = auto()
    quit = auto()
    show_debug_pane = auto()
    continue_to_breakpoint = auto()
    safe_continue_to_breakpoint = auto()
    interact_with_memory = auto()
    pause = auto()
    resume = auto()


KEYBINDINGS = {
    pg.K_n: EmulationEvent.step,
    pg.K_F10: EmulationEvent.step,
    pg.K_r: EmulationEvent.reset,
    pg.K_q: EmulationEvent.quit,
    pg.K_ESCAPE: EmulationEvent.quit,
    pg.K_F1: EmulationEvent.show_debug_pane,
    pg.K_c: EmulationEvent.continue_to_breakpoint,
    pg.K_F5: EmulationEvent.continue_to_breakpoint,
    pg.K_F6: EmulationEvent.safe_continue_to_breakpoint,
    pg.K_F2: EmulationEvent.interact_with_memory,
    pg.K_p: EmulationEvent.pause,
    pg.K_RETURN: EmulationEvent.resume,
}
