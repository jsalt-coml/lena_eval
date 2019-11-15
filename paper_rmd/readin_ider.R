read.csv(paste0(thisdir,"/gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same/ider_report.csv"))->py
#dim(py) #873 clips
#summary(py)

#294 FA, MI, confusion are NA because no speech at all in the clip
pytot=subset(py,item=="TOTAL")
#other fixes and addtions
py=subset(py,item!="TOTAL")
py$false.alarm..[py$total==0 & py$false.alarm!=0]<-100
py$false.alarm..[py$total==0 & py$false.alarm==0]<-0
py$missed.detection..[py$total==0 ]<-0
py$missed.detection..[py$missed.detection==0 ]<-0
py$cor=substr(py$item,1,3)
py$cor[grep("[0-9]",py$cor)]<-"TSI"
py$cor=factor(py$cor)

py$child=substr(py$item,1,8)
py$child[py$cor=="TSI"]=substr(py$item[py$cor=="TSI"],1,3)

# add in age info
spreadsheet = read.csv(paste0("../ACLEW_list_of_corpora.csv"), header=TRUE, sep = ",")
spreadsheet$child=paste0(spreadsheet$labname,"_",ifelse(nchar(spreadsheet$aclew_id)==3,paste0("0",spreadsheet$aclew_id),spreadsheet$aclew_id))
spreadsheet = spreadsheet[,c("child","age_mo_round")]
colnames(spreadsheet) = c("child","age")
spreadsheet_tsi = read.csv(paste0("../anon_metadata.csv"), header=TRUE, sep = ",")
spreadsheet_tsi = spreadsheet_tsi[c("id","age_mo")]
colnames(spreadsheet_tsi) = c("child","age")
age_id = rbind(spreadsheet, spreadsheet_tsi)
py=merge(py,age_id,by.x="child",by.y="child",all.x=T)