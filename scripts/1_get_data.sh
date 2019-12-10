#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "One parameter is expected : username on the habilis server"
    echo "./scripts/1_get_data.sh acristia"
    exit
fi

username=$1
scp -r ${username}@129.199.81.135:/DATA2T/LENA_eval/data .
