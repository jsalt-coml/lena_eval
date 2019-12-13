read.csv(paste0(evaldir,"/gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same/ider_report.csv"))->py

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
spreadsheet <- read.csv("metadata_aclew.csv", header=TRUE, sep = ",")
spreadsheet_tsi = read.csv("metadata_tsi.csv", header=TRUE, sep = ",")
spreadsheet_tsi = spreadsheet_tsi[c("id","age_mo")]
colnames(spreadsheet_tsi) = c("child","age")
age_id = rbind(spreadsheet, spreadsheet_tsi)
py=merge(py,age_id,by.x="child",by.y="child",all.x=T)


# [CHI,OCH,MAL,FEM,OVL] // ELE mapped to SIL
read.csv(paste0(evaldir,"gold_no_ele_lena_sil_no_tv_same/ider_report.csv"))->pynotv

pytot=py[,colnames(pynotv)]

# [CHI,OCH,MAL,FEM,OVL,ELE] 
read.csv(paste0(evaldir,"gold_lena_sil_same/ider_report.csv"))->pynotvnoovl

pynotvnoovl$type<-"pynotvnoovl"
pynotv$type<-"pynotv"
pytot$type="pytot"

clean<-function(py){
  py[py$item!="Total",]->py
  py$cor=substr(py$item,1,1)
  py$cor[py$cor=="C"] ="T"
  py
}

allpy= rbind(pytot,pynotv,pynotvnoovl)

clean(allpy)->allpy 