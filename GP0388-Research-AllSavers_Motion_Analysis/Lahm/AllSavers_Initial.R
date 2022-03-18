library(dplyr)

# Initial look at All Savers tables

data <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                  FROM dbo.MemberSummary", as.is = TRUE)
data$Enrollment_DT <- as.Date(data$Enrollment_DT)

length(unique(data$Member_DIMID))   # 313,890
length(unique(data$FamilyID))       # 188,428
length(unique(data$PolicyID))       # 6,883

table(data$Gender)
table(data$State)
min(data$Enrollment_DT)             # 1-1-2014
max(data$Enrollment_DT)             # 9-1-2016

summary(data$Age)
summary(data$MM)


data <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                  FROM dbo.memberClaimDetailYY", as.is = TRUE)
data <- data %>% mutate_each(funs(as.numeric), RX_AllwAmt:AllwAmt)
data$PMPM <- data$AllwAmt/data$MM_Year

summary(data$Year)
table(data$ClaimYear)

summary(data[data$ClaimYear == 2014, "PMPM"])
summary(data[data$ClaimYear == 2015, "PMPM"])
summary(data[data$ClaimYear == 2016, "PMPM"])
sum(data[data$ClaimYear == 2014, "PMPM"] < 0) # 1 
sum(data[data$ClaimYear == 2015, "PMPM"] < 0) # 1
sum(data[data$ClaimYear == 2016, "PMPM"] < 0) # 4

data <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                  FROM dbo.groupDetailYY", as.is = TRUE)
