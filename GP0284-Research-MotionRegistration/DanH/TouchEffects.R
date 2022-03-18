
library(data.table)
library(savvy)
library(xtable)
library(survival)
library(lme4)

all_dat=data.table(read.odbc("Devsql14",dbQuery='select * from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2]',as.is=TRUE))
all_dat[,RuleGroupName:=NULL]
all_dat[,c('Zipcode','isregistered','RegistrationRate','GroupAge','AdminAllwAmtPM','GroupZip','GroupSICCode','Rn'):=list(as.integer(Zipcode),as.integer(isregistered),as.numeric(RegistrationRate),as.integer(GroupAge),as.numeric(AdminAllwAmtPM),as.integer(GroupZip),as.integer(GroupSICCode),as.integer(Rn))]
all_dat[,age:=round(as.numeric(difftime(as.Date(Sys.time(),tz=""),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]
all_dat[,EffectiveDate:=list(as.Date(EffectiveDate,tz=''))]
# all_dat[,c('FirstName','Lastname','AddressLine','City','StateCode','Zipcode','AdminInsured','AgentLastname','PolicyID','AdminContactGender','AdminPhone','AdminEmail','AdminContact','AdminMotionEligible','Admin_AvgStepsforEnrolledDays','AdminAllwAmtPM','GroupStreet','GroupCity','GroupState','GroupZip','AdminDataAvailable','Rn'):=NULL]

all_reg=data.table(read.odbc("Devsql14",dbQuery='select * from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2_Registrations]',as.is=TRUE))
all_reg
all_reg[,c('LookupRuleGroupid','TotalEligibles','Registered','N','NumMales','NumFemales','NumYoung','NumOld','MayEff','JunEff','Group','IsRegistered'):=list(as.integer(LookupRuleGroupid),as.integer(TotalEligibles),as.integer(Registered),as.integer(N),as.integer(NumMales),as.integer(NumFemales),as.integer(NumYoung),as.integer(NumOld),as.integer(MayEff),as.integer(JunEff),as.integer(Group),as.integer(isregistered))]
all_reg[,c('isregistered','TotalEligibles','Registered','GroupEffectiveDate'):=NULL]

all_grp=data.table(read.odbc("Devsql14",dbQuery='select LookupRuleGroupid, Treat2 from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2_TreatmentGroups]',as.is=TRUE))
all_grp[,LookupRuleGroupid:=as.numeric(LookupRuleGroupid)]
setnames(all_grp,'Treat2','Touch2Det')
all_grp[Touch2Det=='Act Now Comic -  Old Ps',Touch2Det:='ActNow_Comic_OldPS']
all_grp[Touch2Det=='Act Now Letter - New PS',Touch2Det:='ActNow_Letter_NewPS']
all_grp[Touch2Det=='Benefit Letter - Old Ps',Touch2Det:='Benefit_Letter_OldPS']
all_grp[Touch2Det=='Benefit Comic -  New Ps',Touch2Det:='Benefit_Comic_NewPS']

setkeyv(all_grp,'LookupRuleGroupid') ; setkeyv(all_reg,'LookupRuleGroupid')
all_reg=all_grp[all_reg]
rm(all_grp)

setkeyv(all_reg,c('ClientMEMBERID','LookupRuleGroupid')) ; setkeyv(all_dat,c('ClientMEMBERID','LookupRuleGroupid'))
all_dat=all_reg[all_dat]
rm(all_reg)

# all_dat[,c('AccountVerifiedDateTime','EffectiveDate','GroupEffectiveDate','Birthdate','DateBenefitsEnd'):=list(as.Date(AccountVerifiedDateTime,tz=''),as.Date(EffectiveDate,tz=''),as.Date(GroupEffectiveDate,tz=''),as.Date(Birthdate,tz=''),as.Date(DateBenefitsEnd,tz=''))]
all_dat[,c('RowCreatedDateTime','EffectiveDate','GroupEffectiveDate','Birthdate','DateBenefitsEnd'):=list(as.Date(RowCreatedDateTime,tz=''),as.Date(EffectiveDate,tz=''),as.Date(GroupEffectiveDate,tz=''),as.Date(Birthdate,tz=''),as.Date(DateBenefitsEnd,tz=''))]

all_dat[,Touch2:=ifelse(Touch2Det=='Control','Control',ifelse(is.na(Touch2Det),'NA','Treat'))]
all_dat[,Touch1:=ifelse(Treat=='Control','Control','Treat')]

all_dat[,c('TreatmentMethod2','TreatmentFormat2','TreatmentPS'):=list(ifelse(Touch2%in%c('ActNow_Letter_NewPS','ActNow_Comic_OldPS'),'ActNow',ifelse(Touch2%in%c('Benefit_Letter_OldPS','Benefit_Comic_NewPS'),'Benefit','Control')),
                                                                      ifelse(Touch2%in%c('ActNow_Letter_NewPS','Benefit_Letter_OldPS'),'Letter',ifelse(Touch2%in%c('ActNow_Comic_OldPS','Benefit_Comic_NewPS'),'Comic','Control')),
                                                                      ifelse(Touch2%in%c('ActNow_Letter_NewPS','Benefit_Comic_NewPS'),'New',ifelse(Touch2%in%c('ActNow_Comic_OldPS','Benefit_Letter_OldPS'),'Old','Control')))]
all_dat[,Treat2:=factor(Touch2,levels=c('Control','ActNow_Comic_OldPS','ActNow_Letter_NewPS','Benefit_Letter_OldPS','Benefit_Comic_NewPS'))]
all_dat[,TreatmentMethod2:=factor(TreatmentMethod2,levels=c('Control','ActNow','Benefit'))]
all_dat[,TreatmentFormat2:=factor(TreatmentFormat2,levels=c('Control','Comic','Letter'))]
all_dat[,TreatmentPS:=factor(TreatmentPS,levels=c('Control','New','Old'))]
all_dat[,BenefitEndDate:=EffectiveDate+60]
all_dat[,MayOrJune:=ifelse(EffectiveDate<'2016-06-01','May','June')]

# all_dat=all_dat[is.na(AccountVerifiedDateTime) | AccountVerifiedDateTime>'2016-06-14']
all_dat=all_dat[is.na(RowCreatedDateTime) | RowCreatedDateTime>'2016-06-14']
all_dat[RowCreatedDateTime>='2016-08-12',c('RowCreatedDateTime','IsRegistered'):=list(NA,0)]

all_dat[,list(sum(IsRegistered),.N),by=c('Touch1','Touch2')][,list(sum(V1)/sum(N)),by=Touch1]
all_dat[,list(sum(IsRegistered),.N),by=c('Touch1','Touch2')][,list(sum(V1)/sum(N)),by=Touch2]
all_dat[is.na(Touch2),Touch2:='NoTouch2']

all_dat[MayOrJune=='June' & Touch2!='NoTouch2',list(sum(IsRegistered),.N,sum(IsRegistered)/.N),by=c('Touch1','Touch2')]
# all_dat2[MayOrJune=='June',list(sum(IsRegistered),.N,sum(IsRegistered)/.N),by=c('Touch1','Touch2')]

all_dat[,list(sum(IsRegistered),.N,sum(IsRegistered)/.N),by=c('Touch1','Touch2')]
# all_dat2[,list(sum(IsRegistered),.N,sum(IsRegistered)/.N),by=c('Touch1','Touch2')]

# setkeyv(all_dat,c('ClientMEMBERID','LookupRuleGroupid')) ; setkeyv(all_dat2,c('ClientMEMBERID','LookupRuleGroupid'))
# tmp=all_dat[,list(ClientMEMBERID,LookupRuleGroupid,Treat,Touch1,Touch2,Touch2Det,MayOrJune)][all_dat2[,list(ClientMEMBERID,LookupRuleGroupid,Treat,Touch1,Treat2,Touch2)]]
# tmp[,.N,by=c('Touch2','i.Touch2')]


glm1=glm(V1~Touch1+Touch2+MayOrJune+offset(log(N)),data=all_dat[,list(sum(IsRegistered),.N),by=c('Touch1','Touch2','MayOrJune')],family='poisson')
summary(glm1)
beta=coef(glm1)
exp(beta[1]) # control ; control
exp(beta[1]+beta[2])-exp(beta[1]) # control ; Treat2 vs Control
exp(beta[1]+beta[4])-exp(beta[1]) # Treat1 ; control Vs Control
exp(beta[1]+beta[2]+beta[4])-exp(beta[1]) # Treat1 ; control Vs Control

glm1=glm(V1~Touch1+Touch2+offset(log(N)),data=all_dat[Touch2!='NoTouch2',list(sum(IsRegistered),.N),by=c('Touch1','Touch2')],family='poisson')
summary(glm1)
beta=coef(glm1)
exp(beta[1]) # control ; control
exp(beta[1]+beta[2])-exp(beta[1]) # Treat1 ; control Vs Control
exp(beta[1]+beta[3])-exp(beta[1]) # control ; Treat2 vs Control
exp(beta[1]+beta[2]+beta[3])-exp(beta[1]) # Treat1 ; control Vs Control

glm1=glm(V1~Touch1+Touch2+offset(log(N)),data=all_dat[Touch2!='NoTouch2' & MayOrJune=='June',list(sum(IsRegistered),.N),by=c('Touch1','Touch2')],family='poisson')
summary(glm1)
beta=coef(glm1)
exp(beta[1]) # control ; control
exp(beta[1]+beta[2])-exp(beta[1]) # Treat1 ; control Vs Control
exp(beta[1]+beta[3])-exp(beta[1]) # control ; Treat2 vs Control
exp(beta[1]+beta[2]+beta[3])-exp(beta[1]) # Treat1 ; control Vs Control


all_dat[,id:=1:nrow(all_dat)]
all_dat[,registered2:=IsRegistered]
all_dat[,StartTime:=as.numeric(round(difftime('2016-06-14',EffectiveDate,units='days'),0))]
# all_dat[,Time2:=as.numeric(round(difftime(AccountVerifiedDateTime,EffectiveDate,units='days'),0))]
all_dat[,Time2:=as.numeric(round(difftime(RowCreatedDateTime,EffectiveDate,units='days'),0))]

all_dat[is.na(Time2),registered2:=0]
all_dat[,registered2:=factor(registered2)]
all_dat[,Time2:=list(min(c(Time2+1,as.numeric(round(difftime(as.Date(Sys.time(),tz=""),EffectiveDate,units='days'),0))),na.rm=TRUE)),by=id]
md=max(all_dat$Time2)


# fit.Registered=summary(survfit(Surv(StartTime,Time2, registered2==1)~Touch1+Touch2, data= all_dat[Touch2!='NoTouch2']),time=0:md)
# fit.Registered=summary(survfit(Surv(Time2, registered2==1)~Touch1+Touch2, data= all_dat[Touch2!='NoTouch2']),time=0:md)
# fit.Registered=summary(survfit(Surv(Time2, registered2==1)~Touch1+Touch2, data= all_dat[MayOrJune=='June' & Touch2!='NoTouch2']),time=0:md)
fit.Registered=summary(survfit(Surv(Time2, registered2==1)~Touch1+Touch2, data= all_dat),time=0:md)

sdata.time<-data.table(time=fit.Registered$time, surv=fit.Registered$surv, lower=fit.Registered$lower, upper=fit.Registered$upper)
sdata.time$Group<-fit.Registered$strata
sdata.time$surv <- sdata.time$surv * 100
sdata.time$lower <- sdata.time$lower * 100
sdata.time$upper <- sdata.time$upper * 100
# sdata.time$Group=substr(sdata.time$Group,17,50)
md=max(all_dat$Time2)
pdf('~/GP0284-Research-MotionRegistration/DanH/Phase2TouchEffects.pdf',width=11,height=8.5)
ggplot(sdata.time[time<=102],aes(x=time,y=100-surv,color=Group,group=Group))+
  geom_line()+
  geom_vline(aes(xintercept=60),linetype=2,alpha=.5,size=.5)+
#   scale_y_continuous(breaks=seq(80,100,5),labels=seq(80,100,5),limits=c(80,100))+
  scale_x_continuous(breaks=seq(0,102,5),labels=seq(0,102,5),limits=c(0,102))+
  xlab('Days Since Member Effective Date')+ylab('Registration (%)')+
  theme(axis.line = element_line(color = 'black'),legend.position="bottom",legend.text = element_text(size = 10))+guides(col = guide_legend(nrow = 2))
dev.off()


sdata.time[Group=='Touch1=Control, Touch2=Control ',Group:=list('No mailings')]
sdata.time[Group=='Touch1=Control, Touch2=Treat   ',Group:=list('One mailing in July')]
sdata.time[Group=='Touch1=Treat, Touch2=Control ',Group:=list('One mailing in June')]
sdata.time[Group=='Touch1=Treat, Touch2=Treat   ',Group:=list('Both mailings')]
sdata.time=sdata.time[!Group%in%c('Touch1=Control, Touch2=NoTouch2','Touch1=Treat, Touch2=NoTouch2')]

pdf('~/GP0284-Research-MotionRegistration/DanH/Phase2TouchEffects_WriteUp.pdf',width=11,height=8.5)
ggplot(sdata.time,aes(x=time,y=100-surv,color=Group,group=Group))+
  geom_line(size=1)+
  geom_vline(aes(xintercept=60),linetype=2,alpha=.5,size=.5)+
  scale_y_continuous(breaks=seq(0,100,5),labels=seq(0,100,5))+
  scale_x_continuous(breaks=seq(0,100,5),labels=seq(0,100,5),limits=c(0,100))+
  scale_color_discrete(name="")+
  xlab('Days Since Member Effective Date')+ylab('Registration (%)')+
  theme(panel.grid.major=element_line(color='grey'),axis.line = element_line(color = 'grey'),legend.position="bottom",legend.text = element_text(size = 10),panel.background = element_rect(fill='white'))+guides(col = guide_legend(nrow = 2))
dev.off()

tmp=all_dat[,list(sum(registered2==1),.N),by=c('Time2','Touch1','Touch2')][order(Time2)]
tmp2=all_dat[,.N,by=c('Touch1','Touch2')]
tmp2=tmp2[,list(rep(paste(Touch1,";",Touch2,sep=""),each=length(min(tmp$Time2):max(tmp$Time2))),min(tmp$Time2):max(tmp$Time2),rep(N,each=length(min(tmp$Time2):max(tmp$Time2))))]
setnames(tmp2,names(tmp2),c('Treatment','Time2','Value'))
tmp[,Treat2:=paste(Touch1,";",Touch2,sep="")]
setkeyv(tmp2,c('Time2','Treatment')) ; setkeyv(tmp,c('Time2','Treat2'))
tmp=tmp[tmp2]
tmp=tmp[is.na(V1),c('V1','N'):=list(0,0)]
# tmp[,Value:=NULL]
tmp=tmp[,list(Time2,cumsum(V1)),by=c('Treat2')]
tmp[,Treatment:=Treat2]
p2=ggplot(tmp,aes(x=Time2,y=V2,color=Treatment))+
  geom_line()+
  #   geom_point()+
  scale_y_continuous(breaks=seq(0,max(tmp$V2)+5,10),labels=seq(0,max(tmp$V2)+5,10))+
  scale_x_continuous(breaks=seq(10,max(tmp$Time2),10),labels=seq(10,max(tmp$Time2),10))+
  xlab('Time Since Member Effective Date')+ylab('Number of Cumulative Members Registered')+
  theme(axis.line = element_line(color = 'black'),legend.position="bottom",legend.text = element_text(size = 8))+guides(col = guide_legend(nrow = 3))

