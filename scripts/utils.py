import os, re, sys


def chdir_to_root():
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
