# Created by: Joyvalerie Mondejar 
# Date created: 12/07/2018 
# Last updated: 2/6/2019 


library(data.table)
library(ggplot2)
library(grid)
library(gridExtra)
library(kableExtra)
library(htmlTable)
library(knitr)
library(plotly)
library(scales)
library(stats)
library(qwraps2)
library(tableone)
library(arsenal)
library(boot)
library(tidyverse)
library(outliers)
library(effsize)
library(pwr)

padding <- function(pad) paste0("padding-left: ", pad, "em; padding-right: ", pad, "em;")

theme_update(text = element_text(size = 15))

kableone <- function(x, ...) {
  capture.output(x <- print(x))
  knitr::kable(x, ...)
}


# Function to plot RAF scores
plot_raf <- function(data, enroll_flag = "N") {
  
  if(enroll_flag == "Y") {
    data = data[Enroll_Flag == 1]
    
  }
  
  else if(enroll_flag == "N") {
  
  }
  
  tmp_pop1 = data[Group == "July 2017",.(RAF_Score, Group)]
  tmp_pop2 = data[Group == "July 2018" & !is.na(RAF_Score),.(RAF_Score, Group)]
  tmp_pop = rbind(tmp_pop1, tmp_pop2)
  dim(tmp_pop)
  
    ggplot(tmp_pop, aes(x = RAF_Score, fill = Group)) + 
    geom_histogram(bins = 30, 
                   aes(y = stat(width*density)), 
                   position = "identity", alpha = 0.6) +  
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    ylab("Percentage") + xlab("RAF Score") +
    scale_fill_manual(values = c(uhg1, uhg2)) +
    theme_joy_single + guides(fill = guide_legend(title = NULL))
  
}
# sample
# plot_raf(data = pop, enroll_flag = "N")


# Function to create new data of spending having the columns of mean and the confidence interval limits
# Year_Mo_, Category, Mean, Lower, Upper
# The return output will be used to plot the column bars of spend
# data = copy(pop)
pop_spend <- function(data, enroll_flag = "N") {
  
  if(enroll_flag == "Y") {
    data = data[Enroll_Flag == 1]
  }
  
  else if(enroll_flag == "N") {
    
  }
  
  IP_cat = data[,.(IP = mean_ci(IP_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  OP_cat = data[,.(OP = mean_ci(OP_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  DR_cat = data[,.(DR = mean_ci(DR_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  Rx_cat = data[,.(Rx = mean_ci(Rx_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  ER_cat = data[,.(ER = mean_ci(ER_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  Total_cat = data[,.(Total = mean_ci(Total_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  
  Spend_cat = cbind(IP_cat, OP_cat, DR_cat, Rx_cat, ER_cat, Total_cat)
  Spend_cat = Spend_cat[,.(Year_Mo_, IP, OP, DR, Rx, ER, Total, stat)]
  Spend_cat_melt = melt(Spend_cat, id.vars = c('Year_Mo_', 'stat'),
                        measure.vars = c('IP', 'OP', 'DR', 'Rx', 'ER', 'Total'),
                        variable.name = "Category")
  Spend_cat_wide = dcast(Spend_cat_melt, Year_Mo_ + Category ~ stat, value.var = "value")
  
  return(Spend_cat_wide)
}
# sample
# Spend_cat_melt = pop_spend(data = pop, enroll_flag = "N")


# Function to create new list of dataframes for the spending variables

"
  Parameters:
  data: the data the members will be taken from
  columns: Vector of desired columns to calculate effect size. Examples: IP_Allw_Amt, Total_Allw_Amt
  strata: a grouping variable
  percentile: If you want to remove outliers, you need to place your desired percentile rank above 
              which the outliers will be removed. percentile == 1 does not remove any outlier
  "
wo_extreme_func <- function(data, columns = NULL, strata = NULL, percentile = 1) {
  new_data <- list()
  for(i in 1:length(columns)) {
    a1 = data %>% 
      filter(Year_Mo_ ==  "July 2017") %>% 
      select(columns[i], strata) %>% 
      drop_na()
    a1$out = scores(a1[,1], type= "t", prob = percentile)
    a1 = a1 %>% filter(out == FALSE)
    
    a2 = data %>% 
      filter(Year_Mo_ == "July 2018") %>% 
      select(columns[i], strata) %>% 
      drop_na()
    a2$out = scores(a2[,1], type = "t", prob = percentile)
    a2 = a2 %>% filter(out == FALSE)
    new_dat = rbind(a1 ,a2)
    new_dat[,2] = as.factor(new_dat[,2])
    new_data[[i]] = new_dat
  }
  names(new_data) = columns
  return(new_data)
  
}

# Function to provide effect size for numerical variables. 
# It has the options to remove extreme normalized values or not. 
# percentile == 1 does not remove any outlier
  "
  Parameters:
  data: the data the members will be taken from
  columns: Vector of desired columns to calculate effect size. Examples: IP_Allw_Amt, Total_Allw_Amt
  strata: a grouping variable
  remove_outlier: Remove outliers if it is 'Y' or does not remove outlier if it is 'N'. Default value is 'Y'
  percentile: If you want to remove outliers, you need to place your desired percentile rank above 
              which the outliers will be removed
  "
effectsize_func <- function(data, columns = NULL, strata = NULL, percentile = 1, remove_outlier = "Y") {
  effectsize_tab <- data.table()
  
  if(remove_outlier == "Y") {
    new_pop <- wo_extreme_func(data = data, columns = columns, strata = strata, 
                               percentile = percentile)
    for(i in 1:length(new_pop)) {
      
      effect_size = cohen.d(new_pop[[i]][,1], new_pop[[i]][,2], hedges.correction = TRUE, na.rm = TRUE)
      effect_size_estimate = tibble(Variable = names(new_pop[i]), 
                                    # Observed_diff = mean(new_pop)
                                    Estimate = abs(effect_size$estimate), 
                                    Magnitude = effect_size$magnitude)
      
      effectsize_tab = rbind(effectsize_tab, effect_size_estimate)
    }
    return(effectsize_tab)
  }
  
  else if(remove_outlier == "N") {
    for(i in 1:length(columns)) {
      
      a = data %>% 
        select(strata, columns[i]) %>% 
        drop_na() 
      a[,Year_Mo_ := as.factor(Year_Mo_)]
      a = data.frame(a)
      effect_size = cohen.d(a[,2], a[,1], hedges.correction = TRUE, na.rm = TRUE)
      effect_size_estimate = tibble(Variable = columns[i], 
                                    Estimate = abs(effect_size$estimate), 
                                    Magnitude = effect_size$magnitude)
      
      effectsize_tab = rbind(effectsize_tab, effect_size_estimate)
    }
    return(effectsize_tab)
  }

}
# sample
# effectsize_func(pop, columns = c("IP_Allw_Amt", "OP_Allw_Amt", "DR_Allw_Amt", "Rx_Allw_Amt", "ER_Allw_Amt",
#                                  "Total_Allw_Amt"), strata = "Year_Mo_")


#----------------------------------------- Removing extreme values ----------------------------------------------
# These functions are for removing outliers and showing the statistics which are incorporated to the tableby functions
medianq1q3_out <- function(x, weights=rep(1, length(x)), ...){
  x = x[!is.na(x)]
  as = scores(x, prob = 0.995, type = "t")
  fd = data.frame(cbind(x,as))
  fd = fd %>% filter(as==FALSE)
  medianq1q3fd = round(medianq1q3(fd$x),2)
  return(medianq1q3fd)
}

n_outliers_999 <- function(x, weights=rep(1, length(x)), ...){
  sum(scores(na.omit(x), prob = 0.999, type = "t"))
}

mean_out_999 <- function(x, weights=rep(1, length(x)), ...){
  x = x[!is.na(x)]
  as = scores(x, prob = 0.999, type = "t")
  fd = data.frame(cbind(x,as))
  fd = fd %>% filter(as==FALSE)
  meansdfd = round(meansd(fd$x), 3)
  
  return(meansdfd)
}

medianq1q3_out_999 <- function(x, weights=rep(1, length(x)), ...){
  x = x[!is.na(x)]
  as = scores(x, prob = 0.999, type = "t")
  fd = data.frame(cbind(x,as))
  fd = fd %>% filter(as==FALSE)
  medianq1q3fd = round(medianq1q3(fd$x),2)
  return(medianq1q3fd)
}

range_out_999 <- function(x, weights=rep(1, length(x)), ...){
  x = x[!is.na(x)]
  as = scores(x, prob = 0.999, type = "t")
  fd = data.frame(cbind(x,as))
  fd = fd %>% filter(as==FALSE)
  maxfd = round(max(fd$x),2)
  minfd = round(min(fd$x),2)
  com = paste0(minfd, " - ", maxfd)
  return(com)
}

aovout_func_joy <- function(data,columns=NULL,strata=NULL,percentile =0.995){
  p_val_tab <- tibble()
  for(i in 1:length(columns)){
    a1 = data %>% 
      filter(Year_Mo_=="July 2017") %>% 
      select(columns[i],strata) %>% 
      drop_na()
    a1$out = scores(a1[,1], type="t", prob = percentile)
    a1 = a1 %>% filter(out==FALSE)
    a2 = data %>% 
      filter(Year_Mo_=="July 2018") %>% 
      select(columns[i],strata) %>% 
      drop_na()
    a2$out = scores(a2[,1], type="t", prob = percentile)
    a2 = a2 %>% filter(out==FALSE)
    aa = rbind(a1,a2)
    az =aov(formula(paste0(columns[i], "~", strata)), data = aa, na.action = na.exclude)
    az1 = summary(az)
    az2 = tibble(Var = columns[i], p_value=az1[[1]]$`Pr(>F)`[1])
    p_val_tab = rbind(p_val_tab, az2)
  }
  return(p_val_tab)
}

# Function to create new data of RAF scores without outliers 
new_pop_raf <- function(data, enroll_flag = "N") {
  
  if(enroll_flag == "Y") {
    data = data[Enroll_Flag == 1]
  }
  
  else if(enroll_flag == "N") {
    
  }
  
  tmp_pop1 = data[Group == "July 2017",.(RAF_Score, Group)]
  tmp_pop2 = data[Group == "July 2018" & !is.na(RAF_Score),.(RAF_Score, Group)]
  tmp_pop1$out <- scores(tmp_pop1[,1], type="t", prob = 0.999)
  tmp_pop2$out <- scores(tmp_pop2[,1], type="t", prob = 0.999)
  tmp_pop = rbind(tmp_pop1, tmp_pop2)
  tmp_pop = tmp_pop[out == FALSE,]
  
  return(tmp_pop)
}
# sample 
# new_pop_raf(pop, enroll_flag = "N")


# Function to create new data without outliers and plot RAF scores
plot_out <- function(data, enroll_flag = "N") {
  
  if(enroll_flag == "Y") {
    data = data[Enroll_Flag == 1]
    title = "Among enrolled (excluding 0.1% extreme normalized values)"
  }
  
  else if(enroll_flag == "N") {
    title = "Among eligibles (excluding 0.1% extreme normalized values)"
    
  }
  
  tmp_pop1 = data[Group == "July 2017",.(RAF_Score, Group)]
  tmp_pop2 = data[Group == "July 2018" & !is.na(RAF_Score),.(RAF_Score, Group)]
  tmp_pop1$out <- scores(tmp_pop1[,1], type="t", prob = 0.999)
  tmp_pop2$out <- scores(tmp_pop2[,1], type="t", prob = 0.999)
  tmp_pop = rbind(tmp_pop1, tmp_pop2)
  tmp_pop = tmp_pop[out == FALSE,]
  
  
  ggplot(tmp_pop[out == FALSE], aes(x = RAF_Score, fill = Group)) + 
    geom_histogram(bins = 30, 
                   aes(y = stat(width*density)), 
                   position = "identity", alpha = 0.6) +  
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    ggtitle(title) + 
    ylab("Percentage") + xlab("RAF Score") +
    scale_fill_manual(values = c(uhg1, uhg2)) +
    theme_joy_single + guides(fill = guide_legend(title = NULL))
  
}

# Function to create new data of spending without outliers
new_pop_spend <- function(data, enroll_flag = "N") {
  
  if(enroll_flag == "Y") {
    data = data[Enroll_Flag == 1]
    
    new_pop <- wo_extreme_func(data = data, columns = c("IP_Allw_Amt", "OP_Allw_Amt", "DR_Allw_Amt", "Rx_Allw_Amt",  
                                                        "ER_Allw_Amt", "Total_Allw_Amt"), 
                               strata = "Year_Mo_", percentile = 0.995)
  }
  
  else if(enroll_flag == "N") {
    
    new_pop <- wo_extreme_func(data = data, columns = c("IP_Allw_Amt", "OP_Allw_Amt", "DR_Allw_Amt", "Rx_Allw_Amt",  
                                                        "ER_Allw_Amt", "Total_Allw_Amt"), 
                               strata = "Year_Mo_", percentile = 0.995)
  }
  
  new_pop_ip = data.table(new_pop[[1]])
  new_pop_op = data.table(new_pop[[2]])
  new_pop_dr = data.table(new_pop[[3]])
  new_pop_rx = data.table(new_pop[[4]])
  new_pop_er = data.table(new_pop[[5]])
  new_pop_total = data.table(new_pop[[6]])
  
  IP_cat = new_pop_ip[,.(IP = mean_ci(IP_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  OP_cat = new_pop_op[,.(OP = mean_ci(OP_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  DR_cat = new_pop_dr[,.(DR = mean_ci(DR_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  Rx_cat = new_pop_rx[,.(Rx = mean_ci(Rx_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  ER_cat = new_pop_er[,.(ER = mean_ci(ER_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  Total_cat = new_pop_total[,.(Total = mean_ci(Total_Allw_Amt), stat = c('Mean', 'Lower', 'Upper')), keyby = Year_Mo_]
  
  Spend_cat = cbind(IP_cat, OP_cat, DR_cat, Rx_cat, ER_cat, Total_cat)
  Spend_cat = Spend_cat[,.(Year_Mo_, IP, OP, DR, Rx, ER, Total, stat)]
  Spend_cat_mean = Spend_cat[stat == "Mean"]
  Spend_cat_lower = Spend_cat[stat == "Lower"]
  Spend_cat_upper = Spend_cat[stat == "Upper"]
  Spend_cat_mean_melt = melt(Spend_cat_mean, id.vars = c('Year_Mo_'),
                             measure.vars = c('IP', 'OP', 'DR', 'Rx', 'ER', 'Total'),
                             variable.name = "Category",
                             value.name = "Mean")
  Spend_cat_lower_melt = melt(Spend_cat_lower, id.vars = c('Year_Mo_'),
                              measure.vars = c('IP', 'OP', 'DR', 'Rx', 'ER', 'Total'),
                              variable.name = "Category",
                              value.name = "Lower")
  Spend_cat_upper_melt = melt(Spend_cat_upper, id.vars = c('Year_Mo_'),
                              measure.vars = c('IP', 'OP', 'DR', 'Rx', 'ER', 'Total'),
                              variable.name = "Category",
                              value.name = "Upper")
  setkeyv(Spend_cat_mean_melt, c("Year_Mo_", "Category"))
  setkeyv(Spend_cat_lower_melt, c("Year_Mo_", "Category"))
  setkeyv(Spend_cat_upper_melt, c("Year_Mo_", "Category"))
  Spend_cat_melt = Spend_cat_mean_melt[Spend_cat_lower_melt, nomatch = 0]
  Spend_cat_melt = Spend_cat_melt[Spend_cat_upper_melt, nomatch = 0]
  
  return(Spend_cat_melt)
  
}
# sample
# Spend_cat_melt = new_pop_spend(data = pop, enroll_flag = "Y")

#----------------------------------------- Removing extreme values ----------------------------------------------

