# Renew Motion gap analysis survey data analysis

# Steve Smela, Savvysherpa

# July 2018

library(tidyverse)

# If data file not in memory, run code to create it

if(!exists("GapSurvey")) {
  source("Data prep.R")
}

# Do you remember signing up for the Renew Motion program earlier this year?
table(GapSurvey$Remember)

# Are you sure you don't remember signing up for Renew Motion?
table(GapSurvey$SureDontRemember)                            # Were those who didn't remember really sure?

table(GapSurvey$Remember, GapSurvey$SureDontRemember, useNA = "ifany")  # Check on survey flow

## Take out those who thought they never signed up--no further responses from them. ##
GapSurvey <- GapSurvey %>% filter(Remember == "Yes")

# Did you order a Fitbit tracker?
table(GapSurvey$OrderFitbit)

  # (If ordered a fitbit and received one)
  OrderedAndReceived <- GapSurvey %>% filter(OrderFitbit == "I ordered a Fitbit and received one.")
  
  # Did it arrive on time and as expected?
  table(OrderedAndReceived$ArriveOK)
  
    # (If did not arrive on time and as expected)  Describe trouble
    OrderedAndReceived %>% filter(ArriveOK == "No") %>% select(TroubleDescription)
    
  # (If ordered a fitbit but never received it)  Describe trouble
  GapSurvey %>% filter(OrderFitbit == "I ordered a Fitbit but never received it.") %>% select(TroubleDescription)

  
# Did you realize you are not earning rewards?
table(GapSurvey$RealizeNotEarning)

  # (If knew they were not earning)
  table(GapSurvey$DescribeExperience)
  
    # (If ran into problem they couldn't solve)
    GapSurvey %>% filter(is.na(ProblemDescription) == F) %>% select(ProblemDescription)

    # (If changed mind)
    GapSurvey %>% filter(DescribeExperience == "I decided I did not want to particpate after all.") %>%
      select(WhyChangeMind)
    
  # (If they thought they were earning)
    
  # Did you set up your Fitbit account?
  table(GapSurvey$SetUpFitbitAcct)
  
  # Did you complete all of the steps in the Renew Motion setup instructions?
  table(GapSurvey$CompleteSteps)
  
  # Has your Fitbit recorded any steps?
  table(GapSurvey$RecordSteps)
  
  table(GapSurvey$SetUpFitbitAcct, GapSurvey$RecordSteps)
  table(GapSurvey$CompleteSteps, GapSurvey$RecordSteps)
  
  # Have you been able to log in to your Fitbit account?
  table(GapSurvey$AbleToLogIn)
  
  table(GapSurvey$RecordSteps, GapSurvey$AbleToLogIn)
  
  # Did you receive any emails from Renew Motion about your activity level?
  table(GapSurvey$ReceiveEmails)
  
  table(GapSurvey$RecordSteps, GapSurvey$ReceiveEmails)
  
  # Have you received any Renew Motion reward gift cards?
  table(GapSurvey$ReceiveGiftCard)
  
  # Did you contact Renew Motion about any problems you were having?
  table(GapSurvey$ContactRenewMotion)
  
  # (If contacted Renew Motion about problems)
  GapSurvey %>% filter(ContactRenewMotion == "Yes") %>% select(WhatHappenedWhenContact)
  
# Did you receive a call from Renew Motion, letting you know it looked like you weren't participating?
table(GapSurvey$ReceiveCall)

  # (If received call)
  GapSurvey %>% filter(ReceiveCall == "Yes") %>% select(WhatHappnedWhenCalled)
  
# Are you still interested in participating in Renew Motion?
table(GapSurvey$StillInterested)

# Feel free to provide any additional comments about your experience with Renew Motion.
GapSurvey %>% filter(is.na(AdditionalComments) == F) %>% select(AdditionalComments)

  
