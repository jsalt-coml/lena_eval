# This script must be run from the root folder
# Rscript scripts/extract_stat.r data/gold

library(dplyr, warn.conflicts = FALSE)
library(magrittr) 
library(stringr)
library(stringi)

read_rttm <- function(data_folder) {
  all.files <- list.files(data_folder)
  # All rttm files excluding tsimane ones
  rttm.files <- all.files[grep("*.rttm", all.files) & !startsWith(all.files, 'C') ]
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
      file_data = file_data %>% select(2, 4, 5, 6, 7, 9) %>% rename(filename = V2,
                                       onset = V4,
                                       duration = V5,
                                       transcription = V6,
                                       utt_type = V7,
                                       speaker_type = V9)
      
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
  data[data==""]<-NA
  return(data)
}

get_stats <- function(data){
  # Add age column
  desc = read.csv(file="data/ACLEW_list_of_corpora.csv", header=TRUE, sep=",")
  desc$aclew_id = str_pad(desc$aclew_id, 4, pad=0)
  desc["child_id"] = do.call(paste, c(desc[c("labname", "aclew_id")], sep="_"))
  desc = desc[c("child_id", "age_mo_round")]
  data = merge(data, desc, dby="child_id")
  
  # Child scale
  child_CVC = data %>% 
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'C' | tier_subtype == 'N') %>% 
    group_by(child_id, age_mo_round) %>% 
    summarise(CV_cum_dur = sum(duration, na.rm=TRUE), 
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration))
        
  child_CNVC = data %>% 
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    group_by(child_id, age_mo_round) %>% 
    summarise(CNV_cum_dur = sum(duration, na.rm=TRUE),
              CNV_mean = mean(duration, na.rm=TRUE), 
              CNV_count = length(duration))
  
  # File scale
  file_CVC = data %>% 
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'C' | tier_subtype == 'N') %>% 
    group_by(filename, age_mo_round) %>% 
    summarise(CV_cum_dur = sum(duration, na.rm=TRUE), 
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration))
  
  file_CNVC = data %>% 
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    group_by(filename, age_mo_round) %>% 
    summarise(CNV_cum_dur = sum(duration, na.rm=TRUE),
              CNV_mean = mean(duration, na.rm=TRUE), 
              CNV_count = length(duration))
  
  # Aggregated across child and files
  all_CVC = data %>% 
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'C' | tier_subtype == 'N') %>%
    summarise(CV_cum_dur = sum(duration, na.rm=TRUE), 
              CV_mean = mean(duration, na.rm=TRUE),
              CV_count = length(duration))
  
  all_CNVC = data %>% 
    filter(speaker_type == 'CHI', tier_type == 'vcm', tier_subtype == 'L' | tier_subtype == 'U' | tier_subtype == 'Y') %>%
    summarise(CNV_cum_dur = sum(duration, na.rm=TRUE), 
              CNV_mean = mean(duration, na.rm=TRUE),
              CNV_count = length(duration))
  
  child_stats = merge(child_CVC, child_CNVC)
  file_stats = merge(file_CVC, file_CNVC)
  all_stats = merge(all_CVC, all_CNVC)
  
  stats <- list()
  stats$child = child_stats
  stats$file = file_stats
  stats$all = all_stats
  return(stats)
}


# Read the data
# args = commandArgs(trailingOnly=TRUE)
# if (length(args)!=1) {
#   stop("The folder containg .rttm chunk files must be supplied", call.=FALSE)
# } 

gold_data_folder = "data/gold" #args[1]
gold_data <- read_rttm(gold_data_folder)

# Optional : Just log some info !
# List all the files containing utterances without associated tier (no xds, vcm lex or mwu tier)
contains.na = unique(gold_data[is.na(gold_data['utt_type']), "filename"])
print("Files containing none of the 'xds', 'lex', 'vcm' or 'mwu' tier")
print(as.character(contains.na))

# Compute CVC (vcm of type N and C) and CNVC (vcm of type L, U or Y) at multiple scales
stats <- get_stats(gold_data)

output_folder = paste(getwd(), "evaluations", sep = "/")
write.table(stats$child, file=paste(output_folder, "key_child_voc_child_level.csv", sep="/"), row.names=FALSE)
write.table(stats$file, file=paste(output_folder, "key_child_voc_file_level.csv", sep="/"), row.names=FALSE)
write.table(stats$all, file=paste(output_folder, "key_child_voc_corpora_level.csv", sep="/"), row.names=FALSE)

