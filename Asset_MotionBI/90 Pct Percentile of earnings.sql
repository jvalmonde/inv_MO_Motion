-- 9/1/2016

-- Create a script that returns All Savers Motion groups that are in the 90% percentile of earnings in both of the last two months.
-- And, for each of those groups, list the members that are in the 90th percentile of the group in FIT earnings. 
-- Please limit to groups and members that have been enrolled at least 3 months.


USE pdb_DermReporting;


With cte_Earnings as (
	Select ROW_NUMBER() OVER (PARTITION BY RuleGroupName ORDER BY YearMonth) as RN
		,RuleGroupName
		,YearMonth					
		,FITSum = SUM(F + I + T)
		,PossibleFITSum = SUM(PossibleF + PossibleI + PossibleT)
	from Motion_by_Group_by_Month
	where 1=1
		and YearMonth < dbo.YearMonth(Getdate())
		and YearMonth > dbo.YearMonth(DATEADD(MM,-3,Getdate())) 
	Group by RuleGroupName
		,YearMonth
	),
	cte_Group_Earnings as (
	Select RuleGroupName
		,RN1 = MAX(ISNULL(CASE WHEN RN = 1 THEN FITSum/PossibleFITSum END,0.0))
		,RN2 = MAX(ISNULL(CASE WHEN RN = 2 THEN FITSum/PossibleFITSum END,0.0))
	from cte_Earnings
	Group by RuleGroupName
	)
Select *
from (
Select RuleGroupName
	,NTILE(10) OVER (ORDER BY RN1) AS Percentile_90Pct1
	,RN1
	,NTILE(10) OVER (ORDER BY RN2) AS Percentile_90Pct2
	,RN2
from cte_Group_Earnings
) as Main
Where Percentile_90Pct1 >= 9 AND Percentile_90Pct2 >= 9

