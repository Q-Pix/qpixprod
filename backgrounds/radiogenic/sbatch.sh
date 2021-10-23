#!/usr/bin/env bash

#SBATCH -J qpix_snb_bg      # A single job name for the array
#SBATCH -n 1                # Number of cores
#SBATCH -N 1                # All cores on one machine
#SBATCH -p guenette         # Partition
#SBATCH --mem 1000          # Memory request (Mb)
#SBATCH -t 0-2:00           # Maximum execution time (D-HH:MM)
#SBATCH -o /n/holyscratch01/guenette_lab/Users/jh/supernova/log/%A_%a.out        # Standard output
#SBATCH -e /n/holyscratch01/guenette_lab/Users/jh/supernova/log/%A_%a.err        # Standard error

offset=0

SCRATCH_DIR="/n/holyscratch01/guenette_lab/Users/jh/supernova"
STORE_DIR="/n/holystore01/LABS/guenette_lab/Lab/data/q-pix/supernova"
G4_MACRO_DIR="${SCRATCH_DIR}/macros"
G4_OUTPUT_DIR="${SCRATCH_DIR}/g4"
RTD_OUTPUT_DIR="${SCRATCH_DIR}/rtd"
SLIM_OUTPUT_DIR="${SCRATCH_DIR}/slim"
OUTPUT_DIR="${STORE_DIR}/production"

PY_MACRO=/n/home02/jh/repos/qpixprod/backgrounds/radiogenic/generate_macro.py
G4_BIN=/n/home02/jh/repos/qpixg4/build/app/G4_QPIX
RTD_BIN=/n/home02/jh/repos/qpixrtd/EXAMPLE/build/EXAMPLE
SLIMMER=/n/home02/jh/repos/qpixrtd/EXAMPLE/slimmer.c

tuple="\
Po210      10
Ar42       65
K42        65
Co60      250
Bi214    7000
Pb214    7000
K40     12642
Rn222   28000
Kr85    80500
Ar39   707000"

counter=0

while read isotope decays; do

    let counter++

    echo "isotope: '$isotope', decays: '$decays'"

    # index=$(printf "%06d" "${SLURM_ARRAY_TASK_ID}")
    index=$(echo `expr ${SLURM_ARRAY_TASK_ID} + $offset`)
    index=$(printf "%06d" "$index")

    g4_macro_file_name="$isotope"_g4_"$index".mac
    g4_file_name="$isotope"_g4_"$index".root
    rtd_file_name="$isotope"_rtd_"$index".root
    slim_file_name="$isotope"_rtd_slim_"$index".root

    g4_macro_file_path=${G4_MACRO_DIR}/$g4_macro_file_name
    g4_file_path=${G4_OUTPUT_DIR}/$g4_file_name
    rtd_file_path=${RTD_OUTPUT_DIR}/$rtd_file_name
    slim_file_path=${SLIM_OUTPUT_DIR}/$slim_file_name
    output_file_path=${OUTPUT_DIR}/$index

    if [ ! -d "$output_file_path" ]; then
        mkdir -p $output_file_path
    fi

    if [ -f "$g4_macro_file_path" ]; then
        rm $g4_macro_file_path
    fi

    date; sleep 2
    time python ${PY_MACRO} $isotope $decays $g4_file_path --seeds ${SLURM_ARRAY_TASK_ID} $(echo `expr $decays + $counter`) >> $g4_macro_file_path
    date; sleep 2
    time ${G4_BIN} $g4_macro_file_path
    date; sleep 2
    time ${RTD_BIN} $g4_file_path $rtd_file_path
    date; sleep 2
    time root -l -b -q ''${SLIMMER}'("'$rtd_file_path'", "'$slim_file_path'")'
    date; sleep 2
    mv $slim_file_path $output_file_path
    date; sleep 2
    rm $g4_file_path
    date; sleep 2
    rm $rtd_file_path
    date; sleep 2

done <<< "$tuple"

