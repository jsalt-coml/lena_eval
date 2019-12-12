# trying to find why correlations dropped between old and current cvtc implementation
evaldir=c("../evaluations/")
cvtc <- read.table(paste0(evaldir,"key_child_voc_file_level.csv"),header=T,sep=" ")

#subset(cvtc,substr(cvtc$filename,1,1)!="C")->cvtc
#cor.test(cvtc$lena_CHN_count,cvtc$gold_CHI_count)

read.table("../LENA_eval_201906/cvtc.txt",header=T)->old
cvtc$filename=as.character(cvtc$filename)
old$filename=gsub(".rttm","",as.character(old$filename))

#filenames of tsi have changed format, now they are zero-padded and have onset & offset
cvtc$filename[substr(cvtc$filename,1,1)=="C"]=
  gsub("_[0-9]*$","",gsub("_0*","_",cvtc$filename[substr(cvtc$filename,1,1)=="C"]))
merge(old,cvtc,by='filename',all=T)->both

# 2 clips for WAR are missing in the OLD but not the NEW
both[is.na(both$CVC_n),"filename"]

#current has 800 rather than 870 lines because several ROW & 1 SOD kids are too old, 
# and do not have vcm
#remove mismatches
both=both[!is.na(both$CVC_n) & !is.na(both$lena_CV_count),]

#lena check
both$dif_lena=abs(both$CVC_n-both$lena_CV_count)
hist(both$dif_lena)
tail(both[order(both$dif_lena),c("CVC_n","lena_CV_count","filename")])
#following up on this revealed the new rttms were right

both$dif_gold=abs(both$CVC_gold-both$gold_CV_count)
hist(both$dif_gold)
tail(both[order(both$dif_gold),c("CVC_gold","gold_CV_count","filename")])
#BER_3895_013440_013560 reality is 42 CHI, of which only 14 are N or C - so indeed 14
# WAR_4995_026700_026820 all 35 CHI are crying

both$corpus=ifelse(substr(both$filename,1,1)=="C","tsi","aclew")
both$dif_gold=both$CVC_gold-both$gold_CV_count
hist(both$dif_gold[both$corpus=="tsi"])
hist(both$dif_gold[both$corpus!="tsi"])
head(both[order(both$corpus,both$dif_gold),c("CVC_gold","gold_CV_count","filename")])
# BER_1618_041040_041160 has 25 chi vocs (in both old and new), so new is right, old is wrong

#bug in tsimane files confirmed, excluding them
both=both[both$corpus=="aclew",]

#check whether correlation for ling CV is lower than that for total CV
cor.test(both$lena_CV_count,both$gold_CV_count)

#the next one is not exactly right because it counts vocs containing both ling and nonling material twice
cor.test((both$lena_CV_count+both$lena_CNV_count),(both$gold_CV_count+both$gold_CNV_count))

#the next one uses CHI counts from the old one, which have some errors
cor.test(both$CVC_n,both$CVC_gold)

