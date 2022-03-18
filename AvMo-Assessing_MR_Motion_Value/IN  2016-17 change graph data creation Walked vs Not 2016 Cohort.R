# Generating confidence intervals for 2016-17 Change, Indiana Pilot, by Walked, for 2016 cohort

# April 2018, Steve Smela, Savvysherpa

if(!exists("All2016Pilot")) load("All2016Pilot.rda")

temp2016_15 <- All2016Pilot %>% 
  filter(Year == 2015) %>% 
  group_by(SavvyHICN) %>%
  summarise()


IN2016 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2016, State = "IN", RemoveDeaths = T)
IN2017 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2017, State = "IN", RemoveDeaths = T)

IN2016_16 <- IN2016[!(IN2016$SavvyHICN %in% temp2016_15$SavvyHICN), ] 
IN2017_16 <- IN2017[!(IN2017$SavvyHICN %in% temp2016_15$SavvyHICN), ]

PMPMChangeWalk16 <- matrix(nrow = 4, ncol = 11)

colnames(PMPMChangeWalk16) <- c("Year", "Walked", "Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

PMPMChangeWalk16[1:2,1] <- 2016
PMPMChangeWalk16[3:4,1] <- 2017

PMPMChangeWalk16[c(1,3), 2] <- "Yes"
PMPMChangeWalk16[c(2,4), 2] <- "No"

### 2016,Walked ####

PMPMChangeWalk16[1, "Rev"] <- sum(IN2016_16$Total_Revenue[IN2016_16$Registered == T]) / length(IN2016_16$SavvyHICN[IN2016_16$Registered == T])
PMPMChangeWalk16[1, "Cost"] <- sum(IN2016_16$Total_Cost[IN2016_16$Registered == T]) / length(IN2016_16$SavvyHICN[IN2016_16$Registered == T])
PMPMChangeWalk16[1, "Val"] <- sum(IN2016_16$Total_Value[IN2016_16$Registered == T]) / length(IN2016_16$SavvyHICN[IN2016_16$Registered == T])

IN2016_16_Walk <- bootstrapCIs3Vars(Data = IN2016_16, Reps = 500, Group = "Registered")

PMPMChangeWalk16[1, "Rev_L"] <- IN2016_16_Walk[1]
PMPMChangeWalk16[1, "Rev_U"] <- IN2016_16_Walk[2]

PMPMChangeWalk16[1, "Cost_L"] <- IN2016_16_Walk[3]
PMPMChangeWalk16[1, "Cost_U"] <- IN2016_16_Walk[4]

PMPMChangeWalk16[1, "Val_L"] <- IN2016_16_Walk[5]
PMPMChangeWalk16[1, "Val_U"] <- IN2016_16_Walk[6]

save(PMPMChangeWalk16, file = "PMPMChangeWalk16.rda")

### 2016, NotWalked ###

PMPMChangeWalk16[2, "Rev"] <- sum(IN2016_16$Total_Revenue[IN2016_16$NotRegistered == T]) / length(IN2016_16$SavvyHICN[IN2016_16$NotRegistered == T])
PMPMChangeWalk16[2, "Cost"] <- sum(IN2016_16$Total_Cost[IN2016_16$NotRegistered == T]) / length(IN2016_16$SavvyHICN[IN2016_16$NotRegistered == T])
PMPMChangeWalk16[2, "Val"] <- sum(IN2016_16$Total_Value[IN2016_16$NotRegistered == T]) / length(IN2016_16$SavvyHICN[IN2016_16$NotRegistered == T])

IN2016_16_NotWalk <- bootstrapCIs3Vars(Data = IN2016_16, Reps = 500, Group = "NotRegistered")

PMPMChangeWalk16[2, "Rev_L"] <- IN2016_16_NotWalk[1]
PMPMChangeWalk16[2, "Rev_U"] <- IN2016_16_NotWalk[2]

PMPMChangeWalk16[2, "Cost_L"] <- IN2016_16_NotWalk[3]
PMPMChangeWalk16[2, "Cost_U"] <- IN2016_16_NotWalk[4]

PMPMChangeWalk16[2, "Val_L"] <- IN2016_16_NotWalk[5]
PMPMChangeWalk16[2, "Val_U"] <- IN2016_16_NotWalk[6]

save(PMPMChangeWalk16, file = "PMPMChangeWalk16.rda")

### 2017,Walked ####

PMPMChangeWalk16[3, "Rev"] <- sum(IN2017_16$Total_Revenue[IN2017_16$Registered == T]) / length(IN2017_16$SavvyHICN[IN2017_16$Registered == T])
PMPMChangeWalk16[3, "Cost"] <- sum(IN2017_16$Total_Cost[IN2017_16$Registered == T]) / length(IN2017_16$SavvyHICN[IN2017_16$Registered == T])
PMPMChangeWalk16[3, "Val"] <- sum(IN2017_16$Total_Value[IN2017_16$Registered == T]) / length(IN2017_16$SavvyHICN[IN2017_16$Registered == T])

IN2017_16_Walk <- bootstrapCIs3Vars(Data = IN2016_16, Reps = 500, Group = "Registered")

PMPMChangeWalk16[3, "Rev_L"] <- IN2017_16_Walk[1]
PMPMChangeWalk16[3, "Rev_U"] <- IN2017_16_Walk[2]

PMPMChangeWalk16[3, "Cost_L"] <- IN2017_16_Walk[3]
PMPMChangeWalk16[3, "Cost_U"] <- IN2017_16_Walk[4]

PMPMChangeWalk16[3, "Val_L"] <- IN2017_16_Walk[5]
PMPMChangeWalk16[3, "Val_U"] <- IN2017_16_Walk[6]

save(PMPMChangeWalk16, file = "PMPMChangeWalk16.rda")

### 2017, NotWalked ###

PMPMChangeWalk16[4, "Rev"] <- sum(IN2017_16$Total_Revenue[IN2017_16$NotRegistered == T]) / length(IN2017_16$SavvyHICN[IN2017_16$NotRegistered == T])
PMPMChangeWalk16[4, "Cost"] <- sum(IN2017_16$Total_Cost[IN2017_16$NotRegistered == T]) / length(IN2017_16$SavvyHICN[IN2017_16$NotRegistered == T])
PMPMChangeWalk16[4, "Val"] <- sum(IN2017_16$Total_Value[IN2017_16$NotRegistered == T]) / length(IN2017_16$SavvyHICN[IN2017_16$NotRegistered == T])

IN2017_16_NotWalk <- bootstrapCIs3Vars(Data = IN2017_16, Reps = 500, Group = "NotRegistered")

PMPMChangeWalk16[4, "Rev_L"] <- IN2017_16_NotWalk[1]
PMPMChangeWalk16[4, "Rev_U"] <- IN2017_16_NotWalk[2]

PMPMChangeWalk16[4, "Cost_L"] <- IN2017_16_NotWalk[3]
PMPMChangeWalk16[4, "Cost_U"] <- IN2017_16_NotWalk[4]

PMPMChangeWalk16[4, "Val_L"] <- IN2017_16_NotWalk[5]
PMPMChangeWalk16[4, "Val_U"] <- IN2017_16_NotWalk[6]

save(PMPMChangeWalk16, file = "PMPMChangeWalk16.rda")
