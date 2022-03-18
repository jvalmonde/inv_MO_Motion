/*UHC FitBit -- Enrollment Tenure prior to 2017
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */

--Data Requirements
--1) # of months of enrollment in 2016
--2) Total previous months of enrollment (prior to 2017)
--3) # of consecutive months of enrollment leading up to Jan 2017
	--(Counting MM during the last consecutive enrollment period prior to 2017)

--Calculating 
--1) Months of enrollment in 2016 
--2) Total previous months of enrollment prior to 2017

SELECT 
a.Indv_Sys_Id
,COUNT(DISTINCT case when LEFT(SD.Year_Mo,4) = '2016' then Year_Mo else NULL end) AS TotalMM_2016
--,COUNT(DISTINCT case when LEFT(SD.Year_Mo,4) = '2017' then Year_Mo else NULL end) AS TotalMM_2017
,COUNT(DISTINCT case when LEFT(SD.Year_Mo,4) < '2017' then Year_Mo else NULL end) AS TotalMM

INTO pdb_UHCEmails..TenureTemp
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
JOIN MiniHPDM..Summary_Indv_Demographic SD
ON SD.Indv_Sys_Id = a.Indv_Sys_Id
GROUP BY a.Indv_Sys_Id
ORDER BY a.Indv_Sys_Id

SELECT * FROM pdb_UHCEmails..TenureTemp
ORDER BY Indv_Sys_ID

--Adding new fields to master table
/*ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD TotalMM int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET TotalMM = (SELECT TotalMM FROM pdb_UHCEmails..TenureTemp
						WHERE pdb_UHCEmails..TenureTemp.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)*/


--Calculating
--3) # of consecutive months of enrollment leading up to Jan 2017
	--(Counting MM during the last consecutive enrollment period prior to 2017)

--Step 1 Calculates the full date of the first date of new enrollment period 
--by Indv_Sys_Id

SELECT
a.Indv_Sys_ID
,DD.FULL_DT
,DD.YEAR_NBR
--,SD.Year_Mo
,CASE WHEN DateDiff(m,LAG(DD.FULL_DT) OVER(PARTITION BY a.Indv_Sys_Id ORDER BY a.Indv_Sys_Id, SD.Year_Mo),DD.FULL_DT)IS NULL	
		THEN DD.FULL_DT
		WHEN DateDIFF(M,LAG(DD.FULL_DT) OVER(PARTITION BY a.Indv_Sys_Id ORDER BY a.Indv_Sys_Id, SD.Year_Mo),DD.FULL_DT) > 1
		THEN DD.FULL_DT
		ELSE NULL
		END AS IsContinuous

INTO pdb_UHCEmails..EnrollTemp 
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a

JOIN MiniHPDM.dbo.Summary_Indv_Demographic SD
ON a.Indv_Sys_Id = SD.Indv_Sys_Id
JOIN MiniHPDM.dbo.Dim_Date DD 
ON SD.Year_Mo = DD.YEAR_MO 
WHERE DD.LST_DAY_MO_IND = 'y'
AND DD.YEAR_NBR < 2017
ORDER BY a.Indv_Sys_Id, YEAR_NBR

--Calculates the number of consecutive months of enrollment leading up to Jan 1, 2017

SELECT
	E.Indv_Sys_Id
	,MAX(E.IsContinuous) AS StartDate
	,MAX(E.FULL_Dt) AS StopDate
	,DateDiff(month,MAX(E.IsContinuous),MAX(E.FULL_DT)) +1 AS LastConsecEnrollMM
	,COUNT(E.IsContinuous) AS EnrollmentEpisodeCnt

	INTO #Consec_Enroll
	FROM pdb_UHCEmails.[dbo].[EnrollTemp] E
	GROUP BY E.Indv_Sys_Id
	ORDER BY E.Indv_Sys_Id

SELECT * FROM #Consec_Enroll
ORDER BY Indv_Sys_ID

--Merging Consecutive Enrollment #'s with NewPop unique Indv_Sys_ID

SELECT 
	A.Indv_Sys_Id
	,b.LastConsecEnrollMM
	INTO #LastConsecEnroll
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	LEFT JOIN #Consec_Enroll b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

SELECT * FROM #LastConsecEnroll
ORDER BY Indv_Sys_Id

--Updating master table with new values
	
	/*ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD LastConsecEnrollMM int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET LastConsecEnrollMM = (SELECT LastConsecEnrollMM FROM #LastConsecEnroll
						WHERE #LastConsecEnroll.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)*/
