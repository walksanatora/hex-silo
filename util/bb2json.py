# quick script to turn bbcode from hexcasting extention
# into json usable via the ducky peripherals focal port
import re, json
from sys import argv
regex = re.compile(r'\[pat=([aqwedAQWED]+) dir=([nesw]+)\]')

remap_short = {
    "ne": "NORTH_EAST",
    "e": "EAST",
    "se": "SOUTH_EAST",
    "sw": "SOUTH_WEST",
    "w": "WEST",
    "nw": "NORTH_WEST"
}

class PatternEncoder(json.JSONEncoder):
        def default(self, o):
            return o.__dict__

class pattern:
    def __init__(self, angles: str, dir: str):
        self.angles = angles   
        self.startDir = remap_short[dir]
    def __repr__(self):
        return f'HexPattern({self.dir} {self.angles})'

patterns = []

if len(argv) < 3: 
    print("needs 2 arguments")
    exit()

with open(argv[1],"r") as input:
    for pat in re.finditer(regex,input.read()):
        patterns.append(pattern(*pat.groups()))
with open(argv[2],"w") as output:
    json.dump(patterns,output,cls=PatternEncoder)
