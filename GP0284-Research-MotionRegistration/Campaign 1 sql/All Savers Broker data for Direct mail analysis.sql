
/*Put togeher data for Broker and rulegroup.*/


Use pdb_DermReporting;


If Object_Id('pdb_abw.dbo.DirectMail_MotionandBroker') is not null 
Drop table pdb_abw.dbo.DirectMail_MotionandBroker
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
Into pdb_abw.dbo.DirectMail_MotionandBroker   
FROM (Select Distinct a.Policyid, EffectiveDate, a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, a.AgentZip,a.AccountExecutive, SubscriberCnt, EligibleCnt  FROM  Devsql10.[AllSavers_Prod].[dbo].[Fact_Quote] a)  a
	Inner join Motion_by_Group_by_Month c
		ON Convert(varchar(14),a.PolicyId) = replace(c.OfferCode,'-','00') 
		and a.effectivedate = c.PeriodPolicyStartDate
Where LookupRuleGroupid  not in( 3271)
Create unique clustered index idxgroupmonth on pdb_abw.dbo.DirectMail_MotionandBroker(LookupRuleGroupid, YearMonth)

GO

/****************Rollup the performance of each broker.**************************/
If Object_Id('pdb_abw.dbo.DirectMail_BrokerPerformance ') is not null 
Drop table pdb_abw.dbo.DirectMail_BrokerPerformance 
Select *
INTO pdb_abw.dbo.DirectMail_BrokerPerformance 
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
			FROM  pdb_abw.dbo.DirectMail_MotionandBroker
			Where Yearmonth = '201603'and MotionPolicyMonth >= 0 
			group by AgentFirstname, AgentLastname, AmsAgentId, Agency, AgentAddressStreet1, AgentAddressStreet2, AgentCity, AgentState, AgentEmail, AgentZip
	) a
) a



Go 

/*****Get the individual Data for the members********/

use dermsl_Prod;
Drop table #MotionIndvData
Select distinct lrg.lookupRulegroupid, lrg.RuleGroupName, SICCode = ds.[2 DIGIT DESCRIPTION], lrg.Eligibles,lrg.Registered,RegistrationRate = Registered *1.00/Eligibles
, RegistrationRateCategory = case when Registered *1.00/Eligibles >= .40 then 'High'
								  when Registered *1.00/Eligibles >= .24 then 'Med'
								  when Registered *1.00/Eligibles >= 0 then 'Low' else null end 
,msd.Clientmemberid,Firstname, Lastname, Addressline, City, StateCode, msd.Zipcode,msd.Birthdate, msd.Gendercode, EffectiveDate = ProgramStartdate,Isregistered = msd.AccountVerifiedFlag ,  daysfromEffectiveDate = Datediff(Day,ProgramStartdate,getdate()) 
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

Drop table #GaTemp

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



Go 

Drop table #AdminData
Select a.LookupRuleGroupid, a.Policyid, a.Groupname,a.GroupStreet, a.GroupCity, a.GroupState, a.GroupZip, a.AdministrativeContact, a.GroupEmail,a.BusinessPhone, b.systemid, AdminContactGender = b.Gender, AdminContactBirthdate = b.Birthdate, AdminInsured = isnull(b.insuredFlag,0)
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


--Select * FROM #AdminData Where Admin_Insured_  ---Attach this motion and broker data to the group and indv data.
Go

Drop table pdb_Abw.dbo.ClaimsdataforMembers

Select * , GroupAdminAllwAmtPM = Max(Case when AdminSystemid = clientmemberid then AllwAmtPM else null end ) over(Partition by LookupRulegroupid) 
, GroupAdminmonths = Max(Case when AdminSystemid = clientmemberid then months else null end ) over(Partition by LookupRulegroupid) 
Into pdb_Abw.dbo.ClaimsdataforMembers
FROM 
( 
Select mb.LookupRuleGroupid, mb.RuleGroupname,ad.GroupStreet, ad.GroupCity, ad.GroupState, ad.GroupZip, mb.Siccode, mb.Eligibles, mb.Registered, mb.RegistrationRate
, mb.Clientmemberid, mb.Firstname, mb.Lastname,mb.Addressline,mb.City, mb.Statecode, mb.Zipcode, mb.Birthdate
, mb.genderCode, mb.EffectiveDate, mb.isregistered, mb.DaysFromEffectivedate , ad.AdminContactGender
,ad.AdministrativeContact, ad.GroupEmail as AdminEmail, ad.BusinessPhone as AdminPhone, ad.AdminInsured, ad.MotionEligible as AD_MotionEligible
, ad.AccountVerifiedFlag as AD_Motionregistered, ad.EligibleDays as AD_MotionEligibleDays, ad.RegisteredDays as Ad_MotionRegisteredDays
, ad.AvgStepsPerRegisteredDay as AD_AvgStepsPerMotionEnrolledDay, AdminSystemid = ad.SystemId, Months = Sum(Months)
,AllwamtPM = sum(ascd.Allwamt)/sum(ascd.Months) 

 FROM #MotionIndvData mb
		Left join #AdminData ad
		ON mb.LookupRuleGroupid = ad.LookupRuleGroupID  and isnull(adminContactBirthdate , '19990901') <= '20000101'
		Left join pdb_DermReporting.dbo.Dim_AllSaversClaimDetail ascd 
			On mb.clientmemberid = ascd.SystemID
Group by mb.LookupRuleGroupid, mb.RuleGroupname,ad.GroupStreet, ad.GroupCity, ad.GroupState, ad.GroupZip, mb.Siccode, mb.Eligibles, mb.Registered, mb.RegistrationRate
, mb.Clientmemberid, mb.Firstname, mb.Lastname,mb.Addressline,mb.City, mb.Statecode, mb.Zipcode, mb.Birthdate
, mb.genderCode, mb.EffectiveDate, mb.isregistered, mb.DaysFromEffectivedate , ad.AdminContactGender
,ad.AdministrativeContact, ad.GroupEmail , ad.BusinessPhone , ad.AdminInsured, ad.MotionEligible 
, ad.AccountVerifiedFlag , ad.EligibleDays , ad.RegisteredDays
, ad.AvgStepsPerRegisteredDay, ad.SystemId
) a 



Select a.* , EligibleSample = Case when effectiveDate between Dateadd(day,-45, '20160412') and  Dateadd(day,-11, '20160412') then 1 else 0 end  
From pdb_Abw.dbo.ClaimsdataforMembers a
	Inner join Dermsl_prod.dbo.MemberSignupdata b
		On a.Clientmemberid = b.Clientmemberid  and b.Lookupclientid = 50 and b.ActiveFlag = 1 and isnull(CancelledDateTime ,'20990101') > ProgramStartdate and ProgramStartdate < isnull(CancelledDateTime ,'20990101')

/***Eligible Sample***/
Select * From pdb_Abw.dbo.ClaimsdataforMembers Where    isregistered = 0 and effectiveDate between Dateadd(day,-45, '20160412') and  Dateadd(day,-11, '20160412') 

/****All Members - For analysis**************/



--Select * FROM pdb_abw.dbo.DirectMail_BrokerPerformance
--Select Distinct * FROM pdb_abw.dbo.DirectMail_MotionandBroker


--  Select a.LookupClientid, a.LookupClientid, a.Firstname, a.Lastname, Gendercode, HomePhone = coalesce(b.Homephone, a.Homephone,isnull(cellphone,'')), cellPhone  = isnull(cellphone,'') 
--	FROM Dermsl_prod.dbo.Membersignupdata a
--		Left JOIN Dermsl_prod.dbo.Member b
--			ON a.Customerid = b.Customerid 
--where a.lookupClientid in (50, 147) and ActiveFlag = 1 and isnull(a.cancelledDatetime,'20990101' ) > getdate() and a.ProgramStartdate <= getdate() 
--and isnull(b.CancelledDateTime,'20990101') > getdate()
--and coalesce(b.Homephone, a.Homephone,isnull(cellphone,'')) <> '' 

--  Select LookupClientid, Firstname, Lastname, Gender, HomePhone, CellPhone FROM Dermsl_Prod.dbo.member where lookupclientid in(50,147) and Activememberflag = 1 