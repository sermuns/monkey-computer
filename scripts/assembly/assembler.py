"""
Parse the given argument file from monkey-assembly to binary code
"""

# standard imports
import re, sys, os
from pathlib import Path

# Get the absolute path of the parent directory
parent_dir = Path(__file__).resolve().parent.parent

# Add the parent directory to sys.path if not already included
if str(parent_dir) not in sys.path:
    sys.path.append(str(parent_dir))


# custom imports
from section import Section
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
DEBUG_ARG = "loop.s"
INSTRUCTION_WIDTH = 24

# OP GRx, ADR
IN_OPERATIONS = {"LD", "ADD", "SUB", "AND", "OR", "IN", "MUL", "LSR", "LSL"}
# OP ADR, GRx
OUT_OPERATIONS = {"ST", "OUT"}
# OP GRx, GRx
TWO_REG_OPERATIONS = {"MOV", "ADDREG"}
# OP GRx
ONE_REG_OPERATIONS = {"POP", "PUSH", "JSR"}
# OP ADR
ONE_ADDR_OPERATIONS = {"BRA", "JSR"}
# OP
NO_ARGS_OPERATIONS = {"RET"}


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


def parse_operation(parts):
    op_fullname = parts[0]
    op_basename = None
    op_address_mode = None
    for known_op_name in KNOWN_OPCODES:
        if op_fullname.startswith(known_op_name):
            op_basename = known_op_name
            op_address_mode = op_fullname[len(op_basename) :]
            break
    if not op_basename:
        ERROR(f"Unknown operation {op_fullname} in `{line}`")
    return op_basename, op_address_mode


def parse_register_and_address(op_basename, parts):
    op_adr = "-"
    grx_name = "-"
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
    return grx_name, op_adr


def parse_address_mode(addr, mode):
    """
    Parse the address mode and address from the given address and mode
    
    Args:
        addr (str): The address to be parsed.
        mode (str): The mode to be parsed.
    
    Returns:
        tuple: A tuple containing the binary address mode,
        the binary address, and the immediate value.
    """

    if re.match(r"[A-z]+", addr):
        mode_bin = "00"
        addr_bin = "?" * ADR_WIDTH  # value will be filled in later
        return mode_bin, addr_bin, ""

    mode_bin = "--"
    addr_bin = "-" * ADR_WIDTH
    immediate_value = ""

    if addr == "-":
        return mode_bin, addr_bin, immediate_value

    addr = utils.evaluate_expr(addr)
    if mode == "":  # direct
        mode_bin = "00"
        addr_bin = f"{int(addr):0{ADR_WIDTH}b}"
    elif mode == "I":  # immediate
        mode_bin = "01"
        addr_bin = "-" * ADR_WIDTH  # dont care
        immediate_value = f"{int(addr):0{INSTRUCTION_WIDTH}b}"

    return mode_bin, addr_bin, immediate_value


def parse_register(grx_name):
    if grx_name == "-":
        return "---"

    grx_num = re.search(r"GR([0-7])", grx_name)
    if not grx_num:
        ERROR(f"Unknown register {grx_name} in {line}")
    grx_bin = f"{int(grx_num.group(1)):03b}"
    return grx_bin


def assemble_binary_line(instruction_line: str, label: str) -> list:
    """
    Assemble a binary line from the given instruction line and label.

    Args:
        instruction_line (str): The instruction line to be assembled.
        label (str): The label associated with the instruction line.

    Returns:
        list: A list of tuples, each containing a binary line and its corresponding assembly instruction.
    """

    # Initialize the list to hold the binary lines
    binary_lines = []

    # Split the instruction line into parts
    instruction_parts = re.split(r",\s*|\s+", instruction_line)

    # Parse the operation and its address mode from the instruction parts
    operation, address_mode = parse_operation(instruction_parts)

    # Parse the register and address from the operation
    register, address = parse_register_and_address(operation, instruction_parts)

    # Parse the address mode code, binary address, and immediate value from the address and address mode
    address_mode_code, binary_address, immediate_value = parse_address_mode(
        address, address_mode
    )

    # Parse the binary representation of the register
    binary_register = parse_register(register)

    # Assemble the binary line
    binary_instruction = f"{KNOWN_OPCODES[operation]}_{binary_register}_{address_mode_code}_00_{binary_address}"

    # Add the binary line and its corresponding assembly instruction to the list of binary lines
    binary_lines += [(binary_instruction, instruction_line.strip(), label)]

    # If there's an immediate value, add it as a separate binary line
    if immediate_value:
        binary_lines += [(immediate_value, '', '')]

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


def assemble_data(line):
    """
    Return binary lines from the given data line
    """

    # parse the value
    decimal_data = utils.evaluate_expr(line)

    # convert to binary
    binary_data = f"{int(decimal_data):0{INSTRUCTION_WIDTH}b}"

    return (binary_data, decimal_data, "")


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
        if line.startswith("%"):  # section
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
            continue  # already handled

        if "_" in line:  # macro usage
            line = use_macros(line, macros)

        if "%" in line:
            line = use_sections(line, sections)

        if line.endswith(":\n"):  # label
            current_label = line.strip()[:-1]  # remove the colon
            continue

        if re.match(r"\s*[A-z]+.*", line):  # code
            new_line = assemble_binary_line(
                instruction_line=line.strip(),
                label=current_label
                )
        else:  # data
            new_line = [
                assemble_data(line=line.strip())
            ]

        sections[current_section_name].lines += new_line

    # assume that HALT needs to be added
    HALT = ("11111_---_--_--_------------", "HALT", "")
    sections["PROGRAM"].lines.append(HALT)  # add HALT to program section

    array_lines = am.extract_vhdl_array(
        lines=mem_lines, array_start_pattern=r".*:.*p_mem_type.*:=.*"
    )

    cleared_array_lines = [array_lines[0]] + array_lines[-2:]

    # add the sections to the cleared array
    for section_name, section in sections.items():
        cleared_array_lines.insert(-2, f"        -- {section_name}\n")
        for i, line in enumerate(section.lines):
            binary_line, comment, label = line
            if binary_line == "":
                continue
            if not re.match(r"\d+.*", binary_line):
                ERROR(f"Invalid binary line {binary_line}")

            new_array_line = f'        {section.name}+{i} => b"{binary_line}", -- {comment} : {label}\n'

            cleared_array_lines.insert(-2, new_array_line)

    # find all label start addresses
    labels = {}  # dictionary of label -> start address
    for i, line in enumerate(cleared_array_lines):
        if not re.match(r".*=>.*--.*", line):
            continue  # not an element
        if not "PROGRAM" in line:
            break # end of program memory

        element_index = int(re.search(r"PROGRAM\+(\d+)", line).group(1))

        matches = re.search(r".*--.*: (\w+).*", line)
        if matches:
            label = matches.group(1)
            if label in labels:
                continue  # skip if already found

            labels[label] = element_index  # save the start address of the label

    # fix unknown addresses in the binary code
    for i, line in enumerate(cleared_array_lines):
        matches = re.match(r".*(\?+).*", line)
        if matches:  # found an unknown address
            # find comment : label
            comment_label = re.search(r".*--\s*(.*)\n", line)
            if not comment_label:
                continue

            comment, label = comment_label.group(1).split(" : ")

            # find the sought address
            seeked_label = comment.split(" ")[
                1
            ]  # should be second word in branch operations

            if seeked_label not in labels:
                ERROR(f"Label {seeked_label} not found in labels")

            # replace the unknown address with the found address
            cleared_array_lines[i] = re.sub(
                r"\?+", f"{labels[seeked_label]:012b}", line
            )

    mem_start, mem_end = am.find_array_start_end_index(
        lines=mem_lines, array_start_pattern=r".*:.*p_mem_type.*:=.*"
    )

    # clear the old program memory array
    mem_lines[mem_start : mem_end + 1] = cleared_array_lines

    # write the new program memory file
    open(PMEM_FILE, "w").writelines(mem_lines)


if __name__ == "__main__":
    main()
