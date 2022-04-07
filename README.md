# snakemake_metagenomics

snakemake -v
7.1.1

database: uhgg v2 24-Feb-2022 
http://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0/kraken2_db_uhgg_v2/

mamba install bracken

kraken2 --version
Kraken version 2.1.2

fasterq-dump -V
"fasterq-dump" version 2.11.0

To do:
add shadow directive
https://snakemake.readthedocs.io/en/stable/project_info/faq.html#how-can-i-make-use-of-node-local-storage-when-running-cluster-jobs
