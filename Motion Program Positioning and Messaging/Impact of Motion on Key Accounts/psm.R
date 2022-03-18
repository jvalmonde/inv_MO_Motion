library(bigrquery)
library(tidyverse)
library(MatchIt)

options("httr_oauth_cache"="~/.httr-oauth", httr_oob_default = TRUE)

dat_2018 <- query_exec("SELECT * FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_join", 
                       project = "research-00", 
                       use_legacy_sql = FALSE, 
                       max_pages = Inf)

dat_2018_age18 <- dat_2018[dat_2018$Age >= 19,]

dat_2018_comp <- dat_2018_age18[complete.cases(dat_2018_age18),]

dat_2018_comp$MotionEnr <- ifelse(dat_2018_comp$MotionElig == 1 & dat_2018_comp$TotalSteps > 0, 1, 0)

table(dat_2018_comp$MotionElig)
table(dat_2018_comp$MotionElig, dat_2018_comp$MotionEnr)

match_elig <- matchit(MotionElig ~ SilverTotalScore + Age + Gdr_Cd + ST_ABBR_CD + grp_size_desc + MM, 
        data = dat_2018_comp,
        ratio = 2)

save(match_elig, file = "motion_ka_match_elig.RData")

match_enr <- matchit(MotionEnr ~ SilverTotalScore + Age + Gdr_Cd + ST_ABBR_CD + grp_size_desc + MM, 
                      data = dat_2018_comp[dat_2018_comp$MotionElig == 0 | dat_2018_comp$MotionEnr == 1,],
                     ratio = 2)

save(match_enr, file = "motion_ka_match_enr.RData")


summary(match_elig)

summary(match_enr)

dat_match_elig <- match.data(match_elig)

dat_match_enr <- match.data(match_enr)


dat_match_elig %>%
  group_by(MotionElig) %>%
  summarise(N = n(),
            total_allw_mean = mean(total_allw),
            total_allw_sd = sd(total_allw),
            admit_cnt_mean = mean(admit_cnt),
            admit_cnt_sd = sd(admit_cnt),
            vst_cnt_mean = mean(vst_cnt),
            vst_cnt_sd = sd(vst_cnt),
            scrpt_cnt_mean = mean(scrpt_cnt),
            scrpt_cnt_sd = sd(scrpt_cnt)) %>%
  as.data.frame()

dat_match_enr %>%
  group_by(MotionEnr) %>%
  summarise(N = n(),
            total_allw_mean = mean(total_allw),
            total_allw_sd = sd(total_allw),
            admit_cnt_mean = mean(admit_cnt),
            admit_cnt_sd = sd(admit_cnt),
            vst_cnt_mean = mean(vst_cnt),
            vst_cnt_sd = sd(vst_cnt),
            scrpt_cnt_mean = mean(scrpt_cnt),
            scrpt_cnt_sd = sd(scrpt_cnt)) %>%
  as.data.frame()


t.test(dat_match_elig$total_allw[dat_match_elig$MotionElig == 0],
       dat_match_elig$total_allw[dat_match_elig$MotionElig == 1])

t.test(dat_match_enr$scrpt_cnt[dat_match_enr$MotionEnr == 0],
       dat_match_enr$scrpt_cnt[dat_match_enr$MotionEnr == 1])
