uhg1 = rgb(red = 45, green = 95, blue = 167, maxColorValue = 255)      # #2d5fa7    UHG blue
uhg2 = rgb(red = 247, green = 152, blue = 55, maxColorValue = 255)     # #f79837    UHG orange
uhg3 = rgb(red = 114, green = 192, blue = 96, maxColorValue = 255)     # #72c060    UHG green
uhg4 = rgb(red = 234, green = 75, blue = 77, maxColorValue = 255)      # #ea4b4d    UHG red
uhg5 = rgb(red = 2, green = 142, blue = 167, maxColorValue = 255)      # #028ea7    UHG teal
uhg6 = rgb(red = 103, green = 93, blue = 168, maxColorValue = 255)     # #675da8    UHG purple
uhgGrey = rgb(red = 166, green = 166, blue = 166, maxColorValue = 255)

text_size = 10
theme_joy = theme(axis.line = element_line(color = uhgGrey, size = 2),
                  panel.grid.major.y = element_line(color = uhgGrey, size = 0.1, linetype = 2),
                  panel.background = element_rect(fill = 'white'),
                  axis.ticks = element_line(size = 1.5),
                  axis.ticks.length = unit(0.15, 'cm'),
                  axis.text.x = element_text(size = text_size, vjust = 0.9),
                  axis.text.y = element_text(size = text_size),
                  axis.title = element_text(size = text_size, face = 'bold'),
                  legend.position = 'bottom',
                  legend.title = element_text(size = text_size),
                  legend.text = element_text(size = text_size - 2),
                  legend.margin = margin(t = 0.2, r = 0.2, l = 0.2, b = 0.2, unit = 'cm'),
                  panel.spacing = unit(5, 'pt'),
                  strip.text = element_text(size = text_size + 2),
                  plot.title = element_text(size = text_size + 3, face = 'bold', hjust = 0.5))
text_size_ = 14
theme_joy_single = theme(axis.line = element_line(color = uhgGrey, size = 2),
                         panel.grid.major.y = element_line(color = uhgGrey, size = 0.2, linetype = 2),
                         panel.background = element_rect(fill = 'white'),
                         axis.ticks = element_line(size = 1.5),
                         axis.ticks.length = unit(0.15, 'cm'),
                         axis.text.x = element_text(size = text_size_, vjust = 0.9),
                         axis.text.y = element_text(size = text_size_),
                         axis.title = element_text(size = text_size_, face = 'bold'),
                         legend.position = 'bottom',
                         legend.title = element_text(size = text_size_),
                         legend.text = element_text(size = text_size_ - 0),
                         legend.margin = margin(t = 0.2, r = 0.2, l = 0.2, b = 0.2, unit = 'cm'),
                         panel.spacing = unit(5, 'pt'),
                         strip.text = element_text(size = text_size_ + 1),
                         plot.title = element_text(size = text_size_ + 1, face = 'bold', hjust = 0.5))

# -------------------------------------------------------------------------------------------------------------
# This function will calculate the total monthly spending of the two groups. This function will
# produce two tables, i.e. table for bootstrap and table of the PMPM of the two groups
PMPM  <- function(datagroup1, datagroup2, filters=NULL, inflation=NULL){
  
  "
  Parameters:
  datagroup1: the data that the first group will be taken
  datagroup2: the data that the second group wll be taken
  filters: the filters that will be used is either 'eligible' or 'enrolled'.Should not be left blank!
  inflation: the inflation rate that will be used. Note, the user may not put any inflation rate if he/she 
  don't want to adjust the spend value that will be calculated.
  "
  # evaluating filters and inflation parameters
  if (filters=="eligible"){
    arg1 = "eligible_flag=='eligible'"
    if (is.null(inflation)){
      inf = 0
    }
    else{
      inf = inflation
    }
  }
  else if(filters=="enrolled"){
    arg1 = "enroll_flag=='enrolled'"
    if (is.null(inflation)){
      inf = 0
    }
    else{
      inf = inflation
    }
  }
  
  # getting total spending of the two groups
  total1 <- datagroup1 %>% 
    filter(Year_Mo<=201707) %>%
    filter(active_flag=="Active") %>% 
    filter(eval(parse(text = arg1))) %>% 
    group_by(Indv_Sys_ID,Year_Mo,Total_Allw_Amt) %>% 
    summarise(n=n()) %>% 
    group_by(Indv_Sys_ID) %>% 
    summarise(MM_Month=n(),total=sum(Total_Allw_Amt)+(sum(Total_Allw_Amt)*inf))
  total2 <- datagroup2 %>% 
    filter(Year_Mo>=201707) %>% 
    filter(active_flag=="Active") %>% 
    filter(eval(parse(text = arg1))) %>% 
    group_by(Indv_Sys_ID,Year_Mo,Total_Allw_Amt) %>% 
    summarise(n=n()) %>% 
    group_by(Indv_Sys_ID) %>% 
    summarise(MM_Month=n(),total=sum(Total_Allw_Amt))
  
  # getting the number of months of the two groups
  mem1 <- datagroup1 %>% 
    filter(eval(parse(text = arg1))) %>% 
    filter(Year_mo_str=="July 2017") %>%
    filter(active_flag=="Active") %>% 
    group_by(Indv_Sys_ID) %>% 
    summarise(n=n()) %>% 
    mutate(yr_mo="July 2017")
  mem2 <- datagroup2 %>% 
    filter(eval(parse(text = arg1))) %>% 
    filter(Year_mo_str=="July 2018") %>%
    filter(active_flag=="Active") %>% 
    group_by(Indv_Sys_ID) %>% 
    summarise(n=n()) %>% 
    mutate(yr_mo="July 2018")
  
  pmpm_dat1 <- left_join(mem1, total1, by = "Indv_Sys_ID")
  pmpm_dat2 <- left_join(mem2, total2, by = "Indv_Sys_ID")
  
  # Data for the bootstrap
  pmpm_boot_data <- rbind(pmpm_dat1, pmpm_dat2)
  # PMPM Spending of the 2 groups
  PMPM_tab = tibble(`Year Month`= c("July 2017", "July 2018"),
                    `PMPM ($)` = c(sum(pmpm_dat1$total)/sum(pmpm_dat1$MM_Month),
                                   sum(pmpm_dat2$total)/sum(pmpm_dat2$MM_Month) ))
  
  list(boot_data=pmpm_boot_data,PMPM_tab=PMPM_tab)
}
# An example of how to run the function
# a <- PMPM(Group1_dat, Group2_dat, filters="eligible", inflation=0.019)

# -------------------------------------------------------------------------------------------------------------------
# This is the bootstrap function. It returns the Bootsrap analysis 
PMPM_bootstrap <- function(boot_data, R=NULL){
  "
  Parameters:
  boot_data: data will be used for bootstrap
  R: number of iterations
  "
  # function for calculating PMPM
  diff_fn <- function(data, index){
    data <- data[index, ]
    d1 <- data %>% filter(yr_mo=="July 2017")
    d2 <- data %>% filter(yr_mo=="July 2018")
    diff <- (sum(d2$total)/sum(d2$MM_Month))-(sum(d1$total)/sum(d1$MM_Month))
    return(diff)
  }
  
  diff <- boot(boot_data, statistic = diff_fn, R=R)
  boot_pmpm <-boot.ci(diff, type = "norm")
  
  boot_pmpm.tib <- tibble(`OBSERVED DIFFERENCE`=boot_pmpm$t0, `95% CI`=paste("(",
                                                                             round(boot_pmpm$normal[2],2), ",", round(boot_pmpm$normal[3], 2), ")"))
  return(boot_pmpm.tib)
}
# An example how to run the function
# b = PMPM_bootstrap(a$boot_data, R=1000)

# ----------------------------------------------------------------------------------------------------------------------------------------------------


#This function returns the Active Rate table
Active_Rate_Table <- function(datagroup1,datagroup2, filters = NULL,Table.cap=NULL){
  "
  Parameters:
  datagroup1: the data that the first group will be taken
  datagroup2: the data that the second group wll be taken
  filters: the filters that will be used is either 'eligible' or 'enrolled'.Should not be left blank!
  Table.cap: Caption for the table
  "
  
  if (filters=="eligible"){
    arg1 = "eligible_flag=='eligible'"
  }
  else if(filters=="enrolled"){
    arg1 = "enroll_flag=='enrolled'"
  }
  # active rate for group 1
  tab5 <- datagroup1 %>% 
    filter(eval(parse(text = arg1))) %>% 
    filter(Year_mo_str=="July 2017") %>% 
    group_by(Year_Mo, Year_mo_str) %>% 
    summarise(Active=sum(active_flag=="Active"), Inactive=sum(active_flag=="Inactive")) %>% 
    mutate(Active_rate=round((Active/(Active+Inactive))*100,2))
  
  # active rate for group 2
  tab6 <- datagroup2 %>% 
    filter(eval(parse(text = arg1)))  %>% 
    filter(Year_mo_str=="July 2018") %>% 
    group_by(Year_Mo, Year_mo_str) %>% 
    summarise(Active=sum(active_flag=="Active"), Inactive=sum(active_flag=="Inactive")) %>% 
    mutate(Active_rate=round((Active/(Active+Inactive))*100,2))
  
  # combining the groups
  Active <- rbind(tab5,tab6)[,-1]
  
  # changing column headings
  colnames(Active)[1] <- "Year Month"
  colnames(Active)[4] <- "Active Rate %"
  
  # html table
  g <- kable(Active, caption = Table.cap, align = "cc") %>% 
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F) %>% 
    column_spec(1, width = "6.5cm") %>%
    column_spec(2, width = "4cm") %>%
    column_spec(3, width = "4cm") %>%
    column_spec(4, width = "4cm") %>%
    row_spec(0, background = "#d7def2")
  return(g)
}
# Example code of running the function
# Active_Rate_Table(Group1_dat, Group2_dat,filters = "enrolled" ,
#                   Table.cap = "Table  41.  Active rate of current month and current month year ago")

# ------------------------------------------------------------------------------------------------------------------------
# this functions is for removing outlier and showing the statistics and are incorporated to the tableby functions

n_outliers <- function(x, weights=rep(1, length(x)), ...){
  sum(scores(na.omit(x), prob = 0.995, type = "t"))
}
mean_out <- function(x, weights=rep(1, length(x)), ...){
  x = x[!is.na(x)]
  as = scores(x, prob = 0.995, type = "t")
  fd = data.frame(cbind(x,as))
  fd = fd %>% filter(as==FALSE)
  meanfd = meansd(fd$x)
  return(meanfd)
}
range_out <- function(x, weights=rep(1, length(x)), ...){
  x = x[!is.na(x)]
  as = scores(x, prob = 0.995, type = "t")
  fd = data.frame(cbind(x,as))
  fd = fd %>% filter(as==FALSE)
  maxfd = round(max(fd$x),2)
  minfd = round(min(fd$x),2)
  com = paste0(minfd, " - ", maxfd)
  return(com)
}

# this function runs Analysis of Variance for each variable of interest and provide a table of p-values of the analysis
# this function is created to remove the outliers while running the AOV
# the p-values that will be provided by this fucntion will replaced the p-values created by tableby funtion.
# tableby function does not have the capability to provide a p-value without outliers

aovout_func <- function(data,columns=NULL,strata=NULL,percentile =0.99){
  "
  Parameters:
  data: the data that the members will be taken
  columns: variable of interest
  strata: grouping variable
  percentile: percentile level of values that will be removed
  "
  # creating empty table
  p_val_tab <- tibble()

  for(i in 1:length(columns)){
    a1 = data %>% 
      filter(Year_mo_str=="July 2017") %>% 
      select(columns[i],strata) %>% 
      drop_na()
    a1$out = scores(a1[,1], type="t", prob = percentile)
    a1 = a1 %>% filter(out==FALSE)
    a2 = data %>% 
      filter(Year_mo_str=="July 2018") %>% 
      select(columns[i],strata) %>% 
      drop_na()
    a2$out = scores(a2[,1], type="t", prob = percentile)
    a2 = a2 %>% filter(out==FALSE)
    aa = rbind(a1,a2)
    az =aov(formula(paste0(columns[i], "~", strata)), data = aa)
    az1 = summary(az)
    az2 = tibble(Var = columns[i], p_value=az1[[1]]$`Pr(>F)`[1])
    p_val_tab = rbind(p_val_tab, az2)
  }
  return(p_val_tab)
}
#----------------------------------------------------------------------------------------------------------------

# This function is created to trace the chronic condition of members from Jan to July of a given year
# and replace the current July conditions.
# The current July condition is not sufficient because we believe that some other members did not update their claims 
# and in return no records for condition in july (even they already had it prior to that month).

create_chronic_tab = function(data, year_mo_included=1, year_mo_name=NULL){
  "
  Parameters:
  data: the data that the members will be taken
  year_mo_included: specifies what are the months to include. If it is 1, then 
  the function will choose months from Jan 2017 to July 2017. And if it is 2, 
  then the function will choose months from jan 2018 to july 2018.
  year_mo_name: name of year_month column in the data.
  "
  # locate the year_month column
  locate = grep(year_mo_name, names(data))
  locate = locate[length(locate)]
  
  if (year_mo_included==1){
    chron_dat1 <- data %>% 
      filter(Year_Mo >= 201701) %>% 
      filter(Year_Mo <=201707) %>% 
      select(Indv_Sys_ID,locate,31:37)
  }
  else if (year_mo_included==2){
    chron_dat1 <- data %>% 
      filter(Year_Mo >= 201801) %>% 
      select(Indv_Sys_ID,locate,31:37)
  }
  # list of chronic conditions
  chron_names = names(chron_dat1[-c(1,2)])
  chronic_table = data.frame(Indv_Sys_ID=unique(chron_dat1$Indv_Sys_ID))
  
  # tracing and creating new condition table
  for (i in 1:length(chron_names)){
    a = chron_dat1 %>% 
      select(1,2,chron_names[i]) %>% 
      spread(2,3)
    a[is.na(a)] <-0
    a[2:8][a[2:8]=="Y"] = 1 
    a[2:8][a[2:8]=="N"] = 0 
    a[, c(2:8)] <- sapply(a[, c(2:8)], as.numeric)
    a$i <- ifelse(apply(a[2:8], 1, sum)>0,1,0)
    colnames(a)[9] <- chron_names[i]
    a = a[,c(1,9)]
    a[,2][a[,2]==1]= "Y"
    a[,2][a[,2]==0]= "N"
    chronic_table = left_join(chronic_table, a, by = "Indv_Sys_ID")
  }
  return(chronic_table)
}
# An example of running the funtion
# b =create_chronic_tab(Group2_dat, 2, year_mo_name = "Year_mo_str" )

# -----------------------------------------------------------------------------------------------------
# Functions for creating histogram plots
plot.a <- function(datax, xs, y, title=NULL, xlab=NULL, ylab=NULL, binwidth = NULL,
                   by=NULL, alpha=0.5, fill=NULL, color=NULL, legend.title=NULL,
                   legend.position=NULL){
  
  ggplot(data = datax, aes(x=xs, fill=fill, alpha=alpha))+ 
    geom_histogram(aes(y=stat(width*density)), bins = binwidth,position = "identity",na.rm = TRUE)+ 
    ggtitle(title)+ ylab(ylab) + xlab(xlab) +
    guides(alpha=FALSE, color=FALSE, fill=guide_legend(title =legend.title))+
    scale_fill_manual(values = c(uhg1, uhg2))+
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    theme_joy
}
# example
# plot.a(Active_dat1, xs=Active_dat1$Age, binwidth = 30, fill = Active_dat1$Year_mo_str, 
#        color = Active_dat1$Year_mo_str, legend.position = "bottom",title = "AGE",
#        ylab = "Percentage", xlab = "Age")

# -----------------------------------------------------------------------------------------------------------------

# function for hedges's g calculations or finding the effect size estimates for continous variables. 
# This function will produce a table where observe observation, effect size estimates, and magnitude are presented.
COHEN_ME = function(data, factor=NULL, columns = NULL, remove_out = "Y", percentile=NULL,  labelTrans=NULL){
  
  "
  Parameters:
  data: the data the members will be taken
  factor: Grouping factor 
  columns: Desired columns to calculate effect size
  remove_out: Remove outliers if it is 'Y' or do not remove outlier if it is 'N'. Default value is 'Y'
  percentile: if outliers will be remove, you need to put your desired percentile level that needs to be remove
  labelTrans: a list or vector that transform the column names to your desired name
  "
  # Condition if you want to remove outliers
  if (remove_out=="Y"){
    cohen_table = data.frame()
    for (i in 1:length(columns)){
      a = data %>% 
        select(factor,columns[i]) %>% 
        drop_na()
      factors_me = unique(a[,1])
      a1 = a[a[1]==factors_me[1],]
      a2 = a[a[1]==factors_me[2],]
      # deleting outliers for group 1
      a1$out = scores(a1[,2], type = 't', prob = percentile)
      a1 = a1[a1[,3]==FALSE,]
      m1 = round(mean(a1[,2]), 2)
      sd1 = round(sd(a1[,2]), 2)
      # deleting outliers for group 2
      a2$out = scores(a2[,2], type = 't', prob = percentile)
      a2 = a2[a2[,3]==FALSE,]
      m2 = round(mean(a2[,2]), 2)
      sd2 = round(sd(a2[,2]), 2)
      a3 = rbind(a1,a2)
      # cohen's h calculation
      a4 = cohen.d(formula(paste(columns[i], "~", factor)), data=a3, hedges.correction = TRUE)
      # evaluating labeltrans
      if (!is.null(labelTrans)){
        cnt = grep(columns[i], names(labelTrans))
        columns[i]=labelTrans[[cnt]]
      }
      else{
        columns[i]=columns[i]
      }
      a5 = data.frame(Variable=columns[i], t1=round(m1-m2, 3),
                      Estimate=abs(round(a4$estimate, 3)), Magnitude=a4$magnitude)
      colnames(a5)[2] = "Observed Difference"
      cohen_table = rbind(cohen_table, a5)
    }
    return(cohen_table)
  }
  # Condition if you dont want to remove outliers
  else if (remove_out=="N"){
    cohen_table = data.frame()
    for (i in 1:length(columns)){
      a = Active_dat %>% 
        select(factor,columns[i]) %>% 
        drop_na()
      factors_me = unique(a[,1])
      a1 = a[a[1]==factors_me[1],]
      a2 = a[a[1]==factors_me[2],]
      m1 = round(mean(a1[,2]), 2)
      sd1 = round(sd(a1[,2]), 2)
      m2 = round(mean(a2[,2]), 2)
      sd2 = round(sd(a2[,2]), 2)
      a3 = rbind(a1,a2)
      a4 = cohen.d(formula(paste(columns[i], "~", factor)), data=a3, hedges.correction = TRUE)
      if (!is.null(labelTrans)){
        cnt = grep(columns[i], names(labelTrans))
        columns[i]=labelTrans[[cnt]]
      }
      else{
        columns[i]=columns[i]
      }
      a5 = data.frame(Variable=columns[i], t1=round(m1-m2, 3),
                      Estimate=abs(round(a4$estimate,3)), Magnitude=a4$magnitude)
      colnames(a5)[2] = "Observed Difference"
      cohen_table = rbind(cohen_table, a5)
    }
    return(cohen_table)
  }
}
# example
#x =COHEN_ME(data = Active_dat, factor = "Year_mo_str", columns = "Med_Income", percentile = 0.995, labelTrans=expen_labs)

# ----------------------------------------------------------------------------------------------------------------------------

# This function calculates the effect size estimates of categorical variables. 
# It also produces a table where observe difference, effect size estimate, and magnitude are shown.
# Note. This only works on comparing two groups
cohen.h = function(data, factor=NULL, columns=NULL, tofactor=NULL, labelTrans=NULL){
  
  "
  Parameters:
  data: the data the members will be taken
  factor: Grouping factor 
  columns: Desired columns to calculate effect size
  tofactor: Desired factor of the column to calculate effect size
  labelTrans: a list or vector that transform the column names to your desired name
  "
  cohen.h.tib = data.frame()
  for (i in 1:length(columns)){
    data = data.frame(data)
    a = data %>% 
      select(factor,columns[i]) %>% 
      drop_na()
    factors_me = unique(a[,1])
    a1 = a[a[1]==factors_me[1],]
    a2 = a[a[1]==factors_me[2],]
    # c1 =  nrow(a1[a1[,2]==tofactor,])
    # c2 =  nrow(a2[a2[,2]==tofactor,])
    # calculating proportions and effect size
    prop1 = nrow(a1[a1[,2]==tofactor,])/nrow(a1)
    prop2 = nrow(a2[a2[,2]==tofactor,])/nrow(a2)
    H = ES.h(prop1, prop2)
    magnitude = case_when(abs(H)<0.20~"negligible",
                          abs(H)<0.5 ~ "small",
                          abs(H)<0.8 ~ "medium",
                          abs(H)<=1 ~ "large")
    # evaluating labelTrans
    if (!is.null(labelTrans)){
      cnt = grep(columns[i], names(labelTrans))
      columns[i]=labelTrans[[cnt]]
    }
    else{
      columns[i]=columns[i]
    }
    # creating the table
    a3 = data.frame(Variable=paste(columns[i],"", tofactor),
                    t1 = round(prop1-prop2,3),Estimate=abs(round(H, 3)), Magnitude=magnitude)
    colnames(a3)[2] = "Observed Difference"
    cohen.h.tib = rbind(cohen.h.tib, a3)
  }
  return(cohen.h.tib)
  
}
# example
#cohen.h(Active_dat, factor = "Year_mo_str", columns = "T2D_Flag", tofactor="Y", labelTrans=chron_labs)

# ---------------------------------------------------------------------------------------------------------------------------

# extracting data without extreme values
data_without_extreme = function(gdata1, gdata2, filter="eligible", prob=NULL, var = NULL){
  bus = var
  if (filter=='eligible'){
    arg1 = grep("eligible_flag", colnames(Group1_dat))
    arg2 = grep(bus, colnames(Group1_dat))
  }
  else if (filter=='enrolled'){
    arg1 = grep("enroll_flag", colnames(gdata1))
    arg2 = grep(bus, colnames(Group1_dat))
  }
  
  dat_1 <- gdata1 %>%
    filter(Year_mo_str=="July 2017") %>%
    mutate_at(vars(31:37, 12), as.factor) %>%
    mutate_at(vars(14:19, 9, 22), as.numeric) %>% 
    filter(active_flag=="Active")
  
  dat_1 = dat_1[dat_1[,arg1]==filter,]
  dat_1 = dat_1[!is.na(dat_1[,arg2]),]
  dat_1$rafwo_extreme = scores(dat_1[,arg2], type = "t", prob = prob)
  
  dat_1 = dat_1 %>%
    filter(rafwo_extreme==FALSE) %>% 
    select(-rafwo_extreme)
  
  dat_2 = gdata2 %>%
    filter(Year_mo_str=="July 2018") %>%
    mutate_at(vars(31:37, 12), as.factor) %>%
    mutate_at(vars(14:19, 9,22), as.numeric) %>% 
    filter(active_flag=="Active")  
  
  dat_2 = dat_2[dat_2[,arg1]==filter,]
  dat_2 = dat_2[!is.na(dat_2[,arg2]),]
  dat_2$rafwo_extreme = scores(dat_2[,arg2], type = "t", prob = prob)
  dat_2 = dat_2 %>%
    filter(rafwo_extreme==FALSE) %>% 
    select(-rafwo_extreme)
  a = rbind(dat_1, dat_2) %>% data.frame()
  
  return(a)
}
#c = data_without_extreme(Group1_dat, Group2_dat,filter="enrolled",prob = 0.995, var = "RAF_Score" )
