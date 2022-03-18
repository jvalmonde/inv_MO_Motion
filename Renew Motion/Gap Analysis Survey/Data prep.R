
# Renew Motion gap analysis survey data prep

# Steve Smela, Savvysherpa

# July 2018

library(tidyverse)
library(readr)

GapSurvey <- read_csv("Gap survey text 2018-08-02.csv", skip = 1)


# Remove dummy responses from testing

GapSurvey <- GapSurvey %>% filter(X1 >= 10116434016)


GapSurvey <- GapSurvey %>%
  select(-X1, -X2, -X3, -X4, -X5, -X6, -X7, -X8, -X9,
         Remember = Response,
         OrderFitbit = Response_1,
         ArriveOK = Response_2,
         TroubleDescription = `Open-Ended Response`,
         RealizeNotEarning = Response_3,
         DescribeExperience = Response_4,
         ProblemDescription = `Open-Ended Response_1`,
         WhyChangeMind = `Open-Ended Response_2`,
         SetUpFitbitAcct = Response_5,
         CompleteSteps = Response_6,
         RecordSteps = Response_7,
         AbleToLogIn = Response_8,
         ReceiveEmails = Response_9,
         ReceiveGiftCard = Response_10,
         ContactRenewMotion = Response_11,
         WhatHappenedWhenContact = `Open-Ended Response_3`,
         ReceiveCall = Response_12,
         WhatHappnedWhenCalled = `Open-Ended Response_4`,
         StillInterested = Response_13,
         AdditionalComments = `Open-Ended Response_5`,
         SureDontRemember = Response_14)

GapSurvey$Remember <- as.factor(GapSurvey$Remember)

GapSurvey$OrderFitbit <- as.factor(GapSurvey$OrderFitbit)

GapSurvey$ArriveOK <- as.factor(GapSurvey$ArriveOK)

GapSurvey$RealizeNotEarning <- as.factor(GapSurvey$RealizeNotEarning)

GapSurvey$DescribeExperience <- as.factor(GapSurvey$DescribeExperience)

GapSurvey$SetUpFitbitAcct <- as.factor(GapSurvey$SetUpFitbitAcct)

GapSurvey$CompleteSteps <- as.factor(GapSurvey$CompleteSteps)

GapSurvey$RecordSteps <- as.factor(GapSurvey$RecordSteps)

GapSurvey$AbleToLogIn <- as.factor(GapSurvey$AbleToLogIn)

GapSurvey$ReceiveEmails <- as.factor(GapSurvey$ReceiveEmails)

GapSurvey$ReceiveGiftCard <- as.factor(GapSurvey$ReceiveGiftCard)

GapSurvey$ContactRenewMotion <- as.factor(GapSurvey$ContactRenewMotion)

GapSurvey$ReceiveCall <- as.factor(GapSurvey$ReceiveCall)

GapSurvey$StillInterested <- as.factor(GapSurvey$StillInterested)

GapSurvey$SureDontRemember <- as.factor(GapSurvey$SureDontRemember)


