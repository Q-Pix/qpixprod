from __future__ import print_function

import sys
import argparse

# parse arguments from command
parser = argparse.ArgumentParser(description="Generate qpixg4 macro")
parser.add_argument("isotope", type=str, default=None,
                    help="radiogenic isotope")
parser.add_argument("decays", type=int, default=None,
                    help="number of decays")
parser.add_argument("file", type=str, default=None,
                    help="output path for ROOT file")
parser.add_argument('--seeds', nargs="+", type=int, default=None,
                    help='integer seeds for RNG')

args = parser.parse_args()
isotope = str(args.isotope)
decays = str(args.decays)
file_path = str(args.file)
seeds = str(args.seeds).replace("[", "").replace(",", "").replace("]", "")

if not args.seeds:
    seeds = "137 {}".format(decays)

isotopes = {
    "Po210" :     10,
    "Ar42"  :     65,
    "K42"   :     65,
    "Co60"  :    250,
    "Bi214" :   7000,
    "Pb214" :   7000,
    "K40"   :  12642,
    "Rn222" :  28000,
    "Kr85"  :  80500,
    "Ar39"  : 707000,
}

if isotope not in isotopes.keys():
    msg = """Isotope {} is not valid!
Valid radiogenic isotopes:
{}""".format(isotope, list(isotopes.keys()))
    raise ValueError(msg)

# isotope, decays, output file, seed 1, seed 2

g4macro = """
# set verbosity
/control/verbose 1
/run/verbose 1
/tracking/verbose 0

# configure supernova
/Inputs/Particle_Type SUPERNOVA

# output path
/Inputs/root_output {}

# initialize run
/run/initialize
/random/setSeeds {}

# event ID offset
/event/offset 0

# Supernova configs
/Supernova/Event_Window 10 s
/Supernova/Event_Cutoff 10 s

/Supernova/N_{}_Decays 1

# run
/run/beamOn {}
"""

print(g4macro.format(file_path, seeds, isotope, decays))

