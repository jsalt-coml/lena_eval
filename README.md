# LENA evaluation

This github accompanies "A thorough evaluation of the Language Environment Analysis(LENA) system", published in Behavior Research Methods in 2020.

## Contents

- AWC: record of the system needed to go from the raw files (not shared here) to the AWC lena & gold estimates (contact Okko Räsänen for more details)- data: data necessary to reproduce our analyses from scratch- DIHARD_comparison: file used to generate numbers from the dihard 2019 challenge reported on in the paper- evaluations: intermediate files produced while reproducing the paper from scratch, these are all that is needed to reproduce the manuscript itself- LENA_AWC_rel_v1_June.txt: AWC lena & gold estimates- paper_rmd: contains the r markdown version of the paper- README.md: the present file- reliability_evaluations: file used to generate numbers from the ACLEW reliability reported on in the paper- scripts: scripts needed to go from the raw files (not shared here) to the data in data/ (contact Alejandrina Cristia or Marvin Lavechin for more details)

## Reproduction instructions

These instructions are mostly aimed at ACLEW team members who are trying to regenerate the data. If you do not belong to the ACLEW team, most likely you will not be able to do some of these steps, which require access to the raw original data, which is currently not shared with the world.

If you are an ACLEW team member, you may be in the Paris team or elsewhere. If in the Paris team, your best bet is to do this process in oberon. If you are elsewhere, you will need to get in touch with the Paris team to have access to the server with the data. In addition, you will do the pre-requisite steps to make sure you create the environment needed for the analysis in your local server.

In all cases, start by cloning (and moving to) this repository by typing:

```bash
git clone https://github.com/jsalt-coml/lena_eval.git
cd lena_eval
```


### Prerequisites (if reproducing *inside* oberon)

* Activate the environment (this command should be run each time you open a new terminal !)
* might be *source activate lena_eval* depending on how you set up conda
conda activate lena_eval



### Prerequisites (if reproducing *outside* oberon)


Make sure that [pip](https://pypi.org/project/pip/), [conda](https://docs.conda.io/en/latest/) and [R](https://www.r-project.org/) are installed on your system.
Once everything has been installed, we can create the [conda](https://docs.conda.io/en/latest/) environment containing all the necessary python packages.

```bash
# Create environment
conda create --name lena_eval python=3.6

# Activate the environment (this command should be run each time you open a new terminal !)
# might be *source activate lena_eval* depending on how you set up conda
conda activate lena_eval

# Install necessary packages
pip install pyannote-metrics
pip install pympi-ling ipdb
```

You must also verify that [R](https://www.r-project.org/) is installed and have the following packages: dplyr, magrittr, stringr, stringi, and [rlena](https://github.com/HomeBankCode/rlena).
Once you installed everything, you can check that everything went well by launching:

```bash
./scripts/0_check_config.sh
```

which will tell you either what's missing if something's missing or if everything's went as expected.

### Get the data 

REMEMBER, only possible if you are an ACLEW member with access to habilis and oberon!

To download necessary data, you can launch:

```bash
./scripts/1_get_data.sh <habilis_username>
```

where <habilis_username> is the username of your habilis account. 
The script will ask you to type your password.

This will download ACLEW and Tsimane files:  all the GOLD rttms, all the LENA its files (in their full length, as well as in the chunked format). GOLD are the human-made annotations; the lena-made annotations are .its. Both of these have been converted into .rttm in a process not covered here (see historians section at bottom of this file).

### Run the evaluations

You can run all the evaluations by typing:

```bash
./scripts/2_evaluate.sh
```

This will take a bit of time (but probably less than 10 mn ! Go get yourself a cup of coffee...)


### Run the reliability study

First, you must download the reliability data :

```bash
./scripts/1_get_reliability_data.sh
```

This will download all the needed folders from the [git ACLEW repo](https://github.com/aclew/).
Your git account must have been configured for ssh connections (see [here](https://build-me-the-docs-please.readthedocs.io/en/latest/Using_Git/SetUpSSHForGit.html))

Then, you can run the reliability study by typing : 

```bash
./scripts/2_reliability.sh
```

This will generate the results in the _**reliability_evaluations**_ folder.

### Understanding the results

All the steps described above are generating something in the _**evaluations**_ folder.

#### Identification Error Rate 

You can type: 

```bash
tail -1 evaluations/gold_lena_sil_same/ider_report.csv
```

and you should get:

```bash
item,identification error rate %,total,correct,correct %,false alarm,false alarm %,missed detection,missed detection %,confusion,confusion %
TOTAL,123.87,24667.36,8862.20,35.93,14749.43,59.79,5473.64,22.19,10331.52,41.88
```

Which gives you the **identification error rate** aggregated over all of the files for the classes [CHI, OCH, MAL, FEM, ELE, OVL].

Or: 

```bash
tail -1 evaluations/gold_lena_sil_same/only_CHI_deter_report.csv
```

gives you:

```bash
TOTAL,82.90,5879.50,1912.75,32.53,2961.46,50.37
```

which is the detection error rate aggregated over all of the files for the **CHI** class.
The second folder indicates the mapping that has been used for running the evaluations:

- gold_lena_sil_same for when the classes have been mapped to [CHI, OCH, MAL, FEM, ELE, OVL].
- gold_no_ele_lena_sil_no_tv_same for when ELE has been mapped to SIL
- gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same for when ELE and OVL have been mapped to SIL.

#### Confusion Matrices
You can also type:

```bash
head -5 evaluations/all_cm.txt
```

that should return:

```bash
"CHN" "FAN" "OLN" "SIL" "CXN" "TVN" "MAN"
"CHI" 291804 19105 114897 69738 67304 23583 1519
"FEM" 29032 288176 250495 206558 38153 42581 36941
"SIL" 102520 85623 654048 4890321 72284 521608 38860
"OVL" 36133 49651 111847 24854 22735 14252 11955
"ELE" 1431 7355 23714 130184 9567 41415 4869
"MAL" 3849 16638 52653 58645 2375 27592 72435
"OCH" 18310 14809 78075 57385 80543 12215 1364

```

which is the confusion matrix over all of the files, obtained by considering "N" classes of LENA annotations files.
Results are also available at the corpora scale - TSI, BER, ROW, WAR, SOD -.

#### Vocalization statistics

You can type:

```bash
head -5 evaluations/evaluations/key_child_voc_child_level.csv
```

You should get:

```bash
child_id gold_CH_cum_dur gold_CH_count gold_CV_cum_dur gold_CV_count gold_short_CV_count gold_CNV_cum_dur gold_CNV_count gold_short_CNV_count gold_CTC_count lena_CH_cum_dur lena_CH_count lena_CV_cum_dur lena_CV_count lena_short_CV_count lena_CNV_cum_dur lena_CNV_count lena_short_CNV_count lena_CTC_count gold_CH_mean gold_CV_mean gold_CNV_mean lena_CH_mean lena_CV_mean lena_CNV_mean
BER_0396 172.3 163 147.09 149 63 25.21 14 3 64 131.14 102 54.04 59 22 64.57 53 4 15 1.057 0.987 1.801 1.286 0.916 1.218
BER_1196 192.9 207 189.97 206 77 2.94 1 0 31 96.25 93 43.32 54 19 35.32 46 17 7 0.932 0.922 2.940 1.035 0.802 0.768
BER_1618 64.1 69 52.24 62 24 11.90 7 0 45 31.02 30 6.63 9 3 21.53 22 7 5 0.930 0.843 1.700 1.034 0.737 0.979
BER_1844 134.1 71 76.79 56 6 57.29 15 2 49 22.39 26 10.85 14 3 9.09 12 2 3 1.888 1.371 3.819 0.861 0.775 0.757
```

*CV* stands for canonical vocalizations.
*CNV* stands non canonical voocalizations.
For each of these vocalizations, you have its number, its cumulated duration, and its average duration.
*CTC_count* correspond to the number of conversational turn-takings.

Similar files exist across multiples scales, at the scale of the child, the file, or aggregated across all of the files.
You'll also find similar files for the LENA system.

## Historians, look here

If you would like to look back at the earliest stages of data processing, here are the key paths. (These are only accessible to team members.)

- ACLEW data are annotated in .eaf format, stored in raw_* on the ACLEW github
- They are next processed by Julien's pipeline, then the resulting rttm are stored on habilis in `/DATA2T/aclew_data_update/ACLEW_data/databrary_ACLEW`. These are the rttms in data/gold here
- ACLEW's .its are archived on databrary - do a search for its in the component name
- Tsimane data are annotated in textgrid format, in oberon in:  `/scratch1/projects/ac_lacie01/STRUCTURE/tsimane2017_recordings/data/C*/derived/*m1.TextGrid`
- The script that goes from textgrid to rttm is from DiViMe
