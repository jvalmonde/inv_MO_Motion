/*** 
GP 1061 Pharmacy & Motion -- Policy / Group table
Input databases:	AllSavers_Prod, pdb_AllSavers_Research
Date Created: 24 May 2017
***/

--pull for groups which had enrollment in motion in 2016
If (object_id('tempdb..#motion_groups') Is Not Null)
Drop Table #motion_groups
go

select PolicyID, GroupName, GroupState, PolicyEffDate, PolicyEndDate, EnrolledMotionYM
into #motion_groups
from pdb_Allsavers_Research..GroupSummary
where EnrolledMotionYM > 0
--(4908 row(s) affected)
create unique index uIx_PolicyID on #motion_groups (PolicyID);

select * from #motion_groups

--flag if offered with motion in 2015
If (object_id('pdb_PharmaMotion..Policy_MotionQuotation') Is Not Null)
Drop Table pdb_PharmaMotion..Policy_MotionQuotation
go

select PolicyID, GroupName, GroupState, PolicyEffDate, PolicyEndDate, EnrolledMotionYM
	, OfferedMotion_2015_FullDt = max(case when year(QuoteSubmittedDate) = 2015 or year(PolicyEffDate) = 2015	then QuoteSubmittedDate end)
	, OfferedMotion_2016_FullDt = max(case when year(QuoteSubmittedDate) = 2016 or year(PolicyEffDate) = 2016	then QuoteSubmittedDate end)
into pdb_PharmaMotion..Policy_MotionQuotation
from	(
			select a.PolicyID, a.GroupName, a.GroupState, a.PolicyEffDate, a.PolicyEndDate, a.EnrolledMotionYM	
				, b.QuoteSubmittedDate
				, OID = row_number() over(partition by a.PolicyID, year(b.QuoteSubmittedDate) order by b.QuoteSubmittedDate desc)
			from #motion_groups		a
			inner join AllSavers_Prod..Fact_Quote	b	on	a.PolicyID = b.PolicyID
			--where a.PolicyID = 5400001555
		) x
where OID = 1
group by PolicyID, GroupName, GroupState, PolicyEffDate, PolicyEndDate, EnrolledMotionYM
--(4908 row(s) affected)
create unique index uIx_PolicyID on pdb_PharmaMotion..Policy_MotionQuotation (PolicyID);