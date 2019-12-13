args<-commandArgs(TRUE)

# Parse parameters
if (length(args)<2) {
  stop("lena and gold folders must be provided by the user", call.=FALSE)
} else {
  # default output file
  lena_folder = args[1]
  gold_folder = args[2]
  reliability=FALSE
  if(args[3] == "reliability"){
    reliability=TRUE
  }
}

# First, we start to list all the labels that appear in gold and lena files.
# print("Reading gold and lena labels ...")
gold_levels=c()
filenames = list.files(gold_folder, pattern = "*.rttm")
for (filename in filenames){
  rttm_path = paste(gold_folder, filename, sep="/")
  rttm = read.csv(rttm_path, header=FALSE, sep = "\t")[c(4,5,8)]
  gold_levels = c(gold_levels, levels(unique(unlist(rttm[3]))))
  gold_levels = unique(gold_levels)
}

lena_levels=c()
filenames = list.files(lena_folder, pattern = "*.rttm")
for (filename in filenames){
  rttm_path = paste(lena_folder, filename, sep="/")
  rttm = read.csv(rttm_path, header=FALSE, sep = "\t")[c(4,5,8)]
  lena_levels = c(lena_levels, levels(unique(unlist(rttm[3]))))
  lena_levels = unique(lena_levels)
}

# Sort the levels, so that the matrices will be easier to read
gold_levels = gold_levels[order(nchar(gold_levels))]
lena_levels = lena_levels[order(nchar(lena_levels))]

#print("Gold labels found :")
#print(gold_levels)
#print("Lena labels found :")
#print(lena_levels)

corpora = c("BER", "ROW", "SOD","WAR","TSI")
if(reliability){
  corpora= c("BER", "ROW", "WAR", "SOD", "TSE", "ROS")
}

# Let's start by listing the files

confusion_all <- matrix(0, nrow=length(gold_levels), ncol=length(lena_levels))
colnames(confusion_all) <- lena_levels
rownames(confusion_all) <- gold_levels
for(corpus in corpora){
  # List filenames
  filenames = list.files(lena_folder, pattern = "*.rttm")

  if(corpus=="TSI") {
    corpus_filenames = filenames[substr(filenames,1,1) == "C"]
  } else {
    corpus_filenames = filenames[substr(filenames,1,3) == corpus]
  }

  # Create confusion matrices
  confusion_corp <- matrix(0, nrow=length(gold_levels), ncol=length(lena_levels))
  colnames(confusion_corp) <- lena_levels
  rownames(confusion_corp) <- gold_levels

  for(filename in corpus_filenames){
    lena_path = paste(lena_folder, filename, sep="/")
    gold_path = paste(gold_folder, filename, sep="/")

    # The LENA always exist
    lena = read.csv(lena_path, header=FALSE, sep = "\t")[c(4,5,8)]
    names(lena) <- c("onset", "duration", "label")

    if(file.exists(gold_path)){
      gold = read.csv(gold_path, header=FALSE, sep = "\t")[c(4,5,8)]
      names(gold) <- c("onset", "duration", "label")
    } else {
      gold = lena # we make a copy to have the same N of lines
      gold["label"] = "SIL"
    }

    # Fasten your seat belts !
    # The idea is to one-hot encode the labels.
    # Since they are time-aligned, we can compute the confusion matrix by a simple matrix multiplication.
    # We must add a fake factor since model.matrix drops the first factor
    gold = factor(gold[["label"]], levels = c("",gold_levels))
    lena = factor(lena[["label"]], levels = c("",lena_levels))

    gold_mat = model.matrix(~gold)[,-1]
    lena_mat = model.matrix(~lena)[,-1]

    if(nrow(lena_mat) != nrow(gold_mat)){
      print(paste0(filename, " has a different number of rows its lena version, and its gold one."))
    }

    confusion_file = t(gold_mat) %*% lena_mat
    confusion_corp = confusion_corp + confusion_file

  }
  #print(corpus)
  #print(confusion_corp)
  if(corpus != ""){
    write.table(confusion_corp,file=paste(gold_folder,paste0(corpus,"_cm.txt"), sep = "/"))
  }
  confusion_all = confusion_all + confusion_corp
  #print(paste0("Nb frames : ", sum(rowSums(confusion_corp)))) # nb frames
}
#print("All")
#print(confusion_all)
write.table(confusion_all,file=paste(gold_folder, "all_cm.txt", sep="/"))
print("Done computing confusion matrix.")