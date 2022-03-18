use pdb_Dermreporting;
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

  Select * FROM #motionByGroup


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
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and getdate()
Where Clientname in ('All Savers Motion','Key Accounts UHCM')  --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,Year_mo
Order by YearMonth 
Select Distinct RuleGroupname FROM Motion_By_Group_by_month Where clientname like'%Key%'


Drop table #Eligible
Select 
Clientname, Yearmonth, Eligibles = sum(Eligibles), Registered = Sum(Registered)
Into #Eligible
 FROM #motionByGroup 
	where lookupRuleGroupid in ( select LookupRulegroupid FROM #Activity1)
	and RuleGroupName not in('Key Accounts Test 3')
Group BY Clientname,  Yearmonth

Select * FROM #Eligible

Drop table #Logging
Select Clientname,YEAR_MO
,Logging = Count(Distinct Case when TotalSteps > 299 then EligibleId else null end)  
Into #Logging
FROM #Activity1 a 
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts uhcm') --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,Year_mo


/****Combine tables for allsavers Weekly update table.*****/
Drop table pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
Select E.Clientname,e.Yearmonth, e.Eligibles, e.Registered, l.Logging, F.F,F.I,F.T,F.FIT,F.Registered_F,F.Registered_I,F.Registered_T,
F.Registered_FIT
Into pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
FROM #Eligible e 
	Inner join #Logging l
		On e.Clientname = l.Clientname and e.Yearmonth = l.Year_mo
	Inner join #FIT	f 
		ON e.Clientname = f.Clientname and e.Yearmonth = f.Yearmonth

Select * FROM pdb_Dermreporting.dbo.AllsaversWeeklyUpdate

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
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.PeriodPolicyStartDate and PeriodPolicyEndDate
Where Clientname in ('All Savers Motion','Key Accounts uhcm') --and a.LookupRuleGroupid = 182
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 
Group by Clientname,Year_mo
) a 
Order by YearMonth 




Drop table pdb_Dermreporting.dbo.AllsaversWeeklyUpdate2
Select E.Clientname,e.Yearmonth, e.Eligibles, e.Registered, l.Logging, F.F,F.I,F.T,F.FIT,F.Registered_F,F.Registered_I,F.Registered_T,
F.Registered_FIT
Into pdb_Dermreporting.dbo.AllsaversWeeklyUpdate2
FROM #Eligible e 
	Inner join #Logging l
		On e.Clientname = l.Clientname and e.Yearmonth = l.Year_mo
	Inner join #FIT_GoalMet	f 
		ON e.Clientname = f.Clientname and e.Yearmonth = f.Yearmonth


Select * FROM pdb_Dermreporting.dbo.AllsaversWeeklyUpdate2 order by Clientname, Yearmonth



/*********************************************/


/*****************No need to limit to original cohort.  Show the dist of groups by registration rate**********************/
--Figure out why some groups have no eligibles(group termed or no one on plan with ryder). How to display these groups with clarification)
Drop table GroupLevelEngagement
		

Select *,MotionOptionType = Case when PeriodPolicyStartdate <'20151001' then 'Opt-in Period' else 'Default Motion' end ,
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
,TotalGroups = Count( lookupRuleGroupid) Over (Partition by Case when PeriodPolicyStartdate <'20151001' then 'Opt-in Period' else 'Default Motion' end)
Into GroupLevelEngagement 
FROM 
(
		Select v.Clientname, de.LookupRUleGroupID,PeriodPolicyStartDate = Convert(Date,PeriodPolicyStartDate),RegisteredPercent = (Sum(isRegistered)*1.00				   /NULLIF(Count( v.EligibleID ),0))*100,
		GroupSize = NULLIF(Count( v.EligibleID ),0)
		,UnregisteredMembers = Count(Case when isregistered = 0 then v.EligibleID  else null end )
		Select * FROM (#Activity1 v 
			Left join Dim_Eligibles de on v.Eligibleid = de.Eligibleid 
			Left join Dim_SESAllsaversPolicyYear ds on v.LookupRuleGroupid = ds.LOOKUPRuleGroupID 
													 and ds.PeriodPolicyNumber = 1
													-- and ds.PeriodPolicyStartDate >= '20160101'
													) Select * FROM Dim_SESAllsaversPolicyYear where lookupClientid <> 50
Where v.Clientname = 'Key Accounts UHCM'
													-- and ds.EffectiveStartDate = v.ProgramStartDate)
		Where v.Date = Convert(Date,Getdate()) and v.ClientName in( 'All Savers Motion','Key Accounts UHCM') and v.ProgramStartDate between '20140401' and Dateadd(Day,-00,Getdate())
		Group by v.Clientname, de.LookupRUleGroupID, Convert(Date,PeriodPolicyStartDate)
) a

Select * FROM GroupLevelEngagement



/******Shipments*************/

Use ses_prod;


Drop table pdb_abw.dbo.tempShipreport
Select s1.Salesorderid,s1.orderDate, s1.ActualShipDate, ParentCustomer = cbil2.CustomerName, Customerid =  cbil.Customername   , sos.SalesOrderStatusName, pa.ProductAttributeValue,p.PartNumber, OrderQuantity= Sum(sd.OrderQuantity)
into pdb_abw.dbo.tempShipreport
FROM dbo.SalesOrder s1
       INNER JOIN dbo.SalesOrderDetail sd ON sd.SalesOrderID = s1.SalesOrderID
       INNER JOIN dbo.SalesOrderDetailStatus sds ON sds.SalesOrderDetailStatusID = sd.SalesOrderDetailStatusID
	   INNER JOIN dbo.Customer cbil ON cbil.CustomerID = s1.BillToCustomerID
	   INNER JOIN dbo.Customer cbil2 ON cbil.parentCustomerID = cbil2.CustomerID
	   left join  dbo.SalesOrderStatus sos on s1.SalesOrderStatusID= sos.SalesOrderStatusID
	   Left JOIN (dbo.Product p Inner join dbo.ProductAttribute PA ON P.Productid = PA.Productid and pa.ProductAttributeCode = 'Model' AND pa.ProductAttributeValue IN ('32','36','39','61','80','90')) 
                           ON p.ProductID = sd.ProductID and pa.ProductAttributeCode = 'Model'
--Where sos.Salesorderstatusname in('Delivered','New','released','shipped','Staged')
--and s1.salesorderid = 4963
Group by s1.salesorderid,s1.OrderDate, s1.ActualShipDate,cbil2.Customername, cbil.Customername,sos.SalesorderStatusName,pa.ProductAttributeValue,p.Partnumber
order by s1.OrderDate desc




/*****ActivationSticker**********/



Drop table #FirstorderforGroups 


 Select GroupId, Min(ActualShipDate) as ActualDeliveryDate 
 		Into #FirstorderforGroups 
FROM (
		Select cbil.groupid, s1.Salesorderid,s1.orderDate, s1.ActualShipDate,s1.ScheduledDeliveryDate, s1.ActualDeliveryDate, ParentCustomer = cbil2.CustomerName
			,Customerid =  cbil.Customername   , sos.SalesOrderStatusName, pa.ProductAttributeValue,p.PartNumber
			,OrderQuantity= Sum(sd.OrderQuantity)
			,Oid = Row_Number()Over(Partition by cbil.groupid order by s1.ActualDeliverydate) 

		FROM ses_prod.dbo.SalesOrder s1
		       INNER JOIN ses_prod.dbo.SalesOrderDetail			as sd	ON sd.SalesOrderID = s1.SalesOrderID
		       INNER JOIN ses_prod.dbo.SalesOrderDetailStatus	as sds	ON sds.SalesOrderDetailStatusID = sd.SalesOrderDetailStatusID
			   INNER JOIN ses_prod.dbo.Customer					as cbil ON cbil.CustomerID = s1.BillToCustomerID
			   INNER JOIN ses_prod.dbo.Customer					as cbil2 ON cbil.parentCustomerID = cbil2.CustomerID
			   left join  ses_prod.dbo.SalesOrderStatus			as sos	ON s1.SalesOrderStatusID= sos.SalesOrderStatusID
			   Left JOIN (ses_prod.dbo.Product p 
							Inner join ses_prod.dbo.ProductAttribute as PA	ON P.Productid = PA.Productid 
																	and pa.ProductAttributeCode = 'Model' 
																	--AND pa.ProductAttributeValue IN ('32','36','39','61','80','90')
							) 
																		ON p.ProductID = sd.ProductID 
																		and pa.ProductAttributeCode = 'Model'
		Where sos.Salesorderstatusname in('Delivered','New','released','shipped','Staged')
			and cbil2.CustomerName = 'All Savers' --and s1.ActualDeliveryDate is not null 
		--and s1.salesorderid = 4963
		Group by cbil.Groupid,s1.salesorderid,s1.OrderDate, s1.ActualShipDate,s1.ScheduledDeliveryDate, s1.ActualDeliveryDate,cbil2.Customername, cbil.Customername,sos.SalesorderStatusName
			,pa.ProductAttributeValue,p.Partnumber
) a
Group by GroupId


use pdb_DermReporting;




/******/

/**************/



If Object_Id('Dermreporting_dev.dbo.ActivationStickerRegistrations_GroupRatesSimple') is not null 
Drop table Dermreporting_dev.dbo.ActivationStickerRegistrations_GroupRatesSimple

Select DatePart(Year,PeriodPolicyStartDate) as StartYear, DatePart(Month,PeriodPolicystartdate) as StartMonth, DaysFromeligibility, Registered = sum(registered), Eligible = Sum(Eligible), RegistrationRate = Convert(int,(sum(registered)*1.00/sum(Eligible)) *100)
into Dermreporting_dev.dbo.ActivationStickerRegistrations_GroupRatesSimple  
FRom
	(
	Select mgm.LookupRuleGroupid
	,ActivationSticker = Case when fog.ActualDeliveryDate > '20160601' then 1 else 0 end
	, PeriodPolicyStartDate
	,DaysFromEligibility = DateDiff(Day,IIF(PeriodPolicyStartDate > fog.ActualDeliveryDate, PeriodPolicyStartDate,  fog.ActualDeliveryDate), v.Date), Registered = sum(v.isRegistered), Count(*) as Eligible 
	FROM 
		(select OfferCode, PeriodPolicyStartDate, LookupruleGroupid
		, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles FROM Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  
		)  mgm 
			Inner join vwActivityForPreloadGroups v   
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




/**********/
use pdb_DermReporting;
Drop table #memberDetail
Select systemid, Yearmo, Policyid into #memberDetail 
from Devsql10.AllSavers_Prod.dbo.Dim_memberDetail
where policyid is not null 


Create clustered index policy on #memberDetail(PolicyId) 
Create index sysyear on #MemberDetail(Systemid, Yearmo) 


Select LookupRulegroupid, RuleGroupname, offercode, GroupStartdatetime, Groupenddatetime ,GroupStartYearmo = dbo.Yearmonth(GroupStartDatetime) 
 Into #RuleGroup 
 FROM Dermsl_prod.dbo.LOOKUPRuleGroup Where LookupClientid in (50,175) 




Drop table #total
Select StartYearmonth, DaysFROMEligibility , Eligible = Count(*) 
into #total 
FROM 
(
Select Distinct a.Systemid , StartYearmonth = a.Yearmo, full_Dt, Dense_Rank() Over(Partition by a.Systemid order by Full_dt) as DaysFromEligibility
 FROM #memberDetail a
 	Inner join  #RuleGroup b On Convert(Varchar(30),a.Policyid) = Replace(b.Offercode,'-', '00') and a.Yearmo = dbo.Yearmonth(GroupStartDatetime) 
	Inner join Dim_Date dd on dd.Full_Dt between  Convert(Date,convert(Varchar(10),a.Yearmo) + '01')   and Dateadd(day,90,Convert(Date,convert(Varchar(10),a.Yearmo) + '01'))
Where Right(a.Systemid,2) in (00,01) 
) a
	Inner join Devsql10.AllSavers_prod.dbo.Member_Coverage dm on a.Systemid = dm.Systemid and a.Full_Dt between dm.EffectiveDate and dm.TermDate
Group by StartYearmonth, DaysFROMEligibility 



Select a.*, b.Eligible as full_eligibles
Into #registrationswithAllEligiblesandOtherPlanopters 
FROM Dermreporting_dev.dbo.ActivationStickerRegistrations_GroupRatesSimple a  
	inner join #Total b 
		On a.StartYear * 100 + a.StartMonth = b.StartYearmonth
		and a.DaysFromeligibility = b.DaysFromEligibility
Order by StartYear, StartMonth, a.DaysFromeligibility


Select * FROM #registrationswithAllEligiblesandOtherPlanopters							Where DaysFromEligibility between 0 and 90  order by StartYear, StartMonth, DaysFromEligibility
Select * FROM Dermreporting_dev.dbo.ActivationStickerRegistrations_GroupRatesSimple		Where DaysFromEligibility between 0 and 90  order by StartYear, StartMonth, DaysFromEligibility



Drop table Dermreporting_dev.dbo.IndexedRegistrationRates_ActivationSticker
Select StartYear, StartMonth,DaysFromEligibility, RegistrationRate
,MonthIndex = 
Case when Startmonth = 1 then  1.24 
	 when Startmonth = 2 then  1.27
	 when Startmonth = 3 then  1.25
	 when Startmonth = 4 then  1.18
	 when Startmonth = 5 then  .78
	 when Startmonth = 6 then  1.03
	 when Startmonth = 7 then  1.00
	 when Startmonth = 8 then  .94	
	 when Startmonth = 9 then  .78
	 when Startmonth = 10 then  .70
	 when Startmonth = 11 then  .58
	 when Startmonth = 12 then  .58
else RegistrationRate end 
, RegistrationRate_Indexed  = 
Case when Startmonth = 1 then RegistrationRate / 1.24 
	 when Startmonth = 2 then RegistrationRate / 1.27
	 when Startmonth = 3 then RegistrationRate / 1.25
	 when Startmonth = 4 then RegistrationRate / 1.18
	 when Startmonth = 5 then RegistrationRate / .78
	 when Startmonth = 6 then RegistrationRate / 1.03
	 when Startmonth = 7 then RegistrationRate / 1.00
	 when Startmonth = 8 then RegistrationRate / .94	
	 when Startmonth = 9 then RegistrationRate / .78
	 when Startmonth = 10 then RegistrationRate / .70
	 when Startmonth = 11 then RegistrationRate / .58
	 when Startmonth = 12 then RegistrationRate / .58
else RegistrationRate end 
Into Dermreporting_dev.dbo.IndexedRegistrationRates_ActivationSticker
FROM #registrationswithAllEligiblesandOtherPlanopters 
order by StartYear, StartMonth, DaysFromEligibility


Drop table DermReporting_dev.dbo.Tableau_ActivationStickerovservation
SELECT  DaysFromEligibility
, StartMonth = Case when StartYear * 100 + StartMonth between 201510 and 201605  then 'Before Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth = 201606 then 'First Month Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth > 201606  then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End 
, sum( Registered  ) * 1.00    / sum(Eligible) as Registrationrate
Into DermReporting_dev.dbo.Tableau_ActivationStickerovservation
FROM #registrationswithAllEligiblesandOtherPlanopters
GROUP BY  DaysFromEligibility,Case when StartYear * 100 + StartMonth between 201510 and 201605  then 'Before Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth = 201606 then 'First Month Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth > 201606  then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End
ORDER BY  DaysFromEligibility,Case when StartYear * 100 + StartMonth between 201510 and 201605  then 'Before Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth = 201606 then 'First Month Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth > 201606  then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End


Drop table DermReporting_dev.dbo.Tableau_ActivationStickerovservation_FullEligibles
SELECT  DaysFromEligibility
, StartMonth = Case when StartYear * 100 + StartMonth between 201510 and 201605  then 'Before Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth = 201606 then 'First Month Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth > 201606  then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End 
, sum( Registered  ) * 1.00    / sum(Case when  StartYear * 100 + StartMonth < 201510 then full_eligibles else eligible end) as Registrationrate
Into DermReporting_dev.dbo.Tableau_ActivationStickerovservation_FullEligibles
FROM #registrationswithAllEligiblesandOtherPlanopters
WHERE  DaysFromEligibility between -10 and 90
GROUP BY  DaysFromEligibility,Case when StartYear * 100 + StartMonth between 201510 and 201605  then 'Before Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth = 201606 then 'First Month Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth > 201606  then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End
ORDER BY  DaysFromEligibility,Case when StartYear * 100 + StartMonth between 201510 and 201605  then 'Before Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth = 201606 then 'First Month Activation Sticker - Default Motion' 
					when StartYear * 100 + StartMonth > 201606  then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End



/***For all Members, what are changes in reg rates***/

Drop table pdb_dermReporting.dbo.AllMembers_EngagementRampup

Select Treatment = Case when ProgramStartdate between '20151001' and '20160530'  then 'Before Activation Sticker - Default Motion' 
					when ProgramStartdate between '20160601' and '20160630' then 'First Month Activation Sticker - Default Motion' 
					when ProgramStartdate > '20160630' then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End
,DaysFromEligibility					 
,RegistrationRate = suM(isRegistered) *1.00/Count(*) 
,Registered = SuM(isRegistered) 
,Eligible = Count(*) 
Into pdb_dermReporting.dbo.AllMembers_EngagementRampup
From vwActivityForPreloadGroups 
Where Clientname = 'All Savers Motion' and DaysFromEligibility between 0 and 90 
group by Case when ProgramStartdate between '20151001' and '20160530'  then 'Before Activation Sticker - Default Motion' 
					when ProgramStartdate between '20160601' and '20160630' then 'First Month Activation Sticker - Default Motion' 
					when ProgramStartdate > '20160630' then 'After Activation Sticker - Default Motion'
					else 'No Activation Sticker - Opt-in Motion' End
,DaysFromEligibility



Select * FROM pdb_dermReporting.dbo.AllMembers_EngagementRampup order by Treatment, DaysFromEligibility