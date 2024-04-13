#!/usr/bin/env python3
"""
Parse the given argument file from monkey-assembly to binary code
"""

import re, sys

PMEM_FILE = "src/pMem.vhd"
FAX_FILE = "fax.md"
ADR_WIDTH = 12

IN_OPERATIONS = {"LD", "ADD", "SUB", "AND", "OR", "IN", "MUL"}
OUT_OPERATIONS = {"ST", "OUT"}
REG_OPERATIONS = {"MOV", "ADDREG"}

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

def assemble_binary(line, known_opcodes):
    """
    Return binary line(s) from the given assembly line
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
    

    # get register and address
    op_adr = 0
    immediate_value = None
    if op_basename in IN_OPERATIONS:
        grx_name, op_adr = parts[1], parts[2]
    elif op_basename in OUT_OPERATIONS:
        op_adr, grx_name = parts[1], parts[2]
        
    # figure out number base (hex, decimal, binary)
    base = re.search(r'(0([bdx])|\$)', op_adr)
    if base:
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
    else:
        op_adr = int(op_adr)

    # parse the address-mode
    op_address_mode_code = None
    if op_address_mode == "":       # direct
        op_address_mode_code = "00"
        op_adr_bin = f'{int(op_adr):0{ADR_WIDTH}b}'
    elif op_address_mode == "I":    # immediate
        op_address_mode_code = "01"
        
        op_adr_bin = '-' * ADR_WIDTH # dont care
        immediate_value = f'{int(op_adr):024b}'
    else:
        print(f"Error: Unknown address mode {op_address_mode}")
        sys.exit(1)

    # parse the register
    grx_num = re.search(r'GR([0-7])', grx_name)
    if not grx_num:
        print(f"Error: Unknown register {grx_name} in {line}")
        sys.exit(1)
    grx_bin = f'{int(grx_num.group(1)):03b}'

    # create binary code
    binary_lines += [f'{known_opcodes[op_basename]}_{grx_bin}_{op_address_mode_code}_00_{op_adr_bin}']

    # possible immediate value
    if immediate_value:
        binary_lines += [immediate_value]
    
    return binary_lines


def main():
    # check for filename argument    
    if len(sys.argv) != 2:
        print("Usage: python3 assemblyparser.py <filename>")
        sys.exit(1)
    filename = sys.argv[1]

    # read the program memory file
    pmem_lines = []
    with open(PMEM_FILE, "r") as f:
        pmem_lines = f.readlines()
    if not pmem_lines:
        print(f"Error: Could not read {PMEM_FILE}")
        sys.exit(1)

    KNOWN_OPCODES = get_opcodes()
    binary_lines = []

    # read the lines
    with open(filename, "r") as f:
        asm_lines = f.readlines()
    # remove comments
    asm_lines = [re.sub(r"(--|//|@).*", "", line).strip() for line in asm_lines]

    # remove empty lines
    asm_lines = [line for line in asm_lines if line]

    # assemble the binary code
    for i, line in enumerate(asm_lines):
        try:
            binary_lines += assemble_binary(line, KNOWN_OPCODES)
        except ValueError as e:
            print(f"Unable to parse line {i} in {filename}:\n{e}")
            sys.exit(1)

    
    # assume that HALT needs to be added
    binary_lines += ["11111_000_00_00_000000000000"]

    # find start of program memory array
    array_start_linenum = None
    for i, line in enumerate(pmem_lines):
        if re.match(r"\s*CONSTANT p_mem_init.*", line):
            array_start_linenum = i +1
            break
    
    # no program memory array found?
    if array_start_linenum is None:
        print(f"Error: Could not find program memory array in {PMEM_FILE}")
        sys.exit(1)

    # remove old content
    for i, line in enumerate(pmem_lines[array_start_linenum:], start=array_start_linenum):
        if not re.match(r'\s*b".*".*', line): 
            continue # not an array element
        if re.match(r'\s*\);\s*', line):
            break # end of array

        pmem_lines[i] = "garbage"

    # remove garbage
    pmem_lines = [line for line in pmem_lines if line != "garbage"]

    # insert the new content
    for binary_line in reversed(binary_lines):
        pmem_lines.insert(array_start_linenum, f'        b"{binary_line}",\n')


    # write the new program memory file
    with open(PMEM_FILE, "w") as f:
        f.writelines(pmem_lines)


if __name__ == "__main__":
    main()