library(reshape2)
library(ggplot2)
##################################When effect size is 0.05
week<-c(998,2144,1144,598,1376)
pcp_rate<-seq(0.05,0.95, 0.05)
MayMean<-mean(week)
Month<-sum(week)

#varying pcp_rate,get power comparison, fixing sample size, significance level 0.05
r1<-power.prop.test(MayMean/9,p1=pcp_rate,p2=pcp_rate+.05,sig.level=.05,alternative='one.sided')
r2<-power.prop.test(Month/9,p1=pcp_rate,p2=pcp_rate+.05,sig.level=.05,alternative='one.sided')

total1<-cbind(r1$p1, r1$power,r2$power)
colnames(total1)<-c("PCP_rate1", "Power_Weekly", "Power_Monthly")
total1<-as.data.frame(total1)

powerdata <- melt(total1, id="PCP_rate1") 
ggplot(data=powerdata, aes(x=PCP_rate1, y=value, colour=variable)) +geom_line()

#varying power,get sample size, fixing pcp_rate at 0.5, significance level 0.05
p <-seq(0.7,0.9,0.01)#effect size
ns <- length(p)
mymat<-cbind(p)
samsize1<-array(numeric(ns*1), dim=c(ns,1))
for(j in 1: dim(mymat)[1])
{
  result <- power.prop.test(p1=0.2, p2=0.25, power = p[j], sig.level = 0.05, alternative = "one.sided")
  samsize1[j] <- ceiling(result$n)  
}
r3<-cbind(mymat, as.matrix(samsize1[,1], nrow=19, ncol=1))
colnames(r3)<-c("Power", "Sample_Size")
total2<-as.data.frame(r3)
ggplot(data=total2, aes(x=Power, y=Sample_Size))+geom_line()

#varying pcp_rate,get sample size, fixing power at 0.8, significance level 0.05
ns1<-length(pcp_rate)
mymat1<-cbind(pcp_rate)
samsize2<-array(numeric(ns1*1), dim=c(ns1,1))
for(j in 1: dim(mymat1)[1])
{
  result <- power.prop.test(p1=mymat1[j], p2=mymat1[j]+0.05, power = 0.8, sig.level = 0.05, alternative = "one.sided")
  samsize2[j] <- ceiling(result$n)  
}
r4<-cbind(mymat1, as.matrix(samsize2[,1], nrow=19, ncol=1))
colnames(r4)<-c("PCP_rate", "Sample_Size")
total3<-as.data.frame(r4)
ggplot(data=total3, aes(x=PCP_rate, y=Sample_Size))+geom_line()
