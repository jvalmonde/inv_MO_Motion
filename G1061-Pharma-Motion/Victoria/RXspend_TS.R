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

keepids<-data.matched$MemberID[data.matched$WithSteps==1]
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

############################################################

### propensity score matching

### member level

## create "most recent raf" var
data.member$RAF_2014<-as.numeric(data.member$RAF_2014)
data.member$RAF_2015<-as.numeric(data.member$RAF_2015)
data.member$RAF_2016<-as.numeric(data.member$RAF_2016)

recentraf<-vector(length=nrow(data.member))

for(i in 1:nrow(data.member)){
  rafvec<-data.member[i, 41:43]
  if(rafvec[3]==0&rafvec[2]==0){
    recentraf[i]<-rafvec[1]
  }else if(rafvec[3]==0&rafvec[2]!=0){
    recentraf[i]<-rafvec[2]
  }else if(rafvec[3]!=0){
    recentraf[i]<-rafvec[3]
  }
}

recentraf<-unlist(recentraf)
data.member$Recent_RAF<-recentraf
# 2 members have RAF of zero


### create a matched zero variable

id.enrl<-unique(data.member$MemberID[data.member$WithSteps==1])
id.notenrl<-unique(data.member$MemberID[data.member$WithSteps==0])

data.membersum2<-data.membersum[data.membersum$MemberID%in%id.total,]
data.membersum2$YearMo<-as.numeric(data.membersum2$YearMo)

matchedzero<-rep("201401", nrow(data.member))

for(i in 1:nrow(data.member)){
  memberid<-data.member$MemberID[i]
  if(data.member$WithSteps[i]==1){
    matchedzero[i]<-data.member$MotionEnrYM_FstDayWithSteps[i]
  }
}


for(i in 1:nrow(data.member)){
  memberid<-data.member$MemberID[i]
  if(data.member$WithSteps[i]==0){
    if(sum(data.membersum2$MemberID==memberid&data.membersum2$PlcyEnrlMotion_MonthInd==0)!=0){
      matchedzero[i]<-data.membersum2$YearMo[data.membersum2$MemberID==memberid&
                                                              data.membersum2$PlcyEnrlMotion_MonthInd==0]
    }else{
      matchedzero[i]<-min(data.membersum2$YearMo[data.membersum2$MemberID==memberid])
    }
  }
    print(i)
  
}

data.member$MatchedZero<-matchedzero

### set up data
data.member<-data.member[data.member$Age>17,]
data.member$Gender<-as.factor(data.member$Gender)
data.member$Age<-as.numeric(data.member$Age)
data.member$Sbscr_Ind<-as.factor(data.member$Sbscr_Ind)
data.member$MM<-as.numeric(data.member$MM)
data.member$WithSteps<-as.factor(data.member$WithSteps)
data.member$MatchedZero<-as.factor(data.member$MatchedZero)


### vars to include
set.seed(12334)

match.dat <- data.member[, c("MemberID", "Age", "Gender", "Sbscr_Ind", 
                             "Recent_RAF", "MM", "WithSteps", "MatchedZero")]
table(data.member$WithSteps)

member.ids<-unique(match.dat$MemberID[match.dat$WithSteps==1])

pm <- glm(WithSteps ~ Sbscr_Ind + Gender + scale(Age, scale = T) + scale(Recent_RAF, scale = T) 
          + scale(MM, scale = T) + MatchedZero, data = match.dat, family = "binomial")
summary(pm)

control_scores <- predict(pm)[match.dat$WithSteps == 0]  # likelihood not enrolled is enrolled
trt_scores <- predict(pm)[match.dat$WithSteps == 1]      # likelihood enrolled is enrolled

control_scores <- predict(pm, type = "response")[match.dat$WithSteps == 0]  # likelihood not enrolled is enrolled
trt_scores <- predict(pm, type = "response")[match.dat$WithSteps == 1]      # likelihood enrolled is enrolled


data.c <- as.data.frame(control_scores)
colnames(data.c) <- "Control_Scores"
plot <- ggplot(aes(x = Control_Scores), data = data.c) + geom_histogram(fill = "#4f81bd") +
  ggtitle("Not Enrolled Likelihood Before Matching")
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot
data.t <- as.data.frame(trt_scores)
colnames(data.t) <- "Treat_Scores"
plot <- ggplot(aes(x = Treat_Scores), data = data.t) + geom_histogram(fill = "#4f81bd") +
  ggtitle("Enrolled Before Matching")
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

qq <- quantile(trt_scores, seq(0,1,0.01))
treat_bucket <- cut(trt_scores, breaks = qq)
ttab <- table(treat_bucket)
control_bucket <- cut(control_scores, breaks = qq)
qtab <- table(control_bucket)
min(qtab)

which(is.na(control_scores) == TRUE)
control_scores[which(is.na(control_bucket) == TRUE)]

control_include <- rep(0, length(control_scores))
for(ii in unique(control_bucket[!is.na(control_bucket)])){
  rn <- which(control_bucket == ii)
  sp <- sample(rn, min(qtab))
  control_include[sp] <- 1
}

sum(control_include)     # 10500
data.include <- match.dat[match.dat$WithSteps == 0,]
control_primary_ids <- data.include$MemberID[control_include == 1]

data.treat <- match.dat[match.dat$WithSteps == 1,]
data.treat <- cbind(data.treat, trt_scores)
data.include <- cbind(data.include, control_scores)
data.include <- cbind(data.include, control_include)
plot <- ggplot(aes(x = control_scores), data = data.include[data.include$control_include == 1,]) + 
  geom_histogram(fill = "#4f81bd") +
  ggtitle("Not Enrolled Sample Likelihood After Matching")
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

# Before and after matching tables
data.treat$control_include <- 0
drops.1 <- c("trt_scores")
drops.2 <- c("control_scores")
data.tables <- rbind(data.treat[,!(names(data.treat) %in% drops.1)], 
                     data.include[,!(names(data.include) %in% drops.2)])
# before matching
summary(data.tables[data.tables$WithSteps == 1, "Age"])
summary(data.tables[data.tables$WithSteps == 0, "Age"])

summary(data.tables[data.tables$WithSteps == 1, "MM"])
summary(data.tables[data.tables$WithSteps == 0, "MM"])

summary(data.tables[data.tables$WithSteps == 1, "Recent_RAF"])
summary(data.tables[data.tables$WithSteps == 0, "Recent_RAF"])

table(data.tables[data.tables$WithSteps == 1, "Sbscr_Ind"])
table(data.tables[data.tables$WithSteps == 0, "Sbscr_Ind"])

table(data.tables[data.tables$WithSteps == 1, "Gender"])
table(data.tables[data.tables$WithSteps == 0, "Gender"])

# after matching
summary(data.tables[data.tables$WithSteps == 0 & data.tables$control_include == 1, "Age"])
summary(data.tables[data.tables$WithSteps == 1, "Age"])

summary(data.tables[data.tables$WithSteps == 0 & data.tables$control_include == 1, "MM"])
summary(data.tables[data.tables$WithSteps == 1, "MM"])

summary(data.tables[data.tables$WithSteps == 0 & data.tables$control_include == 1, "Recent_RAF"])
summary(data.tables[data.tables$WithSteps == 1, "Recent_RAF"])

table(data.tables[data.tables$WithSteps == 0 & data.tables$control_include == 1, "Sbscr_Ind"])
table(data.tables[data.tables$WithSteps == 1, "Sbscr_Ind"])

table(data.tables[data.tables$WithSteps == 0 & data.tables$control_include == 1, "Gender"])
table(data.tables[data.tables$WithSteps == 1, "Gender"])

table(data.tables[data.tables$WithSteps == 0 & data.tables$control_include == 1, "MatchedZero"])
table(data.tables[data.tables$WithSteps == 1, "MatchedZero"])

data.tables$keeps<-as.numeric(as.character(data.tables$WithSteps))+
                      as.numeric(as.character(data.tables$control_include))
data.matched<-data.tables[data.tables$keeps==1,]

##### time series analysis with matched groups

data.member <- read.odbc("devsql10", dbQuery = "SELECT *
                         FROM pdb_PharmaMotion.dbo.Member_v2", as.is = TRUE)

data.membersum<-read.odbc("devsql10", dbQuery = "SELECT *
                          FROM pdb_PharmaMotion.dbo.MemberSummary_v2", as.is = TRUE)

data.drug1 <- read.odbc("devsql10", dbQuery = "SELECT *
                        FROM pdb_PharmaMotion.dbo.MemberSummaryDrugClassAllw_v2", as.is = TRUE)

data.total <- merge(data.membersum, data.member, by="MemberID", all=T)
data.drugtotal<-merge(data.total, data.drug1, by=c("MemberID", "YearMo"), all.x=T)

data.drugtotal<-data.drugtotal[data.drugtotal$Enrl_Plan.x==1,]
data.drugtotal<-data.drugtotal[data.drugtotal$Age>17,]
data.drugtotal<-data.drugtotal[data.drugtotal$MemberID%in%data.matched$MemberID,]
data.drug<-data.drugtotal


time<-as.numeric(data.drug$YearMo)
time1<-as.factor(time)
time<-as.numeric(time1)
#data.drugtotal$Time<-time
data.drug$Time<-time

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

keepids<-data.drug$MemberID[data.drug$MemberID%in%data.matched$MemberID[data.matched$WithSteps==1]]
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
### all drugs using matched group



###################################

## create proxy for month relative to motion for nonmembers by using
## policy enrl motion

for(i in 1:nrow(data.drug.notenrl)){
 data.drug.notenrl$Der_Enrl_MonthInd.x[i]<-data.drug.notenrl$PlcyEnrlMotion_MonthInd.x[i]
}


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

boxplot(rxts_enrl~cycle(rxts_enrl), main="RX Spend for Maintenance Drugs Per Month", xlab="Month")

plot(aggregate(rxts_enrl,FUN=mean), main="Yearly Trend in RX Spend\nFor Matched Groups", col="purple")
lines(aggregate(rxts_notenrl, FUN=mean))
legend("bottomright", legend = c("Enrolled", "Not Enrolled"), col = c("purple", "black"), 
       lty=c(1,1))

par(mfrow=c(2,2))
acf(rxts_enrl)
pacf(rxts_enrl)
acf(rxts_notenrl)
pacf(rxts_notenrl)



## If the PACF displays a sharp cutoff while the ACF decays more slowly 
## (i.e., has significant spikes at higher lags), we say that the stationarized 
## series displays an "AR signature," meaning that the autocorrelation pattern can 
## be explained more easily by adding AR terms than by adding MA terms

## The lag at which the PACF cuts off is the indicated number of AR terms

## If the autocorrelation is significant at lag k but not at any higher lags -- 
## i.e., if the ACF "cuts off" at lag k--this indicates that exactly k MA terms should 
## be used in the forecasting equation. In the latter case, we say that the stationarized 
## series displays an "MA signature," meaning that the autocorrelation pattern can be 
## explained more easily by adding MA terms than by adding AR terms.

par(mfrow=c(1,1))

mod1<-auto.arima(rxts_enrl)
mod1a<-auto.arima(rxts_enrl, stepwise = F, approximation = F)
mod2<-auto.arima(rxts_notenrl)

enrlmod1<-Arima(rxts_enrl, order = c(1,1,0))
enrlmod2<-Arima(rxts_enrl, order = c(1,1,1))
enrlmod3<-Arima(rxts_enrl, order = c(0,1,1))
enrlmod4<-Arima(rxts_enrl, order = c(0,0,1))

notenrlmod1<-Arima(rxts_notenrl, order=c(0,1,1))




############################################

### relative to motion

mean_rx_maint_rm<-tapply(data.drug.enrl$RX_Spend_Maint[data.drug.enrl$MemberID%in%maint_ids], 
                         data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
mean_rx_maint_ne_rm<-tapply(data.drug.notenrl$RX_Spend_Maint[data.drug.notenrl$MemberID%in%maint_ids], 
                            data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)


rxts2 <- ts(mean_rx_maint_rm, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rx_maint_ne_rm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x))


plot(time2, mean_rx_maint_rm, cex=0, xlab="Time", ylab="Mean Spend",
     main="RX Spend for Maint. Drugs\nRelative to Motion Start")
lines(time2, mean_rx_maint_rm, col="purple")
lines(time2b, mean_rx_maint_ne_rm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))


nvec_maint<-vector(length = length(time2))
nvec_ne_maint<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_maint[i]<-sum(data.drug.enrl$MemberID%in%maint_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_maint[i]<-sum(data.drug.notenrl$MemberID%in%maint_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%maint_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%maint_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_maint<-tapply(data.drug.enrl$RX_Spend_Maint[data.drug.enrl$MemberID%in%maint_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], sd)
sd_rx_maint_ne<-tapply(data.drug.notenrl$RX_Spend_Maint[data.drug.notenrl$MemberID%in%maint_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], sd)

se_maint<-sd_rx_maint/sqrt(nvec_maint)
se_maint_ne<-sd_rx_maint_ne/sqrt(nvec_ne_maint[nvec_ne_maint!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,110),
     main="Trend in RX Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_maint, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_maint, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_maint_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_maint_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


nmaint<-data.frame(time=time2, enrl=nvec_maint, notenrl=nvec_ne_maint, new.enrl=newn, new.notenrl=newn_ne)


plot(nmaint$time, nmaint$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(nmaint$time, nmaint$enrl, col="purple", lwd=2)
lines(nmaint$time, nmaint$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(nmaint$time, nmaint$new.enrl, col="purple", lwd=2, lty=1)
lines(nmaint$time, nmaint$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))


## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c


(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_maint<-c(a,d,e,b,c)
trend_maint_ne<-c(a2,d2,e2,b2,c2)

################################

## get member IDs for each maint drug

## all 7
maint_ids<-unique(data.drug$MemberID[data.drug$RX_Spend_Maint>0])
maint_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$RX_Spend_Maint>0])
maint_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$RX_Spend_Maint>0])
length(maint_ids_e) #9527
length(maint_ids_ne) #3344

## antihyperglycemics
ah_ids<-unique(data.drug$MemberID[data.drug$Antihyperglycemics_Allow>0])
length(ah_ids) #2293
ah_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$Antihyperglycemics_Allow>0])
ah_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$Antihyperglycemics_Allow>0])
length(ah_ids_e) #1625
length(ah_ids_ne) #668


## cardiovascular
cardio_ids<-unique(data.drug$MemberID[data.drug$Cardiovascular_Allow>0])
length(cardio_ids) #8793
cardio_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$Cardiovascular_Allow>0])
cardio_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$Cardiovascular_Allow>0])
length(cardio_ids_e) #6485
length(cardio_ids_ne) #2308

## antiparkinsons
ap_ids<-unique(data.drug$MemberID[data.drug$AntiparkinsonDrugs_Allow>0])
length(ap_ids) #188
ap_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$AntiparkinsonDrugs_Allow>0])
ap_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$AntiparkinsonDrugs_Allow>0])
length(ap_ids_e) #129
length(ap_ids_ne) #59

## cardiac
cardiac_ids<-unique(data.drug$MemberID[data.drug$CardiacDrugs_Allow>0])
length(cardiac_ids) #2040
cardiac_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$CardiacDrugs_Allow>0])
cardiac_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$CardiacDrugs_Allow>0])
length(cardiac_ids_e) #1454
length(cardiac_ids_ne) #586

## diuretics
diur_ids<-unique(data.drug$MemberID[data.drug$Diuretics_Allow>0])
length(diur_ids) #2133
diur_ids_e<-unique(data.drug$MemberID[data.drug.enrl$Diuretics_Allow>0])
diur_ids_ne<-unique(data.drug$MemberID[data.drug.notenrl$Diuretics_Allow>0])
length(diur_ids_e) #3189
length(diur_ids_ne) #2973

## thyroid
thyr_ids<-unique(data.drug$MemberID[data.drug$ThyroidPreps_Allow>0])
length(thyr_ids) #2733
thyr_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$ThyroidPreps_Allow>0])
thyr_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$ThyroidPreps_Allow>0])
length(thyr_ids_e) #2061
length(thyr_ids_ne) #672

## cns
cns_ids<-unique(data.drug$MemberID[data.drug$CNSDrugs_Allow>0])
length(cns_ids) #2257
cns_ids_e<-unique(data.drug.enrl$MemberID[data.drug.enrl$CNSDrugs_Allow>0])
cns_ids_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$CNSDrugs_Allow>0])
length(cns_ids_e) #1642
length(cns_ids_ne) #615


##################################################

## relative to motion analysis by drug (for members who have used those drugs, not all members)


##################################################


## antihyperglycemics


mean_rxah<-tapply(data.drug.enrl$Antihyperglycemics_Allow[data.drug.enrl$MemberID%in%ah_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ah_ids], mean)
mean_rxah_nm<-tapply(data.drug.notenrl$Antihyperglycemics_Allow[data.drug.notenrl$MemberID%in%ah_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%ah_ids], mean)

rxts2 <- ts(mean_rxah, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxah_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ah_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%ah_ids]))

plot(time2, mean_rxah, cex=0, xlab="Time", ylab="Mean Spend",
     main="RX Spend for Antihyperglycemics\nRelative to Motion Start")
lines(time2, mean_rxah, col="purple")
lines(time2b, mean_rxah_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_ah<-vector(length = length(time2))
nvec_ne_ah<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_ah[i]<-sum(data.drug.enrl$MemberID%in%ah_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_ah[i]<-sum(data.drug.notenrl$MemberID%in%ah_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%ah_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%ah_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_ah<-tapply(data.drug.enrl$Antihyperglycemics_Allow[data.drug.enrl$MemberID%in%ah_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ah_ids], sd)
sd_rx_ah_ne<-tapply(data.drug.notenrl$Antihyperglycemics_Allow[data.drug.notenrl$MemberID%in%ah_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%ah_ids], sd)

se_ah<-sd_rx_ah/sqrt(nvec_ah)
se_ah_ne<-sd_rx_ah_ne/sqrt(nvec_ne_ah[nvec_ne_ah!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time",
     main="Trend in Antihyperglycemic Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_ah, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_ah, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_ah_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_ah_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


nah<-data.frame(time=time2, enrl=nvec_ah, notenrl=nvec_ne_ah, new.enrl=newn, new.notenrl=newn_ne)


plot(nah$time, nah$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(nah$time, nah$enrl, col="purple", lwd=2)
lines(nah$time, nah$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(nah$time, nah$new.enrl, col="purple", lwd=2, lty=1)
lines(nah$time, nah$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))


## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_ah<-c(a,d,e,b,c)
trend_ah_ne<-c(a2,d2,e2,b2,c2)


##################################################


## cardiovascular


mean_rxcardio<-tapply(data.drug.enrl$Cardiovascular_Allow[data.drug.enrl$MemberID%in%cardio_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids], mean)
mean_rxcardio_nm<-tapply(data.drug.notenrl$Cardiovascular_Allow[data.drug.notenrl$MemberID%in%cardio_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids], mean)

rxts2 <- ts(mean_rxcardio, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxcardio_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids]))

plot(time2, mean_rxcardio, cex=0, xlab="Time", ylab="Mean Spend",
     main="RX Spend for Cardiovascular Drugs\nRelative to Motion Start")
lines(time2, mean_rxcardio, col="purple")
lines(time2b, mean_rxcardio_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_cardio<-vector(length = length(time2))
nvec_ne_cardio<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_cardio[i]<-sum(data.drug.enrl$MemberID%in%cardio_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_cardio[i]<-sum(data.drug.notenrl$MemberID%in%cardio_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%cardio_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%cardio_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_cardio<-tapply(data.drug.enrl$Cardiovascular_Allow[data.drug.enrl$MemberID%in%cardio_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids], sd)
sd_rx_cardio_ne<-tapply(data.drug.notenrl$Cardiovascular_Allow[data.drug.notenrl$MemberID%in%cardio_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids], sd)

se_cardio<-sd_rx_cardio/sqrt(nvec_cardio)
se_cardio_ne<-sd_rx_cardio_ne/sqrt(nvec_ne_cardio[nvec_ne_cardio!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,45),
     main="Trend in Cardiovascular Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_cardio, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_cardio, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_cardio_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_cardio_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


ncardio<-data.frame(time=time2, enrl=nvec_cardio, notenrl=nvec_ne_cardio, new.enrl=newn, new.notenrl=newn_ne)


plot(ncardio$time, ncardio$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(ncardio$time, ncardio$enrl, col="purple", lwd=2)
lines(ncardio$time, ncardio$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(ncardio$time, ncardio$new.enrl, col="purple", lwd=2, lty=1)
lines(ncardio$time, ncardio$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))


## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_cardio<-c(a,d,e,b,c)
trend_cardio_ne<-c(a2,d2,e2,b2,c2)


##################################################


## antiparkinson


mean_rxap<-tapply(data.drug.enrl$AntiparkinsonDrugs_Allow[data.drug.enrl$MemberID%in%ap_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids], mean)
mean_rxap_nm<-tapply(data.drug.notenrl$AntiparkinsonDrugs_Allow[data.drug.notenrl$MemberID%in%ap_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids], mean)

rxts2 <- ts(mean_rxap, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxap_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids]))

plot(time2b, mean_rxap_nm, cex=0, xlab="Time", ylab="Mean Spend",
     main="RX Spend for Anti-Parksinson's\nRelative to Motion Start")
lines(time2, mean_rxap, col="purple")
lines(time2b, mean_rxap_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_ap<-vector(length = length(time2))
nvec_ne_ap<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_ap[i]<-sum(data.drug.enrl$MemberID%in%ap_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_ap[i]<-sum(data.drug.notenrl$MemberID%in%ap_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%ap_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%ap_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_ap<-tapply(data.drug.enrl$AntiparkinsonDrugs_Allow[data.drug.enrl$MemberID%in%ap_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids], sd)
sd_rx_ap_ne<-tapply(data.drug.notenrl$AntiparkinsonDrugs_Allow[data.drug.notenrl$MemberID%in%ap_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids], sd)

se_ap<-sd_rx_ap/sqrt(nvec_ap)
se_ap_ne<-sd_rx_ap_ne/sqrt(nvec_ne_ap[nvec_ne_ap!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0, 3000),
     main="Trend in Anti-Parkinson's Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_ap, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_ap, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_ap_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_ap_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


nap<-data.frame(time=time2, enrl=nvec_ap, notenrl=nvec_ne_ap, new.enrl=newn, new.notenrl=newn_ne)


plot(nap$time, nap$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(nap$time, nap$enrl, col="purple", lwd=2)
lines(nap$time, nap$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(nap$time, nap$new.enrl, col="purple", lwd=2, lty=1)
lines(nap$time, nap$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))


## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)


e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_ap<-c(a,d,e,b,c)
trend_ap_ne<-c(a2,d2,e2,b2,c2)



##################################################


## cardiac drugs


mean_rxcardiac<-tapply(data.drug.enrl$CardiacDrugs_Allow[data.drug.enrl$MemberID%in%cardiac_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardiac_ids], mean)
mean_rxcardiac_nm<-tapply(data.drug.notenrl$CardiacDrugs_Allow[data.drug.notenrl$MemberID%in%cardiac_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cardiac_ids], mean)

rxts2 <- ts(mean_rxcardiac, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxcardiac_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardiac_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cardiac_ids]))

plot(time2, mean_rxcardiac, cex=0, xlab="Time", ylab="Mean Spend",
     main="RX Spend for Cardiac Drugs\nRelative to Motion Start")
lines(time2, mean_rxcardiac, col="purple")
lines(time2b, mean_rxcardiac_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_cardiac<-vector(length = length(time2))
nvec_ne_cardiac<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_cardiac[i]<-sum(data.drug.enrl$MemberID%in%cardiac_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_cardiac[i]<-sum(data.drug.notenrl$MemberID%in%cardiac_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%cardiac_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%cardiac_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_cardiac<-tapply(data.drug.enrl$CardiacDrugs_Allow[data.drug.enrl$MemberID%in%cardiac_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardiac_ids], sd)
sd_rx_cardiac_ne<-tapply(data.drug.notenrl$CardiacDrugs_Allow[data.drug.notenrl$MemberID%in%cardiac_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cardiac_ids], sd)

se_cardiac<-sd_rx_cardiac/sqrt(nvec_cardiac)
se_cardiac_ne<-sd_rx_cardiac_ne/sqrt(nvec_ne_cardiac[nvec_ne_cardiac!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,42),
     main="Trend in Cardiac Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_cardiac, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_cardiac, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_cardiac_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_cardiac_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


ncardiac<-data.frame(time=time2, enrl=nvec_cardiac, notenrl=nvec_ne_cardiac, new.enrl=newn, new.notenrl=newn_ne)


plot(ncardiac$time, ncardiac$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(ncardiac$time, ncardiac$enrl, col="purple", lwd=2)
lines(ncardiac$time, ncardiac$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(ncardiac$time, ncardiac$new.enrl, col="purple", lwd=2, lty=1)
lines(ncardiac$time, ncardiac$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_cardiac<-c(a,d,e,b,c)
trend_cardiac_ne<-c(a2,d2,e2,b2,c2)


##################################################


## cns drugs


mean_rxcns<-tapply(data.drug.enrl$CNSDrugs_Allow[data.drug.enrl$MemberID%in%cns_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cns_ids], mean)
mean_rxcns_nm<-tapply(data.drug.notenrl$CNSDrugs_Allow[data.drug.notenrl$MemberID%in%cns_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cns_ids], mean)

rxts2 <- ts(mean_rxcns, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxcns_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cns_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cns_ids]))

plot(time2, mean_rxcns, cex=0, xlab="Time", ylab="Mean Spend",
     main="RX Spend for CNS Drugs\nRelative to Motion Start")
lines(time2, mean_rxcns, col="purple")
lines(time2b, mean_rxcns_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_cns<-vector(length = length(time2))
nvec_ne_cns<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_cns[i]<-sum(data.drug.enrl$MemberID%in%cns_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_cns[i]<-sum(data.drug.notenrl$MemberID%in%cns_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%cns_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%cns_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_cns<-tapply(data.drug.enrl$CNSDrugs_Allow[data.drug.enrl$MemberID%in%cns_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cns_ids], sd)
sd_rx_cns_ne<-tapply(data.drug.notenrl$CNSDrugs_Allow[data.drug.notenrl$MemberID%in%cns_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%cns_ids], sd)

se_cns<-sd_rx_cns/sqrt(nvec_cns)
se_cns_ne<-sd_rx_cns_ne/sqrt(nvec_ne_cns[nvec_ne_cns!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,180),
     main="Trend in CNS Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_cns, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_cns, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_cns_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_cns_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


ncns<-data.frame(time=time2, enrl=nvec_cns, notenrl=nvec_ne_cns, new.enrl=newn, new.notenrl=newn_ne)


plot(ncns$time, ncns$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(ncns$time, ncns$enrl, col="purple", lwd=2)
lines(ncns$time, ncns$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(ncns$time, ncns$new.enrl, col="purple", lwd=2, lty=1)
lines(ncns$time, ncns$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))



## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_cns<-c(a,d,e,b,c)
trend_cns_ne<-c(a2,d2,e2,b2,c2)


##################################################


## diuretics


mean_rxdiur<-tapply(data.drug.enrl$Diuretics_Allow[data.drug.enrl$MemberID%in%diur_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%diur_ids], mean)
mean_rxdiur_nm<-tapply(data.drug.notenrl$Diuretics_Allow[data.drug.notenrl$MemberID%in%diur_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%diur_ids], mean)

rxts2 <- ts(mean_rxdiur, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxdiur_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%diur_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%diur_ids]))

plot(time2, mean_rxdiur, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0,15),
     main="RX Spend for Diuretics\nRelative to Motion Start")
lines(time2, mean_rxdiur, col="purple")
lines(time2b, mean_rxdiur_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_diur<-vector(length = length(time2))
nvec_ne_diur<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_diur[i]<-sum(data.drug.enrl$MemberID%in%diur_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_diur[i]<-sum(data.drug.notenrl$MemberID%in%diur_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%diur_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%diur_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_diur<-tapply(data.drug.enrl$Diuretics_Allow[data.drug.enrl$MemberID%in%diur_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%diur_ids], sd)
sd_rx_diur_ne<-tapply(data.drug.notenrl$Diuretics_Allow[data.drug.notenrl$MemberID%in%diur_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%diur_ids], sd)

se_diur<-sd_rx_diur/sqrt(nvec_diur)
se_diur_ne<-sd_rx_diur_ne/sqrt(nvec_ne_diur[nvec_ne_diur!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,15),
     main="Trend in Diuretics Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_diur, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_diur, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_diur_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_diur_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


ndiur<-data.frame(time=time2, enrl=nvec_diur, notenrl=nvec_ne_diur, new.enrl=newn, new.notenrl=newn_ne)


plot(ndiur$time, ndiur$enrl, cex=0, main="Count Density of Drug Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(ndiur$time, ndiur$enrl, col="purple", lwd=2)
lines(ndiur$time, ndiur$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(ndiur$time, ndiur$new.enrl, col="purple", lwd=2, lty=1)
lines(ndiur$time, ndiur$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_diur<-c(a,d,e,b,c)
trend_diur_ne<-c(a2,d2,e2,b2,c2)


##################################################


## thyroid


mean_rxthyr<-tapply(data.drug.enrl$ThyroidPreps_Allow[data.drug.enrl$MemberID%in%thyr_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%thyr_ids], mean)
mean_rxthyr_nm<-tapply(data.drug.notenrl$ThyroidPreps_Allow[data.drug.notenrl$MemberID%in%thyr_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%thyr_ids], mean)

rxts2 <- ts(mean_rxthyr, frequency=12, start=c(2014,1))
rxts2_comp<-decompose(rxts2)

rxts_ne2<-ts(mean_rxthyr_nm, frequency=12, start=c(2014,1))
rxts_ne2_comp<-decompose(rxts_ne2)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%thyr_ids]))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%thyr_ids]))

plot(time2, mean_rxthyr, cex=0, xlab="Time", ylim=c(0, 25),ylab="Mean Spend",
     main="RX Spend for Thyroid Prep\nRelative to Motion Start")
lines(time2, mean_rxthyr, col="purple")
lines(time2b, mean_rxthyr_nm)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

nvec_thyr<-vector(length = length(time2))
nvec_ne_thyr<-vector(length=length(time2))
mems<-vector()
mems_ne<-vector()
newn<-vector()
newn_ne<-vector()
for(i in 1:length(time2)){
  ## n for each month rel to motion
  
  nvec_thyr[i]<-sum(data.drug.enrl$MemberID%in%thyr_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i])
  nvec_ne_thyr[i]<-sum(data.drug.notenrl$MemberID%in%thyr_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i])
  
  
  ## n for each new member per month rel to motion
  ## count not in 'mems'
  mems2<-unique(data.drug.enrl$MemberID[data.drug.enrl$MemberID%in%thyr_ids&data.drug.enrl$Der_Enrl_MonthInd.x==time2[i]])
  newn[i]<-sum(!(mems2%in%mems))
  
  mems2_ne<-unique(data.drug.notenrl$MemberID[data.drug.notenrl$MemberID%in%thyr_ids&data.drug.notenrl$Der_Enrl_MonthInd.x==time2[i]])
  newn_ne[i]<-sum(!(mems2_ne%in%mems_ne))
  
  ## udpate mems
  mems<-unique(sort(c(mems,mems2)))
  mems_ne<-unique(sort(c(mems_ne, mems2_ne)))
}

sd_rx_thyr<-tapply(data.drug.enrl$ThyroidPreps_Allow[data.drug.enrl$MemberID%in%thyr_ids], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%thyr_ids], sd)
sd_rx_thyr_ne<-tapply(data.drug.notenrl$ThyroidPreps_Allow[data.drug.notenrl$MemberID%in%thyr_ids], 
                       data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%thyr_ids], sd)

se_thyr<-sd_rx_thyr/sqrt(nvec_thyr)
se_thyr_ne<-sd_rx_thyr_ne/sqrt(nvec_ne_thyr[nvec_ne_thyr!=0])



plot(time2, rxts2_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,20),
     main="Trend in Thyroid Prep Spend Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, rxts2_comp$trend, col="purple", lwd=2)
lines(time2b, rxts_ne2_comp$trend, lwd=2)
## confidence intervals
lines(time2, rxts2_comp$trend+se_thyr, col="purple", lty=2)
lines(time2, rxts2_comp$trend-se_thyr, col="purple", lty=2)
lines(time2b, rxts_ne2_comp$trend+se_thyr_ne, lty=2)
lines(time2b, rxts_ne2_comp$trend-se_thyr_ne, lty=2)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2, col="grey")


nthyr<-data.frame(time=time2, enrl=nvec_thyr, notenrl=nvec_ne_thyr, new.enrl=newn, new.notenrl=newn_ne)


plot(nthyr$time, nthyr$enrl, cex=0, main="New Users over Time\nRelative to Motion with Matched Non-Motion Group", 
     ylab="Counts", xlab="Month")
lines(nthyr$time, nthyr$enrl, col="purple", lwd=2)
lines(nthyr$time, nthyr$notenrl, lwd=2)
abline(v=c(-12,0,12), lty=2)
lines(nthyr$time, nthyr$new.enrl, col="purple", lwd=2, lty=1)
lines(nthyr$time, nthyr$new.notenrl, lwd=2, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

## % increase

trend1<-as.numeric(rxts2_comp$trend)
a<-trend1[time2==-12]
a
d<-trend1[time2==-1]
d
b<-trend1[time2==1]
b
c<-trend1[time2==12]
c

(peryear1<-(d-a)/a)
(peryear2<-(c-b)/b)

trend2<-as.numeric(rxts_ne2_comp$trend)
a2<-trend2[time2b==-12]
a2
d2<-trend2[time2b==-1]
d2
b2<-trend2[time2b==1]
b2
c2<-trend2[time2b==12]
c2

(peryear1<-(d2-a2)/a2)
(peryear2<-(c2-b2)/b2)

e<-trend1[time2==0]
e2<-trend2[time2b==0]

trend_thyr<-c(a,d,e,b,c)
trend_thyr_ne<-c(a2,d2,e2,b2,c2)


#####################################

## some sort of plot of % change in rx spend for maintenance drugs over time relative to motion...

timepoint<-c(-12,-1,0,1,12)

enrl_trend<-data.frame(time=timepoint, maint=trend_maint, ah=trend_ah, cardio=trend_cardio, 
                       thyr=trend_thyr, ap=trend_ap, cns=trend_cns, cardiac=trend_cardiac, diur=trend_diur)

notenrl_trend<-data.frame(time=timepoint, maint=trend_maint_ne, ah=trend_ah_ne, cardio=trend_cardio_ne, 
                       thyr=trend_thyr_ne, ap=trend_ap_ne, cns=trend_cns_ne, cardiac=trend_cardiac_ne, 
                       diur=trend_diur_ne)

enrl_trend$maint.std<-(enrl_trend$maint-mean(enrl_trend$maint))/sd(enrl_trend$maint)
enrl_trend$ah.std<-(enrl_trend$ah-mean(enrl_trend$ah))/sd(enrl_trend$ah)
enrl_trend$cardio.std<-(enrl_trend$cardio-mean(enrl_trend$cardio))/sd(enrl_trend$cardio)
enrl_trend$thyr.std<-(enrl_trend$thyr-mean(enrl_trend$thyr))/sd(enrl_trend$thyr)
enrl_trend$ap.std<-(enrl_trend$ap-mean(enrl_trend$ap))/sd(enrl_trend$ap)
enrl_trend$cardiac.std<-(enrl_trend$cardiac-mean(enrl_trend$cardiac))/sd(enrl_trend$cardiac)
enrl_trend$cns.std<-(enrl_trend$cns-mean(enrl_trend$cns))/sd(enrl_trend$cns)
enrl_trend$diur.std<-(enrl_trend$diur-mean(enrl_trend$diur))/sd(enrl_trend$diur)

notenrl_trend$maint.std<-(notenrl_trend$maint-mean(notenrl_trend$maint))/sd(notenrl_trend$maint)
notenrl_trend$ah.std<-(notenrl_trend$ah-mean(notenrl_trend$ah))/sd(notenrl_trend$ah)
notenrl_trend$cardio.std<-(notenrl_trend$cardio-mean(notenrl_trend$cardio))/sd(notenrl_trend$cardio)
notenrl_trend$thyr.std<-(notenrl_trend$thyr-mean(notenrl_trend$thyr))/sd(notenrl_trend$thyr)
notenrl_trend$ap.std<-(notenrl_trend$ap-mean(notenrl_trend$ap))/sd(notenrl_trend$ap)
notenrl_trend$cardiac.std<-(notenrl_trend$cardiac-mean(notenrl_trend$cardiac))/sd(notenrl_trend$cardiac)
notenrl_trend$cns.std<-(notenrl_trend$cns-mean(notenrl_trend$cns))/sd(notenrl_trend$cns)
notenrl_trend$diur.std<-(notenrl_trend$diur-mean(notenrl_trend$diur))/sd(notenrl_trend$diur)


plot(enrl_trend$time, enrl_trend$maint.std, cex=0, ylab="Standardized Trend in RX Spend", xlab="Time Relative to Motion",
     ylim=c(-1.75, 1.75),  main="Standardized Trend in Maintenance Medication Use\nFor Motion Members")
lines(enrl_trend$time, enrl_trend$maint.std)
lines(enrl_trend$time, enrl_trend$ah.std, col="red")
lines(enrl_trend$time, enrl_trend$cardio.std, col="blue")
lines(enrl_trend$time, enrl_trend$thyr.std, col="green")
lines(enrl_trend$time, enrl_trend$ap.std, col="coral4")
lines(enrl_trend$time, enrl_trend$cns.std, col="forestgreen")
lines(enrl_trend$time, enrl_trend$cardiac.std, col="darkslategray3")
lines(enrl_trend$time, enrl_trend$diur.std, col="darkgoldenrod3")
abline(v=c(-12,-1,0,1,12), col="grey", lty=2)
legend("topleft", legend=c("All", "AH", "Cardio", "Thyr", "AP", "CNS", "Cardiac", "Diur"), lty = rep(1,8),
       col=c("black", "red", "blue", "green", "coral4", "forestgreen", "darkslategray3", "darkgoldenrod3"), cex=.8)

plot(notenrl_trend$time, notenrl_trend$maint.std, cex=0, ylab="Standardized Trend in RX Spend", xlab="Time Relative to Motion",
     ylim=c(-1.75, 1.75), main="Standardized Trend in Maintenance Medication Use\nFor Non-Motion Members")
lines(notenrl_trend$time, notenrl_trend$maint.std)
lines(notenrl_trend$time, notenrl_trend$ah.std, col="red")
lines(notenrl_trend$time, notenrl_trend$cardio.std, col="blue")
lines(notenrl_trend$time, notenrl_trend$thyr.std, col="green")
lines(notenrl_trend$time, notenrl_trend$ap.std, col="coral4")
lines(notenrl_trend$time, notenrl_trend$cns.std, col="forestgreen")
lines(notenrl_trend$time, notenrl_trend$cardiac.std, col="darkslategray3")
lines(notenrl_trend$time, notenrl_trend$diur.std, col="darkgoldenrod3")
abline(v=c(-12,-1,0,1,12), col="grey", lty=2)
legend("topleft", legend=c("All", "AH", "Cardio", "Thyr", "AP", "CNS", "Cardiac", "Diur"), lty = rep(1,8),
       col=c("black", "red", "blue", "green", "coral4", "forestgreen", "darkslategray3", "darkgoldenrod3"), cex=.8)

colvec<-c("maint","ah", "cardio", "thyr", "ap", "cardiac", "cns", "diur")
percvec<-vector()
percvec2<-vector()
for(i in 1:8){
  a<-enrl_trend[1,(i+9)]
  b<-enrl_trend[2,(i+9)]
  
  a2<-notenrl_trend[1,(i+9)]
  b2<-notenrl_trend[2,(i+9)]
  
  percvec[i]<-(b-a)/a
  percvec2[i]<-(b2-a2)/a2
}



#####################################

## look at difs in costs over time for maint drug users
## those who use drugs from one category vs many categories

drug_ids<-c(ah_ids, cardio_ids, thyr_ids, ap_ids, cardiac_ids, diur_ids, cns_ids)
drug_ids<-sort(drug_ids)
mult_users<-unique(drug_ids[duplicated(drug_ids)])
length(mult_users)/length(maint_ids)
length(mult_users)/length(unique(data.drug$MemberID))
length(mult_users[mult_users%in%data.drug.enrl$MemberID])/length(unique(data.drug.enrl$MemberID))
length(mult_users[mult_users%in%data.drug.notenrl$MemberID])/length(unique(data.drug.notenrl$MemberID))

## 42.19% of all maint drug users from motion and matched group use multiple drugs
single_users<-maint_ids[!(maint_ids%in%mult_users)]

### calculate total # of perscriptions for maint meds pmpm
data.drug$Num_Maint_Scrips<-data.drug$Antihyperglycemics + data.drug$AntiparkinsonDrugs +
                            data.drug$Cardiovascular + data.drug$CardiacDrugs + data.drug$Diuretics +
                            data.drug$ThyroidPreps + data.drug$CNSDrugs

mean(data.drug$Num_Maint_Scrips)
mean(data.drug$Num_Maint_Scrips[data.drug$MemberID%in%maint_ids])
mean(data.drug$Num_Maint_Scrips[data.drug$MemberID%in%single_users])
mean(data.drug$Num_Maint_Scrips[data.drug$MemberID%in%mult_users])
mean(data.drug$Num_Maint_Scrips[data.drug$MemberID%in%maint_ids&
                                  data.drug$MemberID%in%data.drug.enrl$MemberID])
mean(data.drug$Num_Maint_Scrips[data.drug$MemberID%in%maint_ids&
                                  data.drug$MemberID%in%data.drug.notenrl$MemberID])



mean_single<-tapply(data.drug.enrl$RX_Spend_Maint[data.drug.enrl$MemberID%in%single_users], 
                    data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%single_users], mean)
mean_single_ne<-tapply(data.drug.notenrl$RX_Spend_Maint[data.drug.notenrl$MemberID%in%single_users], 
                    data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%single_users], mean)
mean_mult<-tapply(data.drug$RX_Spend_Maint[data.drug$MemberID%in%mult_users], 
                       data.drug$Der_Enrl_MonthInd.x[data.drug$MemberID%in%mult_users], mean)
mean_mult_ne<-tapply(data.drug.notenrl$RX_Spend_Maint[data.drug.notenrl$MemberID%in%mult_users], 
                  data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%mult_users], mean)

single_ts <- ts(mean_single, frequency=12)
sts_comp<-decompose(single_ts)
single_ts_ne <- ts(mean_single_ne, frequency=12)
sts_ne_comp<-decompose(single_ts_ne)


mult_ts<-ts(mean_mult, frequency=12)
mts_comp<-decompose(mult_ts)
mult_ts_ne<-ts(mean_mult_ne, frequency=12)
mts_ne_comp<-decompose(mult_ts_ne)


time3<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%single_users]))
time3b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%single_users]))

time4<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%mult_users]))
time4b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%mult_users]))

##plots for single drug users

plot(time3, mean_single, cex=0, xlab="Time",ylab="Mean Spend", ylim = c(0, 80),
     main="RX Spend for Single and Multiple Maint Medication\nUsers Relative to Motion Start")
lines(time3, mean_single, col="chartreuse3")
lines(time3b, mean_single_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("chartreuse3","black"))

plot(time3, sts_comp$trend, cex=0, xlab="Time",ylab="Mean Spend", ylim = c(0, 80),
     main="RX Spend for Single Maintenance Medication\nUsers Relative to Motion Start")
lines(time3, sts_comp$trend, col="chartreuse3")
lines(time3b, sts_ne_comp$trend)
abline(v=c(-12,0,12), lty=2, col="grey")
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("chartreuse3","black"))

## plots for multiple drug users

plot(time4, mean_mult, cex=0, xlab="Time",ylab="Mean Spend", ylim=c(0,450),
     main="RX Spend for Single and Multiple Maint Medication\nUsers Relative to Motion Start")
lines(time4, mean_mult, col="chartreuse3")
lines(time4b, mean_mult_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("chartreuse3","black"))

plot(time4, mts_comp$trend, cex=0, xlab="Time",ylab="Mean Spend", ylim = c(0, 200),
     main="RX Spend for Multiple Maintenance Medication\nUsers Relative to Motion Start")
lines(time4, mts_comp$trend, col="chartreuse3")
lines(time4b, mts_ne_comp$trend)
abline(v=c(-12,0,12), lty=2, col="grey")
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("chartreuse3","black"))



####
sum(data.drug$Num_Maint_Scrips!=0)
sum(data.drug$Num_Maint_Scrips!=0&data.drug$CNSDrugs!=0)
sum(data.drug$Num_Maint_Scrips!=0&data.drug$CNSDrugs==0)
sum(data.drug$Num_Maint_Scrips!=0&data.drug$CNSDrugs!=0)


#####################################

## exploration of other costs IP/OP/DR/ER
## break down per drug

data.drug.enrl$IP_Allow<-as.numeric(data.drug.enrl$IP_Allow)
data.drug.enrl$OP_Allow<-as.numeric(data.drug.enrl$OP_Allow)
data.drug.enrl$ER_Allow<-as.numeric(data.drug.enrl$ER_Allow)
data.drug.enrl$DR_Allow<-as.numeric(data.drug.enrl$DR_Allow)
data.drug.enrl$RX_Allow<-as.numeric(data.drug.enrl$RX_Allow)
data.drug.enrl$Total_Allow<-as.numeric(data.drug.enrl$Total_Allow)

data.drug.notenrl$IP_Allow<-as.numeric(data.drug.notenrl$IP_Allow)
data.drug.notenrl$OP_Allow<-as.numeric(data.drug.notenrl$OP_Allow)
data.drug.notenrl$ER_Allow<-as.numeric(data.drug.notenrl$ER_Allow)
data.drug.notenrl$DR_Allow<-as.numeric(data.drug.notenrl$DR_Allow)
data.drug.notenrl$RX_Allow<-as.numeric(data.drug.notenrl$RX_Allow)
data.drug.notenrl$Total_Allow<-as.numeric(data.drug.notenrl$Total_Allow)

### IP spend relative to motion for drug users

ip_maint<-tapply(data.drug.enrl$IP_Allow[data.drug.enrl$MemberID%in%maint_ids], 
                         data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
ip_maint_ne<-tapply(data.drug.notenrl$IP_Allow[data.drug.notenrl$MemberID%in%maint_ids], 
                         data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)

ipts <- ts(ip_maint, frequency=12, start=c(2014,1))
ipts_comp<-decompose(ipts)

ipts_ne<-ts(ip_maint_ne, frequency=12, start=c(2014,1))
ipts_ne_comp<-decompose(ipts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x))

plot(time2, ip_maint, cex=0, xlab="Time", ylab="Mean Spend",
     main="IP Spend for Maint. Drug Users\nRelative to Motion Start")
lines(time2, ip_maint, col="purple")
lines(time2b, ip_maint_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, ipts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,400),
     main="Trend in IP Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, ipts_comp$trend, col="purple", lty=2)
lines(time2b, ipts_ne_comp$trend, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(2,1), 
       col = c("purple","black"), cex=.7)
abline(v=c(-12,0,12), lty=2)

### OP spend relative to motion for drug users

OP_maint<-tapply(data.drug.enrl$OP_Allow[data.drug.enrl$MemberID%in%maint_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
OP_thyr_ne<-tapply(data.drug.notenrl$OP_Allow[data.drug.notenrl$MemberID%in%maint_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)

OPts <- ts(OP_maint, frequency=12, start=c(2014,1))
OPts_comp<-decompose(OPts)

OPts_ne<-ts(OP_maint_ne, frequency=12, start=c(2014,1))
OPts_ne_comp<-decompose(OPts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x))

plot(time2, OP_maint, cex=0, xlab="Time", ylab="Mean Spend",
     main="OP Spend for Maint. Drug Users\nRelative to Motion Start")
lines(time2, OP_maint, col="purple")
lines(time2b, OP_maint_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, OPts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,400),
     main="Trend in OP Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, OPts_comp$trend, col="purple", lty=2)
lines(time2b, OPts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### ER spend relative to motion for drug users

ER_maint<-tapply(data.drug.enrl$ER_Allow[data.drug.enrl$MemberID%in%maint_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
ER_maint_ne<-tapply(data.drug.notenrl$ER_Allow[data.drug.notenrl$MemberID%in%maint_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)

ERts <- ts(ER_maint, frequency=12, start=c(2014,1))
ERts_comp<-decompose(ERts)

ERts_ne<-ts(ER_maint_ne, frequency=12, start=c(2014,1))
ERts_ne_comp<-decompose(ERts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x))

plot(time2, ER_maint, cex=0, xlab="Time", ylab="Mean Spend",
     main="ER Spend for Maint. Drug Users\nRelative to Motion Start")
lines(time2, ER_maint, col="purple")
lines(time2b, ER_maint_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, ERts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,400),
     main="Trend in ER Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, ERts_comp$trend, col="purple", lty=2)
lines(time2b, ERts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### DR spend relative to motion for drug usDRs

DR_maint<-tapply(data.drug.enrl$DR_Allow[data.drug.enrl$MemberID%in%maint_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
DR_maint_ne<-tapply(data.drug.notenrl$DR_Allow[data.drug.notenrl$MemberID%in%maint_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)

DRts <- ts(DR_maint, frequency=12, start=c(2014,1))
DRts_comp<-decompose(DRts)

DRts_ne<-ts(DR_maint_ne, frequency=12, start=c(2014,1))
DRts_ne_comp<-decompose(DRts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x))

plot(time2, DR_maint, cex=0, xlab="Time", ylab="Mean Spend",
     main="DR Spend for Maint. Drug Users\nRelative to Motion Start")
lines(time2, DR_maint, col="purple")
lines(time2b, DR_maint_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, DRts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,400),
     main="Trend in DR Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, DRts_comp$trend, col="purple", lty=2)
lines(time2b, DRts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### Total spend relative to motion for drug users

tot_maint<-tapply(data.drug.enrl$Total_Allow[data.drug.enrl$MemberID%in%maint_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
tot_maint_ne<-tapply(data.drug.notenrl$Total_Allow[data.drug.notenrl$MemberID%in%maint_ids], 
                    data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)

totts <- ts(tot_maint, frequency=12, start=c(2014,1))
totts_comp<-decompose(totts)

totts_ne<-ts(tot_maint_ne, frequency=12, start=c(2014,1))
totts_ne_comp<-decompose(totts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x))
time2b<-unique(sort(data.drug.notenrl$Der_Enrl_MonthInd.x))

drug_maint<-tapply(data.drug.enrl$RX_Allow[data.drug.enrl$MemberID%in%maint_ids], 
                  data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%maint_ids], mean)
drug_maint_ne<-tapply(data.drug.notenrl$RX_Allow[data.drug.notenrl$MemberID%in%maint_ids], 
                     data.drug.notenrl$Der_Enrl_MonthInd.x[data.drug.notenrl$MemberID%in%maint_ids], mean)
  

drugts<-ts(drug_maint, frequency = 12)
drugts_comp<-decompose(drugts)
drugts_ne<-ts(drug_maint_ne, frequency = 12)
drugts_ne_comp<-decompose(drugts_ne)


nodrug_maint<-tot_maint-mean_rx_maint_rm
nodrug_maint_ne<-tot_maint_ne-mean_rx_maint_ne_rm


ndts<-ts(nodrug_maint, frequency = 12)
ndts_comp<-decompose(ndts)
ndts_ne<-ts(nodrug_maint_ne, frequency = 12)
ndts_ne_comp<-decompose(ndts_ne)


plot(time2, tot_maint, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0,1800),
     main="Total Spend for Maint. Drug Users\nRelative to Motion Start")
lines(time2, tot_maint, col="purple")
lines(time2b, tot_maint_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, totts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0, 850),
     main="Trend in Spending for Maintenance Medication Users\nRelative to Motion w/ Matched Non-Motion Group")
lines(time2, totts_comp$trend, col="purple", lwd=2)
lines(time2b, totts_ne_comp$trend, lwd=2)
abline(v=c(-12,0,12), lty=2, col="grey")
legend("topleft", legend = c("Motion", "Non-Motion", "Total Spend", "RX Spend", "RX Maint. SPend", "Total-RX Maint. Spend"), 
       lty=c(1,1,1,5,4,3), col=c("purple", "black", "black", "black", "black", "black"), cex = .6)
lines(time2, rxts2_comp$trend, lty=5 , lwd=2, col="purple")
lines(time2b, rxts_ne2_comp$trend, lty=5 , lwd=2)
lines(time2, ndts_comp$trend, lty=3, lwd=2, col="purple")
lines(time2b, ndts_ne_comp$trend, lty=3, lwd=2)
lines(time2, drugts_comp$trend, lty=4, lwd=2, col="purple")
lines(time2b, drugts_ne_comp$trend, lty=4, lwd=2)


#####################################

## ap users

## IP Spend

ip_ap<-tapply(data.drug.enrl$IP_Allow[data.drug.enrl$MemberID%in%ap_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids], mean)
ip_ap_ne<-tapply(data.drug.notenrl$IP_Allow[data.drug.notenrl$MemberID%in%ap_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids], mean)

ipts <- ts(ip_ap, frequency=12, start=c(2014,1))
ipts_comp<-decompose(ipts)

ipts_ne<-ts(ip_ap_ne, frequency=12, start=c(2014,1))
ipts_ne_comp<-decompose(ipts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids]))

plot(time2, ip_ap, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0, 2000),
     main="IP Spend for ap. Drug Users\nRelative to Motion Start")
lines(time2, ip_ap, col="purple")
lines(time2b, ip_ap_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, ipts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,1000),
     main="Trend in IP Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, ipts_comp$trend, col="purple", lty=2)
lines(time2b, ipts_ne_comp$trend, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(2,1), 
       col = c("purple","black"), cex=.7)
abline(v=c(-12,0,12), lty=2)

### OP spend relative to motion for drug users

OP_ap<-tapply(data.drug.enrl$OP_Allow[data.drug.enrl$MemberID%in%ap_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids], mean)
OP_ap_ne<-tapply(data.drug.notenrl$OP_Allow[data.drug.notenrl$MemberID%in%ap_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids], mean)

OPts <- ts(OP_ap, frequency=12, start=c(2014,1))
OPts_comp<-decompose(OPts)

OPts_ne<-ts(OP_ap_ne, frequency=12, start=c(2014,1))
OPts_ne_comp<-decompose(OPts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids]))

plot(time2, OP_ap, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0,3000),
     main="OP Spend for ap. Drug Users\nRelative to Motion Start")
lines(time2, OP_ap, col="purple")
lines(time2b, OP_ap_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, OPts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,1000),
     main="Trend in OP Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, OPts_comp$trend, col="purple", lty=2)
lines(time2b, OPts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### ER spend relative to motion for drug users

ER_ap<-tapply(data.drug.enrl$ER_Allow[data.drug.enrl$MemberID%in%ap_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids], mean)
ER_ap_ne<-tapply(data.drug.notenrl$ER_Allow[data.drug.notenrl$MemberID%in%ap_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids], mean)

ERts <- ts(ER_ap, frequency=12, start=c(2014,1))
ERts_comp<-decompose(ERts)

ERts_ne<-ts(ER_ap_ne, frequency=12, start=c(2014,1))
ERts_ne_comp<-decompose(ERts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids]))

plot(time2, ER_ap, cex=0, xlab="Time", ylab="Mean Spend",
     main="ER Spend for ap. Drug Users\nRelative to Motion Start")
lines(time2, ER_ap, col="purple")
lines(time2b, ER_ap_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, ERts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,80),
     main="Trend in ER Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, ERts_comp$trend, col="purple", lty=2)
lines(time2b, ERts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### DR spend relative to motion for drug usDRs

DR_ap<-tapply(data.drug.enrl$DR_Allow[data.drug.enrl$MemberID%in%ap_ids], 
                 data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids], mean)
DR_ap_ne<-tapply(data.drug.notenrl$DR_Allow[data.drug.notenrl$MemberID%in%ap_ids], 
                    data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids], mean)

DRts <- ts(DR_ap, frequency=12, start=c(2014,1))
DRts_comp<-decompose(DRts)

DRts_ne<-ts(DR_ap_ne, frequency=12, start=c(2014,1))
DRts_ne_comp<-decompose(DRts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%ap_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%ap_ids]))

plot(time2, DR_ap, cex=0, xlab="Time", ylab="Mean Spend",
     main="DR Spend for ap. Drug Users\nRelative to Motion Start")
lines(time2, DR_ap, col="purple")
lines(time2b, DR_ap_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, DRts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,400),
     main="Trend in DR Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, DRts_comp$trend, col="purple", lty=2)
lines(time2b, DRts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)


#####################################

## cardio users

## IP Spend

ip_cardio<-tapply(data.drug.enrl$IP_Allow[data.drug.enrl$MemberID%in%cardio_ids], 
              data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids], mean)
ip_cardio_ne<-tapply(data.drug.notenrl$IP_Allow[data.drug.notenrl$MemberID%in%cardio_ids], 
                 data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids], mean)

ipts <- ts(ip_cardio, frequency=12, start=c(2014,1))
ipts_comp<-decompose(ipts)

ipts_ne<-ts(ip_cardio_ne, frequency=12, start=c(2014,1))
ipts_ne_comp<-decompose(ipts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids]))

plot(time2, ip_cardio, cex=0, xlab="Time", ylab="Mean Spend",ylim=c(0,1200),
     main="IP Spend for cardio. Drug Users\nRelative to Motion Start")
lines(time2, ip_cardio, col="purple")
lines(time2b, ip_cardio_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))


plot(time2, ipts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,400),
     main="Trend in IP Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, ipts_comp$trend, col="purple", lty=2)
lines(time2b, ipts_ne_comp$trend, lty=1)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(2,1), 
       col = c("purple","black"), cex=.7)
abline(v=c(-12,0,12), lty=2)

### OP spend relative to motion for drug users

OP_cardio<-tapply(data.drug.enrl$OP_Allow[data.drug.enrl$MemberID%in%cardio_ids], 
              data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids], mean)
OP_cardio_ne<-tapply(data.drug.notenrl$OP_Allow[data.drug.notenrl$MemberID%in%cardio_ids], 
                 data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids], mean)

OPts <- ts(OP_cardio, frequency=12, start=c(2014,1))
OPts_comp<-decompose(OPts)

OPts_ne<-ts(OP_cardio_ne, frequency=12, start=c(2014,1))
OPts_ne_comp<-decompose(OPts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids]))

plot(time2, OP_cardio, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0,1500),
     main="OP Spend for cardio. Drug Users\nRelative to Motion Start")
lines(time2, OP_cardio, col="purple")
lines(time2b, OP_cardio_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, OPts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,1000),
     main="Trend in OP Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, OPts_comp$trend, col="purple", lty=2)
lines(time2b, OPts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### ER spend relative to motion for drug users

ER_cardio<-tapply(data.drug.enrl$ER_Allow[data.drug.enrl$MemberID%in%cardio_ids], 
              data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids], mean)
ER_cardio_ne<-tapply(data.drug.notenrl$ER_Allow[data.drug.notenrl$MemberID%in%cardio_ids], 
                 data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids], mean)

ERts <- ts(ER_cardio, frequency=12, start=c(2014,1))
ERts_comp<-decompose(ERts)

ERts_ne<-ts(ER_cardio_ne, frequency=12, start=c(2014,1))
ERts_ne_comp<-decompose(ERts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids]))

plot(time2, ER_cardio, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0, 120),
     main="ER Spend for cardio. Drug Users\nRelative to Motion Start")
lines(time2, ER_cardio, col="purple")
lines(time2b, ER_cardio_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, ERts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,50),
     main="Trend in ER Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, ERts_comp$trend, col="purple", lty=2)
lines(time2b, ERts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)

### DR spend relative to motion for drug usDRs

DR_cardio<-tapply(data.drug.enrl$DR_Allow[data.drug.enrl$MemberID%in%cardio_ids], 
              data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids], mean)
DR_cardio_ne<-tapply(data.drug.notenrl$DR_Allow[data.drug.notenrl$MemberID%in%cardio_ids], 
                 data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids], mean)

DRts <- ts(DR_cardio, frequency=12, start=c(2014,1))
DRts_comp<-decompose(DRts)

DRts_ne<-ts(DR_cardio_ne, frequency=12, start=c(2014,1))
DRts_ne_comp<-decompose(DRts_ne)
time2<-unique(sort(data.drug.enrl$Der_Enrl_MonthInd.x[data.drug.enrl$MemberID%in%cardio_ids]))
time2b<-unique(sort(data.drug.notenrl$EnrlMotion_MonthInd.x[data.drug.notenrl$MemberID%in%cardio_ids]))

plot(time2, DR_cardio, cex=0, xlab="Time", ylab="Mean Spend", ylim=c(0, 400),
     main="DR Spend for cardio. Drug Users\nRelative to Motion Start")
lines(time2, DR_cardio, col="purple")
lines(time2b, DR_cardio_ne)
legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))

plot(time2, DRts_comp$trend, cex=0, ylab="Mean Spend", xlab="Time", ylim=c(0,300),
     main="Trend in DR Spend for Drug Users Relative to Motion\nw/ Matched Non-Motion Group")
lines(time2, DRts_comp$trend, col="purple", lty=2)
lines(time2b, DRts_ne_comp$trend)
#legend("topleft", legend = c("Motion", "Not Motion"), lty = c(1,1), col = c("purple","black"))
abline(v=c(-12,0,12), lty=2)


#########################################

## exploration of first motion month for enrolled members
## using first day with steps as proxy for enrl day

enrlday<-data.drug$MotionEnrDate_FstDayWithSteps[data.drug$Der_Enrl_MonthInd.x==0&
                                                   data.drug$WithSteps==1]
enrlday_ne<-data.drug.notenrl$PolicyEffDate[data.drug.notenrl$Der_Enrl_MonthInd.x==0&
                                                      data.drug.notenrl$WithSteps==0]
enrlday2<-data.drug$Mbr_EnrolledMotionDate[data.drug$Der_Enrl_MonthInd.x==0&
                                                   data.drug$WithSteps==1]

summary(enrlday)
enrlday<-as.Date(enrlday)
enrlday_ne<-as.Date(enrlday_ne)
day<-as.numeric(format(enrlday, "%d"))

enrlday2<-as.Date(enrlday2)
day2<-as.numeric(format(enrlday2, "%d"))
sum(day2<15)/length(day2) # 99.28%

sum(day2<8)/length(day2) # 98.89%
sum(day2==1)/length(day2) # 98.63%



## % enrolled within first 2 weeks of month
sum(day<15)/length(day)

## 50.97%

## % enrolled within first 10 days
sum(day<11)/length(day)

## 37.03%

sum(day==1)/length(day)

## 5.63% enroll on day 1

day_ne<-as.numeric(format(enrlday_ne, "%d"))
sum(day_ne<15)/length(day_ne)

## all 1's, policy enrollment is first day of respective month

plot(density(data.drug.enrl$Time[data.drug.enrl$Der_Enrl_MonthInd.x==0], bw=.5),
     main="Density of Motion Enrollment Month Relative to 2014-01", xlab="Month Relative to 2014-01")
lines(density(data.drug.notenrl$Time[data.drug.notenrl$Der_Enrl_MonthInd.x==0], bw=.5), col="red")
legend("topleft", legend = c("Motion", "Non-Motion"), lty=c(1,1), col = c("black", "red"))
abline(v=c(1,13,25), col="grey", lty=2)

playdat.enrl<-data.frame(policyDate=as.Date(data.drug.enrl$PolicyEffDate), 
                    motionDate=as.Date(data.drug.enrl$Mbr_EnrolledMotionDate), 
                    stepDate=as.Date(data.drug.enrl$MotionEnrDate_FstDayWithSteps))

playdat.enrl$dif_motionandsteps<- as.numeric(playdat.enrl$stepDate-playdat.enrl$motionDate)

