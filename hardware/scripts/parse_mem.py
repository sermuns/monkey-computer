#!/usr/bin/env python3

import sys, re

def prepend_index(file):
    """
    Add index to beginning of each comment inside array in VHDL
    """
    
    # Load file as array of lines
    lines = file.readlines()

    # Find beginning of array
    array_start_index = 0
    for i, line in enumerate(lines):
        if re.match(r"\s*CONSTANT.*mem.*:=.*\(", line):
            array_start_index = i
            break
    
    # Find array elements
    element_index = 0
    for i in range(array_start_index, len(lines)):
        if not re.match(r'\s*b".*".*--.*', lines[i]):
            continue # not an array element WITH comment

        lines[i] = prepend_index_in_comment(lines[i], element_index)
        element_index += 1

    return lines

def prepend_index_in_comment(line, index):
    """
    Return line with index prepended to comment.
    If no comment => dont do anything
    """
    
    DECIMAL_WIDTH = 2
    BINARY_WIDTH = 8

    if not re.match(r'\s*b".*".*--.*', line):
        return

    # Split line into comment and code
    groups = re.match(r'(\s*b".*",?)(\s*--.*)', line)
    if not groups:
        raise Exception(f"Error: Could not split line into code and comment: {line}")
    code = groups.group(1)
    comment = groups.group(2)

    # Remove previous index if exists
    comment = re.sub(r'--\[.+\|.+\]\s*', '', comment) 

    # Pad index with whitespaces
    padded_index = str(index).rjust(2)
    binary_index = format(index, f'0{BINARY_WIDTH}b')

    # Insert index
    new_comment = f"--[{padded_index}|{binary_index}] {comment}\n"

    return f"{code}{new_comment}"


def main():
    if not sys.argv[1:]:
        print('Usage: {} <filename>'.format(sys.argv[0]))
        return
    elif sys.argv[1] == '--debug':
        sys.argv[1] = 'uMem.vhd'

    filename = sys.argv[1]

    print(filename)

    with open(filename, 'r') as file:
        new_file_lines = prepend_index(file)

    with open(filename, 'w') as file:
        file.writelines(new_file_lines)


if __name__ == '__main__':
    main()