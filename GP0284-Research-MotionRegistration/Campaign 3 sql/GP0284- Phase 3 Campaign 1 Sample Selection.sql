use pdb_DermReporting;

Drop table #BaseMembership

Select msd.LookupRuleGroupid
,ClientMEMBERID
,RuleGroupName = lrg.RuleGroupName
,FirstName
,Lastname
,AddressLine
,City
,StateCode
,Zipcode
,Birthdate
,GenderCode
,lrg.GroupStartDatetime
,EffectiveDate = ProgramStartDate
,isregistered  = AccountVerifiedFlag
,DaysFromEffectiveDate = DateDiff(day,ProgramStartDate,Getdate())
into #BaseMembership
FROM Dermsl_prod.dbo.MemberSignupData msd 
	Inner join Dermsl_Prod.dbo.LookupRulegroup lrg 
		On msd.LookupRuleGroupid = lrg.lookupRuleGroupid
where activeflag = 1 and programstartdate between '20160701' and '20160801' and AccountVerifiedFlag = 0 and isnull(CancelledDatetime,getdate()) >= getdate() and msd.lookupclientid = 50 
--and lrg.GroupStartDatetime >= '20160701'


/***Add some broker data******/


If Object_Id('tempdb.dbo.#DirectMail_MotionandBroker') is not null 
Drop table #DirectMail_MotionandBroker
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
,MotionPolicyMonth = Row_number()Over(Partition by c.Offercode order by YearMonth) 
,RecentMonthOID    = Row_number()Over(Partition by c.Offercode order by YearMonth desc) 
Into #DirectMail_MotionandBroker   
FROM  Motion_by_Group_by_Month c
	Left join (Select Distinct a.Policyid, EffectiveDate, a.agentFirstname, a.AmsAgentId, a.AgentLastname, a.agency,a.agentAddressStreet1, AgentAddressStreet2,AgentCity, AgentState,AgentEmail, a.AgentZip,a.AccountExecutive, SubscriberCnt, EligibleCnt  FROM  Devsql10.[AllSavers_Prod].[dbo].[Fact_Quote] a)  a
		ON Convert(varchar(14),a.PolicyId) = replace(c.OfferCode,'-','00') 
		and a.effectivedate = c.PeriodPolicyStartDate
Where LookupRuleGroupid  not in( 3271)

Create unique clustered index idxgroupmonth on #DirectMail_MotionandBroker(LookupRuleGroupid, YearMonth)

Select Distinct LookupRuleGroupid FROM tempdb.dbo.#DirectMail_MotionandBroker

/*****Try to get the info on the Group admin******/

If object_Id('tempdb.dbo.#AdminContactData') is not null
Drop table #AdminContactData
Select a.PolicyID
, AdminInsured = Case when dm2.Systemid is NOT null then 1 
					  wHEN DM.pOLICYID IS NOT NULL AND DM2.Systemid IS NULL THEN 0 else nULL end 
,AdminContactGender = dm2.Gender 
,AdminPhone = a.PhoneNumber
,AdminEmail = a.Email
,AdminContact = isnUll(dm.AdministrativeContact,a.CompanyContactName)
,AdminMotionEligible = Case when de.Clientmemberid is not null then 1 else 0 end 
,AdminMotionRegistered = Case when de.ClientMEMBERID is not null then 1 else 0 end 
,Admin_AvgStepsforEnrolledDays = fpa.AvgSteps
,AdminAllwAmtPM = AllwamtPm
,GroupStreet = a.Address1 
,GroupCity   = a.Cityname
,GroupState   = a.StateCode
,GroupZip     = a.ZipCode
,GroupSICCode = dm.GroupSICCode
,AdminDataAvailable = Case when dm.Policyid is not null then 1 else 0 end 
,Rn = Row_number()over(Partition by a.policyid order by dm2.Systemid)
Into #AdminContactData
FROM 
(
	Select * ,Rn = row_Number()Over(Partition by PolicyId order by LoadDate desc) 
	FROM ASIC_Wellness_Group_Motion
	Where MotionOrWellnessInd = 'M' 
) a 
	Left join (Select *, Rn = Row_Number()over(partition by Policyid order by Effectivedate desc) FROM  Devsql10.AllSavers_prod.dbo.Fact_quote) dm			---What is admin contact name?
		On   Replace(a.PolicyID ,'-','00') = dm.Policyid
		and dm.Rn = 1 
	left join  Devsql10.AllSavers_prod.dbo.Dim_Member dm2            --Is member insured?
		On dm.AdministrativeContact = dm2.Firstname + ' ' + dm2.Lastname
	Left join Dermsl_prod.dbo.Membersignupdata de											--Is member eligible/registered for motion.
		On Convert(varchar(30),dm2.Systemid) = de.Clientmemberid
	Left join (Select act.eligibleid, eli.Clientmemberid, AvgSteps =  Avg(totalSteps) From Fact_PreloadActivity act inner join Dim_Eligibles Eli on Eli.EligibleID = act.EligibleID Where isregistered = 1 group by act.eligibleid, eli.Clientmemberid) fpa 
		On de.ClientMEMBERID = fpa.Clientmemberid
	Left join  (Select Systemid, AllwamtPM = Convert(decimal(9,2),(Sum(AllwAmt)*1.00/sum(Months))) From Dim_AllSaversClaimDetail Group by SYSTEMId) clm 
		On dm2.Systemid = clm.SystemID
Where a.Rn = 1 


Select * FROM #AdminContactData where PolicyId = '5400-4578'
--Select * FROM tempdb.dbo.#AdminContactData
----Continue here with pulling admin data.

/*********Base membership with Broker stats,  Registration data, admin contact and Group address data******/
Drop table #MembershipandContactData
Select 
bm.*
,GroupEffectiveDate = bm.GroupStartdatetime
,DateBenefitsEnd = Dateadd(Day,60,EffectiveDate) 
,TotalEligibles = isnull(Eligibles , msd.TotalEligible)
,Registered  = isnull(Registered,msd.TotalRegistered)
,RegistrationRate = isnull(Registered*1.00 / Eligibles, msd.TotalRegistered*1.00/msd.TotalEligible)
,GroupAge = MotionPolicyMonth 
,dm.AgentLastname
,acd.*  
,Sic = ds.[2 DIGIT DESCRIPTION]
into #MembershipandContactData
FROM (#BaseMembership bm inner join Dermsl_prod.dbo.Lookuprulegroup lrg on bm.LOOKUPRuleGroupID = lrg.LOOKUPRuleGroupID)
	Left join #DirectMail_MotionandBroker dm 
		On bm.LOOKUPRuleGroupID = dm.LookupRuleGroupid
		and dm.RecentMonthOID = 1 
	left join #AdminContactData acd
		On lrg.OfferCode = acd.Policyid
		and acd.rn = 1 
	left join pdb_Dermreporting.dbo.Dim_Sic ds on Left(acd.GroupSICCode,2) = ds.[2 DIGIT CODE]
	left join (select LookupruleGroupid,TotalEligible  =  Count(*) , TotalRegistered =  Count(Case when AccountVerifiedFlag = 1 then clientmemberid else null end)From Dermsl_prod.dbo.Membersignupdata msd where activeFlag = 1  group by LookupruleGroupid) msd 
		On bm.LOOKUPRuleGroupID = msd.LookupRulegroupid




		use pdb_AllSaversRegistration;  Select * FROM dbo.ExecutiveContacts_JulandAugNewGroups

		Drop table pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1
Select b.*
, AdminFirstname  = Case when substring(isnull( a.[Executive Contact], b.AdminContact),0,charindex(' ',isnull( a.[Executive Contact], b.AdminContact),0) ) = '' then isnull( a.[Executive Contact], b.AdminContact) else substring(isnull( a.[Executive Contact], b.AdminContact),0,charindex(' ',isnull( a.[Executive Contact], b.AdminContact),0) ) end 
, CEOFirstname = a.[Email First ]
, CEO =  a.[Email First ] + ' ' + [Email Last]
, AdminContact_FullName = isnull( a.[Executive Contact], b.AdminContact)
, CEOandAdminDifferent = Case when Rtrim(Ltrim(a.[Executive Contact]))  <> Rtrim(Ltrim((a.[Email First ] + ' ' + [Email Last]))) then 1
							  when a.[Executive Contact] is null then null  else 0 end 
Into pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1
FROM    #MembershipandContactData b  							
		Left join dbo.ExecutiveContacts_JulandAugNewGroups	a  	On  a.Assoc + '-' + a.Client =  b.PolicyID 
		Select * FROM dbo.ExecutiveContacts_NewGroups


		sELECT dISTINCT lOOKUPrULEGROUPID  from #MembershipandContactData
use pdb_Dermreporting;

--Select * FROM Dermsl_prod.dbo.membersignupdata where rowCreatedDateTime >= '20160603'


update pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1 
set CeoandAdminDifferent = 0 
where CEOFirstname = AdminFirstname
 Select Distinct CEO, CEOFirstname, AdminContact_FullName, AdminFirstname FROM pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1 Where  CEOandAdminDifferent = 0 


 update pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1 
set AdminContact = AdminContact_Fullname

Select * FROM pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1
Select Distinct CEOandAdminDifferent, Groups = Count(Distinct LookupRuleGroupid) , Members = Count(*)  FROM pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1  where groupstartdatetime >= '20160701' Group by CEOandAdminDifferent

--use pdb_DermReporting;
--/***Check the work******/
-- Declare @Clientmemberid varchar(30) = (Select top 1 Clientmemberid   FROM   pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1 order by Newid())
-- Select * FROM pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1 where clientmemberid = @Clientmemberid 
-- Select * FROM  Dermsl_prod.dbo.Membersignupdata where clientmemberid = @clientmemberid 
-- Declare @lookupruleGroupid int = (Select LookupRuleGroupid from Dermsl_prod.dbo.Membersignupdata where clientmemberid = @clientmemberid)
-- Select * FROM Motion_By_Group_By_month where LookupRuleGroupid = @lookupruleGroupid
-- Declare @Policyid varchar(10) = (Select Distinct  Offercode From Motion_by_Group_by_Month where LookupRuleGroupid = @lookupruleGroupid)
-- Select * FROM ASIC_Wellness_Group_Motion where policyid = @Policyid

Select * FROM pdb_DermReporting.dbo.Asic_Wellness_Group_Motion where policyid = '5400-4566'


Select Distinct a.Assoc, a.Client, a.[Group Name] , a.[Effective DT], b.Policyid, b.RuleGroupName, b.GroupStartDatetime 
FROM pdb_AllSaversRegistration.dbo.ExecutiveContacts_JulandAugNewGroups a
	Full JOin   pdb_AllSaversRegistration..DirectMailList_Phase3_Campaign1 b
		On  a.Assoc + '-' + a.Client =  b.PolicyID or a.[Group Name] = b.RuleGroupName
		Where Convert(date,b.GroupStartDatetime) >= '20160701'

		Select lrg.RuleGroupname,lrg.offercode , Members = Count(Distinct msd.Membersignupdataid) 
		 FROM Dermsl_prod.dbo.LookupRuleGroup  lrg 
			Left JOIN Dermsl_prod.dbo.MemberSignupdata msd
				On lrg.lookupRulegroupid = msd.LookupRulegroupid 
where Rulegroupname like 'Stewa%' or lrg.offercode like '4616'
Group by lrg.RuleGroupname, lrg.offercode

Select * FROM Dermsl_prod.dbo.lookupRulegroup where offercode = '5400-4616'
Select * FROM Dermsl_prod..memberSignupdata where lookupRuleGroupid = 4216
Select *  FROM pdb_AllSaversRegistration.dbo.ExecutiveContacts_JulandAugNewGroups where [Group Name] like '%HGE%'