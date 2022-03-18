library(data.table)
library(savvy)
library(xtable)
library(survival)


#### 2 Phone messages ----
all_dat=data.table(read.odbc("PCPdoe",dbQuery='select * from [pdb_AllSavers_PCPSelection].[dbo].[TreatmentMembers]',as.is=TRUE))
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]
all_dat<-all_dat[Treatment=="T",]
#all_dat[,RuleGroupName:=NULL]
#all_dat[,c('Zipcode','isregistered','RegistrationRate','GroupAge','AdminAllwAmtPM','GroupZip','GroupSICCode','Rn'):=list(as.integer(Zipcode),as.integer(isregistered),as.numeric(RegistrationRate),as.integer(GroupAge),as.numeric(AdminAllwAmtPM),as.integer(GroupZip),as.integer(GroupSICCode),as.integer(Rn))]


tmp=all_dat[,list(.N,sum(Gendercode=='M'),sum(Gendercode=='F'),sum(BinAge=='Younger'),sum(BinAge=='Older')),by=c('LookupRuleGroupId')]
setnames(tmp,c('V2','V3','V4','V5'),c('NumMales','NumFemales','NumYoung','NumOld'))

setkey(tmp,N)
tmp=tmp[order(-N)]

tmp[,Group:=rep(1:ceiling(length(N)/8),each=8)]
Treatments=c('PQ/LA','PQ/GS','IQ/LA','IQ/GS','A/LA','A/GS','Other/LA','Other/GS')

#618 companies
#3955 members
test<-as.data.frame(cbind(all_dat$StateCode, all_dat$LookupRuleGroupId))
test=rename(test,c("V1"="State", "V2"="CompanyID"))
tmp=aggregate(data=unique(test), CompanyID~State,FUN="length")


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
tmp_PQ_LA=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='PQ/LA']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_PQ_LA,names(tmp_PQ_LA),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_PQ_LA,'/work/yyang/Github/PCPselection/PQ_LA.csv',row.names=FALSE)

tmp_PQ_GS=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='PQ/GS']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_PQ_GS,names(tmp_PQ_GS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_PQ_GS,'/work/yyang/Github/PCPselection/PQ_GS.csv',row.names=FALSE)

tmp_IQ_LA=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='IQ/LA']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_IQ_LA,names(tmp_IQ_LA),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_IQ_LA,'/work/yyang/Github/PCPselection/IQ_LA.csv',row.names=FALSE)


tmp_IQ_GS=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='IQ/GS']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_IQ_GS,names(tmp_IQ_GS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_IQ_GS,'/work/yyang/Github/PCPselection/IQ_GS.csv',row.names=FALSE)

tmp_A_LA=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='A/LA']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_A_LA,names(tmp_A_LA),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_A_LA,'/work/yyang/Github/PCPselection/A_LA.csv',row.names=FALSE)

tmp_A_GS=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='A/GS']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_A_GS,names(tmp_A_GS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_A_GS,'/work/yyang/Github/PCPselection/A_GS.csv',row.names=FALSE)


tmp_Other_LA=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='Other/LA']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_Other_LA,names(tmp_Other_LA),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_Other_LA,'/work/yyang/Github/PCPselection/Other_LA.csv',row.names=FALSE)

tmp_Other_GS=all_dat[LookupRuleGroupId%in%c(tmp[Treat=='Other/GS']$LookupRuleGroupId),list(Firstname,Lastname,AddressLine,StateCode,ZipCode)]
setnames(tmp_Other_GS,names(tmp_Other_GS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeState','HomeZip'))
write.csv(tmp_Other_GS,'/work/yyang/Github/PCPselection/Other_GS.csv',row.names=FALSE)
