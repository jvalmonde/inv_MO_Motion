# Calculates PMPM Value, Revenue and Cost, including confidence intervals, for 2017 Lifetime Value pilot, using 2017 data,
# by RAF decile

# April 2018, Steve Smela, Savvysherpa

if(!exists("All2017Pilot")) load("All2017Pilot.rda")

LTV_2017_RAF_deciles <- matrix(nrow = 10, ncol = 9)

rownames(LTV_2017_RAF_deciles) <- c("First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth")
colnames(LTV_2017_RAF_deciles) <- c("Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

LTV2017_1 <- filteredMemberMonth(pilotType = "Lifetime Value", RAF_Decile = 1, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["First", "Rev"] <- sum(LTV2017_1$Total_Revenue) / length(LTV2017_1$SavvyHICN)
LTV_2017_RAF_deciles["First", "Cost"] <- sum(LTV2017_1$Total_Cost) / length(LTV2017_1$SavvyHICN)
LTV_2017_RAF_deciles["First", "Val"] <- sum(LTV2017_1$Total_Value) / length(LTV2017_1$SavvyHICN)

LTV2017_1_CIs <- bootstrapCIs3Vars(Data = LTV2017_1, Reps = 200)

LTV_2017_RAF_deciles["First", "Rev_L"] <- LTV2017_1_CIs[1]
LTV_2017_RAF_deciles["First", "Rev_U"] <- LTV2017_1_CIs[2]

LTV_2017_RAF_deciles["First", "Cost_L"] <- LTV2017_1_CIs[3]
LTV_2017_RAF_deciles["First", "Cost_U"] <- LTV2017_1_CIs[4]

LTV_2017_RAF_deciles["First", "Val_L"] <- LTV2017_1_CIs[5]
LTV_2017_RAF_deciles["First", "Val_U"] <- LTV2017_1_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")

### Second Decile ###

LTV2017_2 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 2, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Second", "Rev"] <- sum(LTV2017_2$Total_Revenue) / length(LTV2017_2$SavvyHICN)
LTV_2017_RAF_deciles["Second", "Cost"] <- sum(LTV2017_2$Total_Cost) / length(LTV2017_2$SavvyHICN)
LTV_2017_RAF_deciles["Second", "Val"] <- sum(LTV2017_2$Total_Value) / length(LTV2017_2$SavvyHICN)

LTV2017_2_CIs <- bootstrapCIs3Vars(Data = LTV2017_2, Reps = 200)

LTV_2017_RAF_deciles["Second", "Rev_L"] <- LTV2017_2_CIs[1]
LTV_2017_RAF_deciles["Second", "Rev_U"] <- LTV2017_2_CIs[2]

LTV_2017_RAF_deciles["Second", "Cost_L"] <- LTV2017_2_CIs[3]
LTV_2017_RAF_deciles["Second", "Cost_U"] <- LTV2017_2_CIs[4]

LTV_2017_RAF_deciles["Second", "Val_L"] <- LTV2017_2_CIs[5]
LTV_2017_RAF_deciles["Second", "Val_U"] <- LTV2017_2_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")


### Third Decile ###

LTV2017_3 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 3, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Third", "Rev"] <- sum(LTV2017_3$Total_Revenue) / length(LTV2017_3$SavvyHICN)
LTV_2017_RAF_deciles["Third", "Cost"] <- sum(LTV2017_3$Total_Cost) / length(LTV2017_3$SavvyHICN)
LTV_2017_RAF_deciles["Third", "Val"] <- sum(LTV2017_3$Total_Value) / length(LTV2017_3$SavvyHICN)

LTV2017_3_CIs <- bootstrapCIs3Vars(Data = LTV2017_3, Reps = 200)

LTV_2017_RAF_deciles["Third", "Rev_L"] <- LTV2017_3_CIs[1]
LTV_2017_RAF_deciles["Third", "Rev_U"] <- LTV2017_3_CIs[2]

LTV_2017_RAF_deciles["Third", "Cost_L"] <- LTV2017_3_CIs[3]
LTV_2017_RAF_deciles["Third", "Cost_U"] <- LTV2017_3_CIs[4]

LTV_2017_RAF_deciles["Third", "Val_L"] <- LTV2017_3_CIs[5]
LTV_2017_RAF_deciles["Third", "Val_U"] <- LTV2017_3_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")


### Fourth Decile ###

LTV2017_4 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 4, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Fourth", "Rev"] <- sum(LTV2017_4$Total_Revenue) / length(LTV2017_4$SavvyHICN)
LTV_2017_RAF_deciles["Fourth", "Cost"] <- sum(LTV2017_4$Total_Cost) / length(LTV2017_4$SavvyHICN)
LTV_2017_RAF_deciles["Fourth", "Val"] <- sum(LTV2017_4$Total_Value) / length(LTV2017_4$SavvyHICN)

LTV2017_4_CIs <- bootstrapCIs3Vars(Data = LTV2017_4, Reps = 200)

LTV_2017_RAF_deciles["Fourth", "Rev_L"] <- LTV2017_4_CIs[1]
LTV_2017_RAF_deciles["Fourth", "Rev_U"] <- LTV2017_4_CIs[2]

LTV_2017_RAF_deciles["Fourth", "Cost_L"] <- LTV2017_4_CIs[3]
LTV_2017_RAF_deciles["Fourth", "Cost_U"] <- LTV2017_4_CIs[4]

LTV_2017_RAF_deciles["Fourth", "Val_L"] <- LTV2017_4_CIs[5]
LTV_2017_RAF_deciles["Fourth", "Val_U"] <- LTV2017_4_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")


### Fifth Decile ###

LTV2017_5 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 5, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Fifth", "Rev"] <- sum(LTV2017_5$Total_Revenue) / length(LTV2017_5$SavvyHICN)
LTV_2017_RAF_deciles["Fifth", "Cost"] <- sum(LTV2017_5$Total_Cost) / length(LTV2017_5$SavvyHICN)
LTV_2017_RAF_deciles["Fifth", "Val"] <- sum(LTV2017_5$Total_Value) / length(LTV2017_5$SavvyHICN)

LTV2017_5_CIs <- bootstrapCIs3Vars(Data = LTV2017_5, Reps = 200)

LTV_2017_RAF_deciles["Fifth", "Rev_L"] <- LTV2017_5_CIs[1]
LTV_2017_RAF_deciles["Fifth", "Rev_U"] <- LTV2017_5_CIs[2]

LTV_2017_RAF_deciles["Fifth", "Cost_L"] <- LTV2017_5_CIs[3]
LTV_2017_RAF_deciles["Fifth", "Cost_U"] <- LTV2017_5_CIs[4]

LTV_2017_RAF_deciles["Fifth", "Val_L"] <- LTV2017_5_CIs[5]
LTV_2017_RAF_deciles["Fifth", "Val_U"] <- LTV2017_5_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")


### Sixth Decile ###

LTV2017_6 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 6, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Sixth", "Rev"] <- sum(LTV2017_6$Total_Revenue) / length(LTV2017_6$SavvyHICN)
LTV_2017_RAF_deciles["Sixth", "Cost"] <- sum(LTV2017_6$Total_Cost) / length(LTV2017_6$SavvyHICN)
LTV_2017_RAF_deciles["Sixth", "Val"] <- sum(LTV2017_6$Total_Value) / length(LTV2017_6$SavvyHICN)

LTV2017_6_CIs <- bootstrapCIs3Vars(Data = LTV2017_6, Reps = 200)

LTV_2017_RAF_deciles["Sixth", "Rev_L"] <- LTV2017_6_CIs[1]
LTV_2017_RAF_deciles["Sixth", "Rev_U"] <- LTV2017_6_CIs[2]

LTV_2017_RAF_deciles["Sixth", "Cost_L"] <- LTV2017_6_CIs[3]
LTV_2017_RAF_deciles["Sixth", "Cost_U"] <- LTV2017_6_CIs[4]
loaloa
LTV_2017_RAF_deciles["Sixth", "Val_L"] <- LTV2017_6_CIs[5]
LTV_2017_RAF_deciles["Sixth", "Val_U"] <- LTV2017_6_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")

### Seventh Decile ###

LTV2017_7 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 7, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Seventh", "Rev"] <- sum(LTV2017_7$Total_Revenue) / length(LTV2017_7$SavvyHICN)
LTV_2017_RAF_deciles["Seventh", "Cost"] <- sum(LTV2017_7$Total_Cost) / length(LTV2017_7$SavvyHICN)
LTV_2017_RAF_deciles["Seventh", "Val"] <- sum(LTV2017_7$Total_Value) / length(LTV2017_7$SavvyHICN)

LTV2017_7_CIs <- bootstrapCIs3Vars(Data = LTV2017_7, Reps = 200)

LTV_2017_RAF_deciles["Seventh", "Rev_L"] <- LTV2017_7_CIs[1]
LTV_2017_RAF_deciles["Seventh", "Rev_U"] <- LTV2017_7_CIs[2]

LTV_2017_RAF_deciles["Seventh", "Cost_L"] <- LTV2017_7_CIs[3]
LTV_2017_RAF_deciles["Seventh", "Cost_U"] <- LTV2017_7_CIs[4]

LTV_2017_RAF_deciles["Seventh", "Val_L"] <- LTV2017_7_CIs[5]
LTV_2017_RAF_deciles["Seventh", "Val_U"] <- LTV2017_7_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")

### Eighth Decile ###

LTV2017_8 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 8, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Eighth", "Rev"] <- sum(LTV2017_8$Total_Revenue) / length(LTV2017_8$SavvyHICN)
LTV_2017_RAF_deciles["Eighth", "Cost"] <- sum(LTV2017_8$Total_Cost) / length(LTV2017_8$SavvyHICN)
LTV_2017_RAF_deciles["Eighth", "Val"] <- sum(LTV2017_8$Total_Value) / length(LTV2017_8$SavvyHICN)

LTV2017_8_CIs <- bootstrapCIs3Vars(Data = LTV2017_8, Reps = 200)

LTV_2017_RAF_deciles["Eighth", "Rev_L"] <- LTV2017_8_CIs[1]
LTV_2017_RAF_deciles["Eighth", "Rev_U"] <- LTV2017_8_CIs[2]

LTV_2017_RAF_deciles["Eighth", "Cost_L"] <- LTV2017_8_CIs[3]
LTV_2017_RAF_deciles["Eighth", "Cost_U"] <- LTV2017_8_CIs[4]

LTV_2017_RAF_deciles["Eighth", "Val_L"] <- LTV2017_8_CIs[5]
LTV_2017_RAF_deciles["Eighth", "Val_U"] <- LTV2017_8_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")

### Ninth Decile ###

LTV2017_9 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 9, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Ninth", "Rev"] <- sum(LTV2017_9$Total_Revenue) / length(LTV2017_9$SavvyHICN)
LTV_2017_RAF_deciles["Ninth", "Cost"] <- sum(LTV2017_9$Total_Cost) / length(LTV2017_9$SavvyHICN)
LTV_2017_RAF_deciles["Ninth", "Val"] <- sum(LTV2017_9$Total_Value) / length(LTV2017_9$SavvyHICN)

LTV2017_9_CIs <- bootstrapCIs3Vars(Data = LTV2017_9, Reps = 200)

LTV_2017_RAF_deciles["Ninth", "Rev_L"] <- LTV2017_9_CIs[1]
LTV_2017_RAF_deciles["Ninth", "Rev_U"] <- LTV2017_9_CIs[2]

LTV_2017_RAF_deciles["Ninth", "Cost_L"] <- LTV2017_9_CIs[3]
LTV_2017_RAF_deciles["Ninth", "Cost_U"] <- LTV2017_9_CIs[4]

LTV_2017_RAF_deciles["Ninth", "Val_L"] <- LTV2017_9_CIs[5]
LTV_2017_RAF_deciles["Ninth", "Val_U"] <- LTV2017_9_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")

### Tenth Decile ###

LTV2017_10 <- filteredMemberMonth(pilotType = "Lifetime Value",  RAF_Decile = 10, RemoveDeaths = T, Data = All2017Pilot, Yr = 2017)

LTV_2017_RAF_deciles["Tenth", "Rev"] <- sum(LTV2017_10$Total_Revenue) / length(LTV2017_10$SavvyHICN)
LTV_2017_RAF_deciles["Tenth", "Cost"] <- sum(LTV2017_10$Total_Cost) / length(LTV2017_10$SavvyHICN)
LTV_2017_RAF_deciles["Tenth", "Val"] <- sum(LTV2017_10$Total_Value) / length(LTV2017_10$SavvyHICN)

LTV2017_10_CIs <- bootstrapCIs3Vars(Data = LTV2017_10, Reps = 200)

LTV_2017_RAF_deciles["Tenth", "Rev_L"] <- LTV2017_10_CIs[1]
LTV_2017_RAF_deciles["Tenth", "Rev_U"] <- LTV2017_10_CIs[2]

LTV_2017_RAF_deciles["Tenth", "Cost_L"] <- LTV2017_10_CIs[3]
LTV_2017_RAF_deciles["Tenth", "Cost_U"] <- LTV2017_10_CIs[4]

LTV_2017_RAF_deciles["Tenth", "Val_L"] <- LTV2017_10_CIs[5]
LTV_2017_RAF_deciles["Tenth", "Val_U"] <- LTV2017_10_CIs[6]

save(LTV_2017_RAF_deciles, file = "LTV_2017_RAF_deciles.rda")
