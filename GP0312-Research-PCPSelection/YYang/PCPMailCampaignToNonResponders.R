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
Letter_PQ_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_PQ_G,names(Letter_PQ_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_PQ_G,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_G_NoHSA.csv',row.names=FALSE)

Letter_PQ_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_PQ_L,names(Letter_PQ_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_PQ_L,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_L_NoHSA.csv',row.names=FALSE)

LetterCopay_PQ_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/PQ/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(LetterCopay_PQ_G,names(LetterCopay_PQ_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(LetterCopay_PQ_G,'/work/yyang/Github/PCP/C2MailList/LetterCopay_PQ_G_NoHSA.csv',row.names=FALSE)


LetterCopay_PQ_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/PQ/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(LetterCopay_PQ_L,names(LetterCopay_PQ_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(LetterCopay_PQ_L,'/work/yyang/Github/PCP/C2MailList/LetterCopay_PQ_L_NoHSA.csv',row.names=FALSE)

Letter_A_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/A/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_A_G,names(Letter_A_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_A_G,'/work/yyang/Github/PCP/C2MailList/Letter_A_G_NoHSA.csv',row.names=FALSE)

Letter_A_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='L/A/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_A_L,names(Letter_A_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_A_L,'/work/yyang/Github/PCP/C2MailList/Letter_A_L_NoHSA.csv',row.names=FALSE)


LetterCopay_A_G=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/A/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(LetterCopay_A_G,names(LetterCopay_A_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(LetterCopay_A_G,'/work/yyang/Github/PCP/C2MailList/LetterCopay_A_G_NoHSA.csv',row.names=FALSE)

LetterCopay_A_L=Full[LookupRuleGroupId%in%c(tmp[Treat=='LC/A/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(LetterCopay_A_L,names(LetterCopay_A_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(LetterCopay_A_L,'/work/yyang/Github/PCP/C2MailList/LetterCopay_A_L_NoHSA.csv',row.names=FALSE)



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
Letter_PQ_G_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_PQ_G,names(Letter_PQ_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_PQ_G_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_G_HSA.csv',row.names=FALSE)

Letter_PQ_L_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/PQ/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_PQ_L,names(Letter_PQ_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_PQ_L_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_PQ_L_HSA.csv',row.names=FALSE)


Letter_A_G_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/A/G']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_A_G,names(Letter_A_G),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_A_G_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_A_G_HSA.csv',row.names=FALSE)

Letter_A_L_HSA=Partial[LookupRuleGroupId%in%c(tmp[Treat=='L/A/L']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,city,StateCode,ZipCode)]
setnames(Letter_A_L,names(Letter_A_L),c('MemberFirstName','MemberLastName','HomeStreetAddress','City','HomeState','HomeZip'))
write.csv(Letter_A_L_HSA,'/work/yyang/Github/PCP/C2MailList/Letter_A_L_HSA.csv',row.names=FALSE)



