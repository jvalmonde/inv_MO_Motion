#####GP 219 - Cashman Motion####

#In this:
#Trying out the "log-modulus" transforamtion (http://blogs.sas.com/content/iml/2014/07/14/log-transformation-of-pos-neg.html)
#---cheating with a log transform
#---Spoilers: it doesn't work. It gives us a bimodal distribution
#CDF Plot for illustration of difference

#Cody Miller
#Last update: 2015-11-11


test <- dat
summary(test$Delta)
test$Delta[which(test$Delta > 0)] <- log(test$Delta[which(test$Delta > 0)])
summary(test$Delta) #So far so good
test$Delta[which(test$Delta < 0)] <- -log(abs(test$Delta[which(test$Delta < 0)]))
summary(test$Delta)
hist(test$Delta, breaks=50) #Looks multimodal, not normal, but is this just a function of the log-modulus?

#We've now "logged" all our data. How does this affect our inference, though?

summary(lm(Delta~set + Age + Gender + SicioEconomicScore + Period1_BMI, data=dat)) #Weak significance when we look at it alone



#Concepts in matching: overlap####
set.seed(2015)
nyarp <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
nyarp$x[1:100] <- rnorm(100,0,1)
nyarp$x[101:200] <- rnorm(100,0,1)
nyarp$y[1:100] <- 2 + 2*nyarp$x[1:100] + rnorm(1,0,.25)
nyarp$y[101:200] <- 2*nyarp$x[101:200] + rnorm(1,0,.25)


ggplot(nyarp, aes(x=x, fill=tx)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Test") + ylab("Density") + xlab("X") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))
#Lots of overlap


set.seed(1111)
nyarp2 <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
nyarp2$x[1:100] <- 2 + rnorm(100,3,1)
nyarp2$x[101:200] <- rnorm(100,0,1)
nyarp2$y[1:100] <- 2 + 2*nyarp2$x[1:100] + rnorm(1,0,.25)
nyarp2$y[101:200] <- 2*nyarp2$x[101:200] + rnorm(1,0,.25)

ggplot(nyarp2, aes(x=x, fill=tx)) + geom_density(alpha= .65, position="identity") + ggtitle("nyarp2 Test") + ylab("Density") + xlab("X") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))
#Very little overlap


summary(lm(y~x+tx, data=nyarp))
summary(lm(y~x+tx, data=nyarp2))

#Yeah, they both work in this simple example.

rm(nyarp, nyarp2)


#Let's simulate a bunch of these things and see what happens

#Simulations - Correct model ####

set.seed(9746)
nruns <- 1000
res_c <- data.frame(est=rep(0,2000), overlap=c(rep("Hi",1000), rep("Lo", 1000)), p=rep(0,1000))
for(i in 1:nruns){
nyarp <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
nyarp$x[1:100] <- rnorm(100,0,1)
nyarp$x[101:200] <- rnorm(100,0,1)
nyarp$y[1:100] <- 2 + 2*nyarp$x[1:100] + rnorm(1,0,.25)
nyarp$y[101:200] <- 2*nyarp$x[101:200] + rnorm(1,0,.25)


nyarp2 <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
nyarp2$x[1:100] <- 2 + rnorm(100,3,1)
nyarp2$x[101:200] <- rnorm(100,0,1)
nyarp2$y[1:100] <- 2 + 2*nyarp2$x[1:100] + rnorm(1,0,.25)
nyarp2$y[101:200] <- 2*nyarp2$x[101:200] + rnorm(1,0,.25)

res_c[i,1] <- summary(lm(y~x+tx, data=nyarp))$coefficients[3]
res_c[(i + 1000),1] <- summary(lm(y~x+tx, data=nyarp2))$coefficients[3]
res_c[i,3] <- summary(lm(y~x+tx, data=nyarp))$coefficients[12]
res_c[(i + 1000),3] <- summary(lm(y~x+tx, data=nyarp2))$coefficients[12]


rm(nyarp, nyarp2)
}

ggplot(res_c, aes(x=est, fill=overlap)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Simulation: Estimates with High and Low Overlap - Correct Model") + ylab("Density") + xlab("Estimate") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))

#Conclusion: in this case, linear regression seems to be robust to imbalance
#Question: does this case differ at all from what we're doing with Cashman?
#From G&H pages 200-201: balance protects us from problems of model specification
#---what would happen if we mis-specified the model?

ggplot(res_c, aes(x=p, fill=overlap)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Simulation: Estimates with High and Low Overlap - Correct Model") + ylab("Density") + xlab("p-values") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))

#....huh. Error in the code? Or just ggplot not handling it well? Maybe that. They're all 0.




#Simulation - Incorrect model 1#####
#rm(nruns)
#rm(res_c)


set.seed(5499)
nruns <- 1000
res_m <- data.frame(est=rep(0,2000), overlap=c(rep("Hi",1000), rep("Lo", 1000)), p=rep(0,1000))
for(i in 1:nruns){
  nyarp <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
  nyarp$x[1:100] <- rnorm(100,0,1)
  nyarp$x[101:200] <- rnorm(100,0,1)
  nyarp$y[1:100] <- 4*nyarp$x[1:100] + rnorm(1,0,.25) #Changed to multiplicative effect
  nyarp$y[101:200] <- 2*nyarp$x[101:200] + rnorm(1,0,.25)
  
  
  nyarp2 <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
  nyarp2$x[1:100] <- 2 + rnorm(100,3,1)
  nyarp2$x[101:200] <- rnorm(100,0,1)
  nyarp2$y[1:100] <- 4*nyarp2$x[1:100] + rnorm(1,0,.25) #Changed to multiplicative effect
  nyarp2$y[101:200] <- 2*nyarp2$x[101:200] + rnorm(1,0,.25)
  
  res_m[i,1] <- summary(lm(y~x+tx, data=nyarp))$coefficients[3]
  res_m[(i + 1000),1] <- summary(lm(y~x+tx, data=nyarp2))$coefficients[3]
  res_m[i,3] <- summary(lm(y~x+tx, data=nyarp))$coefficients[12]
  res_m[(i + 1000),3] <- summary(lm(y~x+tx, data=nyarp2))$coefficients[12]
  
  rm(nyarp, nyarp2)
}

ggplot(res_m, aes(x=est, fill=overlap)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Simulation: Estimates with High and Low Overlap: Misspecified Model (Multiplicative)") + ylab("Density") + xlab("Estimate") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))

#This time, we get MASSIVELY different estimates.
#Ideally, we'll always use the correct model, but we can't expect to know the data generation method each time.
#Conclusion: imbalance can lead to very different answers in the relationship between independent and dependent variables

ggplot(res_m, aes(x=p, fill=overlap)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Simulation: Estimates with High and Low Overlap - Misspecified Model (Multiplicative)") + ylab("Density") + xlab("p-values") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))

#rm(nruns)
#rm(res)

#Simulation - Incorrect model 2####

set.seed(2079)
nruns <- 1000
res_q <- data.frame(est=rep(0,2000), overlap=c(rep("Hi",1000), rep("Lo", 1000)), p=rep(0,1000))
for(i in 1:nruns){
  nyarp <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
  nyarp$x[1:100] <- rnorm(100,0,1)
  nyarp$x[101:200] <- rnorm(100,0,1)
  nyarp$y[1:100] <- 2+ nyarp$x[1:100]^2 + rnorm(1,0,.25) #Changed to quadratic effect only
  nyarp$y[101:200] <- nyarp$x[101:200]^2 + rnorm(1,0,.25)
  
  
  nyarp2 <- data.frame(y=rep(0,200), x=rep(0,200),tx=c(rep("Tx",100), rep("Cntr",100)))
  nyarp2$x[1:100] <- 2 + rnorm(100,3,1)
  nyarp2$x[101:200] <- rnorm(100,0,1)
  nyarp2$y[1:100] <- 2 + nyarp2$x[1:100]^2 + rnorm(1,0,.25) #Changed to quadratic effect only
  nyarp2$y[101:200] <- nyarp2$x[101:200]^2 + rnorm(1,0,.25)
  
  res_q[i,1] <- summary(lm(y~x+tx, data=nyarp))$coefficients[3]
  res_q[(i + 1000),1] <- summary(lm(y~x+tx, data=nyarp2))$coefficients[3]
  res_q[i,3] <- summary(lm(y~x+tx, data=nyarp))$coefficients[12]
  res_q[(i + 1000),3] <- summary(lm(y~x+tx, data=nyarp2))$coefficients[12]
  
  rm(nyarp, nyarp2)
}

ggplot(res_q, aes(x=est, fill=overlap)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Simulation: Estimates with High and Low Overlap: Misspecified Model (Quadratic)") + ylab("Density") + xlab("Estimate") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10"))
#The estimates are the same, but the variance is completely different

ggplot(res_q, aes(x=p, fill=overlap)) + geom_density(alpha= .65, position="identity") + ggtitle("Nyarp Simulation: Estimates with High and Low Overlap - Misspecified Model (Quadratic)") + ylab("Density") + xlab("p-values") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold"), plot.title=element_text(size=16, face="bold")) + scale_fill_manual(values=c("#4F81BD", "#FEBE10")) + xlim(0,.0001)
#Different spread. They're all significant, but the spread is different.



rm(nruns, res)











#CDF Plot####

#All of them together (cut off at $10k in either direction)

plot(ecdf(dat2$Delta2), xlim=c(-10000,10000))


