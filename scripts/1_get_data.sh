#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "One parameter is expected : username on the habilis server"
    echo "./scripts/1_get_data.sh acristia"
    exit
fi

# Download ACLEW data
echo "Download ACLEW gold files"
rm -rf data
mkdir data
cd data
rm -f *.eaf
git clone git@github.com:aclew/raw_SOD.git
git clone git@github.com:aclew/raw_WAR.git
git clone git@github.com:aclew/raw_BER.git
git clone git@github.com:aclew/raw_LUC.git
mv raw_LUC raw_ROW

# Process ACLEW data
# Rename something.eaf into corpora_something.eaf
for eaf in */*.eaf; do
    dirname=$(dirname $eaf)
    basename=$(basename $eaf)

    if [[ $dirname =~ rely$ ]]; then
        corpora="${dirname%%_*}"
    else
        corpora="${dirname#*_}"
    fi
    mv $eaf ${dirname}/${corpora}_${basename}
done

mv raw_{SOD,WAR,BER,ROW}/*.eaf .
rm -f SOD_3542-TS.eaf # weird file
rm -rf raw_{SOD,WAR,BER,ROW}
rm -rf gold
mkdir -p gold
cd ..

for eaf in data/*.eaf; do
    eaf=$(basename $eaf)
    python scripts/adjust_timestamps.py data/${eaf} data/gold/
    ret=$?
    if [ $ret == 1 ]; then
        echo "Aborting"
        exit
    fi;
done;

rm -f data/*.eaf

# Download tsimane and LENA data
echo "Downloading tsimane on oberon"
username=$1
mkdir -p data/gold
scp -r ${username}@129.199.81.135:/DATA2T/LENA_eval/data/gold/C* data/gold
scp -r  ${username}@129.199.81.135:/DATA2T/LENA_eval/data/{lena,its} data
