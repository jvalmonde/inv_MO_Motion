--Run on Devsql17 if Devsql14.provoqms is not synced.


USE [ProvoQMS_Prod]


DECLARE @StartDate	date	=	'20150901'
DECLARE @EndDate	date	=	getdate()

-- Active Projects
If OBJECT_ID('tempdb..#ActvPrjcts') is not Null
Drop Table #ActvPrjcts
Select Distinct a.PROJECTID, a.ProjectName, t.Treatmentid, TreatmentName
  Into #ActvPrjcts
From ProvoQMS_Prod.dbo.PROJECT	a
	Inner join Provoqms_prod.dbo.ProjectTreatment pt
		On a.Projectid = pt.PROJECTID
	Inner join Provoqms_prod.dbo.Treatment t
		On pt.TREATMENTID = t.TreatmentID
	Join ProvoQMS_Prod.dbo.LOOKUPProjectStatus	b
		On	a.LOOKUPProjectStatusID	=	b.LOOKUPProjectStatusID
Where b.StatusCode = 'Active'
	and a.ProjectName not like '%test%'


If OBJECT_ID('tempdb..#sub1') is not Null
Drop Table #sub1
Select a.MEMBERID, c.IndividualSysID, b.PROJECTID, b.ProjectName,a.Treatmentid, a.RowCreatedDateTime, c.MEMBERCallLogID--, a.FirstName, a.LastName
	, c.LastCallDateTime, c.RowMOdifiedDateTime
	, c.LOOKUPCallStatusID, d.StatusCode
	, MemberReachedFlag	=	MAX(CAse When StatusCode = 'Member reached – successful' Then 1 Else 0 End) Over(Partition By c.IndividualSysID)
  Into #sub1
From (ProvoQMS_Prod.dbo.Member	a Join ProvoQMS_Prod.dbo.PROJECT	b	On	a.PROJECTID	=	b.PROJECTID)
	Left Join ProvoQMS_Prod.dbo.MEMBERCallLog						c	On	a.MEMBERID	=	c.MEMBERID
																		and LOOKUPCallStatusID <> 29
																		and c.LastCallDateTime > a.RowCreatedDateTime
	Left Join ProvoQMS_Prod.dbo.LOOKUPCallStatus					d	on	c.LOOKUPCallStatusID	=	d.LOOKUPCallStatusID
Where a.PROJECTID in (Select PROJECTID From #ActvPrjcts)		-- All Projects
	and CONVERT(DATE, a.RowCreatedDateTime) between @StartDate and @EndDate
Create Index ix_IndvSysID on #sub1 (IndividualSysID)
Create Index ix_ProjID on #sub1 (PROJECTID)

-- Turn Around Time
If OBJECT_ID('tempdb..#sub2') is not Null
Drop Table #sub2
Select a.MEMBERID, c.IndividualSysID, a.ProjectID, b.ProjectName, a.TreatmentID
	, TAT	=	DateDiff(Day, a.RowCreatedDateTime, Min(c.LastCallDateTime))
  Into #sub2
From (ProvoQMS_Prod.dbo.Member	a Join ProvoQMS_Prod.dbo.PROJECT	b	On	a.PROJECTID	=	b.PROJECTID)
	Inner Join ProvoQMS_Prod.dbo.MEMBERCallLog						c	On	a.MEMBERID	=	c.MEMBERID
Where a.PROJECTID in (Select PROJECTID From #ActvPrjcts)		-- All Projects
	and c.LastCallDateTime > a.RowCreatedDateTime
	and CONVERT(DATE, a.RowCreatedDateTime) between @StartDate and @EndDate
Group By a.MEMBERID, c.IndividualSysID, a.RowCreatedDateTime, a.ProjectID, b.ProjectName, a.treatmentid
Create Index ix_IndvSysID on #sub2 (IndividualSysID)
Create Index ix_ProjID on #sub2 (PROJECTID)


-- Talk Time
If OBJECT_ID('tempdb..#sub3') is not Null
Drop Table #sub3
Select a.MEMBERID, a.IndividualSysID, b.PROJECTID, a.TreatmentID
	, TalkTime	=	SUM(e.Talk_sec + e.Wait_sec + e.Dead_Sec)
  Into #sub3
From (ProvoQMS_Prod.dbo.Member	a Join ProvoQMS_Prod.dbo.PROJECT	b	On	a.PROJECTID	=	b.PROJECTID)	   -----9/25  It would make this query more efficient if you added a filter on projects here.
	Inner Join ProvoQMS_Prod.dbo.MemberCallLogDetail				e	on	a.MemberID	=	e.QMSMemberid
Where a.PROJECTID in (Select PROJECTID From #ActvPrjcts)		-- All Projects
	and CONVERT(DATE, a.RowCreatedDateTime) between @StartDate and @EndDate
Group By a.MEMBERID, a.IndividualSysID, b.PROJECTID, a.TreatmentID
Having SUM(e.Talk_sec + e.Wait_sec + e.Dead_Sec) > 0



If OBJECT_ID('tempdb..#AllMbrs') is not Null
Drop Table #AllMbrs
Select x.*
	, y.TotalTalkTime
	, y.TotalHandleTime
	, y.TurnAroundTime
  Into #AllMbrs
From
(
	Select a.ProjectName, treatmentid
		, MemberstobeCalled	=	Count(Distinct a.MemberID)
		, MembersCalled		=	Count(Distinct Case When a.IndividualSysID is not null Then a.MemberID Else Null End)	-- From ProvoQMS_Prod.dbo.MemberCallLog	---use memberid I think?  ---Ghyatt
		, CallAttempts		=	Count(Distinct a.MEMBERCallLogID)	-- From ProvoQMS_Prod.dbo.MemberCallLog
		, ReachRate			=	Count(Distinct Case When StatusCode = 'Member reached – successful' Then a.MemberID Else Null End) * 1.0/ NULLIF(Count(Distinct Case When a.IndividualSysID is not null Then a.MemberID Else Null End), 0) * 1.0
		, MembersReachedSuccessful	=	Count(Distinct Case When OID = 1 and StatusCode = 'Member reached – successful' Then a.MemberID Else Null End)		-- StatusCode from ProvoQMS_Prod.dbo.LOOKUPCallStatus
		, VoiceMail			=	Count(Distinct Case When OID = 1 and StatusCode = 'Voicemail' Then a.MemberID Else Null End)		-- StatusCode from ProvoQMS_Prod.dbo.LOOKUPCallStatus	
		, Disconnected		=	Count(Distinct Case When OID = 1 and StatusCode = 'Disconnected' Then a.MemberID Else Null End)		-- StatusCode from ProvoQMS_Prod.dbo.LOOKUPCallStatus
		, [Wrong/NoPhoneNumber]		=	Count(Distinct Case When OID = 1 and StatusCode in ('Wrong Number', 'No Phone Number') Then a.MemberID Else Null End)		-- StatusCode from ProvoQMS_Prod.dbo.LOOKUPCallStatus	
		, Other				=	Count(Distinct Case When OID = 1 and StatusCode not in ('Member reached – successful', 'Voicemail', 'Disconnected', 'Wrong Number', 'No Phone Number') Then a.MemberID Else Null End)		-- StatusCode from ProvoQMS_Prod.dbo.LOOKUPCallStatus																																	
	From
	(
		Select *
			, OID	=	ROW_NUMBER() Over(Partition By MemberID Order By LastCallDateTime Desc)
		From #sub1
	)	a
	Group By a.ProjectName, Treatmentid
)	X
left Join	(
		Select a.ProjectName	, a.Treatmentid
			, TotalTalkTime		=	ISNULL(SUM(TalkTime)/60, 0)
			, TotalHandleTime	=	SUM(a.HandleTime)
			, TurnAroundTime	=	AVG(TAT * 1.0)																																				
		From	(
				Select PROJECTID, ProjectName,treatmentid, MEMBERID
					, HandleTime	=	SUM(Case When DateDiff(minute, LastCallDateTime, RowModifiedDateTime) >= 60 Then 60 Else DateDiff(minute, LastCallDateTime, RowModifiedDateTime) End)
				From #sub1
				Group By PROJECTID, ProjectName,treatmentid, MEMBERID
				)	a
			Left Join #sub2	b	On	a.MEMBERID	=	b.MEMBERID	   ----All these joins should be on Memberid, not IndvSysId.  Memberid is a primary key. Ghyatt
								and	a.ProjectID	=	b.ProjectID
								and a.TreatmentID = b.TreatmentID
			Left Join #sub3	c	On	a.MEMBERID	=	c.MEMBERID
								and	a.ProjectID	=	c.ProjectID
								and a.TreatmentID = b.TreatmentID
		Group By a.ProjectName, a.treatmentid
		)	y	On	x.ProjectName	=	y.ProjectName and x.TreatmentID = y.Treatmentid


If OBJECT_ID('tempdb..#MbrsRchd') is not Null
Drop Table #MbrsRchd
Select a.ProjectName, a.Treatmentid	
	, TotalTalkTime		=	ISNULL(SUM(TalkTime)/60, 0)
	, TotalHandleTime	=	SUM(a.HandleTime)
	, TurnAroundTime	=	AVG(TAT * 1.0)		
 Into #MbrsRchd																																				
From	(
		Select PROJECTID, ProjectName,Treatmentid, MEMBERID
			, HandleTime	=	SUM(Case When DateDiff(minute, LastCallDateTime, RowModifiedDateTime) >= 60 Then 60 Else DateDiff(minute, LastCallDateTime, RowModifiedDateTime) End)
		From #sub1
		Where StatusCode = 'Member reached – successful'
		Group By PROJECTID, ProjectName,Treatmentid, MEMBERID
		)	a
	Left Join #sub2	b	On	a.MEMBERID	=	b.MEMBERID	   ----All these joins should be on Memberid, not IndvSysId.  Memberid is a primary key. Ghyatt
						and	a.ProjectID	=	b.ProjectID
						and a.Treatmentid = b.Treatmentid
	Left Join #sub3	c	On	a.MEMBERID	=	c.MEMBERID
						and	a.ProjectID	=	c.ProjectID
Group By a.ProjectName, a.Treatmentid

Go

Drop table #WWProjectstats
Select a.*
	, MemberstobeCalled			=	ISNULL(b.MemberstobeCalled, 0)
	, MembersCalled				=	ISNULL(b.MembersCalled	  , 0)
	, CallAttempts				=	ISNULL(b.CallAttempts	  , 0)
	, MembersReachedSuccessful	=	ISNULL(b.MembersReachedSuccessful	  , 0)
	, Voicemail					=	ISNULL(b.Voicemail	  , 0)
	, Disconnected				=	ISNULL(b.Disconnected	  , 0)
	, [Wrong/NoPhoneNumber]		=	ISNULL(b.[Wrong/NoPhoneNumber]	  , 0)
	, Other						=	ISNULL(b.Other	  , 0)
	, ReachRate					=	ISNULL(b.ReachRate		  , 0)
	, TotalTalkTime				=	ISNULL(b.TotalTalkTime	  , 0)
	, TotalHandleTime			=	ISNULL(b.TotalHandleTime  , 0)
	, TurnAroundTime			=	ISNULL(b.TurnAroundTime	  , 0)
	, MbrsRchd_TtlTalkTime		=	ISNULL(c.TotalTalkTime	, 0)
	, MbrsRchd_TtlHandleTime	=	ISNULL(c.TotalHandleTime, 0)
Into #WWProjectstats

From #ActvPrjcts		a
	Left Join	#AllMbrs	b	on	a.ProjectName	=	b.ProjectName and a.TREATMENTID = b.TreatmentID
	Left Join	#MbrsRchd	c	on	a.ProjectName	=	c.ProjectName and a.TREATMENTID = c.TreatmentID
Where a.ProjectName in ( 
'W&W Follow Up Queue'
,'W&W Inconsistent Syncing'
,'W&W Welcome Calls')
Order By a.PROJECTID


/***********************Num Calls ********/

use provoqms_prod;
Drop table #NumCalls
Select ProjectName,TreatmentName, Treatmentid
, [0 calls] = Count(Distinct Case when CallCount = 0   then Memberid else null end)
 , [1 call] = Count(Distinct Case when CallCount = 1 then Memberid else null end)
 , [2 calls] = Count(Distinct Case when CallCount = 2 then Memberid else null end)
 , [3 calls] = Count(Distinct Case when CallCount = 3 then Memberid else null end)
, [4+ calls] = Count(Distinct Case when CallCount >= 4 then Memberid else null end)
, TotalMembers = Count(  Memberid)
Into #NumCalls
FROM 
( Select Projectname,TreatmentName,t.Treatmentid, m.memberid, CallCount= Count(Case when mcl.memberid is null then null else mcl.memberid end)
FROM project p 
	Inner join Member m on p.projectid = m.Projectid
	Inner join Treatment t on m.treatmentid = t.Treatmentid
	Left join membercallLog mcl on m.Memberid = mcl.Memberid and mcl.LOOKUPCallStatusID <> '29'
Where ProjectName in ( 
'W&W Follow Up Queue'
,'W&W Inconsistent Syncing'
,'W&W Welcome Calls')
	Group by Projectname,TreatmentName,t.Treatmentid, m.Memberid
) a 
group by ProjectName, TreatmentName,Treatmentid
order by ProjectName, TreatmentName,Treatmentid

Select a.ProjectName
,a.TreatmentName
,a.MemberstobeCalled			as [Members Loaded]
,a.MembersCalled				as [Members Called]
,b.[0 calls]
,b.[1 call]
,b.[2 calls]
,b.[3 calls]
,b.[4+ calls]
,a.CallAttempts					as [Call Attempts]
,a.MembersReachedSuccessful    as [Members Reached Successful]
,a.Voicemail					
,a.Disconnected
,a.[Wrong/NoPhoneNumber]		as [[Wrong/No Phone Number] 
,a.Other
,a.ReachRate					as [Reach Rate]
,a.TotalTalkTime				as [Total Talk Time]
,a.TotalHandleTime				as [Total Handle Time]
,a.TurnAroundTime				as [Turn Around Time]
,a.MbrsRchd_TtlTalkTime    as [Talk Time for Members Reached]
,a.MbrsRchd_TtlHandleTime	as [Handle Time for Members Reached]
 FROM #WWProjectstats a
	Full Join #NumCalls b
		ON a.TreatmentID = b.Treatmentid