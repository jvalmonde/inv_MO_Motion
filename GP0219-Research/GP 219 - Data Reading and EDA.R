#####GP 219 - Cashman Motion####

#In this issue...
#--Reading in data
#--EDA
#---Cashman Goals Achieved
#---Cashman RAF
#---Cashman RAF vs. Differences in Spending/RVU

#Created: 2015-11-05
#Last updated: 2015-11-30




#Read in Cashman employee data
cca <- read.odbc("Devsql14pdb_abw", dbQuery="Select * From CashmanClaimsAnalysis_20151022")
optb <- subset (cca, Dataset=="Option B")
optc <- subset (cca, Dataset=="Option C")



cash <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsAnalysis_20151022")
sma <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from SmaClaimsAnalysis_20151022")
#sma_BU <- sma #Backed up due to changes in original data. This backup contains 1344 observations total and has only the stricter inclusion criteria
#cash_BU <- cash #Backed up just to be safe. :)

cash_optB <- cash[cash$Dataset == "Option B",]
sma_optB <- sma[sma$Dataset == "Option B",]

cash_optB$Delta <- cash_optB$Period2_TotalRVU - cash_optB$Period1_TotalRVU
sma_optB$Delta <- sma_optB$Period2_TotalRVU - sma_optB$Period1_TotalRVU

cash_optB$Delta2 <- (cash_optB$Period2_TotalMedSpend  + cash_optB$Period2_TotalRxSpend) - (cash_optB$Period1_TotalMedSpend  + cash_optB$Period1_TotalRxSpend)
sma_optB$Delta2 <- (sma_optB$Period2_TotalMedSpend  + sma_optB$Period2_TotalRxSpend)- (sma_optB$Period1_TotalMedSpend + sma_optB$Period1_TotalRxSpend)

cash_optB$set <- "Cashman"
sma_optB$set <- "SMA"

dat <- rbind(cash_optB[,c(2:4,23:66,74:76)], sma_optB[,c(3:5,6:49, 56:58)])
dat$set <- as.factor(dat$set)
dat$set2 <- ifelse(dat$set == "Cashman", 1, 0)
dat$male <- ifelse(dat$Gender == "M", 1, 0)
dat$logPeriod1_TotalMedSpend <- log(dat$Period1_TotalMedSpend + 1)




#Old
View(names(cca))

attach(optb)

summary(optb)

#Who are these people?
table(cca$Dataset)
#Option B is the 104 people with 4 full years of data (2 before and 2 after the start date). Option C includes all those with 2 years of data (includes all those in Option B)

hist(Age)
summary(Age)

hist(DaysinProgram)
table(DaysinProgram)

hist(IncomePercentile)



#Let's look at how much the subjects achieved their goals:

hist(TotalLogdates, breaks=20); table(TotalLogdates)
hist(FGoalAcheived)
hist(IGoalAcheived)
hist(T10KGoalAcheived)
hist(T8KGoalAcheived)
hist(T6KGoalAcheived)
hist(AverageSteps)

summary(optb[,grep("TotalLogdates", names(optb)):grep("T6K", names(optb))])

#Good job, Cashman employees!


table(FGoalAcheived != FrequencyPoints) # 1 case where they are not the same
table(IGoalAcheived != IntensityPoints) # 1 case where they are not the same
table(FGoalAcheived != FrequencyPoints)

table(Period1_Start)
table(Period1_End)

table(RegisteredMonth) 
table(RegisteredMonth,Period1_End) #Registered Month is Period1_End, shifted 1 month later


hist(Period1_RVUDollarConversion, breaks=59)


detach(optb)



####RAF comparisons - Cashman only####

#Silver scores (based on Phil's (expert) recommendation)
summary(cash_optB$SilverTotalScore)
hist(cash_optB$SilverTotalScore, main="Cashman Silver RAF Scores", xlab="RAF")
hist(cash_optB$SilverTotalScore, breaks=20, main="Cashman Silver RAF Scores", xlab="RAF")
table(cash_optB$SilverTotalScore > mean(cash_optB$SilverTotalScore))
#There are 21 people with RAF higher than the mean. We'd expect around 50 if the distribution were normal, but then again, we wouldn't expect a measure of health to be normally distributed. 
#Conclusion: Yes, there are some big outliers. It will be important to balance on RAF as well.
#I don't think we want to be eliminating high-RAF employees. If we do, our effect becomes "How much does the program help people that are already health?" which may raise some ethical issues. 


#Silver scores vs. Deltas
plot(cash_optB$Delta ~ cash_optB$SilverTotalScore, main="RAF vs. Difference in\nPeriod 1 and Period 2 RVU", xlab="Silver RAF Score", ylab="Difference in RVU")
plot(cash_optB$Delta2 ~ cash_optB$SilverTotalScore, main="RAF vs. Difference in\nPeriod 1 and Period 2 Spending", xlab="Silver RAF Score", ylab="Difference in Med Spend + Rx")

cor(cash_optB$Delta2, cash_optB$SilverTotalScore) #.037 – There's basically no correlation.

#What about the individual spending?
cor(cash_optB$Period1_TotalMedSpend  + cash_optB$Period1_TotalRxSpend, cash_optB$SilverTotalScore) #.276
cor(cash_optB$Period2_TotalMedSpend  + cash_optB$Period2_TotalRxSpend, cash_optB$SilverTotalScore) #.242

#


