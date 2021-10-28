from __future__ import print_function

import sys
import argparse

# parse arguments from command
parser = argparse.ArgumentParser(description="Generate qpixg4 macro")
parser.add_argument("marley", type=str, default=None,
                    help="path to MARLEY configuration file")
parser.add_argument("events", type=int, default=None,
                    help="number of events")
parser.add_argument("file", type=str, default=None,
                    help="output path for ROOT file")
parser.add_argument("--seeds", nargs="+", type=int, default=None,
                    help="integer seeds for RNG")
parser.add_argument("--timing", dest="timing", action="store_true")
parser.add_argument("--no-timing", dest="timing", action="store_false")
parser.set_defaults(timing=False)
parser.add_argument("--th2", type=str, default=None,
                    required="--timing" in sys.argv,
                    help="name of TH2 in nusperbin2d.root")

args = parser.parse_args()
marley = str(args.marley)
events = str(args.events)
file_path = str(args.file)
seeds = str(args.seeds).replace("[", "").replace(",", "").replace("]", "")
timing = args.timing
th2 = args.th2

th2_names = [ "nusperbin2d_nue", "nusperbin2d_nuebar", "nusperbin2d_nux" ]

if not args.seeds:
    seeds = "137 {}".format(events)

if th2 and th2 not in th2_names:
    msg = """TH2 {} is not valid!
Valid TH2 names:
{}""".format(th2, th2_names)
    raise ValueError(msg)

if timing:

    g4macro = """
# set verbosity
/control/verbose 1
/run/verbose 1
/tracking/verbose 0

# configure marley
/Inputs/Particle_Type MARLEY
/Inputs/MARLEY_json {}
/Inputs/isotropic false
/Inputs/override_vertex_position false
/Inputs/vertex_x 1.15 m
/Inputs/vertex_y 3.0 m
/Inputs/vertex_z 1.8 m

# configure supernova timing
/supernova/timing/on         true
/supernova/timing/input_file /n/holystore01/LABS/guenette_lab/Everyone/supernova/nusperbin2d.root
/supernova/timing/th2_name   {}

# output path
/Inputs/root_output {}

# initialize run
/run/initialize
/random/setSeeds {}

# Supernova configs
/Supernova/Event_Cutoff 10 s

# limit radioactive decays
/grdm/nucleusLimits 1 35 1 17  # aMin aMax zMin zMax

# run
/run/beamOn {}
"""

    print(g4macro.format(marley, file_path, th2, seeds, events))

else:

    g4macro = """
# set verbosity
/control/verbose 1
/run/verbose 1
/tracking/verbose 0

# configure marley
/Inputs/Particle_Type MARLEY
/Inputs/MARLEY_json {}
/Inputs/isotropic false
/Inputs/override_vertex_position false
/Inputs/vertex_x 1.15 m
/Inputs/vertex_y 3.0 m
/Inputs/vertex_z 1.8 m

# configure supernova timing
/supernova/timing/on false

# output path
/Inputs/root_output {}

# initialize run
/run/initialize
/random/setSeeds {}

# limit radioactive decays
/grdm/nucleusLimits 1 35 1 17  # aMin aMax zMin zMax

# run
/run/beamOn {}
"""

    print(g4macro.format(marley, file_path, seeds, events))

