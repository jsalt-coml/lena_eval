I've attached a .zip containing MATLAB scripts that go from ACLEW R3 annotations (as MATLAB .mat files, included in /annofiles/ subfolder; see end of the message for format) and .its files to LENA AWC performance measures ("getLENAbaselines.m"). 

The package also includes my scripts ("ACLEWstarterCleanupLongConservative.m") to clean up the orthos of the annotations before performance measurement (essentially discarding everything else than unambiguously transcribed words). We checked with Marvin (or was it with Julien?) that the corresponding python script he developed leads to very similar ortho transcripts after the cleanup than my MATLAB cleanup. 

The actual numbers used in the WCE paper are included in .mat file "LENA_baselines.mat". 

The pipeline from .eaf to .mat is basically ELAN --> manual convert to .TextGrid --> parsing the TextGrid files into a MATLAB struct & in parallel splitting the daylong audios into the corresponding 2/5min chunks that were annotated (the codes use at least 3 separate functions; I can share the full chain if you think its useful). Note that no data discarding/refinement should take place anywhere during that conversion, but the contents of the .mat file should be the same as in the original .eafs (just different format). 

Let me know if you have any questions!

I'll work on the other points you listed today/tomorrow/early next week.

BR,
Okko

---------------

The format of each .mat files is as follows:


              utterance: {150×1 cell}        <-- full utterance transcripts for each of the 150 signals
      t_onset_utterance: {150×1 cell}  <-- utterance onset timestamps
     t_offset_utterance: {150×1 cell} < -- utterance offset timestamps
    talker_id_utterance: {150×1 cell} <-- talker IDs of utterances
                  words: {150×1 cell}     <-- words in each utterance as a cell array
              addressee: {150×1 cell}  <-- addressee tags of utterances
               filename: {150×1 cell}   <-- filenames of the utterances (e.g., /local_path/LUC_1156_001980_002100.wav)
              syllables: {1×150 cell}    <-- syllables in each utterance
            n_syllables: {1×150 cell} <-- number of syllables per utterance

where each of the 150 cell entries is another cell array corresponding to the number of utterances in that recording. The number of utterances per 2 or 5 min recording should be an exact match with the number of speaker turns in the .eaf files. 