library(RODBC)
library(data.table)
library(ggplot2)
library(dplyr)
library(cvTools)
library(AUC)
library(lme4)

db <- odbcConnect(dsn = "devsql10")
dat <- data.table(sqlQuery(db, "Select * From pdb_PharmaMotion..KT_G1061_MotionEnrModeling_Dataset", as.is = T))

# Creating buckets for different company sizes
dat$Company_Size <- "NA"
dat$Company_Size[which(dat$EligibileEmployees <= 18.0)] <- "<=18"
dat$Company_Size[which(dat$EligibileEmployees > 18.0 & dat$EligibileEmployees <= 28.0)] <- "19-28"
dat$Company_Size[which(dat$EligibileEmployees > 28.0 & dat$EligibileEmployees <= 41.0)] <- "29-41"
dat$Company_Size[which(dat$EligibileEmployees > 41.0)] <- ">=41"
dat$Company_Size <- factor(dat$Company_Size, levels = c("<=18", "19-28", "29-41", ">=41"))

# determining which policy ID's have AT LEAST 1 MEMBER ENROLLED IN MOTION
policies_with_motion <- subset(dat[,.(max_motion_flag = max(MotionEnrFlag_StepBased) ),by = list(PolicyID)][which(max_motion_flag>0)],select = c("PolicyID"))
policies_with_motion <- as.vector(policies_with_motion$PolicyID)

# subsetting data to those only in the list of policy id's
work_dat <- dat[which(PolicyID %in% policies_with_motion)]

# Numerical EDA of work_dat
prop.table(table(work_dat$MotionEnrFlag_StepBased))
# 0         1 
# 0.6609482 0.3390518 


# Creating a function to summarize model metrics
model_performance <- function(predicted_proby, actual_values, threshold = 0.5){
  # create a confusion matrix
  conf_mat <- table(actual_values, factor(ifelse(predicted_proby >= threshold, 1,0), levels = c(0,1)))
  
  # creating return value
  retval <- list()
  
  retval$accuracy <- (conf_mat[1,1] + conf_mat[2,2])/(sum(conf_mat))
  
  retval$sensitivity <- (conf_mat[2,2])/(conf_mat[2,2] + conf_mat[2,1])
  
  retval$specificity <- (conf_mat[1,1])/(conf_mat[1,1] + conf_mat[1,2])
  
  return(retval)
}



# Creating models


#######################
#   First Iteration   #
#################################
# Predicting overall enrollment #
# Given only the Demographics   #
#################################

# The specific columns needed
sub_dat_1 <- subset(work_dat, select = c("MemberID", "Age" , "Gender", "Sbscr_Ind","MotionEnrFlag_StepBased", "MotionEnr_MonthInd", "PolicyID", "EligibileEmployees", "Company_Size"))

# Fixing Data Types
sub_dat_1[, 3:5] <- lapply(sub_dat_1[,3:5], as.factor)
sub_dat_1$PolicyID <- as.numeric(dat$PolicyID)

# Train/Test Split: 70 - 30
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_1),
                  replace = T,
                  prob = c(0.7, 0.3))
sub_dat_1_train <- sub_dat_1[indices==1,]
sub_dat_1_test  <- sub_dat_1[indices ==2]



# Logistic Regression Model with company Size as a predictor
overall_enrollment_1 <- glm(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + Company_Size,family = binomial, data=sub_dat_1_train)
summary(overall_enrollment_1)

# Saving prediciton probabilities
sub_dat_1_test$prediction_proby <- predict(overall_enrollment_1, newdata = sub_dat_1_test, type = "response")

model_performance(sub_dat_1_test$prediction_proby, sub_dat_1_test$MotionEnrFlag_StepBased, 0.5)
model_performance(sub_dat_1_test$prediction_proby, sub_dat_1_test$MotionEnrFlag_StepBased, 0.267)


auc(roc(sub_dat_1_test$prediction_proby, sub_dat_1_test$MotionEnrFlag_StepBased)) #  0.638116
plot(roc(sub_dat_1_test$prediction_proby, sub_dat_1_test$MotionEnrFlag_StepBased), main = "Overall Enrollment")

overall_enrollment_2 <- glmer(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + (1|Company_Size),family = binomial, data = sub_dat_1_train)
summary(overall_enrollment_2)

# Saving prediction probabilities
sub_dat_1_test$prediction_proby_2 <- predict(overall_enrollment_2, newdata  = sub_dat_1_test, type = "response")

model_performance(predicted_proby =  sub_dat_1_test$prediction_proby_2, actual_values = sub_dat_1_test$MotionEnrFlag_StepBased, threshold = 0.5)
model_performance(predicted_proby =  sub_dat_1_test$prediction_proby_2, actual_values = sub_dat_1_test$MotionEnrFlag_StepBased, threshold = 0.267)

auc(roc(sub_dat_1_test$prediction_proby_2,sub_dat_1_test$MotionEnrFlag_StepBased ))
plot(roc(sub_dat_1_test$prediction_proby_2,sub_dat_1_test$MotionEnrFlag_StepBased ), main = "Overall Enrollment")

#######################
#  Second Iteration   #
##############################################################
#  Predicting enrollment during the 2nd month of eligibilty  #
#  Given Demographics and Drug Use during the first month.   #
##############################################################

# Subsetting data to information needed only
sub_dat_2 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M1_Maintenance_Flag", "PolicyID", "Company_Size", "EligibileEmployees" )) # dat[, c(1,5:8, 34:50)]

# Editing the enrollment flag for members who enrolled AFTER the second month to 0
sub_dat_2$enrollment_flag <- ifelse(sub_dat_1$MotionEnr_MonthInd == 2, 1,0)
sub_dat_2$enrollment_flag <- as.factor(sub_dat_2$enrollment_flag)

# Taking out members who enrolled in the first month 
sub_dat_2 <- filter(sub_dat_2, MotionEnr_MonthInd != 1) # 95048-8770 = 86278

# Fixing Data types
sub_dat_2[, c(3:4, 6:7)] <- lapply(sub_dat_2[, c(3:4, 6:7)], as.factor)

# Train Test - 70-30 split
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_2),
                  replace = T,
                  prob = c(0.7, 0.3))
sub_dat_2_train <- sub_dat_2[indices==1,]
sub_dat_2_test  <- sub_dat_2[indices ==2,]


# Create model with company size as a predictor
Secon_Month_glm_1 <- glm(enrollment_flag ~ Age +  Gender + Sbscr_Ind + M1_Maintenance_Flag + Company_Size,family = binomial, data = sub_dat_2_train)
summary(Secon_Month_glm_1)

sub_dat_2_test$prediction_proby <- predict(Secon_Month_glm_1, newdata= sub_dat_2_test, type = "response")


# Model Performance
model_performance(sub_dat_2_test$prediction_proby, sub_dat_2_test$enrollment_flag, threshold = 0.267)
model_performance(sub_dat_2_test$prediction_proby, sub_dat_2_test$enrollment_flag, threshold = 0.5)


auc(roc(sub_dat_2_test$prediction_proby, sub_dat_2_test$enrollment_flag)) # 0.6259268
plot(roc(sub_dat_2_test$prediction_proby, sub_dat_2_test$enrollment_flag), main = "Second Month Enrollment")


# Mixed effects model random on company
Second_Month_Enrollment_glm_2 <- glmer(enrollment_flag~ Age + Gender + Sbscr_Ind + M1_Maintenance_Flag + (1|Company_Size),family=binomial, data = sub_dat_2_train)
summary(Second_Month_Enrollment_glm_2)

# saving prediction proby
sub_dat_2_test$prediction_proby_2 <- predict(Second_Month_Enrollment_glm_2, newdata = sub_dat_2_test, type = "response")

model_performance(predicted_proby = sub_dat_2_test$prediction_proby_2, actual_values = sub_dat_2_test$enrollment_flag, threshold = 0.267)
model_performance(predicted_proby = sub_dat_2_test$prediction_proby_2, actual_values = sub_dat_2_test$enrollment_flag, threshold = 0.5)

auc(roc(sub_dat_2_test$prediction_proby_2, sub_dat_2_test$enrollment_flag))
# 0.6258258
plot(roc(sub_dat_2_test$prediction_proby_2, sub_dat_2_test$enrollment_flag), main = "Second Month Enrollment")

#######################
#   Third Iteration   #
#################################################
# Using demographics and Drug use data to model #
# third month enrollment                        #
#################################################


# Subsetting only to information needed
sub_dat_3 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind","M12_Maintenance_Flag", "Company_Size","PolicyID" ))

# Filtering out members who enrolled in the second month and in the first month
sub_dat_3 <- filter(sub_dat_3, MotionEnr_MonthInd != 1 , MotionEnr_MonthInd !=2) # 95048-8770-5656=80622

# Fixing Data types
sub_dat_3[, c(3:4, 6:12)] <- lapply(sub_dat_3[, c(3:4, 6:12)], as.factor)

# Modifiying enrollment flag for members who didnt enroll yet
sub_dat_3$enrollment_flag <- ifelse(sub_dat_3$MotionEnr_MonthInd==3,1,0)
sub_dat_3$enrollment_flag <- as.factor(sub_dat_3$enrollment_flag)

# Train Test Split
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_3),
                  replace = T,
                  prob = c(0.7, 0.3))
sub_dat_3_train <- sub_dat_3[indices==1,]
sub_dat_3_test  <- sub_dat_3[indices ==2,]

# Third Month Model - company size as a predictor
Thrid_Month_Model_1 <- glm(enrollment_flag ~ Age + Gender + Sbscr_Ind + M12_Maintenance_Flag + Company_Size ,family = binomial, data = sub_dat_3_train)
summary(Thrid_Month_Model_1)


# Prediction Proby
sub_dat_3_test$prediction_proby <- predict(Thrid_Month_Model_1, newdata = sub_dat_3_test, type = "response")

# Model Performance
model_performance(predicted_proby = sub_dat_3_test$prediction_proby, actual_values = sub_dat_3_test$enrollment_flag, threshold = 0.267)
model_performance(predicted_proby = sub_dat_3_test$prediction_proby, actual_values = sub_dat_3_test$enrollment_flag, threshold = 0.5)


auc(roc(sub_dat_3_test$prediction_proby, sub_dat_3_test$enrollment_flag)) # 0.6137662
plot(roc(sub_dat_3_test$prediction_proby, sub_dat_3_test$enrollment_flag), main = "Third Month Enrollment")

# Third iteration of model
Third_Month_Enrollment_glm_2 <- glmer(enrollment_flag ~ Age + Gender + Sbscr_Ind + M12_Maintenance_Flag +  (1|Company_Size) ,family = binomial, data = sub_dat_3_train)
summary(Third_Month_Enrollment_glm_2)


# Saving Prediction Probabilities
sub_dat_3_test$prediction_proby_2 <- predict(Third_Month_Enrollment_glm_2, newdata = sub_dat_3_test, type = "response")

# Model performance
model_performance(sub_dat_3_test$prediction_proby_2, sub_dat_3_test$enrollment_flag, threshold = 0.267)
model_performance(sub_dat_3_test$prediction_proby_2, sub_dat_3_test$enrollment_flag, threshold = 0.5)


auc(roc(sub_dat_3_test$prediction_proby_2, sub_dat_3_test$enrollment_flag))
plot(roc(sub_dat_3_test$prediction_proby_2, sub_dat_3_test$enrollment_flag), main = "Third Month Enrollment")


#####################################
#           FOURTH ITERATION        #
#################################################
# Using demographics and Drug use data to model #
# enrollment from the fourth month until the    #
# twelfth month.                                #
#################################################


# Subsetting only to information needed
sub_dat_4 <- subset(dat, select = c("MemberID" ,"Age","Gender","MotionEnrFlag_StepBased", "MotionEnr_MonthInd","Sbscr_Ind", "M12_Maintenance_Flag", "Company_Size","PolicyID"))

# Filtering out members who enrolled in the second month and in the first month
sub_dat_4 <- filter(sub_dat_4, MotionEnr_MonthInd != 1 , MotionEnr_MonthInd !=2) # 95048-8770-5656- = 80622


# Fixing Data types
sub_dat_4[, c(3:4, 6:7)] <- lapply(sub_dat_4[, c(3:4, 6:7)], as.factor)

# Train-test 70-30 split
set.seed(17)
indices <- sample(2,
                  nrow(sub_dat_4),
                  replace = T,
                  prob = c(0.7, 0.3))
sub_dat_4_train <- sub_dat_4[indices==1,]
sub_dat_4_test  <- sub_dat_4[indices ==2,]

# Company size as a predictor
Fourth_Month_Up_Enrollment_glm_1 <- glm(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + M12_Maintenance_Flag + Company_Size,family = binomial, data = sub_dat_4_train)
summary(Fourth_Month_Up_Enrollment_glm_1)



# Predicted Probabilities
sub_dat_4_test$prediction_proby <- predict(Fourth_Month_Up_Enrollment_glm_1, newdata= sub_dat_4_test, type = "response")

# Model Performance
model_performance(sub_dat_4_test$prediction_proby, sub_dat_4_test$MotionEnrFlag_StepBased, threshold = 0.267)
model_performance(sub_dat_4_test$prediction_proby, sub_dat_4_test$MotionEnrFlag_StepBased, threshold = 0.5)


auc(roc(sub_dat_4_test$prediction_proby, sub_dat_4_test$MotionEnrFlag_StepBased)) # 0.6280772
plot(roc(sub_dat_4_test$prediction_proby, sub_dat_4_test$MotionEnrFlag_StepBased), main = "Third to fourteenth month enrollment")


# fourth Iteration of the model
Fourth_Month_Up_Enrollment_glm_2 <- glmer(MotionEnrFlag_StepBased ~ Age + Gender + Sbscr_Ind + M12_Maintenance_Flag + (1|Company_Size),family = binomial, data = sub_dat_4_train)
summary(Fourth_Month_Up_Enrollment_glm_2)


# Prediction Probabilityes
sub_dat_4_test$prediction_proby_2 <- predict(Fourth_Month_Up_Enrollment_glm_2, newdata = sub_dat_4_test, type = "response")

# Model Performance
model_performance(sub_dat_4_test$prediction_proby_2, sub_dat_4_test$MotionEnrFlag_StepBased, threshold = 0.267)
model_performance(sub_dat_4_test$prediction_proby_2, sub_dat_4_test$MotionEnrFlag_StepBased, threshold = 0.5)

auc(roc(sub_dat_4_test$prediction_proby_2, sub_dat_4_test$MotionEnrFlag_StepBased))
plot(roc(sub_dat_4_test$prediction_proby_2, sub_dat_4_test$MotionEnrFlag_StepBased), main = "Third to Fourteenth Month Enrollment")

