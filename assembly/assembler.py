import re

DEFAULT_INPUT_FILE = "main.masm"
DEFAULT_OUTPUT_FILE = "out.bin"

OPERATIONS = [
    "LD",
    "ST",
    "ADD",
    "SUB",
    "CMP",
    "AND",
    "OR",
    "BEQ",
    "BNE",
    "BRA",
    "JSR",
    "RET",
    "PUSH",
    "POP",
    "HALT"
]

REGISTERS = [
    "GR0",
    "GR1",
    "GR2",
    "GR3",
    "GR4",
    "GR5",
    "GR6",
    "GR7",
    "SP",
    "PC",
    "SREG",
]

def parse(line: str) -> bytes:
    """
    Parse the given line into machine code.
    """

    stripped_line = line.strip()

    if stripped_line.startswith("//") or len(stripped_line) == 0:
        return None

    tokens = re.split(r'\s+|,', stripped_line)

    if len(tokens) != 4:
        raise ValueError("Invalid line format")

    # unpack tokens
    (op, reg, m, adr) = tokens

    if op not in OPERATIONS:
        raise ValueError(f"Invalid operation: {op}")


def assemble(lines: list) -> bytes:
    """
    Assemble the given lines of monkey assembly code into machine code.
    """
    pass


def main(input_file: str = DEFAULT_INPUT_FILE, output_file: str = DEFAULT_OUTPUT_FILE) -> None:
    """
    Read the input file, parse it and write the output file.
    """

    with open(input_file, "r") as f:
        lines = f.readlines()

    assembled_output = assemble(lines)
