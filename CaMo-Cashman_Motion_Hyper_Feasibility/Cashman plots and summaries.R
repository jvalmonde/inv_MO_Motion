# Cashman plots and summaries

# February 2018

# Steve Smela, Savvysherpa

# This file re-creates the figures and tables included in the final report.  The orginal draft of the final report was written in R markdown, but the text
# of the Word document was subsequently edited without editing the R markdown file.

# Starting point is file "MemberYear2", which was created in "Combined probability and size modeling."  It contains the predicted probabilities and annual
# claim amounts for claims denominated in RVUs and dollars, for all of the companies in the study (Cashman and the seven comparison companies).

library(tidyverse)
library(knitr)
library(pROC)

if(!exists("MemberYear2"))
  load("MemberYear2.rda")

# Create data set of annual observations by company

CompanyByYear <- MemberYear2 %>%
  group_by(GroupName, Year) %>%
  summarise(TotalMemberMonths = sum(Months),
            TotalPaidPMPM = sum(TotalSpend) / TotalMemberMonths,
            RVUsPMPM = sum(RVUs) / TotalMemberMonths,
            PctSpendClaim = 100*mean(AnySpend),
            PctRVUClaim = 100*mean(AnyRVU),
            AvgSpendProb = 100*mean(Spend_prob_pred1),
            AvgRVUProb = 100*mean(RVU_prob_pred1),
            PMPMRVUSize_pred = sum(RVU_size_pred) / TotalMemberMonths,
            PMPMSpendSize_pred = sum(Spend_size_pred) / TotalMemberMonths, 
            PredRVUsPMPM = sum(RVU_pred) / TotalMemberMonths,
            PredSpendPMPM = sum(Spend_pred) / TotalMemberMonths,
            AvgSubscriber = 100*mean(Subscriber),
            AvgSMA = 100*mean(SMA),
            PctMale = 100 * mean(as.numeric(Gender) == 2),
            AvgAge = mean(AgeAdj),
            AvgSES = mean(SES),
            AvgMonths = mean(Months),
            PctAge0 = 100*mean(Age0))

CompanyByYear$GroupName <- relevel(CompanyByYear$GroupName, ref = "CASHMAN EQUIPMENT CO.")


# Table 1.  Summary info on companies in the study

if(!exists("MemberMonth"))
  load("MemberMonth.rda")

Membership <- MemberMonth %>% filter(Year_Mo == 201709) %>% 
  group_by(GroupName) %>%
  summarise(Subscribers = sum(IsSubscriber),
            Members = n(), 
            Dependents = Members - Subscribers) %>%
  rename(Company = GroupName) %>% 
  select(Company, Subscribers, Dependents, Members)

kable(Membership, caption = "Companies in the study, with membership figures as of September 2017")

# Table 2.  PMPM Spending (dollar) amounts.

temp1 <- MemberMonth %>% filter(Year_Mo >= 201404 & Year_Mo <= 201503) %>%
  group_by(GroupName) %>%
  summarise(TotalMemberMonths = n(),
            TotalPaid = sum(TotalMedicalSpend + RxSpend),
            TotalPaidPMPM = round(TotalPaid / TotalMemberMonths, 0),
            TotalRVUs = sum(DrRVU),
            RVUPMPM = round(TotalRVUs / TotalMemberMonths, 2),
            Ratio = TotalPaidPMPM/ RVUPMPM)

temp2 <-MemberMonth %>% filter(Year_Mo >= 201604 & Year_Mo <= 201703) %>%
  group_by(GroupName) %>%
  summarise(TotalMemberMonths = n(),
            TotalPaid = sum(TotalMedicalSpend + RxSpend),
            TotalPaidPMPM = round(TotalPaid / TotalMemberMonths, 0),
            TotalRVUs = sum(DrRVU),
            RVUPMPM = round(TotalRVUs / TotalMemberMonths, 2),
            Ratio = TotalPaidPMPM/ RVUPMPM)

Comparisons <- merge(temp1, temp2, by = "GroupName")

Comparisons1 <- Comparisons %>% 
  select(GroupName, TotalPaidPMPM.x, TotalPaidPMPM.y) %>%
  rename(Company = GroupName,
         PMPM2014_15 = TotalPaidPMPM.x,
         PMPM2016_17 = TotalPaidPMPM.y)

kable(Comparisons1, caption = "PMPM Total Spending Amounts (Medical + Rx), 4/14 to 3/15 and 4/16 to 3/17")

# Table 3.  PMPM RVU amounts.

Comparisons2 <- Comparisons %>% 
  select(GroupName, RVUPMPM.x, RVUPMPM.y) %>%
  rename(Company = GroupName,
         PMPM2014_15 = RVUPMPM.x,
         PMPM2016_17 = RVUPMPM.y)

kable(Comparisons2, caption = "PMPM RVU Amounts, 4/14 to 3/15 and 4/16 to 3/17")


# Figure 1. PMPM dollar amounts.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = TotalPaidPMPM,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") +
  labs(title = "Annual PMPM dollar amounts", y = "PMPM dollars")


# Figure 2.  PMPM RVU amounts.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = RVUsPMPM,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") +  
  labs(title = "Annual PMPM RVU amounts", y = "PMPM RVUs")

# Figure 3.  Dollar-denominated claim probabilities.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PctSpendClaim,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Probability of having a dollar-denominated claim in a year", y = "Percent with claim")

# Figure 4.  RVU-denominated claim probabilities.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PctRVUClaim,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Probability of having an RVU-denominated claim in a year", y = "Percent with claim")

# Model performance summaries.

# ROC

roc(MemberYear2$AnySpend, MemberYear2$Spend_prob_pred1)
roc(MemberYear2$AnyRVU, MemberYear2$RVU_prob_pred1)

# Percent of variation in annual PMPM amounts by company explained by models ("R-squared")

SS_Spend = sum((CompanyByYear$TotalPaidPMPM - mean(CompanyByYear$TotalPaidPMPM))^2)
SSE_Spend = sum((CompanyByYear$TotalPaidPMPM - CompanyByYear$PredSpendPMPM)^2)
100 * (1- SSE_Spend / SS_Spend)

SS_RVU = sum((CompanyByYear$RVUsPMPM - mean(CompanyByYear$RVUsPMPM))^2)
SSE_RVU = sum((CompanyByYear$RVUsPMPM - CompanyByYear$PredRVUsPMPM)^2)
100 * (1- SSE_RVU / SS_RVU)


### Model Results 1 ###

# Models were estimated in "Combined probability and size modeling".  If not loaded, load them.  If 
# they don't exist, need to run "Combined probability and size modeling."

if(!exists("RVU_prob"))
  load("RVU_prob.rda")

if(!exists("RVU_size"))
  load("RVU_size.rda")

if(!exists("Spend_prob"))
  load("Spend_prob.rda")

if(!exists("Spend_size"))
  load("Spend_size.rda")


# Claim probabilities

# SES
exp(summary(Spend_prob)$coef[12,1])
exp(summary(RVU_prob)$coef[12,1])


# Months enrolled
exp(summary(Spend_prob)$coef[15,1])
exp(summary(RVU_prob)$coef[15,1])

# Preparing for graphs of effect of age on probabilities
Probs <- as.data.frame(seq(from = -1.91, to = 1.85, by = .01))
colnames(Probs) <- "StdAges"
Probs$Ages <- Probs$StdAges * sd(MemberYear2$AgeAdj) + mean(MemberYear2$AgeAdj)

Probs$Male_spend  <- exp(summary(Spend_prob)$coef[1,1] + summary(Spend_prob)$coef[9,1] +  
                           Probs$StdAges *   (summary(Spend_prob)$coef[8,1] + summary(Spend_prob)$coef[16,1]) + 
                           Probs$StdAges^2 * (summary(Spend_prob)$coef[10,1] + summary(Spend_prob)$coef[17,1]) + 
                           Probs$StdAges^3 * (summary(Spend_prob)$coef[11,1] + summary(Spend_prob)$coef[18,1]))

Probs$Female_spend  <- exp(summary(Spend_prob)$coef[1,1] +  
                           Probs$StdAges   * summary(Spend_prob)$coef[8,1]  + 
                           Probs$StdAges^2 * summary(Spend_prob)$coef[10,1]  + 
                           Probs$StdAges^3 * summary(Spend_prob)$coef[11,1] )

# Figure 5.  Effect of age & gender on $-denominated claim probabilites.

Probs %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_spend,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_spend,  color = "Female")) + 
  labs(y = "Odds ratio", title = "Effect of age & gender on claim probability", subtitle = "$-denominated claims")  +
  scale_color_discrete(name = "Gender") + ylim(0, NA)


Probs$Male_RVU  <- exp(summary(RVU_prob)$coef[1,1] + summary(RVU_prob)$coef[9,1] +  
                           Probs$StdAges *   (summary(RVU_prob)$coef[8,1] + summary(RVU_prob)$coef[16,1]) + 
                           Probs$StdAges^2 * (summary(RVU_prob)$coef[10,1] + summary(RVU_prob)$coef[17,1]) + 
                           Probs$StdAges^3 * (summary(RVU_prob)$coef[11,1] + summary(RVU_prob)$coef[18,1]))

Probs$Female_RVU  <- exp(summary(RVU_prob)$coef[1,1] +  
                             Probs$StdAges   * summary(RVU_prob)$coef[8,1]  + 
                             Probs$StdAges^2 * summary(RVU_prob)$coef[10,1]  + 
                             Probs$StdAges^3 * summary(RVU_prob)$coef[11,1] )


# Figure 6.  Effect of age & gender on RVU-denominated claim probabilites.

Probs %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_RVU,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_RVU,  color = "Female")) + 
  labs(y = "Odds ratio", title = "Effect of age & gender on claim probability", subtitle = "RVU-denominated claims")  +
  scale_color_discrete(name = "Gender") + ylim(0, NA)

# Subscriber status
exp(summary(Spend_prob)$coef[14,1])
exp(summary(RVU_prob)$coef[14,1])

# SMA-attributed primary care provider
exp(summary(Spend_prob)$coef[13,1])
exp(summary(RVU_prob)$coef[13,1])





# Figure 7.  Predicted vs. actual probabilities, Cashman.

CompanyByYear %>% filter(GroupName == "CASHMAN EQUIPMENT CO.") %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PctSpendClaim,  color = "Dollars", linetype = "Actual")) + 
  geom_line(aes(x = Year, y = AvgSpendProb,  color = "Dollars", linetype = "Predicted")) +
  geom_line(aes(x = Year, y = PctRVUClaim,  color = "RVUs", linetype = "Actual")) + 
  geom_line(aes(x = Year, y = AvgRVUProb,  color = "RVUs", linetype = "Predicted")) + 
  labs(title = "Predicted vs. actual probabilities", subtitle = "Cashman Equipment Co.", y = "Percent") + 
  scale_color_discrete(name = "Unit of measure") + scale_linetype_discrete(name = "") +
  ylim(40, NA)

# Figure 8.  Predicted vs. actual probabilities, Fairway Chevrolet.

CompanyByYear %>% filter(GroupName == "FAIRWAY CHEVROLET") %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PctSpendClaim,  color = "Dollars", linetype = "Actual")) + 
  geom_line(aes(x = Year, y = AvgSpendProb,  color = "Dollars", linetype = "Predicted")) +
  geom_line(aes(x = Year, y = PctRVUClaim,  color = "RVUs", linetype = "Actual")) + 
  geom_line(aes(x = Year, y = AvgRVUProb,  color = "RVUs", linetype = "Predicted")) + 
  labs(title = "Predicted vs. actual probabilities", subtitle = "Fairway Chevrolet", y = "Percent") + 
  scale_color_discrete(name = "Unit of measure") + scale_linetype_discrete(name = "") +
  ylim(30, NA)

# Figure 9.  Percent male out of total membership

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PctMale,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Percent male out of total membership", y = "Percent")

# Figure 10.  Average age of membership

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = AvgAge,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Average age of membership", y = "Years")

# Figure 11. % membership with an SMA primary-care provider

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = AvgSMA,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Membership with an SMA PCP", y = "Percent")

# Figure 12.  % subscribers out of total membership

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = AvgSubscriber,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Percent subscribers out of total membership", y = "Percent")

# Figure 13.  Average SES.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = AvgSES,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Average socio-economic score", y = "SES")

# Figuer 14.  Average months membership.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = AvgMonths,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Average months membership by year", y = "Months")


# Table 4. Random effects by company for claim probability.

temp <- round(exp(ranef(Spend_prob)[[1]]), 2)
temp[,2] <- round(exp(ranef(RVU_prob)[[1]]), 2)
colnames(temp) <- c("Dollar claim", "RVU Claim")

kable(temp, caption = "Odds ratios for probability of a claim, by company")


#### Model results 2 ####

# Size of annual claim amounts

# SES
exp(summary(Spend_size)$coef[13,1])  # For RVUs not significant

# Months enrolled
exp(summary(Spend_size)$coef[16,1])
exp(summary(RVU_size)$coef[16,1])

# Age and gender

Size <- as.data.frame(seq(from = -1.86, to = 1.85, by = .01))
colnames(Size) <- "StdAges"
Size$Ages <- Size$StdAges * sd(MemberYear2$AgeAdj) + mean(MemberYear2$AgeAdj)

# Since we're interested in only the relative sizes of males vs. females by age, intercept term is not
# included in the following

Size$Male_spend  <- exp(summary(Spend_size)$coef[10,1] +  
                          Size$StdAges   * (summary(Spend_size)$coef[9,1]  + summary(Spend_size)$coef[17,1]) + 
                          Size$StdAges^2 * (summary(Spend_size)$coef[11,1] + summary(Spend_size)$coef[18,1]) + 
                          Size$StdAges^3 * (summary(Spend_size)$coef[12,1] + summary(Spend_size)$coef[19,1]))

Size$Female_spend  <- exp(Size$StdAges   * summary(Spend_size)$coef[9,1]   + 
                          Size$StdAges^2 * summary(Spend_size)$coef[11,1]  + 
                          Size$StdAges^3 * summary(Spend_size)$coef[12,1] )

# Figure 15.  Gender and age effects on size of $-denominated claims.

Size %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_spend,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_spend,  color = "Female")) + 
  labs(y = "Relative size", title = "Effect of age and gender on annual claim amounts", 
       subtitle = "$-denominated claims")  + scale_color_discrete(name = "Gender") + ylim(0, NA)

Size$Male_RVU <- exp(summary(RVU_size)$coef[10,1] +  
                       Size$StdAges   * (summary(RVU_size)$coef[9,1]  + summary(RVU_size)$coef[17,1]) + 
                       Size$StdAges^2 * (summary(RVU_size)$coef[11,1] + summary(RVU_size)$coef[18,1]) + 
                       Size$StdAges^3 * (summary(RVU_size)$coef[12,1] + summary(RVU_size)$coef[19,1]))

Size$Female_RVU <- exp(Size$StdAges   * summary(RVU_size)$coef[9,1] + 
                       Size$StdAges^2 * summary(RVU_size)$coef[11,1] + 
                       Size$StdAges^3 * summary(RVU_size)$coef[12,1] )

# Figure 16.  Gender and age effects on size of RVU-denominated claims.

Size %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_RVU,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_RVU,  color = "Female")) + 
  labs(y = "Relative size", title = "Effect of age and gender on annual claim amounts", 
       subtitle = "RVU-denominated claims")  + scale_color_discrete(name = "Gender") + ylim(0, NA)


# Being born
exp(summary(Spend_size)$coef[8,1])
exp(summary(RVU_size)$coef[8,1])

# Figure 17.  Percent of membership 0 years old.

CompanyByYear %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PctAge0,  color = GroupName, linetype = factor(Cashman), size = factor(Cashman))) +
  scale_size_manual(values = c(1, .5)) + guides(linetype = FALSE) + guides(size = FALSE) + 
  scale_color_discrete(name = "Company") + 
  labs(title = "Percent of membership 0 years old", y = "Percent")


# Subscriber status
exp(summary(Spend_size)$coef[15,1])
exp(summary(RVU_size)$coef[15,1])

# SMA provider (Dollar claims only; RVUs not significant)
exp(summary(Spend_size)$coef[14,1])

# Table 5.  Random effects for size of claim

temp <- round(exp(ranef(Spend_size)[[1]]), 2)
temp[,2] <- round(exp(ranef(RVU_size)[[1]]), 2)
colnames(temp) <- c("Dollar claim", "RVU Claim")

kable(temp, caption = "Multipliers for size of claim, by company")

# Figures 18 and 19:  Actual vs. predicted PMPM dollar amounts

CompanyByYear %>% filter(GroupName == "LV GAMING VENTURES DBA THE M RESORTS" | GroupName == "MV CONTRACT TRANSPORTATION, INC." | GroupName == "ONE NEVADA CREDIT UNION" | 
                           GroupName == "CASHMAN EQUIPMENT CO." ) %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = TotalPaidPMPM,  color = GroupName, linetype = "Actual", size = factor(Cashman))) + 
  geom_line(aes(x = Year, y = PredSpendPMPM,  color = GroupName, linetype = "Predicted", size = factor(Cashman))) + 
  guides(size = FALSE) + scale_size_manual(values = c(1, .5)) +
  scale_color_discrete(name = "Company") + scale_linetype_discrete(name = "") +
  ylim(100, 450) +
  labs(title = "Actual vs. predicted PMPM dollar amounts", y = "Dollars")

CompanyByYear %>% filter(GroupName == "AFFINITY GAMING" | GroupName == "FAIRWAY CHEVROLET" | GroupName == "KONAMI GAMING INC" | 
                           GroupName == "LIFE CARE CENTERS OF AMERICA" ) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = TotalPaidPMPM,  color = GroupName, linetype = "Actual")) + 
  geom_line(aes(x = Year, y = PredSpendPMPM,  color = GroupName, linetype = "Predicted")) + 
  scale_color_discrete(name = "Company") + scale_linetype_discrete(name = "") +
  ylim(100, 450) +
  labs(title = "Actual vs. predicted PMPM dollar amounts", y = "Dollars")

# Figures 20 and 21:  Actual vs. predicted PMPM RVU amounts

CompanyByYear %>% filter(GroupName == "LV GAMING VENTURES DBA THE M RESORTS" | GroupName == "MV CONTRACT TRANSPORTATION, INC." | GroupName == "ONE NEVADA CREDIT UNION" | 
                           GroupName == "CASHMAN EQUIPMENT CO." ) %>%
  mutate(Cashman = ifelse(GroupName == "CASHMAN EQUIPMENT CO.", 1, 2)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = RVUsPMPM,  color = GroupName, linetype = "Actual", size = factor(Cashman))) + 
  geom_line(aes(x = Year, y = PredRVUsPMPM,  color = GroupName, linetype = "Predicted", size = factor(Cashman))) + 
  guides(size = FALSE) + scale_size_manual(values = c(1, .5)) +
  scale_color_discrete(name = "Company") + scale_linetype_discrete(name = "") +
  ylim(.75, 2) +
  labs(title = "Actual vs. predicted PMPM RVU amounts", y = "RVUs")


CompanyByYear %>% filter(GroupName == "AFFINITY GAMING" | GroupName == "FAIRWAY CHEVROLET" | GroupName == "KONAMI GAMING INC" | 
                           GroupName == "LIFE CARE CENTERS OF AMERICA" ) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = RVUsPMPM,  color = GroupName, linetype = "Actual")) + 
  geom_line(aes(x = Year, y = PredRVUsPMPM,  color = GroupName, linetype = "Predicted")) + 
  scale_color_discrete(name = "Company") + scale_linetype_discrete(name = "") +
  ylim(.75, 2) +
  labs(title = "Actual vs. predicted PMPM RVU amounts", y = "RVUs")


### Cashman-only analysis ###

if(!exists("CashMemberYear"))
  load("CashMemberYear.rda")

if(!exists("Subscribers"))
  load("Subscribers.rda")

if(!exists("RAF"))
  load("CashRAF.rda")

Subscribers <- merge(Subscribers, RAF, by=c("SavvyID", "Year"), all.x = T)

# Is walking limited to just subscribers?  (Figures cited in report are 346 subscribers out 
# of 353 walking participants.  Numbers here are slightly lower (329 out of 335) because the data
# set used in the report does not include data after 9/2017, so it misses a few individuals. Numbers
# cited in report come out of the SQL Server database.)

temp <- CashMemberYear %>% group_by(SavvyID) %>% mutate(Walker = max(ifelse(MonthsWalking > 0, 1, 0))) %>% 
  summarise(Sub = max(Subscriber), Walker = max(Walker))
table(temp$Sub, temp$Walker)

# Participation rates in recent years.

Subscribers %>% group_by(Year) %>%
  summarise(PctWalkers = mean(MonthsWalking >0))

# Figures 22 and 23.  PMPM amounts, walkers vs non-walkers

Subscribers %>% mutate(Walker = ifelse(AvgDailySteps == 0, "No", "Yes")) %>%
  group_by(Year, Walker) %>%
  summarise(PMPMRVUs = sum(RVUs) / sum(Months), 
            PMPMSpend = sum(TotalSpend) / sum(Months)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PMPMRVUs, linetype = as.factor(Walker))) +
  scale_linetype_discrete(name = "Walker") +
  labs(title = "PMPM RVUs, walkers vs. non-walkers", y = "RVUs")

Subscribers %>% mutate(Walker = ifelse(AvgDailySteps == 0, "No", "Yes")) %>%
  group_by(Year, Walker) %>%
  summarise(PMPMRVUs = sum(RVUs) / sum(Months), 
            PMPMSpend = sum(TotalSpend) / sum(Months)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = PMPMSpend, linetype = as.factor(Walker))) +
  scale_linetype_discrete(name = "Walker") +
  labs(title = "PMPM dollar amounts, walkers vs. non-walkers", y = "Dollars")

# Figure 24.  RAFs of walkers and non-walkers

Subscribers %>% mutate(Walker = ifelse(AvgDailySteps > 0, "Yes", "No")) %>%
  group_by(Year, Walker) %>%
  summarise(AvgRAF = mean(RAF.x)) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = AvgRAF, linetype = as.factor(Walker))) +
  scale_linetype_discrete(name = "Walker") +
  labs(title = "Average RAF scores of walkers and non-walkers", y = "RAF")

# Figure 25.  High-RAF individuals

Subscribers %>% filter(SavvyID %in% c(406, 34512, 103731, 127721, 236986, 320965, 320991, 321023, 321076, 324112, 470159, 530083, 712247, 765225, 1072860, 1121613 )) %>%
  group_by(SavvyID, Year) %>%
  ggplot() + 
  geom_line(aes(x = Year, y = RAF.x, color = as.factor(SavvyID))) +
  guides(color = FALSE) +
  labs(title = "Highest-RAF Cashman members")

### Model results ###

# SES.  Effect on size is not significant
exp(summary(CashSpend_prob_GLM)$coef[12,1])
exp(summary(CashRVU_prob_GLM)$coef[12,1])

# Months enrolled.  Effect on dollar size is not significant
exp(summary(CashSpend_prob_GLM)$coef[14,1])
exp(summary(CashRVU_prob_GLM)$coef[14,1])

exp(summary(CashRVU_Size_GLM)$coef[14,1])

# Age and gender effects--not included in final report, but presented here

Probs <- as.data.frame(seq(from = -.60, to = 1.85, by = .01))
colnames(Probs) <- "StdAges"
Probs$Ages <- Probs$StdAges * sd(CashMemberYear$AgeAdj) + mean(CashMemberYear$AgeAdj)

Probs$Male_spend  <- exp(summary(CashSpend_prob_GLM)$coef[1,1] + summary(CashSpend_prob_GLM)$coef[9,1] +  
                           Probs$StdAges * (summary(CashSpend_prob_GLM)$coef[8,1] + summary(CashSpend_prob_GLM)$coef[17,1]) + 
                           Probs$StdAges^2 * (summary(CashSpend_prob_GLM)$coef[10,1] + summary(CashSpend_prob_GLM)$coef[18,1]) + 
                           Probs$StdAges^3 * (summary(CashSpend_prob_GLM)$coef[11,1] + summary(CashSpend_prob_GLM)$coef[19,1]))

Probs$Female_spend <-  exp(summary(CashSpend_prob_GLM)$coef[1,1] +  
                             Probs$StdAges * summary(CashSpend_prob_GLM)$coef[8,1] + 
                             Probs$StdAges^2 * summary(CashSpend_prob_GLM)$coef[10,1] + 
                             Probs$StdAges^3 * summary(CashSpend_prob_GLM)$coef[11,1] )

Probs %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_spend,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_spend,  color = "Female")) + 
  labs(y = "Odds ratio", title = "Effect of age and gender on probability of having a dollar-denominated claim")  + ylim(0, NA)

Probs$Male_RVU <- exp(summary(CashRVU_prob_GLM)$coef[1,1] + summary(CashRVU_prob_GLM)$coef[9,1] +  
                        Probs$StdAges * (summary(CashRVU_prob_GLM)$coef[8,1] + summary(CashRVU_prob_GLM)$coef[17,1]) + 
                        Probs$StdAges^2 * (summary(CashRVU_prob_GLM)$coef[10,1] + summary(CashRVU_prob_GLM)$coef[18,1]) + 
                        Probs$StdAges^3 * (summary(CashRVU_prob_GLM)$coef[11,1] + summary(CashRVU_prob_GLM)$coef[19,1]))

Probs$Female_RVU <- exp(summary(CashRVU_prob_GLM)$coef[1,1] +  
                          Probs$StdAges * summary(CashRVU_prob_GLM)$coef[8,1] + 
                          Probs$StdAges^2 * summary(CashRVU_prob_GLM)$coef[10,1] + 
                          Probs$StdAges^3 * summary(CashRVU_prob_GLM)$coef[11,1] )

Probs %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_RVU,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_RVU,  color = "Female")) + 
  labs(y = "Odds ratio", title = "Effect of age and gender on probability of having an RVU-denominated claim") + ylim(0, NA)


# Sizes

Size <- as.data.frame(seq(from = -.60, to = 1.85, by = .01))
colnames(Size) <- "StdAges"
Size$Ages <- Size$StdAges * sd(CashMemberYear$AgeAdj) + mean(CashMemberYear$AgeAdj)

Size$Male_spend  <- exp(summary(CashSpend_Size_GLM)$coef[9,1] +  
                          Probs$StdAges * (summary(CashSpend_Size_GLM)$coef[8,1] + summary(CashSpend_Size_GLM)$coef[17,1]) + 
                          Probs$StdAges^2 * (summary(CashSpend_Size_GLM)$coef[10,1] + summary(CashSpend_Size_GLM)$coef[18,1]) + 
                          Probs$StdAges^3 * (summary(CashSpend_Size_GLM)$coef[11,1] + summary(CashSpend_Size_GLM)$coef[19,1]))
  

Size$Female_spend <-  exp(Probs$StdAges * summary(CashSpend_Size_GLM)$coef[8,1] + 
                          Probs$StdAges^2 * summary(CashSpend_Size_GLM)$coef[10,1] + 
                          Probs$StdAges^3 * summary(CashSpend_Size_GLM)$coef[11,1] )

Size %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_spend,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_spend,  color = "Female")) + 
  labs(y = "Relative size", title = "Effect of age and gender on amount of annual dollar-denominated claims")  + ylim(0, NA)

Size$Male_RVU  <- exp(summary(CashRVU_Size_GLM)$coef[9,1] +  
                        Probs$StdAges * (summary(CashRVU_Size_GLM)$coef[8,1] + summary(CashRVU_Size_GLM)$coef[17,1]) + 
                        Probs$StdAges^2 * (summary(CashRVU_Size_GLM)$coef[10,1] + summary(CashRVU_Size_GLM)$coef[18,1]) + 
                        Probs$StdAges^3 * (summary(CashRVU_Size_GLM)$coef[11,1] + summary(CashRVU_Size_GLM)$coef[19,1]))

Size$Female_RVU  <- exp(Probs$StdAges * summary(CashRVU_Size_GLM)$coef[8,1] + 
                        Probs$StdAges^2 * summary(CashRVU_Size_GLM)$coef[10,1] + 
                         Probs$StdAges^3 * summary(CashRVU_Size_GLM)$coef[11,1] )

Size %>% ggplot() +
  geom_line(aes(x = Ages, y = Male_RVU,  color = "Male")) + 
  geom_line(aes(x = Ages, y = Female_RVU,  color = "Female")) + 
  labs(y = "Relative size", title = "Effect of age and gender on amount of annual RVU-denominated claims")  + ylim(0, NA)

# SMA provider
exp(summary(CashSpend_prob_GLM)$coef[13,1])
exp(summary(CashRVU_prob_GLM)$coef[13,1])

# Months walking
exp(summary(CashSpend_prob_GLM)$coef[15,1])
exp(summary(CashRVU_prob_GLM)$coef[15,1])

exp(summary(CashSpend_Size_GLM)$coef[15,1])
exp(summary(CashRVU_Size_GLM)$coef[15,1])

# Meeting intensity goals
summary(CashMemberYear$IntensityPct[CashMemberYear$AvgDailySteps > 0])

exp(summary(CashSpend_prob_GLM)$coef[16,1]/100)
exp(summary(CashRVU_prob_GLM)$coef[16,1]/100)

# Meeting tenacity goals
exp(summary(CashSpend_Size_GLM)$coef[16,1]/100)
exp(summary(CashRVU_Size_GLM)$coef[16,1]/100)

#### Merely participating in walking program ###

exp(summary(WalkerSpend_prob_GLM)$coef[15,1])
exp(summary(WalkerRVU_prob_GLM)$coef[15,1])
exp(summary(WalkerSpend_Size_GLM)$coef[15,1])
exp(summary(WalkerRVU_Size_GLM)$coef[15,1])




