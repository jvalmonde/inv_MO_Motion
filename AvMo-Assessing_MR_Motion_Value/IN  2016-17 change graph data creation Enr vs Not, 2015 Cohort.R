# Generating confidence intervals for 2016-17 Change, 2015 cohort, Indiana Pilot, by Signed UP

# April 2018, Steve Smela, Savvysherpa

# Find IDs that have data in 2016

if(!exists("All2016Pilot")) load("All2016Pilot.rda")

temp2016_15 <- All2016Pilot %>% 
  filter(Year == 2015) %>% 
  group_by(SavvyHICN) %>%
  summarise()

IN2016 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2016, State = "IN", RemoveDeaths = T)
IN2017 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2017, State = "IN", RemoveDeaths = T)

# Create data sets for 2016 and 2017 data for just the 2015 cohort

IN2016_15 <- IN2016[IN2016$SavvyHICN %in% temp2016_15$SavvyHICN, ]
IN2017_15 <- IN2017[IN2017$SavvyHICN %in% temp2016_15$SavvyHICN, ]

# Create matrix of results

PMPMChangeEnr15 <- matrix(nrow = 4, ncol = 11)

colnames(PMPMChangeEnr15) <- c("Year", "SignedUp", "Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

PMPMChangeEnr15[1:2,1] <- 2016
PMPMChangeEnr15[3:4,1] <- 2017

PMPMChangeEnr15[c(1,3), 2] <- "Yes"
PMPMChangeEnr15[c(2,4), 2] <- "No"


### 2016, Enrolled ####

PMPMChangeEnr15[1, "Rev"] <- sum(IN2016_15$Total_Revenue[IN2016_15$Enrolled == T]) / length(IN2016_15$SavvyHICN[IN2016_15$Enrolled == T])
PMPMChangeEnr15[1, "Cost"] <- sum(IN2016_15$Total_Cost[IN2016_15$Enrolled == T]) / length(IN2016_15$SavvyHICN[IN2016_15$Enrolled == T])
PMPMChangeEnr15[1, "Val"] <- sum(IN2016_15$Total_Value[IN2016_15$Enrolled == T]) / length(IN2016_15$SavvyHICN[IN2016_15$Enrolled == T])

IN2016_15_Enr <- bootstrapCIs3Vars(Data = IN2016_15, Reps = 500, Group = "Enrolled") 

PMPMChangeEnr15[1, "Rev_L"] <- IN2016_15_Enr[1]
PMPMChangeEnr15[1, "Rev_U"] <- IN2016_15_Enr[2]

PMPMChangeEnr15[1, "Cost_L"] <- IN2016_15_Enr[3]
PMPMChangeEnr15[1, "Cost_U"] <- IN2016_15_Enr[4]

PMPMChangeEnr15[1, "Val_L"] <- IN2016_15_Enr[5]
PMPMChangeEnr15[1, "Val_U"] <- IN2016_15_Enr[6]

save(PMPMChangeEnr15, file = "PMPMChangeEnr15.rda")

### 2016, Not Enrolled ###

PMPMChangeEnr15[2, "Rev"] <- sum(IN2016_15$Total_Revenue[IN2016_15$NotEnrolled == T]) / length(IN2016_15$SavvyHICN[IN2016_15$NotEnrolled == T])
PMPMChangeEnr15[2, "Cost"] <- sum(IN2016_15$Total_Cost[IN2016_15$NotEnrolled == T]) / length(IN2016_15$SavvyHICN[IN2016_15$NotEnrolled == T])
PMPMChangeEnr15[2, "Val"] <- sum(IN2016_15$Total_Value[IN2016_15$NotEnrolled == T]) / length(IN2016_15$SavvyHICN[IN2016_15$NotEnrolled == T])

IN2016_15_NotEnr <- bootstrapCIs3Vars(Data = IN2016_15, Reps = 200, Group = "NotEnrolled") 

PMPMChangeEnr15[2, "Rev_L"] <- IN2016_15_NotEnr[1]
PMPMChangeEnr15[2, "Rev_U"] <- IN2016_15_NotEnr[2]

PMPMChangeEnr15[2, "Cost_L"] <- IN2016_15_NotEnr[3]
PMPMChangeEnr15[2, "Cost_U"] <- IN2016_15_NotEnr[4]

PMPMChangeEnr15[2, "Val_L"] <- IN2016_15_NotEnr[5]
PMPMChangeEnr15[2, "Val_U"] <- IN2016_15_NotEnr[6]

save(PMPMChangeEnr15, file = "PMPMChangeEnr15.rda")

### 2017, Enrolled ####


PMPMChangeEnr15[3, "Rev"] <- sum(IN2017_15$Total_Revenue[IN2017_15$Enrolled == T]) / length(IN2017_15$SavvyHICN[IN2017_15$Enrolled == T])
PMPMChangeEnr15[3, "Cost"] <- sum(IN2017_15$Total_Cost[IN2017_15$Enrolled == T]) / length(IN2017_15$SavvyHICN[IN2017_15$Enrolled == T])
PMPMChangeEnr15[3, "Val"] <- sum(IN2017_15$Total_Value[IN2017_15$Enrolled == T]) / length(IN2017_15$SavvyHICN[IN2017_15$Enrolled == T])

IN2017_15_Enr <- bootstrapCIs3Vars(Data = IN2017_15, Reps = 500, Group = "Enrolled") 

PMPMChangeEnr15[3, "Rev_L"] <- IN2017_15_Enr[1]
PMPMChangeEnr15[3, "Rev_U"] <- IN2017_15_Enr[2]

PMPMChangeEnr15[3, "Cost_L"] <- IN2017_15_Enr[3]
PMPMChangeEnr15[3, "Cost_U"] <- IN2017_15_Enr[4]

PMPMChangeEnr15[3, "Val_L"] <- IN2017_15_Enr[5]
PMPMChangeEnr15[3, "Val_U"] <- IN2017_15_Enr[6]

### 2017, Not Enrolled ###

PMPMChangeEnr15[4, "Rev"] <- sum(IN2017_15$Total_Revenue[IN2017_15$NotEnrolled == T]) / length(IN2017_15$SavvyHICN[IN2017_15$NotEnrolled == T])
PMPMChangeEnr15[4, "Cost"] <- sum(IN2017_15$Total_Cost[IN2017_15$NotEnrolled == T]) / length(IN2017_15$SavvyHICN[IN2017_15$NotEnrolled == T])
PMPMChangeEnr15[4, "Val"] <- sum(IN2017_15$Total_Value[IN2017_15$NotEnrolled == T]) / length(IN2017_15$SavvyHICN[IN2017_15$NotEnrolled == T])


IN2017_15_NotEnr <- bootstrapCIs3Vars(Data = IN2017_15, Reps = 200, Group = "NotEnrolled") 

PMPMChangeEnr15[4, "Rev_L"] <- IN2017_15_NotEnr[1]
PMPMChangeEnr15[4, "Rev_U"] <- IN2017_15_NotEnr[2]

PMPMChangeEnr15[4, "Cost_L"] <- IN2017_15_NotEnr[3]
PMPMChangeEnr15[4, "Cost_U"] <- IN2017_15_NotEnr[4]

PMPMChangeEnr15[4, "Val_L"] <- IN2017_15_NotEnr[5]
PMPMChangeEnr15[4, "Val_U"] <- IN2017_15_NotEnr[6]

save(PMPMChangeEnr15, file = "PMPMChangeEnr15.rda")
