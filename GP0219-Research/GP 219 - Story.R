
#####GP 219 - Cashman Motion####


#Created: 2015-11-15
#Last updated: 2015-11-17

#In this issue:
#The Story
#Distributions of Cashman Goals Met
#--Amy.dat, a dataset of completed goals for Amy to use in visualizations


#Telling the story: Cost of Trio Program####

#Per Bruce Shepard, there are 3 costs associated with the Trio program:
#--Devices: $48-$80 depending on device chosen (plus replacement if company wants to pay for it)
#--Admin fee: $1-$2 pmpm. Cashman pays $2 pmpm
#--Incentives: wholly depenedent on employer health plan. Cashman pays up to $3 per day.

#So, with an estimate of $187 and the most expensive estimate of 2 years of costs:

80 + 2*24 + 3*730 #$2,318 for a person that meets their incentive goals every single day

#Without any incentives (which would not be like Cashman)

80 + 2*24  # $128

#Question: what were the actual rewards paid out by Cashman?
#Assumptions: $1 a day for 10k steps, Intensity, Frequency

names(cash_optB)
summary(cash_optB[,12:22])
sapply(cash_optB[,12:14], mean)
sum(sapply(cash_optB[,12:14], mean)) # ~$990

#On average, Cashman paid about $990 to each employee over the 2-year period
#Cashman cost with expensive Trio and high Admin costs:
80 + 2*24 + 990 # $1118





#Distributions of Cashman Goals Met####

hist(cash_optB$FGoalAcheived, main="Frequency Goals Achieved", xlab="Goals Achieved")
hist(cash_optB$IGoalAcheived, main="Intensity Goals Achieved", xlab="Goals Achieved")
hist(cash_optB$T10KGoalAcheived, main="Tenacity 10k Goals Achieved", xlab="Goals Achieved")
hist(cash_optB$T8KGoalAcheived, main="Tenacity 8k Goals Achieved", xlab="Goals Achieved")
hist(cash_optB$T6KGoalAcheived, main="Tenacity 6K Goals Achieved", xlab="Goals Achieved")

Amy.dat <- cash_optB[,c(grep("Savvyid", names(cash_optB)), grep("GoalAch", names(cash_optB)))]
#Now add in percentages of goals achieved
temp <- cash_optB
head(cash_optB[,c(grep("Savvyid", names(cash_optB)), grep("GoalAch", names(cash_optB)))])
names(temp)
temp$TotAchieved10k <- sum(temp$FGoalAcheived,temp$IGoalAcheived,temp$T10KGoalAcheived)
temp$TotAchieved8k <- sum(temp$FGoalAcheived,temp$IGoalAcheived,temp$T8KGoalAcheived)
temp$TotAchieved6k <- sum(temp$FGoalAcheived,temp$IGoalAcheived,temp$T6KGoalAcheived)

temp$Points <- rowSums(temp[,17:19]) #THERE we go.
summary(temp$Points)
temp$PosPoints <- rowSums(temp[,20:22])
summary(temp$PosPoints)

Amy.dat$GoalPercent <- temp$Points/temp$PosPoints
hist(Amy.dat$GoalPercent)

#write.xlsx(Amy.dat, "/home/cmiller/CashmanGoals.xlsx")