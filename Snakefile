import pandas as pd


df = pd.read_csv('srr.no')
SAMPLES = df['Run'].tolist()

rule all:
    input:
        qcfile = expand("fastp/{sample}.html", sample = SAMPLES),
        bracken_report = expand("bracken/{sample}.report.txt", sample = SAMPLES)  

rule fasterq:
    output:
        fq1 = temp("fq/{sample}_1.fastq"),
        fq2 = temp("fq/{sample}_2.fastq")
    threads: 12
    shell:
        "prefetch {wildcards.sample} --output-directory fq/"
        "&& fasterq-dump {wildcards.sample} -e {threads} -S -O fq/"
        "&& cache-mgr --clear >/dev/null 2>&1"

rule gzip:
    input:
        fq1 = "fq/{sample}_1.fastq",                                         
        fq2 = "fq/{sample}_2.fastq"
    output:
        fq1_gz = temp("fq/{sample}_1.fastq.gz"),
        fq2_gz = temp("fq/{sample}_2.fastq.gz")
    shell:
        "gzip fq/{wildcards.sample}_1.fastq"                                 
        "&& gzip fq/{wildcards.sample}_2.fastq"
 
rule fastp:
    input:
        fq1 = "fq/{sample}_1.fastq.gz",
        fq2 = "fq/{sample}_2.fastq.gz"
    output:
        fq1_trimmed = temp("trimmed/{sample}_1.fq.gz"), 
        fq2_trimmed = temp("trimmed/{sample}_2.fq.gz"),
        qcfile = "fastp/{sample}.html"
    threads: 12
    shell:
        "fastp -i {input.fq1} -I {input.fq2} \
        -o {output.fq1_trimmed} -O {output.fq2_trimmed} \
        -h {output.qcfile} -w {threads}"


rule kraken2:
    input:
        index = "/mnt/home/djin/ceph/databases",
        fq1_trimmed = "trimmed/{sample}_1.fq.gz",
        fq2_trimmed = "trimmed/{sample}_2.fq.gz"
    output:
        kraken2_report = "kraken2/{sample}.report.txt",
        kraken2_output = temp("kraken2/{sample}.output.tsv")
    threads: 12
    shell:
        "kraken2 --threads {threads} --db {input.index}/kraken2_db_uhgg_v2\
        --gzip-compressed --paired {input.fq1_trimmed} {input.fq2_trimmed} \
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
