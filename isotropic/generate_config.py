from __future__ import print_function

import sys
import argparse

import numpy as np

import isotro as isotropic

# parse arguments from command
parser = argparse.ArgumentParser(description="Generate MARLEY configuration")
parser.add_argument("--neutrino", type=str, default="ve", help="neutrino")
parser.add_argument("--reaction", type=str, default="es", help="reaction")
parser.add_argument("--seed", type=int, default=None,
                    help='integer seed for RNG')

args = parser.parse_args()
neutrino = args.neutrino
reaction = args.reaction
seed = args.seed

neutrinos = [ "ve", "vebar", "vu", "vubar", "vt", "vtbar" ]

reactions = {
    "cc" : "ve40ArCC_Bhattacharya2009.react",
    "es" : "ES.react",
}

txt_path = "/n/home02/jh/repos/qpixprod/isotropic/txt"

bins_file = txt_path + "/bins.txt"
weights_files = {
    "ve"    : txt_path + "/nue.txt",
    "vebar" : txt_path + "/nuebar.txt",
    "vu"    : txt_path + "/nux.txt",
    "vubar" : txt_path + "/nux.txt",
    "vt"    : txt_path + "/nux.txt",
    "vtbar" : txt_path + "/nux.txt",
}

# check if neutrino is valid
if neutrino not in neutrinos:
    msg = """Neutrino '{}' is not valid!
Valid neutrinos:
{}""".format(neutrino, neutrinos)
    raise ValueError(msg)

# check if reaction is valid
if reaction not in reactions.keys():
    msg = """Reaction '{}' is not valid!
Valid reactions:
{}""".format(reaction, list(reactions.keys()))
    raise ValueError(msg)

# check if cc reaction has ve neutrino
if reaction == "cc" and neutrino != "ve":
    msg = """Neutrino '{}' is not valid for reaction '{}'.
MARLEY can only handle 've' neutrinos in 'cc' reactions.
""".format(neutrino, reaction)
    raise ValueError(msg)

# if not args.seed:
#     seed = 137

x, y, z = isotropic.sample(1, seed=seed)

react = reactions[reaction]

bins = None
weights = None

with open(bins_file) as f:
    bins = f.read()

with open(weights_files[neutrino]) as f:
    weights = f.read()

cfg = """
{{
  seed: {}, // Random number seed (omit to use time since Unix epoch)

  // reaction matrix element files
  reactions: [ "{}" ],

  // neutrino source specification
  source: {{
    type: "histogram",
    neutrino: "{}",

    // low edges of energy bins (MeV)
    E_bin_lefts: [
{}
    ],

    // bin weights (dimensionless)
    weights: [
{}
    ],

    // upper edge of the final bin (MeV)
    Emax: 100.1,
  }},

  // incident neutrino direction 3-vector
  direction: {{ x: {}, y: {}, z: {} }},

}}
"""

print(cfg.format(seed, react, neutrino, bins, weights, x[0], y[0], z[0]))
