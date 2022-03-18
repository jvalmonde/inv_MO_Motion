use pdb_Dermreporting;
Set transaction isolation level read uncommitted 

/*****Set up the Eligibles and Registered by month table.*******/
	SELECT
		t1.Clientname,------Added by Ghyatt 10/11/2015
		t1.LookupRuleGroupid,
		t2.YEAR_MO,
		Registered = COUNT(DISTINCT
			CASE
			WHEN t1.isRegistered = 1 THEN EligibleID
			ELSE NULL
			END
		),
		Eligibles = COUNT(DISTINCT t1.Eligibleid)

Into #Cte1
FROM
		dbo.Fact_PreloadActivity t1
		INNER JOIN dbo.Dim_Date t2 ON
			t1.Dt_Sys_ID = t2.DT_SYS_ID
	WHERE
		t2.FULL_DT < SYSDATETIME()
	GROUP BY
		t1.LookupRuleGroupid,t1.Clientname,
		t2.YEAR_MO


If object_Id ('Tempdb.dbo.#motionByGroup') is not null
Drop table #motionByGroup
SELECT
	cte1.LookupRuleGroupid,
	cte1.clientname,t3.Lookupclientid,		---Added Ghyatt 10/11/22015
	t3.RuleGroupName,
	t3.OfferCode,
	t3.State,
	t3.Zipcode,
	t3.PeriodPolicyNumber,
	YearMonth = cte1.YEAR_MO,
	t3.PeriodPolicyStartDate,
	t3.PeriodPolicyEndDate,
	cte1.Registered,
	cte1.Eligibles
		  Into #motionByGroup
FROM
	dbo.Dim_SESAllsaversPolicyYear t3
	inner JOIN #cte1 cte1 ON
		cte1.LookupRuleGroupid = t3.LOOKUPRuleGroupID
WHERE
	CAST(cte1.YEAR_MO AS INT) >= DATEPART(YEAR, t3.PeriodPolicyStartDate) * 100 + DATEPART(MONTH, t3.PeriodPolicyStartDate)
	AND CAST(cte1.YEAR_MO AS INT) <= DATEPART(YEAR, t3.PeriodPolicyEndDate) * 100 + DATEPART(MONTH, t3.PeriodPolicyEndDate)

  Create unique Clustered index idxRuleGroupMonth on pdb_DermReporting.dbo.Motion_by_Group_by_Month(LookupRuleGroupid,YearMonth)

  Select * FROM #motionByGroup order by lookupRuleGroupid, YearMonth



GO

 Drop table #Activity1
 Select de.clientname,de.programStartdate,de.EligibleID, de.LookupruleGroupid,YEAR_MO, Date = full_Dt, isRegistered, Fpoints,Ipoints, TPOints, PossibleFPoints, PossibleIPoints, PossibleTPoints, TotalAwards,TotalSteps
 into #Activity1
 FROM pdb_DermReporting.dbo.Dim_eligibles de 
 inner join pdb_DermReporting.dbo.Fact_PreloadActivity b on de.EligibleID = b.Eligibleid 
 inner join pdb_DermReporting.dbo.Dim_Date dd on dd.DT_SYS_ID = b.Dt_Sys_ID
 Where de.clientname in( 'All savers Motion','key accounts uhcm')-- and de.LookupRuleGroupid < 2000
Create clustered index idxactivity on #Activity1(LookupruleGroupid)
Create index idxactivity2 on #Activity1(Date, Year_Mo) include (Fpoints,Ipoints,TPOints, EligibleId)
GO 

Drop table PolicyYear
Select Distinct  *   into PolicyYear FROM pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b

Create unique Clustered index idx on PolicyYear(LookupRulegroupid,PeriodPolicyStartDate)
Create index idxlrg on PolicyYear(LookupRuleGroupid)
Create index idxend on PolicyYear(PeriodPolicyEndDate)
Create index idxlSt on PolicyYear(PeriodPolicyStartDate)

Select * FROM Dim_SesAllSaversPolicyYear

use pdb_DermReporting; 
--1. Growth and Participation by Month and for established members(members who have been eligible for at least 90 days. --Can check this out by gender and Agebin if needed.
Drop table #FIT
SELECT ClientName,b.rulegroupname, Policyid = b.Offercode,  b.PeriodPolicyStartDate, b.PeriodPolicyEnddate
,F = Sum(Fpoints*1.00)/NULLIF(Sum(PossibleFPoints),0)
,I = Sum(Ipoints*1.00)/NULLIF(Sum(PossibleIPoints) ,0)
,T = Sum(Tpoints*1.00)/NULLIF(Sum(PossibleTPoints) ,0)
,FIT = SUM(Fpoints + IPoints + TPoints*1.00) /NULLIF(Sum(PossibleFPoints + PossibleIPoints + PossibleTPoints),0)
Into #FIT
FROM #Activity1 a 
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts UHCM')  --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,b.rulegroupname, b.Offercode,  b.PeriodPolicyStartDate, b.PeriodPolicyEnddate



Drop table #Eligibles
Select Clientname, Policyid = b.Offercode,b.PeriodPolicyStartDate, b.PeriodPolicyEndDate
,Eligibles = Count(distinct eligibleid)
,Registered = Count(distinct Case when isregistered = 1 then eligibleid else null end)
,PercentofDaysEnrolled = sum(isregistered)*1.00 /Count(*) 
Into #Eligibles
FROM #Activity1 a 
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts uhcm') --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname, b.Offercode,b.PeriodPolicyStartDate, b.PeriodPolicyEndDate


Drop table #Logging
Select Clientname, Policyid = b.Offercode,b.PeriodPolicyStartDate, b.PeriodPolicyEndDate
,Logging = Count(Distinct Case when TotalSteps > 299 then EligibleId else null end)  
,PercentofRegisteredDaysLogged = Count(Distinct Case when TotalSteps > 299 then EligibleId else null end) *1.00  /sum(Nullif(isregistered,0))

,PercentofEligibleDaysLogged = Count(Distinct Case when TotalSteps > 299 then EligibleId else null end)*1.00  /count(*)
Into #Logging
FROM #Activity1 a 
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts uhcm') --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname, b.Offercode,b.PeriodPolicyStartDate, b.PeriodPolicyEndDate

Go

/****Combine tables for allsavers Weekly update table.*****/
Select E.Clientname,f.rulegroupname, e.Policyid,PolicyStartDate = e.PeriodPolicyStartDate,PolicyEndDate = e.PeriodPolicyEndDate, e.Eligibles, e.Registered, l.Logging, F.F,F.I,F.T,F.FIT
,PercentofRegisteredDaysLogged
,PercentofEligibleDaysLogged
,PercentofDaysEnrolled
Into ##GroupsbyMotionbyYear
FROM #Eligibles e 
	Left join #Logging l
		On e.Clientname = l.Clientname and e.PeriodPolicyStartDate = l.PeriodPolicyStartDate and e.Policyid = l.Policyid
	Left join #FIT	f 
		ON e.Clientname = f.Clientname and e.PeriodPolicyStartDate = f.PeriodPolicyStartDate and e.Policyid = f.Policyid
Where e.Policyid = '5400-2441'

Select * FROM Dermsl_prod.dbo.MemberSignupData m inner join Dermsl_prod.dbo.lookupRuleGroup lrg on lrg.LookupRuleGroupid = m.LookupRuleGroupid 
and m.lookupClientid = 50 and ActiveFlag = 1 and isnull(CancelledDateTime,'20170101') > ProgramStartDate
where CancelledDatetime > ProgramStartDate and CancelledDateTime <= getdate()

Select Sum(Eligibles), sum(registered) FROM ##GroupsbyMotionbyYear Where PolicyendDate > Getdate()
