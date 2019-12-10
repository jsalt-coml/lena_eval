This README.md will give you a step-by-step guide to run the LENA evaluation.

## Prerequisites and Data downloading

Please follow the *__Prerequisites__* and *__Get the data steps__* from the main [README](../README.md)

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
- Mapping choices for the lena files are **[lena_sil, lena_sil_no_tv,lena_sil_no_tv_no_oln]**.
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
BER_0396_005220_005340.rttm,134.26,27.04,19.13,70.73,28.39,104.99,2.73,10.08,5.19,19.18
```

where the first line describes the header, and the second line contains metrics for the *BER_0396_005220_005340.rttm* file.
One can display the last line by typing :

```bash
tail -1 evaluations/gold_lena_sil/diaer_report.csv
```

and should get :

```bash
TOTAL,140.71,24664.56,11962.99,48.50,22004.18,89.21,2278.74,9.24,10422.83,42.26
```

This line contains the metrics aggregated across all of the files, and therefore describes general performances of the LENA model.

## Computing confusion matrices

We start by generating frame-based *.rttm* files to transform our problem into a classification task.

```bash
python scripts/frame_cutter.py  --i data/lena/mapped_lena_sil/ --o framed_lena_sil
python scripts/frame_cutter.py  --i data/gold/mapped_gold/ --o framed_gold
```

This will generate a **framed** sub-folder in both **lena** and **gold** folders containing the framed-based rttm. 

Once it has been done, we can generate the confusion matrices by typing:

```bash
Rscript scripts/conf_mat.r data/lena/framed_lena_sil data/gold/framed_gold
```

This step might take a bit of time, go get yourself a cup of coffee !
Once it's done, the script will save the confusion matrices under **data/gold/framed_gold**.

Let's repatriate these files :

```bash
mv data/gold/framed_gold/*.txt evaluations/gold_lena_sil
```

We can print the first 3 lines of one of these confusion matrices by typing : 

```bash
head -3 evaluations/gold_lena_sil/SOD_cm.txt
```

This should return : 

```bash
"CHN" "FAN" "OLF" "OLN" "SIL" "CHF" "CXF" "CXN" "FAF" "MAF" "TVF" "TVN" "MAN"
"CHI" 40830 2453 2626 23320 3324 266 982 18567 439 1250 1966 5125 147
"FEM" 12841 75210 21495 74932 22831 225 3135 12364 10245 7545 8809 18640 7536
```

With the first line being the LENA labels. 
The first row (without considering its first element) are the gold labels.
And cell(i,j) = number of frames annotated as class_i but classified by the model as class_j 


