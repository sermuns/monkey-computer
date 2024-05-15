import os, re, sys

COMMENT_INITIATORS = {"--", "//", "@"}


def change_dir_to_root():
    """
    Find the root directory of the project
    """
    while not os.path.exists("masm"):
        os.chdir(os.pardir)


def parse_number_string(input_number_string: str) -> int:
    """
    Parse a single number in binary, decimal or hexadecimal format
    to decimal integer.
    """

    # If the input is already an integer, return it as is
    if isinstance(input_number_string, int):
        return input_number_string

    # Find the base of the number and the number itself
    match = re.match(r"(0([bdx])|\$)?([0-9A-Fa-f]+)", input_number_string)

    if not match:
        ERROR(f"Could not parse number string {input_number_string}")

    number_base = match.group(2) or "d"  # default to decimal
    number = match.group(3)

    # Convert the number to an integer based on its base
    if number_base == "b":
        return int(number, 2)
    elif number_base == "d":
        return int(number, 10)
    elif number_base == "x":
        return int(number, 16)


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
        expr = expr.replace(num, str(parse_number_string(num)))

    return eval(expr)


def ERROR(msg: str):
    """
    Print error message and exit with code 1
    """
    raise Exception(msg)


def get_mnemonics():
    """
    Get all the mnemonics from the hardware/fax.md file
    """

    FAX_FILE = "hardware/fax.md"

    change_dir_to_root()

    with open(FAX_FILE, "r") as f:
        lines = f.readlines()
    if not lines:
        print(f"Error: Could not find/read {FAX_FILE}")
        sys.exit(1)
    mnemonics = {}
    # find the opcodes header
    mnemonics_start_line = None
    for i, line in enumerate(lines):
        if line.startswith("## OP-koder"):
            mnemonics_start_line = i
            break

    # no opcodes header found?
    if mnemonics_start_line is None:
        print(f"Error: Could not find opcodes header in {FAX_FILE}")
        sys.exit(1)

    # loop through opcodes
    for i in range(mnemonics_start_line + 1, len(lines)):
        line = lines[i]
        if not line:  # skip empty lines
            continue
        if not re.match(r"\d+", line):  # stop if not numerical, because we are done
            break

        parts = line.split()
        if len(parts) != 2:
            print(f"Error: Could not parse opcode line {i + 1} in {FAX_FILE}")
            sys.exit(1)
        opcode_binary, mnemonic = parts
        mnemonics[mnemonic] = opcode_binary

    return mnemonics


def get_clean_lines(lines):
    """
    Return the lines which have no comments and are not empty
    """
    return [
        line
        for line in lines
        if not re.match(rf"({'|'.join(COMMENT_INITIATORS)}).*", line) and line.strip()
    ]


def get_lines_without_empty_and_comments(lines):
    """
    Return lines that are not empty or only contain comments
    This allows code that has comments at the end of the line
    """

    result = []
    for line in lines:
        # only comment -> skip
        if re.match(rf"^\s*({'|'.join(COMMENT_INITIATORS)}).*", line):
            continue
        # empty line -> skip
        if not line.strip():
            continue
        result.append(line)
    return result
