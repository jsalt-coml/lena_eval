import os, glob
import pandas as pd

lena_path = "/home/lavechin/srvk/DiViMe/data/new_lena_analysis/lena"
wav_path = "/home/lavechin/srvk/DiViMe/data/new_lena_analysis/wav"
corpus = ["BER", "ROW", "SOD", "WAR"]

for corpora in corpus:
    wav_files = glob.glob(os.path.join(wav_path, "%s_*.wav" % corpora))
    for wav in wav_files:
        basename = os.path.basename(wav).replace(".wav", "")
        splitted = basename.split('_')
        id = splitted[1]
        onset = int(splitted[2])
        offset = int(splitted[3])

        daylong_lena_rttm = os.path.join(lena_path, corpora, "%s_%s.rttm" % (corpora, id))
        data = pd.read_csv(daylong_lena_rttm, sep=" ", names=["speaker", "filename", "1_col", "onset", "duration", "not1", "not2", "label", "not3", "not4"])
        chunk = data[(data["onset"]+data["duration"] > onset) & (data["onset"] < offset)]

        above = chunk["onset"] + chunk["duration"] > offset
        chunk.loc[above, "duration"] = offset-chunk.loc[above, "onset"]

        below = chunk["onset"] < onset
        chunk.loc[below, "duration"] = chunk.loc[below, "duration"] - (onset - chunk.loc[below, "onset"])
        chunk.loc[below, "onset"] = onset

        # Shift all onset to start at 0
        chunk["onset"] = chunk["onset"] - onset

        # Write extracted chunk
        output_path = os.path.join(lena_path, "%s_%s_%06d_%06d.rttm" % (corpora, id, onset, offset))
        chunk["filename"] = "%s_%s_%06d_%06d" % (corpora, id, onset, offset)
        chunk.to_csv(path_or_buf=output_path, sep=" ", float_format='%.6f', header=False, index=False)
