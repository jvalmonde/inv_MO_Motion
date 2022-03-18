# Questions:
# Redo spend from previous analysis (compare choice versus non choice) (I can at least look at PMPM of choice in)
# Survival analysis
# likelihood that a company we re-enroll in All Savers
# What members are likely to register?
# Given that a member registers, what members stay more engaged?
# What do claims look like for members after they enroll?
# Based on past claims, can we predict who is likely to register? (cant do in All Savers)
# registration rates
# PCA analysis of steps.  Can we identify groups of walking people.

#########################
# PCA Analysis of Steps #
#########################

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

# Try PCA for different lengths of data

data.one <- data.d[data.d$QtrNbr == 1,]

data.pc.30.one <- prcomp(data.one[,5:34], center = TRUE, scale = TRUE)
summary(data.pc.30.one)  # 81% of at 8, 84.9% at 10
scores.30 <- as.data.frame(data.pc.30.one$x[,1:30])

heatmap <- qplot(x = Var1, y = Var2, data = melt(cor(data.one[,5:34])), geom = "tile",
                 fill = value)
heatmap # change orientation of x-axis labels

data.pc.60.one <- prcomp(data.one[,5:64], center = TRUE, scale = TRUE)
summary(data.pc.60.one)  # 5 is 69%, 14 is 80.6%
scores.60 <- as.data.frame(data.pc.60.one$x[,1:60])

heatmap <- qplot(x = Var1, y = Var2, data = melt(cor(data.one[,5:64])), geom = "tile",
                 fill = value)
heatmap

data.pc.90.one <- prcomp(data.one[,5:94], center = TRUE, scale = TRUE)
summary(data.pc.90.one)  # 5 is 66%, 10 is 73.8, 15 is 77.9%
scores.90 <- as.data.frame(data.pc.90.one$x[,1:90])

heatmap <- qplot(x = Var1, y = Var2, data = melt(cor(data.one[,5:94])), geom = "tile",
                 fill = value)
heatmap
