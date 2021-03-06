 
 use pdb_DermFraud;

/***Create a table of days in which users have at least 300 steps and the steps are after the registration date and 
the steps are in the past 24 days *******/
IF OBJECT_ID('dbo.Process_ThreeHundredStepDays_ETL') is not null
Drop table dbo.Process_ThreeHundredStepDays_ETL
Select a.* 
INTO dbo.Process_ThreeHundredStepDays_ETL
FROM 
(
		Select DermMemberid,LookupClientid = '',ProgramStartdate = '', lookupTenantid = '' ,Logdate = convert(Date, LogdateTime), steps = sum(Steps) 
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
		and a.Logdate = c.LogDate 
		and a.Steps = c.Steps
Where  c.LogDate is null and a.Steps >= 300 
order by Logdate

Create Clustered index idxFBSysuser on Process_ThreeHundredStepDays_ETL(DermMemberid)
Create nonClustered index idxLogDate on Process_ThreeHundredStepDays_ETL(LogDate)

/********************************************Join the steps data---commented out by GHYATT until I can optimize this(taking too long to run right now) --4/20/2016******************************************************/



Declare @Logdate date = Convert(Date,dateadd(day,-15,getdate()))

--IF OBJECT_ID('tempdb.dbo.#StepsbyMinuteIndex_ETL') is not null
--Drop table #StepsbyMinuteIndex_ETL

Select					  m.DermMemberid

,MinuteIndex			= DATEDIFF(MINute,DATEADD(Day,-1,Convert(Date,Current_TimeStamp - 1)),Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate))))
,MinuteofthedayIndex	= DATEDIFF(minute, Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate))), CONVERT(datetime, dpd.Stepdate))
,LogdateTime			= Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate)))
,c.LogDate 
,LookupClientid	  = ''
,LookupTenantid	  = ''
,ProgramStartdate = ''
,Steps = max(dpd.Steps  )
--Select top 100 * 
FROM --(
StreamlineDevices_Prod.dbo.Member m -- Inner join Dermsl_prod.dbo.Member dm on m.Dermmemberid = dm.Memberid and dm.firstname = m.firstname)
											
				Inner join Streamlinedevices_Prod.dbo.MemberDevice md 
					ON m.memberid = md.memberid 
				Inner join StreamlineDevices_prod.dbo.DevicePEDDataHeader dp 
					On md.memberdeviceid = dp.Memberdeviceid
				Inner join StreamlineDevices_prod.dbo.LookupDataheadertype ldht 
					On dp.LookupDataheaderTypeid = ldht.lookupDataheadertypeid 
					and ldht.HeaderTypeName = 'Steps data'
				Inner join StreamlineDevices_prod.dbo.DevicePedData dpd
					On dp.Dataheaderid = dpd.Dataheaderid
				INNER JOIN  dbo.Process_ThreeHundredStepDays_ETL c     ---Changed from dbo.Process_ThreeHundredStepDays 8/7/2016 gh
					ON m.DermMemberid = c.Memberid 
					and dpd.StepDate = c.Logdate
Group by 
m.DermMemberid
,DATEDIFF(MINute,DATEADD(Day,-1,Convert(Date,Current_TimeStamp - 1)),Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate))))
,DATEDIFF(minute, Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate))), CONVERT(datetime, dpd.Stepdate))
,Dateadd(HH,OffsetUsed,Dateadd(MINUTE,MinuteSlotNo,Convert(DateTime,dpd.Stepdate)))
,c.LogDate 

					--Select * FROM StreamlineDevices_prod.dbo.DevicePedData





