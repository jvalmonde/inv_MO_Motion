use Dermsl_reporting;
Set transaction isolation level read uncommitted 

/*****Set up the Eligibles and Registered by month table.*******/
Drop table #Cte1
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

  Create unique Clustered index idxRuleGroupMonth on #motionByGroup(LookupRuleGroupid,YearMonth)



GO

 Drop table #Activity1
 Select de.clientname,de.programStartdate,de.EligibleID, de.LookupruleGroupid,YEAR_MO, Date = full_Dt, isRegistered, Fpoints,Ipoints, TPOints, PossibleFPoints, PossibleIPoints, PossibleTPoints, TotalAwards,TotalSteps
 into #Activity1
 FROM	dbo.Dim_eligibles de 
 inner join		dbo.Fact_PreloadActivity b on de.EligibleID = b.Eligibleid 
 inner join		dbo.Dim_Date dd on dd.DT_SYS_ID = b.Dt_Sys_ID
 Where de.clientname in( 'All savers Motion','key accounts uhcm') and dd.Full_Dt >= '20140401'-- and de.LookupRuleGroupid < 2000
Create clustered index idxactivity on #Activity1(LookupruleGroupid)
Create index idxactivity2 on #Activity1(Date, Year_Mo) include (Fpoints,Ipoints,TPOints, EligibleId)
GO 

Drop table PolicyYear
Select Distinct  *   into PolicyYear FROM	dbo.Dim_SESAllsaversPolicyYear b

Create unique Clustered index idx on PolicyYear(LookupRulegroupid,PeriodPolicyStartDate)
Create index idxlrg on PolicyYear(LookupRuleGroupid)
Create index idxend on PolicyYear(PeriodPolicyEndDate)
Create index idxlSt on PolicyYear(PeriodPolicyStartDate)

GO
use pdb_DermReporting; 
--1. Growth and Participation by Month and for established members(members who have been eligible for at least 90 days. --Can check this out by gender and Agebin if needed.
Drop table #FIT
SELECT ClientName, YearMonth = Year_MO
,F = Sum(Fpoints*1.00)/NULLIF(Sum(PossibleFPoints),0)
,I = Sum(Ipoints*1.00)/NULLIF(Sum(PossibleIPoints) ,0)
,T = Sum(Tpoints*1.00)/NULLIF(Sum(PossibleTPoints) ,0)
,FIT = SUM(Fpoints + IPoints + TPoints*1.00) /NULLIF(Sum(PossibleFPoints + PossibleIPoints + PossibleTPoints),0)

,Registered_F =   Sum(Case when isregistered = 1 then Fpoints					  ELSE 0 END )* 1.00/NULLIF(Sum(  Case when isregistered = 1 then  PossibleFPoints                                     eLSE 0 END ),0)
,Registered_I =   Sum(Case when isregistered = 1 then Ipoints					  ELSE 0 END )* 1.00/NULLIF(Sum(  Case when isregistered = 1 then  PossibleIPoints                                     eLSE 0 END ),0)
,Registered_T =   Sum(Case when isregistered = 1 then Tpoints					  ELSE 0 END )* 1.00/NULLIF(Sum(  Case when isregistered = 1 then  PossibleTPoints                                     eLSE 0 END ),0)
,Registered_FIT = SUM(Case when isregistered = 1 then Fpoints + IPoints + TPoints ELSE 0 END ) *1.00/NULLIF(Sum(  Case when isregistered = 1 then  PossibleFPoints + PossibleIPoints + PossibleTPoints eLSE 0 END ),0)
Into #FIT
FROM #Activity1 a 
	Inner join	Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and getdate()
Where Clientname in ('All Savers Motion','Key Accounts UHCM')  --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,Year_mo
Order by YearMonth 

GO
Drop table #Eligible
Select 
Clientname, Yearmonth, Eligibles = sum(Eligibles), Registered = Sum(Registered) ,Groups = Count(Distinct LookupRuleGroupid)
Into #Eligible
 FROM #motionByGroup 
	where lookupRuleGroupid in ( select LookupRulegroupid FROM #Activity1)
	and RuleGroupName not in('Key Accounts Test 3')
Group BY Clientname,  Yearmonth

Select * FROM #Eligible
GO
Drop table #Logging
Select Clientname,YEAR_MO
,Logging = Count(Distinct Case when TotalSteps > 299 then EligibleId else null end)  
Into #Logging
FROM #Activity1 a 
	Inner join	Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts uhcm') --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,Year_mo
Select * FROM Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear
GO
/****Combine tables for allsavers Weekly update table.*****/
Drop table pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
Select E.Clientname,e.Yearmonth, e.Eligibles, e.Registered, l.Logging, F.F,F.I,F.T,F.FIT,F.Registered_F,F.Registered_I,F.Registered_T,
F.Registered_FIT,e.Groups
Into	pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
FROM #Eligible e 
	Inner join #Logging l
		On e.Clientname = l.Clientname and e.Yearmonth = l.Year_mo
	Inner join #FIT	f 
		ON e.Clientname = f.Clientname and e.Yearmonth = f.Yearmonth

Select * FROM pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
GO
/****Alt method, goals met instead of points earned********/

use pdb_DermReporting; 
--1. Growth and Participation by Month and for established members(members who have been eligible for at least 90 days. --Can check this out by gender and Agebin if needed.
Drop table #FIT_GoalMet

Select Clientname, Yearmonth, F,I,T, Registered_F, Registered_I , Registered_T
,FIT = (Raw_F + Raw_I  + Raw_T)*1.00 / Nullif(Raw_Possible,0)
,registered_FIT = (Raw_Registered_F + Raw_Registered_I  + Raw_Registered_T)* 1.00 / Nullif(Raw_Registered_Possible,0)
Into #FIT_GoalMet
 FROM 
(
SELECT ClientName, YearMonth = Year_MO
,Raw_F =   Sum(Case when Fpoints					  > 0 then 1 ELSE 0 End)
,Raw_I =   Sum(Case when Ipoints					  > 0 then 1 ELSE 0 End)
,Raw_T =   Sum(Case when Tpoints					  > 0 then 1 ELSE 0 End)
,Raw_Possible = sum(case when 1 =1 then 3 else null end )
,F =   Sum(Case when Fpoints					  > 0 then 1 ELSE 0 End)* 1.00/NULLIF( Sum(1),0)
,I =   Sum(Case when Ipoints					  > 0 then 1 ELSE 0 End)* 1.00/NULLIF( Sum(1) ,0)
,T =   Sum(Case when Tpoints					  > 0 then 1 ELSE 0 End)* 1.00/NULLIF( Sum(1) ,0)
,Raw_Registered_F =   Sum(Case when isregistered = 1 and Fpoints					  >= 1 then 1 ELSE 0 END )
,Raw_Registered_I =   Sum(Case when isregistered = 1 and Ipoints					  >= 1 then 1 ELSE 0 END )
,Raw_Registered_T =   Sum(Case when isregistered = 1 and Tpoints					  >= 1 then 1 ELSE 0 END )

,Registered_F =   Sum(Case when isregistered = 1 and Fpoints					  >= 1 then 1 ELSE 0 END )* 1.00/NULLIF(Sum(  Case when isregistered = 1 then  1                                     eLSE 0 END ),0)
,Registered_I =   Sum(Case when isregistered = 1 and Ipoints					  >= 1 then 1 ELSE 0 END )* 1.00/NULLIF(Sum(  Case when isregistered = 1 then  1                                     eLSE 0 END ),0)
,Registered_T =   Sum(Case when isregistered = 1 and Tpoints					  >= 1 then 1 ELSE 0 END )* 1.00/NULLIF(Sum(  Case when isregistered = 1 then  1                                     eLSE 0 END ),0)
,Raw_Registered_Possible = Sum(  Case when isregistered = 1 then  3                                     eLSE 0 END )

FROM #Activity1 a 
	Inner join	Dermsl_reporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts uhcm') --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,Year_mo
) a 
Order by YearMonth 


GO

Drop table pdb_Dermreporting.dbo.AllsaversWeeklyUpdate2
Select E.Clientname,e.Yearmonth, e.Eligibles, e.Registered, l.Logging, F.F,F.I,F.T,F.FIT,F.Registered_F,F.Registered_I,F.Registered_T,
F.Registered_FIT
Into pdb_Dermreporting.dbo.AllsaversWeeklyUpdate2
FROM #Eligible e 
	Inner join #Logging l
		On e.Clientname = l.Clientname and e.Yearmonth = l.Year_mo
	Inner join #FIT_GoalMet	f 
		ON e.Clientname = f.Clientname and e.Yearmonth = f.Yearmonth

GO


/*********************************************/


/*****************No need to limit to original cohort.  Show the dist of groups by registration rate**********************/
--Figure out why some groups have no eligibles(group termed or no one on plan with ryder). How to display these groups with clarification)
Drop table GroupLevelEngagement
		

Select *,--MotionOptionType = Case when PeriodPolicyStartdate <'20151001' then 'Opt-in Period' else 'Default Motion' end ,
 RegistrationPercentBin 
= Case when RegisteredPercent  = 0   then '0' 
	   When RegisteredPercent between 0 and 10 then '1 - 10'
	   When RegisteredPercent between 10 and 20 then '11 -20'
	   When RegisteredPercent between 20 and 30 then '21 - 30'
	   When RegisteredPercent between 30 and 40 then '31 - 40'
	   When RegisteredPercent between 40 and 50 then '41 - 50'
	   When RegisteredPercent between 50 and 60 then '51 - 60'
	   When RegisteredPercent between 60 and 70 then '61 - 70'
	   When RegisteredPercent between 70 and 80 then '71 - 80'
	   When RegisteredPercent between 80 and 90 then '81 - 90'
	   When RegisteredPercent between 90 and 100 then '91 - 100'
	   When RegisteredPercent >100 then  '100+'

	    end 
,TotalGroups = Count( lookupRuleGroupid) over(Partition by ClientName)
Into GroupLevelEngagement 
FROM 
(
		Select v.Clientname, de.LookupRUleGroupID,PeriodPolicyStartDate = Convert(Date,PeriodPolicyStartDate),RegisteredPercent = (Sum(isRegistered)*1.00				   /NULLIF(Count( v.EligibleID ),0))*100,
		GroupSize = NULLIF(Count( v.EligibleID ),0)
		,UnregisteredMembers = Count(Case when isregistered = 0 then v.EligibleID  else null end )
		FROM (#Activity1 v 
			Left join Dermsl_Reporting.dbo.Dim_Eligibles de on v.Eligibleid = de.Eligibleid 
			Left join Dermsl_Reporting.dbo.Dim_SESAllsaversPolicyYear ds on v.LookupRuleGroupid = ds.LOOKUPRuleGroupID 
													 and ds.PeriodPolicyNumber = 1
													-- and ds.PeriodPolicyStartDate >= '20160101'
													) 

													-- and ds.EffectiveStartDate = v.ProgramStartDate)
		Where v.Date = Convert(Date,Dateadd(Day,-1,Getdate())) and v.ClientName in( 'All Savers Motion','Key Accounts UHCM') and v.ProgramStartDate between '20140401' and Dateadd(Day,-00,Getdate())
		Group by v.Clientname, de.LookupRUleGroupID, Convert(Date,PeriodPolicyStartDate) 
) a

Select * FROM GroupLevelEngagement
Select * FROM Dermsl_Reporting.dbo.Dim_Eligibles de 
Select * FROM Dermsl_Reporting.dbo.Dim_SESAllsaversPolicyYear 
GO




/*****ActivationSticker**********/



Drop table #FirstorderforGroups 


 Select GroupId, Min(ActualShipDate) as ActualDeliveryDate 
 		Into #FirstorderforGroups 
FROM (
		Select groupid, Salesorderid,orderDate, ActualShipDate,ScheduledDeliveryDate, ActualDeliveryDate, ParentCustomer 
			,Customerid =  Customername   , SalesOrderStatusName
			,OrderQuantity= Sum(OrderQuantity)
			,Oid = Row_Number()Over(Partition by groupid order by ActualDeliverydate) 

		FROM Rpt_DeviceShipments
		Where Salesorderstatusname in('Delivered','New','released','shipped','Staged')
			and Parentcustomer = 'All Savers' --and s1.ActualDeliveryDate is not null 
		--and s1.salesorderid = 4963
		Group by Groupid,salesorderid,OrderDate, ActualShipDate,ScheduledDeliveryDate, ActualDeliveryDate,ParentCustomer, Customername,SalesorderStatusName
			
) a
Group by GroupId



use pdb_DermReporting;




use Dermsl_reporting;
go
If Object_Id('pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates') is not null 
Drop table pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates

Select mgm.LookupRuleGroupid
,ActivationSticker = Case when msd.GroupFirstShipDate > '20160601' then 1 else 0 end
, PeriodPolicyStartDate
,MonthIndex = 
Case when Datepart(Month,PeriodPolicyStartDate) = 1 then  1 
	 when Datepart(Month,PeriodPolicyStartDate) = 2 then  1.02
	 when Datepart(Month,PeriodPolicyStartDate) = 3 then  1.01
	 when Datepart(Month,PeriodPolicyStartDate) = 4 then  .962
	 when Datepart(Month,PeriodPolicyStartDate) = 5 then  .827
	 when Datepart(Month,PeriodPolicyStartDate) = 6 then  .922
	 when Datepart(Month,PeriodPolicyStartDate) = 7 then  .913
	 when Datepart(Month,PeriodPolicyStartDate) = 8 then  .875	
	 when Datepart(Month,PeriodPolicyStartDate) = 9 then  .797
	 when Datepart(Month,PeriodPolicyStartDate) = 10 then  .880
	 when Datepart(Month,PeriodPolicyStartDate) = 11 then  .925
	 when Datepart(Month,PeriodPolicyStartDate) = 12 then  .966
else NULL end 
,QuarterIndex =  case when  Datepart(Month,PeriodPolicyStartDate) between 1 and 3 then 1
				when  Datepart(Month,PeriodPolicyStartDate) between 4 and 6 then 2
				when  Datepart(Month,PeriodPolicyStartDate) between 7 and 9 then 3
				when  Datepart(Month,PeriodPolicyStartDate) between 10 and 12 then 4 ELSE null end 
,DaysFromEligibility = DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date)
,DaysFromEligibility_ShipDate = DateDiff(Day,IIF(PeriodPolicyStartDate > fog.ActualDeliveryDate, PeriodPolicyStartDate, ActualDeliveryDate), v.Date), Registered = sum(v.isRegistered), Count(*) as Eligible 
into pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates 
FROM 
(select  PeriodPolicyStartDate, LookupruleGroupid, Offercode
, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles 
FROM Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  )  mgm 
	Inner join vwActivityForPreloadGroups v   
		ON mgm.LookupRuleGroupid = v.LookupRuleGroupid 
		and mgm.Rn = 1  and v.ProgramStartDate = mgm.PeriodPolicyStartDate
	Inner join (Select LookupRuleGroupid, Min(Convert(Date,rowCreatedDatetime)) as GroupFirstShipDate FROM Dermsl_prod.dbo.Membersignupdata group by LookupRuleGroupid) msd 
		on  msd.LookupRuleGroupid = v.LookupRuleGroupid
	Left join #FirstorderforGroups fog
		On mgm.OfferCode  = fog.Groupid
--Where msd.rowCreatedDatetime between  dateadd(day, -7 ,v.ProgramStartDate ) and msd.ProgramStartDate
Group by mgm.LookupRuleGroupid
, PeriodPolicyStartdate,DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date)
,DateDiff(Day,IIF(PeriodPolicyStartDate > fog.ActualDeliveryDate, PeriodPolicyStartDate, ActualDeliveryDate), v.Date)
,Case when msd.GroupFirstShipDate > '20160601' then 1 else 0 end


/**************/



If Object_Id('pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple') is not null 
Drop table pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple

Select DatePart(Year,PeriodPolicyStartDate) as StartYear, DatePart(Month,PeriodPolicystartdate) as StartMonth
, DaysFromeligibility, Registered = sum(registered), Eligible = Sum(Eligible), RegistrationRate = Convert(int,(sum(registered)*1.00/sum(Eligible)) *100)
into pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple  
FRom
	(
	Select mgm.LookupRuleGroupid
	,ActivationSticker = Case when fog.ActualDeliveryDate > '20160601' then 1 else 0 end
	, PeriodPolicyStartDate
	,DaysFromEligibility = DateDiff(Day,IIF(PeriodPolicyStartDate > fog.ActualDeliveryDate, PeriodPolicyStartDate,  fog.ActualDeliveryDate), v.Date)
	, Registered = sum(v.isRegistered), Count(*) as Eligible 
	FROM 
		(select OfferCode, PeriodPolicyStartDate, LookupruleGroupid
		, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles FROM Dermsl_reporting.dbo.Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  
		)  mgm 
			Inner join Dermsl_reporting.dbo.vwActivityForPreloadGroups v   
				ON mgm.LookupRuleGroupid = v.LookupRuleGroupid 
				and mgm.Rn = 1  and v.ProgramStartDate = mgm.PeriodPolicyStartDate
			Inner join (Select LookupRuleGroupid, Min(Convert(Date,rowCreatedDatetime)) as GroupFirstShipDate FROM Dermsl_prod.dbo.Membersignupdata group by LookupRuleGroupid) msd 
				on  msd.LookupRuleGroupid = v.LookupRuleGroupid
			Left join #FirstorderforGroups fog
				On mgm.OfferCode  = fog.Groupid
	Group by mgm.LookupRuleGroupid, PeriodPolicyStartdate,DateDiff(Day,IIF(PeriodPolicyStartDate >   fog.ActualDeliveryDate, PeriodPolicyStartDate,  fog.ActualDeliveryDate), v.Date),Case when  fog.ActualDeliveryDate > '20160601' then 1 else 0 end
	) z
group by  DatePart(Year,PeriodPolicyStartDate) , DatePart(Month,PeriodPolicystartdate) , DaysFromeligibility
order by startmonth, DaysFromEligibility




/******Cumulative Registration and eligibility.******/

use Dermsl_reporting;
Drop table #months
Select Distinct Year_mo into #months FROM Dim_Date Where Year_mo between 201510 and 201610


Select 
a.Year_mo
,Total_EverEligible =  Count(Distinct de.Eligibleid)
,Total_EverRegistered = Count(Distinct Case when AccountVerifiedFlag = 1 then de.EligibleId else null end) 
Into pdb_DermReporting.dbo.EligibleAccumulation
 FROM #months a 
	Inner join Dim_eligibles de
		On dbo.Yearmonth(de.ProgramStartDate) <=  a.Year_mo
Group by a.Year_mo
Order by a.Year_mo


Select 
a.Year_mo
,Total_EverEligible =  Count(Distinct de.Clientmemberid)
,Total_EverRegistered = Count(Distinct Case when AccountVerifiedFlag = 1 then de.Clientmemberid else null end) 
 FROM #months a 
	Inner join Dermsl_Prod.dbo.MemberSignupdata de
		On dbo.Yearmonth(de.ProgramStartDate) <=  a.Year_mo
Where de.LookupClientid in (50,175)
Group by a.Year_mo
Order by a.Year_mo





use pdb_DermReporting; 


If Object_Id('pdb_DermReporting.dbo.GroupEarningsDist') is not null 
Drop table pdb_DermReporting.dbo.GroupEarningsDist 

Select * ,totalMonths =  Sum(Months) OVer(Partition by LookupRuleGroupid)
    Into pdb_DermReporting.dbo.GroupEarningsDist
FROM 
( 
SELECT Clientname, [LookupRuleGroupid]
,RuleGroupName
,PolicyYear = PeriodPolicyNumber 
--,b.EmployerGroupId
,maxMonth = max(a.Yearmonth) 
,MonthsintoPolicyYear = Case when count(*) <= 3 then '<3 Months' when count(*) between 4 and 8 then '4-8 Months' when count(*) between 9 and 12 then '9-12 Months' else null end 
,Months = Count(*) 
,Sum(F+I+T) as PointsEarned 
,Sum(Total) as PointsEarnedWC
,PointsPossible = sum(PossibleF + PossibleI + PossibleT)
,PercentofPointsearned = sum(F+I+T)/sum(PossibleF + PossibleI + PossibleT)
,PercentofPointsearnedWC = sum(Total)/sum(PossibleF + PossibleI + PossibleT)
,PercentofPointsearned_Bucket = Case  when sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT) > .51 then '51-100%'
									  when sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT)  > .30 then '30-50%'
									  when sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT)  > .20 then '20-30%'
									  when sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT)  > .10 then '10-20%'
									  when sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT)  > .00 then  '1-10%'
									  when sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT)  >= .00 then '0%'
									 else '0%' END
 ,PercentofFPointsearned_Bucket = Case when  sum(F) * 1.00 / Sum(PossibleF) > .51 then '51-100%'
									  when  sum(F) * 1.00 / Sum(PossibleF)  > .30 then '30-50%'
									  when  sum(F) * 1.00 / Sum(PossibleF)  > .20 then '20-30%'
									  when  sum(F) * 1.00 / Sum(PossibleF)  > .10 then '10-20%'
									  when sum(F) * 1.00 / Sum(PossibleF)   > .00 then  '1-10%'
									  when  sum(F) * 1.00 / Sum(PossibleF)  >= .00 then '0%'
									  else  '0%'  END
 ,PercentofIPointsearned_Bucket = Case when sum(I) * 1.00 / Sum(PossibleI) > .51 then  '51-100%'
									  when sum(I) * 1.00 / Sum(PossibleI)  > .30 then  '30-50%'
									  when sum(I) * 1.00 / Sum(PossibleI)  > .20 then  '20-30%'
									  when sum(I) * 1.00 / Sum(PossibleI)  > .10 then  '10-20%'
									  when sum(I) * 1.00 / Sum(PossibleI)  > .00 then   '1-10%'
									  when sum(I) * 1.00 / Sum(PossibleI)  >= .00 then  '0%'
									  else '0%' END
 ,PercentofTPointsearned_Bucket = Case when sum(T) * 1.00 / Sum(PossibleT) > .51 then	'51-100%'
									  when sum(T) *  1.00 / Sum(PossibleT) > .30 then	'30-50%'
									  when sum(T) *  1.00 / Sum(PossibleT) > .20 then	'20-30%'
									  when sum(T) *  1.00 / Sum(PossibleT) > .10 then	'10-20%'
									  when sum(T) *  1.00 / Sum(PossibleT) > .00 then	 '1-10%'
									  when sum(T) *  1.00 / Sum(PossibleT) >= .00 then	 '0%'
									  else '0%' END

 
  FROM Dermsl_reporting.[dbo].[Motion_by_Group_by_Month] a 
	--Inner join Devsql10.AllSavers_prod.dbo.Dim_policy b
	--	On replace(a.OfferCode, '-','00') = b.Policyid 
	--	and a.Yearmonth = b.Yearmo 
  Where Eligibles >  2  --and 1 = 0 
  group by Clientname, [LookupRuleGroupid]
,RuleGroupName
,PeriodPolicyNumber 
--,b.EmployerGroupId
) a

GO
/********************Member Level  -- This can be made way simpler by avoiding the use of the view.******************************/

/******Simpler Model - Updated 10/27/2016 ******************/


If Object_Id('tempdb.dbo.#possiblePoints') is not null 
Drop table #possiblePoints

Select  Lookuprulegroupid, Dt_Sys_Id, full_dt,Yearmonth, PossiblePoints = sum(PossiblePoints)
Into #possiblePoints
FROM 
(
Select LookupRuleGroupid, ruleName,dd.DT_SYS_ID, dd.Full_Dt,dd.YEAR_MO as Yearmonth, Max(Awards) as possiblePoints 
	From Dermsl_reporting.dbo.Dim_Rulesandpoints drp 
		Inner join Dermsl_reporting.dbo.Dim_Date dd 
			On dd.full_dt >=  drp.Startdate and dd.full_Dt <=  drp.EndDate
	where  RuleName in ('Frequency', 'Intensity','Tenacity') and dd.FULL_DT between '20140101' and EOMonth(dateadd(Month,-1,getdate()))
	group by LookupRuleGroupid,Rulename,dd.DT_SYS_ID, dd.Full_Dt,dd.YEAR_MO
)  a
Group by Lookuprulegroupid,DT_SYS_ID, full_dt,Yearmonth


Create unique clustered index idxppd on #PossiblePoints(LookupRuleGroupid, Full_dt)



/******************************************************************************/



Drop table pdb_DermReporting.dbo.MemberearningsDist_new
Select 
[Sample] = 'Active', a.Clientname, a.LookupRuleGroupid, EligibleID,ActiveFlag
,PolicyYear = PeriodPolicyNumber 
,PeriodPolicyStartDate
,MonthsofEligibility = Datediff(month,Programstartdate,Getdate())
--,MonthsintoPolicyYear = Case when count(Distinct b.Yearmonth) <= 3 then '<3' when count(Distinct b.Yearmonth) between 4 and 8 then '4-8' when count(Distinct b.Yearmonth) between 9 and 12 then '9-12' else null end 
--,Months = Count(*)
,Sum(ISNULL(FPointS,0)+ISNULL(IPoints,0)+ISNULL(TPoints,0)) as FITPointsEarned 
,Sum(ISNULL(TotalAwards,0)) as PointsEarned 
,PercentofGoalsMet = sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(Nullif(dd.PossiblePoints,0))
,PointsPossible = sum(isnull(dd.PossiblePoints,0) )
,PercentofPointsearned = sum(ISNULL(TotalAwards,0))/sum(PossibleFPoints + PossibleIPoints + PossibleTPoints)
,PercentofPointsearned_Bucket = Case when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .75 then '75 - 100%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .50 then '50 - 75%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .25 then '25 -50%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .10 then '10-25%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .00 then '1-10%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) >= .00 then '0%'
									 else '0%' END
,PercentofGoalsMet_Bucket =     Case when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .75 then '75 - 100%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .50 then '50 - 75%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .25 then '25 -50%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .10 then '10-25%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .00 then '1-10%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) >= .00 then '0%'
									 else '0%' END
 ,PercentofGoalsMet_BucketTest =Case when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .75 then '75 - 100%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .50 then '50 - 75%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .25 then '25 -50%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .10 then '10-25%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .00 then '1-10%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) >= .00 then '0%'
									 else '0%' END
Into pdb_DermReporting.dbo.MemberearningsDist_New
FROM (Dermsl_Reporting.dbo.Dim_Eligibles a inner join Dermsl_Reporting.dbo.Motion_by_Group_by_Month b on a.LookupRuleGroupid = b.LookupRuleGroupid and  a.ProgramStartdate between PeriodPolicyStartdate and periodPolicyEndDate) 
		Left join  #possiblePoints dd 
		On a.LookupRuleGroupID = dd.LookupRuleGroupid
		and dd.Full_Dt between a.ProgramStartdate and isnull(a.CancelledDatetime,Getdate())
		and dd.Yearmonth = b.Yearmonth
	Left join Dermsl_Reporting.[dbo].[Fact_Activity]	   FA 
		ON a.Account_id = FA.Account_id
		and dd.Dt_sys_Id = fa.Dt_Sys_Id
Where Datediff(day,a.Programstartdate,isnull(a.CancelledDatetime, getdate())) >= 0 and b.Yearmonth < dbo.Yearmonth(Getdate())
--Select * FROM Dermsl_Reporting.[dbo].[Fact_Activity]
  group by a.Clientname,a.LookupRuleGroupid,  a.EligibleID,ActiveFlag
  ,Datediff(month,Programstartdate,Getdate()),PeriodPolicyNumber,PeriodPolicyStartDate-- ,Case when count(Distinct b.Yearmonth) <= 3 then '<3' when count(Distinct b.Yearmonth) between 4 and 8 then '4-8' when count(Distinct b.Yearmonth) between 9 and 12 then '9-12' else null end 
  having Count(Distinct Case when totalSteps >= 300 then dd.Yearmonth else null end )*1.00  = Count(Distinct b.Yearmonth) 




  union
  Select 
[Sample] = 'Registered', a.Clientname, a.LookupRuleGroupid, EligibleID,ActiveFlag
,PolicyYear = PeriodPolicyNumber 
,PeriodPolicyStartDate
,MonthsofEligibility = Datediff(month,Programstartdate,Getdate())
--,MonthsintoPolicyYear = Case when count(Distinct b.Yearmonth) <= 3 then '<3' when count(Distinct b.Yearmonth) between 4 and 8 then '4-8' when count(Distinct b.Yearmonth) between 9 and 12 then '9-12' else null end 
--,Months = Count(*)
,Sum(ISNULL(FPointS,0)+ISNULL(IPoints,0)+ISNULL(TPoints,0)) as FITPointsEarned 
,Sum(ISNULL(TotalAwards,0)) as PointsEarned 
,PercentofGoalsMet = sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(Nullif(dd.PossiblePoints,0))
,PointsPossible = sum(isnull(dd.PossiblePoints,0) )
,PercentofPointsearned = sum(ISNULL(TotalAwards,0))/sum(PossibleFPoints + PossibleIPoints + PossibleTPoints)
,PercentofPointsearned_Bucket = Case when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .75 then '75 - 100%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .50 then '50 - 75%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .25 then '25 -50%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .10 then '10-25%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .00 then '1-10%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) >= .00 then '0%'
									 else '0%' END
,PercentofGoalsMet_Bucket =     Case when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .75 then '75 - 100%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .50 then '50 - 75%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .25 then '25 -50%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .10 then '10-25%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) > .00 then '1-10%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(dd.PossiblePoints) >= .00 then '0%'
									 else '0%' END
 ,PercentofGoalsMet_BucketTest =Case when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .75 then '75 - 100%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .50 then '50 - 75%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .25 then '25 -50%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .10 then '10-25%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .00 then '1-10%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) >= .00 then '0%'
									 else '0%' END
FROM (Dermsl_Reporting.dbo.Dim_Eligibles a inner join Dermsl_Reporting.dbo.Motion_by_Group_by_Month b on a.LookupRuleGroupid = b.LookupRuleGroupid and  a.ProgramStartdate between PeriodPolicyStartdate and periodPolicyEndDate) 
		Left join  #possiblePoints dd 
		On a.LookupRuleGroupID = dd.LookupRuleGroupid
		and dd.Full_Dt between a.ProgramStartdate and isnull(a.CancelledDatetime,Getdate())
		and dd.Yearmonth = b.Yearmonth
	Left join Dermsl_Reporting.[dbo].[Fact_Activity]	   FA 
		ON a.Account_id = FA.Account_id
		and dd.Dt_sys_Id = fa.Dt_Sys_Id
Where a.AccountVerifiedDateTime is not null and  Datediff(day,a.Programstartdate,isnull(a.CancelledDatetime, getdate())) >= 0 and b.Yearmonth < dbo.Yearmonth(Getdate())
  group by a.Clientname,a.LookupRuleGroupid,  a.EligibleID,ActiveFlag
  ,Datediff(month,Programstartdate,Getdate()),PeriodPolicyNumber,PeriodPolicyStartDate-- ,Case when count(Distinct b.Yearmonth) <= 3 then '<3' when count(Distinct b.Yearmonth) between 4 and 8 then '4-8' when count(Distinct b.Yearmonth) between 9 and 12 then '9-12' else null end 

union

Select 
[Sample] = 'All Eligibles', a.Clientname, a.LookupRuleGroupid, EligibleID, ActiveFlag
,PolicyYear = PeriodPolicyNumber 
,PeriodPolicyStartDate
,MonthsofEligibility = Datediff(month,Programstartdate,Getdate())
,Sum(ISNULL(FPointS,0)+ISNULL(IPoints,0)+ISNULL(TPoints,0)) as FITPointsEarned 
,Sum(ISNULL(TotalAwards,0)) as PointsEarned 

,PercentofPointsearned = sum(ISNULL(TotalAwards,0))/sum(PossibleFPoints + PossibleIPoints + PossibleTPoints)
,PointsPossible = sum(isnull(dd.PossiblePoints,0) )
,PercentofGoals_Met = sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(Nullif(dd.PossiblePoints,0))
,PercentofPointsearned_Bucket = Case when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .75 then '75 - 100%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .50 then '50 - 75%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .25 then '25 -50%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .10 then '10-25%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) > .00 then '1-10%'
									 when sum(ISNULL(TotalAwards,0))*1.00/sum(dd.PossiblePoints) >= .00 then '0%'
									 else '0%' END
,PercentofGoalsMet_Bucket =     Case when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(Nullif(dd.PossiblePoints,0)) > .75 then '75 - 100%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(Nullif(dd.PossiblePoints,0)) > .50 then '50 - 75%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(Nullif(dd.PossiblePoints,0)) > .25 then '25 -50%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(Nullif(dd.PossiblePoints,0)) > .10 then '10-25%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(Nullif(dd.PossiblePoints,0)) > .00 then '1-10%'
									 when sum(ISNULL(Fpoints,0) + ISNULL(IPOINTs,0) + ISNULL(TPOINTS,0))*1.00/sum(Nullif(dd.PossiblePoints,0)) >= .00 then '0%'
									 else '0%' END
 ,PercentofGoalsMet_BucketTest =Case when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .75 then '75 - 100%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .50 then '50 - 75%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .25 then '25 -50%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .10 then '10-25%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) > .00 then '1-10%'
									 when sum(ISNULL(fa.F,0) + ISNULL(fa.I,0) + ISNULL(fa.T,0))*1.00/sum(3) >= .00 then '0%'
									 else '0%' END
FROM (	
Dermsl_Reporting.dbo.Dim_Eligibles a 
			inner join Dermsl_Reporting.dbo.Motion_by_Group_by_Month b 
				on a.LookupRuleGroupid = b.LookupRuleGroupid and  a.ProgramStartdate between PeriodPolicyStartdate and periodPolicyEndDate
	  ) 
		Left join  #possiblePoints dd 
		On a.LookupRuleGroupID = dd.LookupRuleGroupid
		and dd.Full_Dt between a.ProgramStartdate and isnull(a.CancelledDatetime,Getdate())
		and dd.Yearmonth = b.Yearmonth
	Left join Dermsl_Reporting.[dbo].[Fact_Activity]	   FA 
		ON a.Account_id = FA.Account_id
		and dd.Dt_sys_Id = fa.Dt_Sys_Id
Where Datediff(day,a.Programstartdate,isnull(a.CancelledDatetime, getdate())) >= 0 
and a.ProgramStartDate < Dateadd(day,1,EOMonth(Dateadd(month, -1,Getdate())))
group by a.Clientname,a.LookupRuleGroupid,  a.EligibleID,ActiveFlag,Datediff(month,Programstartdate,Getdate()),PeriodPolicyNumber,PeriodPolicyStartDate
Order by EligibleId



/****/

Select * FROM Dermsl_Reporting.dbo.Dim_Eligibles Where isnull(CancelledDatetime, '20990909') > programStartdate

Select Eligibleid, Count(*) 
FROM pdb_DermReporting.dbo.MemberearningsDist_new 
where sample = 'All Eligibles'
group by Eligibleid
Having Count(*) > 1 

Select * FROM dermsl_reporting.dbo.dim_eligibles where eligibleid In
(
113548
,133399
,147677
,168925
,168587

)
Select * FROM  pdb_DermReporting.dbo.MemberearningsDist_new where eligibleid = 56774



Select pointsearned,pointsPossible, *  FROM  pdb_DermReporting.dbo.MemberearningsDist_new where [Sample] = 'All Eligibles'

Select Distinct Eligibleid  FROM dermsl_reporting.dbo.dim_eligibles
except
Select Distinct Eligibleid
FROM pdb_DermReporting.dbo.MemberearningsDist_new 

Select * FROM Dermsl_Reporting.dbo.Dim_Eligibles a Where eligibleid = 133399
Select * FROM (	
Dermsl_Reporting.dbo.Dim_Eligibles a 
			inner join Dermsl_Reporting.dbo.Motion_by_Group_by_Month b 
				on a.LookupRuleGroupid = b.LookupRuleGroupid and ProgramStartdate Between PeriodPolicyStartdate and PeriodPolicyEndDate
	  ) 
		--Left join  #possiblePoints dd 
		--On a.LookupRuleGroupID = dd.LookupRuleGroupid
		--and dd.Full_Dt between a.ProgramStartdate and isnull(a.CancelledDatetime,Getdate())
		--and dd.Yearmonth = b.Yearmonth
	--Left join Dermsl_Reporting.[dbo].[Fact_Activity]	   FA 
	--	ON a.Account_id = FA.Account_id
	--	and dd.Dt_sys_Id = fa.Dt_Sys_Id
Where 1 = 1 
-- and Datediff(day,a.Programstartdate,isnull(a.CancelledDatetime, getdate())) >= 0 
--and a.ProgramStartDate < Dateadd(day,1,EOMonth(Dateadd(month, -1,Getdate()))) 
and eligibleid = 133399
--group by a.Clientname,a.LookupRuleGroupid,  a.EligibleID,ActiveFlag,Datediff(month,Programstartdate,Getdate()),PeriodPolicyNumber,PeriodPolicyStartDate
--Order by EligibleId


Select * FROM Dermsl_prod.dbo.LookupRuleGroup where lookupRulegroupid = 3224

Select Yearmonth, sum(eligibles), Count(*) FROM Dermsl_Reporting.dbo.Motion_by_group_by_month where yearmonth in( 201510,201410) group by Yearmonth

Select PeriodPolicyNumber, Sum(eligibles), Count(*) FROM Dermsl_Reporting.dbo.Motion_by_group_by_month Where dbo.Yearmonth(PeriodPolicyStartdate) = yearmonth and Yearmonth = 201510 Group by PeriodPolicyNumber

Select count(*), Count(EffectiveEndDate) 
--Select *  
FROM Dermsl_Reporting.dbo.Dim_SESAllsaversPolicyYear Where EffectiveStartdate = '20151001' and periodpolicynumber = 1 --74 out of 319

Select count(*), Count(EffectiveEndDate) 
--Select *  
FROM Dermsl_Reporting.dbo.Dim_SESAllsaversPolicyYear Where EffectiveStartdate = '20141001' and periodpolicynumber = 2  --2 out of 15




/******Renewal Rates***************/
 Select a.LookupClientid, Renewed_Percent = Sum(Case when isnull(GroupEndDateTime,'20990101') > PeriodPolicyEndDate then 1 else 0 end)*1.00/Count(*)
 FROM Dim_SESAllsaversPolicyYear a
	Left join Dermsl_prod.dbo.LookupRuleGroup b
		ON a.LookupRulegroupid = b.LookupRuleGroupid 
 where PeriodPolicyStartDate between '20160101' and '20160131'
  Group by a.LookupClientid