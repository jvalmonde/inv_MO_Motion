--/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP 1000 [Account_ID]
--      ,[TenantName]
--      ,[RuleGroupName]
--      ,[ClientName]
--      ,[ProgramStartDate]
--      ,[AccountCreatedDateTime]
--      ,[CancelledDateTime]
--      ,[ActiveMemberFlag]
--      ,[ZipCode]
--      ,[Age]
--      ,[DependentCode]
--      ,[EligibleForIncentivesFlag]
--      ,[Email]
--      ,[ReasonForLeavingNotes]
--      ,[SeizureDisorderFamilyFlag]
--      ,[SeizureParticipantFirstName]
--      ,[SeizureParticipantLastName]
--      ,[DeviceModel]
--      ,[DeviceSerial]
--      ,[Devicetype]
--      ,[isDeviceActive]
--      ,[Platformname]
--      ,[Brand]
--      ,[AppVersion]
--      ,[FirmwareVersion]
--      ,[SyncDate]
--      ,[MonthName]
--      ,[YearMonth]
--      ,[WeekDayName]
--      ,[WeekNumber]
--      ,[BatteryLevel]
--      ,[SyncActivationMethod]
--      ,[syncminute]
--      ,[Count]


/**Syncing by Date and Platform****/

Select StateCode, SyncDate = Convert(Date, Syncdate),Platformname = case when platformname like 'Syncstation' then 'Syncstation' else 'PC or Mobile' end 
 ,  Count(distinct a.Account_ID)  
 FROM [DERMSL_Reporting].[dbo].[vwProgramSync] a
	Inner join DERMSL_Reporting.dbo.dim_member b
		On a.Account_Id = b.Account_id 
  where a.clientname = 'xlhealth' and a.programstartdate >= '20160622' and statecode <> 'MN'
  Group by Statecode,Convert(Date, Syncdate), case when platformname like 'Syncstation' then 'Syncstation' else 'PC or Mobile' end 
  order by Convert(Date, Syncdate), platformname


  Select StateCode,Platformname 
 ,  Count(distinct a.Account_ID)  
 FROM [DERMSL_Reporting].[dbo].[vwProgramSync] a
	Inner join DERMSL_Reporting.dbo.dim_member b
		On a.Account_Id = b.Account_id 
  where a.clientname = 'xlhealth' and a.programstartdate >= '20160622'
  Group by StateCode,platformname with rollup 
  order by StateCode,platformname

  
  
/**Syncing by Date and Platform with both****/


select Statecode, SyncDate, 
PlatformName = Case when Both = 1 then 'Both' 
					when [Mobile or Pc] = 1 then 'Mobile or Pc'
					when Syncstation = 1 then 'syncstation' else 'No Sync' end 
,individuals = count(*) 
FROM 
(
     Select Account_Id,Statecode,
      SyncDate = Convert(Date, Syncdate)
     ,Syncstation  = Max(case when platformname like 'Syncstation' then 1 else 0 end )
     ,[Mobile or Pc]  = Max(case when platformname like 'PC or Mobile' then 1 else 0 end)
     ,Both = Case when Max(case when platformname like 'Syncstation' then 1 else 0 end ) + Max(case when platformname like 'PC or Mobile' then 1 else 0 end) > 1 then 1 else 0 end 
      From 
      (
      Select Statecode,a.Account_id, Syncdate, Platformname = case when platformname like 'Syncstation' then 'Syncstation' else 'PC or Mobile' end   FROM ([DERMSL_Reporting].[dbo].[vwProgramSync] a inner join (Select Distinct Account_Id, Statecode FROM Dim_Member) b on a.Account_ID = b.Account_ID) 
       where clientname = 'xlhealth' and programstartdate >= '20160622' and Statecode <> 'MN'
     
       ) a 
       Group by Statecode,Account_Id,
      Convert(Date, Syncdate)
) a
Group by Statecode, SyncDate, Case when Both = 1 then 'Both' 
					when [Mobile or Pc] = 1 then 'Mobile or Pc'
					when Syncstation = 1 then 'syncstation' else 'No Sync' end 

order by syncdate

/**Count of Individuals that have synced by platform****/



/****Count of People who have synced by x platfrom****/



select 
PlatformName = Case when Both = 1 then 'Both' 
					when [Mobile or Pc] = 1 then 'Mobile or Pc'
					when Syncstation = 1 then 'syncstation' else 'No Sync' end 
,individuals = count(*) 
FROM 
(
     Select Account_Id,

     Syncstation  = Max(case when platformname like 'Syncstation' then 1 else 0 end )
     ,[Mobile or Pc]  = Max(case when platformname like 'PC or Mobile' then 1 else 0 end)
     ,Both = Case when Max(case when platformname like 'Syncstation' then 1 else 0 end ) + Max(case when platformname like 'PC or Mobile' then 1 else 0 end) > 1 then 1 else 0 end 
      From 
      (
      Select Account_id, Syncdate, Platformname = case when platformname like 'Syncstation' then 'Syncstation' else 'PC or Mobile' end   FROM [DERMSL_Reporting].[dbo].[vwProgramSync]
       where clientname = 'xlhealth' and programstartdate >= '20160622' 
     
       ) a 
       Group by Account_Id
) a
Group by Case when Both = 1 then 'Both' 
					when [Mobile or Pc] = 1 then 'Mobile or Pc'
					when Syncstation = 1 then 'syncstation' else 'No Sync' end 




select Statecode,
PlatformName = Case when Both = 1 then 'Both' 
					when [Mobile or Pc] = 1 then 'Mobile or Pc'
					when Syncstation = 1 then 'syncstation' else 'No Sync' end 
,individuals = count(*) 
FROM 
(
     Select Statecode,Account_Id,

     Syncstation  = Max(case when platformname like 'Syncstation' then 1 else 0 end )
     ,[Mobile or Pc]  = Max(case when platformname like 'PC or Mobile' then 1 else 0 end)
     ,Both = Case when Max(case when platformname like 'Syncstation' then 1 else 0 end ) + Max(case when platformname like 'PC or Mobile' then 1 else 0 end) > 1 then 1 else 0 end 
      From 
      (
      Select Statecode, a.Account_id, Syncdate, Platformname = case when platformname like 'Syncstation' then 'Syncstation' else 'PC or Mobile' end  FROM ([DERMSL_Reporting].[dbo].[vwProgramSync] a inner join (Select Distinct Account_Id, Statecode FROM Dim_Member) b on a.Account_ID = b.Account_ID) 
       where clientname = 'xlhealth' and programstartdate >= '20160622' 
     
       ) a 
       Group by Statecode, Account_Id
) a
Group by  Statecode, Case when Both = 1 then 'Both' 
					when [Mobile or Pc] = 1 then 'Mobile or Pc'
					when Syncstation = 1 then 'syncstation' else 'No Sync' end --with rollup
order by Statecode, Platformname
