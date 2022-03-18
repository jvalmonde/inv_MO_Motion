# consolidateResults.R
# December 13, 2017 (original date) through March 1, 2018 (current version)
# Steve Smela, Savvysherpa

# Based on code from Bernardo Marquez


consolidateResults <- function(pilotType = "Lifetime Value", Yr = "All", totalMM = NULL, rxRebate = "40%", removeOutliers = T, 
                                 State = NULL, Data = NULL, RAF_Decile = NULL, Reps = 2500, RemoveDeaths = F, EndYearMo = 201709) {
  "
  Parameters:
     
      pilotType: the pilot from which the members will be taken.
                 The options are '2016', or '2017' and its subsets:  'Alternative', 'Lifetime Value', 'Lifetime Value Control', 
                    'New Age-ins', 'New Diabetics', and 'New Diabetics Control'.
                 The default value is 'Lifetime Value'

       Yr: the year to be considered in extracting the data.
         If 'All', then all years from 2006 to 2017 will be considered.
         The default value is 'All'.

       totalMM: the number of months of enrollment in one year to be required of members.
              The default value is NULL.

      rxRebate: the kind of Rx Rebate to be used in the calculations of MLI.
               The options are '40%', 'Full', and 'None'.
               The default value is '40%'

      removeOutliers: a boolean to indicate whether or not to remove outliers from the calculations.
                     The default value is T.  Works only if Yr != 'All.'

      state: Specified if results from a particular state are desired (e.g., Indiana in the 2016 pilot)

      data: Use if there is an exisiting data set to be used.  If not, the function setupMemberMonth will be called

      RAF_decile:  As name implies, splits data by RAF decile.  Only works if Yr != 'All' and for 2013 and later.

      Reps:  The number of replications used in the randomization tests.

      RemoveDeaths:  If True, data from 12 months up to and including month of disenrollment due to death will be excluded. Default is False.

      EndYearMo:  The last year and month for which data will be analyzed.  Currently (4/2018) is 9/2017.

  "

  ###########################################################
  #             Set up output matrix                        #
  ###########################################################
  
  # For 2016 pilot, we do not have Reached / Not Reached comparisons; for 2017 pilots we do have Reached / Not Reached
  
  if (pilotType == "2016")
    ColumnNames = c("Total Population", "Enrolled", "Not Enrolled", "Enrolled-Not Enrolled Difference", "Enrolled-Not Enrolled p-value",
                    "Registered", "Not Registered", "Registered-Not Registered Difference", "Registered-Not Registered p-value")
  else
    ColumnNames = c("Total Population", "Reached", "Not Reached", "Reached-Not Reached Difference", "Reached-Not Reached p-value", 
                    "Enrolled", "Not Enrolled", "Enrolled-Not Enrolled Difference", "Enrolled-Not Enrolled p-value",
                    "Registered", "Not Registered", "Registered-Not Registered Difference", "Registered-Not Registered p-value")
    
  # Option Yr = 'All' does not allow for outlier removal or for RAF scores.  For rxRebate = 'None', Rx Rebate Amount does not appear.
  # Also, 2017 pilots have additional rows for Arizona and PDB 036.
  
  # Create lists of row names, for those that are common to all tables and those that appear in only some.
  
  Common1 = cbind("Members", "Lifetimes")
  
  Outliers = cbind("Outlier Members", "Filtered Members")
  
  Common2 = cbind("Aggregate Total Revenue", "Aggregate Total Cost", "Aggregate MLI Value", "Total Member Months", "Aggregate PMPM MLI",
                  "Aggregate PMPM MA Amount", "Aggregate PMPM D Amount", "Aggregate PMPM Premium C Amount", "Aggregate PMPM Premium D Amount")
  
  Rebate = "Aggregate PMPM Rx Rebate Amount"
  
  Common3 = cbind("Aggregate PMPM Total Revenue", "Aggregate PMPM MA Derived IP Cost", "Aggregate PMPM MA Derived OP Cost", "Aggregate PMPM MA Derived DR Cost",
                  "Aggregate PMPM MA Derived ER Cost", "Aggregate PMPM MA Derived DME Cost", "Aggregate PMPM D Cost", "Aggregate PMPM Total Cost")
  
  Annual1 = cbind("Median Number of Months", "Mean Number of Months")
  
  Common4 = cbind("Median Tenure (in months)", "Mean Tenure (in months)", "Proportion of Males", "Aggregate MLI Value of Males", "Total Member Months of Males",
                  "Aggregate PMPM MLI of Males", "Proportion of Females", "Aggregate MLI Value of Females", "Total Member Months of Females",
                  "Aggregate PMPM MLI of Females", "Median Age", "Mean Age")
  
  x2017Pilots = cbind("Proportion of AZ", "Proportion of 036")
  
  Common5 = "Mean ADI"
  
  Annual2 = cbind("Median RAF", "Mean RAF", "Median RAF of Males", "Mean RAF of Males", "Median RAF of Females", "Mean RAF of Females")
  
  
  
  # String together row names according to the various combinations of the parameters
  
  RowNames <- Common1
  
  if(Yr != "All" & removeOutliers)
    RowNames <- c(RowNames, Outliers)
  
  RowNames <- c(RowNames, Common2)
  
  if(rxRebate != "None")
    RowNames <- c(RowNames, Rebate)
  
  RowNames <- c(RowNames, Common3)
  
  if(Yr != "All")
    RowNames <- c(RowNames, Annual1)
  
  RowNames <- c(RowNames, Common4)
  
  if(pilotType != "2016")
    RowNames <- c(RowNames, x2017Pilots)
  
  RowNames <- c(RowNames, Common5)
  
  if(Yr != "All")
    RowNames <- c(RowNames, Annual2)
  
  
  # Create results matrix
  
  ResultsMatrix <- matrix(nrow = length(RowNames), ncol = length(ColumnNames), data = NA)
  
  rownames(ResultsMatrix) <- RowNames
  colnames(ResultsMatrix) <- ColumnNames
  
  
  ############################################################# 
  #    Create functions for adding data to results matrix     #
  #############################################################
  
  # Counts of IDs
  
  Count_IDs <- function(RowName, VarName) {
    
    ResultsMatrix[RowName,'Total Population'] <- length(unique(memberMonthDataset[, VarName]))
    
    if(pilotType != '2016') {
      
      ResultsMatrix[RowName,'Reached'] <- length(unique(memberMonthDataset[memberMonthDataset$Reached, VarName]))
      ResultsMatrix[RowName,'Not Reached'] <- length(unique(memberMonthDataset[memberMonthDataset$NotReached, VarName]))
      
    }
    
    ResultsMatrix[RowName,'Enrolled'] <- length(unique(memberMonthDataset[memberMonthDataset$Enrolled, VarName]))
    ResultsMatrix[RowName,'Not Enrolled'] <- length(unique(memberMonthDataset[memberMonthDataset$NotEnrolled, VarName]))
    
    ResultsMatrix[RowName,'Registered'] <- length(unique(memberMonthDataset[memberMonthDataset$Registered, VarName]))
    ResultsMatrix[RowName,'Not Registered'] <- length(unique(memberMonthDataset[memberMonthDataset$NotRegistered, VarName]))
    
    return(ResultsMatrix)
  }
  
  
  # Aggregate values (sums)
  
  AggValues <- function(RowName, VarName) {
    
    ResultsMatrix[RowName,'Total Population'] <- round(sum(CurrentData[, VarName], na.rm = T), 2)
    
    if(pilotType != '2016') {
      
      ResultsMatrix[RowName,'Reached'] <- round(sum(CurrentData[CurrentData$Reached, VarName], na.rm = T), 2)
      ResultsMatrix[RowName,'Not Reached'] <- round(sum(CurrentData[CurrentData$NotReached, VarName], na.rm = T), 2)
      
    }
    
    ResultsMatrix[RowName,'Enrolled'] <- round(sum(CurrentData[CurrentData$Enrolled, VarName], na.rm = T), 2)
    ResultsMatrix[RowName,'Not Enrolled'] <- round(sum(CurrentData[CurrentData$NotEnrolled, VarName], na.rm = T), 2)
    
    ResultsMatrix[RowName,'Registered'] <- round(sum(CurrentData[CurrentData$Registered, VarName], na.rm = T), 2)
    ResultsMatrix[RowName,'Not Registered'] <- round(sum(CurrentData[CurrentData$NotRegistered, VarName], na.rm = T), 2)
    
    return(ResultsMatrix)
    
  }
  
  # Mean values
  
  MeanValues <- function(RowName, VarName, Test = T) {
    
    ResultsMatrix[RowName,'Total Population'] <- mean(CurrentData[, VarName], na.rm = T)
    
    if(pilotType != '2016') {
      
      ResultsMatrix[RowName,'Reached'] <- mean(CurrentData[CurrentData$Reached, VarName], na.rm = T)
      ResultsMatrix[RowName,'Not Reached'] <- mean(CurrentData[CurrentData$NotReached, VarName], na.rm = T)
      
      ResultsMatrix[RowName,'Reached-Not Reached Difference'] <- ResultsMatrix[RowName,'Reached'] - ResultsMatrix[RowName,'Not Reached']
      
      if((Test == T & length(unique(CurrentData$SavvyHICN[CurrentData$Reached])) > 0 & length(unique(CurrentData$SavvyHICN[CurrentData$NotReached])) > 0))
        ResultsMatrix[RowName,'Reached-Not Reached p-value'] <- Test_Diff(Data = CurrentData, VarName = VarName, FUN = 'mean', 
                                                                          Comparison = 'Reached/Not Reached', Reps = Reps)
      
    }
    
    ResultsMatrix[RowName,'Enrolled'] <- mean(CurrentData[CurrentData$Enrolled, VarName], na.rm = T)
    ResultsMatrix[RowName,'Not Enrolled'] <- mean(CurrentData[CurrentData$NotEnrolled, VarName], na.rm = T)
    
    ResultsMatrix[RowName,'Enrolled-Not Enrolled Difference'] <- ResultsMatrix[RowName,'Enrolled'] - ResultsMatrix[RowName,'Not Enrolled']
    
    if((Test == T & length(unique(CurrentData$SavvyHICN[CurrentData$Enrolled])) > 0 & length(unique(CurrentData$SavvyHICN[CurrentData$NotEnrolled])) > 0))
      ResultsMatrix[RowName,'Enrolled-Not Enrolled p-value'] <- Test_Diff(Data = CurrentData, VarName = VarName, FUN = 'mean', 
                                                                          Comparison = 'Enrolled/Not Enrolled', Reps = Reps)
    
    ResultsMatrix[RowName,'Registered'] <- mean(CurrentData[CurrentData$Registered, VarName], na.rm = T)
    ResultsMatrix[RowName,'Not Registered'] <- mean(CurrentData[CurrentData$NotRegistered, VarName], na.rm = T)
    
    ResultsMatrix[RowName,'Registered-Not Registered Difference'] <- ResultsMatrix[RowName,'Registered'] - ResultsMatrix[RowName,'Not Registered']
    
    if((Test == T & length(unique(CurrentData$SavvyHICN[CurrentData$Registered])) > 0 & length(unique(CurrentData$SavvyHICN[CurrentData$NotRegistered])) > 0))
      ResultsMatrix[RowName,'Registered-Not Registered p-value'] <- Test_Diff(Data = CurrentData, VarName = VarName, FUN = 'mean', 
                                                                              Comparison = 'Registered/Not Registered', Reps = Reps)
    
    
    return(ResultsMatrix)
    
  }
  
  # Median values
  
  MedianValues <- function(RowName, VarName, Test = T) {
    
    ResultsMatrix[RowName,'Total Population'] <- median(CurrentData[, VarName], na.rm = T)
    
    if(pilotType != '2016') {
      
      ResultsMatrix[RowName,'Reached'] <- median(CurrentData[CurrentData$Reached, VarName], na.rm = T)
      ResultsMatrix[RowName,'Not Reached'] <- median(CurrentData[CurrentData$NotReached, VarName], na.rm = T)
      
      ResultsMatrix[RowName,'Reached-Not Reached Difference'] <- ResultsMatrix[RowName,'Reached'] - ResultsMatrix[RowName,'Not Reached']
      
      if((Test == T & length(unique(CurrentData$SavvyHICN[CurrentData$Reached])) > 0 & length(unique(CurrentData$SavvyHICN[CurrentData$NotReached])) > 0))
        ResultsMatrix[RowName,'Reached-Not Reached p-value'] <- Test_Diff(Data = CurrentData, VarName = VarName, FUN = 'median', 
                                                                          Comparison = 'Reached/Not Reached', Reps = Reps)
      
      
    }
    
    ResultsMatrix[RowName,'Enrolled'] <- median(CurrentData[CurrentData$Enrolled, VarName], na.rm = T)
    ResultsMatrix[RowName,'Not Enrolled'] <- median(CurrentData[CurrentData$NotEnrolled, VarName], na.rm = T)
    
    ResultsMatrix[RowName,'Enrolled-Not Enrolled Difference'] <- ResultsMatrix[RowName,'Enrolled'] - ResultsMatrix[RowName,'Not Enrolled']
    
    if((Test == T & length(unique(CurrentData$SavvyHICN[CurrentData$Enrolled])) > 0 & length(unique(CurrentData$SavvyHICN[CurrentData$NotEnrolled])) > 0))
      ResultsMatrix[RowName,'Enrolled-Not Enrolled p-value'] <- Test_Diff(Data = CurrentData, VarName = VarName, FUN = 'median', 
                                                                          Comparison = 'Enrolled/Not Enrolled', Reps = Reps)
    
    ResultsMatrix[RowName,'Registered'] <- median(CurrentData[CurrentData$Registered, VarName], na.rm = T)
    ResultsMatrix[RowName,'Not Registered'] <- median(CurrentData[CurrentData$NotRegistered, VarName], na.rm = T)
    
    ResultsMatrix[RowName,'Registered-Not Registered Difference'] <- ResultsMatrix[RowName,'Registered'] - ResultsMatrix[RowName,'Not Registered']
    
    if((Test == T & length(unique(CurrentData$SavvyHICN[CurrentData$Registered])) > 0 & length(unique(CurrentData$SavvyHICN[CurrentData$NotRegistered])) > 0))
      ResultsMatrix[RowName,'Registered-Not Registered p-value'] <- Test_Diff(Data = CurrentData, VarName = VarName, FUN = 'median', 
                                                                              Comparison = 'Registered/Not Registered', Reps = Reps)
    
    return(ResultsMatrix)
    
  }
  
  
  # Proportions of males and females
  
  Gender_Props <- function(RowName, Gender) {
    
    Total_IDs <- length(unique(constant$SavvyHICN))
    Total_Gender <- length(unique(constant$SavvyHICN[constant$Gdr_Cd == Gender]))
    Total_Prop <- Total_Gender / Total_IDs
    
    if(pilotType != '2016') {
      
      Reached_IDs <- length(unique(constant$SavvyHICN[constant$Reached]))
      Reached_Gender <- length(unique(constant$SavvyHICN[(constant$Gdr_Cd == Gender & constant$Reached)]))
      Reached_Prop <- Reached_Gender / Reached_IDs
      
      NotReached_IDs <- length(unique(constant$SavvyHICN[constant$NotReached]))
      NotReached_Gender <- length(unique(constant$SavvyHICN[(constant$Gdr_Cd == Gender & constant$NotReached)]))
      NotReached_Prop <- NotReached_Gender / NotReached_IDs
      
    }
    
    Enrolled_IDs <- length(unique(constant$SavvyHICN[constant$Enrolled]))
    Enrolled_Gender <- length(unique(constant$SavvyHICN[(constant$Gdr_Cd == Gender & constant$Enrolled)]))
    Enrolled_Prop <- Enrolled_Gender / Enrolled_IDs
    
    NotEnrolled_IDs <- length(unique(constant$SavvyHICN[constant$NotEnrolled]))
    NotEnrolled_Gender <- length(unique(constant$SavvyHICN[(constant$Gdr_Cd == Gender & constant$NotEnrolled)]))
    NotEnrolled_Prop <- NotEnrolled_Gender / NotEnrolled_IDs
    
    Registered_IDs <- length(unique(constant$SavvyHICN[constant$Registered]))
    Registered_Gender <- length(unique(constant$SavvyHICN[(constant$Gdr_Cd == Gender & constant$Registered)]))
    Registered_Prop <- Registered_Gender / Registered_IDs
    
    NotRegistered_IDs <- length(unique(constant$SavvyHICN[constant$NotRegistered]))
    NotRegistered_Gender <- length(unique(constant$SavvyHICN[(constant$Gdr_Cd == Gender & constant$NotRegistered)]))
    NotRegistered_Prop <- NotRegistered_Gender / NotRegistered_IDs
    
    
    ResultsMatrix[RowName,'Total Population'] <- Total_Prop
    
    if(pilotType != '2016') {
      
      ResultsMatrix[RowName,'Reached'] <- Reached_Prop
      ResultsMatrix[RowName,'Not Reached'] <- NotReached_Prop
      if(Reached_Prop > 0 & NotReached_Prop > 0 )
        ResultsMatrix[RowName,'Reached-Not Reached p-value'] <- prop.test(c(Reached_Gender, NotReached_Gender), c(Reached_IDs, NotReached_IDs))$p.value
      
    }
    
    ResultsMatrix[RowName,'Enrolled'] <- Enrolled_Prop
    ResultsMatrix[RowName,'Not Enrolled'] <- NotEnrolled_Prop
    if(Enrolled_Prop > 0 & NotEnrolled_Prop > 0)
      ResultsMatrix[RowName,'Enrolled-Not Enrolled p-value'] <- prop.test(c(Enrolled_Gender, NotEnrolled_Gender), c(Enrolled_IDs, NotEnrolled_IDs))$p.value
    
    ResultsMatrix[RowName,'Registered'] <- Registered_Prop
    ResultsMatrix[RowName,'Not Registered'] <- NotRegistered_Prop
    if(Registered_Prop > 0 & NotRegistered_Prop > 0)
      ResultsMatrix[RowName,'Registered-Not Registered p-value'] <- prop.test(c(Registered_Gender, NotRegistered_Gender), c(Registered_IDs, NotRegistered_IDs))$p.value
    
    
    return(ResultsMatrix)
    
  }
  

  ##############################################################
  # Use data passed as a parameter, or read in data if needed  #
  ##############################################################
  
  
  if(!is.null(Data))
    memberMonthDataset <- Data
  else
    memberMonthDataset <- setupMemberMonth(pilotType = pilotType, rxRebate = rxRebate)
  
  # Filter out data post-September 2017
  memberMonthDataset <- memberMonthDataset %>% filter(Year_Mo <= EndYearMo)
  
  ####################################################################
  #   Save timeline for calculating tenure before applying filters   #
  ####################################################################
  
  tenureDataset <- memberMonthDataset %>%
    select(Life_ID) %>%
    mutate(MM = 1)
  
  tenureDataset <- aggregate(MM ~ Life_ID, FUN = "sum", data = tenureDataset)

  
  ################################################################################
  #   Apply filters for pilot type, member months, State, Year, and RAF decile   #
  ################################################################################
  
  # Pilot type
  
  if (pilotType != "2016")
    memberMonthDataset <- filter(memberMonthDataset, PilotType == pilotType)  
  
  # Member months
  
  if(!is.null(totalMM))
    memberMonthDataset <- memberMonthDataset %>%
    filter(Total_MM == totalMM)
  
  # State
  
  if(!is.null(State))
    memberMonthDataset <- memberMonthDataset %>%
    filter(St_Cd == State)
  
  # Year
  
  if(Yr != "All") {
    
    memberMonthDataset <- memberMonthDataset %>% 
      filter(Year == Yr, is.na(Lifetime_ID) == F)                    # Not sure if I need this second filter; from Bernard's code
    
    # RAF decile  (NOTE:  Deciles determined before outlier removal; only works for year selected, 2013 and later)
    
    if(!is.null(RAF_Decile)) {
      
      deciles <- quantile(memberMonthDataset$RAFMMR, probs = seq(0, 1, .1), na.rm = T)
      
      if(RAF_Decile == 1)
        RAF_Lower = 0
      else
        RAF_Lower <- deciles[RAF_Decile]
      
      RAF_Upper <- deciles[RAF_Decile + 1]
      memberMonthDataset <- filter(memberMonthDataset, RAFMMR > RAF_Lower, RAFMMR <= RAF_Upper)
      
    }
  }
  
  ###############################################
  #    Filter deceased members, if needed       #
  ###############################################
  
  if(RemoveDeaths) {
    
    memberMonthDataset <- memberMonthDataset %>% replace_na(list(Death_Flag = 0)) %>%
      mutate(Prev12Months = Year_Mo > Disenroll_Year_Mo - 100 & Year_Mo <= Disenroll_Year_Mo) %>%
      filter(!(Prev12Months == TRUE & Death_Flag == 1)) %>%
      ungroup()
    
  }
    
  ##############################################
  #    Determine Reached / Not Reached, etc.   #
  ##############################################
  
  memberMonthDataset <- memberMonthDataset %>%
    mutate(Reached = (Invite_Flag == 1),
           NotReached = (Invite_Flag == 0),
           Enrolled = (Invite_Flag == 1 & Registered_Flag == 1),
           NotEnrolled = (Invite_Flag == 1 & Registered_Flag == 0),
           Registered = (Invite_Flag == 1 & Registered_Flag == 1 & ActivatedTrio_Flag == 1),
           NotRegistered = (Invite_Flag == 1 & Registered_Flag == 1 & ActivatedTrio_Flag == 0))
  
  
  ###################################################
  # Member Months.  Note:  Total_MM is used for filtering, need to actually count up member months similar to what we did for the tenure data set.
  ###################################################
  
  memberMonthDataset <- memberMonthDataset %>%
    mutate(MM = 1)
  
  
  ##############################################
  #    Fill in top rows of results matrix      #
  ##############################################
  
  ResultsMatrix <- Count_IDs(RowName = 'Members', VarName = 'SavvyHICN')
  ResultsMatrix <- Count_IDs(RowName = 'Lifetimes', VarName = 'Life_ID')
  
  
  #########################################################################
  # Filter outliers, if needed, and fill in rows in results matrix        #
  #########################################################################
  
  if(Yr != 'All' & removeOutliers) {
  
    # Set outlier field according to the year.  (I tried doing this dynamically based on value of Yr, but no success.)

    if (Yr == 2014)
      memberMonthDataset <- memberMonthDataset %>% dplyr::rename(Top5_Prcnt = Top5_Prcnt_2014)
    
    else if (Yr == 2015)
      memberMonthDataset <- memberMonthDataset %>% dplyr::rename(Top5_Prcnt = Top5_Prcnt_2015)

    else if (Yr == 2016)
      memberMonthDataset <- memberMonthDataset %>% dplyr::rename(Top5_Prcnt = Top5_Prcnt_2016)

    else if (Yr == 2017)
      memberMonthDataset <- memberMonthDataset %>% dplyr::rename(Top5_Prcnt = Top5_Prcnt_2017)
      
    ResultsMatrix['Outlier Members','Total Population'] <- length(unique(memberMonthDataset$SavvyHICN[memberMonthDataset$Top5_Prcnt == 1]))
  
  
    if(pilotType != '2016') {
    
      ResultsMatrix['Outlier Members','Reached'] <- length(unique(memberMonthDataset$SavvyHICN[(memberMonthDataset$Top5_Prcnt == 1 & memberMonthDataset$Reached)]))
      ResultsMatrix['Outlier Members','Not Reached'] <- length(unique(memberMonthDataset$SavvyHICN[(memberMonthDataset$Top5_Prcnt == 1 & memberMonthDataset$NotReached)]))
    
    }
    
    ResultsMatrix['Outlier Members','Enrolled'] <- length(unique(memberMonthDataset$SavvyHICN[(memberMonthDataset$Top5_Prcnt == 1 & memberMonthDataset$Enrolled)]))
    ResultsMatrix['Outlier Members','Not Enrolled'] <- length(unique(memberMonthDataset$SavvyHICN[(memberMonthDataset$Top5_Prcnt == 1 & memberMonthDataset$NotEnrolled)]))
    
    ResultsMatrix['Outlier Members','Registered'] <- length(unique(memberMonthDataset$SavvyHICN[(memberMonthDataset$Top5_Prcnt == 1 & memberMonthDataset$Registered)]))
    ResultsMatrix['Outlier Members','Not Registered'] <- length(unique(memberMonthDataset$SavvyHICN[(memberMonthDataset$Top5_Prcnt == 1 & memberMonthDataset$NotRegistered)]))
    

    ############### Apply outlier filter and use resulting data set for remaining calculations ##############
    
    memberMonthDataset <- filter(memberMonthDataset, Top5_Prcnt == 0)

    ResultsMatrix <- Count_IDs(RowName = 'Filtered Members', VarName = 'SavvyHICN')

  }     
  
  
  #################################################################
  #    After filtering, create additional data sets used below    #
  #################################################################
  
  
  ## Tenure data set ##
  
  Life_IDs <- memberMonthDataset[!duplicated(memberMonthDataset$Life_ID), ] %>% 
    dplyr::select(Life_ID, Reached, NotReached, Enrolled, NotEnrolled, Registered, NotRegistered)
  
  tenure <- merge(Life_IDs, tenureDataset, by = "Life_ID")
  
  tenure <- tenure %>% dplyr::rename(SavvyHICN = Life_ID)  # Note:  This is a kludge, so that the Test_Diff function works with this data set.
  
  ## Subset of data for which values do not vary by month ##
  
  constant <- memberMonthDataset %>%
    dplyr::select(SavvyHICN, Total_MM:NotRegistered)    # Note:  RAF varies by year, but only gets summarized if only one year is selected, and that filter has already been applied.
  
  constant <- constant[!duplicated(constant$SavvyHICN),]
  
  ## Males and Females ##
  
  males <- memberMonthDataset[memberMonthDataset$Gdr_Cd == "M",]
  females <- memberMonthDataset[memberMonthDataset$Gdr_Cd == "F",]
  
  
  #################################################
  #    Add in Total Revenue, Cost and MLI Value   #
  #################################################
  
  CurrentData <- memberMonthDataset
  
  ResultsMatrix <- AggValues(RowName = 'Aggregate Total Revenue', VarName = 'Total_Revenue')
  ResultsMatrix <- AggValues(RowName = 'Aggregate Total Cost', VarName = 'Total_Cost')
  ResultsMatrix <- AggValues(RowName = 'Aggregate MLI Value', VarName = 'Total_Value')
  ResultsMatrix <- AggValues(RowName = 'Total Member Months', VarName = 'MM')
  
  
  ####################################################
  #             Add in PMPM Values                   #
  ####################################################
  
 
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MLI', VarName = 'Total_Value', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MA Amount', VarName = 'Total_MA_Amt', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM D Amount', VarName = 'Total_D_Amt', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM Premium C Amount', VarName = 'Premium_C_Amt', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM Premium D Amount', VarName = 'Premium_D_Amt', Test = F)

  if(rxRebate != 'None')
    ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM Rx Rebate Amount', VarName = 'Rx_Rebate_Amt', Test = F)

  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM Total Revenue', VarName = 'Total_Revenue', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MA Derived IP Cost', VarName = 'Total_MA_Derived_IP_Cost', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MA Derived OP Cost', VarName = 'Total_MA_Derived_OP_Cost', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MA Derived DR Cost', VarName = 'Total_MA_Derived_DR_Cost', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MA Derived ER Cost', VarName = 'Total_MA_Derived_ER_Cost', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MA Derived DME Cost', VarName = 'Total_MA_Derived_DME_Cost', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM D Cost', VarName = 'Total_D_Cost', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM Total Cost', VarName = 'Total_Cost', Test = F)
  
  
  ######################################################################################
  #  Add tenure information using 'constant' and 'tenure' datasets created above #
  ######################################################################################
  
  if(Yr != 'All') {             # Calculate median and mean months in the current data set using 'constant' data set
    
    CurrentData <- constant
  
    ResultsMatrix <- MedianValues(RowName = 'Median Number of Months', VarName = 'Total_MM', Test = F)
    ResultsMatrix <- MeanValues(RowName = 'Mean Number of Months', VarName = 'Total_MM', Test = F)
  
  }
  
  # Overall tenure, median and mean #
  
  CurrentData <- tenure
  
  ResultsMatrix <- MedianValues(RowName = 'Median Tenure (in months)', VarName = 'MM', Test = F)
  ResultsMatrix <- MeanValues(RowName = 'Mean Tenure (in months)', VarName = 'MM', Test = F)

  
  ########################################
  #           Males and Females          #
  ########################################
  
  
  ResultsMatrix <- Gender_Props(RowName = 'Proportion of Males', Gender = 'M')
  
  CurrentData <- males
  
  ResultsMatrix <- AggValues(RowName = 'Aggregate MLI Value of Males', VarName = 'Total_Value')
  ResultsMatrix <- AggValues(RowName = 'Total Member Months of Males', VarName = 'MM')
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MLI of Males', VarName = 'Total_Value', Test = F)
  
  
  ResultsMatrix <- Gender_Props(RowName = 'Proportion of Females', Gender = 'F')
  
  CurrentData <- females
  
  ResultsMatrix <- AggValues(RowName = 'Aggregate MLI Value of Females', VarName = 'Total_Value')
  ResultsMatrix <- AggValues(RowName = 'Total Member Months of Females', VarName = 'MM')
  ResultsMatrix <- MeanValues(RowName = 'Aggregate PMPM MLI of Females', VarName = 'Total_Value', Test = T)
  
  
  ######################
  #       Ages         #
  ######################
  
  CurrentData <- constant
  
  ResultsMatrix <- MedianValues(RowName = 'Median Age', VarName = 'Age', Test = T)
  ResultsMatrix <- MeanValues(RowName = 'Mean Age', VarName = 'Age', Test = T)
  
  ##################################################################
  #  For Lifetime Value pilot, proportions of Arizona and PBP 036  #
  ##################################################################
  
  if(pilotType != '2016') {
    
    # Arizona
    
    Total_IDs <- length(unique(constant$SavvyHICN))
    Total_AZ <- length(unique(constant$SavvyHICN[constant$St_Cd == "AZ"]))
    Total_Prop <- Total_AZ / Total_IDs
    
    Reached_IDs <- length(unique(constant$SavvyHICN[constant$Reached]))
    Reached_AZ <- length(unique(constant$SavvyHICN[(constant$St_Cd == "AZ" & constant$Reached)]))
    Reached_Prop <- Reached_AZ / Reached_IDs
    
    NotReached_IDs <- length(unique(constant$SavvyHICN[constant$NotReached]))
    NotReached_AZ <- length(unique(constant$SavvyHICN[(constant$St_Cd == "AZ" & constant$NotReached)]))
    NotReached_Prop <- NotReached_AZ / NotReached_IDs
      
    
    Enrolled_IDs <- length(unique(constant$SavvyHICN[constant$Enrolled]))
    Enrolled_AZ <- length(unique(constant$SavvyHICN[(constant$St_Cd == "AZ" & constant$Enrolled)]))
    Enrolled_Prop <- Enrolled_AZ / Enrolled_IDs
    
    NotEnrolled_IDs <- length(unique(constant$SavvyHICN[constant$NotEnrolled]))
    NotEnrolled_AZ <- length(unique(constant$SavvyHICN[(constant$St_Cd == "AZ" & constant$NotEnrolled)]))
    NotEnrolled_Prop <- NotEnrolled_AZ / NotEnrolled_IDs
    
    Registered_IDs <- length(unique(constant$SavvyHICN[constant$Registered]))
    Registered_AZ <- length(unique(constant$SavvyHICN[(constant$St_Cd == "AZ" & constant$Registered)]))
    Registered_Prop <- Registered_AZ / Registered_IDs
    
    NotRegistered_IDs <- length(unique(constant$SavvyHICN[constant$NotRegistered]))
    NotRegistered_AZ <- length(unique(constant$SavvyHICN[(constant$St_Cd == "AZ" & constant$NotRegistered)]))
    NotRegistered_Prop <- NotRegistered_AZ / NotRegistered_IDs
    
    
    ResultsMatrix['Proportion of AZ','Total Population'] <- Total_Prop
      
    ResultsMatrix['Proportion of AZ','Reached'] <- Reached_Prop
    ResultsMatrix['Proportion of AZ','Not Reached'] <- NotReached_Prop
    ResultsMatrix['Proportion of AZ','Reached-Not Reached p-value'] <- prop.test(c(Reached_AZ, NotReached_AZ), c(Reached_IDs, NotReached_IDs))$p.value
    
    ResultsMatrix['Proportion of AZ','Enrolled'] <- Enrolled_Prop
    ResultsMatrix['Proportion of AZ','Not Enrolled'] <- NotEnrolled_Prop
    ResultsMatrix['Proportion of AZ','Enrolled-Not Enrolled p-value'] <- prop.test(c(Enrolled_AZ, NotEnrolled_AZ), c(Enrolled_IDs, NotEnrolled_IDs))$p.value
    
    ResultsMatrix['Proportion of AZ','Registered'] <- Registered_Prop
    ResultsMatrix['Proportion of AZ','Not Registered'] <- NotRegistered_Prop
    ResultsMatrix['Proportion of AZ','Registered-Not Registered p-value'] <- prop.test(c(Registered_AZ, NotRegistered_AZ), c(Registered_IDs, NotRegistered_IDs))$p.value
    
    
    # PBP 036
    
    Total_IDs <- length(unique(constant$SavvyHICN))
    Total_036 <- length(unique(constant$SavvyHICN[constant$PBP == 36]))
    Total_Prop <- Total_036 / Total_IDs
      
    Reached_IDs <- length(unique(constant$SavvyHICN[constant$Reached]))
    Reached_036 <- length(unique(constant$SavvyHICN[(constant$PBP == 36 & constant$Reached)]))
    Reached_Prop <- Reached_036 / Reached_IDs
    
    NotReached_IDs <- length(unique(constant$SavvyHICN[constant$NotReached]))
    NotReached_036 <- length(unique(constant$SavvyHICN[(constant$PBP == 36 & constant$NotReached)]))
    NotReached_Prop <- NotReached_036 / NotReached_IDs

    Enrolled_IDs <- length(unique(constant$SavvyHICN[constant$Enrolled]))
    Enrolled_036 <- length(unique(constant$SavvyHICN[(constant$PBP == 36 & constant$Enrolled)]))
    Enrolled_Prop <- Enrolled_036 / Enrolled_IDs
    
    NotEnrolled_IDs <- length(unique(constant$SavvyHICN[constant$NotEnrolled]))
    NotEnrolled_036 <- length(unique(constant$SavvyHICN[(constant$PBP == 36 & constant$NotEnrolled)]))
    NotEnrolled_Prop <- NotEnrolled_036 / NotEnrolled_IDs
    
    Registered_IDs <- length(unique(constant$SavvyHICN[constant$Registered]))
    Registered_036 <- length(unique(constant$SavvyHICN[(constant$PBP == 36 & constant$Registered)]))
    Registered_Prop <- Registered_036 / Registered_IDs
    
    NotRegistered_IDs <- length(unique(constant$SavvyHICN[constant$NotRegistered]))
    NotRegistered_036 <- length(unique(constant$SavvyHICN[(constant$PBP == 36 & constant$NotRegistered)]))
    NotRegistered_Prop <- NotRegistered_036 / NotRegistered_IDs
    
    
    ResultsMatrix['Proportion of 036','Total Population'] <- Total_Prop
    
    ResultsMatrix['Proportion of 036','Reached'] <- Reached_Prop
    ResultsMatrix['Proportion of 036','Not Reached'] <- NotReached_Prop
    ResultsMatrix['Proportion of 036','Reached-Not Reached p-value'] <- prop.test(c(Reached_036, NotReached_036), c(Reached_IDs, NotReached_IDs))$p.value
      
    ResultsMatrix['Proportion of 036','Enrolled'] <- Enrolled_Prop
    ResultsMatrix['Proportion of 036','Not Enrolled'] <- NotEnrolled_Prop
    ResultsMatrix['Proportion of 036','Enrolled-Not Enrolled p-value'] <- prop.test(c(Enrolled_036, NotEnrolled_036), c(Enrolled_IDs, NotEnrolled_IDs))$p.value
    
    ResultsMatrix['Proportion of 036','Registered'] <- Registered_Prop
    ResultsMatrix['Proportion of 036','Not Registered'] <- NotRegistered_Prop
    ResultsMatrix['Proportion of 036','Registered-Not Registered p-value'] <- prop.test(c(Registered_036, NotRegistered_036), c(Registered_IDs, NotRegistered_IDs))$p.value
    
  }
  
  #######################
  #       ADIs          #
  #######################
  
  CurrentData <- constant
  
  ResultsMatrix <- MeanValues(RowName = 'Mean ADI', VarName = 'ADI', Test = T)
  
  
  ######################
  #     RAFs           #
  ######################
  
  if(Yr != 'All') {
    
    ResultsMatrix <- MedianValues(RowName = 'Median RAF', VarName = 'RAFMMR', Test = T)
    ResultsMatrix <- MeanValues(RowName = 'Mean RAF', VarName = 'RAFMMR', Test = T)
    
    CurrentData <- constant[constant$Gdr_Cd == 'M', ]
    
    ResultsMatrix <- MedianValues(RowName = 'Median RAF of Males', VarName = 'RAFMMR', Test = T)
    ResultsMatrix <- MeanValues(RowName = 'Mean RAF of Males', VarName = 'RAFMMR', Test = T)
    
    CurrentData <- constant[constant$Gdr_Cd == 'F', ]
    
    ResultsMatrix <- MedianValues(RowName = 'Median RAF of Females', VarName = 'RAFMMR', Test = T)
    ResultsMatrix <- MeanValues(RowName = 'Mean RAF of Females', VarName = 'RAFMMR', Test = T)
    
  }
  
  
  return(ResultsMatrix)
}
