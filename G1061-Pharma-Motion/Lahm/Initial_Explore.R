# Set up the data with the 20% sample

setwd("/work/mlahm/GP1061 PharmaMotion")

set.seed(123)

# Initial work on GP1061

data.member <- read.odbc("devsql10", dbQuery = "SELECT *
                  FROM pdb_PharmaMotion.dbo.Member_v2", as.is = TRUE)
data.member <- data.member %>% mutate_each(funs(as.numeric), Mbr_EnrolledMotionYM, PolicyEffYM, PolicyEndYM,
                                           RAF_2014, RAF_2015, RAF_2016)
data.member <- data.member[data.member$Age > 17,]

data.month <- read.odbc("devsql10", dbQuery = "SELECT *
                        FROM pdb_PharmaMotion.dbo.MemberSummary_v2", as.is = TRUE)
data.month <- data.month %>% mutate_each(funs(as.factor), Enrl_Motion) %>%
  mutate_each(funs(as.numeric), YearMo, RX_Allow, Total_Allow)
data.month[data.month$RX_Allow < 0, "RX_Allow"] <- 0
data.month <- data.month[data.month$Enrl_Plan == 1,]

# Create a time variable for month from 0 to 35
data.month$Time <- 0
data.month[data.month$YearMo < 201500 & data.month$YearMo > 201400, "Time"] <- 
  data.month[data.month$YearMo < 201500 & data.month$YearMo > 201400, "YearMo"] - 201401
data.month[data.month$YearMo < 201600 & data.month$YearMo > 201500, "Time"] <- 
  data.month[data.month$YearMo < 201600 & data.month$YearMo > 201500, "YearMo"] - 201501 + 12
data.month[data.month$YearMo < 201700 & data.month$YearMo > 201600, "Time"] <- 
  data.month[data.month$YearMo < 201700 & data.month$YearMo > 201600, "YearMo"] - 201601 + 24

data.month <- merge(data.month, data.member, by.x = "MemberID", by.y = "MemberID", all.x = TRUE)

data.month$Antihyperglycemics_Ind <- 0
data.month[data.month$Antihyperglycemics > 0, "Antihyperglycemics_Ind"] <- 1
data.month$Cardiovascular_Ind <- 0
data.month[data.month$Cardiovascular > 0, "Cardiovascular_Ind"] <- 1
data.month$ThyroidPreps_Ind <- 0
data.month[data.month$ThyroidPreps > 0, "ThyroidPreps_Ind"] <- 1
data.month$CNSDrugs_Ind <- 0
data.month[data.month$CNSDrugs > 0, "CNSDrugs_Ind"] <- 1
data.month$CardiacDrugs_Ind <- 0
data.month[data.month$CardiacDrugs > 0, "CardiacDrugs_Ind"] <- 1
data.month$Diuretics_Ind <- 0
data.month[data.month$Diuretics > 0, "Diuretics_Ind"] <- 1

data.month$RAF <- 0
data.month[data.month$YearMo > 201400 & data.month$YearMo < 201500, "RAF"] <- 
 data.month[data.month$YearMo > 201400 & data.month$YearMo < 201500, "RAF_2014"]
data.month[data.month$YearMo > 201500 & data.month$YearMo < 201600, "RAF"] <- 
 data.month[data.month$YearMo > 201500 & data.month$YearMo < 201600, "RAF_2015"]
data.month[data.month$YearMo > 201600 & data.month$YearMo < 201700, "RAF"] <- 
 data.month[data.month$YearMo > 201600 & data.month$YearMo < 201700, "RAF_2016"]

# Do some plots of the RAF and drug use over time

mean.Antibiotics <- as.data.frame(data.month[data.month$Enrl_Plan == 1,] %>% group_by(Time) %>%
                                    summarise(total.count = n(),
                                              Antihyperglycemics = mean(Antihyperglycemics),
                                              Cardiovascular = mean(Cardiovascular),
                                              ThyroidPreps = mean(ThyroidPreps),
                                              CNSDrugs = mean(CNSDrugs),
                                              CardiacDrugs = mean(CardiacDrugs),
                                              Diuretics = mean(Diuretics),
                                              Prop_Antihyperglycemics = mean(Antihyperglycemics_Ind),
                                              Prop_Cardiovascular = mean(Cardiovascular_Ind),
                                              Prop_ThyroidPreps = mean(ThyroidPreps_Ind),
                                              Prop_CNSDrugs = mean(CNSDrugs_Ind),
                                              Prop_CardiacDrugs = mean(CardiacDrugs_Ind),
                                              Prop_Diuretics = mean(Diuretics_Ind),
                                              Age_Mean = mean(Age, na.rm = TRUE),
                                              RAF_Mean = mean(RAF, na.rm = TRUE),
                                              Spend_RX = mean(RX_Allow),
                                              Spend_Total = mean(Total_Allow)))

plot <- ggplot(aes(x = Time), data = data.month) + geom_bar(fill = "#4f81bd") +
  ggtitle("Total Member Population")
plot <- plot + 
  xlab("January 2015 through December 2016") + ylab('Count of Members')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

plot <- ggplot(aes(x = Time, y = Age_Mean), 
               data = mean.Antibiotics) + geom_line()
plot

plot <- ggplot(aes(x = Time, y = RAF_Mean), 
               data = mean.Antibiotics[mean.Antibiotics$Time > 12,]) + geom_line(colour = "#4f81bd") +
  ggtitle("Mean RAF by Month")
plot <- plot + 
  xlab("January 2015 through December 2016") + ylab('Mean RAF')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

plot <- ggplot(aes(x = Time, y = Spend_RX), 
               data = mean.Antibiotics[mean.Antibiotics$Time > 12,]) + geom_line(colour = "#4f81bd") +
  ggtitle("RX Spend by Month")
plot <- plot + 
  xlab("January 2015 through December 2016") + ylab('Mean RX Spend')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

plot <- ggplot(aes(x = Time, y = Prop_Antihyperglycemics), 
               data = mean.Antibiotics) + geom_line()
plot

plot <- ggplot(aes(x = Time, y = Prop_Cardiovascular), 
               data = mean.Antibiotics) + geom_line()
plot

plot <- ggplot(aes(x = Time, y = Prop_ThyroidPreps), 
               data = mean.Antibiotics) + geom_line()
plot

plot <- ggplot(aes(x = Time, y = Prop_CNSDrugs), 
               data = mean.Antibiotics) + geom_line()
plot

plot <- ggplot(aes(x = Time, y = Prop_CardiacDrugs), 
               data = mean.Antibiotics) + geom_line()
plot

plot <- ggplot(aes(x = Time, y = Prop_Diuretics), 
               data = mean.Antibiotics) + geom_line()
plot

test_data_long <- melt(mean.Antibiotics[,c("Time", "Prop_Antihyperglycemics",
                                                  "Prop_Cardiovascular", "Prop_ThyroidPreps",
                                                  "Prop_CNSDrugs", "Prop_CardiacDrugs",
                                                  "Prop_Diuretics")], id = "Time")

plot <- ggplot(data = test_data_long[test_data_long$Time > 12,], 
               aes(x = Time, y = value, colour = variable)) + geom_line() +
  scale_colour_manual(values = c("#4f81bd", "#febe01", "#9bbb59", "#c0504d",
                                 "#8064a2", "#4bacc6")) +
  ggtitle("Monthly Maintenance Drug Useage")
plot <- plot + 
  xlab("January 2015 through December 2016") + ylab('Proportion of Members')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

# Do some plots of the RAF and drug use over months related to when enrolled in motion

table(data.month$YearMo, data.month$EnrlMotion_MonthInd)

mean.Antibiotics.motion <- as.data.frame(data.month[data.month$Enrl_Plan == 1 & !is.na(data.month$EnrlMotion_MonthInd),] %>% 
                                    group_by(EnrlMotion_MonthInd) %>%
                                    summarise(total.count = n(),
                                              Antihyperglycemics = mean(Antihyperglycemics),
                                              Cardiovascular = mean(Cardiovascular),
                                              ThyroidPreps = mean(ThyroidPreps),
                                              CNSDrugs = mean(CNSDrugs),
                                              CardiacDrugs = mean(CardiacDrugs),
                                              Diuretics = mean(Diuretics),
                                              Prop_Antihyperglycemics = mean(Antihyperglycemics_Ind),
                                              Prop_Cardiovascular = mean(Cardiovascular_Ind),
                                              Prop_ThyroidPreps = mean(ThyroidPreps_Ind),
                                              Prop_CNSDrugs = mean(CNSDrugs_Ind),
                                              Prop_CardiacDrugs = mean(CardiacDrugs_Ind),
                                              Prop_Diuretics = mean(Diuretics_Ind),
                                              Age_Mean = mean(Age, na.rm = TRUE),
                                              RAF_Mean = mean(RAF, na.rm = TRUE),
                                              Spend_RX = mean(RX_Allow),
                                              Spend_Total = mean(Total_Allow)))

plot <- ggplot(aes(x = EnrlMotion_MonthInd), data = data.month[!is.na(data.month$EnrlMotion_MonthInd),]) + 
  geom_bar(fill = "#4f81bd") +
  ggtitle("Motion Member Population")
plot <- plot + 
  xlab("Month Relative to Motion") + ylab('Count of Members')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Age_Mean), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + 
geom_line()
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = RAF_Mean), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + 
  geom_line(colour = "#4f81bd")+
ggtitle("Motion Mean RAF by Month")
plot <- plot + 
  xlab("Month Relative to Motion") + ylab('Mean RAF')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Spend_RX), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + 
  geom_line(colour = "#4f81bd")+
  ggtitle("Motion RX Spend by Month")
plot <- plot + 
  xlab("Month Relative to Motion") + ylab('Mean RAF')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Prop_Antihyperglycemics), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + geom_line()
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Prop_Cardiovascular), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + geom_line()
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Prop_ThyroidPreps), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + geom_line()
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Prop_CNSDrugs), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + geom_line()
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Prop_CardiacDrugs), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + geom_line()
plot

plot <- ggplot(aes(x = EnrlMotion_MonthInd, y = Prop_Diuretics), 
               data = mean.Antibiotics.motion[mean.Antibiotics.motion$EnrlMotion_MonthInd > -13 &
                                                mean.Antibiotics.motion$EnrlMotion_MonthInd < 18,]) + geom_line()
plot

test_data_long <- melt(mean.Antibiotics.motion[,c("EnrlMotion_MonthInd", "Prop_Antihyperglycemics",
                                                  "Prop_Cardiovascular", "Prop_ThyroidPreps",
                                                  "Prop_CNSDrugs", "Prop_CardiacDrugs",
                                                  "Prop_Diuretics")], id = "EnrlMotion_MonthInd")

plot <- ggplot(data = test_data_long[test_data_long$EnrlMotion_MonthInd > -13 &
                                       test_data_long$EnrlMotion_MonthInd < 19,], 
               aes(x = EnrlMotion_MonthInd, y = value, colour = variable)) + geom_line() +
  scale_colour_manual(values = c("#4f81bd", "#febe01", "#9bbb59", "#c0504d",
                                 "#8064a2", "#4bacc6")) +
  ggtitle("Motion Monthly Maintenance Drug Useage")
plot <- plot + 
  xlab("Month Relative to Motion") + ylab('Proportion of Members')
plot <- plot + theme_bw() + 
  theme(panel.border=element_blank(), axis.line=element_line("#a6a6a6")) + 
  theme(panel.grid.major.y = element_line("dashed", size = .5, colour="#a6a6a6"),  
        panel.grid.minor.y = element_line("dashed", size = .5, colour="#a6a6a6"),
        plot.title = element_text(hjust = 0.5)) 
plot

# Do the 20% sample for the modeling

member.output <- read.csv("Member_Type.csv", header = TRUE)

sum(member.output$Count_0 > 3 & member.output$Count_1 > 3)
member.output$Type <- "Other"
member.output[member.output$Count_0 > 3 & member.output$Count_1 > 3, "Type"] <- "Both"
member.output[member.output$Count_0 == 1, "Type"] <- "Enrolled"  # Enrolled the entire time

member.use <- data.member[data.member$MemberID %in% member.output$MemberID,]

data.month <- merge(data.month, member.output[,c("MemberID", "Type")], all.x = TRUE)
data.month <- data.month[!is.na(data.month$Type),]

#data.month <- data.month[data.month$MemberID %in% member.use$MemberID,]
#data.month <- merge(data.month, member.use, by.x = "MemberID", by.y = "MemberID", all.x = TRUE)

###################################
# Initial modeling of ALL members #
###################################

null.model <- lmer(log(RX_Allow + 1) ~ (1|MemberID), data = data.month)
VarCorr(null.model)
1.6111^2/(1.6111^2 + 1.3153^2)  # ICC is .600

null.model <- lmer(log(RX_Allow + 1) ~ (1|Time), data = data.month)
VarCorr(null.model)
.17005^2/(.17005^2 + 2.076^2)  # ICC is .0066

model.1 <- lmer(log(RX_Allow + 1) ~ Time + (1|MemberID), data = data.month)
summary(model.1)

model.2 <- lmer(log(RX_Allow + 1) ~ Time + (1|MemberID), data = data.month)
summary(model.2)

model.3 <- lmer(log(RX_Allow + 1) ~ (1|Time) + (1|MemberID), data = data.month)
summary(model.3)

anova(model.2, model.3)

model.4 <- lmer(log(RX_Allow + 1) ~ as.factor(Enrl_Motion) + Age*RAF +
                  as.factor(Sbscr_Ind)*Gender +
                  (1|Time) + (1|MemberID), data = data.month)
summary(model.4)

# Initial modeling of indicator of using a drug

# Use a 25% sample of the 20% sample.
# members <- unique(data.month$MemberID)
# members <- sample(members, .25*length(members), replace = FALSE)
# data.month <- data.month[data.month$MemberID %in% members,]

model.1.a <- glmer(Antihyperglycemics_Ind  ~ as.factor(Enrl_Motion) + Age*RAF +
                     as.factor(Sbscr_Ind)*Gender +
                     (1|Time) + (1|MemberID), family = binomial,
                 data = data.month[data.month$Enrl_Plan == 1,],
                 nAGQ=0,
                 control=glmerControl(optimizer = "nloptwrap"))
summary(model.1.a)

model.2.a <- glmer(Cardiovascular_Ind  ~ as.factor(Enrl_Motion) + Age*RAF +
                     as.factor(Sbscr_Ind)*Gender +
                     (1|Time) + (1|MemberID), family = binomial,
                   data = data.month[data.month$Enrl_Plan == 1,],
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
summary(model.2.a)

model.3.a <- glmer(ThyroidPreps_Ind  ~ as.factor(Enrl_Motion) + Age*RAF +
                     as.factor(Sbscr_Ind)*Gender +
                     (1|Time) + (1|MemberID), family = binomial,
                   data = data.month[data.month$Enrl_Plan == 1,],
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
summary(model.3.a)

model.4.a <- glmer(CNSDrugs_Ind  ~ as.factor(Enrl_Motion) + Age*RAF +
                     as.factor(Sbscr_Ind)*Gender +
                     (1|Time) + (1|MemberID), family = binomial,
                   data = data.month[data.month$Enrl_Plan == 1,],
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
summary(model.4.a)

model.5.a <- glmer(CardiacDrugs_Ind  ~ as.factor(Enrl_Motion) + Age*RAF +
                     as.factor(Sbscr_Ind)*Gender +
                     (1|Time) + (1|MemberID), family = binomial,
                   data = data.month[data.month$Enrl_Plan == 1,],
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
summary(model.5.a)

model.6.a <- glmer(Diuretics_Ind  ~ as.factor(Enrl_Motion) + Age*RAF +
                     as.factor(Sbscr_Ind)*Gender +
                     (1|Time) + (1|MemberID), family = binomial,
                   data = data.month[data.month$Enrl_Plan == 1,],
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
summary(model.6.a)

#######################################################
# Initial modeling of only members who have 6 of each #
#######################################################

null.model <- lmer(log(RX_Allow + 1) ~ (1|MemberID), 
                   data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
VarCorr(null.model)
1.5523^2/(1.5574^2 + 1.3326^2)  # ICC is .574

model.2 <- lmer(log(RX_Allow + 1) ~ Time + (1|MemberID), data = data.month)
summary(model.2)

model.3 <- lmer(log(RX_Allow + 1) ~ Time + (1|MemberID), data = data.month)
summary(model.3)

model.4 <- lmer(log(RX_Allow + 1) ~ (1|Time) + (1|MemberID), data = data.month)
summary(model.4)

anova(model.3, model.4)

model.5 <- lmer(log(RX_Allow + 1) ~ Enrl_Motion + Age + RAF + Gender +
                  (1|Time) + (1|MemberID), 
                data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.5)

# Initial modeling of indicator of using a drug

model.1 <- glmer(Antihyperglycemics_Ind  ~ Enrl_Motion + Age + RAF + Gender +
                   (1|Time) + (1|MemberID), family = binomial,
                 data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.1)

model.2 <- glmer(Cardiovascular_Ind ~ Enrl_Motion + Age + RAF + Gender +
                  (1|Time) + (1|MemberID), family = binomial,
                data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.2)

model.3 <- glmer(ThyroidPreps_Ind ~ Enrl_Motion + Age + RAF + Gender +
                   (1|Time) + (1|MemberID), family = binomial,
                 data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.3)

model.4 <- glmer(CNSDrugs_Ind ~ Enrl_Motion + Age + RAF + Gender +
                   (1|Time) + (1|MemberID), family = binomial,
                 data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.4)

model.5 <- glmer(CardiacDrugs_Ind ~ Enrl_Motion + Age + RAF + Gender +
                   (1|Time) + (1|MemberID), family = binomial,
                 data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.5)

model.6 <- glmer(Diuretics_Ind ~ Enrl_Motion + Age + RAF + Gender +
                   (1|Time) + (1|MemberID), family = binomial,
                 data = data.month[data.month$Type == "Both" & data.month$Enrl_Plan == 1,])
summary(model.6)

# Team Work
# Marvin - Does drug useage help predict drug utilization?
# ------- are some drugs asthma less likely to walk, diuretic more likely?
# Kae
# ------- Define the member population of walkers and how the different groups use drugs.
# Klem
# ------- Modeling of over time variables (month by month) versus aggregated variables, counts
# ------- of months that someone uses a drug.  Random effects models versus 1 obs per member
# Victoria
# ------- Investigate time series versus random effects model.  Does accounting for potential
# ------- autocorrelation improve model fit?