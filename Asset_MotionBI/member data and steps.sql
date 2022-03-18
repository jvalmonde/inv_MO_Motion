/*****This is a helpful start to putting together some data....Keep in mind that there will be multiple rows for a member day if they were part of two overlapping challenges.  I don't know if there are any such cases or not.****/


/*** ALL MEMBERS WITH CHALLENGES ***/
-- Drop Table #AllMembers
Select Distinct MEMBERID
  Into #AllMembers
FROM [DERMSL_Prod].[dbo].[MEMBERTeamDetail]
-- 2,945 08/23

/*** RULENAMES AND DESCRIPTIONS ***/
-- Drop Table #rules
Select *
	, OID	=	ROW_NUMBER() Over(Partition By LookUpRuleGroupID, RuleName, StartDate Order By Awards, RuleDescription)
  Into #rules
From pdb_DermReporting.dbo.Dim_RulesandPoints
--where LookupRuleGroupid = 36


/*** Triogotchi Data ***/
if object_id ('[pdb_Triogotchi_GP306].[dbo].[MemberStepsData]') is not null
drop table [pdb_Triogotchi_GP306].[dbo].[MemberStepsData]
Select Distinct dm.clientname, dm.Account_ID, dm.Dermsl_memberid, fpa.LookupRuleGroupID
	, dm.age, dm.Gender
	, [Date]	=	CONVERT(Date, dd.FULL_DT)
	, fpa.TotalSteps
	, GoalsMet	=	 F + I + T
	, FrequencyBouts
	, Fpoints, Ipoints, Tpoints, TotalAwards
	, FrequencyDescription		=	MAX(Case When rp.RuleName = 'Frequency' Then rp.RuleDescription Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, IntensityDescription		=	MAX(Case When rp.RuleName = 'Intensity' Then rp.RuleDescription Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, Tenacity1Description		=	MAX(Case When rp.RuleName = 'Tenacity' and rp.OID = 1 Then rp.RuleDescription Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, Tenacity2Description		=	MAX(Case When rp.RuleName = 'Tenacity' and rp.OID = 2 Then rp.RuleDescription Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, Tenacity3Description		=	MAX(Case When rp.RuleName = 'Tenacity' and rp.OID = 3 Then rp.RuleDescription Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, FrequencyPossiblePoints	=	SUM(Case When rp.RuleName = 'Frequency' Then rp.Awards Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, IntensityPossiblePoints	=	SUM(Case When rp.RuleName = 'Intensity' Then rp.Awards Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, Tenacity1PossiblePoints	=	SUM(Case When rp.RuleName = 'Tenacity' and rp.OID = 1 Then rp.Awards Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, Tenacity2PossiblePoints	=	SUM(Case When rp.RuleName = 'Tenacity' and rp.OID = 2 Then rp.Awards Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, Tenacity3PossiblePoints	=	SUM(Case When rp.RuleName = 'Tenacity' and rp.OID = 3 Then rp.Awards Else Null End) Over(Partition By dm.Account_ID, dd.FULL_DT)
	, dmt.TeamID, dmt.TeamName
	, dmt.StartDate
	, dmt.EndDate
	, dmt.Title
	, EmployerMotivation		=	Case When dm.ClientName = 'Cashman' and dd.Full_dt between dmt.StartDate and dmt.endDate Then 1 Else 0 End
	, Notes						=	Case When dm.ClientName = 'Cashman' and dd.Full_dt between dmt.StartDate and dmt.endDate Then 'Pushed for Challenges' Else NULL End
	, [1stDayofChallenge]		=	Case When dd.FULL_DT = dmt.StartDate and dmt.StartDate Is not NUll Then 1
										When dd.FULL_DT <> dmt.StartDate and dmt.StartDate Is not NUll Then 0
										Else NULL
									End
	, [LastDayofChallenge]		=	Case When dd.FULL_DT = dmt.EndDate and dmt.StartDate Is not NUll Then 1
										When dd.FULL_DT <> dmt.EndDate and dmt.StartDate Is not NUll Then 0
										Else NULL
									End
	, ChallengeJoined			=	Case When dmt.StartDate Is not NUll Then dmt2.OID Else Null End
	, dmt.ChallengeType, dmt.IsDefaultChallengeView
	, dmt.UseAverage, dmt.PointsFlag, dmt.UseStepsFlag, dmt.UseMonthlyDisplay
  Into [pdb_Triogotchi_GP306].[dbo].[MemberStepsData]
From #AllMembers	am
	Inner Join pdb_DermReporting.dbo.Dim_member dm 
		ON	am.MEMBERID	=	dm.Dermsl_Memberid
	Left join pdb_DermReporting.dbo.Fact_Activity fpa 
		ON dm.Account_id = fpa.Account_id 
	Left join pdb_DermReporting.dbo.Dim_date  dd
		ON fpa.Dt_Sys_ID = dd.DT_SYS_ID
	Left join pdb_Dermreporting.dbo.Dim_MemberTeam  dmt
		ON dm.Account_ID = dmt.Account_id
		and dd.Full_dt between dmt.StartDate and dmt.endDate
	Left Join #rules rp
		ON	rp.LookupRuleGroupid	=	fpa.LookupRuleGroupID
		and dd.Full_dt between rp.StartDate and rp.endDate
	Left Join	(
				Select *
					, OID =	ROW_NUMBER() Over(Partition By Account_ID Order By StartDate, EndDate)
				From	(
						Select Distinct Account_ID, StartDate, EndDate
						From pdb_Dermreporting.dbo.Dim_MemberTeam
						)	a
				)	dmt2
		ON dm.Account_ID = dmt2.Account_ID
		and dmt.StartDate = dmt2.StartDate
		and dmt.EndDate = dmt2.EndDate
--Where dm.Account_id = 4487
order by Date


/*** LOOKUP TEAM to RULEGROUP to CLIENT ***/
Select Distinct c.LookupClientID, b.LookupRuleGroupID, TeamID
FROM [pdb_DermReporting].[dbo].[Dim_MemberTeam]			a
	Join [pdb_DermReporting].[dbo].[Fact_Activity]		b
		on	a.Account_ID	=	b.Account_ID
	Join [pdb_DermReporting].[dbo].[Dim_LookupRuleGroup]	c
		on	b.LookupRuleGroupID	=	c.LOOKUPRuleGroupID
Order By c.LOOKUPClientID, b.LookupRuleGroupID, TeamID



/*** HEALTH STATS AND RAF SCORES FROM 2012 FOR CASHMAN EMPLOYEES ***/
Select Distinct Dermsl_Memberid
FROM [pdb_abw].[dbo].[CashmanClaimsAnalysisAllEmployees]
where Dermsl_Memberid is not null
order by Dermsl_Memberid


Select Distinct a.*
	, HadAnyTeamChallenge	=	Case When c.Account_ID is not null then 1 else 0 End
FROM [pdb_abw].[dbo].[CashmanClaimsAnalysisAllEmployees]	a
	Inner Join pdb_DermReporting.dbo.Dim_Member	b
		On	a.Dermsl_Memberid	=	b.Dermsl_Memberid
	Left Join pdb_DermReporting.dbo.Dim_MemberTeam	c
		On	b.Account_ID	=	c.Account_ID
where a.Dermsl_Memberid is not null
	and Dataset = 'Option C'
Order By a.Dermsl_Memberid