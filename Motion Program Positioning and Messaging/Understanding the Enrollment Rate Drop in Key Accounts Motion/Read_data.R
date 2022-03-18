# Code for reading and formatting data for Understanding the Enrollment Rate Drop in Key Account Motion grant 

# Created by: Joyvalerie Mondejar 
# Date created: 12/07/2018 
# Last updated: 2/5/2019 

# Inputs: pdb_MotionEnrollmentEngagement.dbo.KA_Motion_Enr_DropRate (on DBSEP3832 server inside NGIS) 
# Inputs: pdb_MotionEnrollmentEngagement.dbo.KA_Motion_Enr_DropRate_201807 (on DBSEP3832 server inside NGIS) 
# Code for Key Account Motion data
library(data.table)
library(ggplot2)
library(RODBC)
library(zoo)
library(lubridate)

# All the files used here should be in the current working directory; use 'setwd()' before
# running this code.
rm(list = ls())

db <- odbcConnect("dbsep3832")

enrich <- function(dat) {
  dat[, `:=`(Gdr_Cd, factor(Gdr_Cd))]
  dat[, `:=`(Year_Mo, as.integer(Year_Mo))]
  dat[, `:=`(c("IP_Allw_Amt", "OP_Allw_Amt", "DR_Allw_Amt", "Rx_Allw_Amt", "ER_Allw_Amt", 
               "Total_Allw_Amt", "Med_Income", "Total_Incentive", "Adjustment_Incentive", "RAF_Score"), 
             lapply(.SD, as.numeric)), .SDcols = c("IP_Allw_Amt", "OP_Allw_Amt", "DR_Allw_Amt", "Rx_Allw_Amt", 
                                                   "ER_Allw_Amt", "Total_Allw_Amt", "Med_Income", "Total_Incentive", 
                                                   "Adjustment_Incentive", "RAF_Score")]
  dat[, `:=`(c("Cnt_Active", "Cnt_FIT", "Cnt_F", "Cnt_I", "Cnt_T"), lapply(.SD, as.integer)), 
      .SDcols = c("Cnt_Active", "Cnt_FIT", "Cnt_F", "Cnt_I", "Cnt_T")]
  dat[, `:=`(c("T2D_Flag", "Hypertension_Flag", "Dep_Anx_Flag", "COPD_Flag", "CHF_Flag", "RA_Flag", "ChronicPain_Flag"),
             lapply(.SD, as.character)), .SDcols = c("T2D_Flag", "Hypertension_Flag", "Dep_Anx_Flag", "COPD_Flag", 
                                                     "CHF_Flag", "RA_Flag", "ChronicPain_Flag")]
  dat[, `:=`(Sbscr, factor(Sbscr_Ind, levels = 0:1, labels = c("Dependent", "Subscriber")))]
  dat[, `:=`(USR_Ind, factor(USR_Ind, levels = c("U", "S", "R", NA)))]
  dat[, `:=`(Year_Mo_Enrollment, as.integer(Year_Mo_Enrollment))]
  dat[, `:=`(Mo_Enroll_Flg, as.numeric(Mo_Enroll_Flg))]
  dat[, `:=`(Enroll_Flag, ifelse(!is.na(Year_Mo_Enrollment), 1, 0))]
  dat[, `:=`(ActiveFlag_YrMo, as.numeric(ActiveFlag_YrMo))]
  dat[, `:=`(c("Year", "Month"), .(substr(Year_Mo, 1, 4), substr(Year_Mo, 5, 6)))]
  dat[, `:=`(Year_Mo_, paste(Year, Month, sep = "-"))]
  dat[, `:=`(Year_Mo_, as.yearmon(Year_Mo_))]
  
}

data_all <- data.table(sqlQuery(db, "select * from pdb_MotionEnrollmentEngagement.dbo.KA_Motion_Enr_DropRate_201807", 
                                as.is = TRUE))
setkeyv(data_all, c("Indv_Sys_ID", "ComEnrld_Yr_Mo", "Year_Mo", "Cnt_Active", "Year_Mo_Enrollment"))
dim(data_all)  # 465758     43
dim(unique(data_all, by = c("Indv_Sys_ID", "Year_Mo")))  #  463815     43

data_all[is.na(ComEnrld_Yr_Mo), .N]  # 74142
data_all[is.na(Year_Mo), .N]  #   2395
data_all[is.na(Year_Mo_Enrollment), .N]  #  Now  232866

mm <- enrich(data_all)
all.equal(mm$Mo_Enroll_Flg, mm$Enroll_Flag)


# -------------------------------------------- Investigate duplicates------------------------------------- 
# Number of rows that have duplicates
dim(mm) - dim(unique(mm, by = c("Indv_Sys_ID", "Year_Mo")))  # 1943    
# Number of unique individuals in the whole table
dim(unique(mm, by = c("Indv_Sys_ID")))

# Group 1: Members of employers eligible for Key Account Motion program in July 2017. 
#          Got their monthly data going back to July 2016.  
# Group 2: Members of employers eligible for Key Account Motion program in July 2018. 
#          Got their monthly data going back to July 2016.
# Number of unique individuals in population 1
dim(unique(mm[Group1_Flag == 1 & Year_Mo == 201707 & !is.na(ComEnrld_Yr_Mo)], by = c("Indv_Sys_ID")))
dim(unique(mm[Group1_Flag == 1 & !is.na(ComEnrld_Yr_Mo)], by = c("Indv_Sys_ID")))

# Number of unique individuals in population 2
dim(unique(mm[Group2_Flag == 1 & Year_Mo == 201807 & !is.na(ComEnrld_Yr_Mo)], by = c("Indv_Sys_ID")))
dim(unique(mm[Group2_Flag == 1 & !is.na(ComEnrld_Yr_Mo)], by = c("Indv_Sys_ID")))

# count of individuals that have duplicates (UHC enrolled, motion eligible, but different
# motion enrolled flag) mm[,.N, keyby = .(Groups, Year_Mo, Indv_Sys_ID)][N > 1][!is.na(Year_Mo)]
mm[!is.na(ComEnrld_Yr_Mo) & Group1_Flag == 1, .N, 
   keyby = .(Group1_Flag, Year_Mo, Indv_Sys_ID)][N > 1][, .N, Indv_Sys_ID]  # 1 IDs

mm[!is.na(ComEnrld_Yr_Mo) & Group2_Flag == 1, .N, 
   keyby = .(Group2_Flag, Year_Mo, Indv_Sys_ID)][N > 1][, .N, Indv_Sys_ID]  # 6 IDs with 32 records
# -------------------------------------------- Investigate duplicates-------------------------------------

# ============================================= Clean data and remove duplicates ================================

# The following were removed:

# * Those individuals not enrolled in UHC
# * Row records which do not belong to either groups
# * Members not associated with Key Account motion
# * We also suspected that members younger than 18 years old are not eligible to Key Account motion program.
# * Duplicates

mm[!is.na(ComEnrld_Yr_Mo) & (!is.na(Group1_Flag | !is.na(Group2_Flag))) & KA_Flag == 1 & Age > 
     18, `:=`(IDyrmo, paste(Indv_Sys_ID, Year_Mo, sep = "")), by = c("Indv_Sys_ID", "Year_Mo")]

# Count of row duplicates
tmp1 = mm[!is.na(ComEnrld_Yr_Mo) & Group1_Flag == 1 & KA_Flag == 1 & Age > 18, .N, 
          keyby = .(Indv_Sys_ID, Year_Mo, IDyrmo)][N > 1]  # 4 row duplicates in Grp 1
tmp2 = mm[!is.na(ComEnrld_Yr_Mo) & Group2_Flag == 1 & KA_Flag == 1 & Age > 18, .N, 
          keyby = .(Indv_Sys_ID, Year_Mo, IDyrmo)][N > 1]  # 25 row duplicates in Grp 2

# getting the 2nd row record among those with duplicates in Group 1
tmp1_ = mm[IDyrmo %in% tmp1$IDyrmo]  # # 8 rows with duplicates
tmp1__ = tmp1_[which(duplicated(tmp1_$IDyrmo, fromLast = TRUE) == FALSE)]  # cleaned  4 rows

# getting the 2nd row record among those with duplicates in Group 2
tmp2_ = mm[IDyrmo %in% tmp2$IDyrmo]
tmp2_ = tmp2_[Indv_Sys_ID != 1381674208]
tmp2__ = tmp2_[which(duplicated(tmp2_$IDyrmo, fromLast = TRUE) == FALSE)]  # 21 rows
tmp2__ = tmp2__[!is.na(Year_Mo_Enrollment)]  # 21 rows

tmp_ = rbind(tmp1_, tmp2_)  # 54 rows
tmp__ = rbind(tmp1__, tmp2__)  # 25 rows

mm_without_dup = mm[IDyrmo %in% tmp1$IDyrmo | IDyrmo %in% tmp2$IDyrmo]  # 54 rows

# removed from mm those duplicates
mm = mm[!IDyrmo %in% mm_without_dup$IDyrmo]
mm = rbind(mm, tmp__)  # 465729     49

# removed those not enrolled in a UHC plan
mm = mm[!is.na(ComEnrld_Yr_Mo)]  # 391587     49

# removed those without any group
mm = mm[!(is.na(Group1_Flag) & is.na(Group2_Flag))]  # 389192     49

# removed those not with Key account motion flag
mm = mm[KA_Flag == 1]  # 359530     49

# removed 13 Individuals
mm = mm[Age >= 18]  # 359492     49
setkeyv(mm, c("Indv_Sys_ID", "Year_Mo"))
# ============================================= Clean data and remove duplicates ================================

# ============================================= Finalize data =================================================== 

# * Those individuals not enrolled in UHC
# * Row records which do not belong to either groups
# * Members not associated with Key Account motion
# * We also suspected that members younger than 18 years old are not eligible to Key Account motion program.
# * Duplicates

mm[, `:=`(Med_Income, ifelse(Med_Income == 0, NA, Med_Income))]
mm[, `:=`(Med_Income_log, log(Med_Income))]
mm[Gdr_Cd == "U", `:=`(Gdr_Cd, NA)]
mm[, `:=`(Gdr_Cd, factor(Gdr_Cd))]
mm[, `:=`(RAF_Score, ifelse(RAF_Score == 0, NA, RAF_Score))]
mm[IP_Allw_Amt < 0 | is.na(IP_Allw_Amt), `:=`(IP_Allw_Amt, 0)]
mm[OP_Allw_Amt < 0 | is.na(OP_Allw_Amt), `:=`(OP_Allw_Amt, 0)]
mm[DR_Allw_Amt < 0 | is.na(DR_Allw_Amt), `:=`(DR_Allw_Amt, 0)]
mm[Rx_Allw_Amt < 0 | is.na(Rx_Allw_Amt), `:=`(Rx_Allw_Amt, 0)]
mm[ER_Allw_Amt < 0 | is.na(ER_Allw_Amt), `:=`(ER_Allw_Amt, 0)]
mm[Total_Allw_Amt < 0 | is.na(Total_Allw_Amt), `:=`(Total_Allw_Amt, 0)]

mm[, `:=`(UHC_Enroll_Flag, ifelse(!is.na(ComEnrld_Yr_Mo), 1, 0))]
all.equal(mm$UHC_Enroll_Flag, mm$Cont_Enroll_Flag)
# mm[Group1_Flag == 1 & Year_Mo <= 201707, UHC_Enr_Mos1 := sum(UHC_Enroll_Flag), by =
# .(Indv_Sys_ID)] mm[Group2_Flag == 1 & Year_Mo >= 201707, UHC_Enr_Mos2 :=
# sum(UHC_Enroll_Flag), by = .(Indv_Sys_ID)]
mm[Group1_Flag == 1 & Year_Mo <= 201707, .(Max = max(UHC_Enr_Mos1)), by = Indv_Sys_ID][Max == 13, .N]  # 865
mm[Group2_Flag == 1 & Year_Mo >= 201707, .(Max = max(UHC_Enr_Mos2)), by = Indv_Sys_ID][Max == 13, .N]  # 7628

# mm[Indv_Sys_ID == 17866937,.(Indv_Sys_ID,Group1_Flag, Group2_Flag, Cont_Enroll_Flag, ComEnrld_Yr_Mo,
#                              UHC_Enroll_Flag, UHC_Enr_Mos1, UHC_Enr_Mos2)]

# ============================================= Finalize data ===================================================

# save(mm, file = "Data/mm.rda")
odbcClose(db)
toretain = ls()[ls()!= "mm"]
rm(list=toretain)





# End script