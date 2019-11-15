all=read.table(paste0(thisdir,"all","_cm.txt"),header=T)

#remove empty rows
all=all[rownames(all)[rowSums(all)>0],]

#collapse overlap in gold
#row 4 is called "OVL" - it contains info on all the overlaps
#remove all cols with "/" which contain the broken down info on overlaps
all[-c(grep("/",rownames(all))),]->all

#reorder rows and cols so that they are more sensible
#rownames(all)
#colnames(all)
all[c("CHI" ,"FEM" , "MAL" ,"OCH", "ELE", "OVL","SIL"),c("CHN", "FAN", "MAN", "CXN",  "TVN", "OLN", "SIL"  )]->all

sumref=rowSums(all)