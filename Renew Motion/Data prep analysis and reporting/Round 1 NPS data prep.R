# Renew Motion Round 1 NPS data prep

# Steve Smela, Savvysherpa
# July-August, 2018

# Previous data checking found duplicates and/or phantom records.  These were exported into Excel
# for manual checking / data cleaning.  The resulting file is imported below.

require("RPostgreSQL")
library(tidyverse)
library(readxl)

# Code to open connection to AWS from Riley server. This will need to be modified for other users.  File "AWS.R" has
# user-specific log-in information.

setwd("/home/ssmela")

PostgreSQL_con=function(file){
  library('RPostgreSQL')
  source(file,local=TRUE)
  dbConnect(RPostgreSQL::PostgreSQL(), dbname=pg_dsn, host=host, port=port, password=password, user=username)
}

conV=PostgreSQL_con('AWS.R')

# Read in NPS data

query = "SELECT * FROM renew_motion.rm_prod_nps_score"
Initial_NPS <- dbGetQuery(conV, query)
Initial_NPS <- Initial_NPS %>% arrange(savvy_id, create_date, modified_date)

# Create lookup table for SavvyID & CandidateID

query2 = "SELECT * FROM renew_motion.rm_prod_candidate"
LookupTable <- dbGetQuery(conV, query2)
LookupTable <- LookupTable %>% select(candidate_id, savvy_id)

Initial_NPS <- merge(Initial_NPS, LookupTable, by = "savvy_id")

length(unique(Initial_NPS$savvy_id))
length(unique(Initial_NPS$candidate_id))

setwd("/work/ssmela/Renew Motion")

# Throw out data after March 23rd (last date of Round 1 NPS calls)

Initial_NPS <- Initial_NPS %>% filter(create_date < "2018-03-24") %>% mutate(nps_score = as.numeric(nps_score))

length(unique(Initial_NPS$savvy_id))  # Now 5104; was 5084 previously

# Filter out nulls

Initial_NPS <- Initial_NPS %>% filter(is.na(nps_score) == F)
length(unique(Initial_NPS$savvy_id))                    # Back to 5084

## Looking for multiple records ## 

Initial_NPS$Duplicate <- 0

for (i in 2:(length(Initial_NPS$savvy_id))) {
  
  if (Initial_NPS$savvy_id[i] == Initial_NPS$savvy_id[i-1]) {
    
    Initial_NPS$Duplicate[i] <- 9999
    Initial_NPS$Duplicate[i-1] <- 8888
  }
  
}


# Split into duplicated and non-duplicated records

Duplicates <- Initial_NPS %>% filter(Duplicate != 0)

NoDuplicates <- Initial_NPS %>% filter(Duplicate == 0)

length(NoDuplicates$savvy_id)   # 4933
length(unique(Duplicates$savvy_id))   # 151


# Within Duplicates, find cases where scores are the same (not an issue)

Duplicates$SameScore <- 0

for (i in 2:(length(Duplicates$savvy_id))) {
  
  if (Duplicates$savvy_id[i] == Duplicates$savvy_id[i-1] & Duplicates$nps_score[i] == Duplicates$nps_score[i-1]) {
    
    Duplicates$SameScore[i] <- 1
    Duplicates$SameScore[i-1] <- 1
  }
    
}

# Take care of triplicates or higher multiples

Duplicates$SameScore[Duplicates$savvy_id %in% c(14361, 15526)] <- 0  

## Split into those with same scores and those with different scores

SameScores <- Duplicates %>% filter(SameScore == 1)
DiffScores <- Duplicates %>% filter(SameScore == 0)

# Read in corrections from Excel file

Corrections <- read_excel("/work/ssmela/Renew Motion/Renew motion survey final clean up 052318 2 (003).xlsx")
Corrections <- Corrections[,2:9]

# Throw out data after March 23rd (last date of Round 1 NPS calls)

Corrections <- Corrections %>% filter(create_date < "2018-03-24")


DiffScores <- DiffScores %>% select(savvy_id, nps_score, create_date, candidate_id)

CorrIDs <- unique(Corrections$candidate_id)
DiffIDs <- unique(DiffScores$candidate_id)

# Different numbers of IDs in each list; and one is not a subset of the other

setdiff(CorrIDs, DiffIDs)  # In Corrections list, not in Diffs list.  Some (30) on this list, but looks like data were changed
           # since Corrections file was pulled on 5/23, so not gonna worry about it.
setdiff(DiffIDs, CorrIDs)  # In Diffs list, not in Corrections list.  None here.

### Merge corrections info into list of IDs on Diff list  ##

DiffIDs <- as.data.frame(DiffIDs)

DiffIDs <- DiffIDs %>% rename(candidate_id = DiffIDs) %>% mutate(candidate_id = as.character(candidate_id))

# Merge in those that are "yes", "min", and "max"
Yes <- Corrections %>% filter(Use == "Yes") %>% select(candidate_id, nps_score) %>% rename(YesScore = nps_score)

DiffCorrected <- merge(DiffIDs, Yes, by = "candidate_id", all.x = T)

Min <- Corrections %>% filter(Use == "Min") %>% select(candidate_id, nps_score) %>% rename(MinScore = nps_score)

DiffCorrected <- merge(DiffCorrected, Min, by = "candidate_id", all.x = T)

Max <- Corrections %>% filter(Use == "Max" | Use == "max") %>% select(candidate_id, nps_score) %>% rename(MaxScore = nps_score)

DiffCorrected <- merge(DiffCorrected, Max, by = "candidate_id", all.x = T)

# Four IDs have no score. Notes in Excel file say they were "unknown / not a survey call."

# Replace missing Min and Max scores with Yes scores

DiffCorrected <- DiffCorrected %>% 
  mutate(MinScore = ifelse(is.na(MinScore), YesScore, MinScore),
         MaxScore = ifelse(is.na(MaxScore), YesScore, MaxScore))

### Re-build master data set, using No Duplicates, Same Scores, and DiffCorrected, the latter with 2 versions, 
### one with min scores and the other with max score

Set1 <- NoDuplicates %>% select(candidate_id, nps_score)
Set2 <- SameScores %>% 
  select(candidate_id, nps_score) %>%
  group_by(candidate_id) %>%
  summarise(nps_score = mean(nps_score))

SetMin <- DiffCorrected %>% 
  filter(is.na(MinScore) == F) %>% 
  rename(nps_score = MinScore) %>% 
  select(candidate_id, nps_score)

SetMax <- DiffCorrected %>% 
  filter(is.na(MaxScore) == F) %>% 
  rename(nps_score = MaxScore) %>% 
  select(candidate_id, nps_score)

MinNPS <- rbind(Set1, Set2)
MinNPS <- rbind(MinNPS, SetMin)

MaxNPS <- rbind(Set1, Set2)
MaxNPS <- rbind(MaxNPS, SetMax)

# Put people into groups; 0-6 Detractors, 7-8 Passive, 9-10 Promotors
MinNPS <- MinNPS %>% mutate(NPSGroup = ifelse(nps_score <= 6, -1, ifelse(nps_score >= 9, 1, 0)))
MaxNPS <- MaxNPS %>% mutate(NPSGroup = ifelse(nps_score <= 6, -1, ifelse(nps_score >= 9, 1, 0)))




# What if we look at NPS among just participants?  And we can bring in the post-3/23 round 1 calls.

# Re-load NPS data

LateNPS <- dbGetQuery(conV, query)
LateNPS <- LateNPS %>% arrange(savvy_id, create_date, modified_date)

# Create lookup table for SavvyID & CandidateID

LateNPS <- merge(LateNPS, LookupTable, by = "savvy_id")

length(unique(LateNPS$savvy_id))
length(unique(LateNPS$candidate_id))

# Throw out data before March 24th (last date of Round 1 NPS calls) and after May 23rd (start of Round 2 calls)

LateNPS <- LateNPS %>% 
  filter(create_date >= "2018-03-24" & create_date <= "2018-05-24") %>% 
  mutate(nps_score = as.numeric(nps_score))

LateNPS <- LateNPS %>% filter(is.na(LateNPS$nps_score) == F)           # Line added 8/6/2018

# Find duplicates

LateNPS$Duplicate <- 0


for (i in 2:(length(LateNPS$savvy_id))) {
  
  if (LateNPS$savvy_id[i] == LateNPS$savvy_id[i-1]) {
    
    LateNPS$Duplicate[i] <- 9999
    LateNPS$Duplicate[i-1] <- 8888
  }
  
}

LateNPS <- LateNPS %>% select(savvy_id, candidate_id, create_date, nps_score, Duplicate)

LateNPS %>% filter(Duplicate != 0)

# There are few enough of these that we can make the corrections 'by hand' using the Excel corrections file

MinNPS2 <- LateNPS %>% select(savvy_id, candidate_id, nps_score, Duplicate)

MinNPS2 <- MinNPS2 %>% 
  filter(!(savvy_id == 2562 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 3547 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 5839 & Duplicate == 9999)) %>%
  filter(!(savvy_id == 6771 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 8298 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 10505 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 10705))                              # Has an NPS number from 3/14

MinNPS2 <- MinNPS2 %>%
  select(candidate_id, nps_score) %>%
  mutate(NPSGroup = ifelse(nps_score <= 6, -1, ifelse(nps_score >= 9, 1, 0)))


MaxNPS2 <- LateNPS %>% select(savvy_id, candidate_id, nps_score, Duplicate)

MaxNPS2 <- MaxNPS2 %>% 
  filter(!(savvy_id == 2562 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 3547 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 5839 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 6771 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 8298 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 10505 & Duplicate == 8888)) %>%
  filter(!(savvy_id == 10705))                              # Has an NPS number from 3/14

MaxNPS2 <- MaxNPS2 %>%
  select(candidate_id, nps_score) %>%
  mutate(NPSGroup = ifelse(nps_score <= 6, -1, ifelse(nps_score >= 9, 1, 0)))

MinNPS <- MinNPS %>% mutate(Group = 1)
MaxNPS <- MaxNPS %>% mutate(Group = 1)

MinNPS2 <- MinNPS2 %>% mutate(Group = 2)
MaxNPS2 <- MaxNPS2 %>% mutate(Group = 2)

MinCombo <- rbind(MinNPS, MinNPS2)
MaxCombo <- rbind(MaxNPS, MaxNPS2)


# Any duplicates?

MinCombo$Duplicate <- 0

MinCombo <- MinCombo %>% arrange(candidate_id)

for (i in 2:(length(MinCombo$candidate_id))) {
  
  if (MinCombo$candidate_id[i] == MinCombo$candidate_id[i-1]) {
    
    MinCombo$Duplicate[i] <- 9999
    MinCombo$Duplicate[i-1] <- 8888
  }
  
}

MaxCombo$Duplicate <- 0

MaxCombo <- MaxCombo %>% arrange(candidate_id)

for (i in 2:(length(MaxCombo$candidate_id))) {
  
  if (MaxCombo$candidate_id[i] == MaxCombo$candidate_id[i-1]) {
    
    MaxCombo$Duplicate[i] <- 9999
    MaxCombo$Duplicate[i-1] <- 8888
  }
  
}

