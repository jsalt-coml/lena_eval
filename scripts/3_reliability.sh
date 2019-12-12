##!/usr/bin/env bash

rm -rf data/reliability/*/match
rm -rf data/reliability/*/rttm

# Extract rttm chunks from eaf
indices=(1 2)
for index in ${indices[*]}; do
    mkdir -p data/reliability/gold${index}/rttm
    for eaf in data/reliability/gold${index}/eaf/*.eaf; do
        eaf=$(basename $eaf)
        python scripts/adjust_timestamps.py data/reliability/gold${index}/eaf/${eaf} data/reliability/gold${index}/rttm/
        ret=$?
        if [ $ret == 1 ]; then
            exit
        fi;
    done;
done;

# Prepare reliability
python scripts/prepare_reliability.py

mkdir -p data/reliability/gold2/match
for rttm in data/reliability/gold2/rttm/*.rttm; do
    # Delete rely_ from the filename, so that pyannote can do the pairing
    new_path=${rttm/rttm\//match\/}
    new_path=${new_path/rely_/}

    cp $rttm $new_path
done


###########################
#   1) pyannote metrics  ##
###########################
source activate lena_eval

python scripts/labels_mapper.py -p data/reliability/gold1/match -m gold -o
python scripts/labels_mapper.py -p data/reliability/gold2/match -m gold -o

python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t identification \
    -m ider precision recall
python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t detection\
     -m deter precision recall --class_to_keep OCH
python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t detection\
     -m deter precision recall precision recall --class_to_keep CHI
python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t detection\
     -m deter precision recall --class_to_keep MAL
python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t detection\
     -m deter precision recall --class_to_keep FEM
python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t detection\
     -m deter precision recall --class_to_keep ELE
python scripts/compute_metrics.py -ref data/reliability/gold1/match/mapped_gold \
    -hyp data/reliability/gold2/match/mapped_gold -t detection\
     -m deter precision recall --class_to_keep OVL

rm -rf reliability_evaluations
mkdir reliability_evaluations

mv data/reliability/gold1/match/mapped_gold/gold_gold reliability_evaluations/metrics

###################################
##  3) Confusion matrices        ##
###################################

python scripts/frame_cutter.py  --i data/reliability/gold1/match/mapped_gold --o framed_mapped -d 60
python scripts/frame_cutter.py  --i data/reliability/gold2/match/mapped_gold --o framed_mapped -d 60
Rscript scripts/conf_mat.r data/reliability/gold1/framed_mapped data/reliability/gold2/framed_mapped no_corpora
mv data/reliability/gold2/framed_mapped/*.txt reliability_evaluations

###################################
##  4) Vocalizations statistics  ##
###################################

Rscript scripts/extract_stat_reliability.r