import re


class Section:
    """
    Represents continious portion of the memory
    """

    def __init__(self, name: str, start: int, lines: list = None):
        """
        Construct section object from given parameters
        """
        self.name = name
        self.start = start
        self.lines = lines or []

    def __init__(self, declaration_line: str, lines: list = None):
        """
        Construct section object from declaration line
        """
        parts = (declaration_line.replace("%", "")).split()[:3] # ignore comments
        self.name = parts[0]
        try:
            self.start = int(parts[1])
        except IndexError:
            self.start = 0
        self.lines = lines or []

    def __repr__(self) -> str:
        return f"Section({self.name}, {self.start}, {self.lines})"


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