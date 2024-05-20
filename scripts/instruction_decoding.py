from utils import ERROR
import utils
from typing import Sequence


REG_ADR_OPS = {"LD", "ADD", "SUB", "AND", "OR", "MUL", "LSR", "LSL", "CMP"}
ADR_REG_OPS = {"ST", "SWAP"}
REG_REG_OPS = {"MOV"}
REG_OPS = {"POP", "PUSH"}
ADDR_OPS = {"BRA", "JSR", "BNE", "BEQ"}
NO_ARGS_OPS = {"RET", "HALT"}

KNOWN_MNEMONICS = utils.get_mnemonics()


def parse_operation(parts: Sequence) -> tuple[str, str]:
    mnemonic = parts[0]
    op_basename = None
    op_address_mode = None
    for known_mnemonic in KNOWN_MNEMONICS:
        if mnemonic.startswith(known_mnemonic):
            op_basename = known_mnemonic
            op_address_mode = mnemonic[len(op_basename) :]
            break
    if not op_basename:
        ERROR(f"Unknown operation {mnemonic} in `{parts}`")
    return op_basename, op_address_mode


def parse_register_and_address(mnemonic_base: str, parts: Sequence) -> tuple[str, str]:
    """
    Given the mnemonic base and the parts of the instruction,
    return the register name and address, both as strings.
    """

    # assume don't care
    op_adr = "-"
    grx_name = "-"

    if mnemonic_base in REG_ADR_OPS:
        grx_name, op_adr = parts[1], parts[2]
    elif mnemonic_base in ADR_REG_OPS:
        op_adr, grx_name = parts[1], parts[2]
    elif mnemonic_base in REG_OPS:
        grx_name = parts[1]
    elif mnemonic_base in NO_ARGS_OPS:
        pass # no arguments
    elif mnemonic_base in ADDR_OPS:
        op_adr = parts[1]
    else:
        ERROR(f"Unknown operation {mnemonic_base} in `{parts}`")

    return grx_name, op_adr
