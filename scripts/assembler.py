"""
Parse the given argument file from monkey-assembly to binary code
"""

# standard imports
import re, sys, os
from pathlib import Path

# add parent dir to path, to be able to import modules
sys.path.append(str(Path(__file__).resolve().parents[1]))

# custom imports
from section import Section, use_sections
from utils import ERROR
import utils
import array_manip as am
from macros import use_macros
from instruction_decoding import parse_operation, parse_register_and_address

KNOWN_OPCODES = utils.get_mnemonics()

PROG_DIR = "masm"
HARDWARE_DIR = "hardware"
PMEM_FILE = os.path.join(HARDWARE_DIR, "pMem.vhd")
FAX_FILE = os.path.join(HARDWARE_DIR, "fax.md")

ADR_WIDTH = 12
DEBUG_ARG = "path.s"

INSTRUCTION_WIDTH = 24


def parse_address_mode(addr: str, mode: str):
    """
    Parse the address mode and address from the given address and mode

    Args:
        addr (str): The address to be parsed.
        mode (str): The mode to be parsed.

    Returns:
        tuple: A tuple containing the binary address mode,
        the binary address, and the immediate value.
    """

    # address is label?
    if re.match(r"[A-z]+", addr):
        mode_bin = "00"
        addr_bin = "?" * ADR_WIDTH  # value will be filled in later
        return mode_bin, addr_bin, ""

    mode_bin = "--" # assume don't care for mode
    addr_bin = "-" * ADR_WIDTH # assume don't care for address
    immediate_value = "" # assume no immediate value

    if addr == "-":
        return mode_bin, addr_bin, immediate_value

    addr = utils.evaluate_expr(addr)
    if mode == "":  # direct
        mode_bin = "00"
        addr_bin = f"{int(addr):0{ADR_WIDTH}b}"
    elif mode == "I":  # immediate
        mode_bin = "01"
        immediate_value = f"{int(addr):0{INSTRUCTION_WIDTH}b}"
    elif mode == "X":  # indirect
        mode_bin = "10"
        addr_bin = f"{int(addr):0{ADR_WIDTH}b}"
    elif mode == "N": # indexed
        mode_bin = "11"
        addr_bin = f"{int(addr):0{ADR_WIDTH}b}"
    else:
        ERROR(f"Unknown address mode {mode}")

    return mode_bin, addr_bin, immediate_value


def parse_register(grx_name):
    if grx_name == "-":
        return "-"*4

    grx_num = re.search(r"GR([0-15])", grx_name)
    if not grx_num:
        ERROR(f"Unknown register {grx_name}")
    grx_bin = f"{int(grx_num.group(1)):04b}"
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
    mnemonic, address_mode = parse_operation(instruction_parts)

    # Parse the register and address from the operation
    register, address = parse_register_and_address(mnemonic, instruction_parts)

    # Parse the address mode code, binary address, and immediate value from the address and address mode
    address_mode_code, binary_address, immediate_value = parse_address_mode(
        address, address_mode
    )

    # Parse the binary representation of the register
    binary_register = parse_register(register)
    
    # Check for special case for keyboard access.
    key = "0"
    if binary_register == "1111":
        key = "1"    

    # Assemble the binary line
    binary_instruction = f"{KNOWN_OPCODES[mnemonic]}_{binary_register}_{address_mode_code}_{key}_{binary_address}"

    # Add the binary line and its corresponding assembly instruction to the list of binary lines
    binary_lines += [(binary_instruction, instruction_line.strip(), label)]

    # If there's an immediate value, add it as a separate binary line
    if immediate_value:
        binary_lines += [(immediate_value, "", "")]

    return binary_lines


def read_lines(filename):
    """
    Return the lines from the given file
    """

    try:
        lines = open(filename, "r").readlines()
    except FileNotFoundError:
        ERROR(f"File {filename} not found")

    if not lines:
        ERROR(f"Empty file {filename}")

    return lines


def get_arg():
    """
    Get the filename argument
    """
    if len(sys.argv) != 2:
        this_script_name = os.path.basename(__file__)
        print(f"Usage: python3 {this_script_name} <masm file>.s")
        sys.exit(1)

    arg = sys.argv[1]

    if arg == "--debug":
        return DEBUG_ARG  # hardcoded, can be changed for debugging

    return sys.argv[1]


def assemble_data(line):
    """
    Return binary lines from the given data line
    """

    # parse the value
    decimal_data = utils.evaluate_expr(line)

    # convert to binary
    binary_data = f"{int(decimal_data):0{INSTRUCTION_WIDTH}b}"

    return (binary_data, decimal_data, "")


def main():

    # begin by changing dir to root of file
    utils.change_dir_to_root()

    # find the file containing assembly code
    asm_file_name = get_arg()
    asm_file_path = os.path.join(PROG_DIR, asm_file_name)

    # read the assembly file
    asm_lines = read_lines(asm_file_path)

    # remove comments and empty lines
    asm_lines = utils.get_lines_without_empty_and_comments(asm_lines)

    current_section_name = ""
    new_label = ""
    sections = {}

    # replace MOV with LD and ST
    for i, line in enumerate(asm_lines):
        if "MOV" not in line:
            continue

        # store source register value on %HEAP
        source_register = re.findall(r"GR\d+", line)
        st_line = f"ST %HEAP, {source_register[-1]}"
        
        # load source register value from %HEAP
        destination_register = re.findall(r"GR\d+", line)
        ld_line = f"LD {destination_register[0]}, %HEAP"

        # remove original line, add new lines
        asm_lines[i] = st_line
        asm_lines.insert(i+1, ld_line)


    # find all sections beforehand
    for i, line in enumerate(asm_lines):
        if line.startswith("%"):  # section
            this_section = Section(line)
            sections[this_section.name] = this_section

    macros = {}

    # assemble the binary code
    for i, line in enumerate(asm_lines):
        if line.startswith("_"):  # macro definition
            macro_name, macro_value = line.replace(" ", "").strip().split("=")
            macros[macro_name] = macro_value
            continue
        elif line.startswith("%"):  # section declaration
            current_section_name = line.split()[0].replace("%", "")
            continue  # already handled

        # macro usage
        line = use_macros(line, macros)

        # section usage
        line = use_sections(line, sections)

        if line.endswith(":\n"):  # label
            new_label = line.strip()[:-1]  # remove the colon
            continue

        if re.match(r"\s*[A-z]+.*", line):  # code
            new_line = assemble_binary_line(
                instruction_line=line.strip(), label=new_label
            )
            new_label = ""  # reset label
        else:  # data
            new_line = [assemble_data(line=line.strip())]

        sections[current_section_name].lines += new_line

    if sections["PROGRAM"].lines[-1][1] != "HALT":
        print("\033[95mWarning:\033[0m Last instruction in given program is not HALT. This is added automatically.")
        # assume that HALT needs to be added
        halt_opcode = KNOWN_OPCODES["HALT"]
        halt_binary = (f"{halt_opcode}_---_--_--_------------", "HALT", "")
        sections["PROGRAM"].lines.append(halt_binary)

    # read the program memory file
    mem_lines = read_lines(PMEM_FILE)

    array_lines = am.extract_vhdl_array(
        lines=mem_lines, array_start_pattern=r".*:.*p_mem_type.*:=.*"
    )

    cleared_array_lines = [array_lines[0]] + array_lines[-2:]

    # add the sections to the cleared array
    for section_name, this_section in sections.items():
        cleared_array_lines.insert(-2, f"        -- {section_name}\n")
        for i, line in enumerate(this_section.lines):
            binary_line, full_comment, label = line
            if binary_line == "":
                continue
            if not re.match(r"\d+.*", binary_line):
                ERROR(f"Invalid binary line {binary_line}")

            label_string = f"{label} : " if label else ""
            new_array_line = f'        {this_section.name}+{i} => b"{binary_line}", -- {label_string}{full_comment}\n'

            cleared_array_lines.insert(-2, new_array_line)

    # find all label start addresses
    labels = {}  # dictionary of label -> start address
    for i, line in enumerate(cleared_array_lines):
        if not re.match(r".*=>.*\n", line):
            continue  # not an element
        if not "PROGRAM" in line:
            break  # end of program memory

        element_index = int(re.search(r"PROGRAM\+(\d+)", line).group(1))

        label_match = re.search(r'.*--\s*(\w+)\s*:.*', line)

        if not label_match:
            continue # no label

        label = label_match.group(1)

        labels[label] = element_index  # save the start address of the label

    # fix unknown addresses in the binary code
    for i, line in enumerate(cleared_array_lines):
        if '?'*12 not in line:
            continue  # not an unknown address

        full_comment = re.search(r".*--\s*(.+)\n", line)

        if not full_comment:
            utils.ERROR(
                f"Cant resolve symbolic address in line {i + 1} in {PMEM_FILE}, no comment found"
            )

        full_comment_parts = full_comment.group(1).split(":")

        comment = full_comment_parts[-1].strip()

        # get label from the BRANCH instruction
        seeked_label = comment.split()[1].strip()

        if seeked_label not in labels:
            ERROR(f"Label {seeked_label} not found in labels")

        # replace the unknown address with the found address
        jump_address = labels[seeked_label]

        if jump_address > 2 ** ADR_WIDTH:
            ERROR(f"Jump address {jump_address} is too large")
        elif jump_address < 0:
            ERROR(f"Jump address {jump_address} is negative")

        cleared_array_lines[i] = re.sub(r"\?+", f"{jump_address:0{ADR_WIDTH}b}", line)

    mem_start, mem_end = am.find_array_start_end_index(
        lines=mem_lines, array_start_pattern=r".*:.*p_mem_type.*:=.*"
    )

    # clear the old program memory array
    mem_lines[mem_start : mem_end + 1] = cleared_array_lines

    # write the new program memory file
    open(PMEM_FILE, "w").writelines(mem_lines)


if __name__ == "__main__":
    main()
