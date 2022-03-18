# Bootstrap Confidence Intervals Value, Revenue, Cost.R

# January 3, 2018
# Steve Smela, Savvysherpa

# April 12:  Now does three variables at a time (Revenue, Cost & Value)
# April 18:  Returns CIs instead of matrix of bootstrap estimates

bootstrapCIs3Vars <- function(Data = memberMonthDataset, Reps = 1000, Group = NULL, FUN = 'mean') {
  
  "
  Used for getting 95% confidence intervals for PMPM Revenue, Cost and Value for the Member Level Insights (MLI) 
  / Assessing the Value of Motion (AvMo) projects.

  Parameters:
  
    Data:  Data set to be used.  Default is the memberMonthDataset, created by running the filteredMemberMonth function
    
    Reps:  Number of bootstrap replications.    

    Group:  Subgroup for which confidence intervals are desired.  Options include 'Reached', 'NotReached', 'Enrolled', 'NotEnrolled',
      'Registered', 'NotRegistered'.

    FUN:  Options are 'mean' and 'median'.
  
  "
  
  # Create list of unique SavvyHICNs with corresponding group indicators
  
  SavvyList <- Data[ , c("SavvyHICN", "Reached", "NotReached", "Enrolled", "NotEnrolled", "Registered", "NotRegistered")]
  SavvyList <- SavvyList[!duplicated(SavvyList$SavvyHICN),]
  
  # Create subsets based on Group selected
  
  if(is.null(Group))
    Selection <- SavvyList[, "SavvyHICN"]
  
  else if(Group == 'Reached')
    Selection <- SavvyList[SavvyList$Reached, "SavvyHICN"]
  
  else if(Group == 'NotReached')
    Selection <- SavvyList[SavvyList$NotReached, "SavvyHICN"]
  
  else if(Group == 'Enrolled')
    Selection <- SavvyList[SavvyList$Enrolled, "SavvyHICN"]
  
  else if(Group == 'NotEnrolled')
    Selection <- SavvyList[SavvyList$NotEnrolled, "SavvyHICN"]
  
  else if(Group == 'Registered')
    Selection <- SavvyList[SavvyList$Registered, "SavvyHICN"]
  
  else if(Group == 'NotRegistered')
    Selection <- SavvyList[SavvyList$NotRegistered, "SavvyHICN"]
  

  
  Results <- matrix(nrow = Reps, ncol = 3, NA)                                      # Create vector to store results from bootstrap replications
  colnames(Results) <- c("Revenue", "Cost", "Value")
  SampleID = 0                        # Initialize
  
  for(i in 1:Reps) {                                            # Start bootstrap replications
    
    Sample = matrix(nrow = 1, ncol = 3)                                                # Starting value 
    colnames(Sample) <- c("Total_Revenue", "Total_Cost", "Total_Value")
    
    for(j in 1:length(Selection)) {                             # Bootstrap sample
      
      if(j %% 5000 == 0) print(j)
      
      SampleID <- sample(Selection, size = 1)                   # Sample with replacement
      
      Sample <- rbind(Sample, Data[Data$SavvyHICN == SampleID, c("Total_Revenue", "Total_Cost", "Total_Value")]) # Since # of obs per ID can be variable, need to add on to this as sample is taken
      
    }
    
    print(i)
    
    if(FUN == 'mean') {
      Results[i,1] <- mean(Sample[,1], na.rm = T)  # Ignore starting NA 
      Results[i,2] <- mean(Sample[,2], na.rm = T)
      Results[i,3] <- mean(Sample[,3], na.rm = T)
   
    }
    else if(FUN == 'median')
      Results[i] <- median(Sample, na.rm = T)                     # Ignore starting NA
    
  }
  
  Rev_L <- quantile(Results[, "Revenue"], probs = .025)
  Rev_U <- quantile(Results[, "Revenue"], probs = .975)
  
  Cost_L <- quantile(Results[, "Cost"], probs = .025)
  Cost_U <- quantile(Results[, "Cost"], probs = .975)
  
  Val_L <- quantile(Results[, "Value"], probs = .025)
  Val_U <- quantile(Results[, "Value"], probs = .975)
  
  CIs <- c(Rev_L, Rev_U, Cost_L, Cost_U, Val_L, Val_U)
  
  return(CIs)

}


