-- DEVSQL10
Use pdb_ABW
Go

/******************************************** Match HY members to AllSavers ********************************************/ 

Select Distinct a.First, a.Last, a.DOB, a.State		-- 129,297 Distinct a.First, a.Last, a.DOB, a.State	
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a

-- Match by FirstName, LastName, DOB, State
-- Drop Table #FirstMatch_Mbrs
Select Distinct a.First, a.Last, a.DOB, a.State		-- 127,441 Distinct a.First, a.Last, a.DOB, a.State	MATCHED
	, b.SystemID, b.MemberID						-- 127,810
  Into #FirstMatch_Mbrs
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a
Inner Join AllSavers_Prod.dbo.Dim_Member	b	on	a.First	=	b.FirstName
												and	a.Last	=	b.LastName
												and a.DOB	=	b.BirthDate
												and a.State	=	b.State
--Order By a.Last, a.First

-- Filter Out thos who have more than 1 systemIDs
--Drop Table pdb_ABW.dbo.HY_MatchedMbrs
Select b.*
  Into pdb_ABW.dbo.HY_MatchedMbrs
From
(
	Select First, Last, DOB, State, Cnt = Count(Distinct SystemID)
	From #FirstMatch_Mbrs
	Group By First, Last, DOB, State
	Having Count(Distinct SystemID) = 1
)	a
Join #FirstMatch_Mbrs b	on	a.First	=	b.First
						and	a.Last	=	b.Last
						and a.DOB	=	b.DOB
						and a.State	=	b.State
Order By b.Last, b.First
-- 127,073 members that have only 1 systemID/MemberID
-- 98% match rate (127,073 / 129,297)


/******************************************** HY members and Consults ********************************************/ 

/*** 2015 ***/
Select Distinct a._ID										-- 130,380 Distinct _IDs. 1 distinct member (Name, DOB, State) may have more than 1 _ID. 1 _ID may represent 1 member either primary or dependent.
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a

Select Distinct a._ID										-- 3,650 with consults; 126,730 without; 130,380 Distinct _IDs (only 2.8% have consults)
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a
JOIN [pdb_ABW].[dbo].[HealthiestYou_UHG_2015_CONSULTS]	b	on	a._id		=	b.Reporting2


/*************************************************** HY ALLSAVERS AND MOTION ***************************************************/
-- DEVSQL14
--Use pdb_DermReporting
--Go

/*****
IMPORT [pdb_DermReporting].[dbo].[HY_MatchedMbrs] to pdb_DemrReporting
*****/

SELECT a.[First], a.[Last], a.[DOB], a.[State], a.[SystemID], a.[MemberID]
	, b.Firstname, b.Lastname, b.Birthdate, b.StateCode
FROM [pdb_DermReporting].[dbo].[HY_MatchedMbrs]	a
Join [pdb_DermReporting].[dbo].Dim_Eligibles	b	on	CONVERT(varchar(50), a.SystemID)	=	b.Clientmemberid
-- 81,182
-- 64%
