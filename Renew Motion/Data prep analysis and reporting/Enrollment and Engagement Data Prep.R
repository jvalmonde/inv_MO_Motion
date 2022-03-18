## Renew Motion Enrollment and Engagement Data Prep

# Steve Smela, UHG R&D
# August, 2018

# Getting at Killer Question #2 from Renew Motion initiative, 

# Does the Fitbit program achieve better enrollment, tracker use, retention, activity levels, and goal achievement than past Trio-based programs?

library(tidyverse)
library(RPostgres)
library(survival)

setwd("R:/Users/ssmela/Renew Motion")

# User name and password set outside this file.

connection <- dbConnect(RPostgres::Postgres(), dbname='operations', host='operational.c1nqtd6s9v6b.us-east-1.rds.amazonaws.com', 
                 port=5432, password='password', user='user')

# Read in data on activity levels

QStepsRaw <- "SELECT * FROM renew_motion.rm_prod_earnings_daily"
StepsRaw <- dbGetQuery(connection, QStepsRaw) 

Daily <- StepsRaw %>%
  filter(rule_description == "Daily Activity") %>%
  select(savvy_id, Date = goal_date, DailyEarnings = earned_amount, totalsteps, DailyGoalMet = goal_met) %>%
  mutate(Date = as.Date(Date))

Hourly <- StepsRaw %>%
  filter(rule_description == "Hourly Activity") %>%
  select(savvy_id, Date = goal_date, HourlyEarnings = earned_amount, HourlyGoalMet = goal_met) %>%
  mutate(Date = as.Date(Date))

Bonus <- StepsRaw %>%
  filter(rule_description == "Bonus") %>%
  select(savvy_id, Bonus = earned_amount)

Earnings <- merge(Daily, Hourly, by = c("savvy_id", "Date"), all = T)

Earnings <- Earnings %>% replace_na(list(HourlyEarnings = 0, HourlyGoalMet = 0))    # Check data after Karan's fix

## Using criterion of a minimum of 300 steps to be considered an "active" day ##

ActiveDays <- Earnings %>% 
  filter(totalsteps > 300) %>%
  group_by(savvy_id) %>%
  summarise(FirstActiveDate = min(Date),
            LastActiveDate = max(Date),
            TotalDaysActive = as.numeric(LastActiveDate - FirstActiveDate) + 1,
            ActiveDays = n(),
            AvgStepsActive = mean(totalsteps))


WalkingSummary <- Earnings %>%
  group_by(savvy_id) %>%
  summarise(FirstDate = min(Date),
            LastDate = max(Date),
            TotalDays = as.numeric(LastDate - FirstDate) + 1,
            DaysWalked = n(), 
            PctDaysWalked = 100* DaysWalked / TotalDays,
            AvgSteps = mean(totalsteps),
            DailyGoals = sum(DailyGoalMet), 
            HourlyGoals = sum(HourlyGoalMet),
            PctDaily = 100 * DailyGoals / TotalDays,
            PctHourly = 100 * HourlyGoals / TotalDays,
            TotalEarnings = sum(DailyEarnings + HourlyEarnings),
            NotWalking = ifelse(LastDate < Sys.Date() - 10, 1, 0),
            StillWalking = as.factor(NotWalking))

levels(WalkingSummary$StillWalking) <- c("Yes","No")

WalkingSummary <- merge(WalkingSummary, Bonus, by = "savvy_id", all = T)
WalkingSummary <- merge(WalkingSummary, ActiveDays, by = "savvy_id", all.x = T)

WalkingSummary <- WalkingSummary %>%
  replace_na(list(Bonus = 0)) %>%
  mutate(TotalMoney = TotalEarnings + Bonus, 
         MaxReached = ifelse(TotalMoney == 150, "Yes", "No"),
         GetBonus = as.factor(ifelse(Bonus == 25, "Yes", "No")),
         PctDaysActive = 100 * ActiveDays / TotalDays)

WalkingSummary <- WalkingSummary %>%
  select(savvy_id, FirstDate, LastDate, TotalDays, DaysWalked, PctDaysWalked, 
         FirstActiveDate, LastActiveDate, TotalDaysActive, ActiveDays, everything())


## Bring in info on treatment groups ##

QCrosswalk <- "SELECT savvy_id, savvyhicn FROM renew_motion.rm_prod_candidate"
Crosswalk <- dbGetQuery(connection, QCrosswalk) 

QTrtGrps <- "SELECT srckeyid1__c, secondary_treatment_description__c FROM renew_motion.src_salesforce_combined"
TrtGrps <- dbGetQuery(connection, QTrtGrps)
TrtGrps <- TrtGrps %>% rename(savvyhicn = srckeyid1__c, TrtGrp = secondary_treatment_description__c)

Crosswalk <- merge(Crosswalk, TrtGrps, by = "savvyhicn", all.x = T)

WalkingSummary <- merge(WalkingSummary, Crosswalk, by = "savvy_id", all.x = T)


# table(WalkingSummary$TrtGrp) shows that there are 6 individuals walking who are in the 
# Control group (!).  Filter them out.

NoControl <- WalkingSummary %>% 
  filter(TrtGrp != "Control (Survey)") %>%
  mutate(TrtGrp = as.factor(TrtGrp))


