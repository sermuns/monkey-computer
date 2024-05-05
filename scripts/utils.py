import os


def chdir_to_root():
    """
    Find the root directory of the project
    """
    while not os.path.exists("masm"):
        os.chdir(os.pardir)
