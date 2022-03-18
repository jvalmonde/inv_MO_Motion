
use pdb_DermReporting; 

 Drop Table #Members
Select 
  a.[EligibleID]
 ,a.[TenantName]
 ,a.[ClientName]
 ,a.[PreloadRequiredFlag]
 ,a.[MemberSignupdataid]
 ,a.[Account_ID]
 ,a.[MemberName]
 ,a.[Clientmemberid]
 ,a.[Firstname]
 ,a.[Lastname]
 ,a.[Birthdate]
 ,a.[Gendercode]
 ,a.[EmailAddress]
 ,a.[StateCode]
 ,a.[Zipcode]
 ,a.[Dependentcode]
 ,a.[ParentClientmemberid]
 ,a.[AccountVerifiedDateTime]
 ,a.[AccountVerifiedFlag]
 ,a.[ProgramStartDate]
 ,a.[customerid]
 ,a.[ActiveFlag]
 ,a.[CancelledDatetime]
 ,a.[PreloadTeamName]
 ,a.[LookupRuleGroupid]
	, TreatmentGroup		=	Case When b.Membersignupdataid is null then 'Calls' else 'No Calls' end
	, ProgramstartYearMonth	=	dbo.YearMOnth(a.programstartdate)
	, RegisteredYearMonth	=	dbo.YearMOnth(a.accountverifieddatetime)
	, CancelledYearMonth	=	dbo.YearMOnth(a.cancelleddatetime)
	,Called = Max(Case when mcl.IndividualSysID is not null then 1 else 0 end )
	,reached = Max(Case when mcl.LOOKUPCallStatusID = 1 then 1 else 0 end)

  Into #Members
FROM [pdb_DermReporting].[dbo].[Dim_Eligibles]	a
	Left Join [pdb_DermReporting].[dbo].[AllsaversNocallTreatmentgroup]	b	on	a.Membersignupdataid	=	b.Membersignupdataid
	left join provoqms_prod.dbo.member m
		ON a.Clientmemberid = m.IndividualSysId	and m.Projectid = 128
	Left join (Select Distinct Memberid,IndividualSysid, lookupcallstatusid = max(case when lookupcallstatusid = 2 then 1 else 0 end) 
				from provoqms_prod.dbo.membercallLog where lookupcallstatusid <> 29  group by memberid, IndividualSysid )
				mcl On m.memberid = mcl.memberid 
Where a.Clientname = 'All Savers Motion'
	and dbo.YearMOnth(a.programstartdate) between 201512 and 201512
	Group by 
	
	  A.[EligibleID]
	 ,A.[TenantName]
	 ,A.[ClientName]
	 ,A.[PreloadRequiredFlag]
	 ,A.[MemberSignupdataid]
	 ,A.[Account_ID]
	 ,A.[MemberName]
	 ,A.[Clientmemberid]
	 ,A.[Firstname]
	 ,A.[Lastname]
	 ,A.[Birthdate]
	 ,A.[Gendercode]
	 ,A.[EmailAddress]
	 ,A.[StateCode]
	 ,A.[Zipcode]
	 ,A.[Dependentcode]
	 ,A.[ParentClientmemberid]
	 ,A.[AccountVerifiedDateTime]
	 ,A.[AccountVerifiedFlag]
	 ,A.[ProgramStartDate]
	 ,A.[customerid]
	 ,A.[ActiveFlag]
	 ,A.[CancelledDatetime]
	 ,A.[PreloadTeamName]
	 ,A.[LookupRuleGroupid]
	,Case When b.Membersignupdataid is null then 'Calls' else 'No Calls' end
	,dbo.YearMOnth(a.programstartdate)
	,dbo.YearMOnth(a.accountverifieddatetime)
	,dbo.YearMOnth(a.cancelleddatetime)
-- 58,063

--Select * From #Members
--where programstartdate <= CONVERT(date, ISNULL(accountverifieddatetime, getdate()))
--	--intersect--Union
--Select * From #Members
--where programstartdate > CONVERT(date, ISNULL(accountverifieddatetime, getdate()))

Select TreatmentGroup
	, MemberCount	=	Count(*)
From #Members
Group By TreatmentGroup

Select TreatmentGroup
	, MemberCount				=	Count(Distinct Clientmemberid)
	,CalledCount = sum(called)
	,Reached = sum(reached)
	, HaveRegistered			=	Count(Distinct Case When RegisteredYearMonth Is Not Null Then EligibleID Else Null End)
	, [%Registered]				=	Count(Distinct Case When RegisteredYearMonth Is Not Null Then EligibleID Else Null End) * 1.0 / Count(*)
	, RegisteredStillActive		=	Count(Distinct Case When RegisteredYearMonth Is Not Null and ActiveFlag = 1 Then EligibleID Else Null End)
	, [%RegisteredStillActive]	=	Count(Distinct Case When RegisteredYearMonth Is Not Null and ActiveFlag = 1 Then EligibleID Else Null End) * 1.0 / Count(Distinct Case When RegisteredYearMonth Is Not Null Then EligibleID Else Null End)
	, RegisteredinDec2015		=	Count(Distinct Case When RegisteredYearMonth <= 201512 Then EligibleID Else Null End)
	, [%RegisteredinDec2015]	=	Count(Distinct Case When RegisteredYearMonth <= 201512 Then EligibleID Else Null End) * 1.0 / Count(Distinct  EligibleID )
	, RegisteredinJan2016		=	Count(Distinct Case When RegisteredYearMonth <= 201601 Then EligibleID Else Null End)
	, [%RegisteredinJan2016]	=	Count(Distinct Case When RegisteredYearMonth <= 201601 Then EligibleID Else Null End) * 1.0 / Count(Distinct  EligibleID )
	, RegisteredinFeb2016		=	Count(Distinct Case When RegisteredYearMonth <= 201602 Then EligibleID Else Null End)
	, [%RegisteredinFeb2016]	=	Count(Distinct Case When RegisteredYearMonth <= 201602 Then EligibleID Else Null End) * 1.0 / Count(Distinct  EligibleID )
	, RegisteredinMar2016		=	Count(Distinct Case When RegisteredYearMonth <= 201603 Then EligibleID Else Null End)
	, [%RegisteredinMar2016]	=	Count(Distinct Case When RegisteredYearMonth <= 201603 Then EligibleID Else Null End) * 1.0 / Count(Distinct  EligibleID )
	, RegisteredinApr2016		=	Count(Distinct Case When RegisteredYearMonth <= 201604 Then EligibleID Else Null End)
	, [%RegisteredinApr2016]	=	Count(Distinct Case When RegisteredYearMonth <= 201604 Then EligibleID Else Null End) * 1.0 / Count(Distinct  EligibleID )
	, RegisteredinMay2016		=	Count(Distinct Case When RegisteredYearMonth <= 201605 Then EligibleID Else Null End)
	, [%RegisteredinMay2016]	=	Count(Distinct Case When RegisteredYearMonth <= 201605 Then EligibleID Else Null End) * 1.0 / Count(Distinct  EligibleID )
From
(-- 57,474	Members that registered after their programstartdate
	Select * From #Members
	where programstartdate <= CONVERT(date, ISNULL(accountverifieddatetime, getdate()))
)	Sub
Group By TreatmentGroup



Select statusCode, DaysFromEligibility, RegistrationRate = sum(isRegistered*1.00)/count(*)
FROM 
(
Select v.clientmemberid, lcs.StatusCode, v.isRegistered, Date, DaysFromEligibility FROM vwActivityForPreloadGroups  v 
	Left join provoqms_prod.dbo.member   m 
		ON v.Clientmemberid = m.IndividualSysID and m.PROJECTID = 128 
	inner join (Select *, RN = Row_Number()over(partition by individualSysid order by LastCallDatetime ) FROM provoqms_prod.dbo.membercallLog ) mcl on m.memberid = mcl.memberid and mcl.Rn = 1
	Left join provoqms_prod.dbo.LOOKUPCallStatus lcs on mcl.LOOKUPCallStatusID = lcs.LOOKUPCallStatusId	
Where v.DaysFromEligibility in(30,60,90,120)
) a
Group by statusCode, DaysFromEligibility


Select * FROM provoqms_prod.dbo.lookupcallstatus where statuscode  = 'No Phone Call/Member Edit'