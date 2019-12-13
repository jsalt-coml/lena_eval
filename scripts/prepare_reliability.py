"""
This scripts work on :
1) "data/reliability/gold1/rttm" containing all the chunks annotated by human1 (5mn chunks)
2) gold2 = "data/reliability/gold2/rttm" containing the SUBSET of chunks annotated by human2 for the reliability study (1mn chunks)

For every chunk of human2 (1 per child), we have 1 chunk made by human1, this script finds it and extract the
relevant part.
"""

import os, glob
import pandas as pd


def extract_rttm(rttm_path, beg, end, output_path):
    """
    Cut down a rttm from beg to end (in sec)
    """
    data = pd.read_csv(rttm_path, header=None, sep="\t",index_col=False,
                       names=["V1", "filename", "V3", "onset", "duration", "V6", "V7", "V8", "spkr"])

    new_bn = os.path.basename(output_path).replace(".rttm", "")
    data["filename"] = new_bn
    data["offset"] = data["onset"] + data["duration"]
    data = data[data["offset"] > beg]
    data = data[data["onset"] < end]
    data.loc[data["onset"] < beg, "onset"] = beg
    data.loc[data["offset"] > end, "duration"] = end
    data["duration"] = data["offset"]-data["onset"]
    data["onset"] = data["onset"] - beg
    data = data.drop("offset", axis=1)
    data.to_csv(output_path, sep="\t", header=False, index=False, float_format='%.2f')

gold1 = "data/reliability/gold1/rttm"
gold2 = "data/reliability/gold2/rttm"
output_folder = "match"

try:
    os.makedirs(os.path.join(os.path.dirname(gold1), output_folder))
except FileExistsError:
    # directory already exists
    pass

rttm_files1 = glob.glob(os.path.join(gold1, "*.rttm"))
rttm_files2 = glob.glob(os.path.join(gold2, "*.rttm"))

for rttm2 in rttm_files2:
    basename2 = os.path.basename(rttm2).replace(".rttm", "")
    splitted2 = basename2.split("_")
    id2, onset2, offset2 = splitted2[0]+'_'+splitted2[2], int(splitted2[3]), int(splitted2[4])

    for rttm1 in rttm_files1:
        basename1 = os.path.basename(rttm1).replace(".rttm", "")
        splitted1 = basename1.split("_")

        id1, onset1, offset1 = splitted1[0]+'_'+splitted1[1], int(splitted1[2]), int(splitted1[3])
        # print("2")
        # print("%s %s %s" % (id2, onset2, offset2))
        # print("1")
        # print("%s %s %s" % (id1, onset1, offset1))
        if id1 == id2:
            if onset2 >= onset1 and offset2 <= offset1:
                beg = onset2-onset1
                end = beg + offset2 - onset2
                new_name = id1+'_'+'{:0>6}'.format(onset1+beg)+'_'+'{:0>6}'.format(onset1+end)+'.rttm'
                output_path = os.path.join(os.path.dirname(gold1), output_folder, new_name)
                extract_rttm(rttm1, beg, end, output_path)
                continue

