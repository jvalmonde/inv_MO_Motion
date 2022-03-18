#####GP 219 - Cashman Motion####

#Cody Miller
#Last update: 2015-11-09

# Coarsened Exact Matching #####

#install.packages("cem")
#update.packages() #This... takes a while. Maybe time it next time.
library(cem)

#Reading in data. Taken from Nathan's code in cashman.R
cash <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsAnalysis_20151022")
sma <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from SmaClaimsAnalysis_20151022")

cash_optB <- cash[cash$Dataset == "Option B",]
sma_optB <- sma[sma$Dataset == "Option B",]

cash_optB$Delta <- cash_optB$Period2_TotalRVU - cash_optB$Period1_TotalRVU
sma_optB$Delta <- sma_optB$Period2_TotalRVU - sma_optB$Period1_TotalRVU

cash_optB$Delta2 <- cash_optB$Period2_TotalMedSpend - cash_optB$Period1_TotalMedSpend
sma_optB$Delta2 <- sma_optB$Period2_TotalMedSpend - sma_optB$Period1_TotalMedSpend

cash_optB$set <- "Cashman"
sma_optB$set <- "SMA"

dat <- rbind(cash_optB[,c(2:4,23:69)], sma_optB[,c(3:5,6:52)])
dat$set <- as.factor(dat$set)
dat$set2 <- ifelse(dat$set == "Cashman", 1, 0)
dat$male <- ifelse(dat$Gender == "M", 1, 0)


vars <- c("Age", "male", "logPeriod1_TotalMedSpend", "SicioEconomicScore","Delta", "Delta2", "set2")
dat2 <-dat[,vars]

# Dry Run - Automatic Coarsening#####
# http://gking.harvard.edu/files/gking/files/cem.pdf?m=1360071263

names(dat2)

imbalance(group=dat2$set, data=dat2[vars])

mat <- cem(treatment = "set2", data=dat2, drop=c("Delta", "Delta2"))
mat
#plot(mat)

#Estimate Effects

est <- att(mat, Delta2~set2, data=dat2)
est

est <- att(mat, Delta~set2, data=dat2)
est

#According to this, there is no significant difference
#Caveat: we don't know which points were kept in the data, nor did we think about how to coarsen the variables. 














