# Goal Achievement Comparison

# Steve Smela, UHG R&D
# August 2018

# For Renew Motion Study.  Works on NGIS. Pulls in data from Walk and Win and Lifetime Value pilots in order to make
# comparisons to Renew Motion results.

library(dplyr)
library(RODBC)
library(tidyverse)
library(survival)

# Used to access data on NGIS.  ODBC_Connection will have to be modified depening on the user's settings. Database is on
# DBSEP3832 server.

database1 <- "LTV"
database2 <- "pdb_WalkandWin"
ODBC_Connection = "pdbRally"
channel <- odbcConnect(ODBC_Connection)

QGoals = "SELECT * FROM pdb_WalkandWin.dbo.MEMBEREarnedIncentiveDetails_20180716 WHERE ClientName LIKE 'XL%'"
Goals <- sqlQuery(channel, QGoals)

Goals <- Goals %>%
  mutate(ClientName = as.character(ClientName)) %>%
  filter(ClientName %in% c("XLHealth", "XLHealth50", "XLHealth150", "XLHealth250")) 

  
temp <- Goals %>%    
  group_by(DERMMemberID) %>%
  filter(TotalSteps > 0) %>%
  mutate(FirstDay = min(IncentiveDate),
         EndDate = FirstDay + 173) %>%
  filter(IncentiveDate <= EndDate) %>%
  arrange(DERMMemberID, IncentiveDate) %>%
  select(DERMMemberID, IncentiveDate, FirstDay, EndDate, everything())


ActiveDays <- temp %>%
  filter(TotalSteps > 300) %>%
  group_by(DERMMemberID) %>%
  summarise(FirstActiveDate = min(IncentiveDate),
            LastActiveDate = max(IncentiveDate),
            TotalDaysActive = as.numeric(LastActiveDate - FirstActiveDate) + 1,
            ActiveDays = n(),
            AvgStepsActive = mean(TotalSteps))

WalkingSummary <- temp %>%
  group_by(DERMMemberID) %>%
  summarise(FirstDate = min(IncentiveDate),
            LastDate = max(IncentiveDate),
            TotalDays = as.numeric(LastDate - FirstDate) + 1,
            DaysWalked = n(),
            PctDaysWalked = 100 * DaysWalked / TotalDays,
            AvgSteps = mean(TotalSteps),
            Frequency = sum(Frequency),
            Intensity = sum(Intensity),
            Tenacity = sum(Tenacity),
            PctFrequency = 100 * Frequency / TotalDays,
            PctIntensity = 100 * Intensity / TotalDays,
            PctTenacity = 100 * Tenacity / TotalDays,
            ClientName = first(ClientName))

WalkingSummary <- merge(WalkingSummary, ActiveDays, by = "DERMMemberID", all.x = T)

WalkingSummary <- WalkingSummary %>% 
  mutate(PctDaysActive = 100 * ActiveDays / TotalDays)

WalkingSummary %>%
  group_by(ClientName) %>%
  summarise(PctDaysWalked = mean(PctDaysWalked),
            PctDaysActive = mean(PctDaysActive, na.rm = T),
            AvgSteps = mean(AvgSteps), 
            AvgStepsActive = mean(AvgStepsActive, na.rm = T),
            PctFrequency = mean(PctFrequency),
            PctTenacity = mean(PctTenacity),
            PctIntensity = mean(PctIntensity))

### Survival Analysis ###  (from AvMo report)

# LTV Pilot

LTVWalkingQuery <- paste0("select A.SavvyHICN, PilotType, Incentive_Group, B.* ",
                          "from pdb_WalkandWin.dbo.GP1026_WnW_Member_Details as A ",
                          "join pdb_WalkandWin.dbo.GP1026_WnW_Derm_Info as B ",
                          "on A.SavvyHicn = B.SavvyHicn ",
                          "where PilotType = 'Lifetime Value' ")

LTVWalking <- sqlQuery(channel, LTVWalkingQuery)

LTVWalking <- LTVWalking %>% select(-SavvyHicn)

# Indiana 2016

INWalkingQuery <- paste0("SELECT SavvyHICN, SavvyID, Call_Flag, ST_ABBR_CD, WithemailFlag, GroupNumber, Outreach_Method,  ",
                         "Message_Invite, Motivation, Net_Promoter_Score, SilverSneaker_Flag, Sync_Type, Registered_Flag,  ",
                         "WithSteps_Flag, Daysmet_FreqTen, Daysmet_Frqcy, TotalFreq_Bouts, Daysmet_Tncty, Total_Steps,  ",
                         "Total_Incentives, AvgSteps, 300ormoreSteps, FirstLogDate, LastLogDate, LastSyncDate, DaysEnrolled,  ",
                         "Enrollment_Date, EndorsedMember_Flag, CancelledDateTime, Registered_QMS, DateRun, Member_Status, Dateofcall ",
                         "FROM pdb_WalkandWin.dbo.Member_2016_Pilot ",
                         " where Registered_Flag = 1 and ST_ABBR_CD = 'IN' ")

INWalking <- sqlQuery(channel, INWalkingQuery)

# Combined table

CombinedQuery <- "SELECT SavvyHICN, ActiveDays FROM pdb_WalkandWin.dbo.Member_Steps_Combined"

Combined <- sqlQuery(channel, CombinedQuery)


# So for LTV data, last date of data is 3/14/18; let's give a two-week grace period and treat anyone whose last log date was after 2018-02-28 as censored.  (Maybe
# they're still participating but just didn't synch).

LTVCensorDate <- "2018-02-28"

LTVWalking <- LTVWalking %>% 
  filter(ActivatedTrio_Flag == 1 & Incentive_Group != "") %>%
  mutate(DaysParticipating = as.integer(as.Date(LastLogDate) - as.Date(FirstLogDate) + 1))

LTVWalking <- LTVWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, LastSyncDate, DaysEnrolled, everything())

# Create 'death' variable

LTVWalking <- LTVWalking %>% mutate(Quit = ifelse(as.character(LastLogDate) <= LTVCensorDate , 1, 0))

LTVWalking <- LTVWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, Quit, LastSyncDate, DaysEnrolled, everything())


# Now let's look at Indiana data

INCensorDate <- "2018-03-09"

INWalking <- INWalking %>% 
  filter(WithSteps_Flag == 1) %>%
  mutate(DaysParticipating = as.integer(as.Date(LastLogDate) - as.Date(FirstLogDate) + 1))

INWalking <- INWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, LastSyncDate, DaysEnrolled, everything())

# Create 'death' variable

INWalking <- INWalking %>% mutate(Quit = ifelse(as.character(LastLogDate) <= INCensorDate , 1, 0))

INWalking <- INWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, Quit, LastSyncDate, DaysEnrolled, everything())

INWalking <- merge(INWalking, Combined, by = "SavvyHICN", all.x = T)


# Create combined data set

LTV <- LTVWalking %>% select(DaysParticipating, Quit, Incentive_Group)
IN <- INWalking %>% select(DaysParticipating, Quit) %>% mutate(Incentive_Group = "IN 2016")

Combined <- rbind(LTV, IN)

# LTV Pilot

LTVWalkingQuery <- paste0("select A.SavvyHICN, PilotType, Incentive_Group, B.* ",
                          "from pdb_WalkandWin.dbo.GP1026_WnW_Member_Details as A ",
                          "join pdb_WalkandWin.dbo.GP1026_WnW_Derm_Info as B ",
                          "on A.SavvyHicn = B.SavvyHicn ",
                          "where PilotType = 'Lifetime Value' ")

LTVWalking <- sqlQuery(channel, LTVWalkingQuery)

LTVWalking <- LTVWalking %>% select(-SavvyHicn)

# Indiana 2016

INWalkingQuery <- paste0("SELECT SavvyHICN, SavvyID, Call_Flag, ST_ABBR_CD, WithemailFlag, GroupNumber, Outreach_Method,  ",
                         "Message_Invite, Motivation, Net_Promoter_Score, SilverSneaker_Flag, Sync_Type, Registered_Flag,  ",
                         "WithSteps_Flag, Daysmet_FreqTen, Daysmet_Frqcy, TotalFreq_Bouts, Daysmet_Tncty, Total_Steps,  ",
                         "Total_Incentives, AvgSteps, 300ormoreSteps, FirstLogDate, LastLogDate, LastSyncDate, DaysEnrolled,  ",
                         "Enrollment_Date, EndorsedMember_Flag, CancelledDateTime, Registered_QMS, DateRun, Member_Status, Dateofcall ",
                         "FROM pdb_WalkandWin.dbo.Member_2016_Pilot ",
                         " where Registered_Flag = 1 and ST_ABBR_CD = 'IN' ")

INWalking <- sqlQuery(channel, INWalkingQuery)

# Combined table

CombinedQuery <- "SELECT SavvyHICN, ActiveDays FROM pdb_WalkandWin.dbo.Member_Steps_Combined"

Combined <- sqlQuery(channel, CombinedQuery)


# So for LTV data, last date of data is 3/14/18; let's give a two-week grace period and treat anyone whose last log date was after 2018-02-28 as censored.  (Maybe
# they're still participating but just didn't synch).

LTVCensorDate <- "2018-02-28"

LTVWalking <- LTVWalking %>% 
  filter(ActivatedTrio_Flag == 1 & Incentive_Group != "") %>%
  mutate(DaysParticipating = as.integer(as.Date(LastLogDate) - as.Date(FirstLogDate) + 1))

LTVWalking <- LTVWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, LastSyncDate, DaysEnrolled, everything())

# Create 'death' variable

LTVWalking <- LTVWalking %>% mutate(Quit = ifelse(as.character(LastLogDate) <= LTVCensorDate , 1, 0))

LTVWalking <- LTVWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, Quit, LastSyncDate, DaysEnrolled, everything())


# Now let's look at Indiana data

INCensorDate <- "2018-03-09"

INWalking <- INWalking %>% 
  filter(WithSteps_Flag == 1) %>%
  mutate(DaysParticipating = as.integer(as.Date(LastLogDate) - as.Date(FirstLogDate) + 1))

INWalking <- INWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, LastSyncDate, DaysEnrolled, everything())

# Create 'death' variable

INWalking <- INWalking %>% mutate(Quit = ifelse(as.character(LastLogDate) <= INCensorDate , 1, 0))

INWalking <- INWalking %>% select(Enrollment_Date, FirstLogDate, LastLogDate, DaysParticipating, Quit, LastSyncDate, DaysEnrolled, everything())

INWalking <- merge(INWalking, Combined, by = "SavvyHICN", all.x = T)


# Create combined data set

LTV <- LTVWalking %>% select(DaysParticipating, Quit, Incentive_Group)
IN <- INWalking %>% select(DaysParticipating, Quit) %>% mutate(Incentive_Group = "IN 2016")

Combined <- rbind(LTV, IN)


ComboMod <- survfit(Surv(time = DaysParticipating, event = Quit) ~ as.factor(Incentive_Group), data = Combined, 
                    type = 'kaplan-meier')

plot(ComboMod, col = 1:4, xlab = "Days since first log date",  ylab = "% remaining active", 
     xlim = c(0,175))
legend(0, .58, c( "WnW: $50", "LTV: $50", "LTV: $150", "LTV: $250"), lty = 1, col = c(4,3,1,2),
       title = "Incentive Group")
title("WnW and LTV Retention")
abline(v = 100, col = 'gray')



summary(ComboMod, times = 100)
