import sys, re, os
from utils import change_dir_to_root, ERROR

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
        if not re.match(r'\s*b.*[,\s]*', lines[i]):
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

    # Split line into comment and code
    match = re.match(r'(\s*b".*",?)\s*--(.*)', line)
    if not match:
        ERROR(f"Error: Could not split line into code and comment: {line}")
    code = match.group(1)
    comment = match.group(2)
    
    if "MOV" in comment:
        pass

    # Remove previous index if exists
    comment = re.sub(r'\[.{2}\|.{8}\]', '', comment).strip()

    # Pad index with whitespaces
    padded_index = str(index).rjust(2)
    binary_index = format(index, f'0{BINARY_WIDTH}b')

    # Insert index
    new_comment = f"[{padded_index}|{binary_index}] {comment}\n"

    return f"{code}--{new_comment}"


def main():
    change_dir_to_root()
    umem_file = os.path.join('hardware','uMem.vhd')

    with open(umem_file, 'r') as file:
        new_file_lines = prepend_index(file)

    with open(umem_file, 'w') as file:
        file.writelines(new_file_lines)


if __name__ == '__main__':
    main()