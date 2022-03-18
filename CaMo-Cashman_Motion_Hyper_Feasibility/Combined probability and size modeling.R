# Combined probability and size modeling for Cashman project

# Steve Smela, Savvysherpa
# February 2018

# This file contains only the final models used in the preparation of the report, without diagnostic plots, tests, etc.

# Data file 'MemberYear' was created through 'Cashman annual data set create.' It contains data at the member-year level on
# members of Sierra Health plans in Cashman Equipment Company and the seven comparison companies.

# There are four sets of models, based on claim denomination (dollars or relative value units [RVUs]) and what is being predicted
# (probability of having a claim or annual claim amounts, given that a claim occurred).


if(!exists("MemberYear"))
  load("MemberYear.rda")

library(boot)
library(pROC)
library(lme4)
library(tidyverse)

# Take out members with missing socioeconomic scores.
MemberYear2 <- MemberYear[!is.na(MemberYear$SES), ]


#### RVUs #####

# Probability first

RVU_prob <- glmer(AnyRVU ~ as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                    I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Subscriber + Months +
                   (1|GroupName), 
                 family = binomial(link = "logit"),
                 data = MemberYear2, verbose = 1, control = glmerControl(tolPwrss = 1e-04))
summary(RVU_prob)
ranef(RVU_prob)
save(RVU_prob, file = "RVU_prob.rda")

# Add predicted probabilities to data file
MemberYear2$RVU_prob_pred1<- predict(RVU_prob, type = "response")


# Now RVU size.  Predicted using only those who had a claim in the year.


RVU_size <- glmer(RVUs ~  as.factor(Year) + Age0 + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                  I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Subscriber + Months +
                  (1|GroupName),
                data =  MemberYear2[MemberYear2$AnyRVU > 0, ], family = Gamma(link = "log"),
                verbose = 1, control = glmerControl(tolPwrss = 1e-04))
summary(RVU_size)
ranef(RVU_size)

# Add predicted probabilites to data file, using whole data set.
MemberYear2$RVU_size_pred <- predict(RVU_size, newdata = MemberYear2, type = "response")

save(RVU_size, file = "RVU_size.rda")


#################  Spending ###############

Spend_prob <- glmer(AnySpend ~ as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                    I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Subscriber + Months +
                    (1|GroupName), 
                  family = binomial(link = "logit"),
                  data = MemberYear2, verbose = 1, control = glmerControl(tolPwrss = 1e-04))
summary(Spend_prob)
ranef(Spend_prob)
save(Spend_prob, file = "Spend_prob.rda")

MemberYear2$Spend_prob_pred1<- predict(Spend_prob, type = "response")

# Now spending size. Predicted using only those who had a claim in the year.


Spend_size <- glmer(TotalSpend ~  as.factor(Year) + Age0 + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                    I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Subscriber + Months +
                    (1|GroupName),
                  data =  MemberYear2[MemberYear2$AnySpend > 0, ], family = Gamma(link = "log"),
                  verbose = 1, control = glmerControl(tolPwrss = 1e-04))
summary(Spend_size)
ranef(Spend_size)

# Add predicted probabilites to data file, using whole data set.
MemberYear2$Spend_size_pred <- predict(Spend_size, newdata = MemberYear2, type = "response")

save(Spend_size, file = "Spend_size.rda")

# Predict member-level annual amounts by multiplying frequency and severity predictions
MemberYear2$Spend_pred <- MemberYear2$Spend_prob_pred1 * MemberYear2$Spend_size_pred
MemberYear2$RVU_pred <- MemberYear2$RVU_prob_pred1 * MemberYear2$RVU_size_pred

save(MemberYear2, file = "MemberYear2.rda")
