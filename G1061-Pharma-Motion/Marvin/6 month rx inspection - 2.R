# Loading Libraries
library(RODBC)
library(data.table)
library(ggplot2)
library(AUC)
library(plotROC)
library(dplyr)
library(caret)

# Loading Data
db <- odbcConnect(dsn = "devsql10")
dat <- sqlQuery(db, "Select * From udb_magor..MA_G1061_EnrollmentByPrescriptionModeling", as.is=T)

# Fixing data types
dat$Pre_Average_RX  <- as.numeric(dat$Pre_Average_RX)
dat$Pre_Average_RX <- as.numeric(dat$Pre_Average_RX)
dat$Gender          <- as.factor(dat$Gender)
dat$Sbscr_Ind       <- as.factor(dat$Sbscr_Ind)
dat[,2:8]           <- lapply(dat[,2:8], as.factor)
dat[,22:28]         <- lapply(dat[,22:28], as.factor)
dat$motion_enrollment_flag <- as.factor(dat$motion_enrollment_flag)

# Proportion of enrollees vs non-enrollees
prop.table(table(dat$motion_enrollment_flag))
# 0         1 
# 0.8160587 0.1839413  # Use this as threshold for prediction?



# re-assembling data so that we use post RX data for the enrollees
non_enrollees <- filter(subset(dat, select = c("MemberID", "Age", "Gender", "Sbscr_Ind", "DependentCnt", "motion_enrollment_flag","Pre_Count_AntiparkinsonDrugs", "Pre_Count_Antihyperglycemics", "Pre_Count_Diuretics", "Pre_Count_CNSDrugs", "Pre_Count_Cardiovascular","Pre_Count_CardiacDrugs" , "Pre_Count_ThyroidPreps", "Pre_Average_RX")), motion_enrollment_flag == 0)
enrollees <- filter(subset(dat, select = c("MemberID", "Age", "Gender", "Sbscr_Ind", "DependentCnt", "motion_enrollment_flag","Post_Count_AntiparkinsonDrugs", "Post_Count_Antihyperglycemics", "Post_Count_Diuretics", "Post_Count_CNSDrugs", "Post_Count_Cardiovascular","Post_Count_CardiacDrugs" , "Post_Count_ThyroidPreps", "Post_Average_RX")), motion_enrollment_flag == 1)
new_names <- c("MemberID", "Age", "Gender", "Sbscr_Ind", "DependentCnt", "motion_enrollment_flag","AntiparkinsonDrugs", "Antihyperglycemics", "Diuretics", "CNSDrugs", "Cardiovascular","CardiacDrugs" , "ThyroidPreps", "Average_RX")

# Making column names consistent for rbinding
colnames(non_enrollees) <- new_names
colnames(enrollees) <- new_names

# The "cheat"
modeling_dat <- rbind(non_enrollees, enrollees)

# Train/Test Split 70-30
set.seed(17)
indices <- sample(2,
                  nrow(modeling_dat),
                  replace = T,
                  prob = c(0.7,0.3))

modeling_dat_train <- modeling_dat[indices==1,]
modeling_dat_test  <- modeling_dat[indices==2,]

# Model 1: Just demographics
demo_model <- glm(motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + DependentCnt,family = binomial, data = modeling_dat_train)
summary(demo_model)

# Call:
#   glm(formula = motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + 
#         DependentCnt, family = binomial, data = modeling_dat_train)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.6990  -0.6834  -0.5618  -0.3735   2.3713  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
#   (Intercept)  -2.9035847  0.0473579  -61.31   <2e-16 ***
#   Age           0.0152301  0.0008571   17.77   <2e-16 ***
#   GenderM      -0.6176943  0.0238117  -25.94   <2e-16 ***
#   Sbscr_Ind1    1.2110304  0.0331636   36.52   <2e-16 ***
#   DependentCnt  0.3453037  0.0243750   14.17   <2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 56853  on 59741  degrees of freedom
# Residual deviance: 54495  on 59737  degrees of freedom
# (6 observations deleted due to missingness)
# AIC: 54505
# 
# Number of Fisher Scoring iterations: 4



exp(coef(demo_model))
# (Intercept)          Age      GenderM   Sbscr_Ind1 DependentCnt 
# 0.05482633   1.01534665   0.53918622   3.35694178   1.41241878

# ROC Curve
demo_roc <- roc(predict(demo_model, newdata = modeling_dat_test, type = "response"), modeling_dat_test$motion_enrollment_flag)
#plot
plot(demo_roc)
# AUC
auc(demo_roc)

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_model, newdata = modeling_dat_test, type = "response")>0.5,1,0))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0.813593

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9999043

# confusion matrix - at 0.184
conf_mat_0.105 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_model, newdata = modeling_dat_test, type = "response")>0.184,1,0))

# accuracy - 0.184
(conf_mat_0.105[1,1] + conf_mat_0.105[2,2])/(sum(conf_mat_0.105))
# 0.5797468

# sensitivity - 0.184
(conf_mat_0.105[2,2])/(conf_mat_0.105[2,2] + conf_mat_0.105[2,1])
# 0.611204

# specificity - 0.184
(conf_mat_0.105[1,1])/(conf_mat_0.105[1,1] + conf_mat_0.105[1,2])
# 0.5725432

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_model, newdata = modeling_dat_test, type = "response")>0.267,1,0))

# accuracy - 0.0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
0.7510419
# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.2217809

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.8722416

# Model 2: demo + RX Allowed
demo_rx_model <- glm(motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + DependentCnt + Average_RX,family = binomial, data = modeling_dat_train)
summary(demo_rx_model)

# Call:
#   glm(formula = motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + 
#         DependentCnt + Average_RX, family = binomial, data = modeling_dat_train)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.6974  -0.6858  -0.5621  -0.3755   2.3716  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept)  -2.903e+00  4.736e-02  -61.28   <2e-16 ***
#   Age           1.515e-02  8.596e-04   17.62   <2e-16 ***
#   GenderM      -6.172e-01  2.381e-02  -25.92   <2e-16 ***
#   Sbscr_Ind1    1.211e+00  3.317e-02   36.53   <2e-16 ***
#   DependentCnt  3.451e-01  2.438e-02   14.16   <2e-16 ***
#   Average_RX    3.094e-05  2.537e-05    1.22    0.223    
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 56853  on 59741  degrees of freedom
# Residual deviance: 54493  on 59736  degrees of freedom
# (6 observations deleted due to missingness)
# AIC: 54505
# 
# Number of Fisher Scoring iterations: 4


exp(coef(demo_rx_model))
# (Intercept)          Age      GenderM   Sbscr_Ind1 DependentCnt   Average_RX 
# 0.05488513   1.01526548   0.53943140   3.35830526   1.41219357   1.00003094

# ROC Curve
demo_rx_roc <- roc(predict(demo_rx_model, newdata = modeling_dat, type = "response"), modeling_dat$motion_enrollment_flag)
#plot
plot(demo_rx_roc)
# AUC
auc(demo_rx_roc)

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_rx_model, newdata = modeling_dat_test, type = "response")>0.5,1,0))

# accuracy - 0.5
(conf_mat_0.5[1,1] + conf_mat_0.5[2,2])/(sum(conf_mat_0.5))
# 0.8918965

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9999521

# confusion matrix - at 0.105
conf_mat_0.105 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_rx_model, newdata = modeling_dat_test, type = "response")>0.105,1,0))

# accuracy - 0.105
(conf_mat_0.105[1,1] + conf_mat_0.105[2,2])/(sum(conf_mat_0.105))
# 0.5858594

# sensitivity - 0.105
(conf_mat_0.105[2,2])/(conf_mat_0.105[2,2] + conf_mat_0.105[2,1])
# 0.6203082

# specificity - 0.105
(conf_mat_0.105[1,1])/(conf_mat_0.105[1,1] + conf_mat_0.105[1,2])
# 0.5816859

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_rx_model, newdata = modeling_dat_test, type = "response")>0.267,1,0))

# accuracy - 0.0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.8911707

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.004741209

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.998564