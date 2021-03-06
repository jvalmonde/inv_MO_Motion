

If Object_Id('pdb_abw.dbo.MotionandBroker') is not null 
Drop table pdb_abw.dbo.MotionandBroker
SELECT Distinct  InitialMotionEffectiveDate = Min(EffectiveDate) over(Partition by c.Offercode), a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, a.AgentZip, a.AccountExecutive
,c.LookupRulegroupid
,c.Clientname
,c.Rulegroupname
,c.Offercode
,c.State
,c.Zipcode
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
Into pdb_abw.dbo.MotionandBroker   
FROM (Select Distinct a.Policyid, EffectiveDate, a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, a.AgentZip,a.AccountExecutive, SubscriberCnt, EligibleCnt  FROM  Devsql10.[AllSavers_Prod].[dbo].[Fact_Quote] a)  a
	Inner join Motion_by_Group_by_Month c
		ON Convert(varchar(14),a.PolicyId) = replace(c.OfferCode,'-','00') 
		and a.effectivedate = c.PeriodPolicyStartDate
Where LookupRuleGroupid  not in( 3271)
Create unique clustered index idxgroupmonth on pdb_abw.dbo.MotionandBroker(LookupRuleGroupid, YearMonth)

GO

/******************************************/
If Object_Id('pdb_abw.dbo.BrokerPerformance ') is not null 
Drop table pdb_abw.dbo.BrokerPerformance 
Select *
INTO pdb_abw.dbo.BrokerPerformance 
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
			Select AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip,
			TotalEligible = sum(Eligibles), TotalRegistered = sum(registered), TotalGroups = Count(Distinct RuleGroupName) ,FirstAllSaversMotionPolicySold = min(convert(date,InitialMotionEffectiveDate))--Agency,AgentFirstname, amsAgentId, Agentlastname, agentZip   
			FROM  pdb_abw.dbo.MotionandBroker
			Where Yearmonth = '201603'and MotionPolicyMonth >= 0 
			group by AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip
	) a
) a


GO


Select * FROM pdb_abw.dbo.BrokerPerformance
Select Distinct * FROM pdb_abw.dbo.MotionandBroker


Go 

/*****Get the individual Data for the members********/

use dermsl_Prod;

Select distinct lrg.lookupRulegroupid, lrg.RuleGroupName, SICCode = ds.[2 DIGIT DESCRIPTION], lrg.Eligibles,lrg.Registered,RegistrationRate = Registered *1.00/Eligibles
, RegistrationRateCategory = case when Registered *1.00/Eligibles >= .40 then 'High'
								  when Registered *1.00/Eligibles >= .24 then 'Med'
								  when Registered *1.00/Eligibles >= 0 then 'Low' else null end 
,Firstname, Lastname, Addressline, City, StateCode, msd.Zipcode,msd.Birthdate, msd.Gendercode, EffectiveDate = ProgramStartdate,Isregistered = msd.AccountVerifiedFlag ,  daysfromEffectiveDate = Datediff(Day,ProgramStartdate,getdate()) 
into #MotionIndvData
FROM membersignupdata msd
	inner join (pdb_DermReporting.dbo.Motion_by_Group_By_month	lrg 
	left join (Select Distinct LookupRulegroupid,groupsiccode =  Max(GroupSICCode) 
				FROM pdb_Dermreporting.dbo.Dim_AllSaversGroupDetail group by LookupRulegroupid ) 
				 dgd on lrg.LookupRuleGroupid = dgd.LookupRuleGroupid 
				 left join pdb_Dermreporting.dbo.Dim_Sic ds on Left(dgd.GroupSICCode,2) = ds.[2 DIGIT CODE])
		ON msd.LOOKUPRuleGroupID = lrg.LookupRulegroupid and YearMonth  = '201603'
Where msd.lookupclientid = 50  and activeflag = 1 and (cancelleddatetime is null or cancelleddatetime >= getdate())
and isnull(CancelledDateTime,'20990101') > ProgramStartDate



/**Aquire the group admin data for use by Paul, include the motion, demo, and, if possible, the claims data*********/

use pdb_Dermreporting;



Select * 
Into #GATemp
FROM 
(
  Select *, rn = Row_Number()Over(Partition by Policyid order by Effectivedate Desc) FROM Devsql10.AllSavers_prod.dbo.Fact_Quote a
	Inner join Dim_LookupRuleGroup b
		ON Convert(varchar(30),a.PolicyID) = replace(b.RuleGroupOffercode ,'-','00')
		and b.Lookupclientid = 50 and RuleGroupOffercode <> '' 
) a
Where Rn = 1 and TerminationDate is null  order by policyid

Create unique Clustered index idx on #Gatemp(Policyid) 


Select * FROM #GATemp
Go 

Drop table #AdminData
Select a.LookupRuleGroupid, a.Policyid, a.Groupname, a.AdministrativeContact, a.GroupEmail,a.BusinessPhone, b.systemid, AdminContactGender = b.Gender, AdminContactBirthdate = b.Birthdate, AdminInsured = isnull(b.insuredFlag,0)
,MotionEligible = isnull(c.ActiveFlag,0), AccountVerifiedFlag = isnull(c.AccountVerifiedFlag,0)
,EligibleDays, RegisteredDays, AvgStepsPerRegisteredDay
Into #AdminData
From #GaTemp a 
	Left join Devsql10.AllSavers_prod.dbo.Dim_Member b
		ON a.AdministrativeContact = b.Firstname + ' '+ b.Lastname  
		and a.Policyid = b.Policyid
	Left JOIN Dim_Eligibles c
		ON Convert(varchar(30),b.Systemid )= c.clientmemberid
	Left join (Select Eligibleid,EligibleDays = Count(*), RegisteredDays = sum(isRegistered),AvgStepsPerRegisteredDay = Avg(Case when isregistered = 1 then TotalSteps Else null end) 
	From  vwActivityForPreloadGroups   Group by Eligibleid ) d
		On c.EligibleID = d.EligibleID

Select * FROM #AdminData Where Admin_Insured_  ---Attach this motion and broker data to the group and indv data.



Select mb.*, ad.AdminInsured, ad.MotionEligible as AD_MotionEligible, ad.AccountVerifiedFlag as AD_Motionregistered, ad.EligibleDays as AD_MotionEligibleDays, ad.RegisteredDays as Ad_MotionRegisteredDays, ad.AvgStepsPerRegisteredDay as AD_AvgStepsPerMotionEnrolledDay
FROM pdb_abw.dbo.MotionandBroker mb 
	Left join #AdminData ad
		ON mb.LookupRuleGroupid = ad.LookupRuleGroupID


Select mb.*,ad.AdministrativeContact, ad.GroupEmail as AdminEmail, ad.BusinessPhone as AdminPhone, ad.AdminInsured, ad.MotionEligible as AD_MotionEligible, ad.AccountVerifiedFlag as AD_Motionregistered, ad.EligibleDays as AD_MotionEligibleDays, ad.RegisteredDays as Ad_MotionRegisteredDays, ad.AvgStepsPerRegisteredDay as AD_AvgStepsPerMotionEnrolledDay
 FROM #MotionIndvData mb
		Left join #AdminData ad
		ON mb.LookupRuleGroupid = ad.LookupRuleGroupID








--  Select a.LookupClientid, a.LookupClientid, a.Firstname, a.Lastname, Gendercode, HomePhone = coalesce(b.Homephone, a.Homephone,isnull(cellphone,'')), cellPhone  = isnull(cellphone,'') 
--	FROM Dermsl_prod.dbo.Membersignupdata a
--		Left JOIN Dermsl_prod.dbo.Member b
--			ON a.Customerid = b.Customerid 
--where a.lookupClientid in (50, 147) and ActiveFlag = 1 and isnull(a.cancelledDatetime,'20990101' ) > getdate() and a.ProgramStartdate <= getdate() 
--and isnull(b.CancelledDateTime,'20990101') > getdate()
--and coalesce(b.Homephone, a.Homephone,isnull(cellphone,'')) <> '' 

--  Select LookupClientid, Firstname, Lastname, Gender, HomePhone, CellPhone FROM Dermsl_Prod.dbo.member where lookupclientid in(50,147) and Activememberflag = 1 