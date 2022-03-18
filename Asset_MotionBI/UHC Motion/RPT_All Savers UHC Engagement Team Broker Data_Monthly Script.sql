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
	InitialMotionEffectiveDate = Min(EffectiveDate) over(Partition by Offercode), agentFirstname, AmsAgentId, AgentLastname, agency,agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, AgentZip, AccountExecutive
	,LookupRulegroupid
	,Clientname
	,Rulegroupname
	,Offercode
	,State		= sz.GroupState
	,Zipcode    = sz.GroupZip
	,Yearmonth
	,PeriodPolicyNumber
	,PeriodPolicyStartDate
	,PeriodPolicyEndDate
	,Registered
	,Eligibles
	,PercentActiveDays as ActiveDays
	,TotalDays
	,F
	,PossibleF
	,I
	,PossibleI
	,T
	,PossibleT
	,Total
	,QuoteSubscriberCnt = SubscriberCnt, QuoteEligibleCnt  = EligibleCnt
	,MotionPolicyMonth = Row_number()Over(Partition by a.Policyid order by YearMonth) 
	,ReverseMPM = Row_number()Over(Partition by a.Policyid order by YearMonth desc) 
Into pdb_Dermreporting.dbo.MotionandBroker   
FROM 
(
	Select * , RN2 = Row_Number()Over(Partition by Offercode, PeriodPolicyStartdate, yearmonth order by Effectivedate desc) ---Added this line to select the most recent broker.
		FROM	
		(  Select Distinct a.Policyid, EffectiveDate, a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity
				   ,AgentState,AgentEmail, a.AgentZip,a.AccountExecutive, SubscriberCnt, EligibleCnt 
				   ,Rn = Row_Number()over(partition by Policyid, EffectiveDate order by AmsAgentid desc) 
				   FROM  AllSaversQuotes as a 
				)	as a
	Right join Dermsl_Reporting.dbo.Motion_by_Group_by_Month		as c	ON Convert(varchar(14),a.PolicyId) = replace(c.OfferCode,'-','00') 
			and a.effectivedate between c.PeriodPolicyStartDate and c.PeriodPolicyEnddate
			and a.Rn = 1 
	Where exists(Select * FROM Dermsl_prod.dbo.LookupRuleGroup lrg  where LookupClientid = 50 and GroupStartdateTime <= getdate() and isnull(Groupenddatetime,'20161231') > getdate() and c.LookupRulegroupid = lrg.LOOKUPRuleGroupID) 
) a 
Left join #StateandZip sz
	On replace(a.OfferCode,'-','00') = sz.Policyid 
	and sz.Rn = 1 

Where rn2 = 1 
Create unique clustered index idxgroupmonth on pdb_Dermreporting.dbo.MotionandBroker(LookupRuleGroupid, YearMonth)

GO


/******************************************/


GO


--use pdb_DermReporting; 

Drop table #Shipdates ;


Select mb.offercode, fog.ScheduledDeliveryDate, fog.ActualDeliveryDate
Into #Shipdates  
From pdb_Dermreporting.dbo.MotionandBroker	as mb
Left join FirstorderforGroups		as fog	on mb.OfferCode = fog.groupid
											and fog.OID  = 1 
 Where mb.YearMonth = pdb_DermReporting.dbo.Yearmonth(Getdate()) - 1  --Status for this month
 --and Datediff(Month,InitialMotionEffectiveDate,Getdate()) <= 2  ---To filter for the last two months
 


 GO
 
Drop table #Report1a_Group_Level_Data	;


Select GroupName = mb.RuleGroupName,
mb.LookupruleGroupid as internalGroupid,
 PolicyNumber = mb.OfferCode, mb.YearMonth
	,NewBusinessEffectivedate = Convert(Date,InitialMotionEffectiveDate)
	,DateofWelcomeCall = NULL
	,mb.LookupRuleGroupid
	,DateOfEstimatedDelivery = sd.ScheduledDeliveryDate
	,FirstConfirmedDelivery = sd.ActualDeliverydate
	,FirstLoggedDay =Convert(Date,FirstLoggedDay) 
	, DateofHYCall = Null 
	,AgentofRecord = AgentFirstname + ' ' + AgentLastname, AgentState
	,AccountExecutive = AEG.Account_Executive
	,HealthPlan = AEG.HealthPlan_AE_Ag
	,mb.State as GroupState
	,mb.Eligibles
	,mb.Registered
	,RegistrationPercent = mb.Registered*1.00/mb.Eligibles
	,ActivelyLoggingUsers =  isnull(lrg.ActivelyLogging,0)
	,PercentofPointsEarned = x.PercentofPointsEarned
	,MotionPolicyMonth
	,F,I,T,PossibleF,PossibleI,PossibleT, TotalAwardswithCredits = Total
Into #Report1a_Group_Level_Data
From  pdb_Dermreporting.dbo.MotionandBroker    mb
	Left join 
		(Select LookupruleGroupid
			,ActivelyLogging =  Count(Distinct Case when LastLoggedDate > Dateadd(day,-14,getdate()) then fa.eligibleid else null end),FirstloggedDay = Min(FirstLoggedDay)   
		 FROM 
			(Select Distinct LookupRulegroupid, dd.YEAR_MO ,fa.EligibleID
				,FirstLoggedDay = Min(fa.Date)
				,LastLoggedDate = Max(Fa.Date) 
			 From Dermsl_reporting.dbo.Fact_PreloadActivity	as fa 
			 inner join pdb_DermReporting.dbo.Dim_Date			as dd on fa.Dt_Sys_ID = dd.DT_SYS_ID
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
						Left join AllSavers_Dim_Policy	as dp ON a.EmployerGroupID = dp.EmployerGroupid 
				)			
						as AEG		on aeg.Policyid = Replace(Mb.Offercode,'-','00')
									and aeg.Rn = 1 
	Left JOin 	(	
					Select * FROM 
						(
						Select LookupRuleGroupid, Yearmonth
							,PercentofPointsEarned = Sum(F+I+T)*1.00/ Sum(PossibleF + PossibleI + PossibleT)    
						FROM Dermsl_Reporting.dbo.Motion_by_Group_by_Month 
						Group by LookupRuleGroupid, Yearmonth
						) as a
				) 
						as x		on x.LOOKUPRuleGroupID = mb.LookupRuleGroupid and mb.YearMonth = x.YearMonth
--Where mb.Yearmonth  = 201607  --Status for this month
 --and Datediff(Month,InitialMotionEffectiveDate,Getdate()) <=2  --This will filter for just the last two months.

Create unique Clustered index idxgrpid on #Report1a_Group_Level_Data (policyNumber,Yearmonth)
Go


/***Check to make sure we have everyone*****/
Select * FROM Dermsl_prod.dbo.MemberSignupdata 
Where LookupRuleGroupid in 
(
Select LookupRuleGroupid 
FROM Dermsl_prod.dbo.LookupRuleGroup where LookupClientid = 50 and GroupStartdateTime <= getdate() and isnull(Groupenddatetime,'20161231') > getdate()
Except

Select LookupRuleGroupid From #Report1a_Group_Level_Data
Where Yearmonth >= 201608 
) 
and ActiveFlag = 1



--Select * FROM pdb_Dermreporting.dbo.MotionandBroker where lookupRulegroupid = 718
--Select * From #Report1a_Group_Level_Data where lookupRulegroupid = 718
--Select * FROM Dermsl_prod.dbo.LookupRuleGroup where lookupRulegroupid = 718			
--Select * FROM Devsql10.AllSavers_prod.dbo.Dim_Policy WHere policyid = '5400003207'
--Select * FROM Dim_SESAllsaversPolicyYear where LookupRuleGroupid = 2396
--Select * FROM Motion_by_Group_by_Month where LookupRuleGroupid = 2396
--Select * FROM Ses_Prod.dbo.Customer where groupid = '5400-3625'
--Select * FROM dermsl_prod.dbo.membersignupdata where lookuprulegroupid = 718


 ------------------output-------------------------------------------------------------------------------------------------------------------------------

 Select *  From #Report1a_Group_Level_Data 
 where Yearmonth >201512 
 order by policynumber, yearmonth

  Select * 
  --,sum(eligibles)  
  From #Report1a_Group_Level_Data b
  Where exists(Select * FROM Report1a_Group_Level_Data rgl where b.groupname = rgl.groupname) 
 and Yearmonth = '201609'
 --order by policynumber, yearmonth


 -------------------------------------------------------------------------------------------------------------------------------------------------

