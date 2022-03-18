# Generating confidence intervals for 2016-17 Change, Indiana Pilot, by Walked

# April 2018, Steve Smela, Savvysherpa

if(!exists("All2016Pilot")) load("All2016Pilot.rda")

IN2016 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2016, State = "IN", RemoveDeaths = T)
IN2017 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2017, State = "IN", RemoveDeaths = T)

PMPMChangeWalk <- matrix(nrow = 4, ncol = 11)

colnames(PMPMChangeWalk) <- c("Year", "Walked", "Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

PMPMChangeWalk[1:2,1] <- 2016
PMPMChangeWalk[3:4,1] <- 2017

PMPMChangeWalk[c(1,3), 2] <- "Yes"
PMPMChangeWalk[c(2,4), 2] <- "No"

### 2016,Walked ####

PMPMChangeWalk[1, "Rev"] <- sum(IN2016$Total_Revenue[IN2016$Registered == T]) / length(IN2016$SavvyHICN[IN2016$Registered == T])
PMPMChangeWalk[1, "Cost"] <- sum(IN2016$Total_Cost[IN2016$Registered == T]) / length(IN2016$SavvyHICN[IN2016$Registered == T])
PMPMChangeWalk[1, "Val"] <- sum(IN2016$Total_Value[IN2016$Registered == T]) / length(IN2016$SavvyHICN[IN2016$Registered == T])

IN2016_Walk <- bootstrapCIs3Vars(Data = IN2016, Group = "Registered", Reps = 500)

PMPMChangeWalk[1, "Rev_L"] <- IN2016_Walk[1]
PMPMChangeWalk[1, "Rev_U"] <- IN2016_Walk[2]

PMPMChangeWalk[1, "Cost_L"] <- IN2016_Walk[3]
PMPMChangeWalk[1, "Cost_U"] <- IN2016_Walk[4]

PMPMChangeWalk[1, "Val_L"] <- IN2016_Walk[5]
PMPMChangeWalk[1, "Val_U"] <- IN2016_Walk[6]

save(PMPMChangeWalk, file = "PMPMChangeWalk.rda")

### 2016, NotWalked ###

PMPMChangeWalk[2, "Rev"] <- sum(IN2016$Total_Revenue[IN2016$NotRegistered == T]) / length(IN2016$SavvyHICN[IN2016$NotRegistered == T])
PMPMChangeWalk[2, "Cost"] <- sum(IN2016$Total_Cost[IN2016$NotRegistered == T]) / length(IN2016$SavvyHICN[IN2016$NotRegistered == T])
PMPMChangeWalk[2, "Val"] <- sum(IN2016$Total_Value[IN2016$NotRegistered == T]) / length(IN2016$SavvyHICN[IN2016$NotRegistered == T])

IN2016_NotWalk <- bootstrapCIs3Vars(Data = IN2016, Group = "NotRegistered", Reps = 500)

PMPMChangeWalk[2, "Rev_L"] <- IN2016_NotWalk[1]
PMPMChangeWalk[2, "Rev_U"] <- IN2016_NotWalk[2]

PMPMChangeWalk[2, "Cost_L"] <- IN2016_NotWalk[3]
PMPMChangeWalk[2, "Cost_U"] <- IN2016_NotWalk[4]

PMPMChangeWalk[2, "Val_L"] <- IN2016_NotWalk[5]
PMPMChangeWalk[2, "Val_U"] <- IN2016_NotWalk[6]

save(PMPMChangeWalk, file = "PMPMChangeWalk.rda")

### 2017,Walked ####

PMPMChangeWalk[3, "Rev"] <- sum(IN2017$Total_Revenue[IN2017$Registered == T]) / length(IN2017$SavvyHICN[IN2017$Registered == T])
PMPMChangeWalk[3, "Cost"] <- sum(IN2017$Total_Cost[IN2017$Registered == T]) / length(IN2017$SavvyHICN[IN2017$Registered == T])
PMPMChangeWalk[3, "Val"] <- sum(IN2017$Total_Value[IN2017$Registered == T]) / length(IN2017$SavvyHICN[IN2017$Registered == T])

IN2017_Walk <- bootstrapCIs3Vars(Data = IN2017, Group = "Registered", Reps = 500)

PMPMChangeWalk[3, "Rev_L"] <- IN2017_Walk[1]
PMPMChangeWalk[3, "Rev_U"] <- IN2017_Walk[2]

PMPMChangeWalk[3, "Cost_L"] <- IN2017_Walk[3]
PMPMChangeWalk[3, "Cost_U"] <- IN2017_Walk[4]

PMPMChangeWalk[3, "Val_L"] <- IN2017_Walk[5]
PMPMChangeWalk[3, "Val_U"] <- IN2017_Walk[6]

save(PMPMChangeWalk, file = "PMPMChangeWalk.rda")

### 2017, NotWalked ###

PMPMChangeWalk[4, "Rev"] <- sum(IN2017$Total_Revenue[IN2017$NotRegistered == T]) / length(IN2017$SavvyHICN[IN2017$NotRegistered == T])
PMPMChangeWalk[4, "Cost"] <- sum(IN2017$Total_Cost[IN2017$NotRegistered == T]) / length(IN2017$SavvyHICN[IN2017$NotRegistered == T])
PMPMChangeWalk[4, "Val"] <- sum(IN2017$Total_Value[IN2017$NotRegistered == T]) / length(IN2017$SavvyHICN[IN2017$NotRegistered == T])

IN2017_NotWalk <- bootstrapCIs3Vars(Data = IN2017, Group = "NotRegistered", Reps = 500)

PMPMChangeWalk[4, "Rev_L"] <- IN2017_NotWalk[1]
PMPMChangeWalk[4, "Rev_U"] <- IN2017_NotWalk[2]

PMPMChangeWalk[4, "Cost_L"] <- IN2017_NotWalk[3]
PMPMChangeWalk[4, "Cost_U"] <- IN2017_NotWalk[4]

PMPMChangeWalk[4, "Val_L"] <- IN2017_NotWalk[5]
PMPMChangeWalk[4, "Val_U"] <- IN2017_NotWalk[6]

save(PMPMChangeWalk, file = "PMPMChangeWalk.rda")
