
all_dat=data.table(read.odbc("PCPResponse",dbQuery='select * from [pdb_AllSavers_PCPSelection].[dbo].[TreatmentMembers]',as.is=TRUE))
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]
all_dat<-all_dat[Treatment=="T",]
all_dat<-all_dat[Campaign=="1",]
all_dat<-all_dat[SurveyResponseFlag=="0",]
all_dat<-all_dat[Attempt=="2",]

all_Group=data.table(read.odbc("PCPResponse",dbQuery='select * from [pdb_AllSavers_PCPSelection].[dbo].[TreatmentGroups]',as.is=TRUE))

Company<-as.data.frame(unique(all_dat$LookupRuleGroupId))
names(Company)<-"LookupRuleGroupid"
tmp<-merge(Company,all_Group,by="LookupRuleGroupid")
table(tmp$StateCd)

all_dat$LookupRuleGroupid<-as.numeric(all_dat$LookupRuleGroupId)
all_Group$LookupRuleGroupid<-as.numeric(all_Group$LookupRuleGroupid)

tmp1$dif<-tmp1$Look
tmp1<-merge(all_dat,all_Group,by="LookupRuleGroupid")
table(tmp1$StateCd)