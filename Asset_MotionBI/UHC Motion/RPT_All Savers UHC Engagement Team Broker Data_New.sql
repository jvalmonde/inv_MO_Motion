/********************
Hi Garrett,--

I received some feedback regarding the reports from the meeting this afternoon:

Updates:
-	On the GroupData report can you add a column to provide the group’s participation percent?  Calculating the percentage of points the group has earned vs. the total number of points that were eligible to be earned.
-	Include the data on all active Motion groups and members not just the groups that were activated within the current month and the last 2 months.
-	On both reports can you add filtering and freeze panes at cell C2?

Frequency:  The group requested an updated version of the report on a weekly basis run in the Sunday/Monday timeframe.

Distribution:  I setup a folder for the reports on an All Savers Operations SharePoint that the HealthPlans have access to.  Is there an existing folder location that we can use to pass the file each week?  I believe there is one that Erik Edvalson works with currently to provide some motion reporting on renewing groups on a monthly basis.


Items left for completion:

--Still need to add the percentage of points earned. --use motion by month and aggregate the percentage of points earned in the last two months.
--Fill in Account Exec and Health plan with reliable data.  ---may need to talk with Rex about where to find that.
****************************/
/***************************
  use pdb_Dermreporting;
  USE DEVSQL14
***************************/

If Object_Id('tempdb.dbo.#StateandZip') is not null 
Drop table #StateandZip

Select Policyid, GroupState, GroupZip , YearMo, RN = Row_Number()over(Partition by PolicyId order by Yearmo desc) 
into #StateandZip
 FROM AllSavers_Dim_Policy

/*****************************************************************************************************************************
REPORT 1a
******************************************************************************************************************************/
If Object_Id('pdb_Dermreporting.dbo.MotionandBroker') is not null 
Drop table pdb_Dermreporting.dbo.MotionandBroker
SELECT Distinct  
	InitialMotionEffectiveDate = Min(EffectiveDate) over(Partition by c.Offercode), a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, a.AgentZip, a.AccountExecutive
	,c.LookupRulegroupid
	,c.Clientname
	,c.Rulegroupname
	,c.Offercode
	,sz.GroupState
	,sz.GroupZip
	,c.Yearmonth
	,c.PeriodPolicyNumber
	,c.PeriodPolicyStartDate
	,c.PeriodPolicyEndDate
	,c.Registered
	,c.Eligibles
	,c.PercentActiveDays as ActiveDays
	,c.TotalDays
	,c.F
	,c.PossibleF
	,c.I
	,c.PossibleI
	,c.T
	,c.PossibleT
	,c.Total
	,QuoteSubscriberCnt = SubscriberCnt, QuoteEligibleCnt  = EligibleCnt
	,MotionPolicyMonth = Row_number()Over(Partition by a.Policyid order by YearMonth) 
	,ReverseMPM = Row_number()Over(Partition by a.Policyid order by YearMonth desc) 
Into pdb_Dermreporting.dbo.MotionandBroker   
FROM DERMSL_Reporting.dbo.Motion_by_Group_by_Month		as c 
Left  join  pdb_DermReporting.dbo.AllSaversQuotes		as a	ON Convert(varchar(14),a.PolicyId) = replace(c.OfferCode,'-','00') 
		--and dbo.YearMonth(a.effectivedate) = dbo.Yearmonth(c.PeriodPolicyStartDate)
		and a.Rn = 1 
Left join #StateandZip sz
	On replace(c.OfferCode,'-','00') = sz.Policyid 
	and sz.Rn = 1 


--Where LookupRuleGroupid  not in( 3271)
--and LookupRuleGroupid in (707)
Create unique clustered index idxgroupmonth on pdb_DermReporting.dbo.MotionandBroker(LookupRuleGroupid, YearMonth)
--Select sum(eligibles) From dermsl_reporting.dbo.motion_by_group_by_month    where yearmonth = '201610'

--Select * From pdb_Dermreporting.dbo.MotionandBroker
 
GO



/******************************************/
If Object_Id('pdb_DermReporting.dbo.BrokerPerformance ') is not null 
Drop table pdb_DermReporting.dbo.BrokerPerformance
 
Select *
INTO pdb_DermReporting.dbo.BrokerPerformance 
FROM 
	(
		Select 
		*
		,Registrationrate =  TotalRegistered*1.00/TotalEligible
		,BrokerPoolSizeRank = Case when NTILE(3)over(Order by TotalEligible Desc) = 1 then 'Large' when NTILE(3)over(Order by TotalEligible Desc) = 2 then 'Medium' else 'Small' end
		,BrokerPoolRegistrationRank =  Case when NTILE(3)over(Order by TotalRegistered*1.00/TotalEligible ) = 1 then 'Low' when NTILE(3)over(Order by TotalRegistered*1.00/TotalEligible Desc) = 2 then 'Medium' else 'High' end
		--,BrokerPoolGroupCountRank = Case when NTILE(3)over(Order by TotalGroups Desc) = 1 then 'Lots' when NTILE(3)over(Order by TotalGroups Desc) = 2 then 'Some' else 'Few' end
	
		FROM 
		(
			Select AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip
				,TotalEligible = sum(Eligibles)
				,TotalRegistered = sum(registered)
				,TotalGroups = Count(Distinct RuleGroupName) 
				,FirstAllSaversMotionPolicySold = min(convert(date,InitialMotionEffectiveDate))--Agency,AgentFirstname, amsAgentId, Agentlastname, agentZip   
			FROM  pdb_DermReporting.dbo.MotionandBroker
			Where Yearmonth = pdb_Dermreporting.dbo.yearmonth(getdate()) and MotionPolicyMonth >= 0 
			group by AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip
	) a
) a


GO
/****Need to look up the Estimated and confirmed deliverydate for each group --just the initial shipment ****/



--use pdb_DermReporting; 
If Object_Id('tempdb.dbo.#Shipdates') is not null 
Drop table #Shipdates


--Drop table #Shipdates ;


Select mb.offercode, fog.ScheduledDeliveryDate, fog.ActualDeliveryDate
Into #Shipdates  
From pdb_DermReporting.dbo.MotionandBroker	as mb
Left join pdb_DermReporting..FirstorderforGroups		as fog	on mb.OfferCode = fog.groupid
											and fog.OID  = 1 
 Where mb.YearMonth = pdb_DermReporting.dbo.Yearmonth(Getdate())  --Status for this month
 --and Datediff(Month,InitialMotionEffectiveDate,Getdate()) <= 2  ---To filter for the last two months
 


 GO
 
If Object_Id('pdb_DermReporting.dbo.Report1a_Group_Level_Data ') is not null 
Drop table pdb_DermReporting.dbo.Report1a_Group_Level_Data
--Drop table Report1a_Group_Level_Data	;


Select GroupName = REPLACE(mb.RuleGroupName,',',''), PolicyNumber = mb.OfferCode
	,NewBusinessEffectivedate = Convert(Date,InitialMotionEffectiveDate)
	,DateofWelcomeCall = NULL
	,DateOfEstimatedDelivery = sd.ScheduledDeliveryDate
	,FirstConfirmedDelivery = sd.ActualDeliverydate
	,FirstLoggedDay =Convert(Date,FirstLoggedDay) 
	, DateofHYCall = Null 
	,AgentofRecord = CONVERT(VARCHAR(50),AgentFirstname + ' ' + AgentLastname)
	,AgentState =  CONVERT(VARCHAR(4),AgentState)
	,AccountExecutive = AEG.Account_Executive
	,HealthPlan = REPLACE(AEG.HealthPlan_AE_Ag,',','')
	,GroupState = CONVERT(VARCHAR(4),mb.GroupState)
	,mb.Eligibles
	,mb.Registered
	,RegistrationPercent = mb.Registered*1.00/mb.Eligibles
	,ActivelyLoggingUsers =  isnull(lrg.ActivelyLogging,0)
	,PrevTwoMonths_PercentofPointsEarned = x.PercentofPointsEarned
Into Report1a_Group_Level_Data
From  pdb_DermReporting.dbo.MotionandBroker    mb
	Left join 
		(Select LookupruleGroupid
			,ActivelyLogging =  Count(Distinct Case when LastLoggedDate > Dateadd(day,-14,getdate()) then fa.eligibleid else null end),FirstloggedDay = Min(FirstLoggedDay)   
		 FROM 
			(Select Distinct LookupRulegroupid, dd.YEAR_MO ,fa.EligibleID
				,FirstLoggedDay = Min(fa.Date)
				,LastLoggedDate = Max(Fa.Date) 
			 From Dermsl_Reporting.dbo.Fact_PreloadActivity	as fa 
			 inner join Dermsl_Reporting.dbo.Dim_Date			as dd on fa.Dt_Sys_ID = dd.DT_SYS_ID
			 Where fa.TotalSteps >= 300 
				and Clientname = 'All Savers Motion'
			 Group by LookupRulegroupid, dd.YEAR_MO ,fa.EligibleID 
			 ) 
				as fa 
		Group by LookupruleGroupid
		) 
							as lrg	on lrg.LookupRuleGroupID = mb.lookuprulegroupid 
	Left JOIn #shipdates	as sd	on sd.OfferCode = mb.OfferCode
	Left join (
				  Select  a.[EmployerGroupID], dp.Policyid
			      ,a.Group_Name
				  ,a.Quote_Type
				  ,a.Account_Executive
				  ,a.HealthPlan_AE_AG
				  ,Rn = Row_Number()over(Partition by dp.Policyid order by EffectiveDate desc) 
				   FROM [pdb_DermReporting].[dbo].[AllSavers_EmployerGroup] as a 
						Left join pdb_DermReporting.dbo.AllSavers_Dim_policy	as dp ON a.EmployerGroupID = dp.EmployerGroupid 
				)			
						as AEG		on aeg.Policyid = Replace(Mb.Offercode,'-','00')
									and aeg.Rn = 1 
	Left JOin 	(	
					Select * FROM 
						(
						Select LookupRuleGroupid
							,PercentofPointsEarned = Sum(F+I+T)*1.00/ Sum(PossibleF + PossibleI + PossibleT)    
						FROM Dermsl_Reporting.dbo.Motion_by_Group_by_Month 
						Where YearMonth >= pdb_DermReporting.dbo.Yearmonth(Dateadd(month,-2,getdate()))  Group by LookupRuleGroupid
						) as a
				) 
						as x		on x.LOOKUPRuleGroupID = mb.LookupRuleGroupid
Where ReverseMPM = 1 and YearMonth = dbo.Yearmonth(getdate()) --Status for this month
and not exists(Select * FROM Dermsl_prod.dbo.LookupRuleGroup lrg where isnull(GroupEndDatetime ,'20990101') <= getdate() and mb.lookupRuleGroupid = lrg.LookupRuleGroupid)
 --and Datediff(Month,InitialMotionEffectiveDate,Getdate()) <=2  --This will filter for just the last two months.

Create unique Clustered index idxgrpid on Report1a_Group_Level_Data (policyNumber)

--Select * FROM #Finaltable
--Select * FROM   pdb_DermReporting.dbo.MotionandBroker    mb
-- Select * from Report1a_Group_Level_Data


 -------------------------------------------------------------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------------------------------------------------------------

 /*****************************************************************************************************************************
REPORT 1b
******************************************************************************************************************************/

 If object_ID('tempdb.dbo.#1') is not null
 Drop table #1
 Select * Into #1
 FROM Dermsl_reporting.dbo.vwActivityForPreloadGroups c
 Where c.Date = '20160930'--Convert(Date, Getdate() )

 Create clustered index idx on #1(LookupRuleGroupid)

 /***This is the member level data*****/
 If Object_Id('pdb_DermReporting.dbo.Report1b_Member_Data ') is not null 
Drop table pdb_DermReporting.dbo.Report1b_Member_Data
 
 --Drop table Report1b_Member_Data	;


 Select Distinct Policynumber = isnull(a.PolicyNumber,b.RuleGroupoffercode)
	,c.ProgramStartDate
	,b.RuleGroupName
	,c.Membername
	,Clientmemberid as Systemid
	,Relationship = Case when Right(clientmemberid, 2) = '00' then 'employee' else 'Dependent/Spouse' End
	,IsRegistered = IIF(isregistered = 1, 'Yes', 'No') 
	,DateofEnrollment = Convert(date,c.AccountVerifiedDateTime) 
Into Report1b_Member_Data
 --Select Count(*)
FROM #1	as c  
	Inner join Dermsl_reporting.dbo.dim_lookupRulegroup	as b	ON  c.LookupRuleGroupid = b.LookupRuleGroupID 
	--Left join #finalTable									as a	ON b.RuleGroupOfferCode = a.PolicyNumber
	Left join pdb_DermReporting.dbo.Report1a_Group_Level_Data					as a	ON b.RuleGroupOfferCode = a.PolicyNumber
Where c.Clientname = 'All Savers Motion' and RuleGroupname not in ( 'AS Test Group 2 AS Test Group 2 AS Test Group 2','AS Test Group 1', 'AS Test Group 2') 
and exists(Select * FROM Report1a_Group_Level_Data rgl where b.RuleGroupname = rgl.Groupname) 



 /*****************************************************************************************************************************
REPORT 1a- PIVOTED
******************************************************************************************************************************/

If Object_Id('pdb_DermReporting.dbo.Report2_Engagement_ByState_Percentage ') is not null 
Drop table pdb_DermReporting.dbo.Report2_Engagement_ByState_Percentage


Select GroupState
	,TotalRegistered	= sum(Registered)
	,TotalEligibles		= sum(Eligibles)
	,TotalActivelyLoggingUsers = sum(ActivelyLoggingUsers)
	,Registration_Rate	= (sum(Registered) * 1.0 / sum(Eligibles) )
	,Active_Percent		= (sum(ActivelyLoggingUsers) * 1.0 / Nullif((sum(Registered)),0) )
Into Report2_Engagement_ByState_Percentage
From	Report1a_Group_Level_Data
Group by GroupState

Select * FROM Report2_Engagement_ByState_Percentage
select * from Report1b_Member_Data
Select * From Report1a_Group_Level_Data


--Select Count(*) FROM Dermsl_Prod.dbo.Membersignupdata where lookupclientid = 50 and activeflag = 1 