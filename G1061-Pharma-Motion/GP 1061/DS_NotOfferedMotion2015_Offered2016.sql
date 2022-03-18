/*** 
GP 1061 Pharmacy & Motion -- Data Set for groups offered motion in 2016 but not in 2015
Input databases:	AllSavers_Prod, pdb_AllSavers_Research, pdb_PharmaMotion
Date Created: 11 May 2017
***/

--pull for groups which had enrollment in motion in 2016
If (object_id('tempdb..#motion_groups') Is Not Null)
Drop Table #motion_groups
go

select PolicyID, GroupName, GroupState, PolicyEffDate, PolicyEndDate, EnrolledMotionYM
into #motion_groups
from pdb_Allsavers_Research..GroupSummary
where EnrolledMotionYM > 0
	--and GroupState not in ('PA', 'WI', 'DE', 'MO')	--to be consistent with the pulling of the data set
--(2830 row(s) affected)
--(4908 row(s) affected)
create unique index uIx_PolicyID on #motion_groups (PolicyID);

--flag if offered with motion in 2015
If (object_id('tempdb..#offeredmotion_2015') Is Not Null)
Drop Table #offeredmotion_2015
go

select a.PolicyID, a.GroupName, a.GroupState, a.PolicyEffDate, a.PolicyEndDate, a.EnrolledMotionYM	
	--, OfferedMotion_2014_Flag = max(case when year(b.QuoteSubmittedDate) = 2014 or year(PolicyEffDate) = 2014	then 1 else 0	end)
	, OfferedMotion_2015_Flag = max(case when year(b.QuoteSubmittedDate) = 2015 or year(PolicyEffDate) = 2015	then 1 else 0	end)
	, OfferedMotion_2016_Flag = max(case when year(b.QuoteSubmittedDate) = 2016 or year(PolicyEffDate) = 2016	then 1 else 0	end)
into #offeredmotion_2015
from #motion_groups		a
inner join AllSavers_Prod..Fact_Quote	b	on	a.PolicyID = b.PolicyID
group by a.PolicyID, a.GroupName, a.GroupState, a.PolicyEffDate, a.PolicyEndDate, a.EnrolledMotionYM
order by 1
--(4908 row(s) affected)
create unique index uIx_PolicyID on #offeredmotion_2015 (PolicyID);

/* test queries
select * from #test where OfferedMotion_2015_Flag = 0	--1,121 rows
select * from #test where OfferedMotion_2015_Flag = 0	and year(PolicyEffDate) <> 2016
select * from #test2 where OfferedMotion_2015_Flag = 0	--1,115 rows
select * from #test2 --where OfferedMotion_2015_Flag = 0	and year(PolicyEffDate) <> 2016	--0 rows
select a.PolicyID, a.GroupName, a.GroupState, a.PolicyEffDate, a.PolicyEndDate, a.EnrolledMotionYM, b.QuoteSubmittedDate, b.QuoteType, b.EffectiveDate
	, OfferedMotion_2015_Flag = case when year(b.QuoteSubmittedDate) = 2015 	then 1 else 0	end
from #motion_groups		a
inner join AllSavers_Prod..Fact_Quote	b	on	a.PolicyID = b.PolicyID
--where (case when year(b.QuoteSubmittedDate) = 2015	then 1 else 0	end) = 1
where a.PolicyID = 5400002057
order by 1, b.QuoteSubmittedDate
*/


--pull for the members under the said policies
If (object_id('pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016') Is Not Null)
Drop Table pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016
go

select d.MemberID	--d.*	
--into pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
into #test
from #offeredmotion_2015						a
inner join AllSavers_Prod..Dim_Member			b	on	a.PolicyID = b.PolicyID
inner join pdb_PharmaMotion..Member				c	on	b.MemberID = c.MemberID
inner join pdb_PharmaMotion..MemberSummary_cont	d	on	c.MemberID = d.MemberID
where OfferedMotion_2016_Flag = 0	
	and (c.MM_2015 > 0
	or c.MM_2016 > 0)
	and c.Motion = 1
group by d.MemberID
--(5832 row(s) affected)
--127368
create unique index uIx_MemberID_YrMo on pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016 (MemberID, YearMo);
--OfferedMotion_2016_Flag = 0	750 members

--remove members enrolled in motion June 2016 onwards
If (object_id('tempdb..#mbrmtn_less6mos') Is Not Null)
Drop Table #mbrmtn_less6mos
go

select MemberID, Min_YM = min(YearMo)
into #mbrmtn_less6mos
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
where Enrl_Motion = 1
group by MemberID
having min(YearMo) >= 201606
--(439 row(s) affected)
create unique index uIx_MemberID on #mbrmtn_less6mos (MemberID);

delete from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
where MemberID in (select MemberID from #mbrmtn_less6mos)
--15,804


select *
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
where MemberID = 9838


select count(distinct a.MemberID)
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2	a
left join #test														b	on a.MemberID = b.MemberID
where a.MemberID is null

select Mtn, count(distinct MemberID)
from	(
select MemberID, Mtn = max(Enrl_Motion)
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
group by MemberID
	) z
group by Mtn

select count(distinct MemberID)	--3,538
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2

select count(distinct MemberID)	--162; 26; 8275
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016

select Year_Nbr = left(YearMo, 4)
	, count(distinct MemberID)
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
where Enrl_Motion = 1
group by left(YearMo, 4)

select count(distinct MemberID)
from pdb_PharmaMotion..MemberSummary_notOffered2015_Offered2016_v2
where Enrl_Plan = 1
having count(distinct YearMo) < 12 --min(YearMo) > 201606