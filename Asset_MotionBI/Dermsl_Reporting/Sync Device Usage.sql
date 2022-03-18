-- Home Time and Work Time

use pdb_DermReporting;

Select Groupsize = case when Eligibles > 25 then '>25 eligible' when Eligibles <= 25 then '<= 25 eligible' else null end
,Platformname
	, HomeTime	=	SUM(Case When SyncMinute not between 480 and 1020 Then 1 Else 0 End)
	, WorkTime	=	SUM(Case When SyncMinute between 480 and 1020 Then 1 Else 0 End)
	, Count		=	Count(*) 
FROM [pdb_DermReporting].[dbo].[Fact_Sync]	a
	Inner join pdb_Dermreporting.dbo.Dim_member dm		on a.Account_ID = dm.Account_ID
	Inner Join[pdb_DermReporting].[dbo].Dim_Date	b	On	a.SyncDtSysID	=	b.DT_SYS_ID
	Left Join [pdb_DermReporting].[dbo].[Dim_Platform]	c	On	a.PlatFormSysId	=	c.PlatFormSysId
	inner join pdb_DermReporting.dbo.Motion_by_group_by_month  d On dm.RuleGroupName = d.RuleGroupName and d.YearMonth = 201606
Where YEAR_MO = 201605 
Group By case when Eligibles > 25 then '>25 eligible' when Eligibles <= 25 then '<= 25 eligible' else null end, Platformname 
Order By Groupsize, Platformname, Count desc

-- WeekDay and WeekEnd
Select Groupsize = case when Eligibles > 25 then '>25 eligible' when Eligibles <= 25 then '<= 25 eligible' else null end
,Platformname
	, WeekDay	=	SUM(Case When b.WEEK_DAY_IND = 'Y' Then 1 Else 0 End)
	, WeekEnd	=	SUM(Case When b.WEEK_DAY_IND = 'N' Then 1 Else 0 End)
	, Count		=	Count(*) 
FROM [pdb_DermReporting].[dbo].[Fact_Sync]	a
	Inner join pdb_Dermreporting.dbo.Dim_member dm		on a.Account_ID = dm.Account_ID
	Inner Join[pdb_DermReporting].[dbo].Dim_Date	b	On	a.SyncDtSysID	=	b.DT_SYS_ID
	Left Join [pdb_DermReporting].[dbo].[Dim_Platform]	c	On	a.PlatFormSysId	=	c.PlatFormSysId
	inner join pdb_DermReporting.dbo.Motion_by_group_by_month  d On dm.RuleGroupName = d.RuleGroupName and d.YearMonth = 201606
Where YEAR_MO = 201605
Group By case when Eligibles > 25 then '>25 eligible' when Eligibles <= 25 then '<= 25 eligible' else null end, Platformname 
Order By Groupsize, Platformname, Count desc