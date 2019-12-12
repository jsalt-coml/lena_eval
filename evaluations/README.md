# LENA evaluation: evaluations folder

This folder contains all data needed to reproduce the manuscript entitled "A thorough evaluation of the Language Environment Analysis (LENA) system", and more:

## Confusion matrices

In each case, columns are LENA labels, rows are human labels; cells indicate the number of 10 millisecond frames in each LENA-human crossing. 

LENA labels are: CHN (key child near); FAN (female adult near); OLN (overlap near); SIL (all the far categories as well as silence); CXN (other child 
near), TVN (TV near), MAN (male adult near).

Human labels are: CHI (key child), FEM (female adult), SIL (all non-speech including silence), OVL (overlap between two or more talkers), ELE 
(electronic voices, including radio, telephone, skype, toys), MAL (male adult), OCH (other children).

These are organized as follows:

- all_cm.txt: all data together- BER_cm.txt: Only Bergelson data- ROW_cm.txt: Only Lucid/Rowland data- SOD_cm.txt: Only Soderstrom data- TSI_cm.txt: Only Tsimane' data- WAR_cm.txt: Only Warlaumont data

## Identification error and related metrics

These are organized in three subfolders:

- gold_lena_sil_same: labels across human and lena have been matched, and all labels are included- gold_no_ele_lena_sil_no_tv_same: labels across human and lena have been matched, but ELE is combined with SIL in human and TV is combined with SIL in LENA- gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same: labels across human and lena have been matched, but ELE, OVL, SIL are combined in human; and TV, OLN, SIL are combined in LENA

Within each folder there are the following csv's (all generated using pyannote):

- ider_report.csv
- precision_report.csv
- recall_report.csv

Since these tables contain several fields, they are detailed in the following subsections.

In addition, each folder contains a detection error report for the classes that are included. Thus, maximally, there are the following (in gold_lena_sil_same):

- only_CHI_deter_report.csv- only_ELE_deter_report.csv- only_FEM_deter_report.csv- only_MAL_deter_report.csv- only_OCH_deter_report.csv- only_OVL_deter_report.csv


They each contain the following fields:

|field name | explanation|
|--- | ---|
|detection error   rate \% | sum of FA \% and M \%|
|total | total number of frames considered|
|false alarm | number of frames for which the system returned this label but the human   had provided a different label (including SIL)|
|false alarm \% | percent out of the total that the false alarm frames represent|
|miss | number of frames for which the system returned another label  (including SIL) but the human had provided   this label|
|miss \% | percent out of the total that the missed frames represent|

### ider_report.csv

Identification error rate report:

|field name | explanation|
|--- | ---|
|item | file that was analyzed|
|identification error rate \% | total Identification error rate in percent (sum of FA\%, MD\%, C\%)|
|total | total number of frames analyzed|
|correct | number of correct frames|
|correct \% | percent of frames that were correct out of the total number of frames   analyzed|
|false alarm | number of frames for which the system returned a label when the human   coded this as SIL|
|false alarm \% | percent of frames for which the system returned a label when the human   coded this as SIL, out of the total number of frames analyzed|
|missed detection | number of frames for which the system returned SIL when the human did not   code this as SIL|
|missed detection \% | percent of frames for which the system returned SIL when the human did   not code this as SIL, out of the total number of frames analyzed|
|confusion | number of frames for which the system returned the incorrect label (ie   any label other than SIL and the one the human gave)|
|confusion \% | percent of frames for which the system returned  the incorrect label (ie any label other   than SIL and the one the human gave), out of the total number of frames   analyzed|


### precision_report.csv

|field name | explanation|
|--- | ---|
|item | file that was analyzed|
|detection precision  \% | overall percentage that was correctly detected (out of the total in the LENA annotation), summing across all   classes|
|retrieved | number of frames that were found|
|relevant retrieved | number of speech frames (ie anything but SIL) that were correctly   detected|


###  recall_report.csv
|field name | explanation|
|--- | ---|
|item | file that was analyzed|
|detection recall  \% | overall percentage that was found (out of the total in the human annotation), summing across all   classes|
|relevant | number of frames that were in the human to be found|
|relevant retrieved | number of speech frames (ie anything but SIL) that were correctly   detected|



## Derived metrics

It contains three files:

- key_child_voc_file_level.csv: For each file (i.e., 1- or 2-minute-long annotation), statistics on the LENA and human child vocalization counts, child segment counts, turn counts, as well as overall and mean duration
- key_child_voc_child_level.csv: The same but summing at the child level- key_child_voc_corpora_level.csv: The same but summing at the corpus level


They all have the following fields (except for the last field, available for file and child level, but not corpora level):

|field name | explanation|
|--- | ---|
|filename | chunk file name|
|gold_CV_cum_dur | according to the human annotation, cumulative duration of child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying)|
|gold_CV_mean | according to the human annotation, mean duration of individual child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying)|
|gold_CV_count | according to the human annotation, total number of individual child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying)|
|gold_short_CV_count | according to the human annotation, total number of individual child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying) that are shorter than 600 ms in length|
|gold_CNV_cum_dur | according to the human annotation, cumulative duration of child   vocalizations classified as laughing or crying|
|gold_CNV_mean | according to the human annotation, mean duration of individual child   vocalizations classified as laughing or crying|
|gold_CNV_count | according to the human annotation, total number of individual child   vocalizations classified as laughing or crying|
|gold_short_CNV_count | according to the human annotation, total number of individual child   vocalizations classified as laughing or crying that are shorter than 600 ms   in length|
|gold_CTC_count | according to the human annotation, total number of turns involving one   voc by the child that contains at least some linguistic material (canonical   or non-canonical) and one voc by an adult, in either order|
|lena_CV_count | according to the lena annotation, cumulative duration of child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying)|
|lena_CNV_count | according to the lena annotation, mean duration of individual child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying)|
|lena_short_CV_count | according to the lena annotation, total number of individual child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying)|
|lena_short_CNV_count | according to the lena annotation, total number of individual child   vocalizations classified as canonical or non-canonical (i.e. excludes   laughing or crying) that are shorter than 600 ms in length|
|lena_CV_mean | according to the lena annotation, cumulative duration of child   vocalizations classified as laughing or crying|
|lena_CNV_mean | according to the lena annotation, mean duration of individual child   vocalizations classified as laughing or crying|
|lena_CV_cum_dur | according to the lena annotation, total number of individual child   vocalizations classified as laughing or crying|
|lena_CNV_cum_dur | according to the lena annotation, total number of individual child   vocalizations classified as laughing or crying that are shorter than 600 ms   in length|
|lena_CTC_count | according to the lena annotation, total number of turns involving one voc   by the child that contains at least some linguistic material (canonical or   non-canonical) and one voc by an adult, in either order|
|child_id | child id for ACLEW, child id + recording date for tsimane|
