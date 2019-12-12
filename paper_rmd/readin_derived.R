#read in files
cvtc <- read.table(paste0(evaldir,"key_child_voc_file_level.csv"),header=T,sep=" ")
cvtc$child=substr(cvtc$filename,1,8)
cvtc$child[substr(cvtc$child,1,1)=="C"]=substr(cvtc$filename[substr(cvtc$child,1,1)=="C"],1,3)
cvtc$cor=substr(cvtc$filename,1,3)
cvtc$cor[substr(cvtc$child,1,1)=="C"]="TSI"
merge(cvtc,age_id,by="child")->cvtc


#AC2EB this may be annoying across labs, let's see...
read.table(paste0("../","LENA_AWC_rel_v1_June.txt"))->awc
colnames(awc)<-c("filename","gold","LENA")
gsub("LUC","ROW",awc$filename)->awc$filename
awc$cor=substr(awc$filename,1,3)
awc$child=substr(awc$filename,1,8)
merge(awc,age_id,by="child")->awc
