#Count the amount of numbers that are in a string
# VERY IMPORTANT CODE FOR TSTE24
import regex as re
def count_nums(string):
    return len(re.findall(r'\d', string))
    
print(count_nums("00001_000_00_00000000000000")) #3