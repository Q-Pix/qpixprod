#!/usr/bin/env bash

#SBATCH -J qpix_snb_iso     # A single job name for the array
#SBATCH -n 1                # Number of cores
#SBATCH -N 1                # All cores on one machine
#SBATCH -p guenette         # Partition
#SBATCH --mem 1000          # Memory request (Mb)
#SBATCH -t 0-2:00           # Maximum execution time (D-HH:MM)
#SBATCH -o /n/holyscratch01/guenette_lab/Users/jh/supernova/log/%A_%a.out        # Standard output
#SBATCH -e /n/holyscratch01/guenette_lab/Users/jh/supernova/log/%A_%a.err        # Standard error

offset=0

SCRATCH_DIR="/n/holyscratch01/guenette_lab/Users/jh/supernova/isotropic"
STORE_DIR="/n/holystore01/LABS/guenette_lab/Lab/data/q-pix/supernova"
MARLEY_CONFIG_DIR="${SCRATCH_DIR}/marley"
G4_MACRO_DIR="${SCRATCH_DIR}/macros"
G4_OUTPUT_DIR="${SCRATCH_DIR}/g4"
RTD_OUTPUT_DIR="${SCRATCH_DIR}/rtd"
SLIM_OUTPUT_DIR="${SCRATCH_DIR}/slim"
# OUTPUT_DIR="${STORE_DIR}/production"
OUTPUT_DIR="${STORE_DIR}/isotropic"

PY_CONFIG=/n/home02/jh/repos/qpixprod/isotropic/generate_config.py
PY_MACRO=/n/home02/jh/repos/qpixprod/isotropic/generate_macro.py
G4_BIN=/n/home02/jh/repos/qpixg4/build/app/G4_QPIX
RTD_BIN=/n/home02/jh/repos/qpixrtd/EXAMPLE/build/EXAMPLE
SLIMMER=/n/home02/jh/repos/qpixrtd/EXAMPLE/signal_slimmer.c

tuple="\
ve     nusperbin2d_nue
vebar  nusperbin2d_nuebar
vu     nusperbin2d_nux
vubar  nusperbin2d_nux
vt     nusperbin2d_nux
vtbar  nusperbin2d_nux"

events=100000

reactions=(cc es)

counter=0

while read neutrino th2; do

    for reaction in $reactions
    do

        let counter++

        echo "neutrino: '$neutrino', th2: '$th2', reaction: '$reaction'"

        # index=$(printf "%06d" "${SLURM_ARRAY_TASK_ID}")
        index=$(echo `expr ${SLURM_ARRAY_TASK_ID} + $offset`)
        index_lz=$(printf "%06d" "$index")

        marley_config_file_name="$neutrino"_"$reaction"_marley_"$index_lz".cfg
        g4_macro_file_name="$neutrino"_"$reaction"_g4_"$index_lz".mac
        g4_file_name="$neutrino"_"$reaction"_g4_"$index_lz".root
        rtd_file_name="$neutrino"_"$reaction"_rtd_"$index_lz".root
        slim_file_name="$neutrino"_"$reaction"_rtd_slim_"$index_lz".root

        marley_config_file_path=${MARLEY_CONFIG_DIR}/$marley_config_file_name
        g4_macro_file_path=${G4_MACRO_DIR}/$g4_macro_file_name
        g4_file_path=${G4_OUTPUT_DIR}/$g4_file_name
        rtd_file_path=${RTD_OUTPUT_DIR}/$rtd_file_name
        slim_file_path=${SLIM_OUTPUT_DIR}/$slim_file_name
        output_file_path=${OUTPUT_DIR}/"$neutrino"_"$reaction"/$index_lz

        # if [ ! -d "$output_file_path" ]; then
        #     mkdir -p $output_file_path
        # fi

        if [ -f "$marley_config_file_path" ]; then
            rm $marley_config_file_path
        fi

        if [ -f "$g4_macro_file_path" ]; then
            rm $g4_macro_file_path
        fi

        echo date; sleep 2
        echo time python ${PY_CONFIG} --neutrino $neutrino --reaction $reaction --seed $index #>> $marley_config_file_path
        echo date; sleep 2
        # echo time python ${PY_MACRO} $marley_config_file_path $events $g4_file_path --seeds ${SLURM_ARRAY_TASK_ID} $(echo `expr $index + $counter`) --timing --th2 $th2 >> $g4_macro_file_path
        echo time python ${PY_MACRO} $marley_config_file_path $events $g4_file_path --seeds ${SLURM_ARRAY_TASK_ID} $(echo `expr $index + $counter`) #>> $g4_macro_file_path
        echo date; sleep 2
        echo time ${G4_BIN} $g4_macro_file_path
        echo date; sleep 2
        echo time ${RTD_BIN} $g4_file_path $rtd_file_path
        echo date; sleep 2
        echo time root -l -b -q ''${SLIMMER}'("'$rtd_file_path'", "'$slim_file_path'")'
        echo date; sleep 2
        echo mv $slim_file_path $output_file_path
        echo date; sleep 2
        echo mv $marley_config_file_path $output_file_path
        echo date; sleep 2
        echo mv $g4_macro_file_path $output_file_path
        echo date; sleep 2
        echo rm $g4_file_path
        echo date; sleep 2
        echo rm $rtd_file_path
        echo date; sleep 2

    done

done <<< "$tuple"

