# Test_Diff.R

# December 22, 2017 (original date) and March 1, 2018 (current version)
# Steve Smela
# Savvysherpa


Test_Diff <- function(Data, VarName, FUN, Comparison, Reps = 2500) {
  
  "
  Provides a randomization test to compare two groups (given by 'Comparison') using the specified variable ('VarName')
  and function ('FUN').
  
  Comparison:  Options are 'Reached/Not Reached', 'Enrolled/Not Enrolled' and 'Registered/Not Registered'.
  
  FUN:  Options are 'mean' and 'median'.
  
  Reps: Number of times randomization is performed.
  
  "
  
  # Set up vector to store results from each randomization run
  Results = rep(NA, Reps)
  
  # Create subsets and store observed values depending on the comparison and function chosen
  
  if(Comparison == 'Reached/Not Reached') {
    
    Subset1 <- unique(Data[Data$Reached, 'SavvyHICN'])
    Subset2 <- unique(Data[Data$NotReached, 'SavvyHICN'])
    
    Values <- Data[(Data$Reached | Data$NotReached), c("SavvyHICN", VarName)]
    
    if(FUN == 'mean')
      ObservedValue <- mean(Data[Data$Reached, VarName], na.rm = T) - mean(Data[Data$NotReached, VarName], na.rm = T)
    
    else if (FUN == 'median')
      ObservedValue <- median(Data[Data$Reached, VarName], na.rm = T) - median(Data[Data$NotReached, VarName], na.rm = T)
    
  }
  else if(Comparison == 'Enrolled/Not Enrolled') {
    
    Subset1 <- unique(Data[Data$Enrolled, 'SavvyHICN'])
    Subset2 <- unique(Data[Data$NotEnrolled, 'SavvyHICN'])
    
    Values <- Data[(Data$Enrolled | Data$NotEnrolled), c("SavvyHICN", VarName)]
    
    if(FUN == 'mean')
      ObservedValue <- mean(Data[Data$Enrolled, VarName], na.rm = T) - mean(Data[Data$NotEnrolled, VarName], na.rm = T)
    
    else if (FUN == 'median')
      ObservedValue <- median(Data[Data$Enrolled, VarName], na.rm = T) - median(Data[Data$NotEnrolled, VarName], na.rm = T)
    
  }
  else if(Comparison == 'Registered/Not Registered') {
    
    Subset1 <- unique(Data[Data$Registered, 'SavvyHICN'])
    Subset2 <- unique(Data[Data$NotRegistered, 'SavvyHICN'])
    
    Values <- Data[(Data$Registered | Data$NotRegistered), c("SavvyHICN", VarName)]
    
    if(FUN == 'mean')
      ObservedValue <- mean(Data[Data$Registered, VarName], na.rm = T) - mean(Data[Data$NotRegistered, VarName], na.rm = T)
    
    else if (FUN == 'median')
      ObservedValue <- median(Data[Data$Registered, VarName], na.rm = T) - median(Data[Data$NotRegistered, VarName], na.rm = T)
    
  }
  
  print(VarName)
  print(ObservedValue)
  
  SavvyHICN <- c(Subset1, Subset2)     # Concatenate all of the IDs into one vector

  for(i in 1:Reps) {
    
    # Randomize order of IDs
    
    Rand <- runif(length(SavvyHICN))
    ID_List <- as.data.frame(cbind(SavvyHICN, Rand))
    ID_List <- ID_List %>% dplyr::arrange(Rand)
    
    Group1 <- ID_List[1:length(Subset1), "SavvyHICN"]                         # Take first bunch of IDs and assign them to Group 1
    Group2 <- ID_List[(length(Subset1) + 1):length(SavvyHICN), "SavvyHICN"]         # Take second bunch of IDs and assign them to Group 1
    
    NewDataSet <- mutate(Values, Group1 = Values$SavvyHICN %in% Group1)      # Create new data set based on random assignment to groups
    NewDataSet <- mutate(NewDataSet, Group2 = Values$SavvyHICN %in% Group2)
    
    # Calculate statistic of interest and store in results vector
    
#   mean(NewDataSet[NewDataSet$Group1 == 1, VarName], na.rm = T) -  mean(NewDataSet[NewDataSet$Group2 == 1, VarName], na.rm = T)
    
    if(FUN == 'mean')
      Results[i] <- mean(NewDataSet[NewDataSet$Group1 == 1, VarName], na.rm = T) -  mean(NewDataSet[NewDataSet$Group2 == 1, VarName], na.rm = T)
    
    else if(FUN == 'median')
      Results[i] <- median(NewDataSet[NewDataSet$Group1 == 1, VarName], na.rm = T) -  median(NewDataSet[NewDataSet$Group2 == 1, VarName], na.rm = T)
    
    if(i %% 500 == 0)
      print(c(i, "..."))
  }
  
  ### Summarize and return result ###
  
  ECDF <- ecdf(Results)  # Empirical cumulative density function
  p_val <- ECDF(ObservedValue)
  
  if(p_val < .5)
    p_val <- 2 * p_val           # Two-tailed test
  else
    p_val <- 2 * (1-p_val)
  
  return(p_val)
  
}