---Run on Devsql17 if Devsql14.Provoqms is not in sync...
---References Devsql14.DermReporting_Dev.dbo.[Walk and Win Motion Performance data], which is refreshed by the idlememberscallqueue refresh(In the task named "Move tables from Aws to Devsql14 for processing")  this package runs hourly throughout the day. ***/

use provoqms_prod;


/***outbound Communications****/

If Object_Id('tempdb.dbo.#OutreachbyState') is not null 
Drop table  #OutreachbyState
Select ReachMethod = Case when m.EmailAddress like '%Mail%' then 'Mail' 
					when m.EmailAddress like '%IVR%' then 'IVR' ELSE 'NP' End
,Statecode
,OutReach_Total = Count(*) 
,OutReach_TotalResponses = Count(Distinct Case when mcl.Memberid is not null then mcl.memberid else null end )  
Into #OutreachbyState
FROM provoqms_prod.dbo.vmember m 
		Left join provoqms_prod.dbo.MemberCallLog mcl on m.memberid = mcl.memberid
		Left join provoqms_prod.dbo.lookupCallStatus lcs on mcl.LookupCallStatusid = lcs.LookupCallStatusid
		Left join provoqms_prod.dbo.ProjectDisposition pd on mcl.ProjectDispositionid = pd.ProjectDispositionid
Where m.Treatmentid = 306 
Group by Case when m.EmailAddress like '%Mail%' then 'Mail' 
					when m.EmailAddress like '%IVR%' then 'IVR' ELSE 'NP' End
,Statecode
order by Count(*)  desc


/*****Welcome and setup call for members****/

If Object_Id('tempdb.dbo.#WelcomeCallByState') is not null 
Drop table #WelcomeCallByState

Select 
m.FirstName
,m.Lastname
,m.IndividualSysID
,m.Treatmentid
,Welcome_TotalMembersLoaded = count(Distinct m.memberid)
,Welcome_TotalMembersCalled = Count(Distinct Case when lcs.LookupcallStatusid is not null then mcl.memberid else null end ) 
,Welcome_TotalCalls         = count(lcs.StatusCode)
,Welcome_TotalReached = Count(Distinct Case when lcs.statuscode like '%member%Reached%Success%' then mcl.memberid else null end )  
Into #WelcomeCallByState
FROM provoqms_prod.dbo.vmember m 
		Left join provoqms_prod.dbo.MemberCallLog mcl on m.memberid = mcl.memberid
		Left join provoqms_prod.dbo.lookupCallStatus lcs on mcl.LookupCallStatusid = lcs.LookupCallStatusid and StatusCode not in ('No Phone Call/Member Edit','Member Edit','No Phone Call/Member Edit','Call In Progress/Skip')
		Left join provoqms_prod.dbo.ProjectDisposition pd on mcl.ProjectDispositionid = pd.ProjectDispositionid
Where m.Treatmentid in (304,305)
Group by m.Firstname, m.Lastname,m.IndividualSysID, m.Treatmentid
order by Count(*)  desc



/***Follow up calls*************/


If Object_Id('tempdb.dbo.#FollowupCallByState') is not null 
Drop table #FollowupCallByState

Select m.Treatmentid
--,StatusCode
,Followup_TotalMembersLoaded = count(Distinct m.memberid)
,Followup_TotalMembersCalled = Count(Distinct Case when lcs.LookupcallStatusid is not null then mcl.memberid else null end ) 
,Followup_TotalCalls         = count(lcs.StatusCode)
,Followup_TotalReached = Count(Distinct Case when lcs.statuscode like '%member%Reached%Success%' then mcl.memberid else null end )  
Into #FollowupCallByState
FROM provoqms_prod.dbo.vmember m 
		Left join provoqms_prod.dbo.MemberCallLog mcl on m.memberid = mcl.memberid
		Left join provoqms_prod.dbo.lookupCallStatus lcs on mcl.LookupCallStatusid = lcs.LookupCallStatusid and StatusCode not in ('No Phone Call/Member Edit','Member Edit','No Phone Call/Member Edit','Call In Progress/Skip')
		Left join provoqms_prod.dbo.ProjectDisposition pd on mcl.ProjectDispositionid = pd.ProjectDispositionid
Where m.Treatmentid in (307,308)
Group by m.Treatmentid--,StatusCode
order by Count(*)  desc


/******Welcome Call NPS Survey**********/
use provoqms_prod;
		Select Distinct  m.Memberid, t.Treatmentname, Script = csr.CALLScriptResponseID,Scripttext = Convert(Varchar(max),csd.ScriptText) , Response =  Convert(Varchar(max),csr.ResponseText)

		FROM Project p 
			Inner join LOOKUPProjectStatus lps on p.LOOKUPProjectStatusID = lps.LOOKUPProjectStatusID
			Inner join Member m on m.Projectid = p.Projectid  
		    Inner join CALLScriptParticipant csp on m.memberid = csp.memberid 
			Inner join CALLScriptResponse csr on csr.CALLScriptResponseID = csp.CALLScriptResponseID
			Inner join CALLScriptDetail csd on csr.CALLScriptDetailID = csd.CALLScriptDetailID
			Inner join CallScript cs on cs.CALLScriptID = csd.CALLScriptId
			Inner join TREATMENT         t on m.TreatmentID = t.TREATMENTID
		Where T.Treatmentid in ( 304,305,306) and Convert(Varchar(max),csd.ScriptText) like '%recommend%'


/***30 day survey********/
		Select Distinct  m.Memberid, t.Treatmentname, Script = csr.CALLScriptResponseID,Scripttext = Convert(Varchar(max),csd.ScriptText) , Response =  Convert(Varchar(max),csr.ResponseText)
	FROM Project p 
			Inner join LOOKUPProjectStatus lps on p.LOOKUPProjectStatusID = lps.LOOKUPProjectStatusID
			Inner join Member m on m.Projectid = p.Projectid  
		    Inner join CALLScriptParticipant csp on m.memberid = csp.memberid 
			Inner join CALLScriptResponse csr on csr.CALLScriptResponseID = csp.CALLScriptResponseID
			Inner join CALLScriptDetail csd on csr.CALLScriptDetailID = csd.CALLScriptDetailID
			Inner join CallScript cs on cs.CALLScriptID = csd.CALLScriptId
			Inner join TREATMENT         t on m.TreatmentID = t.TREATMENTID
		Where T.Treatmentid in (313
,312
,310
,309) and Convert(Varchar(max),csd.ScriptText) like '%recommend%'  



--Select pd.DispositionDescription, Count(*) 
--FROM provoqms_prod.dbo.vmember m 
--		Left join provoqms_prod.dbo.MemberCallLog mcl on m.memberid = mcl.memberid
--		Left join provoqms_prod.dbo.lookupCallStatus lcs on mcl.LookupCallStatusid = lcs.LookupCallStatusid and StatusCode not in ('No Phone Call/Member Edit','Member Edit','No Phone Call/Member Edit','Call In Progress/Skip')
--		Left join provoqms_prod.dbo.ProjectDisposition pd on mcl.ProjectDispositionid = pd.ProjectDispositionid
--Where m.Treatmentid in ( 305,306) 
--Group by DispositionDescription

If Object_Id('tempdb.dbo.#30Dayfollowup') is not null 
Drop table #30Dayfollowup
Select m.Treatmentid
,Firstname
,Lastname
,m.IndividualSysid
,ThirtyDay_TotalMembersLoaded = count(Distinct m.memberid)
,ThirtyDay_TotalMembersCalled = Count(Distinct Case when lcs.LookupcallStatusid is not null then mcl.memberid else null end ) 
,ThirtyDay_TotalCalls         = count(lcs.StatusCode)
,ThirtyDay_TotalReached = Count(Distinct Case when lcs.statuscode like '%member%Reached%Success%' then mcl.memberid else null end )  
,ThirtyDay_SurveyDisposition = Max(DispositionDescription)
Into #30Dayfollowup
FROM provoqms_prod.dbo.vmember m 
		INNEr join provoqms_prod.dbo.MemberCallLog mcl on m.memberid = mcl.memberid
		INNEr join provoqms_prod.dbo.lookupCallStatus lcs on mcl.LookupCallStatusid = lcs.LookupCallStatusid and StatusCode not in ('No Phone Call/Member Edit','Member Edit','No Phone Call/Member Edit','Call In Progress/Skip')
		INNEr join provoqms_prod.dbo.ProjectDisposition pd on mcl.ProjectDispositionid = pd.ProjectDispositionid
Where m.Treatmentid in 
( 309
,310
,312
,313)
Group by m.Treatmentid,Firstname
,Lastname,m.IndividualSysid
order by Count(*)  desc


/**********Bring the following data over from 02 server and refresh table Devsql14.DermReporting_Dev.dbo.[Walk and Win Motion Performance data](Occurs when the idle refresh package is executed) ****************/



--Select 
--m.Memberid,
--Customerid,
--Statecode,
--Firstname,
--Birthdate,
--Lastname,
--m.Zipcode
--,m.RowCreatedDateTime
--,msd.FirstActivationDate
--,msd.LastStepMinute
--,m.ActiveMemberflag as IsRegistered
--,Status = 
-- Case when m.ActivememberFlag = 1  and msd.lastStepMinute is not null and datediff(day,msd.lastStepMinute, Getdate()) > 7  and  convert(date,msd.LastStepMinute)> convert(date, msd.FirstActivationDate) then 'Idle-Inactive for 7 Days'
--	  when m.ActivememberFlag = 1  and msd.lastStepMinute is not null and datediff(day,msd.lastStepMinute, Getdate()) <= 7  then 'Logging'
--	  when m.Activememberflag = 1 and msd.lastStepMinute is not null and convert(date,msd.LastStepMinute)= convert(date, msd.FirstActivationDate)  then 'InitialSync_ButDidNotPersist'
--	  when m.ActivememberFlag = 1  and msd.lastStepMinute is null then 'Registered'
--	  when m.Activememberflag = 0 then 'Deactivated' else 'Registered' end 
-- FROM Dermsl_Prod.dbo.Member m 
--inner join Dermsl_Prod.dbo.MemberStepMovementMetaData msd 
--	On m.Memberid = msd.memberid 
--Where lookupClientid = 125
--order by rowCreatedDatetime

/********************************************************************/

If Object_Id('tempdb.dbo.#StepsData') is not null 
Drop table #StepsData


Select m.Memberid 
,Customerid
,m.StateCode
,m.Firstname 
,m.Birthdate
,m.ZIpcode
,m.Lastname
,m.RowCreatedDatetime
,m.FirstActivationDate
,m.LastStepMinute
,Case when pm.EmailAddress is not null and  (pm.EmailAddress  like '% mail %' or pm.EmailAddress  like '%IVR%' ) then pm.EmailAddress 
	  when pm.Emailaddress is  null and m.Statecode = 'IN'  then 'unknown' 
	  when pm.Emailaddress is null then 'NP' else 'unknown' End as Treatment
,isregistered 
,Status 
,pm.emailaddress
,ReachMethod = Case when pm.EmailAddress like '% Mail%' then 'Mail' 
					when pm.EmailAddress like '%IVR%' then 'IVR'
					When pm.Emailaddress is not null then 'unknown'
					When pm.Emailaddress is  null and m.Statecode = 'IN' then 'unknown'
					 ELSE 'NP' End  --there are a couple of exceptions here where the email address is updated...
Into #StepsData
 FROM Devsql14.DermReporting_Dev.dbo.[Walk and Win Motion Performance data] m  ---Imported data from dbs-derm-prd-02.derm.triomotionfit.com dermsl_Prod(the query above)
	Left join provoqms_prod.dbo.vmember pm 
			on m.Firstname = pm.FirstName 
			and m.LastName = pm.LastName 
			and m.Zipcode = pm.Zipcode
			and pm.TreatmentID = 306 
			and m.StateCode = 'In'					---For info on DM/IVR
	Where m.rowCreatedDatetime > '20160501' and m.Statecode in ('NC','In')
	order by treatment


--Select * FROM  Devsql14.DermReporting_Dev.dbo.[Walk and Win Motion Performance data] order by RowCreatedDateTime

Select State					= isnull(b.Statecode, a.Statecode)
, ReachMethod					= Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM')  and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End
--,TotalOutreach =  Max(b.OutReach_Total) 
,Responders						=  Max(b.OutReach_totalResponses) 
, Registered					= Count(*)--Sum(Convert(int,isRegistered))
,Logging_InTheLast7Days			= Sum(Case when Status = 'Logging' then 1 else 0 end )
,[Idle-Inactive for 7 Days]		= Sum(Case when Status = 'Idle-Inactive for 7 Days' then 1 else 0 end )
,[Registered_NotLogging]		= Sum(Case when Status = 'Registered' then 1 else 0 end )
,Deactivated					= Sum(Case when Status = 'Deactivated' then 1 else 0 end )
,InitialSync_ButDidNotPersist	= Sum(Case when Status = 'InitialSync_ButDidNotPersist' then 1 else 0 end )
FROM #StepsData a
		Left join #OutreachbyState b
			On a.Statecode = b.Statecode and b.ReachMethod = a.Reachmethod
		Left join #WelcomeCallByState c on a.Customerid = c.IndividualSysId
		Left join #30Dayfollowup d on a.Customerid = d.IndividualSysId
Group by isnull(b.Statecode, a.Statecode),  Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End



Select State							= isnull(b.Statecode, a.Statecode), ReachMethod = Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End  
, Registered							= Count(*) --Sum(Convert(int,isRegistered))
,Logging_InTheLast7Days					= Sum(Case when Status = 'Logging' then 1 else 0 end )
,[Idle-Inactive for 7 Days]				= Sum(Case when Status = 'Idle-Inactive for 7 Days' then 1 else 0 end )
,[Registered_NotLogging]				= Sum(Case when Status = 'Registered' then 1 else 0 end )
,Deactivated							= Sum(Case when Status = 'Deactivated' then 1 else 0 end )
,InitialSync_ButDidNotPersist			= Sum(Case when Status = 'InitialSync_ButDidNotPersist' then 1 else 0 end )
FROM #StepsData a
		Left join #OutreachbyState b
			On a.Statecode = b.Statecode and b.ReachMethod = a.Reachmethod
		Left join #WelcomeCallByState c on a.Customerid = c.IndividualSysId
		Left join #30Dayfollowup d on a.Customerid = d.IndividualSysId
Where datediff(day,a.rowCreatedDatetime, getdate()) >= 30 
Group by isnull(b.Statecode, a.Statecode), Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End	 




Select Age									= Case when DateDiff(Year,a.Birthdate,Getdate()) >= 65 then '65+' else '<65' end, State = isnull(b.Statecode, a.Statecode), ReachMethod = Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End
, Registered								= Count(*) 
,Logging_InTheLast7Days						= Sum(Case when Status = 'Logging' then 1 else 0 end )
,[Idle-Inactive for 7 Days]					= Sum(Case when Status = 'Idle-Inactive for 7 Days' then 1 else 0 end )
,[Registered_NotLogging]					= Sum(Case when Status = 'Registered' then 1 else 0 end )
,Deactivated								= Sum(Case when Status = 'Deactivated' then 1 else 0 end )
,InitialSync_ButDidNotPersist				= Sum(Case when Status = 'InitialSync_ButDidNotPersist' then 1 else 0 end )
 FROM #StepsData a
		Left join #OutreachbyState b
			On a.Statecode = b.Statecode and b.ReachMethod = a.Reachmethod
		Left join #WelcomeCallByState c on a.Customerid = c.IndividualSysId
		Left join #30Dayfollowup d on a.Customerid = d.IndividualSysId 
Group by Case when DateDiff(Year,a.Birthdate,Getdate()) >= 65 then '65+' else '<65' end, isnull(b.Statecode, a.Statecode), Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End	 



/***Run again for Ga data****/	

If Object_Id('tempdb.dbo.#GAStepsData') is not null 
Drop table #GAStepsData
Select m.Memberid 
,Customerid
,m.StateCode
,m.Firstname 
,m.Birthdate
,m.Lastname
,m.RowCreatedDatetime
,m.FirstActivationDate
,m.LastStepMinute
,isnull(pm.EmailAddress,'NP') as Treatment
,isregistered 
,Status 
,ReachMethod = Case when pm.EmailAddress like '%Mail%' then 'Mail' 
					when pm.EmailAddress like '%IVR%' then 'IVR' ELSE 'NP' End 
Into #GAStepsData
 FROM Devsql14.DermReporting_Dev.dbo.[Walk and Win Motion Performance data] m
	Left join provoqms_prod.dbo.vmember pm on m.Firstname = pm.FirstName and m.LastName = pm.LastName and pm.TreatmentID = 306 and m.RowCreatedDateTime > '20160501' and m.StateCode = 'In' 
Where m.Statecode = 'Ga'
order by m.Statecode


Select State = isnull(b.Statecode, a.Statecode)
, ReachMethod = Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End
,TotalOutreach =  Max(b.OutReach_Total) 
,Responders    =  Max(b.OutReach_totalResponses) 
, Registered = Sum(convert(int,isRegistered))
,Logging_InTheLast7Days = Sum(Case when Status = 'Logging' then 1 else 0 end )
,[Idle-Inactive for 7 Days] = Sum(Case when Status = 'Idle-Inactive for 7 Days' then 1 else 0 end )
,[Registered_NotLogging] = Sum(Case when Status = 'Registered' then 1 else 0 end )
,Deactivated = Sum(Case when Status = 'Deactivated' then 1 else 0 end )
,InitialSync_ButDidNotPersist = Sum(Case when Status = 'InitialSync_ButDidNotPersist' then 1 else 0 end )
FROM #GAStepsData a
		Left join #OutreachbyState b
			On a.Statecode = b.Statecode and b.ReachMethod = a.Reachmethod
		Left join #WelcomeCallByState c on a.Customerid = c.IndividualSysId
		Left join #30Dayfollowup d on a.Customerid = d.IndividualSysId
Group by isnull(b.Statecode, a.Statecode), Case when isnull(b.ReachMethod, a.Reachmethod) not in( 'IVR','DM') and isnull(b.Statecode, a.Statecode) = 'In' then 'mail' else isnull(b.ReachMethod, a.Reachmethod) End



/****  This query will pull in earnings data for end of the month report.
/****Walk and Win Earnings ---use prd-02**/
  	  Select-- Count(Distinct Account_Id)
	  Account_Id, Firstname, Lastname,Statecode,Startdate = Convert(Date,AccountCreatedDatetime), EndDate = convert(Date,CancelledDateTime), DaysInProgram = datediff(day,accountCreatedDatetime, isnUll(CancelledDatetime,getdate()))
	  , F_Total =  isnull(Sum(FPoints)																		   ,0)

	  , T_Total =  isnull(Sum(Tpoints)																		   ,0)
	  	  , Total =  isnull(Sum(TotalAwards)																		   ,0)
	  , F_OCT =    isnull( Sum(case when Full_Dt between '20161001' and '20161031' then FPoints else null end )  ,0)
	
	  , T_OCT=    isnull(Sum(case when Full_Dt between '20161001' and '20161031' then TPoints else null end )   ,0)
	  	  , Total_OCT =    isnull(Sum(case when Full_Dt between '20161001' and '20161031' then TotalAwards else null end )   ,0)
  FROM [DERMSL_Reporting].[dbo].[vwProgramActivity_EnrolledDates]
  Where Statecode in ('In','NC','Ga') and Clientname = 'xlhealth'  and Full_Dt >= '20160101'
  Group by Account_Id, Firstname, Lastname, Statecode, datediff(day,accountCreatedDatetime, isnUll(CancelledDatetime,getdate()))
  , Convert(Date,AccountCreatedDatetime), CancelledDateTime
  Order by Total Desc


  ***/


