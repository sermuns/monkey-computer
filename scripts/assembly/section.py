class Section:
    """
    Represents continious portion of the memory
    """

    def __init__(self, name, start, height, lines=None):
        self.name = name
        self.start = start
        self.height = height
        self.lines = lines or []

    def __repr__(self) -> str:
        return f"{self.name} {self.start} {self.height}"