# ConfInts.R

# April 18, 2018

# Steve Smela, Savvysherpa

# Calculates confidence intervals for values appearing in AvMo report graphs.  See chunk KQ1_9 in "AvMo Report generation"
# Markdown file.

# April 18th modification makes use of new version of Bootstrap CIs, which calculates CIs for Cost, Revenue and Value
# at once and returns lower and upper limits for each of these three.

IN2016 <- filteredMemberMonth(pilotType = 2016, Data = All2016Pilot, State = "IN", Yr = 2016, RemoveDeaths = T)

# IN_CIs <- matrix(nrow = 5, ncol = 6, rep(0, 30))
rownames(IN_CIs) <- c("Overall", "Enrolled", "Not Enrolled", "Registered", "Not Registered")
colnames(IN_CIs) <- c("Rev_L", "Rev_U", "Cost_L", "Cost_U", "Val_L", "Val_U")

# Check:
length(unique(IN2016$SavvyHICN[IN2016$Enrolled]))
IN2016[IN2016$Enrolled,] %>% summarise(MLI = sum(Total_Value) / n())


## Overall

INOverall <- bootstrapCIs3Vars(Data = IN2016, Reps = 100)

IN_CIs["Overall", "Rev_L"] <- INOverall[1]
IN_CIs["Overall", "Rev_U"] <- INOverall[2]

IN_CIs["Overall", "Cost_L"] <- INOverall[3]
IN_CIs["Overall", "Cost_U"] <- INOverall[4]

IN_CIs["Overall", "Val_L"] <- INOverall[5]
IN_CIs["Overall", "Val_U"] <- INOverall[6]

save(IN_CIs, file = "IN_CIs.rda")

## Enrolled ##

INEnrolled <- bootstrapCIs3Vars(Data = IN2016, Group = "Enrolled", Reps = 500)

IN_CIs["Enrolled", "Rev_L"] <- INEnrolled[1]
IN_CIs["Enrolled", "Rev_U"] <- INEnrolled[2] 

IN_CIs["Enrolled", "Cost_L"] <- INEnrolled[3] 
IN_CIs["Enrolled", "Cost_U"] <- INEnrolled[4]

IN_CIs["Enrolled", "Val_L"] <- INEnrolled[5]
IN_CIs["Enrolled", "Val_U"] <- INEnrolled[6]

save(IN_CIs, file = "IN_CIs.rda")

## Not Enrolled ##

INNotEnrolled <- bootstrapCIs3Vars(Data = IN2016, Group = "NotEnrolled", Reps = 100)

IN_CIs["Not Enrolled", "Rev_L"] <- INNotEnrolled[1] 
IN_CIs["Not Enrolled", "Rev_U"] <- INNotEnrolled[2]

IN_CIs["Not Enrolled", "Cost_L"] <- INNotEnrolled[3]
IN_CIs["Not Enrolled", "Cost_U"] <- INNotEnrolled[4]

IN_CIs["Not Enrolled", "Val_L"] <- INNotEnrolled[5] 
IN_CIs["Not Enrolled", "Val_U"] <- INNotEnrolled[6]

save(IN_CIs, file = "IN_CIs.rda")

## Registered ##

# Check:
length(unique(IN2016$SavvyHICN[IN2016$Registered]))
IN2016 %>% filter(Registered == T) %>% summarise(MLI = sum(Total_Value) / n())

INRegistered <- bootstrapCIs3Vars(Data = IN2016, Group = "Registered", Reps = 500)

IN_CIs["Registered", "Rev_L"] <- INRegistered[1]
IN_CIs["Registered", "Rev_U"] <- INRegistered[2]

IN_CIs["Registered", "Cost_L"] <- INRegistered[3]
IN_CIs["Registered", "Cost_U"] <- INRegistered[4]

IN_CIs["Registered", "Val_L"] <- INRegistered[5]
IN_CIs["Registered", "Val_U"] <- INRegistered[6]

save(IN_CIs, file = "IN_CIs.rda")

## Not registered ##

length(unique(IN2016$SavvyHICN[IN2016$NotRegistered]))
IN2016 %>% filter(NotRegistered == T) %>% summarise(MLI = sum(Total_Value) / n())

INNotRegistered <- bootstrapCIs3Vars(Data = IN2016, Group = "NotRegistered", Reps = 500)

IN_CIs["Not Registered", "Rev_L"] <-  INNotRegistered[1]
IN_CIs["Not Registered", "Rev_U"] <-  INNotRegistered[2]

IN_CIs["Not Registered", "Cost_L"] <- INNotRegistered[3]
IN_CIs["Not Registered", "Cost_U"] <- INNotRegistered[4]

IN_CIs["Not Registered", "Val_L"] <-  INNotRegistered[5]
IN_CIs["Not Registered", "Val_U"] <-  INNotRegistered[6]

save(IN_CIs, file = "IN_CIs.rda")


#################################
######### LTV ###################
#################################

#LTV_CIs <- matrix(nrow = 7, ncol = 6, rep(0, 42))
rownames(LTV_CIs) <- c("Overall", "Reached", "Not Reached", "Enrolled", "Not Enrolled",
                          "Registered", "Not Registered")
colnames(LTV_CIs) <- c("Rev_L", "Rev_U", "Cost_L", "Cost_U", "Val_L", "Val_U")


LTV2017 <- filteredMemberMonth(Data = All2017Pilot, pilotType = "Lifetime Value", Yr = 2017, RemoveDeaths = T)

# Check:
length(unique(LTV2017$SavvyHICN))
LTV2017 %>% summarise(MLI = sum(Total_Value) / n())

## Overall ##

LTVOverall <- bootstrapCIs3Vars(Data = LTV2017, Reps = 100)

LTV_CIs["Overall", "Rev_L"] <- LTVOverall[1]
LTV_CIs["Overall", "Rev_U"] <- LTVOverall[2]

LTV_CIs["Overall", "Cost_L"] <- LTVOverall[3]
LTV_CIs["Overall", "Cost_U"] <- LTVOverall[4]

LTV_CIs["Overall", "Val_L"] <- LTVOverall[5]
LTV_CIs["Overall", "Val_U"] <- LTVOverall[6]

save(LTV_CIs, file = "LTV_CIs.rda")

## Reached ##

# Check:
length(unique(LTV2017$SavvyHICN[LTV2017$Reached]))
LTV2017[LTV2017$Reached, ] %>% summarise(MLI = sum(Total_Value) / n())

LTVReached <- bootstrapCIs3Vars(Data = LTV2017, Group = "Reached", Reps = 100)

LTV_CIs["Reached", "Rev_L"] <- LTVReached[1]
LTV_CIs["Reached", "Rev_U"] <- LTVReached[2]

LTV_CIs["Reached", "Cost_L"] <- LTVReached[3]
LTV_CIs["Reached", "Cost_U"] <- LTVReached[4]

LTV_CIs["Reached", "Val_L"] <- LTVReached[5]
LTV_CIs["Reached", "Val_U"] <- LTVReached[6]

save(LTV_CIs, file = "LTV_CIs.rda")

## Not Reached ##

# Check:
LTVNotReached <- bootstrapCIs3Vars(Data = LTV2017, Group = "NotReached", Reps = 100)
length(unique(LTV2017$SavvyHICN[LTV2017$NotReached]))
LTV2017[LTV2017$NotReached, ] %>% summarise(MLI = sum(Total_Value) / n())


LTV_CIs["Not Reached", "Rev_L"] <- LTVNotReached[1]
LTV_CIs["Not Reached", "Rev_U"] <- LTVNotReached[2]


LTV_CIs["Not Reached", "Cost_L"] <- LTVNotReached[3]
LTV_CIs["Not Reached", "Cost_U"] <- LTVNotReached[4]

LTV_CIs["Not Reached", "Val_L"] <- LTVNotReached[5]
LTV_CIs["Not Reached", "Val_U"] <- LTVNotReached[6]

save(LTV_CIs, file = "LTV_CIs.rda")

##  Enrolled ##

LTVEnrolled <- bootstrapCIs3Vars(Data = LTV2017, Group = "Enrolled", Reps = 200)

LTV_CIs["Enrolled", "Rev_L"] <- LTVEnrolled[1]
LTV_CIs["Enrolled", "Rev_U"] <- LTVEnrolled[2]

LTV_CIs["Enrolled", "Cost_L"] <- LTVEnrolled[3]
LTV_CIs["Enrolled", "Cost_U"] <- LTVEnrolled[4]

LTV_CIs["Enrolled", "Val_L"] <- LTVEnrolled[5]
LTV_CIs["Enrolled", "Val_U"] <- LTVEnrolled[6]

save(LTV_CIs, file = "LTV_CIs.rda")

## Not Enrolled ###

LTVNotEnrolled <- bootstrapCIs3Vars(Data = LTV2017, Group = "NotEnrolled", Reps = 125)

LTV_CIs["Not Enrolled", "Rev_L"] <- LTVNotEnrolled[1]
LTV_CIs["Not Enrolled", "Rev_U"] <- LTVNotEnrolled[2]

LTV_CIs["Not Enrolled", "Cost_L"] <- LTVNotEnrolled[3]
LTV_CIs["Not Enrolled", "Cost_U"] <- LTVNotEnrolled[4]

LTV_CIs["Not Enrolled", "Val_L"] <- LTVNotEnrolled[5]
LTV_CIs["Not Enrolled", "Val_U"] <- LTVNotEnrolled[6]

save(LTV_CIs, file = "LTV_CIs.rda")

## Registered ##

LTVRegistered <- bootstrapCIs3Vars(Data = LTV2017, Group = "Registered", Reps = 200)

LTV_CIs["Registered", "Rev_L"] <- LTVRegistered[1]
LTV_CIs["Registered", "Rev_U"] <- LTVRegistered[2]

LTV_CIs["Registered", "Cost_L"] <- LTVRegistered[3]
LTV_CIs["Registered", "Cost_U"] <- LTVRegistered[4]

LTV_CIs["Registered", "Val_L"] <- LTVRegistered[5]
LTV_CIs["Registered", "Val_U"] <- LTVRegistered[6]

save(LTV_CIs, file = "LTV_CIs.rda")

## Not registered ##

LTVNotRegistered <- bootstrapCIs3Vars(Data = LTV2017, Group = "NotRegistered", Reps = 200)

LTV_CIs["Not Registered", "Rev_L"] <- LTVNotRegistered[1]
LTV_CIs["Not Registered", "Rev_U"] <- LTVNotRegistered[2]

LTV_CIs["Not Registered", "Cost_L"] <- LTVNotRegistered[3]
LTV_CIs["Not Registered", "Cost_U"] <- LTVNotRegistered[4]

LTV_CIs["Not Registered", "Val_L"] <- LTVNotRegistered[5]
LTV_CIs["Not Registered", "Val_U"] <- LTVNotRegistered[6]

save(LTV_CIs, file = "LTV_CIs.rda")