import re


def apply_constants_in_expr(expr, constants):
    """
    Replace all constants in `expr` with their values.
    """

    for c in constants:
        expr = expr.replace(c, str(constants[c]))

    return expr


def parse_constants(lines):
    """
    Find all defined constants and return a dictionary of them.
    """

    constants = {}

    for line in lines:
        if re.match(r"\s*CONSTANT.*INTEGER\s*:=.*", line):
            line = apply_constants_in_expr(line, constants)
            groups = re.search(r"\s*CONSTANT\s+(\w+).*:=\s*(.*);\n", line)
            if not groups:
                raise ValueError(f"Invalid constant declaration: {line}")
            name, value = groups.groups()
            value = eval(value)

            constants[name] = int(value)

    return constants


def extract_vhdl_array(lines, array_start_pattern):
    """
    Use `regex_pattern` to find start of array declaration in within `lines`.
    Return all lines of the array.
    """

    # Find the start of the array declaration
    for i, line in enumerate(lines):
        if re.match(array_start_pattern, line):
            start = i
            break
    else:
        raise ValueError("Array declaration not found")

    # Find the end of the array declaration
    for i, line in enumerate(lines[start:]):
        if re.match(r"\s*\);", line):
            end = i
            break
    else:
        raise ValueError("Array termination cannot be found")

    return lines[start : start + end + 1]


def clear_vhdl_array(lines: list, element_pattern: str, remove_comments=False) -> list:
    """
    Given lines of a VHDL array, remove all elements from it.
    """

    text = "\n".join(lines)

    # Find all elements separated by commas
    elements = re.findall(element_pattern, text)

    # Remove all elements from the text
    for elem in elements:
        text = text.replace(elem, "")

    if remove_comments:
        # Remove lines with only comments
        text = re.sub(r"\s*--.*\n", "", text)

    # Split the text back into lines
    lines = [
        line for line in text.splitlines(keepends=True) if line.strip()
    ]  # ignore empty
    return lines


def find_array_start_end_index(lines, array_start_pattern):
    """
    Find index of start and end of array declaration in `lines`.
    """
    # find start
    for i, line in enumerate(lines):
        if re.match(array_start_pattern, line):
            start_index = i
            break

    # find end
    for j, line in enumerate(lines[start_index:]):
        if re.match(r"\s*\);", line):
            end_index = start_index + j
            break

    if start_index > end_index:
        raise ValueError("Array termination cannot be found")

    return start_index, end_index


def get_vhdl_array_elements(lines, element_pattern):
    """
    Given lines of a VHDL array, and a pattern to match every element with,
    return a list of its elements.

    Skip comments and empty lines.
    """

    # Clean up the lines
    clean_lines = []
    for line in lines:
        # Skip comments, empty lines and OTHERS
        if (
            re.match(r"\s*--.*", line)
            or re.match(r"\s*$", line)
            or re.match(r"\s*OTHERS.*", line)
        ):
            continue
        # Remove comments from the line
        line_without_comment = re.sub(r"\s*--.*$", "", line)
        clean_lines += [line_without_comment]

    text = "\n".join(clean_lines)

    elements = []

    # Find all elements separated by commas
    for elem in re.findall(element_pattern, text):
        elements += [elem.strip()]

    return elements
