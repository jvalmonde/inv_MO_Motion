# AvMo Master 

# Steve Smela, Savvysherpa

# April 2018 

# This file loads the functions used in the creation of the "Assessing the Value of Motion" (AvMo) analysis.

# The starting point was code written by Bernardo Marquez for the "Member Level Insights" project for the 
# 2017 Lifetime Value pilot.

# General setup

rm(list = ls(all = T))      # Clear workspace

library(dplyr)
library(RODBC)
library(tidyverse)

# Used to access data on NGIS.  ODBC_Connection will have to be modified depening on the user's settings. Database is on
# DBSEP3832 server.

database1 <- "LTV"
database2 <- "pdb_WalkandWin"
ODBC_Connection = "pdbRally"

# Load the "read" function
source("read.R")

# Load the "setupMemberMonth" function
source("setupMemberMonth.R")

# Load the "Test_Diff" function
source("Test_Diff.R")

# Load the "consolidateResults" function
source("consolidateResults.R")

# Load the "bootstrapCIs" function
source("Bootstrap Confidence Intervals Value, Revenue, Cost.R")

# Load the "filteredMemberMonth" function
source("filteredMemberMonth.R")

"
The first 4 files work together, and the last two work together.

'consolidateResults' can be run on its own, and it will call the needed functions.

'Bootstrap Confidence Intervals' is meant to be run after 'consolidateResults', to get confidence intervals on 
PMPM Revenue, Cost and Value.  It uses a data set created by 'filteredMemberMonth', which in turn runs 'setupMemberMonth' if needed.

If bootstrap confidence intervals are desired, an efficient way to run things (to limit I/O and processing time is):

  Run 'filteredMemberMonth' and save the output to a data file 
  Run 'consolidateResults' passing the data file just created as a parameter
  Run 'bootstrapCIs' for variables of interest

Otherwise 'consolidateResults' can just be run on its own
"
