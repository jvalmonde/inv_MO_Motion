# Cashman project master file

# Steve Smela, Savvysherpa
# February, 2018

# Change this as needed
setwd("/work/ssmela/Cashman/Final Code")

# Clear workspace
rm(list = ls())

# Code to create data sets
source("Combined data sets create.R")
source("Cashman annual data set create.R")

# Code to perform the analyses
source("Combined probability and size modeling.R")
source("Cashman steps analysis.R")

# After these are run, to produce the output for the report, run "Cashman plots and summaries".