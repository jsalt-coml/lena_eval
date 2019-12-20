#confusion matrix with key speakers only
all=read.table(paste0(evaldir,"all","_cm.txt"),header=T)

#remove empty rows
all=all[rownames(all)[rowSums(all)>0],]


#reorder rows and cols so that they are more sensible
#rownames(all)
#colnames(all)
all[c("CHI","OCH" ,"FEM" , "MAL" , "ELE", "OVL","SIL"),c("CHN", "CXN", "FAN", "MAN",  "TVN", "OLN", "SIL"  )]->all

sumref=rowSums(all)

#confusion matrix with far category
all_far=read.table(paste0(evaldir,"lena_all_all_cm.txt"),header=T)

#remove empty rows
all_far=all_far[rownames(all_far)[rowSums(all_far)>0],]

#merge noise and silence
all_far$Other=all_far$SIL+all_far$NON+all_far$NOF

#reorder rows and cols so that they are more sensible
#rownames(all_far)
#colnames(all_far)
all_far[c("CHI","OCH" ,"FEM" , "MAL" , "ELE", "OVL","SIL"),c("CHN","CHF", "CXN","CXF", "FAN","FAF", "MAN","MAF",  "TVN","TVF", "OLN","OLF", "Other"  )]->all_far
