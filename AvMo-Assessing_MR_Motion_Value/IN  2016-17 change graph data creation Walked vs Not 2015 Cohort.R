# Generating confidence intervals for 2016-17 ChangeWalk, Indiana Pilot, by Walked, for 2015 cohort

# April 2018, Steve Smela, Savvysherpa

# setwd("C:/Users/ssmela/Documents/AvMo/Final Code")

if(!exists("All2016Pilot")) load("All2016Pilot.rda")

temp2016_15 <- All2016Pilot %>% 
  filter(Year == 2015) %>% 
  group_by(SavvyHICN) %>%
  summarise()


IN2016 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2016, State = "IN", RemoveDeaths = T)
IN2017 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, Yr = 2017, State = "IN", RemoveDeaths = T)

# Find 2016 & 2017 data for 2015 cohort

IN2016_15 <- IN2016[IN2016$SavvyHICN %in% temp2016_15$SavvyHICN, ] 
IN2017_15 <- IN2017[IN2017$SavvyHICN %in% temp2016_15$SavvyHICN, ]

PMPMChangeWalk15 <- matrix(nrow = 4, ncol = 11)

colnames(PMPMChangeWalk15) <- c("Year", "Walked", "Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

PMPMChangeWalk15[1:2,1] <- 2016
PMPMChangeWalk15[3:4,1] <- 2017

PMPMChangeWalk15[c(1,3), 2] <- "Yes"
PMPMChangeWalk15[c(2,4), 2] <- "No"

### 2016,Walked ####


PMPMChangeWalk15[1, "Rev"] <- sum(IN2016_15$Total_Revenue[IN2016_15$Registered == T]) / length(IN2016_15$SavvyHICN[IN2016_15$Registered == T])
PMPMChangeWalk15[1, "Cost"] <- sum(IN2016_15$Total_Cost[IN2016_15$Registered == T]) / length(IN2016_15$SavvyHICN[IN2016_15$Registered == T])
PMPMChangeWalk15[1, "Val"] <- sum(IN2016_15$Total_Value[IN2016_15$Registered == T]) / length(IN2016_15$SavvyHICN[IN2016_15$Registered == T])

IN2016_15_Walk <- bootstrapCIs3Vars(Data = IN2016_15, Group = "Registered", Reps = 500)

PMPMChangeWalk15[1, "Rev_L"] <- IN2016_15_Walk[1]
PMPMChangeWalk15[1, "Rev_U"] <- IN2016_15_Walk[2]

PMPMChangeWalk15[1, "Cost_L"] <- IN2016_15_Walk[3]
PMPMChangeWalk15[1, "Cost_U"] <- IN2016_15_Walk[4]

PMPMChangeWalk15[1, "Val_L"] <- IN2016_15_Walk[5]
PMPMChangeWalk15[1, "Val_U"] <- IN2016_15_Walk[6]


### 2016, NotWalked ###

PMPMChangeWalk15[2, "Rev"] <- sum(IN2016_15$Total_Revenue[IN2016_15$NotRegistered == T]) / length(IN2016_15$SavvyHICN[IN2016_15$NotRegistered == T])
PMPMChangeWalk15[2, "Cost"] <- sum(IN2016_15$Total_Cost[IN2016_15$NotRegistered == T]) / length(IN2016_15$SavvyHICN[IN2016_15$NotRegistered == T])
PMPMChangeWalk15[2, "Val"] <- sum(IN2016_15$Total_Value[IN2016_15$NotRegistered == T]) / length(IN2016_15$SavvyHICN[IN2016_15$NotRegistered == T])

IN2016_15_NotWalk <- bootstrapCIs3Vars(Data = IN2016_15, Group = "NotRegistered", Reps = 500)

PMPMChangeWalk15[2, "Rev_L"] <- IN2016_15_NotWalk[1]
PMPMChangeWalk15[2, "Rev_U"] <- IN2016_15_NotWalk[2]

PMPMChangeWalk15[2, "Cost_L"] <- IN2016_15_NotWalk[3]
PMPMChangeWalk15[2, "Cost_U"] <- IN2016_15_NotWalk[4]

PMPMChangeWalk15[2, "Val_L"] <- IN2016_15_NotWalk[5]
PMPMChangeWalk15[2, "Val_U"] <- IN2016_15_NotWalk[6]

### 2017,Walked ####


PMPMChangeWalk15[3, "Rev"] <- sum(IN2017_15$Total_Revenue[IN2017_15$Registered == T]) / length(IN2017_15$SavvyHICN[IN2017_15$Registered == T])
PMPMChangeWalk15[3, "Cost"] <- sum(IN2017_15$Total_Cost[IN2017_15$Registered == T]) / length(IN2017_15$SavvyHICN[IN2017_15$Registered == T])
PMPMChangeWalk15[3, "Val"] <- sum(IN2017_15$Total_Value[IN2017_15$Registered == T]) / length(IN2017_15$SavvyHICN[IN2017_15$Registered == T])

IN2017_15_Walk <- bootstrapCIs3Vars(Data = IN2017_15, Group = "Registered", Reps = 500)

PMPMChangeWalk15[3, "Rev_L"] <- IN2017_15_Walk[1]
PMPMChangeWalk15[3, "Rev_U"] <- IN2017_15_Walk[2]

PMPMChangeWalk15[3, "Cost_L"] <- IN2017_15_Walk[3]
PMPMChangeWalk15[3, "Cost_U"] <- IN2017_15_Walk[4]

PMPMChangeWalk15[3, "Val_L"] <- IN2017_15_Walk[5]
PMPMChangeWalk15[3, "Val_U"] <- IN2017_15_Walk[6]

### 2017, NotWalked ###

PMPMChangeWalk15[4, "Rev"] <- sum(IN2017_15$Total_Revenue[IN2017_15$NotRegistered == T]) / length(IN2017_15$SavvyHICN[IN2017_15$NotRegistered == T])
PMPMChangeWalk15[4, "Cost"] <- sum(IN2017_15$Total_Cost[IN2017_15$NotRegistered == T]) / length(IN2017_15$SavvyHICN[IN2017_15$NotRegistered == T])
PMPMChangeWalk15[4, "Val"] <- sum(IN2017_15$Total_Value[IN2017_15$NotRegistered == T]) / length(IN2017_15$SavvyHICN[IN2017_15$NotRegistered == T])


IN2017_15_NotWalk <- bootstrapCIs3Vars(Data = IN2017_15, Group = "NotRegistered", Reps = 500)

PMPMChangeWalk15[4, "Rev_L"] <- IN2017_15_NotWalk[1]
PMPMChangeWalk15[4, "Rev_U"] <- IN2017_15_NotWalk[2]

PMPMChangeWalk15[4, "Cost_L"] <- IN2017_15_NotWalk[3]
PMPMChangeWalk15[4, "Cost_U"] <- IN2017_15_NotWalk[4]

PMPMChangeWalk15[4, "Val_L"] <- IN2017_15_NotWalk[5]
PMPMChangeWalk15[4, "Val_U"] <- IN2017_15_NotWalk[6]

save(PMPMChangeWalk15, file = "PMPMChangeWalk15.rda")
