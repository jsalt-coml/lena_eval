read.csv("deter_gold_no_ele_lena_sil_no_tv_no_oln_report.csv")->py

#other fixes and addtions
py=subset(py,item!="TOTAL")
py$cor=substr(py$item,1,3)
py$cor[grep("[0-9]",py$cor)]<-"tsi"
py$cor=factor(py$cor)

py$child=substr(py$item,1,8)
py$child[py$cor=="tsi"]=substr(py$item[py$cor=="tsi"],1,3)

py$false.alarm..[py$total==0 & py$false.alarm!=0]<-100
py$false.alarm..[py$total==0 & py$false.alarm==0]<-0

py$miss..[py$total==0 ]<-0

aggregate(py$detection.error.rate..,by=list(py$cor),mean,na.rm=T)
aggregate(py$false.alarm..,by=list(py$cor),mean,na.rm=T)
aggregate(py$miss..,by=list(py$cor),mean,na.rm=T)
