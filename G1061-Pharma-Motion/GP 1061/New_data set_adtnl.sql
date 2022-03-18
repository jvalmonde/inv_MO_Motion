/*** 
GP 1061 Pharmacy & Motion -- additional fields for the New data set

Input databases:	AllSavers_Prod, pdb_AllSavers_Research

Date Created: 07 June 2017
***/

--additions to the member table
--alter table pdb_PharmaMotion..Member_v2
--	add WithSteps tinyint
--		, Der_Mbr_EnrolledMotion_YrMo	int
--		, Der_Mbr_DisenrolledMotion		int
--		, Mbr_DisenrFlag				tinyint
--		, Der_Mtn_PcyMM					int
--		, Der_Grp_EnrolledMotionYM		int
--go
alter table pdb_PharmaMotion..Member_v2
	--alter column WithSteps tinyint
	alter column Der_Mbr_EnrolledMotionYM int
go

update pdb_PharmaMotion..Member_v2
set WithSteps = isnull(b.WithSteps, 0)
	, Der_Mbr_EnrolledMotionYM = b.Der_Mbr_EnrolledMotion_YrMo
	--, Der_Mbr_DisenrolledMotion	= b.Der_Mbr_DisenrolledMotion
	--, Mbr_DisenrFlag = isnull(b.Mbr_DisenrFlag, 0)
	, Der_Mtn_PcyMM = isnull(b.Der_Mtn_PcyMM, 0)
	--, Der_Grp_EnrolledMotionYM = b.Der_Grp_EnrolledMotionYM
from pdb_PharmaMotion..Member_v2	a
left join	(
				select SystemID
					, WithSteps = 1
					, Der_Mbr_EnrolledMotion_YrMo
					--, Der_Mbr_DisenrolledMotion
					--, Mbr_DisenrFlag
					, Der_Mtn_PcyMM = datediff(mm, cast(cast(Der_Mbr_EnrolledMotion_YrMo as varchar) + '01' as date), cast(Der_Mbr_DisenrolledMotion + '01' as date))
					--, Der_Grp_EnrolledMotionYM
				from	(
							select a.SystemID
								, Steps							= sum(Step_Cnt)
								, Der_Mbr_EnrolledMotion_YrMo	= min(case when Step_Cnt > 0	then YearMo	end)
								, Der_Mbr_DisenrolledMotion		= max(b.Der_Mbr_DisenrolledMotionYM)
								--, Mbr_DisenrFlag				= max(case when year(Mbr_DisenrolledMotionDate) <> 2999 and format(Mbr_DisenrolledMotionDate, 'yyyyMM') > format(PolicyEndDate, 'yyyyMM')	then 1	else 0	end)
								--, Der_Grp_EnrolledMotionYM		= max(case when Grp_EnrolledMotionYM < format(PolicyEffDate, 'yyyyMM')	then format(PolicyEffDate, 'yyyyMM') else Grp_EnrolledMotionYM	end)
							from pdb_PharmaMotion..MemberSummary_v2	a
							inner join pdb_PharmaMotion..Member_v2	b	on	a.SystemID = b.SystemID
							where a.Enrl_Motion = 1
							--where a.MemberID = 142
							group by a.SystemID
							having sum(Step_Cnt) > 0
						) z
				--where SystemID = 54000040250000700	--MemberID = 9819
			) b	on	a.SystemID = b.SystemID

select * from pdb_PharmaMotion..Member_v2

--Date: 06/12/2017
--enrollment date, year months
alter table pdb_PharmaMotion..Member_v2
	add Grp_EnrolledMotionDate		date
		, Mbr_EnrolledMotionDate	date
		, Mbr_DisenrolledMotionYM	char(6)
		, PolicyEffYM				char(6)
		, PolicyEndYM				char(6)
		, Mbr_PlanEffDate			date
		, Mbr_PlanEndDate			date
		, Fst_StepDate				date
		, Lst_StepDate				date
		, RAF_2014					decimal(9,2)
		, RAF_2015					decimal(9,2)
		, RAF_2016					decimal(9,2)
go

update pdb_PharmaMotion..Member_v2
set Grp_EnrolledMotionDate = cast(cast(Grp_EnrolledMotionYM as varchar) + '01' as date)
	, Mbr_DisenrolledMotionYM	= case when format(Mbr_DisenrolledMotionDate, 'yyyyMM') = '190001'	then NULL	else format(Mbr_DisenrolledMotionDate, 'yyyyMM')	end
	, PolicyEffYM	= format(PolicyEffDate, 'yyyyMM')
	, PolicyEndYM	= format(PolicyEndDate, 'yyyyMM')
from pdb_PharmaMotion..Member_v2

--Commercial RAF scores for every 6 months or more of member enrollment
alter table pdb_PharmaMotion..Member_v2
	--alter column RAF_2014					decimal(9,2)
	--alter column RAF_2015					decimal(9,2)
	alter column RAF_2016					decimal(9,2)
go

update pdb_PharmaMotion..Member_v2
set RAF_2014	= isnull(b.SilverTotalScore, 0)
	, RAF_2015	= isnull(c.SilverTotalScore, 0)
	, RAF_2016	= isnull(d.SilverTotalScore, 0)
from pdb_PharmaMotion..Member_v2	a
left join pdb_PharmaMotion..RA_Com_Q_MetalScoresPivoted_2014	b	on	a.SystemID = b.UniqueMemberID
left join pdb_PharmaMotion..RA_Com_J_MetalScoresPivoted_2015	c	on	a.SystemID = c.UniqueMemberID
left join pdb_PharmaMotion..RA_Com_J_MetalScoresPivoted_2016	d	on	a.SystemID = d.UniqueMemberID

/*
select avg(RAF_2014), avg(RAF_2015), avg(RAF_2016) from pdb_PharmaMotion..Member_v2
select min(RAF_2014), min(RAF_2015), min(RAF_2016) from pdb_PharmaMotion..Member_v2
select max(RAF_2014), max(RAF_2015), max(RAF_2016) from pdb_PharmaMotion..Member_v2
select * from pdb_PharmaMotion..Member_v2 where RAF_2015 = 156.88
select * from pdb_PharmaMotion..RA_Com_J_MetalScoresPivoted_2015 where UniquememberID = 54000023060006301
*/

--member plan enrollment dates
alter table pdb_PharmaMotion..Member_v2
	--alter column Mbr_PlanEffDate date
	alter column Mbr_PlanEndDate date
go

update pdb_PharmaMotion..Member_v2
set Mbr_PlanEffDate	= case when c.SystemID is null then cast(cast(a.Mbr_PlanEffYM as varchar) + '01' as date)											--handles the missing SystemIDs in the Member_Coverage table
								when a.Mbr_PlanEffYM <> format(c.EffectiveDate, 'yyyyMM')	then cast(cast(a.Mbr_PlanEffYM as varchar) + '01' as date)	--handles those members who changed SystemIDs over time
								else c.EffectiveDate 	end
	, Mbr_PlanEndDate =	case when c.SystemID is null then eomonth(cast(cast(a.Mbr_PlanEndYM as varchar) + '01' as date))
								when a.Mbr_PlanEndYM > format(c.TermDate, 'yyyyMM')  
									or (a.Mbr_PlanEndYM < format(c.TermDate, 'yyyyMM') and year(c.TermDate) <> 9999 and a.Mbr_PlanEndYM <> 201612)	then eomonth(cast(cast(a.Mbr_PlanEndYM as varchar) + '01' as date))
								else c.TermDate	end
from pdb_PharmaMotion..Member_v2	a
--inner join Allsavers_Prod..Dim_Member		b	on	a.SystemID = b.SystemID
left join Allsavers_Prod..Member_Coverage	c	on	a.SystemID = c.SystemID


/*--motion enrollment date
update pdb_PharmaMotion..Member_v2
set Mbr_EnrolledMotionDate = b.Mbr_EnrolledMotionDate
from pdb_PharmaMotion..Member_v2	a
left join	(
				select a.MemberID
					, Mbr_EnrolledMotionDate = case when c.SystemID is null and a.Mbr_EnrolledMotionYM <> ''	then cast(cast(a.Mbr_EnrolledMotionYM as varchar) + '01' as date)
														else d.FirstEnrolled end
				from pdb_PharmaMotion..Member_v2	a
				inner join Allsavers_Prod..Dim_Member					b	on	a.MemberID = b.MemberID
				left join pdb_Allsavers_Research..ASM_xwalk_Member		c	on	b.SystemID = c.SystemID
				left join pdb_Allsavers_Research..DERMEnrollme0Basis	d	on	c.Member_DIMID = d.Member_DIMID
				where d.Year_Mo <= 201607
			)	b	on	a.MemberID = b.MemberID
*/

--first & last day with steps >= 300
alter table pdb_PharmaMotion..Member_v2
	--alter column Fst_StepDate date
	--alter column Lst_StepDate date
	add Fst_StepYM		char(6)
		, Lst_StepYM	char(6)
go

update pdb_PharmaMotion..Member_v2
set Fst_StepDate = b.Fst_StepDate
	, Lst_StepDate = b.Lst_StepDate
	, Fst_StepYM = b.Fst_StepYM
	, Lst_StepYM = b.Lst_StepYM
from pdb_PharmaMotion..Member_v2	a
left join	(--27,815 rows
				select a.SystemID
					, Fst_StepDate = min(Full_Dt)
					, Lst_StepDate = max(Full_Dt)
					, Fst_StepYM	= format(min(Full_Dt), 'yyyyMM')
					, Lst_StepYM	= format(max(Full_Dt), 'yyyyMM')
				from	pdb_PharmaMotion..Member_v2	a
				--inner join Allsavers_Prod..Dim_Member						b	on	a.MemberID = b.MemberID
				--inner join pdb_Allsavers_Research..ASM_xwalk_Member			c	on	b.SystemID = c.SystemID
				--inner join pdb_Allsavers_Research..Longitudinal_Day_Pivoted	d	on	c.Member_DIMID = d.Member_DIMID
				inner join pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt	b	on	a.SystemID = b.SystemID
				where b.Steps >= 300
					--and a.MemberID = 139584
					and a.Mbr_EnrolledMotionYM <> ''
				group by a.SystemID
			)	b	on	a.SystemID = b.SystemID
--(131967 row(s) affected)

--add derived motion disenrolled motion date
alter table pdb_PharmaMotion..Member_v2
	add Der_Mbr_DisenrolledMotionDate date
go

update pdb_PharmaMotion..Member_v2
set Der_Mbr_DisenrolledMotionDate = case when Mbr_DisenrolledMotionDate > PolicyEndDate	then PolicyEndDate	else Mbr_DisenrolledMotionDate	end
from pdb_PharmaMotion..Member_v2


--add Member_DIMID
alter table pdb_PharmaMotion..Member_v2
	add Member_DIMID varchar(32)
go

update pdb_PharmaMotion..Member_v2	
set Member_DIMID = b.Member_DIMID
from pdb_PharmaMotion..Member_v2	a
left join	(--106,229 rows
				select a.MemberID, c.Member_DIMID
				from pdb_PharmaMotion..Member_v2					a
				inner join Allsavers_Prod..Dim_MemberDetail			b	on	a.MemberID = b.MemberID
				inner join pdb_Allsavers_Research..ASM_xwalk_Member	c	on	b.SystemID = c.SystemID
				where left(b.YearMo, 4) in (2014, 2015, 2016)
					and a.MemberID not in (15381, 52702, 408844)	--have multiple systemIDs/Member_DIMID
				group by a.MemberID, c.Member_DIMID
			) b	on	a.MemberID = b.MemberID

--add member enrolled date with First day with steps
alter table pdb_PharmaMotion..Member_v2
	add MotionEnrDate_FstDayWithSteps	date
		, MotionEnrYM_FstDayWithSteps	char(6)
		, MotionEnrDate_LstDayWithSteps	date
		, MotionEnrYM_LstDayWithSteps	char(6)
go

update pdb_PharmaMotion..Member_v2
set MotionEnrDate_FstDayWithSteps = b.MotionEnrDate_FstDayWithSteps
	, MotionEnrYM_FstDayWithSteps = b.MotionEnrYM_FstDayWithSteps
	, MotionEnrDate_LstDayWithSteps = b.MotionEnrDate_LstDayWithSteps
	, MotionEnrYM_LstDayWithSteps = b.MotionEnrYM_LstDayWithSteps
from pdb_PharmaMotion..Member_v2	a
left join	(
				select a.SystemID
					, MotionEnrDate_FstDayWithSteps		= min(case when b.Steps > 0	then b.Full_Dt	end)
					, MotionEnrYM_FstDayWithSteps		= format(min(case when b.Steps > 0	then b.Full_Dt	end), 'yyyyMM')
					, MotionEnrDate_LstDayWithSteps		= max(case when b.Steps > 0	then b.Full_Dt	end)
					, MotionEnrYM_LstDayWithSteps		= format(max(case when b.Steps > 0	then b.Full_Dt	end), 'yyyyMM')
				from pdb_PharmaMotion..Member_v2	a
				inner join pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt	b	on	a.SystemID = b.SystemID
				group by a.SystemID
			) b	on a.SystemID = b.SystemID
select * from pdb_PharmaMotion..Member_v2

--additions to the member summary table
--Kae's request
alter table pdb_PharmaMotion..MemberSummary_v2
	add Der_Enrl_Motion	tinyint
		, Der_Enrl_MonthInd	smallint
		, Der_PlcyEnrlMotion_MonthInd	smallint
go

update pdb_PharmaMotion..MemberSummary_v2
set Der_Enrl_Motion = b.Der_Enrl_Motion
	, Der_Enrl_MonthInd = b.Der_Enrl_MonthInd
	, Der_PlcyEnrlMotion_MonthInd = b.Der_PlcyEnrlMotion_MonthInd
from  pdb_PharmaMotion..MemberSummary_v2	a
inner join	(
				select a.SystemID, a.YearMo
					--, Enrl_Plan, Enrl_Motion, EnrlMotion_MonthInd, PlcyEnrlMotion_MonthInd
					, Der_Enrl_Motion	= case when a.YearMo between b.Der_Mbr_EnrolledMotionYM and b.Der_Mbr_DisenrolledMotionYM	then 1	else 0 end
					, Der_Enrl_MonthInd = case when (case when a.YearMo between b.Der_Mbr_EnrolledMotionYM and b.Der_Mbr_DisenrolledMotionYM	then 1	else 0 end) = 1 
												then datediff(mm, cast(cast(b.Der_Mbr_EnrolledMotionYM as varchar) + '01' as date), cast(a.YearMo + '01' as date)) 
												else datediff(mm, cast(cast(b.Der_Mbr_EnrolledMotionYM as varchar) + '01' as date), cast(a.YearMo + '01' as date)) 	end
					, Der_PlcyEnrlMotion_MonthInd = datediff(mm, cast(cast(b.Der_Grp_EnrolledMotionYM as varchar) + '01' as date), cast(a.YearMo + '01' as date))
				from pdb_PharmaMotion..MemberSummary_v2	a
				inner join pdb_PharmaMotion..Member_v2	b	on	a.SystemID = b.SystemID
				--where a.SystemID = 54000048110000101		
			)	b	on	a.SystemID = b.SystemID
					and a.YearMo = b.YearMo				
--(2,549,198 row(s) affected)


--Mike's request
alter table pdb_PharmaMotion..MemberSummary_v2
	add Der_Enrl_Motion_w300	tinyint
		, Der_Enrl_MonthInd_w300	smallint
go

update pdb_PharmaMotion..MemberSummary_v2
set Der_Enrl_Motion_w300 = b.Der_Enrl_Motion_w300
	, Der_Enrl_MonthInd_w300 = b.Der_Enrl_MonthInd_w300
from pdb_PharmaMotion..MemberSummary_v2	a
inner join	(
				select a.SystemID, a.YearMo
					, Der_Enrl_Motion_w300		= case when a.YearMo between b.Fst_StepYM and b.Lst_StepYM	then 1	else 0 end
					, Der_Enrl_MonthInd_w300	= case when (case when a.YearMo between b.Fst_StepYM and b.Lst_StepYM	then 1	else 0 end) = 1 
														then datediff(mm, b.Fst_StepDate, cast(a.YearMo + '01' as date)) 
														else datediff(mm, b.Fst_StepDate, cast(a.YearMo + '01' as date))	end
				from pdb_PharmaMotion..MemberSummary_v2	a
				inner join pdb_PharmaMotion..Member_v2	b	on	a.SystemID = b.SystemID
				--where b.MemberID = 192858
			)	b	on	a.SystemID = b.SystemID
					and	a.YearMo = b.YearMo

select * from pdb_PharmaMotion..MemberSummary_v2