/*UHC FitBit -- Zip Code and Census Educational Attainment (via Zip Code matching)
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */

-- 1) Zip Code and State -- adding variables to main population table
SELECT 
	a.Indv_Sys_Id
	,c.ZIP_CD
	,c.ST_ABBR_CD
	INTO #TempZipCode
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	JOIN MiniHPDM..Dim_Member b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	LEFT JOIN MiniHPDM..Dim_Zip c
	ON b.Zip = c.ZIP_CD
	ORDER BY a.Indv_Sys_Id

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD ZIP_CD char(10), ST_ABBR_CD char(10)

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET ZIP_CD = (SELECT ZIP_CD FROM #TempZipCode
				WHERE #TempZipCode.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET ST_ABBR_CD = (SELECT ST_ABBR_CD FROM #TempZipCode
				WHERE #TempZipCode.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

--2) Socioeconomic variables based on census data and member zip code
------a) Educational Attainment



--Finding appropriate column to use
/*SELECT * 
FROM Census..ACS_TableDefinition a
WHERE a.TableName LIKE 'ACS_EducationalAttainment'
ORDER BY a.ColumnName*/

----Creating Table for Educational Attainment Categories using ACS_EducationalAttainment Table
SELECT 
	a.LogRecNo
	,a.[Year]
	,a.StatisticsID
	,a.StateCode
	,a.Chariter
	,a.[SEQUENCE]
	,a.B15001_001 AS EA_TotalEdPop
	,EA_Less_9thGr = (a.B15001_004 + a.B15001_012 +a.B15001_020 + a.B15001_028 
				  + a.B15001_036 + a.B15001_045 + a.B15001_053 + a.B15001_061 
				  + a.B15001_069 + a.B15001_077)

	,EA_Gr9_12_NoDipl = (a.B15001_005 + a.B15001_013 + a.B15001_021 + a.B15001_029 
				  + a.B15001_037 + a.B15001_046 + a.B15001_054 + a.B15001_062 
				  + a.B15001_070 + a.B15001_078)

	,EA_HS_Grad_GED = (a.B15001_006 + a.B15001_014 + a.B15001_022 + a.B15001_030 
				  + a.B15001_038 + a.B15001_047 + a.B15001_055 + a.B15001_063 
				  + a.B15001_071 + a.B15001_079)

	,EA_SomeCollege_NoDeg = (a.B15001_007 + a.B15001_015 + a.B15001_023 + a.B15001_031
				  + a.B15001_039 + a.B15001_048 + a.B15001_056 + a.B15001_064 
				  + a.B15001_072 + a.B15001_080)

	,EA_Assoc_Deg = (a.B15001_008 + a.B15001_016 + a.B15001_024 + a.B15001_032
				  + a.B15001_040 + a.B15001_049 + a.B15001_057 + a.B15001_065 
				  + a.B15001_073 + a.B15001_081) 

	,EA_Bach_Deg = (a.B15001_009 + a.B15001_017 + a.B15001_025 + a.B15001_033
				  + a.B15001_041 + a.B15001_050 + a.B15001_058 + a.B15001_066 
				  + a.B15001_074 + a.B15001_082) 	

	,EA_Grad_Prof_Deg = (a.B15001_010 + a.B15001_018 + a.B15001_026 + a.B15001_034
				  + a.B15001_042 + a.B15001_051 + a.B15001_059 + a.B15001_067 
				  + a.B15001_075 + a.B15001_083) 
				    		
INTO pdb_UHCEmails.dbo.EducAttainCategory
FROM Census..ACS_EducationalAttainment a
WHERE a.Year = 2015
ORDER BY a.LogRecNo

SELECT * FROM pdb_UHCEmails.dbo.EducAttainCategory
ORDER BY LogRecNo

---Merging with population by Zip Code into Temp Table for later Percentage Calculations

SELECT
a.Indv_Sys_Id
,b.Zip
,b.ZCTA
,b.County
,b.St_Cd
, b.MSA
, c.USR_Class
, d.LogRecNo
, e.EA_TotalEdPop
, e.EA_Less_9thGr
, e.EA_Gr9_12_NoDipl
, e.EA_HS_Grad_GED
, e.EA_SomeCollege_NoDeg
, e.EA_Assoc_Deg
, e.EA_Bach_Deg
, e.EA_Grad_Prof_Deg

INTO #EducationalAttain_Temp
FROM #Main_Pop_Temp a
LEFT JOIN Census..Zip_Census b ON a.ZIP_CD = b.Zip
LEFT JOIN Census..ZCTA c on c.ZCTA = b.ZCTA
LEFT JOIN (
			SELECT LogRecNo, [Year], ZCTA, StateCode, GeographyType
				FROM Census..ACS_Geography
				WHERE [Year] = 2015
				and GeographyType = 'ZCTA Level'
		   ) d on d.ZCTA = b.ZCTA
LEFT JOIN (
			SELECT [Year], StatisticsID, StateCode, LogRecNo, Chariter, [SEQUENCE]
				, EA_TotalEdPop
				, EA_Less_9thGr
				, EA_Gr9_12_NoDipl
				, EA_HS_Grad_GED
				, EA_SomeCollege_NoDeg
				, EA_Assoc_Deg
				, EA_Bach_Deg
				, EA_Grad_Prof_Deg

				FROM pdb_UHCEmails.dbo.EducAttainCategory
				WHERE [Year] = 2015
				and StatisticsID = 1
			) e on e.LogRecNo = d.LogRecNo
			  and e.StateCode = d.StateCode
ORDER BY a.Indv_Sys_Id

SELECT * FROM #EducationalAttain_Temp


--Calculating Percent of Pop by Individual Member's zip-code

SELECT
a.Indv_Sys_Id
,CAST(ROUND(a.EA_Less_9thGr * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_Less9thGr
,CAST(ROUND(a.EA_Gr9_12_NoDipl * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_Gr9_12_NoDipl
,CAST(ROUND(a.EA_HS_Grad_GED * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_HS_Grad_GED
,CAST(ROUND(a.EA_SomeCollege_NoDeg * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_SomeCollege_NoDeg
,CAST(ROUND(a.EA_Assoc_Deg * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_Assoc_Deg
,CAST(ROUND(a.EA_Bach_Deg * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_Bach_Deg
,CAST(ROUND(a.EA_Grad_Prof_Deg * 100.0 / a.EA_TotalEdPop, 2) as decimal(5,2)) AS Pct_Grad_Prof_Deg
INTO #PctEdAttain_Temp
FROM #EducationalAttain_Temp a
WHERE a.EA_TotalEdPop > 0
ORDER BY Indv_Sys_Id


--Left Joining to Main Population table

SELECT
	a.Indv_Sys_Id AS UniqueID
	,b.*
INTO #PctEdAttain_Join
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
LEFT JOIN #PctEdAttain_Temp b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
ORDER BY a.Indv_Sys_Id

SELECT * FROM #PctEdAttain_Join
ORDER BY UniqueID


--Updating main table 

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	--ADD Pct_Less9thGr decimal(18,2)
	--ADD Pct_Gr9_12_NoDipl decimal(18,2)
	--ADD Pct_HS_Grad_GED decimal(18,2)
	--ADD Pct_SomeCollege_NoDeg decimal(18,2)
	--ADD Pct_Assoc_Deg decimal(18,2)
	--ADD Pct_Bach_Deg decimal(18,2)
	ADD Pct_Grad_Prof_Deg decimal(18,2)


UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET Pct_Grad_Prof_Deg = (SELECT Pct_Grad_Prof_Deg FROM #PctEdAttain_Join
						WHERE #PctEdAttain_Join.UniqueID = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

SELECT * FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
ORDER BY Indv_Sys_Id


