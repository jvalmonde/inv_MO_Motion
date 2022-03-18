library(data.table)
library(savvy)
library(xtable)
library(survival)


#### 2 Phone messages ----
all_dat=data.table(read.odbc("PCPResponse",dbQuery='select * from [pdb_AllSavers_PCPSelection].[dbo].[TreatmentMembers]',as.is=TRUE))
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]
all_dat<-all_dat[Treatment=="T",]
all_dat<-all_dat[Campaign=="1",]
all_dat<-all_dat[Attempt=="2",]

all_dat<-all_dat[SurveyResponseFlag=="0",]



Full<-all_dat[CopayFlag=="1"]
Partial<-all_dat[CopayFlag=="0"]
#all_dat[,RuleGroupName:=NULL]
#all_dat[,c('Zipcode','isregistered','RegistrationRate','GroupAge','AdminAllwAmtPM','GroupZip','GroupSICCode','Rn'):=list(as.integer(Zipcode),as.integer(isregistered),as.numeric(RegistrationRate),as.integer(GroupAge),as.numeric(AdminAllwAmtPM),as.integer(GroupZip),as.integer(GroupSICCode),as.integer(Rn))]

###################Full####################
tmp=Full[,list(.N,sum(Gendercode=='M'),sum(Gendercode=='F'),sum(BinAge=='Younger'),sum(BinAge=='Older')),by=c('LookupRuleGroupId')]
setnames(tmp,c('V2','V3','V4','V5'),c('NumMales','NumFemales','NumYoung','NumOld'))

setkey(tmp,N)
tmp=tmp[order(-N)]

tmp[,Group:=rep(1:ceiling(length(N)/8),each=8)]
Treatments=c('L/PQ/G','L/PQ/L','LC/PQ/G','LC/PQ/L','L/A/G','L/A/L','LC/A/G','LC/A/L')

#618 companies
#3955 members
#test<-as.data.frame(cbind(all_dat$StateCode, all_dat$LookupRuleGroupId))
#test=rename(test,c("V1"="State", "V2"="CompanyID"))
#tmp=aggregate(data=unique(test), CompanyID~State,FUN="length")


set.seed(1245)
sim.results=data.table(ind=c(round(runif(1000)*10000)))
group_construction=function(ind)
{
  set.seed(ind)
  tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('Group')]
  tmp2=tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld)),by=Treat][order(Treat)]
  setnames(tmp2,names(tmp2),c('Treatment','Individuals','Companies','Males','Females','Young','Old'))
  return(list(sd(tmp2$Individuals),sd(tmp2$Companies),sd(tmp2$Males),sd(tmp2$Females),sd(tmp2$Young),sd(tmp2$Old)))
}

sim.results[,c('sd_Individuals','sd_Companies','sd_Males','sd_Females','sd_Young','sd_Old'):=group_construction(ind),by=ind]
setkeyv(sim.results,c('sd_Individuals','sd_Companies','sd_Males','sd_Females','sd_Young','sd_Old'))
sim.results

ind=sim.results[4,ind]
set.seed(ind)
tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('Group')]
tmp2=tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld)),by=Treat][order(Treat)]
setnames(tmp2,names(tmp2),c('Treatment','Individuals','Companies','Males','Females','Young','Old'))
tmp2
tmp2[,list(sd(Individuals),sd(Companies),sd(Males),sd(Females),sd(Young),sd(Old))]

#### Save the Groups ----
Letter_PQ_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_PQ_G,names(Letter_PQ_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_PQ_G$Treatment<-as.factor("LetterPQGain")
Letter_PQ_G$Trt<-1
Letter_PQ_G$Factor1<-as.factor("noIncentive")
Letter_PQ_G$Factor2<-as.factor("PQ")
Letter_PQ_G$Factor3<-as.factor("Gain")
write.csv(Letter_PQ_G,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_G_NoHSA_new.csv',row.names=FALSE)

Letter_PQ_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_PQ_L,names(Letter_PQ_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_PQ_L$Treatment<-as.factor("LetterPQLoss")
Letter_PQ_L$Trt<-2
Letter_PQ_L$Factor1<-as.factor("noIncentive")
Letter_PQ_L$Factor2<-as.factor("PQ")
Letter_PQ_L$Factor3<-as.factor("Loss")
write.csv(Letter_PQ_L,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_L_NoHSA_new.csv',row.names=FALSE)

LetterCopay_PQ_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/PQ/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(LetterCopay_PQ_G,names(LetterCopay_PQ_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
LetterCopay_PQ_G$Treatment<-as.factor("LetterCopayPQGain")
LetterCopay_PQ_G$Trt<-3
LetterCopay_PQ_G$Factor1<-as.factor("Incentive")
LetterCopay_PQ_G$Factor2<-as.factor("PQ")
LetterCopay_PQ_G$Factor3<-as.factor("Gain")
write.csv(LetterCopay_PQ_G,'/work/yyang/Github/PCP/C2MailList/LetterCopay_PQ_G_NoHSA_new.csv',row.names=FALSE)


LetterCopay_PQ_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/PQ/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(LetterCopay_PQ_L,names(LetterCopay_PQ_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
LetterCopay_PQ_L$Treatment<-as.factor("LetterCopayPQLoss")
LetterCopay_PQ_L$Trt<-4
LetterCopay_PQ_L$Factor1<-as.factor("Incentive")
LetterCopay_PQ_L$Factor2<-as.factor("PQ")
LetterCopay_PQ_L$Factor3<-as.factor("Loss")
write.csv(LetterCopay_PQ_L,'/work/yyang/Github/PCP/C2MailList/LetterCopay_PQ_L_NoHSA_new.csv',row.names=FALSE)

Letter_A_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/A/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_A_G,names(Letter_A_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_A_G$Treatment<-as.factor("LetterAGain")
Letter_A_G$Trt<-5
Letter_A_G$Factor1<-as.factor("noIncentive")
Letter_A_G$Factor2<-as.factor("A")
Letter_A_G$Factor3<-as.factor("Gain")
write.csv(Letter_A_G,'/work/yyang/Github/PCP/C2MailList/Letter_A_G_NoHSA_new.csv',row.names=FALSE)

Letter_A_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/A/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_A_L,names(Letter_A_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_A_L$Treatment<-as.factor("LetterALoss")
Letter_A_L$Trt<-6
Letter_A_L$Factor1<-as.factor("noIncentive")
Letter_A_L$Factor2<-as.factor("A")
Letter_A_L$Factor3<-as.factor("Loss")
write.csv(Letter_A_L,'/work/yyang/Github/PCP/C2MailList/Letter_A_L_NoHSA_new.csv',row.names=FALSE)


LetterCopay_A_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/A/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(LetterCopay_A_G,names(LetterCopay_A_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
LetterCopay_A_G$Treatment<-as.factor("LetterCopayAGain")
LetterCopay_A_G$Trt<-7
LetterCopay_A_G$Factor1<-as.factor("Incentive")
LetterCopay_A_G$Factor2<-as.factor("A")
LetterCopay_A_G$Factor3<-as.factor("Gain")
write.csv(LetterCopay_A_G,'/work/yyang/Github/PCP/C2MailList/LetterCopay_A_G_NoHSA_new.csv',row.names=FALSE)

LetterCopay_A_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/A/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(LetterCopay_A_L,names(LetterCopay_A_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
LetterCopay_A_L$Treatment<-as.factor("LetterCopayALoss")
LetterCopay_A_L$Trt<-8
LetterCopay_A_L$Factor1<-as.factor("Incentive")
LetterCopay_A_L$Factor2<-as.factor("A")
LetterCopay_A_L$Factor3<-as.factor("Loss")
write.csv(LetterCopay_A_L,'/work/yyang/Github/PCP/C2MailList/LetterCopay_A_L_NoHSA_new.csv',row.names=FALSE)

FullTrtMember_tab<-rbind(Letter_PQ_G,Letter_PQ_L,LetterCopay_PQ_G,LetterCopay_PQ_L,Letter_A_G,Letter_A_L,LetterCopay_A_G,LetterCopay_A_L)
FullTrtMember_tab$HSA<-as.factor("No")

#####################Partial


tmp=Partial[,list(.N,sum(Gendercode=='M'),sum(Gendercode=='F'),sum(BinAge=='Younger'),sum(BinAge=='Older')),by=c('LookupRuleGroupId')]
setnames(tmp,c('V2','V3','V4','V5'),c('NumMales','NumFemales','NumYoung','NumOld'))

setkey(tmp,N)
tmp=tmp[order(-N)]

tmp[,Group:=rep(1:ceiling(length(N)/4),each=4)]
Treatments=c('L/PQ/G','L/PQ/L','L/A/G','L/A/L')

#618 companies
#3955 members
#test<-as.data.frame(cbind(all_dat$StateCode, all_dat$LookupRuleGroupId))
#test=rename(test,c("V1"="State", "V2"="CompanyID"))
#tmp=aggregate(data=unique(test), CompanyID~State,FUN="length")


set.seed(1235)
sim.results=data.table(ind=c(round(runif(1000)*10000)))
group_construction=function(ind)
{
  set.seed(ind)
  tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('Group')]
  tmp2=tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld)),by=Treat][order(Treat)]
  setnames(tmp2,names(tmp2),c('Treatment','Individuals','Companies','Males','Females','Young','Old'))
  return(list(sd(tmp2$Individuals),sd(tmp2$Companies),sd(tmp2$Males),sd(tmp2$Females),sd(tmp2$Young),sd(tmp2$Old)))
}

sim.results[,c('sd_Individuals','sd_Companies','sd_Males','sd_Females','sd_Young','sd_Old'):=group_construction(ind),by=ind]
setkeyv(sim.results,c('sd_Individuals','sd_Companies','sd_Males','sd_Females','sd_Young','sd_Old'))
sim.results

ind=sim.results[4,ind]
set.seed(ind)
tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('Group')]
tmp2=tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld)),by=Treat][order(Treat)]
setnames(tmp2,names(tmp2),c('Treatment','Individuals','Companies','Males','Females','Young','Old'))
tmp2
tmp2[,list(sd(Individuals),sd(Companies),sd(Males),sd(Females),sd(Young),sd(Old))]

#### Save the Groups ----
Letter_PQ_G_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_PQ_G_HSA,names(Letter_PQ_G_HSA),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_PQ_G_HSA$Treatment<-as.factor("LetterPQGain")
Letter_PQ_G_HSA$Trt<-1
Letter_PQ_G_HSA$Factor1<-as.factor("noIncentive")
Letter_PQ_G_HSA$Factor2<-as.factor("PQ")
Letter_PQ_G_HSA$Factor3<-as.factor("Gain")
write.csv(Letter_PQ_G_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_G_HSA_new.csv',row.names=FALSE)

Letter_PQ_L_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_PQ_L_HSA,names(Letter_PQ_L_HSA),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_PQ_L_HSA$Treatment<-as.factor("LetterPQLoss")
Letter_PQ_L_HSA$Trt<-2
Letter_PQ_L_HSA$Factor1<-as.factor("noIncentive")
Letter_PQ_L_HSA$Factor2<-as.factor("PQ")
Letter_PQ_L_HSA$Factor3<-as.factor("Loss")
write.csv(Letter_PQ_L_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_L_HSA_new.csv',row.names=FALSE)


Letter_A_G_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/A/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_A_G_HSA,names(Letter_A_G_HSA),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_A_G_HSA$Treatment<-as.factor("LetterAGain")
Letter_A_G_HSA$Trt<-3
Letter_A_G_HSA$Factor1<-as.factor("noIncentive")
Letter_A_G_HSA$Factor2<-as.factor("A")
Letter_A_G_HSA$Factor3<-as.factor("Gain")
write.csv(Letter_A_G_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_A_G_HSA_new.csv',row.names=FALSE)

Letter_A_L_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/A/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode,Clientmemberid)]
setnames(Letter_A_L_HSA,names(Letter_A_L_HSA),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip','ClientmemberID'))
Letter_A_L_HSA$Treatment<-as.factor("LetterALoss")
Letter_A_L_HSA$Trt<-4
Letter_A_L_HSA$Factor1<-as.factor("noIncentive")
Letter_A_L_HSA$Factor2<-as.factor("A")
Letter_A_L_HSA$Factor3<-as.factor("Loss")
write.csv(Letter_A_L_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_A_L_HSA_new.csv',row.names=FALSE)

PartialTrtMember_tab<-rbind(Letter_PQ_G_HSA,Letter_PQ_L_HSA,Letter_A_G_HSA,Letter_A_L_HSA)
PartialTrtMember_tab$HSA<-as.factor("YES")

totalmemberC2<-as.data.frame(rbind(FullTrtMember_tab,PartialTrtMember_tab))
ListforSue<-totalmemberC2[c(1:2,8,13)]
ListforMatt<-totalmemberC2[c(7:13)]
write.csv(ListforSue,'/work/yyang/Github/PCP/C2MailList/ListforSue.csv',row.names=FALSE)
write.csv(ListforMatt,'/work/yyang/Github/PCP/C2MailList/ListforMatt.csv',row.names=FALSE)
write.csv(totalmemberC2,'/work/yyang/Github/PCP/C2MailList/TotalmemberList.csv',row.names=FALSE)
