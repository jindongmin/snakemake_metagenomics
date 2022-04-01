import pandas as pd


df = pd.read_csv('srr.no')
SAMPLES = df['Run'].tolist()
sample = expand('{sample}',sample=SAMPLES)

rule all:
    input:
        qcfile = expand("fastp/{sample}.html", sample = SAMPLES),
        bracken_report = expand("bracken/{sample}.report.txt", sample = SAMPLES),  
rule fastq_dump:
    output:
        fq1 = expand("fastq/{sample}_1.fastq.gz", sample = SAMPLES),
        fq2 = expand("fastq/{sample}_2.fastq.gz", sample = SAMPLES)
    shell:
        """
        fastq-dump --split-3 --gzip {sample} -O fastq/
        cache-mgr --clear >/dev/null 2>&1
        """


rule fastp:
    input:
        fq1 = "fastq/{sample}_1.fastq.gz",
        fq2 = "fastq/{sample}_2.fastq.gz"
    output:
        fq1_trimmed = "trimmed/{sample}_1.fq.gz", 
        fq2_trimmed = "trimmed/{sample}_2.fq.gz",
        qcfile = "fastp/{sample}.html"
    shell:
        "fastp -i {input.fq1} -I {input.fq2} \
        -o {output.fq1_trimmed} -O {output.fq2_trimmed} \
        -h {output.qcfile}"


rule kraken2:
    input:
        index = "/mnt/home/djin/ceph/databases",
        fq1_trimmed = "trimmed/{sample}_1.fq.gz",
        fq2_trimmed = "trimmed/{sample}_2.fq.gz"
    output:
        kraken2_report = "kraken2/{sample}.report.txt",
        kraken2_output = "kraken2/{sample}.output.tsv"
    shell:
        "kraken2 --threads 12 --db {input.index}/kraken2_db_uhgg_v2 --gzip-compressed \
        --paired {input.fq1_trimmed} {input.fq2_trimmed} \
        --report {output.kraken2_report} --output {output.kraken2_output}"

rule bracken:
    input:
        index = "/mnt/home/djin/ceph/databases",
        kraken2_report = "kraken2/{sample}.report.txt"
    output:
        bracken_output = "bracken/{sample}.output.txt",
        bracken_report = "bracken/{sample}.report.txt"
    shell:
        "bracken -d {input.index}/kraken2_db_uhgg_v2 -i {input.kraken2_report} \
        -o {output.bracken_output} -w {output.bracken_report} -r 100 -l S"
