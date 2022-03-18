library(savvy)
library(forecast)

data.member <- read.odbc("devsql10", dbQuery = "SELECT *
                         FROM pdb_PharmaMotion.dbo.Member_v2", as.is = TRUE)

data.membersum<-read.odbc("devsql10", dbQuery = "SELECT *
                          FROM pdb_PharmaMotion.dbo.MemberSummary_v2", as.is = TRUE)

data.membersum<-read.odbc("devsql10", dbQuery = "SELECT MemberID, PlcyEnrlMotion_MonthInd, YearMo
                          FROM pdb_PharmaMotion.dbo.MemberSummary_v2", as.is = TRUE)

data.drug1 <- read.odbc("devsql10", dbQuery = "SELECT *
                        FROM pdb_PharmaMotion.dbo.MemberSummaryDrugClassAllw_v2", as.is = TRUE)

data.total <- merge(data.membersum, data.member, by="MemberID", all=T)
data.drugtotal<-merge(data.total, data.drug1, by=c("MemberID", "YearMo"), all.x=T)

data.drugtotal<-data.drugtotal[data.drugtotal$Enrl_Plan.x==1,]
data.drugtotal<-data.drugtotal[data.drugtotal$Age>17,]
data.drug<-data.drugtotal


time<-as.numeric(data.drug$YearMo)
time1<-as.factor(time)
time<-as.numeric(time1)
#data.drugtotal$Time<-time
data.drug$Time<-time

### drugs of interest
### antihyperglycemics, cardiovascular, thyriod preps, cns drugs
### cardiac drugs, diuretics


############################################################

time<-unique(sort(time))
data.drug$CNSDrugs_Allow<-as.numeric(data.drug$CNSDrugs_Allow)
data.drug$CNSDrugs_Allow[is.na(data.drug$CNSDrugs_Allow)]<-0

data.drug$Cardiovascular_Allow<-as.numeric(data.drug$Cardiovascular_Allow)
data.drug$Cardiovascular_Allow[is.na(data.drug$Cardiovascular_Allow)]<-0

data.drug$CardiacDrugs_Allow<-as.numeric(data.drug$CardiacDrugs_Allow)
data.drug$CardiacDrugs_Allow[is.na(data.drug$CardiacDrugs_Allow)]<-0


data.drug$Antihyperglycemics_Allow<-as.numeric(data.drug$Antihyperglycemics_Allow)
data.drug$Antihyperglycemics_Allow[is.na(data.drug$Antihyperglycemics_Allow)]<-0

data.drug$Diuretics_Allow<-as.numeric(data.drug$Diuretics_Allow)
data.drug$Diuretics_Allow[is.na(data.drug$Diuretics_Allow)]<-0

data.drug$ThyroidPreps_Allow<-as.numeric(data.drug$ThyroidPreps_Allow)
data.drug$ThyroidPreps_Allow[is.na(data.drug$ThyroidPreps_Allow)]<-0

data.drug$AntiparkinsonDrugs_Allow<-as.numeric(data.drug$AntiparkinsonDrugs_Allow)
data.drug$AntiparkinsonDrugs_Allow[is.na(data.drug$AntiparkinsonDrugs_Allow)]<-0

data.drug$RX_Spend_Maint<-data.drug$CNSDrugs_Allow + data.drug$CardiacDrugs_Allow + 
  data.drug$Cardiovascular_Allow + data.drug$Antihyperglycemics_Allow + 
  data.drug$Diuretics_Allow + data.drug$ThyroidPreps_Allow +
  data.drug$AntiparkinsonDrugs_Allow

mean_rx_maint<-tapply(as.numeric(data.drug$RX_Spend_Maint), data.drug$Time, mean)
#mean_drugcount<-tapply(as.numeric(data.total$DrugCount), data.total$Time, mean)


############################################################

#set up data for enrolled members only

keepids<-data.drug$MemberID[data.drug$Der_Enrl_MonthInd.x !=0]
keepids<-unique(keepids)

data.drug.enrl<-data.drug[data.drug$MemberID%in%keepids,]
data.drug.notenrl<-data.drug[!(data.drug$MemberID%in%keepids),]

time.enrl<-as.numeric(data.drug.enrl$YearMo)
time1<-as.factor(time.enrl)
time.enrl<-as.numeric(time1)
#data.drugtotal$Time<-time
data.drug.enrl$Time<-time.enrl
time.enrl<-unique(sort(time.enrl))

time.notenrl<-as.numeric(data.drug.notenrl$YearMo)
time1<-as.factor(time.notenrl)
time.notenrl<-as.numeric(time1)
#data.drugtotal$Time<-time
data.drug.notenrl$Time<-time.notenrl
time.notenrl<-unique(sort(time.notenrl))

############################################################

### time series for all spent on maintenance drugs (7 categories) over time for all members

plot(time, mean_rx_maint, cex=0 , main = "Mean RX Allowed for Maint. Drugs Per Month",
     xlab = "Month", ylab = "Mean RX Allowed")
lines(time, mean_rx_maint)
abline(v=c(12, 24), lty=2)

rxts <- ts(mean_rx_maint, frequency=12, start=c(2014,1))
rxts_comp<-decompose(rxts)

plot(time, rxts_comp$seasonal, main = "Seasonal Variation in Monthly RX Allowed for Maint. Drugs",
     xlab = "Time", cex=0)
lines(time, rxts_comp$seasonal)
abline(v=c(12, 24), lty=2)
abline(0,0, lty=2)

plot(time, rxts_comp$random, main = "Random Variation in Monthly RX Allowed for Maint. Drugs", cex=0)
lines(time, rxts_comp$random)
abline(v=c(12, 24), lty=2)


plot(time, rxts_comp$trend, main = "Overall Trend in Monthly RX Allowed for Maint. Drugs", cex=0)
lines(time, rxts_comp$trend)
abline(v=c(12, 24), lty=2)

### for motion members
mean_rx_maint_enrl<-tapply(as.numeric(data.drug.enrl$RX_Spend_Maint), data.drug.enrl$Time, mean)
mean_rx_maint_notenrl<-tapply(as.numeric(data.drug.notenrl$RX_Spend_Maint), data.drug.notenrl$Time, mean)


rxts_enrl <- ts(mean_rx_maint_enrl, frequency=12, start=c(2014,1))
rxts_enrl_comp<-decompose(rxts_enrl)
rxts_notenrl <- ts(mean_rx_maint_notenrl, frequency=12, start=c(2014,1))
rxts_notenrl_comp<-decompose(rxts_notenrl)


par(mfrow=c(2,2))

#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_rx_maint_enrl, cex=0 , main = "RX Spend for Maintenance Drugs Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed", ylim = c(0, 30))
lines(time.enrl, mean_rx_maint_enrl, col="purple")
lines(time.notenrl, mean_rx_maint_notenrl, lty=1)
lines(time, mean_rx_maint, lty=2)
abline(v=c(12, 24), lty=1)
legend("bottomright", legend = c("All", "Motion", "Not Motion"), lty = c(2,1,1), 
       col = c("black", "purple","black"), cex=.7)

plot(time.enrl, rxts_enrl_comp$seasonal, main = "Seasonal Variation in RX Spend for Maint. Drugs",
     xlab = "Time", cex=0, ylim = c(-4,5), ylab = "Variation")
lines(time.enrl, rxts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, rxts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)

#legend("topright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.7)



#plot(time.enrl, rxts_enrl_comp$random, main = "Random Variation in RX Spend for Maint. Drugs",
#     xlab = "Time", cex=0, ylim = c(-10,10))
#lines(time.enrl, rxts_enrl_comp$random, col="purple")
#lines(time.notenrl, rxts_notenrl_comp$random, lty=1)
#abline(v=c(12, 24), lty=2)


plot(time.enrl, rxts_enrl_comp$trend, main = "Trend in RX Spend for Maint. Drugs",
     xlab = "Time", cex=0, ylim = c(9, 25))
lines(time.enrl, rxts_enrl_comp$trend, col="purple")
lines(time.notenrl, rxts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.7)


#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(rxts_enrl_comp$trend[18:30]-rxts_notenrl_comp$trend[18:30])/
  rxts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference",
     main = "% Dif Between Motion and Not Motion\nin Maintenance Drug Spending over Time")
lines(c(18:30), pd)
avgdif<-mean(pd)
#10% approx

#### autocorrelation
acf(rxts, lag.max = 10)
rxts_enrl_forecasts<-forecast.Arima(rxts, h=5)
#Box.test(rxts$, lag=20, type="Ljung-Box")

pacf(rxts)

######### relative to motion

mean_rx_maint_rm<-tapply(data.drug.enrl$RX_Spend_Maint, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
rxts2 <- ts(mean_rx_maint_rm, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_rx_maint_rm, main = "RX Spend for All Maint. Drugs\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_rx_maint_rm)
lines(time2, rxts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(rxts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)



############################################################

### time series for cardiovascular spend

mean_cardio<-tapply(as.numeric(data.drug$Cardiovascular_Allow), data.drug$Time, mean)
mean_cardio_enrl<-tapply(as.numeric(data.drug.enrl$Cardiovascular_Allow), data.drug.enrl$Time, mean)
mean_cardio_notenrl<-tapply(as.numeric(data.drug.notenrl$Cardiovascular_Allow), data.drug.notenrl$Time, mean)

cardiots_enrl <- ts(mean_cardio_enrl, frequency=12, start=c(2014,1))
cardiots_enrl_comp<-decompose(cardiots_enrl)
cardiots_notenrl <- ts(mean_cardio_notenrl, frequency=12, start=c(2014,1))
cardiots_notenrl_comp<-decompose(cardiots_notenrl)

par(mfrow=c(2,2))

#plot of avg spend per month for motion and not motion
plot(time.notenrl, mean_cardio_notenrl, cex=0 , main = "Cardiovascular Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed", ylim = c(0,12))
lines(time.enrl, mean_cardio_enrl, col="purple")
lines(time.notenrl, mean_cardio_notenrl, lty=1)
lines(time, mean_cardio, lty=2)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)


plot(time.enrl, cardiots_enrl_comp$seasonal, main = "Seasonal Variation in Cardio Spend",
     xlab = "Time", cex=0, ylab = "Variation")
lines(time.enrl, cardiots_enrl_comp$seasonal, col="purple")
lines(time.notenrl, cardiots_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)

#plot(time.enrl, cardiots_enrl_comp$random, main = "Random Variation in Cardio Spend",
#     xlab = "Time", cex=0)
#lines(time.enrl, cardiots_enrl_comp$random, col="purple")
#lines(time.notenrl, cardiots_notenrl_comp$random, lty=1)
#abline(v=c(12, 24), lty=2)
#legend("topright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.8)


plot(time.enrl, cardiots_enrl_comp$trend, main = "Trend in Cardio Spend",
     xlab = "Time", cex=0, ylab = "Trend", ylim = c(13, 20))
lines(time.enrl, cardiots_enrl_comp$trend, col="purple")
lines(time.notenrl, cardiots_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)


#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(cardiots_enrl_comp$trend[18:30]-cardiots_notenrl_comp$trend[18:30])/
  cardiots_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference",
     main = "% Dif Between Motion and Not Motion\nin Cardiovascular Drug Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx

######### relative to motion

mean_cardio_rm<-tapply(data.drug.enrl$Cardiovascular_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
cardiots2 <- ts(mean_cardio_rm, frequency=12, start=c(2014,1))
cardiots2_comp<-decompose(cardiots2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_cardio_rm, main = "RX Spend for Cardiovascular Drugs\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_cardio_rm)
lines(time2, cardiots2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(cardiots2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)


############################################################

### time series for antihyp

mean_hyp<-tapply(as.numeric(data.drug$Antihyperglycemics_Allow), data.drug$Time, mean)
mean_hyp_enrl<-tapply(as.numeric(data.drug.enrl$Antihyperglycemics_Allow), data.drug.enrl$Time, mean)
mean_hyp_notenrl<-tapply(as.numeric(data.drug.notenrl$Antihyperglycemics_Allow), data.drug.notenrl$Time, mean)

hypts_enrl <- ts(mean_hyp_enrl, frequency=12, start=c(2014,1))
hypts_enrl_comp<-decompose(hypts_enrl)
hypts_notenrl <- ts(mean_hyp_notenrl, frequency=12, start=c(2014,1))
hypts_notenrl_comp<-decompose(hypts_notenrl)


par(mfrow=c(2,2))
#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_hyp_enrl, cex=0 , main = "Antihyperglycemic Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed", ylim = c(0, 15))
lines(time.enrl, mean_hyp_enrl, col="purple")
lines(time.notenrl, mean_hyp_notenrl, lty=1)
lines(time, mean_hyp, lty=2)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)


plot(time.enrl, hypts_enrl_comp$seasonal, main = "Seasonal Variation in Antihyperglycemic Spend",
     xlab = "Time", cex=0, ylim = c(-3,3))
lines(time.enrl, hypts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, hypts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)


plot(time.enrl, hypts_enrl_comp$trend, main = "Trend in Antihyperglycemic Spend",
     xlab = "Time", cex=0, ylim = c(4, 12))
lines(time.enrl, hypts_enrl_comp$trend, col="purple")
lines(time.notenrl, hypts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)

#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(hypts_enrl_comp$trend[18:30]-hypts_notenrl_comp$trend[18:30])/
  hypts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference",
     main = "% Dif Between Motion and Not Motion\nin Antihyperglycemic Drug Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx

######### relative to motion

mean_ah_rm<-tapply(data.drug.enrl$Antihyperglycemics_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
ahts2 <- ts(mean_ah_rm, frequency=12, start=c(2014,1))
ahts2_comp<-decompose(ahts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_ah_rm, main = "RX Spend for Antihyperglycemics\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_ah_rm)
lines(time2, ahts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(ahts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)


############################################################

### time series for antipark

mean_ap<-tapply(as.numeric(data.drug$AntiparkinsonDrugs_Allow), data.drug$Time, mean)
mean_ap_enrl<-tapply(as.numeric(data.drug.enrl$AntiparkinsonDrugs_Allow), data.drug.enrl$Time, mean)
mean_ap_notenrl<-tapply(as.numeric(data.drug.notenrl$AntiparkinsonDrugs_Allow), data.drug.notenrl$Time, mean)

apts_enrl <- ts(mean_ap_enrl, frequency=12, start=c(2014,1))
apts_enrl_comp<-decompose(apts_enrl)
apts_notenrl <- ts(mean_ap_notenrl, frequency=12, start=c(2014,1))
apts_notenrl_comp<-decompose(apts_notenrl)

data.drug.park<-data.drug[data.drug$AntiparkinsonDrugs_Allow>0,]
data.drug.park.enrl<-data.drug[data.drug.park$MemberID%in%keepids,]
data.drug.park.notenrl<-data.drug[!(data.drug.park$MemberID%in%keepids),]


par(mfrow=c(2,2))
#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_ap_enrl, cex=0 , main = "Antiparkinson Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed", ylim=c(0, .4))
lines(time.enrl, mean_ap_enrl, col="purple")
lines(time.notenrl, mean_ap_notenrl, lty=1)
lines(time, mean_ap, lty=2)
abline(v=c(12, 24), lty=2)
legend("topleft", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)


plot(time.enrl,apts_enrl_comp$seasonal, main = "Seasonal Variation in Antiparkinson Spend",
     xlab = "Time", cex=0, ylim = c(-2,2), ylab="Variation")
lines(time.enrl, hypts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, hypts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)


plot(time.enrl, apts_enrl_comp$trend, main = "Trend in Antiparkinson Spend",
     xlab = "Time", cex=0, ylim=c(0,.3), ylab="Trend")
lines(time.enrl, apts_enrl_comp$trend, col="purple")
lines(time.notenrl, apts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)

#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(apts_enrl_comp$trend[18:30]-apts_notenrl_comp$trend[18:30])/
  apts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference",
     main = "% Dif Between Motion and Not Motion\nin Antihyperglycemic Drug Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx

######### relative to motion

mean_ap_rm<-tapply(data.drug.enrl$AntiparkinsonDrugs_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
apts2 <- ts(mean_ap_rm, frequency=12, start=c(2014,1))
apts2_comp<-decompose(apts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_ap_rm, main = "RX Spend for Antiparksinsons\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_ap_rm)
lines(time2, apts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"), cex=.9)
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(apts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)

############################################################


### time series for thyroid

mean_thyr<-tapply(as.numeric(data.drug$ThyroidPreps_Allow), data.drug$Time, mean)
mean_thyr_enrl<-tapply(as.numeric(data.drug.enrl$ThyroidPreps_Allow), data.drug.enrl$Time, mean)
mean_thyr_notenrl<-tapply(as.numeric(data.drug.notenrl$ThyroidPreps_Allow), data.drug.notenrl$Time, mean)

thyrts_enrl <- ts(mean_thyr_enrl, frequency=12, start=c(2014,1))
thyrts_enrl_comp<-decompose(thyrts_enrl)
thyrts_notenrl <- ts(mean_thyr_notenrl, frequency=12, start=c(2014,1))
thyrts_notenrl_comp<-decompose(thyrts_notenrl)

par(mfrow=c(2,2))


#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_thyr_enrl, cex=0 , main = "Thyroid Prep Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed")
lines(time.enrl, mean_thyr_enrl, col="purple")
lines(time.notenrl, mean_thyr_notenrl, lty=1)
lines(time, mean_thyr, lty=2)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)

plot(time.enrl, thyrts_enrl_comp$seasonal, main = "Seasonal Variation in Thyroid Prep Spend",
     xlab = "Time", cex=0, ylab = "Variation")
lines(time.enrl, thyrts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, thyrts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)


plot(time.enrl, thyrts_enrl_comp$trend, main = "Trend in Thyroid Prep Spend",
     xlab = "Time", cex=0, ylab = "Trend", ylim = c(0, 1.4))
lines(time.enrl, thyrts_enrl_comp$trend, col="purple")
lines(time.notenrl, thyrts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)



#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(thyrts_enrl_comp$trend[18:30]-thyrts_notenrl_comp$trend[18:30])/
  thyrts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference", ylim = c(.39,.51),
     main = "% Dif Between Motion and Not Motion\nin Thyroid Prep Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx


######### relative to motion

mean_thyr_rm<-tapply(data.drug.enrl$ThyroidPreps_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
thyrts2 <- ts(mean_thyr_rm, frequency=12, start=c(2014,1))
thyrts2_comp<-decompose(thyrts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_thyr_rm, main = "RX Spend for Thyroid Preps\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_thyr_rm)
lines(time2, thyrts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(thyrts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)


###########################################################

### time series for cns

mean_cns<-tapply(as.numeric(data.drug$CNSDrugs_Allow), data.drug$Time, mean)
mean_cns_enrl<-tapply(as.numeric(data.drug.enrl$CNSDrugs_Allow), data.drug.enrl$Time, mean)
mean_cns_notenrl<-tapply(as.numeric(data.drug.notenrl$CNSDrugs_Allow), data.drug.notenrl$Time, mean)

cnsts_enrl <- ts(mean_cns_enrl, frequency=12, start=c(2014,1))
cnsts_enrl_comp<-decompose(cnsts_enrl)
cnsts_notenrl <- ts(mean_cns_notenrl, frequency=12, start=c(2014,1))
cnsts_notenrl_comp<-decompose(cnsts_notenrl)

par(mfrow=c(2,2))

#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_cns_enrl, cex=0 , main = "CNS Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed")
lines(time.enrl, mean_cns_enrl, col="purple")
lines(time.notenrl, mean_cns_notenrl, lty=1)
lines(time, mean_cns, lty=2)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)



plot(time.enrl, cnsts_enrl_comp$seasonal, main = "Seasonal Variation in CNS Spend",
     xlab = "Time", cex=0, ylim = c(-1, 2.3), ylab = "Variation")
lines(time.enrl, cnsts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, cnsts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)


plot(time.enrl, cnsts_enrl_comp$trend, main = "Trend in CNS Spend",
     xlab = "Time", cex=0, ylab = "Trend")
lines(time.enrl, cnsts_enrl_comp$trend, col="purple")
lines(time.notenrl, cnsts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)


#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(cnsts_enrl_comp$trend[18:30]-cnsts_notenrl_comp$trend[18:30])/
  cnsts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference",
     main = "% Dif Between Motion and Not Motion\nin CNS Drug Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx


######### relative to motion

mean_cns_rm<-tapply(data.drug.enrl$CNSDrugs_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
cnsts2 <- ts(mean_cns_rm, frequency=12, start=c(2014,1))
cnsts2_comp<-decompose(cnsts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_cns_rm, main = "RX Spend for CNS Drugs\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_cns_rm)
lines(time2, cnsts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(cnsts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)


############################################################


### time series for cardiac

mean_cardiac<-tapply(as.numeric(data.drug$CardiacDrugs_Allow), data.drug$Time, mean)
mean_cardiac_enrl<-tapply(as.numeric(data.drug.enrl$CardiacDrugs_Allow), data.drug.enrl$Time, mean)
mean_cardiac_notenrl<-tapply(as.numeric(data.drug.notenrl$CardiacDrugs_Allow), data.drug.notenrl$Time, mean)

cardiacts_enrl <- ts(mean_cardiac_enrl, frequency=12, start=c(2014,1))
cardiacts_enrl_comp<-decompose(cardiacts_enrl)
cardiacts_notenrl <- ts(mean_cardiac_notenrl, frequency=12, start=c(2014,1))
cardiacts_notenrl_comp<-decompose(cardiacts_notenrl)

par(mfrow=c(2,2))

#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_cardiac_enrl, cex=0 , main = "Cardiac Drugs Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed")
lines(time.enrl, mean_cardiac_enrl, col="purple")
lines(time.notenrl, mean_cardiac_notenrl, lty=1)
lines(time, mean_cardiac, lty=2)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)



plot(time.enrl, cardiacts_enrl_comp$seasonal, main = "Seasonal Variation in Cardiac Drugs Spend",
     xlab = "Time", cex=0, ylab = "Seasonal")
lines(time.enrl, cardiacts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, cardiacts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)


plot(time.enrl, cardiacts_enrl_comp$trend, main = "Trend in Cardiac Drugs Spend",
     xlab = "Time", cex=0, ylab = "Trend")
lines(time.enrl, cardiacts_enrl_comp$trend, col="purple")
lines(time.notenrl, cardiacts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)



#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(cardiacts_enrl_comp$trend[18:30]-cardiacts_notenrl_comp$trend[18:30])/
  cardiacts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference", ylim = c(.13, .18),
     main = "% Dif Between Motion and Not Motion\nin Cardiac Drug Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx

######### relative to motion

mean_cardiac_rm<-tapply(data.drug.enrl$CardiacDrugs_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
cardiacts2 <- ts(mean_cardiac_rm, frequency=12, start=c(2014,1))
cardiacts2_comp<-decompose(cardiacts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_cardiac_rm, main = "RX Spend for Cardiac Drugs\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_cardiac_rm)
lines(time2, cardiacts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(cardiacts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)



############################################################



### time series for diuretics

mean_diur<-tapply(as.numeric(data.drug$Diuretics_Allow), data.drug$Time, mean)
mean_diur_enrl<-tapply(as.numeric(data.drug.enrl$Diuretics_Allow), data.drug.enrl$Time, mean)
mean_diur_notenrl<-tapply(as.numeric(data.drug.notenrl$Diuretics_Allow), data.drug.notenrl$Time, mean)

diurts_enrl <- ts(mean_diur_enrl, frequency=12, start=c(2014,1))
diurts_enrl_comp<-decompose(diurts_enrl)
diurts_notenrl <- ts(mean_diur_notenrl, frequency=12, start=c(2014,1))
diurts_notenrl_comp<-decompose(diurts_notenrl)

par(mfrow=c(2,2))


#plot of avg spend per month for motion and not motion
plot(time.enrl, mean_diur_enrl, cex=0 , main = "Diuretics Spend Per Month",
     xlab = "Month", ylab = "Mean Spend Allowed")
lines(time.enrl, mean_diur_enrl, col="purple")
lines(time.notenrl, mean_diur_notenrl, lty=1)
lines(time, mean_diur, lty=2)
abline(v=c(12, 24), lty=2)
legend("topright", legend = c("All", "Motion", "Not Motion"), 
       lty = c(2,1,1), col = c("black", "purple","black"), cex=.8)



plot(time.enrl, diurts_enrl_comp$seasonal, main = "Seasonal Variation in Diuretics Spend",
     xlab = "Time", cex=0, ylab = "Seasonal")
lines(time.enrl, diurts_enrl_comp$seasonal, col="purple")
lines(time.notenrl, diurts_notenrl_comp$seasonal)
abline(v=c(12, 24), lty=2)
#legend(22.1,10, legend = c("Motion", "Not Motion"), lty = c(1,1), 
#       col = c( "purple","black"), cex=.67)


plot(time.enrl, diurts_enrl_comp$trend, main = "Trend in Diuretics Spend",
     xlab = "Time", cex=0, ylab = "Trend", ylim = c(0, .4))
lines(time.enrl, diurts_enrl_comp$trend, col="purple")
lines(time.notenrl, diurts_notenrl_comp$trend, lty=1)
abline(v=c(12, 24), lty=2)
legend("bottomright", legend = c("Motion", "Not Motion"), lty = c(1,1), 
       col = c( "purple","black"), cex=.8)


#########

## quantify differences in trend
## look at months 18 (after trend stabilizes) to 30 (where trend data ends)

pd<-(diurts_enrl_comp$trend[18:30]-diurts_notenrl_comp$trend[18:30])/
  diurts_notenrl_comp$trend[18:30]

pd
plot(c(18:30), pd, cex=0, xlab = "Time", ylab = "% Difference",
     main = "% Dif Between Motion and Not Motion\nin Diuretics Spending over Time")
lines(c(18:30), pd)
(avgdif<-mean(pd))
#10% approx

######### relative to motion

mean_diur_rm<-tapply(data.drug.enrl$Diuretics_Allow, data.drug.enrl$Der_Enrl_MonthInd.x, mean)
diurts2 <- ts(mean_diur_rm, frequency=12, start=c(2014,1))
diurts2_comp<-decompose(diurts2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))

plot(time2, mean_diur_rm, main = "RX Spend for Diuretics\nRelative to Motion",
     xlab = "Time", cex=0, ylab = "RX Spend")
lines(time2, mean_diur_rm)
lines(time2, diurts2_comp$trend, col="purple")
abline(v=c(-12,0,12), lty=2)
legend("topleft", legend = c("Trend", "Overall"), lty = c(1,1), 
       col = c( "purple","black"))
# calculate % growth from trendline for -12, 0, 12

trend<-as.numeric(diurts2_comp$trend)
a<-trend[time2==-12]
a
b<-trend[time2==0]
b
c<-trend[time2==12]
c

(peryear1<-(b-a)/a)
(peryear2<-(c-b)/b)



############################################################


### caculate # of patients that use each type of "maintenance" drug

id.total<-unique(data.drug$MemberID)
# 107739 members with drug data who are 18+ years old

### antihyp
id.ah<-unique(data.drug$MemberID[data.drug$Antihyperglycemics_Allow>0])
length(id.ah)
# 5734 members
# 5.32% of users

### cardio
id.cardio<-unique(data.drug$MemberID[data.drug$Cardiovascular_Allow>0])
length(id.cardio)
# 20792 members
# 19.30%

### cardiac
id.cardiac<-unique(data.drug$MemberID[data.drug$CardiacDrugs_Allow>0])
length(id.cardiac)
# 4966
# 4.61%

### cns
id.cns<-unique(data.drug$MemberID[data.drug$CNSDrugs_Allow>0])
length(id.cns)
# 5973
# 5.54%

### diuretics
id.diur<-unique(data.drug$MemberID[data.drug$Diuretics_Allow>0])
length(id.diur)
# 5029
# 4.67%

### thyroid
id.thyr<-unique(data.drug$MemberID[data.drug$ThyroidPreps_Allow>0])
length(id.thyr)
# 6137
# 5.70%

### anti parkinson
id.ap<-unique(data.drug$MemberID[data.drug$AntiparkinsonDrugs_Allow>0])
length(id.ap)
# 454
# 

### total
id.maint<-unique(data.drug$MemberID[data.drug$RX_Spend_Maint>0])
length(id.maint)
# 30862
# 28.65%

id.drugusers<-c(id.ah, id.cardio, id.cardiac, id.cns, id.diur, id.thyr)
sort(id.drugusers)
levels(as.factor(id.drugusers))
id.dup<-id.drugusers[duplicated(id.drugusers)]
length(id.dup)



########################################