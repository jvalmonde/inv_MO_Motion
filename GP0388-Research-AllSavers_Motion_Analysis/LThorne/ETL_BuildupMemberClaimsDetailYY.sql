use pdb_Allsavers_Research;

-- Claims detail is part of the story to the Aggregated Claims for a member

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'MemberClaimDetailYY')
   drop table pdb_Allsavers_Research.dbo.MemberClaimDetailYY;

CREATE TABLE dbo.MemberClaimDetailYY(
	Member_DIMID       varchar(32),
	PolicyYear         int,
	[Year]             int,
	MM_Year            int,
	MM_Total           int,
	RAF                decimal(7,3),
	RX_AllwAmt         decimal(11, 2),
	RX_PaidAmt         decimal(11, 2),
	IP_AllwAmt         decimal(11, 2),
	IP_PaidAmt         decimal(11, 2),
	OP_AllwAmt         decimal(11, 2),
	OP_PaidAmt         decimal(11, 2),
	ER_AllwAmt         decimal(11, 2),
	ER_PaidAmt         decimal(11, 2),
	MD_AllwAmt         decimal(11, 2),
	MD_PaidAmt         decimal(11, 2),
	OtherAllwAmt       decimal(11, 2),
	OtherPaidAmt       decimal(11, 2),
	PaidAmt            decimal(11, 2),
	AllwAmt            decimal(11, 2),
	IP_Visits          int,
	IP_Days            int,
	OP_Visits          int,
	MD_Visits          int,
	ER_Visits          int,
	DateLastGeneration datetime
);

go  -- reset namespace

-- Establish Member / PolicyYear time basis  for this process
-- This table is at the member level with policy year defined for the member

if object_id(N'tempdb..#mbrBasis') is not null
   drop table #mbrBasis;

declare @minYearMo int = (select min(YearMo) from pdb_Allsavers_Research..ASM_YearMo);
declare @maxYearMo int = (select max(YearMo) from pdb_Allsavers_Research..ASM_YearMo);

SELECT distinct ms.Member_DIMID
	 , PolicyYear = p1.PolicyYR, md.YearMo, dp.MinDtSysID, dp.MaxDtSysID
  into #mbrBasis
  FROM MemberSummary                       ms
  join ASM_xwalk_Member                    xm on ms.Member_DIMID = xm.Member_DIMID           -- filter on the member basis for project
  join AllSavers_Prod..Dim_MemberDetail    md on xm.SystemID     = md.SystemID and isnull(md.PolicyID,0) > 0
                                             and md.YearMo between @minYearMo and @maxYearMo -- must have a policy, and for the YearMo
  join ASM_YearMo                          ym on md.YearMo       = ym.YearMo                 -- filter on the YearMo spread for project
  join AllSavers_Prod..Dim_Policy          dp on ms.PolicyID     = dp.PolicyID and md.yearmo = dp.yearmo
 cross apply (select PolicyYR = p0.YearMo/100, p0.MinDtSysID, p0.MaxDtSysID        -- this is replicated code used in other
                from AllSavers_Prod..Dim_Policy (nolock) p0                        -- places in these processes
               where p0.PolicyID = dp.PolicyID and p0.PolicyYear = dp.PolicyYear   -- so, if make change, be sure to
			     and p0.PolicyMonth = ((dp.PolicyYear-1)*12)+1                     -- replicate, replicate, replicate ..
			 ) p1
 order by 1,2,3
;
create clustered index ucix_Member_DIMID on #mbrBasis (Member_DIMID);

--TP: select top 100 * from #mbrBasis order by 1,2,3

-- Stub out the table; will fill in later step

insert into pdb_Allsavers_Research.dbo.MemberClaimDetailYY
select mb.Member_DIMID, mb.PolicyYear
	 , [Year]             = cast(0 as tinyint)
	 , MM_Year            = count(mb.YearMo)
	 , MM_Total           = 0
	 , RAF                = 0.0
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
  from #mbrBasis mb
 group by mb.Member_DIMID, mb.PolicyYear
order by 1,2
;

create clustered index ucix_Member_DIMID on pdb_Allsavers_Research.dbo.MemberClaimDetailYY (Member_DIMID);

--  OK, now time to fill the table in with details for the members policy year time window

if object_id(N'tempdb..#CLMMembers') is not null
   drop table #CLMMembers;

select distinct --top 100         -- intermediate catalyst table 
       yy.Member_DIMID, yy.PolicyYear, EffDtSysID = mb.MinDtSysId, EndDtSysID = mb.MaxDtSysID
     , xm.SystemID
  into #CLMMembers
  from MemberClaimDetailYY      yy
  join (select distinct Member_DIMID, PolicyYear
             , MinDtSysId = min(MinDtSysID)
			 , MaxDtSysID = max(MaxDtSysID)
          from #mbrBasis
		 group by Member_DIMID, PolicyYear
	   )                        mb on yy.Member_DIMID = mb.Member_DIMID
		                          and yy.PolicyYear   = mb.PolicyYear
  join ASM_xwalk_Member         xm on yy.Member_DIMID = xm.Member_DIMID
;

create clustered index ucix_SystemID on #CLMMembers (SystemID);
create           index ucix_DIMID    on #CLMMembers (Member_DIMID);

--TP: select top 100 * from #CLMMembers order by 1,2

-- Using the member basis catalyst table, update the various buckets with 
-- the good stuff.
-- This step, or a very close derivation thereof, is used in many processes
-- for this project; so, be forwarned matey, you change it, you own it, 
-- and you must change it everywhere as appropriate.

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
  from MemberClaimDetailYY yy
  join (
SELECT cg.Member_DIMID, cg.PolicyYear
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
     , OtherAllwAmt   = Sum(Case when st.ServiceTypeDescription Not in ('Pharmacy','Inpatient','Outpatient','Physician') then AllwAmt else 0 end )
     , OtherPaidAmt   = Sum(Case when st.ServiceTypeDescription Not in ('Pharmacy','Inpatient','Outpatient','Physician') then PaidAmt else 0 end)
     , PaidAmt        = SUM(isnull(fc.PaidAmt,0))
     , AllwAmt        = SUM(isnull(fc.AllwAmt,0))
     , IP_Visits      = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then AdmitCnt else 0 end)
     , IP_Days        = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then DayCnt  else 0 end)
     , OP_Visits      = Sum(Case when st.ServiceTypeDescription = 'Outpatient' then VisitCnt else 0 end)
     , MD_Visits      = Sum(Case when st.ServiceTypeDescription = 'Physician'  then VisitCnt else 0 end)
     , ER_Visits      = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService = '23' then VisitCnt else 0 end
					             else 0 end)
  FROM #CLMMembers                                     cg
  JOIN allsavers_Prod.dbo.Fact_Claims         (nolock) fc on cg.SystemID = fc.SystemID
                                                         and fc.FromDtSysID between cg.EffDtSysID and cg.EndDtSysID
  join  allsavers_prod.dbo.Dim_ServiceType    (nolock) st on fc.ServiceTypeSysID = st.ServiceTypeSysID
 Group by cg.Member_DIMID, cg.PolicyYear
       ) clm on yy.Member_DIMID = clm.Member_DIMID and yy.PolicyYear = clm.PolicyYear
;
