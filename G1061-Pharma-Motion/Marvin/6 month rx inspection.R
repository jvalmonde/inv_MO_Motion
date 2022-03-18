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
dat$Post_Average_RX <- as.numeric(dat$Post_Average_RX)
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
non_enrollees <- filter(subset(dat, select = c("MemberID", "Age", "Gender", "Sbscr_Ind", "DependentCnt", "motion_enrollment_flag","Pre_AntiparkinsonDrugs", "Pre_Antihyperglycemics", "Pre_Diuretics", "Pre_CNSDrugs", "Pre_Cardiovascular","Pre_CardiacDrugs" , "Pre_ThyroidPreps", "Pre_Average_RX")), motion_enrollment_flag == 0)
enrollees <- filter(subset(dat, select = c("MemberID", "Age", "Gender", "Sbscr_Ind", "DependentCnt", "motion_enrollment_flag","Post_AntiparkinsonDrugs", "Post_Antihyperglycemics", "Post_Diuretics", "Post_CNSDrugs", "Post_Cardiovascular","Post_CardiacDrugs" , "Post_ThyroidPreps", "Post_Average_RX")), motion_enrollment_flag == 1)
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
# -1.6803  -0.5240  -0.4172  -0.3307   2.6454  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept)  -3.605361   0.062620  -57.58   <2e-16 ***
#   Age           0.013364   0.001131   11.82   <2e-16 ***
#   GenderM      -0.629488   0.031089  -20.25   <2e-16 ***
#   Sbscr_Ind1    1.325013   0.044326   29.89   <2e-16 ***
#   DependentCnt  0.418968   0.031506   13.30   <2e-16 ***
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 36383  on 54481  degrees of freedom
# Residual deviance: 34933  on 54477  degrees of freedom
# (6 observations deleted due to missingness)
# AIC: 34943
# 
# Number of Fisher Scoring iterations: 5



exp(coef(demo_model))
# (Intercept)          Age      GenderM   Sbscr_Ind1 
# 0.02717764   1.01345351   0.53286459   3.76223446 
# DependentCnt 
# 1.52039223 

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
# 0.8918965

# sensitivity - 0.5
(conf_mat_0.5[2,2])/(conf_mat_0.5[2,2] + conf_mat_0.5[2,1])
# 0

# specificity - 0.5
(conf_mat_0.5[1,1])/(conf_mat_0.5[1,1] + conf_mat_0.5[1,2])
# 0.9999521

# confusion matrix - at 0.105
conf_mat_0.105 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_model, newdata = modeling_dat_test, type = "response")>0.105,1,0))

# accuracy - 0.105
(conf_mat_0.105[1,1] + conf_mat_0.105[2,2])/(sum(conf_mat_0.105))
# 0.5873111

# sensitivity - 0.105
(conf_mat_0.105[2,2])/(conf_mat_0.105[2,2] + conf_mat_0.105[2,1])
# 0.6187278

# specificity - 0.105
(conf_mat_0.105[1,1])/(conf_mat_0.105[1,1] + conf_mat_0.105[1,2])
# 0.9266439

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_model, newdata = modeling_dat_test, type = "response")>0.267,1,0))

# accuracy - 0.0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.8910426

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.004346108

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.9984682

# Model 2: demo + RX Allowed
demo_rx_model <- glm(motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + DependentCnt + Average_RX,family = binomial, data = modeling_dat_train)
summary(demo_rx_model)

# Call:
#   glm(formula = motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + 
#         DependentCnt + Average_RX, family = binomial, data = modeling_dat_train)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.6775  -0.5236  -0.4184  -0.3306   2.6414  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept)  -3.603e+00  6.262e-02 -57.541   <2e-16 ***
#   Age           1.321e-02  1.134e-03  11.649   <2e-16 ***
#   GenderM      -6.287e-01  3.109e-02 -20.221   <2e-16 ***
#   Sbscr_Ind1    1.326e+00  4.433e-02  29.908   <2e-16 ***
#   DependentCnt  4.187e-01  3.151e-02  13.289   <2e-16 ***
#   Average_RX    5.462e-05  2.862e-05   1.908   0.0564 .  
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 36383  on 54481  degrees of freedom
# Residual deviance: 34929  on 54476  degrees of freedom
# (6 observations deleted due to missingness)
# AIC: 34941
# 
# Number of Fisher Scoring iterations: 5


exp(coef(demo_rx_model))
# (Intercept)          Age      GenderM   Sbscr_Ind1 DependentCnt 
# 0.0272360    1.0132989    0.5332732    3.7655854    1.5199952 
# Average_RX 
# 1.0000546 
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

# Model 3: demo + RX + drugs
demo_rx_drugs_model <- glm(motion_enrollment_flag ~ ., family = binomial, data = modeling_dat_train[,-1])
summary(demo_rx_drugs_model)

# Call:
#   glm(formula = motion_enrollment_flag ~ ., family = binomial, 
#       data = modeling_dat_train[, -1])
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.6715  -0.5237  -0.4168  -0.3313   2.6422  
# 
# Coefficients:
#   Estimate Std. Error z value Pr(>|z|)    
# (Intercept)         -3.577e+00  6.333e-02 -56.485  < 2e-16 ***
#   Age                  1.224e-02  1.175e-03  10.422  < 2e-16 ***
#   GenderM             -6.290e-01  3.127e-02 -20.115  < 2e-16 ***
#   Sbscr_Ind1           1.329e+00  4.437e-02  29.959  < 2e-16 ***
#   DependentCnt         4.188e-01  3.152e-02  13.287  < 2e-16 ***
#   AntiparkinsonDrugs1  1.806e-01  6.340e-01   0.285  0.77569    
# Antihyperglycemics1  4.561e-02  9.824e-02   0.464  0.64244    
# Diuretics1          -1.739e-01  2.730e-01  -0.637  0.52419    
# CNSDrugs1           -7.809e-03  1.799e-01  -0.043  0.96539    
# Cardiovascular1      1.383e-01  5.798e-02   2.386  0.01704 *  
#   CardiacDrugs1        1.915e-01  1.991e-01   0.962  0.33598    
# ThyroidPreps1        4.228e-01  1.365e-01   3.097  0.00195 ** 
#   Average_RX           4.337e-05  2.980e-05   1.456  0.14552    
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 36383  on 54481  degrees of freedom
# Residual deviance: 34912  on 54469  degrees of freedom
# (6 observations deleted due to missingness)
# AIC: 34938
# 
# Number of Fisher Scoring iterations: 5

exp(coef(demo_rx_drugs_model))
# (Intercept)                 Age             GenderM 
# 0.02795054          1.01231963          0.53310622 
# Sbscr_Ind1        DependentCnt AntiparkinsonDrugs1 
# 3.77837778          1.52009521          1.19798769 
# Antihyperglycemics1          Diuretics1           CNSDrugs1 
# 1.04666556          0.84042265          0.99222189 
# Cardiovascular1       CardiacDrugs1       ThyroidPreps1 
# 1.14836234          1.21110334          1.52618614 
# Average_RX 
# 1.00004337 

# ROC
drugs_rx_roc <- roc(predict(demo_rx_drugs_model, newdata= modeling_dat, type = "response"), modeling_dat$motion_enrollment_flag)
plot(drugs_rx_roc)

# AUC
auc(drugs_rx_roc)


# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_rx_drugs_model, newdata = modeling_dat_test, type = "response")>0.5,1,0))

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
conf_mat_0.105 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_rx_drugs_model, newdata = modeling_dat_test, type = "response")>0.105,1,0))

# accuracy - 0.105
(conf_mat_0.105[1,1] + conf_mat_0.105[2,2])/(sum(conf_mat_0.105))
# 0.5876526

# sensitivity - 0.105
(conf_mat_0.105[2,2])/(conf_mat_0.105[2,2] + conf_mat_0.105[2,1])
# 0.6258396

# specificity - 0.105
(conf_mat_0.105[1,1])/(conf_mat_0.105[1,1] + conf_mat_0.105[1,2])
# 0.5830262

# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(demo_rx_drugs_model, newdata = modeling_dat_test, type = "response")>0.267,1,0))

# accuracy - 0.0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.890573

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.008297116

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
# 0.997463

# With interactions
interactions_model<- glm (motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + DependentCnt + Average_RX + Average_RX*ThyroidPreps + Average_RX*Cardiovascular  ,family = binomial, data = modeling_dat_train)
summary(interactions_model)

# Call:
#   glm(formula = motion_enrollment_flag ~ Age + Gender + Sbscr_Ind + 
#         DependentCnt + Average_RX + Average_RX * ThyroidPreps + Average_RX * 
#         Cardiovascular, family = binomial, data = modeling_dat_train)
# 
# Deviance Residuals: 
#   Min       1Q   Median       3Q      Max  
# -1.6684  -0.5234  -0.4168  -0.3312   2.6413  
# 
# Coefficients:
#   Estimate Std. Error z value
# (Intercept)                -3.579e+00  6.330e-02 -56.549
# Age                         1.228e-02  1.173e-03  10.471
# GenderM                    -6.280e-01  3.126e-02 -20.089
# Sbscr_Ind1                  1.329e+00  4.436e-02  29.970
# DependentCnt                4.181e-01  3.151e-02  13.268
# Average_RX                  5.779e-05  3.321e-05   1.740
# ThyroidPreps1               4.698e-01  1.451e-01   3.236
# Cardiovascular1             1.563e-01  5.734e-02   2.726
# Average_RX:ThyroidPreps1   -2.205e-04  2.659e-04  -0.829
# Average_RX:Cardiovascular1 -3.632e-05  7.343e-05  -0.495
# Pr(>|z|)    
# (Intercept)                 < 2e-16 ***
#   Age                         < 2e-16 ***
#   GenderM                     < 2e-16 ***
#   Sbscr_Ind1                  < 2e-16 ***
#   DependentCnt                < 2e-16 ***
#   Average_RX                  0.08182 .  
# ThyroidPreps1               0.00121 ** 
#   Cardiovascular1             0.00642 ** 
#   Average_RX:ThyroidPreps1    0.40706    
# Average_RX:Cardiovascular1  0.62085    
# ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# (Dispersion parameter for binomial family taken to be 1)
# 
# Null deviance: 36383  on 54481  degrees of freedom
# Residual deviance: 34912  on 54472  degrees of freedom
# (6 observations deleted due to missingness)
# AIC: 34932
# 
# Number of Fisher Scoring iterations: 5

#ROC
roc_interactions <- roc(predict(interactions_model, newdata=modeling_dat_test, type = "response"),modeling_dat_test$motion_enrollment_flag)

# AUC
auc(roc_interactions)
# 0.6450481

# confusion matrix - at 0.5
conf_mat_0.5 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(interactions_model, newdata = modeling_dat_test, type = "response")>0.5,1,0))

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
conf_mat_0.105 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(interactions_model, newdata = modeling_dat_test, type = "response")>0.105,1,0))

# accuracy - 0.105
(conf_mat_0.105[1,1] + conf_mat_0.105[2,2])/(sum(conf_mat_0.105))
# 0.5876099

# sensitivity - 0.105
(conf_mat_0.105[2,2])/(conf_mat_0.105[2,2] + conf_mat_0.105[2,1])
# 0.6242592

# specificity - 0.105
(conf_mat_0.105[1,1])/(conf_mat_0.105[1,1] + conf_mat_0.105[1,2])
# 0.5831698


# confusion matrix - at 0.267
conf_mat_0.267 <-table(y = modeling_dat_test$motion_enrollment_flag, x = ifelse(predict(interactions_model, newdata = modeling_dat_test, type = "response")>0.267,1,0))

# accuracy - 0.0.267
(conf_mat_0.267[1,1] + conf_mat_0.267[2,2])/(sum(conf_mat_0.267))
# 0.8906584

# sensitivity - 0.267
(conf_mat_0.267[2,2])/(conf_mat_0.267[2,2] + conf_mat_0.267[2,1])
# 0.007506914

# specificity - 0.267
(conf_mat_0.267[1,1])/(conf_mat_0.267[1,1] + conf_mat_0.267[1,2])
#0.9976545

###############################
# predicting actual enrollees # 
###############################

enrollees_2 <- filter(subset(dat, select = c("MemberID", "Age", "Gender", "Sbscr_Ind", "DependentCnt", "motion_enrollment_flag","Pre_AntiparkinsonDrugs", "Pre_Antihyperglycemics", "Pre_Diuretics", "Pre_CNSDrugs", "Pre_Cardiovascular","Pre_CardiacDrugs" , "Pre_ThyroidPreps", "Pre_Average_RX")), motion_enrollment_flag==1)
names(enrollees_2) <- new_names

# demographics only prediction - 0.5 threshold
demo_pred <- ifelse(predict(demo_model, newdata = enrollees_2, type = "response")> 0.5,1,0)
sum(demo_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0

# demographics only prediction - 0.105 threshold
demo_pred <- ifelse(predict(demo_model, newdata = enrollees_2, type = "response")> 0.105,1,0)
sum(demo_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0.6228049

# demographics and RX prediciton - 0.5 threshold
demo_rx_pred <- ifelse(predict(demo_rx_model, newdata = enrollees_2, type = "response")> 0.5,1,0)
sum(demo_rx_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0

# demographics and RX prediciton - 0.105 threshold
demo_rx_pred <- ifelse(predict(demo_rx_model, newdata = enrollees_2, type = "response")> 0.105,1,0)
sum(demo_rx_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0.6241463


# demographics,RX, and drugs prediciton - 0.5 threshold
demo_rx_drugs_pred <- ifelse(predict(demo_rx_drugs_model, newdata = enrollees_2, type = "response")> 0.5,1,0)
sum(demo_rx_drugs_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0


# demographics and RX prediciton - 0.105 threshold
demo_rx_drugs_pred <- ifelse(predict(demo_rx_drugs_model, newdata = enrollees_2, type = "response")> 0.105,1,0)
sum(demo_rx_drugs_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0.6281707


# interactions predcitions - 0.5 threshold
interactions_pred <-ifelse(predict(interactions_model, newdata = enrollees_2, type = "response")> 0.5,1,0)
sum(interactions_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0

# interactions predcitions - 0.105 threshold
interactions_pred <-ifelse(predict(interactions_model, newdata = enrollees_2, type = "response")> 0.105,1,0)
sum(interactions_pred==enrollees_2$motion_enrollment_flag)/nrow(enrollees_2)
# 0.6286585
