
library(data.table)
library(savvy)
library(xtable)
library(survival)
library(lme4)
library(MASS)
library(multcomp)

all_dat=data.table(read.odbc("Devsql14",dbQuery='select * from [pdb_AllSaversRegistration].[dbo].[DirectMailList_Phase3_Campaign2_Registrations]',as.is=TRUE))
all_dat[,c('RuleGroupName','FirstName','Lastname','AddressLine','City','StateCode','Zipcode','TotalEligibles','RegistrationRate','GroupAge','AgentLastname','PolicyID','AdminInsured','AdminContactGender','AdminPhone','AdminEmail','AdminContact','Admin_AvgStepsforEnrolledDays','AdminAllwAmtPM','GroupStreet','GroupStreet2','GroupCity','GroupState','GroupZip','GroupSICCode','Rn','Sic','AdminFirstname','CEOFirstname','CEO','AdminContact_FullName'):=NULL]

treatGroups=data.table(read.csv("/work/dhalterman/AllSaversMotionGP0284/Phase3_Campaign2/Company_Treatments_Phase3.csv"))

setkeyv(treatGroups,'LookupRuleGroupid') ; setkeyv(all_dat,'LookupRuleGroupid')
all_dat=treatGroups[,list(LookupRuleGroupid,Treat)][all_dat]

all_dat[,c('isregistered'):=list(as.integer(isregistered))]
all_dat[,age:=round(as.numeric(difftime(as.Date('2016-11-01'),Birthdate)/364.25),0),by=Birthdate]
all_dat[,BinAge:=ifelse(age>=38,'Older','Younger')]

setnames(all_dat,c('AccountCreatedDate','DateBenefitsEnd'),c('RegistrationDate','BenefitEndDate'))
all_dat[,c('RegistrationDate','EffectiveDate','GroupEffectiveDate','Birthdate','BenefitEndDate'):=list(as.Date(RegistrationDate,tz=''),as.Date(EffectiveDate,tz=''),as.Date(GroupEffectiveDate,tz=''),as.Date(Birthdate,tz=''),as.Date(BenefitEndDate,tz=''))]
all_dat[,c('TreatmentMember','TreatmentCEO','TreatmentBC'):=list(ifelse(Treat%in%c('Member/BC/CEO','Member','Member/BC','Member/CEO'),'Members Treated','Members Not Treated'),ifelse(Treat%in%c('Member/BC/CEO','Member/CEO','BC/CEO','CEO'),'CEOs Treated','CEOs Not Treated'),ifelse(Treat%in%c('Member/BC/CEO','BC','Member/BC','BC/CEO'),'BCs Treated','BCs Not Treated'))]
all_dat[Treat=='Control',c('TreatmentMember','TreatmentCEO','TreatmentBC'):='Control']
all_dat[,Treat:=factor(Treat,levels=c('Control','Member/BC/CEO','Member/CEO','Member/BC','BC/CEO','Member','BC','CEO'))]
all_dat[,TreatmentMember:=factor(TreatmentMember,levels=c('Control','Members Treated','Members Not Treated'))]
all_dat[,TreatmentCEO:=factor(TreatmentCEO,levels=c('Control','CEOs Treated','CEOs Not Treated'))]
all_dat[,TreatmentBC:=factor(TreatmentBC,levels=c('Control','BCs Treated','BCs Not Treated'))]
all_dat[,OthersReg:=ifelse(Registered>0,'Others Registered Prior to Mailing - Yes','Others Registered Prior to Mailing - No')]
all_dat=all_dat[is.na(RegistrationDate) | RegistrationDate>='2016-10-01']

tmp=data.table(Dates=seq(as.Date("2016-10-01"),as.Date('2016-11-01'),by="1 day"),Value=0)
all_dat[RegistrationDate>='2016-11-02',RegistrationDate:=NA]

all_dat[,c('TreatmentMember','TreatmentCEO','TreatmentBC'):=list(ifelse(Treat%in%c('Member/BC/CEO','Member','Member/BC','Member/CEO'),'Members Treated','Control'),ifelse(Treat%in%c('Member/BC/CEO','Member/CEO','BC/CEO','CEO'),'CEOs Treated','Control'),ifelse(Treat%in%c('Member/BC/CEO','BC','Member/BC','BC/CEO'),'BCs Treated','Control'))]
all_dat[Treat=='Control',c('TreatmentMember','TreatmentCEO','TreatmentBC'):='Control']
all_dat[,Treat:=factor(Treat,levels=c('Control','Member/BC/CEO','Member/CEO','Member/BC','BC/CEO','Member','BC','CEO'))]
all_dat[,TreatmentMember:=factor(TreatmentMember,levels=c('Control','Members Treated'))]
all_dat[,TreatmentCEO:=factor(TreatmentCEO,levels=c('Control','CEOs Treated'))]
all_dat[,TreatmentBC:=factor(TreatmentBC,levels=c('Control','BCs Treated'))]

glm1=glm(V1~TreatmentCEO*TreatmentBC*TreatmentMember+offset(log(N)),data=all_dat[,list(sum(!is.na(RegistrationDate)),.N),by=c('TreatmentCEO','TreatmentBC','TreatmentMember')],family='poisson')
summary(glm1)
beta=coef(glm1)
exp(beta[1]) # control
exp(beta[1]+beta[2])-exp(beta[1]) # CEO 
exp(beta[1]+beta[3])-exp(beta[1]) # BC
exp(beta[1]+beta[4])-exp(beta[1]) # Member
exp(beta[1]+beta[2]+beta[3]+beta[5])-exp(beta[1]) # CEO + BC 
exp(beta[1]+beta[2]+beta[4]+beta[6])-exp(beta[1]) # CEO + Member
exp(beta[1]+beta[3]+beta[4]+beta[7])-exp(beta[1]) # BC + Member
exp(beta[1]+beta[2]+beta[3]+beta[4]+beta[5]+beta[6]+beta[7])-exp(beta[1]) # CEO + BC + Member

glm1=glm(V1~TreatmentCEO+TreatmentBC+TreatmentMember+offset(log(N)),data=all_dat[,list(sum(!is.na(RegistrationDate)),.N),by=c('TreatmentCEO','TreatmentBC','TreatmentMember')],family='poisson')
summary(glm1)
beta=coef(glm1)
exp(beta[1]) # control
exp(beta[1]+beta[2])-exp(beta[1]) # CEO 
exp(beta[1]+beta[3])-exp(beta[1]) # BC
exp(beta[1]+beta[4])-exp(beta[1]) # Member
exp(beta[1]+beta[2]+beta[3])-exp(beta[1]) # CEO + BC 
exp(beta[1]+beta[2]+beta[4])-exp(beta[1]) # CEO + Member
exp(beta[1]+beta[3]+beta[4])-exp(beta[1]) # BC + Member
exp(beta[1]+beta[2]+beta[3]+beta[4])-exp(beta[1]) # CEO + BC + Member
exp(beta[1]) # Control Effect
exp(beta[2]) # CEO Effect
exp(beta[3]) # BC Effect
exp(beta[4]) # Member Effect




all_dat[,id:=1:nrow(all_dat)]
all_dat[,registered2:=IsRegistered]
all_dat[,StartTime:=as.numeric(round(difftime('2016-06-14',EffectiveDate,units='days'),0))]
all_dat[,Time2:=as.numeric(round(difftime(AccountVerifiedDateTime,EffectiveDate,units='days'),0))]
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
ggplot(sdata.time,aes(x=time,y=100-surv,color=Group,group=Group))+
  geom_line()+
  geom_vline(aes(xintercept=60),linetype=2,alpha=.5,size=.5)+
  #   scale_y_continuous(breaks=seq(80,100,5),labels=seq(80,100,5),limits=c(80,100))+
  scale_x_continuous(breaks=seq(0,md,5),labels=seq(0,md,5),limits=c(0,md))+
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

