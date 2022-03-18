
---run on dbs-derm-prd-02

USE Dermsl_Reporting;

DECLARE @Wkb4Week_Begin_Dt date = Dateadd(day,-6,Getdate())
DECLARE @1Db4Get_date date = Dateadd(Day,-1,Convert(Date,Getdate()))
Drop table #Logged
		SELECT DISTINCT  Statecode, dd.Week_Begn_Dt, MSt.Account_ID
			INTO #Logged  --drop table #Logged
			FROM (
				Select Distinct m.Tenantname, m.ClientName, m.Age,m.Gender, m.Zipcode,m.Statecode, m.Firstname, m.Lastname, m.RuleGroupname, Account_ID, m.ProgramStartDate, m.AccountCreatedDateTime, M.CancelledDateTime, StepDate =  dd.Full_Dt-- , Count(*) 
				FROM [dbo].[Dim_Member] m 
					INNER Join dbo.Dim_Date dd 
					on dd.Full_Dt between IIF (m.ProgramStartdate < '20130101',m.AccountCreatedDateTime,m.ProgramStartDate)and  isnull(m.CancelledDateTime,Getdate())
					and dd.Full_Dt between '20130101' and Getdate()	
				WHERE m.Clientname = 'XLhealth'
				 
				and m.FirstName not like '%System%'
				and m.FirstName not like '%test%'
				and m.Address1 not like '%test%'
			) MSt
			INNER JOIN dbo.Dim_Date dd ON MSt.StepDate = dd.FULL_DT
			LEFT JOIN dbo.Fact_Activity FA on MSt.Account_ID = FA.Account_ID and FA.Dt_Sys_ID = dd.DT_SYS_ID and MSt.ClientName = 'XLhealth'
		WHERE MSt.Account_id not in (9113,13669) AND FA.TotalSteps >= 300
		CREATE CLUSTERED INDEX idxWeekBDt ON #Logged (Week_Begn_Dt)


Drop table #MainTable
Select Statecode,Week_Begn_Dt, Week_End_Dt = Dateadd(Day,6,Week_Begn_dt), Clientname			--43secs
	,Enrolled =  Count(Distinct Account_ID) 
	,Logged = Count(Distinct Case when 	TotalSteps  > 299 then  Account_Id Else Null end)
	,AverageStepsPerActiveDay = Avg( Case when 	TotalSteps  > 299 then  TotalSteps Else Null end)
	,AverageStepsPerDay       = Avg(TotalSteps)

	into #MainTable				--drop table #MainTable
	FROM (

		SELECT a.[Tenantname]			,a.[ClientName]	      ,a.[FirstName]	      ,a.[LastName]	      ,a.[Age]	      ,a.[Gender]	      ,a.[Zipcode]	      ,a.[RuleGroupname], a.StateCode
			  ,a.[Account_ID]			,a.[ProgramStartDate] ,a.[AccountCreatedDateTime]	      ,a.[CancelledDateTime]	      ,a.[DaysFromRegistration]
			  ,a.[ProgramStartYearMo]	,a.[DAY_NBR]	      ,a.[DAY_WK]	      ,a.[Full_Dt]	      ,a.[Month_Nbr]	      ,a.[Month_Nm]	      ,a.[Year_Mo]
			  ,a.[Week_Begn_Dt]	        ,a.[ManualAwardFlag]  ,a.[ManualAwardNotes]	      ,a.[TotalSteps]	      ,a.[F]	      ,a.[I]	      ,a.[T]
			  ,a.[FrequencyBouts]	    ,a.[ActiveMinutes]	  ,a.[LastUpdate]	      ,a.[TotalAwards]	      ,a.[FPoints]	      ,a.[IPoints]
			  ,a.[TPoints]		  ,[Syncs] = Count(b.SyncDate)      ,[DaysinProgram]	= Max(DaysFromRegistration + 1)	 Over(Partition by a.Account_ID)
			  --into #tempTable1	--40,734	SELECT * FROM #tempTable1
			  FROM dbo.vwProgramActivity_EnrolledDates  a
			  LEFT JOIN dbo.vwProgramSync   B 	oN a.Account_ID = b.Account_ID		and a.Full_Dt = b.SyncDate
		Where a.Clientname = 'XLhealth'	and a.ProgramStartdate < @1Db4Get_date --Dateadd(Day,-1,Convert(Date,Getdate()))	
		and a.Account_id not in (9113,13669)
		Group by    a.[Tenantname]    ,a.[ClientName]	   ,a.[FirstName]     ,a.[LastName]     ,a.[Age]     ,a.[Gender]     ,a.[Zipcode]     ,a.[RuleGroupname], a.StateCode
			  ,a.[Account_ID]    ,a.[ProgramStartDate]     ,a.[AccountCreatedDateTime]     ,a.[CancelledDateTime]     ,a.[DaysFromRegistration]    ,a.[ProgramStartYearMo]
			  ,a.[DAY_NBR]     ,a.[DAY_WK]     ,a.[Full_Dt]     ,a.[Month_Nbr]     ,a.[Month_Nm]    ,a.[Year_Mo]     ,a.[Week_Begn_Dt]     ,a.[ManualAwardFlag]
			  ,a.[ManualAwardNotes]     ,a.[TotalSteps]     ,a.[F]     ,a.[I]     ,a.[T]     ,a.[FrequencyBouts]    ,a.[ActiveMinutes]     ,a.[LastUpdate]     ,a.[TotalAwards]
			  ,a.[FPoints]    ,a.[IPoints]    ,a.[TPoints]
		) a
	Group by Statecode,Week_Begn_Dt,CLientname
	CREATE CLUSTERED INDEX idxWeekBDt_Main ON #MainTable (Week_End_Dt,Week_Begn_Dt)

Select a.Statecode,Week_Begn_Dt = Convert(Date,a.Week_Begn_Dt), Week_End_Dt = Convert(date,Week_End_Dt), Enrolled, Logged
, EverRegistered = Count(Distinct Dm.Account_Id)
, EverLogged = Count(Distinct Pa.Account_Id)
,AverageStepsPerActiveDay
,AverageStepsPerDay      

FROM
( 	select Statecode, Week_Begn_Dt, Week_End_Dt, Enrolled, Logged ,AverageStepsPerActiveDay
,AverageStepsPerDay   FROM #MainTable
) a
	left join dbo.Dim_Member dm 	
	ON dm.AccountCreatedDateTime <= Dateadd(Day,1,Week_End_Dt)	and dm.Statecode = a.Statecode and  dm.Clientname = 'XLhealth'	and  dm.Account_id not in (9113,13669)
	LEFT JOIN (SELECT Week_Begn_Dt, Account_ID, Statecode FROM #Logged ) PA ON PA.Week_Begn_Dt  <= a.Week_Begn_Dt and pa.Statecode = a.Statecode 

Where  a.Statecode in ( 'IN','NC','GA')  --Dateadd(day,-6,Getdate())
Group by a.Statecode,a.Week_Begn_Dt, Week_End_Dt, Enrolled, Logged,AverageStepsPerActiveDay
,AverageStepsPerDay   
order by Week_Begn_dt
