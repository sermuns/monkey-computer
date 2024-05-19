import utils, os
from utils import COLORS

MASM_DIR = "masm"

def preassemble(asm_file_name: str) -> list[str]:
    """
    Preassemble the assembly file by performing various
    pre-processing steps.
    Return preassembled file lines
    """
    
    # Find the root directory of the project
    utils.change_dir_to_root()
    
    # Read the assembly file
    asm_file_path = os.path.join(MASM_DIR, asm_file_name)
    asm_lines = open(asm_file_path, "r").readlines()
    
    # Resolve all includes in the assembly file
    utils.resolve_includes(asm_lines, masm_dir="masm")
    
    # Remove comments and empty lines
    asm_lines = utils.get_without_empty_or_only_comment_lines(asm_lines)

    utils.resolve_mov_on_stack(asm_lines)

    # check if program contains HALT, otherwise crash
    if not any("HALT" in line for line in asm_lines):
        print(f"{COLORS.FAIL}ERROR:{COLORS.ENDC} HALT instruction not found in program")

    return asm_lines