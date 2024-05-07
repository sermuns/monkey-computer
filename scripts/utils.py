import os, re, sys


def change_dir_to_root():
    """
    Find the root directory of the project
    """
    while not os.path.exists("masm"):
        os.chdir(os.pardir)


def parse_value(value: str) -> int:
    """
    Parse a single number in binary, decimal or hexadecimal format
    to decimal integer.
    """

    if isinstance(value, int):
        return value # nothing to do

    # find the base of the number
    base = re.search(r"(0([bdx])|\$)", value)

    if base is None:
        base = "d"
    else:
        value = value[len(base.group(0)) :]  # slice away the base
        if base.group(1) == "$":
            base = "x"
        else:
            base = base.group(2)

    if base == "b":
        value = int(value, 2)
    elif base == "d":
        value = int(value, 10)
    elif base == "x":
        value = int(value, 16)

    return value


def evaluate_expr(expr: str) -> int:
    """
    Given string of arithmetic expression between numbers
    in binary, decimal or hexadecimal formats, return
    the integer value of the expression.
    """

    # remove whitespace and underscores
    expr = re.sub(r"\s+|_", "", expr)

    # find all numbers in the expression
    numbers = re.findall(r"[0-9a-fA-F]+", expr)

    for num in numbers:
        expr = expr.replace(num, str(parse_value(num)))

    return eval(expr)


def ERROR(msg: str):
    """
    Print error message and exit with code 1
    """
    print(f"Error: {msg}")
    sys.exit(1)


def get_opcodes():
    """
    Get the opcodes from the `fax.md` file
    """

    FAX_FILE = "hardware/fax.md"

    change_dir_to_root()

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