"""
This script contains a `Machine` class with methods for interpreting an assembly lines
and updating its state accordingly.

Should be used in conjunction with emulate.py to visualise the state of the machine
after each instruction.

The methods of the machine are to be called from emulate.py, and are not
intended to be run directly.
"""

import numpy as np
import pygame as pg
import re
import time

import array_manip as am
import utils
from section import Section, use_sections
from macros import use_macros
from instruction_decoding import parse_operation, parse_register_and_address

TICK_DELAY_S = 1e-4

class Machine:
    """
    Represent the state of the machine:
    - memory
    - registers
    - flags
    """

    MEMORY_HEIGHT = 4096

    def __init__(self, assembly_lines):
        self.init_memory(assembly_lines)
        self.find_all_breakpoints()
        self.init_registers()
        self.init_flags()
        self.running_free = False
        self.halted = False
        self.stop_at_breakpoints = False

    def init_memory(self, assembly_lines):
        """
        Expand the assembly lines into the full memory.
        - Includes are resolved,
        - Macros are expanded,
        - Sections are used
        """

        self.sections = {}  # section name -> Section object
        macros = {}  # macro name -> macro value

        # resolve includes (<file.s>)
        utils.resolve_includes(assembly_lines, masm_dir="masm")

        # remove lines that are empty or only contain comments
        clean_lines = utils.get_without_empty_or_only_comment_lines(assembly_lines)

        # begin by finding all sections
        for i, line in enumerate(clean_lines):
            if not line.startswith("%"):
                continue  # not a section declaration
            new_section = Section(line)
            self.sections[new_section.name] = new_section  # store section

        current_section = None
        self.labels = {}  # label name -> line number
        for i, line in enumerate(clean_lines):
            # macro declaration
            if line.startswith("_"):
                parts = re.match(r"(_\w+)\s*=\s*(.+)", line).groups()
                macro_name, macro_value = parts
                macros[macro_name] = macro_value  # store macro value
                continue
            # section declaration
            if line.startswith("%"):
                current_section = self.sections[line.replace("%", "").split()[0]]
                continue
            if line.endswith(":\n"):
                new_label = line.replace(":", "").strip()
                label_linenum = len(current_section.lines) + current_section.start
                self.labels[new_label] = label_linenum
                continue

            # replace macros with their values
            line = use_macros(line, macros)
            # replace section names with their start line number
            line = use_sections(line, self.sections)

            current_section.lines.append(line)

        # init empty memory
        self.memory = [""] * self.MEMORY_HEIGHT

        # now that all macros and sections have been expanded, we can
        # fill the memory
        for section in self.sections.values():
            for i, line in enumerate(section.lines):
                self.memory[section.start + i] = line.strip()

    def set_register(self, register, value):
        """
        Set the value of a register
        """

        if register not in self.registers:
            utils.ERROR(f"Unknown register {register}")

        if value > 2**24 - 1:
            utils.ERROR(f"Value {value} is too large for 24-bit register")

        self.registers[register] = value

    def init_registers(self):
        self.registers = {
            "GR0": 0,
            "GR1": 0,
            "GR2": 0,
            "GR3": 0,
            "GR4": 0,
            "GR5": 0,
            "GR6": 0,
            "GR7": 0,
            "GR8": 0,
            "GR9": 0,
            "GR10": 0,
            "GR11": 0,
            "GR12": 0,
            "GR13": 0,
            "GR14": 0,
            "GR15": 0,
            "PC": 0,
            "SP": len(self.memory) - 1,
        }

    def init_flags(self):
        self.flags = {"Z": 0, "N": 0, "C": 0, "V": 0}

    def register_keypress(self, key):
        """
        Store the keypress in GR15
        """

        if key == pg.K_a:
            key_num = 1
        elif key == pg.K_d:
            key_num = 2
        elif key == pg.K_w:
            key_num = 4
        elif key == pg.K_s:
            key_num = 8
        elif key == pg.K_SPACE:
            key_num = 3
        else:
            return  # no known key

        self.set_register("GR15", key_num)

    def increment_pc(self):
        """
        Increment the PC register
        """

        self.set_register("PC", self.registers["PC"] + 1)

    def execute_next_instruction(self):
        """
        Perform the next instruction in the memory
        """

        if self.halted:
            print("Machine is halted! Press 'r' to reset")
            return

        # Fetch the next instruction
        instruction = self.get_from_memory(self.registers["PC"])

        if not instruction:
            utils.ERROR(f"Empty instruction at line {self.registers['PC']}")

        self.increment_pc()

        # Interpret the instruction
        self.execute_instruction(instruction)

    def get_from_memory(self, address):
        """
        Get the value at the given address in memory
        """

        address = utils.get_decimal_int(address)

        return self.memory[address]

    def at_breakpoint(self):
        """
        Check if the current instruction is at a breakpoint
        """
        current_line = self.registers["PC"]
        return current_line in self.breakpoints

    def continue_to_breakpoint(self):
        """
        Continue executing instructions until a breakpoint is reached
        """

        if not self.breakpoints:
            print("No breakpoints set")
            return

        self.stop_at_breakpoints = True
        self.running_free = True


    def find_all_breakpoints(self):
        """
        Find all breakpoints in the memory
        """

        self.breakpoints = []
        for i, line in enumerate(self.memory):
            if re.match(r".*;b.*", line):
                self.breakpoints.append(i)

    def execute_instruction(self, assembly_line: str):
        """
        Perform a single instruction
        """

        parts = re.split(r"\s*,\s*|\s+", assembly_line)
        mnemonic, address_mode = parse_operation(parts)

        if mnemonic == "HALT":
            print("HALT instruction reached")
            self.halted = True
            return  # do nothing
        elif mnemonic == "RET":
            self.perform_stack_operation(["POP", "PC"])
            return
        elif mnemonic in {"BRA", "JSR", "BNE", "BEQ"}:  # branch instructions
            destination = parts[1]
            self.branch(mnemonic, destination)
            return
        elif mnemonic == "MOV":
            self.perform_move(parts)
            return
        elif mnemonic in {"POP", "PUSH"}:
            self.perform_stack_operation(parts)
            return

        reg, adr = parse_register_and_address(mnemonic, parts)

        if isinstance(adr, str):
            adr = eval(adr)

        if mnemonic == "LD":
            self.load_value(reg, adr, address_mode)
        elif mnemonic == "ST":
            self.store_value(reg, adr, address_mode)
        elif mnemonic in {"ADD", "SUB", "AND", "OR", "MUL", "LSR", "LSL", "CMP"}:
            self.perform_alu_operation(mnemonic, reg, adr, address_mode)
        else:
            utils.ERROR(f"Unknown instruction {mnemonic}")

    def perform_stack_operation(self, parts):
        """
        Perform a stack operation
        """

        if len(parts) != 2:
            utils.ERROR(f"Stack operation needs to have exactly 2 parts: {parts}")

        mnemonic, reg_name = parts

        if mnemonic == "PUSH":
            self.memory[self.registers["SP"]] = self.registers[reg_name]
            self.registers["SP"] -= 1
        elif mnemonic == "POP":
            self.registers["SP"] += 1
            self.registers[reg_name] = self.memory[self.registers["SP"]]

    def perform_move(self, parts):
        """
        Copy the value of GR[adr] into GR[reg]
        """
        destination, source = parts[1], parts[2]
        self.registers[destination] = self.registers[source]

    def halt(self):
        """
        Halt the machine
        """

        self.halted = True

    def toggle_pause(self):
        """
        Toggle the pause state of the machine
        """

        self.running_free = not self.running_free

    def run_fast(self):
        """
        Run the machine as fast as possible
        If breakpoint is True, stop at the next breakpoint
        """

        while True:
            if self.running_free:
                self.execute_next_instruction()
            if self.halted:
                break
            if self.stop_at_breakpoints and self.at_breakpoint():
                self.toggle_pause()
            time.sleep(TICK_DELAY_S)

    def branch(self, mnemonic, destination):
        """
        Perform a branch instruction
        """

        if re.match(r"\d+", destination):
            adr = int(destination)
        elif destination in self.labels:
            adr = self.labels[destination]
        else:
            utils.ERROR(f"Unknown destination {destination}")

        if mnemonic == "BRA":
            self.registers["PC"] = adr
        elif mnemonic == "BNE":
            if self.flags["Z"] == 0:
                self.registers["PC"] = adr
        elif mnemonic == "BEQ":
            if self.flags["Z"] == 1:
                self.registers["PC"] = adr
        elif mnemonic == "JSR":
            self.perform_stack_operation(["PUSH", "PC"])
            self.registers["PC"] = adr
        else:
            utils.ERROR(f"Unknown branch mnemonic {mnemonic}")

    def load_value(self, reg, adr, address_mode):
        """
        Load value into register. If address_mode == '', then load
        from memory[adr]. If address_mode == 'I', load the literal `adr` into
        the register.
        """
        if address_mode == "":
            value = self.memory[adr]
        elif address_mode == "I":
            value = adr
        elif address_mode == "N":
            value = self.memory[self.registers["GR3"] + adr]
        else:
            utils.ERROR(f"Unknown address mode {address_mode}")

        self.registers[reg] = utils.get_decimal_int(value)

    def store_value(self, reg, adr: int, address_mode):
        """
        Store the value of register into memory[adr]
        """

        # format as 24 bit binary string
        data = f"0b{self.registers[reg]:024b}"

        if address_mode == "":  # direct
            self.memory[adr] = data
            return
        elif address_mode == "N":  # indexed
            self.memory[self.registers["GR3"] + adr] = data
            return

    def perform_alu_operation(
        self, mnemonic: str, reg: str, adr: int, address_mode: str
    ):
        """
        Perform the ALU operation
        """

        if address_mode == "":
            value = utils.get_decimal_int(self.memory[adr])
        elif address_mode == "I":
            value = adr

        if mnemonic == "ADD":
            result = self.registers[reg] + value
        elif mnemonic in {"SUB", "CMP"}:
            result = self.registers[reg] - value
        elif mnemonic == "AND":
            result = self.registers[reg] & value
        elif mnemonic == "OR":
            result = self.registers[reg] | value
        elif mnemonic == "MUL":
            result = self.registers[reg] * value
        elif mnemonic == "LSR":
            result = self.registers[reg] >> value
        elif mnemonic == "LSL":
            result = self.registers[reg] << value
        else:
            utils.ERROR(f"Unknown mnemonic {mnemonic}")

        # TODO: set other flags
        self.flags["Z"] = 1 if result == 0 else 0

        if mnemonic == "CMP":
            return  # do not write result to register

        # write result to register
        self.registers[reg] = result
