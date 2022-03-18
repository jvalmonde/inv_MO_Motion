library(RODBC)
library(data.table)
library(ggplot2)
library(dplyr)
library(cvTools)
library(AUC)
library(lme4)

db <- odbcConnect(dsn = "devsql10")
dat <- data.table(sqlQuery(db, "Select * From pdb_PharmaMotion..KT_G1061_MotionEnrModeling_Dataset", as.is = T))

#######################
#   First Iteration   #
#################################
# Predicting overall enrollment #
# Given only the Demographics   #
#################################

# The specific columns needed
sub_dat_1 <- subset(dat, select = c("MemberID", "Age" , "Gender", "Sbscr_Ind","MotionEnrFlag_StepBased", "MotionEnr_MonthInd", "PolicyID"))

# Fixing Data Types
sub_dat_1[, 3:5] <- lapply(sub_dat_1[,3:5], as.factor)
dat$PolicyID <- as.numeric(dat$PolicyID)


demo_only <- glmer(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + (1|PolicyID),family = binomial, data = sub_dat_1)
summary(demo_only)


#######################
#  Second Iteration   #
##############################################################
#  Predicting enrollment during the 2nd month of eligibilty  #
#  Given Demographics and Drug Use during the first month.   #
##############################################################

# Subsetting data to information needed only
sub_dat_2 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M1_Antihyperglycemics" ,"M1_Cardiovascular","M1_ThyroidPreps","M1_CNSDrugs", "M1_CardiacDrugs", "M1_Diuretics","M1_AntiparkinsonDrugs", "PolicyID" )) # dat[, c(1,5:8, 34:50)]

# Editing the enrollment flag for members who enrolled AFTER the second month to 0
sub_dat_2$enrollment_flag <- ifelse(sub_dat_1$MotionEnr_MonthInd == 2, 1,0)
sub_dat_2$enrollment_flag <- as.factor(sub_dat_2$enrollment_flag)

# Taking out members who enrolled in the first month 
sub_dat_2 <- filter(sub_dat_2, MotionEnr_MonthInd != 1) # 95048-8770 = 86278

# Fixing Data types
sub_dat_2[, c(3:4, 6:14)] <- lapply(sub_dat_2[, c(3:4, 6:14)], as.factor)

# Mixed effects model random on company
Second_Month_Enrollment_glm <- glmer(enrollment_flag~ Age + Gender + Sbscr_Ind + M1_Antihyperglycemics + M1_Cardiovascular + M1_ThyroidPreps + M1_CNSDrugs + M1_CardiacDrugs + M1_Diuretics +M1_AntiparkinsonDrugs + (1|PolicyID),family=binomial, data = sub_dat_2)

summary(Second_Month_Enrollment_glm)


# Creating Model for Second Month Enrollment using only member demographics
Second_Month_Enrollment_glm_2 <- glmer(enrollment_flag~ Age + Gender + Sbscr_Ind + (1|PolicyID) ,family=binomial, data = sub_dat_2)

summary(Second_Month_Enrollment_glm_2)

#######################
#   Third Iteration   #
#################################################
# Using demographics and Drug use data to model #
# third month enrollment                        #
#################################################

# Subsetting only to information needed
sub_dat_3 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M12_Antihyperglycemics" ,"M12_Cardiovascular","M12_ThyroidPreps","M12_CNSDrugs", "M12_CardiacDrugs", "M12_Diuretics", "M12_AntiparkinsonDrugs", "PolicyID" ))

# Filtering out members who enrolled in the second month and in the first month
sub_dat_3 <- filter(sub_dat_3, MotionEnr_MonthInd != 1 , MotionEnr_MonthInd !=2) # 95048-8770-5656=80622

# Fixing Data types
sub_dat_3[, c(3:4, 6:12)] <- lapply(sub_dat_3[, c(3:4, 6:12)], as.factor)

# Modifiying enrollment flag for members who didnt enroll yet
sub_dat_3$enrollment_flag <- ifelse(sub_dat_3$MotionEnr_MonthInd==3,1,0)
sub_dat_3$enrollment_flag <- as.factor(sub_dat_3$enrollment_flag)

# Third iteration of model
Third_Month_Enrollment_glm <- glmer(enrollment_flag~Age + Gender + Sbscr_Ind + M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics + M12_AntiparkinsonDrugs + (1|PolicyID), data= sub_dat_3, family=binomial)
summary(Third_Month_Enrollment_glm)

# Creating model that predicts third month enrollment using only demographics
Third_Month_Enrollment_glm_2 <- glmer(enrollment_flag~Age + Gender + Sbscr_Ind + (1|PolicyID) , data= sub_dat_3, family=binomial)
summary(Third_Month_Enrollment_glm_2)

# Generalized linear mixed model fit by maximum likelihood (Laplace Approximation) ['glmerMod']
# Family: binomial  ( logit )
# Formula: enrollment_flag ~ Age + Gender + Sbscr_Ind + (1 | PolicyID)
# Data: sub_dat_3
# 
# AIC      BIC   logLik deviance df.resid 
# 12241.4  12287.9  -6115.7  12231.4    80617 
# 
# Scaled residuals: 
#   Min      1Q  Median      3Q     Max 
# -1.6424 -0.0272 -0.0214 -0.0174 11.4904 
# 
# Random effects:
#   Groups   Name        Variance Std.Dev.
# PolicyID (Intercept) 16.59    4.073   
# Number of obs: 80622, groups:  PolicyID, 3617
# 
# Fixed effects:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept) -8.982941   0.264697  -33.94  < 2e-16 ***
#   Age          0.022592   0.002401    9.41  < 2e-16 ***
#   GenderM     -0.476362   0.067916   -7.01 2.32e-12 ***
#   Sbscr_Ind1   0.926366   0.080973   11.44  < 2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# Correlation of Fixed Effects:
#   (Intr) Age    GendrM
# Age        -0.419              
# GenderM    -0.028  0.074       
# Sbscr_Ind1 -0.167 -0.225 -0.436
# convergence code: 0

#####################################
#           FOURTH ITERATION        #
#################################################
# Using demographics and Drug use data to model #
# enrollment from the fourth month until the    #
# twelfth month.                                #
#################################################


# Subsetting only to information needed
sub_dat_4 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M12_Antihyperglycemics" ,"M12_Cardiovascular","M12_ThyroidPreps","M12_CNSDrugs", "M12_CardiacDrugs", "M12_Diuretics", "M12_AntiparkinsonDrugs", "PolicyID"))

# Filtering out members who enrolled in the second month and in the first month
sub_dat_4 <- filter(sub_dat_4, MotionEnr_MonthInd != 1 , MotionEnr_MonthInd !=2) # 95048-8770-5656- = 80622


# Fixing Data types
sub_dat_4[, c(3:4, 6:12)] <- lapply(sub_dat_4[, c(3:4, 6:12)], as.factor)


# fourth Iteration of the model
Fourth_Month_Up_Enrollment_glm <- glmer(MotionEnrFlag_StepBased~Age + Gender + Sbscr_Ind + M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics + M12_AntiparkinsonDrugs + (1|PolicyID),family=binomial, data = sub_dat_4)
summary(Fourth_Month_Up_Enrollment_glm)

# Generalized linear mixed model fit by maximum likelihood (Laplace Approximation) ['glmerMod']
# Family: binomial  ( logit )
# Formula: MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + M12_Antihyperglycemics +  
#   M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs +      M12_Diuretics + M12_AntiparkinsonDrugs + (1 | PolicyID)
# Data: sub_dat_4
# 
# AIC      BIC   logLik deviance df.resid 
# 47770.6  47882.1 -23873.3  47746.6    80610 
# 
# Scaled residuals: 
#   Min      1Q  Median      3Q     Max 
# -3.6285 -0.3082 -0.1340 -0.0802 12.0671 
# 
# Random effects:
#   Groups   Name        Variance Std.Dev.
# PolicyID (Intercept) 4.556    2.135   
# Number of obs: 80622, groups:  PolicyID, 3617
# 
# Fixed effects:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept)             -4.78596    0.07389  -64.77  < 2e-16 ***
#   Age                      0.01844    0.00110   16.76  < 2e-16 ***
#   GenderM                 -0.67076    0.02984  -22.48  < 2e-16 ***
#   Sbscr_Ind1               1.39959    0.03548   39.45  < 2e-16 ***
#   M12_Antihyperglycemics1  0.01355    0.07864    0.17 0.863157    
# M12_Cardiovascular1      0.08185    0.04537    1.80 0.071197 .  
# M12_ThyroidPreps1        0.25559    0.07067    3.62 0.000299 ***
#   M12_CNSDrugs1           -0.12875    0.08825   -1.46 0.144569    
# M12_CardiacDrugs1       -0.11264    0.08691   -1.30 0.194962    
# M12_Diuretics1           0.01004    0.09241    0.11 0.913499    
# M12_AntiparkinsonDrugs  -0.01552    0.29886   -0.05 0.958592    
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# Correlation of Fixed Effects:
#   (Intr) Age    GendrM Sbs_I1 M12_A1 M12_C1 M12_TP M12_CN M12_CD M12_D1
# Age         -0.593                                                               
# GenderM     -0.077  0.049                                                        
# Sbscr_Ind1  -0.196 -0.201 -0.428                                                 
# M12_Anthyp1  0.007 -0.026 -0.001  0.000                                          
# M12_Crdvsc1  0.106 -0.227 -0.064  0.023 -0.257                                   
# M12_ThyrdP1 -0.016 -0.077  0.102  0.035 -0.031 -0.062                            
# M12_CNSDrg1 -0.011 -0.028  0.040  0.014 -0.016 -0.044 -0.030                     
# M12_CrdcDr1  0.033 -0.054 -0.022  0.006 -0.025 -0.219  0.004 -0.003              
# M12_Dirtcs1  0.000 -0.032  0.045  0.002 -0.037 -0.133 -0.034 -0.038 -0.102       
# M12_AntprkD  0.004 -0.027  0.002  0.021  0.011 -0.012 -0.012 -0.064 -0.003 -0.005
# convergence code: 0

# Similar to the fourth iteration, but using only member demographics
Fourth_Month_Up_Enrollment_glm_2 <- glmer(MotionEnrFlag_StepBased~Age + Gender + Sbscr_Ind + (1|PolicyID),family=binomial, data = sub_dat_4)
summary(Fourth_Month_Up_Enrollment_glm_2)

# Generalized linear mixed model fit by maximum likelihood (Laplace Approximation) ['glmerMod']
# Family: binomial  ( logit )
# Formula: MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + (1 | PolicyID)
# Data: sub_dat_4
# 
# AIC      BIC   logLik deviance df.resid 
# 47773.7  47820.1 -23881.8  47763.7    80617 
# 
# Scaled residuals: 
#   Min      1Q  Median      3Q     Max 
# -3.6504 -0.3091 -0.1341 -0.0805 11.9571 
# 
# Random effects:
#   Groups   Name        Variance Std.Dev.
# PolicyID (Intercept) 4.519    2.126   
# Number of obs: 80622, groups:  PolicyID, 3617
# 
# Fixed effects:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept) -4.764516   0.073033  -65.24   <2e-16 ***
#   Age          0.018484   0.001046   17.67   <2e-16 ***
#   GenderM     -0.689949   0.029552  -23.35   <2e-16 ***
#   Sbscr_Ind1   1.399220   0.035412   39.51   <2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# Correlation of Fixed Effects:
#   (Intr) Age    GendrM
# Age        -0.589              
# GenderM    -0.067  0.046       
# Sbscr_Ind1 -0.200 -0.200 -0.436
# convergence code: 0
