import glob
import os, shutil
import re
import argparse
import pandas as pd

parser = argparse.ArgumentParser(description="Convert the old naming convention of tsi/lena files into the new one."
                                             "Ex : python scripts/change_tsi_lena_names.py -f data/its/lena"
                                             "Such as downloaded there : https://www.dropbox.com/home/tsi_its"
                                             "(Ask Alex Cristia for access")
parser.add_argument('-f', '--folder', type=str, required=True,
                    help="path to the input folder containing tsi its files (e20181015_114815_013102.its, ...)"
                         "The root folder is expected to contain tsi_key_info.csv")
args = parser.parse_args()

path_tsi_folder = args.folder
its_files = glob.iglob(os.path.join(path_tsi_folder, '*.its'))

tsi_key_info = pd.read_csv(os.path.join(os.path.dirname(path_tsi_folder),
                                        'tsi_key_info_r.csv'))

for its in its_files:
    basename = os.path.basename(its).replace(".its", "")
    filtered = tsi_key_info[tsi_key_info['file_lena'] == basename]

    if len(filtered) != 0:
        key = filtered.iloc[0]['key']
        new_path = os.path.join(os.path.dirname(its), str(key) + ".its")
        shutil.copyfile(its, new_path)

    if os.path.basename(its)[0] == "e":
        os.remove(its)

