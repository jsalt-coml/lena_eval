# trying to find why correlations dropped between old and current cvtc implementation

read.table("../LENA_eval_201906/cvtc.txt",header=T)->old
cvtc$filename=as.character(cvtc$filename)
old$filename=gsub(".rttm","",as.character(old$filename))

#filenames of tsi have changed format, now they are zero-padded and have onset & offset
cvtc$filename[substr(cvtc$filename,1,1)=="C"]=
  gsub("_[0-9]*$","",gsub("_0*","_",cvtc$filename[substr(cvtc$filename,1,1)=="C"]))
merge(old,cvtc,by='filename',all=T)->both

# 2 clips for WAR are missing
both[is.na(both$CVC_n),"filename"]

#current has 800 rather than 870 lines because several ROW & 1 SOD kids are too old, and do not have vcm
