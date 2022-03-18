#####################

## exploration of patients with depression/RA

library(savvy)
library(forecast)

data.member <- read.odbc("devsql10", dbQuery = "SELECT *
                         FROM pdb_PharmaMotion.dbo.Member_v2", as.is = TRUE)

data.membersum<-read.odbc("devsql10", dbQuery = "SELECT *
                         FROM pdb_PharmaMotion.dbo.MemberSummary_v2", as.is = TRUE)

data.druguse <- read.odbc("devsql10", dbQuery = "SELECT *
                        FROM pdb_PharmaMotion.dbo.MemberSummaryDrugClassAllw_v2", as.is = TRUE)

data.depRA <- read.odbc("devsql10", dbQuery = "SELECT *
                        FROM pdb_PharmaMotion.dbo.MemberSummary_Depression_RA", as.is = TRUE)

data.total1 <- merge(data.membersum, data.member, by=c("MemberID", "PolicyID", "SystemID"), all=T)
data.total2<-merge(data.total1, data.druguse, by=c("MemberID", "YearMo"), all.x=T)
data.total3<-merge(data.total2, data.depRA, by=c("MemberID", "YearMo"), all.x=T)


data.total<-data.total3[data.total3$Enrl_Plan.x==1,]
data.total<-data.total[data.total$Age>17,]


rm(list=c("data.total1", "data.total2", "data.total3", "data.membersum", "data.member", "data.druguse"))


#######################

all.ids<-unique(sort(data.total$MemberID))
healthy.ids<-unique(sort(data.total$MemberID[data.total$RA_Flag.x==0&data.total$Depressed_Flag.x==0]))
dep.ids<-unique(sort(data.total$MemberID[data.total$Depressed_Flag.x==1]))
ra.ids<-unique(sort(data.total$MemberID[data.total$RA_Flag.x==1]))
ra.dep.ids<-unique(sort(data.total$MemberID[data.total$RA_Flag.x==1&data.total$Depressed_Flag.x==1]))
enrl.ids<-unique(sort(data.total$MemberID[data.total$WithSteps==1]))
#some overlap between depression and RA, 285 of 107739 members

data.total$RxDepression_Allow<-as.numeric(data.total$RxDepression_Allow)
data.total$RxDepression_Allow[is.na(data.total$RxDepression_Allow)]<-0

data.total$RxRA_Allow<-as.numeric(data.total$RxRA_Allow)
data.total$RxRA_Allow[is.na(data.total$RxRA_Allow)]<-0

data.total$RX_Allow<-as.numeric(data.total$RX_Allow)
data.total$RX_Allow[is.na(data.total$RX_Allow)]<-0


length(unique(data.total$MemberID[data.total$RA_Flag.x==1&data.total$WithSteps==1])) # 420
length(unique(data.total$MemberID[data.total$Depressed_Flag.x==1&data.total$WithSteps==1])) #2985

ra.enrl.ids<-unique(data.total$MemberID[data.total$RA_Flag.x==1&data.total$WithSteps==1])
dep.enrl.ids<-unique(data.total$MemberID[data.total$Depressed_Flag.x==1&data.total$WithSteps==1])


a<-nrow(data.member.adult[data.member.adult$Gender=="F"&data.member.adult$Depressed_Flag==1,])
b<-nrow(data.member.adult[data.member.adult$Gender=="F"&data.member.adult$Depressed_Flag==0,])
c<-nrow(data.member.adult[data.member.adult$Gender=="M"&data.member.adult$Depressed_Flag==1,])
d<-nrow(data.member.adult[data.member.adult$Gender=="M"&data.member.adult$Depressed_Flag==0,])

e<-nrow(data.member.adult[data.member.adult$Gender=="F",])
f<-nrow(data.member.adult[data.member.adult$Gender=="M",])
g<-nrow(data.member.adult[data.member.adult$Depressed_Flag=="1",])
h<-nrow(data.member.adult[data.member.adult$Depressed_Flag=="0",])

vec1<-c(a/e, b/e, c/f, d/f)
vec2<-c("F", "F", "M", "M")
vec3<-c(1,0,1,0)

df1<-data.frame(Gender = vec2, Depressed_Flag = vec3, Percent = vec1)
  
ggplot(data=df1) + geom_bar(aes(y = Percent, x = Gender, fill = as.factor(Depressed_Flag)), stat="identity")+
  ggtitle("Percentage of Depressed Members by Gender") + 
  scale_y_continuous(labels = percent_format())

ggplot(data.member.adult, aes(x=Age, fill=as.factor(Depressed_Flag), group=as.factor(Depressed_Flag))) +
  geom_density(alpha=.5) + 
  #scale_fill_manual( values = c("red","blue")) +
  ggtitle("Age Densities for Depressed and Non-Depressed Members")

mean(data.member.adult$Age[data.member.adult$Depressed_Flag==1])
mean(data.member.adult$Age[data.member.adult$Depressed_Flag==0])

mean(data.member.adult$Age[data.member.adult$Depressed_Flag==1&data.member.adult$Gender=="F"])
mean(data.member.adult$Age[data.member.adult$Depressed_Flag==1&data.member.adult$Gender=="M"])
mean(data.member.adult$Age[data.member.adult$Depressed_Flag==0&data.member.adult$Gender=="F"])
mean(data.member.adult$Age[data.member.adult$Depressed_Flag==0&data.member.adult$Gender=="M"])

#######################


## enrollment and depression

data.total.enrl<-data.total[data.total$MemberID%in%enrl.ids,]

length(unique(data.total.enrl$MemberID[data.total.enrl$Depressed_Flag.x==0]))

with(data.total.enrl, cor(Step_Cnt.x, Age)) # .1496
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==1,], cor(Step_Cnt.x, Age)) # .0939
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==0,], cor(Step_Cnt.x, Age)) # .1571

with(data.total.enrl, cor(NoDays_wSteps.x, Age)) # .1691
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==1,], cor(NoDays_wSteps.x, Age)) # .1179
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==0,], cor(NoDays_wSteps.x, Age)) # .1762


with(data.total.enrl, cor(Step_Cnt.x, RX_Allow)) # .0031
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==1,], cor(Step_Cnt.x, RX_Allow)) #-.0131
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==0,], cor(Step_Cnt.x, RX_Allow)) # .0083

with(data.total.enrl, cor(Step_Cnt.x, NoDays_wSteps.x)) # .8506
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==1,], cor(Step_Cnt.x, NoDays_wSteps.x)) # .8530
with(data.total.enrl[data.total.enrl$Depressed_Flag.x==0,], cor(Step_Cnt.x, NoDays_wSteps.x)) # .8506

with(data.total.enrl[data.total.enrl$Depressed_Flag.x==1,], cor(Step_Cnt.x, RxDepression_Allow)) # .0037

mean(data.total.enrl$Step_Cnt.x[data.total.enrl$Depressed_Flag.x==1])
mean(data.total.enrl$Step_Cnt.x[data.total.enrl$Depressed_Flag.x==0])

a<-data.total.enrl$Step_Cnt.x[data.total.enrl$Depressed_Flag.x==1]
b<-data.total.enrl$Step_Cnt.x[data.total.enrl$Depressed_Flag.x==0]

var.test(a,b) #signif dif variances
t.test(a,b, var.equal = F, paired = F) # signif dif step count

stepcnt_dep<-tapply(data.total.enrl$Step_Cnt.x[data.total.enrl$Depressed_Flag.x==1],
                    data.total.enrl$MemberID[data.total.enrl$Depressed_Flag.x==1], mean)
stepcnt_nodep<-tapply(data.total.enrl$Step_Cnt.x[data.total.enrl$Depressed_Flag.x==0],
                      data.total.enrl$MemberID[data.total.enrl$Depressed_Flag.x==0], mean)

var.test(stepcnt_dep, stepcnt_nodep)
t.test(stepcnt_dep, stepcnt_nodep, var.equal = F, paired = F) # signif dif when looking at avg per member

ggplot(data.total.enrl, aes(x=Step_Cnt.x, fill=as.factor(Depressed_Flag.x), 
                            group=as.factor(Depressed_Flag.x))) +
  geom_density(alpha=.5) + 
  #scale_fill_manual( values = c("red","blue")) +
  ggtitle("Step Count Densities for Depressed and Non-Depressed Members") +
  coord_cartesian(xlim = c(0, 100000)) 

step_quartile<-quantile(c(stepcnt_dep, stepcnt_nodep))
mean_step_cnt<-c(stepcnt_dep, stepcnt_nodep)

data.member.enrl<-data.member.adult[data.member.adult$WithSteps==1,]
data.member.enrl$MeanStep<-mean_step_cnt[match(data.member.enrl$MemberID, names(mean_step_cnt))]

data.member.enrl$MeanStep<-mean_step_cnt[match(data.member.enrl$MemberID, names(mean_step_cnt))]

quart<-vector()
for(i in 1:nrow(data.member.enrl)){
  if(data.member.enrl$MeanStep[i]<step_quartile[2]){
    data.member.enrl$StepQuart[i]<-1
  }else if(data.member.enrl$MeanStep[i]<step_quartile[3]){
    data.member.enrl$StepQuart[i]<-2
  }else if(data.member.enrl$MeanStep[i]<step_quartile[4]){
    data.member.enrl$StepQuart[i]<-3
  }else{
    data.member.enrl$StepQuart[i]<-4
  }
  
}



ggplot(data=data.member.enrl, aes(as.factor(StepQuart))) + 
  geom_bar(aes(fill = as.factor(Depressed_Flag)))+
  ggtitle("Member Breakdown by Step Count Quartiles (1=least active, 4=most active)") 


ggplot(data=data.member.enrl, aes(as.factor(StepQuart))) + 
  geom_bar(aes(fill = as.factor(RA_Flag)))+
  ggtitle("Member Breakdown by Step Count Quartiles (1=least active, 4=most active)") 


## compare depressed members in different quartiles in terms of RX spend, gender, age

data.member.enrl.dep<-data.member.enrl[data.member.enrl$Depressed_Flag==1,]

mod1<-lm(data=data.member.enrl.dep, Age ~ as.factor(StepQuart))
obj<-lsmeans(mod1, "StepQuart")
contrast(obj, "tukey")

mod2<-lm(data=data.member.enrl.dep, MeanRXSpend ~ as.factor(StepQuart))
obj<-lsmeans(mod2, "StepQuart")
contrast(obj, "tukey")

mean.dep.allow2<-tapply(data.total$RxDepression_Allow[data.total$MemberID%in%dep.enrl.ids], 
                        data.total$MemberID[data.total$MemberID%in%dep.enrl.ids], mean)

data.total$Total_Allow<-as.numeric(data.total$Total_Allow)
mean.total.allow<-tapply(data.total$Total_Allow,  data.total$MemberID, mean)

data.member.enrl$MeanTotalSpend<-mean.total.allow[match(data.member.enrl$MemberID, names(mean.total.allow))]

mod2<-lm(data=data.member.enrl.dep, MeanDepSpend ~ as.factor(StepQuart))
obj<-lsmeans(mod2, "StepQuart")
contrast(obj, "tukey")

mod2<-lm(data=data.member.enrl.dep, MeanTotalSpend ~ as.factor(StepQuart))
obj<-lsmeans(mod2, "StepQuart")
contrast(obj, "tukey")

table(data.member.enrl.dep$StepQuart, data.member.enrl.dep$Gender)
chisq.test(data.member.enrl.dep$Gender, data.member.enrl.dep$StepQuart)

for(i in 1:nrow(data.member.adult)){
  if(data.member.adult$Depressed_Flag[i]==1){
    if(data.member.adult$WithSteps[i]==1){
      data.member.adult$Group1[i]<-1
    }else{
      data.member.adult$Group1[i]<-2
    }
    if(data.member.adult$Gender[i]=="F"){
      data.member.adult$Group2[i]<-1
    }else{
      data.member.adult$Group2[i]<-2
    }
  }else{
    if(data.member.adult$WithSteps[i]==1){
      data.member.adult$Group1[i]<-3
    }else{
      data.member.adult$Group1[i]<-4
    }
    if(data.member.adult$Gender[i]=="F"){
      data.member.adult$Group2[i]<-3
    }else{
      data.member.adult$Group2[i]<-4
    }
  }
}

mod2<-lm(data=data.member.adult, MeanRXSpend ~ as.factor(Group1))
obj<-lsmeans(mod2, "Group1")
contrast(obj, "tukey")

mod2<-lm(data=data.member.adult, MeanRXSpend ~ as.factor(Group2))
obj<-lsmeans(mod2, "Group2")
contrast(obj, "tukey")
#######################

## analysis of rx spend and rx spend for RA drugs over time relative to motion

data.depRA$RxRA_Allow<-as.numeric(data.depRA$RxRA_Allow)
data.depRA$RxDepression_Allow<-as.numeric(data.depRA$RxDepression_Allow)

hist(data.depRA$RxRA_Allow[data.depRA$RA_Flag==1])
hist(data.depRA$RxDepression_Allow[data.depRA$RxDepression_Allow!=0])

time<-as.numeric(data.total$YearMo)
time1<-as.factor(time)
time<-as.numeric(time1)
data.total$Time<-time

mean.ra.allow<-tapply(data.total$RxRA_Allow[data.total$MemberID%in%ra.enrl.ids], 
                      data.total$Time[data.total$MemberID%in%ra.enrl.ids], mean)

mean.ra.allow.rm<-tapply(data.total$RxRA_Allow[data.total$MemberID%in%ra.enrl.ids], 
                      data.total$Der_Enrl_MonthInd.x[data.total$MemberID%in%ra.enrl.ids], mean)

mean.rxra.allow.rm<-tapply(data.total$RX_Allow[data.total$MemberID%in%ra.enrl.ids], 
                         data.total$Der_Enrl_MonthInd.x[data.total$MemberID%in%ra.enrl.ids], mean)

time2<-unique(sort(data.total$Der_Enrl_MonthInd.x[data.total$MemberID%in%ra.enrl.ids]))

plot(c(2:36), mean.ra.allow, cex=0)
lines(c(2:36), mean.ra.allow)

plot(time2, mean.rxra.allow.rm, cex=0, 
     main="RX Allowed vs. RX Allowed for RA Medications\n Over Time Relative to Motion")
lines(time2, mean.rxra.allow.rm, lwd=2)
lines(time2, mean.ra.allow.rm, col="red", lwd=2)
abline(v=c(-12,0,12), col="grey", lty=2)
legend("topleft", legend = c("RX Allowed", "RX RA Allowed"), col=c("black", "red"),
       lty=c(1,1), cex=.8)


## calculate % of rx allow that is for RA using raw amounts
time2b<-time2[time2<13&time2>-13]

ra.vec<-(mean.ra.allow.rm)/mean.rxra.allow.rm
ra.vec<-unname(ra.vec)
mean(ra.vec[time2<13&time2>-13])

a<-nrow(data.member.adult[data.member.adult$Gender=="F"&data.member.adult$RA_Flag==1,])
b<-nrow(data.member.adult[data.member.adult$Gender=="F"&data.member.adult$RA_Flag==0,])
c<-nrow(data.member.adult[data.member.adult$Gender=="M"&data.member.adult$RA_Flag==1,])
d<-nrow(data.member.adult[data.member.adult$Gender=="M"&data.member.adult$RA_Flag==0,])

e<-nrow(data.member.adult[data.member.adult$Gender=="F",])
f<-nrow(data.member.adult[data.member.adult$Gender=="M",])
g<-nrow(data.member.adult[data.member.adult$RA_Flag=="1",])
h<-nrow(data.member.adult[data.member.adult$RA_Flag=="0",])

vec1<-c(a/e, b/e, c/f, d/f)
vec2<-c("F", "F", "M", "M")
vec3<-c(1,0,1,0)

df2<-data.frame(Gender = vec2, RA_Flag = vec3, Percent = vec1)

ggplot(data=df2) + geom_bar(aes(y = Percent, x = Gender, fill = as.factor(RA_Flag)), stat="identity")+
  ggtitle("Percentage of RA Members by Gender") + 
  scale_y_continuous(labels = percent_format())

ggplot(data.member.adult, aes(x=Age, fill=as.factor(RA_Flag), group=as.factor(RA_Flag))) +
  geom_density(alpha=.5) + 
  #scale_fill_manual( values = c("red","blue")) +
  ggtitle("Age Densities by RA Diagnosis")

mean(data.member.adult$Age[data.member.adult$RA_Flag==1])
mean(data.member.adult$Age[data.member.adult$RA_Flag==0])

mean(data.member.adult$Age[data.member.adult$RA_Flag==1&data.member.adult$Gender=="F"])
mean(data.member.adult$Age[data.member.adult$RA_Flag==0&data.member.adult$Gender=="F"])
mean(data.member.adult$Age[data.member.adult$RA_Flag==1&data.member.adult$Gender=="M"])
mean(data.member.adult$Age[data.member.adult$RA_Flag==0&data.member.adult$Gender=="M"])

nrow(data.member.adult[data.member.adult$Gender=="F"&data.member.adult$RA_Flag==1,])/nrow(data.member.adult[data.member.adult$Gender=="F",])
nrow(data.member.adult[data.member.adult$Gender=="F"&data.member.adult$RA_Flag==1,])/nrow(data.member.adult[data.member.adult$RA_Flag==1,])
nrow(data.member.adult[data.member.adult$Gender=="M"&data.member.adult$RA_Flag==1,])/nrow(data.member.adult[data.member.adult$Gender=="M",])


with(data.total.enrl, cor(Step_Cnt.x, Age)) # .1496
with(data.total.enrl[data.total.enrl$RA_Flag.x==1,], cor(Step_Cnt.x, Age)) # .1173
with(data.total.enrl[data.total.enrl$RA_Flag.x==0,], cor(Step_Cnt.x, Age)) # .1502

with(data.total.enrl, cor(NoDays_wSteps.x, Age)) # .1691
with(data.total.enrl[data.total.enrl$RA_Flag.x==1,], cor(NoDays_wSteps.x, Age)) # .1463
with(data.total.enrl[data.total.enrl$RA_Flag.x==0,], cor(NoDays_wSteps.x, Age)) # .1696


with(data.total.enrl, cor(Step_Cnt.x, RX_Allow)) # .0031
with(data.total.enrl[data.total.enrl$RA_Flag.x==1,], cor(Step_Cnt.x, RX_Allow)) #-.0131
with(data.total.enrl[data.total.enrl$RA_Flag.x==0,], cor(Step_Cnt.x, RX_Allow)) # .0083

with(data.total.enrl[data.total.enrl$RA_Flag==1,], cor(Step_Cnt.x, RxRA_Allow)) # .0037

for(i in 1:nrow(data.member.adult)){
  if(data.member.adult$RA_Flag[i]==1){
    if(data.member.adult$WithSteps[i]==1){
      data.member.adult$Group3[i]<-1
    }else{
      data.member.adult$Group3[i]<-2
    }
    if(data.member.adult$Gender[i]=="F"){
      data.member.adult$Group4[i]<-1
    }else{
      data.member.adult$Group4[i]<-2
    }
  }else{
    if(data.member.adult$WithSteps[i]==1){
      data.member.adult$Group3[i]<-3
    }else{
      data.member.adult$Group3[i]<-4
    }
    if(data.member.adult$Gender[i]=="F"){
      data.member.adult$Group4[i]<-3
    }else{
      data.member.adult$Group4[i]<-4
    }
  }
}

mod2<-lm(data=data.member.adult, MeanRXSpend ~ as.factor(Group3))
obj<-lsmeans(mod2, "Group3")
contrast(obj, "tukey")

mod2<-lm(data=data.member.adult, MeanRXSpend ~ as.factor(Group4))
obj<-lsmeans(mod2, "Group4")
contrast(obj, "tukey")

stepcnt_ra<-tapply(data.total.enrl$Step_Cnt.x[data.total.enrl$RA_Flag.x==1],
                    data.total.enrl$MemberID[data.total.enrl$RA_Flag.x==1], mean)
stepcnt_nora<-tapply(data.total.enrl$Step_Cnt.x[data.total.enrl$RA_Flag.x==0],
                      data.total.enrl$MemberID[data.total.enrl$RA_Flag.x==0], mean)

var.test(stepcnt_ra, stepcnt_nora) # var not significantly dif
t.test(stepcnt_ra, stepcnt_nora, var.equal = T, paired = F) # not signif dif

## compare ra members in different quartiles in terms of RX spend, gender, age

data.member.enrl.ra<-data.member.enrl[data.member.enrl$RA_Flag==1,]

mod1<-lm(data=data.member.enrl.ra, Age ~ as.factor(StepQuart))
obj<-lsmeans(mod1, "StepQuart")
contrast(obj, "tukey")


mod2<-lm(data=data.member.enrl.ra, MeanRXSpend ~ as.factor(StepQuart))
obj<-lsmeans(mod2, "StepQuart")
contrast(obj, "tukey")

mean.dep.allow2<-tapply(data.total$RxDepression_Allow[data.total$MemberID%in%dep.enrl.ids], 
                        data.total$MemberID[data.total$MemberID%in%dep.enrl.ids], mean)

data.total$Total_Allow<-as.numeric(data.total$Total_Allow)
mean.ra.allow<-tapply(data.total$RxRA_Allow[data.total$MemberID%in%ra.enrl.ids], 
                         data.total$MemberID[data.total$MemberID%in%ra.enrl.ids], mean)

data.member.enrl.ra$MeanRASpend<-mean.ra.allow[match(data.member.enrl.ra$MemberID, names(mean.ra.allow))]

mod2<-lm(data=data.member.enrl.ra, MeanRASpend ~ as.factor(StepQuart))
obj<-lsmeans(mod2, "StepQuart")
contrast(obj, "tukey")

mod2<-lm(data=data.member.enrl.ra, MeanTotalSpend ~ as.factor(StepQuart))
obj<-lsmeans(mod2, "StepQuart")
contrast(obj, "tukey")

table(data.member.enrl.ra$StepQuart, data.member.enrl.ra$Gender)
chisq.test(data.member.enrl.ra$Gender, data.member.enrl.ra$StepQuart)


#########################

## analysis of rx spend and rx spend for dep drugs

mean.dep.allow<-tapply(data.total$RxDepression_Allow[data.total$MemberID%in%dep.enrl.ids], 
                      data.total$Time[data.total$MemberID%in%dep.enrl.ids], mean)

mean.dep.allow2<-tapply(data.total$RxDepression_Allow[data.total$MemberID%in%dep.enrl.ids], 
                       data.total$MemberID[data.total$MemberID%in%dep.enrl.ids], mean)

mean.dep.allow.rm<-tapply(data.total$RxDepression_Allow[data.total$MemberID%in%dep.enrl.ids], 
                         data.total$Der_Enrl_MonthInd.x[data.total$MemberID%in%dep.enrl.ids], mean)

mean.rxdep.allow.rm<-tapply(data.total$RX_Allow[data.total$MemberID%in%dep.enrl.ids], 
                           data.total$Der_Enrl_MonthInd.x[data.total$MemberID%in%dep.enrl.ids], mean)

time2<-unique(sort(data.total$Der_Enrl_MonthInd.x[data.total$MemberID%in%dep.enrl.ids]))

plot(time2, mean.rxdep.allow.rm, cex=0, ylim=c(0, 300), 
     main="RX Allowed vs. RX Allowed for Depression Medication\nOver Time Relative to Motion")
lines(time2, mean.rxdep.allow.rm, lwd=2)
lines(time2, mean.dep.allow.rm, col="red", lwd=2)
abline(v=c(-12,0,12), col="grey", lty=2)
legend("topright", legend=c("RX Allowed", "RX Allowed for Dep"), col=c("black", "red"), lty = c(1,1))

## calculate % of rx allow that is for RA using raw amounts
time2b<-time2[time2<13&time2>-13]
dep.vec<-vector(length=length(time2b))
for(i in 1:length(time2b)){
  dep.vec[i]<-(mean.rxdep.allow.rm[time2==time2b[i]]-mean.dep.allow.rm[time2==time2b[i]])/
    mean.rxdep.allow.rm[time2==time2b[i]]
}

mean(mean.dep.allow.rm[time2<13&time2>-13]/mean.rxdep.allow.rm[time2<13&time2>-13])

max(mean.dep.allow.rm/mean.rxdep.allow.rm)
#[1] 0.1177318
mean(mean.dep.allow.rm/mean.rxdep.allow.rm)
#[1] 0.03821964

#########################

## analysis of step counts for enrolled members with ra/depression vs. healthy
data.total$Step_Cnt[is.na(data.total$Step_Cnt)]<-0
plot(density(data.total$Step_Cnt[data.total$MemberID%in%healthy.ids&data.total$WithSteps==1]))


mean.step<-tapply(data.total$Step_Cnt, data.total$MemberID, mean)
data.member$MeanStep<-mean.step[match(data.member$MemberID, names(mean.step))]



########################

## create recent raf variable?
data.member$RAF_2014<-as.numeric(data.member$RAF_2014)
data.member$RAF_2015<-as.numeric(data.member$RAF_2015)
data.member$RAF_2016<-as.numeric(data.member$RAF_2016)

recentraf<-vector(length=nrow(data.member))

for(i in 1:nrow(data.member)){
  rafvec<-data.member[i, 41:43]
  if(rafvec[3]==0&rafvec[2]==0){
    recentraf[i]<-rafvec[1]
  }else if(rafvec[3]==0&rafvec[2]!=0){
    recentraf[i]<-rafvec[2]
  }else if(rafvec[3]!=0){
    recentraf[i]<-rafvec[3]
  }
}

recentraf<-unlist(recentraf)
data.member$Recent_RAF<-recentraf



#########################

## comparison between depressed and RA members (and those with both)

for(i in 1:nrow(data.member.adult)){
  if(data.member.adult$Depressed_Flag[i]==1|data.member.adult$RA_Flag[i]==1){
    data.member.adult$DepRA_Flag[i] <- 1
  }else{
    data.member.adult$DepRA_Flag[i] <- 0 
  }
  
}

data.member.depra<-data.member.adult[data.member.adult$DepRA_Flag==1,]

for(i in 1:nrow(data.member.depra)){
  if(data.member.depra$Depressed_Flag[i]==1&data.member.depra$RA_Flag[i]==1){
    data.member.depra$Group5[i]<-1
  }else if(data.member.depra$Depressed_Flag[i]==1){
    data.member.depra$Group5[i]<-3
  }else{
    data.member.depra$Group5[i]<-2
  }
}

mod2<-lm(data=data.member.depra, MeanRXSpend ~ as.factor(Group5))
obj<-lsmeans(mod2, "Group5")
contrast(obj, "tukey")

data.member.depra$MeanTotalSpend<-mean.total.allow[match(data.member.depra$MemberID, names(mean.total.allow))]

mod2<-lm(data=data.member.depra, MeanTotalSpend ~ as.factor(Group5))
obj<-lsmeans(mod2, "Group5")
contrast(obj, "tukey")

mod2<-lm(data=data.member.depra, Age ~ as.factor(Group5))
obj<-lsmeans(mod2, "Group5")
contrast(obj, "tukey")

table(data.member.depra$Gender, data.member.depra$Group5)
chisq.test(data.member.depra$Gender, data.member.depra$Group5)

table(data.member.depra$WithSteps, data.member.depra$Group5)
chisq.test(data.member.depra$Gender, data.member.depra$Group5)
