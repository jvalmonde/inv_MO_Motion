# Calculates PMPM Value, Revenue and Cost, with confidence intervals, for 2016 Indiana pilot, using 2016 data,
# by RAF decile

# April 2018, Steve Smela, Savvysherpa

if(!exists("All2016Pilot")) load("All2016Pilot.rda")

IN_2016_RAF_deciles <- matrix(nrow = 10, ncol = 9)

rownames(IN_2016_RAF_deciles) <- c("First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth")
colnames(IN_2016_RAF_deciles) <- c("Rev_L", "Rev", "Rev_U", "Cost_L", "Cost", "Cost_U", "Val_L", "Val", "Val_U")

IN2016_1 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 1, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["First", "Rev"] <- sum(IN2016_1$Total_Revenue) / length(IN2016_1$SavvyHICN)
IN_2016_RAF_deciles["First", "Cost"] <- sum(IN2016_1$Total_Cost) / length(IN2016_1$SavvyHICN)
IN_2016_RAF_deciles["First", "Val"] <- sum(IN2016_1$Total_Value) / length(IN2016_1$SavvyHICN)

IN2016_1_CIs <- bootstrapCIs3Vars(Data = IN2016_1, Reps = 500)

IN_2016_RAF_deciles["First", "Rev_L"] <- IN2016_1_CIs[1]
IN_2016_RAF_deciles["First", "Rev_U"] <- IN2016_1_CIs[2]

IN_2016_RAF_deciles["First", "Cost_L"] <- IN2016_1_CIs[3]
IN_2016_RAF_deciles["First", "Cost_U"] <- IN2016_1_CIs[4]

IN_2016_RAF_deciles["First", "Val_L"] <- IN2016_1_CIs[5]
IN_2016_RAF_deciles["First", "Val_U"] <- IN2016_1_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")

### Second Decile ###

IN2016_2 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 2, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Second", "Rev"] <- sum(IN2016_2$Total_Revenue) / length(IN2016_2$SavvyHICN)
IN_2016_RAF_deciles["Second", "Cost"] <- sum(IN2016_2$Total_Cost) / length(IN2016_2$SavvyHICN)
IN_2016_RAF_deciles["Second", "Val"] <- sum(IN2016_2$Total_Value) / length(IN2016_2$SavvyHICN)

IN2016_2_CIs <- bootstrapCIs3Vars(Data = IN2016_2, Reps = 200)

IN_2016_RAF_deciles["Second", "Rev_L"] <- IN2016_2_CIs[1]
IN_2016_RAF_deciles["Second", "Rev_U"] <- IN2016_2_CIs[2]

IN_2016_RAF_deciles["Second", "Cost_L"] <- IN2016_2_CIs[3]
IN_2016_RAF_deciles["Second", "Cost_U"] <- IN2016_2_CIs[4]

IN_2016_RAF_deciles["Second", "Val_L"] <- IN2016_2_CIs[5]
IN_2016_RAF_deciles["Second", "Val_U"] <- IN2016_2_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")


### Third Decile ###

IN2016_3 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 3, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Third", "Rev"] <- sum(IN2016_3$Total_Revenue) / length(IN2016_3$SavvyHICN)
IN_2016_RAF_deciles["Third", "Cost"] <- sum(IN2016_3$Total_Cost) / length(IN2016_3$SavvyHICN)
IN_2016_RAF_deciles["Third", "Val"] <- sum(IN2016_3$Total_Value) / length(IN2016_3$SavvyHICN)

IN2016_3_CIs <- bootstrapCIs3Vars(Data = IN2016_3, Reps = 200)

IN_2016_RAF_deciles["Third", "Rev_L"] <- IN2016_3_CIs[1]
IN_2016_RAF_deciles["Third", "Rev_U"] <- IN2016_3_CIs[2]

IN_2016_RAF_deciles["Third", "Cost_L"] <- IN2016_3_CIs[3]
IN_2016_RAF_deciles["Third", "Cost_U"] <- IN2016_3_CIs[4]

IN_2016_RAF_deciles["Third", "Val_L"] <- IN2016_3_CIs[5]
IN_2016_RAF_deciles["Third", "Val_U"] <- IN2016_3_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")


### Fourth Decile ###

IN2016_4 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 4, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Fourth", "Rev"] <- sum(IN2016_4$Total_Revenue) / length(IN2016_4$SavvyHICN)
IN_2016_RAF_deciles["Fourth", "Cost"] <- sum(IN2016_4$Total_Cost) / length(IN2016_4$SavvyHICN)
IN_2016_RAF_deciles["Fourth", "Val"] <- sum(IN2016_4$Total_Value) / length(IN2016_4$SavvyHICN)

IN2016_4_CIs <- bootstrapCIs3Vars(Data = IN2016_4, Reps = 200)

IN_2016_RAF_deciles["Fourth", "Rev_L"] <- IN2016_4_CIs[1]
IN_2016_RAF_deciles["Fourth", "Rev_U"] <- IN2016_4_CIs[2]

IN_2016_RAF_deciles["Fourth", "Cost_L"] <- IN2016_4_CIs[3]
IN_2016_RAF_deciles["Fourth", "Cost_U"] <- IN2016_4_CIs[4]

IN_2016_RAF_deciles["Fourth", "Val_L"] <- IN2016_4_CIs[5]
IN_2016_RAF_deciles["Fourth", "Val_U"] <- IN2016_4_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")


### Fifth Decile ###

IN2016_5 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 5, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Fifth", "Rev"] <- sum(IN2016_5$Total_Revenue) / length(IN2016_5$SavvyHICN)
IN_2016_RAF_deciles["Fifth", "Cost"] <- sum(IN2016_5$Total_Cost) / length(IN2016_5$SavvyHICN)
IN_2016_RAF_deciles["Fifth", "Val"] <- sum(IN2016_5$Total_Value) / length(IN2016_5$SavvyHICN)

IN2016_5_CIs <- bootstrapCIs3Vars(Data = IN2016_5, Reps = 200)

IN_2016_RAF_deciles["Fifth", "Rev_L"] <- IN2016_5_CIs[1]
IN_2016_RAF_deciles["Fifth", "Rev_U"] <- IN2016_5_CIs[2]

IN_2016_RAF_deciles["Fifth", "Cost_L"] <- IN2016_5_CIs[3]
IN_2016_RAF_deciles["Fifth", "Cost_U"] <- IN2016_5_CIs[4]

IN_2016_RAF_deciles["Fifth", "Val_L"] <- IN2016_5_CIs[5]
IN_2016_RAF_deciles["Fifth", "Val_U"] <- IN2016_5_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")


### Sixth Decile ###

IN2016_6 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 6, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Sixth", "Rev"] <- sum(IN2016_6$Total_Revenue) / length(IN2016_6$SavvyHICN)
IN_2016_RAF_deciles["Sixth", "Cost"] <- sum(IN2016_6$Total_Cost) / length(IN2016_6$SavvyHICN)
IN_2016_RAF_deciles["Sixth", "Val"] <- sum(IN2016_6$Total_Value) / length(IN2016_6$SavvyHICN)

IN2016_6_CIs <- bootstrapCIs3Vars(Data = IN2016_6, Reps = 200)

IN_2016_RAF_deciles["Sixth", "Rev_L"] <- IN2016_6_CIs[1]
IN_2016_RAF_deciles["Sixth", "Rev_U"] <- IN2016_6_CIs[2]

IN_2016_RAF_deciles["Sixth", "Cost_L"] <- IN2016_6_CIs[3]
IN_2016_RAF_deciles["Sixth", "Cost_U"] <- IN2016_6_CIs[4]

IN_2016_RAF_deciles["Sixth", "Val_L"] <- IN2016_6_CIs[5]
IN_2016_RAF_deciles["Sixth", "Val_U"] <- IN2016_6_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")

### Seventh Decile ###

IN2016_7 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 7, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Seventh", "Rev"] <- sum(IN2016_7$Total_Revenue) / length(IN2016_7$SavvyHICN)
IN_2016_RAF_deciles["Seventh", "Cost"] <- sum(IN2016_7$Total_Cost) / length(IN2016_7$SavvyHICN)
IN_2016_RAF_deciles["Seventh", "Val"] <- sum(IN2016_7$Total_Value) / length(IN2016_7$SavvyHICN)

IN2016_7_CIs <- bootstrapCIs3Vars(Data = IN2016_7, Reps = 200)

IN_2016_RAF_deciles["Seventh", "Rev_L"] <- IN2016_7_CIs[1]
IN_2016_RAF_deciles["Seventh", "Rev_U"] <- IN2016_7_CIs[2]

IN_2016_RAF_deciles["Seventh", "Cost_L"] <- IN2016_7_CIs[3]
IN_2016_RAF_deciles["Seventh", "Cost_U"] <- IN2016_7_CIs[4]

IN_2016_RAF_deciles["Seventh", "Val_L"] <- IN2016_7_CIs[5]
IN_2016_RAF_deciles["Seventh", "Val_U"] <- IN2016_7_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")

### Eighth Decile ###

IN2016_8 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 8, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Eighth", "Rev"] <- sum(IN2016_8$Total_Revenue) / length(IN2016_8$SavvyHICN)
IN_2016_RAF_deciles["Eighth", "Cost"] <- sum(IN2016_8$Total_Cost) / length(IN2016_8$SavvyHICN)
IN_2016_RAF_deciles["Eighth", "Val"] <- sum(IN2016_8$Total_Value) / length(IN2016_8$SavvyHICN)

IN2016_8_CIs <- bootstrapCIs3Vars(Data = IN2016_8, Reps = 200)

IN_2016_RAF_deciles["Eighth", "Rev_L"] <- IN2016_8_CIs[1]
IN_2016_RAF_deciles["Eighth", "Rev_U"] <- IN2016_8_CIs[2]

IN_2016_RAF_deciles["Eighth", "Cost_L"] <- IN2016_8_CIs[3]
IN_2016_RAF_deciles["Eighth", "Cost_U"] <- IN2016_8_CIs[4]

IN_2016_RAF_deciles["Eighth", "Val_L"] <- IN2016_8_CIs[5]
IN_2016_RAF_deciles["Eighth", "Val_U"] <- IN2016_8_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")

### Ninth Decile ###

IN2016_9 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 9, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Ninth", "Rev"] <- sum(IN2016_9$Total_Revenue) / length(IN2016_9$SavvyHICN)
IN_2016_RAF_deciles["Ninth", "Cost"] <- sum(IN2016_9$Total_Cost) / length(IN2016_9$SavvyHICN)
IN_2016_RAF_deciles["Ninth", "Val"] <- sum(IN2016_9$Total_Value) / length(IN2016_9$SavvyHICN)

IN2016_9_CIs <- bootstrapCIs3Vars(Data = IN2016_9, Reps = 200)

IN_2016_RAF_deciles["Ninth", "Rev_L"] <- IN2016_9_CIs[1]
IN_2016_RAF_deciles["Ninth", "Rev_U"] <- IN2016_9_CIs[2]

IN_2016_RAF_deciles["Ninth", "Cost_L"] <- IN2016_9_CIs[3]
IN_2016_RAF_deciles["Ninth", "Cost_U"] <- IN2016_9_CIs[4]

IN_2016_RAF_deciles["Ninth", "Val_L"] <- IN2016_9_CIs[5]
IN_2016_RAF_deciles["Ninth", "Val_U"] <- IN2016_9_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")

### Tenth Decile ###

IN2016_10 <- filteredMemberMonth(pilotType = 2016, State = "IN", RAF_Decile = 10, RemoveDeaths = T, Data = All2016Pilot, Yr = 2016)

IN_2016_RAF_deciles["Tenth", "Rev"] <- sum(IN2016_10$Total_Revenue) / length(IN2016_10$SavvyHICN)
IN_2016_RAF_deciles["Tenth", "Cost"] <- sum(IN2016_10$Total_Cost) / length(IN2016_10$SavvyHICN)
IN_2016_RAF_deciles["Tenth", "Val"] <- sum(IN2016_10$Total_Value) / length(IN2016_10$SavvyHICN)

IN2016_10_CIs <- bootstrapCIs3Vars(Data = IN2016_10, Reps = 200)

IN_2016_RAF_deciles["Tenth", "Rev_L"] <- IN2016_10_CIs[1]
IN_2016_RAF_deciles["Tenth", "Rev_U"] <- IN2016_10_CIs[2]

IN_2016_RAF_deciles["Tenth", "Cost_L"] <- IN2016_10_CIs[3]
IN_2016_RAF_deciles["Tenth", "Cost_U"] <- IN2016_10_CIs[4]

IN_2016_RAF_deciles["Tenth", "Val_L"] <- IN2016_10_CIs[5]
IN_2016_RAF_deciles["Tenth", "Val_U"] <- IN2016_10_CIs[6]

save(IN_2016_RAF_deciles, file = "IN_2016_RAF_deciles.rda")
