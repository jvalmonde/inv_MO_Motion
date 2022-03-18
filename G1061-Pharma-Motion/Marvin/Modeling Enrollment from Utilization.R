library(RODBC)
library(data.table)
library(ggplot2)
library(dplyr)
library(cvTools)
library(AUC)


db <- odbcConnect(dsn = "devsql10")
dat <- data.table(sqlQuery(db, "Select * From pdb_PharmaMotion..KT_G1061_MotionEnrModeling_Dataset", as.is = T))

## Counter- Checking Summary Stats ##

# Number of Non-enrolless or non-walkers: 69,711
nrow(dat[which(MotionEnrFlag_StepBased == 0 & MotionEnr_MonthInd == 0)])
# 69,711

# Number of members who enrolled in Motion after 14 months of eligibility: 1,153
nrow(dat[which(MotionEnrFlag_StepBased == 1 & MotionEnr_MonthInd == 0)])
#1153

# Number of members who enrolledin Motion during the first month of eligibility: 8,770
nrow(dat[which(MotionEnrFlag_StepBased == 1 & MotionEnr_MonthInd == 1)])
#8770

# Number of members who enrolled in Motion in the second month of eligibility: 5,656
nrow(dat[which(MotionEnrFlag_StepBased == 1 & MotionEnr_MonthInd == 2)])
# 5656

# Number of members who enrolled in Motion in the third month of eligibility: 1,532
nrow(dat[which(MotionEnrFlag_StepBased == 1 & MotionEnr_MonthInd == 3)])
#1532

# Number of members who enrolledin Motion BETWEEN THE 3RD MONTH AND THE 14TH month of eligibility: 8226
nrow(dat[which(MotionEnrFlag_StepBased == 1 & (MotionEnr_MonthInd >3 & MotionEnr_MonthInd <= 14) )])
# 8226

#######################
#   First Iteration   #
#################################
# Predicting overall enrollment #
# Given only the Demographics   #
#################################

# The specific columns needed
sub_dat_1 <- subset(dat, select = c("MemberID", "Age" , "Gender", "Sbscr_Ind","MotionEnrFlag_StepBased", "MotionEnr_MonthInd"))

# Fixing Data Types
sub_dat_1[, 3:5] <- lapply(sub_dat_1[,3:5], as.factor)

# Creating a model that predicts enrollment during the first month of eligibility
Overall_Enrollment_glm <- glm(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind, family = binomial, data =  sub_dat_1)#_train)
summary(Overall_Enrollment_glm )


# Call:
#   glm(formula = MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind, 
#       family = binomial, data = sub_dat_1)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.3162  -0.8304  -0.6973   1.2588   2.2117  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept) -2.1825547  0.0295124  -73.95   <2e-16 ***
#   Age          0.0159329  0.0005966   26.71   <2e-16 ***
#   GenderM     -0.5868937  0.0164935  -35.58   <2e-16 ***
#   Sbscr_Ind    1.0851621  0.0204678   53.02   <2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 110221  on 95047  degrees of freedom
# Residual deviance: 105273  on 95044  degrees of freedom
# AIC: 105281
# 
# Number of Fisher Scoring iterations: 4

# Predicting the enrollment -- overall
y_pred <- ifelse(predict(Overall_Enrollment_glm , subset(sub_dat_1, select = c("Age", "Gender", "Sbscr_Ind")), type = "response") > 0.5,1,0)
#head(y_pred)

# Calculating Accuracy- overall
round(sum(y_pred == sub_dat_1$MotionEnrFlag_StepBased)/nrow(sub_dat_1)*100,4)
# 73.2556

# Predicting enrollment for the specific members who enrolled in the first month of eligilibty 
y_pred_month1 <- ifelse(predict(Overall_Enrollment_glm,subset(sub_dat_1_holdout, select = c("Age", "Gender", "Sbscr_Ind")), type = "response") > 0.5,1,0)


# Calculating the accuracy - specific members who enrolled in the first month of eligibility
round(( sum(y_pred_month1==sub_dat_1_holdout$MotionEnrFlag_StepBased)  /nrow(sub_dat_1_holdout))*100,4)
# 0.1254

# Creating holdout set prep
sub_dat_1$holdoutpred <- rep(0, nrow(sub_dat_1))
sub_dat_1$prediction_proby <- 0

# AUC placeholder
auc_overall <- c()

# 10-fold CV
set.seed(17)
folds <- cvFolds(NROW(sub_dat_1), K = 10)
for(i in 1:10){
  # Setting the training set
  train <- sub_dat_1[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_1[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind, data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  # Put the hold out prediction in the data set for later use
  sub_dat_1[folds$subsets[folds$which ==i],]$holdoutpred <- new_pred
  
  # Saving the prediciton probabilities
  sub_dat_1[folds$subsets[folds$which ==i],]$prediction_proby <- predict(logReg, newdata = validation, type = "response")

  # Creating ROC object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$MotionEnrFlag_StepBased)
  
  # calculating this iteration's auc
  auc_i <- auc(roc_obj)
  
  # storing auc in AUC placeholder
  
  auc_overall <- c(auc_overall, auc_i)
  
}
# Calculating AUC based on predicted probabilities from the 10-fold 
auc(roc(sub_dat_1$prediction_proby, sub_dat_1$MotionEnrFlag_StepBased))
#0.6338784
plot(roc(sub_dat_1$prediction_proby, sub_dat_1$MotionEnrFlag_StepBased), main = "Overall Enrollment")

# Accuracy - 0.5
sum(sub_dat_1$MotionEnrFlag_StepBased == sub_dat_1$holdoutpred)/nrow(sub_dat_1)
# 0.7326193
sum((sub_dat_1$prediction_proby>=0.5) == as.numeric(as.character(sub_dat_1$MotionEnrFlag_StepBased)))/nrow(sub_dat_1)
#0.7326193

# confusion matrix - 0.5
# confusion matrix - 0.267



# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_1$MotionEnrFlag_StepBased, x = factor(ifelse(sub_dat_1$prediction_proby>0.5,1,0), levels =c(0,1)))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0.8918965

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9984507

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_1$MotionEnrFlag_StepBased, x = ifelse(sub_dat_1$prediction_proby>0.267,1,0))

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.5773399

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.001223507

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9984507


# Mean AUC
mean(auc_overall)
# 0.6338998

# Creating ROCs
roc_overall <- roc(predict(Overall_Enrollment_glm, sub_dat_1), sub_dat_1$MotionEnrFlag_StepBased)
plot(roc_overall, main = "ROC - Overall Enrollment")
auc(roc_overall)
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
sub_dat_2[, c(3:4, 6:13)] <- lapply(sub_dat_2[, c(3:4, 6:13)], as.factor)
sub_dat_2$PolicyID <- as.factor(sub_dat_2$PolicyID)


# Second Iteration of the model
Second_Month_Enrollment_glm <- glm(enrollment_flag~ Age + Gender + Sbscr_Ind + M1_Antihyperglycemics + M1_Cardiovascular + M1_ThyroidPreps + M1_CNSDrugs + M1_CardiacDrugs + M1_Diuretics +M1_AntiparkinsonDrugs  ,family=binomial, data = sub_dat_2)
summary(Second_Month_Enrollment_glm)

# Call:
#   glm(formula = enrollment_flag ~ Age + Gender + Sbscr_Ind + M1_Antihyperglycemics + 
#         M1_Cardiovascular + M1_ThyroidPreps + M1_CNSDrugs + M1_CardiacDrugs + 
#         M1_Diuretics + M1_AntiparkinsonDrugs, family = binomial, 
#       data = sub_dat_2)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -0.6710  -0.4050  -0.3527  -0.2850   2.7392  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
#   (Intercept)            -3.652009   0.055822 -65.422   <2e-16 ***
#   Age                     0.013024   0.001130  11.521   <2e-16 ***
#   GenderM                -0.479481   0.029811 -16.084   <2e-16 ***
#   Sbscr_Ind1              0.916385   0.038733  23.659   <2e-16 ***
#   M1_Antihyperglycemics1  0.012169   0.111232   0.109    0.913    
#   M1_Cardiovascular1     -0.008817   0.062534  -0.141    0.888    
#   M1_ThyroidPreps1        0.229175   0.097701   2.346    0.019 *  
#   M1_CNSDrugs1            0.048888   0.128679   0.380    0.704    
#   M1_CardiacDrugs1        0.062447   0.124298   0.502    0.615    
#   M1_Diuretics1          -0.094046   0.142539  -0.660    0.509    
#   M1_AntiparkinsonDrugs1 -0.027965   0.427127  -0.065    0.948    
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 41756  on 86277  degrees of freedom
# Residual deviance: 40736  on 86267  degrees of freedom
# AIC: 40758
# 
# Number of Fisher Scoring iterations: 6

# Predicting Outcomes -- For All
y_pred <- ifelse(predict(Second_Month_Enrollment_glm , subset(sub_dat_2, select = c("Age", "Gender", "Sbscr_Ind", "M1_Antihyperglycemics" ,"M1_Cardiovascular","M1_ThyroidPreps", "M1_CNSDrugs", "M1_CardiacDrugs", "M1_Diuretics" )), type = "response") > 0.5,1,0)


# Calculating Accuracy -- For All
round(sum(y_pred == sub_dat_2$MotionEnrFlag_StepBased)/nrow(sub_dat_2)*100,4)
# 80.797

# Predicting Outcomes -- For enrolled during second month of eligibility
y_pred_month2 <- ifelse(predict(Second_Month_Enrollment_glm , subset(sub_dat_2_holdout, select = c("Age", "Gender", "Sbscr_Ind", "M1_Antihyperglycemics" ,"M1_Cardiovascular","M1_ThyroidPreps", "M1_CNSDrugs", "M1_CardiacDrugs", "M1_Diuretics")), type = "response") > 0.5,1,0)

# Calculating Accuracy -- For enrolled during second month of eligibilty
round(sum(y_pred_month2 == sub_dat_2_holdout$MotionEnrFlag_StepBased)/nrow(sub_dat_2_holdout)*100,4)

# Creating holdout set for the 10fold CV
sub_dat_2$holdoutpred <- 0
sub_dat_2$prediction_proby <- 0

# Creating an empty auc vector
auc_second_month_1 <- c()

# 10 fold CV - log reg with drugs
set.seed(17)
folds <- cvFolds(NROW(sub_dat_2), K = 10)
for(i in 1:10){
  # Setting the training set
  train <- sub_dat_2[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_2[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(enrollment_flag ~ Age + Gender + Sbscr_Ind + M1_Antihyperglycemics + M1_Cardiovascular + M1_ThyroidPreps + M1_CNSDrugs + M1_CardiacDrugs + M1_Diuretics + M1_AntiparkinsonDrugs, data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  # Saving the prediciton probabilities
  sub_dat_2[folds$subsets[folds$which ==i],]$prediction_proby <- predict(logReg, newdata = validation, type = "response")
  
  
  # Put the hold out prediction in the data set for later use
  sub_dat_2[folds$subsets[folds$which ==i],]$holdoutpred <- new_pred
  
  # creating an roc object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$enrollment_flag)
  
  # creating this run's auc calculation
  auc_i <- auc(roc_obj)
  
  # Stroing it in the auc vector
  auc_second_month_1 <- c(auc_second_month_1, auc_i)
}

# Auc from prediction probabilities
auc(roc(sub_dat_2$prediction_proby, sub_dat_2$enrollment_flag))
# 0.6128962

plot(roc(sub_dat_2$prediction_proby, sub_dat_2$enrollment_flag), main = " Second Month : Demo + Drugs")

# Accuracy
sum(sub_dat_2$enrollment_flag == sub_dat_2$holdoutpred)/nrow(sub_dat_2)
# 0.9344445

# Mean auc
mean(auc_second_month_1)
#0.649392


# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_2$enrollment_flag, x = factor(ifelse(sub_dat_2$prediction_proby>0.5,1,0), levels = c(0,1) ) )

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9984507

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_2$enrollment_flag, x = factor(ifelse(sub_dat_2$prediction_proby>0.267,1,0) , levels = c(0,1) ))

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.5773399

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.001223507

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9984507



# Creating Model for Second Month Enrollment using only member demographics
Second_Month_Enrollment_glm_2 <- glm(enrollment_flag~ Age + Gender + Sbscr_Ind   ,family=binomial, data = sub_dat_2)
summary(Second_Month_Enrollment_glm_2)
# Call:
#   glm(formula = enrollment_flag ~ Age + Gender + Sbscr_Ind, family = binomial, 
#       data = sub_dat_2)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -0.6176  -0.4058  -0.3526  -0.2842   2.7389  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept) -3.652161   0.055232  -66.12   <2e-16 ***
#   Age          0.013236   0.001097   12.07   <2e-16 ***
#   GenderM     -0.485053   0.029627  -16.37   <2e-16 ***
#   Sbscr_Ind1   0.914080   0.038695   23.62   <2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 41756  on 86277  degrees of freedom
# Residual deviance: 40742  on 86274  degrees of freedom
# AIC: 40750
# 
# Number of Fisher Scoring iterations: 6

# Creating holdout set for the 10fold CV
sub_dat_2$holdoutpred_2 <- 0
sub_dat_2$prediction_proby_2 <- 0

# creating an empty auc vector
auc_second_month_2 <- c()

# 10 fold CV - second month enrollment demographics only
set.seed(17)
folds <- cvFolds(NROW(sub_dat_2), K = 10)
for(i in 1:10){
  # Setting the training set
  train <- sub_dat_2[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_2[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(enrollment_flag ~ Age + Gender + Sbscr_Ind, data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  
  # Saving the prediciton probabilities
  sub_dat_2[folds$subsets[folds$which ==i],]$prediction_proby_2 <- predict(logReg, newdata = validation, type = "response")
  
  
  # Put the hold out prediction in the data set for later use
  sub_dat_2[folds$subsets[folds$which ==i],]$holdoutpred_2 <- new_pred
  
  # Creating an ROC object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$enrollment_flag)
  
  # Creating this runs'auc
  auc_i <- auc(roc_obj)
  
  # Stroing auc in the empty auc vector
  auc_second_month_2 <- c(auc_second_month_2, auc_i)
}

# AUC from prediction probabilities
auc(roc(sub_dat_2$prediction_proby_2, sub_dat_2$enrollment_flag))
# 0.6136097

plot(roc(sub_dat_2$prediction_proby_2, sub_dat_2$enrollment_flag), main = "Scond Month: Demo only")

# Accuracy
sum(sub_dat_2$enrollment_flag == sub_dat_2$holdoutpred_2)/nrow(sub_dat_2)
# 0.8079812

# Calculatin mean auc
mean(auc_second_month_2)
# 0.6281212

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_2$enrollment_flag, x = factor(ifelse(sub_dat_2$prediction_proby_2 >0.5,1,0), levels = c(0,1) ))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9984507

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_2$enrollment_flag, x = factor(ifelse(sub_dat_2$prediction_proby_2>0.267,1,0), levels = c(0,1) ))

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.5773399

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.001223507

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9984507


# Drop in deviance test
anova(Second_Month_Enrollment_glm_2, Second_Month_Enrollment_glm, type = "Chisq")

# Creating ROCs
roc_secondmonth_1 <- roc(predict(Second_Month_Enrollment_glm, newdata = sub_dat_2, type = "response"), sub_dat_2$enrollment_flag)
plot(roc_secondmonth_1, col = "blue", main = "ROC - Second Month Enrollment")
auc(roc_secondmonth_1)
roc_secondmonth_2 <- roc(predict(Second_Month_Enrollment_glm_2, newdata = sub_dat_2, type = "response"), sub_dat_2$enrollment_flag)
plot(roc_secondmonth_2, add=T, col = "red")
par(xpd=T)
legend(2.8,
       1,
       c("Demo only (auc = 0.6144)", "Demo + Drugs (auc = 0.6143)"),
       col = c("blue", "red"))
auc(roc_secondmonth_2)
#######################
#   Third Iteration   #
#################################################
# Using demographics and Drug use data to model #
# third month enrollment                        #
#################################################

# Subsetting only to information needed
sub_dat_3 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M12_Antihyperglycemics" ,"M12_Cardiovascular","M12_ThyroidPreps","M12_CNSDrugs", "M12_CardiacDrugs", "M12_Diuretics", "M12_AntiparkinsonDrugs" ))

# Filtering out members who enrolled in the second month and in the first month
sub_dat_3 <- filter(sub_dat_3, MotionEnr_MonthInd != 1 , MotionEnr_MonthInd !=2) # 95048-8770-5656=80622

# Fixing Data types
sub_dat_3[, c(3:4, 6:12)] <- lapply(sub_dat_3[, c(3:4, 6:12)], as.factor)

# Modifiying enrollment flag for members who didnt enroll yet
sub_dat_3$enrollment_flag <- ifelse(sub_dat_3$MotionEnr_MonthInd==3,1,0)
sub_dat_3$enrollment_flag <- as.factor(sub_dat_3$enrollment_flag)

# Third iteration of model
Third_Month_Enrollment_glm <- glm(enrollment_flag~Age + Gender + Sbscr_Ind + M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics + M12_AntiparkinsonDrugs, data= sub_dat_3, family=binomial)
summary(Third_Month_Enrollment_glm)
# 
# Call:
#   glm(formula = enrollment_flag ~ Age + Gender + Sbscr_Ind + M12_Antihyperglycemics + 
#         M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + 
#         M12_Diuretics + M12_AntiparkinsonDrugs, family = binomial, 
#       data = sub_dat_3)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -0.3463  -0.2137  -0.1922  -0.1728   3.0691  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)
# (Intercept)             -4.758662   0.100713 -47.250  < 2e-16
# Age                      0.013704   0.002129   6.436 1.23e-10
# GenderM                 -0.325767   0.056862  -5.729 1.01e-08
# Sbscr_Ind1               0.539974   0.068170   7.921 2.36e-15
# M12_Antihyperglycemics1 -0.318963   0.175072  -1.822   0.0685
# M12_Cardiovascular1      0.088936   0.089700   0.991   0.3215
# M12_ThyroidPreps1        0.181076   0.135894   1.332   0.1827
# M12_CNSDrugs1            0.036775   0.172480   0.213   0.8312
# M12_CardiacDrugs1       -0.122540   0.179169  -0.684   0.4940
# M12_Diuretics1           0.173613   0.173120   1.003   0.3159
# M12_AntiparkinsonDrugs   0.009222   0.586874   0.016   0.9875
# 
# (Intercept)             ***
#   Age                     ***
#   GenderM                 ***
#   Sbscr_Ind1              ***
#   M12_Antihyperglycemics1 .  
# M12_Cardiovascular1        
# M12_ThyroidPreps1          
# M12_CNSDrugs1              
# M12_CardiacDrugs1          
# M12_Diuretics1             
# M12_AntiparkinsonDrugs     
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 15178  on 80621  degrees of freedom
# Residual deviance: 15008  on 80611  degrees of freedom
# AIC: 15030
# 
# Number of Fisher Scoring iterations: 7

y_pred <- ifelse(predict(Third_Month_Enrollment_glm, sub_dat_3, type="response")>0.5,1,0)

sum(y_pred==sub_dat_3$MotionEnrFlag_StepBased)/nrow(sub_dat_3)

# Creating holdout set for the 10fold CV
sub_dat_3$holdoutpred <- rep(0, nrow(sub_dat_3))
sub_dat_3$prediction_proby <- 0

# Creating empty auc vector
auc_third_month_1 <- c()

# 10 fold CV - with drugs as predictors
set.seed(17)
folds <- cvFolds(NROW(sub_dat_3), K = 10)
for(i in 1:10){
  # Setting the training set
  train <- sub_dat_3[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_3[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(enrollment_flag ~ Age + Gender + Sbscr_Ind + M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics, data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  
  # Saving the prediciton probabilities
  sub_dat_3[folds$subsets[folds$which ==i],]$prediction_proby <- predict(logReg, newdata = validation, type = "response")
  
  
  # Put the hold out prediction in the data set for later use
  sub_dat_3[folds$subsets[folds$which ==i],]$holdoutpred <- new_pred
  
  # Creating roc object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$enrollment_flag)
  
  # Calculating this run's auc
  auc_i <- auc(roc_obj)
  
  # Storing this run's auc in the auc vector
  auc_third_month_1 <- c(auc_third_month_1, auc_i)
  
}

auc(roc(sub_dat_3$prediction_proby, sub_dat_3$enrollment_flag))
plot(roc(sub_dat_3$prediction_proby, sub_dat_3$enrollment_flag), main = "Third Month: Demo + Drugs")

# Accuracy
sum(sub_dat_3$enrollment_flag == sub_dat_3$holdoutpred)/nrow(sub_dat_3)
# 0.9809977

# MEan AUC
mean(auc_third_month_1)


# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_3$enrollment_flag, x = factor(ifelse(sub_dat_3$prediction_proby>0.5,1,0), levels= c(0,1)))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9809977

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_3$enrollment_flag, x = factor(ifelse(sub_dat_3$prediction_proby>0.267,1,0), levels= c(0,1)))

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.9809977

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.001223507

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9984507

# Creating model that predicts third month enrollment using only demographics
Third_Month_Enrollment_glm_2 <- glm(enrollment_flag~Age + Gender + Sbscr_Ind  , data= sub_dat_3, family=binomial)
summary(Third_Month_Enrollment_glm_2)

# Call:
#   glm(formula = enrollment_flag ~ Age + Gender + Sbscr_Ind, family = binomial, 
#       data = sub_dat_3)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -0.3180  -0.2139  -0.1924  -0.1730   3.0693  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept) -4.763861   0.098655 -48.288  < 2e-16 ***
#   Age          0.014258   0.002014   7.080 1.44e-12 ***
#   GenderM     -0.336532   0.056206  -5.988 2.13e-09 ***
#   Sbscr_Ind1   0.535419   0.068061   7.867 3.64e-15 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 15178  on 80621  degrees of freedom
# Residual deviance: 15015  on 80618  degrees of freedom
# AIC: 15023
# 
# Number of Fisher Scoring iterations: 7

# Creating holdout set for the 10fold CV
sub_dat_3$holdoutpred_2 <- rep(0, nrow(sub_dat_3))
sub_dat_3$prediction_proby_2 <- 0

# creating an empty auc vector
auc_third_month_2 <- c()

# 10 fold CV - using member demo only
set.seed(17)
folds <- cvFolds(NROW(sub_dat_3), K = 10)

for(i in 1:10){
  # Setting the training set
  train <- sub_dat_3[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_3[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(enrollment_flag ~ Age + Gender + Sbscr_Ind , data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  
  # Saving the prediciton probabilities
  sub_dat_3[folds$subsets[folds$which ==i],]$prediction_proby_2 <- predict(logReg, newdata = validation, type = "response")
  
  
  # Put the hold out prediction in the data set for later use
  sub_dat_3[folds$subsets[folds$which ==i],]$holdoutpred <- new_pred
  
  # Creating roc object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$enrollment_flag)
  
  # Calculating this run's auc
  auc_i <- auc(roc_obj)
  
  # storing this runs'auc
  auc_third_month_2 <- c(auc_third_month_2, auc_i)
}

# AUC
auc(roc(sub_dat_3$prediction_proby_2, sub_dat_3$enrollment_flag))
#0.5771376
plot(roc(sub_dat_3$prediction_proby_2, sub_dat_3$enrollment_flag), main = "Third Month: Demo only")

# Accuracy
sum(sub_dat_3$enrollment_flag == sub_dat_3$holdoutpred_2)/nrow(sub_dat_3)
# 0.9809977

# Mean AUC
mean(auc_third_month_2)
#0.5782048

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_3$enrollment_flag, x = factor(ifelse(sub_dat_3$prediction_proby_2>0.5,1,0), levels=c(0,1) ) )

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9809977

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_3$enrollment_flag, x = factor(ifelse(sub_dat_3$prediction_proby_2>0.267,1,0), levels=c(0,1) ) )

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.9809977

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.001223507

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9984507


# Drop in deviance test
anova(Third_Month_Enrollment_glm_2, Third_Month_Enrollment_glm, type = "Chisq")

# Creating ROC's
roc_thirdMonth_1 <- roc(predict(Third_Month_Enrollment_glm, newdata=sub_dat_3, type = "response"), sub_dat_3$enrollment_flag)
roc_thirdMonth_2 <- roc(predict(Third_Month_Enrollment_glm_2, newdata=sub_dat_3, type = "response"), sub_dat_3$enrollment_flag)
plot(roc_thirdMonth_1, col = "blue", main = "ROC - Third Month Enrollment")
plot(roc_thirdMonth_2, col = "red", add=T)
auc(roc_thirdMonth_1)
auc(roc_thirdMonth_2)

#####################################
#           FOURTH ITERATION        #
#################################################
# Using demographics and Drug use data to model #
# enrollment from the fourth month until the    #
# twelfth month.                                #
#################################################


# Subsetting only to information needed
sub_dat_4 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M12_Antihyperglycemics" ,"M12_Cardiovascular","M12_ThyroidPreps","M12_CNSDrugs", "M12_CardiacDrugs", "M12_Diuretics", "M12_AntiparkinsonDrugs" ))

# Filtering out members who enrolled in the second month and in the first month
sub_dat_4 <- filter(sub_dat_4, MotionEnr_MonthInd != 1 , MotionEnr_MonthInd !=2) # 95048-8770-5656- = 80622


# Fixing Data types
sub_dat_4[, c(3:4, 6:12)] <- lapply(sub_dat_4[, c(3:4, 6:12)], as.factor)


# fourth Iteration of the model
Fourth_Month_Up_Enrollment_glm <- glm(MotionEnrFlag_StepBased~Age + Gender + Sbscr_Ind + M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics + M12_AntiparkinsonDrugs,family=binomial, data = sub_dat_4)
summary(Fourth_Month_Up_Enrollment_glm)

# Call:
#   glm(formula = MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + 
#         M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + 
#         M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics + M12_AntiparkinsonDrugs, 
#       family = binomial, data = sub_dat_4)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.0159  -0.5847  -0.5027  -0.3760   2.5032  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
#   (Intercept)             -2.9242444  0.0415717 -70.342  < 2e-16 ***
#   Age                      0.0147795  0.0008685  17.016  < 2e-16 ***
#   GenderM                 -0.5485371  0.0229191 -23.934  < 2e-16 ***
#   Sbscr_Ind1               0.9802201  0.0286616  34.200  < 2e-16 ***
#   M12_Antihyperglycemics1 -0.0239489  0.0638697  -0.375 0.707687    
#   M12_Cardiovascular1      0.0866608  0.0368661   2.351 0.018738 *  
#   M12_ThyroidPreps1        0.2085948  0.0566696   3.681 0.000232 ***
#   M12_CNSDrugs1           -0.0797133  0.0734441  -1.085 0.277762    
#   M12_CardiacDrugs1       -0.0624331  0.0713956  -0.874 0.381864    
#   M12_Diuretics1           0.0146585  0.0751880   0.195 0.845426    
#   M12_AntiparkinsonDrugs  -0.1206048  0.2574653  -0.468 0.639476    
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 63918  on 80621  degrees of freedom
# Residual deviance: 61673  on 80611  degrees of freedom
# AIC: 61695
# 
# Number of Fisher Scoring iterations: 5

y_pred <- ifelse(predict(Fourth_Month_Up_Enrollment_glm, sub_dat_4, type="response")>0.5,1,0)

sum(y_pred==sub_dat_4$MotionEnrFlag_StepBased)/nrow(sub_dat_4)
# Creating holdout set for the 10fold CV

sub_dat_4$holdoutpred <- rep(0, nrow(sub_dat_4))
sub_dat_4$prediction_proby <- 0
auc_fourth_up_1 <- c()

# 10 fold CV modeling enrollment with demo + drugs
set.seed(17)
folds <- cvFolds(NROW(sub_dat_4), K = 10)
for(i in 1:10){
  # Setting the training set
  train <- sub_dat_4[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_4[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind +M12_Antihyperglycemics + M12_Cardiovascular + M12_ThyroidPreps + M12_CNSDrugs + M12_CardiacDrugs + M12_Diuretics, data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  
  # Saving the prediciton probabilities
  sub_dat_4[folds$subsets[folds$which ==i],]$prediction_proby <- predict(logReg, newdata = validation, type = "response")
  
  
  # Put the hold out prediction in the data set for later use
  sub_dat_4[folds$subsets[folds$which ==i],]$holdoutpred <- new_pred
  
  # Creating roc object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$MotionEnrFlag_StepBased)
  
  # calculating auc
  auc_i <- auc(roc_obj)
  
  #storing auc
  auc_fourth_up_1 <- c(auc_fourth_up_1, auc_i)
}

auc(roc(sub_dat_4$prediction_proby, sub_dat_4$MotionEnrFlag_StepBased))
# 0.6270681
plot(roc(sub_dat_4$prediction_proby, sub_dat_4$MotionEnrFlag_StepBased), main = "Third to Fourteenth Month enrollment : Demo + Drugs")

# Accuracy
sum(sub_dat_4$MotionEnrFlag_StepBased == sub_dat_4$holdoutpred)/nrow(sub_dat_4)
# 0.8646647

mean(auc_fourth_up_1)
# 0.6325859

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_4$MotionEnrFlag_StepBased, x = factor(ifelse(sub_dat_4$prediction_proby>0.5,1,0), levels=c(0,1)))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9809977

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_4$MotionEnrFlag_StepBased, x = factor(ifelse(sub_dat_4$prediction_proby>0.267,1,0), levels=c(0,1)))

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.8527449

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.02960315

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9815811

# Similar to the fourth iteration, but using only member demographics
Fourth_Month_Up_Enrollment_glm_2 <- glm(MotionEnrFlag_StepBased~Age + Gender + Sbscr_Ind,family=binomial, data = sub_dat_4)
summary(Fourth_Month_Up_Enrollment_glm_2)

# Call:
#   glm(formula = MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind, 
#       family = binomial, data = sub_dat_4)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -0.9441  -0.5896  -0.5027  -0.3762   2.5037  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept) -2.9403388  0.0407725  -72.12   <2e-16 ***
#   Age          0.0155883  0.0008217   18.97   <2e-16 ***
#   GenderM     -0.5546736  0.0226724  -24.46   <2e-16 ***
#   Sbscr_Ind1   0.9759460  0.0286095   34.11   <2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 63918  on 80621  degrees of freedom
# Residual deviance: 61694  on 80618  degrees of freedom
# AIC: 61702
# 
# Number of Fisher Scoring iterations: 5

sub_dat_4$holdoutpred_2 <- rep(0, nrow(sub_dat_4))
sub_dat_4$prediction_proby_2 <- 0
auc_fourth_up_2 <- c()

# 10 fold CV modeling enrollment with demo + drugs
set.seed(17)
folds <- cvFolds(NROW(sub_dat_4), K = 10)
for(i in 1:10){
  # Setting the training set
  train <- sub_dat_4[folds$subsets[folds$which !=i],]   
  
  # setting the Validation set
  validation <- sub_dat_4[folds$subsets[folds$which ==i],]      
  
  # Fitting on Train Data
  logReg <- glm(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind , data = train, family = binomial)
  
  # Get the predictions for the validation set
  new_pred <- ifelse(predict(logReg, newdata = validation, type = "response")>0.5,1,0)
  
  
  # Saving the prediciton probabilities
  sub_dat_4[folds$subsets[folds$which ==i],]$prediction_proby_2 <- predict(logReg, newdata = validation, type = "response")
  
  
  # Put the hold out prediction in the data set for later use
  sub_dat_4[folds$subsets[folds$which ==i],]$holdoutpred_2 <- new_pred
  
  # Creating roc object
  roc_obj <- roc(predict(logReg, newdata = validation, type = "response"), validation$MotionEnrFlag_StepBased)
  
  # calculating auc
  auc_i <- auc(roc_obj)
  
  #storing auc
  auc_fourth_up_2 <- c(auc_fourth_up_2, auc_i)
}

auc(roc(sub_dat_4$prediction_proby_2, sub_dat_4$MotionEnrFlag_StepBased))
# 0.6263371
plot(roc(sub_dat_4$prediction_proby_2, sub_dat_4$MotionEnrFlag_StepBased), main = "Third to Fourteenth Month enrollment : Demo only")


# Accuracy
sum(sub_dat_4$MotionEnrFlag_StepBased == sub_dat_4$holdoutpred_2)/nrow(sub_dat_4)
# 0.8646647

mean(auc_fourth_up_2)
#0.6264886

#drop in deviance test
anova(Fourth_Month_Up_Enrollment_glm_2, Fourth_Month_Up_Enrollment_glm)

# Creating ROC's
roc_fourthMonth_1 <- roc(predict(Fourth_Month_Up_Enrollment_glm, newdata=sub_dat_4, type = "response"), sub_dat_3$MotionEnrFlag_StepBased)
roc_fourthMonth_2 <- roc(predict(Fourth_Month_Up_Enrollment_glm_2, newdata=sub_dat_4, type = "response"), sub_dat_3$MotionEnrFlag_StepBased)
plot(roc_fourthMonth_1, col = "blue", main = "ROC - Third Month Enrollment")
plot(roc_fourthMonth_2, col = "red", add=T)
auc(roc_fourthMonth_1)
auc(roc_fourthMonth_2)

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = sub_dat_4$MotionEnrFlag_StepBased, x = factor(ifelse(sub_dat_4$prediction_proby_2>0.5,1,0), levels = c(0,1)))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0.001223507

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9809977

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = sub_dat_4$MotionEnrFlag_StepBased, x = factor(ifelse(sub_dat_4$prediction_proby_2>0.267,1,0), levels = c(0,1)))

# accuracy - 0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.8528938

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.02676198

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
#  0.9821979


###################################
# Using Random Forests to predict #
# Enrollment. Redoing iterations  #
###################################
library(randomForest)

#######################
#   First Iteration   #
#################################
# Predicting overall enrollment #
# Given only the Demographics   #
#################################

# # Fixing data types
# sub_dat_1$MotionEnrFlag_StepBased <- as.factor(as.character(sub_dat_1$MotionEnrFlag_StepBased))
# sub_dat_1$Gender <- as.factor(sub_dat_1$Gender)

# Creating train/test split for the model
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_1),
                  replace=T,
                  prob = (c(0.75,0.25)))
sub_dat_1_train <- sub_dat_1[indices==1,]
sub_dat_1_test <- sub_dat_1[indices==2,]

# Creating the Fromula [object]
varNames <- names(sub_dat_1)
varNames <- varNames[!varNames %in% c("MemberID", "MotionEnrFlag_StepBased", "MotionEnr_MonthInd", "holdoutpred")]
varNames1 <- paste(varNames, collapse = "+")
RF.formula <- as.formula(paste("MotionEnrFlag_StepBased", varNames1, sep = "~"))

# Creating Random Forest to predict enrollment
set.seed(17)
Overall_enrollment_RF <- randomForest(RF.formula,
                                      sub_dat_1_train[, c( "Age", "Gender", "Sbscr_Ind", "MotionEnrFlag_StepBased")],
                                      ntree=100,
                                      importance=T)
plot(Overall_enrollment_RF)


# Variable Importance
varImpPlot(Overall_enrollment_RF,
           sort=T,
           main = "Variable Importance")

# Variable importance table
var.imp <- data.frame(importance(Overall_enrollment_RF, type = 2))

# Make row names as columns
var.imp$Variables <- row.names(var.imp)
var.imp[order(var.imp$MeanDecreaseGini, decreasing = T),]

rf_pred <- predict(Overall_enrollment_RF, newdata = sub_dat_1_test) 
sum(rf_pred==sub_dat_1_test$MotionEnrFlag_StepBased)/nrow(sub_dat_1_test)
#0.7340821

#######################
#  Second Iteration   #
##############################################################
#  Predicting enrollment during the 2nd month of eligibilty  #
#  Given Demographics and Drug Use during the first month.   #
##############################################################

# # Fixing data types
# sub_dat_2$MotionEnrFlag_StepBased <- as.factor(as.character(sub_dat_2$MotionEnrFlag_StepBased))
# sub_dat_2$Gender <- as.factor(sub_dat_2$Gender)
# sub_dat_2[,7:12] <- lapply(sub_dat_2[,7:12], as.factor)

# Creating train/test split for the model
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_2),
                  replace=T,
                  prob = (c(0.75,0.25)))
sub_dat_2_train <- sub_dat_2[indices==1,]
sub_dat_2_test <- sub_dat_2[indices==2,]

# Creating the Fromula [object]
varNames <- names(sub_dat_2)
varNames <- varNames[!varNames %in% c("MemberID",  "MotionEnrFlag_StepBased","enrollment_flag","MotionEnr_MonthInd", "holdoutpred", "holdoutpred_2")]
varNames1 <- paste(varNames, collapse = "+")
RF.formula <- as.formula(paste("enrollment_flag", varNames1, sep = "~"))

# Creating RF
set.seed(17)
Second_Month_enrollment_RF <- randomForest(RF.formula,
                                      sub_dat_2_train[, c( "Age", "Gender", "Sbscr_Ind", "enrollment_flag","M1_Antihyperglycemics", "M1_Cardiovascular", "M1_ThyroidPreps", "M1_CNSDrugs", "M1_CardiacDrugs", "M1_Diuretics")],
                                      ntree=100,
                                      importance=T)

# Variable Importance
varImpPlot(Second_Month_enrollment_RF,
           sort=T,
           main = "Variable Importance")

# Variable importance table
var.imp <- data.frame(importance(Second_Month_enrollment_RF, type = 2))

# Make row names as columns
var.imp$Variables <- row.names(var.imp)
var.imp[order(var.imp$MeanDecreaseGini, decreasing = T),]


# CAlculating accuracy
rf_pred <- predict(Second_Month_enrollment_RF, newdata = sub_dat_2_test)
sum(rf_pred==sub_dat_2_test$enrollment_flag)/nrow(sub_dat_2_test)
# 0.9378458

#######################
#   Third Iteration   #
#######################


# Fixing data types
sub_dat_3$MotionEnrFlag_StepBased <- as.factor(as.character(sub_dat_3$MotionEnrFlag_StepBased))
sub_dat_3$Gender <- as.factor(sub_dat_3$Gender)
sub_dat_3[,7:12] <- lapply(sub_dat_3[,7:12], as.factor)

# Creating train/test split for the model
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_3),
                  replace=T,
                  prob = (c(0.75,0.25)))
sub_dat_3_train <- sub_dat_3[indices==1,]
sub_dat_3_test <- sub_dat_3[indices==2,]

# Creating the Fromula [object]
varNames <- names(sub_dat_3)
varNames <- varNames[!varNames %in% c("MemberID", "MotionEnrFlag_StepBased","enrollment_flag", "MotionEnr_MonthInd" , "holdoutpred", "holdoutpred_2")]
varNames1 <- paste(varNames, collapse = "+")
RF.formula <- as.formula(paste("enrollment_flag", varNames1, sep = "~"))

# Creating RF
set.seed(17)
Third_Month_enrollment_RF <- randomForest(RF.formula,
                                          sub_dat_3_train[, c( "Age", "Gender", "Sbscr_Ind", "enrollment_flag","M12_Antihyperglycemics", "M12_Cardiovascular", "M12_ThyroidPreps", "M12_CNSDrugs", "M12_CardiacDrugs", "M12_Diuretics")],
                                          ntree=100,
                                          importance=T)

# Variable Importance
varImpPlot(Third_Month_enrollment_RF,
           sort=T,
           main = "Variable Importance")

# Variable importance table
var.imp <- data.frame(importance(Third_Month_enrollment_RF, type = 2))

# Make row names as columns
var.imp$Variables <- row.names(var.imp)
var.imp[order(var.imp$MeanDecreaseGini, decreasing = T),]

# Calculating accuracy
rf_pred <- predict(Third_Month_enrollment_RF, newdata = sub_dat_3_test)
sum(rf_pred==sub_dat_3_test$enrollment_flag)/nrow(sub_dat_3_test)
#0.9817611

#######################
#   Fourth Iteration  #
#######################

# Fixing data types
sub_dat_4$MotionEnrFlag_StepBased <- as.factor(as.character(sub_dat_4$MotionEnrFlag_StepBased))
sub_dat_4$Gender <- as.factor(sub_dat_4$Gender)
sub_dat_4[,7:12] <- lapply(sub_dat_4[,7:12], as.factor)

# Creating train/test split for the model
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_4),
                  replace=T,
                  prob = (c(0.75,0.25)))
sub_dat_4_train <- sub_dat_4[indices==1,]
sub_dat_4_test <- sub_dat_4[indices==2,]


# Creating the Fromula [object]
varNames <- names(sub_dat_4)
varNames <- varNames[!varNames %in% c("MemberID", "holdoutpred","holdoutpred_2","MotionEnrFlag_StepBased", "MotionEnr_MonthInd")]
varNames1 <- paste(varNames, collapse = "+")
RF.formula <- as.formula(paste("MotionEnrFlag_StepBased", varNames1, sep = "~"))


# Creating RF
set.seed(17)
Fourth_Month_up_enrollment_RF <- randomForest(RF.formula,
                                              sub_dat_4_train[, c( "Age", "MotionEnrFlag_StepBased","Gender", "Sbscr_Ind", "M12_Antihyperglycemics", "M12_Cardiovascular", "M12_ThyroidPreps", "M12_CNSDrugs", "M12_CardiacDrugs", "M12_Diuretics")],
                                          ntree=100,
                                          importance=T)


# Variable Importance
varImpPlot(Fourth_Month_up_enrollment_RF,
           sort=T,
           main = "Variable Importance")

# Variable importance table
var.imp <- data.frame(importance(Fourth_Month_up_enrollment_RF, type = 2))

# Make row names as columns
var.imp$Variables <- row.names(var.imp)
var.imp[order(var.imp$MeanDecreaseGini, decreasing = T),]

# Calculating accuracy
rf_pred <- predict(Fourth_Month_up_enrollment_RF, newdata  =sub_dat_4_test)
sum(rf_pred== sub_dat_4_test$MotionEnrFlag_StepBased)/nrow(sub_dat_4_test)
# 0.8648527