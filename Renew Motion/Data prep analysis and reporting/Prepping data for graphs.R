# Prepping data for graphs

# Steve Smela, Savvysherpa
# July-August, 2018

# Data prep is handled in "Round 2 NPS data prep."

# Three groups:  The "legit" Round 1 (group 1), Round 1 collected as people registered (group 2), and Round 2 (group 3)

# For the purposes of the Killer Questions, we'll just look at group 1 and group 3 (the "legit" scores).

# Because of duplications, I calculated NPS using the min and max values from a respondent in each round.  This didn't materially
# change NPS, but to be safe for all Round 1 / Round 2 comparisons I used the max Round 1 values and min Round 2 values.

library(tidyverse)

if(!exists("NPS")) load("NPS.rda")

table(NPS$Group, NPS$participant_flag)

# Response counts by treatment group

NPS %>% 
  summarise(Round1 = sum(is.na(Round1Min) == F),
            Round2 = sum(is.na(Round2Min) == F))

NPS %>% 
  group_by(Group, participant_flag) %>%
  summarise(Round1 = sum(is.na(Round1Min) == F),
            Round2 = sum(is.na(Round2Min) == F))

NPS %>% 
  group_by(participant_flag) %>%
  summarise(Round1 = sum(is.na(Round1MinGroup) == F),
            Round2 = sum(is.na(Round2MinGroup) == F))

#### Function to calculate NPS, do randomization tests, 2-sample version ###

NPSCalc <- function(Group1, Group2, test = T, reps = 10000) {
  
  Group1NPS = 100 * sum(Group1) / length(Group1)
  Group2NPS = 100 * sum(Group2) / length(Group2)
  
  NPSDiff <- Group2NPS - Group1NPS
  
  NPSGroups <- as.data.frame(c(Group1, Group2))
  names(NPSGroups) <- "NPSGroup"
  
  pval = NA
  
  # If test is requested
  
  if(test == T) {
  
    Results = matrix(nrow = reps, ncol = 1)
    
    for(i in 1:reps) {
    
      # Perform Randomization
      
      NPSGroups <- NPSGroups %>%
        mutate(RAND = runif(nrow(NPSGroups)),
               Group = 2) %>%
        arrange(RAND)
      
      NPSGroups$Group[1:length(Group1)] <- 1
      
      Rand1NPS <- NPSGroups %>% 
        filter(Group == 1) %>%
        summarise(NPS = 100 * sum(NPSGroup) / n())
      
      Rand2NPS <- NPSGroups %>% 
        filter(Group == 2) %>%
        summarise(NPS = 100 * sum(NPSGroup) / n())
      
      Results[i,1] <- as.numeric(Rand1NPS) - as.numeric(Rand2NPS)
      
    }
  
    ECDF <- ecdf(Results)
    pval <- 1 - ECDF(NPSDiff)
    
  }
  
  list(Group1NPS = Group1NPS, Group2NPS = Group2NPS, Diff = NPSDiff, pval = pval)
  
}

##########################


#### Function to calculate NPS, do randomization tests, paired version ###

NPSPaired <- function(Selection, test = T, reps = 10000) {
  
  Group1NPS = 100 * sum(Selection$Round1MaxGroup) / length(Selection$Round1MaxGroup)
  Group2NPS = 100 * sum(Selection$Round2MinGroup) / length(Selection$Round2MinGroup)
  
  NPSDiff <- Group2NPS - Group1NPS
  
  pval = NA
  
  # If test is requested
  
  if(test == T) {
    
    Results = matrix(nrow = reps, ncol = 1)
    
    for(i in 1:reps) {
      
      # Perform Randomization.  "Flip" scores between Round 1 and Round 2 randomly with a probability of .5, 
      # calculate NPS
      
      Selection <- Selection %>% 
        mutate(Rand = runif(n = dim(Selection)[1]),
               Round1 = ifelse(Rand < .5, Round1MaxGroup, Round2MinGroup),
               Round2 = ifelse(Rand < .5, Round2MinGroup, Round1MaxGroup)) %>%
        select(Rand, Round1MaxGroup, Round2MinGroup, Round1, Round2)
  
      
      Rand1NPS <- Selection %>% 
        summarise(NPS = 100 * sum(Round1) / n())
      
      Rand2NPS <- Selection %>% 
        summarise(NPS = 100 * sum(Round2) / n())
      
      Results[i,1] <- as.numeric(Rand1NPS) - as.numeric(Rand2NPS)
      
    }
    
    ECDF <- ecdf(Results)
    pval <- 1 - ECDF(NPSDiff)
    
  }
  
  list(Group1NPS = Group1NPS, Group2NPS = Group2NPS, Diff = NPSDiff, pval = pval)
  
}

##########################




################  Function to calculate confidence intevals on NPS #####

BS_CIs <- function(Selection, Reps = 10000) {
  
  Obs = length(Selection)
  
  Results <- matrix(nrow = Reps, ncol = 1)
  
  for(i in 1:Reps) {
    
    NPSData <- sample(Selection, size = Obs, replace = T)
    
    Promoters = 100 * sum(NPSData >= 9) / Obs
    Detractors = 100 * sum(NPSData <= 6) / Obs
    
    Results[i] <- Promoters - Detractors

  }
  
  return(quantile(Results, probs = c(.025, .975)))

}

#######

## First set of comparisions:  All Pre/Post, those for whom we have both scores Pre/Post

GenResults <- matrix(nrow = 4, ncol = 8)
colnames(GenResults) <- c("Group", "Name", "N", "Lower", "NPS", "Upper", "Diff", "PVal")

GenResults[,1] <- c(1,2,3,4)
GenResults[,2] <- c("All Pre", "All Post", "Both Pre", "Both Post")


## Round 1 vs Round 2 overall comparisons ##

Round1Max <-  NPS %>% 
  filter(is.na(Round1MinGroup) == F) %>%
  select(Round1Max, Round1MaxGroup)

Round2Min <- NPS %>% 
  filter(is.na(Round2MinGroup) == F) %>%
  select(Round2Min, Round2MinGroup)

GenResults[1,3] <- dim(Round1Max)[1]
GenResults[2,3] <- dim(Round2Min)[1]

Round1CIs <- BS_CIs(Selection = Round1Max$Round1Max)
Round2CIs <- BS_CIs(Selection = Round2Min$Round2Min)
Round1_vs_Round2 <- NPSCalc(Round1Max$Round1MaxGroup, Round2Min$Round2MinGroup, test = T) # Max from Round 1 vs. Min from Round 2

GenResults[1,4] <- round(Round1CIs[1], 1)
GenResults[1,5] <- round(Round1_vs_Round2$Group1NPS, 1)
GenResults[1,6] <- round(Round1CIs[2], 1)

GenResults[2,4] <- round(Round2CIs[1], 1)
GenResults[2,5] <- round(Round1_vs_Round2$Group2NPS, 1)
GenResults[2,6] <- round(Round2CIs[2], 1)

GenResults[2,7] <- round(Round1_vs_Round2$Diff, 1)
GenResults[2,8] <- round(Round1_vs_Round2$pval, 3)


### Round 1 vs Round2 where we have both scores from an individual ###

BothRounds <- NPS %>% filter(is.na(Round1MinGroup) == F & is.na(Round2MinGroup) == F)

BothMax1 <- BothRounds %>% select(Round1Max,Round1MaxGroup)
BothMin2 <- BothRounds %>% select(Round2Min, Round2MinGroup)

GenResults[3,3] <- dim(BothMax1)[1]
GenResults[4,3] <- dim(BothMin2)[1]

Both1CIs <- BS_CIs(Selection = BothMax1$Round1Max)
Both2CIs <- BS_CIs(Selection = BothMin2$Round2Min)
Both1_vs_2 <- NPSPaired(BothRounds, test = T)  # Max from Round 1 vs. Min from Round 2

GenResults[3,4] <- round(Both1CIs[1], 1)
GenResults[3,5] <- round(Both1_vs_2$Group1NPS, 1)
GenResults[3,6] <- round(Both1CIs[2], 1)

GenResults[4,4] <- round(Both2CIs[1], 1)
GenResults[4,5] <- round(Both1_vs_2$Group2NPS, 1)
GenResults[4,6] <- round(Both2CIs[2], 1)

GenResults[4,7] <- round(Both1_vs_2$Diff, 1)
GenResults[4,8] <- round(Both1_vs_2$pval, 3)



## Next set of comparisons:  By control/treatment groups

TrtGrps <- matrix(nrow = 10, ncol = 8)
colnames(TrtGrps) <- c("Group", "Name", "N", "Lower", "NPS", "Upper", "Diff", "PVal")

TrtGrps[,1] <- seq(1:10)
TrtGrps[,2] <- c("Control Pre", "Control Post", "Survey Pre", "Survey Post",
                    "Bonus Pre", "Bonus Post", "Bonus + Screening Pre", "Bonus + Screening Post",
                    "Screening Pre", "Screening Post")



### Round 1 vs. Round 2 for the Control group

Control1Max <- NPS %>%  
  filter(is.na(Round1MaxGroup) == F,
         Group == "Control (Survey)") %>%
  select(Round1Max, Round1MaxGroup)

Control2Min <- NPS %>%  
  filter(is.na(Round2MinGroup) == F,
         Group == "Control (Survey)") %>%
  select(Round2Min, Round2MinGroup)

TrtGrps[1,3] <- dim(Control1Max)[1]
TrtGrps[2,3] <- dim(Control2Min)[1]

Control1CIs <- BS_CIs(Selection = Control1Max$Round1Max)
Control2CIs <- BS_CIs(Selection = Control2Min$Round2Min)
Control1_vs_2 <- NPSCalc(Control1Max$Round1MaxGroup, Control2Min$Round2MinGroup, test = T)

TrtGrps[1,4] <- round(Control1CIs[1], 1)
TrtGrps[1,5] <- round(Control1_vs_2$Group1NPS, 1)
TrtGrps[1,6] <- round(Control1CIs[2], 1)

TrtGrps[2,4] <- round(Control2CIs[1], 1)
TrtGrps[2,5] <- round(Control1_vs_2$Group2NPS, 1)
TrtGrps[2,6] <- round(Control2CIs[2], 1)

TrtGrps[2,7] <- round(Control1_vs_2$Diff, 1)
TrtGrps[2,8] <- round(Control1_vs_2$pval, 3)




### Round 1 vs. Round 2 for the Survey group

Survey1Max <- NPS %>%  
  filter(is.na(Round1MaxGroup) == F,
         Group == "Survey") %>%
  select(Round1Max, Round1MaxGroup)

Survey2Min <- NPS %>%  
  filter(is.na(Round2MinGroup) == F,
         Group == "Survey") %>%
  select(Round2Min, Round2MinGroup)

TrtGrps[3,3] <- dim(Survey1Max)[1]
TrtGrps[4,3] <- dim(Survey2Min)[1]

Survey1CIs <- BS_CIs(Selection = Survey1Max$Round1Max)
Survey2CIs <- BS_CIs(Selection = Survey2Min$Round2Min)
Survey1_vs_2 <- NPSCalc(Survey1Max$Round1MaxGroup, Survey2Min$Round2MinGroup, test = T) 

TrtGrps[3,4] <- round(Survey1CIs[1], 1)
TrtGrps[3,5] <- round(Survey1_vs_2$Group1NPS, 1)
TrtGrps[3,6] <- round(Survey1CIs[2], 1)

TrtGrps[4,4] <- round(Survey2CIs[1], 1)
TrtGrps[4,5] <- round(Survey1_vs_2$Group2NPS, 1)
TrtGrps[4,6] <- round(Survey2CIs[2], 1)

TrtGrps[4,7] <- round(Survey1_vs_2$Diff, 1)
TrtGrps[4,8] <- round(Survey1_vs_2$pval, 3)






### Round 1 vs. Round 2 for the Bonus group

Bonus1Max <- NPS %>%  
  filter(is.na(Round1MaxGroup) == F,
         Group == "Survey + Bonus") %>%
  select(Round1Max, Round1MaxGroup)

Bonus2Min <- NPS %>%  
  filter(is.na(Round2MinGroup) == F,
         Group == "Survey + Bonus") %>%
  select(Round2Min, Round2MinGroup)

TrtGrps[5,3] <- dim(Bonus1Max)[1]
TrtGrps[6,3] <- dim(Bonus2Min)[1]

Bonus1CIs <- BS_CIs(Selection = Bonus1Max$Round1Max)
Bonus2CIs <- BS_CIs(Selection = Bonus2Min$Round2Min)
Bonus1_vs_2 <- NPSCalc(Bonus1Max$Round1MaxGroup, Bonus2Min$Round2MinGroup, test = T) 

TrtGrps[5,4] <- round(Bonus1CIs[1], 1)
TrtGrps[5,5] <- round(Bonus1_vs_2$Group1NPS, 1)
TrtGrps[5,6] <- round(Bonus1CIs[2], 1)

TrtGrps[6,4] <- round(Bonus2CIs[1], 1)
TrtGrps[6,5] <- round(Bonus1_vs_2$Group2NPS, 1)
TrtGrps[6,6] <- round(Bonus2CIs[2], 1)

TrtGrps[6,7] <- round(Bonus1_vs_2$Diff, 1)
TrtGrps[6,8] <- round(Bonus1_vs_2$pval, 3)




### Round 1 vs. Round 2 for the Bonus + Screening group

BonusScreen1Max <- NPS %>%  
  filter(is.na(Round1MaxGroup) == F,
         Group == "Survey + Bonus + Screening") %>%
  select(Round1Max, Round1MaxGroup)

BonusScreen2Min <- NPS %>%  
  filter(is.na(Round2MinGroup) == F,
         Group == "Survey + Bonus + Screening") %>%
  select(Round2Min, Round2MinGroup)

TrtGrps[7,3] <- dim(BonusScreen1Max)[1]
TrtGrps[8,3] <- dim(BonusScreen2Min)[1]

BonusScreen1CIs <- BS_CIs(Selection = BonusScreen1Max$Round1Max)
BonusScreen2CIs <- BS_CIs(Selection = BonusScreen2Min$Round2Min)
BonusScreen1_vs_2 <- NPSCalc(BonusScreen1Max$Round1MaxGroup, BonusScreen2Min$Round2MinGroup, test = T) 

TrtGrps[7,4] <- round(BonusScreen1CIs[1], 1)
TrtGrps[7,5] <- round(BonusScreen1_vs_2$Group1NPS, 1)
TrtGrps[7,6] <- round(BonusScreen1CIs[2], 1)

TrtGrps[8,4] <- round(BonusScreen2CIs[1], 1)
TrtGrps[8,5] <- round(BonusScreen1_vs_2$Group2NPS, 1)
TrtGrps[8,6] <- round(BonusScreen2CIs[2], 1)

TrtGrps[8,7] <- round(BonusScreen1_vs_2$Diff, 1)
TrtGrps[8,8] <- round(BonusScreen1_vs_2$pval, 3)



### Round 1 vs. Round 2 for the Screening group

Screen1Max <- NPS %>%  
  filter(is.na(Round1MaxGroup) == F,
         Group == "Survey + Screening") %>%
  select(Round1Max, Round1MaxGroup)

Screen2Min <- NPS %>%  
  filter(is.na(Round2MinGroup) == F,
         Group == "Survey + Screening") %>%
  select(Round2Min, Round2MinGroup)

TrtGrps[9,3] <- dim(Screen1Max)[1]
TrtGrps[10,3] <- dim(Screen2Min)[1]

Screen1CIs <- BS_CIs(Selection = Screen1Max$Round1Max)
Screen2CIs <- BS_CIs(Selection = Screen2Min$Round2Min)
Screen1_vs_2 <- NPSCalc(Screen1Max$Round1MaxGroup, Screen2Min$Round2MinGroup, test = T)

TrtGrps[9,4] <- round(Screen1CIs[1], 1)
TrtGrps[9,5] <- round(Screen1_vs_2$Group1NPS, 1)
TrtGrps[9,6] <- round(Screen1CIs[2], 1)

TrtGrps[10,4] <- round(Screen2CIs[1], 1)
TrtGrps[10,5] <- round(Screen1_vs_2$Group2NPS, 1)
TrtGrps[10,6] <- round(Screen2CIs[2], 1)

TrtGrps[10,7] <- round(Screen1_vs_2$Diff, 1)
TrtGrps[10,8] <- round(Screen1_vs_2$pval, 3)




##### Next set of comparisons:  Study participants ####

Participants <- NPS %>% filter(participant_flag == 1)

PartResults <- matrix(nrow = 6, ncol = 8)
colnames(PartResults) <- c("Group", "Name", "N", "Lower", "NPS", "Upper", "Diff", "PVal")

PartResults[,1] <- c(1,2,3,4,5,6)
PartResults[,2] <- c("All Pre", "All Post", "Walkers Pre", "Walkers Post",
                     "Non-Walkers Pre", "Non-Walkers Post")


## Round 1 vs Round 2 overall comparisons ##

Part1Max <-  Participants %>% 
  filter(is.na(Round1MinGroup) == F) %>%
  select(Round1Max, Round1MaxGroup)

Part2Min <- Participants %>% 
  filter(is.na(Round2MinGroup) == F) %>%
  select(Round2Min, Round2MinGroup)

PartResults[1,3] <- dim(Part1Max)[1]
PartResults[2,3] <- dim(Part2Min)[1]

Part1CIs <- BS_CIs(Selection = Part1Max$Round1Max)
Part2CIs <- BS_CIs(Selection = Part2Min$Round2Min)
Part1_vs_Part2 <- NPSCalc(Part1Max$Round1MaxGroup, Part2Min$Round2MinGroup, test = T) # Max from Round 1 vs. Min from Round 2

PartResults[1,4] <- round(Part1CIs[1], 1)
PartResults[1,5] <- round(Part1_vs_Part2$Group1NPS, 1)
PartResults[1,6] <- round(Part1CIs[2], 1)

PartResults[2,4] <- round(Part2CIs[1], 1)
PartResults[2,5] <- round(Part1_vs_Part2$Group2NPS, 1)
PartResults[2,6] <- round(Part2CIs[2], 1)

PartResults[2,7] <- round(Part1_vs_Part2$Diff, 1)
PartResults[2,8] <- round(Part1_vs_Part2$pval, 3)


# Round 1 vs. Round 2 for folks who recorded steps at any time #

Walkers1Max <-  Participants %>% 
  filter(is.na(Round1MinGroup) == F, Walker == 1) %>%
  select(Round1Max, Round1MaxGroup)

Walkers2Min <- Participants %>% 
  filter(is.na(Round2MinGroup) == F, Walker == 1) %>%
  select(Round2Min, Round2MinGroup)

PartResults[3,3] <- dim(Walkers1Max)[1]
PartResults[4,3] <- dim(Walkers2Min)[1]

Walkers1CIs <- BS_CIs(Selection = Walkers1Max$Round1Max)
Walkers2CIs <- BS_CIs(Selection = Walkers2Min$Round2Min)
Walkers1_vs_Walkers2 <- NPSCalc(Walkers1Max$Round1MaxGroup, Walkers2Min$Round2MinGroup, test = T) # Max from Round 1 vs. Min from Round 2

PartResults[3,4] <- round(Walkers1CIs[1], 1)
PartResults[3,5] <- round(Walkers1_vs_Walkers2$Group1NPS, 1)
PartResults[3,6] <- round(Walkers1CIs[2], 1)

PartResults[4,4] <- round(Walkers2CIs[1], 1)
PartResults[4,5] <- round(Walkers1_vs_Walkers2$Group2NPS, 1)
PartResults[4,6] <- round(Walkers2CIs[2], 1)

PartResults[4,7] <- round(Walkers1_vs_Walkers2$Diff, 1)
PartResults[4,8] <- round(Walkers1_vs_Walkers2$pval, 3)



# Round 1 vs. Round 2 for folks who have not recorded steps #

NonWalkers1Max <-  Participants %>% 
  filter(is.na(Round1MinGroup) == F, Walker == 0) %>%
  select(Round1Max, Round1MaxGroup)

NonWalkers2Min <- Participants %>% 
  filter(is.na(Round2MinGroup) == F, Walker == 0) %>%
  select(Round2Min, Round2MinGroup)

PartResults[5,3] <- dim(NonWalkers1Max)[1]
PartResults[6,3] <- dim(NonWalkers2Min)[1]

NonWalkers1CIs <- BS_CIs(Selection = NonWalkers1Max$Round1Max)
NonWalkers2CIs <- BS_CIs(Selection = NonWalkers2Min$Round2Min)
NonWalkers1_vs_NonWalkers2 <- NPSCalc(NonWalkers1Max$Round1MaxGroup, NonWalkers2Min$Round2MinGroup, test = T) # Max from Round 1 vs. Min from Round 2

PartResults[5,4] <- round(NonWalkers1CIs[1], 1)
PartResults[5,5] <- round(NonWalkers1_vs_NonWalkers2$Group1NPS, 1)
PartResults[5,6] <- round(NonWalkers1CIs[2], 1)

PartResults[6,4] <- round(NonWalkers2CIs[1], 1)
PartResults[6,5] <- round(NonWalkers1_vs_NonWalkers2$Group2NPS, 1)
PartResults[6,6] <- round(NonWalkers2CIs[2], 1)

PartResults[6,7] <- round(NonWalkers1_vs_NonWalkers2$Diff, 1)
PartResults[6,8] <- round(NonWalkers1_vs_NonWalkers2$pval, 3)




### Round 1 vs Round2 where we have both scores from an individual ###

PartBothResults <- matrix(nrow = 6, ncol = 8)
colnames(PartBothResults) <- c("Group", "Name", "N", "Lower", "NPS", "Upper", "Diff", "PVal")

PartBothResults[,1] <- c(1,2,3,4,5,6)
PartBothResults[,2] <- c("All Pre", "All Post", "Walkers Pre", "Walkers Post",
                     "Non-Walkers Pre", "Non-Walkers Post")


PartBoth <- Participants %>% filter(is.na(Round1MinGroup) == F & is.na(Round2MinGroup) == F)
PartBoth <- PartBoth %>% replace_na(list(WalkFirst = 0))           # Folks who had missing step data did not walk before 2nd NPS call

PartBothMax1 <- PartBoth %>% select(Round1Max,Round1MaxGroup)
PartBothMin2 <- PartBoth %>% select(Round2Min, Round2MinGroup)

PartBothResults[1,3] <- dim(PartBothMax1)[1]
PartBothResults[2,3] <- dim(PartBothMin2)[1]

PartBoth1CIs <- BS_CIs(Selection = PartBothMax1$Round1Max)
PartBoth2CIs <- BS_CIs(Selection = PartBothMin2$Round2Min)
PartBoth1_vs_2 <- NPSPaired(PartBoth, test = T)  # Max from Round 1 vs. Min from Round 2

PartBothResults[1,4] <- round(PartBoth1CIs[1], 1)
PartBothResults[1,5] <- round(PartBoth1_vs_2$Group1NPS, 1)
PartBothResults[1,6] <- round(PartBoth1CIs[2], 1)

PartBothResults[2,4] <- round(PartBoth2CIs[1], 1)
PartBothResults[2,5] <- round(PartBoth1_vs_2$Group2NPS, 1)
PartBothResults[2,6] <- round(PartBoth2CIs[2], 1)

PartBothResults[2,7] <- round(PartBoth1_vs_2$Diff, 1)
PartBothResults[2,8] <- round(PartBoth1_vs_2$pval, 3)

### Round 1 vs Round2 where we have both scores from an individual and they walked before 2nd NPS call ###

BothWalkers <- PartBoth %>% filter(WalkFirst == 1)

BothWalkers1 <- PartBoth %>% filter(WalkFirst == 1) %>% select(Round1Max, Round1MaxGroup)
BothWalkers2 <- PartBoth %>% filter(WalkFirst == 1) %>% select(Round2Min, Round2MinGroup)

PartBothResults[3,3] <- dim(BothWalkers1)[1]
PartBothResults[4,3] <- dim(BothWalkers2)[1]

BothWalkers1CIs <- BS_CIs(Selection = BothWalkers1$Round1Max)
BothWalkers2CIs <- BS_CIs(Selection = BothWalkers2$Round2Min)
BothWalkers1_vs_2 <- NPSPaired(BothWalkers, test = T)  

PartBothResults[3,4] <- round(BothWalkers1CIs[1], 1)
PartBothResults[3,5] <- round(BothWalkers1_vs_2$Group1NPS, 1)
PartBothResults[3,6] <- round(BothWalkers1CIs[2], 1)

PartBothResults[4,4] <- round(BothWalkers2CIs[1], 1)
PartBothResults[4,5] <- round(BothWalkers1_vs_2$Group2NPS, 1)
PartBothResults[4,6] <- round(BothWalkers2CIs[2], 1)

PartBothResults[4,7] <- round(BothWalkers1_vs_2$Diff, 1)
PartBothResults[4,8] <- round(BothWalkers1_vs_2$pval, 3)



### Round 1 vs Round2 where we have both scores from an individual and they didn't walk before 2nd NPS call ###

BothNonWalkers <- PartBoth %>% filter(WalkFirst == 0)

BothNonWalkers1 <- PartBoth %>% filter(WalkFirst == 0) %>% select(Round1Max, Round1MaxGroup)
BothNonWalkers2 <- PartBoth %>% filter(WalkFirst == 0) %>% select(Round2Min, Round2MinGroup)

PartBothResults[5,3] <- dim(BothNonWalkers1)[1]
PartBothResults[6,3] <- dim(BothNonWalkers2)[1]

BothNonWalkers1CIs <- BS_CIs(Selection = BothNonWalkers1$Round1Max)
BothNonWalkers2CIs <- BS_CIs(Selection = BothNonWalkers2$Round2Min)
BothNonWalkers1_vs_2 <- NPSPaired(BothNonWalkers, test = T)  

PartBothResults[5,4] <- round(BothNonWalkers1CIs[1], 1)
PartBothResults[5,5] <- round(BothNonWalkers1_vs_2$Group1NPS, 1)
PartBothResults[5,6] <- round(BothNonWalkers1CIs[2], 1)

PartBothResults[6,4] <- round(BothNonWalkers2CIs[1], 1)
PartBothResults[6,5] <- round(BothNonWalkers1_vs_2$Group2NPS, 1)
PartBothResults[6,6] <- round(BothNonWalkers2CIs[2], 1)

PartBothResults[6,7] <- round(BothNonWalkers1_vs_2$Diff, 1)
PartBothResults[6,8] <- round(BothNonWalkers1_vs_2$pval, 3)


#############  Saving results for graphing #########

GenResults <- as.tibble(GenResults)
TrtGrps <- as.tibble(TrtGrps)
PartResults <- as.tibble(PartResults)
PartBothResults <- as.tibble(PartBothResults)

GenResults <- GenResults %>%
  mutate(Group = as.integer(Group),
         N = as.integer(N),
         Lower = as.numeric(Lower),
         NPS = as.numeric(NPS), 
         Upper = as.numeric(Upper),
         Diff = as.numeric(Diff),
         PVal = as.numeric(PVal))

GenResults$PrePost <- c(1,2,1,2)
GenResults$PrePost <- as.factor(GenResults$PrePost)
levels(GenResults$PrePost) <- c("Round 1", "Round 2")

save(GenResults, file = "GenResults.rda")

TrtGrps <- TrtGrps %>%
  mutate(Group = as.integer(Group),
         N = as.integer(N),
         Lower = as.numeric(Lower),
         NPS = as.numeric(NPS), 
         Upper = as.numeric(Upper),
         Diff = as.numeric(Diff),
         PVal = as.numeric(PVal))

TrtGrps$PrePost <- c(1,2,1,2,1,2,1,2,1,2)
TrtGrps$PrePost <- as.factor(TrtGrps$PrePost)
levels(TrtGrps$PrePost) <- c("Round 1", "Round 2")

save(TrtGrps, file = "TrtGrps.rda")

PartResults <- PartResults %>%
  mutate(Group = as.integer(Group),
         N = as.integer(N),
         Lower = as.numeric(Lower),
         NPS = as.numeric(NPS), 
         Upper = as.numeric(Upper),
         Diff = as.numeric(Diff),
         PVal = as.numeric(PVal))

PartResults$PrePost <- c(1,2,1,2,1,2)
PartResults$PrePost <- as.factor(PartResults$PrePost)
levels(PartResults$PrePost) <- c("Round 1", "Round 2")

save(PartResults, file = "PartResults.rda")

PartBothResults <- PartBothResults %>%
  mutate(Group = as.integer(Group),
         N = as.integer(N),
         Lower = as.numeric(Lower),
         NPS = as.numeric(NPS), 
         Upper = as.numeric(Upper),
         Diff = as.numeric(Diff),
         PVal = as.numeric(PVal))

PartBothResults$PrePost <- c(1,2,1,2,1,2)
PartBothResults$PrePost <- as.factor(PartBothResults$PrePost)
levels(PartBothResults$PrePost) <- c("Round 1", "Round 2")

save(PartBothResults, file = "PartBothResults.rda")
