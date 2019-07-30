library(readr)
library(scales)

read.csv("deter_gold_no_ele_lena_sil_no_tv_no_oln_report.csv")->py
py$item=as.character(py$item)
py$item=gsub(".rttm","",py$item)

subset(py,item=="TOTAL")->lenameans
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
py$miss..[py$miss==0 ]<-0


aggregate(py$detection.error.rate..,by=list(py$cor),mean,na.rm=T)->lm
aggregate(py$false.alarm..,by=list(py$cor),mean,na.rm=T)
aggregate(py$miss..,by=list(py$cor),mean,na.rm=T)

read_table("sincnet_20190829.csv",comment="--")->jsalt
summary(jsalt)
colnames(jsalt)[1]<-"item"
colnames(jsalt)<-gsub(" ",".",colnames(jsalt))

subset(jsalt,item=="TOTAL")->sincmeans

#other fixes and addtions
jsalt=subset(jsalt,item!="TOTAL")
jsalt$cor=substr(jsalt$item,1,3)
jsalt$cor[grep("[0-9]",jsalt$cor)]<-"tsi"
jsalt$cor=factor(jsalt$cor)

colnames(jsalt)[colnames(jsalt)=="%"]<-"false.alarm.."
colnames(jsalt)[colnames(jsalt)=="%_1"]<-"miss.."

jsalt$false.alarm..[jsalt$total==0 & jsalt$false.alarm!=0]<-100
jsalt$false.alarm..[jsalt$total==0 & jsalt$false.alarm==0]<-0

jsalt$miss..[jsalt$total==0 ]<-0
jsalt$miss..[jsalt$miss==0 ]<-0

aggregate(jsalt$false.alarm..,by=list(jsalt$cor),mean)
aggregate(jsalt$miss..,by=list(jsalt$cor),mean)
aggregate(jsalt$detection.error.rate,by=list(jsalt$cor),mean)->jm

summary(jsalt)

merge(jsalt,py,by="item")->x
# 3 rows lost only -- strange...

colnames(x)<-gsub(".x","jsalt",colnames(x),fixed=T)
colnames(x)<-gsub(".y","lena",colnames(x),fixed=T)

plot(x$false.alarm..jsalt~x$false.alarm..lena,pch=20,col=alpha("black",.2),xlim=c(0,200),ylim=c(0,200))
plot(density(x$false.alarm..jsalt),xlim=c(0,150))
plot(density(x$false.alarm..lena),xlim=c(0,150),add=T)
y=stack(x[,c("false.alarm..jsalt","false.alarm..lena")])
summary(y)
boxplot(y$values~y$ind)
boxplot(y$values~y$ind,ylim=c(0,100))

y=stack(x[,c("miss..jsalt","miss..lena")])
summary(y)
boxplot(y$values~y$ind)
boxplot(y$values~y$ind,ylim=c(0,100))

y=stack(x[,c("detection.error.rate","detection.error.rate..")])
summary(y)
boxplot(y$values~y$ind)
boxplot(y$values~y$ind,ylim=c(0,100))
library(gplots)
plotmeans(y$values~y$ind,n.label=F,barcol="black")

lm[lm$Group.1!="tsi",]->lm
cbind(lm,jm[,2])->xx
colnames(xx)<-c("cor","lena","jsalt")
barplot(t(xx[,2:3]),beside=T,legend.text=c("LENA","SincNet"),names.arg=(xx[,1]),
        args.legend = list(x = "topleft"))

barplot(colMeans(xx[,2:3]),beside=T,ylim=c(0,70))
