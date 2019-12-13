import argparse
import os, glob
import numpy as np

# Mapping to [OCH, CHI, FEM, MAL, ELE]
gold_dict = {
    'C1': 'OCH',
    'C2': 'OCH',
    'CHI': 'CHI',
    'CHI*': 'CHI',
    'EE1': 'ELE',
    'FA0': 'FEM',
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
    'FC2': 'OCH',
    'FC3': 'OCH',
    'MA0': 'MAL',
    'MA1': 'MAL',
    'MA2': 'MAL',
    'MA3': 'MAL',
    'MA4': 'MAL',
    'MA5': 'MAL',
    'MAE': 'ELE',
    'MC1': 'OCH',
    'MC2': 'OCH',
    'MC3': 'OCH',
    'MC4': 'OCH',
    'MC5': 'OCH',
    'MI1': 'OCH',
    'MOT*': 'FEM',
    'OC0': 'OCH',
    'UC1': 'OCH',
    'UC2': 'OCH',
    'UC3': 'OCH',
    'UC4': 'OCH',
    'UC5': 'OCH',
    'UC6': 'OCH'
}

# Map ELE to SIL
gold_dict_no_ele = {
    'C1': 'OCH',
    'C2': 'OCH',
    'CHI': 'CHI',
    'CHI*': 'CHI',
    'EE1': 'SIL',
    'FA0': 'FEM',
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
    'MA0': 'MAL',
    'MA1': 'MAL',
    'MA2': 'MAL',
    'MA3': 'MAL',
    'MA4': 'MAL',
    'MA5': 'MAL',
    'MAE': 'SIL',
    'MC1': 'OCH',
    'MC2': 'OCH',
    'MC3': 'OCH',
    'MI1': 'OCH',
    'MOT*': 'FEM',
    'OC0': 'OCH',
    'UC1': 'OCH',
    'UC2': 'OCH',
    'UC3': 'OCH',
    'UC4': 'OCH',
    'UC5': 'OCH',
    'UC6': 'OCH'
}

# Keep near classes only
lena_dict_near_only = {
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

# Near classes without TV
lena_dict_near_only_no_tv = {
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

# Near classes without TV
lena_all = {
    'CHF': 'CHF',
    'CHN': 'CHN',
    'CXF': 'CXF',
    'CXN': 'CXN',
    'FAF': 'FAF',
    'FAN': 'FAN',
    'MAF': 'MAF',
    'MAN': 'MAN',
    'NOF': 'NOF',
    'NON': 'NON',
    'OLF': 'OLF',
    'OLN': 'OLN',
    'SIL': 'SIL',
    'TVN': 'TVN',
    'TVF': 'TVF'
}

# Near classes without tv and overlap
lena_dict_near_only_no_tv_no_oln = {
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

# Used when gold and lena labels need to be the same
lena_to_gold = {'SIL': 'SIL',
                'NOF': 'SIL',
                'NON': 'SIL',
                'CHN': 'CHI',
                'CHF': 'CHI',
                'CXN': 'OCH',
                'CXF': 'OCH',
                'FAN': 'FEM',
                'FAF': 'FEM',
                'MAN': 'MAL',
                'MAF': 'MAL',
                'OLN': 'OVL',
                'OLF': 'OVL',
                'TVN': 'ELE',
                'TVF': 'ELE'}


def map_rttm(rttm, overlap, dict, same, output_folder):
    # Output name
    output = os.path.join(output_folder,
                          os.path.basename(rttm))

    if dict == "lena_sil":
        dict = lena_dict_near_only
    elif dict == "lena_sil_no_tv":
        dict = lena_dict_near_only_no_tv
    elif dict == "lena_sil_no_tv_no_oln":
        dict = lena_dict_near_only_no_tv_no_oln
    elif dict == "gold":
        dict = gold_dict
    elif dict == "gold_no_ele":
        dict = gold_dict_no_ele
    elif dict == "lena_all":
        dict = lena_all
    else:
        raise ValueError("Value of dict unknown, must be in [lena_sil, lena_sil_no_tv, lena_sil_no_tv_no_oln, gold, gold_no_ele")

    data = []
    # Version without overlap
    with open(rttm, "r") as fi:
        with open(output, "w") as fo:
            basename = os.path.basename(rttm).replace(".rttm", "")
            if not overlap:
                # Version without overlap
                for line in fi:
                    splitted = line.split('\t')
                    onset, duration, sentence, sentence_type, speaker = float(splitted[3]), float(splitted[4]), splitted[5], splitted[6], splitted[7]
                    target_speaker = dict[speaker]
                    if same:
                        target_speaker = lena_to_gold[target_speaker]
                    if target_speaker != "SIL":
                        fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n"
                                 % (basename, onset, duration, sentence, sentence_type, target_speaker))
                    data.append([onset, duration, target_speaker])
            else:
                # Version with overlap
                prev_onset, prev_duration, prev_offset, prev_speaker = 0.0, 0.0, 0.0, "SIL"
                prev_sentence, prev_sentence_type = "<NA>", "<NA>"

                for line in fi:
                    splitted = line.split('\t')
                    onset, duration, sentence, sentence_type, speaker = round(float(splitted[3]), 2), round(float(splitted[4]),2), \
                                               splitted[5], splitted[6], splitted[7]
                    offset = round(onset+duration, 2)
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
                                    fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n"
                                             % (basename, prev_onset, onset-prev_onset, prev_sentence, prev_sentence_type, prev_speaker))
                                if prev_offset - onset > 0:
                                    fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n"
                                             % (basename, onset, prev_offset - onset, sentence, sentence_type, "OVL"))
                                duration = duration - (prev_offset - onset)
                                onset = prev_onset + prev_duration
                                offset = onset + duration
                            else:
                                # Second type overlap
                                # |------------|
                                #       |----|
                                if onset-prev_onset > 0:
                                    fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n"
                                             % (basename, prev_onset, onset-prev_onset, prev_sentence, prev_sentence_type, prev_speaker))
                                if duration > 0:
                                    fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n"
                                             % (basename, onset, duration, sentence, sentence_type, "OVL"))
                                onset = offset
                                duration = prev_offset - offset
                                offset = prev_offset
                                target_speaker = prev_speaker
                        else:
                            if prev_duration > 0:
                                fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n" % (basename, prev_onset,
                                                                                          prev_duration, prev_sentence, prev_sentence_type, prev_speaker))
                    #print("%f : %f : %s" % (prev_onset, prev_offset, prev_speaker))
                    prev_onset = onset
                    prev_duration = duration
                    prev_offset = offset
                    prev_speaker = target_speaker
                    prev_sentence = sentence
                    prev_sentence_type = sentence_type

                # Write last utterance
                if prev_duration > 0 and prev_speaker != "SIL":
                    fo.write("SPEAKER\t%s\t1\t%.2f\t%.2f\t%s\t%s\t%s\t<NA>\t<NA>\n" % (basename, prev_onset,
                                                                                    prev_duration, prev_sentence, prev_sentence_type, prev_speaker))


def main():
    parser = argparse.ArgumentParser(description="Map labels of rttm files. All the generated files are stored in a subfolder"
                                                 "called mapped")
    parser.add_argument('-p', '--path', type=str, required=True,
                        help="Path to the folder containing .rttm files")
    parser.add_argument('-m', '--map', type=str, required=True, choices=["lena_all", "lena_sil", "lena_sil_no_tv", "lena_sil_no_tv_no_oln", "gold", "gold_no_ele"],
                        help="Indicates if this is lena files that needs to be mapped or gold files."
                             "Must be in [lena_sil,lena_far, lena_sil_no_tv,lena_sil_no_tv_no_oln,gold,gold_no_ele]")
    parser.add_argument('-o', '--overlap', action="store_true",
                        help="Indicates if we need to map overlapping speech to the label \"OVL\"")
    parser.add_argument('-s', '--same', action="store_true",
                        help="Indicates if we need to map lena labels so that they're the same than gold labels")
    args = parser.parse_args()

    folder_path = args.path
    overlap = args.overlap
    dict = args.map

    same = False
    if dict == "lena_sil" or dict == "lena_sil_no_tv" or dict == "lena_sil_no_tv_no_oln" or dict == "lena_same":
        same = args.same

    rttm_files = glob.glob(os.path.join(folder_path, "*.rttm"))

    if len(rttm_files) == 0:
        raise ValueError("No rttm files have been found in %s" % folder_path)

    # Create output dir

    output_folder = os.path.join(folder_path, "mapped_%s" % dict)
    if dict == "gold_no_ele" and not overlap:
        output_folder += "_no_ovl"

    if same:
        output_folder += "_same"

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print("Directory", output_folder, " created ")

    for rttm in rttm_files:
        map_rttm(rttm, overlap, dict, same, output_folder)


if __name__ == '__main__':
    main()
