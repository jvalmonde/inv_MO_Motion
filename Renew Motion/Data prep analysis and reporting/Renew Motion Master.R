# Renew Motion Master File

# Steve Smela, Savvysherpa

# May, 2018

# Takes the various files and combines them into a master file

#### Set-up ####

library(tidyverse)
library(RPostgres)
library(survival)

setwd("R:/Users/ssmela/Renew Motion")

# User name and password specified outside this file.

conV <- dbConnect(RPostgres::Postgres(), dbname='operations', host='operational.c1nqtd6s9v6b.us-east-1.rds.amazonaws.com', 
                        port=5432, password='password', user='user')

# File "Renew Motion Roster" has data on all 16333 participants grouped into households.  It's derived from 'src_salesforce_combined'.

load("Renew Motion Roster.rda")  # Created by "Renew Motion Roster.R"

Master <- Roster2 %>% 
  select(Household, street, city, state, postalcode, SavvyHICN, TrtGroup, birthdate, gender__c) %>%
  rename(Gender = gender__c)

rm(Roster2)

# rm_prod_candidate has lookup table to cross-reference savvy_id, candidate_id, SavvyHICN, and whether they are participating in walking

CandQuery = "SELECT savvy_id, candidate_id, savvyhicn, participant_flag FROM renew_motion.rm_prod_candidate"
Candidate <- dbGetQuery(conV, CandQuery)

Candidate <- Candidate %>% rename(SavvyHICN = savvyhicn)

Master <- merge(Master, Candidate, by = "SavvyHICN")

# Next bring in Earnings Summary

EarningsQuery = "SELECT savvy_id, bonus, reward_balance, current_annual_earning FROM renew_motion.rm_prod_earnings_summary"
Earnings <- dbGetQuery(conV, EarningsQuery)


Master <- merge(Master, Earnings, by = "savvy_id", all.x = T)

# Select those in households and calculate household size

Households <- Master %>% 
  filter(Household > 0) %>% 
  select(Household, TrtGroup) %>%
  group_by(Household, TrtGroup) %>%
  summarise(NumInGroup = n()) %>%
  group_by(Household) %>%
  summarise(HHoldSize = sum(NumInGroup),
            NumOfGroups = n())

Master <- merge(Master, Households, by = "Household", all.x = T)

# Add in household size of 1 for those by themselves, calculate age

Master <- Master %>% mutate(HHoldSize = ifelse(Household == 0, 1, HHoldSize),
                            Age = 2018 - as.numeric(str_sub(birthdate, start = 1, end = 4)),
                            Solo = ifelse(Household == 0, 1, 0))
