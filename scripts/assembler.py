#!/usr/bin/env python3
"""
Parse the given argument file from monkey-assembly to binary code
"""

import re, sys

PMEM_FILE = "hardware/pMem.vhd"
FAX_FILE = "hardware/fax.md"
ADR_WIDTH = 12

DEBUG_ARG = "busywait.s"

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
        if not line: # skip empty lines
            continue
        if not re.match(r"\d+", line): # stop if not numerical
            break
        parts = line.split()
        if len(parts) != 2:
            print(f"Error: Could not parse opcode line {i + 1} in {FAX_FILE}")
            sys.exit(1)
        opcode, name = parts
        opcodes[name] = opcode

    return opcodes

def assemble_binary_line(line, known_opcodes):
    """
    Return binary line from the given assembly line
    If the instruction is an immediate instruction, the immediate value is 
    also returned as a separate line.
    """ 

    binary_lines = []

    # split into parts by comma and whitespace
    parts = re.split(r",\s*|\s+", line)
    op_fullname = parts[0]

    op_basename = None
    op_address_mode = None
    # get base opname
    for known_op_name in known_opcodes:
        if op_fullname.startswith(known_op_name):
            op_basename = known_op_name
            op_address_mode = op_fullname[len(op_basename):]
            break

    # unknown op?
    if not op_basename:
        raise ValueError(f"Error: Unknown op: {op_fullname} in {line}")
    
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
        base = re.search(r'(0([bdx])|\$)', op_adr)

        if base is None:
            base = 'd' 
        else:
            op_adr = op_adr[len(base.group(0)):] # slice away the base
            if base.group(1) == '$':
                base = 'x'
            else:
                base = base.group(2)

        if base == 'b':
            op_adr = int(op_adr, 2)
        elif base == 'd':
            op_adr = int(op_adr, 10)
        elif base == 'x':
            op_adr = int(op_adr, 16)

        # parse the address-mode
        if op_address_mode == "":       # direct
            op_address_mode_code = "00"
            op_adr_bin = f'{int(op_adr):0{ADR_WIDTH}b}'
        elif op_address_mode == "I":    # immediate
            op_address_mode_code = "01"
            
            op_adr_bin = '-' * ADR_WIDTH # dont care
            immediate_value = f'{int(op_adr):0{INSTRUCTION_WIDTH}b}'
        else:
            print(f"Error: Unknown address mode {op_address_mode}")
            sys.exit(1)
    else:
        op_address_mode_code = "--"
        op_adr_bin = "-" * ADR_WIDTH

    if grx_name != "-":
        # parse the register
        grx_num = re.search(r'GR([0-7])', grx_name)
        if not grx_num:
            print(f"Error: Unknown register {grx_name} in {line}")
            sys.exit(1)
        grx_bin = f'{int(grx_num.group(1)):03b}'
    else:
        grx_bin = "000"

    # create binary code
    binary_line = f'{known_opcodes[op_basename]}_{grx_bin}_{op_address_mode_code}_00_{op_adr_bin}'
    binary_lines += [(binary_line, line.strip())]

    # possible immediate value
    if immediate_value:
        binary_lines += [(immediate_value, "")]
    
    return binary_lines


def read_lines(filename):
    """
    Return the lines from the given file
    """

    lines = []
    with open(filename, "r") as f:
        lines = f.readlines()

    if not lines:
        print(f"Error: Could not read {filename}")
        sys.exit(1)

    return lines


def remove_comments_and_empty_lines(lines):
    """
    Remove comments and empty lines from the given list of lines
    """
    return [line for line in lines if not re.match(r"(--|//|@).*", line) and line.strip()]


def get_arg():
    """
    Get the filename argument
    """
    if len(sys.argv) != 2:
        print("Usage: python3 assemblyparser.py <filename>")
        sys.exit(1)

    arg = sys.argv[1]

    if arg == "--debug":
        return DEBUG_ARG # hardcoded, can be changed for debugging

    return sys.argv[1]


def main():
    asm_file_name = get_arg()
    asm_file_path = f"src/masm/{asm_file_name}"

    # read the program memory file
    mem_lines = read_lines(PMEM_FILE)

    KNOWN_OPCODES = get_opcodes()
    binary_lines = []

    # read the assembly file
    asm_lines = read_lines(asm_file_path)

    # remove comments and empty lines
    asm_lines = remove_comments_and_empty_lines(asm_lines)

    # assemble the binary code
    for i, line in enumerate(asm_lines):
        try:
            binary_lines += assemble_binary_line(line, KNOWN_OPCODES)
        except ValueError as e:
            print(f"Unable to parse line {i} in {asm_file_path}:\n{e}")
            sys.exit(1)
    
    # assume that HALT needs to be added
    binary_lines += [("11111_---_--_--_------------", "HALT")]

    # find start and end of the program memory part of array
    mem_start_linenum = None
    program_end_linenum = None 
    for i, line in enumerate(mem_lines):
        if mem_start_linenum is None and re.match(r"\s*CONSTANT p_mem_init.*", line):
            while re.match(r"\s*--.*", mem_lines[i+1]):
                i += 1 # skip comments
            mem_start_linenum = i+1 # found the start
        elif re.match(r"\s*VMEM_START.*=>.*\,.*", line):
            program_end_linenum = i-2
            break # found the end
    
    # no program memory array found?
    if mem_start_linenum is None:
        print(f"Error: Could not find program memory array in {PMEM_FILE}")
        sys.exit(1)

    # remove old content
    for i, line in enumerate(mem_lines[mem_start_linenum:], start=mem_start_linenum):
        if i == program_end_linenum:
            break # end of program memory part
        elif not re.match(r'.*b".*",.*', line): 
            continue # not an array element
        
        # mark for removal
        mem_lines[i] = ""

    # remove garbage
    mem_lines = [line for line in mem_lines if line != ""]

    # insert the new content
    array_index = len(binary_lines) - 1
    for binary_line in reversed(binary_lines):
        new_line = f'        {array_index} => b"{binary_line[0]}",'

        # add original assembly line as a comment, none if immediate value
        if binary_line[1] != "": 
            new_line += f' -- {binary_line[1]}'
        new_line += '\n'

        mem_lines.insert(mem_start_linenum, new_line)
        array_index -= 1

    # write the new program memory file
    with open(PMEM_FILE, "w") as f:
        f.writelines(mem_lines)


if __name__ == "__main__":
    main()