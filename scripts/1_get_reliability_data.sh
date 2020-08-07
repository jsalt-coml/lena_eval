#!/usr/bin/env bash

mkdir -p data/reliability

# Get data from github aclew repo
cd data/reliability
git clone git@github.com:aclew/raw_SOD.git
git clone git@github.com:aclew/SOD_rely.git
git clone git@github.com:aclew/raw_WAR.git
git clone git@github.com:aclew/WAR_rely.git
git clone git@github.com:aclew/raw_ROS.git
git clone git@github.com:aclew/ROS_rely.git
git clone git@github.com:aclew/raw_TSE.git
git clone git@github.com:aclew/TSE_rely.git
git clone git@github.com:aclew/raw_LUC.git
git clone git@github.com:aclew/ROW_rely.git
git clone git@github.com:aclew/raw_BER.git
git clone git@github.com:aclew/BER_rely.git

# Fix folder name
mv raw_LUC raw_ROW

# Move {SOD,WAR,LUC,ROW}_rely/Random_Sampling to {SOD,WAR,LUC,ROW}/
# (to go back to previous repository organisation)
for eaf in *_rely/Random_Sampling/*.eaf; do
    dirname=$(dirname $(dirname $eaf))
    basename=$(basename $eaf)
    mv $eaf $dirname/$basename
done;


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

mv */*.eaf .
rm -rf gold{1,2}
mkdir -p gold1/eaf gold2/eaf
mv *_rely_*.eaf gold2/eaf
mv *.eaf gold1/eaf
rm -rf raw_*
rm -rf *_rely
