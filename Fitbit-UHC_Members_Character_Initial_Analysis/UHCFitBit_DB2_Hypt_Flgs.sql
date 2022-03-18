/*UHC FitBit Flags for Diseases of Interest -Type 2 Diabetes & Hypertension
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */

/*
--2017 and 2016 Flags for diseases of interest
--1) Type 2 Diabetes
	--a) At least 2 diabetes Diagnoses at least 15 days apart
	--b) Must have at least 90% of diabetes diagnoses as type 2
--2) Hypertension
	--a) At least one diagnosis in AHRQ_DTL_CATGY_CD = 098 or 099 
			--(Use Dim_Diagnosis_Code)
--3) Depression and Anxiety
	--a) One prescription filled for any of the following drugs -OR- 
		 Any depression or anxiety diagnosis
		 Eligible Rx Drug List:
		--SSRI's
		--1) Citalopram
		--2) Escitalopram
		--3) Paroxetine
		--4) Sertraline
		--5) Fluoxetine
		--6) Fluvoxamine
		--SNRI's
		--1) Venlafaxine
		--2) Desvenlafaxine
		--Tricyclic Antidepressants
		--1) Trimipramine
		--Other
		--1) Buproprion
		--2) Mirtazapine
		--Eligible Diagnoses List:
			--Depression/Anxiety
			('F32%') -- Maj Dep Dis Single Epi
			('F33%') -- Maj Dep Dis Recurrent
			('F34%') -- Persistent mood [affective] dis
			('F39%') -- Unspecified mood [affective] dis
			('F40%') -- Phobic Anxiety Disorders
			('F41%') -- Other anxiety disorders
			('F42%') -- Obsessive-Compulsive Dis
			('F43%') -- Reaction to severe stress/adjustment dis
			('F45%') -- Somatoform Disorders
			('300%') -- Anxiety, Dissociative, Somatoform dis
			('311%') -- Depressive Disorder
--4) Rheumatoid Arthritis and Specified Autoimmune Disorders
	--a) Use HCC 056
--5) COPD
	--a) Use HCC 160
--6) Congestive Heart Failure
	--a) Use HCC 130


	*/

-- START 2016 Type 2 Diabetes 

--1) Loading 2016 continuous MM into temp table for diagnosis flag prep

SELECT a.*
,b.MM_2016
INTO #TempContinuous2016
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
JOIN MiniHPDM.dbo.Dim_Member b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
WHERE b.MM_2016 = 12
ORDER BY a.Indv_Sys_Id

SELECT * FROM #TempContinuous2016
ORDER BY Indv_Sys_Id

CREATE UNIQUE INDEX ixInd_Sys_ID on #TempContinuous2016(Indv_Sys_Id)

--2) Creating diabetes condition table to help filter claims data
SELECT
	DIAG_CD_SYS_ID
	,Diag_CD
	,DIAG_DESC
	,MAJ_DIAG_GRP_CD
	,ICD_VER_CD
	,DIAB_TYPE = case when (DIAG_CD LIKE 'E11%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%2%' and ICD_VER_CD = 0)
							or (DIAG_CD LIKE '250%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%TYPE II%' and ICD_VER_CD = 9)
							then 'Type 2' else 'Type 1' end
	INTO #DiagTypeTemp
	FROM MiniHPDM..Dim_Diagnosis_Code
	WHERE (DIAG_CD LIKE 'E11%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%2%' and ICD_VER_CD = 0)
		or (DIAG_CD LIKE '250%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%TYPE II%' and ICD_VER_CD = 9)
		or (DIAG_CD LIKE 'E10%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%1%' and ICD_VER_CD = 0)
		or (DIAG_CD LIKE '250%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%TYPE I%' and ICD_VER_CD = 9)
	
	SELECT * FROM #DiagTypeTemp
	ORDER BY ICD_VER_CD, DIAB_TYPE, DIAG_CD


--3) Joining in all 2016 claims data using 2016 Cont MM population using diabetes condition
--table to filter output

SELECT DISTINCT
	a.Indv_Sys_Id AS Member_ID
	,a.MM_2016
	--,a.Diabetes
	,c.FULL_DT AS Claim_Date
	,DIAG_TYPE = case when (d.DIAB_TYPE = 'Type 1' or d1.DIAB_TYPE = 'Type 1' or d2.DIAB_TYPE = 'Type 1') then 'Type 1'
					when (d.DIAB_TYPE = 'Type 2' or d1.DIAB_TYPE = 'Type 2' or d2.DIAB_TYPE = 'Type 2') then 'Type 2' end
	,b.*
INTO pdb_UHCEmails.dbo.DBClaimsDiag_2016
FROM #TempContinuous2016 a
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
WHERE c.YEAR_NBR = 2016


--4) Creating labels for 2016 Claims Data --> based on Type of DB classification
--and having a minimum of 2 diagnoses at least 15 days apart.

SELECT
	x.Member_ID
	,MinT2DiagDt = MinDate
	,DiabLabelCombined = case when Type2_prcent_clm = 1 then 'Type 2 -- 100'
							when Type2_prcent_clm >= .9 then 'Type 2 -- 90'
							when Type2_prcent_clm >= .8 then 'Type 2 -- 80'
							when Type2_prcent_clm >= .7 then 'Type 2 -- 70'

							when Type1_prcent_clm = 1 then 'Type 1 -- 100'
							when Type1_prcent_clm >= .9 then 'Type 1 -- 90'
							when Type1_prcent_clm >= .8 then 'Type 2 -- 80'
							when Type1_prcent_clm >= .7 then 'Type 2 -- 70'
							else 'Unclear' end
	,x.Day_Gap_Flag
	,x.TotDiabCnt
INTO pdb_UHCEmails.dbo.DBType2Diab_2016
FROM
	(SELECT DISTINCT Member_ID
		,Type2_Prcent_clm = max((Total_Type2_DiagCnt * 1.0) / nullif((Total_Type1_DiagCnt + Total_Type2_DiagCnt),0))
		,Type1_Prcent_clm = max((Total_Type1_DiagCnt * 1.0) / nullif((Total_Type1_DiagCnt + Total_Type2_DiagCnt),0))
		,Day_Gap_Flag = max(case when datediff(dd, MinDate, MaxDate) >= 15 then 1 else 0 end)
		,MinDate = min(MinDate)
		,TotDiabCnt = SUM(Total_Type1_DiagCnt) + SUM(Total_Type2_DiagCnt)
		
		FROM	
			(SELECT 
			a.Member_ID
			,Total_Type1_DiagCnt = count(distinct case when a.Diag_Type = 'Type 1' then a.Dt_Sys_ID end)
			,Total_Type2_DiagCnt = count(distinct case when a.Diag_Type = 'Type 2' then a.Dt_Sys_ID end)
			,MinDate = min(case when a.Diag_Type = 'Type 2' then a.Claim_Date end)
			,MaxDate = max(case when a.Diag_Type = 'Type 2' then a.Claim_Date end)

			FROM pdb_UHCEmails..DBClaimsDiag_2016 a
			GROUP BY a.Member_ID
			)x
	GROUP BY x.Member_ID
	)x
GROUP BY x.Member_ID, Type2_prcent_clm, Type1_Prcent_clm, Day_Gap_Flag, MinDate,TotDiabCnt 
ORDER BY x.Member_ID, Type2_prcent_clm, Type1_Prcent_clm, Day_Gap_Flag, MinDate,TotDiabCnt 

SELECT * from pdb_UHCEmails.dbo.DBType2Diab_2016
ORDER BY Member_ID

--5) Creating temp table for Diabetes Flag for 2016 population
DROP TABLE #Temp2016Diabetes
SELECT
	a.Indv_Sys_Id
	,DB_Flg_2016 = (Case when ((b.DiabLabelCombined LIKE 'Type 2 -- 100'
							or b.DiabLabelCombined LIKE 'Type 2 -- 90')
							AND b.Day_Gap_Flag = 1
							AND b.TotDiabCnt >= 2) then 1 
						 when (a.MM_2016 IS NULL) then null
						 else 0
						 end)

	INTO #Temp2016Diabetes
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	LEFT JOIN pdb_UHCEmails.dbo.DBType2Diab_2016 b
	ON b.Member_ID = a.Indv_Sys_Id

	/*SELECT COUNT(Indv_Sys_Id)
	,DB_Flg_2016
	FROM #Temp2016Diabetes
	GROUP BY DB_Flg_2016*/
	
--6) Adding new DB2_2016 flag columns to Mem_Cont_2017_HPDM_NewPop table
ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
ADD DB_Flg_2016 int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET DB2_Flg_2016 = (SELECT DB_Flg_2016 FROM #Temp2016Diabetes
					WHERE #Temp2016Diabetes.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

SELECT COUNT(Indv_Sys_Id)
  ,a.DB2_Flg_2016
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
GROUP BY DB2_Flg_2016


-- START 2017 Type 2 Diabetes 

--1) Loading 2017 continuous MM into temp table for diagnosis flag prep

SELECT a.*
--,b.MM_2017
INTO #TempContinuous2017
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a

CREATE UNIQUE INDEX ixInd_Sys_ID on #TempContinuous2017(Indv_Sys_Id)

--2) Creating temp table to define the appropriate Type 1 and Type 2 DB diagnoses for filtering

SELECT
	DIAG_CD_SYS_ID
	,Diag_CD
	,DIAG_DESC
	,MAJ_DIAG_GRP_CD
	,ICD_VER_CD
	,DIAB_TYPE = case when (DIAG_CD LIKE 'E11%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%2%' and ICD_VER_CD = 0)
							or (DIAG_CD LIKE '250%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%TYPE II%' and ICD_VER_CD = 9)
							then 'Type 2' else 'Type 1' end
	INTO #DiagTypeTemp2017
	FROM MiniHPDM..Dim_Diagnosis_Code
	WHERE (DIAG_CD LIKE 'E11%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%2%' and ICD_VER_CD = 0)
		or (DIAG_CD LIKE '250%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%TYPE II%' and ICD_VER_CD = 9)
		or (DIAG_CD LIKE 'E10%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%1%' and ICD_VER_CD = 0)
		or (DIAG_CD LIKE '250%' AND MAJ_DIAG_GRP_CD <> 'UN' AND DIAG_DESC like '%TYPE I%' and ICD_VER_CD = 9)
	
	SELECT * FROM #DiagTypeTemp2017
	ORDER BY ICD_VER_CD, DIAB_TYPE, DIAG_CD

--3) Joining in 2017 claims data

SELECT DISTINCT
	a.Indv_Sys_Id AS Member_ID
	,a.MM_2017
	--,a.Diabetes
	,c.FULL_DT AS Claim_Date
	,DIAG_TYPE = case when (d.DIAB_TYPE = 'Type 1' or d1.DIAB_TYPE = 'Type 1' or d2.DIAB_TYPE = 'Type 1') then 'Type 1'
					when (d.DIAB_TYPE = 'Type 2' or d1.DIAB_TYPE = 'Type 2' or d2.DIAB_TYPE = 'Type 2') then 'Type 2' end
	,b.*
INTO pdb_UHCEmails.dbo.DBClaimsDiag_2017
FROM #TempContinuous2017 a
JOIN MiniHPDM..Fact_Claims b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
JOIN MiniHPDM..Dim_Date c
ON c.DT_SYS_ID = b.Dt_Sys_Id
LEFT JOIN #DiagTypeTemp2017 d
ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
LEFT JOIN #DiagTypeTemp2017 d1
ON d1.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
LEFT JOIN #DiagTypeTemp2017 d2
ON D2.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
WHERE c.YEAR_NBR = 2017

CREATE INDEX id2Member_ID on DBClaimsDiag_2017(Member_ID)

--4) Creating labels for 2016 Claims Data --> based on Type of DB classification
--and having a minimum of 2 diagnoses at least 15 days apart.

SELECT
	x.Member_ID
	,MinT2DiagDt = MinDate
	,DiabLabelCombined = case when Type2_prcent_clm = 1 then 'Type 2 -- 100'
							when Type2_prcent_clm >= .9 then 'Type 2 -- 90'
							when Type2_prcent_clm >= .8 then 'Type 2 -- 80'
							when Type2_prcent_clm >= .7 then 'Type 2 -- 70'

							when Type1_prcent_clm = 1 then 'Type 1 -- 100'
							when Type1_prcent_clm >= .9 then 'Type 1 -- 90'
							when Type1_prcent_clm >= .8 then 'Type 2 -- 80'
							when Type1_prcent_clm >= .7 then 'Type 2 -- 70'
							else 'Unclear' end
	,x.Day_Gap_Flag
	,x.TotDiabCnt
INTO pdb_UHCEmails.dbo.DBType2Diab_2017
FROM
	(SELECT DISTINCT Member_ID
		,Type2_Prcent_clm = max((Total_Type2_DiagCnt * 1.0) / nullif((Total_Type1_DiagCnt + Total_Type2_DiagCnt),0))
		,Type1_Prcent_clm = max((Total_Type1_DiagCnt * 1.0) / nullif((Total_Type1_DiagCnt + Total_Type2_DiagCnt),0))
		,Day_Gap_Flag = max(case when datediff(dd, MinDate, MaxDate) >= 15 then 1 else 0 end)
		,MinDate = min(MinDate)
		,TotDiabCnt = SUM(Total_Type1_DiagCnt) + SUM(Total_Type2_DiagCnt)
		
		FROM	
			(SELECT 
			a.Member_ID
			,Total_Type1_DiagCnt = count(distinct case when a.Diag_Type = 'Type 1' then a.Dt_Sys_ID end)
			,Total_Type2_DiagCnt = count(distinct case when a.Diag_Type = 'Type 2' then a.Dt_Sys_ID end)
			,MinDate = min(case when a.Diag_Type = 'Type 2' then a.Claim_Date end)
			,MaxDate = max(case when a.Diag_Type = 'Type 2' then a.Claim_Date end)

			FROM pdb_UHCEmails..DBClaimsDiag_2017 a
			GROUP BY a.Member_ID
			)x
	GROUP BY x.Member_ID
	)x
GROUP BY x.Member_ID, Type2_prcent_clm, Type1_Prcent_clm, Day_Gap_Flag, MinDate,TotDiabCnt 
ORDER BY x.Member_ID, Type2_prcent_clm, Type1_Prcent_clm, Day_Gap_Flag, MinDate,TotDiabCnt 

SELECT * from pdb_UHCEmails.dbo.DBType2Diab_2017
ORDER BY Member_ID


--5) Creating temp table for Diabetes Flag for 2017 population

SELECT
	a.Indv_Sys_Id
	,a.Diabetes
	,DB_Flg_2017 = (Case when ((b.DiabLabelCombined LIKE 'Type 2 -- 100'
							or b.DiabLabelCombined LIKE 'Type 2 -- 90')
							AND b.Day_Gap_Flag = 1
							AND b.TotDiabCnt >= 2) then 1 else 0 end)
	INTO #Temp2017Diabetes
	FROM dbo.Mem_Cont_2017_HPDM_NewPop a
	LEFT JOIN pdb_UHCEmails.dbo.DBType2Diab_2017 b
	ON b.Member_ID = a.Indv_Sys_Id

	ORDER BY Indv_Sys_Id

--6) Adding new flag columns to Mem_Cont_2017_HPDM_NewPop table
	ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD DB_Flg_2017 int

	UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET DB2_Flg_2017 = (SELECT DB_Flg_2017 FROM #Temp2017Diabetes
					WHERE #Temp2017Diabetes.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

--START 2016 Hypertension

--1) Gathering population and diagnosis codes for Hypertension flag creation 2016

CREATE UNIQUE INDEX ixInd_Sys_ID on pdb_UHCEmails..[Mem_Cont_2017_HPDM_NewPop_MM2016](Indv_Sys_Id)


--2) Creating temp table with appropriate diagnoses by which to filter claims by
SELECT 
*
INTO #TempDiag2016
FROM MiniHPDM.dbo.Dim_Diagnosis_Code D
WHERE D.AHRQ_DIAG_DTL_CATGY_CD IN (098, 099)
ORDER BY D.DIAG_CD_SYS_ID

SELECT * FROM #TempDiag2016


--3) Adding 2016 claims data to 2016 Cont MM population - specifying Hypertension diagnoses
SELECT DISTINCT
a.Indv_Sys_Id AS Member_ID
,c.FULL_DT
,C.YEAR_MO
,C.YEAR_NBR
,d.DIAG_CD AS D1
,d2.DIAG_CD AS D2
,d3.DIAG_CD AS D3
,Hyp_Flag = case when (d.AHRQ_DIAG_DTL_CATGY_CD = 098 or d2.AHRQ_DIAG_DTL_CATGY_CD = 098 or d3.AHRQ_DIAG_DTL_CATGY_CD = 098
					or d.AHRQ_DIAG_DTL_CATGY_CD = 099 or d2.AHRQ_DIAG_DTL_CATGY_CD = 099 or d3.AHRQ_DIAG_DTL_CATGY_CD = 099)
					THEN 1 else 0 end
 ,b.*
INTO #TempHypertension2016
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop_MM2016 a
JOIN MiniHPDM.dbo.Fact_Claims b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
JOIN MiniHPDM..Dim_Date c
ON c.DT_SYS_ID = b.Dt_Sys_Id
LEFT JOIN #TempDiag2016 d
ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
LEFT JOIN #TempDiag2016 d2
ON d2.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
LEFT JOIN #TempDiag2016 d3
ON d3.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
WHERE YEAR_NBR = 2016
ORDER BY a.Indv_Sys_Id

--4) coding for 2016 hypertension flag
SELECT DISTINCT
	a.Indv_Sys_Id
	,Hyp_Flag = MAX(case when a.Hyp_Flag = 1 then 1 else 0 end)
	INTO #TempHypFlag_2016
	FROM #TempHypertension2016 a
	GROUP BY a.Indv_Sys_Id

	SELECT * FROM #TempHypFlag_2016
	ORDER BY Indv_Sys_Id


SELECT 
	HypFlag_2016 = case when a.Hyp_Flag = 1 then 1 
						when b.MM_2016 IS NULL then NULL
						else 0 end
	,b.*
	INTO #TempAll
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop b
	LEFT JOIN #TempHypFlag_2016 a
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY b.Indv_Sys_Id

	SELECT COUNT(*)
	,HypFlag_2016
	,Hypertension
	FROM #TempAll
	GROUP BY HypFlag_2016, Hypertension

--5) Adding new flag columns to Mem_Cont_2017_HPDM_NewPop table
/*ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
ADD Hyp_Flg_2016 int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET Hyp_Flg2016 = (SELECT Hyp_Flag_2016 FROM #TempAll
						WHERE #TempAll.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)*/

--START 2016 Hypertension


--1) Gathering population and diagnosis codes for Hypertension flag creation 2017

SELECT *
INTO #TempContinuous2017
FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop

CREATE UNIQUE INDEX ixInd_Sys_ID on #TempContinuous2017(Indv_Sys_Id)

SELECT 
*
INTO #TempDiag2017
FROM MiniHPDM.dbo.Dim_Diagnosis_Code D
WHERE D.AHRQ_DIAG_DTL_CATGY_CD IN (098, 099)
ORDER BY D.DIAG_CD_SYS_ID

SELECT * FROM #TempDiag2017

--2) Adding 2017 claims data to 2017 Cont MM population - specifying Hypertension diagnoses


SELECT DISTINCT
a.Indv_Sys_Id AS Member_ID
,c.FULL_DT
,C.YEAR_MO
,C.YEAR_NBR
,d.DIAG_CD AS D1
,d2.DIAG_CD AS D2
,d3.DIAG_CD AS D3
,Hyp_Flag = case when (d.AHRQ_DIAG_DTL_CATGY_CD = 098 or d2.AHRQ_DIAG_DTL_CATGY_CD = 098 or d3.AHRQ_DIAG_DTL_CATGY_CD = 098
					or d.AHRQ_DIAG_DTL_CATGY_CD = 099 or d2.AHRQ_DIAG_DTL_CATGY_CD = 099 or d3.AHRQ_DIAG_DTL_CATGY_CD = 099)
					THEN 1 else 0 end
 ,b.*
INTO #TempHypertension2017
FROM #TempContinuous2017 a
JOIN MiniHPDM.dbo.Fact_Claims b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
JOIN MiniHPDM..Dim_Date c
ON c.DT_SYS_ID = b.Dt_Sys_Id
LEFT JOIN #TempDiag2017 d
ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
LEFT JOIN #TempDiag2017 d2
ON d2.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
LEFT JOIN #TempDiag2017 d3
ON d3.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
WHERE c.YEAR_NBR = 2017
ORDER BY a.Indv_Sys_Id

--3) coding for 2016 hypertension flag
SELECT DISTINCT
	a.Indv_Sys_Id
	,Hyp_Flag = MAX(case when a.Hyp_Flag = 1 then 1 else 0 end)
	INTO #TempHypFlag_2017
	FROM #TempHypertension2017 a
	GROUP BY a.Indv_Sys_Id

	SELECT * FROM #TempHypFlag_2017
	ORDER BY Indv_Sys_Id

	SELECT 
	Hyp_Flag_2017 = case when a.Hyp_Flag = 1 then 1 else 0 end
	,b.*
	INTO #TempAll
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop b
	LEFT JOIN #TempHypFlag_2017 a
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	ORDER BY b.Indv_Sys_Id

	SELECT COUNT(*)
	,Hyp_Flag_2017
	,Hypertension
	FROM #TempAll
	GROUP BY Hyp_Flag_2017, Hypertension

--4) Adding new flag columns to Mem_Cont_2017_HPDM_NewPop table
/*ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD Hyp_Flg2017 int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET Hyp_Flg2017 = (SELECT Hyp_Flag_2017 FROM #TempAll
						WHERE #TempAll.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)*/