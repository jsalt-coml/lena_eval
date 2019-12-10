all=read.table(paste0(evaldir,"all","_cm.txt"),header=T)

#remove empty rows
all=all[rownames(all)[rowSums(all)>0],]


#reorder rows and cols so that they are more sensible
#rownames(all)
#colnames(all)
all[c("CHI","OCH" ,"FEM" , "MAL" , "ELE", "OVL","SIL"),c("CHN", "CXN", "FAN", "MAN",  "TVN", "OLN", "SIL"  )]->all

sumref=rowSums(all)
