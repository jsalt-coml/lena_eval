 read.csv("../LENA_eval_201906/gold/diaer_lena_sil.csv")->pysil
 read.csv("../LENA_eval_201906/gold/diaer_lena_far.csv")->pyfar
 read.csv("../LENA_eval_201906/gold/diaer_gold_no_ele_lena_sil_no_tv_report.csv")->pynotv
 read.csv("../LENA_eval_201906/gold/diaer_gold_no_ele_lena_sil_no_tv_no_oln_report.csv")->pynooln
 
pysil$type<-"pysil"
pyfar$type<-"pyfar"
pynotv$type<-"pynotv"
pynooln$type<-"pynooln"

clean<-function(py){
  py[py$item!="Total",]->py
  py$cor=substr(py$item,1,1)
  py$cor[py$cor=="C"] ="T"
  py
}

py= rbind(pysil,pyfar,pynotv,pynooln)

clean(py)->py 
 
medians=aggregate(py[,c("false.alarm..","missed.detection..","confusion..")],by=list(py$cor,py$type),median,na.rm=T)

write.table(medians,"medians.txt")
