import re


class Section:
    """
    Represents continious portion of the memory
    """

    def __init__(self, name: str, start: int, height: int, lines: list = None):
        """
        Construct section object from given parameters
        """
        self.name = name
        self.start = start
        self.height = height
        self.lines = lines or []

    def __init__(self, declaration_line: str, lines: list = None):
        """
        Construct section object from declaration line
        """
        parts = (declaration_line.replace("%", "")).split()
        self.name = parts[0]
        self.start = int(parts[1])
        self.height = int(parts[2])
        self.lines = lines or []

    def __repr__(self) -> str:
        return f"{self.name} {self.start} {self.height}"


def use_sections(line, sections):
    """
    Replace all %<section name> in the line with their
    start linenum
    """

    if not "%" in line:
        return line # nothing to do
    
    for section_name, section in sections.items():
        line = line.replace(f"%{section.name}", str(section.start))

    return line