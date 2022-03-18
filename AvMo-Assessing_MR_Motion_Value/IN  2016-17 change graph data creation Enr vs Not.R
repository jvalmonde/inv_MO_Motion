# Generating confidence intervals for 2016-17 Change, Indiana Pilot, by Signed UP

# April 2018, Steve Smela, Savvysherpa

if(!exists("All2016Pilot")) load("All2016Pilot.rda")

IN2016 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2016, State = "IN", RemoveDeaths = T)
IN2017 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2017, State = "IN", RemoveDeaths = T)

PMPMChangeEnr <- matrix(nrow = 4, ncol = 11)

colnames(PMPMChangeEnr) <- c("Year", "Signed Up", "Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

PMPMChangeEnr[1:2,1] <- 2016
PMPMChangeEnr[3:4,1] <- 2017

PMPMChangeEnr[c(1,3), 2] <- "Yes"
PMPMChangeEnr[c(2,4), 2] <- "No"

### 2016, Enrolled ###

PMPMChangeEnr[1, "Rev"] <- sum(IN2016$Total_Revenue[IN2016$Enrolled == T]) / length(IN2016$SavvyHICN[IN2016$Enrolled == T])
PMPMChangeEnr[1, "Cost"] <- sum(IN2016$Total_Cost[IN2016$Enrolled == T]) / length(IN2016$SavvyHICN[IN2016$Enrolled == T])
PMPMChangeEnr[1, "Val"] <- sum(IN2016$Total_Value[IN2016$Enrolled == T]) / length(IN2016$SavvyHICN[IN2016$Enrolled == T])

IN2016_Enr_CIs <- bootstrapCIs3Vars(Data = IN2016, Group = "Enrolled", Reps = 500)

PMPMChangeEnr[1, "Rev_L"] <- IN2016_Enr_CIs[1]
PMPMChangeEnr[1, "Rev_U"] <- IN2016_Enr_CIs[2]

PMPMChangeEnr[1, "Cost_L"] <- IN2016_Enr_CIs[3]
PMPMChangeEnr[1, "Cost_U"] <- IN2016_Enr_CIs[4]

PMPMChangeEnr[1, "Val_L"] <- IN2016_Enr_CIs[5]
PMPMChangeEnr[1, "Val_U"] <- IN2016_Enr_CIs[6]

save(PMPMChangeEnr, file = "PMPMChangeEnr.rda")

### 2016, Not Enrolled ###

PMPMChangeEnr[2, "Rev"] <- sum(IN2016$Total_Revenue[IN2016$NotEnrolled == T]) / length(IN2016$SavvyHICN[IN2016$NotEnrolled == T])
PMPMChangeEnr[2, "Cost"] <- sum(IN2016$Total_Cost[IN2016$NotEnrolled == T]) / length(IN2016$SavvyHICN[IN2016$NotEnrolled == T])
PMPMChangeEnr[2, "Val"] <- sum(IN2016$Total_Value[IN2016$NotEnrolled == T]) / length(IN2016$SavvyHICN[IN2016$NotEnrolled == T])

# 2016 Not Enrolled values were previously calculated in "IN_CIs" (using 100 reps). Use them.

if(!exists("IN_CIs")) load("IN_CIs.rda")

PMPMChangeEnr[2, "Rev_L"] <- IN_CIs["Not Enrolled", "Rev_L"]
PMPMChangeEnr[2, "Rev_U"] <- IN_CIs["Not Enrolled", "Rev_U"]

PMPMChangeEnr[2, "Cost_L"] <- IN_CIs["Not Enrolled", "Cost_L"]
PMPMChangeEnr[2, "Cost_U"] <- IN_CIs["Not Enrolled", "Cost_U"]

PMPMChangeEnr[2, "Val_L"] <- IN_CIs["Not Enrolled", "Val_L"]
PMPMChangeEnr[2, "Val_U"] <- IN_CIs["Not Enrolled", "Val_U"]

save(PMPMChangeEnr, file = "PMPMChangeEnr.rda")

### 2017, Enrolled ####


PMPMChangeEnr[3, "Rev"] <- sum(IN2017$Total_Revenue[IN2017$Enrolled == T]) / length(IN2017$SavvyHICN[IN2017$Enrolled == T])
PMPMChangeEnr[3, "Cost"] <- sum(IN2017$Total_Cost[IN2017$Enrolled == T]) / length(IN2017$SavvyHICN[IN2017$Enrolled == T])
PMPMChangeEnr[3, "Val"] <- sum(IN2017$Total_Value[IN2017$Enrolled == T]) / length(IN2017$SavvyHICN[IN2017$Enrolled == T])

IN2017_Enr_CIs <- bootstrapCIs3Vars(Data = IN2017, Group = "Enrolled", Reps = 500)

PMPMChangeEnr[3, "Rev_L"] <- IN2017_Enr_CIs[1]
PMPMChangeEnr[3, "Rev_U"] <- IN2017_Enr_CIs[2]

PMPMChangeEnr[3, "Cost_L"] <- IN2017_Enr_CIs[3]
PMPMChangeEnr[3, "Cost_U"] <- IN2017_Enr_CIs[4]

PMPMChangeEnr[3, "Val_L"] <- IN2017_Enr_CIs[5]
PMPMChangeEnr[3, "Val_U"] <- IN2017_Enr_CIs[6]

save(PMPMChangeEnr, file = "PMPMChangeEnr.rda")

### 2017, Not Enrolled ###

PMPMChangeEnr[4, "Rev"] <- sum(IN2017$Total_Revenue[IN2017$NotEnrolled == T]) / length(IN2017$SavvyHICN[IN2017$NotEnrolled == T])
PMPMChangeEnr[4, "Cost"] <- sum(IN2017$Total_Cost[IN2017$NotEnrolled == T]) / length(IN2017$SavvyHICN[IN2017$NotEnrolled == T])
PMPMChangeEnr[4, "Val"] <- sum(IN2017$Total_Value[IN2017$NotEnrolled == T]) / length(IN2017$SavvyHICN[IN2017$NotEnrolled == T])


IN2017_NotEnr_CIs <- bootstrapCIs3Vars(Data = IN2017, Reps = 125, Group = "NotEnrolled")

PMPMChangeEnr[4, "Rev_L"] <- IN2017_NotEnr_CIs[1]
PMPMChangeEnr[4, "Rev_U"] <- IN2017_NotEnr_CIs[2]

PMPMChangeEnr[4, "Cost_L"] <- IN2017_NotEnr_CIs[3]
PMPMChangeEnr[4, "Cost_U"] <- IN2017_NotEnr_CIs[4]

PMPMChangeEnr[4, "Val_L"] <- IN2017_NotEnr_CIs[5]
PMPMChangeEnr[4, "Val_U"] <- IN2017_NotEnr_CIs[6]

save(PMPMChangeEnr, file = "PMPMChangeEnr.rda")
