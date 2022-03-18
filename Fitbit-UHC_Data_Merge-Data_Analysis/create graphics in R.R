# C:\Savvy\Scratch\Fitbit\InsuranceEmailGender.txt has member counts by 
# those categories
# we'll pull them into a data object and try to create a nice graph that's 
# annoying to build in Excel


#load package and data
#install.packages("ggplot2")
#install.packages("gridExtra")
#install.packages("scales")
#install.packages("dplyr")
library(ggplot2)
library(gridExtra)
library(scales)
library(dplyr)



#IEG <- read.table("C:\\Savvy\\Scratch\\Fitbit\\InsuranceEmailGender.txt", header=TRUE)
#IEG.ASO <- IEG[IEG$Insurance == "ASO",]
#IEG.FI <- IEG[IEG$Insurance == "UHC-FI",]

IEGA <- read.table("C:\\Savvy\\Scratch\\Fitbit\\InsuranceEmailGenderAgeBand.txt", header=TRUE)
#IEGA.ASO <- IEGA[IEGA$Insurance == "ASO",]
#IEGA.FI <- IEGA[IEGA$Insurance == "UHC-FI",]


#test <- expand.grid('cat' = LETTERS[1:5], 'cond' = c(F, T), 'year' = 2011:2015)
#test$value <- floor((rnorm(nrow(test)))*100)
#test$value[test$value < 0] <- 0

# tbl <- expand.grid('cat' = LETTERS[1:2], 'year' = 2016:2018)
# tbl$cat=='A'
# tbl[tbl$cat=='A',]
# rm(tbl)

#plot 
# PlotMemberEmail.ASO <- ggplot() + 
#   geom_bar(data=IEGA[IEGA$Insurance == "ASO",], aes(y = MemberCnt / 1000, x = HaveEmail, fill = AgeBand), 
#            stat = "identity", position = position_stack(reverse = TRUE)) +
#   facet_grid( ~ Gdr_Cd) + 
#   labs(y = "Member Count (000s)", title = "ASO (by Gender)") +
#   #guides(fill = FALSE) #makes it wider than the other one
# 
#   PlotMemberEmail.FI <- ggplot() + 
#   geom_bar(data=IEGA[IEGA$Insurance == "UHC-FI",], aes(y = MemberCnt / 1000, x = HaveEmail, fill = AgeBand), 
#            stat = "identity", position = position_stack(reverse = TRUE)) +
#   facet_grid( ~ Gdr_Cd)  + 
#   labs(y = "", title = "FI (by Gender)", fill = "Age Band")
# 
# grid.arrange(PlotMemberEmail.ASO, PlotMemberEmail.FI, ncol=2)

ggplot() + 
  geom_bar(data=IEGA, aes(y = MemberCnt / 1000, x = HaveEmail, fill = AgeBand), 
           stat = "identity", position = position_stack(reverse = TRUE)) +
  facet_grid( ~ Insurance + Gdr_Cd)  + 
  labs(x = "We have their email address", y = "Member Count (000s)", title = "By Insurance, By Gender", fill = "Age Band")

#probably change the color, but for now let's move on to costs
IEGS <- read.table("C:\\Savvy\\Scratch\\Fitbit\\InsuranceEmailGenderStats.txt", header=TRUE)
IEGS$AllwAmt <- as.numeric(IEGS$AllwAmt)
IEGS$CostCategory <- factor(IEGS$CostCategory, levels = c('Inpatient', 'Outpatient', 'Physician', 'Pharmacy', 'ER'))
IEGS.total <- IEGS %>% 
  group_by(Insurance, Gdr_Cd, HaveEmail) %>% 
  summarise(TotalAllw = sum(AllwAmt))


ggplot() + 
  geom_bar(data=IEGS, aes(y = AllwAmt, x = HaveEmail, fill = CostCategory), 
           stat = "identity", position = position_stack(reverse = TRUE)) +
  facet_grid( ~ Insurance + Gdr_Cd)  + 
  scale_y_continuous(label=dollar_format()) +
  labs(x = "We have their email address", y = "Allow Amt (PMPM)", title = "By Insurance, By Gender", fill = "Cost Category") + 
  geom_text(aes(HaveEmail, TotalAllw + 25, label = dollar(TotalAllw), fill = NULL), data = IEGS.total, size = 3)
  #geom_text(size = 3, position = position_stack(vjust = 0.5))

#Why are the costs higher? What conditions do they have?
#Just about all of them!
EC <- read.table("C:\\Savvy\\Scratch\\Fitbit\\EmailCondition.txt", header=TRUE)
EC$Rate <- as.numeric((EC$Rate))

ggplot() + 
  geom_bar(data=EC, aes(y = Rate, x = Condition, fill = factor(HaveEmail)), stat = "identity", position = "dodge") +
  scale_y_continuous(label=percent_format()) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "We have their email address", y = "Member Share", title = "Members with diagnoses related to conditions in 2017", fill = "Have Email")


#So, let's restrict to just those members with emails, and we'll look at how those members compare
IEGAF <- read.table("C:\\Savvy\\Scratch\\Fitbit\\InsuranceEmailGenderAgeBandFitbitStats.txt", header=TRUE)

ggplot() + 
  geom_bar(data=IEGAF[IEGAF$AgeBand != "NULL",], aes(y = MemberCnt / 1000, x = HaveFitbit, fill = AgeBand), 
           stat = "identity", position = position_stack(reverse = TRUE)) +
  facet_grid( ~ Insurance + Gdr_Cd)  + 
  labs(x = "Have a Fitbit", y = "Member Count (000s)", title = "Members With Email Addresses, By Insurance, By Gender", fill = "Age Band")


ggplot() + 
  geom_bar(data=IEGAF[IEGAF$AgeBand == "NULL",], aes(y = AllwAmt, x = HaveFitbit, fill = AllwAmt), 
           stat = "identity", position = position_stack(reverse = TRUE)) +
  facet_grid( ~ Insurance + Gdr_Cd) + 
  scale_y_continuous(label=dollar_format()) + 
  labs(x = "Have a Fitbit", y = "Avg Allw (PMPM)", title = "Members With Email Addresses, By Insurance, By Gender", fill = "Age Band")

MyData <- read.table("C:\\Savvy\\Scratch\\Fitbit\\FitbitMasterStats.txt", header=TRUE)
#sapply(MyData, class)
#DollarCols <- c("PMPM", "PMPM_Med", "PMPM_Ip", "PMPM_Op", "PMPM_Dr", "PMPM_Er", "PMPM_Rx")
#MyData[DollarCols] <- lapply(MyData[DollarCols], as.numeric)

MyData.InsuranceSegmentGroup <- read.table("C:\\Savvy\\Scratch\\Fitbit\\InsuranceSegmentGroup.txt", header=TRUE, sep='\t')
MyData.InsuranceSegmentGroup$Company <- as.character(MyData.InsuranceSegmentGroup$Company)
MyData.InsuranceSegmentGroup$Fund <- as.character(MyData.InsuranceSegmentGroup$Fund)
attach(MyData.InsuranceSegmentGroup)


ISGToReport <- c("Rnk", "CUST_SEG_NM", "MbrCnt", "Age", "PctFemale", "IP.Admit", "ER.Visit", "PMPM", "PMPM.Med", "PMPM.Rx", "Charlson", "Diabetes", "HTN", "Depression")

MyData.InsuranceSegmentGroup[Company == "Uniprise " & Fund == "FI ", ISGToReport]
Company

kable(MyData.InsuranceSegmentGroup[Company == "UHC" & Fund == "FI ", ISGToReport], caption = "UHC-FI")



MyData.InsuranceSegmentGroup <- read.table("C:\\Savvy\\Scratch\\Fitbit\\InsuranceSegmentGroup.txt", header=TRUE, sep='\t')
MyData.InsuranceSegmentGroup$Company <- as.character(MyData.InsuranceSegmentGroup$Company)
MyData.InsuranceSegmentGroup$Fund <- as.character(MyData.InsuranceSegmentGroup$Fund)

MyData.InsuranceSegmentGroup[Company == "UNIPRISE " & Fund == "ASO", ISGToReport]
MyData.InsuranceSegmentGroup[Company == "UNIPRISE " & Fund == "FI ", ISGToReport]
MyData.InsuranceSegmentGroup[Company == "UHC" & Fund == "ASO", ISGToReport]
MyData.InsuranceSegmentGroup[Company == "UHC" & Fund == "FI ", ISGToReport]

MyData


EC <- read.table("C:\\Savvy\\Scratch\\Fitbit\\EmailCondition.txt", header=TRUE)
EC$Rate <- as.numeric((EC$Rate))

MyData <- read.table("C:\\Savvy\\Scratch\\Fitbit\\FitbitMasterStats.txt", header=TRUE)

#report email havers by insurance, by gender. 
MyData.HaveEmail <- MyData[MyData$Insurance    != "NULL" & 
                             MyData$HaveEmail  != "NULL" & 
                             MyData$HaveFitbit == "NULL" & 
                             MyData$Gdr_Cd     != "NULL" & 
                             MyData$AgeBand    != "NULL" ,]




ggplot() + 
  geom_bar(data=EC, aes(y = Rate, x = Condition, fill = factor(HaveEmail)), stat = "identity", position = "dodge") +
  scale_y_continuous(label=percent_format()) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "We have their email address", y = "Member Share", title = "Members with diagnoses related to conditions in 2017", fill = "Have Email")


MyData.Cond <- read.table("C:\\Savvy\\Scratch\\Fitbit\\FitbitMasterStats_ConditionPivot.txt", header=TRUE)

#report email havers by insurance, by gender. 
MyData.Cond.FI <- MyData.Cond[MyData.Cond$Insurance != "UHC-FI",]
MyData.Cond.ASO <- MyData.Cond[MyData.Cond$Insurance != "Uni-ASO",]

#FI
ggplot() + 
  geom_bar(data=MyData.Cond.FI, aes(y = Rate, x = Condition, fill = factor(HaveEmail)), stat = "identity", position = "dodge") +
  scale_y_continuous(label=percent_format()) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "We have their email address", y = "Member Share", title = "Members with diagnoses related to conditions in 2017: FI", fill = "Have Email")

#ASO
ggplot() + 
  geom_bar(data=MyData.Cond.ASO, aes(y = Rate, x = Condition, fill = factor(HaveEmail)), stat = "identity", position = "dodge") +
  scale_y_continuous(label=percent_format()) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "We have their email address", y = "Member Share", title = "Members with diagnoses related to conditions in 2017: ASO", fill = "Have Email")

m <- MyData.HaveEmail[,c("Insurance", "Age", "PctEmail", "PMPM", "PMPM_Med", "PMPM_Rx")]
m$a <- as.integer(m$PMPM)


MyData.HaveEmailSummary <- MyData[MyData$Insurance    != "NULL" & 
                                    MyData$HaveEmail  != "NULL" & 
                                    MyData$HaveFitbit == "NULL" & 
                                    MyData$Gdr_Cd     == "NULL" & 
                                    MyData$AgeBand    == "NULL", 
                                  c("Insurance", "HaveEmail", "MbrCnt", "Age", "Female", "IP.Admit", "ER.Visit", "PMPM", "Med", "Rx", "Charlson", "Diabetes", "HTN", "Depression")]


MyData[
         MyData$Insurance  != "NULL" & 
         MyData$HaveEmail  == "Yes" & 
         MyData$HaveFitbit == "NULL" & 
         MyData$Gdr_Cd     != "NULL" & 
         MyData$AgeBand    != "NULL" &
         TRUE
           , c("Insurance", "HaveFitbit", "Gdr_Cd", "AgeBand", "MbrCnt", "Age", "Female", "IP.Admit", "PMPM", "Med", "Rx", "Charlson", "Diabetes", "HTN", "Depression")]

MyData.HaveFitbit <- MyData[MyData$Insurance   != "NULL" & 
                              MyData$HaveEmail  == "Yes" & 
                              MyData$HaveFitbit == "NULL" & 
                              MyData$Gdr_Cd     != "NULL" & 
                              MyData$AgeBand    != "NULL" ,]

#FI
ggplot() + 
  geom_bar(data=MyData.HaveFitbit, aes(y = HasFitbit, x = AgeBand, fill = factor(AgeBand)), 
           stat = "identity", position = position_stack(reverse = TRUE)) +
  facet_grid( ~ Insurance + Gdr_Cd)  + 
  labs(x = "We have their email address", y = "Member Count (000s)", title = "By Insurance, By Gender", fill = "Age Band")


ggplot() + 
  geom_bar(data=MyData.HaveFitbit, aes(y = PMPM, x = Insurance, fill = factor(AgeBand)), stat = "identity", position = "dodge") +
  scale_y_continuous(label=dollar_format()) +
  #theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "We have their email address", y = "Member Share", title = "Members with diagnoses related to conditions in 2017: Fully Insured", fill = "Have Email")

#ASO
ggplot() + 
  geom_bar(data=MyData.Cond.ASO, aes(y = PMPM, x = Insurance + Gdr_Cd, fill = factor(AgeBand)), stat = "identity", position = "dodge") +
  scale_y_continuous(label=percent_format()) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "We have their email address", y = "Member Share", title = "Members with diagnoses related to conditions in 2017: ASO", fill = "Have Email")

setwd("//nasv0404/ssdpnas_users/Users/sgrossinger/AdHoc/FitBitMatchData")
rmarkdown::render('create report with graphics in R.Rmd',
                  output_file = 'Members_with_Fitbits.html')
