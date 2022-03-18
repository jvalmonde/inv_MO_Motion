/*UHC FitBit Median Income Two Ways (Zip Code and GeoBlock)
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */


--START Zip Code matching to provide Median Income Census data

--Pulling fields from the main study population table into Temp table

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
--N = 609276

--Replicating Rodney's code to join Median Income

SELECT
a.Indv_Sys_Id
,b.Zip
,b.ZCTA
,b.County
,b.St_Cd
, b.MSA
, c.USR_Class
, d.LogRecNo
, e.B19013_001 as Median_Income
INTO #MedianIncome
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
			SELECT [Year], StatisticsID, StateCode, LogRecNo, Chariter, [SEQUENCE], B19013_001
				FROM Census..ACS_MedianIncome
				WHERE [Year] = 2015
				and StatisticsID = 1
			) e on e.LogRecNo = d.LogRecNo
			  and e.StateCode = d.StateCode
ORDER BY a.Indv_Sys_Id

--N = 609276
--Updating main population table with new field

ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD Median_Income int

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET Median_Income = (SELECT Median_Income FROM #MedianIncome
						WHERE #MedianIncome.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)

--START GeoBlock matching to provide Median Income Census data

--Finding the most appropriate address_id based on 
--Year membership of 2017 and most recent address
SELECT
a.Indv_Sys_Id
,xx.Address_id
INTO pdb_UHCEmails..TempGeoAddressID
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
LEFT JOIN 
	(SELECT DISTINCT
		x.Indv_Sys_Id
		,MAX(x.Address_id) as Address_ID
	FROM  
		(SELECT DISTINCT
			a.Indv_Sys_id
			,a.Address_id
			,MAX(Year_Mo) AS Max_YearMo
			FROM MiniHPDM..Summary_Indv_Demographic a
			WHERE a.Year_Mo LIKE '2017%'
			GROUP BY a.Indv_Sys_Id, a.Address_id) x
	GROUP BY x.Indv_Sys_Id)xx
ON a.Indv_Sys_Id = xx.Indv_Sys_Id

ORDER BY a.Indv_Sys_Id

--Joining address to GeocodeRepo..GeocodeAddress to get GeoID
SELECT
	b.Indv_Sys_Id
	,a.Address_ID
	,a.GeoID
	
INTO #GeocodeTemp
FROM GeocodeRepo..GeocodedAddress a
RIGHT JOIN pdb_UHCEmails..TempGeoAddressID b
ON a.Address_ID = b.Address_id
ORDER BY b.Indv_Sys_Id

--Getting block level Log Rec, State Code and Year to use for matching to Census 
--median income data
SELECT
a.Indv_Sys_Id
	,a.GeoID
	,a.Address_ID
	,b.LogRecNo
	,b.StateCode
	,b.[Year]

INTO #CensusGeo_Temp
FROM #GeocodeTemp a
	LEFT JOIN (SELECT DISTINCT
				MIN(x.LogRecNo) as LogRecNo
				,GeoID
				,x.StateCode
				,x.[Year]
				FROM Census..ACS_Geography x
				WHERE x.Year = '2015'
				AND GeographyType = 'Block Group Level'
				GROUP BY 
				x.GeoID
				,x.StateCode
				,x.[Year]
				)b
	ON b.GeoID = a.GeoID
	ORDER BY a.Indv_Sys_Id

--Using Geo Block level data to pull Census Median Income field

SELECT
a.Indv_Sys_Id
, e.B19013_001 as GeoMedian_Income
INTO #GeoMedianIncome
FROM #CensusGeo_Temp a
LEFT JOIN (
			SELECT [Year], StatisticsID, StateCode, LogRecNo, Chariter, [SEQUENCE], B19013_001
				FROM Census..ACS_MedianIncome
				WHERE [Year] = 2015
				and StatisticsID = 1
			) e on e.LogRecNo = a.LogRecNo
			  and e.StateCode = a.StateCode
ORDER BY a.Indv_Sys_Id


--Updating main population table 
ALTER TABLE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	ADD GeoBlockMedian_Income bigint

UPDATE pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop
	SET GeoBlockMedian_Income = (SELECT geomedian_Income FROM #GeoMedianIncome
						WHERE #GeoMedianIncome.Indv_Sys_Id = pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop.Indv_Sys_Id)
