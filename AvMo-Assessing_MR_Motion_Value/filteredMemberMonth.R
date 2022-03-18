# filteredMemberMonth.R

# January 2, 2018
# Steve Smela, Savvysherpa

# Takes data created by the setupMemberMonth function and applies filters as in the consolidateResults function.
# Returns a memberMonthDataset, which can be used for estimating bootstrap confidence intervals.

# March 2, 2018:  Fixed problem where Yr = 'All' (moved line 127 inside 'if' statement)
# March 5, 2018:  Added option to filter out deceased members (will take out 12 months of data)
# March 26, 2018:  Added code for Top 5 % in 2017
# April 1, 2018:  Filtered out data post-September 2017.
# April 4, 2018:  Added code to filter by pilot type.
# April 18, 2018:  Made data end date a parameter

filteredMemberMonth <- function(pilotType = "Lifetime Value", Yr = "All", totalMM = NULL, rxRebate = "40%", removeOutliers = T, 
                               State = NULL, Data = NULL, RAF_Decile = NULL, RemoveDeaths = F, EndYearMo = 201709) {
  
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

      RemoveDeaths:  If True, data from 12 months up to and including month of disenrollment due to death will be excluded. Default is False.

      EndYearMo:  The last year and month for which data will be analyzed.  Currently (4/2018) is 9/2017.

  "
  
  ##############################################################
  # Use data passed as a parameter, or read in data if needed  #
  ##############################################################
  
  
  if(!is.null(Data))
    memberMonthDataset <- Data
  else
    memberMonthDataset <- setupMemberMonth(pilotType = pilotType, rxRebate = rxRebate)
  
  # Filter out data post-September 2017
  memberMonthDataset <- memberMonthDataset %>% filter(Year_Mo <= EndYearMo)
  
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
  
  
  ###############################################
  #            Filter outliers, if needed       #
  ###############################################
  
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
    
    memberMonthDataset <- filter(memberMonthDataset, Top5_Prcnt == 0)
    
  }
  
  ###############################################
  #    Filter deceased members, if needed       #
  ###############################################
  
  if(RemoveDeaths) {
    
    memberMonthDataset <- memberMonthDataset %>% replace_na(list(Death_Flag = 0)) %>%
      mutate(Prev12Months = Year_Mo > Disenroll_Year_Mo - 100 & Year_Mo <= Disenroll_Year_Mo) %>%
      filter(!(Prev12Months == TRUE & Death_Flag == 1)) 

  }
  
  return(memberMonthDataset)
  
}