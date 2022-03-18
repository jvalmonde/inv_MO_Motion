USE pdb_Allsavers_Research;

-- In Allsavers Groups = Policies; develop the group level detail and summary

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'GroupDetailYY')
   drop table pdb_Allsavers_Research.dbo.GroupDetailYY;

CREATE TABLE dbo.GroupDetailYY (
	PolicyID           bigint,
	PolicyYear         int,
	GroupState         char(2),
	GroupZip           char(5),
	PolicyEffDate      date,
	PolicyEndDate      date,
	PolicyEffYearMo    int,
	PolicyEndYearMo    int,
	EnrolledMotionYM   int,
	EnrolledMotionMbr  int,
	EnrolledMotionMM   int,
	PolicyMM           int,
	Premium            decimal(15,2),
	Active             tinyint,
	RenewedPrior       tinyint,
	RenewedFollow      tinyint,
	EligibileEmployees smallint,
	EnrolledEmployees  smallint,
	EnrolledMembers    int,
	EnrolledMM         int,
	EnrolledPMPM       decimal(9,2),
    RX_AllwAmt         decimal(11,2),
    RX_PaidAmt         decimal(11,2),
    IP_AllwAmt         decimal(11,2),
    IP_PaidAmt         decimal(11,2),
    OP_AllwAmt         decimal(11,2),
    OP_PaidAmt         decimal(11,2),
    ER_AllwAmt         decimal(11,2),
    ER_PaidAmt         decimal(11,2),
    MD_AllwAmt         decimal(11,2),
    MD_PaidAmt         decimal(11,2),
    OtherAllwAmt       decimal(11,2),
    OtherPaidAmt       decimal(11,2),
    PaidAmt            decimal(11,2),
    AllwAmt            decimal(11,2),
	IP_Visits          int,
	IP_Days            int,
	OP_Visits          int,
	MD_Visits          int,
	ER_Visits          int,
	DateLastGeneration datetime
);

GO  -- reset the namespace

-- Stub out the group detail

with GroupBasis as (
select distinct p.PolicyID, p.YearMo
     , GroupState    = isnull(p.GroupState,'NA')  -- a small portion of policies
	 , GroupZip      = isnull(p.GroupZip,'NA')    -- do not exist in Quote
     , GroupName     = isnull(fq.GroupName,'NA')  -- or the Policy is partially null
     , PolicyYR      = p1.PolicyYR
     , PolicyEffDate = convert(date,d1.fulldt,126), PolicyEndDate = convert(date,d2.fulldt,126)
	 , PolicyEffYearMo = convert(int,d1.YearMo,0),  PolicyEndYearMo = convert(int,d2.YearMo,0)
	 , p.Premium
	 , p.EligibileEmployees, p.EnrolledEmployees, p.EnrolledMembers
  from (select distinct PolicyID from MemberSummary) pb
  join AllSavers_Prod..Dim_Policy (nolock)  p on p.PolicyID   = pb.PolicyID      -- filter to project policies
  join asm_yearmo                 (nolock) ym on p.YearMo     = ym.yearmo        -- filter to project months
  join AllSavers_Prod..Dim_Date   (nolock) d1 on p.MinDtSysId = d1.DtSysId
  join AllSavers_Prod..Dim_Date   (nolock) d2 on p.MaxDtSysId = d2.DtSysId
 cross apply (select PolicyYR = p0.YearMo/100 from AllSavers_Prod..Dim_Policy (nolock) p0
               where p0.PolicyID = p.PolicyID and p0.PolicyYear = p.PolicyYear
			     and p0.PolicyMonth = ((p.PolicyYear-1)*12)+1
			 ) p1
 outer apply (select distinct fq0.PolicyID, fq0.GroupName
                from AllSavers_Prod..Fact_Quote (nolock) fq0
			   where fq0.PolicyID = pb.PolicyID) fq
)

insert into GroupDetailYY
select a.PolicyID, a.PolicyYR, a.GroupState, a.GroupZip
     , PolicyEffDate      = min(a.PolicyEffDate)
	 , PolicyEndDate      = max(a.PolicyEndDate)
	 , PolicyEffYearMo    = min(a.PolicyEffYearMo)
	 , PolicyEndYearMo    = max(a.PolicyEndYearMo)
	 , EnrolledMotionYM   = 0
	 , EnrolledMotionMbr  = 0
	 , EnrolledMotionMM   = 0
	 , PolicyMM           = count(a.YearMo)
	 , Premium            = sum(a.Premium)
	 , Active             = cast(0 as tinyint)
	 , RenewPrior         = cast(0 as tinyint)
	 , RenewFollow        = cast(0 as tinyint)
	 , EligibileEmployees = avg(a.EligibileEmployees)
	 , EnrolledEmployees  = 0 --max(b.enrEmployees)
	 , EnrolledMembers    = 0 --max(b.enrMembers)
	 , EnrolledMM         = 0 --sum(a.EnrolledMembers) --* Count(a.YearMO)
	 , EnrolledPMPM       = cast(0.0 as decimal(9,2)) --sum(a.Premium) / (sum(a.EnrolledMembers)) -- * Count(a.YearMO))
     , RX_AllwAmt         = cast(0.0 as decimal(11,2))
     , RX_PaidAmt         = cast(0.0 as decimal(11,2))
     , IP_AllwAmt         = cast(0.0 as decimal(11,2))
     , IP_PaidAmt         = cast(0.0 as decimal(11,2))
     , OP_AllwAmt         = cast(0.0 as decimal(11,2))
     , OP_PaidAmt         = cast(0.0 as decimal(11,2))
     , ER_AllwAmt         = cast(0.0 as decimal(11,2))
     , ER_PaidAmt         = cast(0.0 as decimal(11,2))
     , MD_AllwAmt         = cast(0.0 as decimal(11,2))
     , MD_PaidAmt         = cast(0.0 as decimal(11,2))
     , OtherAllwAmt       = cast(0.0 as decimal(11,2))
     , OtherPaidAmt       = cast(0.0 as decimal(11,2))
     , PaidAmt            = cast(0.0 as decimal(11,2))
     , AllwAmt            = cast(0.0 as decimal(11,2))
	 , IP_Visits          = 0
	 , IP_Days            = 0
	 , OP_Visits          = 0
	 , MD_Visits          = 0
	 , ER_Visits          = 0
	 , DateLastGeneration = GETDATE()
  from GroupBasis a
  left join (select pb.PolicyID, pb.PolicyYR, enrEmployees = count(distinct case when md.Sbscr_Ind = 1 then md.SystemID else null end)
                                 , enrMembers   = count(distinct case when md.InsuredFlag = 1 then md.SystemID else null end)
               from GroupBasis                       pb
               join AllSavers_Prod..Dim_MemberDetail md on pb.PolicyID = md.PolicyID
                                                       and md.YearMo between pb.PolicyEffYearMo and pb.PolicyEndYearMo
              group by pb.PolicyID, pb.PolicyYR
			) b on a.PolicyID = b.PolicyID and a.PolicyYR = b.PolicyYR
 group by a.PolicyID, a.PolicyYR, a.GroupState, a.GroupZip
;

create clustered index ucix_PolicyID on GroupDetailYY (PolicyID);

-- update active flags

declare @maxPolicyYear int = (select max(PolicyYear) from GroupDetailYY);

update yy
   set Active        = case when yy.PolicyYear = @maxPolicyYear then 1 else 0 end
     , RenewedPrior  = case when isnull(past.PolicyID,0) > 0 then 1 else 0 end
     , RenewedFollow = case when isnull(future.PolicyID,0) > 0 then 1 else 0 end
  from GroupDetailYY yy
 outer apply(select PolicyID, PolicyYear
               from GroupDetailYY (nolock) 
			  where PolicyID   = yy.PolicyID and PolicyYear = yy.PolicyYear - 1
			) past
 outer apply(select PolicyID, PolicyYear
               from GroupDetailYY (nolock) 
			  where PolicyID   = yy.PolicyID and PolicyYear = yy.PolicyYear + 1
			) future
;

-- and another wash through to set the member levels and MM / PMPM basis the MemberDetail
-- Note: the member levels in dim_Policy are basis Fact_Quote, not MemberDetail

update a
   set EnrolledEmployees = b.enrEmployees
     , EligibileEmployees = case when EligibileEmployees < b.enrEmployees then b.enrEmployees else EligibileEmployees end
     , EnrolledMembers   = b.enrMembers
	 , EnrolledMM        = b.enrMM
	 , EnrolledPMPM      = round(a.Premium / b.enrMM,2)
  from pdb_Allsavers_Research..GroupDetailYY a
  join (select gd.PolicyID, gd.PolicyYeaR
             , enrEmployees = count(distinct case when md.Sbscr_Ind = 1 then md.SystemID else null end)
             , enrMembers   = count(distinct case when md.InsuredFlag = 1 then md.SystemID else null end)
			 , enrMM        = count(distinct convert(varchar(20),md.SystemID)+convert(varchar(6),md.YearMo))
          from pdb_Allsavers_Research..GroupDetailYY (nolock) gd
          join AllSavers_Prod..Dim_MemberDetail md on gd.PolicyID = md.PolicyID
                                                  and md.YearMo between gd.PolicyEffYearMo and gd.PolicyEndYearMo
         group by gd.PolicyID, gd.PolicyYeaR
	) b on a.PolicyID = b.PolicyID and a.PolicyYear = b.PolicyYear
;
go -- reset namespace

-- update the motion related columns
--      [requires the derm data to be resident and xwalk to be built]

update yy  -- first off, extract the motion enrollment YM for the group
   set EnrolledMotionYM = isnull(a.StartYearmo,0)
  from GroupDetailYY yy
  left join ETL.AS_DERM_RuleGroups a on yy.PolicyID = a.policyid
;

-- now, the bigger fish; get members and MM [this is messy]

if object_id(N'tempdb..#GroupMotion') is not null
   drop table #GroupMotion;

declare @MonthEnd date    = (select max(FullDt) from allsavers_prod..dim_date
                              where YearNbr = year(getdate()) and MonthNbr = month(getdate()));

with mbrBasis as (  -- only working with those folks we can xwalk
SELECT a.Memberid, a.StartDate, EndDate = isnull(a.EndDate,@MonthEnd), PolicyID = left(m.ClientMEMBERID,10)
  FROM ETL.AS_DERM_MemberEnrollment a
  join ETL.AS_DERM_Members          m on a.memberid = m.memberid             -- use
  join etl.DERM_xwalk_Member        x on m.ClientMemberID = x.ClientMemberID -- to filter out
                                     and x.aSystemID <> 0                    -- the unidentified
-- order by 1
),   expandIT as (  -- blow up the dates to a simulated MM countable item, but only for months in policy
select distinct a.MemberID, a.PolicyID, dt.YearMo, p1.PolicyYr
  from mbrBasis                            a                                                 -- begin w basis
  join allsavers_prod..dim_date           dt on dt.FullDt between a.StartDate and a.EndDate  -- expand it
  join AllSavers_Prod..Dim_Policy (nolock) p on a.PolicyID = p.PolicyID and p.YearMo = dt.YearMo -- controlled expansion
 cross apply (select PolicyYR = p0.YearMo/100 from AllSavers_Prod..Dim_Policy (nolock) p0    -- figures out
               where p0.PolicyID = p.PolicyID and p0.PolicyYear = p.PolicyYear               -- the proper
			     and p0.PolicyMonth = ((p.PolicyYear-1)*12)+1                                -- policy year
			 ) p1
)

select *
  into #GroupMotion  -- saving for groupsummary
  from expandIT
;
create           index ucix_PolicyID on #GroupMotion (PolicyID);

--TP:  select count(distinct MemberID) from #GroupMotion  where memberid = 11199--top 100 *

with synthesizeIT as (  -- now synthesize to policy and year in prep for update
select z.PolicyID, z.PolicyYr, Mbrs=count(distinct z.MemberID), MM = sum(z.MM)
  from (
select a.PolicyID, a.MemberID, a.PolicyYr, MM = count(a.YearMO)
  from #GroupMotion a
 group by a.PolicyID, a.MemberID, a.PolicyYr
       ) z
 group by z.PolicyID, z.PolicyYr
)

/* test point to validate input into update
select * 
  from synthesizeIT a
--  left join GroupDetailYY yy on yy.PolicyID = a.policyid and yy.PolicyYear = a.PolicyYr
-- where yy.PolicyID is null
 order by 1,2
*/

update yy  -- whew!
   set EnrolledMotionMbr = a.Mbrs
     , EnrolledMotionMM  = a.MM
  from GroupDetailYY yy
  join synthesizeIT   a on yy.PolicyID = a.policyid and yy.PolicyYear = a.PolicyYr
;

-- and update the membersummary from the groupmotion notion
-- gets different results from the similar notion in membersummary, which is strictly
-- member enrollment based  ** anomally alert as to why ***

update ms
   set EnrolledMotion = case when isnull(me.MemberID,0) = 0 then 0 else 1 end
  from pdb_Allsavers_Research..MemberSummary                 ms
  join pdb_Allsavers_Research..ASM_xwalk_Member     (nolock) ax on ms.member_dimid   = ax.member_dimid   -- DIMID
  join pdb_Allsavers_Research.etl.DERM_xwalk_Member (nolock) dx on ax.SystemID       = dx.aSystemID      -- xwalk to
  join pdb_Allsavers_Research.etl.AS_DERM_Members   (nolock) dm on dx.ClientMemberid = dm.clientMEMBERID -- Memberid
  left join #GroupMotion (nolock) me on dm.MemberID = me.MemberID
;


--- update claim utilization columns [essentially, a clone of claimsdetailyy logic with a few grouping changes]

if object_id(N'tempdb..#CLMGroups') is not null
   drop table #CLMGroups;

select distinct --top 100
       yy.PolicyID, yy.PolicyYear, EffDtSysID = d1.DtSysId, EndDtSysID = d2.DtSysId
     , xm.SystemID
  into #CLMGroups
  from MemberSummary            ms
  join ASM_xwalk_Member         xm on ms.Member_DIMID = xm.Member_DIMID
  join GroupDetailYY            yy on ms.PolicyID = yy.PolicyID
  join AllSavers_Prod..Dim_Date d1 on yy.PolicyEffDate = d1.FullDt
  join AllSavers_Prod..Dim_Date d2 on yy.PolicyEndDate = d2.FullDt
;

create clustered index ucix_SystemID on #CLMGroups (SystemID);
create           index ucix_PolicyID on #CLMGroups (PolicyID);

--TP: select top 100 * from #CLMGroups

update yy
   set RX_AllwAmt   = clm.RX_AllwAmt, RX_PaidAmt     = clm.RX_PaidAmt  
     , IP_AllwAmt   = clm.IP_AllwAmt, IP_PaidAmt     = clm.IP_PaidAmt 
     , OP_AllwAmt   = clm.OP_AllwAmt, OP_PaidAmt     = clm.OP_PaidAmt
	 , ER_AllwAmt   = clm.ER_AllwAmt, ER_PaidAmt     = clm.ER_PaidAmt
     , MD_AllwAmt   = clm.MD_AllwAmt, MD_PaidAmt     = clm.MD_PaidAmt
     , OtherAllwAmt = clm.OtherAllwAmt, OtherPaidAmt = clm.OtherPaidAmt
     , PaidAmt      = clm.PaidAmt, AllwAmt           = clm.AllwAmt
	 , IP_Visits    = clm.IP_Visits, IP_Days         = clm.IP_Days
	 , OP_Visits    = clm.OP_Visits
	 , MD_Visits    = clm.MD_Visits
	 , ER_Visits    = clm.ER_Visits
  from GroupDetailYY yy
  join (
SELECT cg.PolicyID, cg.PolicyYear
     , RX_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Pharmacy'   then AllwAmt else 0 end)
     , RX_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Pharmacy'   then PaidAmt else 0 end)
     , IP_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then AllwAmt else 0 end)
     , IP_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then PaidAmt else 0 end)
     , OP_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService <> '23'         then AllwAmt else 0 end
								 else 0 end)
     , OP_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService <> '23'         then PaidAmt else 0 end
								 else 0 end)
     , ER_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient'
	                             then case when PlaceOfService = '23'          then AllwAmt else 0 end
								 else 0 end)
     , ER_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService = '23'          then PaidAmt else 0 end
					             else 0 end)
     , MD_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Physician'  then AllwAmt else 0 end)
     , MD_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Physician'  then PaidAmt else 0 end)
     , OtherAllwAmt        = Sum(Case when st.ServiceTypeDescription Not in ('Pharmacy','Inpatient','Outpatient','Physician') then AllwAmt else 0 end )
     , OtherPaidAmt        = Sum(Case when st.ServiceTypeDescription Not in ('Pharmacy','Inpatient','Outpatient','Physician') then PaidAmt else 0 end)
     , PaidAmt             = SUM(isnull(fc.PaidAmt,0))
     , AllwAmt             = SUM(isnull(fc.AllwAmt,0))
     , IP_Visits           = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then AdmitCnt else 0 end)
     , IP_Days             = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then DayCnt  else 0 end)
     , OP_Visits           = Sum(Case when st.ServiceTypeDescription = 'Outpatient' then VisitCnt else 0 end)
     , MD_Visits           = Sum(Case when st.ServiceTypeDescription = 'Physician'  then VisitCnt else 0 end)
     , ER_Visits           = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                                  then case when PlaceOfService = '23' then VisitCnt else 0 end
									  else 0 end)
  FROM #CLMGroups                                      cg
  JOIN allsavers_Prod.dbo.Fact_Claims         (nolock) fc on cg.SystemID = fc.SystemID
                                                         and fc.FromDtSysID between cg.EffDtSysID and cg.EndDtSysID
  join  allsavers_prod.dbo.Dim_ServiceType    (nolock) st on fc.ServiceTypeSysID = st.ServiceTypeSysID
 Group by cg.PolicyID, cg.PolicyYear
       ) clm on yy.PolicyID = clm.PolicyID and yy.PolicyYear = clm.PolicyYear
;

-- GroupSummary is a Policy summarization (roll up) of all project years

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'GroupSummary')
   drop table pdb_Allsavers_Research.dbo.GroupSummary;

declare @maxPolicyYear int = (select max(PolicyYear) from GroupDetailYY);

with GroupActive as (
select PolicyID, Active
  from GroupDetailYY (nolock)
 where PolicyYear = @maxPolicyYear
)

select yy.PolicyID
     , GroupName          = max(fq.GroupName)
	 , GroupState         = max(yy.GroupState)
	 , GroupZip           = max(yy.GroupZip)
     , Active             = max(isnull(ga.Active,0))
     , PolicyEffDate      = min(yy.PolicyEffDate)
	 , PolicyEndDate      = max(yy.PolicyEndDate)
	 , PolicyMM           = sum(yy.policymm)
	 , EnrolledMotionYM   = max(yy.EnrolledMotionYM)
	 , YearsInMotionPgm   = max(gd.YearsInMotionPgm)
	 , EnrolledMotionMbr  = max(gm.Mbrs)
	 , EnrolledMotionMM   = max(gd.EnrolledMotionMM)
     , RX_AllwAmt         = sum(yy.RX_AllwAmt)
     , RX_PaidAmt         = sum(yy.RX_PaidAmt)
     , IP_AllwAmt         = sum(yy.IP_AllwAmt) 
     , IP_PaidAmt         = sum(yy.IP_PaidAmt)
     , OP_AllwAmt         = sum(yy.OP_AllwAmt)
     , OP_PaidAmt         = sum(yy.OP_PaidAmt)
     , ER_AllwAmt         = sum(yy.ER_AllwAmt)
     , ER_PaidAmt         = sum(yy.ER_PaidAmt)
     , MD_AllwAmt         = sum(yy.MD_AllwAmt)
     , MD_PaidAmt         = sum(yy.MD_PaidAmt)
     , OtherAllwAmt       = sum(yy.OtherAllwAmt)
     , OtherPaidAmt       = sum(yy.OtherPaidAmt)
     , PaidAmt            = sum(yy.PaidAmt)
     , AllwAmt            = sum(yy.AllwAmt)
     , IP_Visits          = Sum(yy.IP_Visits)
     , IP_Days            = Sum(yy.IP_Days)
     , OP_Visits          = Sum(yy.OP_Visits)
     , MD_Visits          = Sum(yy.MD_Visits)
     , ER_Visits          = Sum(yy.ER_Visits)
	 , DateLastGeneration = GETDATE()
  into GroupSummary
  from GroupDetailYY  (nolock)   yy
 cross apply (select YearsInMotionPgm   = sum(case when y0.EnrolledMotionMbr > 0 then 1 else 0 end)
                   , EnrolledMotionMM   = sum(y0.EnrolledMotionMM)
                from GroupDetailYY  (nolock)   y0
			   where yy.PolicyID = y0.PolicyID
			 ) gd
  left join AllSavers_Prod..Fact_Quote fq on yy.PolicyID = fq.PolicyID
  left join groupActive  ga on yy.PolicyID = ga.PolicyID
 outer apply (select Mbrs = count(distinct g0.Memberid)
                from #GroupMotion g0 
			   where yy.PolicyID = g0.PolicyID
			 ) gm
 group by yy.PolicyID
;

create clustered index ucix_PolicyID on GroupSummary (PolicyID);
