#!/usr/bin/env bash

####################################
## 1) Create appropriate mappings ##
####################################

# With same set of labels
python scripts/labels_mapper.py -p data/gold -m gold -o             # All
python scripts/labels_mapper.py -p data/gold -m gold_no_ele -o      # All but ELE
python scripts/labels_mapper.py -p data/gold -m gold_no_ele         # All but ELE and OVL
python scripts/labels_mapper.py -p data/lena -m lena_sil -s                # Near classes
python scripts/labels_mapper.py -p data/lena -m lena_sil_no_tv -s          # Near classes, no TV
python scripts/labels_mapper.py -p data/lena -m lena_sil_no_tv_no_oln -s   # Near classes, no TV, no OLN
python scripts/labels_mapper.py -p data/lena -m lena_sil_no_tv_no_oln -s
python scripts/labels_mapper.py -p data/lena -m lena_all -s         # All lena labels

# With respective labels for computing confusion matrices
python scripts/labels_mapper.py -p data/lena -m lena_sil    # Near classes

###################################
# 2) Running evaluation metrics  ##
###################################
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t identification \
    -m ider precision recall
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t detection \
    -m deter --class_to_keep OCH
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t detection \
    -m deter --class_to_keep CHI
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t detection \
    -m deter --class_to_keep MAL
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t detection \
    -m deter --class_to_keep FEM
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t detection \
    -m deter --class_to_keep ELE
python scripts/compute_metrics.py -ref data/gold/mapped_gold \
    -hyp data/lena/mapped_lena_sil_same -t detection \
    -m deter --class_to_keep OVL

python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele \
    -hyp data/lena/mapped_lena_sil_no_tv_same -t identification \
    -m ider precision recall
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele \
    -hyp data/lena/mapped_lena_sil_no_tv_same -t detection \
    -m deter --class_to_keep OCH
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele \
    -hyp data/lena/mapped_lena_sil_no_tv_same -t detection \
    -m deter --class_to_keep CHI
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele \
    -hyp data/lena/mapped_lena_sil_no_tv_same -t detection \
    -m deter --class_to_keep MAL
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele \
    -hyp data/lena/mapped_lena_sil_no_tv_same -t detection \
    -m deter --class_to_keep FEM
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele \
    -hyp data/lena/mapped_lena_sil_no_tv_same -t detection \
    -m deter --class_to_keep OVL

python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele_no_ovl \
    -hyp data/lena/mapped_lena_sil_no_tv_no_oln_same -t identification \
    -m ider precision
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele_no_ovl \
    -hyp data/lena/mapped_lena_sil_no_tv_no_oln_same -t detection \
    -m deter --class_to_keep OCH
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele_no_ovl \
    -hyp data/lena/mapped_lena_sil_no_tv_no_oln_same -t detection \
    -m deter --class_to_keep CHI
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele_no_ovl \
    -hyp data/lena/mapped_lena_sil_no_tv_no_oln_same -t detection \
    -m deter --class_to_keep MAL
python scripts/compute_metrics.py -ref data/gold/mapped_gold_no_ele_no_ovl \
    -hyp data/lena/mapped_lena_sil_no_tv_no_oln_same -t detection \
    -m deter --class_to_keep FEM


rm -rf evaluations
mkdir evaluations

mv data/gold/mapped_gold/gold_lena_sil_same evaluations
mv data/gold/mapped_gold_no_ele/gold_no_ele_lena_sil_no_tv_same evaluations
mv data/gold/mapped_gold_no_ele_no_ovl/gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same evaluations

##################################
#  3) Confusion matrices        ##
##################################

python scripts/frame_cutter.py  --i data/lena/mapped_lena_sil/ --o framed_lena_sil
python scripts/frame_cutter.py  --i data/gold/mapped_gold/ --o framed_gold
python scripts/frame_cutter.py  --i data/lena/mapped_lena_all/ --o framed_lena_all

Rscript scripts/conf_mat.r data/lena/framed_lena_sil data/gold/framed_gold corpora
mv data/gold/framed_gold/*.txt evaluations

Rscript scripts/conf_mat.r data/lena/framed_lena_all data/gold/framed_gold corpora
for f in data/gold/framed_gold/*.txt ; do mv $f evaluations/lena_all_$(basename $f); done


##################################
#  4) Vocalizations statistics  ##
##################################

Rscript scripts/extract_stat.r
