USE [pdb_abw]
GO

/****** Object:  View [dbo].[vwGP0284_MemberRegistrations]    Script Date: 4/28/2016 3:35:14 PM ******/
SET ANSI_NULLS ON
GO

Drop table [pdb_abw].[dbo].[GP0284_MemberRegistrations] 
Select a.Treatment, a.LookupRuleGroupid,
GroupFirstStartDate = c.EffectiveStartdate,MemberEffectiveDate = a.ProgramStartDate,MemberEligibilityEndDate = a.CancelledDatetime, registeredDate = a.AccountVerifiedDateTime,IsRegistered =  a.AccountVerifiedFlag, IsEligible = a.ActiveFlag, a.Birthdate, a.Gendercode, a.CancelledDatetime, a.State, a.Zipcode
, [Group] = IIF(b.Clientmemberid is not null , 'Mail Recipient' , 'Group Member - No mail'),
 GroupState = x.State, Groupzip = x.ZipCode,GroupRegistrationRateatStart = Max(RegistrationRate) over(Partition by a.LookupRuleGroupid) 
,TreatmentName = Case		 when a.Treatment = '1' Then 'Easy money/Postcard/Home'
					 when a.Treatment = '2' Then 'Easy money/Letter/Work'
					 when a.Treatment = '3' Then 'You won/Postcard/Home'
					 when a.Treatment = '4' Then 'You won/Letter/Work'
					 when a.Treatment = '5' Then 'Tap negative energy/Postcard/Work'
					 when a.Treatment = '6' Then 'Tap negative energy/Letter/Home'
					 when a.Treatment = '7' Then 'Comic (tribal appeal)/Postcard/Work'
					 when a.Treatment = '8' Then 'Comic (tribal appeal)/Letter/Home'
					 ELSE 'Control'
			  END,
			  TreatmentMethod = Case		 when a.Treatment = '1' Then 'Easy money'
					 when a.Treatment = '2' Then 'Easy money'
					 when a.Treatment = '3' Then 'You won'
					 when a.Treatment = '4' Then 'You won'
					 when a.Treatment = '5' Then 'Tap negative energy'
					 when a.Treatment = '6' Then 'Tap negative energy'
					 when a.Treatment = '7' Then 'Comic (tribal appeal)'
					 when a.Treatment = '8' Then 'Comic (tribal appeal)'
					 ELSE 'Control'
			  END,
			  TreatmentFormat = Case		 when a.Treatment = '1' Then 'Postcard'
					 when a.Treatment = '2' Then 'Letter'
					 when a.Treatment = '3' Then 'Postcard'
					 when a.Treatment = '4' Then 'Letter'
					 when a.Treatment = '5' Then 'Postcard'
					 when a.Treatment = '6' Then 'Letter'
					 when a.Treatment = '7' Then 'Postcard'
					 when a.Treatment = '8' Then 'Letter'
					 ELSE 'Control'
			  END,
			  TreatmentDestination = Case		 when a.Treatment = '1' Then 'Home'
					 when a.Treatment = '2' Then 'Work'
					 when a.Treatment = '3' Then 'Home'
					 when a.Treatment = '4' Then 'Work'
					 when a.Treatment = '5' Then 'Work'
					 when a.Treatment = '6' Then 'Home'
					 when a.Treatment = '7' Then 'Work'
					 when a.Treatment = '8' Then 'Home'
					 ELSE 'Control'
			  END,

RegistrationPercent = Sum(Convert(int,AccountVerifiedFlag))Over(Partition by a.LookupRuleGroupid)*1.00/Count(a.LookupRuleGroupid)Over(Partition by a.LookupRuleGroupid) 
into [pdb_abw].[dbo].[GP0284_MemberRegistrations] 
FROM 
	(Select Treatment, b.clientmemberid,  a.LookupRuleGroupid,b.ProgramStartDate, b.AccountVerifiedDateTime, b.ActiveFlag, b.AccountVerifiedFlag, b.Birthdate, b.Gendercode, b.CancelledDatetime,State = b.Statecode, b.Zipcode , b.Firstname, b.Lastname
		FROM (Select Distinct a.Treatment, a.LookupRuleGroupid FROM pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] a)  a 
			Inner join pdb_Dermreporting.dbo.dim_eligibles b
				ON  a.LookupRuleGroupid = b.LookupRuleGroupid 
				and (b.ActiveFlag = 1 or isnull(b.cancelledDatetime , '20990101') >= '20160501')
				and isnull(b.CancelledDatetime, '20990101')  > programstartdate
				and b.clientname = 'All savers Motion' ) a
	Left JOIN pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] b
		ON a.clientmemberid = b.clientmemberid
		 and a.LookupRuleGroupid = b.LookupRuleGroupid
		and a.Treatment = b.Treatment
	Left join (Select LookupRulegroupid, Effectivestartdate =  Min(Effectivestartdate) From pdb_Dermreporting.dbo.Dim_SESAllsaversPolicyYear Group by LookupRuleGroupid )c
		ON a.LookupRuleGroupid = c.LOOKUPRuleGroupID
	Left JOin 	(	Select * FROM 
					(Select LookupRuleGroupid, State, ZipCode, Rn = Row_Number()over(Partition by LookupRuleGroupid order by PeriodPolicyyear desc), PeriodPolicyYear  FROM Pdb_DermReporting.dbo.Dim_SESAllsaversPolicyYear 
					) a Where Rn = 1 
				) x 
					On x.LOOKUPRuleGroupID = a.LookupRuleGroupid
Where a.Treatment in ('1','2','3','4','5','6','7','8', 'c')


