from utils import ERROR
import utils


# OP GRx, ADR
IN_OPERATIONS = {"LD", "ADD", "SUB", "AND", "OR", "IN", "MUL", "LSR", "LSL"}
# OP ADR, GRx
OUT_OPERATIONS = {"ST", "OUT"}
# OP GRx, GRx
TWO_REG_OPERATIONS = {"MOV", "ADDREG"}
# OP GRx
ONE_REG_OPERATIONS = {"POP", "PUSH", "JSR"}
# OP ADR
ONE_ADDR_OPERATIONS = {"BRA", "JSR"}
# OP
NO_ARGS_OPERATIONS = {"RET"}

KNOWN_OPCODES = utils.get_opcodes()


def parse_operation(parts):
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

def parse_register_and_address(op_basename, parts):
    op_adr = "-"
    grx_name = "-"
    if op_basename in IN_OPERATIONS:
        grx_name, op_adr = parts[1], parts[2]
    elif op_basename in OUT_OPERATIONS:
        op_adr, grx_name = parts[1], parts[2]
    elif op_basename in ONE_REG_OPERATIONS:
        grx_name = parts[1]
    elif op_basename in NO_ARGS_OPERATIONS:
        pass
    elif op_basename in ONE_ADDR_OPERATIONS:
        op_adr = parts[1]
    return grx_name, utils.evaluate_expr(op_adr)