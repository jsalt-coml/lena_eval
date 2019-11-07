# This script must be run from the root folder
# Rscript scripts/extract_stat.r data/gold
library(plyr)
library(dplyr, warn.conflicts = FALSE)
library(magrittr) 
library(stringr)
library(stringi)
library(rlena)

read_its <- function(data_folder, gold_folder) {
  all.files <- list.files(data_folder)
  its.files <- all.files[endsWith(all.files, '.its')]
  rttm.files <- list.files(gold_folder)
  rttm.files <- rttm.files[endsWith(rttm.files, '.rttm')]

  data <- data.frame()
  for(its in its.files) {
    filepath = paste(data_folder, its, sep="/")
    info = file.info(filepath)
    if (info['size'] != 0) {
      file_data <- gather_segments(read_its_file(filepath))
      child_id = str_replace(its, ".its", "")
      # List of associated rttm to know onset/offset of chunks
      associated.rttm <- rttm.files[grepl(paste0(child_id,'_'), rttm.files)]
      # Read onsets/offsets of gold chunks
      if(startsWith(its, "C")){
        onsets = as.integer(str_match(associated.rttm, ".*_.*_(.*?).rttm")[,2])
        offsets = onsets+60
      } else {
        onsets = as.integer(str_match(associated.rttm, ".*_.*_(.*?)_.*.rttm")[,2])
        offsets = onsets+120
      }
      
      for(i in 1:length(onsets)) {
        onset = onsets[i]
        offset = offsets[i]
        chunk = file_data[file_data$startTime > onset & file_data$startTime < offset, ]
        if(nrow(chunk) != 0) {
          chunk$onset = onset
          chunk$offset = offset
          chunk$child_id = child_id
          chunk = select(chunk, -c("itsId", "startClockTime", "endClockTime", 
                            "startClockTimeLocal", "endClockTimeLocal",
                            "average_dB", "peak_dB"))
          data <- rbind.fill(data, chunk)
        } else {
          print(paste("Nothing found for", child_id, onset, offset, sep = " "))
        }
      }
    }
  }
  
  data <- data %>% filter(spkr == "CHN" | spkr == "MAN" | spkr == "FAN" | spkr == "CXN")
  # columns to paste together
  cols <- c('child_id', 'onset', 'offset')
  # create a new column `filename` with the three columns collapsed together
  data$filename <- apply( data[ ,cols] , 1 , paste0 , collapse = "_" )
  ## Let's count turn-taking in the clearest way as possible
  next_starts = c(data[2:nrow(data), "startTime"], 10000)
  prev_ends = data[1:nrow(data), "endTime"]
  less_than_5 = (next_starts - prev_ends) < 5.0
  less_than_5 = c(FALSE, less_than_5[1:length(less_than_5)-1])
  data$less_than_5 = less_than_5
  
  change_files = c(data$filename,0) != c(0, data$filename)
  change_files = change_files[1:length(change_files)-1]
  data[change_files, "less_than_5"] = FALSE

  
  prev_spkr = data[1:nrow(data), "spkr"]
  next_spkr = factor(append(as.character(data[2:nrow(data), "spkr"]), "UNKUNK"))
  cond1 = prev_spkr == 'CHN' & (next_spkr == 'MAN' | next_spkr == 'FAN')
  cond2 = (prev_spkr == 'MAN' | prev_spkr == 'FAN') & next_spkr == 'CHN'
  data$adult_chi_swipe = cond1 | cond2
  data$turn_taking = data$adult_chi_swipe & data$less_than_5
  return(data)
}

read_rttm <- function(data_folder) {
  all.files <- list.files(data_folder)
  # All rttm files excluding tsimane ones
  rttm.files <- all.files[endsWith(all.files, '.rttm') & !startsWith(all.files, 'C') ]
  # Data structure where we'll store all the annotations
  data <- data.frame(filename = character(),
                     onset = double(),
                     duration = double(),
                     transcription = character(),
                     utt_type = character(),
                     speaker_type = character())
  for(rttm in rttm.files){
    filepath = paste(data_folder, rttm, sep ="/")
    info = file.info(filepath)

    if (info['size'] != 0) {
      file_data = read.csv(file=filepath, header=FALSE, sep="\t")
      file_data = file_data %>% select(2, 4, 5, 6, 7, 8) %>% dplyr::rename(filename = V2,
                                       onset = V4,
                                       duration = V5,
                                       transcription = V6,
                                       utt_type = V7,
                                       speaker_type = V8)

      file_data <- data.frame(file_data)
      data <- rbind(data, file_data)
    }
  }
  # Data post-processing to clean up a bit the tiers.
  data$utt_type <- stringi::stri_replace_all_charclass(data$utt_type, fixed('\\p{WHITE_SPACE}'), '')
  data$utt_type <- stringr::str_replace_all(data$utt_type, '\\.', '')

  # Add new columns : tier_type amongst [xds, vcm, mwu, lex]
  data$tier_type = str_sub(data$utt_type,2,4)
  # And tier_subtype being a letter (N,C,L,Y...)
  data$tier_subtype = str_sub(data$utt_type,6,6)
  data$child_id = str_sub(data$filename,1,8)
  data$end_time <- data$onset + data$duration
  data[data==""]<-NA

  ## Let's count turn-taking in the clearest way as possible
  next_starts = c(data[2:nrow(data), "onset"], 10000)
  prev_ends = data[1:nrow(data), "end_time"]
  less_than_5 = (next_starts - prev_ends) < 5.0
  less_than_5 = c(FALSE, less_than_5[1:length(less_than_5)-1])
  data$less_than_5 = less_than_5

  change_files = c(data$filename,0) != c(0, data$filename)
  change_files = change_files[1:length(change_files)-1]
  data[change_files, "less_than_5"] = FALSE

  # How to map in R
  gold_mapping.levels <- list(
    OCH = c('C1', 'C2', 'FC1', 'MC1', 'MC2', 'MC3', 'MI1', 'UC1', 'UC2', 'UC3', 'UC4', 'UC5', 'UC6'),
    FEM = c('FA1', 'FA2', 'FA3', 'FA4', 'FA5', 'FA6', 'FA7', 'FA8', 'MOT*'),
    MAL = c('MA1','MA2', 'MA3', 'MA4', 'MA5'),
    CHI = c('CHI','CHI*'),
    ELE = c('EE1', 'FAE', 'MAE'))
  data$mapped_speaker_type = data$speaker_type
  levels(data$mapped_speaker_type) <- gold_mapping.levels

  prev_spkr = data[1:nrow(data), "mapped_speaker_type"]
  next_spkr = factor(append(as.character(data[2:nrow(data), "mapped_speaker_type"]), "UNKUNK"))
  cond1 = prev_spkr == 'CHI' & (next_spkr == 'MAL' | next_spkr == 'FEM')
  cond2 = (prev_spkr == 'MAL' | prev_spkr == 'FEM') & next_spkr == 'CHI'
  data$adult_chi_swipe = cond1 | cond2
  data$turn_taking = data$adult_chi_swipe & data$less_than_5
  data = data[,c(1,2,3,11,12,13,14,4,5,6,7,8,9,10)]
  return(data)
}

get_stats_gold <- function(gold_data){
  # Add age column
  desc = read.csv(file="data/ACLEW_list_of_corpora.csv", header=TRUE, sep=",")
  desc$aclew_id = str_pad(desc$aclew_id, 4, pad=0)
  desc["child_id"] = do.call(paste, c(desc[c("labname", "aclew_id")], sep="_"))
  desc = desc[c("child_id", "age_mo_round")]
  gold_data = merge(gold_data, desc, dby="child_id")

  # Child scale
  child_CVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'C' | tier_subtype == 'N') %>%
    dplyr::group_by(child_id, age_mo_round) %>%
    dplyr::summarise(CV_cum_dur = sum(duration, na.rm=TRUE),
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration))

  child_CNVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    dplyr::group_by(child_id, age_mo_round) %>%
    dplyr::summarise(CNV_cum_dur = sum(duration, na.rm=TRUE),
              CNV_mean = mean(duration, na.rm=TRUE),
              CNV_count = length(duration))

  child_CTC = gold_data %>% dplyr::group_by(child_id, age_mo_round) %>%
    dplyr::summarise(CTC_count = sum(turn_taking))

  # File scale
  file_CVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'C' | tier_subtype == 'N') %>%
    dplyr::group_by(filename, age_mo_round) %>%
    dplyr::summarise(CV_cum_dur = sum(duration, na.rm=TRUE),
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration))

  file_CNVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    dplyr::group_by(filename, age_mo_round) %>%
    dplyr::summarise(CNV_cum_dur = sum(duration, na.rm=TRUE),
              CNV_mean = mean(duration, na.rm=TRUE),
              CNV_count = length(duration))

  file_CTC = gold_data %>% dplyr::group_by(filename, age_mo_round) %>%
    dplyr::summarise(CTC_count = sum(turn_taking))

  # Aggregated across child and files
  all_CVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'C' | tier_subtype == 'N') %>%
    dplyr::summarise(CV_cum_dur = sum(duration, na.rm=TRUE),
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration))

  all_CNVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    dplyr::summarise(CNV_cum_dur = sum(duration, na.rm=TRUE),
              CNV_mean = mean(duration, na.rm=TRUE),
              CNV_count = length(duration))
  all_CTC = gold_data %>% dplyr::summarise(CTC_count = sum(turn_taking))

  child_stats = merge(child_CVC, child_CNVC)
  child_stats = merge(child_stats, child_CTC)
  file_stats = merge(file_CVC, file_CNVC)
  file_stats = merge(file_stats, file_CTC)
  all_stats = merge(all_CVC, all_CNVC)
  all_stats = merge(all_stats, all_CTC)

  stats <- list()
  stats$child = child_stats
  stats$file = file_stats
  stats$all = all_stats
  return(stats)
}

get_stats_its <- function(its_data){
  # Add age column
  desc = read.csv(file="data/ACLEW_list_of_corpora.csv", header=TRUE, sep=",")
  desc$aclew_id = str_pad(desc$aclew_id, 4, pad=0)
  desc["child_id"] = do.call(paste, c(desc[c("labname", "aclew_id")], sep="_"))
  desc = desc[c("child_id", "age_mo_round")]
  desc$child_id = str_match(desc$child_id, "_(.*)")[,2]
  its_data = merge(its_data, desc, dby="child_id")

  # Child level statistics
  child_level = its_data %>% filter(spkr == "CHN") %>%
    dplyr::group_by(child_id, age_mo_round) %>%
    dplyr::summarise(CV_cum_dur = sum(childUttLen, na.rm = TRUE),
              CV_mean = mean(childUttLen, na.rm = TRUE),
              CV_count = sum(childUttLen > 0, na.rm = TRUE),
              CNV_cum_dur = sum(childCryVfxLen, na.rm = TRUE),
              CNV_mean = mean(childCryVfxLen, na.rm = TRUE),
              CNV_count = sum(childCryVfxLen > 0, na.rm = TRUE))
  child_CTC = its_data %>% dplyr::group_by(child_id, age_mo_round) %>%
    dplyr::summarise(CTC_count = sum(turn_taking))
  
  # File level statistics
  file_level = its_data %>% filter(spkr == "CHN") %>%
    dplyr::group_by(filename, age_mo_round) %>% 
    dplyr::summarise(CV_cum_dur = sum(childUttLen, na.rm = TRUE),
              CV_mean = mean(childUttLen, na.rm = TRUE),
              CV_count = sum(childUttLen > 0, na.rm = TRUE),
              CNV_cum_dur = sum(childCryVfxLen, na.rm = TRUE),
              CNV_mean = mean(childCryVfxLen, na.rm = TRUE),
              CNV_count = sum(childCryVfxLen > 0, na.rm = TRUE))
  file_CTC = its_data %>% dplyr::group_by(filename, age_mo_round) %>%
    dplyr::summarise(CTC_count = sum(turn_taking))
  
  # Aggregated across all
  all_level = its_data %>% filter(spkr == "CHN") %>% 
    dplyr::summarise(CV_cum_dur = sum(childUttLen, na.rm = TRUE),
              CV_mean = mean(childUttLen, na.rm = TRUE),
              CV_count = sum(childUttLen > 0, na.rm = TRUE),
              CNV_cum_dur = sum(childCryVfxLen, na.rm = TRUE),
              CNV_mean = mean(childCryVfxLen, na.rm = TRUE),
              CNV_count = sum(childCryVfxLen > 0, na.rm = TRUE))
  all_CTC = its_data %>% dplyr::summarise(CTC_count = sum(turn_taking))
  
  child_stats = merge(child_level, child_CTC)
  file_stats = merge(file_level, file_CTC)
  all_stats = merge(all_level, all_CTC)

  stats <- list()
  stats$child = child_stats
  stats$file = file_stats
  stats$all = all_stats
  return(stats)
}

# Read the data
lena_its_folder = "data/its/lena"
gold_data_folder = "data/gold"
its_data <- read_its(lena_its_folder, gold_data_folder)

gold_data_folder = "data/gold"
gold_data <- read_rttm(gold_data_folder)

# Optional : Just log some info !
# List all the files containing utterances without associated tier (no xds, vcm lex or mwu tier)
contains.na = unique(gold_data[is.na(gold_data['utt_type']), "filename"])
print("Files containing none of the 'xds', 'lex', 'vcm' or 'mwu' tier")
print(as.character(contains.na))

# Compute CVC (vcm of type N and C) and CNVC (vcm of type L, U or Y) at multiple scales
gold_stats <- get_stats_gold(gold_data)

lena_stats <- get_stats_its(its_data)


output_folder = paste(getwd(), "evaluations", sep = "/")
write.table(gold_stats$child, file=paste(output_folder, "gold_key_child_voc_child_level.csv", sep="/"), row.names=FALSE)
write.table(gold_stats$file, file=paste(output_folder, "gold_key_child_voc_file_level.csv", sep="/"), row.names=FALSE)
write.table(gold_stats$all, file=paste(output_folder, "gold_key_child_voc_corpora_level.csv", sep="/"), row.names=FALSE)
write.table(lena_stats$child, file=paste(output_folder, "lena_key_child_voc_child_level.csv", sep="/"), row.names=FALSE)
write.table(lena_stats$file, file=paste(output_folder, "lena_key_child_voc_file_level.csv", sep="/"), row.names=FALSE)
write.table(lena_stats$all, file=paste(output_folder, "lena_key_child_voc_corpora_level.csv", sep="/"), row.names=FALSE)