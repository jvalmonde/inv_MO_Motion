library(savvy)
library(MASS)
library(dplyr)
library(ggplot2)
library(MatchIt)

setwd("/home/nzimmerman/cashman")

cash <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from CashmanClaimsAnalysis_20151022 where Dataset = 'Option B'")
sma <- read.odbc("Devsql14pdb_abw", dbQuery = "select * from SmaClaimsAnalysis_20151022 where Dataset = 'Option B'")

cash$set <- "Cashman"
sma$set <- "SMA"

dat <- unique(rbind(dplyr::select(cash, Savvyid, Age, Gender, Zipcode, SilverTotalScore, Period1_Start:Period2_BMI,  set) %>% as.data.frame(),
                    dplyr::select(sma, Savvyid, Age, Gender, Zipcode, SilverTotalScore, Period1_Start:Period2_BMI, set) %>% as.data.frame()))

dat$Delta <- (dat$Period2_TotalMedSpend + dat$Period2_TotalRxSpend) - (dat$Period1_TotalMedSpend + dat$Period1_TotalRxSpend) 

# dat$Delta <- dat$Period2_TotalMedSpend - dat$Period1_TotalMedSpend

dat$logPeriod1_TotalSpend <- log(dat$Period1_TotalMedSpend + dat$Period1_TotalRxSpend + 1)

# dat$logPeriod1_TotalSpend <- log(dat$Period1_TotalMedSpend + 1)

dat$Gender <- as.factor(gsub(" ", "", as.character(dat$Gender)))
dat$set <- as.factor(dat$set)

ggplot(dat, aes(set, Delta)) + geom_boxplot() + ylab("total spend delta")
ggplot(dat, aes(set, Delta)) + geom_boxplot() + ylim(-8000, 8000) + ylab("total spend delta")

dat <- dat[!is.na(dat$SicioEconomicScore),]

dat$set2 <- ifelse(dat$set == "Cashman", 1, 0)

dat <- dplyr::select(dat, -Period1_BMI, -Period2_BMI)

m.out <- matchit(set2 ~ Age + Gender + logPeriod1_TotalSpend + SicioEconomicScore + SilverTotalScore, data = dat, method = "nearest", ratio = 5)

summary(m.out)
dat2 <- match.data(m.out)

ggplot(dat2, aes(set, Delta)) + geom_boxplot() + ylab("total spend delta")
ggplot(dat2, aes(set, Delta)) + geom_boxplot() + ylim(-8000, 8000) + ylab("total spend delta")

wilcox.test(Delta ~ set, data = dat2, alternative = "less")

w <- rep(0,15)

for(i in 1:15) {
  
  m.out <- matchit(set2 ~ Age + Gender + logPeriod1_TotalSpend + SicioEconomicScore + SilverTotalScore, data = dat, method = "nearest", ratio = i)
  
  dat2 <- match.data(m.out)
  
  w[i] <- wilcox.test(Delta ~ set, data = dat2, alternative = "less")$p.value
  
}

plot(1:15, w, xlab = "ratio", ylab = "p-value", main = "Mann-Whitney U Test with Matched Samples")
mtext("n1 = 104,  n2 = 104 * ratio")