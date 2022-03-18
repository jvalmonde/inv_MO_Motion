############
#packages
############
library(RODBC)
library(foreign)
library(nnet)
library(ggplot2)
library(dplyr)
library(plyr)
#library(effects)
library(reshape2)


############
#dataset
############

database <- odbcConnect("devsql10")
eng <- sqlQuery(database, "select * from udb_ktanudtanud.dbo.KT_G1061_EngagementAnalysis_Dataset2")
str(eng) #28028 rows, 90 variables



#converting to factors
eng <- eng %>% mutate_each (funs(as.factor),Sbscr_Ind, PA_Quartile,PA_Quartile_M1, PA_Quartile_M16,MotionEnrFlag_StepBased,
                            M1_Maintenance_Flag, M16_Maintenance_Flag, ME_Maintenance_Flag, M1_Flag, M16_Flag, M1_Maintenance_Flag, M16_Maintenance_Flag,  
                            M1_Antihyperglycemics, M1_Cardiovascular, M1_ThyroidPreps, M1_AntiparkinsonDrugs, M1_CNSDrugs,
                            M1_CardiacDrugs, M1_Diuretics,
                            M16_Antihyperglycemics, M16_Cardiovascular, M16_ThyroidPreps, M16_AntiparkinsonDrugs, M16_CNSDrugs,
                            M16_CardiacDrugs, M16_Diuretics,
                            ME_Antihyperglycemics, ME_Cardiovascular, ME_ThyroidPreps, ME_AntiparkinsonDrugs, ME_CNSDrugs,
                            ME_CardiacDrugs, ME_Diuretics,ME_Maintenance_Flag)

eng$PA_Quartile <- factor(eng$PA_Quartile, levels = c ("4","3","2","1"))
eng$PA_Quartile_M1 <- factor(eng$PA_Quartile_M1, levels = c ("4","3","2","1"))
eng$PA_Quartile_M16 <- factor(eng$PA_Quartile_M16, levels = c ("4","3","2","1"))
str(eng)

#checking counts
table(eng$Sbscr_Ind)
table(eng$PA_Quartile)
table(eng$PA_Quartile_M1)
table(eng$PA_Quartile_M16)
nrow(eng[eng$M1_Flag==1,]) #18705
nrow(eng[eng$M16_Flag==1,]) #10403


############
#[A.] multinomial logistic regression: predicting level of engagement (1-month data)
############

#ONE-MONTH DATA SET
eng_month1 <- eng[eng$M1_Flag==1,]
nrow(eng_month1) #18705 members


#distribution by length of enrollment
#ggplot(eng_month1[eng_month1$MotionEnr_Dur_Month >0,], aes(MotionEnr_Dur_Month)) + geom_histogram (binwidth =3) + scale_fill_grey() + theme_classic ()
print(ggplot(eng_month1[eng_month1$MotionEnr_Dur_Month >0,], aes(MotionEnr_Dur_Month)) + geom_histogram (binwidth =3, color = "lightblue", fill = "darkgrey") 
+ (labs (x = "Months of enrollment in Motion", y = "Member count")))

#sum stat for enr dur
summary(eng_month1[eng_month1$MotionEnr_Dur_Month >0,"MotionEnr_Dur_Month"]) #11, 11


#1-MONTH DATA BASED MODEL: ENGAGEMENT LEVEL
#specifying baseline
eng_month1$PA_Quartile_M1b <- relevel(eng_month1$PA_Quartile_M1, ref="4")
str(eng_month1)

#models
EL1 <- multinom(PA_Quartile_M1b ~ Age + Gender + Sbscr_Ind 
                            + M1_Antihyperglycemics + M1_Cardiovascular + M1_ThyroidPreps 
                            + M1_AntiparkinsonDrugs + M1_CNSDrugs + M1_CardiacDrugs + M1_Diuretics, data = eng_month1)

EL1 <- multinom(PA_Quartile_M1b ~  Gender + Sbscr_Ind + M1_Antihyperglycemics + M1_Cardiovascular + M1_ThyroidPreps 
                + M1_AntiparkinsonDrugs + M1_CNSDrugs + M1_CardiacDrugs + M1_Diuretics, data = eng_month1)

#EL1 <- multinom(PA_Quartile_M1b ~ Age + Gender + Sbscr_Ind  + M1_Maintenance_Flag, data = eng_month1)
#EL1 <- multinom(PA_Quartile_M1b ~ Age + Gender+ M1_Maintenance_Flag, data = eng_month1)
EL1 <- multinom(PA_Quartile_M1b ~ Gender + Sbscr_Ind + M1_Maintenance_Flag, data = eng_month1)


#creating function to retrieve coefficients, p-values, CI for odds ratio
model <- function (mlr) { 
  coef <-summary(EL1)$coefficients
  z <- summary(EL1)$coefficients / summary(EL1)$standard.errors
  pval <- (1-pnorm(abs(z),0,1)) * 2
  #ci <- exp(coef(EL1))
  ci <- exp(confint(EL1))
  c<- cbind(coef,pval)
  return((list(first=c, second= ci)))
}

model(EL1)


#PLOTTING PROBABILITIES
#[1] probabilities for Thyroidprep med while holding other variables constant (with 7 drug classes)
test <- data.frame(Gender = rep(c("M"),times=2), Sbscr_Ind = rep(c("1"), times = 2), M1_Antihyperglycemics = rep(c("0"), times = 2), M1_Cardiovascular = rep(c("0"), times = 2),
                   M1_ThyroidPreps = rep(c("0", "1"), each = 1), M1_AntiparkinsonDrugs = rep(c("0"), times = 2), M1_CNSDrugs = rep(c("0"), times = 2), M1_CardiacDrugs = rep(c("0"), times = 2),
                   M1_Diuretics = rep(c("0"), times = 2), Age = rep(c(mean(eng$Age)),2))

#str(test)
#prob.test <- predict (EL1, newdata = test, type="probs")
prob.test <- cbind (test,predict (EL1, newdata = test, type="probs", se = TRUE))
head(prob.test)
prob.test2 <- melt(prob.test, id.vars = "M1_ThyroidPreps", measure.vars= c("1","2","3","4"))
prob.test2

#ggplot(prob.test2[prob.test2$M1_ThyroidPreps=="1",], aes(y=value, x= variable)) + geom_point() + geom_bar (stat="identity", width=0.01) + coord_flip ()
#ggplot(prob.test2[prob.test2$M1_ThyroidPreps=="0",], aes(y=value, x= variable)) + geom_point() + geom_bar (stat="identity", width=0.01) + coord_flip ()
#ggplot(data=prob.test2[prob.test2$M1_ThyroidPreps==1,], aes(y=value, x=variable)) + geom_point () + geom_segment (aes(xend=variable), yend=0) 
#+ expand_limits (y=0)+  coord_flip() + facet_grid (M1_ThyroidPreps ~., scales = "free") 

print(ggplot(prob.test2, aes(y=value, x= variable)) + geom_point() + geom_bar (stat="identity", width=0.01) + coord_flip () + facet_grid (M1_ThyroidPreps ~., scales = "free")
      + labs (y="probability", x = "engagement level"))



#[2] probabilities for age while holding other variables constant (with one flag for maintenance drug)
test <- data.frame(Gender = rep(c("M"),times=100), Sbscr_Ind = rep(c("1"), times = 100), M1_Maintenance_Flag = rep(c("0","1"), each = 50),  Age = rep(c(21:70),2))
    #this is to understand the model using the pred prob by looking at the pred prob for diff values of age (for each medication status)
prob.test <- cbind (test,predict (EL1, newdata = test, type="probs", se = TRUE))
prob.test2 <- melt(prob.test, id.vars = c("Age","M1_Maintenance_Flag"), measure.vars= c("1","2","3","4"))
str(prob.test2)
print(ggplot(prob.test2, aes (x=Age, y = value, colour = M1_Maintenance_Flag)) + geom_line () + facet_grid(variable ~ ., scales = "free")
          + labs (x = "age", y="probability", colour = "Maintenance Drug"))


#DESCRIPTIVE SUMMARY: CHARTS
#1.1 thyroid drug use and engagement level
#print(ggplot(eng_month1, aes(M1_ThyroidPreps, fill=PA_Quartile_M1)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"))
#      + labs (x="Thyroid drug use", y = "proportion of members"))

print(ggplot(eng_month1, aes(M1_ThyroidPreps, fill=PA_Quartile_M1)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"), name= "Engagement level")
+ labs (x="Thyroid drug use", y = "proportion of members"))


#1.2 cardio vascular drug use and engagement level
print(ggplot(eng_month1, aes(M1_Cardiovascular, fill=PA_Quartile_M1)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"), name= "Engagement level")
      + labs (x="Cardiovascular drug use", y = "proportion of members"))


#2.1 maintenance medication and engagement level
print(ggplot(eng_month1, aes(M1_Maintenance_Flag, fill=PA_Quartile_M1)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"), name= "Engagement level")
      + labs (x="Maintenance medication", y = "proportion of members"))


############
#[B.] Multinomial logistic regression: predicting level of engagement (6-month data)
############

#SIX-MONTH DATA SET
eng_month16 <- eng[eng$M16_Flag==1,]
nrow(eng_month16) #10403 members

#distribution by length of enrollment
print(ggplot(eng_month16[eng_month16$MotionEnr_Dur_Month >0,], aes(MotionEnr_Dur_Month)) + geom_histogram (binwidth =3, color = "lightblue", fill = "darkgrey") 
      + (labs (x = "Months of enrollment in Motion", y = "Member count")))

summary(eng_month16[eng_month16$MotionEnr_Dur_Month >0,"MotionEnr_Dur_Month"])


#6-MONTH DATA BASED MODEL: ENGAGEMENT LEVEL
#specifying baseline
eng_month16$PA_Quartile_M16b <- relevel(eng_month16$PA_Quartile_M16, ref="4")

#models
EL16 <- multinom(PA_Quartile_M16b ~ Age + Gender + Sbscr_Ind 
                + M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
                + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = eng_month16)

EL16 <- multinom(PA_Quartile_M16b ~ M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
                 + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = eng_month16)

EL16 <- multinom(PA_Quartile_M16b ~ Gender + Sbscr_Ind + M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
                 + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = eng_month16)


#EL16 <- multinom(PA_Quartile_M16b ~ Age + Gender + Sbscr_Ind + M16_Maintenance_Flag, data = eng_month16)
#EL16 <- multinom(PA_Quartile_M16b ~  Age + M16_Maintenance_Flag, data = eng_month16)
EL16 <- multinom(PA_Quartile_M16b ~  Gender + Sbscr_Ind  + M16_Maintenance_Flag, data = eng_month16)


#creating function to retrieve coefficients, p-values, CI for odds ratio
model2 <- function (mlr2) { 
  coef <-summary(EL16)$coefficients
  z <- summary(EL16)$coefficients / summary(EL16)$standard.errors
  pval <- (1-pnorm(abs(z),0,1)) * 2
  #ci <- exp(coef(EL1))
  ci <- exp(confint(EL16))
  c<- cbind(coef,pval)
  return((list(first=c, second= ci)))
}

model2(EL16)


#PLOTTING PROBABILITIES
#[1] probabilities for maintenance drug use while holding other variables constant 
test <- data.frame(Gender = rep(c("M"),times=2), Sbscr_Ind = rep(c("1"), times = 2), M16_Maintenance_Flag = rep(c("0", "1"), each = 1))
str(test)
prob.test <- cbind (test,predict (EL16, newdata = test, type="probs", se = TRUE))
head(prob.test)
prob.test2 <- melt(prob.test, id.vars = "M16_Maintenance_Flag", measure.vars= c("1","2","3","4"))
prob.test2

print(ggplot(prob.test2, aes(y=value, x= variable)) + geom_point() + geom_bar (stat="identity", width=0.01) + coord_flip () + facet_grid (M16_Maintenance_Flag ~., scales = "free")
      + labs (y="probability", x = "engagement level"))

#[2] probabilities by age while holding other variables constant (with one flag for maintenance drugs)

#condtion 2.1
test <- data.frame(Gender = rep(c("M"),times=100), Sbscr_Ind = rep(c("1"), times = 100), M16_Maintenance_Flag = rep(c("0","1"), each = 50),  Age = rep(c(21:70),2))
prob.test <- cbind (test,predict (EL16, newdata = test, type="probs", se = TRUE))
prob.test2 <- melt(prob.test, id.vars = c("Age","M16_Maintenance_Flag"), measure.vars= c("1","2","3","4"))

print(ggplot(prob.test2, aes (x=Age, y = value, colour = M16_Maintenance_Flag)) + geom_line () + facet_grid(variable ~ ., scales = "free")
      + labs (x = "age", y="probability", colour = "Maintenance Drug"))


#DESCRIPTIVE SUMMARY: CHARTS
#1.1 Thyroid drug use and engagement level
print(ggplot(eng_month16, aes(M16_ThyroidPreps, fill=PA_Quartile_M16)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"), name= "Engagement level")
      + labs (x="Thyroid drug use", y = "proportion of members"))

#1.2 cardio vascular drug use and engagement level
print(ggplot(eng_month16, aes(M16_Cardiovascular, fill=PA_Quartile_M16)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"), name= "Engagement level")
      + labs (x="Cardiovascular drug use", y = "proportion of members"))

#2.1 maintenance medication and engagement level
print(ggplot(eng_month16, aes(M16_Maintenance_Flag, fill=PA_Quartile_M16)) + geom_bar(position="fill") + scale_fill_manual(values= c("#999999","#E69F00","#009E73","#0072B2"), name= "Engagement level")
      + labs (x="Maintenance medication", y = "proportion of members"))


############
#[C.] MLR per engagement level grp (using 6-month data)
############

#average steps: boxplots
steps <- ggplot (eng_month16,aes(PA_Quartile_M16,AvgStepsPerMbr1))
steps + geom_boxplot () + xlab ("Quartile of portion of active days") + ylab ("average steps per day")


#logged avg steps per day
eng_month16$LoggedAvgSteps <- log(eng_month16$AvgStepsPerMbr1) 

#checking distribution (for normality assumption)
hist(eng_month16$AvgStepsPerMbr1)
hist(eng_month16$LoggedAvgSteps)

#quartiles
q1 <- eng_month16[eng_month16$PA_Quartile_M16=='1',]
q2 <- eng_month16[eng_month16$PA_Quartile_M16=='2',]
q3 <- eng_month16[eng_month16$PA_Quartile_M16=='3',]
q4 <- eng_month16[eng_month16$PA_Quartile_M16=='4',]

nrow(q1)#2603
nrow(q2)#2603
nrow(q3)#2602
nrow(q4)#2602


#using 7 drug classes as predictors
Q1 <- lm(LoggedAvgSteps ~   Gender + Sbscr_Ind 
         + M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
         + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = q1)
summary(Q1)

Q2 <- lm(LoggedAvgSteps ~   Gender + Sbscr_Ind 
         + M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
         + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = q2)
summary(Q2)

Q3 <- lm(LoggedAvgSteps ~   Gender + Sbscr_Ind 
         + M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
         + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = q3)
summary(Q3)

Q4 <- lm(LoggedAvgSteps ~   Gender + Sbscr_Ind 
         + M16_Antihyperglycemics + M16_Cardiovascular + M16_ThyroidPreps 
         + M16_AntiparkinsonDrugs + M16_CNSDrugs + M16_CardiacDrugs + M16_Diuretics, data = q4)
summary(Q4)


############
#[D.] Motion enrollees and maintenance drug users: engagement level and drug spending
############

#enrollees on maintenance medication while in Motion (limiting to members with at least 4 months of enr in Motion)
nrow(eng[eng$ME_Maintenance_Flag =="1",]) #9153
enr <- eng[eng$MotionEnr_Dur_Month > 3 & eng$ME_Maintenance_Flag =="1",] 
nrow(enr) #(9072 out of 9153 members)

#adding enr gr
enr$EnrGr <- ifelse(enr$MotionEnr_Dur_Month <= 9, "4_9",
                        ifelse(enr$MotionEnr_Dur_Month <= 12, "10_12", ">1yr"))
table(enr$EnrGr)


#adding engagement gr
enr$EngGr <- ifelse(enr$Portion_ActiveDays <= 0.25, "<=0.25",
                    ifelse(enr$Portion_ActiveDays <= 0.50, "<=0.50", ">0.50"))
table(enr$EngGr)

#adding levels
enr$EnrGr <- factor(enr$EnrGr, levels = c("4_9","10_12",">1yr"))
enr$EngGr <- factor(enr$EngGr, levels = c("<=0.25","<=0.50",">0.50"))
table(enr$EnrGr,enr$EngGr)


#average monthly Rx spending  during Motion enrollment
print(ggplot(data = enr,aes(x=EnrGr,y=log(ME_AvgMonthly_Rx_Allow+1))) + geom_boxplot (aes(fill=EngGr))
        + labs (x= "Months of enrollment", y = "Average monthly Rx spending", fill = "Engagement level"))

#summary stat for average monthly Rx spending during Motion enrollment
summary(enr[enr$EnrGr=="4_9" & enr$EngGr =="<=0.25","ME_AvgMonthly_Rx_Allow"])
summary(enr[enr$EnrGr=="4_9" & enr$EngGr =="<=0.50","ME_AvgMonthly_Rx_Allow"])
summary(enr[enr$EnrGr=="4_9" & enr$EngGr ==">0.50","ME_AvgMonthly_Rx_Allow"])

summary(enr[enr$EnrGr=="10_12" & enr$EngGr =="<=0.25","ME_AvgMonthly_Rx_Allow"])
summary(enr[enr$EnrGr=="10_12" & enr$EngGr =="<=0.50","ME_AvgMonthly_Rx_Allow"])
summary(enr[enr$EnrGr=="10_12" & enr$EngGr ==">0.50","ME_AvgMonthly_Rx_Allow"])

summary(enr[enr$EnrGr==">1yr" & enr$EngGr =="<=0.25","ME_AvgMonthly_Rx_Allow"])
summary(enr[enr$EnrGr==">1yr" & enr$EngGr =="<=0.50","ME_AvgMonthly_Rx_Allow"])
summary(enr[enr$EnrGr==">1yr" & enr$EngGr ==">0.50","ME_AvgMonthly_Rx_Allow"])


#summary stat for age of maintenance drug users
summary(eng_month1[eng_month1$M1_Maintenance_Flag ==1,"Age"])     #1 month prior to enr in Motion
summary(eng_month16[eng_month16$M16_Maintenance_Flag ==1,"Age"])  #6 months prior to enr in Motion
summary(eng[eng$ME_Maintenance_Flag ==1,"Age"])                   #Motion enrollment period


#**************** NOTHING FOLLOWS ***************************************************************************
#************************************************************************************************************
