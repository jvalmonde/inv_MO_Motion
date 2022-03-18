#####GP 219 - Cashman Motion####

#Created: 2015-11-23
#Last updated: 2015-11-30

#In this issue:
#Post-Hoc Analysis (Correlations)
#--High vs. low engagement with the program
#--medical expenditure for Cashman by month (and maybe also the control group)
#---Monthly running average
#--Cashman and SMA RAF vs. Deltas
#--PMPM cost before and after matching
#--BMI
#--Correlation: percentage of goals met and utilization
#--Differences in first and second year



#####Differences in Engagement#####

#Goal: Look at Period 1/Period 2 changes in expenditure between defined "high" and "low" engagement groups

#How do we divide the groups?
#--Split at median goals met
#--Split into top, med, bottom thirds

#Split by points

eng1 <- cash_optB
grep("FrequencyPoints", names(eng1))
eng1$Points <- rowSums(eng1[,21:23])
eng1$PosPoints <- rowSums(eng1[,24:26])
eng1$GoalPercent <- eng1$Points/eng1$PosPoints
summary(eng1$GoalPercent) #median 44.04
eng1$Group <- as.factor(ifelse(eng1$GoalPercent <= median(eng1$GoalPercent), "Low", "High"))

#Look at Delta values within Cashman by engagement level


boxplot(eng1$Delta2~eng1$Group, main="Difference in Spending: Two Groups", xlab="Activity Group", ylab="Difference in Expenditure (Medical + Rx)")
boxplot(eng1$Delta2~eng1$Group, main="Difference in Spending: Two Groups (Zoomed)", xlab="Activity Group", ylim=c(-2000, 2000), , ylab="Difference in Expenditure (Medical + Rx)")

#Now with 3 groups

quantile(eng1$GoalPercent, c(1/3,2/3))
eng1$Group2 <- ifelse(eng1$GoalPercent <= quantile(eng1$GoalPercent, 1/3), "Low", ifelse(eng1$GoalPercent > quantile(eng1$GoalPercent, 2/3), "High", "Med"))
eng1$Group2 <- ordered(eng1$Group2, levels=c("High", "Med", "Low"))

boxplot(eng1$Delta2~eng1$Group2, main="Difference in Spending: Three Groups", xlab="Activity Group", , ylab="Difference in Expenditure (Medical + Rx)")
boxplot(eng1$Delta2~eng1$Group2, ylim=c(-2000,2000), main="Difference in Spending: Three Groups (Zoomed)", xlab="Activity Group", , ylab="Difference in Expenditure (Medical + Rx)")

#Conclusions: Small sample size, so it's hard to say, but there doesn't appear to be a major difference in the differences between high and low groups, at least. The medians seem pretty consistent.







#####Monthly Spend#####

#Read in data - Cashman only
cmonth <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsMonthlyAnalysis_20151022")

#What is the data like?
dim(cmonth);names(cmonth)
class(cmonth$Year_mo)
#One row per member per month

#Create y variable
cmonth$tot <- cmonth$TotalMedSpend + cmonth$TotalRxSpend

#Convert Year_mo to a date
library(zoo)
#Cheat and add the first day of the month
cmonth$month <- paste(substr(cmonth$Year_mo, 1, 4), "-", substr(cmonth$Year_mo, 5, 6), "-01",sep="")
cmonth$month <- as.Date(cmonth$month)

#These all failed. Maaaaan....
#cmonth$month <- as.yearmon(cmonth$Year_mo)
#cmonth$month <- read.zoo(text = cmonth$month, FUN = as.yearmon)
#cmonth$month <- as.Date(cmonth$month)
#cmonth$month <- as.Date(cmonth$Year_mo, "%Y%m")
#cmonth$month <- paste(cmonth$Year_mo, "01", sep="")
#cmonth$month <- as.Date(cmonth$Year_mo, "%Y%m%d")
#cmonth$month <- as.Date(cmonth$Year_mo, "%Y%m%d")
#cmonth$month <- as.POSIXct(cmonth$Year_mo)

class(cmonth$month)
head(cmonth$month)


#Plot the boxplots
ggplot(cmonth, aes(x=month, y=tot)) + geom_boxplot()
#Hm...


#Let's summarize the data first.
#A couple methods available here: http://www.cookbook-r.com/Manipulating_data/Summarizing_data/

library(plyr)
cmonth.sum <- ddply(cmonth, "month", summarise, N = length(tot), mean=mean(tot), med=median(tot), sd = sd(tot), se = sd/sqrt(N))
View(cmonth.sum)

#This looks good. However, the first and last three months have almost no subjects. I'm going to truncate those months, since they are completely different from the others and could give a misleading impression.

cmonth.clipped <- subset(cmonth.sum, month > "2011-03-01" & month < "2015-05-01")
View(cmonth.clipped)

#Plot some lines
#The means with se
ggplot(cmonth.clipped, aes(x=month, y=mean)) + geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.1) + geom_line() + geom_point() + labs(title="Cashman Monthly Spending:\nMeans and Standard Errors", x= "Month", y="Total Medical + Rx Spending") + geom_hline(yintercept=mean(cmonth.clipped$mean))
ggplot(cmonth.clipped, aes(x=month, y=mean)) + geom_line() + geom_point() + labs(title="Cashman Monthly Spending: Means", x= "Month", y="Total Medical + Rx Spending") + geom_hline(yintercept=mean(cmonth.clipped$mean))
#The medians
ggplot(cmonth.clipped, aes(x=month, y=med)) + geom_line() + geom_point() + labs(title="Cashman Monthly Spending:\nMedian Expenditure", x= "Month", y="Total Medical + Rx Spending") + geom_hline(yintercept=median(cmonth.clipped$med))

table(cmonth.clipped$med == 0)
table(cmonth.clipped$med <= 20)







#Monthly Running Averages####
summary(cmonth.clipped)

run.avg <- cumsum(cmonth.clipped$mean) / seq_along(cmonth.clipped$mean)
ra.df <- cbind(cmonth.clipped, run.avg)
View(ra.df)
plot(run.avg)
ggplot(cmonth.clipped, aes(x=month, y=run.avg)) + geom_line() + geom_point() + labs(title="Cashman Monthly Spending: Running Average", x= "Month", y="Running Average: Total Medical + Rx Spending") + geom_hline(yintercept=mean(cmonth.clipped$mean))



#Now doing a 3-month moving average, which may be more comparable

movec <- rep(0,49)
for(i in 3:length(cmonth.clipped$month)){
  movec[i] <- mean(c(cmonth.clipped$mean[i], cmonth.clipped$mean[i-1], cmonth.clipped$mean[i-2] ))
}

movec.df <- subset(cbind(ra.df, movec), movec>0)
ggplot(movec.df, aes(month)) + geom_line(aes(y = run.avg, colour = "Key")) + geom_line(aes(y = movec, colour = "3-Month Average")) + labs(title="Cashman Monthly Spending: 3-Month Averages", x= "Month", y="Average Total Medical + Rx Spending") + geom_hline(yintercept=mean(cmonth.clipped$mean)) 
#Doesn't seem to be much of a pattern.


#Now with 6-month moving average, just to see if it flattens out at all.

movec2 <- rep(0,49)
for(i in 6:length(cmonth.clipped$month)){
  movec2[i] <- mean(c(cmonth.clipped$mean[i], cmonth.clipped$mean[i-1], cmonth.clipped$mean[i-2], cmonth.clipped$mean[i-3], cmonth.clipped$mean[i-4],cmonth.clipped$mean[i-5]  ))
}

movec2.df <- subset(cbind(ra.df, movec2), movec2>0)
ggplot(movec2.df, aes(month)) + geom_line(aes(y = run.avg, colour = "Key")) + geom_line(aes(y = movec2, colour = "6-Month Average")) + labs(title="Cashman Monthly Spending: 6-Month Averages", x= "Month", y="Average Total Medical + Rx Spending") + geom_hline(yintercept=mean(cmonth.clipped$mean)) 
#Doesn't seem to be much of a pattern.



#Plots with just the averages

movec3.df <- subset(cbind(ra.df, movec, movec2), movec2>0)
ggplot(movec3.df, aes(month)) + geom_line(aes(y = movec, colour = "3-Month Average")) + geom_line(aes(y = movec2, colour = "6-Month Average")) + geom_line(aes(y = mean, colour = "1-Month Value")) + labs(title="Cashman Monthly Spending: Monthly Averages", x= "Month", y="Average Total Medical + Rx Spending") + geom_hline(yintercept=mean(cmonth.clipped$mean)) + scale_colour_discrete(name = "Key")


####Before-and-After BMI####

#EDA
table(is.na(cash_optB$Period1_BMI))
table(is.na(cash_optB$Period2_BMI))
table(is.na(cash_optB$Period1_BMI), is.na(cash_optB$Period1_BMI))

#How many subjects had BMI measurements in both periods?
cash.BMI <- subset(cash_optB, !is.na(Period1_BMI) & !is.na(Period2_BMI))
dim(cash.BMI) #49 cases with BMI in both periods

#More EDA
hist(cash.BMI$Period1_BMI, breaks=20, main="Period 1 BMI", xlab="Period 1 BMI")
hist(cash.BMI$Period2_BMI, breaks=20, main="Period 2 BMI", xlab="Period 2 BMI")
#Compare to US BMI distribution:
#http://www.niddk.nih.gov/health-information/health-statistics/documents/stat904z.pdf



#Let's look at the differences in BMI
cash.BMI$Delta3 <- cash.BMI$Period1_BMI - cash.BMI$Period2_BMI #Delta3 is how much they lost
summary(cash.BMI$Delta3)
hist(cash.BMI$Delta3, main="Differences in BMI", xlab="Difference in BMI") #Clearly there's an outlier.
View(cash.BMI$Delta3)

#The outlier is row 17 in the cash_optB data, male, age 37, Silver score 0.24, met most of his goals,
#Period 1 BMI: 67.67333, Period 2 BMI: 32.28500
#The Period 1 BMI is WAY off the tables that show a person's BMI. The ones I'm seeing end in the low 50's, 
#Using a calculator (http://www.nhlbi.nih.gov/health/educational/lose_wt/BMI/bmicalc.htm), he'd have to be 460 pounds at 5'9"
#and gotten down to 220 by the end of period 2. That's half his body weight.
#I suspect that something else went on besides the walking program to get him to lose that much weight.
#This seems extreme (or could be a coding error), so I'm going to remove him from the analysis.

#--look into gastric bypass or something? This is an average weight loss of 10 pounds per month on the program.

cash.BMI2 <- subset(cash.BMI, Delta3 < 25)
hist(cash.BMI2$Delta3, main="Differences in BMI\n(Outlier Removed)", xlab="Difference in BMI")
summary(cash.BMI2$Delta3)
#In general, people got fatter. If we also remove the person that gained the most...
summary(cash.BMI2$Delta3[cash.BMI2$Delta3 > -5])
hist(cash.BMI2$Delta3[cash.BMI2$Delta3 > -5], main="Differences in BMI\n(2 Outliers Removed)", xlab="Difference in BMI", breaks=15)
#...it doesn't change much.

cash.BMI3 <- subset(cash.BMI2, Delta3 > -5)
#Based on this chart: http://www.inner-image.com/assets/2015/04/Mayo-Clinic-BMI.jpg
#... half a BMI point looks like 2-3 pounds, which is feasible in over a couple years, but I'm not sure it's meaningful.


#Do heavier people lose more?
plot(Delta3~Period1_BMI, data=cash.BMI2)
cor(cash.BMI2$Delta3,cash.BMI2$Period1_BMI) #Without the high outlier: -.2165
cor(cash.BMI3$Delta3,cash.BMI3$Period1_BMI) #Without the high or low outliers: -.1159

#Small correlation: heavier people actually tended to gain more weight.





####Correlation: Goals met, utilization####
#First, run cashman.R

cor <- rep(0,15)
for(i in 1:15) {
  
  m.out <- matchit(set2 ~ Age + Gender + logPeriod1_TotalSpend + SicioEconomicScore + SilverTotalScore, data = dat, method = "nearest", ratio = i)
  
  dat2 <- match.data(m.out)
  
  cor <- wilcox.test(Delta ~ set, data = dat2, alternative = "less")$p.value
  
}


#Now ignore all that.

names(eng1)
cor(eng1$GoalPercent, eng1$Delta2)
cor(eng1$GoalPercent, eng1$Delta)









####Differences: Year 1 and Year 2 of walking program####

#Taken from above. This might already be in your environment if you are running everything.

cmonth <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsMonthlyAnalysis_20151022")
cmonth$tot <- cmonth$TotalMedSpend + cmonth$TotalRxSpend
cmonth$month <- paste(substr(cmonth$Year_mo, 1, 4), "-", substr(cmonth$Year_mo, 5, 6), "-01",sep="")
cmonth$month <- as.Date(cmonth$month)

library(plyr)
cmonth.sum <- ddply(cmonth, "month", summarise, N = length(tot), mean=mean(tot), med=median(tot), sd = sd(tot), se = sd/sqrt(N))

cmonth.clipped <- subset(cmonth.sum, month > "2011-03-01" & month < "2015-05-01")

#Break down to the years with the treatment
cmonth.tx <- subset(cmonth.sum, month >= "2013-04-01" & month < "2015-04-01")
tx1 <- subset(cmonth.sum, month >= "2013-04-01" & month < "2014-04-01")
tx2 <- subset(cmonth.sum, month >= "2014-04-01" & month < "2015-05-01")

table(cmonth.tx$month < "2014-04-01") #12 T, 13 F
cmonth.tx$year <- c(rep("Year 1", 12), rep("Year 2", 12))
boxplot(cmonth.tx$mean~cmonth.tx$year, main="Average Monthly Medical + Rx Expenditure:\nFirst Two Years of Cashman on the Move", ylab="Medical + Rx Spend (2014 Dollars)")

summary(tx1$mean)
summary(tx2$mean)


#Now with RVU
rvu <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsMonthlyAnalysis_20151022")
rvu$month <- paste(substr(rvu$Year_mo, 1, 4), "-", substr(rvu$Year_mo, 5, 6), "-01",sep="")
rvu$month <- as.Date(rvu$month)

library(plyr)
rvu.sum <- ddply(rvu, "month", summarise, N = length(TotalRVU), mean=mean(TotalRVU), med=median(TotalRVU), sd = sd(TotalRVU), se = sd/sqrt(N))

rvu.clipped <- subset(rvu.sum, month > "2011-03-01" & month < "2015-05-01")

#Break down to the years with the treatment
rvu.tx <- subset(rvu.sum, month >= "2013-03-01" & month < "2015-04-01")
tx1.r <- subset(rvu.sum, month >= "2013-03-01" & month < "2014-03-01")
tx2.r <- subset(rvu.sum, month >= "2014-03-01" & month < "2015-05-01")

table(rvu.tx$month < "2014-03-01") #12 T, 13 F
rvu.tx$year <- c(rep("Year 1", 12), rep("Year 2", 13))
boxplot(rvu.tx$mean~rvu.tx$year, main="Average RVU:\nFirst Two Years of Cashman on the Move", ylab="Average RVU")

summary(tx1.r$mean)
summary(tx2.r$mean)



#Now with the first years

cmonth <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsMonthlyAnalysis_20151022")
cmonth$tot <- cmonth$TotalMedSpend + cmonth$TotalRxSpend
cmonth$month <- paste(substr(cmonth$Year_mo, 1, 4), "-", substr(cmonth$Year_mo, 5, 6), "-01",sep="")
cmonth$month <- as.Date(cmonth$month)

library(plyr)
cmonth.sum <- ddply(cmonth, "month", summarise, N = length(tot), mean=mean(tot), med=median(tot), sd = sd(tot), se = sd/sqrt(N))

cmonth.clipped <- subset(cmonth.sum, month > "2011-03-01" & month < "2015-04-01")

#Break down to the years with the treatment
cmonth.tx <- subset(cmonth.sum, month >= "2013-04-01" & month < "2015-04-01")
cn1 <- subset(cmonth.sum, month >= "2011-04-01" & month < "2012-04-01")
cn2 <- subset(cmonth.sum, month >= "2012-04-01" & month < "2013-04-01")
tx1 <- subset(cmonth.sum, month >= "2013-04-01" & month < "2014-04-01")
tx2 <- subset(cmonth.sum, month >= "2014-04-01" & month < "2015-05-01")

table(cmonth.tx$month < "2014-04-01") #12 T, 13 F
cmonth.clipped$year <- c(rep("Year 1", 12), rep("Year 2", 12),rep("Year 3\n(Program Active)", 12), rep("Year 4\n(Program Active)", 12))
boxplot(cmonth.clipped$mean~cmonth.clipped$year, main="Average Monthly Medical + Rx Expenditure", ylab="Medical + Rx Spend (2014 Dollars)")

summary(tx1$mean)
summary(tx2$mean)
