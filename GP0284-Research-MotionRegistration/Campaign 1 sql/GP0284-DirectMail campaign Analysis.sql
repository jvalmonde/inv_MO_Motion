/****** Script for SelectTopNRows command from SSMS  ******/
/****For each Treatment Group - Look at the members in the Treatment group and calculate the daily Registration Rate*****/

Use pdb_Dermreporting;

go

Alter proc dbo.DSelect_GP0284_DirectMail_Observation
as 
Begin
Select Sample = 'Sample Only'
,TreatmentNumber = Treatment
, Treatment = Case   when Treatment = '1' Then 'Easy money/Postcard/Home'
					 when Treatment = '2' Then 'Easy money/Letter/Work'
					 when Treatment = '3' Then 'You won/Postcard/Home'
					 when Treatment = '4' Then 'You won/Letter/Work'
					 when Treatment = '5' Then 'Tap negative energy/Postcard/Work'
					 when Treatment = '6' Then 'Tap negative energy/Letter/Home'
					 when Treatment = '7' Then 'Comic (tribal appeal)/Postcard/Work'
					 when Treatment = '8' Then 'Comic (tribal appeal)/Letter/Home'
					 ELSE 'Control'
			  END
, Date, Eligibles = Count(Distinct Eligibleid), Registered =  Count(Distinct Case when RegistrationDate <= Date then Eligibleid else null end )
,NetEnrollmentGain = IIF(Date <= '20160414' ,NULL,  Count(Distinct Case when RegistrationDate <= Date then Eligibleid else null end ) -  Sum(Case when date = '20160414' then sum(Convert(int,Case when RegistrationDate <= '20160414' then AccountVerifiedFlag else 0 end)) else null end) over (Partition by Treatment))
FROM 
(
	Select Date = Convert(Date,Dateadd(Day,n.Number,'20160414')), * 
	FROM 
	(
		SELECT 

		Treatment
		,b.Clientmemberid
		,b.EligibleID
		,b.AccountVerifiedFlag
		,RegistrationDate = Convert(Date,b.AccountverifiedDatetime)
		  FROM pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] a 
			Inner join pdb_Dermreporting.dbo.dim_eligibles b
				ON a.Firstname = b.Firstname 
				and a.Lastname = b.Lastname 
				and a.LookupRuleGroupid = b.LookupRuleGroupid 
				and a.Birthdate = b.Birthdate
				and b.ActiveFlag = 1 
				and isnull(b.CancelledDatetime, '20990101')  > programstartdate
				and isnull(b.cancelledDatetime , '20990101') > getdate()
				and (AccountVerifiedDateTime is null or AccountVerifiedDateTime >= '20160414')
				and Treatment <> 'C2'
	) a 
	 Join pdb_DermReporting.dbo.Number n 
on n.number between 0 and Datediff(day,'20160414',Getdate()) 
 ) a 
Group by  Treatment, Case		 when Treatment = '1' Then 'Easy money/Postcard/Home'
					 when Treatment = '2' Then 'Easy money/Letter/Work'
					 when Treatment = '3' Then 'You won/Postcard/Home'
					 when Treatment = '4' Then 'You won/Letter/Work'
					 when Treatment = '5' Then 'Tap negative energy/Postcard/Work'
					 when Treatment = '6' Then 'Tap negative energy/Letter/Home'
					 when Treatment = '7' Then 'Comic (tribal appeal)/Postcard/Work'
					 when Treatment = '8' Then 'Comic (tribal appeal)/Letter/Home'
					 ELSE 'Control'
			  END, Date


Union
/****Do the same thing as above, but expand the member sample to include the entire group *******/

/****For each Treatment Group - Look at the Groups associated with the members in the Treatment group and calculate the daily Registration Rate*****/
Select Sample = 'Full Group'
,TreatmentNumber = Treatment
, Treatment = Case   when Treatment = '1' Then 'Easy money/Postcard/Home'
					 when Treatment = '2' Then 'Easy money/Letter/Work'
					 when Treatment = '3' Then 'You won/Postcard/Home'
					 when Treatment = '4' Then 'You won/Letter/Work'
					 when Treatment = '5' Then 'Tap negative energy/Postcard/Work'
					 when Treatment = '6' Then 'Tap negative energy/Letter/Home'
					 when Treatment = '7' Then 'Comic (tribal appeal)/Postcard/Work'
					 when Treatment = '8' Then 'Comic (tribal appeal)/Letter/Home'
					 ELSE 'Control'
			  END


, Date, Eligibles = Count(Distinct Eligibleid), Registered = Count(Distinct Case when RegistrationDate <= Date then Eligibleid else null end )
,NetEnrollmentGain = IIF(Date <= '20160413' ,NULL,  Count(Distinct Case when RegistrationDate <= Date then Eligibleid else null end ) -  Sum(Case when date = '20160413' then sum(Convert(int,Case when RegistrationDate <= '20160413' then AccountVerifiedFlag else 0 end)) else null end) over (Partition by Treatment))
FROM 
(
	Select Date = Convert(Date,Dateadd(Day,n.Number,'20160401')), * 
	FROM 
	(
		SELECT 
		Treatment
		,b.Clientmemberid
		,b.EligibleID
		,b.AccountVerifiedFlag
		,RegistrationDate = Convert(Date,b.AccountverifiedDatetime)
		  FROM (Select Distinct a.Treatment, a.LookupRuleGroupid FROM pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] a)  a 
			Inner join pdb_Dermreporting.dbo.dim_eligibles b
				ON  a.LookupRuleGroupid = b.LookupRuleGroupid 
				and b.ActiveFlag = 1 
				and isnull(b.CancelledDatetime, '20990101')  > programstartdate
				and isnull(b.cancelledDatetime , '20990101') > getdate()
				and b.clientname = 'All savers Motion'
				and Treatment <> 'C2'
	) a 
	 Join pdb_DermReporting.dbo.Number n 
on n.number between 0 and Datediff(day,'20160401',Getdate()) 
 ) a 
Group by Treatment, Case		 when Treatment = '1' Then 'Easy money/Postcard/Home'
					 when Treatment = '2' Then 'Easy money/Letter/Work'
					 when Treatment = '3' Then 'You won/Postcard/Home'
					 when Treatment = '4' Then 'You won/Letter/Work'
					 when Treatment = '5' Then 'Tap negative energy/Postcard/Work'
					 when Treatment = '6' Then 'Tap negative energy/Letter/Home'
					 when Treatment = '7' Then 'Comic (tribal appeal)/Postcard/Work'
					 when Treatment = '8' Then 'Comic (tribal appeal)/Letter/Home'
					 ELSE 'Control'
			  END, Date
 
 END

 
/*****Output a datafile with all members and Registration info - use this in report **************/

Select a.Treatment, a.LookupRuleGroupid,
GroupFirstStartDate = c.EffectiveStartdate,MemberEffectiveDate = a.ProgramStartDate, a.AccountVerifiedDateTime, a.ActiveFlag, a.AccountVerifiedFlag, a.Birthdate, a.Gendercode, a.CancelledDatetime, a.Zipcode
, [Group] = IIF(b.Clientmemberid is not null , 'Mail Recipient' , 'Group Member - No mail'),
RegistrationPercent = Sum(Convert(int,AccountVerifiedFlag))Over(Partition by a.LookupRuleGroupid)*1.00/Count(a.LookupRuleGroupid)Over(Partition by a.LookupRuleGroupid)  
FROM 
	(Select Treatment, a.LookupRuleGroupid,b.ProgramStartDate, b.AccountVerifiedDateTime, b.ActiveFlag, b.AccountVerifiedFlag, b.Birthdate, b.Gendercode, b.CancelledDatetime, b.Zipcode , b.Firstname, b.Lastname
		FROM (Select Distinct a.Treatment, a.LookupRuleGroupid FROM pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] a)  a 
			Inner join pdb_Dermreporting.dbo.dim_eligibles b
				ON  a.LookupRuleGroupid = b.LookupRuleGroupid 
				and b.ActiveFlag = 1 
				and isnull(b.CancelledDatetime, '20990101')  > programstartdate
				and isnull(b.cancelledDatetime , '20990101') > getdate()
				and b.clientname = 'All savers Motion') a 
	Left JOIN pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] b
		ON a.Firstname =b.Firstname
		and a.Lastname = b.Lastname 
		and a.Birthdate = b.Birthdate
		and a.Gendercode = b.genderCode
	Left join (Select LookupRulegroupid, Effectivestartdate =  Min(Effectivestartdate) From pdb_Dermreporting.dbo.Dim_SESAllsaversPolicyYear Group by LookupRuleGroupid )c
		ON a.LookupRuleGroupid = c.LOOKUPRuleGroupID
--Where a.Treatment <> 'c'

/****Look at the totals for each treatment******************/
Select Treatment,Treatment = sum(memberstotreat), EligiblesforAllmembersofgroups = sum(Convert(int,Eligibles)), RegisteredforAllmembersofgroups = sum(Convert(int,Registered) )
FROM 
(
Select Distinct Treatment, Eligibles, Registered, memberstotreat = Count(*)  FROM pdb_DermReporting.[dbo].[GP0284_DirectMailAllSaversCampaignTreatmentGroups] a Group by Treatment, Eligibles, Registered 
) a 
Group by Treatment
