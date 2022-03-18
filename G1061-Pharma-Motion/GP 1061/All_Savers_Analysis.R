
### read in the data for 
all_savers_member <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.Member where Cont_Enrl = 1 and Age >= 18")
all_savers_member_summary <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.MemberSummary")
all_savers_member_summary_cont <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.MemberSummary_cont")
all_savers_drugs <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.tmp_DrugClassCnt_unpivot")
all_savers_member_months <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.tmp_MbrMos")

### Drug Summary

all_savers_drugs <- all_savers_drugs[all_savers_drugs$MemberID %in% all_savers_member$MemberID,]

library(data.table)
library(plyr)

count_per_drug = aggregate(x = all_savers_drugs[c("Cnt")], by = list(Drug_Class = all_savers_drugs$DrugClass), FUN = sum, na.rm = TRUE)
member_per_drug = ddply(all_savers_drugs,~DrugClass,summarise,number_of_distinct_members=length(unique(MemberID)))
claims_count = ddply(all_savers_drugs,~DrugClass,summarise,count_of_claims=length(MemberID))

### Member Summary

library(ggplot2)
table(all_savers_member$Gender)

summary(all_savers_member$Age)
hist(all_savers_member$Age, xlab = "Age", main = "All Savers Members' Age Distribution")

summary(all_savers_member$Age[all_savers_member$Gender=="M"])
ggplot(all_savers_member, aes(Age, fill = Gender)) + geom_bar(pos="dodge")

summary(all_savers_member$Age[all_savers_member$Motion == 1])
all_savers_member$Motion <- as.character(all_savers_member$Motion)
ggplot(all_savers_member, aes(Age, fill = Motion)) + geom_bar(pos="dodge")

table(all_savers_member$Motion[all_savers_member$Gender=="M"])

