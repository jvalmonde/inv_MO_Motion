

library(data.table)
library(savvy)
library(xtable)
library(survival)

all_dat=data.table(read.odbc("Devsql14pdb_AllSavers",dbQuery='select * from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2]'))
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]
all_dat[,EffectiveDate:=list(as.Date(EffectiveDate,tz=''))]

tmp=all_dat[,list(.N,sum(GenderCode=='M'),sum(GenderCode=='F'),sum(BinAge=='Younger'),sum(BinAge=='Older'),sum(EffectiveDate<'2016-06-01'),sum(EffectiveDate>='2016-06-01')),by=c('LookupRuleGroupid','TotalEligibles','Registered','GroupEffectiveDate')]
setnames(tmp,c('V2','V3','V4','V5','V6','V7'),c('NumMales','NumFemales','NumYoung','NumOld','MayEff','JunEff'))
tmp[,GroupEffectiveDate:=list(as.Date(GroupEffectiveDate,tz=''))]
tmp[,StartBin:=ifelse(GroupEffectiveDate-as.Date('2016-01-01')<0,'Old Company','New Company')]
tmp[,OthersReg:=ifelse(Registered>0,'Yes','No')]

setkeyv(tmp,c('N','TotalEligibles','StartBin','OthersReg'))

tmp=tmp[order(-N)]
tmp[,Group:=rep(1:round(length(N)/5),each=5),c('OthersReg','StartBin')]

Treatments=c('Control','Tribal_Comic','Tribal_Letter','YouWon_Comic','YouWon_Letter')
ind=86085           # 907, 2833, 86085,              94037, 25464
print(ind)
set.seed(ind)
tmp[,Treat:=sample(Treatments,replace=FALSE),by=c('OthersReg','StartBin','Group')]
tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld),sum(MayEff),sum(JunEff)),by=Treat]

tmp_Tribal_Comic=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Tribal_Comic']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Tribal_Comic,names(tmp_Tribal_Comic),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Tribal_Comic,'/work/dhalterman/AllSaversMotionGP0284/00196-TM-0416 Treatment 8 Tribal Appeal (Comic) Letter.csv',row.names=FALSE)

tmp_Tribal_Letter=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Tribal_Letter']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Tribal_Letter,names(tmp_Tribal_Letter),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Tribal_Letter,'/work/dhalterman/AllSaversMotionGP0284/00213-TM-0616 Tribal Appeal Non Comic-Letter.csv',row.names=FALSE)

tmp_YouWon_Comic=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='YouWon_Comic']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_YouWon_Comic,names(tmp_YouWon_Comic),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_YouWon_Comic,'/work/dhalterman/AllSaversMotionGP0284/00214-TM-0616 You Won Comic-Letter.csv')

tmp_YouWon_Letter=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='YouWon_Letter']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_YouWon_Letter,names(tmp_YouWon_Letter),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_YouWon_Letter,'/work/dhalterman/AllSaversMotionGP0284/00201-TM-0416 Treatment 4 You Won Letter.csv',row.names=FALSE)

tmp_Control=all_dat[LookupRuleGroupid%in%c(tmp[Treat=='Control']$LookupRuleGroupid),list(FirstName,Lastname,AddressLine,City,StateCode,Zipcode,ifelse(is.na(AdminContact),'.',':'),AdminContact,ifelse(is.na(AdminContact),NA,'|'),AdminPhone,ifelse(is.na(AdminContact),NA,'|'),AdminEmail,DateBenefitsEnd)]
setnames(tmp_Control,names(tmp_Control),c('MemberFirstName','MemberLastName','HomeStreetAddress','HomeCity','HomeState','HomeZip','ColonOrPeriod','BenefitsCoordinatorName','BeforePhone','BenefitsCoordinatorPhone','BeforeEmail','BenefitsCoordinatorEmail','DateBenefitsEnd'))
write.csv(tmp_Control,'/work/dhalterman/AllSaversMotionGP0284/Control.csv',row.names=FALSE)

write.csv(tmp,'/work/dhalterman/AllSaversMotionGP0284/Company_Treatments.csv',row.names=FALSE)

tmp=data.table(read.csv('/work/dhalterman/AllSaversMotionGP0284/Company_Treatments.csv'))
tmp[,list(sum(N),.N,sum(NumMales),sum(NumFemales),sum(NumYoung),sum(NumOld),sum(MayEff),sum(JunEff)),by=Treat]

