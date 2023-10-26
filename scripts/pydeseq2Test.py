#! /usr/bin/env python

from pydeseq2.dds import DeseqDataSet
from pydeseq2.ds import DeseqStats
import numpy as np
import pandas as pd
from scipy.sparse import coo_matrix
import random
from statsmodels.stats.proportion import binom_test
from statsmodels.stats.multitest import multipletests
#from sys import argv
from argparse import ArgumentParser 
import os

    
def pydeseq2Test(X, y, z, k, nc):
    """
    X: count matrix of microbes (m microbes X n samples)
    y: disease lables for samples (n samples)
    z: colname of the condition (eg. disease status)
    k: top k microbes, eg k = 100
    nc: number of cpu
    """
    # Convert counts and group labels to PyDESeq2 input format
    dds = DeseqDataSet(
        X, 
        y, 
        design_factors = z,# compare samples based on the "disease"
        refit_cooks = True,
        n_cpus = nc
    )
    dds.deseq2()
    #set of the sample status: Healthy, disease
    status = set(y[z])
    #remove healthy
    status.remove("Healthy")
    disease = ', '.join(status)
    #sample status colname: disease, 
    #disease: name of that disease
    stat_res = DeseqStats(dds,contrast = [z, disease, "Healthy" ], n_cpus=nc)
    #stat_res = DeseqStats(dds,contrast = ["disease", "Healthy", "AD" ], n_cpus=8)
    res = stat_res.summary()
    res_df = stat_res.results_df    
    res_df["CI_95"] = res_df["log2FoldChange"] + res_df['lfcSE'] * 1.96
    res_df["CI_5" ] = res_df["log2FoldChange"] - res_df['lfcSE'] * 1.96
    #top k microbes: the ones with largest CI_5
    top = res_df.sort_values(by=['CI_5'],ascending=False).head(k)
    #bottom k microbes: the ones with smallest CI_95
    bot = res_df.sort_values(by=['CI_95'],ascending=True).head(k)
    #convert microbe names to species ids
    top_microbe = top #set(top.index)
    bot_microbe = bot #set(bot.index)
             
    return res_df, top_microbe, bot_microbe



def get_options():
    parser = ArgumentParser()
    parser.add_argument("-x", dest="microbe_table",
                       help="count matrix of microbes (m microbes X n samples)",
                       required=True)
    parser.add_argument("-y", dest="disease_labels",
                       help="disease lables for samples (n samples)",
                       required=True)
    parser.add_argument("-z", dest="disease_status",
                       help="colnames of the diseases status",
                       required=True)
    parser.add_argument("-k", dest="top_k", default=100, type=int,
                       help="top k microbes. "
                            "Default: %(default)i")
    parser.add_argument("-nc", dest="number_cpus",default=8, type=int,
                       help="number of cpus")
    parser.add_argument("-o", dest="output_dir",
                       help="new output folder containing following files: "
                            "1) table: res_df, "
                            "2) table: top_microbe "
                            "3) table: bot_microbe",
                       required=True)
    options = parser.parse_args()
    os.mkdir(options.output_dir)
    return options


def main():
    option = get_options()
    input_table = pd.read_table(option.microbe_table, sep = '\t', index_col = 0)
    input_table = input_table.T
    input_table2 = pd.read_table(option.disease_labels, sep = '\t', index_col = 'featureid')
    input_table = input_table.loc[input_table2.index]
    input_table = input_table.reindex(input_table2.index)
	
    res_df, top_microbe, bot_microbe = pydeseq2Test(X = input_table,
                                                y = input_table2,
                                                z = option.disease_status,
                                                k = option.top_k,
                                                nc = option.number_cpus)

    res_df.to_csv(option.output_dir + "/" + "res_df.tsv", sep = '\t')
    top_microbe.to_csv(option.output_dir + "/" + "top_microbe.tsv", sep = '\t')
    bot_microbe.to_csv(option.output_dir + "/" + "bot_microbe.tsv", sep = '\t')


if __name__ == '__main__':
    main()
