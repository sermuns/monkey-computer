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
        if re.match(r'.*".\s*--.*', lines[i]):
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

    if "--" not in line:
        return

    # Split line into comment and code
    comment_column = line.index("--") + 2
    code = line[:comment_column]
    comment = line[comment_column:]

    # Remove previous index if exists
    comment = re.sub(rf"^\[.*\|.*\]\s*", "", comment)

    # Pad index with whitespaces
    padded_index = str(index).rjust(2)
    binary_index = format(index, f'0{BINARY_WIDTH}b')

    # Insert index
    new_comment = f"[{padded_index}|{binary_index}] {comment}"

    return code + new_comment


def main():
    if not sys.argv[1:]:
        print('Usage: {} <filename>'.format(sys.argv[0]))
        return

    filename = sys.argv[1]

    with open(filename, 'r+') as file:
        new_file_lines = prepend_index(file)
        file.seek(0)  # move file pointer to the beginning
        file.writelines(new_file_lines)
        file.truncate()  # remove any remaining original content


if __name__ == '__main__':
    main()