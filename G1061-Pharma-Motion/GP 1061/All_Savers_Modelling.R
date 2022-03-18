### read in the data for modelling
all_data <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.MemberSummary_v2") 

before_enrollment_data <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.MemberSummary_v2 where PlcyEnrlMotion_MonthInd  < 0 and Enrl_Plan = 1")

after_enrollment_data <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.MemberSummary_v2 where PlcyEnrlMotion_MonthInd > 0 and Enrl_Plan = 1")

demographics <- read.odbc("Devsql10", dbQuery = "select * from pdb_PharmaMotion.dbo.Member_v2")
### get top 10 drugs base on member counts

drug_cols = c("Analgesic_Antihistamine_Combination",
              "Analgesics",
              "Anesthetics",
              "AntiObesityDrugs",
              "Antiarthritics",
              "Antiasthmatics",
              "Antibiotics",
              "Anticoagulants",
              "Antidotes",
              "AntiFungals",
              "Antihistamine_Decongestant_Combination",
              "Antihistamines",
              "Antihyperglycemics",
              "Antiinfectives",
              "AntiinfectivesMiscellaneous",
              "Antineoplastics",
              "AntiparkinsonDrugs",
              "AntiplateletDrugs",
              "Antivirals",
              "AutonomicDrugs",
              "Biologicals",
              "Blood",
              "CardiacDrugs",
              "Cardiovascular",
              "CNSDrugs",
              "ColonyStimulatingFactors",
              "Contraceptives",
              "CoughColdPreparations",
              "Diagnostic",
              "Diuretics",
              "EENTPreps",
              "ElectCaloricH2O",
              "Gastrointestinal",
              "Herbals",
              "Hormones",
              "Immunosuppresant",
              "MiscMedicalSuppliesDevicesNondrug",
              "MuscleRelaxants",
              "PreNatalVitamins",
              "PhyscotherapeuticDrugs",
              "SedativeHypnotics",
              "SkinPreps",
              "SmokingDeterrents",
              "ThyroidPreps",
              "Vitamins"
)

member_drug = aggregate(x = all_data[c(drug_cols)], by = list(MemberID = all_data$MemberID), FUN = sum, na.rm = TRUE)

member_drug2 = member_drug

for (drug in drug_cols){
  member_drug2[[drug]] <- with(member_drug2, ifelse(member_drug2[[drug]] >= 1, 1, 0))
}

member_count_per_drug = colSums(member_drug2[drug_cols])
member_count_per_drug = data.table(names = names(member_count_per_drug), member_count_per_drug)

top10_drug_cols = c("Antiinfectives",
                    "Antibiotics",
                    "Analgesics",
                    "Hormones",
                    "Cardiovascular",
                    "PhyscotherapeuticDrugs",
                    "Gastrointestinal",
                    "Antiarthritics",
                    "EENTPreps",
                    "SkinPreps"
)

### Modelling with top 10 drug classes
new_member_drug = aggregate(x = before_enrollment_data[c(drug_cols)], by = list(MemberID = before_enrollment_data$MemberID), FUN = sum, na.rm = TRUE)
new_member_drug2 = new_member_drug

for (drug in drug_cols){
  new_member_drug2[[drug]] <- with(new_member_drug2, ifelse(new_member_drug2[[drug]] >= 1, 1, 0))
}

member_top10_drugs = new_member_drug2[c("MemberID", top10_drug_cols)]

member_motion_enrollment = aggregate(x = after_enrollment_data[c("Enrl_Motion")], by = list(MemberID = after_enrollment_data$MemberID), FUN = max, na.rm = TRUE)

member_data = merge(member_top10_drugs, member_motion_enrollment, by = c("MemberID"))

member_data$total_drug_class <- rowSums(member_data[top10_drug_cols])

### Add demographics

dem_cols = c("MemberID","Age", "Gender", "Zip")
dem_data = demographics[dem_cols]
member_data = merge(member_data, dem_data, by = c("MemberID"))

### Select 18 years old and above

member_data = member_data[member_data$Age>=18,]

### Set binary variables as factors

member_data = mutate(member_data, Enrl_Motion = as.factor(Enrl_Motion))
member_data = mutate(member_data, Antiinfectives = as.factor(Antiinfectives))
member_data = mutate(member_data, Antibiotics = as.factor(Antibiotics))
member_data = mutate(member_data, Analgesics = as.factor(Analgesics))
member_data = mutate(member_data, Hormones = as.factor(Hormones))
member_data = mutate(member_data, Cardiovascular = as.factor(Cardiovascular))
member_data = mutate(member_data, PhyscotherapeuticDrugs = as.factor(PhyscotherapeuticDrugs))
member_data = mutate(member_data, Gastrointestinal = as.factor(Gastrointestinal))
member_data = mutate(member_data, EENTPreps = as.factor(EENTPreps))
member_data = mutate(member_data, Antiarthritics = as.factor(Antiarthritics))
member_data = mutate(member_data, SkinPreps = as.factor(SkinPreps))

# with(member_data, cdplot(Enrl_Motion~Antiinfectives))
# with(member_data, cdplot(Enrl_Motion~Cardiovascular))
# with(member_data, cdplot(Enrl_Motion~Analgesics))
# with(member_data, cdplot(Enrl_Motion~PhyscotherapeuticDrugs))
# with(member_data, cdplot(Enrl_Motion~Antibiotics))
# with(member_data, cdplot(Enrl_Motion~Hormones))
# with(member_data, cdplot(Enrl_Motion~Gastrointestinal))
# with(member_data, cdplot(Enrl_Motion~Antiarthritics))
# with(member_data, cdplot(Enrl_Motion~EENTPreps))
# with(member_data, cdplot(Enrl_Motion~SkinPreps))
# 
# with(member_data, boxplot(Enrl_Motion~Antiinfectives))
# with(member_data, boxplot(Enrl_Motion~Cardiovascular))
# with(member_data, boxplot(Enrl_Motion~Analgesics))
# with(member_data, boxplot(Enrl_Motion~PhyscotherapeuticDrugs))
# with(member_data, boxplot(Enrl_Motion~Antibiotics))
# with(member_data, boxplot(Enrl_Motion~Hormones))
# with(member_data, boxplot(Enrl_Motion~Gastrointestinal))
# with(member_data, boxplot(Enrl_Motion~Antiarthritics))
# with(member_data, boxplot(Enrl_Motion~EENTPreps))
# with(member_data, boxplot(Enrl_Motion~SkinPreps))

### Demographics

### Member Summary

library(ggplot2)
table(member_data$Gender[member_data$Enrl_Motion == 1])
table(member_data$Gender[member_data$Enrl_Motion == 0])

summary(member_data$Age[member_data$Gender=="M"])
summary(member_data$Age[member_data$Gender=="F"])
ggplot(member_data, aes(Age, fill = Gender)) + geom_bar(pos="dodge")

summary(member_data$Age[member_data$Enrl_Motion == 1])
summary(member_data$Age[member_data$Enrl_Motion == 0])
member_data$Enrl_Motion <- as.character(member_data$Enrl_Motion)
ggplot(member_data, aes(Age, fill = Enrl_Motion)) + geom_bar(pos="dodge")

### Predictors are the top 10 drugs in binary format whether the members took them or not.
model1 = glm(Enrl_Motion ~ Antiinfectives
             + Antibiotics
             + Analgesics
             + Hormones
             + Cardiovascular
             + PhyscotherapeuticDrugs
             + Gastrointestinal
             + Antiarthritics
             + EENTPreps
             + SkinPreps
             , family = binomial(link = "logit"), data = member_data)

summary(model1)

with(member_data, cdplot(Enrl_Motion~total_drug_class))
with(member_data, boxplot(Enrl_Motion~total_drug_class))

### Predictor is the total count of unique drug classes the members took.
model2 = glm(Enrl_Motion ~ total_drug_class, family = binomial(link = "logit"), data = member_data)

summary(model2)

### Predictors are the top 10 drug classes' total number taken by each memeber

new_member_top10_drugs = new_member_drug[c("MemberID", top10_drug_cols)]
new_member_data = merge(new_member_top10_drugs, member_motion_enrollment, by = c("MemberID"))

### Add demographics
new_member_data = merge(new_member_data, dem_data, by = c("MemberID"))

model3 = glm(Enrl_Motion ~ Antiinfectives
             + Antibiotics
             + Analgesics
             + Hormones
             + Cardiovascular
             + PhyscotherapeuticDrugs
             + Gastrointestinal
             + Antiarthritics
             + EENTPreps
             + SkinPreps
             , family = binomial(link = "logit"), data = new_member_data)

summary(model3)

### Predictors are the top 10 drugs in binary format whether the members took them or not + age and gender.
model4 = glm(Enrl_Motion ~ Antiinfectives
             + Antibiotics
             + Analgesics
             + Hormones
             + Cardiovascular
             + PhyscotherapeuticDrugs
             + Gastrointestinal
             + Antiarthritics
             + EENTPreps
             + SkinPreps
             + Age
             + Gender
             , family = binomial(link = "logit"), data = member_data)

summary(model4)

with(member_data, cdplot(Enrl_Motion~total_drug_class))
with(member_data, boxplot(Enrl_Motion~total_drug_class))

### Predictor is the total count of unique drug classes the members took + age and gender.
model5 = glm(Enrl_Motion ~ total_drug_class + Age + Gender, family = binomial(link = "logit"), data = member_data)

summary(model5)

### Check for correlated variables

matrix_cols = c("Age", "Gender", top10_drug_cols)
matrix_continuous =  new_member_data[matrix_cols]
matrix_continuous = mutate(matrix_continuous, Gender = as.integer(ifelse(Gender == "M", 1, 0)))
cor(matrix_continuous, method = c("pearson"))
matrix_binary =  member_data[matrix_cols]
matrix_binary = mutate(matrix_binary, Gender = as.integer(ifelse(Gender == "M", 1, 0)))
matrix_binary$Antiinfectives = as.integer(matrix_binary$Antiinfectives)
matrix_binary$Antibiotics = as.integer(matrix_binary$Antibiotics)
matrix_binary$Analgesics = as.integer(matrix_binary$Analgesics)
matrix_binary$Hormones = as.integer(matrix_binary$Hormones)
matrix_binary$Cardiovascular = as.integer(matrix_binary$Cardiovascular )
matrix_binary$PhyscotherapeuticDrugs = as.integer(matrix_binary$PhyscotherapeuticDrugs)
matrix_binary$Gastrointestinal = as.integer(matrix_binary$Gastrointestinal)
matrix_binary$EENTPreps = as.integer(matrix_binary$EENTPreps )
matrix_binary$Antiarthritics = as.integer(matrix_binary$Antiarthritics)
matrix_binary$SkinPreps = as.integer(matrix_binary$SkinPreps)
cor(matrix_binary, method = c("spearman"))

##################################################

### Principal Component Analysis

continuous_drugs = aggregate(x = allsavers_data[c(drug_cols)], by = list(MemberID = allsavers_data$MemberID), FUN = sum, na.rm = TRUE)

binary_drugs = continuous_drugs

for (drug in drug_cols){
  binary_drugs[[drug]] <- with(binary_drugs, ifelse(binary_drugs[[drug]] >= 1, 1, 0))
}

# motion_enrollment = aggregate(x = allsavers_data[c("Enrl_Motion")], by = list(MemberID = allsavers_data$MemberID), FUN = max, na.rm = TRUE)
# 
# continuous_drugs = merge(continuous_drugs, motion_enrollment, by = c("MemberID"))
# 
# binary_drugs = merge(binary_drugs, motion_enrollment, by = c("MemberID"))
# 
# continuous_drugs = mutate(continuous_drugs, Enrl_Motion = as.factor(ifelse(Enrl_Motion == 1, "Yes", "No")))
# 
# binary_drugs = mutate(binary_drugs, Enrl_Motion = as.factor(ifelse(Enrl_Motion == 1, "Yes", "No")))
# 
# continuous_motion <- factor(continuous_drugs$Enrl_Motion)
# 
# binary_motion <- factor(binary_drugs$Enrl_Motion)

# Perform PCA
myPCA_continuous <- prcomp(continuous_drugs[,-1,-47], scale. = F, center = F)
myPCA_binary <- prcomp(binary_drugs[,-1,-47], scale. = F, center = F)
# myPCA$rotation # loadings
# myPCA$x # scores

# Perform SVD
mySVD_continuous <- svd(continuous_drugs)
mySVD_binary <- svd(binary_drugs)
# mySVD # the diagonal of Sigma mySVD$d is given as a vector
# sigma <- matrix(0,4,4) # we have 4 PCs, no need for a 5th column
# diag(sigma) <- mySVD$d # sigma is now our true sigma matrix
# 
# # Compare PCA scores with the SVD's U*Sigma
# theoreticalScores <- mySVD$u %*% sigma
# all(round(myPCA$x,5) == round(theoreticalScores,5)) # TRUE
# 
# # Compare PCA loadings with the SVD's V
# all(round(myPCA$rotation,5) == round(mySVD$v,5)) # TRUE
# 
# # Show that mat == U*Sigma*t(V)
# recoverMatSVD <- theoreticalScores %*% t(mySVD$v)
# all(round(mat,5) == round(recoverMatSVD,5)) # TRUE
# 
# #Show that mat == scores*t(loadings)
# recoverMatPCA <- myPCA$x %*% t(myPCA$rotation)
# all(round(mat,5) == round(recoverMatPCA,5)) # TRUE
##################################################

### DRUG USE BEFORE AND AFTER ENROLLMENT IN MOTION

#EnrlMotion_MonthInd
