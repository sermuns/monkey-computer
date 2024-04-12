#!/usr/bin/env python3
"""
Preprocess VHDL files by resolving macro-symbols in SOURCE_FILES from comments in MEM_FILES
"""

import re

SOURCE_DIR = "src"
SOURCE_FILES = ["cpu.vhd", "uMem.vhd"]
MEM_FILES = ["uMem.vhd"]

def extract_macro_symbols(mem_lines):
    """
    Extract macro-symbols from comments in MEM_FILES
    Return dictionary of macro-symbols and their array index
    """

    symbols = {}
    array_index = -1

    for i, line in enumerate(mem_lines):
        if not re.match(r'^.*".*".*', line):
            continue # not an array element
        array_index += 1

        if not "--" in line:
            continue # no comment => no symbols

        comment = line[line.index("--") + 2:]

        # find {symbols} in comment
        matches_in_comment = re.findall(r"\{(.*?)\}", comment)

        for macro in matches_in_comment:
            # if macro is already defined -> error
            if macro in symbols:
                print(f"Error: Macro '{macro}' already defined in line {i}")
                exit(1)

            # add macro to symbols
            symbols[macro] = array_index

    return symbols

def get_appropiate_num(base, width, number):
    """
    Given a number, return it in the desired base and width
    If width is not specified, use minimum width
    """
    if base == "b":
        return f'b"{int(number):0{width}b}"'
    elif base == "d":
        return f'd"{int(number):0{width}d}"'
    elif base == "x":
        return f'x"{int(number):0{width}x}"'
    else:
        print(f"Error: Invalid base {base}")
        exit(1)

def use_macro_symbols(file_path, symbols):
    """
    Given a file path and dictionary of macro-symbols,
    find occurences of macro-symbols (key of SYMBOLS) in file and prepend them with 
    their corresponding array index (value of SYMBOLS)
    """
    macros_used = 0
    lines = []

    with open(file_path, "r") as file:
        lines = file.readlines()
    
    for i, line in enumerate(lines):
        for macro, index in symbols.items():
            if not f"/*{macro}" in line:
                continue # macro not in line

            # find desired digit width and number base 
            # e.g. /*{macro}.8b*/ => 8b
            options = re.search(rf'.*\/\*{macro}\.([bdx])(\d*)\*\/', line)
            if not options:
                print(f"Error: No options found for {macro} in line {i} of {file_path}")
                exit(1)
            
            base = options.group(1)
            width = options.group(2)

            appropiate_num = get_appropiate_num(base, width, index)

            # put index to the left of macro. e.g. /*{macro}*/ => {index}/*{macro}*/
            # should also remove any existing content to the left of the macro not separated by whitespace
            replaced_line = re.sub(rf'\S*\/\*{macro}', f'{appropiate_num}/*{macro}', line)
            lines[i] = replaced_line
            macros_used += 1
    
    with open(file_path, "w") as file:
        file.writelines(lines)
    
    print(f"Used {macros_used} macro-symbols in {file_path}")

def main():
    symbols = {}

    # Extract macro-symbols from MEM_FILES
    mem_paths = [f"{SOURCE_DIR}/{file}" for file in MEM_FILES]
    for mem_path in mem_paths:
        with open(mem_path, "r") as mem_file:
            mem_lines = mem_file.readlines()
            symbols = extract_macro_symbols(mem_lines)

    # Use macro-symbols in SOURCE_FILES
    file_paths = [f"{SOURCE_DIR}/{file}" for file in SOURCE_FILES]
    for file_path in file_paths:
        use_macro_symbols(file_path, symbols)
    
if __name__ == "__main__":
    main()