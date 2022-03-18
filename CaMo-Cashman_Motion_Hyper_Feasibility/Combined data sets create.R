# Combined data sets create

# Steve Smela, Savvysherpa
# February 2018

# For Cashman project, reads in data for Cashman and comparison comapanies and combines them into unified data sets.
# Creates two data sets, one at the member-month level and one at the member-year level.  In the end, only the latter was
# used in the analyses.

library(tidyverse)
library(savvy)
library(RODBC)

# Read in tables from database
SMAMed <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.SMA_Non_Cashman_Member_Medical_Claims_Summary")
SMADemog <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.SMA_Non_Cashman_Member")
SMASubscribe <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.SMA_Non_Cashman_Member_Detail")
SMARAF <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.SMA_Non_Cashman_Member_RAF") %>%
  rename(Year = Year_Nbr)


CashMed <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member_Medical_Claims_Summary")
CashDemog <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member") %>% 
  select(-WalkingAccountCreationDate, -WalkingRegisteredMonth)
CashSubscribe <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member_Detail")
CashRAF <- read.odbc("Devsql10", dbQuery = "select * from pdb_Cashman.dbo.Cashman_Member_RAF") %>%
  rename(Year = Year_Nbr)

# Note:  Claims info is current up through 9/2017, so I'll filter out any dates after that

Med <- rbind(SMAMed, CashMed)
Demog <- rbind(SMADemog, CashDemog)
Subscribe <- rbind(SMASubscribe, CashSubscribe)
RAF <- rbind(SMARAF, CashRAF)

##########  Add demographic info to monthly table  ########

Demog <- Demog %>% select(SavvyID, Gender, Age, SES)  # Keep just what we want
Demog <- Demog %>% group_by(SavvyID) %>%
  summarise(Gender = first(Gender), Age = first(Age), SES = first(SES)) # Get rid of duplicates

Med <- Med %>% 
  filter(Year_Mo <= 201709) %>% 
  select(-SavvyMRN)

MemberMonth <- merge(Demog, Med, by = "SavvyID")

# Drop stuff we won't use
MemberMonth <- MemberMonth %>% select(-BMI, -Systolic, -Diastolic, -RxDaysSupply)

# Adjust Age.  Ages are given at the time data set was created.  Need to back-adjust to approximate actual age in year.

MemberMonth <- MemberMonth %>% mutate(Year = round(Year_Mo / 100, 0), Month = Year_Mo %% 100)

MemberMonth$AgeAdj <- MemberMonth$Age - (2017 - MemberMonth$Year)  
MemberMonth$AgeAdj <- ifelse(MemberMonth$AgeAdj < 0, 0, MemberMonth$AgeAdj)

###########  Add in Subscriber info (can change with month) #####################

Subscribe <- Subscribe %>% select(SavvyID, Year_Mo, IsSubscriber, GroupName, SMAIndicator, SavvySubscriberID)

MemberMonth <- merge(MemberMonth, Subscribe, by = c("SavvyID", "Year_Mo"))

##############  Take out data we're not going to use ######

# Decided not to used Advanstaff and Tropicana in study.  Take out MV Contract Transport prior to 6/2013 because it
# didn't really get up and running until then.

MemberMonth <- MemberMonth %>% filter(!(GroupName == 'MV CONTRACT TRANSPORTATION, INC.' & Year_Mo <= 201306)) %>%
  filter(GroupName != 'TROPICANA RESORT' & GroupName != 'ADVANSTAFF')


######################  Collapse down to create data set of annual observations ###############

MemberYear <- MemberMonth %>% group_by(SavvyID, Year) %>% 
  summarise(GroupName = first(GroupName),
            MedSpend = sum(TotalMedicalSpend),
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
            SubscriberID = first(SavvySubscriberID)) %>%
  arrange(SavvyID, Year)


############  Merge in RAF data ################

# Clean up duplicate/wrong values

RAF <- RAF %>% filter(!(SavvyID == 616529 & Age <=25))
RAF <- RAF %>% filter(!(SavvyID == 1507691 & Age == 20))
RAF <- RAF %>% distinct()


# Take out Age from RAF dataset

RAF <- RAF %>% select(-Age)

MemberYear <- merge(MemberYear, RAF, by = c("SavvyID", "Year"), all.x = TRUE)
MemberMonth <- merge(MemberMonth, RAF, by = c("SavvyID", "Year"), all.x = TRUE)

# Fifty-four non-Cashman values have missing RAFs. Not gonna worry about it.

"
  MemberYear[is.na(MemberYear$RAF) == TRUE, c('SavvyID', 'Year')]
  dim(MemberYear[is.na(MemberYear$RAF) == TRUE, c('SavvyID', 'Year')])
"
# But four Cahsman values have missing RAFs.  Replace them with adjacent values

MemberYear[MemberYear$SavvyID == 1244142 & is.na(MemberYear$RAF) == TRUE, ]$RAF <- 1.572
MemberYear[MemberYear$SavvyID == 1247412 & is.na(MemberYear$RAF) == TRUE, ]$RAF <- 1.572
MemberYear[MemberYear$SavvyID == 1309743 & is.na(MemberYear$RAF) == TRUE, ]$RAF <- 0.998
MemberYear[MemberYear$SavvyID == 1792429 & is.na(MemberYear$RAF) == TRUE, ]$RAF <- 18.560

MemberMonth[MemberMonth$SavvyID == 1244142 & is.na(MemberMonth$RAF) == TRUE, ]$RAF <- 1.572
MemberMonth[MemberMonth$SavvyID == 1247412 & is.na(MemberMonth$RAF) == TRUE, ]$RAF <- 1.572
MemberMonth[MemberMonth$SavvyID == 1309743 & is.na(MemberMonth$RAF) == TRUE, ]$RAF <- 0.998
MemberMonth[MemberMonth$SavvyID == 1792429 & is.na(MemberMonth$RAF) == TRUE, ]$RAF <- 18.560



######### Clean up & some additional vars ###################

MemberYear <- MemberYear %>%
  mutate(AnyMedicalSpend = ifelse(MedSpend > 0, 1, 0), 
         AnyRVU = ifelse(RVUs > 0, 1, 0), 
         AnyRx = ifelse(RxSpendPM > 0, 1, 0),
         AnyClaim = ifelse(MedSpend > 0 | RVUs > 0, 1, 0),
         AnySpend = ifelse(SpendPM > 0, 1, 0),
         Age0 = ifelse(AgeAdj == 0, 1, 0))

MemberMonth <- MemberMonth %>%
  mutate(AnyMedicalSpend = ifelse(TotalMedicalSpend > 0, 1, 0), 
         AnyRVU = ifelse(DrRVU > 0, 1, 0), 
         AnyRx = ifelse(RxSpend > 0, 1, 0),
         AnyClaim = ifelse(TotalMedicalSpend > 0 | DrRVU > 0, 1, 0),
         Age0 = ifelse(AgeAdj == 0, 1, 0))

# Standardize AgeAdj, SES and RAF

MemberYear$StdAgeAdj <- (MemberYear$AgeAdj - mean(MemberYear$AgeAdj))/ sd(MemberYear$AgeAdj)
MemberYear$StdSES <- (MemberYear$SES - mean(MemberYear$SES, na.rm = T))/ sd(MemberYear$SES, na.rm = T)
MemberYear$StdRAF <- (MemberYear$RAF - mean(MemberYear$RAF, na.rm = T))/ sd(MemberYear$RAF, na.rm = T)

##### Save files #####

save(MemberMonth, file = "MemberMonth.rda")
save(MemberYear, file = "MemberYear.rda")

