#!/bin/bash
#PBS -N sampler
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l walltime=00:10:00
#PBS -j oe
#PBS -m bae

# Change to the directory where the job was submitted
cd $PBS_O_WORKDIR              

# Your actual commands
echo "Starting job on $(hostname)"
sleep 5
echo "Job finished at $(date)"
