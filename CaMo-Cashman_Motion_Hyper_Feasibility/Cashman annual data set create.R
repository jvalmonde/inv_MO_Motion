# Cashman annual data set create

# Steve Smela, Savvysherpa
# February 2018

# Modeled on "Combined data sets create", but adds in walking data.  Creates a data set of by member and year of Cashman plan members.
# Also saves a file on Cashman member RAF scores (used in the final report).

library(tidyverse)
library(savvy)
library(RODBC)

Med <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member_Medical_Claims_Summary")
Demog <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member") %>% 
  select(-WalkingAccountCreationDate)
Subscribe <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member_Detail")
RAF <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member_RAF") %>%
  rename(Year = Year_Nbr)
Step <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_SMA_Step_Data")

# Note:  Claims info is current up through 9/2017, so I'll filter out any dates after that


##########  Add demographic info to monthly table  ########

# Add indicator for walker / non-walker
Demog <- Demog %>% mutate(Walker = ifelse(is.na(WalkingRegisteredMonth), 0, 1))

Demog <- Demog %>% select(SavvyID, Gender, Age, SES, Walker, WalkingRegisteredMonth)  # Keep just what we want
Demog <- Demog %>% group_by(SavvyID) %>%
  summarise(Gender = first(Gender), Age = first(Age), SES = first(SES), Walker = first(Walker), WalkingRegisteredMonth = first(WalkingRegisteredMonth)) # Get rid of duplicates

Med <- Med %>% 
  filter(Year_Mo <= 201709) %>% 
  select(-SavvyMRN)

CashMemberMonth <- merge(Demog, Med, by = "SavvyID")

# Drop stuff we won't use
CashMemberMonth <- CashMemberMonth %>% select(-BMI, -Systolic, -Diastolic, -RxDaysSupply)

# Adjust Age.  Ages are given at the time data set was created.  Need to back-adjust to approximate actual age in year.

CashMemberMonth <- CashMemberMonth %>% mutate(Year = round(Year_Mo / 100, 0), Month = Year_Mo %% 100)

CashMemberMonth$AgeAdj <- CashMemberMonth$Age - (2017 - CashMemberMonth$Year)  
CashMemberMonth$AgeAdj <- ifelse(CashMemberMonth$AgeAdj < 0, 0, CashMemberMonth$AgeAdj)

###########  Add in Subscriber info (can change with month) #####################

Subscribe <- Subscribe %>% select(SavvyID, Year_Mo, IsSubscriber, SMAIndicator, SavvySubscriberID)

CashMemberMonth <- merge(CashMemberMonth, Subscribe, by = c("SavvyID", "Year_Mo"))


######### Walking stuff ###########################


Step$Year <- as.integer(substr(Step$IncentiveDate, 1, 4))
Step$Month <- as.integer(substr(Step$IncentiveDate, 6, 7))

Step <- Step[!(Step$Year == 2017 & Step$Month > 9),]
Step <- Step[!(Step$Year == 2018),]

# Aggregate step data by year

StepsPersonYear <- Step %>% 
  group_by(SavvyID, Year) %>% 
  summarise(Days = n(), 
            FreqPct = sum(isFrequencyAchieved)/Days,
            IntensityPct = sum(isIntensityAchieved)/Days,
            TenacityPct = sum(isTenacityAchieved)/Days,
            AvgDailySteps = sum(TotalSteps)/Days/ 1000)


##### Add walking data  ####

# Create indicator if Year-Month is after Walking Registered Month

CashMemberMonth <- CashMemberMonth %>% replace_na(list(WalkingRegisteredMonth = 999999))
CashMemberMonth <- CashMemberMonth %>% mutate(Walking = ifelse(Year_Mo >= WalkingRegisteredMonth, 1, 0))

# Determine how long they've been walking--cumulative effects

CashMemberMonth <- CashMemberMonth %>% mutate(Year = round(Year_Mo / 100, 0), Month = Year_Mo %% 100,
                                              YearStart = round(WalkingRegisteredMonth / 100, 0),
                                              MonthStart = WalkingRegisteredMonth %% 100)

CashMemberMonth <- CashMemberMonth %>% mutate(MonthsWalking = ifelse(Walking == 1, 12*(Year - YearStart) + (Month - MonthStart), 0))

CashMemberMonth <- CashMemberMonth %>% select(-YearStart, -MonthStart, -WalkingRegisteredMonth)

######  Collapse down to annual data set  ####

CashMemberYear <- CashMemberMonth %>% group_by(SavvyID, Year) %>% 
  summarise(MedSpend = sum(TotalMedicalSpend),
            TotalSpend = sum(TotalMedicalSpend + RxSpend),
            RVUs = sum(DrRVU),
            Months = n(),
            MedSpendPM = MedSpend / Months,
            RVUPM = RVUs / Months,
            SpendPM = TotalSpend / Months,
            DrSpendPM = sum(DrSpend) / Months,
            DrServiceDatesPM = sum(DrServiceDates) / Months,
            DrVisitsPM = sum(DrVisits) / Months,
            IPSpendPM = sum(IpSpend) / Months,
            IPAdmitsPM = sum(IpAdmits) / Months,
            IPDaysOfStayPM = sum(IpDaysOfStay) / Months, 
            OPSpendPM = sum(OpSpend) / Months,
            OPServiceDatesPM = sum(OpServiceDates) / Months, 
            OpVisitsPM = sum(OpVisits) / Months,
            OtherSpendPM = sum(OtherSpend) / Months,
            OtherServiceDatesPM = sum(OtherServiceDates) / Months, 
            OtherVistsPM = sum(OtherVisits) / Months,
            RxSpendPM = sum(RxSpend) / Months,
            Subscriber = max(IsSubscriber),
            Gender = first(Gender),
            AgeAdj = mean(AgeAdj), 
            SES = first(SES),
            SMA = first(SMAIndicator),
            SubscriberID = first(SavvySubscriberID),
            MonthsWalking = mean(MonthsWalking)) %>%
  arrange(SavvyID, Year)


# Merge in walking data

CashMemberYear <- merge(CashMemberYear, StepsPersonYear, by = c("SavvyID", "Year"), all.x = TRUE)
CashMemberYear <- CashMemberYear %>% replace_na(list(Days = 0, FreqPct = 0, IntensityPct = 0, TenacityPct = 0, AvgDailySteps = 0))

######### Clean up & some additional vars ###################


CashMemberYear <- CashMemberYear %>%
  mutate(AnyMedicalSpend = ifelse(MedSpend > 0, 1, 0), 
         AnyRVU = ifelse(RVUs > 0, 1, 0), 
         AnyRx = ifelse(RxSpendPM > 0, 1, 0),
         AnyClaim = ifelse(MedSpend > 0 | RVUs > 0, 1, 0),
         AnySpend = ifelse(SpendPM > 0, 1, 0),
         Age0 = ifelse(AgeAdj == 0, 1, 0))

CashMemberYear$StdAgeAdj <- (CashMemberYear$AgeAdj - mean(CashMemberYear$AgeAdj))/ sd(CashMemberYear$AgeAdj)
CashMemberYear$StdSES <- (CashMemberYear$SES - mean(CashMemberYear$SES, na.rm = T))/ sd(CashMemberYear$SES, na.rm = T)



##### Save file #####

save(CashMemberYear, file = "CashMemberYear.rda")
save(RAF, file="CashRAF.rda")
