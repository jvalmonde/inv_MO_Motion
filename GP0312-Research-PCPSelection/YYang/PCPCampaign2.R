library(data.table)
library(savvy)
library(xtable)
library(survival)

#### 2 Phone messages ----
all_dat=data.table(read.odbc("PCPdoe",dbQuery='select * from [pdb_AllSavers_PCPSelection].[dbo].[TreatmentMembers]'))
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=40,'Older','Younger')]
all_dat<-all_dat[Treatment=="T"& Campaign==2]
all_dat$Block[all_dat$BinAge=="Older"& all_dat$Gendercode=="F"]<-1
all_dat$Block[all_dat$BinAge=="Older"& all_dat$Gendercode=="M"]<-2
all_dat$Block[all_dat$BinAge=="Younger"& all_dat$Gendercode=="F"]<-3
all_dat$Block[all_dat$BinAge=="Younger"& all_dat$Gendercode=="M"]<-4

all_dat<-as.data.frame(all_dat)
PHI<-all_dat[c(11:17,26,28,31)]

head(all_dat)
set.seed(123)
B1<-subset(PHI,Block==1)
B1$tmp<-runif(nrow(B1),0,1)
B1$trt<-ifelse(B1$tmp<=0.5,"trt1","trt2")
B2<-subset(PHI,Block==2)
B2$tmp<-runif(nrow(B2),0,1)
B2$trt<-ifelse(B2$tmp<=0.5,"trt1","trt2")
B3<-subset(PHI,Block==3)
B3$tmp<-runif(nrow(B3),0,1)
B3$trt<-ifelse(B3$tmp<=0.5,"trt1","trt2")
B4<-subset(PHI,Block==4)
B4$tmp<-runif(nrow(B4),0,1)
B4$trt<-ifelse(B4$tmp<=0.5,"trt1","trt2")

total<-rbind(B1,B2,B3,B4)
final<-total[c(-10,-11)]

trt1<-subset(final,trt=="trt1")
trt2<-subset(final,trt=="trt2")

write.csv(trt1,file="trt1.csv")
write.csv(trt2,file="trt2.csv")


