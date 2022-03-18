

library(data.table)
library(savvy)
library(xtable)
library(survival)


#### 2 Phone messages ----
all_dat=data.table(read.odbc("Devsql14pdb_AllSavers",dbQuery='select * from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2]',as.is=TRUE))
all_dat[,RuleGroupName:=NULL]
all_dat[,c('Zipcode','isregistered','RegistrationRate','GroupAge','AdminAllwAmtPM','GroupZip','GroupSICCode','Rn'):=list(as.integer(Zipcode),as.integer(isregistered),as.numeric(RegistrationRate),as.integer(GroupAge),as.numeric(AdminAllwAmtPM),as.integer(GroupZip),as.integer(GroupSICCode),as.integer(Rn))]
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]
all_dat[,EffectiveDate:=list(as.Date(EffectiveDate,tz=''))]

all_reg=data.table(read.odbc("Devsql14pdb_AllSavers",dbQuery='select * from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2_Registrations]',as.is=TRUE))
all_reg
all_reg[,c('LookupRuleGroupid','TotalEligibles','Registered','N','NumMales','NumFemales','NumYoung','NumOld','MayEff','JunEff','Group','isregistered'):=list(as.integer(LookupRuleGroupid),as.integer(TotalEligibles),as.integer(Registered),as.integer(N),as.integer(NumMales),as.integer(NumFemales),as.integer(NumYoung),as.integer(NumOld),as.integer(MayEff),as.integer(JunEff),as.integer(Group),as.integer(isregistered))]
all_reg


all_dat=all_dat[ClientMEMBERID%in%c(all_reg[isregistered==0]$ClientMEMBERID)]
# all_dat=all_dat[ClientMEMBERID%in%all_reg[is.na(AccountVerifiedDateTime) | AccountVerifiedDateTime>='2016-06-21']$ClientMEMBERID]

tmp=all_dat[,list(.N,sum(GenderCode=='M'),sum(GenderCode=='F'),sum(BinAge=='Younger'),sum(BinAge=='Older'),sum(EffectiveDate<'2016-06-01'),sum(EffectiveDate>='2016-06-01')),by=c('LookupRuleGroupid','TotalEligibles','Registered','GroupEffectiveDate')]
setnames(tmp,c('V2','V3','V4','V5','V6','V7'),c('NumMales','NumFemales','NumYoung','NumOld','MayEff','JunEff'))
tmp[,GroupEffectiveDate:=list(as.Date(GroupEffectiveDate,tz=''))]
tmp[,StartBin:=ifelse(GroupEffectiveDate-as.Date('2016-01-01')<0,'Old Company','New Company')]
tmp[,OthersReg:=ifelse(Registered>0,'Yes','No')]

setkeyv(tmp,c('N','TotalEligibles','StartBin','OthersReg'))

tmp=tmp[order(-N)]
tmp[,Group:=rep(1:ceiling(length(N)/5),each=5),c('OthersReg','StartBin')]


Treatments=c('Control','Act Now / Comic / Old PS','Benefit Review / Letter / Old PS','Benefit Review / Comic / New PS','Act Now / Letter / New PS')

set.seed(1245)
sim.results=data.table(ind=c(round(runif(1000)*10000)))
group_construction=function(ind){
  set.seed(ind)
  tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('OthersReg','StartBin','Group')]
  tmp2=tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld),sum(MayEff),sum(JunEff)),by=Treat][order(Treat)]
  setnames(tmp2,names(tmp2),c('Treatment','Individuals','Companies','Males','Females','Young','Old','MayEff','JunEff'))
  return(list(sd(tmp2$Individuals),sd(tmp2$Companies),sd(tmp2$Males),sd(tmp2$Females),sd(tmp2$Young),sd(tmp2$Old),sd(tmp2$MayEff),sd(tmp2$JunEff)))
}

sim.results[,c('sd_Individuals','sd_Companies','sd_Males','sd_Females','sd_Young','sd_Old','sd_MayEff','sd_JunEff'):=group_construction(ind),by=ind]
setkeyv(sim.results,c('sd_Individuals','sd_Companies','sd_Males','sd_Females','sd_Young','sd_Old','sd_MayEff','sd_JunEff'))
sim.results

ind=sim.results[4,ind]
set.seed(ind)
tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('OthersReg','StartBin','Group')]
tmp2=tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld),sum(MayEff),sum(JunEff)),by=Treat][order(Treat)]
setnames(tmp2,names(tmp2),c('Treatment','Individuals','Companies','Males','Females','Young','Old','MayEff','JunEff'))
tmp2
tmp2[,list(sd(Individuals),sd(Companies),sd(Males),sd(Females),sd(Young),sd(Old),sd(MayEff),sd(JunEff))]

#### Save the Groups ----
tmp_ActNow_Comic_OldPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Act Now / Comic / Old PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_ActNow_Comic_OldPS,names(tmp_ActNow_Comic_OldPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_ActNow_Comic_OldPS,'/work/dhalterman/AllSaversMotionGP0284/00217-TM-0216-Act-Now-Letter-Comic.csv',row.names=FALSE)

tmp_Benefit_Letter_OldPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Benefit Review / Letter / Old PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Benefit_Letter_OldPS,names(tmp_Benefit_Letter_OldPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Benefit_Letter_OldPS,'/work/dhalterman/AllSaversMotionGP0284/00216-TM-0616-Benefit-Letter-No-Comic.csv',row.names=FALSE)

tmp_Benefit_Comic_NewPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Benefit Review / Comic / New PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Benefit_Comic_NewPS,names(tmp_Benefit_Comic_NewPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Benefit_Comic_NewPS,'/work/dhalterman/AllSaversMotionGP0284/00218-TM-0216-Benefits-Letter-Comic.csv')

tmp_ActNow_Letter_NewPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Act Now / Letter / New PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_ActNow_Letter_NewPS,names(tmp_ActNow_Letter_NewPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_ActNow_Letter_NewPS,'/work/dhalterman/AllSaversMotionGP0284/00215-TM-0616-Act-Now-Letter-No-Comic.csv',row.names=FALSE)

tmp_Control=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Control']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Control,names(tmp_Control),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Control,'/work/dhalterman/AllSaversMotionGP0284/C2T2_Control.csv',row.names=FALSE)

write.csv(tmp,'/work/dhalterman/AllSaversMotionGP0284/C2T2_Company_Treatments.csv',row.names=FALSE)



####  ----
tmp=data.table(read.csv('/work/dhalterman/AllSaversMotionGP0284/C2T2_Company_Treatments.csv'))
# tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld),sum(MayEff),sum(JunEff)),by=Treat]

setkeyv(tmp,c('LookupRuleGroupid')) ; setkeyv(all_dat,'LookupRuleGroupid')
all_dat=all_dat[tmp[,list(LookupRuleGroupid,Treat)]]
all_dat[,.N,by=DateBenefitsEnd][order(DateBenefitsEnd)]

all_dat[DateBenefitsEnd>'2016-06-30',list(.N,length(unique(LookupRuleGroupid)),sum(GenderCode=='M'),sum(GenderCode=='F'),sum(BinAge=='Younger'),sum(BinAge=='Older')),by=c('Treat')]
all_dat=all_dat[DateBenefitsEnd>'2016-06-30']

tmp_ActNow_Comic_OldPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Act Now / Comic / Old PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_ActNow_Comic_OldPS,names(tmp_ActNow_Comic_OldPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_ActNow_Comic_OldPS,'/work/dhalterman/AllSaversMotionGP0284/00217-TM-0216-Act-Now-Letter-Comic2.csv',row.names=FALSE)

tmp_Benefit_Letter_OldPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Benefit Review / Letter / Old PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Benefit_Letter_OldPS,names(tmp_Benefit_Letter_OldPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Benefit_Letter_OldPS,'/work/dhalterman/AllSaversMotionGP0284/00216-TM-0616-Benefit-Letter-No-Comic2.csv',row.names=FALSE)

tmp_Benefit_Comic_NewPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Benefit Review / Comic / New PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Benefit_Comic_NewPS,names(tmp_Benefit_Comic_NewPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Benefit_Comic_NewPS,'/work/dhalterman/AllSaversMotionGP0284/00218-TM-0216-Benefits-Letter-Comic2.csv')

tmp_ActNow_Letter_NewPS=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Act Now / Letter / New PS']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_ActNow_Letter_NewPS,names(tmp_ActNow_Letter_NewPS),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_ActNow_Letter_NewPS,'/work/dhalterman/AllSaversMotionGP0284/00215-TM-0616-Act-Now-Letter-No-Comic2.csv',row.names=FALSE)

tmp_Control=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Control']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Control,names(tmp_Control),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Control,'/work/dhalterman/AllSaversMotionGP0284/C2T2_Control2.csv',row.names=FALSE)

write.csv(tmp,'/work/dhalterman/AllSaversMotionGP0284/C2T2_Company_Treatments2.csv',row.names=FALSE)



