# Set up pyannote-metrics environment

conda create --name pyannote-lena python=3.6
source activate pyannote-lena 
in mac

however, in oberon, this is:
conda activate pyannote-lena

pip install pyannote-metrics

# After having activated pyannote-lena environment
## Map the labels
## You can change the mapping in labels_mapper.py
## The -o option indicates if overlapping classes need to be aggregated as being "OVL"

python labels_mapper.py -p lena/ -m lena
python labels_mapper.py -p gold/ -m gold -o

## Evaluate lena performances (should not be run in the frontnode)
# With -t being the task (identification, diarization or detection)
# -m being the list of metrics
python compute_metrics.py -ref gold/mapped/ -hyp lena/mapped/ -t diarization -m diaer coverage homogeneity completeness purity

--> This script will output the performances tables in the standard output + will generate .csv files in the gold/mapped directory.
