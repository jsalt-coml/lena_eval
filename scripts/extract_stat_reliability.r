# This script must be run from the root folder
# Rscript scripts/extract_stat.r data/gold

###### HELPER FUNCTIONS ###### 
library(plyr)
library(dplyr, warn.conflicts = FALSE)
library(magrittr) 
library(stringr)
library(stringi)
library(rlena) #if needed, devtools::install_github("HomeBankCode/rlena", dependencies = TRUE)
library(tidyr)

read_rttm <- function(data_folder) {
  all.files <- list.files(data_folder)
  # All rttm files excluding tsimane ones
  rttm.files <- all.files[endsWith(all.files, '.rttm')]
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
    filename = str_remove(basename(filepath), ".rttm")
    if (info['size'] != 0) {
      file_data = read.csv(file=filepath, header=FALSE, sep="\t")
      file_data = file_data %>% select(2, 4, 5, 6, 7, 8) %>% dplyr::rename(filename = V2,
                                       onset = V4,
                                       duration = V5,
                                       transcription = V6,
                                       utt_type = V7,
                                       speaker_type = V8)
      file_data$filename = filename
      file_data <- data.frame(file_data)
      data <- rbind(data, file_data)
    } else {
      fake_row = data.frame(filename=filename,
                           onset=0,
                           duration=0,
                           transcription="0.",
                           utt_type=NA,
                           speaker_type=NA)
      data <- rbind(data, fake_row)
    }
  }
  #by now, all files have been read in, so data are complete
  # Data post-processing to clean up a bit the tiers.
  data$utt_type <- stringi::stri_replace_all_charclass(data$utt_type, fixed('\\p{WHITE_SPACE}'), '')
  data$utt_type <- stringr::str_replace_all(data$utt_type, '\\.', '')
  
  # Add new columns : tier_type amongst [xds, vcm, mwu, lex]
  data$tier_type = str_sub(data$utt_type,2,4)
  # And tier_subtype being a letter (N,C,L,Y...)
  data$tier_subtype = str_sub(data$utt_type,6,6)
  # Process tsimane file differently
  data[startsWith(data$filename,"C"), "tier_subtype"] = data[startsWith(data$filename,"C"), "utt_type"]
  data[startsWith(data$filename,"C"), "tier_type"] = "vcm"
  data[startsWith(data$filename,"C"), "utt_type"] = "vcm"
  
  data$child_id = str_sub(data$filename,1,8)
  data[substr(data$filename,1,1) == "C", "child_id"] = str_sub(data[substr(data$filename,1,1) == "C", "filename"], 1, 12)
  data$end_time <- data$onset + data$duration
  data[data==""]<-NA
  data[is.na(data)] <- "<NA>" 

  ## Let's count turn-taking in the clearest way as possible
  next_starts = c(data[2:nrow(data), "onset"], 10000)
  prev_ends = data[1:nrow(data), "end_time"]
  less_than_5 = (next_starts - prev_ends) < 5.0
  less_than_5 = c(FALSE, less_than_5[1:length(less_than_5)-1])
  data$less_than_5 = less_than_5

  # invalidate all the rows that are at a point where the file name changes 
  # -- those cannot be turns because they span 2 different files
  change_files = c(data$filename,0) != c(0, data$filename)
  change_files = change_files[1:length(change_files)-1]
  data[change_files, "less_than_5"] = FALSE

  # remap speakers into a clearer list (left are lena-like labels, right are the annotated labels)
  gold_mapping.levels <- list(
    OCH = c('C1', 'C2', 'FC1', 'MC1', 'MC2', 'MC3', 'MI1', 'UC1', 'UC2', 'UC3', 'UC4', 'UC5', 'UC6'),
    FEM = c('FA1', 'FA2', 'FA3', 'FA4', 'FA5', 'FA6', 'FA7', 'FA8', 'MOT*'),
    MAL = c('MA1','MA2', 'MA3', 'MA4', 'MA5'),
    CHI = c('CHI','CHI*'),
    ELE = c('EE1', 'FAE', 'MAE'))
  data$mapped_speaker_type = data$speaker_type
  levels(data$mapped_speaker_type) <- gold_mapping.levels

  # generate vectors containing shifted data, to find previous/next events
  # imagine a point where you have to make a decision whether there is a turn
  # the previous person who spoke from that point is prev_spkr; the next person is next_spkr
  prev_spkr = data[1:nrow(data), "mapped_speaker_type"]
  prev_subtype = data[1:nrow(data), "tier_subtype"]
  # "UNKUNK" is just some random code, to make sure that speaker is not matched with anything
  next_spkr = factor(append(as.character(data[2:nrow(data), "mapped_speaker_type"]), "UNKUNK"))
  next_subtype = factor(append(as.character(data[2:nrow(data), "tier_subtype"]), "UNKUNK"))

  #here are our conditions for whether there is a turn:
  #cond1: if CHI produces a voc before the putative turn, 
  #       and this voc is linguistic (C or N (or W)) 
  #       and the next speaker is male or female adult 
  cond1 = prev_spkr == 'CHI' & (prev_subtype == "C" | prev_subtype == "N" | prev_subtype == "W") & 
    (next_spkr == 'MAL' | next_spkr == 'FEM')
  #cond2: if FEM/MAL produce a voc before the putative turn, 
  #       and the next speaker isCHI 
  #       and this voc is linguistic (C or N (or W)) 
  cond2 = (prev_spkr == 'MAL' | prev_spkr == 'FEM') & 
    next_spkr == 'CHI' & (next_subtype == "C" | next_subtype == "N" | next_subtype == "W")
  data$adult_chi_swipe = cond1 | cond2
  data$turn_taking = data$adult_chi_swipe & data$less_than_5
  data = data[,c(1,2,3,11,12,13,14,4,5,6,7,8,9,10)]
  return(data)
}

get_stats_gold <- function(gold_data){
  CC = gold_data %>%
    filter(speaker_type == 'CHI') %>%
    dplyr::group_by(filename) %>%
    dplyr::summarise(CH_cum_dur = sum(duration, na.rm=TRUE),
                     CH_mean = mean(duration, na.rm=TRUE),
                     CH_count = length(duration))
  
  CVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_subtype == 'C' | tier_subtype == 'N' | tier_subtype == "W") %>%
    dplyr::group_by(filename) %>%
    dplyr::summarise(CV_cum_dur = sum(duration, na.rm=TRUE),
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration),
              short_CV_count = sum(duration < 0.6))

  CNVC = gold_data %>%
    filter(speaker_type == 'CHI', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    dplyr::group_by(filename) %>%
    dplyr::summarise(CNV_cum_dur = sum(duration, na.rm=TRUE),
              CNV_mean = mean(duration, na.rm=TRUE),
              CNV_count = length(duration),
              short_CNV_count = sum(duration < 0.6))

  CTC = gold_data %>% dplyr::group_by(filename) %>%
    dplyr::summarise(CTC_count = sum(turn_taking))

  stats = merge(CVC, CNVC, all = TRUE)
  stats = merge(stats, CC, all = TRUE)
  stats = merge(stats, CTC, all = TRUE)
  stats[is.na(stats)] = 0
  return(stats)
}

###### SCRIPT STARTS HERE ###### 

# Read the data
gold_data1_folder = "data/reliability/gold1/match"
gold_data2_folder = "data/reliability/gold2/match"

gold_data1 <- read_rttm(gold_data1_folder)
gold_data2 <- read_rttm(gold_data2_folder)

# Optional : Just log some info !
# List all the files containing utterances without associated tier (no xds, vcm lex or mwu tier)
only_CHI = gold_data1[gold_data1$mapped_speaker_type == "CHI",]
contains.na = unique(only_CHI %>% dplyr::filter(!tier_subtype %in% c("C", "N", "W", "L", "U", "Y")) %>% select(filename))
print("Files containing not annotated as vcm")
contains.na = contains.na[! is.na(contains.na)]
print(contains.na)

# Remove files that were not annotated with vcm tier for the key child
gold_data1 = gold_data1 %>% dplyr::filter(!filename %in% as.list(contains.na))
gold_data2 = gold_data2 %>% dplyr::filter(!filename %in% as.list(contains.na))

# Compute CVC (vcm of type N and C) and CNVC (vcm of type L, U or Y) at multiple scales
gold_stats1 <- get_stats_gold(gold_data1)
gold_stats2 <- get_stats_gold(gold_data2)

output_folder = paste(getwd(), "reliability_evaluations", sep = "/")

# Cleaning a bit naming convention
colnames(gold_stats1) = paste("gold1", colnames(gold_stats1), sep = "_")
colnames(gold_stats2) = paste("gold2", colnames(gold_stats2), sep = "_")

stats = merge(gold_stats1, gold_stats2, all=TRUE, by.x="gold1_filename", by.y="gold2_filename")
colnames(stats)[colnames(stats) == "gold1_filename"] = "filename"
stats[is.na(stats)] <- 0
stats$child_id <- str_match(stats$filename, "(.*_.*)_.*_.*")[,2]

file = stats
child = stats %>% subset(select = -filename ) %>%
  dplyr::group_by(child_id) %>%
  summarise(gold1_CH_cum_dur = sum(gold1_CH_cum_dur), #ac
            gold1_CH_count = sum(gold1_CH_count), #ac
            gold1_CV_cum_dur = sum(gold1_CV_cum_dur),
            gold1_CV_count = sum(gold1_CV_count),
            gold1_short_CV_count = sum(gold1_short_CV_count),
            gold1_CNV_cum_dur = sum(gold1_CNV_cum_dur),
            gold1_CNV_count = sum(gold1_CNV_count),
            gold1_short_CNV_count = sum(gold1_short_CNV_count),
            gold1_CTC_count = sum(gold1_CTC_count),
            gold2_CH_cum_dur = sum(gold2_CH_cum_dur), #ac
            gold2_CH_count = sum(gold2_CH_count), #ac
            gold2_CV_cum_dur = sum(gold2_CV_cum_dur),
            gold2_CV_count = sum(gold2_CV_count),
            gold2_short_CV_count = sum(gold2_short_CV_count),
            gold2_CNV_cum_dur = sum(gold2_CNV_cum_dur),
            gold2_CNV_count = sum(gold2_CNV_count),
            gold2_short_CNV_count = sum(gold2_short_CNV_count),
            gold2_CTC_count = sum(gold2_CTC_count))
# We have to recompute the mean
child$gold1_CH_mean = child$gold1_CH_cum_dur / child$gold1_CH_count  #ac
child$gold1_CV_mean = child$gold1_CV_cum_dur / child$gold1_CV_count
child$gold1_CNV_mean = child$gold1_CNV_cum_dur / child$gold1_CNV_count
child$gold2_CH_mean = child$gold2_CH_cum_dur / child$gold2_CH_count  #ac
child$gold2_CV_mean = child$gold2_CV_cum_dur / child$gold2_CV_count
child$gold2_CNV_mean = child$gold2_CNV_cum_dur / child$gold2_CNV_count
child[is.na(child)] = 0

all = stats %>% subset(select = -c(filename, child_id))
all = colSums(all)
all = data.frame(as.list(all))
all$gold1_CV_mean = all$gold1_CV_cum_dur / all$gold1_CV_count
all$gold1_CNV_mean = all$gold1_CNV_cum_dur / all$gold1_CNV_count
all$gold2_CV_mean = all$gold2_CV_cum_dur / all$gold2_CV_count
all$gold2_CNV_mean = all$gold2_CNV_cum_dur / all$gold2_CNV_count
write.table(child, file=paste(output_folder, "key_child_voc_child_level.csv", sep="/"), row.names=FALSE)
write.table(file, file=paste(output_folder, "key_child_voc_file_level.csv", sep="/"), row.names=FALSE)
write.table(all, file=paste(output_folder, "key_child_voc_corpora_level.csv", sep="/"), row.names=FALSE)