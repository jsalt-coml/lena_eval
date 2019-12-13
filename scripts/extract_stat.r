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
        onsets = as.integer(str_match(associated.rttm, ".*_.*_(.*?)_.*.rttm")[,2])
        offsets = onsets+60
      } else {
        onsets = as.integer(str_match(associated.rttm, ".*_.*_(.*?)_.*.rttm")[,2])
        offsets = onsets+120
      }
      
      for(i in 1:length(onsets)) {
        onset = onsets[i]
        offset = offsets[i]
        chunk = file_data[file_data$endTime > onset & file_data$startTime < offset, ]
        chunk[chunk$startTime < onset, "startTime"] = onset
        chunk[chunk$endTime > offset, "offset"] = offset

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
  
  data <- data %>% filter(spkr == "CHN" | spkr == "CHF" | spkr == "MAN" | spkr == "FAN" | spkr == "CXN") #ac added CHF for CVC/CTC counts
  # columns to paste together
  cols <- c('child_id', 'onset', 'offset')
  data$onset = str_pad(data$onset, 6, pad = "0")
  data$offset = str_pad(data$offset, 6, pad = "0")
  # create a new column `filename` with the three columns collapsed together
  data$filename <- apply(data[ ,cols] , 1 , paste0 , collapse = "_" )
  data$filename <- gsub(' ', '0', data$filename)
  return(data)
}

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
  #ac added whole block above

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

get_stats_its <- function(its_data){
  # Convert timestamp format to float
  starts_cries = colnames(its_data)[str_detect(colnames(its_data), regex("startCry*"))]
  ends_cries = colnames(its_data)[str_detect(colnames(its_data), regex("endCry*"))]
  starts_utts = colnames(its_data)[str_detect(colnames(its_data), regex("startUtt*"))]
  ends_utts = colnames(its_data)[str_detect(colnames(its_data), regex("endUtt*"))]
  all_timestamps = c(starts_cries,ends_cries,starts_utts, ends_utts, "startVfx1", "endVfx1")
  its_data[,all_timestamps] = apply(its_data[,all_timestamps], 2, function(x) gsub("PT|S", "",x))
  its_data$dur=its_data$endTime-its_data$startTime #ac
    
  # Replace NA timestamps by 0
  na_to_0 = rep(0, length(all_timestamps))
  names(na_to_0) = all_timestamps
  na_to_0 = as.data.frame(t(na_to_0))
  its_data = tidyr::replace_na(its_data, na_to_0)

  # Count duration of voc and cries 
  for (i in 1:length(starts_cries)){
    name_dur = paste0("durCry", i)
    name_start = paste0("startCry", i)
    name_end = paste0("endCry", i)
    its_data[name_dur] = as.numeric(its_data[[name_end]])-as.numeric(its_data[[name_start]])
  }
  
  for (i in 1:length(starts_utts)){
    name_dur = paste0("durUtt", i)
    name_start = paste0("startUtt", i)
    name_end = paste0("endUtt", i)
    its_data[name_dur] = as.numeric(its_data[[name_end]])-as.numeric(its_data[[name_start]])
  }
  
  # Count number of cries/vegetative/fixed for each segment
  its_data$cryCnt = rowSums((its_data %>% dplyr::select(matches("startCry*|startVfx*"))) != 0)
  
  # Compute counts 
  counts = its_data %>% dplyr::group_by(filename) %>% 
    filter(spkr == "CHN" | spkr == "CHF") %>% #ac added CHF for CVC/CTC counts
    dplyr::summarise(CH_count = length(spkr), CV_count = sum(childUttCnt), CNV_count = sum(cryCnt))
  #ac added CH_count = length(spkr), 
  
  # Compute sums
  sums = its_data %>% dplyr::group_by(filename) %>% 
    filter(spkr == "CHN" | spkr == "CHF") %>% #ac added CHF for CVC/CTC counts
    dplyr::summarise(CH_cum_dur = sum(dur), CV_cum_dur = sum(childUttLen), CNV_cum_dur = sum(childCryVfxLen))
  #ac added CH_cum_dur = sum(dur),  
  
  # Compute means (should be done at the end)
  means = data.frame(counts$filename, sums$CH_cum_dur/counts$CH_count,  sums$CV_cum_dur/counts$CV_count,  sums$CNV_cum_dur/counts$CNV_count)
  #ac added sums$CH_cum_dur/counts$CH_count, 
  means[is.na(means)] <- 0
  names(means) = c("filename", "CH_mean", "CV_mean", "CNV_mean")
  
  # Compute short vocalizations
  short_counts = its_data %>% dplyr::group_by(filename) %>% 
    filter(spkr == "CHN" | spkr == "CHF") %>% #ac added CHF for CVC/CTC counts
    dplyr::summarise(short_CV_count = sum(durUtt1 < 0.6 & durUtt1 != 0)+sum(durUtt2 < 0.6 & durUtt2 != 0)+
                                       sum(durUtt3 < 0.6 & durUtt3 != 0)+sum(durUtt4 < 0.6 & durUtt4 != 0)+
                                       sum(durUtt5 < 0.6 & durUtt5 != 0)+sum(durUtt6 < 0.6 & durUtt6 != 0)+
                                       sum(durUtt7 < 0.6 & durUtt7 != 0 )+sum(durUtt8 < 0.6 & durUtt8 != 0)+
                                       sum(durUtt9 < 0.6 & durUtt9 != 0)+sum(durUtt10 < 0.6 & durUtt10 != 0)+
                                       sum(durUtt11 < 0.6 & durUtt11 != 0),
                                     short_CNV_count = sum(durCry1 < 0.6 & durCry1 != 0)+sum(durCry2 < 0.6 & durCry2 != 0)+
                                       sum(durCry3 < 0.6 & durCry3 != 0)+sum(durCry4 < 0.6 & durCry4 != 0)+
                                       sum(durCry5 < 0.6 & durCry5 != 0)+sum(durCry6 < 0.6 & durCry6 != 0)+
                                       sum(durCry7 < 0.6 & durCry7 != 0)+sum(durCry8 < 0.6 & durCry8 != 0)+
                                       sum(durCry9 < 0.6 & durCry9 != 0)+sum(durCry10 < 0.6 & durCry10 != 0)+
                                       sum(durCry11 < 0.6 & durCry11 != 0)+sum(durCry12 < 0.6 & durCry12 != 0)+
                                       sum(durCry13 < 0.6 & durCry13 != 0))
                                                      
  CTC = its_data %>% dplyr::group_by(filename) %>% 
    dplyr::summarise(CTC_count = sum(convTurnType != "NT", na.rm=TRUE))

  stats = merge(counts, short_counts, all=TRUE)
  stats = merge(stats, means, all=TRUE)
  stats = merge(stats, sums, all=TRUE)
  stats = merge(stats, CTC, all=TRUE)
  stats[is.na(stats)] = 0
  return(stats)
}

###### SCRIPT STARTS HERE ###### 

# Read the data
lena_its_folder = "data/its/lena"
gold_data_folder = "data/gold"
its_data <- read_its(lena_its_folder, gold_data_folder)

gold_data_folder = "data/gold"
gold_data <- read_rttm(gold_data_folder)

# Optional : Just log some info !
# List all the files containing utterances without associated tier (no xds, vcm lex or mwu tier)
only_CHI = gold_data[gold_data$mapped_speaker_type == "CHI",]
contains.na = unique(only_CHI[only_CHI['tier_type'] != "vcm", "filename"])
contains.na = contains.na[! is.na(contains.na)]
print("Files not annotated as vcm")
print(as.character(contains.na))

# Remove files that were not annotated with vcm tier for the key child
gold_data = gold_data[! gold_data$filename %in% contains.na,]
its_data = its_data[! its_data$filename %in% contains.na,]

# Compute CVC (vcm of type N and C) and CNVC (vcm of type L, U or Y) at multiple scales
gold_stats <- get_stats_gold(gold_data)
lena_stats <- get_stats_its(its_data)

output_folder = paste(getwd(), "evaluations", sep = "/")

# Cleaning a bit naming convention
colnames(gold_stats) = paste("gold", colnames(gold_stats), sep = "_")
colnames(lena_stats) = paste("lena", colnames(lena_stats), sep = "_")

stats = merge(gold_stats, lena_stats, all=TRUE, by.x="gold_filename", by.y="lena_filename")
colnames(stats)[colnames(stats) == "gold_filename"] = "filename"
stats[is.na(stats)] <- 0
stats$child_id <- str_match(stats$filename, "(.*_.*)_.*_.*")[,2]

file = stats
child = stats %>% subset(select = -filename ) %>%
  dplyr::group_by(child_id) %>%
  summarise(gold_CH_cum_dur = sum(gold_CH_cum_dur), #ac
            gold_CH_count = sum(gold_CH_count), #ac
            gold_CV_cum_dur = sum(gold_CV_cum_dur),
            gold_CV_count = sum(gold_CV_count),
            gold_short_CV_count = sum(gold_short_CV_count),
            gold_CNV_cum_dur = sum(gold_CNV_cum_dur),
            gold_CNV_count = sum(gold_CNV_count),
            gold_short_CNV_count = sum(gold_short_CNV_count),
            gold_CTC_count = sum(gold_CTC_count),
            lena_CH_cum_dur = sum(lena_CH_cum_dur), #ac
            lena_CH_count = sum(lena_CH_count), #ac
            lena_CV_cum_dur = sum(lena_CV_cum_dur),
            lena_CV_count = sum(lena_CV_count),
            lena_short_CV_count = sum(lena_short_CV_count),
            lena_CNV_cum_dur = sum(lena_CNV_cum_dur),
            lena_CNV_count = sum(lena_CNV_count),
            lena_short_CNV_count = sum(lena_short_CNV_count),
            lena_CTC_count = sum(lena_CTC_count))
# We have to recompute the mean
child$gold_CH_mean = child$gold_CH_cum_dur / child$gold_CH_count  #ac
child$gold_CV_mean = child$gold_CV_cum_dur / child$gold_CV_count
child$gold_CNV_mean = child$gold_CNV_cum_dur / child$gold_CNV_count
child$lena_CH_mean = child$lena_CH_cum_dur / child$lena_CH_count  #ac
child$lena_CV_mean = child$lena_CV_cum_dur / child$lena_CV_count
child$lena_CNV_mean = child$lena_CNV_cum_dur / child$lena_CNV_count
child[is.na(child)] = 0

all = stats %>% subset(select = -c(filename, child_id))
all = colSums(all)
all = data.frame(as.list(all))
all$gold_CV_mean = all$gold_CV_cum_dur / all$gold_CV_count
all$gold_CNV_mean = all$gold_CNV_cum_dur / all$gold_CNV_count
all$lena_CV_mean = all$lena_CV_cum_dur / all$lena_CV_count
all$lena_CNV_mean = all$lena_CNV_cum_dur / all$lena_CNV_count
write.table(child, file=paste(output_folder, "key_child_voc_child_level.csv", sep="/"), row.names=FALSE)
write.table(file, file=paste(output_folder, "key_child_voc_file_level.csv", sep="/"), row.names=FALSE)
write.table(all, file=paste(output_folder, "key_child_voc_corpora_level.csv", sep="/"), row.names=FALSE)
