import os, re, sys, time

COMMENT_INITIATORS = {"--", "//", "@"}


class COLORS:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def busywait(duration, get_now=time.perf_counter):
    """
    Busy wait for the given duration
    """

    now = get_now()
    end = now + duration
    while now < end:
        now = get_now()


def change_dir_to_root():
    """
    Find the root directory of the project
    """

    while not os.path.exists("masm"):
        os.chdir(os.pardir)


def resolve_includes(asm_lines: list, masm_dir: str):
    """
    Resolve all includes in the given assembly lines
    """

    for i, line in enumerate(asm_lines):
        if "<" not in line:
            continue

        include_file_name = re.search(r"<(.+)>", line).group(1)
        include_file_path = os.path.join(masm_dir, include_file_name)

        include_lines = open(include_file_path, "r").readlines()

        # replace the include line with the lines from the included file
        asm_lines[i : i + 1] = include_lines


def get_decimal_int(input_number_string: str) -> int:
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

    # # remove whitespace and underscores
    # expr = re.sub(r"\s+|_", "", expr)

    # # find all numbers in the expression
    # numbers = re.findall(r"[0-9a-fA-F]+", expr)

    # # replace the numbers with their decimal values
    # for num in numbers:
    #     expr = expr.replace(num, str(get_decimal_int(num)))

    # return the decimal value of the expression
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


def resolve_mov_on_stack(asm_lines):
    """
    Replace MOV instructions with PUSH and POP instructions
    """

    for i, line in enumerate(asm_lines):
        if "MOV" not in line:
            continue

        registers = re.findall(r"GR\d+", line)

        push_line = f"PUSH {registers[1]}"
        pop_line = f"POP {registers[0]}"

        # remove original line, add new lines
        asm_lines[i : i + 1] = [push_line, pop_line]


def get_without_empty_or_only_comment_lines(lines):
    """
    Remove empty lines and lines that are only comments
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


if __name__ == "__main__":
    print(get_decimal_int("123"))
    print(get_decimal_int("0b1010"))
    print(get_decimal_int("0x1A"))
