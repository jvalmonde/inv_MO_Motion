/*UHC FitBit Flags for Diseases of Interest - Other Disease Flags based on HCC (from RAF) Scores
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */

--Creating temp table to Join 2016 and 2017 HCC scores into master table
SELECT
a.Indv_Sys_Id
,a.MM_2016
,a.MM_2017
,b.HCC056 AS RA_2017 --rheumatoid arthritis and specified autoimmune disorders
,c.HCC056 AS RA_2016
,b.HCC160 AS COPD_2017 --COPD
,c.HCC160 AS COPD_2016
,b.HCC130 AS CHF_2017 --Congestive Heart Failure
,c.HCC130 AS CHF_2016
INTO #TempRAFMerge
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
JOIN pdb_UHCEmails..MM2017_RAF b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
LEFT JOIN pdb_UHCEmails..MM2016_RAF c
ON a.Indv_Sys_Id = c.Indv_Sys_Id
ORDER BY a.Indv_Sys_Id

SELECT * FROM #TempRAFMerge
ORDER BY Indv_Sys_ID

--Updating main population table with condition flags

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD RA_Flg_2016 int, COPD_Flg_2016 int, HrtFail_Flg_2016 int, 
		RA_Flg_2017 int, COPD_Flg_2017 int, HrtFail_Flg_2017 int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET HrtFail_Flg_2017 = (SELECT CHF_2017 FROM #TempRAFMerge
						WHERE #TempRAFMerge.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

