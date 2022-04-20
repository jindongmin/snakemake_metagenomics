#!/usr/bin/env python3



import argparse
import biom
import glob
from biom.util import biom_open
import pandas

parser = argparse.ArgumentParser()
parser.add_argument('--data-dir', help='Data directory of braken outputs',
                    required=True)
parser.add_argument('--output-biom', help='Output biom format',
                    required=True)
args = parser.parse_args()
data_dir = args.data_dir
# to do stuff ...
abund_files = glob.glob(f"{data_dir}/*.abundance.txt")
bracken_abunds = map(pd.read_table, abund_files)
def pd2biom(x):
    feature_ids = x['name']
    sample_id = x.columns[-1]
    counts = x[sample_id].values
    return biom.Table(counts, feature_ids, [sample_id])
biom_tables = list(map(pd2biom, bracken_abunds))
table = biom_tables[0].concat(biom_tables[1:])
with biom_open(args.output_biom, 'wb') as f:
    table.to_hdf5(f, 'combined')
