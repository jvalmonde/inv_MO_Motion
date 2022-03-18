library(ggplot2)
library(metafor)
library(data.table)
library(glmulti)
library(grid)
library(rmeta)


path <- "S:/Research Group/Anti-inflammatory Effects of Exercise/"
# path <- "/Users/mac/Desktop/"
# data <- read.csv(paste(path, "anti_inflammatory_exercise_v3.csv", sep = ''), stringsAsFactors = F)
data <- read.csv(paste(path, "anti_inflammatory_exercise_v4.csv", sep = ''), stringsAsFactors = F)
str(data)
summary(data)
#changing blank character column cells to NA
data[data==""] <- NA

#estimating effect sizes using Standard mean difference----
data <- escalc(measure="SMCRH",m2i = Mean.pre_lvl, m1i =Mean.post_lvl, sd2i=SD.pre_lvl, sd1i=SD.post_lvl, ni=Population, ri=rep(0, nrow(data)), data=data)
data <- as.data.table(data)

#classifying duration by high, moderate and low ----
data[,':=' (Dur.Aerobic = ifelse(is.na(Dur.Aerobic), 0, Dur.Aerobic),
            Dur.Resistance = ifelse(is.na(Dur.Resistance), 0, Dur.Resistance)
)]


duration_class <- function(arbic, res){
  oc <- if(arbic > 40 | res > 15) "high" else
    if((arbic <=40 & arbic > 20) | (res <= 15 & res > 8)) "moderate" else
      if((arbic <= 20 & arbic > 0) | (res <= 8 & res > 0)) "low" else 
        if(arbic == 0 & res == 0) "control"  
  return(oc)
}

data[,Duration := mapply(function(x,y) duration_class(x,y), Dur.Aerobic, Dur.Resistance)]


#categorizing pro-inflammatory and anti-inflammatory biomarkers----
pro_inflam <- c( "TNF-alpha", "IL-18", "CRP", "hs-CRP", "MCP-1", "IL-1beta", "IL-15", "sTNFR1", 
                 "sICAM-1", "sVCAM-1", "ICAM-1", "VCAM-1", "MPO", "calprotectin", "leptin", "IL-8", "GM-CSF", "STNFR2", "CK", "WBC")
anti_inflam <- c("adiponectin", "IL-10", "EC-SOD", "IL-4", "IL-6", "IL-1ra")
data[,biomarker_type:=ifelse(Biomarker %in% anti_inflam, "ai", "pi")]

length(unique(data$biomarker)) == length(pro_inflam) + length(anti_inflam)
data[,yi_new:=ifelse(biomarker_type == "pi", -yi, yi)] #modifying the direction of the effect size for pro infammatory markers

#changing relevant charcter columns to factors ----
rel_col <- c("Gender", "Condition", "Treatment.type", "Activity.type", "Intensity", "Duration", "Biomarker")
data[,(rel_col):=lapply(.SD, as.factor),.SDcols = rel_col]
str(data)

#changing order of factor levels for Activity.type, Intensity, Duration & biomarker
data$Activity.type <- factor(data$Activity.type, levels=c("control", "aerobic", "aerobic-resistance", "resistance"))
# data$Intensity <- ordered(data$Intensity, levels= c("control", "low", "moderate", "high"))
# data$Duration <- ordered(data$Duration, levels= c("control", "low", "moderate", "high"))

data$Intensity <- factor(data$Intensity, levels= c("control", "low", "moderate", "high"), ordered=F)
data$Duration <- factor(data$Duration, levels= c("control", "low", "moderate", "high"), ordered=F)


#summary on study details
study <- unique(data$Study)
Biomarkers <- unlist(lapply(
  lapply(study, function(x) unique(data[Study==x, Biomarker])),
  function(y) paste(as.character(y), collapse=", ")
))
pop <- round(data[,.(mean_pop=mean(Population)), by=Study][,mean_pop],0)
Cond <- unlist(lapply(
  lapply(study, function(x) unique(data[Study==x, Condition])),
  function(y) paste(as.character(y), collapse=", ")
))
Age_dat <- data[,.(Age = round(sum(Population*Age)/sum(Population), 2),
                   SD.Age = round(sqrt(sum(SD.Age^2*(Population-1)))/(sum(Population-1) - .N),2 )
), by=Study]

Age <- apply(Age_dat[,.(Age, SD.Age)], 1, function(x) paste(x, collapse=" \u00B1 "))
Gender <- data[,.N, by=.(Study, Gender)][,Gender]

study_summr <- data.table(Study=study, Population=pop,  Age=Age, Gender=Gender, Condition=Cond, Biomarkers=Biomarkers)
write.csv(study_summr, file=paste(path, "study_summary.csv", sep = ''), sep=",")



#all biomarkers
data_overall.rma <- rma(yi_new, vi, data=data[Treatment.type!="control"], method="REML")
dat_mod.rma <- rma.mv(yi_new, vi, data=data, mods=~Activity.type + Intensity + Duration + PeriodLength, random=~1|Study/Biomarker, method="REML")

#only pro-inflammatory
dat_pi <- data[biomarker_type=="pi"]
dat_pi.ovrma <- rma(yi_new, vi, data=dat_pi, method="REML")
dat_pi.rma <- rma.mv(yi_new, vi, data=dat_pi, mods=~Activity.type + Intensity + Duration + PeriodLength, random=~1|Study/Biomarker, method="REML")

#only anti-inflammatory
dat_ai <- data[biomarker_type=="ai"]
dat_ai.ovrma <- rma(yi_new, vi, data=dat_ai, method="REML")
dat_ai.rma <- rma.mv(yi_new, vi, data=dat_ai, mods=~Activity.type + Intensity + Duration + PeriodLength, random=~1|Study/Biomarker, method="REML")

#based on TNF-alpha (pro-inflammatory)
dat_tnf <- data[Biomarker=="TNF-alpha"]
dat_tnf.rma <- rma.mv(yi_new, vi, data=dat_tnf, mods=~Activity.type + Intensity + Duration + PeriodLength, random=~1|Study/Biomarker, method="REML")

#based on IL-10 (anti-inflammatory)
dat_il10 <- data[Biomarker=="IL-10"]
dat_il10.rma <- rma.mv(yi_new, vi, data=dat_il10, mods=~Activity.type + Intensity + Duration + PeriodLength, random=~1|Study/Biomarker, method="REML")

#Based on IL-6 (anti-inflammatory)
dat_il6 <- data[Biomarker == "IL-6"]
dat_il6.rma <- rma.mv(yi_new, vi, data=dat_il6, mods=~Activity.type + Intensity + Duration + PeriodLength, random=~1|Study/Biomarker, method="REML")

mean.rma <- function(yi, vi){
est <- coef(rma(yi, vi, method="FE"))
return(est)
}

ci.lb.rma <- function(yi, vi){
est <- summary(rma(yi, vi,  method="FE"))$ci.lb
return(est)
}

ci.ub.rma <- function(yi, vi){
est <- summary(rma(yi, vi, method="FE"))$ci.ub
return(est)
}

var.rma <-  function(yi, vi){
est <- diag(vcov(rma(yi, vi, method="FE")))
return(est)
}

dat_study <- data[Treatment.type!="control",
.(estimate = mean.rma(yi_new, vi), variance = var.rma(yi_new, vi),
ci.lb = ci.lb.rma(yi_new, vi),
ci.ub = ci.ub.rma(yi_new, vi)), by=Study
][,wi:=1/sqrt(variance)
][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi))]

data[Treatment.type!="control",.(variance=var.rma(yi_new,vi))]

var.rma(data$yi_new, data$vi)
dat_overall <- data[Treatment.type!="control", 
.(Study = "overall",
estimate = mean.rma(yi_new, vi),
variance = var.rma(yi_new, vi),
ci.lb = ci.lb.rma(yi_new, vi),
ci.ub = ci.ub.rma(yi_new, vi),
wi = 0,
size = 5)]
dat_study <- rbind(dat_study, dat_overall)


ggplot(dat_study, aes(x=Study, y=estimate, color=Study)) +
geom_point(stat='identity', shape=15, aes(size=size)) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width= 0.2, size=1) +
theme() +
coord_flip() +
scale_size_continuous(guide=FALSE) +
scale_color_discrete(guide=FALSE) +
geom_hline(yintercept=0, color="gray")  


tabletext <-cbind(c("","Study",dat_study[Study!="overall", Study],NA,"Summary"),
c("","SMD",format(dat_study[Study!="overall", estimate], digits=2),NA,format(dat_study[Study=="overall",estimate],digits=2)),
c("", "95% CI", paste("(",format(dat_study[Study!="overall", ci.lb], digits=2), ",", format(dat_study[Study!="overall", ci.ub], digits=2), ")", sep=""), NA, paste("(",format(dat_study[Study=="overall", ci.lb], digits=2), ",", format(dat_study[Study=="overall", ci.ub], digits=2), ")", sep="" )  )
)

m <- c(NA,NA, dat_study[Study!="overall", estimate], NA, dat_study[Study=="overall", estimate])
l <- c(NA,NA, dat_study[Study!="overall", ci.lb], NA, dat_study[Study=="overall", ci.lb])
u <- c(NA,NA, dat_study[Study!="overall", ci.ub], NA, dat_study[Study=="overall", ci.ub])

forestplot(tabletext, m,l,u, zero=0,
is.summary=c(T, T, rep(F,21), TRUE),
col = meta.colors(box="royalblue", line="darkblue", summary="royalblue"))





##Effects of exercise training parameters on anti-inflammation   


#testing different models
rma.glmulti <- function(formula, data, ...)
rma.mv(formula, vi, data=data, method="REML",...)

res <- glmulti(yi_new ~ Activity.type + Intensity + Duration + PeriodLength, random =~1|Study, data=data, level=2, fitfunction=rma.glmulti, crit="aicc", confsetsize=1000)
summary(res@objects[[1]])
final.mod <- res@objects[[1]]


### Effect of Activity type on anti-inflammation
activity.mod <- rma(yi_new, vi, mods=~Activity.type, data=data)               
par(mar = c(4, 4, 1, 2))
estimate <- coef(activity.mod)[2:4]
variance <- diag(vcov(activity.mod)[2:4,2:4])
labels <- c("Low", "Moderate", "High")
labels <- c("Aerobic", "Resistance", "Aerobic-Resistance")
forest(estimates, variances, slab = labels, psize = 1, efac = 0)
# addpoly(estimates, variances, rows = 4:1, col = "white", annotate = F, efac = 1.25)
grid.text("Activity type", 0.12, 0.78, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.78, gp = gpar(cex = 1))
grid.text("Anti-inflammatory effect across Activity Types" , 0.5, 0.85, gp = gpar(cex = 1.25))

activity.dat <- data.table(Activity.type=labels, estimate = estimate, vi = variance, ci.lb=summary(activity.mod)$ci.lb[2:4], ci.ub = summary(activity.mod)$ci.ub[2:4]
)[,wi:=1/sqrt(vi)][,size:=2 +3*(wi-min(wi))/(max(wi)-min(wi))]

ggplot(activity.dat, aes(x=Activity.type, y=estimate, color=Activity.type)) +
geom_point(size=5,stat='identity', shape=15) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width= 0.2, size=1) +
theme() +
scale_y_continuous(lim=c(-1, 1), breaks=seq(-1,1, by=0.5)) +
coord_flip() +
scale_size_continuous(guide=FALSE) +
scale_color_discrete(guide=FALSE) +
geom_hline(yintercept=0, color="gray") +
labs(y = "Anti-inflammatory effect size", x="Activity type", title="anti-inflammatory effect of exercise with activity type") +
theme(axis.text.y=element_text(face="bold", size=12), plot.margin=unit(c(0.1,1,0.1,0.1), "in")) +
geom_text(aes(label = round(ci.lb,2), y=ci.lb), vjust = -1.5, size=3.5) +
geom_text(aes(label = round(ci.ub,2), y=ci.ub), vjust=-1.5, size=3.5)                      

###Effect of exercise duration on anti-inflammation
duration.mod <- rma(yi_new, vi, mods=~Duration-1, data=data)
par(mar = c(4, 4, 1, 2))
estimate <- coef(duration.mod)[2:4]
variance <- diag(vcov(duration.mod)[2:4,2:4])
labels <- c("Low", "Moderate", "High")
forest(estimates, variances, slab = labels, psize = 1, efac = 0)
# addpoly(estimates, variances, rows = 4:1, col = "white", annotate = F, efac = 1.25)
grid.text("Subgroup", 0.12, 0.78, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.78, gp = gpar(cex = 1))
grid.text("Anti-inflammatory effects across Exercise Duration Levels" , 0.5, 0.85, gp = gpar(cex = 1.25))

intens.dat <- data.table(Duration=labels, estimate = estimate, vi = variance, ci.lb=summary(duration.mod)$ci.lb[2:4], ci.ub = summary(duration.mod)$ci.ub[2:4]
)[,wi:=1/sqrt(vi)][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi))]

ggplot(intens.dat, aes(x=Duration, y=estimate, color=Duration)) +
geom_point(size=5,stat='identity', shape=15) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width= 0.2, size=1) +
theme() +
scale_y_continuous(lim=c(-1, 1), breaks=seq(-1,1, by=0.5)) +
coord_flip() +
scale_size_continuous(guide=FALSE) +
scale_color_discrete(guide=FALSE) +
geom_hline(yintercept=0, color="gray") +
labs(y = "Anti-inflammatory effect size", title="anti-inflammatory effect of exercise with duration") +
theme(axis.text.y=element_text(face="bold", size=12), plot.margin=unit(c(0.1,1,0.1,0.1), "in")) +
geom_text(aes(label = round(ci.lb,2), y=ci.lb), vjust = -1.5, size=3.5) +
geom_text(aes(label = round(ci.ub,2), y=ci.ub), vjust=-1.5, size=3.5)


###Effect of intensity on anti-inflammation

intens.mod <- rma(yi_new, vi, mods=~Intensity-1, data=data[Activity.type=="aerobic"])

par(mar = c(4, 4, 1, 2))
estimate <- coef(intens.mod)[2:4]
variance <- diag(vcov(final.mod)[2:4,2:4])
labels <- c("Low", "Moderate", "High")
forest(estimates, variances, slab = labels, psize = 1, efac = 0)
# addpoly(estimates, variances, rows = 4:1, col = "white", annotate = F, efac = 1.25)
grid.text("Subgroup", 0.12, 0.78, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.78, gp = gpar(cex = 1))
grid.text("Anti-inflammatory effects across Exercise Intensity Levels" , 0.5, 0.85, gp = gpar(cex = 1.25))

#using ggplot
intens.dat <- data.table(Intensity=labels, estimate = estimate, vi = variance, ci.lb=summary(intens.mod)$ci.lb[2:4], ci.ub = summary(intens.mod)$ci.ub[2:4]
)[,wi:=1/sqrt(vi)][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi))]

ggplot(intens.dat, aes(x=Intensity, y=estimate, color=Intensity)) +
geom_point(size=5,stat='identity', shape=15) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width= 0.2, size=1) +
theme() +
scale_y_continuous(lim=c(-1, 1), breaks=seq(-1,1, by=0.5)) +
coord_flip() +
scale_size_continuous(guide=FALSE) +
scale_color_discrete(guide=FALSE) +
geom_hline(yintercept=0, color="gray") +
labs(y = "Anti-inflammatory effect size", title="anti-inflammatory effect of exercise with intensity") +
theme(axis.text.y=element_text(face="bold", size=12), plot.margin=unit(c(0.1,1,0.1,0.1), "in")) +
geom_text(aes(label = round(ci.lb,2), y=ci.lb), vjust = -1.5, size=3.5) +
geom_text(aes(label = round(ci.ub,2), y=ci.ub), vjust=-1.5, size=3.5)



###Effect of periodicity on anti-inflammation
periodicity.mod <- rma(yi_new, vi, mods=~PeriodLength, data=data)
period_dat <-as.data.table(predict(periodicity.mod, data$PeriodLength)
)[,':='(PeriodLength=data$PeriodLength, vi_actual= data$vi, yi_actual=data$yi_new)
][,wi:=1/sqrt(vi_actual)][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi))]

ggplot(period_dat, aes(x=PeriodLength, y=pred)) +
geom_line(color="blue") +
geom_point(aes(y=yi_actual, size=size), color="skyblue4", shape=1, alpha=0.8) +
scale_y_continuous(lim=c(-1,1)) +
geom_ribbon(aes(ymin=ci.lb, ymax=ci.ub), alpha=0.3) +
labs(x="length of exercise training (weeks)", y="anti-inflammatory effect size", title="anti-inflammatory effect of exercise with periodicity") +
scale_size_continuous(guide=FALSE) 


###Interaction between exercise intensity and period length

#plotting for Intensity-periodLength interaction (based on model) ----
#intesity-periodLength Interaction
# intens.pl_rma <- rma.mv(yi_new ~ PeriodLength:Intensity, V=vi, data=data, random=~1|Study/Biomarker)
intens.pl_rma <- rma.mv(yi_new ~ PeriodLength:Intensity, V=vi, data=data)

#Low-Intensity
mat_low <- as.matrix(data[Intensity=="low",.(PeriodLength)])
val_intens_low <- mat_low %*% c(0,1,0,0)
data_pred_low <- data.table(Intensity = "Low", yi_actual= data[Intensity=="low",yi_new], vi_actual= data[Intensity=="low",vi] ,PeriodLength = c(mat_low), as.data.frame(predict(intens.pl_rma, val_intens_low)) )

#Moderate-Intensity
mat_mid <- as.matrix(data[Intensity=="moderate",.(PeriodLength)])
val_intens_mid <- mat_mid %*% c(0,0,1,0)
data_pred_mid <- data.table(Intensity = "Moderate", yi_actual =data[Intensity=="moderate",yi_new], vi_actual= data[Intensity=="moderate",vi], PeriodLength = c(mat_mid), as.data.frame(predict(intens.pl_rma, val_intens_mid)) )

#High Intensity
mat_high <- as.matrix(data[Intensity=="high",.(PeriodLength)])
val_intens_high <- mat_high %*% c(0,0,0,1)
data_pred_high <- data.table(Intensity = "High", yi_actual =data[Intensity=="high",yi_new], vi_actual= data[Intensity=="high",vi], PeriodLength = c(mat_high), as.data.frame(predict(intens.pl_rma, val_intens_high)) )

data_intens <- rbind(data_pred_low, data_pred_mid, data_pred_high)[,wi:=1/sqrt(vi_actual)
][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi)), by=Intensity]


png(filename = paste(path,"graphs/intens_periodLength.png", sep=""), width=754, height=545)
ggplot(data_intens, aes(x=PeriodLength, y=pred)) +
geom_line(aes(color=Intensity), size=1) +
geom_point(aes(y=yi_actual, size=size),  alpha=0.2, fill="white", color="black") +
labs(y ="anti-inflammatory effect size", x="Length of Exercise training period (weeks)", title="Interaction of exercise intensity and period length")+
scale_colour_brewer(palette ="Dark2") +coord_cartesian(ylim=c(-2,2)) +
scale_y_continuous(breaks=seq(-2,2, by=0.5)) +
theme( legend.title=element_text(face="bold"), axis.title=element_text(face="bold")) +
geom_ribbon(aes(ymin=ci.lb, ymax=ci.ub), alpha=0.2) +
scale_size_continuous(guide=FALSE) +
facet_grid(.~Intensity)
dev.off()


#Plotting for Intensity-periodlength interaction (loess)---
ggplot(data, aes(x=PeriodLength, y= yi_new)) +
stat_smooth(method="loess", se=FALSE) +
geom_point(size=2, alpha=0.4, color="skyblue4")+
labs(y="anti-inflammatory effect of exercise", x="Length of exercise training period (weeks)") +
theme(legend.title=element_text(face="bold")) +
coord_cartesian(ylim=c(-2.5,2.5)) +
facet_wrap(~Intensity)


### Interaction effect of Duration and Period Length

#plotting Duration-periodLength interaction ----
dur_periodlength.rma <- rma.mv(yi_new ~ Duration:PeriodLength-1, data=data, V=vi)

#Low Duration
mat_low <- as.matrix(data[Duration=="low",.(PeriodLength)])
val_dur_low <- mat_low %*% c(0,1,0,0)
dur.pred_low <- data.table(Duration = "Low", yi_actual =data[Duration=="low",yi_new], vi_actual=data[Duration=="low",vi], PeriodLength = c(mat_low), as.data.frame(predict(dur_periodlength.rma, val_dur_low)) )

#Moderate duration
mat_mid <- as.matrix(data[Duration=="moderate",.(PeriodLength)])
val_dur_mid <- mat_mid %*% c(0,0,1,0)
dur.pred_mid <- data.table(Duration = "Moderate", yi_actual =data[Duration=="moderate",yi_new], vi_actual=data[Duration=="moderate",vi], PeriodLength = c(mat_mid), as.data.frame(predict(dur_periodlength.rma, val_dur_mid)) )

#High Duration
mat_high <- as.matrix(data[Duration=="high",.(PeriodLength)])
val_dur_high <- mat_high %*% c(0,0,1,0)
dur.pred_high <- data.table(Duration = "High", yi_actual =data[Duration=="high",yi_new], vi_actual=data[Duration=="high",vi], PeriodLength = c(mat_high), as.data.frame(predict(dur_periodlength.rma, val_dur_high)) )

data_dur <- rbind(dur.pred_low, dur.pred_mid, dur.pred_high)[,wi:=1/sqrt(vi_actual)
][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi)), by=Duration]

ggplot(data_dur, aes(x=PeriodLength, y=pred)) +
geom_line(size=1, aes(color=Duration)) +
# geom_point() +
geom_point(aes(y=yi_actual, size=size), alpha=0.2)+
labs(y ="anti-inflammatory effect of exercise", x="Length of Exercise training period (weeks)", title="Interaction of exercise duration and period length") +
scale_colour_brewer(palette ="Dark2") +coord_cartesian(ylim=c(-2,2)) +
scale_y_continuous(breaks=seq(-2,2, by=0.5)) +
theme(legend.title=element_text(face="bold"), title=element_text(face="bold"))  +
facet_grid(.~Duration) +
geom_ribbon(aes(ymin=ci.lb, ymax=ci.ub), alpha=0.2) +
scale_size_continuous(guide=FALSE) 

###Interaction effect of Intensity and Duration
#plotting intensity-duration interaction ----
# intens_dur.rma <- rma.mv(yi_new, vi, mods= ~Duration:Intensity, random=~1|Study/Biomarker,data=data)
rma(yi_new, vi, mods=~Duration:Intensity-1, data=data)
intens_dur.dat <- data.table(expand.grid(Duration=c( "Low", "Moderate", "High"), Intensity=c("Low", "Moderate", "High"))[-c(9),], estimate=coef(intens_dur.rma)[3:10], ci.lb =summary(intens_dur.rma)$ci.lb[3:10], ci.ub =summary(intens_dur.rma)$ci.ub[3:10])

ggplot(intens_dur.dat, aes(x=Duration, y=estimate)) +
geom_line(aes(group=Intensity, color=Intensity), size=1) +
geom_point(aes(group=Intensity,color=Intensity ), size=4, alpha=0.4) +
scale_colour_brewer(palette ="Dark2") +
labs(y="anti-inflammatory effect of exercise") +
theme(legend.title=element_text(face="bold")) +
coord_cartesian(ylim=c(-3,3)) +
scale_y_continuous(breaks=seq(-3, 3, by=0.5)) +
theme(axis.title=element_text(face="bold")) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub, color=Intensity), width=0.1, size=1)



###Effects of pre-existing conditions on the anti-inflammatory effect of exercise
data[Condition=="chronic kidney disease", Condition:="CKD"]
cond.rma <- rma.mv(yi_new ~-1 + Condition, random=~1|Study/Biomarker,data=data[Treatment.type!="control"], V=vi)
estimate <- coef(cond.rma)
variance <- diag(vcov(cond.rma))
labels <- gsub("Condition", "",names(coef(cond.rma)))
forest(estimate, variance, slab=labels, psize=1, efac=0)
grid.text("Condition", 0.08, 0.85, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.85, gp = gpar(cex = 1))
grid.text("Anti-inflammatory effects of exercise with various health conditions" , 0.5, 0.9, gp = gpar(cex = 1.25))



#using ggplot
cond.dat <- data.table(Condition=labels, estimate = estimate, vi = variance, ci.lb=summary(cond.rma)$ci.lb, ci.ub = summary(cond.rma)$ci.ub
)[,wi:=1/sqrt(vi)][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi))]

png(filename = paste(path,"graphs/healthcond.png", sep=""))
ggplot(cond.dat, aes(x=Condition, y=estimate, color=Condition)) +
geom_point(size=5,stat='identity', shape=15) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width= 0.2) +
theme() +
scale_y_continuous(lim=c(-5, 5), breaks=seq(-5,5, by=1)) +
coord_flip() +
scale_size_continuous(guide=FALSE) +
scale_color_discrete(guide=FALSE) +
geom_hline(yintercept=0, color="gray") +
labs(y = "Anti-inflammatory effect size", title="anti-inflammatory effect of exercise on various health conditions") +
theme(axis.text.y=element_text(face="bold")) +
geom_text(aes(label = round(ci.lb,2), y=ci.lb), vjust = -1, size=3) +
geom_text(aes(label = round(ci.ub,2), y=ci.ub), vjust=-1, size=3)
dev.off()

###effect of exercise with condition type (healthy or sick)
data[,Condition_type:=ifelse(Condition=="healthy" & Treatment.type!="control", "healthy", "sick")]

cond_type_class <- function(cnd, trt){
outcome <- if(cnd == "healthy" & trt !="control") "healthy" else
if(cnd =="healthy" & trt == "control") "healthy inactive" else
if(cnd != "healthy" & trt != "control") "sick" else
if(cnd != "healthy" & trt == "control") "sick inactive"
return(outcome)
}

data[,Condition_type:=mapply(function(x,y) cond_type_class(x, y), Condition, Treatment.type)]

cond.type_rma <- rma.mv(yi_new ~-1 + Condition_type, random=~1|Study/Biomarker,data=data, V=vi)
estimate <- coef(cond.type_rma)
variance <- diag(vcov(cond.type_rma))
labels <- gsub("Condition_type", "",names(coef(cond.type_rma)))
forest(estimate, variance, slab=labels, psize=1, efac=0)
grid.text("Condition type", 0.1, 0.5, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.5, gp = gpar(cex = 1))
grid.text("anti-inflammatory effect of exercise on healthy or sick individuals" , 0.5, 0.6, gp = gpar(cex = 1.25))


#using ggplot
cond_type.dat <- data.table(Condition=labels, estimate = estimate, vi = variance, ci.lb=summary(cond.type_rma)$ci.lb, ci.ub = summary(cond.type_rma)$ci.ub
)[,wi:=1/sqrt(vi)][,size:=0.5 +3*(wi-min(wi))/(max(wi)-min(wi))]

png(filename = paste(path,"graphs/healthcond_type.png", sep=""))
ggplot(cond_type.dat, aes(x=Condition, y=estimate, color=Condition)) +
geom_point(size=4,stat='identity', shape=15) +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width= 0.2, size=1) +
scale_y_continuous(lim=c(-1, 1), breaks=seq(-1,1, by=0.5)) +
coord_flip() +
scale_size_continuous(guide=FALSE) +
scale_color_discrete(guide=FALSE) +
geom_hline(yintercept=0, color="gray") +
labs(y = "Anti-inflammatory effect size", title="anti-inflammatory effect of exercise on healthy and sick individuals") +
theme(axis.text.y=element_text(size=12), plot.margin=unit(c(0.1,0.5,0.1,0.2), "in")) +
geom_text(aes(label = round(ci.lb,2), y=ci.lb), vjust = -2, size=4) +
geom_text(aes(label = round(ci.ub,2), y=ci.ub), vjust=-2, size=4)
dev.off()


#Intensity-Duration interaction plots using raw data
mean.rma <- function(yi, vi){
est <- coef(rma(yi, vi, method="FE"))
return(est)
}

ci.lb.rma <- function(yi, vi){
est <- summary(rma(yi, vi,  method="FE"))$ci.lb
return(est)
}

ci.ub.rma <- function(yi, vi){
est <- summary(rma(yi, vi, method="FE"))$ci.ub
return(est)
}



mean.meta <- function(y,v){

w <- 1/v
M <- sum(w%*%y)/sum(w)
return(M)
}



intens_dur <- data[Biomarker!="IL-6",.(estimate=mean.rma(yi_new, vi),
ci.lb = ci.lb.rma(yi_new, vi),
ci.ub = ci.ub.rma(yi_new, vi),
study_count =.N
), by=.(Intensity, Duration)]

# intens_dur_meta <- data[,.(estimate=mean.meta(yi_new, vi)), by=.(Intensity,Duration)]

ggplot(intens_dur, aes(x=Duration, y=estimate, color=Intensity)) +
geom_point(size=5, alpha=0.4) +
geom_line(aes(group=Intensity, color=Intensity), size=1) +
# scale_y_continuous(limits=c(-0.5,0.5), breaks=seq(-0.5, 0.5, by=0.25)) +
geom_hline(yintercept = 0, color="grey33", linetype=2) +
labs(y="Anti-inflammatory effect of exercise") +
geom_errorbar(aes(ymin=ci.lb, ymax=ci.ub), width=0.2)


#Intensity to period length plots (means)
intens_pl_raw <- data[,.(estimate=mean.rma(yi_new, vi),
ci.lb = ci.lb.rma(yi_new, vi),
ci.ub = ci.ub.rma(yi_new, vi)
), by=.(Intensity, PeriodLength)]

ggplot(intens_pl_raw, aes(x=PeriodLength, y=estimate, color=Intensity)) +
geom_point(size=3.5, shape=1, stroke=1.5) +
geom_line() +
labs(y="Anti-inflammatory effect of exercise", x="period length of exercise training (weeks)")

#Duration to period length plots (means)
dur_pl_raw <- data[,.(estimate=mean.rma(yi_new, vi),
ci.lb = ci.lb.rma(yi_new, vi),
ci.ub = ci.ub.rma(yi_new, vi)
), by=.(Duration, PeriodLength)]

ggplot(dur_pl_raw, aes(x=PeriodLength, y=estimate, color=Duration)) +
geom_point(size=3.5, shape=1, stroke=1.3) +
geom_line() +
labs(y="Anti-inflammatory effect of exercise", x="period length of exercise training (weeks)")

#Intensity-duration-activity plots with relation to condition
intens_dur_act <- data[,.(estimate=mean.rma(yi_new, vi),
ci.lb = ci.lb.rma(yi_new, vi),
ci.ub = ci.ub.rma(yi_new, vi)
), by=.(Duration, Intensity, Activity.type)]

ggplot(intens_dur_act, aes(x=Duration, y=estimate, color=Intensity)) +
geom_point(size=5, alpha=0.4) +
geom_line(aes(group=Intensity, color=Intensity), size=1) +
scale_y_continuous(limits=c(-1.5,1), breaks=seq(-1.5, 1, by=0.5)) +
geom_hline(yintercept = 0, color="grey33", linetype=2) +
labs(y="Anti-inflammatory effect of exercise") +
facet_grid(~Activity.type)

#modelling with additional filters (nominal variable coding)
#for healthy
data_new_hlth <- data[Biomarker!="IL-6" & Condition=="healthy"]
data_new_hlth[,.N, by=.(Intensity, Duration, Activity.type)]

data_new_hlth.mod <- rma.mv(yi_new, vi, mods=~Activity.type + Intensity + Duration + PeriodLength + Intensity:Duration + Intensity:PeriodLength + Duration:PeriodLength, data=data_new_hlth, random=~1|Study, method="REML")
summary(data_new_hlth.mod)
anova(data_new_hlth.mod, btt=2:3) #anova for activity type
anova(data_new_hlth.mod, btt=4:5) #anova for intensity
anova(data_new_hlth.mod, btt=6:7) #anova for Duration
anova(data_new_hlth.mod, btt=8) #anova for periodicity
anova(data_new_hlth.mod, btt=9) #anova for intensity and duration
anova(data_new_hlth.mod, btt=10:11) #anova for Intensity period length
anova(data_new_hlth.mod, btt=12) #anova for duration-period length

#for non-healthy
data_new_nh <- data[Biomarker!="IL-6" & Condition !="healthy"]
data_new_nh.mod <- rma.mv(yi_new, vi, mods=~Activity.type + Intensity + Duration + PeriodLength + Intensity:Duration + Intensity:PeriodLength + Duration:PeriodLength, data=data_new_nh, random=~1|Study, method="REML")
summary(data_new_nh.mod)

anova(data_new_nh.mod, btt=2:4) #anova for activity type
anova(data_new_nh.mod, btt=5:7) #anova for intensity
anova(data_new_nh.mod, btt=8:9) #anova for Duration
anova(data_new_nh.mod, btt=10) #anova for periodicity
anova(data_new_nh.mod, btt=11:13) #anova for intensity and duration
anova(data_new_nh.mod, btt=14:16) #anova for Intensity period length
anova(data_new_nh.mod, btt=17:18) #anova for duration-period length




#modelling with additional filters (polynomial coding)
#for healthy
data_poly <- data[,':='(Intensity=ordered(Intensity, levels= c("control", "low", "moderate", "high")),
Duration=ordered(Duration, levels= c("control", "low", "moderate", "high")))]

dat_newhlth_poly <- data[Biomarker!="IL-6" & Condition=="healthy"]
hlth_poly.rma <- rma.mv(yi_new, vi, mods=~Activity.type + Intensity + Duration + PeriodLength + Intensity:Duration + Intensity:PeriodLength + Duration:PeriodLength, data=dat_newhlth_poly, random=~1|Study, method="REML")
summary(hlth_poly.rma)
anova(hlth_poly.rma, btt=2:3) #anova for activity type
anova(hlth_poly.rma, btt=4:5) #anova for intensity
anova(hlth_poly.rma, btt=6:7) #anova for Duration
anova(hlth_poly.rma, btt=8) #anova for periodicity
anova(hlth_poly.rma, btt=9) #anova for intensity and duration
anova(hlth_poly.rma, btt=10:12) #anova for Intensity period length
anova(hlth_poly.rma, btt=13) #anova for duration-period length

#for non-healthy
data_newnh_poly <- data[Biomarker!="IL-6" & Condition !="healthy"]
nh_poly.rma <- rma.mv(yi_new, vi, mods=~Activity.type + Intensity + Duration + PeriodLength + Intensity:Duration + Intensity:PeriodLength + Duration:PeriodLength, data=data_newnh_poly, random=~1|Study, method="REML")
summary(nh_poly.rma)

anova(nh_poly.rma, btt=2:4) #anova for activity type
anova(nh_poly.rma, btt=5:7) #anova for intensity
anova(nh_poly.rma, btt=8:9) #anova for Duration
anova(nh_poly.rma, btt=10) #anova for periodicity
anova(nh_poly.rma, btt=11:13) #anova for intensity and duration
anova(nh_poly.rma, btt=14:16) #anova for Intensity period length
anova(nh_poly.rma, btt=17:18) #anova for duration-period length



#plotting with additional filters (healthy, no IL-6, intensity-duration)
mean.rma_re <- function(yi, vi){
# data <- data.frame(yi=yi, vi=vi, Study=Study)
est <- coef(rma.mv(yi, vi, method="FE"))
return(est)
}

ci.lb.rma_re <- function(yi, vi){
# data <- data.frame(yi=yi, vi=vi, Study=Study)
est <- summary(rma.mv(yi, vi,  method="FE"))$ci.lb
return(est)
}

ci.ub.rma_re <- function(yi, vi){
# data <- data.frame(yi=yi, vi=vi, Study=Study)
est <- summary(rma.mv(yi, vi, method="FE"))$ci.ub
return(est)
}


intens_dur_hlth <- data_new_hlth[,.(estimate=mean.rma_re(yi_new, vi),
ci.lb = ci.lb.rma_re(yi_new, vi),
ci.ub = ci.ub.rma_re(yi_new, vi),
study_count =.N
), by=.(Intensity, Duration)]



ggplot(intens_dur_hlth, aes(x=Duration, y=estimate, color=Intensity)) +
geom_point(size=5, alpha=0.4) +
geom_line(aes(group=Intensity, color=Intensity), size=1) +
# scale_y_continuous(limits=c(-0.5,0.5), breaks=seq(-0.5, 0.5, by=0.25)) +
geom_hline(yintercept = 0, color="grey33", linetype=2) +
labs(y="Anti-inflammatory effect of exercise") +
geom_errorbar(aes(color=Intensity, ymin=ci.lb, ymax=ci.ub), width=0.2)  


#plotting with additional filters (non-healthy, no IL-6, intensity-duration)
intens_dur_nh <- data_new_nh[,.(estimate=mean.rma_re(yi_new, vi),
ci.lb = ci.lb.rma_re(yi_new, vi),
ci.ub = ci.ub.rma_re(yi_new, vi),
study_count =.N
), by=.(Intensity, Duration)]

data_new_nh[Activity.type=="control"]

ggplot(intens_dur_nh, aes(x=Duration, y=estimate, color=Intensity)) +
geom_point(size=5, alpha=0.4) +
geom_line(aes(group=Intensity, color=Intensity), size=1) +
# scale_y_continuous(limits=c(-0.5,0.5), breaks=seq(-0.5, 0.5, by=0.25)) +
geom_hline(yintercept = 0, color="grey33", linetype=2) +
labs(y="Anti-inflammatory effect of exercise") +
geom_errorbar(aes(color=Intensity, ymin=ci.lb, ymax=ci.ub), width=0.2)


fgrph_act <- function(data,group, eval=FALSE, echo=FALSE){
aerobic_resistance <- data[Activity.type=="aerobic-resistance"]
aerobic <- data[Activity.type=="aerobic"]
resistance <- data[Activity.type=="resistance"]
sedentary <- data[Activity.type=="control"]

Forest_A.Res <- result.md(aerobic_resistance, "REML")
Forest_aerobic<- result.md(aerobic, "REML")
Forest_res <- result.md(resistance, "REML")
Forest_sed <- result.md(sedentary, "REML")


par(mar = c(4, 4, 1, 2))
estimates <- c(coef(Forest_A.Res), coef(Forest_aerobic), coef(Forest_res), coef(Forest_sed), coef(res_1))
variances <- c(vcov(Forest_A.Res), vcov(Forest_aerobic), vcov(Forest_res), vcov(Forest_sed), vcov(res_1))
labels <- c("Aerobic-resistance", "aerobic", "resistance", "sedentary", "Over-All")
forest(estimates, variances, slab = labels, psize = 1, efac = 0)
addpoly(estimates, variances, rows = 5:1, col = "white", annotate = F, efac = 1.25)
grid.text("Subgroup", 0.12, 0.78, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.78, gp = gpar(cex = 1))
grid.text(paste("Effect Size Across  Activity type",paste("(",group,")", sep="")) , 0.5, 0.85, gp = gpar(cex = 1.25))

}

png(filename = paste(path,"graphs/act_type_allbiomarkers.png", sep=""))
fgrph_act(data, "all biomarkers")
dev.off()

png(filename = paste(path,"graphs/act_type_ai.png", sep=""))
fgrph_act(dat_ai, "anti-inflammatory")
dev.off()

png(filename = paste(path,"graphs/act_type_pi.png", sep=""))
fgrph_act(dat_pi, "pro_inflammatory")
dev.off()

png(filename = paste(path,"graphs/act_type_tnfalpha.png", sep=""))
fgrph_act(dat_tnf, "TNF-alpha")
dev.off()



fgrph_intens <- function(data,group){

Low <- data[Intensity=="low"]
Mid <- data[Intensity=="moderate"]
High <- data[Intensity=="high"]


Forest_Low <- result.md(Low, "REML")
Forest_Mid <- result.md(Mid, "REML")
Forest_High <- result.md(High, "REML")

par(mar=c(4, 4, 1, 2))
estimates <- c( coef(Forest_Low), coef(Forest_Mid), coef(Forest_High), coef(res_1))
variances <- c( vcov(Forest_Low), vcov(Forest_Mid), vcov(Forest_High), vcov(res_1))
labels <- c("Low", "Moderate", "High", "Over-All")
forest(estimates, variances, slab = labels, psize = 1, efac = 0)
addpoly(estimates, variances, rows=4:1, col="white", annotate=FALSE, efac = 1.25)
grid.text("Subgroup", 0.12, 0.78, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.78, gp = gpar(cex = 1))
grid.text(paste("Effect Size Across Intensity",paste("(",group,")", sep="")) , 0.5, 0.85, gp = gpar(cex = 1.25))
}

png(filename = paste(path,"graphs/intens_type_allbiomarkers.png", sep=""))
fgrph_intens(data, "all biomarkers")
dev.off()

png(filename = paste(path,"graphs/intens_type_ai.png", sep=""))
fgrph_intens(dat_ai, "anti-inflammatory")
dev.off()

png(filename = paste(path,"graphs/intens_type_pi.png", sep=""))
fgrph_intens(dat_pi, "pro_inflammatory")
dev.off()

png(filename = paste(path,"graphs/intens_type_tnfalpha.png", sep=""))
fgrph_intens(dat_tnf, "TNF-alpha")
dev.off()

png(filename = paste(path,"graphs/intens_type_il10.png", sep=""))
fgrph_intens(dat_il10, "IL-10")
dev.off()

fgrph_dur <- function(data,group){
Low <- data[Duration=="low"]
Mid <- data[Duration=="moderate"]
High <- data[Duration=="high"]


Forest_Low <- result.md(Low, "REML")
Forest_Mid <- result.md(Mid, "REML")
Forest_High <- result.md(High, "REML")

par(mar=c(4, 4, 1, 2))
estimates <- c( coef(Forest_Low), coef(Forest_Mid), coef(Forest_High), coef(res_1))
variances <- c( vcov(Forest_Low), vcov(Forest_Mid), vcov(Forest_High), vcov(res_1))
labels <- c("Low", "Moderate", "High", "Over-All")
forest(estimates, variances, slab = labels, psize = 1, efac = 0)
addpoly(estimates, variances, rows=4:1, col="white", annotate=FALSE, efac = 1.25)
grid.text("Subgroup", 0.12, 0.78, gp = gpar(cex = 1))
grid.text("SMD[95%CI]", 0.85, 0.78, gp = gpar(cex = 1))
grid.text("Effect size across exercise duration", 0.5, 0.85, gp = gpar(cex = 1.25))
}

