# Renew Motion NPS Calculation
# Steve Smela, Savvysherpa
# July-August, 2018

# NPS calls were made in 3 batches.  The first was "legitimate" calls done March 23 or earlier.  After that, some of the call center
# folks mistakenly collected NPS data when people called in to register.  These ended May 25th.  The second round of "legit" calls
# started on May 30th.

# For this analysis, we'll treat these all separately. There are duplicates, so we'll look for duplicates only within each round.

# This file starts with the data just for the 2nd round of "legit" calls, then runs another file to bring in the legit Round 1 calls.

require("RPostgreSQL")
library(tidyverse)
library(readxl)

# Code for opening connection to AWS from Riley servers. The file AWS.R is user-specific and will need to be created separately
# for other users.

setwd("/home/ssmela")

PostgreSQL_con=function(file){
  library('RPostgreSQL')
  source(file,local=TRUE)
  dbConnect(RPostgreSQL::PostgreSQL(), dbname=pg_dsn, host=host, port=port, password=password, user=username)
}

conV=PostgreSQL_con('AWS.R')

# Read in NPS data

query = "SELECT savvy_id, nps_score, create_date FROM renew_motion.rm_prod_nps_score"
Round2NPS <- dbGetQuery(conV, query)

# Create lookup table for SavvyID & CandidateID

query2 = "SELECT * FROM renew_motion.rm_prod_candidate"
LookupTable <- dbGetQuery(conV, query2)
LookupTable <- LookupTable %>% select(savvy_id, savvyhicn, candidate_id, participant_flag)

Round2NPS <- merge(Round2NPS, LookupTable, by = "savvy_id")

length(unique(Round2NPS$savvy_id))
length(unique(Round2NPS$candidate_id))

setwd("/work/ssmela/Renew Motion")

# Select third time period as decribed above

Round2NPS <- Round2NPS %>%
  filter(create_date >= "2018-05-28") %>% 
  mutate(nps_score = as.numeric(nps_score)) %>%
  filter(is.na(nps_score) == F)


# Find duplicates within round

Round2NPS$Duplicate <- 0

Round2NPS <- Round2NPS %>% arrange(savvy_id, create_date)

for (i in 2:(length(Round2NPS$savvy_id))) {
  
  if (Round2NPS$savvy_id[i] == Round2NPS$savvy_id[i-1]) {
    
    Round2NPS$Duplicate[i] <- 9999
    Round2NPS$Duplicate[i-1] <- 8888
  }
  
}

# Split into duplicated and non-duplicated records

Duplicates2 <- Round2NPS %>% filter(Duplicate != 0) %>% arrange(savvy_id)

NoDuplicates2 <- Round2NPS %>% filter(Duplicate == 0)

length(NoDuplicates2$savvy_id)   # 4905
length(unique(Duplicates2$savvy_id))   # 56


# Within Duplicates, find cases where scores are the same (not an issue)

Duplicates2$SameScore <- 0

for (i in 2:(length(Duplicates2$savvy_id))) {
  
  if (Duplicates2$savvy_id[i] == Duplicates2$savvy_id[i-1] & Duplicates2$nps_score[i] == Duplicates2$nps_score[i-1]) {
    
    Duplicates2$SameScore[i] <- 1
    Duplicates2$SameScore[i-1] <- 1
  }
    
}

# There are no triplicates or higher multiples


## Split into those with same scores and those with different scores

SameScores2 <- Duplicates2 %>% filter(SameScore == 1)

DiffScores2 <- Duplicates2 %>% 
  filter(SameScore == 0) %>%
  arrange(savvy_id, nps_score)
DiffScores2$MaxMin = seq(1,2)


### Re-build master data set, using No Duplicates, Same Scores, and DiffCorrected, the latter with 2 versions, 
### one with min scores and the other with max score

Set1 <- NoDuplicates2 %>% select(candidate_id, nps_score)
Set2 <- SameScores2 %>% 
  select(candidate_id, nps_score) %>%
  group_by(candidate_id) %>%
  summarise(nps_score = mean(nps_score))

Set3Min <- DiffScores2 %>% filter(MaxMin == 1) %>% select(candidate_id, nps_score)
Set3Max <- DiffScores2 %>% filter(MaxMin == 2) %>% select(candidate_id, nps_score)


Round2Min <- rbind(Set1, Set2)
Round2Min <- rbind(Round2Min, Set3Min)

Round2Max <- rbind(Set1, Set2)
Round2Max <- rbind(Round2Max, Set3Max)

Round2Min <- Round2Min %>% rename(Round2Min = nps_score)
Round2Max <- Round2Max %>% rename(Round2Max = nps_score)

# Pull in data from first NPS rounds.  Keep only the "legit" first-round scores

source("Round 1 NPS data prep.R")

MinCombo <- MinCombo %>% 
  filter(Group == 1) %>%
  select(candidate_id, nps_score) %>%
  rename(Round1Min = nps_score)

MaxCombo <- MaxCombo %>% 
  filter(Group == 1) %>%
  select(candidate_id, nps_score) %>%
  rename(Round1Max = nps_score)

NPS <- merge(MinCombo, MaxCombo, by = "candidate_id", all = T)
NPS <- merge(NPS, Round2Min, by = "candidate_id", all = T)
NPS <- merge(NPS, Round2Max, by = "candidate_id", all = T)

NPS <- NPS %>%
  mutate(Round1MinGroup = ifelse(Round1Min <= 6, -1, ifelse(Round1Min >= 9, 1, 0)),
         Round1MaxGroup = ifelse(Round1Max <= 6, -1, ifelse(Round1Max >= 9, 1, 0)),
         Round2MinGroup = ifelse(Round2Min <= 6, -1, ifelse(Round2Min >= 9, 1, 0)),
         Round2MaxGroup = ifelse(Round2Max <= 6, -1, ifelse(Round2Max >= 9, 1, 0)))

## Pull in participation data ##

QParticipants = "SELECT savvy_id, candidate_id, savvyhicn, participant_flag FROM renew_motion.rm_prod_candidate"
Participants <- dbGetQuery(conV, QParticipants)

NPS <- merge(NPS, Participants, by = "candidate_id", all.x = T)


## Table "salesforce combined" has info on control and treatment groups, age & gender

QGroups = "SELECT srckeyid1__c, secondary_treatment_description__c, birthdate, gender__c FROM renew_motion.src_salesforce_combined"
Groups <- dbGetQuery(conV, QGroups)

Groups <- Groups %>%
  rename(savvyhicn = srckeyid1__c,
         Gender = gender__c,
         Group = secondary_treatment_description__c)


NPS <- merge(NPS, Groups, by = "savvyhicn", all.x = T)


### Creating indicator of which of the particpants was actually logging steps before the Round 2 NPS
### call was done.

Round2FirstCall <- Round2NPS %>%
  group_by(savvy_id) %>%
  summarise(FirstCall = as.Date(min(create_date)))

QMinDates <- "SELECT savvy_id, min(goal_date) AS FirstSteps FROM renew_motion.rm_prod_earnings_daily GROUP BY savvy_id ORDER BY savvy_id"
MinDates <- dbGetQuery(conV, QMinDates)
MinDates <- MinDates %>% mutate(FirstSteps = as.Date(firststeps)) %>% select(-firststeps)

Round2FirstCall <- merge(Round2FirstCall, MinDates, by = "savvy_id")
Round2FirstCall <- Round2FirstCall %>% 
  mutate(WalkFirst = ifelse(FirstSteps < FirstCall, 1, 0)) %>% 
  select(savvy_id, WalkFirst)

Walkers <- MinDates %>% mutate(Walker = 1) %>% select(savvy_id, Walker)

NPS <- merge(NPS, Round2FirstCall, by = "savvy_id", all.x = T)
NPS <- merge(NPS, Walkers, by = "savvy_id", all.x = T)

NPS <- NPS %>% mutate(Walker = ifelse(participant_flag == 1 & is.na(Walker) == T, 0, Walker))

save(NPS, file = "NPS.rda")
