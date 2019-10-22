import argparse
import os, glob
import numpy as np

# Must arrive in [SIL, CHI, FEM, MAL]
gold_dict = {
    'C1': 'OCH',
    'C2': 'OCH',
    'CHI': 'CHI',
    'CHI*': 'CHI',
    'EE1': 'ELE',
    'FA1': 'FEM',
    'FA2': 'FEM',
    'FA3': 'FEM',
    'FA4': 'FEM',
    'FA5': 'FEM',
    'FA6': 'FEM',
    'FA7': 'FEM',
    'FA8': 'FEM',
    'FAE': 'ELE',
    'FC1': 'OCH',
    'MA1': 'MAL',
    'MA2': 'MAL',
    'MA3': 'MAL',
    'MA4': 'MAL',
    'MA5': 'MAL',
    'MAE': 'ELE',
    'MC1': 'OCH',
    'MC2': 'OCH',
    'MC3': 'OCH',
    'MI1': 'OCH', # not sure for this one
    'MOT*': 'FEM',
    'UC1': 'OCH',
    'UC2': 'OCH',
    'UC3': 'OCH',
    'UC4': 'OCH',
    'UC5': 'OCH',
    'UC6': 'OCH'
}

gold_dict_no_ele = {
    'C1': 'OCH',
    'C2': 'OCH',
    'CHI': 'CHI',
    'CHI*': 'CHI',
    'EE1': 'SIL',
    'FA1': 'FEM',
    'FA2': 'FEM',
    'FA3': 'FEM',
    'FA4': 'FEM',
    'FA5': 'FEM',
    'FA6': 'FEM',
    'FA7': 'FEM',
    'FA8': 'FEM',
    'FAE': 'SIL',
    'FC1': 'OCH',
    'MA1': 'MAL',
    'MA2': 'MAL',
    'MA3': 'MAL',
    'MA4': 'MAL',
    'MA5': 'MAL',
    'MAE': 'SIL',
    'MC1': 'OCH',
    'MC2': 'OCH',
    'MC3': 'OCH',
    'MI1': 'OCH', # not sure for this one
    'MOT*': 'FEM',
    'UC1': 'OCH',
    'UC2': 'OCH',
    'UC3': 'OCH',
    'UC4': 'OCH',
    'UC5': 'OCH',
    'UC6': 'OCH'
}

#
lena_dict_far = {
    'CHF': 'CHF',
    'CHN': 'CHN',
    'CXF': 'CXF',
    'CXN': 'CXN',
    'FAF': 'FAF',
    'FAN': 'FAN',
    'MAF': 'MAF',
    'MAN': 'MAN',
    'NOF': 'SIL',
    'NON': 'SIL',
    'OLF': 'OLF',
    'OLN': 'OLN',
    'SIL': 'SIL',
    'TVN': 'TVN',
    'TVF': 'TVF'
}

#all the far categories  go to nonspeech
lena_dict_sil = {
    'CHF': 'SIL',
    'CHN': 'CHN',
    'CXF': 'SIL',
    'CXN': 'CXN',
    'FAF': 'SIL',
    'FAN': 'FAN',
    'MAF': 'SIL',
    'MAN': 'MAN',
    'NOF': 'SIL',
    'NON': 'SIL',
    'OLF': 'SIL',
    'OLN': 'OLN',
    'SIL': 'SIL',
    'TVN': 'TVN',
    'TVF': 'SIL'
}

#all the far categories  go to nonspeech
lena_dict_sil_no_tv = {
    'CHF': 'SIL',
    'CHN': 'CHN',
    'CXF': 'SIL',
    'CXN': 'CXN',
    'FAF': 'SIL',
    'FAN': 'FAN',
    'MAF': 'SIL',
    'MAN': 'MAN',
    'NOF': 'SIL',
    'NON': 'SIL',
    'OLF': 'SIL',
    'OLN': 'OLN',
    'SIL': 'SIL',
    'TVN': 'SIL',
    'TVF': 'SIL'
}

lena_dict_sil_no_tv_no_oln = {
    'CHF': 'SIL',
    'CHN': 'CHN',
    'CXF': 'SIL',
    'CXN': 'CXN',
    'FAF': 'SIL',
    'FAN': 'FAN',
    'MAF': 'SIL',
    'MAN': 'MAN',
    'NOF': 'SIL',
    'NON': 'SIL',
    'OLF': 'SIL',
    'OLN': 'SIL',
    'SIL': 'SIL',
    'TVN': 'SIL',
    'TVF': 'SIL'
}


def map_rttm(rttm, overlap, dict):

    # Output name
    output = os.path.join(os.path.dirname(rttm),
                          "mapped_%s" % dict,
                          os.path.basename(rttm))

    if dict == "lena_far":
        dict = lena_dict_far
    elif dict == "lena_sil":
        dict = lena_dict_sil
    elif dict == "lena_sil_no_tv":
        dict = lena_dict_sil_no_tv
    elif dict == "lena_sil_no_tv_no_oln":
        dict = lena_dict_sil_no_tv_no_oln
    elif dict == "gold":
        dict = gold_dict
    elif dict == "gold_no_ele":
        dict = gold_dict_no_ele



    data = []
    # Version without overlap
    with open(rttm, "r") as fi:
        with open(output, "w") as fo:
            basename = os.path.basename(rttm).replace(".rttm", "")
            if not overlap:
                # Version without overlap
                for line in fi:
                    splitted = line.split(' ')
                    onset, duration, speaker = float(splitted[3]), float(splitted[4]), splitted[7]
                    target_speaker = dict[speaker]
                    if target_speaker != "SIL":
                        fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n"
                                 % (basename, onset, duration, target_speaker))
                    data.append([onset, duration, target_speaker])
            else:
                # Version with overlap
                prev_onset, prev_duration, prev_offset, prev_speaker = 0.0, 0.0, 0.0, "SIL"

                for line in fi:
                    splitted = line.split(' ')
                    onset, duration, speaker = round(float(splitted[3]), 4), round(float(splitted[4]),4), \
                                               splitted[7]
                    offset = round(onset+duration, 4)
                    target_speaker = dict[speaker]

                    if prev_onset > onset:
                        duration = max(0, duration - prev_onset + onset)
                        onset = prev_onset
                        offset = onset+duration

                    if prev_speaker != "SIL":
                        if prev_offset > onset:
                            if prev_offset < offset:
                                # First type overlap
                                # |---------|
                                #       |---------|
                                if onset-prev_onset > 0:
                                    fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n"
                                             % (basename, prev_onset, onset-prev_onset, prev_speaker))
                                if prev_offset - onset > 0:
                                    fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n"
                                             % (basename, onset, prev_offset - onset, "OVL"))
                                duration = duration - (prev_offset - onset)
                                onset = prev_onset + prev_duration
                                offset = onset + duration
                            else:
                                # Second type overlap
                                # |------------|
                                #       |----|
                                if onset-prev_onset > 0:
                                    fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n"
                                             % (basename, prev_onset, onset-prev_onset, prev_speaker))
                                if duration > 0:
                                    fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n"
                                             % (basename, onset, duration, "OVL"))
                                onset = offset
                                duration = prev_offset - offset
                                offset = prev_offset
                                target_speaker = prev_speaker
                        else:
                            if prev_duration > 0:
                                fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n" % (basename, prev_onset,
                                                                                          prev_duration, prev_speaker))
                    #print("%f : %f : %s" % (prev_onset, prev_offset, prev_speaker))
                    prev_onset = onset
                    prev_duration = duration
                    prev_offset = offset
                    prev_speaker = target_speaker

                # Write last utterance
                if prev_duration > 0 and prev_speaker != "SIL":
                    fo.write("SPEAKER %s 1 %.4f %.4f <NA> <NA> %s <NA> <NA>\n" % (basename, prev_onset,
                                                                                    prev_duration, prev_speaker))


def main():
    parser = argparse.ArgumentParser(description="Map labels of rttm files. All the generated files are stored in a subfolder"
                                                 "called mapped")
    parser.add_argument('-p', '--path', type=str, required=True,
                        help="Path to the folder containing .rttm files")
    parser.add_argument('-m', '--map', type=str, required=True, choices=["lena_sil","lena_far", "lena_sil_no_tv", "lena_sil_no_tv_no_oln", "gold", "gold_no_ele"],
                        help="Indicates if this is lena files that needs to be mapped or gold files."
                             "Must be in [lena_sil,lena_far, lena_sil_no_tv,lena_sil_no_tv_no_oln,gold,gold_no_ele]")
    parser.add_argument('-o', '--overlap', action="store_true",
                        help="Indicates if we need to map overlapping speech to the label \"OVL\"")
    args = parser.parse_args()

    folder_path = args.path
    overlap = args.overlap
    dict = args.map
    rttm_files = glob.glob(os.path.join(folder_path, "*.rttm"))

    if len(rttm_files) == 0:
        raise ValueError("No rttm files have been found in %s" % folder_path)

    # Create output dir
    output_folder = os.path.join(folder_path, "mapped_%s" % dict)
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print("Directory", output_folder, " created ")

    for rttm in rttm_files:
        map_rttm(rttm, overlap, dict)


if __name__ == '__main__':
    main()
