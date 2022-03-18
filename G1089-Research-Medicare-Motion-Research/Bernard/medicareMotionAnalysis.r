
rm(list = ls(all = T))
library(dplyr)
library(RODBC)
library(RVAideMemoire)

database1 <- "LTV"
database2 <- "pdb_GP1026_WalkandWin_Research"

read <- function(server, database, schema, table, fields, total_rows, show_time = T) {
        "
        Reads a table in a SQL database and puts it in a dataframe.

        Parameters:
        
           server: the name of the server where the SQL database is located.
           database: the name of a SQL database.
           schema: the name of a schema in a SQL database.
           table: the name of a table in a SQL database.
           fields: the names of the columns to be retrieved.
                   if '*', then all columns will be retrieved.
           total_rows: if a positive integer, then that is the total number of rows to be retrieved.
                       if 'all', then all the rows will be retrieved.
           show_time: a boolean to indicate whether or not to display the time it took to read the table.
                      The default value is T.
        
        Output: a dataframe that holds the data contained in a table in a SQL database.

        Example:

           server = 'devsql10'
           database = database1
           schema = 'dbo'
           table = AreaDeprivationIndex_ZIPLevel
           fields = '*'
           total_rows = 'all'
          
           Run a = read(server, database, schema, table, fields, total_rows)
        "
        
        if (show_time)
            t1 <- Sys.time()
        
        channel <- odbcConnect(server)
        fields <- paste(fields, collapse = ", ")
        
        if (total_rows == "all")
            query <- paste0("SELECT ", fields, " FROM ", database, ".", schema, ".",table)
        else
            query <- paste0("SELECT TOP ", as.integer(total_rows), " ", fields, " FROM ", database, ".", schema, ".", table)
        
        output <- sqlQuery(channel, query)
        odbcClose(channel)
        
        if (show_time) {
          
            t2 <- Sys.time()
            
            cat("\n")
            print(t2 - t1)
            cat("\n")
        }
        
        return(output)
}

setupMLIDataset <- function(pilotType, Invited = NULL, Enrolled = NULL, Registered = NULL, Yr = NULL, memberStatus = NULL,
                            rxRebate = "40%") {
                   "
                   Sets up a dataframe that contains various MLI-related information for each captured year in the dataset of an 
                      identified group of Medicare members.
          
                    Parameters:
          
                      pilotType: the pilot from which the members will be taken from.
                                 The options are '2016', '2017', 'Alternative', 'Lifetime Value', 'Lifetime Value Control', 'New Age-ins',
                                     'New Diabetics', and 'New Diabetics Control'.
                      Invited: if '1', invited members are considered.
                               if '0', uninvited members are considered.
                               if 'NULL', all members are considered regardless of their invitation status.
                               The default value is 'NULL'.
                      Enrolled: if '1', enrolled members are considered.
                               if '0', unenrolled members are considered.
                               if 'NULL', all members are considered regardless of their enrollment status.
                               The default value is 'NULL'.
                      Registered: if '1', registered members are considered.
                                  if '0', unregistered members are considered.
                                  if 'NULL', all members are considered regardless of their registration status.
                                  The default value is 'NULL'.
                      Yr: the year to be considered in extracting the data.
                          The default value is 'NULL'.
                      memberStatus: the status of members to be considered.
                                    The options are 'Old Member' and 'New Member'.
                                    The default value is 'NULL'.
                      rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
                                The options are '40%', 'Full', and 'None'.
                                The default value is '40%'
          
                   Output: the required dataframe.
          
                   Example:
          
                       pilotType = 'Lifetime Value'
                       Invited = 1
                       Enrolled = 1
          
                       Run a = setupMLIDataset(pilotType, Invited, Enrolled)
                   "
             
                   # Read from the LTV_Member_Month_2016_Pilot or LTV_Member_Month table.
  
                   if (pilotType == "2016")
                        tableName <- "LTV_Member_Month_2016_Pilot"
                   else 
                        tableName <- "LTV_Member_Month"
  
                   ltvMemberMonthsNeededFields <- c("SavvyHICN", "Lifetime_ID", "Year_Mo", "Total_MA_Amt", "Total_D_Amt", "Premium_C_Amt",
                                                    "Premium_D_Amt", "Total_MA_Derived_IP_Cost", "Total_MA_Derived_OP_Cost", 
                                                    "Total_MA_Derived_DR_Cost", "Total_MA_Derived_ER_Cost", "Total_MA_Derived_DME_Cost",
                                                    "Total_D_Cost", "Total_Revenue")
                   
                   if (rxRebate == "40%")
                       ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_40Percent", "Total_Cost_40Percent_Rebate",
                                                        "Total_Value_40Percent_Rebate")
                   else if (rxRebate == "Full")
                            ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_Full", "Total_Cost_Full_Rebate",
                                                             "Total_Value_Full_Rebate")
                   else if (rxRebate == "None")
                            ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Total_Cost_NoRebate", "Total_Value_NoRebate")

                   ltvMemberMonthDataset <- read("devsql14", database2, "res", tableName, ltvMemberMonthsNeededFields, "all", F)
                   
                   if (rxRebate == "40%")
                       ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                       Total_Revenue = Total_Revenue + Rx_Rebate_Amt_40Percent, 
                                                       Total_Cost = Total_Cost_40Percent_Rebate + Rx_Rebate_Amt_40Percent, Total_MM = 1) %>% 
                                                dplyr::select(SavvyHICN, Year, Lifetime_ID, Life_ID, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                              Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                              Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost,
                                                              Rx_Rebate_Amt_40Percent, Total_Revenue, Total_Cost, Total_Value_40Percent_Rebate, Total_MM) %>%
                                                dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_40Percent, Total_Value = Total_Value_40Percent_Rebate)
                   else if (rxRebate == "Full")
                            ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                            Total_Revenue = Total_Revenue + Rx_Rebate_Amt_Full, 
                                                            Total_Cost = Total_Cost_Full_Rebate + Rx_Rebate_Amt_Full, Total_MM = 1) %>% 
                            dplyr::select(SavvyHICN, Year, Lifetime_ID, Life_ID, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                          Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                          Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost,
                                          Rx_Rebate_Amt_Full, Total_Revenue, Total_Cost, Total_Value_Full_Rebate, Total_MM) %>%
                            dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_Full, Total_Value = Total_Value_Full_Rebate)
                   else if (rxRebate == "None")
                            ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                            Total_Cost = Total_Cost_NoRebate, Total_MM = 1) %>% 
                            dplyr::select(SavvyHICN, Year, Lifetime_ID, Life_ID, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                          Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                          Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost, Total_Revenue, Total_Cost, 
                                          Total_Value_NoRebate, Total_MM) %>%
                            dplyr::rename(Total_Value = Total_Value_NoRebate)

                   ltvMemberYearDataset <- aggregate(.~ SavvyHICN + Year + Lifetime_ID + Life_ID, FUN = "sum", data = ltvMemberMonthDataset)
                   ltvMemberYearDataset <- dplyr::arrange(ltvMemberYearDataset, SavvyHICN, Year, Lifetime_ID)
                   
                   savvyHicnDataset <- data.frame(SavvyHICN = sort(unique(ltvMemberYearDataset$SavvyHICN)))
                   YearDataset <- data.frame(Year = sort(unique(ltvMemberYearDataset$Year)))
                   savvyHicnYearDataset <- merge(savvyHicnDataset, YearDataset, by = NULL)
                   savvyHicnYearDataset <- dplyr::arrange(savvyHicnYearDataset, SavvyHICN, Year)
                   
                   ltvMemberYearDataset <- merge(savvyHicnYearDataset, ltvMemberYearDataset, by = c("SavvyHICN", "Year"), all.x = T)
                   
                   # Read from the RAF_2016_Pilot or GP1026_WnW_Member_Claims table.
                   
                   if (pilotType == "2016") {
                     
                     raf2016PilotNeededFields <- c("SavvyHICN", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016")
                     raf2016PilotDataset <- read("devsql14", database2, "res", "RAF_2016_Pilot", raf2016PilotNeededFields, "all", F)
                     rafDataset <- dplyr::rename(raf2016PilotDataset, "2013" = RAFMMR_2013, "2014" = RAFMMR_2014, "2015" = RAFMMR_2015, 
                                                 "2016" = RAFMMR_2016)
                   }
                   else {

                       memberClaimsNeededFields <- c("SavvyHicn", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016")
                       memberClaimsDataset <- read("devsql14", database2, "final", "GP1026_WnW_Member_Claims", memberClaimsNeededFields, "all", F)
                       rafDataset <- dplyr::rename(memberClaimsDataset, SavvyHICN = SavvyHicn, "2013" = RAFMMR_2013, "2014" = RAFMMR_2014,
                                                   "2015" = RAFMMR_2015, "2016" = RAFMMR_2016)
                   }

                   rafDataset <- melt(rafDataset, id = c("SavvyHICN"))
                   rafDataset <- dplyr::rename(rafDataset, Year = variable, RAFMMR = value) %>% arrange(SavvyHICN, Year)
                   
                   ltvMemberYearDataset <- merge(ltvMemberYearDataset, rafDataset, by = c("SavvyHICN", "Year"), all.x = T)

                   # Read from the LTV_Member_Lifetime_2016_Pilot or LTV_Member_Lifetime table.
                   
                   if (pilotType == "2016")
                       tableName <- "LTV_Member_Lifetime_2016_Pilot"
                   else 
                       tableName <- "LTV_Member_Lifetime"
                   
                   ltvMemberLifetimeNeededFields <- c("SavvyHICN", "Lifetime_ID", "Lifetime_Type", "Enroll_Year_Mo", "Enroll_Flag")
                   ltvMemberLifetimeDataset <- read("devsql14", database2, "res", tableName, ltvMemberLifetimeNeededFields, "all", F)
                   
                   lifetimeTypeDataset <- dplyr::select(ltvMemberLifetimeDataset, SavvyHICN, Lifetime_ID, Lifetime_Type)
                   
                   MAEnrollYearDataset <- dplyr::select(ltvMemberLifetimeDataset, SavvyHICN, Enroll_Year_Mo, Enroll_Flag) %>% 
                                          filter(Enroll_Flag == 1) %>% mutate(Enroll_Year = substr(Enroll_Year_Mo, 1, 4)) %>% 
                                          dplyr::select(SavvyHICN, Enroll_Year, Enroll_Flag) %>% 
                                          dplyr::rename(Year = Enroll_Year, MA_Enroll_Flag = Enroll_Flag)
                   
                   ltvMemberYearDataset <- merge(ltvMemberYearDataset, MAEnrollYearDataset, by = c("SavvyHICN", "Year"), all.x = T)
                   ltvMemberYearDataset <- merge(ltvMemberYearDataset, lifetimeTypeDataset, by = c("SavvyHICN", "Lifetime_ID"), 
                                                 all.x = T)

                   ltvMemberYearDataset[!is.na(ltvMemberYearDataset$Lifetime_ID) & is.na(ltvMemberYearDataset$MA_Enroll_Flag), "MA_Enroll_Flag"] <- 0
                   
                   # Read from the New_Member_Information_2016_Pilot or New_Member_Information table.
                   
                   if (pilotType == "2016")
                       tableName <- "New_Member_Information_2016_Pilot"
                   else 
                       tableName <- "New_Member_Information"
                   
                   newMemberInformationNeededFields <- c("SavvyHICN", "PartD_Flag", "Commercial_Flag")
                   newMemberInformationDataset <- read("devsql14", database2, "res", tableName, newMemberInformationNeededFields, "all", F)
                   newMemberInformationDataset <- filter(newMemberInformationDataset, PartD_Flag == 0, Commercial_Flag == 0) %>% 
                                                  mutate(Member_Status = "New Member") %>% dplyr::select(SavvyHICN, Member_Status)
                   
                   ltvMemberYearDataset <- merge(ltvMemberYearDataset, newMemberInformationDataset, by = "SavvyHICN", all.x = T)

                   # Read from the Members_2016_Pilot or GP1026_WnW_Member_Details table.
                   
                   if (pilotType == "2016") {
                     
                       member2016PilotNeededFields <- c("SavvyHICN", "Gender", "Age", "PBP", "Registered_Flag", "WithSteps_Flag")
                       member2016PilotDataset <- read("devsql14", database2, "res", "Member_2016_Pilot", member2016PilotNeededFields, "all", F)
                       memberNeededInfoDataset <- dplyr::rename(member2016PilotDataset, Gdr_Cd = Gender, ActivatedTrio_Flag = WithSteps_Flag) %>% 
                                                  mutate(PilotType = "2016", Invite_Flag = 1) %>%
                                                  dplyr::select(SavvyHICN, Gdr_Cd, Age, PBP, PilotType, Invite_Flag, Registered_Flag, 
                                                                ActivatedTrio_Flag)
                       
                       memberNeededInfoDataset[is.na(memberNeededInfoDataset$Registered_Flag), "Registered_Flag"] <- 0
                   }
                   else {
                     
                       memberDetailsNeededFields <- c("SavvyHicn", "Gdr_Cd", "Age", "PBP", "PilotType", "Invite_Flag", "Registered_Flag",
                                                      "ActivatedTrio_Flag")
                       memberDetailsDataset <- read("devsql14", database2, "final", "GP1026_WnW_Member_Details", memberDetailsNeededFields, "all", F)
                       memberNeededInfoDataset <- dplyr::rename(memberDetailsDataset, SavvyHICN = SavvyHicn)
                   }

                   # Read from the LTV_Member_Demographics_2016_Pilot or LTV_Member_Demographics table.

                   if (pilotType == "2016")
                       tableName <- "LTV_Member_Demographics_2016_Pilot"
                   else 
                       tableName <- "LTV_Member_Demographics"
                   
                   ltvMemberDemographicsNeededFields <- c("SavvyHICN", "ZIP", "St_Cd")
                   ltvMemberDemographicsDataset <- read("devsql14", database2, "res", tableName, ltvMemberDemographicsNeededFields, "all", F)
                   
                   memberNeededInfoDataset <- merge(memberNeededInfoDataset, ltvMemberDemographicsDataset, by = "SavvyHICN", all.x = T)
                   
                   # Read from the AreaDeprivationIndex_ZIPLevel table.
                   
                   areaDeprivationIndexDataset <- read("devsql10", database1, "dbo", "AreaDeprivationIndex_ZIPLevel", "*", "all", F)
                   areaDeprivationIndexDataset <- mutate(areaDeprivationIndexDataset, ZIP = zip, ADI = DepIdx)
                   
                   memberNeededInfoDataset <- merge(memberNeededInfoDataset, areaDeprivationIndexDataset, by = "ZIP", all.x = T)

                   memberNeededInfoDataset <- dplyr::select(memberNeededInfoDataset, SavvyHICN, Gdr_Cd, Age, ZIP, ADI, St_Cd, PBP, PilotType, Invite_Flag, 
                                                            Registered_Flag, ActivatedTrio_Flag)

                   ltvMemberYearDataset <- merge(ltvMemberYearDataset, memberNeededInfoDataset, by = "SavvyHICN", all.y = T)
                   
                   ltvMemberYearDataset[is.na(ltvMemberYearDataset$Member_Status), "Member_Status"] <- "Old Member"
                   ltvMemberYearDataset <- dplyr::arrange(ltvMemberYearDataset, SavvyHICN, Year, Lifetime_ID)
                   
                   if (pilotType != "2017")
                       ltvMemberYearDataset <- filter(ltvMemberYearDataset, PilotType == pilotType)

                   if (!is.null(Invited))
                       ltvMemberYearDataset <- filter(ltvMemberYearDataset, Invite_Flag == Invited)
                   
                   if (!is.null(Enrolled))
                       ltvMemberYearDataset <- filter(ltvMemberYearDataset, Registered_Flag == Enrolled)
                   
                   if (!is.null(Registered))
                       ltvMemberYearDataset <- filter(ltvMemberYearDataset, ActivatedTrio_Flag == Registered)
                   
                   if (!is.null(Yr))
                       ltvMemberYearDataset <- filter(ltvMemberYearDataset, Year == Yr)
                   
                   if (!is.null(memberStatus))
                       ltvMemberYearDataset <- filter(ltvMemberYearDataset, Member_Status == memberStatus)
                   
                   return(ltvMemberYearDataset)
}

summarizeMedicareMotion <- function(pilotType = "Lifetime Value", Yr = "All", totalMM = NULL, rxRebate = "40%", removeOutliers = T) {
                           "
                           Determine relevant counts and measures for different groups of Medicare members pertaining to the LTV Pilot.
                              These groups of members are: members who were reached, members who were not reeached, members who enrolled, 
                              members who did not enroll, members who registered, and members who did not register.

                           Parameters:

                              pilotType: the pilot from which the members will be taken from.
                                         The options are '2016', '2017', 'Alternative', 'Lifetime Value', 'Lifetime Value Control', 'New Age-ins',
                                            'New Diabetics', and 'New Diabetics Control'.
                                         The default value is 'Lifetime Value'.
                              Yr: the year to be considered in extracting the data.
                                  If 'All', then all years from 2006 to 2017 will be considered.
                                  The default value is 'All'.
                              totalMM: the number of months of enrollment in one year to be required of members.
                                       The default value is NULL.
                              rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
                                        The options are '40%', 'Full', and 'None'.
                                        The default value is '40%'
                              removeOutliers: a boolean to indicate whether or not to remove outliers from the calculations.
                                              The default value is T.

                           Output: a dataframe consisting of the counts and measures for the different groups.

                           Example:

                              Run a = summarizeMedicareMotion()
                           "
  
                           cat("\n")
                           cat("Setting up the MLI dataset ...")
                           cat("\n")
                              
                           MLIDataset <- setupMLIDataset(pilotType = pilotType, rxRebate = rxRebate)
                           
                           rowLabels <- as.character()
                           percentLowerRowLabels <- as.character()
                           
                           columns <- list()
                           columns[["Total Population"]] <- as.numeric()
                           
                           if (pilotType != "2016") {
                           
                               columns[["Reached"]] <- as.numeric()
                               columns[["Not Reached"]] <- as.numeric()
                           }
                           
                           columns[["Enrolled"]] <- as.numeric()
                           columns[["Not Enrolled"]] <- as.numeric()
                           columns[["Registered"]] <- as.numeric()
                           columns[["Not Registered"]] <- as.numeric()

                           allGroups <- names(columns)
                           
                           for (group in allGroups) {
                             
                                cat("\n")
                                cat("Summarizing results for", group, "...")
                                cat("\n")
                                
                                if (group == "Total Population")
                                    filteredMLIDataset <- MLIDataset
                                else if (group == "Reached")
                                    filteredMLIDataset <- filter(MLIDataset, Invite_Flag == 1)
                                else if (group == "Not Reached")
                                         filteredMLIDataset <- filter(MLIDataset, Invite_Flag == 0)
                                else if (group == "Enrolled")
                                         filteredMLIDataset <- filter(MLIDataset, Invite_Flag == 1, Registered_Flag == 1)
                                else if (group == "Not Enrolled")
                                         filteredMLIDataset <- filter(MLIDataset, Invite_Flag == 1, Registered_Flag == 0)
                                else if (group == "Registered")
                                         filteredMLIDataset <- filter(MLIDataset, Invite_Flag == 1, Registered_Flag == 1, ActivatedTrio_Flag == 1)
                                else if (group == "Not Registered")
                                         filteredMLIDataset <- filter(MLIDataset, Invite_Flag == 1, Registered_Flag == 1, ActivatedTrio_Flag == 0)

                                if (Yr != "All") {
                                    
                                    originalFilteredMLIDataset <- filteredMLIDataset
                                  
                                    Yr <- as.character(Yr)
                                    filteredMLIDataset <- filter(filteredMLIDataset, Year == Yr, is.na(Lifetime_ID) == F)
                                    yrSavvyHICNs <- unique(filteredMLIDataset$SavvyHICN)
                                    
                                    if (pilotType == "2016")
                                        tableName <- "LTV_Member_Month_2016_Pilot"
                                    else
                                        tableName <- "LTV_Member_Month"
                                      
                                    if (removeOutliers) {
                                
                                        columnName <- paste0("Top5_Prcnt_", Yr)
                                        outlierFlagNeededFields <- c("SavvyHICN", "Year_Mo", columnName)
                                        outlierFlagDataset <- read("devsql14", database2, "res", tableName, outlierFlagNeededFields, "all", F)
                                        outlierFlagDataset <- mutate(outlierFlagDataset, Year = substr(Year_Mo, 1, 4))
                                        outlierFlagDataset <- aggregate(.~ SavvyHICN + Year, FUN = "sum", data = outlierFlagDataset)
                                        
                                        filteredMLIDataset <- merge(filteredMLIDataset, outlierFlagDataset, by = c("SavvyHICN", "Year"), all.x = T)
                                    }
                                    
                                    tenureDataset <- filter(originalFilteredMLIDataset, SavvyHICN %in% yrSavvyHICNs)
                                }
                                
                                if (!is.null(totalMM)) {
                                  
                                    originalFilteredMLIDataset <- filteredMLIDataset
                                  
                                    filteredMLIDataset <- filter(filteredMLIDataset, Total_MM == totalMM)
                                    totalMMSavvyHICNs <- unique(filteredMLIDataset$SavvyHICN)
                                    
                                    if (Yr == "All")
                                        tenureDataset <- filter(originalFilteredMLIDataset, SavvyHICN %in% totalMMSavvyHICNs)
                                    else
                                        tenureDataset <- filter(tenureDataset, SavvyHICN %in% totalMMSavvyHICNs)
                                }

                                columns[[group]] <- as.numeric()
                                
                                # Determine the number of members
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Number of Members")
                                
                                allMembers <- unique(filteredMLIDataset$SavvyHICN)
                                countOfAllMembers <- length(allMembers)
                                columns[[group]] <- c(columns[[group]], countOfAllMembers)
                                
                                # Determine the number of unique Life IDs.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Number of Lifetimes")
                                
                                uniqueLifeIds <- unique(filteredMLIDataset$Life_ID)
                                uniqueLifeIds <- uniqueLifeIds[!is.na(uniqueLifeIds)]
                                countOfUniqueLifeIds <- length(uniqueLifeIds)
                                columns[[group]] <- c(columns[[group]], countOfUniqueLifeIds)
                                
                                if (Yr != "All") {
                                      
                                    if (removeOutliers) {
                               
                                        # Determine the number of outlier members.
                                  
                                        if (group == allGroups[1])
                                            rowLabels <- c(rowLabels, "Number of Outlier Members")
                                      
                                        outlierMembers <- unique(filteredMLIDataset[filteredMLIDataset[, columnName] > 0, "SavvyHICN"])
                                        countOfOutlierMembers <- length(outlierMembers)
                                        
                                        columns[[group]] <- c(columns[[group]], countOfOutlierMembers)
                                        
                                        filteredMembers <- setdiff(allMembers, outlierMembers) 
                                        filteredMLIDataset <- filter(filteredMLIDataset, SavvyHICN %in% filteredMembers)
                                      
                                        # Determine the number of filtered members.
                                        
                                        if (group == allGroups[1]) {
                                          
                                            rowLabels <- c(rowLabels, "Number of Filtered Members")
                                            allFilteredMembers <- filteredMembers
                                        }
    
                                        countOfFilteredMembers <- length(filteredMembers)
                                        
                                        columns[[group]] <- c(columns[[group]], countOfFilteredMembers)
                                    }
                                    else {
                                      
                                        if (group == allGroups[1])
                                            allFilteredMembers <- allMembers
                                    }
                                }
                                
                                # Determine the aggregate total revenue.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate Total Revenue")
                                
                                aggregateTotalRevenue <- round(sum(filteredMLIDataset$Total_Revenue, na.rm = T), 2)
                                columns[[group]] <- c(columns[[group]], aggregateTotalRevenue)
                                
                                # Determine the aggregate total cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate Total Cost")
                                
                                aggregateTotalCost <- round(sum(filteredMLIDataset$Total_Cost, na.rm = T), 2)
                                columns[[group]] <- c(columns[[group]], aggregateTotalCost)
                                
                                # Determine the aggregate MLI value.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate MLI Value")
                                
                                aggregateMLIValue <- round(sum(filteredMLIDataset$Total_Value, na.rm = T), 2)
                                columns[[group]] <- c(columns[[group]], aggregateMLIValue)
                                
                                # Determine the aggregate total member months.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate Total Member Months")
                                
                                aggregateTotalMM <- sum(filteredMLIDataset$Total_MM, na.rm = T)
                                columns[[group]] <- c(columns[[group]], aggregateTotalMM)
                                
                                # Determine the aggregate PMPM MLI.
                                
                                if (group == allGroups[1]) {
                                  
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MLI")
                                    percentLowerRowLabels <- c(percentLowerRowLabels, "Aggregate PMPM MLI")
                                }
                                
                                aggregatePMPMMLI <- round(aggregateMLIValue/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMLI)
                                
                                # Determine the aggregate PMPM MA amount.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MA Amount")
                                
                                aggregateTotalMAAmount <- sum(filteredMLIDataset$Total_MA_Amt, na.rm = T)
                                aggregatePMPMMAAmount <- round(aggregateTotalMAAmount/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMAAmount)
                                
                                # Determine the aggregate PMPM D amount.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM D Amount")
                                
                                aggregateTotalDAmount <- sum(filteredMLIDataset$Total_D_Amt, na.rm = T)
                                aggregatePMPMDAmount <- round(aggregateTotalDAmount/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMDAmount)
                                
                                # Determine the aggregate PMPM Premium C amount.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM Premium C Amount")
                                
                                aggregatePremiumCAmount <- sum(filteredMLIDataset$Premium_C_Amt, na.rm = T)
                                aggregatePMPMPremiumCAmount <- round(aggregatePremiumCAmount/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMPremiumCAmount)
                                
                                # Determine the aggregate PMPM Premium D amount.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM Premium D Amount")
                                
                                aggregatePremiumDAmount <- sum(filteredMLIDataset$Premium_D_Amt, na.rm = T)
                                aggregatePMPMPremiumDAmount <- round(aggregatePremiumDAmount/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMPremiumDAmount)
                                
                                if (rxRebate != "None") {

                                    # Determine the aggregate PMPM Rx rebate amount.
                                    
                                    if (group == allGroups[1])
                                        rowLabels <- c(rowLabels, "Aggregate PMPM Rx Rebate Amount")
                                    
                                    aggregateRxRebateAmount <- sum(filteredMLIDataset$Rx_Rebate_Amt, na.rm = T)
                                    aggregatePMPMRxRebateAmount <- round(aggregateRxRebateAmount/aggregateTotalMM, 2)
                                    columns[[group]] <- c(columns[[group]], aggregatePMPMRxRebateAmount)
                                }
                                
                                # Determine the aggregate PMPM total revenue.
                                
                                if (group == allGroups[1]) {
                                  
                                    rowLabels <- c(rowLabels, "Aggregate PMPM Total Revenue")
                                    percentLowerRowLabels <- c(percentLowerRowLabels, "Aggregate PMPM Total Revenue")
                                }
                                
                                aggregateTotalRevenue <- sum(filteredMLIDataset$Total_Revenue, na.rm = T)
                                aggregatePMPMTotalRevenue <- round(aggregateTotalRevenue/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMTotalRevenue)

                                # Determine the aggregate PMPM MA Derived IP cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived IP Cost")
                                
                                aggregateTotalMADerivedIPCost <- sum(filteredMLIDataset$Total_MA_Derived_IP_Cost, na.rm = T)
                                aggregatePMPMMADerivedIPCost <- round(aggregateTotalMADerivedIPCost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMADerivedIPCost)
                                
                                # Determine the aggregate PMPM MA Derived OP cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived OP Cost")
                                
                                aggregateTotalMADerivedOPCost <- sum(filteredMLIDataset$Total_MA_Derived_OP_Cost, na.rm = T)
                                aggregatePMPMMADerivedOPCost <- round(aggregateTotalMADerivedOPCost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMADerivedOPCost)
                                
                                # Determine the aggregate PMPM MA Derived DR cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived DR Cost")
                                
                                aggregateTotalMADerivedDRCost <- sum(filteredMLIDataset$Total_MA_Derived_DR_Cost, na.rm = T)
                                aggregatePMPMMADerivedDRCost <- round(aggregateTotalMADerivedDRCost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMADerivedDRCost)
                                
                                # Determine the aggregate PMPM MA Derived ER cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived ER Cost")
                                
                                aggregateTotalMADerivedERCost <- sum(filteredMLIDataset$Total_MA_Derived_ER_Cost, na.rm = T)
                                aggregatePMPMMADerivedERCost <- round(aggregateTotalMADerivedERCost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMADerivedERCost)
                                
                                # Determine the aggregate PMPM MA Derived DME cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived DME Cost")
                                
                                aggregateTotalMADerivedDMECost <- sum(filteredMLIDataset$Total_MA_Derived_DME_Cost, na.rm = T)
                                aggregatePMPMMADerivedDMECost <- round(aggregateTotalMADerivedDMECost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMMADerivedDMECost)

                                # Determine the aggregate PMPM MA D cost.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate PMPM D Cost")
                                
                                aggregateTotalDCost <- sum(filteredMLIDataset$Total_D_Cost, na.rm = T)
                                aggregatePMPMDCost <- round(aggregateTotalDCost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMDCost)
                                
                                # Determine the aggregate PMPM total cost.
                                
                                if (group == allGroups[1]) {
                                  
                                  rowLabels <- c(rowLabels, "Aggregate PMPM Total Cost")
                                  percentLowerRowLabels <- c(percentLowerRowLabels, "Aggregate PMPM Total Cost")
                                }
                                
                                aggregateTotalCost <- sum(filteredMLIDataset$Total_Cost, na.rm = T)
                                aggregatePMPMTotalCost <- round(aggregateTotalCost/aggregateTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregatePMPMTotalCost)

                                if (Yr != "All") {
                                  
                                    # Determine the median number of months enrolled in the specified year.
                                  
                                    yrMonthsEnrolledDataset <- dplyr::select(filteredMLIDataset, Life_ID, Total_MM) %>% 
                                                               filter(is.na(Life_ID) == F)
                                
                                    yrMonthsEnrolledDataset <- aggregate(.~ Life_ID, FUN = "sum", data = yrMonthsEnrolledDataset)
                                    summaryOutput <- summary(yrMonthsEnrolledDataset$Total_MM)
                                    
                                    if (group == allGroups[1]) {
                                      
                                      rowLabels <- c(rowLabels, "Median Number of Months")
                                      percentLowerRowLabels <- c(percentLowerRowLabels, "Median Number of Months")
                                    }
                                    
                                    medianNumberOfMonths <- round(summaryOutput["Median"], 2)
                                    columns[[group]] <- c(columns[[group]], medianNumberOfMonths)
                                
                                    # Determine the mean number of months enrolled in the specified year.
                                    
                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Mean Number of Months")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Mean Number of Months")
                                    }
                                    
                                    meanNumberOfMonths <- round(summaryOutput["Mean"], 2)
                                    columns[[group]] <- c(columns[[group]], meanNumberOfMonths)
                                }

                                # Determine the median tenure.
                                
                                if (Yr == "All" & is.null(totalMM))
                                    tenureDataset <- dplyr::select(filteredMLIDataset, Life_ID, Total_MM) %>% filter(is.na(Life_ID) == F)
                                else
                                    tenureDataset <- dplyr::select(tenureDataset, Life_ID, Total_MM) %>% filter(is.na(Life_ID) == F)

                                tenureDataset <- aggregate(.~ Life_ID, FUN = "sum", data = tenureDataset)
                                summaryOutput <- summary(tenureDataset$Total_MM)
                                
                                if (group == allGroups[1]) {
                                  
                                    rowLabels <- c(rowLabels, "Median Tenure (in months)")
                                    percentLowerRowLabels <- c(percentLowerRowLabels, "Median Tenure (in months)")
                                }
                                
                                medianTenure <- round(summaryOutput["Median"], 2)
                                columns[[group]] <- c(columns[[group]], medianTenure)
                                
                                # Determine the mean tenure.
                                
                                if (group == allGroups[1]) {
                                  
                                    rowLabels <- c(rowLabels, "Mean Tenure (in months)")
                                    percentLowerRowLabels <- c(percentLowerRowLabels, "Mean Tenure (in months)")
                                }
                                
                                meanTenure <- round(summaryOutput["Mean"], 2)
                                columns[[group]] <- c(columns[[group]], meanTenure)
                                
                                # Determine the proportion of males.
                                
                                genderDataset <- dplyr::select(filteredMLIDataset, SavvyHICN, Gdr_Cd)
                                genderDataset <- genderDataset[!duplicated(genderDataset), ]
                                genderDistribution <- prop.table(table(genderDataset$Gdr_Cd))
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Proportion of Males")
                                
                                proportionMales <- round(genderDistribution['M'], 2)
                                columns[[group]] <- c(columns[[group]], proportionMales)
                                
                                # Determine the aggregate MLI value of males.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate MLI Value of Males")
                                
                                maleFilteredMLIDataset <- filter(filteredMLIDataset, Gdr_Cd == "M")
                                
                                aggregateMaleMLIValue <- round(sum(maleFilteredMLIDataset$Total_Value, na.rm = T), 2)
                                columns[[group]] <- c(columns[[group]], aggregateMaleMLIValue)
                                
                                # Determine the aggregate total member months of males.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate Total Member Months of Males")
                                
                                aggregateMaleTotalMM <- sum(maleFilteredMLIDataset$Total_MM, na.rm = T)
                                columns[[group]] <- c(columns[[group]], aggregateMaleTotalMM)
                                
                                # Determine the aggregate PMPM MLI of males.
                                
                                if (group == allGroups[1]) {
                                  
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MLI of Males")
                                    percentLowerRowLabels <- c(percentLowerRowLabels, "Aggregate PMPM MLI of Males")
                                }
                                
                                aggregateMalePMPMMLI <- round(aggregateMaleMLIValue/aggregateMaleTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregateMalePMPMMLI)
                                
                                # Determine the proportion of females.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Proportion of Females")
                                
                                proportionFemales <- round(genderDistribution['F'], 2)
                                columns[[group]] <- c(columns[[group]], proportionFemales)
                                
                                # Determine the aggregate MLI value of females.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate MLI Value of Females")
                                
                                femaleFilteredMLIDataset <- filter(filteredMLIDataset, Gdr_Cd == "F")
                                
                                aggregateFemaleMLIValue <- round(sum(femaleFilteredMLIDataset$Total_Value, na.rm = T), 2)
                                columns[[group]] <- c(columns[[group]], aggregateFemaleMLIValue)
                                
                                # Determine the aggregate total member months of females.
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Aggregate Total Member Months of Females")

                                aggregateFemaleTotalMM <- sum(femaleFilteredMLIDataset$Total_MM, na.rm = T)
                                columns[[group]] <- c(columns[[group]], aggregateFemaleTotalMM)
                                
                                # Determine the aggregate PMPM MLI of females.
                                
                                if (group == allGroups[1]) {
                                  
                                    rowLabels <- c(rowLabels, "Aggregate PMPM MLI of Females")
                                    percentLowerRowLabels <- c(percentLowerRowLabels, "Aggregate PMPM MLI of Females")
                                }
                                
                                aggregateFemalePMPMMLI <- round(aggregateFemaleMLIValue/aggregateFemaleTotalMM, 2)
                                columns[[group]] <- c(columns[[group]], aggregateFemalePMPMMLI)

                                # Determine the median age.
                                
                                ageDataset <- dplyr::select(filteredMLIDataset, SavvyHICN, Age)
                                ageDataset <- ageDataset[!duplicated(ageDataset), ]
                                summaryOutput <- summary(ageDataset$Age)
                                
                                if (group == allGroups[1]) {
                                  
                                  rowLabels <- c(rowLabels, "Median Age")
                                  percentLowerRowLabels <- c(percentLowerRowLabels, "Median Age")
                                }
                                
                                medianAge <- round(summaryOutput["Median"], 2)
                                columns[[group]] <- c(columns[[group]], medianAge)
                                
                                # Determine the mean age.
                                
                                if (group == allGroups[1]) {
                                  
                                  rowLabels <- c(rowLabels, "Mean Age")
                                  percentLowerRowLabels <- c(percentLowerRowLabels, "Mean Age")
                                }
                                
                                meanAge <- round(summaryOutput["Mean"], 2)
                                columns[[group]] <- c(columns[[group]], meanAge)
                                
                                if (pilotType != "2016") {
                                
                                    # Determine the proportion of members from AZ.
                                    
                                    stateDataset <- dplyr::select(filteredMLIDataset, SavvyHICN, St_Cd)
                                    stateDataset <- stateDataset[!duplicated(stateDataset), ]
                                    stateDataset <- mutate(stateDataset, State = ifelse(St_Cd == "AZ", "AZ", "non-AZ"))
                                    stateDistribution <- prop.table(table(stateDataset$State))
                                    
                                    if (group == allGroups[1])
                                      rowLabels <- c(rowLabels, "Proportion of AZ")
                                    
                                    proportionAZ <- round(stateDistribution["AZ"], 2)
                                    columns[[group]] <- c(columns[[group]], proportionAZ)
                                    
                                    # Determine the proportion of members from a state other than AZ.
                                    
                                    if (group == allGroups[1])
                                      rowLabels <- c(rowLabels, "Proportion of non-AZ")
                                    
                                    proportionNonAZ <- round(stateDistribution["non-AZ"], 2)
                                    columns[[group]] <- c(columns[[group]], proportionNonAZ)

                                    # Determine the proportion of members with PBP 036.
                                    
                                    PBPDataset <- dplyr::select(filteredMLIDataset, SavvyHICN, PBP)
                                    PBPDataset <- PBPDataset[!duplicated(PBPDataset), ]
                                    PBPDataset <- mutate(PBPDataset, PBP = ifelse(PBP < 10, paste0("00", PBP), 
                                                                                  ifelse(PBP >= 10 & PBP < 100, paste0("0", PBP), PBP))) %>%
                                                  mutate(PBP = ifelse(PBP == "036", "036", "non-036"))
                                    PBPDistribution <- prop.table(table(PBPDataset$PBP))
                                    
                                    if (group == allGroups[1])
                                      rowLabels <- c(rowLabels, "Proportion of 036")
                                    
                                    proportion036 <- round(PBPDistribution["036"], 2)
                                    columns[[group]] <- c(columns[[group]], proportion036)
                                    
                                    # Determine the proportion of members with PBP other than 036.
                                    
                                    if (group == allGroups[1])
                                      rowLabels <- c(rowLabels, "Proportion of non-036")
                                    
                                    proportionNon036 <- round(PBPDistribution["non-036"], 2)
                                    columns[[group]] <- c(columns[[group]], proportionNon036)
                                }
                                
                                # Determine the mean ADI.
                                
                                ADIDataset <- dplyr::select(filteredMLIDataset, SavvyHICN, ADI)
                                ADIDataset <- ADIDataset[!duplicated(ADIDataset), ]
                                
                                if (group == allGroups[1])
                                    rowLabels <- c(rowLabels, "Mean ADI")
                                
                                meanADI <- mean(ADIDataset$ADI, na.rm = T)
                                columns[[group]] <- c(columns[[group]], meanADI)

                                if (Yr != "All") {
                                
                                    # Determine the median RAF.
                                  
                                    RAFDataset <- dplyr::select(filteredMLIDataset, SavvyHICN, Year, RAFMMR, Gdr_Cd) %>% filter(Year == Yr)
                                    RAFDataset <- RAFDataset[!duplicated(RAFDataset), ]
                                    summaryOutput <- summary(RAFDataset$RAFMMR)

                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Median RAF")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Median RAF")
                                    }
                                
                                    medianRAF <- round(summaryOutput["Median"], 2)
                                    columns[[group]] <- c(columns[[group]], medianRAF)
                                
                                    # Determine the mean RAF.
                                
                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Mean RAF")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Mean RAF")
                                    }
                                
                                    meanRAF <- round(summaryOutput["Mean"], 2)
                                    columns[[group]] <- c(columns[[group]], meanRAF)
                                
                                    # Determine the median RAF of Males.
                                
                                    malesRAFDataset <- filter(RAFDataset, Gdr_Cd == "M")
                                    summaryOutput <- summary(malesRAFDataset$RAFMMR)
                                
                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Median RAF of Males")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Median RAF of Males")
                                    }
                                
                                    medianMalesRAF <- round(summaryOutput["Median"], 2)
                                    columns[[group]] <- c(columns[[group]], medianMalesRAF)
                                
                                    # Determine the mean RAF of Males.
                                
                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Mean RAF of Males")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Mean RAF of Males")
                                    }
                                
                                    meanMalesRAF <- round(summaryOutput["Mean"], 2)
                                    columns[[group]] <- c(columns[[group]], meanMalesRAF)
                                
                                    # Determine the median RAF of Females.
                                
                                    femalesRAFDataset <- filter(RAFDataset, Gdr_Cd == "F")
                                    summaryOutput <- summary(femalesRAFDataset$RAFMMR)
                                
                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Median RAF of Females")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Median RAF of Females")
                                    }
                                
                                    medianFemalesRAF <- round(summaryOutput["Median"], 2)
                                    columns[[group]] <- c(columns[[group]], medianFemalesRAF)
                                
                                    # Determine the mean RAF of Females.
                                
                                    if (group == allGroups[1]) {
                                      
                                        rowLabels <- c(rowLabels, "Mean RAF of Females")
                                        percentLowerRowLabels <- c(percentLowerRowLabels, "Mean RAF of Females")
                                    }
                                
                                    meanFemalesRAF <- round(summaryOutput["Mean"], 2)
                                    columns[[group]] <- c(columns[[group]], meanFemalesRAF)
                                }
                           }
                           
                           # Consolidate results.
                           
                           options("scipen" = 100)
                           
                           if (pilotType == "2016") {
                               
                               summaryTable <- data.frame(RowLabels = rowLabels, TotalPopulation = columns[["Total Population"]], 
                                                          Enrolled = columns[["Enrolled"]], NotEnrolled = columns[["Not Enrolled"]], 
                                                          Registered = columns[["Registered"]], NotRegistered = columns[["Not Registered"]])
                               numberOfComparisons <- 2
                           }
                           else {
                             
                               summaryTable <- data.frame(RowLabels = rowLabels, TotalPopulation = columns[["Total Population"]], Reached = columns[["Reached"]], 
                                                          NotReached = columns[["Not Reached"]], Enrolled = columns[["Enrolled"]], 
                                                          NotEnrolled = columns[["Not Enrolled"]], Registered = columns[["Registered"]], 
                                                          NotRegistered = columns[["Not Registered"]])
                               numberOfComparisons <- 3
                           }
                           
                           # Set up output table
                           
                           outputTable <- dplyr::select(summaryTable, RowLabels, TotalPopulation) %>% mutate(RowNumber = row_number())
                           
                           percentLowerTable <- data.frame(RowLabels = percentLowerRowLabels)
                           percentLowerTable <- merge(percentLowerTable, summaryTable, by = "RowLabels", all.x = T)

                           for (i in 1:numberOfComparisons) {
                             
                                groupPairs <- colnames(summaryTable)[c(2*i + 1, 2*i + 2)]
                                
                                groupPairsSummaryTable <- dplyr::select(summaryTable, RowLabels, one_of(groupPairs))
                                
                                groupPairsPercentLowerTable <- dplyr::select(percentLowerTable, RowLabels, one_of(groupPairs))
                                percentLowerColumnHeader <-  paste(paste0(groupPairs, collapse = "-"), "% Lower")
                                groupPairsPercentLowerTable[, percentLowerColumnHeader] <- round(100*(groupPairsPercentLowerTable[, groupPairs[2]] - groupPairsPercentLowerTable[, groupPairs[1]])/groupPairsPercentLowerTable[, groupPairs[2]], 2)
                                groupPairsPercentLowerTable <- dplyr::select(groupPairsPercentLowerTable, RowLabels, one_of(percentLowerColumnHeader))
                                
                                groupPairsSummaryTable <- merge(groupPairsSummaryTable, groupPairsPercentLowerTable, by = "RowLabels", all.x = T)
                                outputTable <- merge(outputTable, groupPairsSummaryTable, by = "RowLabels", all.x = T)
                           }

                           outputTable <- dplyr::arrange(outputTable, RowNumber) %>% dplyr::select(-RowNumber)
                           colnames(outputTable)[1] <- ""
                           
                           if (Yr == "All")
                               output <- outputTable
                           else {
                             
                               output <- list()
                               output$allFilteredMembers <- allFilteredMembers
                               output$outputTable <- outputTable
                           }
                           
                           return(output)
}

significanceTests <- function(group1, group2, pilotType = "Lifetime Value", Yr = "All", totalMM = NULL, rxRebate = "40%", 
                              data = NULL, filteredMembers = NULL) {
                     "
                     Perform tests of significant differences between two groups of medicare members. 
                    
                     Parameters:
                    
                        group1: the name of the first group of members.
                                The options are 'Enrolled', 'Not Enrolled', 'Registered', and 'Not Registered'.
                                If pilotType is a pilot other than '2016', the options also include 'Reached' and 'Not Reached'.
                        group2: the name of the second group of members.
                                The options are 'Enrolled', 'Not Enrolled', 'Registered', and 'Not Registered'.
                                If pilotType is a pilot other than '2016', the options also include 'Reached' and 'Not Reached'.
                        pilotType: the pilot from which the members will be taken from.
                                   The options are '2016', '2017', 'Alternative', 'Lifetime Value', 'Lifetime Value Control', 'New Age-ins',
                                       'New Diabetics', and 'New Diabetics Control'.
                                   The default value is 'Lifetime Value'.
                        Yr: the year to be considered in extracting the data.
                            If 'All', then all years from 2006 to 2017 will be considered.
                            The default value is 'All'.
                        totalMM: the number of months of enrollment in one year to be required of members.
                                The default value is NULL.
                        rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
                                  The options are '40%', 'Full', and 'None'.
                                  The default value is '40%'
                        data: a dataframe consisting of the data needed to perform the statistical tests.
                              The default value is NULL.
                        filteredMembers: a vector of SavvHICNs that remain after removing the outliers.
                                         The default value is NULL.
                    
                     Output: a dataframe consisting of the p-values from the statistical tests.
                    
                     Example:

                        group1 = 'Reached'
                        group2 = 'Not Reached'
                    
                        Run a = significantTests(group1, group2)
                     "
  
                     if (is.null(data)) {
                       
                         # Read from the LTV_Member_Month_2016_Pilot or LTV_Member_Month table.
                         
                         if (pilotType == "2016")
                             tableName <- "LTV_Member_Month_2016_Pilot"
                         else 
                             tableName <- "LTV_Member_Month"
    
                         ltvMemberMonthsNeededFields <- c("SavvyHICN", "Lifetime_ID", "Year_Mo", "Total_MA_Amt", "Total_D_Amt", "Premium_C_Amt",
                                                          "Premium_D_Amt", "Total_MA_Derived_IP_Cost", "Total_MA_Derived_OP_Cost", 
                                                          "Total_MA_Derived_DR_Cost", "Total_MA_Derived_ER_Cost", "Total_MA_Derived_DME_Cost",
                                                          "Total_D_Cost", "Total_Revenue")
                         
                         if (rxRebate == "40%")
                             ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_40Percent", "Total_Cost_40Percent_Rebate",
                                                              "Total_Value_40Percent_Rebate")
                         else if (rxRebate == "Full")
                                  ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_Full", "Total_Cost_Full_Rebate",
                                                            "Total_Value_Full_Rebate")
                         else if (rxRebate == "None")
                                  ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Total_Cost_NoRebate", "Total_Value_NoRebate")
                         
                         ltvMemberMonthDataset <- read("devsql14", database2, "res", tableName, ltvMemberMonthsNeededFields, "all", F)
                         
                         if (rxRebate == "40%")
                             ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                             Total_Revenue = Total_Revenue + Rx_Rebate_Amt_40Percent, 
                                                             Total_Cost = Total_Cost_40Percent_Rebate + Rx_Rebate_Amt_40Percent) %>% 
                                                      dplyr::select(SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                                    Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                                    Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost,
                                                                    Rx_Rebate_Amt_40Percent, Total_Revenue, Total_Cost, Total_Value_40Percent_Rebate) %>%
                                                      dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_40Percent, Total_Value = Total_Value_40Percent_Rebate)
                         else if (rxRebate == "Full")
                                  ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                                  Total_Revenue = Total_Revenue + Rx_Rebate_Amt_Full, 
                                                                  Total_Cost = Total_Cost_Full_Rebate + Rx_Rebate_Amt_Full) %>% 
                                  dplyr::select(SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost,
                                                Rx_Rebate_Amt_Full, Total_Revenue, Total_Cost, Total_Value_Full_Rebate) %>%
                                  dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_Full, Total_Value = Total_Value_Full_Rebate)
                         else if (rxRebate == "None")
                                  ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                                  Total_Cost = Total_Cost_NoRebate) %>% 
                                  dplyr::select(SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost, Total_Revenue, Total_Cost, 
                                                Total_Value_NoRebate) %>%
                                  dplyr::rename(Total_Value = Total_Value_NoRebate)

                         totalMMDataset <- dplyr::select(ltvMemberMonthDataset, Life_ID, Year) %>% mutate(Total_MM = 1)
                         totalMMDataset <- aggregate(.~ Life_ID + Year, FUN = "sum", data = totalMMDataset)
                         
                         ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, totalMMDataset, by = c("Life_ID", "Year"), all.x = T)
                         
                         if (rxRebate == "None")
                             ltvMemberMonthDataset <- dplyr::select(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, 
                                                                    Premium_C_Amt, Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, 
                                                                    Total_MA_Derived_DR_Cost, Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost,
                                                                    Total_D_Cost, Total_Revenue, Total_Cost, Total_Value, Total_MM) 
                         else
                             ltvMemberMonthDataset <- dplyr::select(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, 
                                                                    Premium_C_Amt, Premium_D_Amt, Rx_Rebate_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, 
                                                                    Total_MA_Derived_DR_Cost, Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost,
                                                                    Total_D_Cost, Total_Revenue, Total_Cost, Total_Value, Total_MM) 
                         
                         ltvMemberMonthDataset <- dplyr::arrange(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Year_Mo)
                         
                         # Read from the New_Member_Information_2016_Pilot or New_Member_Information table.
                         
                         if (pilotType == "2016")
                             tableName <- "New_Member_Information_2016_Pilot"
                         else 
                             tableName <- "New_Member_Information"
                         
                         newMemberInformationNeededFields <- c("SavvyHICN", "PartD_Flag", "Commercial_Flag")
                         newMemberInformationDataset <- read("devsql14", database2, "res", tableName, newMemberInformationNeededFields, "all", F)
                         newMemberInformationDataset <- filter(newMemberInformationDataset, PartD_Flag == 0, Commercial_Flag == 0) %>% 
                                                        mutate(Member_Status = "New Member") %>% dplyr::select(SavvyHICN, Member_Status)
                         
                         ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, newMemberInformationDataset, by = "SavvyHICN", all.x = T)

                         # Read from the Members_2016_Pilot or GP1026_WnW_Member_Details table.
                         
                         if (pilotType == "2016") {
                           
                           member2016PilotNeededFields <- c("SavvyHICN", "Gender", "Age", "PBP", "Registered_Flag", "WithSteps_Flag")
                           member2016PilotDataset <- read("devsql14", database2, "res", "Member_2016_Pilot", member2016PilotNeededFields, "all", F)
                           memberNeededInfoDataset <- dplyr::rename(member2016PilotDataset, Gdr_Cd = Gender, ActivatedTrio_Flag = WithSteps_Flag) %>% 
                                                      mutate(PilotType = "2016", Invite_Flag = 1) %>%
                                                      dplyr::select(SavvyHICN, Gdr_Cd, Age, PBP, PilotType, Invite_Flag, Registered_Flag, 
                                                                    ActivatedTrio_Flag)
                           
                           memberNeededInfoDataset[is.na(memberNeededInfoDataset$Registered_Flag), "Registered_Flag"] <- 0
                         }
                         else {
                           
                             memberDetailsNeededFields <- c("SavvyHicn", "Gdr_Cd", "Age", "PBP", "PilotType", "Invite_Flag", "Registered_Flag",
                                                            "ActivatedTrio_Flag")
                             memberDetailsDataset <- read("devsql14", database2, "final", "GP1026_WnW_Member_Details", memberDetailsNeededFields, "all", F)
                             memberNeededInfoDataset <- dplyr::rename(memberDetailsDataset, SavvyHICN = SavvyHicn)
                         }

                         ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, memberNeededInfoDataset, by = "SavvyHICN", all.y = T)
                         
                         # Read from the LTV_Member_Demographics_2016_Pilot or LTV_Member_Demographics table.
                         
                         if (pilotType == "2016")
                             tableName <- "LTV_Member_Demographics_2016_Pilot"
                         else 
                             tableName <- "LTV_Member_Demographics"

                         ltvMemberDemographicsNeededFields <- c("SavvyHICN", "ZIP", "St_Cd")
                         ltvMemberDemographicsDataset <- read("devsql14", database2, "res", tableName, ltvMemberDemographicsNeededFields, "all", F)
                         
                         ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, ltvMemberDemographicsDataset, by = "SavvyHICN", all.x = T)
                         
                         # Read from the RAF_2016_Pilot or GP1026_WnW_Member_Claims table.
                         
                         if (pilotType == "2016") {
                           
                             raf2016PilotNeededFields <- c("SavvyHICN", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016")
                             raf2016PilotDataset <- read("devsql14", database2, "res", "RAF_2016_Pilot", raf2016PilotNeededFields, "all", F)
                             rafDataset <- dplyr::rename(raf2016PilotDataset, "2013" = RAFMMR_2013, "2014" = RAFMMR_2014, "2015" = RAFMMR_2015, 
                                                         "2016" = RAFMMR_2016)
                         }
                         else {
                           
                             memberClaimsNeededFields <- c("SavvyHicn", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016")
                             memberClaimsDataset <- read("devsql14", database2, "final", "GP1026_WnW_Member_Claims", memberClaimsNeededFields, "all", F)
                             rafDataset <- dplyr::rename(memberClaimsDataset, SavvyHICN = SavvyHicn, "2013" = RAFMMR_2013, "2014" = RAFMMR_2014,
                                                         "2015" = RAFMMR_2015, "2016" = RAFMMR_2016)
                         }
                         
                         rafDataset <- melt(rafDataset, id = c("SavvyHICN"))
                         rafDataset <- dplyr::rename(rafDataset, Year = variable, RAFMMR = value) %>% arrange(SavvyHICN, Year)
                         
                         ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, rafDataset, by = c("SavvyHICN", "Year"), all.x = T)

                         # Read from the AreaDeprivationIndex_ZIPLevel table.
                         
                         areaDeprivationIndexDataset <- read("devsql10", database1, "dbo", "AreaDeprivationIndex_ZIPLevel", "*", "all", F)
                         areaDeprivationIndexDataset <- mutate(areaDeprivationIndexDataset, ZIP = zip, ADI = DepIdx)
                         
                         ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, areaDeprivationIndexDataset, by = "ZIP", all.x = T)
                         
                         ltvMemberMonthDataset[is.na(ltvMemberMonthDataset$Member_Status), "Member_Status"] <- "Old Member"

                         ltvMemberMonthDataset <- filter(ltvMemberMonthDataset, PilotType == pilotType) %>%
                                                  dplyr::select(-PilotType) %>% dplyr::arrange(SavvyHICN, Lifetime_ID, Year_Mo)
                     }
                     else
                         ltvMemberMonthDataset <- data
                     
                     if (group1 == "Reached") 
                         filteredMLIDataset1 <- filter(ltvMemberMonthDataset, Invite_Flag == 1)
                     else if (group1 == "Not Reached")
                              filteredMLIDataset1 <- filter(ltvMemberMonthDataset, Invite_Flag == 0)
                     else if (group1 == "Enrolled")
                              filteredMLIDataset1 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 1)
                     else if (group1 == "Not Enrolled")
                              filteredMLIDataset1 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 0)
                     else if (group1 == "Registered")
                              filteredMLIDataset1 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 1, ActivatedTrio_Flag == 1)
                     else if (group1 == "Not Registered")
                              filteredMLIDataset1 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 1, ActivatedTrio_Flag == 0)
                     
                     if (group2 == "Reached")
                         filteredMLIDataset2 <- filter(ltvMemberMonthDataset, Invite_Flag == 1)
                     else if (group2 == "Not Reached")
                       filteredMLIDataset2 <- filter(ltvMemberMonthDataset, Invite_Flag == 0)
                     else if (group2 == "Enrolled")
                              filteredMLIDataset2 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 1)
                     else if (group2 == "Not Enrolled")
                              filteredMLIDataset2 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 0)
                     else if (group2 == "Registered")
                              filteredMLIDataset2 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 1, ActivatedTrio_Flag == 1)
                     else if (group2 == "Not Registered")
                              filteredMLIDataset2 <- filter(ltvMemberMonthDataset, Invite_Flag == 1, Registered_Flag == 1, ActivatedTrio_Flag == 0)
                     
                     if (Yr != "All") {
                       
                         originalfilteredMLIDataset1 <- filteredMLIDataset1
                         originalfilteredMLIDataset2 <- filteredMLIDataset2
                       
                         Yr <- as.character(Yr)
                         filteredMLIDataset1 <- filter(filteredMLIDataset1, Year == Yr, is.na(Lifetime_ID) == F)
                         filteredMLIDataset2 <- filter(filteredMLIDataset2, Year == Yr, is.na(Lifetime_ID) == F)
                         
                         if (!is.null(filteredMembers)) {
                           
                             filteredMLIDataset1 <- filter(filteredMLIDataset1, SavvyHICN %in% filteredMembers)
                             filteredMLIDataset2 <- filter(filteredMLIDataset2, SavvyHICN %in% filteredMembers)
                         }

                         yrSavvyHICNs1 <- unique(filteredMLIDataset1$SavvyHICN)
                         yrSavvyHICNs2 <- unique(filteredMLIDataset2$SavvyHICN)
                       
                         tenureDataset1 <- filter(originalfilteredMLIDataset1, SavvyHICN %in% yrSavvyHICNs1)
                         tenureDataset2 <- filter(originalfilteredMLIDataset2, SavvyHICN %in% yrSavvyHICNs2)
                     }
                     
                     if (!is.null(totalMM)) {
                       
                         originalfilteredMLIDataset1 <- filteredMLIDataset1
                         originalfilteredMLIDataset2 <- filteredMLIDataset2
                       
                         filteredMLIDataset1 <- filter(filteredMLIDataset1, Total_MM == totalMM)
                         filteredMLIDataset2 <- filter(filteredMLIDataset2, Total_MM == totalMM)
                         totalMMSavvyHICNs1 <- unique(filteredMLIDataset1$SavvyHICN)
                         totalMMSavvyHICNs2 <- unique(filteredMLIDataset2$SavvyHICN)

                         if (Yr == "All") {
                           
                             tenureDataset1 <- filter(originalfilteredMLIDataset1, SavvyHICN %in% totalMMSavvyHICNs1)
                             tenureDataset2 <- filter(originalfilteredMLIDataset2, SavvyHICN %in% totalMMSavvyHICNs2)
                         }
                         else {
                           
                             tenureDataset1 <- filter(tenureDataset1, SavvyHICN %in% totalMMSavvyHICNs1)
                             tenureDataset2 <- filter(tenureDataset2, SavvyHICN %in% totalMMSavvyHICNs2)
                         }
                     }

                     rowLabels <- c()
                     pValues <- c()
                     
                     # Perform t-test of MLI.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MLI")
                     ttestTotalValue <- t.test(filteredMLIDataset1$Total_Value, filteredMLIDataset2$Total_Value)
                     pValues <- c(pValues, round(ttestTotalValue$p.value, 2))
                     
                     # Perform t-test of MA amount.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MA Amount")
                     ttestTotalMAAmount <- t.test(filteredMLIDataset1$Total_MA_Amt, filteredMLIDataset2$Total_MA_Amt)
                     pValues <- c(pValues, round(ttestTotalMAAmount$p.value, 2))
                     
                     # Perform t-test of D amount.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM D Amount")
                     ttestTotalDAmount <- t.test(filteredMLIDataset1$Total_D_Amt, filteredMLIDataset2$Total_D_Amt)
                     pValues <- c(pValues, round(ttestTotalDAmount$p.value, 2))
                     
                     # Perform t-test of Premium C amount.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM Premium C Amount")
                     ttestPremiumCAmount <- t.test(filteredMLIDataset1$Premium_C_Amt, filteredMLIDataset2$Premium_C_Amt)
                     pValues <- c(pValues, round(ttestPremiumCAmount$p.value, 2))
                     
                     # Perform t-test of Premium D amount.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM Premium D Amount")
                     ttestPremiumDAmount <- t.test(filteredMLIDataset1$Premium_D_Amt, filteredMLIDataset2$Premium_D_Amt)
                     pValues <- c(pValues, round(ttestPremiumDAmount$p.value, 2))
                     
                     # Perform t-test of Rx rebate amount.
                     
                     if (rxRebate != "None") {
                     
                         rowLabels <- c(rowLabels, "Aggregate PMPM Rx Rebate Amount")
                         ttestRxRebateAmount <- t.test(filteredMLIDataset1$Rx_Rebate_Amt, filteredMLIDataset2$Rx_Rebate_Amt)
                         pValues <- c(pValues, round(ttestRxRebateAmount$p.value, 2))
                     }

                     # Perform t-test of total revenue.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM Total Revenue")
                     ttestTotalRevenue <- t.test(filteredMLIDataset1$Total_Revenue, filteredMLIDataset2$Total_Revenue)
                     pValues <- c(pValues, round(ttestTotalRevenue$p.value, 2))
                     
                     # Perform t-test of total MA Derived IP cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived IP Cost")
                     ttestTotalMADerivedIPCost <- t.test(filteredMLIDataset1$Total_MA_Derived_IP_Cost, 
                                                         filteredMLIDataset2$Total_MA_Derived_IP_Cost)
                     pValues <- c(pValues, round(ttestTotalMADerivedIPCost$p.value, 2))
                     
                     # Perform t-test of total MA Derived OP cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived OP Cost")
                     ttestTotalMADerivedOPCost <- t.test(filteredMLIDataset1$Total_MA_Derived_OP_Cost, 
                                                         filteredMLIDataset2$Total_MA_Derived_OP_Cost)
                     pValues <- c(pValues, round(ttestTotalMADerivedOPCost$p.value, 2))
                     
                     # Perform t-test of total MA Derived DR cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived DR Cost")
                     ttestTotalMADerivedDRCost <- t.test(filteredMLIDataset1$Total_MA_Derived_DR_Cost, 
                                                         filteredMLIDataset2$Total_MA_Derived_DR_Cost)
                     pValues <- c(pValues, round(ttestTotalMADerivedDRCost$p.value, 2))
                     
                     # Perform t-test of total MA Derived ER cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived ER Cost")
                     ttestTotalMADerivedERCost <- t.test(filteredMLIDataset1$Total_MA_Derived_ER_Cost, 
                                                         filteredMLIDataset2$Total_MA_Derived_ER_Cost)
                     pValues <- c(pValues, round(ttestTotalMADerivedERCost$p.value, 2))
                     
                     # Perform t-test of total MA Derived DME cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MA Derived DME Cost")
                     ttestTotalMADerivedDMECost <- t.test(filteredMLIDataset1$Total_MA_Derived_DME_Cost, 
                                                         filteredMLIDataset2$Total_MA_Derived_DME_Cost)
                     pValues <- c(pValues, round(ttestTotalMADerivedDMECost$p.value, 2))
                     
                     # Perform t-test of total D cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM D Cost")
                     ttestTotalDCost <- t.test(filteredMLIDataset1$Total_D_Cost, filteredMLIDataset2$Total_D_Cost)
                     pValues <- c(pValues, round(ttestTotalDCost$p.value, 2))

                     # Perform t-test of total cost.
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM Total Cost")
                     ttestTotalCost <- t.test(filteredMLIDataset1$Total_Cost, filteredMLIDataset2$Total_Cost)
                     pValues <- c(pValues, round(ttestTotalCost$p.value, 2))
                     
                     # Perform median test of tenure.
                     
                     if (Yr == "All" & is.null(totalMM)) {
                       
                         tenureDataset1 <- dplyr::select(filteredMLIDataset1, Life_ID, Year, Total_MM) %>% filter(is.na(Life_ID) == F)
                         tenureDataset2 <- dplyr::select(filteredMLIDataset2, Life_ID, Year, Total_MM) %>% filter(is.na(Life_ID) == F)
                     }
                     else {
                       
                         tenureDataset1 <- dplyr::select(tenureDataset1, Life_ID, Year, Total_MM) %>% filter(is.na(Life_ID) == F)
                         tenureDataset2 <- dplyr::select(tenureDataset2, Life_ID, Year, Total_MM) %>% filter(is.na(Life_ID) == F)
                     }

                     tenureDataset1 <- tenureDataset1[!duplicated(tenureDataset1), ]
                     tenureDataset1 <- dplyr::select(tenureDataset1, -Year)
                     tenureDataset1 <- aggregate(.~ Life_ID, FUN = "sum", data = tenureDataset1)
                     
                     tenureDataset2 <- tenureDataset2[!duplicated(tenureDataset2), ]
                     tenureDataset2 <- dplyr::select(tenureDataset2, -Year)
                     tenureDataset2 <- aggregate(.~ Life_ID, FUN = "sum", data = tenureDataset2)
                     
                     tenureVector <- c(tenureDataset1$Total_MM, tenureDataset2$Total_MM)
                     groupVector <- c(rep("Group 1", length(tenureDataset1$Total_MM)), rep("Group 2", length(tenureDataset2$Total_MM)))

                     rowLabels <- c(rowLabels, "Median Tenure (in months)")
                     moodMedianTestTenure <- mood.medtest(tenureVector, groupVector)
                     pValues <- c(pValues, round(moodMedianTestTenure$p.value, 2))
                     
                     # Perform t-test of tenure.
                     
                     rowLabels <- c(rowLabels, "Mean Tenure (in months)")
                     ttestTenure <- t.test(tenureDataset1$Total_MM, tenureDataset2$Total_MM)
                     pValues <- c(pValues, round(ttestTenure$p.value, 2))
                     
                     # Perform test of proportions of males.
                     
                     genderDataset1 <- dplyr::select(filteredMLIDataset1, SavvyHICN, Gdr_Cd)
                     genderDataset1 <- genderDataset1[!duplicated(genderDataset1), ]
                     genderCounts1 <- table(genderDataset1$Gdr_Cd)
                     
                     genderDataset2 <- dplyr::select(filteredMLIDataset2, SavvyHICN, Gdr_Cd)
                     genderDataset2 <- genderDataset2[!duplicated(genderDataset2), ]
                     genderCounts2 <- table(genderDataset2$Gdr_Cd)
                     
                     testOfProportionsMalesMatrix <- rbind(genderCounts1[c("M", "F")], genderCounts2[c("M", "F")])
                     
                     rowLabels <- c(rowLabels, "Proportion of Males")
                     testOfProportionsMales <- prop.test(testOfProportionsMalesMatrix)
                     pValues <- c(pValues, round(testOfProportionsMales$p.value, 2))
                     
                     # Perform t-test of MLI of males.
                     
                     maleFilteredMLIDataset1 <- filter(filteredMLIDataset1, Gdr_Cd == "M")
                     maleFilteredMLIDataset2 <- filter(filteredMLIDataset2, Gdr_Cd == "M")
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MLI of Males")
                     ttestTotalValueMales <- t.test(maleFilteredMLIDataset1$Total_Value, maleFilteredMLIDataset2$Total_Value)
                     pValues <- c(pValues, round(ttestTotalValueMales$p.value, 2))
                     
                     # Perform test of proportions of females.
                     
                     testOfProportionsFemalesMatrix <- rbind(genderCounts1[c("F", "M")], genderCounts2[c("F", "M")])
                     
                     rowLabels <- c(rowLabels, "Proportion of Females")
                     testOfProportionsFemales <- prop.test(testOfProportionsFemalesMatrix)
                     pValues <- c(pValues, round(testOfProportionsFemales$p.value, 2))
                     
                     # Perform t-test of MLI of females.
                     
                     femaleFilteredMLIDataset1 <- filter(filteredMLIDataset1, Gdr_Cd == "F")
                     femaleFilteredMLIDataset2 <- filter(filteredMLIDataset2, Gdr_Cd == "F")
                     
                     rowLabels <- c(rowLabels, "Aggregate PMPM MLI of Females")
                     ttestTotalValueFemales <- t.test(femaleFilteredMLIDataset1$Total_Value, femaleFilteredMLIDataset2$Total_Value)
                     pValues <- c(pValues, round(ttestTotalValueFemales$p.value, 2))
                     
                     # Perform median test of age.
                     
                     ageDataset1 <- dplyr::select(filteredMLIDataset1, SavvyHICN, Age)
                     ageDataset1 <- ageDataset1[!duplicated(ageDataset1), ]
                     
                     ageDataset2 <- dplyr::select(filteredMLIDataset2, SavvyHICN, Age)
                     ageDataset2 <- ageDataset2[!duplicated(ageDataset2), ]
                     
                     ageVector <- c(ageDataset1$Age, ageDataset2$Age)
                     groupVector <- c(rep("Group 1", length(ageDataset1$Age)), rep("Group 2", length(ageDataset2$Age)))
                     
                     rowLabels <- c(rowLabels, "Median Age")
                     moodMedianTestAge <- mood.medtest(ageVector, groupVector)
                     pValues <- c(pValues, round(moodMedianTestAge$p.value, 2))

                     # Perform t-test of age.
                     
                     rowLabels <- c(rowLabels, "Mean Age")
                     ttestAge <- t.test(ageDataset1$Age, ageDataset2$Age)
                     pValues <- c(pValues, round(ttestAge$p.value, 2))
                     
                     if (pilotType != "2016") {
                     
                         # Perform test of proportions of members from AZ.
                         
                         stateDataset1 <- dplyr::select(filteredMLIDataset1, SavvyHICN, St_Cd)
                         stateDataset1 <- stateDataset1[!duplicated(stateDataset1), ]
                         stateDataset1 <- mutate(stateDataset1, State = ifelse(St_Cd == "AZ", "AZ", "non-AZ"))
                         stateCounts1 <- table(stateDataset1$State)
                         
                         stateDataset2 <- dplyr::select(filteredMLIDataset2, SavvyHICN, St_Cd)
                         stateDataset2 <- stateDataset2[!duplicated(stateDataset2), ]
                         stateDataset2 <- mutate(stateDataset2, State = ifelse(St_Cd == "AZ", "AZ", "non-AZ"))
                         stateCounts2 <- table(stateDataset2$State)
                         
                         testOfProportionsAZMatrix <- rbind(stateCounts1[c("AZ", "non-AZ")], stateCounts2[c("AZ", "non-AZ")])
                         
                         rowLabels <- c(rowLabels, "Proportion of AZ")
                         testOfProportionsAZ <- prop.test(testOfProportionsAZMatrix)
                         pValues <- c(pValues, round(testOfProportionsAZ$p.value, 2))
                         
                         # Perform test of proportions of members from states other than AZ.
                         
                         testOfProportionsNonAZMatrix <- rbind(stateCounts1[c("non-AZ", "AZ")], stateCounts2[c("non-AZ", "AZ")])
                         
                         rowLabels <- c(rowLabels, "Proportion of non-AZ")
                         testOfProportionsNonAZ <- prop.test(testOfProportionsNonAZMatrix)
                         pValues <- c(pValues, round(testOfProportionsNonAZ$p.value, 2))

                         # Perform test of proportions of members with PBP 036.
                         
                         PBPDataset1 <- dplyr::select(filteredMLIDataset1, SavvyHICN, PBP)
                         PBPDataset1 <- PBPDataset1[!duplicated(PBPDataset1), ]
                         PBPDataset1 <- mutate(PBPDataset1, PBP = ifelse(PBP < 10, paste0("00", PBP), paste0("0", PBP))) %>%
                                        mutate(PBP = ifelse(PBP == "036", "036", "non-036"))
                         PBPCounts1 <- table(PBPDataset1$PBP)
                         
                         PBPDataset2 <- dplyr::select(filteredMLIDataset2, SavvyHICN, PBP)
                         PBPDataset2 <- PBPDataset2[!duplicated(PBPDataset2), ]
                         PBPDataset2 <- mutate(PBPDataset2, PBP = ifelse(PBP < 10, paste0("00", PBP), paste0("0", PBP))) %>%
                                        mutate(PBP = ifelse(PBP == "036", "036", "non-036"))
                         PBPCounts2 <- table(PBPDataset2$PBP)
                         
                         testOfProportionsPBP036Matrix <- rbind(PBPCounts1[c("036", "non-036")], PBPCounts2[c("036", "non-036")])
                         
                         rowLabels <- c(rowLabels, "Proportion of 036")
                         testOfProportionsPBP036 <- prop.test(testOfProportionsPBP036Matrix)
                         pValues <- c(pValues, round(testOfProportionsPBP036$p.value, 2))
                         
                         # Perform test of proportions of members with PBPs other than PBP 036.
    
                         testOfProportionsNonPBP036Matrix <- rbind(PBPCounts1[c("non-036", "036")], PBPCounts2[c("non-036", "036")])
                         
                         rowLabels <- c(rowLabels, "Proportion of non-036")
                         testOfProportionsNonPBP036 <- prop.test(testOfProportionsNonPBP036Matrix)
                         pValues <- c(pValues, round(testOfProportionsNonPBP036$p.value, 2))
                     }
                     
                     # Perform t-test of ADI.
                     
                     ADIDataset1 <- dplyr::select(filteredMLIDataset1, SavvyHICN, ADI)
                     ADIDataset1 <- ADIDataset1[!duplicated(ADIDataset1), ]
                     
                     ADIDataset2 <- dplyr::select(filteredMLIDataset2, SavvyHICN, ADI)
                     ADIDataset2 <- ADIDataset2[!duplicated(ADIDataset2), ]

                     rowLabels <- c(rowLabels, "Mean ADI")
                     ttestADI <- t.test(ADIDataset1$ADI, ADIDataset2$ADI)
                     pValues <- c(pValues, round(ttestADI$p.value, 2))

                     if (Yr != "All") {
                       
                         # Perform median test of RAF.

                         RAFDataset1 <- dplyr::select(filteredMLIDataset1, SavvyHICN, Year, RAFMMR, Gdr_Cd) %>% filter(Year == Yr)
                         RAFDataset1 <- RAFDataset1[!duplicated(RAFDataset1), ]
                       
                         RAFDataset2 <- dplyr::select(filteredMLIDataset2, SavvyHICN, Year, RAFMMR, Gdr_Cd) %>% filter(Year == Yr)
                         RAFDataset2 <- RAFDataset2[!duplicated(RAFDataset2), ]

                         RAFVector <- c(RAFDataset1$RAFMMR, RAFDataset2$RAFMMR)
                         groupVector <- c(rep("Group 1", length(RAFDataset1$RAFMMR)), rep("Group 2", length(RAFDataset2$RAFMMR)))
                         
                         rowLabels <- c(rowLabels, "Median RAF")
                         moodMedianTestRAF <- mood.medtest(RAFVector, groupVector)
                         pValues <- c(pValues, round(moodMedianTestRAF$p.value, 2))
                         
                         # Perform t-test of RAF.
                         
                         rowLabels <- c(rowLabels, "Mean RAF")
                         ttestRAF <- t.test(RAFDataset1$RAFMMR, RAFDataset2$RAFMMR)
                         pValues <- c(pValues, round(ttestRAF$p.value, 2))
                         
                         # Perform median test of RAF of males.
                         
                         malesRAFDataset1 <- filter(RAFDataset1, Gdr_Cd == "M")
                         malesRAFDataset2 <- filter(RAFDataset2, Gdr_Cd == "M")
                         
                         malesRAFVector <- c(malesRAFDataset1$RAFMMR, malesRAFDataset2$RAFMMR)
                         groupVector <- c(rep("Group 1", length(malesRAFDataset1$RAFMMR)), rep("Group 2", length(malesRAFDataset2$RAFMMR)))
                         
                         rowLabels <- c(rowLabels, "Median RAF of Males")
                         moodMedianTestMalesRAF <- mood.medtest(malesRAFVector, groupVector)
                         pValues <- c(pValues, round(moodMedianTestMalesRAF$p.value, 2))
                         
                         # Perform t-test of RAF of males.
                         
                         rowLabels <- c(rowLabels, "Mean RAF of Males")
                         ttestMalesRAF <- t.test(malesRAFDataset1$RAFMMR, malesRAFDataset2$RAFMMR)
                         pValues <- c(pValues, round(ttestMalesRAF$p.value, 2))
                         
                         # Perform median test of RAF of females.
                         
                         femalesRAFDataset1 <- filter(RAFDataset1, Gdr_Cd == "F")
                         femalesRAFDataset2 <- filter(RAFDataset2, Gdr_Cd == "F")
                         
                         femalesRAFVector <- c(femalesRAFDataset1$RAFMMR, femalesRAFDataset2$RAFMMR)
                         groupVector <- c(rep("Group 1", length(femalesRAFDataset1$RAFMMR)), rep("Group 2", length(femalesRAFDataset2$RAFMMR)))
                         
                         rowLabels <- c(rowLabels, "Median RAF of Females")
                         moodMedianTestFemalesRAF <- mood.medtest(femalesRAFVector, groupVector)
                         pValues <- c(pValues, round(moodMedianTestFemalesRAF$p.value, 2))
                         
                         # Perform t-test of RAF of females.
                         
                         rowLabels <- c(rowLabels, "Mean RAF of Females")
                         ttestFemalesRAF <- t.test(femalesRAFDataset1$RAFMMR, femalesRAFDataset2$RAFMMR)
                         pValues <- c(pValues, round(ttestFemalesRAF$p.value, 2))
                     }

                     # Set up output.
                     
                     output <- data.frame(rowLabels, pValues)
                     colnames(output) <- c("", "p-value")

                     return(output)
}

runAllTests <- function(pilotType = "Lifetime Value", Yr = "All", totalMM = NULL, rxRebate = "40%", filteredMembers = NULL) {
               "
               Perform tests of significant differences between all pairs of groups of interest. 
              
               Parameters:
              
                  pilotType: the pilot from which the members will be taken from.
                             The options are '2016', '2017', 'Alternative', 'Lifetime Value', 'Lifetime Value Control', 'New Age-ins',
                                 'New Diabetics', and 'New Diabetics Control'.
                             The default value is 'Lifetime Value'.
                  Yr: the year to be considered in extracting the data.
                      If 'All', then all years from 2006 to 2017 will be considered.
                      The default value is 'All'.
                  totalMM: the number of months of enrollment in one year to be required of members.
                          The default value is NULL.
                  rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
                            The options are '40%', 'Full', and 'None'.
                            The default value is '40%'
                  filteredMembers: a vector of SavvHICNs that remain after removing the outliers.
                                   The default value is NULL.
              
               Output: a dataframe consisting of the p-values from the statistical tests.
              
               Example:
              
                  Run a = runAllTests()
               "
  
               # Read from the LTV_Member_Month_2016_Pilot or LTV_Member_Month table.
              
               if (pilotType == "2016")
                   tableName <- "LTV_Member_Month_2016_Pilot"
               else 
                   tableName <- "LTV_Member_Month"

               ltvMemberMonthsNeededFields <- c("SavvyHICN", "Lifetime_ID", "Year_Mo", "Total_MA_Amt", "Total_D_Amt", "Premium_C_Amt",
                                                "Premium_D_Amt", "Total_MA_Derived_IP_Cost", "Total_MA_Derived_OP_Cost", 
                                                "Total_MA_Derived_DR_Cost", "Total_MA_Derived_ER_Cost", "Total_MA_Derived_DME_Cost",
                                                "Total_D_Cost", "Total_Revenue")
               
               if (rxRebate == "40%")
                   ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_40Percent", "Total_Cost_40Percent_Rebate",
                                                    "Total_Value_40Percent_Rebate")
               else if (rxRebate == "Full")
                        ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Rx_Rebate_Amt_Full", "Total_Cost_Full_Rebate",
                                                         "Total_Value_Full_Rebate")
               else if (rxRebate == "None")
                        ltvMemberMonthsNeededFields <- c(ltvMemberMonthsNeededFields, "Total_Cost_NoRebate", "Total_Value_NoRebate")
               
               ltvMemberMonthDataset <- read("devsql14", database2, "res", tableName, ltvMemberMonthsNeededFields, "all", F)
               
               if (rxRebate == "40%")
                   ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                   Total_Revenue = Total_Revenue + Rx_Rebate_Amt_40Percent, 
                                                   Total_Cost = Total_Cost_40Percent_Rebate + Rx_Rebate_Amt_40Percent) %>% 
                                            dplyr::select(SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                          Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                          Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost,
                                                          Rx_Rebate_Amt_40Percent, Total_Revenue, Total_Cost, Total_Value_40Percent_Rebate) %>%
                                            dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_40Percent, Total_Value = Total_Value_40Percent_Rebate)
               else if (rxRebate == "Full")
                        ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                        Total_Revenue = Total_Revenue + Rx_Rebate_Amt_Full, 
                                                        Total_Cost = Total_Cost_Full_Rebate + Rx_Rebate_Amt_Full) %>% 
                                                 dplyr::select(SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                               Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                               Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost,
                                                               Rx_Rebate_Amt_Full, Total_Revenue, Total_Cost, Total_Value_Full_Rebate) %>%
                                                 dplyr::rename(Rx_Rebate_Amt = Rx_Rebate_Amt_Full, Total_Value = Total_Value_Full_Rebate)
               else if (rxRebate == "None")
                        ltvMemberMonthDataset <- mutate(ltvMemberMonthDataset, Life_ID = paste0(SavvyHICN, "-", Lifetime_ID), Year = substr(Year_Mo, 1, 4), 
                                                        Total_Cost = Total_Cost_NoRebate) %>% 
                                                 dplyr::select(SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, Premium_C_Amt,
                                                               Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, Total_MA_Derived_DR_Cost, 
                                                               Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost, Total_D_Cost, Total_Revenue, Total_Cost, 
                                                               Total_Value_NoRebate) %>%
                                                 dplyr::rename(Total_Value = Total_Value_NoRebate)
              
               totalMMDataset <- dplyr::select(ltvMemberMonthDataset, Life_ID, Year) %>% mutate(Total_MM = 1)
               totalMMDataset <- aggregate(.~ Life_ID + Year, FUN = "sum", data = totalMMDataset)
              
               ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, totalMMDataset, by = c("Life_ID", "Year"), all.x = T)
               
               if (rxRebate == "None")
                   ltvMemberMonthDataset <- dplyr::select(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, 
                                                          Premium_C_Amt, Premium_D_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, 
                                                          Total_MA_Derived_DR_Cost, Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost,
                                                          Total_D_Cost, Total_Revenue, Total_Cost, Total_Value, Total_MM) 
               else
                   ltvMemberMonthDataset <- dplyr::select(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Life_ID, Year, Year_Mo, Total_MA_Amt, Total_D_Amt, 
                                                          Premium_C_Amt, Premium_D_Amt, Rx_Rebate_Amt, Total_MA_Derived_IP_Cost, Total_MA_Derived_OP_Cost, 
                                                          Total_MA_Derived_DR_Cost, Total_MA_Derived_ER_Cost, Total_MA_Derived_DME_Cost,
                                                          Total_D_Cost, Total_Revenue, Total_Cost, Total_Value, Total_MM) 
               
               ltvMemberMonthDataset <- dplyr::arrange(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Year_Mo)
              
               # Read from the New_Member_Information_2016_Pilot or New_Member_Information table.
              
               if (pilotType == "2016")
                   tableName <- "New_Member_Information_2016_Pilot"
               else 
                   tableName <- "New_Member_Information"
              
               newMemberInformationNeededFields <- c("SavvyHICN", "PartD_Flag", "Commercial_Flag")
               newMemberInformationDataset <- read("devsql14", database2, "res", tableName, newMemberInformationNeededFields, "all", F)
               newMemberInformationDataset <- filter(newMemberInformationDataset, PartD_Flag == 0, Commercial_Flag == 0) %>% 
                                              mutate(Member_Status = "New Member") %>% dplyr::select(SavvyHICN, Member_Status)
              
               ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, newMemberInformationDataset, by = "SavvyHICN", all.x = T)
              
               # Read from the Members_2016_Pilot or GP1026_WnW_Member_Details table.
              
               if (pilotType == "2016") {
                
                   member2016PilotNeededFields <- c("SavvyHICN", "Gender", "Age", "PBP", "Registered_Flag", "WithSteps_Flag")
                   member2016PilotDataset <- read("devsql14", database2, "res", "Member_2016_Pilot", member2016PilotNeededFields, "all", F)
                   memberNeededInfoDataset <- dplyr::rename(member2016PilotDataset, Gdr_Cd = Gender, ActivatedTrio_Flag = WithSteps_Flag) %>% 
                                              mutate(PilotType = "2016", Invite_Flag = 1) %>%
                                              dplyr::select(SavvyHICN, Gdr_Cd, Age, PBP, PilotType, Invite_Flag, Registered_Flag, 
                                                            ActivatedTrio_Flag)
                  
                   memberNeededInfoDataset[is.na(memberNeededInfoDataset$Registered_Flag), "Registered_Flag"] <- 0
               }
               else {
                
                   memberDetailsNeededFields <- c("SavvyHicn", "Gdr_Cd", "Age", "PBP", "PilotType", "Invite_Flag", "Registered_Flag",
                                                  "ActivatedTrio_Flag")
                   memberDetailsDataset <- read("devsql14", database2, "final", "GP1026_WnW_Member_Details", memberDetailsNeededFields, "all", F)
                   memberNeededInfoDataset <- dplyr::rename(memberDetailsDataset, SavvyHICN = SavvyHicn)
               }
              
               ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, memberNeededInfoDataset, by = "SavvyHICN", all.y = T)
              
               # Read from the LTV_Member_Demographics_2016_Pilot or LTV_Member_Demographics table.
              
               if (pilotType == "2016")
                   tableName <- "LTV_Member_Demographics_2016_Pilot"
               else 
                   tableName <- "LTV_Member_Demographics"
              
               ltvMemberDemographicsNeededFields <- c("SavvyHICN", "ZIP", "St_Cd")
               ltvMemberDemographicsDataset <- read("devsql14", database2, "res", tableName, ltvMemberDemographicsNeededFields, "all", F)
              
               ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, ltvMemberDemographicsDataset, by = "SavvyHICN", all.x = T)
              
               # Read from the RAF_2016_Pilot or GP1026_WnW_Member_Claims table.
              
               if (pilotType == "2016") {
                
                   raf2016PilotNeededFields <- c("SavvyHICN", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016")
                   raf2016PilotDataset <- read("devsql14", database2, "res", "RAF_2016_Pilot", raf2016PilotNeededFields, "all", F)
                   rafDataset <- dplyr::rename(raf2016PilotDataset, "2013" = RAFMMR_2013, "2014" = RAFMMR_2014, "2015" = RAFMMR_2015, 
                                              "2016" = RAFMMR_2016)
               }
               else {
                
                   memberClaimsNeededFields <- c("SavvyHicn", "RAFMMR_2013", "RAFMMR_2014", "RAFMMR_2015", "RAFMMR_2016")
                   memberClaimsDataset <- read("devsql14", database2, "final", "GP1026_WnW_Member_Claims", memberClaimsNeededFields, "all", F)
                   rafDataset <- dplyr::rename(memberClaimsDataset, SavvyHICN = SavvyHicn, "2013" = RAFMMR_2013, "2014" = RAFMMR_2014,
                                              "2015" = RAFMMR_2015, "2016" = RAFMMR_2016)
               }
              
               rafDataset <- melt(rafDataset, id = c("SavvyHICN"))
               rafDataset <- dplyr::rename(rafDataset, Year = variable, RAFMMR = value) %>% arrange(SavvyHICN, Year)
              
               ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, rafDataset, by = c("SavvyHICN", "Year"), all.x = T)
              
               # Read from the AreaDeprivationIndex_ZIPLevel table.
              
               areaDeprivationIndexDataset <- read("devsql10", database1, "dbo", "AreaDeprivationIndex_ZIPLevel", "*", "all", F)
               areaDeprivationIndexDataset <- mutate(areaDeprivationIndexDataset, ZIP = zip, ADI = DepIdx)
              
               ltvMemberMonthDataset <- merge(ltvMemberMonthDataset, areaDeprivationIndexDataset, by = "ZIP", all.x = T)
              
               ltvMemberMonthDataset[is.na(ltvMemberMonthDataset$Member_Status), "Member_Status"] <- "Old Member"
              
               if (pilotType != "2017")
                   ltvMemberMonthDataset <- filter(ltvMemberMonthDataset, PilotType == pilotType) %>% dplyr::select(-PilotType) 
               
               ltvMemberMonthDataset <- dplyr::arrange(ltvMemberMonthDataset, SavvyHICN, Lifetime_ID, Year_Mo)
 
               if (pilotType == "2016")
                   startIndex <- 2
               else
                   startIndex <- 1
               
               for (i in 1:3) {
                 
                    if (i == 1) {
                      
                        if (pilotType == "2016")
                            next
                      
                        group1 <- "Reached"
                        group2 <- "Not Reached"
                    }
                    else if (i == 2) {
                      
                             group1 <- "Enrolled"
                             group2 <- "Not Enrolled"
                    }
                    else if (i == 3) {
                      
                             group1 <- "Registered"
                             group2 <- "Not Registered"
                    }
                 
                    cat("\n")
                    cat("     ", group1, "and", group2)
                    cat("\n")
                 
                    significanceTestsOutput <- significanceTests(group1 = group1, group2 = group2, pilotType = pilotType, Yr = Yr, totalMM = totalMM, 
                                                                 rxRebate = rxRebate, data = ltvMemberMonthDataset, filteredMembers = filteredMembers)
                    colnames(significanceTestsOutput) <- c("RowLabel", paste(gsub(" ", "", paste(group1, "-", group2)), "p-value"))

                    if (i == startIndex)
                        output <- significanceTestsOutput
                    else
                        output <- merge(output, significanceTestsOutput, by = "RowLabel", all.x = T)
               }
               
               colnames(output)[1] <- ""

               return(output)
}

consolidateResults <- function(pilotType = "Lifetime Value", Yr = "All", totalMM = NULL, rxRebate = "40%", removeOutliers = T) {
                      "
                      Consolidate the results of the summarizeMedicareMotion and runAllTests functions.

                      Parameters:
                         
                         pilotType: the pilot from which the members will be taken from.
                                    The options are '2016', '2017', 'Alternative', 'Lifetime Value', 'Lifetime Value Control', 'New Age-ins',
                                        'New Diabetics', and 'New Diabetics Control'.
                                    The default value is 'Lifetime Value'.
                         Yr: the year to be considered in extracting the data.
                             If 'All', then all years from 2006 to 2017 will be considered.
                             The default value is 'All'.
                         totalMM: the number of months of enrollment in one year to be required of members.
                                  The default value is NULL.
                         rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
                                   The options are '40%', 'Full', and 'None'.
                                   The default value is '40%'
                         removeOutliers: a boolean to indicate whether or not to remove outliers from the calculations.
                                         The default value is T.

                      Output: a dataframe consisting of the consolidated results of the suummarizeMedicareMotion and runAllTests functions.

                      Example:

                         Run a = consolidateResults()
                      "
  
                      t1 <- Sys.time()
  
                      summarizeMedicareMotionOutput <- summarizeMedicareMotion(pilotType = pilotType, Yr = Yr, totalMM = totalMM, 
                                                                               rxRebate = rxRebate, removeOutliers = removeOutliers)
                      
                      if (Yr == "All") {
                        
                          summarizeMedicareMotionOutputTable <- summarizeMedicareMotionOutput
                          allFilteredMembers <- NULL
                      }
                      else {
                        
                          summarizeMedicareMotionOutputTable <- summarizeMedicareMotionOutput$outputTable
                          allFilteredMembers <- summarizeMedicareMotionOutput$allFilteredMembers
                      }
                      
                      colnames(summarizeMedicareMotionOutputTable)[1] <- "RowLabel"
                      summarizeMedicareMotionOutputTable <- mutate(summarizeMedicareMotionOutputTable, RowNumber = row_number())
                      
                      cat("\n")
                      cat("Performing tests of significance ...")
                      cat("\n")
                      
                      runAllTestsOutput <- runAllTests(pilotType = pilotType, Yr = Yr, totalMM = totalMM, rxRebate = rxRebate, 
                                                       filteredMembers = allFilteredMembers)
                      colnames(runAllTestsOutput)[1] <- "RowLabel"

                      output <- merge(summarizeMedicareMotionOutputTable, runAllTestsOutput, by = "RowLabel", all.x = T)
                      output <- dplyr::arrange(output, RowNumber)
                      
                      if (pilotType == "2016")
                          output <- dplyr::select(output, one_of("RowLabel", "TotalPopulation", "Enrolled", "NotEnrolled", "Enrolled-NotEnrolled % Lower", 
                                                                 "Enrolled-NotEnrolled p-value", "Registered", "NotRegistered", "Registered-NotRegistered % Lower",
                                                                 "Registered-NotRegistered p-value"))
                      else
                          output <- dplyr::select(output, one_of("RowLabel", "TotalPopulation", "Reached", "NotReached", "Reached-NotReached % Lower",
                                                                 "Reached-NotReached p-value", "Enrolled", "NotEnrolled", "Enrolled-NotEnrolled % Lower", 
                                                                 "Enrolled-NotEnrolled p-value", "Registered", "NotRegistered", "Registered-NotRegistered % Lower",
                                                                 "Registered-NotRegistered p-value"))

                      colnames(output)[1] <- ""
                      
                      t2 <- Sys.time()
                      
                      cat("\n")
                      print(t2 - t1)
                      cat("\n")
                      
                      return(output)
}
