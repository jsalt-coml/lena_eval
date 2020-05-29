


thisdir=c("../LENA_eval_201906/")
library(lme4)
library(sm)
library(scales)
library(ggpubr)
library(ggplot2)
library(car)
library(dplyr)
library(kableExtra)

dodiv=function(x) x/sum(x, na.rm=T)


read.csv(paste0(thisdir,"../evaluations/gold_no_ele_no_ovl_lena_sil_no_tv_no_oln_same/ider_report.csv"))->py
#other fixes and addtions
py=subset(py,item!="TOTAL")
py$cor=substr(py$item,1,3)
py$cor[grep("[0-9]",py$cor)]<-"TSI"
py$cor=factor(py$cor)

py$child=substr(py$item,1,8)
py$child[py$cor=="TSI"]=substr(py$item[py$cor=="TSI"],1,3)

py$false.alarm..[py$total==0 & py$false.alarm!=0]<-100
py$false.alarm..[py$total==0 & py$false.alarm==0]<-0

py$missed.detection..[py$total==0 ]<-0
py$missed.detection..[py$missed.detection==0 ]<-0

# add in age info
spreadsheet = read.csv(paste0("../ACLEW_list_of_corpora.csv"), header=TRUE, sep = ",")
spreadsheet$child=paste0(spreadsheet$labname,"_",ifelse(nchar(spreadsheet$aclew_id)==3,paste0("0",spreadsheet$aclew_id),spreadsheet$aclew_id))
spreadsheet = spreadsheet[,c("child","age_mo_round")]
colnames(spreadsheet) = c("child","age")
spreadsheet_tsi = read.csv(paste0("../anon_metadata.csv"), header=TRUE, sep = ",")
spreadsheet_tsi = spreadsheet_tsi[c("id","age_mo")]
colnames(spreadsheet_tsi) = c("child","age")
age_id = rbind(spreadsheet, spreadsheet_tsi)
py=merge(py,age_id,by.x="child",by.y="child",all.x=T) #one row is lost... **ATTENTION BUG HERE**

mydv=c("false.alarm..","missed.detection..","confusion..")

subset(py,cor=="TSI")->py


mean(py$identification.error.rate..)
bychild=aggregate(py$identification.error.rate..,list(py$child,py$cor,py$age),median,na.rm=T)

#bychild$jitter=as.numeric(bychild$Group.3)+(as.numeric(bychild$Group.2)/8-mean(as.numeric(bychild$Group.2)/8))
mycols=c("blue","darkgreen","black","gray","purple")

names(mycols)<-levels(factor(bychild$Group.2))
plot(bychild$x~bychild$Group.3,ylim=range(0,115),pch=20,xlab="Age in months",ylab="Identification error rate",col="black")


all=read.table(paste0(thisdir,"../evaluations/TSI","_cm.txt"),header=T)
#generate version with collapsed data
colapall=all
# Old version with FAR
#colapall$Other=all$FAF+all$CHF+all$CXF+all$MAF+all$OLN+all$OLF+all$TVN+all$TVF+all$SIL
# New version without FAR
colapall$NonSpeech=all$OLN+all$TVN+all$SIL
# Old version
# colapall["SIL",]<-colapall["SIL",]+colapall["OVL",]+colapall["ELE",]
# New version : we map all overlapping classes to SIL
colapall["NonSpeech",]<-colapall["SIL",]+colapall["OVL",]+colapall["ELE",]+colSums(all[which(grepl("/", rownames(all))),])
colapall[c("FEM","CHI","OCH","MAL","NonSpeech"),c("CHN","FAN","MAN","CXN","NonSpeech")]->colapall
#rownames(colapall)[5]<-"NonSpeech"
colnames(colapall)[1:4]<-c("CHI","FEM","MAL","OCH")
colapall=colapall[,c(2,1,4,3,5)]

prop_cat=data.frame(apply(colapall,2,dodiv)*100) #generates precision because columns
#colSums(prop_cat)
stack(colapall)->stcolapall
colnames(stcolapall)<-c("n","LENA")
stcolapall$human=factor(rownames(colapall),levels=c("FEM","CHI","OCH","MAL","NonSpeech"))
stcolapall$pr=stack(prop_cat)$values

pdf("prec.pdf",height=12,width=15)
ggplot(data = stcolapall, mapping = aes(y = stcolapall$human, x=stcolapall$LENA)) +
  geom_tile(aes(fill= rescale(stcolapall$pr)), colour = "white") +
  geom_text(aes(label = paste(round(stcolapall$pr),"%")), vjust = -1,size=8) +
  geom_text(aes(label = stcolapall$n), vjust = 1,size=8) +
  scale_fill_gradient(low = "white", high = "red", name = "Proportion") +
  xlab("LENA(R)") + ylab("Human")+ 
  theme(text = element_text(size = 30))
dev.off()

prop_cat=data.frame(apply(colapall,1,dodiv)*100) #generates recall because rows
#colSums(prop_cat)
stack(colapall)->stcolapall
colnames(stcolapall)<-c("n","LENA")
stcolapall$human=factor(rownames(colapall),levels=c("FEM","CHI","OCH","MAL","NonSpeech"))
stcolapall$pr=stack(prop_cat)$values


pdf("rec.pdf",height=12,width=15)
ggplot(data = stcolapall, mapping = aes(y = stcolapall$human, x=stcolapall$LENA)) +
  geom_tile(aes(fill= rescale(stcolapall$pr)), colour = "white") +
  geom_text(aes(label = paste(round(stcolapall$pr),"%")), vjust = -1,size=8) +
  geom_text(aes(label = stcolapall$n), vjust = 1,size=8) +
  scale_fill_gradient(low = "white", high = "red", name = "Proportion") +
  xlab("LENA(R)") + ylab("Human") + 
  theme(text = element_text(size = 30))
dev.off()
