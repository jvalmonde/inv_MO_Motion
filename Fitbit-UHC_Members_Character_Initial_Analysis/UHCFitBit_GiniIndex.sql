/*UHC FitBit Gini Index of Income Inequality
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */


--Pulling the Gini Index of Income Inequality and matching to main population by Zip Code

--Researching Gini Table
SELECT *
FROM Census..ACS_TableDefinition a
WHERE a.TableName = 'ACS_GiniIndexOfIncomeInequality'

--Using a temp table to store main population and fields to link by
SELECT
	a.Indv_Sys_Id
	,a.ZIP_CD
	,a.ST_ABBR_CD
	,a.MM_2016
	,a.MM_2017
	INTO #Main_Pop_Temp
	FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	ORDER BY a.Indv_Sys_Id

create index id_Zip on #Main_Pop_Temp(Zip_Cd)

--Using zip code to link to Census tables to pull Gini Index scores
SELECT
a.Indv_Sys_Id
,b.Zip
,b.ZCTA
,b.County
,b.St_Cd
, b.MSA
, c.USR_Class
, d.LogRecNo
, e.B19083_001 as GiniIndex

INTO #GiniTemp
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
			SELECT [Year], StatisticsID, StateCode, LogRecNo, Chariter, [SEQUENCE], B19083_001
				FROM Census..ACS_GiniIndexOfIncomeInequality
				WHERE [Year] = 2015
				and StatisticsID = 1
			) e on e.LogRecNo = d.LogRecNo
			  and e.StateCode = d.StateCode
ORDER BY a.Indv_Sys_Id


--Updating main population table with Gini Index field

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
ADD GiniIndex varchar(50)

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET GiniIndex = (SELECT GiniIndex FROM #GiniTemp
						WHERE #GiniTemp.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)