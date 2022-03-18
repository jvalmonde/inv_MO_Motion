/*** 
GP 1061 Pharmacy & Motion -- Utilization, FIT Goals, Customer segment/company
Input databases:	AllSavers_Prod, pdb_AllSavers_Research, pdb_PharmaMotion
Date Created: 03 May 2017
***/

--Utilization
If (object_id('tempdb..#utilization') Is Not Null)
Drop Table #utilization
go

select a.MemberID, c.YearMo
	--allow amounts
	, IP_Allow = sum(case when d.ServiceTypeCd = 'IP'									then b.AllwAmt	else 0	end)
	, OP_Allow = sum(case when d.ServiceTypeCd = 'OP' and b.PlaceOfService <> 23		then b.AllwAmt	else 0	end)
	, DR_Allow = sum(case when d.ServiceTypeCd = 'DR' 									then b.AllwAmt	else 0	end)
	, ER_Allow = sum(case when d.ServiceTypeCd = 'OP' and b.PlaceOfService = 23 and e.ServiceCodeLongDescription = 'Emergency Room Facility'		then b.AllwAmt	else 0	end)
	, RX_Allow = sum(case when d.ServiceTypeCd = 'RX' 									then b.AllwAmt	else 0	end)
	--, Total_Allow = sum(b.AllwAmt)
	
	--visit counts
	, IP_Visits	= count(distinct case when d.ServiceTypeCd = 'IP' and b.AdmitCnt = 1		then b.FromDtSysID	end)
	, IP_Days	= sum(case when d.ServiceTypeCd = 'IP' and b.AdmitCnt = 1					then b.DayCnt	else 0	end)
	, OP_Visits	= count(distinct case when d.ServiceTypeCd = 'OP' 							then b.FromDtSysID	end)
	, DR_Visits	= count(distinct case when d.ServiceTypeCd = 'DR' 							then b.FromDtSysID	end)
	, ER_Visits	= count(distinct case when e.ServiceCodeLongDescription = 'Emergency Room Facility'		then b.FromDtSysID	end)
	, RX_Scripts	= sum(case when d.ServiceTypeCd = 'RX' 						then b.ScriptCnt	else 0	end)
into #utilization
from pdb_PharmaMotion..Member		a
inner join AllSavers_Prod..Fact_Claims		b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date			c	on	b.FromDtSysID = c.DtSysId
inner join AllSavers_Prod..Dim_ServiceType	d	on	b.ServiceTypeSysID = d.ServiceTypeSysID
inner join AllSavers_Prod..Dim_ServiceCode	e	on	b.ServiceCodeSysID = e.ServiceCodeSysID
where c.YearNbr in  (2014, 2015, 2016)
--where a.MemberID = 126430
--	and c.YearMo = 201608
group by a.MemberID, c.YearMo
--(488534 row(s) affected); 1.19 minutes
create unique index uIx_MemberID_YrMo on #utilization (MemberID, YearMo);

/* test queries
select *
from #utilization
where Total_Allow <> (IP_Allow + OP_Allow + DR_Allow + /*ER_Allow*/ + RX_Allow)

select min(IP_Days), max(IP_Days), avg(IP_Days)
	--, percentile_cont(0.5) within group (order by IP_Days) over(partition by MemberID)
from #utilization

select distinct percentile_cont(0.5) within group (order by IP_Days) over(partition by 1)
from #utilization
where IP_Days > 0

select a.*, d.ServiceTypeCd, e.ServiceCodeLongDescription
from AllSavers_Prod..Fact_Claims	a
inner join AllSavers_Prod..Dim_Date	b	on	a.FromDtSysID = b.DtSysId
inner join AllSavers_Prod..Dim_ServiceType	d	on	a.ServiceTypeSysID = d.ServiceTypeSysID
inner join AllSavers_Prod..Dim_ServiceCode	e	on	a.ServiceCodeSysID = e.ServiceCodeSysID
where b.YearMo = 201605
	and a.MemberID = 160768	--267688
*/

alter table pdb_PharmaMotion..MemberSummary_cont
	add	  IP_Allow	decimal(38,2)
		, OP_Allow	decimal(38,2)
		, DR_Allow	decimal(38,2)
		, ER_Allow	decimal(38,2)
		, RX_Allow	decimal(38,2)
		, Total_Allow	decimal(38,2)
		, IP_Visits	int
		, IP_Days		int
		, OP_Visits	int
		, DR_Visits	int
		, ER_Visits	int
		, RX_Scripts	int
--drop column IP_Allow, OP_Allow, DR_Allow, ER_Allow, RX_Allow, Total_Allow, IP_SrvcCnt, IP_Days, OP_SrvcCnt, DR_SrvcCnt, ER_SrvcCnt, RX_Scripts
go

update pdb_PharmaMotion..MemberSummary_cont
set IP_Allow		= isnull(b.IP_Allow, 0)	
	, OP_Allow		= isnull(b.OP_Allow, 0)
	, DR_Allow		= isnull(b.DR_Allow, 0)
	, ER_Allow		= isnull(b.ER_Allow, 0)
	, RX_Allow		= isnull(b.RX_Allow, 0)
	, Total_Allow	= (isnull(b.IP_Allow, 0) + isnull(b.OP_Allow, 0) + isnull(b.DR_Allow, 0) + isnull(b.RX_Allow, 0) + isnull(b.ER_Allow, 0))
	, IP_Visits	= isnull(b.IP_Visits, 0)
	, IP_Days		= isnull(b.IP_Days	, 0)
	, OP_Visits		= isnull(b.OP_Visits, 0)
	, DR_Visits		= isnull(b.DR_Visits, 0)
	, ER_Visits		= isnull(b.ER_Visits, 0)
	, RX_Scripts	= isnull(b.RX_Scripts, 0)
from pdb_PharmaMotion..MemberSummary_cont	a
left join #utilization						b	on	a.MemberID = b.MemberID
												and a.YearMo = b.YearMo
--(1823832 row(s) affected)
select * from pdb_PharmaMotion..MemberSummary_cont

--FIT goals
select count(distinct a.MemberID)	--43,365
from pdb_PharmaMotion..Member							a
inner join AllSavers_Prod..Dim_Member					b	on	a.MemberID = b.MemberID
inner join pdb_Allsavers_Research..ASM_xwalk_Member		c	on	b.SystemID = c.SystemID	--73,077
inner join pdb_Allsavers_Research..Longitudinal_Month	d	on	c.Member_DIMID = d.Member_DIMID


if object_id(N'tempdb..#IncentiveBasis') is not null
   drop table #IncentiveBasis;

select MemberID, Year_Mo
     , ttlIncentiveEarnedForMonth   = sum(TotalIncentiveEarned)
	 --, maxPossibleIncentiveForMonth = sum(maxPossibleIncentiveForMonth)
     , Frequency_ttlIncentiveEarned = max(case when IncentiveType = 'Frequency' then TotalIncentiveEarned else 0.00 end)
     , Frequency_ttlIncentiveSteps  = max(case when IncentiveType = 'Frequency' then TotalSteps else 0 end)
     , Frequency_ttlIncentiveBouts  = max(case when IncentiveType = 'Frequency' then TotalBouts else 0 end)
     --, maxPossible4Month_Frequency  = max(case when IncentiveType = 'Frequency' then maxPossibleIncentiveForMonth else 0.00 end)
     --, reqSteps2Earn_Frequency      = max(case when IncentiveType = 'Frequency' then RequiredToEarnIncentive_Steps else 0 end)
     --, reqMinutes2Earn_Frequency    = max(case when IncentiveType = 'Frequency' then RequiredToEarnIncentive_Minutes else 0 end)
     --, reqBouts2Earn_Frequency      = max(case when IncentiveType = 'Frequency' then RequiredToEarnIncentive_Bouts else 0 end)
     , Intensity_ttlIncentiveEarned = max(case when IncentiveType = 'Intensity' then TotalIncentiveEarned else 0.00 end)
     , Intensity_ttlIncentiveSteps  = max(case when IncentiveType = 'Intensity' then TotalSteps else 0 end)
     , Intensity_ttlIncentiveBouts  = max(case when IncentiveType = 'Intensity' then TotalBouts else 0 end)
     --, maxPossible4Month_Intensity  = max(case when IncentiveType = 'Intensity' then maxPossibleIncentiveForMonth else 0.00 end)
     --, reqSteps2Earn_Intensity      = max(case when IncentiveType = 'Intensity' then RequiredToEarnIncentive_Steps else 0 end)
     --, reqMinutes2Earn_Intensity    = max(case when IncentiveType = 'Intensity' then RequiredToEarnIncentive_Minutes else 0 end)
     --, reqBouts2Earn_Intensity      = max(case when IncentiveType = 'Intensity' then RequiredToEarnIncentive_Bouts else 0 end)
     , Tenacity_ttlIncentiveEarned  = max(case when IncentiveType = 'Tenacity'  then TotalIncentiveEarned else 0.00 end)
     , Tenacity_ttlIncentiveSteps   = max(case when IncentiveType = 'Tenacity'  then TotalSteps else 0 end)
     , Tenacity_ttlIncentiveBouts   = max(case when IncentiveType = 'Tenacity'  then TotalBouts else 0 end)
     --, maxPossible4Month_Tenacity   = max(case when IncentiveType = 'Tenacity'  then maxPossibleIncentiveForMonth else 0.00 end)
     --, reqSteps2Earn_Tenacity       = max(case when IncentiveType = 'Tenacity'  then RequiredToEarnIncentive_Steps else 0 end)
     --, reqMinutes2Earn_Tenacity     = max(case when IncentiveType = 'Tenacity'  then RequiredToEarnIncentive_Minutes else 0 end)
     --, reqBouts2Earn_Tenacity       = max(case when IncentiveType = 'Tenacity'  then RequiredToEarnIncentive_Bouts else 0 end)
  into #IncentiveBasis
  from (select distinct a.MEMBERID, a.Year_Mo, IncentiveType = r.RuleName, IncentiveUOM = i.LabelName
        	 , TotalIncentiveEarned = a.IncentiveAmount, a.TotalSteps,a.TotalBouts
        	 , maxPossibleIncentiveForMonth = ym.DaysInMonth * r.IncentiveAmount
        	 , RequiredToEarnIncentive_Steps = r.TotalStepsMin,  RequiredToEarnIncentive_Minutes = r.TotalMinutes
        	 , RequiredToEarnIncentive_Bouts = r.TotalBouts
          FROM pdb_Allsavers_Research.ETL.AS_DERM_MemberEarnedIncentives a
          join pdb_Allsavers_Research..ASM_YearMo                        ym on a.Year_Mo            = ym.Year_Mo
          join pdb_Allsavers_Research.etl.AS_DERM_LookupRule             r on a.LOOKUPRuleID       = r.LOOKUPRuleID
																			and r.RuleName in ('Frequency','Intensity','Tenacity')
          join pdb_Allsavers_Research.ETL.AS_DERM_RuleGroups             g on r.LOOKUPRuleGroupID  = g.LOOKUPRuleGroupID
          join pdb_Allsavers_Research.ETL.AS_DERM_IncentiveLabel         i on g.LOOKUPIncentiveLabelID = i.LookupIncentiveLabelID
       ) IncentiveBasis
 group by MemberID, Year_Mo
;--(225604 row(s) affected)
create clustered index ucix_MemberID on #IncentiveBasis (MemberID);


If (object_id('tempdb..#fitgoalsincentives') Is Not Null)
Drop Table #fitgoalsincentives
go

select mc.MemberID, a.*
into #fitgoalsincentives
from	(--211,305
			select ax.SystemID, ma.Year_Mo, Step_Cnt = ma.TotalSteps, NoDays_wSteps = ma.NbrDayWalked	--use these fields instead of getting from Longitudinal_Day
				, ib.ttlIncentiveEarnedForMonth
				, ib.Frequency_ttlIncentiveEarned
				, ib.Frequency_ttlIncentiveSteps 
				, ib.Frequency_ttlIncentiveBouts 
				, ib.Intensity_ttlIncentiveEarned
				, ib.Intensity_ttlIncentiveSteps 
				, ib.Intensity_ttlIncentiveBouts
				, ib.Tenacity_ttlIncentiveEarned
				, ib.Tenacity_ttlIncentiveSteps 
				, ib.Tenacity_ttlIncentiveBouts
			from pdb_Allsavers_Research.etl.AS_DERM_MemberAction          ma
			join pdb_Allsavers_Research..ASM_YearMo                       ym on ma.Year_Mo        = ym.Year_Mo
			join pdb_Allsavers_Research.etl.AS_DERM_Members      (nolock) dm on ma.Memberid       = dm.MEMBERID   -- Memberid
			join pdb_Allsavers_Research.etl.DERM_xwalk_Member    (nolock) dx on dm.ClientMEMBERID = dx.dSystemID  -- xwalk to
			join pdb_Allsavers_Research..ASM_xwalk_Member        (nolock) ax on dx.aSystemid      = ax.SystemID   -- DIMID
			join #IncentiveBasis										  ib on ma.MEMBERID = ib.MEMBERID
																		  	 and ma.Year_mo = ib.Year_Mo
			group by ax.SystemID, ma.Year_Mo, ma.TotalSteps, ma.NbrDayWalked
				, ib.ttlIncentiveEarnedForMonth
				, ib.Frequency_ttlIncentiveEarned
				, ib.Frequency_ttlIncentiveSteps 
				, ib.Frequency_ttlIncentiveBouts 
				, ib.Intensity_ttlIncentiveEarned
				, ib.Intensity_ttlIncentiveSteps 
				, ib.Intensity_ttlIncentiveBouts
				, ib.Tenacity_ttlIncentiveEarned
				, ib.Tenacity_ttlIncentiveSteps 
				, ib.Tenacity_ttlIncentiveBouts
		) a
join AllSavers_Prod..Dim_Member		dmbr	on	a.SystemID = dmbr.SystemID
join pdb_PharmaMotion..Member		mc		on dmbr.MemberID = mc.MemberID
--where mc.MemberID = 9668
--(210779 row(s) affected)
create unique index uIx_MemberID_YrMo on #fitgoalsincentives (MemberID, Year_Mo);

select * from #fitgoalsincentives

/*
select a.MemberID, d.YearMo
	, d.ttlIncentiveEarnedForMonth
	, Frequency_ttlIncentiveSteps	= d.ttlIncentiveSteps_Frequency
	, Frequency_ttlIncentiveBouts	= d.ttlIncentiveBouts_Frequency
	, Frequency_ttlIncentiveEarned	= d.ttlIncentiveEarned_Frequency
	, Intensity_ttlIncentiveSteps	= d.ttlIncentiveSteps_Intensity
	, Intensity_ttlIncentiveBouts	= d.ttlIncentiveBouts_Intensity
	, Intensity_ttlIncentiveEarned	= d.ttlIncentiveEarned_Intensity
	, Tenacity_ttlIncentiveSteps	= d.ttlIncentiveSteps_Tenacity
	, Tenacity_ttlIncentiveBouts	= d.ttlIncentiveBouts_Tenacity
	, Tenacity_ttlIncentiveEarned	= d.ttlIncentiveEarned_Tenacity
into #fitgoalsincentives
from pdb_PharmaMotion..Member							a
inner join AllSavers_Prod..Dim_Member					b	on	a.MemberID = b.MemberID
inner join pdb_Allsavers_Research..ASM_xwalk_Member		c	on	b.SystemID = c.SystemID
inner join pdb_Allsavers_Research..Longitudinal_Month	d	on	c.Member_DIMID = d.Member_DIMID
--(246923 row(s) affected)
create unique index uIx_MemberID_YrMo on #fitgoalsincentives (MemberID, YearMo);
*/


alter table pdb_PharmaMotion..MemberSummary_cont
	add	 ttlIncentiveEarnedForMonth		decimal(11,2)
		, Frequency_ttlIncentiveSteps	int
		, Frequency_ttlIncentiveBouts	int
		, Frequency_ttlIncentiveEarned	decimal(11,2)
		, Intensity_ttlIncentiveSteps	int
		, Intensity_ttlIncentiveBouts	int
		, Intensity_ttlIncentiveEarned	decimal(11,2)
		, Tenacity_ttlIncentiveSteps	int
		, Tenacity_ttlIncentiveBouts	int
		, Tenacity_ttlIncentiveEarned	decimal(11,2)
go

update pdb_PharmaMotion..MemberSummary_cont
set Step_Cnt = isnull(b.Step_Cnt, 0)
	, NoDays_wSteps	= isnull(b.NoDays_wSteps, 0)
	, ttlIncentiveEarnedForMonth	= isnull(b.ttlIncentiveEarnedForMonth,0)
	, Frequency_ttlIncentiveSteps	= isnull(b.Frequency_ttlIncentiveSteps	,0)
	, Frequency_ttlIncentiveBouts	= isnull(b.Frequency_ttlIncentiveBouts	,0)
	, Frequency_ttlIncentiveEarned	= isnull(b.Frequency_ttlIncentiveEarned	,0)
	, Intensity_ttlIncentiveSteps	= isnull(b.Intensity_ttlIncentiveSteps	,0)
	, Intensity_ttlIncentiveBouts	= isnull(b.Intensity_ttlIncentiveBouts	,0)
	, Intensity_ttlIncentiveEarned	= isnull(b.Intensity_ttlIncentiveEarned	,0)
	, Tenacity_ttlIncentiveSteps	= isnull(b.Tenacity_ttlIncentiveSteps	,0)
	, Tenacity_ttlIncentiveBouts	= isnull(b.Tenacity_ttlIncentiveBouts	,0)
	, Tenacity_ttlIncentiveEarned	= isnull(b.Tenacity_ttlIncentiveEarned	,0)
from pdb_PharmaMotion..MemberSummary_cont	a
left join #fitgoalsincentives				b	on	a.MemberID = b.MemberID
												and a.YearMo = b.Year_Mo

/*
select MemberID, YearMo, Enrl_Motion, Step_Cnt, NoDays_wSteps
	, ttlIncentiveEarnedForMonth
	, Frequency_ttlIncentiveSteps	
	, Frequency_ttlIncentiveBouts	
	, Frequency_ttlIncentiveEarned	
	, Intensity_ttlIncentiveSteps	
	, Intensity_ttlIncentiveBouts	
	, Intensity_ttlIncentiveEarned	
	, Tenacity_ttlIncentiveSteps	
	, Tenacity_ttlIncentiveBouts	
	, Tenacity_ttlIncentiveEarned
from pdb_PharmaMotion..MemberSummary_cont
where Enrl_Motion = 1
	--and ttlIncentiveEarnedForMonth > 0
	--and Step_Cnt = 0
	and MemberID = 267585	--9691
select MemberID, YearMo, Step_Cnt, NoDays_wSteps
from pdb_PharmaMotion..MemberSummary
where MemberID = 9691
*/

--motion month indicator
--Date: 15 May 2017
If (object_id('tempdb..#motion_monthind') Is Not Null)
Drop Table #motion_monthind
go

select b.MemberID, b.YearMo
	, EnrlMotion_MonthInd = case when a.Motion = 1	then datediff(mm, cast(a.EnrolledMotion_YrMo + '01' as date), cast(b.YearMo + '01' as date))	else 0	end
into #motion_monthind
from pdb_PharmaMotion..Member	a
inner join pdb_PharmaMotion..MemberSummary_cont	b	on	a.MemberID = b.MemberID
--where a.MemberID in (93419, 28052)
--(1823832 row(s) affected)
create unique index uIx_MemberID_YrMo on #motion_monthind (MemberID, YearMo);

alter table pdb_PharmaMotion..MemberSummary_cont
	add EnrlMotion_MonthInd	smallint
go

update pdb_PharmaMotion..MemberSummary_cont
set EnrlMotion_MonthInd = b.EnrlMotion_MonthInd
from pdb_PharmaMotion..MemberSummary_cont	a
inner join #motion_monthind					b	on	a.MemberID = b.MemberID
												and a.YearMo = b.YearMo


--add flags on those members whose policies belong to the 4 States ('PA', 'WI', 'DE', 'MO')
--Date: 16 May 2017
If (object_id('tempdb..#questionable_policies') Is Not Null)
Drop Table #questionable_policies
go

select *
into #questionable_policies
from [pdb_Allsavers_Research].[dbo].[GroupSummary]
where GroupState in ('PA', 'WI', 'DE', 'MO')
	and EnrolledMotionYM > 0
--(50 row(s) affected)
create unique index uIx_PolicyID on #questionable_policies (PolicyID);


--pull for the members under these policies
If (object_id('tempdb..#questionablembrs') Is Not Null)
Drop Table #questionablembrs
go

select c.MemberID, b.PolicyID	
into #questionablembrs
from #questionable_policies	a
inner join AllSavers_Prod..Dim_Member	b	on	a.PolicyID = b.PolicyID
inner join pdb_PharmaMotion..MemberSummary_cont	c	on	b.MemberID = c.MemberID
where Enrl_Motion = 1
	and Step_Cnt > 0
	and ttlIncentiveEarnedForMonth > 0
group by c.MemberID, b.PolicyID
--(461 row(s) affected)
create unique index uIx_MemberID_PolicyID on #questionablembrs (MemberID, PolicyID);

alter table pdb_PharmaMotion..Member
	add Flag_PolicyIDin4St smallint
go

update pdb_PharmaMotion..Member
set Flag_PolicyIDin4St = case when b.MemberID is not null	then	1 else 0	end
from pdb_PharmaMotion..Member	a
left join #questionablembrs		b	on	a.MemberID = b.MemberID


alter table pdb_PharmaMotion..MemberSummary_cont
	add Flag_PolicyIDin4St smallint
go

update pdb_PharmaMotion..MemberSummary_cont
set Flag_PolicyIDin4St = case when b.MemberID is not null	then	1 else 0	end
from pdb_PharmaMotion..MemberSummary_cont	a
left join #questionablembrs					b	on	a.MemberID = b.MemberID


--drop Cont_Enrl column
--date: 18 May 2017
alter table pdb_PharmaMotion..MemberSummary
	drop column cont_enrl
go