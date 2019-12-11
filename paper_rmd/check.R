# trying to find why correlations dropped between old and current cvtc implementation
evaldir=c("../evaluations/")
cvtc <- read.table(paste0(evaldir,"key_child_voc_file_level.csv"),header=T,sep=" ")

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

both$dif_lena=abs(both$CVC_n-both$lena_CV_count)
hist(both$dif_lena)
tail(both[order(both$dif),c("CVC_n","lena_CV_count","filename")])
