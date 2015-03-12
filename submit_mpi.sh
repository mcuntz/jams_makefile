#!/bin/bash
#$ -S /bin/bash
#$ -N mpitest
#$ -cwd
#$ -o $JOB_NAME-$JOB_ID.log
#$ -j y
#$ -l h_rt=00:00:10
#$ -l h_vmem=0.1G
#$ -pe openmpi-orte 3
module load openmpi/gcc
mpirun -np ${NSLOTS:-1} ./Prog
