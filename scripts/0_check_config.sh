#!/usr/bin/env bash

pyan_met_v=$(pip show pyannote.metrics | grep "Version")

if [ "$pyan_met_v" == "" ]; then
    echo "pyannote.metrics python package not found"
    echo "either check that the pyannote conda environment has been activated"
    echo "(you can activate it by typing conda activate pyannote or source activate pyannote"
    echo "or check that pyannote.metrics has been installed"
    exit
else
    echo "pyannote.metrics $pyan_met_v" | sed s/V/v/g | sed s/\://g
fi

r_v=$(R --version | grep "R version")
if [ "$r_v" == "" ]; then
    echo "Can't find R software"
    echo "You can check that R is present by typing : R --version"
    exit
else
    echo "$r_v"
fi

r_packages=$(Rscript -e 'installed.packages()')

dplyr_v=$(echo "$r_packages" | grep "dplyr")
magrittr_v=$(echo "$r_packages" | grep "magrittr")
stringr_v=$(echo "$r_packages" | grep "stringr")
stringi_v=$(echo "$r_packages" | grep "stringi")

if [ "$dplyr_v" == "" ]; then
    echo "dplyr R library hasn't been found."
    exit
else
    echo $dplyr_v
fi

if [ "$magrittr_v" == "" ]; then
    echo "dplyr R library hasn't been found."
    exit
else
    echo $magrittr_v
fi

if [ "$stringr_v" == "" ]; then
    echo "stringi R library hasn't been found."
    exit
else
    echo $stringr_v
fi

if [ "$stringi_v" == "" ]; then
    echo "stringi R library hasn't been found."
    exit
else
    echo $stringi_v
fi

echo -e "\n\n"
echo "ALRIGHT ! Everything's good :)"
echo "You can start running ./scripts/1_get_data.sh"