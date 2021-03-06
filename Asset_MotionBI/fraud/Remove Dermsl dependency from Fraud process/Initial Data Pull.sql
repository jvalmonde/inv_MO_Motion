USE [pdb_DermFraud]
GO
/****** Object:  StoredProcedure [dbo].[dselectFraudProcessDataPull]    Script Date: 11/15/2016 10:31:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




--Do we need the columns LookupClientid, ProgramStartdate, and LookupTenant?, going forward, pdb_DermFraud first and then update Dermsl_Prod.

/***Create a table of days in which users have at least 300 steps and the steps are after the registration date and 
the steps are in the past 24 days *******/
IF OBJECT_ID('tempdb.dbo.#Process_ThreeHundredStepDays_ETL') is not null
Drop table #Process_ThreeHundredStepDays_ETL

Select  a.Memberid, a.LookupClientid, ProgramStartdate, a.LookupTenantid, LogDate = Querydate, Steps = totalSteps
INTO #Process_ThreeHundredStepDays_ETL
FROM Dermsl_prod.dbo.Member a    
	INNER JOIN (Select mei.Memberid,Querydate = IncentiveDate, mei.TotalSteps FROM Dermsl_Prod.dbo.MemberEarnedIncentives mei inner join Dermsl_prod.dbo.LookupRule lr on mei.LOOKUPRuleID = lr.LOOKUPRuleID and RuleName = 'Tenacity') b
		oN a.Memberid = b.Memberid 
		and b.Querydate >= a.ProgramStartDate
	Left JOIN Dermsl_Prod.dbo.FraudRollup c 
	ON b.Memberid = c.Memberid and a.LOOKUPClientID = c.LookupClientid 
	and b.Querydate = c.LogDate 
	and b.TotalSteps = c.Steps
Where  c.LogDate is null
--and a.LookupTenantid in (2,3) 
and TotalSteps >= 300 
and Querydate between  Dateadd(day,-30,Convert(date,Current_Timestamp)) and Dateadd(day,-1,Convert(date,Current_Timestamp))
order by Logdate

Select * FROM #Process_ThreeHundredStepDays_ETL Where memberid = 6299
Order by Logdate
--Create Clustered index idxFBSysuser on Process_ThreeHundredStepDays_ETL(Memberid)
--Create nonClustered index idxLogDate on Process_ThreeHundredStepDays_ETL(LogDate)

/****Why are there DermMemberids in StreamlineDevices prod that don't exist in Derm..member?**********/

Drop table #1
Select a.* 
Into #1
FROM 
(
		Select DermMemberid, Stepdate = convert(Date, LogdateTime), steps = sum(Steps) 
		FROM 
		(
			Select m.DermMemberid, Stepdate,  MinuteSlotNo
			, LogdateTime = Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,Stepdate)))
			,Steps
			FROM (StreamlineDevices_Prod.dbo.Member m Inner join Dermsl_prod.dbo.Member dm on m.Dermmemberid = dm.Memberid and dm.firstname = m.firstname)
				Inner join Streamlinedevices_Prod.dbo.MemberDevice md 
					ON m.memberid = md.memberid 
				Inner join StreamlineDevices_prod.dbo.DevicePEDDataHeader dp 
					On md.memberdeviceid = dp.Memberdeviceid
				Inner join StreamlineDevices_prod.dbo.LookupDataheadertype ldht 
					On dp.LookupDataheaderTypeid = ldht.lookupDataheadertypeid 
					and ldht.HeaderTypeName = 'Steps data'
				Inner join StreamlineDevices_prod.dbo.DevicePedData dpd
					On dp.Dataheaderid = dpd.Dataheaderid
			Where  Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,Stepdate))) between  Dateadd(day,-30,Convert(date,Current_Timestamp)) and Dateadd(day,-1,Convert(date,Current_Timestamp))
			) 
		a 
		Group by  DermMemberid, convert(Date, LogdateTime)
) a 
	Left JOIN Dermsl_Prod.dbo.FraudRollup c 
		ON a.DermMemberid = c.Memberid 
		and a.Stepdate = c.LogDate 
		and a.Steps = c.Steps
Where  c.LogDate is null and a.Steps >= 300 
order by stepdate

Select Distinct Memberid, logdate FROM #Process_ThreeHundredStepDays_ETL Where memberid = 19495
except
Select Distinct DermMemberid, Stepdate FROM #1 where Dermmemberid = 19495




/********************************************Join the steps data---commented out by GHYATT until I can optimize this(taking too long to run right now) --4/20/2016******************************************************/

Declare @Logdatetime datetime = dateadd(day,-15,getdate())


Select a.Memberid

,MinuteIndex = DATEDIFF(MINute,DATEADD(Day,-1,Convert(Date,Current_TimeStamp - 1)),LogDateTime)
,MinuteofthedayIndex = DATEDIFF(minute, c.LogDate, CONVERT(datetime, logdatetime))
,LogDateTime
,LogDate = c.Logdate
,m.Lookupclientid
,m.LookupTenantid
,m.ProgramStartdate
,LogValue  
FROM Dermsl_Prod.dbo.Member M
	INNER JOIN Dermsl_Prod.dbo.MEMBERIntradayData  a
		On M.Memberid = a.memberid	
	INNER JOIN  #Process_ThreeHundredStepDays_ETL c     ---Changed from dbo.Process_ThreeHundredStepDays 8/7/2016 gh
		ON a.Memberid = c.Memberid and M.Lookupclientid = c.Lookupclientid
		and Convert(date,a.LogDatetime) = c.LogDate
Where LogdateTime >= @Logdatetime and m.memberid = 73888




Declare @Logdate date = Convert(Date,dateadd(day,-15,getdate()))

--IF OBJECT_ID('tempdb.dbo.#StepsbyMinuteIndex_ETL') is not null
--Drop table #StepsbyMinuteIndex_ETL

Select dm.Memberid

,MinuteIndex = DATEDIFF(MINute,DATEADD(Day,-1,Convert(Date,Current_TimeStamp - 1)),Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate))))
,MinuteofthedayIndex = DATEDIFF(minute, Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate))), CONVERT(datetime, dpd.Stepdate))
,LogdateTime = Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate)))
--,LogDate = c.Stepdate
,dpd.Steps  
FROM (StreamlineDevices_Prod.dbo.Member m Inner join Dermsl_prod.dbo.Member dm on m.Dermmemberid = dm.Memberid and dm.firstname = m.firstname)
				Inner join Streamlinedevices_Prod.dbo.MemberDevice md 
					ON m.memberid = md.memberid 
				Inner join StreamlineDevices_prod.dbo.DevicePEDDataHeader dp 
					On md.memberdeviceid = dp.Memberdeviceid
				Inner join StreamlineDevices_prod.dbo.LookupDataheadertype ldht 
					On dp.LookupDataheaderTypeid = ldht.lookupDataheadertypeid 
					and ldht.HeaderTypeName = 'Steps data'
				Inner join StreamlineDevices_prod.dbo.DevicePedData dpd
					On dp.Dataheaderid = dpd.Dataheaderid
				--INNER JOIN  #1 c     ---Changed from dbo.Process_ThreeHundredStepDays 8/7/2016 gh
				--	ON m.Memberid = c.DermMemberid 
				--	and dpd.StepDate = c.Stepdate
Where dm.Memberid = 73888 and c.Stepdate




