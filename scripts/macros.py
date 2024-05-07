def use_macros(line, macros):
    """
    Replace all macros in the given line with their values
    """

    if not "_" in line:
        return line # nothing to do

    for macro in macros:
        line = line.replace(macro, macros[macro])

    return line