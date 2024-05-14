from utils import ERROR
import utils
from typing import Sequence


REG_ADR_OPS = {"LD", "ADD", "SUB", "AND", "OR", "MUL", "LSR", "LSL"}
ADR_REG_OPS = {"ST", "OUT", "SWAP"}
REG_REG_OPS = {"MOV", "ADDREG"}
REG_OPS = {"POP", "PUSH", "JSR"}
ADDR_OPS = {"BRA", "JSR"}
NO_ARGS_OPS = {"RET"}

KNOWN_OPCODES = utils.get_opcodes()


def parse_operation(parts: Sequence) -> tuple[str, str]:
    op_fullname = parts[0]
    op_basename = None
    op_address_mode = None
    for known_op_name in KNOWN_OPCODES:
        if op_fullname.startswith(known_op_name):
            op_basename = known_op_name
            op_address_mode = op_fullname[len(op_basename) :]
            break
    if not op_basename:
        ERROR(f"Unknown operation {op_fullname} in `{parts}`")
    return op_basename, op_address_mode


def parse_register_and_address(op_basename: str, parts: Sequence) -> tuple[str, int]:
    # assume don't care
    op_adr = "-"
    grx_name = "-"

    if op_basename in REG_ADR_OPS:
        grx_name, op_adr = parts[1], parts[2]
    elif op_basename in ADR_REG_OPS:
        op_adr, grx_name = parts[1], parts[2]
    elif op_basename in REG_OPS:
        grx_name = parts[1]
    elif op_basename in NO_ARGS_OPS:
        pass
    elif op_basename in ADDR_OPS:
        op_adr = parts[1]
    return grx_name, utils.evaluate_expr(op_adr)
