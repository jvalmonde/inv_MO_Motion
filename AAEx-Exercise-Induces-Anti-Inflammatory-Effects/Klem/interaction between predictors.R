# library(fields)
library(ggplot2)
library(grid)
library(metafor)
# library(MCMCpack)
# library(mvtnorm)
# library(splines)
library(jtools)
library(data.table)
library(glmulti)
library(lava)
library(tidyr)

########################################################################
# Data Loading
########################################################################

path <- "/work/ksenyahan/ReOrg Projects/Chronic Inflammation/Analysis/"
data <- data.table(read.csv(paste(path, "anti_inflammatory_exercise_v4.csv", sep = ''), stringsAsFactors = F))

########################################################################
# Data Transformation and Cleaning
########################################################################

data[,'X'] <- NULL
data[, 'SD.pre_lvl' := ifelse(SD.pre_lvl == 0, SD.post_lvl, SD.pre_lvl)]
pro_inflam <- c( "TNF-alpha", "IL-18", "CRP", "hs-CRP", "MCP-1", "IL-1beta", "IL-15", "sTNFR1", 
                 "sICAM-1", "sVCAM-1", "ICAM-1", "VCAM-1", "MPO", "calprotectin", "leptin", "IL-8", "GM-CSF", "STNFR2", "CK", "WBC")
anti_inflam <- c("adiponectin", "IL-10", "EC-SOD", "IL-4", "IL-6", "IL-1ra")
anti_inflam2 <- c("adiponectin", "IL-10", "EC-SOD", "IL-4", "IL-1ra")
data[, c('biomarker_type', 'biomarker_type2'):= list(ifelse(Biomarker %in% anti_inflam, "ai", "pi"), 
                                                     ifelse(Biomarker %in% anti_inflam2, "ai", 
                                                            ifelse(Biomarker %in% pro_inflam, "pi", "pi/ai")))]
data[, c('Mean.pre_lvl2', 'Mean.post_lvl2'):= list(ifelse(biomarker_type2 == 'pi', -Mean.pre_lvl, Mean.pre_lvl), 
                                                   ifelse(biomarker_type2 == 'pi', -Mean.post_lvl, Mean.post_lvl))]
data <- data.table(escalc(measure="SMCRH",m2i = Mean.pre_lvl2, m1i =Mean.post_lvl2, sd2i=SD.pre_lvl, sd1i=SD.post_lvl, ni=Population, ri=rep(0, nrow(data)), data=data))
colnames(data) <- c(colnames(data)[-c(length(colnames(data))-1, length(colnames(data)))], 'yi2', 'vi2')
data <- data.table(escalc(measure="SMCRH",m2i = Mean.pre_lvl, m1i =Mean.post_lvl, sd2i=SD.pre_lvl, sd1i=SD.post_lvl, ni=Population, ri=rep(0, nrow(data)), data=data))
data[, c('wyi2', 'wyi') := list(yi2/vi2, yi/vi)]

data[, c('Gender', 'Condition', 'Treatment.type', 
         'Activity.type', 'Intensity', 'Biomarker') := list(factor(Gender), 
                                                            factor(Condition), 
                                                            factor(Treatment.type),
                                                            factor(Activity.type),
                                                            factor(Intensity),
                                                            factor(Biomarker))]

data[,c('Dur.Aerobic', 'Dur.Resistance') := list(ifelse(is.na(Dur.Aerobic) == TRUE, 0, Dur.Aerobic),
                                                 ifelse(is.na(Dur.Resistance) == TRUE, 0, Dur.Resistance))]

duration_class <- function(arbic, res){
  oc <- if(arbic > 40 | res > 15) "high" else
    if((arbic <= 40 & arbic > 20) | (res <= 15 & res > 8)) "moderate" else
      if((arbic <= 20 & arbic > 0) | (res <= 8 & res > 0)) "low" else 
        if(arbic == 0 & res == 0) "control"  
  return(oc)
}

data[,Duration := mapply(function(x,y) duration_class(x,y), Dur.Aerobic, Dur.Resistance)]
data[, c('biomarker_type2.col'):= list(ifelse(Biomarker %in% pro_inflam, "#c0504d", ifelse(Biomarker %in% anti_inflam2, "#4f81bd", "#febe10")))]    #(yellow, blue)

length(unique(data$Biomarker)) == length(pro_inflam) + length(anti_inflam)
data[, c('yi_new'):=list(ifelse(biomarker_type == "pi", -yi, yi))] #modifying the direction of the effect size for pro infammatory markers

data$Activity.type <- factor(data$Activity.type, levels=c("control", "aerobic", "aerobic-resistance", "resistance"))
data$Intensity <- factor(data$Intensity, levels= c("low", "moderate", "high", "control"))
data$Duration <- factor(data$Duration, levels= c( "low", "moderate", "high","control"))
data$Gender <- factor(data$Gender, levels= c("female", "male", "both"))
data$biomarker_type2 <- factor(data$biomarker_type2, levels= c("ai", "pi/ai", "pi"))

########################################################################
# Initial Summary
########################################################################

summary(data)
#table(data$Duration, data$Intensity)
#table(data[Activity.type == 'aerobic',]$Duration, data[Activity.type == 'aerobic',]$Intensity)
table(data[Activity.type == 'aerobic'|Activity.type == 'control',]$Duration, data[Activity.type == 'aerobic'|Activity.type == 'control',]$Intensity)
table(data[Activity.type == 'aerobic-resistance'|Activity.type == 'control',]$Duration, data[Activity.type == 'aerobic-resistance'|Activity.type == 'control',]$Intensity)
table(data[Activity.type == 'resistance'|Activity.type == 'control',]$Duration, data[Activity.type == 'resistance'|Activity.type == 'control',]$Intensity)

activity_type <- c('aerobic', 'control')
summary_table <- summarize(group_by(data.frame(data[Activity.type %in% activity_type,]), Duration, Intensity), RowCnt = n(), StudyCnt = n_distinct(Study))
summary_table.RowCnt <- spread(dplyr::select(summary_table, -StudyCnt), Intensity, RowCnt)
summary_table.StudyCnt <- spread(dplyr::select(summary_table, -RowCnt), Intensity, StudyCnt)
rm(summary_table)
summary_table.RowCnt
summary_table.StudyCnt
# Realization: Comparing the amount of data contained in each of the Activity.type, I decided to 
#              restrict the analysis to studies that conducted aerobic exercises

#Interaction Plots of raw data
agg_table <- summarize(group_by(data.frame(data[Activity.type %in% activity_type,]), Duration, Intensity), RowCnt = n(), mean.yi_new = mean(yi_new))$mean.yi_new
plot(c(agg_table[1], NA, NA, NA), type="o", pch=16, ylim = c(-25, 10), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Mean Difference", xlab = "Intensity")
axis(side=1, at=1:4, labels=c("control", "low", "moderate", "high"))
lines(c(NA, agg_table[2:4]), type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
lines(c(NA, agg_table[5:7]), type="o", pch=15, lty="dotted", lwd = 2, col = '#febe10')
lines(c(NA, agg_table[8:10]), type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("bottomleft", legend=c("control", "Duration-low", "Duration-moderate", "Duration-high"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10','#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2) # Image dimension: 480 x420

########################################################################
# Meta-Regression
########################################################################
# Model Selection
rma.glmulti <- function(formula, data, ...)
  rma(formula, vi, data=data, method="REML", ...)

data_aero <- data[Activity.type %in% activity_type,]
data_aero$Activity.type <- factor(data_aero$Activity.type, levels=c("control", "aerobic"))
data_aero$Intensity <- factor(data_aero$Intensity, levels= c("control", "low", "moderate", "high"))
data_aero$Duration <- factor(data_aero$Duration, levels= c("control", "low", "moderate", "high"))

res_aero <- glmulti(yi_new ~ Activity.type + Intensity + Duration + PeriodLength, data= data_aero, level=2, fitfunction=rma.glmulti, crit="aicc", confsetsize=1000)
tmp <- weightable(res_aero)
tmp <- tmp[tmp$aicc <= min(tmp$aicc) + 2,]
tmp

summary(res_aero@objects[[1]])

#Interaction plots
final.model1 <- rma(yi_new, vi, data=data_aero, mods=~ Intensity:Duration-1, method="REML")
plot(c(coef(final.model1)[1], NA, NA, NA), type="o", pch=16, ylim = c(-0.8, 1.5), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
axis(side=1, at=1:4, labels=c("control", "low", "moderate", "high"))
lines(c(NA, coef(final.model1)[2:4]), type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
lines(c(NA, coef(final.model1)[5:7]), type="o", pch=15, lty="dashed", lwd = 2, col = '#febe10')
lines(c(NA, coef(final.model1)[8:10]), type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("topright", legend=c("control", "Duration-low", "Duration-moderate", "Duration-high"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

final.model2 <- rma(yi_new, vi, data=data_aero, mods=~ Intensity:PeriodLength-1, method="REML")
plot(coef(final.model2)[1]*seq(-1, 24), type="o", pch=16, ylim = c(-0.6, 1), col = '#c0504d', lwd = 2, bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
lines(coef(final.model2)[2]*seq(-1, 24), type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
lines(coef(final.model2)[3]*seq(-1, 24), type="o", pch=15, lty="dashed", lwd = 2, col = '#febe10')
lines(coef(final.model2)[4]*seq(-1, 24), type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("bottomright", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

final.model2_1 <- rma(yi_new, vi, data=data_aero, mods=~ Duration:PeriodLength-1, method="REML")
plot(coef(final.model2_1)[1]*seq(-1, 24), type="o", pch=16, ylim = c(-0.8, 1), col = '#c0504d', lwd = 2, bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
lines(coef(final.model2_1)[2]*seq(-1, 24), type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
lines(coef(final.model2_1)[3]*seq(-1, 24), type="o", pch=15, lty="dashed", lwd = 2, col = '#febe10')
lines(coef(final.model2_1)[4]*seq(-1, 24), type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("bottomright", legend=c("control", "Duration-low", "Duration-moderate", "Duration-high"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

final.model3 <- rma(yi, vi, data=data_aero[biomarker_type2 != 'pi/ai'], mods=~ Intensity:biomarker_type2-1, method="REML")
plot(coef(final.model3)[1:3], type="o", pch=16, ylim = c(-0.8, 1.5), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
lines(coef(final.model3)[5:7], type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
legend("topleft", legend=c("Anti-Inflammatory", "Pro-Inflammatory"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

final.model4 <- rma(yi, vi, data=data_aero[biomarker_type2 != 'pi/ai'], mods=~ Duration:biomarker_type2-1, method="REML")
plot(coef(final.model4)[1:3], type="o", pch=16, ylim = c(-0.8, 1.5), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
lines(coef(final.model4)[5:7], type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
legend("topleft", legend=c("Anti-Inflammatory", "Pro-Inflammatory"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

final.model8 <- rma(yi, vi, data=data_aero[biomarker_type2 != 'pi/ai'], mods=~ PeriodLength:biomarker_type2-1, method="REML")
plot(coef(final.model8)[1]*seq(-1, 24), type="o", pch=16, ylim = c(-0.8, 1.5), col = '#c0504d', lwd = 2, bty = "l", ylab = "Standardized Mean Difference", xlab = "Period Length")
lines(coef(final.model8)[2]*seq(-1, 24), type="o", pch=19, lty="dotted", lwd = 2, col = '#4f81bd')
legend("topleft", legend=c("Anti-Inflammatory", "Pro-Inflammatory"), 
       lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 19, 15, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

data_aero.ai <- data_aero[biomarker_type2 == 'ai'] 
final.model5 <- rma(yi, vi, data=data_aero.ai, mods=~ Intensity:Duration-1, method="REML")
plot(c(NA, NA, coef(final.model5)[1]), type="o", pch=19, ylim = c(-0.8, 1.2), col = '#4f81bd', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
lines(c(NA, coef(final.model5)[2], NA), type="o", pch=15, lty="dotted", lwd = 2, col = '#febe10')
lines(coef(final.model5)[3:5], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("topright", legend=c("Duration-low", "Duration-moderate", "Duration-high"), 
       lty=c('solid', 'dotted', 'dashed'), pch = c(19, 15, 17), col = c('#4f81bd', '#febe10','#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

data_aero.pi <- data_aero[biomarker_type2 == 'pi' & Duration != 'control' & Intensity != 'control'] 
final.model6 <- rma(yi, vi, data=data_aero.pi, mods=~ Intensity:Duration-1, method="REML")
plot(coef(final.model6)[1:3], type="o", pch=19, ylim = c(-1.5, 2.5), col = '#4f81bd', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
lines(coef(final.model6)[4:6], type="o", pch=15, lty="dotted", lwd = 2, col = '#febe10')
lines(coef(final.model6)[7:9], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("topleft", legend=c("Duration-low", "Duration-moderate", "Duration-high"), 
       lty=c('solid', 'dotted', 'dashed'), pch = c(19, 15, 17), col = c('#4f81bd', '#febe10','#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)

data_aero.pi_ai <- data_aero[biomarker_type2 == 'pi/ai']
final.model7 <- rma(yi, vi, data=data_aero.pi_ai, mods=~ Intensity:Duration-1, method="REML")
plot(coef(final.model7)[1:3], type="o", pch=19, ylim = c(-1.6, 5.5), col = '#4f81bd', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Intensity")
axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
lines(c(coef(final.model7)[4:5], NA), type="o", pch=15, lty="dotted", lwd = 2, col = '#febe10')
lines(coef(final.model7)[6:8], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
legend("topleft", legend=c("Duration-low", "Duration-moderate", "Duration-high"), 
       lty=c('solid', 'dotted', 'dashed'), pch = c(19, 15, 17), col = c('#4f81bd', '#febe10','#abbb59'),
       inset=0.01 ,cex = 0.7, pt.cex = 1.2)


####################################################################################
# Whole New Approach - Healthy
####################################################################################
# Initial Data Exploration
summary(data)
table(data[Condition == 'healthy']$Treatment.type)
# control exercise 
# 29       69 
summary(data[Condition == 'healthy' & Treatment.type == 'control']$Activity.type)
summary(data[Condition == 'healthy' & Treatment.type == 'exercise']$Activity.type)
# Realization: Compare effect size among the ff. groups:         
#     Treatment.type == 'control' & Activity.type == 'aerobic' (control-active)
#     Treatment.type == 'control' & Activity.type == 'control' (control-inactive/sedentary)
#     Treatment.type == 'exercise' & Activity.type == 'aerobic' (treatment-active)
#     Treatment.type == 'exercise' & Activity.type == 'aerobic-resistance' (treatment-active)
summary(data[Condition == 'healthy' & Treatment.type == 'control' & Activity.type == 'control']$yi_new)
unique(data[Condition == 'healthy' & Treatment.type == 'control' & Activity.type == 'control']$Biomarker)
# Min.      1st Qu.   Median     Mean      3rd Qu.     Max. 
# -1.50800 -0.71770   -0.03316   -0.12310  0.35350     1.44000 
# Biomarkers: c('CRP', 'IL-6', 'TNF-alpha', 'IL-10', 'IL-4') 
summary(data[Condition == 'healthy' & Treatment.type == 'control' & Activity.type == 'aerobic']$yi_new)
unique(data[Condition == 'healthy' & Treatment.type == 'control' & Activity.type == 'aerobic']$Biomarker)
# Min.       1st Qu.    Median      Mean       3rd Qu.      Max. 
# -15.18000  -1.35700   -0.26330    -1.39600   0.04297      0.78770 
# Biomarkers: c('TNF-alpha', 'IL-10', 'IL-6', 'adiponectin', 'leptin', 'CK', 'WBC')   
summary(data[Condition == 'healthy' & Treatment.type == 'exercise' & Activity.type == 'aerobic']$yi_new)
unique(data[Condition == 'healthy' & Treatment.type == 'exercise' & Activity.type == 'aerobic']$Biomarker)
# Min.        1st Qu.    Median      Mean        3rd Qu.      Max. 
# -693.2000   -2.3750    -0.1897     -17.2200    0.1350       164.9000 
# Biomarkers: c('IL-6', 'IL-18', 'TNF-alpha', 'adiponectin',  'CRP', 'IL-10', 'calprotectin', 'MCP-1', 'MPO', 'CK', 'WBC', 'IL-1beta', 'IL-1ra', 'IL-4')    
summary(data[Condition == 'healthy' & Treatment.type == 'exercise' & Activity.type == 'aerobic-resistance']$yi_new)
unique(data[Condition == 'healthy' & Treatment.type == 'exercise' & Activity.type == 'aerobic-resistance']$Biomarker)
# Min.      1st Qu.   Median   Mean     3rd Qu.     Max. 
# -0.38920 -0.14160   0.10600  0.09085  0.33850     0.54070 
# Biomarkers: c('CRP', 'IL-6 ', 'TNF-alpha', 'IL-10')
#Realization: Only look at Biomarkers c('TNF-alpha', 'IL-6', 'IL-10', 'CRP') since they are all present in all of the groups above

#Building New Data

#######################  Data 1
data_new <- rbind(data[Condition == 'healthy' & Treatment.type == 'control'], data[Condition == 'healthy' & Treatment.type == 'exercise'])
#data_new <- data_new[!Biomarker %in% c('calprotectin', 'IL-1ra')]
#data_new <- data_new[Biomarker %in% c('TNF-alpha', 'IL-6', 'IL-10', 'CRP')]
#table(data_new[,c('Treatment.type', 'Activity.type')])
#summary(data_new)

data_new$Activity.type <- factor(data_new$Activity.type , levels=c("control", "aerobic", "aerobic-resistance"))
data_new$Gender <- factor(data_new$Gender, levels= c("female", "male", "both"))
data_new$Condition <- factor(data_new$Condition, levels= c("healthy"))
#data_new$Biomarker <- factor(data_new$Biomarker, levels= c("IL-10", "IL-6", "TNF-alpha", "CRP"))
data_new$biomarker_type2 <- factor(data_new$biomarker_type2)
data_new$biomarker_type2.col <- factor(data_new$biomarker_type2.col)
data_new$Intensity <- factor(data_new$Intensity, levels= c('low', 'moderate', 'high', 'control'))
data_new$Duration <- factor(data_new$Duration, levels= c('low', 'moderate', 'high', 'control'))
data_new$biomarker_type2 <- factor(data_new$biomarker_type2, levels= c("ai", "pi/ai", "pi"))
data_new <- data.table(data_new)
data_new[,c('biomarker_type')] <- NULL
data_new[, 'Condition_new' := factor(ifelse(Condition == 'control', 'Control', 
                                            ifelse(Condition == 'healthy', 'Healthy', 'Non-Healthy')))]

#######################  Data 2
data_new2 <- rbind(data[Condition != 'healthy' & Treatment.type == 'control'], data[Condition != 'healthy' & Treatment.type == 'exercise'])
#data_new2 <- data_new2[!Biomarker %in% c('calprotectin', 'IL-1ra')]
#data_new2 <- data_new2[Biomarker %in% c('TNF-alpha', 'IL-6', 'IL-10', 'CRP')]
#table(data_new2[,c('Treatment.type', 'Activity.type')])
#summary(data_new2)

data_new2$Activity.type <- factor(data_new2$Activity.type , levels=c("control", "aerobic", "aerobic-resistance"))
data_new2$Gender <- factor(data_new2$Gender, levels= c("female", "male", "both"))
data_new2$Condition <- factor(ifelse(data_new2$Condition == 'chronic kidney disease', 'CKD', as.character(data_new2$Condition)))
#data_new2$Biomarker <- factor(data_new2$Biomarker, levels= c("IL-10", "IL-6", "TNF-alpha", "CRP"))
data_new2$biomarker_type2 <- factor(data_new2$biomarker_type2)
data_new2$biomarker_type2.col <- factor(data_new2$biomarker_type2.col)
data_new2$Intensity <- factor(data_new2$Intensity, levels= c('low', 'moderate', 'high', 'control'))
data_new2$Duration <- factor(data_new2$Duration, levels= c('low', 'moderate', 'high', 'control'))
data_new2$biomarker_type2 <- factor(data_new2$biomarker_type2, levels= c("ai", "pi/ai", "pi"))
data_new2 <- data.table(data_new2)
data_new2[,c('biomarker_type', 'yi2_new')] <- NULL
data_new2[, 'Condition_new' := factor(ifelse(Condition == 'control', 'Control', 
                                             ifelse(Condition == 'healthy', 'Healthy', 'Non-Healthy')))]

## Healthy - tables
View(summarize(group_by(filter(data_new, Biomarker != 'IL-6'), Activity.type, Treatment.type, Intensity, Duration), min = min(yi_new),
                                                                                       mean = mean(yi_new),
                                                                                       median = median(yi_new),
                                                                                       max = max(yi_new)))
View(summarize(group_by(filter(data_new, Biomarker != 'IL-6'), Activity.type, Treatment.type, Intensity, Duration), min = min(wyi2), 
                                                                                       mean = mean(wyi2),
                                                                                       mean2 = sum(wyi2)/sum(1/vi2),
                                                                                       median = median(wyi2),
                                                                                       max = max(wyi2)))

## Non-Healthy - tables
View(summarize(group_by(filter(data_new2, Biomarker != 'IL-6'), Activity.type, Treatment.type, Intensity, Duration), min = min(yi_new), 
               mean = mean(yi_new),
               median = median(yi_new),
               max = max(yi_new)))
View(summarize(group_by(filter(data_new2, Biomarker != 'IL-6'), Activity.type, Treatment.type, Intensity, Duration), min = min(wyi2), 
               mean = mean(wyi2),
               mean2 = sum(wyi2)/sum(1/vi2),
               median = median(wyi2),
               max = max(wyi2)))

## Healthy - plots
ggplot(data_new, aes(Biomarker, yi, ymin=yi-sqrt(vi), ymax=yi+sqrt(vi))) + geom_errorbar() #+ facet_grid(Treatment.type~Activity.type)
## Non-Healthy - plots
ggplot(data_new2, aes(Biomarker, yi, ymin=yi-sqrt(vi), ymax=yi+sqrt(vi))) + geom_errorbar() #+ facet_grid(Treatment.type~Activity.type)

##############################################################
# Meta-Regression Analysis: Intensity and Duration interaction
##############################################################
# table(data$Intensity, data$Duration)
# rma.data <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity+Duration, method="REML")
# rma.data2 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity*Duration, method="REML")
# anova(rma.data, rma.data2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data3.1 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity:Duration-1, method="FE") #REML
rma.data3 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Intensity:Duration-1, method="FE") #REML
coef_rma.data3 <- data.frame(coef(rma.data3)) 
coef_rma.data3$Predictors <- rownames(coef_rma.data3)
coef_rma.data3$group <- 'data'
rownames(coef_rma.data3) <- NULL
colnames(coef_rma.data3) <- c('SMD', 'Predictors' , 'group')

coef_rma.data3.1 <- data.frame(coef(rma.data3.1))
coef_rma.data3.1$Predictors <- rownames(coef_rma.data3.1)
coef_rma.data3.1$group <- 'data.demo'
rownames(coef_rma.data3.1) <- NULL
colnames(coef_rma.data3.1) <- c('SMD', 'Predictors' , 'group')


# table(data_new$Intensity, data_new$Duration)
# rma.data_healthy <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity+Duration, method="REML")
# rma.data_healthy2 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity*Duration, method="REML")
# anova(rma.data_healthy, rma.data_healthy2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data_healthy3.1 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity:Duration-1, method="FE") #REML
rma.data_healthy3 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Intensity:Duration-1, method="FE") #REML
coef_rma.data_healthy3 <- data.frame(coef(rma.data_healthy3))
coef_rma.data_healthy3$Predictors <- rownames(coef_rma.data_healthy3)
coef_rma.data_healthy3$group <- 'healthy'
rownames(coef_rma.data_healthy3) <- NULL
colnames(coef_rma.data_healthy3) <- c('SMD', 'Predictors', 'group')

coef_rma.data_healthy3.1 <- data.frame(coef(rma.data_healthy3.1))
coef_rma.data_healthy3.1$Predictors <- rownames(coef_rma.data_healthy3.1)
coef_rma.data_healthy3.1$group <- 'healthy.demo'
rownames(coef_rma.data_healthy3.1) <- NULL
colnames(coef_rma.data_healthy3.1) <- c('SMD', 'Predictors', 'group')


# table(data_new2$Intensity, data_new2$Duration)
# rma.data_nonhealthy <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity+Duration, method="REML")
# rma.data_nonhealthy2 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity*Duration, method="REML")
# anova(rma.data_nonhealthy, rma.data_nonhealthy2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data_nonhealthy3.1 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity:Duration-1, method="FE") #REML
rma.data_nonhealthy3 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Intensity:Duration-1, method="FE") #REML
coef_rma.data_nonhealthy3 <- data.frame(coef(rma.data_nonhealthy3))
coef_rma.data_nonhealthy3$Predictors <- rownames(coef_rma.data_nonhealthy3)
coef_rma.data_nonhealthy3$group <- 'non-healthy'
rownames(coef_rma.data_nonhealthy3) <- NULL
colnames(coef_rma.data_nonhealthy3) <- c('SMD', 'Predictors', 'group')

coef_rma.data_nonhealthy3.1 <- data.frame(coef(rma.data_nonhealthy3.1))
coef_rma.data_nonhealthy3.1$Predictors <- rownames(coef_rma.data_nonhealthy3.1)
coef_rma.data_nonhealthy3.1$group <- 'non-healthy.demo'
rownames(coef_rma.data_nonhealthy3.1) <- NULL
colnames(coef_rma.data_nonhealthy3.1) <- c('SMD', 'Predictors', 'group')


#Combining of Results
Predictors <- c('Age', 'Genderfemale', 'Gendermale', 'Genderboth', 'PeriodLength', 'Intensitylow:Durationlow', 'Intensitylow:Durationmoderate', 
          'Intensitylow:Durationhigh', 'Intensitymoderate:Durationlow', 'Intensitymoderate:Durationmoderate', 'Intensitymoderate:Durationhigh',
          'Intensityhigh:Durationlow', 'Intensityhigh:Durationmoderate', 'Intensityhigh:Durationhigh', 'Intensitycontrol:Durationcontrol', 'Intensitycontrol:Durationlow', 
          'Intensitycontrol:Durationmoderate', 'Intensitycontrol:Durationhigh')
predictors <- data.frame(Predictors)
predictors_data <- left_join(predictors, coef_rma.data3, by = 'Predictors')
predictors_data$group <- 'All:Interaction'
predictors_data.1 <- left_join(predictors, coef_rma.data3.1, by = 'Predictors')
predictors_data.1$group <- 'All:Interaction + Demographics'
predictors_datahealthy <- left_join(predictors, coef_rma.data_healthy3, by = 'Predictors')
predictors_datahealthy$group <- 'Healthy:Interaction'
predictors_datahealthy.1 <- left_join(predictors, coef_rma.data_healthy3.1, by = 'Predictors')
predictors_datahealthy.1$group <- 'Healthy:Interaction + Demographics'
predictors_datanonhealthy <- left_join(predictors, coef_rma.data_nonhealthy3, by = 'Predictors')
predictors_datanonhealthy$group <- 'Nonhealthy:Interaction'
predictors_datanonhealthy.1 <- left_join(predictors, coef_rma.data_nonhealthy3.1, by = 'Predictors')
predictors_datanonhealthy.1$group <- 'Nonhealthy:Interaction + Demographics'

predictors_ <- data.table(rbind(predictors_data, predictors_datahealthy, predictors_datanonhealthy,
                                predictors_data.1, predictors_datahealthy.1, predictors_datanonhealthy.1))

predictors_[, c('Intensity', 'Duration') := list('', '')] 
for(i in 1:nrow(predictors_)) {
  predictors_[,'Intensity'][i] <- unlist(strsplit(as.character(predictors_[,'Predictors'][i]), "[:]"))[1]
  predictors_[,'Duration'][i] <- unlist(strsplit(as.character(predictors_[,'Predictors'][i]), "[:]"))[2]
                              }
predictors_[, c('Intensity') := ifelse(Intensity == 'Intensitylow', 'low',
                                              ifelse(Intensity == 'Intensitymoderate', 'moderate',
                                                     ifelse(Intensity == 'Intensityhigh', 'high',
                                                            ifelse(Intensity == 'Intensitycontrol', 'control', NA))))]
predictors_[, c('Duration') := ifelse(Duration == 'Durationlow', 'low',
                                       ifelse(Duration == 'Durationmoderate', 'moderate',
                                              ifelse(Duration == 'Durationhigh', 'high',
                                                     ifelse(Duration == 'Durationcontrol', 'control', NA))))]

predictors_[group %in% c('All:Interaction') & Intensity == 'control' & Duration != 'control']$SMD <- 
  ifelse(is.na(predictors_[group %in% c('All:Interaction') & Intensity == 'control' & Duration != 'control']$SMD) == TRUE, 
       predictors_[group %in% c('All:Interaction') & Intensity == 'control' & Duration == 'control']$SMD, predictors_$SMD)
predictors_[group %in% c('All:Interaction + Demographics') & Intensity == 'control']$SMD <- 
  ifelse(is.na(predictors_[group %in% c('All:Interaction + Demographics') & Intensity == 'control']$SMD) == TRUE, 0, predictors_$SMD)
predictors_[group %in% c('Healthy:Interaction') & Intensity == 'control' & Duration != 'control']$SMD <- 
  ifelse(is.na(predictors_[group %in% c('Healthy:Interaction') & Intensity == 'control' & Duration != 'control']$SMD) == TRUE, 
         predictors_[group %in% c('Healthy:Interaction') & Intensity == 'control' & Duration == 'control']$SMD, predictors_$SMD)
predictors_[group %in% c('Healthy:Interaction + Demographics') & Intensity == 'control']$SMD <- 
  ifelse(is.na(predictors_[group %in% c('Healthy:Interaction + Demographics') & Intensity == 'control']$SMD) == TRUE, 0, predictors_$SMD)
predictors_[group %in% c('Nonhealthy:Interaction') & Intensity == 'control' & Duration != 'control']$SMD <- 
  ifelse(is.na(predictors_[group %in% c('Nonhealthy:Interaction') & Intensity == 'control' & Duration != 'control']$SMD) == TRUE, 
         predictors_[group %in% c('Nonhealthy:Interaction') & Intensity == 'control' & Duration == 'control']$SMD, predictors_$SMD)
predictors_[group %in% c('Nonhealthy:Interaction + Demographics') & Intensity == 'control']$SMD <- 
  ifelse(is.na(predictors_[group %in% c('Nonhealthy:Interaction + Demographics') & Intensity == 'control']$SMD) == TRUE, 0, predictors_$SMD)
predictors_[, c('Intensity', 'Duration') := list(factor(Intensity, levels= c('low', 'moderate', 'high', 'control')),
                                                 factor(Duration, levels= c('low', 'moderate', 'high', 'control')))]


#Interaction plots: Intensity and Duration
ID.all <- ggplot(predictors_[group %in% c('All:Interaction', 'All:Interaction + Demographics') & is.na(Intensity) == FALSE & Predictors != 'Intensitycontrol:Durationcontrol']) + 
  geom_point(aes(Duration, SMD, group = Intensity, colour = Intensity)) + 
  geom_line(aes(Duration, SMD, colour = Intensity, group = Intensity)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers')

ID.all  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


ID.healthy <- ggplot(predictors_[group %in% c('Healthy:Interaction', 'Healthy:Interaction + Demographics') & is.na(Intensity) == FALSE & Predictors != 'Intensitycontrol:Durationcontrol']) + 
  geom_point(aes(Duration, SMD, group = Intensity, colour = Intensity)) + 
  geom_line(aes(Duration, SMD, colour = Intensity, group = Intensity)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers')

ID.healthy + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


ID.nonhealthy <- ggplot(predictors_[group %in% c('Nonhealthy:Interaction', 'Nonhealthy:Interaction + Demographics') & is.na(Intensity) == FALSE & Predictors != 'Intensitycontrol:Durationcontrol']) + 
  geom_point(aes(Duration, SMD, group = Intensity, colour = Intensity)) + 
  geom_line(aes(Duration, SMD, colour = Intensity, group = Intensity)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers')

ID.nonhealthy + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


ID.HNH <- ggplot(predictors_[group %in% c('Healthy:Interaction', 'Nonhealthy:Interaction') & is.na(Intensity) == FALSE & Predictors != 'Intensitycontrol:Durationcontrol']) + 
  geom_point(aes(Duration, SMD, group = Intensity, colour = Intensity)) + 
  geom_line(aes(Duration, SMD, colour = Intensity, group = Intensity)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers')

ID.HNH + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 

ID.HNH.demo <- ggplot(predictors_[group %in% c('Healthy:Interaction + Demographics', 'Nonhealthy:Interaction + Demographics') & is.na(Intensity) == FALSE & Predictors != 'Intensitycontrol:Durationcontrol']) + 
  geom_point(aes(Duration, SMD, group = Intensity, colour = Intensity)) + 
  geom_line(aes(Duration, SMD, colour = Intensity, group = Intensity)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers')

ID.HNH.demo + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d'))  #500 x 420




# #Interaction Plots (Alternative way)
# #par(mfrow=c(2, 1))
# plot(rep(predictors_[group=='data']$SMD[c(15)], 3), type="o", pch=16, lty="twodash", ylim = c(-2.0, 3.0), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
# axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
# lines(predictors_[group=='data']$SMD[c(6:8)], type="o", pch=15, lty="solid", lwd = 2, col = '#4f81bd')
# lines(predictors_[group=='data']$SMD[c(9:11)], type="o", pch=19, lty="dotted", lwd = 2, col = '#febe10')
# lines(predictors_[group=='data']$SMD[c(12:14)], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
# legend("topright", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"),
#        lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 15, 19, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
#        cex = 0.7, pt.cex = 1.2)
# 
# plot(rep(0, 3), type="o", pch=16, lty="twodash", ylim = c(-2.0, 3.0), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
# axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
# lines(predictors_[group=='data.demo']$SMD[c(6:8)], type="o", pch=15, lty="solid", lwd = 2, col = '#4f81bd')
# lines(predictors_[group=='data.demo']$SMD[c(9:11)], type="o", pch=19, lty="dotted", lwd = 2, col = '#febe10')
# lines(predictors_[group=='data.demo']$SMD[c(12:14)], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
# legend("topright", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"), 
#        lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 15, 19, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
#        inset=0.1 ,cex = 0.7, pt.cex = 1.2)
# 
# 
# 
# plot(rep(predictors_[group=='healthy']$SMD[c(15)], 3), type="o", pch=16, lty="twodash", ylim = c(-3.0, 3.0), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
# axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
# lines(predictors_[group=='healthy']$SMD[c(6:8)], type="o", pch=15, lty="solid", lwd = 2, col = '#4f81bd')
# lines(predictors_[group=='healthy']$SMD[c(9:11)], type="o", pch=19, lty="dotted", lwd = 2, col = '#febe10')
# lines(predictors_[group=='healthy']$SMD[c(12:14)], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
# legend("topleft", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"), 
#        lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 15, 19, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
#        inset=0.01 ,cex = 0.7, pt.cex = 1.2)
# 
# plot(rep(0, 3), type="o", pch=16, lty="twodash", ylim = c(-3.0, 3.0), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
# axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
# lines(predictors_[group=='healthy.demo']$SMD[c(6:8)], type="o", pch=15, lty="solid", lwd = 2, col = '#4f81bd')
# lines(predictors_[group=='healthy.demo']$SMD[c(9:11)], type="o", pch=19, lty="dotted", lwd = 2, col = '#febe10')
# lines(predictors_[group=='healthy.demo']$SMD[c(12:14)], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
# legend("topleft", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"), 
#        lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 15, 19, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
#        inset=0.01 ,cex = 0.7, pt.cex = 1.2)
# 
# 
# plot(rep(predictors_[group=='nonhealthy']$SMD[c(15)], 3), type="o", pch=16, lty="twodash", ylim = c(-1.0, 3.0), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
# axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
# lines(predictors_[group=='nonhealthy']$SMD[c(6:8)], type="o", pch=15, lty="solid", lwd = 2, col = '#4f81bd')
# lines(predictors_[group=='nonhealthy']$SMD[c(9:11)], type="o", pch=19, lty="dotted", lwd = 2, col = '#febe10')
# lines(predictors_[group=='nonhealthy']$SMD[c(12:14)], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
# legend("topleft", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"), 
#        lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 15, 19, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
#        inset=0.01 ,cex = 0.7, pt.cex = 1.2)
# 
# plot(rep(0, 3), type="o", pch=16, lty="twodash", ylim = c(-1.0, 3.0), col = '#c0504d', lwd = 2, xaxt = "n", bty = "l", ylab = "Standardized Mean Difference", xlab = "Duration")
# axis(side=1, at=1:3, labels=c("low", "moderate", "high"))
# lines(predictors_[group=='nonhealthy.demo']$SMD[c(6:8)], type="o", pch=15, lty="solid", lwd = 2, col = '#4f81bd')
# lines(predictors_[group=='nonhealthy.demo']$SMD[c(9:11)], type="o", pch=19, lty="dotted", lwd = 2, col = '#febe10')
# lines(predictors_[group=='nonhealthy.demo']$SMD[c(12:14)], type="o", pch=17, lty="dashed", lwd = 2, col = '#abbb59')
# legend("topleft", legend=c("control", "Intensity-low", "Intensity-moderate", "Intensity-high"), 
#        lty=c('twodash', 'solid', 'dotted', 'dashed'), pch = c(16, 15, 19, 17), col = c('#c0504d', '#4f81bd', '#febe10', '#abbb59'),
#        inset=0.01 ,cex = 0.7, pt.cex = 1.2)


####################################################################
# Meta-Regression Analysis: Intensity and PeriodLength interaction
####################################################################
# table(data$Intensity, data$PeriodLength)
# rma.data <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity+Duration, method="REML")
# rma.data2 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+Intensity*PeriodLength+Duration, method="REML")
# anova(rma.data, rma.data2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data3.1 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+Intensity:PeriodLength+Duration-1, method="FE") #+Duration:PeriodLength
rma.data3 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Intensity:PeriodLength+Duration-1, method="FE")
coef_rma.data3 <- data.frame(coef(rma.data3))
coef_rma.data3$Predictors <- rownames(coef_rma.data3)
coef_rma.data3$group <- 'data'
rownames(coef_rma.data3) <- NULL
colnames(coef_rma.data3) <- c('SMD', 'Predictors' , 'group')

coef_rma.data3.1 <- data.frame(coef(rma.data3.1))
coef_rma.data3.1$Predictors <- rownames(coef_rma.data3.1)
coef_rma.data3.1$group <- 'data.demo'
rownames(coef_rma.data3.1) <- NULL
colnames(coef_rma.data3.1) <- c('SMD', 'Predictors' , 'group')


# table(data_new$Intensity, data_new$Duration)
# rma.data_healthy <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity, method="REML")
# rma.data_healthy2 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+Intensity*PeriodLength, method="REML")
# anova(rma.data_healthy, rma.data_healthy2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data_healthy3.1 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+Intensity:PeriodLength+Duration-1, method="FE")
rma.data_healthy3 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Intensity:PeriodLength+Duration-1, method="FE")
coef_rma.data_healthy3 <- data.frame(coef(rma.data_healthy3))
coef_rma.data_healthy3$Predictors <- rownames(coef_rma.data_healthy3)
coef_rma.data_healthy3$group <- 'healthy'
rownames(coef_rma.data_healthy3) <- NULL
colnames(coef_rma.data_healthy3) <- c('SMD', 'Predictors', 'group')

coef_rma.data_healthy3.1 <- data.frame(coef(rma.data_healthy3.1))
coef_rma.data_healthy3.1$Predictors <- rownames(coef_rma.data_healthy3.1)
coef_rma.data_healthy3.1$group <- 'healthy.demo'
rownames(coef_rma.data_healthy3.1) <- NULL
colnames(coef_rma.data_healthy3.1) <- c('SMD', 'Predictors', 'group')


# table(data_new2$Intensity, data_new2$Duration)
# rma.data_nonhealthy <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity, method="REML")
# rma.data_nonhealthy2 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+Intensity:PeriodLength, method="REML")
# anova(rma.data_nonhealthy, rma.data_nonhealthy2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data_nonhealthy3.1 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+Intensity:PeriodLength+Duration-1, method="FE")
rma.data_nonhealthy3 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Intensity:PeriodLength+Duration-1, method="FE")
coef_rma.data_nonhealthy3 <- data.frame(coef(rma.data_nonhealthy3))
coef_rma.data_nonhealthy3$Predictors <- rownames(coef_rma.data_nonhealthy3)
coef_rma.data_nonhealthy3$group <- 'non-healthy'
rownames(coef_rma.data_nonhealthy3) <- NULL
colnames(coef_rma.data_nonhealthy3) <- c('SMD', 'Predictors', 'group')

coef_rma.data_nonhealthy3.1 <- data.frame(coef(rma.data_nonhealthy3.1))
coef_rma.data_nonhealthy3.1$Predictors <- rownames(coef_rma.data_nonhealthy3.1)
coef_rma.data_nonhealthy3.1$group <- 'non-healthy.demo'
rownames(coef_rma.data_nonhealthy3.1) <- NULL
colnames(coef_rma.data_nonhealthy3.1) <- c('SMD', 'Predictors', 'group')


#Combining of Results
Predictors <- c('Age', 'Genderfemale', 'Gendermale', 'Genderboth', 'PeriodLength', 'Intensitylow:PeriodLength', 'Intensitymoderate:PeriodLength', 
                'Intensityhigh:PeriodLength', 'Intensitycontrol:PeriodLength')
predictors <- data.frame(Predictors)
predictors_data <- left_join(predictors, coef_rma.data3, by = 'Predictors')
predictors_data$group <- 'All:Interaction'
predictors_data.1 <- left_join(predictors, coef_rma.data3.1, by = 'Predictors')
predictors_data.1$group <- 'All:Interaction + Demographics'
predictors_datahealthy <- left_join(predictors, coef_rma.data_healthy3, by = 'Predictors')
predictors_datahealthy$group <- 'Healthy:Interaction'
predictors_datahealthy.1 <- left_join(predictors, coef_rma.data_healthy3.1, by = 'Predictors')
predictors_datahealthy.1$group <- 'Healthy:Interaction + Demographics'
predictors_datanonhealthy <- left_join(predictors, coef_rma.data_nonhealthy3, by = 'Predictors')
predictors_datanonhealthy$group <- 'Nonhealthy:Interaction'
predictors_datanonhealthy.1 <- left_join(predictors, coef_rma.data_nonhealthy3.1, by = 'Predictors')
predictors_datanonhealthy.1$group <- 'Nonhealthy:Interaction + Demographics'

predictors_ <- data.table(rbind(predictors_data, predictors_datahealthy, predictors_datanonhealthy,
                                predictors_data.1, predictors_datahealthy.1, predictors_datanonhealthy.1))
#predictors_ <- data.table(rbind(predictors_data,predictors_data.1))

predictors_[, c('Intensity') := list('')] 
for(i in 1:nrow(predictors_)) {
  predictors_[,'Intensity'][i] <- unlist(strsplit(as.character(predictors_[,'Predictors'][i]), "[:]"))[1]
}
predictors_[, c('Intensity') := ifelse(Intensity == 'Intensitylow', 'low',
                                       ifelse(Intensity == 'Intensitymoderate', 'moderate',
                                              ifelse(Intensity == 'Intensityhigh', 'high',
                                                     ifelse(Intensity == 'Intensitycontrol', 'control', NA))))]

predictors_new <- predictors_[is.na(Intensity) == FALSE]
predictors_new_ <- data.frame(matrix(seq(1, 5760, 1), nrow=1152, ncol = 5))
for(i in 1:24) {
  for(j in 1:24) {
    value <- predictors_new$SMD[i]*j
    predictors <- predictors_new[,c('Predictors')][i]
    smd <- predictors_new[,c('SMD')][i]
    group <- predictors_new[,c('group')][i]
    intensity <- predictors_new[,c('Intensity')][i]
    predictors_new_[j+(48*(i-1)), ] <- c(predictors, smd, group, intensity, value)
    predictors_new_$i[j+(48*(i-1))] <- i
    predictors_new_$j[j+(48*(i-1))] <- j
  }
}
colnames(predictors_new_) <- c('Predictors', 'SMD', 'group', 'Intensity', 'value', 'i', 'j')
predictors_new_ <- data.table(predictors_new_)
predictors_new_$Intensity <- factor(predictors_new_$Intensity, levels = c('low', 'moderate', 'high', 'control'))

#Interaction plots: Intensity and PeriodLength
IP.all <- ggplot(predictors_new_[group %in% c('All:Interaction', 'All:Interaction + Demographics') & is.na(Intensity) == FALSE]) + 
  geom_point(aes(j, value, group = Intensity, colour = Intensity)) + 
  geom_line(aes(j, value, colour = Intensity, group = Intensity)) + 
  #geom_line(predictors_[group %in% c('data') & Intensity == 'control' & Duration == 'control'], aes(rep(SMD, 3))) +
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

IP.all  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


IP.healthy <- ggplot(predictors_new_[group %in% c('Healthy:Interaction', 'Healthy:Interaction + Demographics') & is.na(Intensity) == FALSE]) + 
  geom_point(aes(j, value, group = Intensity, colour = Intensity)) + 
  geom_line(aes(j, value, colour = Intensity, group = Intensity)) + 
  #geom_line(predictors_[group %in% c('data') & Intensity == 'control' & Duration == 'control'], aes(rep(SMD, 3))) +
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

IP.healthy  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


IP.nonhealthy <- ggplot(predictors_new_[group %in% c('Nonhealthy:Interaction', 'Nonhealthy:Interaction + Demographics') & is.na(Intensity) == FALSE]) + 
  geom_point(aes(j, value, group = Intensity, colour = Intensity)) + 
  geom_line(aes(j, value, colour = Intensity, group = Intensity)) + 
  #geom_line(predictors_[group %in% c('data') & Intensity == 'control' & Duration == 'control'], aes(rep(SMD, 3))) +
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

IP.nonhealthy  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


IP.healthynonhealthy <- ggplot(predictors_new_[group %in% c('Healthy:Interaction', 'Nonhealthy:Interaction') & is.na(Intensity) == FALSE]) + 
  geom_point(aes(j, value, group = Intensity, colour = Intensity)) + 
  geom_line(aes(j, value, colour = Intensity, group = Intensity)) + 
  #geom_line(predictors_[group %in% c('data') & Intensity == 'control' & Duration == 'control'], aes(rep(SMD, 3))) +
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

IP.healthynonhealthy  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


IP.healthynonhealthy.demo <- ggplot(predictors_new_[group %in% c('Healthy:Interaction + Demographics', 'Nonhealthy:Interaction + Demographics') & is.na(Intensity) == FALSE]) + 
  geom_point(aes(j, value, group = Intensity, colour = Intensity)) + 
  geom_line(aes(j, value, colour = Intensity, group = Intensity)) + 
  #geom_line(predictors_[group %in% c('data') & Intensity == 'control' & Duration == 'control'], aes(rep(SMD, 3))) +
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

IP.healthynonhealthy.demo  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Intensity', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 

####################################################################
# Meta-Regression Analysis: Duration and PeriodLength interaction
####################################################################
# table(data$Intensity, data$PeriodLength)
# rma.data <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity+Duration, method="REML")
# rma.data2 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+Duration*PeriodLength+Intensity, method="REML")
# anova(rma.data, rma.data2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data3.1 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Age+Gender+Duration:PeriodLength+Intensity-1, method="FE") #+Duration:PeriodLength
rma.data3 <- rma(yi2, vi2, data=data[Biomarker != 'IL-6'], mods=~ Duration:PeriodLength+Intensity-1, method="FE")
coef_rma.data3 <- data.frame(coef(rma.data3))
coef_rma.data3$Predictors <- rownames(coef_rma.data3)
coef_rma.data3$group <- 'data'
rownames(coef_rma.data3) <- NULL
colnames(coef_rma.data3) <- c('SMD', 'Predictors' , 'group')

coef_rma.data3.1 <- data.frame(coef(rma.data3.1))
coef_rma.data3.1$Predictors <- rownames(coef_rma.data3.1)
coef_rma.data3.1$group <- 'data.demo'
rownames(coef_rma.data3.1) <- NULL
colnames(coef_rma.data3.1) <- c('SMD', 'Predictors' , 'group')


# table(data_new$Intensity, data_new$Duration)
# rma.data_healthy <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity, method="REML")
# rma.data_healthy2 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+Duration:PeriodLength+Intensity, method="REML")
# anova(rma.data_healthy, rma.data_healthy2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data_healthy3.1 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Age+Gender+Duration:PeriodLength+Intensity-1, method="FE")
rma.data_healthy3 <- rma(yi2, vi2, data=data_new[Biomarker != 'IL-6'], mods=~ Duration:PeriodLength+Intensity-1, method="FE")
coef_rma.data_healthy3 <- data.frame(coef(rma.data_healthy3))
coef_rma.data_healthy3$Predictors <- rownames(coef_rma.data_healthy3)
coef_rma.data_healthy3$group <- 'healthy'
rownames(coef_rma.data_healthy3) <- NULL
colnames(coef_rma.data_healthy3) <- c('SMD', 'Predictors', 'group')

coef_rma.data_healthy3.1 <- data.frame(coef(rma.data_healthy3.1))
coef_rma.data_healthy3.1$Predictors <- rownames(coef_rma.data_healthy3.1)
coef_rma.data_healthy3.1$group <- 'healthy.demo'
rownames(coef_rma.data_healthy3.1) <- NULL
colnames(coef_rma.data_healthy3.1) <- c('SMD', 'Predictors', 'group')


# table(data_new2$Intensity, data_new2$Duration)
# rma.data_nonhealthy <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+PeriodLength+Intensity, method="REML")
# rma.data_nonhealthy2 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+Duration:PeriodLength+Intensity, method="REML")
# anova(rma.data_nonhealthy, rma.data_nonhealthy2)

#Age+Gender+PeriodLength+Intensity:Duration+Intensity:PeriodLength+Duration:PeriodLength
#Intensity:Duration
rma.data_nonhealthy3.1 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Age+Gender+Duration:PeriodLength+Intensity-1, method="FE")
rma.data_nonhealthy3 <- rma(yi2, vi2, data=data_new2[Biomarker != 'IL-6'], mods=~ Duration:PeriodLength+Intensity-1, method="FE")
coef_rma.data_nonhealthy3 <- data.frame(coef(rma.data_nonhealthy3))
coef_rma.data_nonhealthy3$Predictors <- rownames(coef_rma.data_nonhealthy3)
coef_rma.data_nonhealthy3$group <- 'non-healthy'
rownames(coef_rma.data_nonhealthy3) <- NULL
colnames(coef_rma.data_nonhealthy3) <- c('SMD', 'Predictors', 'group')

coef_rma.data_nonhealthy3.1 <- data.frame(coef(rma.data_nonhealthy3.1))
coef_rma.data_nonhealthy3.1$Predictors <- rownames(coef_rma.data_nonhealthy3.1)
coef_rma.data_nonhealthy3.1$group <- 'non-healthy.demo'
rownames(coef_rma.data_nonhealthy3.1) <- NULL
colnames(coef_rma.data_nonhealthy3.1) <- c('SMD', 'Predictors', 'group')


#Combining of Results
Predictors <- c('Age', 'Genderfemale', 'Gendermale', 'Genderboth', 'PeriodLength', 'Durationlow:PeriodLength', 'Durationmoderate:PeriodLength', 
                'Durationhigh:PeriodLength', 'Durationcontrol:PeriodLength')
predictors <- data.frame(Predictors)
predictors_data <- left_join(predictors, coef_rma.data3, by = 'Predictors')
predictors_data$group <- 'All:Interaction'
predictors_data.1 <- left_join(predictors, coef_rma.data3.1, by = 'Predictors')
predictors_data.1$group <- 'All:Interaction + Demographics'
predictors_datahealthy <- left_join(predictors, coef_rma.data_healthy3, by = 'Predictors')
predictors_datahealthy$group <- 'Healthy:Interaction'
predictors_datahealthy.1 <- left_join(predictors, coef_rma.data_healthy3.1, by = 'Predictors')
predictors_datahealthy.1$group <- 'Healthy:Interaction + Demographics'
predictors_datanonhealthy <- left_join(predictors, coef_rma.data_nonhealthy3, by = 'Predictors')
predictors_datanonhealthy$group <- 'Nonhealthy:Interaction'
predictors_datanonhealthy.1 <- left_join(predictors, coef_rma.data_nonhealthy3.1, by = 'Predictors')
predictors_datanonhealthy.1$group <- 'Nonhealthy:Interaction + Demographics'

predictors_ <- data.table(rbind(predictors_data, predictors_datahealthy, predictors_datanonhealthy,
                                predictors_data.1, predictors_datahealthy.1, predictors_datanonhealthy.1))

predictors_[, c('Duration') := list('')] 
for(i in 1:nrow(predictors_)) {
  predictors_[,'Duration'][i] <- unlist(strsplit(as.character(predictors_[,'Predictors'][i]), "[:]"))[1]
}
predictors_[, c('Duration') := ifelse(Duration == 'Durationlow', 'low',
                                       ifelse(Duration == 'Durationmoderate', 'moderate',
                                              ifelse(Duration == 'Durationhigh', 'high',
                                                     ifelse(Duration == 'Durationcontrol', 'control', NA))))]

predictors_new <- predictors_[is.na(Duration) == FALSE]
predictors_new_ <- data.frame(matrix(seq(1, 5760, 1), nrow=1152, ncol = 5))
for(i in 1:24) {
  for(j in 1:24) {
    value <- predictors_new$SMD[i]*j
    predictors <- predictors_new[,c('Predictors')][i]
    smd <- predictors_new[,c('SMD')][i]
    group <- predictors_new[,c('group')][i]
    duration <- predictors_new[,c('Duration')][i]
    predictors_new_[j+(48*(i-1)), ] <- c(predictors, smd, group, duration, value)
    predictors_new_$i[j+(48*(i-1))] <- i
    predictors_new_$j[j+(48*(i-1))] <- j
  }
}
colnames(predictors_new_) <- c('Predictors', 'SMD', 'group', 'Duration', 'value', 'i', 'j')
predictors_new_ <- data.table(predictors_new_)
predictors_new_$Duration <- factor(predictors_new_$Duration, levels = c('low', 'moderate', 'high', 'control'))

#Interaction plots: Intensity and PeriodLength
DP.all <- ggplot(predictors_new_[group %in% c('All:Interaction', 'All:Interaction + Demographics') & is.na(Duration) == FALSE]) + 
  geom_point(aes(j, value, group = Duration, colour = Duration)) + 
  geom_line(aes(j, value, colour = Duration, group = Duration)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

DP.all  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Duration', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


DP.healthy <- ggplot(predictors_new_[group %in% c('Healthy:Interaction', 'Healthy:Interaction + Demographics') & is.na(Duration) == FALSE]) + 
  geom_point(aes(j, value, group = Duration, colour = Duration)) + 
  geom_line(aes(j, value, colour = Duration, group = Duration)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

DP.healthy  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Duration', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


DP.nonhealthy <- ggplot(predictors_new_[group %in% c('Nonhealthy:Interaction', 'Nonhealthy:Interaction + Demographics') & is.na(Duration) == FALSE]) + 
  geom_point(aes(j, value, group = Duration, colour = Duration)) + 
  geom_line(aes(j, value, colour = Duration, group = Duration)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

DP.nonhealthy  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Duration', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


DP.healthynonhealthy <- ggplot(predictors_new_[group %in% c('Healthy:Interaction', 'Nonhealthy:Interaction') & is.na(Duration) == FALSE]) + 
  geom_point(aes(j, value, group = Duration, colour = Duration)) + 
  geom_line(aes(j, value, colour = Duration, group = Duration)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

DP.healthynonhealthy  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Duration', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 


DP.healthynonhealthy.demo <- ggplot(predictors_new_[group %in% c('Healthy:Interaction + Demographics', 'Nonhealthy:Interaction + Demographics') & is.na(Duration) == FALSE]) + 
  geom_point(aes(j, value, group = Duration, colour = Duration)) + 
  geom_line(aes(j, value, colour = Duration, group = Duration)) + 
  facet_grid(.~group) + ylab('Standardized Mean Difference \n of the effect change in inflammatory biomarkers') + xlab('Period Length (weeks)')

DP.healthynonhealthy.demo  + theme_bw() + theme(panel.border = element_blank(), axis.line=element_line('#a6a6a6'), axis.text.x=element_text(hjust=1)) + 
  theme(legend.position = 'top') +
  theme(panel.grid.major.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), panel.grid.minor.y = element_line("dashed", size = 0.5, colour = "#a6a6a6"), 
        plot.title = element_text(hjust = 0.5)) +
  scale_colour_manual(name = 'Duration', values = c('#4f81bd', '#febe10', '#abbb59', '#c0504d')) 

