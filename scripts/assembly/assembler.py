"""
Parse the given argument file from monkey-assembly to binary code
"""

import re, sys, os
from pathlib import Path

# Get the absolute path of the parent directory
parent_dir = Path(__file__).resolve().parent.parent

# Add the parent directory to sys.path if not already included
if str(parent_dir) not in sys.path:
    sys.path.append(str(parent_dir))

import utils
from utils import ERROR
import array_manip as am

# begin by changing dir to root of file
utils.chdir_to_root()

PROG_DIR = "masm"
HARDWARE_DIR = "hardware"
PMEM_FILE = os.path.join(HARDWARE_DIR, "pMem.vhd")
FAX_FILE = os.path.join(HARDWARE_DIR, "fax.md")

ADR_WIDTH = 12

DEBUG_ARG = "directives.s"

# OP GRx, ADR
IN_OPERATIONS = {"LD", "ADD", "SUB", "AND", "OR", "IN", "MUL", "LSR", "LSL"}
# OP ADR, GRx
OUT_OPERATIONS = {"ST", "OUT"}
# OP GRx, GRx
TWO_REG_OPERATIONS = {"MOV", "ADDREG"}
# OP GRx
ONE_REG_OPERATIONS = {"POP", "PUSH", "JSR"}
# OP
NO_ARGS_OPERATIONS = {"RET"}
# OP ADR
ONE_ADDR_OPERATIONS = {"BRA"}

INSTRUCTION_WIDTH = 24


def get_opcodes():
    """
    Get the opcodes from the `fax.md` file
    """

    with open(FAX_FILE, "r") as f:
        lines = f.readlines()
    if not lines:
        print(f"Error: Could not find/read {FAX_FILE}")
        sys.exit(1)
    opcodes = {}
    # find the opcodes header
    opcodes_start_line = None
    for i, line in enumerate(lines):
        if line.startswith("## OP-koder"):
            opcodes_start_line = i
            break

    # no opcodes header found?
    if opcodes_start_line is None:
        print(f"Error: Could not find opcodes header in {FAX_FILE}")
        sys.exit(1)

    # loop through opcodes
    for i in range(opcodes_start_line + 1, len(lines)):
        line = lines[i]
        if not line:  # skip empty lines
            continue
        if not re.match(r"\d+", line):  # stop if not numerical
            break
        parts = line.split()
        if len(parts) != 2:
            print(f"Error: Could not parse opcode line {i + 1} in {FAX_FILE}")
            sys.exit(1)
        opcode, name = parts
        opcodes[name] = opcode

    return opcodes


KNOWN_OPCODES = get_opcodes()


class Section:
    """
    Represents continious portion of the memory
    """

    def __init__(self, name, start, height, lines=None):
        self.name = name
        self.start = start
        self.height = height
        self.lines = lines or []

    def __repr__(self) -> str:
        return f"{self.name} {self.start} {self.height}"


def assemble_binary_line(line, label):
    """
    Return binary line from the given assembly line
    If the instruction is an immediate instruction, the immediate value is
    also returned as a separate line.
    """

    binary_lines = []

    # split into parts by comma and whitespace
    parts = re.split(r",\s*|\s+", line)
    op_fullname = parts[0]

    # get base opname
    op_basename = None
    op_address_mode = None
    for known_op_name in KNOWN_OPCODES:
        if op_fullname.startswith(known_op_name):
            op_basename = known_op_name
            op_address_mode = op_fullname[len(op_basename) :]
            break

    # unknown op?
    if not op_basename:
        ERROR(f"Unknown operation {op_fullname} in {line}")

    # initialize variables
    op_adr = "-"
    grx_name = "-"
    immediate_value = ""

    # get register and address
    if op_basename in IN_OPERATIONS:
        grx_name, op_adr = parts[1], parts[2]
    elif op_basename in OUT_OPERATIONS:
        op_adr, grx_name = parts[1], parts[2]
    elif op_basename in ONE_REG_OPERATIONS:
        grx_name = parts[1]
    elif op_basename in NO_ARGS_OPERATIONS:
        pass
    elif op_basename in ONE_ADDR_OPERATIONS:
        op_adr = parts[1]

    # figure out number base (hex, decimal, binary)
    if op_adr != "-":
        op_adr = utils.evaluate_expr(op_adr)

        # parse the address-mode
        if op_address_mode == "":  # direct
            op_address_mode_code = "00"
            op_adr_bin = f"{int(op_adr):0{ADR_WIDTH}b}"
        elif op_address_mode == "I":  # immediate
            op_address_mode_code = "01"

            op_adr_bin = "-" * ADR_WIDTH  # dont care
            immediate_value = f"{int(op_adr):0{INSTRUCTION_WIDTH}b}"
        else:
            ERROR(f"Unknown address mode {op_address_mode}")
    else:
        op_address_mode_code = "--"
        op_adr_bin = "-" * ADR_WIDTH

    if grx_name != "-":
        # parse the register
        grx_num = re.search(r"GR([0-7])", grx_name)
        if not grx_num:
            ERROR(f"Unknown register {grx_name} in {line}")
        grx_bin = f"{int(grx_num.group(1)):03b}"
    else:
        grx_bin = "000"

    # create binary code
    binary_line = (
        f"{KNOWN_OPCODES[op_basename]}_{grx_bin}_{op_address_mode_code}_00_{op_adr_bin}"
    )
    binary_lines += [(binary_line, line.strip())]

    # possible immediate value
    if immediate_value:
        binary_lines += [(immediate_value, "")]

    return binary_lines


def read_lines(filename):
    """
    Return the lines from the given file
    """

    lines = open(filename, "r").readlines()

    if not lines:
        ERROR(f"Could not read {filename}")

    return lines


def remove_comments_and_empty_lines(lines):
    """
    Remove comments and empty lines from the given list of lines
    """
    COMMENT_INITIATORS = {"--", "//", "@"}
    return [
        line
        for line in lines
        if not re.match(rf"({'|'.join(COMMENT_INITIATORS)}).*", line) and line.strip()
    ]


def get_arg():
    """
    Get the filename argument
    """
    if len(sys.argv) != 2:
        print("Usage: python3 assemblyparser.py <filename>")
        sys.exit(1)

    arg = sys.argv[1]

    if arg == "--debug":
        return DEBUG_ARG  # hardcoded, can be changed for debugging

    return sys.argv[1]


def get_section(line) -> Section:
    """
    Return a section object from the given line
    """
    if not re.match(r"%.*", line):
        ERROR(f"Not a section directive: {line}")

    parts = (line.replace("%", "")).split()

    if len(parts) < 3:
        ERROR(f"Directive does not contain 3 parts: {line}")

    name, start, end = parts

    section = Section(name, int(start), int(end))

    return section


def assemble_data(line, section):
    """
    Return binary lines from the given data line
    """

    # parse the value
    value = utils.evaluate_expr(line)

    # convert to binary
    binary_line = f"{int(value):0{INSTRUCTION_WIDTH}b}"

    return (binary_line, value)


def use_sections(line, sections):
    """
    Replace all %<section name> in the line with their
    start linenum
    """
    for section_name, section in sections.items():
        line = line.replace(f"%{section.name}", str(section.start))

    return line


def use_macros(line, macros):
    """
    Replace all macros in the given line with their values
    """
    for macro in macros:
        line = line.replace(macro, macros[macro])

    return line


def main():

    # find the file containing assembly code
    asm_file_name = get_arg()
    asm_file_path = os.path.join(PROG_DIR, asm_file_name)

    # read the program memory file
    mem_lines = read_lines(PMEM_FILE)

    # read the assembly file
    asm_lines = read_lines(asm_file_path)

    # remove comments and empty lines
    asm_lines = remove_comments_and_empty_lines(asm_lines)

    current_section_name = ""
    current_label = ""
    sections = {}

    # find all sections beforehand
    for i, line in enumerate(asm_lines):
        if line.startswith("%"):
            section = get_section(line)
            sections[section.name] = section

    macros = {}

    # assemble the binary code
    for i, line in enumerate(asm_lines):
        if line.startswith("_"):  # macro definition
            macro_name, macro_value = line.replace(" ", "").strip().split("=")
            macros[macro_name] = macro_value
            continue
        elif line.startswith("%"):  # section directive
            current_section_name = line.split()[0].replace("%", "")
            continue # already handled

        if "_" in line:  # macro usage
            line = use_macros(line, macros)

        if "%" in line:
            line = use_sections(line, sections)
            
        if line.endswith(":\n"):  # label
            current_label = line.strip()[:-1]  # remove the colon
            continue

        if re.match(r"\s*[A-z]+.*", line):  # code
            new_line = assemble_binary_line(
                line=line.strip(),
                label=current_label,
            )
        else:  # data
            new_line = [assemble_data(
                line=line.strip(),
                section=sections[current_section_name]
                )]

        sections[current_section_name].lines += new_line

    # assume that HALT needs to be added
    HALT = ("11111_---_--_--_------------", "HALT")
    sections['PROGRAM'].lines.append(HALT)  # add HALT to program section

    array_lines = am.extract_vhdl_array(
        lines=mem_lines, array_start_pattern=r".*:.*p_mem_type.*:=.*"
    )

    cleared_array_lines = [array_lines[0]] + array_lines[-2:]

    for section_name, section in sections.items():
        cleared_array_lines.insert(-2, f"        -- {section_name}\n")
        for i, line in enumerate(section.lines):
            binary_line, comment = line
            if binary_line == "":
                continue
            if not re.match(r"\d+.*", binary_line):
                ERROR(f"Invalid binary line {binary_line}")

            new_array_line = f'        {section.name}+{i} => b"{binary_line}", -- {comment}\n'

            cleared_array_lines.insert(-2, new_array_line)

    mem_start, mem_end = am.find_array_start_end_index(
        lines=mem_lines, array_start_pattern=r".*:.*p_mem_type.*:=.*"
    )

    # clear the old program memory array
    mem_lines[mem_start : mem_end + 1] = cleared_array_lines

    # write the new program memory file
    open(PMEM_FILE, "w").writelines(mem_lines)


if __name__ == "__main__":
    main()
