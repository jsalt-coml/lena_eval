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

mv */*.eaf .
mkdir -p gold1/eaf gold2/eaf
mv rely_*.eaf gold2/eaf
mv *.eaf gold1/eaf
rm -rf raw_*
rm -rf *_rely
