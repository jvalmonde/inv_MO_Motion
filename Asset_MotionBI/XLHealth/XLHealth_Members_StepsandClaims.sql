
Select a.Dermsl_memberid, a.Mbr_sys_id, b.*  
--Into #XLHealthActivity 
FROM Devsql10.pdb_abw.dbo.XL_MembersList a 
	Inner join (pdb_Dermreporting.dbo.Dim_member dm inner join pdb_DermReporting.dbo.vwProgramActivity_EnrolledDates b on dm.Account_ID = b.Account_Id) 
		ON a.Dermsl_memberid = dm.Dermsl_memberid 
order by a.account_id, Full_Dt

Select * FROM #XLHealthActivity

IF OBJECT_ID('tempdb..#TEMP_XLMemberlist') is not null
	DROP TABLE #TEMP_XLMemberlist

	SELECT xl.Account_ID, xl.FirstName, xl.LastName, m.*
	INTO #TEMP_XLMemberlist				--SELECT DISTINCT Mbr_Sys_ID FROM #TEMP_XLMemberlist
	FROM pdb_abw.dbo.XL_MembersList xl
	INNER JOIN [MiniOV].[dbo].[SavvyID_to_Mbr_Sys_ID] s	ON xl.Mbr_sys_id = s.Mbr_Sys_Id
	INNER JOIN [MiniOV].[dbo].Dim_Member m ON s.SavvyID = m.SavvyID--s.Mbr_Sys_ID = m.Mbr_Sys_ID
--188 rows
--------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#RAF_SourceTable') IS NOT NULL
	DROP TABLE #RAF_SourceTable

SELECT  fc.SavvyId, fc.Mbr_Sys_Id, m.Account_ID, m.Gender, m.Age, m.Zip, d.YEAR_MO, Full_Dt = convert(date,d.Full_Dt),
		fc.Diag_1_Cd_Sys_Id, dc1.DIAG_FULL_DESC [Diag1_desc], dc1.DIAG_CD [Diag1_CD],
		fc.Diag_2_Cd_Sys_Id, dc2.DIAG_FULL_DESC [Diag2_desc], dc2.DIAG_CD [Diag2_CD],
		fc.Diag_3_Cd_Sys_Id, dc3.DIAG_FULL_DESC [Diag3_desc], dc3.DIAG_CD [Diag3_CD], pc.PROC_CD ,pc.PROC_DESC, st.Srvc_Typ_Desc
	    ,d.YEAR_NBR, d.MONTH_NBR, d.DAY_NBR, fc.Clm_Aud_Nbr  ,[MM_2006]    ,[MM_2007]      ,[MM_2008]      ,[MM_2009]      ,[MM_2010]     ,[MM_2011]      ,[MM_2012]      ,[MM_2013]      ,[MM_2014]      ,[MM_2015]  ,m.MM
		
		,Allw_Amt		 = sum(fc.Allw_Amt   )
		,Deriv_Amt		 = sum(fc.Deriv_Amt	 )
		,Admit_Cnt		 = sum(fc.Admit_Cnt	 )
		,Day_Cnt		 = sum(fc.Day_Cnt	 )
		,Net_Pd_Amt		 = sum(fc.Net_Pd_Amt )
		,Vst_Cnt		 = sum(fc.Vst_Cnt	 )
		--INTO udb_wsadora.[dbo].[RAF_SourceTable]	--5,318 ROWS	 83 Distinct Mbr_Sys_Id
		INTO #RAF_SourceTable		--select distinct Mbr_Sys_Id from #RAF_SourceTable	169 rows
	 	FROM [MiniOV].dbo.Fact_Claims fc
		LEFT JOIN [MiniOV].dbo.Dim_Diagnosis_Code dc1 ON fc.[Diag_1_Cd_Sys_Id] = dc1.DIAG_CD_SYS_ID
		LEFT JOIN [MiniOV].dbo.Dim_Diagnosis_Code dc2 ON fc.[Diag_2_Cd_Sys_Id] = dc2.DIAG_CD_SYS_ID
		LEFT JOIN [MiniOV].dbo.Dim_Diagnosis_Code dc3 ON fc.[Diag_3_Cd_Sys_Id] = dc3.DIAG_CD_SYS_ID
		LEFT JOIN [MiniOV].dbo.Dim_Procedure_Code pc ON fc.Proc_Cd_Sys_Id = pc.PROC_CD_SYS_ID
		LEFT JOIN [MiniOV].dbo.Dim_Service_Type st ON fc.Srvc_Typ_Sys_Id = st.Srvc_Typ_Sys_Id
		Left JOIN [MiniOV].dbo.Dim_Date d ON fc.Dt_Sys_Id = d.DT_SYS_ID
		INNER JOIN #TEMP_XLMemberlist m ON fc.SavvyId = m.SavvyID and fc.Mbr_Sys_Id = m.Mbr_Sys_ID
		--WHERE dc1.ICD_VER_CD = 9 OR dc2.ICD_VER_CD = 9 OR dc3.ICD_VER_CD = 9
Group by   fc.SavvyId, fc.Mbr_Sys_Id, m.Account_ID, m.Gender, m.Age, m.Zip, d.YEAR_MO,  convert(date,d.Full_Dt),
		fc.Diag_1_Cd_Sys_Id, dc1.DIAG_FULL_DESC , dc1.DIAG_CD,
		fc.Diag_2_Cd_Sys_Id, dc2.DIAG_FULL_DESC , dc2.DIAG_CD,
		fc.Diag_3_Cd_Sys_Id, dc3.DIAG_FULL_DESC , dc3.DIAG_CD, pc.PROC_CD ,pc.PROC_DESC, st.Srvc_Typ_Desc
	    ,d.YEAR_NBR, d.MONTH_NBR, d.DAY_NBR, fc.Clm_Aud_Nbr  ,[MM_2006]    ,[MM_2007]      ,[MM_2008]      ,[MM_2009]      ,[MM_2010]     ,[MM_2011]      ,[MM_2012]      ,[MM_2013]      ,[MM_2014]      ,[MM_2015]  ,m.MM
		ORDER BY fc.SavvyId ASC, fc.Mbr_Sys_Id ASC, d.YEAR_MO ASC
	

Select * FROM #RAF_SourceTable         

--PERSONS TABLE
if object_id ('tempdb..#RAF_Persons') is not null
drop table #RAF_Persons

SELECT	tab.Mbr_Sys_Id as UniqueMemberID,	 
		tab.Gender as GenderCd,
		a.AgeFirstYYYYMM as [Age],
		OREC	= CASE WHEN a.AgeFirstYYYYMM < 65 then 1 ELSE 0 end,
		MCAID	= CASE WHEN a.Age < 65 then 1 ELSE 0 end
		INTO #RAF_Persons					--SELECT * FROM udb_wsadora.dbo.RAF_Persons
	FROM #RAF_SourceTable tab	 
	INNER JOIN (
		SELECT t.Mbr_Sys_Id, t.Age, YEAR_MO, [No], t.Age - DATEDIFF(YY, YEAR_MO, getdate()) [AgeFirstYYYYMM]
			FROM (
				SELECT Mbr_Sys_Id, Age, YEAR_MO + '01' as YEAR_MO, ROW_NUMBER () over(partition by Mbr_Sys_Id ORDER BY YEAR_MO) as [No]
					FROM udb_wsadora.[dbo].[RAF_SourceTable]
				GROUP BY Mbr_Sys_Id, Age, YEAR_MO
				) t
		WHERE t.[No] = 1
			) a ON tab.Mbr_Sys_Id = a.Mbr_Sys_Id
--GROUP BY tab.Mbr_Sys_Id, tab.Gender, a.Age, a.AgeFirstYYYYMM

--Diagnosis TABLE
if object_id ('tempdb..#RAF_Diagnosis ') is not null
drop table #RAF_Diagnosis 

SELECT Mbr_Sys_Id as UniqueMemberID, Diag1_CD as DiagCd --, Diag2_CD, Diag3_CD 
	INTO #RAF_Diagnosis  -- DROP TABLE udb_wsadora.dbo.RAF_Diagnosis		--		SELECT * FROM udb_wsadora.dbo.RAF_Diagnosis
	FROM #RAF_SourceTable
UNION ALL
SELECT Mbr_Sys_Id as UniqueMemberID, Diag2_CD as DiagCd --, Diag2_CD, Diag3_CD 
	FROM #RAF_SourceTable
UNION ALL
SELECT Mbr_Sys_Id as UniqueMemberID, Diag3_CD as DiagCd --, Diag2_CD, Diag3_CD  			 
	FROM #RAF_SourceTable
--1,867 ROWS


Exec [RA_Medicare_2014_v2 ].dbo.[spRAFDiagnosisDemographicInput]
	 @ModelID = 6
	,@InputDiagnosisTableLocation = 'tempdbo..#RAF_Diagnosis'			--can be set to NULL
	,@InputDemographicsTableLocation = 'tempdbo..#RAF_Persons'		--can be set to NULL
	,@OutputDatabase = '[RA_Medicare_2014_v2]'
	,@OutputSuffix = 'XLHealth'

	Select * FROM pdb_Abw.dbo.XLHealth
