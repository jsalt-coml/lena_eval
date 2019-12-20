read.csv(paste0(evaldir,"/gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same/ider_report.csv"))->py


# [CHI,OCH,MAL,FEM,OVL] // ELE mapped to SIL
read.csv(paste0(evaldir,"gold_no_ele_lena_sil_no_tv_same/ider_report.csv"))->pyWtv

# [CHI,OCH,MAL,FEM,OVL,ELE] 
read.csv(paste0(evaldir,"gold_lena_sil_same/ider_report.csv"))->pyWtvWov

pyWtvWov$type<-"WtvWov"
pyWtv$type<-"Wtv"
py$type="main"


allpy= rbind(py,pyWtv,pyWtvWov)



#other fixes and additions 
allpy$false.alarm..[allpy$total==0 & allpy$false.alarm!=0]<-100
allpy$false.alarm..[allpy$total==0 & allpy$false.alarm==0]<-0
allpy$missed.detection..[allpy$total==0 ]<-0
allpy$missed.detection..[allpy$missed.detection==0 ]<-0

#and for the one that will be used in the regression
py=allpy[allpy$item!="TOTAL" & allpy$type=="main",]

py$cor=substr(py$item,1,3)
py$cor[grep("[0-9]",py$cor)]<-"TSI"
py$cor=factor(py$cor)

py$child=substr(py$item,1,8)
py$child[py$cor=="TSI"]=substr(py$item[py$cor=="TSI"],1,3)

# add in age info
spreadsheet <- read.csv("metadata_aclew.csv", header=TRUE, sep = ",")
spreadsheet_tsi = read.csv("metadata_tsi.csv", header=TRUE, sep = ",")
spreadsheet_tsi = spreadsheet_tsi[c("id","age_mo")]
colnames(spreadsheet_tsi) = c("child","age")
age_id = rbind(spreadsheet, spreadsheet_tsi)
py=merge(py,age_id,by.x="child",by.y="child",all.x=T)
