/*UHC FitBit 20 Percent Sample Preparation
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 

1) Create table with random 20 percent sample from 
Member Continuous 2017 HPDM Summary of Fully-Insured and Non Fitbit Users

Step 1 - Validate the counts for only those members with Continuous MM in 2017
and Insurance = 'UHC-FI' 
NOTE: When looking at the Member_Continuous_2017_HPDM_Summary in Nov 2018 (it was built in Aug 2018)
I noticed that the data must've been updated since as 2,222 members from the original 2.5 million
no longer had 12 mo continuous MM in 2017.  I took the entire summary table and re-filtered based on
Dim_Member for MM_2017 = 12 to remove those 2,222 members.
*/

--Step 2 - Randomly select 20 percent of the no-fitbit population to create new
--study population.

SELECT top 20 percent
a.*
,b.MM_2017
into pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NoFB_20Percent
from pdb_UHCEmails.dbo.Member_Continuous_2017_HPDM_Summary a
JOIN MiniHPDM..Dim_Member b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
where a.isFitbit = 0
AND a.Insurance = 'UHC-FI'
AND b.MM_2017 = 12
order by newid()

--Step 2 - Merge the 20 percent no-fitbit sample and the entire yes-fitbit sample together
--into one master table.

SELECT a.*, b.MM_2017 
INTO  #TempPop1
FROM pdb_UHCEmails..Member_Continuous_2017_HPDM_Summary a
JOIN MiniHPDM.dbo.Dim_Member b 
ON a.Indv_Sys_Id = b.Indv_Sys_Id
WHERE a.isFitbit = 1
AND a.Insurance = 'UHC-FI'
AND b.MM_2017 = 12

SELECT *
INTO pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
FROM #TempPop1

UNION ALL
SELECT *
FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NoFB_20Percent
ORDER BY Indv_Sys_Id

--Step 3 - Verifying new sample counts

SELECT
  COUNT(*) AS NewPopCount
  ,Insurance
  ,HaveEmail
  ,HaveFitbit
 
  FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
  GROUP BY Insurance, HaveEmail, HaveFitbit
  ORDER BY Insurance, HaveEmail, HaveFitbit

  --Total N = 609276