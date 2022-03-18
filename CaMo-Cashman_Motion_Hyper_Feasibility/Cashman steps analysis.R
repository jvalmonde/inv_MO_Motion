# Cashman steps analysis

# Steve Smela, Savvysherpa
# February 2018

# Modeling probability and size of claims using just Cashman employee data to judge effects of walking program
# on claim frequency and size.

# As in the analyses performed in "Combined probability and size modeling," there are 4 sets of models,
# based on claim denomination (dollars or relative value units [RVUs]) and what is being predicted
# (probability of having a claim or annual claim amounts, given that a claim occurred).

# Each set of models is created twice: Once for the degree of participation in the walking program, and 
# once for merely signing up to be in the program.

# As before, this file contains only the final models used in the preparation of the report, 
# without diagnostic plots, tests, etc.

# Data are in  "CashMemberYear", which was created by "Cashman annual data set create".

if(!exists("CashMemberYear"))
  load("CashMemberYear.rda")

library(boot)
library(pROC)
library(tidyverse)

# Only subscribers can be walkers ....

Subscribers <- CashMemberYear %>% filter(Subscriber == 1)

### Using participation levels in the models ###

## Probabilities

# RVU-denominated claims

CashRVU_prob_GLM <- glm(AnyRVU ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                      I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months + MonthsWalking + IntensityPct,
                    family = binomial(link = "logit"),
                    data = Subscribers)

Subscribers$RVUProb_GLM <- inv.logit(fitted(CashRVU_prob_GLM))

# Dollar-denominated claims

CashSpend_prob_GLM <- glm(AnySpend ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                          I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months + MonthsWalking + IntensityPct   ,
                        family = binomial(link = "logit"),
                        data = Subscribers)

summary(CashSpend_prob_GLM)

Subscribers$SpendProb_GLM <- inv.logit(fitted(CashSpend_prob_GLM))


## Sizes

# RVU-denominated claims

CashRVU_Size_GLM <- glm(RVUs ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                          I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months  + MonthsWalking  + TenacityPct,
                        data =  Subscribers[Subscribers$RVUs > 0, ], family = Gamma(link = "log"))
summary(CashRVU_Size_GLM)

# Dollar-denominated claims

CashSpend_Size_GLM <- glm(TotalSpend ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                          I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months  + MonthsWalking  + TenacityPct,
                        data =  Subscribers[Subscribers$TotalSpend > 0, ], family = Gamma(link = "log"))
summary(CashSpend_Size_GLM)

save(Subscribers, file = "Subscribers.rda")


#### Adding in Larry's suggestion of looking at just participation in program, not participation levels
### (Intention to Treat)

Subscribers <- Subscribers %>% group_by(SavvyID) %>% mutate(Walker = max(ifelse(MonthsWalking > 0, 1, 0)),
                                                            MaxYear = max(Year))
# Need to filter out those who left before 2013--didn't have the opportunity to participate
AtRisk <- Subscribers[Subscribers$MaxYear >= 2013, ]

#RVU claims, probabilities

WalkerRVU_prob_GLM <- glm(AnyRVU ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                          I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months + Walker,
                        family = binomial(link = "logit"),
                        data = AtRisk)
summary(WalkerRVU_prob_GLM)


# Dollar claims, probabilities

WalkerSpend_prob_GLM <- glm(AnySpend ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                            I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months + Walker,
                          family = binomial(link = "logit"),
                          data = AtRisk)
summary(WalkerSpend_prob_GLM)

## Sizes

WalkerRVU_Size_GLM <- glm(RVUs ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                          I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months  + Walker,
                        data =  AtRisk[AtRisk$RVUs > 0, ], family = Gamma(link = "log"))
summary(WalkerRVU_Size_GLM)


WalkerSpend_Size_GLM <- glm(TotalSpend ~  as.factor(Year) + StdAgeAdj + Gender + StdAgeAdj:Gender + I(StdAgeAdj^2) + I(StdAgeAdj^2):Gender + 
                            I(StdAgeAdj^3) + I(StdAgeAdj^3):Gender + StdSES + SMA  + Months  + Walker,
                          data =  AtRisk[AtRisk$TotalSpend > 0, ], family = Gamma(link = "log"))
summary(WalkerSpend_Size_GLM)
