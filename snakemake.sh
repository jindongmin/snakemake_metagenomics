#!/bin/sh
#SBATCH --job-name=snakemake
#SBATCH --output=slurm_%j.out
#SBATCH --cpus-per-task=12
#SBATCH --nodes=1
#SBATCH --time=4-00:00:00

snakemake --rerun-incomplete -R $(snakemake --list-code-changes) --cores 40
