#!/usr/bin/env bash

#SBATCH -J snb_bg_qpix      # A single job name for the array
#SBATCH -n 1                # Number of cores
#SBATCH -N 1                # All cores on one machine
#SBATCH -p guenette         # Partition
#SBATCH --mem 1500          # Memory request (Mb)
#SBATCH -t 0-12:00          # Maximum execution time (D-HH:MM)
#SBATCH --signal=B:USR1@60  # signal handling for jobs that time out
#SBATCH -o /n/holyscratch01/guenette_lab/Users/jh/supernova/backgrounds/radiogenic/log/%A_%a.out        # Standard output
#SBATCH -e /n/holyscratch01/guenette_lab/Users/jh/supernova/backgrounds/radiogenic/log/%A_%a.err        # Standard error

offset=0
#offset=10000
#offset=20000
#offset=30000
#offset=40000
#offset=50000
#offset=60000
#offset=70000
#offset=80000
#offset=90000
#offset=100000
#offset=110000
#offset=120000
#offset=130000
#offset=140000
#offset=150000
#offset=160000
#offset=170000
#offset=180000
#offset=190000
#offset=200000
#offset=210000
#offset=220000
#offset=230000
#offset=240000
#offset=250000
#offset=260000
#offset=270000
#offset=280000
#offset=290000
#offset=300000

index=$(echo `expr ${SLURM_ARRAY_TASK_ID} + $offset`)
index_lz=$(printf "%06d" "$index")

# SCRATCH_DIR="/n/holyscratch01/guenette_lab/Users/jh/supernova/backgrounds/radiogenic"
# STORE_DIR="/n/holystore01/LABS/guenette_lab/Lab/data/q-pix/supernova/production/backgrounds/radiogenic"
# G4_MACRO_DIR="${SCRATCH_DIR}/macros"
# G4_OUTPUT_DIR="${SCRATCH_DIR}/g4"
# RTD_OUTPUT_DIR="${SCRATCH_DIR}/rtd"
# SLIM_OUTPUT_DIR="${SCRATCH_DIR}/slim"
# OUTPUT_DIR="${STORE_DIR}"

SCRATCH_DIR="/scratch/`whoami`"
STORE_DIR="/n/holystore01/LABS/guenette_lab/Lab/data/q-pix/supernova/production/backgrounds/radiogenic"
G4_MACRO_DIR="${SCRATCH_DIR}"
G4_OUTPUT_DIR="${SCRATCH_DIR}"
RTD_OUTPUT_DIR="${SCRATCH_DIR}"
SLIM_OUTPUT_DIR="${SCRATCH_DIR}"
LOG_DIR=${SCRATCH_DIR}
OUTPUT_DIR="${STORE_DIR}"

if [ ! -d "${SCRATCH_DIR}" ]; then
  mkdir -p ${SCRATCH_DIR}
fi

LOG_PREFIX="${SLURM_ARRAY_JOB_ID}"_"${SLURM_ARRAY_TASK_ID}" 
LOG_PATH=${LOG_DIR}/${LOG_PREFIX}

PY_MACRO=/n/home02/jh/repos/qpixprod/backgrounds/radiogenic/generate_macro.py
G4_BIN=/n/home02/jh/repos/qpixg4/build/app/G4_QPIX
RTD_BIN=/n/home02/jh/repos/qpixrtd/EXAMPLE/build/EXAMPLE
SLIMMER=/n/home02/jh/repos/qpixrtd/EXAMPLE/background_slimmer.c

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

function main() {

  while read isotope decays; do

    let counter++

    echo "isotope: '$isotope', decays: '$decays'"

    g4_macro_file_name="$isotope"_g4_"$index_lz".mac
    g4_file_name="$isotope"_g4_"$index_lz".root
    rtd_file_name="$isotope"_rtd_"$index_lz".root
    slim_file_name="$isotope"_rtd_slim_"$index_lz".root

    g4_macro_file_path=${G4_MACRO_DIR}/$g4_macro_file_name
    g4_file_path=${G4_OUTPUT_DIR}/$g4_file_name
    rtd_file_path=${RTD_OUTPUT_DIR}/$rtd_file_name
    slim_file_path=${SLIM_OUTPUT_DIR}/$slim_file_name
    # output_file_path=${OUTPUT_DIR}/$index_lz
    output_file_path=${OUTPUT_DIR}/${index_lz:0:2}/${index_lz:2:2}/${index_lz:4:2}

    if [ ! -d "$output_file_path" ]; then
      mkdir -p $output_file_path
    fi

    if [ -f "$g4_macro_file_path" ]; then
      rm $g4_macro_file_path
    fi

    date; sleep 2
    time python ${PY_MACRO} $isotope $decays $g4_file_path --seeds $index $(echo `expr $decays + $counter`) >> $g4_macro_file_path
    date; sleep 2
    time ${G4_BIN} $g4_macro_file_path
    date; sleep 2
    time ${RTD_BIN} $g4_file_path $rtd_file_path
    date; sleep 2
    time root -l -b -q ''${SLIMMER}'("'$rtd_file_path'", "'$slim_file_path'")'
    date; sleep 2
    mv $slim_file_path $output_file_path
    date; sleep 2
    mv $g4_macro_file_path $output_file_path
    date; sleep 2
    rm $g4_file_path
    date; sleep 2
    rm $rtd_file_path
    date; sleep 2

  done <<< "$tuple"

}

function signal_handler() {
  echo "Catching signal"
  cd $SLURM_SUBMIT_DIR
  mkdir -p $SLURM_ARRAY_JOB_ID
  touch ${SLURM_ARRAY_JOB_ID}/job_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}_caught_signal
  # cp -R $TMPDIR/* $SLURM_JOB_ID
  cp ${LOG_PATH}.{out,err} ${SLURM_ARRAY_JOB_ID}
  exit
}  

trap signal_handler USR1
trap signal_handler TERM

main 1> ${LOG_PATH}.out 2> ${LOG_PATH}.err &
wait

