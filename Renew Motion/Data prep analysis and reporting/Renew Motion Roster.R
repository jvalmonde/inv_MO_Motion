# Renew Motion Roster.R

# Steve Smela, Savvysherpa
# May 2018

# Reads in data from AWS, groups individuals into households, creates and saves a master list of the study population

require("RPostgreSQL")
library(tidyverse)

# Code for opening connection to AWS from Riley servers.  File AWS has user-specific info and will need to be
# created for each user.

setwd("/home/ssmela")

PostgreSQL_con=function(file){
  library('RPostgreSQL')
  source(file,local=TRUE)
  dbConnect(RPostgreSQL::PostgreSQL(), dbname=pg_dsn, host=host, port=port, password=password, user=username)
}

conV=PostgreSQL_con('AWS.R')

query = "SELECT * FROM renew_motion.src_salesforce_combined"

Roster <- dbGetQuery(conV, query)

setwd("/work/ssmela/Renew Motion")

Roster <- Roster %>% mutate(SavvyHICN = as.numeric(srckeyid1__c)) %>% arrange(SavvyHICN)

## Looking for duplicates ##

Roster$Duplicate <- 0

for (i in 2:(length(Roster$SavvyHICN))) {
  Roster$Duplicate[i] <- ifelse(Roster$SavvyHICN[i] == Roster$SavvyHICN[i-1], 9999, 0)
}

table(Roster$Duplicate)

Roster <- Roster %>% arrange(lastname, firstname)

for (i in 2:(length(Roster$SavvyHICN))) {
  Roster$Duplicate[i] <- ifelse(Roster$lastname[i] == Roster$lastname[i-1] & Roster$firstname[i] == Roster$firstname[i-1], 9999, 0)
}

Roster2 <- Roster %>% select(Duplicate, SavvyHICN, lastname, firstname, street, city, state, postalcode, birthdate, gender__c,secondary_treatment_description__c)

# Doesn't appear to be any duplicates.  Count is off by 1 from Mike Maresh's reports-- 16337 instead of 16336-- one more member
# in Survey + Bonus + Screening group

table(Roster$secondary_treatment_description__c)


###### Looking for members who live together ####

Roster2 <- Roster %>% 
  select(SavvyHICN,
         secondary_treatment_description__c,
         firstname,
         lastname,
         street,
         city,
         state,
         postalcode,
         birthdate,
         gender__c,
         phone) %>%
  rename(TrtGroup = secondary_treatment_description__c) %>%
  arrange(postalcode,
          state,
          city,
          street,
          lastname,
          firstname)

# Same address, name & phone #

Roster2$SameAddress <- 0
Roster2$SameName <- 0
Roster2$SamePhone <- 0

for (i in 2:(length(Roster2$SavvyHICN))) {
  
  if (Roster2$postalcode[i] == Roster2$postalcode[i-1] & Roster2$state[i] == Roster2$state[i-1] & Roster2$city[i] == Roster2$city[i-1] &
      Roster2$street[i] == Roster2$street[i-1]) {
    
    Roster2$SameAddress[i] <- i
    Roster2$SameAddress[i-1] <- i
    
  }
  
  if (Roster2$lastname[i] == Roster2$lastname[i-1]) {
    
    Roster2$SameName[i] <- i
    Roster2$SameName[i-1] <- i
    
  }
  
  if (Roster2$phone[i] == Roster2$phone[i-1]) {
    
    Roster2$SamePhone[i] <- i
    Roster2$SamePhone[i-1] <- i
    
  }

}

Roster2 <- Roster2 %>%
  mutate(All3 = ifelse(SameAddress > 0 & SameName > 0 & SamePhone > 0, 1, 0),
         AddName = ifelse(SameAddress > 0 & SameName > 0 & SamePhone == 0, 1, 0),
         AddPhone = ifelse(SameAddress > 0 & SameName == 0 & SamePhone > 0, 1, 0), 
         NamePhone = ifelse(SameAddress == 0 & SameName > 0 & SamePhone > 0, 1, 0),
         AddOnly = ifelse(SameAddress > 0 & SameName == 0 & SamePhone == 0, 1, 0),
         NameOnly = ifelse(SameAddress == 0 & SameName > 0 & SamePhone == 0, 1, 0),
         PhoneOnly = ifelse(SameAddress == 0 & SameName == 0 & SamePhone > 0, 1, 0))

# Let's say that if any of Address, Name or Phone are the same, they're in the same household

Roster2$Household <- 0

for (i in 1:(length(Roster2$SavvyHICN))) {
  
  Roster2$Household[i] <- max(Roster2$SameAddress[i], Roster2$SameName[i], Roster2$SamePhone[i])
  
}

Roster2 <- Roster2 %>% 
  select(Household, firstname:postalcode, phone, everything()) %>%
  arrange(desc(Household))

## Looks like things turned out pretty well ##

# But let's do some cleanup

Roster3 <- Roster2 %>%
  filter(Household > 0) %>%
  group_by(Household) %>%
  mutate(HHSize = n()) %>%
  select(HHSize, everything()) %>%
  arrange(HHSize)

# There are 20 members who are in households of size 1. Group them either with others or by themselves. 21 appear on list below b/c of a switcheroo.

Roster2$Household[Roster2$SavvyHICN == 18634814] <- 15003
Roster2$Household[Roster2$SavvyHICN == 18593734] <- 14872
Roster2$Household[Roster2$SavvyHICN == 14958263] <- 0
Roster2$Household[Roster2$SavvyHICN == 21111642] <- 14601
Roster2$Household[Roster2$SavvyHICN == 13255056] <- 0
Roster2$Household[Roster2$SavvyHICN == 20699066] <- 13971
Roster2$Household[Roster2$SavvyHICN == 20594632] <- 0
Roster2$Household[Roster2$SavvyHICN == 18473866] <- 13440
Roster2$Household[Roster2$SavvyHICN == 20277686] <- 13109
Roster2$Household[Roster2$SavvyHICN == 20455496] <- 12996
Roster2$Household[Roster2$SavvyHICN == 18565063] <- 12892
Roster2$Household[Roster2$SavvyHICN == 20154184] <- 12563
Roster2$Household[Roster2$SavvyHICN == 20230178] <- 0
Roster2$Household[Roster2$SavvyHICN == 1074571]  <- 0
Roster2$Household[Roster2$SavvyHICN == 340470]   <- 9285
Roster2$Household[Roster2$SavvyHICN == 21528964] <- 0
Roster2$Household[Roster2$SavvyHICN == 19487278] <- 9275
Roster2$Household[Roster2$SavvyHICN == 19864539] <- 8461
Roster2$Household[Roster2$SavvyHICN == 8915454]  <- 0
Roster2$Household[Roster2$SavvyHICN == 1213604]  <- 5925
Roster2$Household[Roster2$SavvyHICN == 19969890] <- 4003

# Based on other work (see Renew Motion Data Check), we have 4 individuals who somehow got dropped from the mailing list, NPS calls, etc.

Roster2 %>% filter(SavvyHICN %in% c(83622, 14901701, 20517336, 20711703)) %>% select(Household, SavvyHICN, lastname, street)

Roster2 %>% filter(Household %in% c(4595, 13436)) %>% select(Household, SavvyHICN, lastname, street)  

Roster2 <- Roster2 %>% filter(!(SavvyHICN %in% c(83622, 14901701, 20517336, 20711703)))

# Members of households of these 4 individuals who got dropped

Roster2$Household[Roster2$Household == 4595] <- 0
Roster2$Household[Roster2$Household == 13436] <- 0

Roster3 <- Roster2 %>%
  filter(Household > 0) %>%
  group_by(Household) %>%
  mutate(HHSize = n()) %>%
  select(HHSize, everything()) %>%
  arrange(HHSize)

# Let's look at where we have only an address match

table(Roster2$AddOnly)   # 243 cases

Roster2 <- Roster2 %>% arrange(desc(AddOnly), Household)

Roster2$Household[Roster2$Household %in% c(15484)] <- 0  # Senior living facility; all others checked out OK

# May 21:  Found another household that fell through the cracks.  (Wife was in Control group and signed up for a device)

Roster2$Household[Roster2$SavvyHICN %in% c(19969457, 18523038)] <- 16338

# Let's see how often members of household were put into same treatment group

Roster4 <- Roster2 %>% 
  filter(Household > 0) %>% 
  select(Household, TrtGroup) %>%
  group_by(Household, TrtGroup) %>%
  summarise(NumInGroup = n()) %>%
  group_by(Household) %>%
  summarise(HHoldSize = sum(NumInGroup),
            NumOfGroups = n())

table(Roster4$HHoldSize, Roster4$NumOfGroups)

save(Roster2, file = "Renew Motion Roster.rda")

