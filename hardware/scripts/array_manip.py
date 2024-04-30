import re

def extract_vhdl_array(lines, regex_pattern):
    """
    Use `regex_pattern` to find start of array declaration in within `lines`.
    Return all lines of the array.
    """

    # Find the start of the array declaration
    for i, line in enumerate(lines):
        if re.match(regex_pattern, line):
            start = i
            break
    else:
        raise ValueError("Array declaration not found")

    # Find the end of the array declaration
    for i, line in enumerate(lines[start:]):
        if re.match(r'\s*\);', line):
            end = i
            break
    else:
        raise ValueError("Array declaration not terminated")

    return lines[start:start+end+1]


def get_vhdl_array_elements(lines):
    """
    Given lines of a VHDL array, return a list of its elements.
    Skip comments and empty lines.
    """

    elements = []
    
    for line in lines:
        # Skip comments and empty lines
        if re.match(r'\s*--', line) or re.match(r'\s*$', line) or re.match(r'\s*OTHERS.*', line):
            continue

        # Extract elements
        elements += [line]

    return elements[1:-1] # Trim array declaration and termination



