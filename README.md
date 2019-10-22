# LENA evaluation

First, you can clone (and move to) this repository by typing :

```bash
git clone https://github.com/jsalt-coml/lena_eval.git
cd lena_eval
```

## Data downloading & sanity check

For **oberon** users, data can be found under **/scratch1/projects/LENA_eval_Marvin/data**. Type the following command to download the **data** :

```bash
rsync -rzvvPL /scratch1/projects/LENA_eval_Marvin/data .
```

This folder contains three sub-folders called :
- **rttm** containing the human-made annotations.
- **lena** containing the lena-made annotations.
- **wav** containing the audio files.
Once the data have been downloaded, we can verify that everything went smoothly by checking the number of files :

```bash
CORPUS=("BER" "ROW" "SOD" "WAR" "C");
for CORPORA in ${CORPUS[*]}; do 
    NB_GOLDS=$(find data/gold/${CORPORA}*.rttm | wc -l);
    NB_LENAS=$(find data/lena/${CORPORA}*.rttm | wc -l);
    NB_AUDIOS=$(find data/wav/${CORPORA}*.wav | wc -l);
    echo "$CORPORA : ${NB_GOLDS} / ${NB_LENAS} / ${NB_AUDIOS}";      
done;
```

The output should EXACTLY be (under the format **CORPORA : NB_GOLDS/NB_LENAS/NB_AUDIOS** ) :

```bash
BER : 150 / 150 / 150
ROW : 150 / 150 / 150
SOD : 150 / 150 / 150
WAR : 150 / 150 / 150
```

## Creating the conda environment

Make sure that [pip](https://pypi.org/project/pip/) and [conda](https://docs.conda.io/en/latest/) are installed.
Now, we can create the [conda](https://docs.conda.io/en/latest/) environment containing all the necessary python packages.

```bash
# Create environment
conda create --name lena-eval python=3.6

# Activate the environment (this command should be run each time you open a new terminal !)
# might be *source activate lena-eval* depending on how you set up conda
conda activate lena-eval

# Install necessary packages
pip install pyannote-metrics
```

## Computing performance metrics

Let us get down to business !

1) Map the labels :

```bash
python scripts/labels_mapper.py -p data/lena/ -m lena_sil
python scripts/labels_mapper.py -p data/gold/ -m gold -o
```

This will create :
- a **mapped_lena_sil** sub-folder in the **lena** folder
- a **mapped_gold** in the gold folder.

The parameter **-m** describes the desired mapping :
- Mapping choices for the lena files are **[lena_far, lena_sil, lena_sil_no_tv,lena_sil_no_tv_no_oln]**.
- Mapping choices for the gold files are **[gold, gold_no_ele]**.

If provided, the **-o** option is responsible for mapping to "OVL" moments where two speakers are speaking at the same time (shouldn't be the case in LENA files).

2) Compute the metrics :

```bash
python scripts/compute_metrics.py -ref data/gold/mapped_gold -hyp data/lena/mapped_lena_sil -t diarization -m diaer coverage homogeneity completeness purity
```

This will list all pairs that have been found between the human-made and the lena-made files (150 pairs).
It will also generate *.csv files containing the evaluations in the *data/gold/mapped_gold/gold_no_ele_lena_sil* folder.
Let's repatriate these files :

```bash
mkdir evaluations
mv data/gold/mapped_gold/gold_lena_sil evaluations
```

If we display the 2 first lines of one of these files by typing :

```bash
head -2 evaluations/gold_lena_sil/diaer_report.csv
```

we should get :

```bash
item,diarization error rate %,total,correct,correct %,false alarm,false alarm %,missed detection,missed detection %,confusion,confusion %
BER_0396_005220_005340.rttm,95.96,27.04,19.13,70.73,18.03,66.70,3.21,11.88,4.70,17.39
```

where the first line describes the header, and the second line contains metrics for the *BER_0396_005220_005340.rttm* file.
One can display the last line by typing :

```bash
tail -1 evaluations/gold_lena_sil/diaer_report.csv
```

and should get :

```bash
TOTAL,113.70,24664.56,11369.63,46.10,14747.86,59.79,5469.27,22.17,7825.66,31.73
```

This line contains the metrics aggregated across all of the files, and therefore describes general performances of the LENA model.

## Computing confusion matrices


##### Alex notes :
TODO
4. Pick up again from the beginning: how does one go from full rec to clip annotation for ACLEW, and for tsi?
5. Replace tsi its with real ones
6. Rerun whole
7. Update results
8. Talk with Okko, set up reproducible pipeline for AWC