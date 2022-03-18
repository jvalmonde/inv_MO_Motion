# setupMemberMonth.R
# December 12, 2017 (original date) through April 17, 2018 (current version)
# Steve Smela, Savvysherpa
# Based on code from Bernardo Marquez

# December 18, 2017:  Added line to take out duplicates from RAF data set
# March 1, 2018:  Deleted unused lines.
# March 5, 2018:  Added in death info for possible filtering.
# March 6, 2018:  Added flexible ODBC connection in calls to 'read' function.  Connection set in MLI Master.
# March 7, 2018:  Appended "_ORIGINAL" to table names to test code using old tables, except for the Member_Month tables.  
#     Changed method used to reshape the RAF data set from wide to long.
# March 15, 16, 2018:  Changed file names for new tables to reflect Seth's new naming convention.
# March 16, 2018:  Added FIPS code to list of needed fields from Demographics table.
# March 26, 2018:  Updated some of the table names away from "ORIGINAL", use new RAF tables.  Added code for Top 5 Percent 2017.
# April 17, 2018:  Took out " %>% dplyr::select(-PilotType)  " from line 184 so that Consolidate Results will work correctly. 
#                  Also did some clean-up of commented-out lines.

######################################################################
#  Reads in data from the appropriate table depending on the pilot,  #
#  exports it for further use.                                       #
######################################################################

# Code extracted from "run all tests" function in Bernard's code, 
# lines 1625 - 1774 of his Github file.

setupMemberMonth <- function(pilotType, rxRebate) {

  "
  Reads in data from the appropriate table depending on the pilot,  applies the specified
  Rx rebate amount, exports it for further use.

   Parameters:
              
      pilotType: the pilot from which the members will be taken.
                 The options are '2016', or '2017' and its subsets:  'Alternative', 'Lifetime Value', 'Lifetime Value Control', 
                    'New Age-ins', 'New Diabetics', and 'New Diabetics Control'.


      rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
                The options are '40%', 'Full', and 'None'.
                The default value is '40%'

  "
  
  # Read in base data
  
  if (pilotType == "2016")
    tableName <- "LTV_Member_Month_2016_Pilot"
  else 
    tableName <- "LTV_Member_Month_2017_Pilot"
  
  ltvMemberMonthsNeededFields <- c("SavvyHICN", "Lifetime_ID", "Year_Mo", "Total_MA_Amt", "Total_D_Amt", "Premium_C_Amt",
                                   "Premium_D_Amt", "Total_MA_Derived_IP_Cost", "Total_MA_Derived_OP_Cost", 
                                   "Total_MA_Derived_DR_Cost", "Total_MA_Derived_ER_Cost", "Total_MA_Derived_DME_Cost",
                                   "Total_D_Cost", "Total_Revenue", "Top5_Prcnt_2014", "Top5_Prcnt_2015", "Top5_Prcnt_2016", "Top5_Prcnt_2017")
  
  if (rxRebate == "40%")
    ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_40Percent", "Total_Cost_40Percent_Rebate",
                                     "Total_Value_40Percent_Rebate")
  else if (rxRebate == "Full")
    ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_Full", "Total_Cost_Full_Rebate",
                                     "Total_Value_Full_Rebate")
  else if (rxRebate == "None")
    ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Total_Cost_NoRebate", "Total_Value_NoRebate")
  
  ltvMemberMonthDataset <- read(ODBC_Connection, database2, "dbo", tableName, ltvMemberMonthsNeededFields, "all", F)
  
  if (rxRebate == "40%")
    ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                    Total_Revenue = Total_Revenue + Rx_Rebate_Amt_40Percent, 
                                    Total_Cost = Total_Cost_40Percent_Rebate + Rx_Rebate_Amt_40Percent) %>% 
    dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_40Percent, Total_Value = Total_Value_40Percent_Rebate)
  else if (rxRebate == "Full")
    ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                    Total_Revenue = Total_Revenue + Rx_Rebate_Amt_Full, 
                                    Total_Cost = Total_Cost_Full_Rebate + Rx_Rebate_Amt_Full) %>% 
    dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_Full, Total_Value = Total_Value_Full_Rebate)
  else if (rxRebate == "None")
    ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                    Total_Cost = Total_Cost_NoRebate) %>% 
    dplyr::rename(Total_Value = Total_Value_NoRebate)
  
  totalMMDataset <- dplyr::select(ltvMemberMonthDataset, Life_ID, Year) %>% mutate(Total_MM = 1)
  totalMMDataset <- aggregate(.~ Life_ID + Year, FUN = "sum", data = totalMMDataset)
  
  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, totalMMDataset, by = c("Life_ID", "Year"), all.x = T)
  
  ltvMemberMonthDataset <- dplyr::arrange(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Year_Mo)

  
    
  # Add in info from the New_Member_Information_2016_Pilot or New_Member_Information table.
  
  if (pilotType == "2016")
    tableName <- "New_Member_Information_2016_Pilot"
  else 
    tableName <- "New_Member_Information_2017_Pilot"
  
  newMemberInformationNeededFields <- c("SavvyHICN", "PartD_Flag", "Commercial_Flag")
  newMemberInformationDataset <- read(ODBC_Connection, database2, "dbo", tableName, newMemberInformationNeededFields, "all", F)
  newMemberInformationDataset <- filter(newMemberInformationDataset, PartD_Flag == 0, Commercial_Flag == 0) %>% 
    mutate(Member_Status = "New Member") %>% dplyr::select(SavvyHICN, Member_Status)
  
  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, newMemberInformationDataset, by = "SavvyHICN", all.x = T)
  

  
  # Add in info from the Members_2016_Pilot or GP1026_WnW_Member_Details table.
  
  if (pilotType == "2016") {
    
    member2016PilotNeededFields <- c("SavvyHICN", "Gender", "Age", "PBP", "Registered_Flag", "WithSteps_Flag")
    member2016PilotDataset <- read(ODBC_Connection, database2, "dbo", "Member_2016_Pilot", member2016PilotNeededFields, "all", F)
    memberNeededInfoDataset <- dplyr::rename(member2016PilotDataset, Gdr_Cd = Gender, ActivatedTrio_Flag = WithSteps_Flag) %>% 
      mutate(PilotType = "2016", Invite_Flag = 1) %>%
      dplyr::select(SavvyHICN, Gdr_Cd, Age, PBP, PilotType, Invite_Flag, Registered_Flag, 
                    ActivatedTrio_Flag)
    
    memberNeededInfoDataset[is.na(memberNeededInfoDataset$Registered_Flag), "Registered_Flag"] <- 0
  }
  else {
    
    memberDetailsNeededFields <- c("SavvyHicn", "Gdr_Cd", "Age", "PBP", "PilotType", "Invite_Flag", "Registered_Flag",
                                   "ActivatedTrio_Flag")
    memberDetailsDataset <- read(ODBC_Connection, database2, "dbo", "GP1026_WnW_Member_Details", memberDetailsNeededFields, "all", F)
    memberNeededInfoDataset <- dplyr::rename(memberDetailsDataset, SavvyHICN = SavvyHicn)
  }
  
  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, memberNeededInfoDataset, by = "SavvyHICN", all.y = T)
  

  
  # Add in info from the LTV_Member_Demographics_2016_Pilot or LTV_Member_Demographics table.
  
  if (pilotType == "2016")
    tableName <- "LTV_Member_Demographics_2016_Pilot"
  else 
    tableName <- "LTV_Member_Demographics_2017_Pilot"
  
  ltvMemberDemographicsNeededFields <- c("SavvyHICN", "ZIP", "St_Cd", "FIPS")
  ltvMemberDemographicsDataset <- read(ODBC_Connection, database2, "dbo", tableName, ltvMemberDemographicsNeededFields, "all", F)
  
  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, ltvMemberDemographicsDataset, by = "SavvyHICN", all.x = T)
  
  
  
  # Add RAF info from the RAF_2016_Pilot or RAF_2017_Pilot table.
  
  if (pilotType == "2016") {
    
    raf2016PilotNeededFields <- c("SavvyHICN", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016", "RAFMMR_2017")
    rafDataset <- read(ODBC_Connection, database2, "dbo", "RAF_2016_Pilot", raf2016PilotNeededFields, "all", F)
  }
  else {
    
    memberClaimsNeededFields <- c("SavvyHicn", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016", "RAFMMR_2017")
    memberClaimsDataset <- read(ODBC_Connection, database2, "dbo", "RAF_2017_Pilot", memberClaimsNeededFields, "all", F)
    rafDataset <- dplyr::rename(memberClaimsDataset, SavvyHICN = SavvyHicn)
  }
  
  # Take out possible duplicates in RAF dataset
  
  rafDataset <- rafDataset[!duplicated(rafDataset$SavvyHICN),]
  
  rafDataset <- rafDataset %>% gather(key = "Year", value = "RAFMMR", RAFMMR_2013:RAFMMR_2017)
  rafDataset$Year <- as.integer(substring(rafDataset$Year, 8, 11))

  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, rafDataset, by = c("SavvyHICN", "Year"), all.x = T)
  
  
  # Add info from the AreaDeprivationIndex_ZIPLevel table.
  
  areaDeprivationIndexDataset <- read(ODBC_Connection, database1, "dbo", "AreaDeprivationIndex_ZIPLevel", "*", "all", F)
  areaDeprivationIndexDataset <- mutate(areaDeprivationIndexDataset, ZIP = zip, ADI = DepIdx)
  
  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, areaDeprivationIndexDataset, by = "ZIP", all.x = T)
  
  ltvMemberMonthDataset[is.na(ltvMemberMonthDataset$Member_Status), "Member_Status"] <- "Old Member"
  
  # Filter according to pilot type
  
  if (pilotType != "2017")
    ltvMemberMonthDataset <- filter(ltvMemberMonthDataset, PilotType == pilotType)
  
  ltvMemberMonthDataset <- dplyr::arrange(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Year_Mo)
  
  # Through the mergings, some SavvyHICNs were introduced that were not in the original data sets.  It seems these came from the Members_2016_Pilot or 
  # GP1026_WnW_Member_Details table or the RAF tables.
  
  ltvMemberMonthDataset <- filter(ltvMemberMonthDataset, !is.na(Year))
  
  
  # Pull in death and disenrollment date from disenrollment table
  
  if (pilotType == "2016")
    tableName <- "LTV_Member_Disenrollment_2016_Pilot"
  else 
    tableName <- "LTV_Member_Disenrollment_2017_Pilot"
  
  ltvMemberDisenrollmentNeededFields <- c("SavvyHICN", "Disenroll_Year_Mo", "Lifetime_ID", "Death_Flag")
  ltvMemberDisenrollmentDataset <- read(ODBC_Connection, database2, "dbo", tableName, ltvMemberDisenrollmentNeededFields, "all", F)
  
  ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, ltvMemberDisenrollmentDataset, by = c("SavvyHICN", "Lifetime_ID"), all.x = T)
  
  
  return(ltvMemberMonthDataset)

}