#!/usr/bin/env bash

#SBATCH -J ve_cc_iso_snb_qpix  # a single job name for the array
#SBATCH -n 1                   # number of cores
#SBATCH -N 1                   # all cores on one machine
#SBATCH -p serial_requeue      # partition
#SBATCH --mem 1000             # memory request (Mb)
#SBATCH -t 0-48:00             # maximum execution time (D-HH:MM)
#SBATCH --signal=B:USR1@60     # signal handling for jobs that time out

offset=0

index=$(echo `expr ${SLURM_ARRAY_TASK_ID} + $offset`)
index_lz=$(printf "%06d" "$index")

SCRATCH_DIR="/scratch/`whoami`"
STORE_DIR="/n/holystore01/LABS/guenette_lab/Lab/data/q-pix/supernova/production"
MARLEY_CONFIG_DIR="${SCRATCH_DIR}"
G4_MACRO_DIR="${SCRATCH_DIR}"
G4_OUTPUT_DIR="${SCRATCH_DIR}"
RTD_OUTPUT_DIR="${SCRATCH_DIR}"
SLIM_OUTPUT_DIR="${SCRATCH_DIR}"
LOG_DIR=${SCRATCH_DIR}
OUTPUT_DIR="${STORE_DIR}/signal"

if [ ! -d "${SCRATCH_DIR}" ]; then
  mkdir -p ${SCRATCH_DIR}
fi

LOG_PREFIX="${SLURM_ARRAY_JOB_ID}"_"${SLURM_ARRAY_TASK_ID}"
LOG_PATH=${LOG_DIR}/${LOG_PREFIX}

PY_CONFIG=/n/home02/jh/repos/qpixprod/isotropic/generate_config.py
PY_MACRO=/n/home02/jh/repos/qpixprod/isotropic/generate_macro.py
G4_BIN=/n/home02/jh/repos/qpixg4/build/app/G4_QPIX
RTD_BIN=/n/home02/jh/repos/qpixrtd/EXAMPLE/build/EXAMPLE
SLIMMER=/n/home02/jh/repos/qpixrtd/EXAMPLE/signal_slimmer.c

# tuple="\
# ve     nusperbin2d_nue
# vebar  nusperbin2d_nuebar
# vu     nusperbin2d_nux
# vubar  nusperbin2d_nux
# vt     nusperbin2d_nux
# vtbar  nusperbin2d_nux"

tuple="\
ve     nusperbin2d_nue"

events=100000

# reactions=(cc es)
reactions=(cc)

counter=0

function main() {

  while read neutrino th2; do

    for reaction in $reactions
    do

      let counter++

      echo "neutrino: '$neutrino', th2: '$th2', reaction: '$reaction'"

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
      output_file_path=${OUTPUT_DIR}/"$neutrino"_"$reaction"/garching/${index_lz:0:2}/${index_lz:2:2}/${index_lz:4:2}

      if [ ! -d "$output_file_path" ]; then
        mkdir -p $output_file_path
      fi

      if [ -f "$marley_config_file_path" ]; then
        rm $marley_config_file_path
      fi

      if [ -f "$g4_macro_file_path" ]; then
        rm $g4_macro_file_path
      fi

      date; sleep 2
      time python ${PY_CONFIG} --neutrino $neutrino --reaction $reaction --seed $index >> $marley_config_file_path
      date; sleep 2
      time python ${PY_MACRO} $marley_config_file_path $events $g4_file_path --seeds ${SLURM_ARRAY_TASK_ID} $(echo `expr $index + $counter`) --timing --th2 $th2 >> $g4_macro_file_path
      date; sleep 2
      time ${G4_BIN} $g4_macro_file_path
      date; sleep 2
      time ${RTD_BIN} $g4_file_path $rtd_file_path
      date; sleep 2
      time root -l -b -q ''${SLIMMER}'("'$rtd_file_path'", "'$slim_file_path'")'
      date; sleep 2
      mv $slim_file_path $output_file_path
      date; sleep 2
      mv $marley_config_file_path $output_file_path
      date; sleep 2
      mv $g4_macro_file_path $output_file_path
      date; sleep 2
      rm $g4_file_path
      date; sleep 2
      rm $rtd_file_path
      date; sleep 2

    done

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

