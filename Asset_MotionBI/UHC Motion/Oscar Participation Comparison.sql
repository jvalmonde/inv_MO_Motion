/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [EligibleID]
      ,[TenantName]
      ,[ClientName]
      ,[PreloadRequiredFlag]
      ,[MemberSignupdataid]
      ,[Account_ID]
      ,[MemberName]
      ,[Clientmemberid]
      ,[Firstname]
      ,[Lastname]
      ,[Birthdate]
      ,[Gendercode]
      ,[EmailAddress]
      ,[StateCode]
      ,[Zipcode]
      ,[Dependentcode]
      ,[ParentClientmemberid]
      ,[AccountVerifiedDateTime]
      ,[AccountVerifiedFlag]
      ,[ProgramStartDate]
      ,[customerid]
      ,[ActiveFlag]
      ,[CancelledDatetime]
      ,[PreloadTeamName]
      ,[LookupRuleGroupid]
  FROM [DERMSL_Reporting].[dbo].[Dim_Eligibles]



  If object_id('tempdb.dbo.#Eligibles') is not null 
  Drop table #Eligibles

  Select Clientname,Programstartdate,LookupRuleGroupid,Eligibleid,Account_ID, Birthdate, AccountVerifiedFlag, AccountVerifiedDateTime 
  into #Eligibles
  FROM  [DERMSL_Reporting].[dbo].[Dim_Eligibles]
  Where CancelledDatetime is null or CancelledDatetime > ProgramStartDate


    If object_id('tempdb.dbo.#FirstSteps') is not null 
  Drop table #FirstSteps

  Select EligibleId, FirstStepDate = Min(Date)
  into #FirstSteps
  FROM Fact_PreloadActivity 
  Where TotalSteps > 300 
  Group by EligibleId


      If object_id('tempdb.dbo.#FirstSync') is not null 
  Drop table #FirstSync

  Select AccOunt_id, FirstSyncDate = Min(Full_Dt)
  into #FirstSync
  FROM Fact_Sync a
	Inner join Dim_Date b
		On a.SyncDtSysid = b.DT_SYS_ID
  Group by Account_Id


  If object_Id('tempdb.dbo.#Registrations') is not null 
  Drop table #Registrations

  Select a.*
  , AgeGroup = 
  Case when DateDiff(Year,birthdate, Getdate()) >= 55 then '55+'
	   when DateDiff(Year,birthdate, Getdate()) >= 45 then '45 - 54'
	   when DateDiff(Year,birthdate, Getdate()) >= 35 then '35 - 44' 
	   when DateDiff(Year,birthdate, Getdate()) >= 25 then '25 - 34' 
	   when DateDiff(Year,birthdate, Getdate()) >= 18 then '18 - 24' 
	   when DateDiff(Year,birthdate, Getdate()) >= 0 then   '0 - 17' else null end  
	   , b.FirstStepDate, c.FirstSyncDate
into #Registrations
  FROM #Eligibles a 
	Left join #FirstSteps b
		oN a.EligibleID = b.EligibleID
	Left Join #FirstSync c
		On a.Account_ID = c.Account_ID 

		Select Top 100 * FROM #Registrations
/****Percent (by agegroup and total) that register within 30/60/90 days***/
Go 



Select Clientname,BusinessModel = Case when Programstartdate < '20151001' then 'Opt-in'  
						    when Programstartdate < '20160601' then 'Built-in' 
							when Programstartdate < getdate()  then 'Built-in with ActivationSticker' else null end 
,RegisteredWithin30Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 30 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin60Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 60 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin90Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 90 , 1, 0 ))*1.00/Count(*)
,Registered = Sum(Case when AccountVerifiedFlag = 1 then 1 else 0 end ) *1.00/ Count(*) 
,SampleSize = Count(*) 
FROM #Registrations
Where Programstartdate <= dateadd(Day,-90,Getdate())
Group by Clientname, Case when Programstartdate < '20151001' then 'Opt-in'  
						    when Programstartdate < '20160601' then 'Built-in' 
							when Programstartdate < getdate()  then 'Built-in with ActivationSticker' else null end 
with rollup


Go
Select AgeGroup	, 
RegisteredWithin30Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 30 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin60Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 60 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin90Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 90 , 1, 0 ))*1.00/Count(*)
,Registered = Sum(Case when AccountVerifiedFlag = 1 then 1 else 0 end ) *1.00/ Count(*) 
FROM #Registrations
Where Clientname = 'Key Accounts UHCM'
Group by AgeGroup	 with rollup


/**********/
/****Percent (by agegroup and total) that Log within 30/60/90 days***/
Go 



Select Clientname,BusinessModel = Case when Programstartdate < '20151001' then 'Opt-in'  
						    when Programstartdate < '20160601' then 'Built-in' 
							when Programstartdate < getdate()  then 'Built-in with ActivationSticker' else null end 
,LoggedWithin30Days = sum(IIF(dateDiff(Day,ProgramStartdate,FirstStepdate) <= 30 , 1, 0 ))*1.00/Count(*)
,LoggedWithin60Days = sum(IIF(dateDiff(Day,ProgramStartdate,FirstStepdate) <= 60 , 1, 0 ))*1.00/Count(*)
,LoggedWithin90Days = sum(IIF(dateDiff(Day,ProgramStartdate,FirstStepdate) <= 90 , 1, 0 ))*1.00/Count(*)
,Logged = Sum(Case when FirstStepdate is not null then 1 else 0 end ) *1.00/ Count(*) 
,SampleSize = Count(*) 
FROM #Registrations
Where Programstartdate <= dateadd(Day,-90,Getdate())
Group by Clientname, Case when Programstartdate < '20151001' then 'Opt-in'  
						    when Programstartdate < '20160601' then 'Built-in' 
							when Programstartdate < getdate()  then 'Built-in with ActivationSticker' else null end 
with rollup


Go
Select Clientname, AgeGroup	, 
 StepsWithin30Days = sum(IIF(dateDiff (Day,ProgramStartdate,FirstStepDate) <= 30 , 1, 0 ))*1.00/Count(*)
,StepsWithin60Days = sum(IIF(dateDiff(Day,ProgramStartdate,FirstStepDate) <= 60 , 1, 0 ))*1.00/Count(*)
,StepsWithin90Days = sum(IIF(dateDiff(Day,ProgramStartdate,FirstStepDate) <= 90 , 1, 0 ))*1.00/Count(*)
,Steps = Sum(Case when AccountVerifiedFlag = 1 then 1 else 0 end ) *1.00/ Count(*) 
FROM #Registrations
Group by Clientname, AgeGroup	 with rollup


/****For the total of members that register, how quickly?*****/

Go
Select ClientName,AgeGroup	, 
RegisteredWithin30Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 30 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin60Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 60 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin90Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 90 , 1, 0 ))*1.00/Count(*)
,RegisteredWithin120Days = sum(IIF(dateDiff(Day,ProgramStartdate,AccountVerifiedDatetime) <= 120 , 1, 0 ))*1.00/Count(*)
,Registered = Sum(Case when AccountVerifiedFlag = 1 then 1 else 0 end ) *1.00/ Count(*) 
FROM #Registrations
Where AccountVerifiedFlag = 1
Group by Clientname, AgeGroup	 with rollup


/****how long until 25, 50 and 75% of users register?*********/


Go

Select DaysFRomEligibility, RegistrationPercent = sum(isregistered)*1.00/ count(*)
FROM vwActivityForPreloadGroups
Where Clientname = 'Key Accounts UHCM' and AccountVerifiedDateTime is not null --and DaysFromEligibility = 5 
Group by DaysFRomEligibility
Order by DaysFromEligibility


/******Who is using apple and who is using android?***********/

Select Platformname,Count(Distinct Account_Id)  FROM vwProgramSync 
where clientname in ('All Savers Motion')
group by Platformname with rollup


Select Platformname,Count(Distinct Account_Id)  FROM vwProgramSync 
where clientname in ('Key Accounts Uhcm')
group by Platformname with rollup