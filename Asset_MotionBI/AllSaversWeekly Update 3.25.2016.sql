use provoqms_Prod;

/****
1. Overall growth						x	pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
2. Registration rate Bins				x   GroupLevelEngagement 
3. Geographic view of groups/people		x   (pdb_DermReporting.dbo.Motion_by_Group_By_Month/vw_factpreloadActivity)		x
4. Broker data							x	pdb_abw.dbo.BrokerPerformance 
5. Call Volume/Call Efficacy?				--Later add
6. Syncing by OS						x	vw_ProgramSync  --why are apps showing up as null?
7. Shipping report						x	Ses_Shipping report  --temp copy.
8. New Starter Kit performance			x	UptakeByTreatmentGroupDetail
9. Outreach Difference					    --Later add(Target 3/21)
****/ 

/***Overall Registration,eligible and loggin data*****/

Set transaction isolation level read uncommitted 
GO

use pdb_DermReporting; 
--1. Growth and Participation by Month and for established members(members who have been eligible for at least 90 days. --Can check this out by gender and Agebin if needed.
Drop table pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
SELECT ClientName, YearMonth = dbo.YearMOnth(Date)
--,MemberType = case when Datediff(Month, ProgramstartDate, Date) >= 3  then 'Established' Else 'New' end
,Eligibles = Count(Distinct  [EligibleID])																				--1. Growth and Participation by Month and for established members(members who have been eligible for at least 90 days.
,Registered = Count(Distinct Case when isRegistered = 1 then EligibleId else null End) 
,Logging = Count(Distinct Case when TotalSteps > 299 then EligibleId else null end)  
,F = Sum(Fpoints)* 1.00/NULLIF(Sum(PossibleFPoints),0)
,I = Sum(Ipoints)* 1.00/NULLIF(Sum(PossibleIPoints),0)
,T = Sum(Tpoints)* 1.00/NULLIF(Sum(PossibleTPoints),0)
,FIT = SUM(Fpoints + IPoints + TPoints) *1.00/NULLIF(Sum(PossibleFPoints + PossibleIPoints + PossibleTPoints),0 )
Into pdb_Dermreporting.dbo.AllsaversWeeklyUpdate
FROM [pdb_DermReporting].[dbo].[vwActivityForPreloadGroups] a 
	Inner join pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRUleGroupid 
		and a.Date between b.EffectiveStartDate and isnull(b.EffectiveEndDate,getdate())
Where Clientname in ('All Savers Motion','Key Accounts') 
and a.LookupRuleGroupID <> 937 and ProgramStartDate >= '20130401' --and cancelledDateTime > ProgramStartdate --and Date >= '20160301' and TotalSteps >= 300 

Group by Clientname,dbo.YearMOnth(Date)
--, case when Datediff(Month, ProgramstartDate, Date) >= 3  then 'Established' Else 'New' end
Order by YearMonth 


/****Look at comparison of results after updating the active flag filter in vwActivityForPreloadGroups***/

--Select * FROM pdb_Dermreporting.dbo.AllsaversWeeklyUpdate Where Clientname = 'All Savers Motion' order by YearMonth 


--Select * FROM #t1 order by YearMonth

--Select * FROM Dermsl_prod.dbo.Membersignupdata where Programstartdate between '20140401' and  '20140501' and LookupClientid = 50 


--If Object_Id('tempdb..#t1') is not null 
--DROP TABLE #t1
--Select YearMonth
--	, TotalMotionEligibles	=	SUM(Eligibles)
--  Into #t1
--FROM [pdb_DermReporting].[dbo].[Motion_by_Group_by_Month]
--Where clientname = 'All Savers Motion'
--	and YearMonth between 201404 and 201603
--Group By YearMonth
--Order By YearMonth



/*****For Jason to inspect********************************************/



/*****Membersignupdata flags don't match***************/

--Select * FROM Dermsl_prod.dbo.membersignupdata Where LookupClientid = 50  and CancelledDateTime is not null and CancelledDateTime < Getdate() and ActiveFlag = 1 

--Select * FROM Dermsl_prod.dbo.membersignupdata Where LookupClientid = 50  and CancelledDateTime is  null and   ActiveFlag = 0

--Select * FROM Dermsl_prod.dbo.Membersignupdata a inner join Dermsl_prod.dbo.Member b on a.CustomerID = b.CustomerID and a.LOOKUPClientID = 50 and b.Lookupclientid = 50 


/***********************************************/


--If Object_Id('tempdb.dbo.#CallsandResults') is not null 
--Drop table #CallsandResults
 
--Select b.ProjectName,a.IndividualSysId, a.Memberid, a.BirthDate, a.GenderCode, c.LastCallDateTime,a.RowCreatedDateTime, d.StatusCode, pd.DispositionDescription , a.GroupName
		
--		, CallResult	=	MIN(CAse When StatusCode in( 'Member reached – successful') Then 1 when StatusCode = 'VoiceMail' then 2 else 3 End) Over(Partition By c.Memberid)
--into #CallsandResults
--From (ProvoQMS_Prod.dbo.Member	a Join ProvoQMS_Prod.dbo.PROJECT	b	On	a.PROJECTID	=	b.PROJECTID)
--	Inner Join ProvoQMS_Prod.dbo.MEMBERCallLog	c	On	a.memberid	=	c.memberid
--									and LOOKUPCallStatusID <> 29
--									and c.LastCallDateTime > a.RowCreatedDateTime
--	Left Join ProvoQMS_Prod.dbo.LOOKUPCallStatus	d	on	c.LOOKUPCallStatusID	=	d.LOOKUPCallStatusID and d.StatusCode not like '%member edit%'
--	Left join provoqms_prod.dbo.ProjectDisposition pd 
--		ON pd.projectdispositionid = c.Projectdispositionid
--Where a.PROJECTID in (128,129,130,131)		-- All Projects
--	and DATEDIFF(Day, a.RowCreatedDateTime, getdate()) <= 500
--	and a.IndividualSysID <> '' 
--	and d.StatusCode not like '%member edit%'
--	--and c.LastCallDateTime >= '20150505'
----Create Index ix_IndvSysID on #sub1 (IndividualSysID)
----Create Index ix_ProjID on #sub1 (PROJECTID)
--Go 

--Declare @EndDate Date = '20151201'


/**********/

Select * FROM Dermsl_prod.dbo.LookupRuleGroup  where Lookupclientid = 50 and rowCreatedDatetime < '20150901'


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
		Select de.LookupRUleGroupID,PeriodPolicyStartDate = Convert(Date,PeriodPolicyStartDate),RegisteredPercent = (Sum(isRegistered)*1.00				   /NULLIF(Count( v.EligibleID ),0))*100,
		GroupSize = NULLIF(Count( v.EligibleID ),0)
		,UnregisteredMembers = Count(Case when isregistered = 0 then v.EligibleID  else null end )
		FROM ([pdb_DermReporting].[dbo].[vwActivityForPreloadGroups] v 
			inner join Dim_Eligibles de on v.Eligibleid = de.Eligibleid 
			inner join Dim_SESAllsaversPolicyYear ds on v.LookupRuleGroupid = ds.LOOKUPRuleGroupID 
													 and ds.PeriodPolicyNumber = 1
													-- and ds.PeriodPolicyStartDate >= '20160101'
													)
													-- and ds.EffectiveStartDate = v.ProgramStartDate)
		Where v.Date = Convert(Date,Getdate()) and v.ClientName = 'All Savers Motion' and v.ProgramStartDate between '20140401' and Dateadd(Day,-60,Getdate())
		Group by de.LookupRUleGroupID, Convert(Date,PeriodPolicyStartDate)
) a


/******New Starter Kit effect --from program start date************/
Drop table #NewStarterKit 
Select Distinct Clientmemberid into #NewStarterKit FROM Dermsl_Prod.dbo.Membersignupdata  where RowCreatedDatetime >= '20151214' and LOOKUPClientID = 50 


Drop table UptakeByTreatmentGroupDetailSplit40Perc
Select 
DaysFromEligibility ,--= DateDiff(Day,Case when v.ProgramStartdate > msd.RowCreatedDateTime then v.ProgramStartDate else Convert(Date, msd.RowCreatedDatetime) end, date),
EnthusiasticGroup = Case when gle.RegisteredPercent >= 40 then 1 else 0 end 
,Treatment = Case when dbo.Yearmonth(v.ProgramStartdate) = '201601' then 'Jan 2016 - New Starter Kit' when dbo.Yearmonth(v.ProgramStartdate) = '201501' then 'Jan 2015 - Old Starter kit' when dbo.Yearmonth(v.Programstartdate) = '201511' then 'Nov 2015 - Old Starter Kit' end --Treatment_Kit  = Case when nsk.Clientmemberid is null then 'Old StarterKit' else 'New StarterKit ' End 

,RegisteredPercent = Sum(isRegistered)*1.00				   /NULLIF(Count( v.EligibleID ),0)
,LoggingPercent = SUM(Case when isregistered = 1 and TotalSteps > =300 then isregistered else 0 end)*1.00 /NULLIF(Count( v.EligibleID ),0)
,CountofMembers = Count(*)
Into UptakeByTreatmentGroupDetailSplit40Perc
FROM ([pdb_DermReporting].[dbo].[vwActivityForPreloadGroups] v inner join Dim_Eligibles de on v.Eligibleid = de.Eligibleid Left join Dim_SESAllsaversPolicyYear ds on v.LookupRuleGroupid = ds.LOOKUPRuleGroupID and ds.PeriodPolicyNumber = 1 and ds.EffectiveStartDate = v.ProgramStartDate)
Left join #NewStarterKit nsk on de.Clientmemberid = nsk.Clientmemberid 
left JOin Dermsl_prod.dbo.Membersignupdata msd on de.Clientmemberid = msd.Clientmemberid and v.LookupRuleGroupid = msd.LookupRuleGroupid
left join GroupLevelEngagement gle on gle.LookupRuleGroupid = v.LookupRuleGroupid 
Where DaysFromEligibility between 0 and 90 and dbo.Yearmonth(v.ProgramStartDate) In( '201511','201601','201501')   and v.Clientname = 'All Savers Motion'
Group by  DaysFromEligibility,Case when gle.RegisteredPercent >= 40 then 1 else 0 end
,Case when dbo.Yearmonth(v.ProgramStartdate) = '201601' then 'Jan 2016 - New Starter Kit' when dbo.Yearmonth(v.ProgramStartdate) = '201501' then 'Jan 2015 - Old Starter kit' when dbo.Yearmonth(v.Programstartdate) = '201511' then 'Nov 2015 - Old Starter Kit' end 



Drop table UptakeByTreatmentGroupDetail
Select 
DaysFromEligibility ,--= DateDiff(Day,Case when v.ProgramStartdate > msd.RowCreatedDateTime then v.ProgramStartDate else Convert(Date, msd.RowCreatedDatetime) end, date),
--EnthusiasticGroup = Case when gle.RegisteredPercent >= 40 then 1 else 0 end 
Treatment = Case when dbo.Yearmonth(v.ProgramStartdate) = '201601' then 'Jan 2016 - New Starter Kit' when dbo.Yearmonth(v.ProgramStartdate) = '201501' then 'Jan 2015 - Old Starter kit' when dbo.Yearmonth(v.Programstartdate) = '201511' then 'Nov 2015 - Old Starter Kit' end --Treatment_Kit  = Case when nsk.Clientmemberid is null then 'Old StarterKit' else 'New StarterKit ' End 

,RegisteredPercent = Sum(isRegistered)*1.00				   /NULLIF(Count( v.EligibleID ),0)
,LoggingPercent = SUM(Case when isregistered = 1 and TotalSteps > =300 then isregistered else 0 end)*1.00 /NULLIF(Count( v.EligibleID ),0)
,CountofMembers = Count(*)
Into UptakeByTreatmentGroupDetail
FROM ([pdb_DermReporting].[dbo].[vwActivityForPreloadGroups] v inner join Dim_Eligibles de on v.Eligibleid = de.Eligibleid Left join Dim_SESAllsaversPolicyYear ds on v.LookupRuleGroupid = ds.LOOKUPRuleGroupID and ds.PeriodPolicyNumber = 1 and ds.EffectiveStartDate = v.ProgramStartDate)
Left join #NewStarterKit nsk on de.Clientmemberid = nsk.Clientmemberid 
left JOin Dermsl_prod.dbo.Membersignupdata msd on de.Clientmemberid = msd.Clientmemberid and v.LookupRuleGroupid = msd.LookupRuleGroupid
Where DaysFromEligibility between 0 and 90 and dbo.Yearmonth(v.ProgramStartDate) In( '201511','201601','201501')   and v.Clientname = 'All Savers Motion'
Group by  DaysFromEligibility--,Case when gle.RegisteredPercent >= 40 then 1 else 0 end
,Case when dbo.Yearmonth(v.ProgramStartdate) = '201601' then 'Jan 2016 - New Starter Kit' when dbo.Yearmonth(v.ProgramStartdate) = '201501' then 'Jan 2015 - Old Starter kit' when dbo.Yearmonth(v.Programstartdate) = '201511' then 'Nov 2015 - Old Starter Kit' end 

Select *
FROM UptakeByTreatmentGroupDetail 
Where DaysFromEligibility = 90


/**********Aggregate broker data for reporting*****************************/
/************************************************************************************************************************/
If Object_Id('tempdb.dbo.#CurrentGroupPerformance') is not null 
Drop table #CurrentGroupPerformance
Select  PeriodPolicyStartdate, b.RuleGroupOfferCode, de.LookupRuleGroupid, Eligible = Count(*), Registered = sum(Convert(Int,AccountVerifiedFlag))
into #CurrentGroupPerformance
FROM   Dim_Eligibles de Left join Dim_member a on a.Account_ID = de.Account_ID
	Left join Dim_LookupRuleGroup b
		ON de.LookupRuleGroupid = b.LookupRuleGroupID
	Left join Dim_SesAllSaversPolicyYear ds 
		ON de.LookupRuleGroupid = ds.LOOKUPRuleGroupID 
Where   de.ActiveFlag = 1 and (de.CancelledDatetime is null or de.CancelledDateTime > getdate())
Group by PeriodPolicyStartdate, b.RuleGroupOfferCode, de.LookupRuleGroupid

use pdb_DermReporting;
/*******************************************************/
If Object_Id('pdb_abw.dbo.MotionandBroker') is not null 
Drop table pdb_abw.dbo.MotionandBroker
SELECT Distinct  EffectiveDate, a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, a.AgentZip ,   c.* 
Into pdb_abw.dbo.MotionandBroker  
FROM Devsql10.[AllSavers_Prod].[dbo].[Fact_Quote] a
	Inner join Motion_by_Group_by_Month c
		ON Convert(varchar(14),a.PolicyId) = replace(c.OfferCode,'-','00') 
		and a.effectivedate = c.PeriodPolicyStartDate


/******************************************/
If Object_Id('pdb_abw.dbo.BrokerPerformance ') is not null 
Drop table pdb_abw.dbo.BrokerPerformance 
Select *
INTO pdb_abw.dbo.BrokerPerformance 
FROM 
	(
		Select 
		*
		,Registrationrate =  (TotalRegistered*1.00/TotalEligible) * 100
		,BrokerPoolSizeRank = Case when NTILE(3)over(Order by TotalEligible Desc) = 1 then 'Large' when NTILE(3)over(Order by TotalEligible Desc) = 2 then 'Medium' else 'Small' end
		,BrokerPoolRegistrationRank =  Case when NTILE(3)over(Order by TotalRegistered*1.00/TotalEligible ) = 1 then 'Low' when NTILE(3)over(Order by TotalRegistered*1.00/TotalEligible Desc) = 2 then 'Medium' else 'High' end
		--,BrokerPoolGroupCountRank = Case when NTILE(3)over(Order by TotalGroups Desc) = 1 then 'Lots' when NTILE(3)over(Order by TotalGroups Desc) = 2 then 'Some' else 'Few' end
	
		FROM 
		(
			Select AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip, 
			TotalEligible = sum(Eligibles), TotalRegistered = sum(registered), TotalGroups = Count(Distinct RuleGroupName) --Agency,AgentFirstname, amsAgentId, Agentlastname, agentZip   
			FROM  pdb_abw.dbo.MotionandBroker1  Where YearMonth = '201603'
			group by AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip
	) a
) a

Select * FROM pdb_abw.dbo.BrokerPerformance  Where AgentLastname like '%souza%'
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
Where sos.Salesorderstatusname in('Delivered','New','released','shipped','Staged')
--and s1.salesorderid = 4963
Group by s1.salesorderid,s1.OrderDate, s1.ActualShipDate,cbil2.Customername, cbil.Customername,sos.SalesorderStatusName,pa.ProductAttributeValue,p.Partnumber
order by s1.OrderDate desc




