
use Dermsl_reporting; 

--Select sum(Convert(int,[Member Months])) FROM [pdb_dermReporting].[dbo].[MotionGroupPremiums] 
-- where [Plan Effective date] in ('20151001','20161101') order by [Plan Effective Date]
/****Need to limit this to Oct 2015 and nov 2015************/
GO 
Drop table #Exclusions
Select *
into #Exclusions 
FROM 
(
Select *,  Rn = row_number()over(Partition by [Group id] order by Convert(date,[Plan Effective Date]))  FROM [pdb_dermReporting].[dbo].[MotionGroupPremiums] 
) a
Where Rn = 1 and [Plan Effective date] not between  '20151001'  and '20151130'
GO



 /****Separate out days eligible for Reg Credit and not - groups established pre 10/1 have 40 day window, post 10/1 have 25 day window.*****/

 Drop table #Earnings
 Select LookupRuleGroupid, YearMonth,RegistrationCreditEligible
 ,sum(PossibleFPoints) as PossibleFPoints
 ,sum(PossibleIPoints) as PossibleIPoints
 ,sum(PossibletPoints) as PossibletPoints
 ,sum(Fpoints) as FPoints
 ,Sum(IPoints) as IPoints 
 ,sum(TotalAwards) as TotalAwards
 ,sum(TPoints) as TPoints 
 ,sum(TotalSteps) as TotalSteps
Into #Earnings
 FROM 
 (
 Select a.LookupRuleGroupid , RegistrationCreditEligible = Case when DaysFromEligibility < 29 and a.PeriodPolicyStartDate < '20151001'  then 1
																when DaysFromEligibility < 24 and a.PeriodPolicyStartDate >= '20151001'  then 1
																else 0 end
, DaysFromEligibility
 , a.PeriodPolicyNumber, PeriodPolicyStartDate, a.YearMonth,b.PossibleFPoints, b.PossibleIPoints,  b.PossibleTPoints,b.FPoints, b.TPoints,b.IPoints,  b.totalAwards, TotalSteps 
 --Select Distinct b.* 
 FROM Dermsl_reporting.dbo.Motion_by_Group_by_Month   a
	Inner join Dermsl_reporting.dbo.vwActivityForPreloadGroups b
		on a.LookupRuleGroupid  = b.LookupRuleGroupid
		and dbo.Yearmonth(b.Date) = a.Yearmonth 
--Where a.LookupRuleGroupid = 1276
) a 
Group  by LookupRuleGroupid, YearMonth,RegistrationCreditEligible

--Select * FROM #Earnings where LookupRuleGroupid = 1088  order by Yearmonth
/*****************************************/

Drop table #Policies
  Select Policyid,Yearmo, Members = Count(*) 
  INTO #Policies 
  FROM pdb_DermReporting.dbo.Dim_MemberDetail Where insuredFlag = 1 Group by Policyid, Yearmo



If Object_Id('tempdb.dbo.#Aggregate1') is not null
Drop table #Aggregate1

SELECT  
Groupid = b.Offercode
,b.Rulegroupname
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end as Firstmonth  
,Case when  PeriodPolicyNumber = 1  then 1 else 0 end as FirstYear 
, [Plan Effective date] = Convert(Date,b.[PeriodPOlicyStartdate])
, [Plan Term Date]      = Convert(Date,b.[PeriodPOlicyEnddate])
, [Total Premium Equivalent] = '' 
, sum(c.Members) as [Insured Members]
, b.LookupRuleGroupid
,MotionDataPolicyMonths = Count(Distinct b.Yearmonth)
, EligibleMemberMonths		 = sum(eligibles)
, Earnings = suM(e.TotalAwards)
, F_Earnings = sum(e.Fpoints)
, I_Earnings = sum(e.Ipoints)
, T_earnings = sum(e.TPoints)
, F_Possible = Sum(Case when e.RegistrationCreditEligible = 0 then e.PossibleFPoints else 0 end )
, I_Possible = Sum(Case when e.RegistrationCreditEligible = 0 then e.PossibleIPoints else 0 end )
, T_Possible = Sum(Case when e.RegistrationCreditEligible = 0 then e.PossibleTPoints else 0 end )
, RegisteredMemberMonths = sum(Registered)
, ActiveMemberMonths     = sum(PercentActiveDays) 
,PossibleEarnings        = sum(Case when e.RegistrationCreditEligible = 0 then e.PossibleFPoints + e.PossibleIPoints + e.PossibleTPoints else 0 end)
, RegistrationCreditsEarned = sum(Case when e.RegistrationCreditEligible = 1 then e.TotalAwards else 0 end)
,RegistrationCreditsAvailable = sum(Case when e.RegistrationCreditEligible = 1 then e.PossibleFPoints + e.PossibleIPoints + e.PossibleTPoints else 0 end)
, OtherCreditsEarned = sum(Case when e.RegistrationCreditEligible = 0 and (e.FPoints + E.IPoints + e.TPoints) <> e.TotalAwards then e.TotalAwards - (e.FPoints + E.IPoints + e.TPoints) else 0 end)
,Rn = row_number()over(Partition by b.LookupRuleGroupid order by Convert(date,PeriodPolicyStartdate)) 
Into #Aggregate1
FROM  Dermsl_reporting.dbo.Motion_by_Group_by_Month b
	Left join #Earnings e 
		On b.LookupRuleGroupid = e.LookupRuleGroupid
		and b.YearMonth  = e.YearMonth 
	Left join #Policies c 
		On replace(b.Offercode,'-','00') = c.PolicyId 
		and b.YearMonth = c.Yearmo
Where  b.PeriodPolicyStartdate between '20151001' and '20151130'
Group by b.Offercode, b.Rulegroupname
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end
,Case when  PeriodPolicyNumber = 1  then 1 else 0 end 
,Convert(Date,b.[PeriodPOlicyStartdate])
,Convert(Date,b.[PeriodPOlicyEnddate])
, b.LookupRuleGroupid
Go 
 Create unique Clustered index idx1 on #Aggregate1([GroupID], RN)
 Create index idx2 on #Aggregate1([Plan Effective Date], [Plan Term Date])
 Go
 --use tempdb;
 --Select a.* FROM tempdb.dbo.#Policies a


If Object_Id('tempdb.dbo.#Aggregate2') is not null
Drop table #Aggregate2

SELECT  
Groupid = b.Offercode
,b.Rulegroupname
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end as Firstmonth  
,Case when  PeriodPolicyNumber = 1  then 1 else 0 end as FirstYear 
, [Plan Effective date] = Convert(Date,b.[PeriodPOlicyStartdate])
, [Plan Term Date]      = Convert(Date,b.[PeriodPOlicyEnddate])
, [Total Premium Equivalent] = '' 
, sum(c.Members) as [Insured Members]
, b.LookupRuleGroupid
,MotionDataPolicyMonths = Count(Distinct b.Yearmonth)
, EligibleMemberMonths		 = sum(eligibles)
,Rn = row_number()over(Partition by b.Offercode order by Convert(date,PeriodPolicyStartdate)) 
Into #Aggregate2
FROM  Dermsl_reporting.dbo.Motion_by_Group_by_Month b
	Left join #Policies c 
		On replace(b.Offercode,'-','00') = c.PolicyId 
		and b.YearMonth = c.Yearmo
Where  b.PeriodPolicyStartdate between '20151001' and '20151130'
Group by b.Offercode, b.Rulegroupname
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end
,Case when  PeriodPolicyNumber = 1  then 1 else 0 end 
,Convert(Date,b.[PeriodPOlicyStartdate])
,Convert(Date,b.[PeriodPOlicyEnddate])
, b.LookupRuleGroupid


Go

/*************Year 1 **********************************************/
/***************MemberMonths***********/
 Select Sample  = 'First Month'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2
 Where FirstMonth = 1 and firstYear = 1
 union
 Select Sample  = 'All Others'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2
 Where FirstMonth = 0 and firstYear = 1
 Union

 Select Sample  = 'Total'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2 Where  firstYear = 1




 Select Sample  = 'First Month'
 --,MemberMonths = sum(EligibleMemberMonths)
 --  ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
 Where FirstMonth = 1 and firstYear = 1
 union
 Select Sample  = 'All Others'
 --,MemberMonths = sum(EligibleMemberMonths)
 --  ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
 Where FirstMonth = 0 and firstYear = 1
 Union

 Select Sample  = 'Total'
 --,MemberMonths = sum(EligibleMemberMonths)
 --  ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1 Where  firstYear = 1


 /*************Year 2 **********************************************/
/***************MemberMonths***********/
 Select Sample  = 'First Month'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2
 Where FirstMonth = 1 and firstYear = 0
 union
 Select Sample  = 'All Others'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2
 Where FirstMonth = 0 and firstYear = 0
 Union

 Select Sample  = 'Total'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2 Where  firstYear = 0


/***Filtered for groups in which we have premium data, includes data through April 2014, and for plans with plan effective date prior to April 1,2016****/

 Select Sample  = 'First Month'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
 Where FirstMonth = 1 and firstYear = 0
 union
 Select Sample  = 'All Others'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
 Where FirstMonth = 0 and firstYear = 0
 Union

 Select Sample  = 'Total'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1 Where  firstYear = 0



  /*************All Years**********************************************/
/***************MemberMonths***********/
 Select Sample  = 'First Month'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2
 Where FirstMonth = 1 --and firstYear = 0
 union
 Select Sample  = 'All Others'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2
 Where FirstMonth = 0 --and firstYear = 0
 Union

 Select Sample  = 'Total'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 FROM #Aggregate2 --Where  firstYear = 0


/***Filtered for groups in which we have premium data, includes data through April 2014, and for plans with plan effective date prior to April 1,2016****/
/****All Years***/
 Select Sample  = 'First Month'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
 Where FirstMonth = 1-- and firstYear = 0
 union
 Select Sample  = 'All Others'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
 Where FirstMonth = 0 --and firstYear = 0
 Union

 Select Sample  = 'Total'
 ,MemberMonths = sum(EligibleMemberMonths)
   ,InsuredmemberMonths = sum([Insured Members])
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
   ,RegistrationCreditsEarned = suM(RegistrationCreditsEarned)
      ,RegistrationCreditsAvailable = suM(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings) + suM(RegistrationCreditsEarned) + sum(OtherCreditsEarned)
 , OtherCreditsEarned = sum(OtherCreditsEarned)
 ,[Total Possible Earnings] =   Sum(PossibleEarnings) + suM(RegistrationCreditsAvailable)
 FROM #Aggregate1
  --Where  firstYear = 0


  use Dermsl_reporting;
 /*****Key Accounts*****************/
 Drop table #Goalsmet
 Select a.EligibleID, dd.FULL_DT, c.F,c.I,c.T
into #Goalsmet
FROM Dermsl_reporting.dbo.vwActivityForPreloadGroups a
	Inner join Dermsl_reporting.dbo.Dim_Eligibles b
		On a.eligibleid = b.Eligibleid 
	Inner join (Dermsl_reporting.dbo.Fact_Activity c	inner join dim_date dd on c.Dt_Sys_ID = dd.DT_SYS_ID) 
		on b.Account_ID = c.Account_ID and a.Date = dd.FULL_DT


 Drop table #KAAggregate

 Select 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end as Firstmonth  
,MotionDataPolicyMonths = Count(Distinct Convert(varchar,b.Yearmonth)		+ Convert(varchar,b.Eligibleid ))
, EligibleMemberMonths		 = Count(Distinct Convert(varchar,b.Yearmonth) +  Convert(varchar,b.Eligibleid ))
, Earnings   = suM(b.totalAwards)
, F_Earnings = sum(Case when DaysFromEligibility > 29 then b.FPoints	   Else 0 end )
, I_Earnings = sum(Case when DaysFromEligibility > 29 then b.IPoints	   Else 0 end )
, T_earnings = sum(Case when DaysFromEligibility > 29 then b.TPoints	   Else 0 end )
, F_Possible = Sum(Case when DaysFromEligibility > 29 then PossibleFPoints Else 0 end )
, I_Possible = Sum(Case when DaysFromEligibility > 29 then PossibleIPoints Else 0 end )
, T_Possible = Sum(Case when DaysFromEligibility > 29 then PossibleTPoints Else 0 end )
, F_met = sum(gm.F)
, I_met = sum(gm.I)
, T_met = sum(gm.T)
, F_metPossible = Count(Case when DaysFromEligibility > 29 then PossibleFPoints Else 0 end)
, I_metPossible = Count(Case when DaysFromEligibility > 29 then PossibleIPoints Else 0 end)
, T_metPossible = Count(Case when DaysFromEligibility > 29 then PossibleTPoints Else 0 end)
, RegisteredMemberMonths = sum(isRegistered)
,RegistrationCreditsEarned    = Sum(Case when DaysFromEligibility <= 29 then totalAwards Else 0 end )
,RegistrationCreditsAvailable =	Sum(Case when DaysFromEligibility <= 29 then b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints Else 0 end )
,PossibleFITEarnings = sum(Case when DaysFromEligibility > 29 then b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints Else 0 end)
,PossibleEarnings        = sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, GoalAcheivement        = sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, Acheiving60PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.599' then 1 else 0 end 
, Acheiving30PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.299' then 1 else 0 end 
, Acheiving40PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.399' then 1 else 0 end 
, Acheiving50PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.499' then 1 else 0 end 
Into #KAAggregate
 FROM Dermsl_reporting.dbo.vwActivityForPreloadGroups b 
	Inner join Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear c
		ON b.LookupRuleGroupid = c.LOOKUPRuleGroupID
	Left join #goalsmet gm
		On b.EligibleID = gm.Eligibleid 
		and gm.Full_dt = b.Date
Where Clientname = 'Key Accounts'  and b.LookupRuleGroupid = 883 and YearMonth < 201607 and PeriodPolicyStartDate < '2016-06-01 00:00:00.000'
Group by 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end
, b.LookupRuleGroupid
union

 Select 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end as Firstmonth  
,MotionDataPolicyMonths = Count(Distinct Convert(varchar,b.Yearmonth)		+ Convert(varchar,b.Eligibleid ))
, EligibleMemberMonths		 = Count(Distinct Convert(varchar,b.Yearmonth) +  Convert(varchar,b.Eligibleid ))
, Earnings   = suM(b.totalAwards)
, F_Earnings = sum(Case when DaysFromEligibility > 3 then b.FPoints	   Else 0 end )
, I_Earnings = sum(Case when DaysFromEligibility > 3 then b.IPoints	   Else 0 end )
, T_earnings = sum(Case when DaysFromEligibility > 3 then b.TPoints	   Else 0 end )
, F_Possible = Sum(Case when DaysFromEligibility > 3 then PossibleFPoints Else 0 end )
, I_Possible = Sum(Case when DaysFromEligibility > 3 then PossibleIPoints Else 0 end )
, T_Possible = Sum(Case when DaysFromEligibility > 3 then PossibleTPoints Else 0 end )
, F_met = sum(gm.F)
, I_met = sum(gm.I)
, T_met = sum(gm.T)
, F_metPossible = Count(Case when DaysFromEligibility > 3 then PossibleFPoints Else 0 end)
, I_metPossible = Count(Case when DaysFromEligibility > 3 then PossibleIPoints Else 0 end)
, T_metPossible = Count(Case when DaysFromEligibility > 3 then PossibleTPoints Else 0 end)
, RegisteredMemberMonths = sum(isRegistered)
,RegistrationCreditsEarned    = Sum(Case when DaysFromEligibility <= 3 then totalAwards Else 0 end )
,RegistrationCreditsAvailable =	Sum(Case when DaysFromEligibility <= 3 then b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints Else 0 end )
,PossibleFITEarnings = sum(Case when DaysFromEligibility > 3 then b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints Else 0 end)
,PossibleEarnings        = sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, GoalAcheivement        = sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, Acheiving60PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.599' then 1 else 0 end 
, Acheiving30PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.299' then 1 else 0 end 
, Acheiving40PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.399' then 1 else 0 end 
, Acheiving50PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.499' then 1 else 0 end 
 FROM Dermsl_reporting.dbo.vwActivityForPreloadGroups b 
	Inner join Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear c
		ON b.LookupRuleGroupid = c.LOOKUPRuleGroupID
	Left join #goalsmet gm
		On b.EligibleID = gm.Eligibleid 
		and gm.Full_dt = b.Date
Where Clientname = 'Key Accounts'  and b.LookupRuleGroupid = 2497 and YearMonth < 201607 and PeriodPolicyStartDate < '2016-06-01 00:00:00.000'
Group by 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end
, b.LookupRuleGroupid

union

 Select 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end as Firstmonth  
,MotionDataPolicyMonths = Count(Distinct Convert(varchar,b.Yearmonth)		+ Convert(varchar,b.Eligibleid ))
, EligibleMemberMonths		 = Count(Distinct Convert(varchar,b.Yearmonth) +  Convert(varchar,b.Eligibleid ))
, Earnings   = suM(b.totalAwards)
, F_Earnings = sum( b.FPoints	     )
, I_Earnings = sum( b.IPoints	     )
, T_earnings = sum( b.TPoints	     )
, F_Possible = Sum( PossibleFPoints  )
, I_Possible = Sum( PossibleIPoints  )
, T_Possible = Sum( PossibleTPoints  )
, F_met = sum(gm.F)
, I_met = sum(gm.I)
, T_met = sum(gm.T)
, F_metPossible = Count(  PossibleFPoints )
, I_metPossible = Count(  PossibleIPoints )
, T_metPossible = Count(  PossibleTPoints )
, RegisteredMemberMonths = sum(isRegistered)
,RegistrationCreditsEarned    = Sum(0 )
,RegistrationCreditsAvailable =	Sum(0)
,PossibleFITEarnings = sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
,PossibleEarnings        = sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, GoalAcheivement        = sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, Acheiving60PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.599' then 1 else 0 end 
, Acheiving30PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.299' then 1 else 0 end 
, Acheiving40PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.399' then 1 else 0 end 
, Acheiving50PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.499' then 1 else 0 end 
 FROM Dermsl_reporting.dbo.vwActivityForPreloadGroups b 
	Inner join Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear c
		ON b.LookupRuleGroupid = c.LOOKUPRuleGroupID
	Left join #goalsmet gm
		On b.EligibleID = gm.Eligibleid 
		and gm.Full_dt = b.Date
Where Clientname = 'Key Accounts'  and b.LookupRuleGroupid in (2496,2617) and YearMonth < 201607 and PeriodPolicyStartDate < '2016-06-01 00:00:00.000'
Group by 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end
, b.LookupRuleGroupid

union

 Select 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end as Firstmonth  
,MotionDataPolicyMonths = Count(Distinct Convert(varchar,b.Yearmonth)		+ Convert(varchar,b.Eligibleid ))
, EligibleMemberMonths		 = Count(Distinct Convert(varchar,b.Yearmonth) +  Convert(varchar,b.Eligibleid ))
, Earnings   = suM(b.totalAwards)
, F_Earnings = sum( b.FPoints	     )
, I_Earnings = sum( b.IPoints	     )
, T_earnings = sum( b.TPoints	     )
, F_Possible = Sum( PossibleFPoints  )
, I_Possible = Sum( PossibleIPoints  )
, T_Possible = Sum( PossibleTPoints  )
, F_met = sum(gm.F)
, I_met = sum(gm.I)
, T_met = sum(gm.T)
, F_metPossible = Count(  PossibleFPoints )
, I_metPossible = Count(  PossibleIPoints )
, T_metPossible = Count(  PossibleTPoints )
, RegisteredMemberMonths = sum(isRegistered)
,RegistrationCreditsEarned    = Sum(Case when totalAwards >= 40 then 40 else 0 end  )
,RegistrationCreditsAvailable =	Sum(Case when DaysFromEligibility = 0 then 40 else 0 end) 
,PossibleFITEarnings = sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
,PossibleEarnings        = sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) + Sum(Case when DaysFromEligibility = 0 then 40 else 0 end) 
, GoalAcheivement        = sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints)
, Acheiving60PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.599' then 1 else 0 end 
, Acheiving30PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.299' then 1 else 0 end 
, Acheiving40PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.399' then 1 else 0 end 
, Acheiving50PercentRateCap        = Case when sum(b.TotalAwards)/sum(b.PossibleFPoints + b.PossibleIPoints + b.PossibleTPoints) > '.499' then 1 else 0 end 
 FROM Dermsl_reporting.dbo.vwActivityForPreloadGroups b 
	Inner join Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear c
		ON b.LookupRuleGroupid = c.LOOKUPRuleGroupID
	Left join #goalsmet gm
		On b.EligibleID = gm.Eligibleid 
		and gm.Full_dt = b.Date
Where Clientname = 'Key Accounts'  and b.LookupRuleGroupid in (2616) and YearMonth < 201607 and PeriodPolicyStartDate < '2016-06-01 00:00:00.000'
Group by 
 b.LookupRuleGroupid
,case when b.Yearmonth = dbo.Yearmonth(PeriodPolicyStartdate) then 1 else 0 end
, b.LookupRuleGroupid







--Select * FROM Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear where LookupClientid = 147 and PeriodPolicyStartDate <'20160601'

--Select Distinct LookupRuleGroupid From vwActivityForPreloadGroups where clientname = 'Key Accounts' and ProgramStartDate <= '20160201'





--/*******883 gets 4*30 and difference is added to earnings*********/
--Select DaysFromEligibility - DaysFromRegistration, * FROM vwActivityForPreloadGroups Where Clientname = 'Key Accounts' and LookupRuleGroupid = 883 
--and DaysFromEligibility between 30 and 90 and AccountVerifiedDateTime is not null and totalAwards > 0  and (FPoints + IPoints + TPoints) < totalAwards
--order by EligibleId, Date

--/*******2497 gets 4*4  and difference is added to earnings*********/
--Select DaysFromEligibility, sum(Fpoints+Ipoints+Tpoints), SUM(TotalAwards), Count(distinct Eligibleid), count(Distinct Case when AccountVerifiedDateTime is not null then eligibleid else null end)  
--FROM vwActivityForPreloadGroups Where Clientname = 'Key Accounts' and LookupRuleGroupid = 2497 
--and DaysFromEligibility between 0 and 25  --and totalAwards > 0  and (FPoints + IPoints + TPoints) < totalAwards
--Group by DaysFromEligibility
--order by DaysFromEligibility

--Select DaysFromEligibility - DaysFromRegistration, * FROM vwActivityForPreloadGroups Where Clientname = 'Key Accounts' 
--and LookupRuleGroupid = 2497 
--and DaysFromEligibility between 3 and 3 and AccountVerifiedDateTime is not null and totalAwards > 0  and (FPoints + IPoints + TPoints) < totalAwards
--order by EligibleId, Date

--/*******2496 gets nothing*********/
--Select DaysFromEligibility - DaysFromRegistration, * FROM vwActivityForPreloadGroups Where Clientname = 'Key Accounts' 
--and LookupRuleGroupid = 2496 and DaysFromEligibility between 0 and 30 and AccountVerifiedDateTime is not null and totalAwards > 0  and (FPoints + IPoints + TPoints) < totalAwards
--order by EligibleId, Date

--/*******2617 gets Nothing*********/
--Select DaysFromEligibility - DaysFromRegistration, * FROM vwActivityForPreloadGroups Where Clientname = 'Key Accounts' 
--and LookupRuleGroupid = 2617 and DaysFromEligibility between 0 and 30 and AccountVerifiedDateTime is not null and totalAwards > 0  and (FPoints + IPoints + TPoints) < totalAwards
--order by EligibleId, Date

--/*******2616 gets 40$ bonus on the day of registration if register within 30 days.*********/
Select DaysFromEligibility - DaysFromRegistration, * FROM vwActivityForPreloadGroups Where Clientname = 'Key Accounts' 
and LookupRuleGroupid = 4068 and DaysFromEligibility between 0 and 30 and AccountVerifiedDateTime is not null and totalAwards > 0  and (FPoints + IPoints + TPoints) < totalAwards
order by EligibleId, Date
Select * FROM Motion_by_Group_by_Month where LookupClientid = 175





 Select Sample  = 'First Month'
  ,MemberMonths = sum(EligibleMemberMonths)
, F_met = sum( F_met)
, I_met = sum( I_met)
, T_met = sum( T_met)
, F_metPossible = sum( F_metPossible)
, I_metPossible = sum( I_metPossible)
, T_metPossible = sum( T_metPossible)
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
 ,  RegistrationCreditsEarned       = sum(RegistrationCreditsEarned   )
,   RegistrationCreditsAvailable	= sum(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = sum(earnings)
 ,[Total Possible Earnings] =  Sum(PossibleEarnings) 
 FROM #KAAggregate
 Where FirstMonth = 1
 union
  Select Sample  = 'All Others'
  ,MemberMonths = sum(EligibleMemberMonths)
, F_met = sum( F_met)
, I_met = sum( I_met)
, T_met = sum( T_met)
, F_metPossible = sum( F_metPossible)
, I_metPossible = sum( I_metPossible)
, T_metPossible = sum( T_metPossible)
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
    ,  RegistrationCreditsEarned       = sum(RegistrationCreditsEarned   )
,   RegistrationCreditsAvailable	= sum(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = sum(earnings)
 ,[Total Possible Earnings] =  Sum(PossibleEarnings) 
 FROM #KAAggregate
 Where FirstMonth = 0
 union
  Select Sample  = 'Total'
  ,MemberMonths = sum(EligibleMemberMonths)
, F_met = sum( F_met)
, I_met = sum( I_met)
, T_met = sum( T_met)
, F_metPossible = sum( F_metPossible)
, I_metPossible = sum( I_metPossible)
, T_metPossible = sum( T_metPossible)
 ,Frequency = sum(F_Earnings)
 ,Intensity = sum(I_Earnings)
 ,Tenacity = sum(T_Earnings)
 ,F_Possible  = sum(F_possible)
  ,I_Possible  = sum(I_possible)
   ,T_Possible  = sum(T_possible)
    ,  RegistrationCreditsEarned       = sum(RegistrationCreditsEarned   )
,   RegistrationCreditsAvailable	= sum(RegistrationCreditsAvailable)
 , [Total Earned No Credits] = Sum(F_earnings) + sum(I_Earnings) + sum(T_Earnings)
 ,[Total Earned] = sum(earnings)
 ,[Total Possible Earnings] =  Sum(PossibleEarnings) 
 FROM #KAAggregate
Order by MemberMonths

--Select sum(eligibles) FROM dermsl_reporting.dbo.Motion_by_Group_by_Month m 
--where m.PeriodPolicyNumber = 1 and YearMonth = dbo.Yearmonth(periodpolicyStartDate) and Yearmonth <= '201606' and LookupClientid = 50 
--and m.PeriodPolicyStartDate < '20160501' 

----Select * FROM Dermsl_reporting.dbo.memberSignupdata where 

-- Select Right(Clientmemberid,2),  count(*) From #Aggregate1 a
--	Left join dermsl_Prod.dbo.Membersignupdata b 
--		ON a.LookupRuleGroupid = b.Lookuprulegroupid 
--		and dbo.Yearmonth(a.[Plan Effective date]) between  dbo.Yearmonth(b.ProgramStartdate) and dbo.Yearmonth(isnull(b.CancelledDatetime,'20990101'))
-- Where Firstmonth = 1 
-- Group by Right(Clientmemberid,2) 
-- order by count(*) desc

-- Select right(Systemid,2), Count(*)  FROM pdb_DermReporting.dbo.Dim_MemberDetail 
-- Where insuredFlag = 1  and Yearmo = 201606
-- Group by Right(Systemid,2) with rollup
-- order by Count(*) 