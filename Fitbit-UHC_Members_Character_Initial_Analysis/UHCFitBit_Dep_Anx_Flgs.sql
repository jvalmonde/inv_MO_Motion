/*UHC FitBit Flags for Diseases of Interest - Depression and Anxiety
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */

--START 2016 Dep/Anx Flag

--Loading 2016 continuous MM into temp table for diagnosis flag prep

DROP TABLE #TempContinuous2016

SELECT a.Indv_Sys_Id
,a.MM_2016
INTO #TempContinuous2016
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
WHERE a.MM_2016 = 12
ORDER BY a.Indv_Sys_Id

SELECT COUNT(*) FROM #TempContinuous2016


CREATE UNIQUE INDEX ixInd_Sys_ID on #TempContinuous2016(Indv_Sys_Id)

--Creating temp table to define the appropriate depression/anxiety diagnoses for filtering

DROP TABLE #DiagTypeTemp

SELECT
	D.Diag_Cd_Sys_Id
	,D.Diag_CD
	,D.DIAG_DESC
	,D.MAJ_DIAG_GRP_CD
	,D.ICD_VER_CD
	,(Case when D.Diag_Cd LIKE ('F32%') -- Maj Dep Dis Single Epi
		or D.Diag_Cd LIKE ('F33%') -- Maj Dep Dis Recurrent
		or D.Diag_Cd LIKE ('F34%') -- Persistent mood [affective] dis
		or D.Diag_Cd LIKE ('F39%') -- Unspecified mood [affective] dis
		or D.Diag_Cd LIKE ('F40%') -- Phobic Anxiety Disorders
		or D.Diag_Cd LIKE ('F41%') -- Other anxiety disorders
		or D.Diag_Cd LIKE ('F42%') -- Obsessive-Compulsive Dis
		or D.Diag_Cd LIKE ('F43%') -- Reaction to severe stress/adjustment dis
		or D.Diag_Cd LIKE ('F45%') -- Somatoform Disorders
		or D.Diag_Cd LIKE ('300%') -- Anxiety, Dissociative, Somatoform dis
		or D.Diag_Cd LIKE ('311%') -- Depressive Disorder
		 then 1 else 0 end) as Dep_Anx_Ind2016
	
	INTO #DiagTypeTemp
	FROM MiniHPDM..Dim_Diagnosis_Code D
	WHERE ((D.DIAG_CD LIKE 'F32%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F33%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F34%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F39%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F40%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F41%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F42%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F43%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F45%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE '300%' and D.ICD_VER_CD = 9)
		or (D.DIAG_CD LIKE '311%' and D.ICD_VER_CD = 9))
		AND D.MAJ_DIAG_GRP_CD <> 'UN'
	
	SELECT * FROM #DiagTypeTemp
	ORDER BY Diag_CD


--Joining in all 2016 claims data using 2016 Cont MM population
SELECT DISTINCT
	a.Indv_Sys_Id AS Member_ID
	,a.MM_2016
	,c.FULL_DT AS Claim_Date
	,DIAG_TYPE = case when (d.Dep_Anx_Ind2016 = 1 or d1.Dep_Anx_Ind2016 = 1 or d2.Dep_Anx_Ind2016 = 1) then 1 else 0 end

INTO #Temp_MH_Diag
FROM #TempContinuous2016 a
LEFT JOIN MiniHPDM..Fact_Claims b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
LEFT JOIN MiniHPDM..Dim_Date c
ON c.DT_SYS_ID = b.Dt_Sys_Id
LEFT JOIN #DiagTypeTemp d
ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
LEFT JOIN #DiagTypeTemp d1
ON d1.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
LEFT JOIN #DiagTypeTemp d2
ON D2.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
WHERE c.YEAR_NBR = 2016


--Create temp table to store MH indicator based on diagnoses
SELECT
	Member_ID
	,case when(SUM(Diag_Type)) >= 1 then 1 else 0 end AS MHDiag_Ind
INTO #MH_Diag_IndTemp
FROM #Temp_MH_Diag
GROUP BY Member_ID
ORDER BY Member_ID



----Gathering Medication qualifications

IF OBJECT_ID ('tempdb..#TempMeds') IS NOT NULL DROP TABLE #TempMeds
SELECT
	a.NDC_DRG_SYS_ID
	,a.NDC
	,a.EXT_AHFS_THRPTC_CLSS_DESC
	,a.GNRC_NM
	INTO #TempMeds
	FROM MiniHPDM..Dim_NDC_Drug a
	WHERE a.GNRC_NM IN ('citalopram hydrobromide',
							'ESCITALOPRAM OXALATE',
							'paroxetine HCl',
							'PAROXETINE MESYLATE',
							'sertraline HCl',
							'fluoxetine',
							'fluoxetine HCl',
							'FLUOXETINE HCL/DIET. SUPP NO.8',
							'FLUOXETINE HCL/DIET.SUPP NO.17',
							'FLUVOXAMINE MALEATE',
							'venlafaxine HCl',
							'desvenlafaxine',
							'desvenlafaxine fumarate',
							'desvenlafaxine succinate',
							'trimipramine maleate',
							'bupropion HBr',
							'bupropion HCl',
							'BUPROPION HCL/DIET SUPP. NO.15',
							'BUPROPION HCL/DIET SUPP. NO.16',
							'MIRTAZAPINE')

SELECT * FROM #TempMeds
ORDER BY NDC


--Merging claims data to pull out just pharmacy data related to the medications above


SELECT 
	a.Indv_Sys_Id
	,d.EXT_AHFS_THRPTC_CLSS_DESC
	,d.NDC
	,d.NDC_DRG_SYS_ID
	,d.GNRC_NM
	,c.FULL_DT
	,b.Qty_Cnt
	INTO #DepAnxMeds_Temp
	FROM #TempContinuous2016 a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN #TempMeds d
	ON d.NDC_DRG_SYS_ID = b.NDC_Drg_Sys_Id
	WHERE c.YEAR_NBR = 2016
	AND b.Srvc_Typ_Sys_Id = 4


--Create temp table to store MH indicator based on Rx claims

SELECT a.Indv_Sys_ID
	,case when (COUNT(a.Indv_Sys_ID)) >= 1 then 1 else 0 end AS MH_Rx_Ind
INTO #MH_Rx_Ind_Temp 
FROM #DepAnxMeds_Temp a
GROUP BY Indv_Sys_ID
ORDER BY Indv_Sys_ID

--Merging flag with main 2016 population
SELECT
	a.Indv_Sys_Id
	,case when(b.MH_Rx_Ind = 1) then 1 else 0 end AS MH_RxInd
	INTO #MH_Rx_Final
	FROM #TempContinuous2016 a
	LEFT JOIN #MH_Rx_Ind_Temp b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

SELECT
	a.Indv_Sys_Id
	,case when(b.MHDiag_Ind = 1) then 1 else 0 end AS MH_DiagInd
	INTO #MH_Diag_Final
	FROM #TempContinuous2016 a
	LEFT JOIN #MH_Diag_IndTemp b
	ON a.Indv_Sys_Id = b.Member_ID
	ORDER BY a.Indv_Sys_Id

--creating temp table with both types of flags (MH Diag & Rx)
SELECT a.*
	 ,b.MH_DiagInd
	 ,case when (a.MH_RxInd + b.MH_DiagInd > =1) then 1 else 0 end AS Dep_Anx_Ind
	INTO #Dep_Anx_Ind_Temp
	FROM #MH_Rx_Final a
	JOIN #MH_Diag_Final b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

SELECT * FROM #Dep_Anx_Ind_Temp

--determining final flag status

SELECT
	a.Indv_Sys_Id
	,a.MM_2016
	,case when (b.Dep_Anx_Ind is not NULL) then b.Dep_Anx_Ind else NULL end as Dep_Anx_Flg_2016
	INTO #Dep_Anx_Flag_Final
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	LEFT JOIN #Dep_Anx_Ind_Temp b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

	SELECT * FROM #Dep_Anx_Flag_Final a
	ORDER BY a.Indv_Sys_Id

	SELECT COUNT(*)
	,Dep_Anx_Flg_2016
	FROM  #Dep_Anx_Flag_Final
	GROUP BY Dep_Anx_Flg_2016

--updating main population table

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
ADD DepAnx_Flg_2016 int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET DepAnx_Flg_2016 = (SELECT Dep_Anx_Flg_2016 FROM #Dep_Anx_Flag_Final
						WHERE #Dep_Anx_Flag_Final.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

SELECT COUNT(*)
	,DepAnx_Flg_2016
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop
	GROUP BY DepAnx_Flg_2016

--START 2017 Depression/Anxiety Flags

--Loading 2017 continuous MM into temp table for diagnosis flag prep

SELECT a.Indv_Sys_Id
	,a.MM_2017
INTO #TempContinuous2017
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
ORDER BY a.Indv_Sys_Id

SELECT * FROM #TempContinuous2017
ORDER BY Indv_Sys_Id


CREATE UNIQUE INDEX ixInd_Sys_ID on #TempContinuous2017(Indv_Sys_Id)

DROP TABLE #DiagTypeTemp

SELECT
	D.Diag_Cd_Sys_Id
	,D.Diag_CD
	,D.DIAG_DESC
	,D.MAJ_DIAG_GRP_CD
	,D.ICD_VER_CD
	,(Case when D.Diag_Cd LIKE ('F32%') 
		or D.Diag_Cd LIKE ('F33%') 
		or D.Diag_Cd LIKE ('F34%')
		or D.Diag_Cd LIKE ('F39%') 
		or D.Diag_Cd LIKE ('F40%')
		or D.Diag_Cd LIKE ('F41%')
		or D.Diag_Cd LIKE ('F42%')
		or D.Diag_Cd LIKE ('F43%')
		or D.Diag_Cd LIKE ('F45%')
		or D.Diag_Cd LIKE ('300%')
		or D.Diag_Cd LIKE ('311%') then 1 else 0 end) as Dep_Anx_Ind2017
	
	INTO #DiagTypeTemp
	FROM MiniHPDM..Dim_Diagnosis_Code D
	WHERE ((D.DIAG_CD LIKE 'F32%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F33%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F34%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F39%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F40%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F41%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F42%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F43%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE 'F45%' and D.ICD_VER_CD = 0)
		or (D.DIAG_CD LIKE '300%' and D.ICD_VER_CD = 9)
		or (D.DIAG_CD LIKE '311%' and D.ICD_VER_CD = 9))
		AND D.MAJ_DIAG_GRP_CD <> 'UN'
	
	SELECT * FROM #DiagTypeTemp
	ORDER BY Diag_CD


--Joining in all 2017 claims data using 2017 Cont MM population
SELECT DISTINCT
	a.Indv_Sys_Id AS Member_ID
	,a.MM_2017
	,c.FULL_DT AS Claim_Date
	,DIAG_TYPE = case when (d.Dep_Anx_Ind2017 = 1 or d1.Dep_Anx_Ind2017 = 1 or d2.Dep_Anx_Ind2017 = 1) then 1 else 0 end

INTO #Temp_MH_Diag2017
FROM #TempContinuous2017 a
JOIN MiniHPDM..Fact_Claims b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
JOIN MiniHPDM..Dim_Date c
ON c.DT_SYS_ID = b.Dt_Sys_Id
LEFT JOIN #DiagTypeTemp d
ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
LEFT JOIN #DiagTypeTemp d1
ON d1.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
LEFT JOIN #DiagTypeTemp d2
ON D2.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
WHERE c.YEAR_NBR = 2017

SELECT TOP (1000) *
	FROM #Temp_MH_Diag2017


SELECT
	Member_ID
	,case when(SUM(Diag_Type)) >= 1 then 1 else 0 end AS MHDiag_Ind
INTO #MH_Diag_IndTemp2017
FROM #Temp_MH_Diag2017
GROUP BY Member_ID
ORDER BY Member_ID

SELECT * FROM #MH_Diag_IndTemp2017
ORDER BY Member_ID

SELECT
	a.Indv_Sys_Id
	,case when(b.MHDiag_Ind = 1) then 1 else 0 end AS MH_DiagInd
	INTO #MH_Diag_Final2017
	FROM #TempContinuous2017 a
	LEFT JOIN #MH_Diag_IndTemp2017 b
	ON a.Indv_Sys_Id = b.Member_ID
	ORDER BY a.Indv_Sys_Id

SELECT * FROM #MH_Diag_Final2017 a
ORDER BY a.Indv_Sys_Id

----Gathering Medication qualifications

IF OBJECT_ID ('tempdb..#TempMeds') IS NOT NULL DROP TABLE #TempMeds
SELECT
	a.NDC_DRG_SYS_ID
	,a.NDC
	,a.EXT_AHFS_THRPTC_CLSS_DESC
	,a.GNRC_NM
	INTO #TempMeds
	FROM MiniHPDM..Dim_NDC_Drug a
	WHERE a.GNRC_NM IN ('citalopram hydrobromide',
							'ESCITALOPRAM OXALATE',
							'paroxetine HCl',
							'PAROXETINE MESYLATE',
							'sertraline HCl',
							'fluoxetine',
							'fluoxetine HCl',
							'FLUOXETINE HCL/DIET. SUPP NO.8',
							'FLUOXETINE HCL/DIET.SUPP NO.17',
							'FLUVOXAMINE MALEATE',
							'venlafaxine HCl',
							'desvenlafaxine',
							'desvenlafaxine fumarate',
							'desvenlafaxine succinate',
							'trimipramine maleate',
							'bupropion HBr',
							'bupropion HCl',
							'BUPROPION HCL/DIET SUPP. NO.15',
							'BUPROPION HCL/DIET SUPP. NO.16',
							'MIRTAZAPINE')

SELECT * FROM #TempMeds
ORDER BY NDC


--Merging claims data to pull out just pharmacy data related to the medications above


SELECT 
	a.Indv_Sys_Id
	,d.EXT_AHFS_THRPTC_CLSS_DESC
	,d.NDC
	,d.NDC_DRG_SYS_ID
	,d.GNRC_NM
	,c.FULL_DT
	,b.Qty_Cnt
	INTO #DepAnxMeds_Temp2017
	FROM #TempContinuous2017 a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN #TempMeds d
	ON d.NDC_DRG_SYS_ID = b.NDC_Drg_Sys_Id
	WHERE c.YEAR_NBR = 2016
	AND b.Srvc_Typ_Sys_Id = 4

SELECT a.Indv_Sys_ID
	,case when (COUNT(a.Indv_Sys_ID)) >= 1 then 1 else 0 end AS MH_Rx_Ind
INTO #MH_Rx_Ind_Temp2017 
FROM #DepAnxMeds_Temp2017 a
GROUP BY Indv_Sys_ID
ORDER BY Indv_Sys_ID

--Using temp tables to line up flags for final flag creation

SELECT
	a.Indv_Sys_Id
	,case when(b.MH_Rx_Ind = 1) then 1 else 0 end AS MH_RxInd
	INTO #MH_Rx_Final2017
	FROM #TempContinuous2017 a
	LEFT JOIN #MH_Rx_Ind_Temp2017 b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

SELECT a.*
	 ,b.MH_DiagInd
	 ,case when (a.MH_RxInd + b.MH_DiagInd >= 1) then 1 else 0 end AS Dep_Anx_Ind
	INTO #Dep_Anx_Ind_Temp2017
	FROM #MH_Rx_Final2017 a
	JOIN #MH_Diag_Final2017 b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

SELECT * FROM #Dep_Anx_Ind_Temp2017
ORDER BY Indv_Sys_ID

SELECT
	a.Indv_Sys_Id
	,a.MM_2017
	,case when (b.Dep_Anx_Ind is not NULL) then b.Dep_Anx_Ind else NULL end as Dep_Anx_Flg_2017
	INTO #Dep_Anx_Flag_Final2017
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	LEFT JOIN #Dep_Anx_Ind_Temp2017 b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY a.Indv_Sys_Id

	SELECT * FROM #Dep_Anx_Flag_Final2017 a
	ORDER BY a.Indv_Sys_Id

	SELECT COUNT(*)
	,Dep_Anx_Flg_2017
	FROM  #Dep_Anx_Flag_Final2017
	GROUP BY Dep_Anx_Flg_2017

--Updating main population table with 2017 mh flag

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
ADD DepAnx_Flg_2017 int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET DepAnx_Flg_2017 = (SELECT Dep_Anx_Flg_2017 FROM #Dep_Anx_Flag_Final2017
						WHERE #Dep_Anx_Flag_Final2017.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

SELECT COUNT(*)
	,DepAnx_Flg_2017
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop
	GROUP BY DepAnx_Flg_2017