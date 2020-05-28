# LENA evaluation

These instructions are mostly aimed at ACLEW team members who are trying to regenerate the data. If you do not belong to the ACLEW team, most likely you will not be able to do some of these steps, which require access to the raw original data, which is currently not shared with the world.

If you are an ACLEW team member, you may be in the Paris team or elsewhere. If in the Paris team, your best bet is to do this process in oberon. If you are elsewhere, you will need to get in touch with the Paris team to have access to the server with the data. In addition, you will do the pre-requisite steps to make sure you create the environment needed for the analysis in your local server.

In all cases, start by cloning (and moving to) this repository by typing:

```bash
git clone https://github.com/jsalt-coml/lena_eval.git
cd lena_eval
```


## Prerequisites (if reproducing *inside* oberon)

# Activate the environment (this command should be run each time you open a new terminal !)
# might be *source activate lena_eval* depending on how you set up conda
conda activate lena_eval



## Prerequisites (if reproducing *outside* oberon)


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

## Get the data 

REMEMBER, only possible if you are an ACLEW member with access to habilis and to the ACLEW project in github.

To download necessary data, you can launch:

```bash
./scripts/1_get_data.sh <habilis_username>
```

where <habilis_username> is the username of your habilis account. 
The script will ask you to type your password.

This will download ACLEW and Tsimane files:  all the GOLD rttms, all the LENA its files (in their full length, as well as in the chunked format). GOLD are the human-made annotations; the lena-made annotations are .its. Both of these have been converted into .rttm in a process not covered here (see historians section at bottom of this file).

You can check that you downloaded all the files by typing :

```bash
ls data/{gold,lena}/*.rttm | wc -l
```

which will count the number of files in the **data/gold** and **data/lena** folders and should return **1744** = (600 aclew files + 272 tsimane files) * 2.

You can also count the number of its files by typing : 

```bash
ls data/its/lena/*.its | wc -l
```

which should return **57** = 40 aclew files + 17 tsimane files.
If you don't have the right number of files, you should check that you have access to the git ACLEW repos, and to oberon.

## Run the evaluations

You can run all the evaluations by typing:

```bash
./scripts/2_evaluate.sh
```

This will take a bit of time (but probably less than 10 mn ! Go get yourself a cup of coffee...)


## Run the reliability study

First, you must download the reliability data :

```bash
./scripts/1_get_reliability_data.sh
```

This will download all the needed folders from the [git ACLEW repo](https://github.com/aclew/).
Your git account must have been configured for ssh connnections (see [here](https://build-me-the-docs-please.readthedocs.io/en/latest/Using_Git/SetUpSSHForGit.html))

Then, you can run the reliability study by typing : 

```bash
./scripts/2_reliability.sh
```

This will generate the results in the _**reliability_evaluations**_ folder.

## Understanding the results

All the steps described above are generating something in the _**evaluations**_ folder.

### Identification Error Rate 

You can type: 

```bash
tail -1 evaluations/gold_lena_sil_same/ider_report.csv
```

and you should get:

```bash
item,identification error rate %,total,correct,correct %,false alarm,false alarm %,missed detection,missed detection %,confusion,confusion %
TOTAL,123.87,24664.27,8860.30,35.92,14748.43,59.80,5469.55,22.18,10334.42,41.90
```

Which gives you the **identification error rate** aggregated over all of the files for the classes [CHI, OCH, MAL, FEM, ELE, OVL].

Or: 

```bash
tail -1 evaluations/gold_lena_sil_same/only_CHI_deter_report.csv
```

gives you:

```bash
TOTAL,82.90,5881.48,1912.53,32.52,2963.21,50.38
```

which is the detection error rate aggregated over all of the files for the **CHI** class.
The second folder indicates the mapping that has been used for running the evaluations:

- gold_lena_sil_same for when the classes have been mapped to [CHI, OCH, MAL, FEM, ELE, OVL].
- gold_no_ele_lena_sil_no_tv_same for when ELE has been mapped to SIL
- gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same for when ELE and OVL have been mapped to SIL.

### Confusion Matrices
You can also type:

```bash
head -5 evaluations/all_cm.txt
```

that should return:

```bash
"CHN" "FAN" "OLN" "SIL" "CXN" "TVN" "MAN"
"CHI" 292047 19167 115415 70443 67488 23664 1529
"FEM" 29041 288019 250749 207098 38179 42612 36886
"SIL" 102053 85137 652443 4888170 71942 521342 38700
"OVL" 35929 49562 111186 24663 22517 14193 11967
```

which is the confusion matrix over all of the files, obtained by considering "N" classes of LENA annotations files.
Results are also available at the corpora scale - TSI, BER, ROW, WAR, SOD -.

### Vocalization statistics

You can type:

```bash
head -5 evaluations/evaluations/gold_key_child_voc_child_level.csv
```

You should get:

```bash
"child_id" "CV_cum_dur" "CV_mean" "CV_count" "CNV_cum_dur" "CNV_mean" "CNV_count" "CTC_count"
"BER_0396" 147.024 0.986738255033557 149 25.211 1.80078571428571 14 71
"BER_1196" 189.982 0.922242718446602 206 2.942 2.942 1 31
"BER_1618" 52.272 0.843096774193548 62 11.889 1.69842857142857 7 47
"BER_1844" 76.787 1.37119642857143 56 57.291 3.8194 15 73
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
