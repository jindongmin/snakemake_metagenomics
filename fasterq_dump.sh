#!/bin/sh
#SBATCH --job-name=fasterq_dump
#SBATCH --output=slurm_%j.out
#SBATCH --cpus-per-task=12
#SBATCH --nodes=1


fasterq-dump ERR011189 -e 12 -S -O fq/