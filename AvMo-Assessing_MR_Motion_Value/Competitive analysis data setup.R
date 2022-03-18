# Competitive analysis data setup

# April 2018

# Steve Smela, Savvysherpa

# Reads in data on market share of UHC Medicare vs. competitors by county in January 2016, 2017 and 2018.
# Data are in NGIS on DBSEP3832 server.


# March 26, 2018:  Added restriction to not include drug plans
# April 4, 2018:  Added query to get # of companies in county


library(RODBC)
library(tidyverse)

channel <- odbcConnect("pdbRally")

# Market share: UHC's % of Medicare Advantage population, by county

CompeteQuery <- paste0(" SELECT a.YearMo, a.CountyName, a.StateAbbr, a.FIPSCode, count(*) Plans, ",
                      " Org = case when b.ParentOrg like 'UnitedH%' then 'UHC' else 'Other' end, ",
                      " Enrollment = sum(Enrollment), EnrollmentShr = 1. * sum(Enrollment) / sum(sum(Enrollment)) ",
                      " over(partition by a.YearMo, a.countyname, a.stateabbr) ", 
                      " FROM pdb_WalkandWin.dbo.StateCountyContractPlanEnrollment_CMS a ",
                      " join pdb_WalkandWin.dbo.StateCountyContractPlanInfo_CMS b ", 
                      " on  a.ContractNbr =  b.ContractNbr ", 
                      " and a.PlanID      =  b.PlanID ",
                      " and a.YearMo      =  b.YearMo ",
                      " where Enrollment > 0 and a.YearMo in (201601, 201701, 201801) ",
                      " and b.OrgType <> 'Medicare Prescription Drug Plan' ",
                      " group by a.YearMo, a.CountyName, a.StateAbbr, a.FIPSCode, ", 
                      " case when b.ParentOrg like 'UnitedH%' then 'UHC' else 'Other' end ",
                      " order by StateAbbr, CountyName, YearMo, Org ")

CompeteData <- sqlQuery(channel, CompeteQuery)

ShareData <- CompeteData %>% 
  filter(Org == 'UHC') %>%
  mutate(Year = paste0("Y", as.character(round(YearMo / 100, 0))),
         EnrollmentShr = 100 * EnrollmentShr) %>%
  select(FIPSCode, Year, EnrollmentShr) %>%
  spread(key = Year, value = EnrollmentShr) %>%
  rename(FIPS = FIPSCode, Share2016 = Y2016, Share2017 = Y2017, Share2018 = Y2018)

  
UHC_EnrollmentData <- CompeteData %>% 
  filter(Org == 'UHC') %>%
  mutate(Year = paste0("Y", as.character(round(YearMo / 100, 0)))) %>%
  select(FIPSCode, Year, Enrollment) %>%
  spread(key = Year, value = Enrollment) %>%
  rename(FIPS = FIPSCode, Enrollment2016 = Y2016, Enrollment2017 = Y2017, Enrollment2018 = Y2018)

# Number of companies offering Medicare Advantage in county

CompeteQuery2 <- paste0( " SELECT a.YearMo, a.CountyName, a.StateAbbr, a.FIPSCode, count(distinct(b.ParentOrg)) as Companies ",
                       " FROM pdb_WalkandWin.dbo.StateCountyContractPlanEnrollment_CMS a ",
                       " join pdb_WalkandWin.dbo.StateCountyContractPlanInfo_CMS b  ",
                       " on  a.ContractNbr =  b.ContractNbr  ",
                       " and a.PlanID      =  b.PlanID ",
                       " and a.YearMo      =  b.YearMo ",
                       " where Enrollment > 0 and a.YearMo in (201601, 201701, 201801) ",
                       " and b.OrgType <> 'Medicare Prescription Drug Plan' ",
                       " group by a.YearMo, a.CountyName, a.StateAbbr, a.FIPSCode ",
                       " order by StateAbbr, CountyName, YearMo" )

CompeteData2 <- sqlQuery(channel, CompeteQuery2)

Companies <- CompeteData2 %>% 
  mutate(Year = paste0("Y", as.character(round(YearMo / 100, 0)))) %>%
  select(FIPSCode, Year, Companies) %>%
  spread(key = Year, value = Companies) %>%
  rename(FIPS = FIPSCode, Companies2016 = Y2016, Companies2017 = Y2017, Companies2018 = Y2018)

# Put datasets together, calculate annual change variables

CompetitiveData <- merge(ShareData, Companies, by = "FIPS", all.x = T)

CompetitiveData <- CompetitiveData %>% 
  mutate(Sh16_17 = Share2017 - Share2016,
         Sh17_18 = Share2018 - Share2017,
         Comp16_17 = Companies2017 - Companies2016,
         Comp17_18 = Companies2018 - Companies2017,
         Pct16_17 = 100 * Comp16_17 / Companies2016,
         Pct17_18 = 100 * Comp17_18 / Companies2017)

