# Investigating each table

#########################################
# dbo.GroupSummary                      #
#########################################

data.groups <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                         FROM dbo.GroupSummary", as.is = TRUE)
data.groups <- data.groups %>% mutate_each(funs(as.numeric), RX_AllwAmt:AllwAmt)
data.groups <- data.groups %>% mutate_each(funs(as.Date), PolicyEffDate:PolicyEndDate)

table(data.groups$GroupState)
summary(data.groups$PolicyMM)

length(unique(data.groups$PolicyID))                            # 7,068

summary(data.groups$AllwAmt)

#########################################
# dbo.GroupDetailYY                     #
#########################################

data.groupd <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                  FROM dbo.GroupDetailYY", as.is = TRUE)
data.groupd <- data.groupd %>% mutate_each(funs(as.numeric), Premium:AllwAmt)
data.groupd <- data.groupd %>% mutate_each(funs(as.Date), PolicyEffDate:PolicyEndDate)
length(unique(data.groupd$PolicyID))                          # 7,068
table(data.groupd$PolicyYear)
table(data.groupd$GroupState)

summary(data.groupd$EligibileEmployees)
summary(data.groupd$EnrolledEmployees)
sum(data.groupd$EligibileEmployees == data.groupd$EnrolledEmployees, na.rm = TRUE) # 5,889 are equal

sum(is.na(data.groupd$PolicyMM))
sum(is.na(data.groupd$EnrolledMembers))                        # 56 NA
sum(is.na(data.groupd$EnrolledMM))                             # 56 NA
sum(data.groupd$PolicyMM * data.groupd$EnrolledMembers != data.groupd$EnrolledMM, na.rm = TRUE)  #

data.groupd[data.groupd$RenewedPrior == 0, "RenewedPrior"] <- "A"
data.groupd[data.groupd$RenewedPrior == 1, "RenewedPrior"] <- "B"
table(data.groupd$RenewedPrior, data.groupd$RenewedFollow)
table(data.groupd$Active, data.groupd$RenewedPrior, data.groupd$RenewedFollow)     # Not making sense, (some do show up 3 times)

#########################################
# dbo.MemberSummary                     #
#########################################

# Add if they are primary or dependent on the plan

data <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                  FROM dbo.MemberSummary", as.is = TRUE)
length(unique(data$Member_DIMID))                                 # 324,785

mean(data$Sbscr_Ind)
mean(data$EnrolledMotion)    # 13.39% enrolled in motion                                     

length(unique(data$PolicyID))                                     # 7,068

attach(data)
hold.mm <- aggregate(data$MM, by = list(PolicyID = data$PolicyID), FUN = sum)
colnames(hold.mm)[2] <- "MM"
detach(data)
  
#########################################
# dbo.MemberClaimDetailYY               #
#########################################

data.y <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                    FROM dbo.MemberClaimDetailYY", as.is = TRUE)
data.y <- data.y %>% mutate_each(funs(as.numeric), RAF:AllwAmt)
length(unique(data.y$Member_DIMID))                               # 324,783  
table(data.y$ClaimYear)
summary(data.y$RAF)
summary(data.y$AllwAmt)
sum(data.y$AllwAmt < 0)                                           # 10 with allwamt less than 0
summary(data.y$MM_Total)                                          # All 0s

# data.y2 <- merge(data.y, data, by.x = "Member_DIMID", by.y = "Member_DIMID")
# str(data.y2)

#########################################
# dbo.MemberHCCDetailYY                 #
#########################################

data.h <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                    FROM dbo.MemberHCCDetailYY", as.is = TRUE)
data.h <- data.h %>% mutate_each(funs(as.numeric), RAF)
length(unique(data.h$Member_DIMID))                               # 27,126

data.h$Sum <- rowSums(data.h[,4:130])  # minimum 1

hold.hcc <- as.data.frame(matrix(nrow = length(4:130), ncol = 2))
hold.hcc[1:127,1] <- colnames(data.h[,4:130])
colnames(hold.hcc) <- c("HCC", "Mean")
for(i in 4:130){
  hold.hcc[i-3,2] <- mean(data.h[,i])
}


hold.hcc[hold.hcc$Mean > sort(hold.hcc$Mean, TRUE)[11],]

#########################################
# dbo.Longitudinal_Month                #
#########################################

# Very few members with month information before their 0 month (51 at -1, 1 at -11)
# Distribution of 0, 1, 2 months seems strange. (Shouldn't be any 0s)

data.m <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                  FROM dbo.Longitudinal_Month", as.is = TRUE)
data.m <- data.m %>% mutate_each(funs(as.numeric), RAF:AllwAmt)
length(unique(data.m$Member_DIMID))                                        # 43,685
table(data.m$Month)                        

# data.m2 <- merge(data.m, data, by.x = "Member_DIMID", by.y = "Member_DIMID")
# str(data.m2)

summary(data.m$RAF)

hold.monthsteps <- as.data.frame(matrix(nrow = 24, ncol = 2))
colnames(hold.monthsteps) <- c("Month", "Mean_Steps")
hold.monthsteps$Month <- 0:23
for(i in 1:24){
  hold.monthsteps[i, "Mean_Steps"] <- mean(data.m[data.m$Month == i - 1,"TotalStepsForMonth"])
}

plot <- ggplot(aes(x = Month, y = Mean_Steps), data = hold.monthsteps) + geom_point()
plot

hold.monthsteps <- as.data.frame(matrix(nrow = 24, ncol = 2))
colnames(hold.monthsteps) <- c("Month", "Mean_Allw")
hold.monthsteps$Month <- 0:23
for(i in 1:24){
  hold.monthsteps[i, "Mean_Allw"] <- mean(data.m[data.m$Month == i - 1,"AllwAmt"])
}

plot <- ggplot(aes(x = Month, y = Mean_Allw), data = hold.monthsteps) + geom_point()
plot

#########################################
# dbo.Longitudinal_Day                  #
#########################################

# Notes:
# 43,627 unique ID, but only 39,959 with qtr 1
# Add a couple columns: mean steps over 90 day period
# The four plots of the 90 day periods seem suspect

data.d <- read.odbc("pdb_Allsavers_Research", dbQuery = "SELECT *
                    FROM dbo.Longitudinal_Day", as.is = TRUE)
length(unique(data.d$Member_DIMID))                                   # 43,627 (slightly different than 43,685)
table(data.d$QtrNbr)

# What are the rules for people being included in a quarter?

data.one <- data.d[data.d$QtrNbr == 1,]

hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
colnames(hold.day) <- c("Day", "Percent")
hold.day$Day <- 1:90
for(i in 1:90){
  hold.day[i, "Percent"] <- sum(data.one[,i+4] > 300)/length(data.one[,i+4])
}

plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
plot

data.two <- data.d[data.d$QtrNbr == 2,]

hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
colnames(hold.day) <- c("Day", "Percent")
hold.day$Day <- 1:90
for(i in 1:90){
  hold.day[i, "Percent"] <- sum(data.two[,i+4] > 300)/length(data.two[,i+4])
}

plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
plot

data.three <- data.d[data.d$QtrNbr == 3,]

hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
colnames(hold.day) <- c("Day", "Percent")
hold.day$Day <- 1:90
for(i in 1:90){
  hold.day[i, "Percent"] <- sum(data.three[,i+4] > 300)/length(data.three[,i+4])
}

plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
plot

data.four <- data.d[data.d$QtrNbr == 4,]

hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
colnames(hold.day) <- c("Day", "Percent")
hold.day$Day <- 1:90
for(i in 1:90){
  hold.day[i, "Percent"] <- sum(data.four[,i+4] > 300)/length(data.four[,i+4])
}

plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
plot

data.five <- data.d[data.d$QtrNbr == 5,]

hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
colnames(hold.day) <- c("Day", "Percent")
hold.day$Day <- 1:90
for(i in 1:90){
  hold.day[i, "Percent"] <- sum(data.five[,i+5] > 300)/length(data.five[,i+5])
}

plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
plot

# data.six <- data.d[data.d$QtrNbr == 6,]
# 
# hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
# colnames(hold.day) <- c("Day", "Percent")
# hold.day$Day <- 1:90
# for(i in 1:90){
#   hold.day[i, "Percent"] <- sum(data.six[,i+6] > 300)/length(data.six[,i+6])
# }
# 
# plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
# plot

# Plot those that are in at least 1 and 2.  How to do this?

data.one <- data.d[data.d$QtrNbr == 1,]

hold.day <- as.data.frame(matrix(nrow = 90, ncol = 2))
colnames(hold.day) <- c("Day", "Percent")
hold.day$Day <- 1:90
for(i in 1:90){
  hold.day[i, "Percent"] <- sum(data.one[,i+4] > 300)/length(data.one[,i+4])
}

plot <- ggplot(aes(x = Day, y = Percent), data = hold.day) + geom_point()
plot