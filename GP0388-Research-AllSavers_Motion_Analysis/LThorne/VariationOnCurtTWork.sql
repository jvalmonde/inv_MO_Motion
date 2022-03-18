/****
Project Name : All Savers Motion Program Analysis Data Specification
Date Created: 03.03.2016

INPUT TABLES:
AllSavers_Prod..Fact_Quote		-- contains details of each employer group and quote combinations with other associated information
AllSavers_Prod..Dim_Policy		-- contains records for each unique Policy and related information
DERMSL_Prod..LOOKUPRuleGroup	-- Devqlsql14: contains details related to an employer group
DERMSL_Prod..MEMBERSignupData	-- table for eligible members for ALS Motion
DERMSL_Prod..MEMBER				-- table for enrolled members of ALS Motion
AllSavers_Prod..Dim_MemberDetail -- table for member per year and month that the individual is covered
AllSavers_Prod..Dim_Member		-- contains detailed demographics and member reporting


OUTPUT TABLES:
pdb_HealthcareResearch..ALSMotion				-- employer groups enrolled in ALS Motion program extracted from DEVSQL14
pdb_HealthcareResearch..ALSMotion_Groups		-- final employer group table
pdb_HealthcareResearch..ALSMotion_MemberTable	-- final Member table
pdb_HealthcareResearch..ALSMotion_DiagTable		-- final Diagnosis table
****/


-- DATA SET A.1: ALL SAVERS EMPLOYER GROUPS

-- All Groups participating in any All Savers Health Plan for at least one year that started 04/01/2016
-- Check #Groups for continuous enrollment
-- Table 1: #Groups
-- Curt's logic on YearMo to build YearMo table


if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'ASM_YearMo')
   drop table pdb_Allsavers_Research.dbo.ASM_YearMo;

create table  pdb_Allsavers_Research..ASM_YearMo (OrderID int identity(1,1), YearMo char(6));

insert into pdb_Allsavers_Research..ASM_YearMo (YearMo)
                             values  ('201401')
                                    ,('201402')
									,('201403')
									,('201404')
									,('201405')
									,('201406')
									,('201407')
									,('201408')
									,('201409')
									,('201410')
									,('201411')
									,('201412')
									,('201501')
									,('201502')
									,('201503')
									,('201504')
									,('201505')
									,('201506')
									,('201507')
									,('201508')
									,('201509')
									,('201510')
									,('201511')
									,('201512')
									,('201601')
									,('201602')
									,('201603')
									,('201604')
									,('201605')
									,('201606')
									,('201607')
									,('201608')
									,('201609')
									,('201610')
									,('201611')
									,('201612')
;									
create unique clustered index ucix_yearmo on pdb_Allsavers_Research..ASM_YearMo (YearMo);
select * from pdb_Allsavers_Research..ASM_YearMo									
;

-----

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'ASM_xwalk_Member')
   drop table pdb_Allsavers_Research.dbo.ASM_xwalk_Member;

with mbrBasis as (
select distinct md.MemberID
  from AllSavers_Prod..Dim_MemberDetail   md
  join pdb_Allsavers_Research..ASM_YearMo ym on md.YearMo = ym.YearMo
 where isnull(md.PolicyID,0) > 0                                                      -- must have a policy
)

select --top 1000
       Member_Hash  = cast(hashbytes('MD5',SSN+cast(birthdate as varchar(10))) as binary(16))
     , Member_DIMID = convert(varchar(32), cast(hashbytes('MD5',SSN+cast(birthdate as varchar(10))) as binary(16)),2)
	 , SystemID
  into pdb_Allsavers_Research..ASM_xwalk_Member
  FROM mbrBasis                   mb
  join AllSavers_Prod..Dim_Member  m on mb.MemberID = m.MemberID
                                    and m.MemberID > 0
;
create clustered index ucix_SID   on pdb_Allsavers_Research..ASM_xwalk_Member (SystemID);
create           index ucix_Hash  on pdb_Allsavers_Research..ASM_xwalk_Member (Member_Hash);
create           index ucix_DIMID on pdb_Allsavers_Research..ASM_xwalk_Member (Member_DIMID);
;
----


if object_id(N'tempdb..#Groups') is not null
   drop table #Groups

select OID = row_number() over (partition by PolicyID order by YearMo)
	, PolicyID = left(PolicyID,4 ) + '-'+  right(PolicyID, 4)
	, YearMo
into #Groups
from AllSavers_Prod..Dim_Policy
where YearMo   >= (Select min(YearMo) from #yearmo)
	and YearMo <= (select max(YearMo) from #yearmo)
	and  PolicyID is not null
;

-- check for groups with skips in YearMo

select a.PolicyID, a.YearMo as YearMOGroup, b.YearMo as YearMoDT
	 , flag = case when a.YearMo = b.YearMo then 1 else 0 end
  into #CheckGroup
  from #Groups		as a
  left join #yearmo as b on a.YearMo = b.YearMo

select *
from #CheckGroup
where flag = 0
order by PolicyID, YearMoDT  
-- (14497 row(s) affected)
-- employer groups with YearMo >= 201512; Initial assumption is to pull groups within 042014 to 201511 YearMos only


--PULL FOR THE EMPLOYER GROUPS

if object_id(N'tempdb..#ALSGroups') is not null
   drop table #ALSGroups

select a.PolicyID
	, BeginYearMo = max(case when OID = 1 then a.YearMo end)
	, EndYearMO   = max(case when OID = 12 then a.YearMo end)
--into #ALSGroups
from ( select OID = row_number() over (partition by PolicyID order by YearMo)
            , PolicyID = left(PolicyID,4 ) + '-'+  right(PolicyID, 4)
            , YearMo
         from AllSavers_Prod..Dim_Policy
        where YearMo   >= (Select min(YearMo) from #yearmo)
          and YearMo <= (select max(YearMo) from #yearmo)
          and  PolicyID is not null
        group by PolicyID, YearMo
	) as a
group by a.PolicyID
having count(distinct OID) >= 12
-- (2202 row(s) affected)



-- identify Original Group Effective Date and eligible, enrolled members
if object_id('pdb_AllSaversResearch..ALSGroups') is not null
drop table pdb_AllSaversResearch..ALSGroups

select a.PolicyID
	, a.BeginYearMo
	, a.EndYearMO
	, a.EnrolledEmployees
	, a.EligibleCnt
	, a.Group_EffDate
	, a.NewGroupGlag
into pdb_AllSaversResearch..ALSGroups
from 
	(
			select oid = row_number() over (partition by b.policyid order by c.eligiblecnt desc)
				, b.PolicyID
				, b.BeginYearMo
				, b.EndYearMO
				, a.EnrolledEmployees
				, c.EligibleCnt
				, d.Group_EffDate
				, NewGroupGlag = case when year(d.Group_EffDate) = left(b.BeginYearMo, 4) then 1 else 0 end
			from AllSavers_Prod..Dim_Policy									as a
			inner join #ALSGroups											as b on left(a.PolicyID,4 ) + '-'+  right(a.PolicyID, 4) = b.PolicyID
																					and a.YearMo = b.BeginYearMo	
			inner join	
					( select distinct PolicyID, employergroupid, EligibleCnt
					  from AllSavers_Prod..Fact_Quote	)					as c on  a.PolicyID = c.PolicyID
			inner join 
				( select PolicyID
					, GroupName
					, Group_EffDate = min(EffectiveDate)
				  from AllSavers_Prod..Fact_Quote	
				  where PolicyID is not null
				  group by PolicyID, GroupName
				 )															as d on a.PolicyID = d.PolicyID
	 
			where a.YearMo between b.BeginYearMo and b.EndYearMo
			group by b.PolicyID
				, b.BeginYearMo
				, b.EndYearMO
				, a.EnrolledEmployees
				, c.EligibleCnt
				, d.Group_EffDate
			
	) as a
where a.oid = 1

--(2196 row(s) affected)

create unique clustered index ucix_PolicyID on pdb_AllSaversResearch..ALSGroups (PolicyID)
select * from pdb_AllSaversResearch..ALSGroups

/****
-- QUICK CHECK
select *
from DERMSL_Prod..LookupTenant
where TenantName = 'Trio Motion'
-- Result: LOOKUPTenantID = 9 

select * 
from DERMSL_Prod..LOOKUPClient
where LOOKUPTenantID = 9 
and ClientName = 'All Savers Motion'
-- Result: LOOKUPClientID = 50
****/

-- Table 2: DERMSL ALS Motion Groups
-- Pull for ALS Motion Groups to be used to identify if employers identified in #MM_Groups table are participating in the Motion Program.
if object_id('pdb_DermResearch..ALSMotion') is not null
drop table pdb_DermResearch..ALSMotion
select a.*
into pdb_DermResearch..ALSMotion
from 
		(
		select distinct OID = ROW_NUMBER() over (partition by a.LookupRuleGroupid order by enddate asc)
			, a.LOOKUPRuleGroupID
			, a.RuleGroupName
			, a.OfferCode
			, b.StartDate
			, b.EndDate
			, Elig_Members = count(distinct c.ClientMEMBERID)
			, Enroll_Members = count(distinct d.ClientMemberID)
		--into pdb_DermResearch..ALSMotion
		from DERMSL_Prod..LOOKUPRuleGroup			as a
		inner join DERMSL_Prod..LOOKUPRule			as b on a.LOOKUPRuleGroupID = b.LOOKUPRuleGroupID
		inner join DERMSL_Prod..MEMBERSignupData	as c on b.LOOKUPRuleGroupID = c.LOOKUPRuleGroupID
		left join DERMSL_Prod..MEMBER				as d on c.ClientMEMBERID = d.ClientMEMBERID
														and c.LOOKUPClientID = d.LOOKUPClientID
		where a.LOOKUPClientID = 50
			and a.OfferCode <> ''  -- PolicyID
		group by  a.LOOKUPRuleGroupID
			, a.RuleGroupName
			, a.OfferCode
			, b.StartDate
			, b.EndDate
		) as a
where OID = 1
--(3193 row(s) affected)

-- Table 2 transfer to devsql10.pdb_AllSaversResearch

-- drop table pdb_AllsaversResearch..ALSMotion
-- 

/**** FINAL EMPLOYER TABLE ******/

if object_id('pdb_AllSaversResearch..ALSGroup_Table') is not null
drop table pdb_AllSaversResearch..ALSGroup_Table

Select  a.PolicyID
	, a.Group_EffDate
	, MotionProgramStartDt 
	, MotionProgramEndDt
	, ShareOfEligibleBeneficiaries
	, NewGroupGlag
into pdb_AllSaversResearch..ALSGroup_Table
from (
		select OID = row_number () over (partition by a.PolicyID order by a.Group_EffDate)
			, a.PolicyID
			, a.Group_EffDate
			, MotionProgramStartDt = b.StartDate
			, MotionProgramEndDt = b.EndDate
			, ShareOfEligibleBeneficiaries = case when b.StartDate is null then a.EnrolledEmployees * 1.0 / a.EligibleCnt
												  else b.Enroll_Members *1.0 / b.Elig_Members
											  end
			, a.NewGroupGlag
		from pdb_AllSaversResearch..ALSGroups		as a
		left join pdb_AllsaversResearch..ALSMotion	as b on a.PolicyID = b.OfferCode
	  ) as a
where a.OID = 1
--(2196 row(s) affected)

create unique index uIx_Id on pdb_AllSaversResearch..ALSGroup_Table (PolicyID)		    


--select * from pdb_AllSaversResearch..ALSGroup_Table
--where policyid = '5400-2132'


-- DATA SET A.2: ALL SAVERS INDIVIDUAL FROM A.1  (FOR REVISION)

-- Identify Members in employer groups in pdb_HealthcareResearch..ALSMotion_Groups that were enrolled for the entire 1st yr
if object_id('tempdb..#MM_Members') is not null
drop table #MM_Members

select c.MemberID
	, a.PolicyID
	, count(c.YearMo) as Mm_Mbrs
into #MM_Members
from pdb_HealthcareResearch..ALSGroup_Table						as a
inner join pdb_AllSaversResearch..ALSGroups						as b on a.PolicyID = b.PolicyID
inner join 
		( select MemberID, YearMo, PolicyID
		  from AllSavers_Prod..Dim_MemberDetail
		  where PolicyID is not null and PolicyID <> 0)			as c  on b.PolicyID = left(c.PolicyID,4 ) + '-'+  right(c.PolicyID, 4)
where  c.YearMo between b.BeginYearMo and b.EndYearMo
group by c.MemberID
	, a.PolicyID 
having count(c.YearMo) = 12    -- enrolled for the entire 1st yr of ALS coverage
-- (53207 row(s) affected)

-- Member table

if object_id('tempdb..#MemberTable') is not null
drop table #MemberTable

select Distinct UniqueMemberID = b.MemberID
	, b.PolicyID
	, GenderCd = c.Gender
	, BirthDate = c.BirthDate
	, AgeLast = datediff( yy, c.BirthDate, getdate())
into #MemberTable
from pdb_HealthcareResearch..ALSGroup_Table			as a
inner join #MM_Members								as b on a.PolicyID = b.PolicyID
inner join AllSavers_Prod..Dim_Member				as c on b.MemberID = c.MemberID
-- (53207 row(s) affected)



-- Diagnosis table

if object_id('pdb_AllSaversResearch..ALSMotion_DiagTable') is not null
drop table pdb_AllSaversResearch..ALSMotion_DiagTable

select distinct UniqueMemberID = b.UniqueMemberID
	, ICDCd = e.DiagDecmCd
	, DiagnosisServiceDate = f.FullDt
into pdb_AllSaversResearch..ALSMotion_DiagTable
from pdb_AllSaversResearch..ALSGroups						as a
inner join #MemberTable										as b on a.PolicyID = b.PolicyID
inner join AllSavers_Prod..Fact_Claims						as c on b.UniqueMemberID = c.MemberID
inner join AllSavers_Prod..Fact_Diagnosis					as d on c.ClaimNumber = d.ClaimNumber
																   and c.MemberID = d.MemberID
																   and d.DiagnosisNbr in (1,2,3)
inner join AllSavers_Prod..Dim_DiagnosisCode				as e on d.DiagCdSysId = e.DiagCdSysId
inner join AllSavers_Prod..Dim_Date							as f on c.FromDtSysID = f.DtSysId
																	and f.YearMo between a.BeginYearMo and a.EndYearMo
--(13,607,090 row(s) affected)

select * from pdb_AllSaversResearch..ALSMotion_DiagTable

create unique index uCIx_Id on pdb_AllSaversResearch..ALSMotion_DiagTable (UniqueMemberID)

/**************************************************************************
-- Run RAF stored proc located in VSQL10
-- Copy both tables into devsql10 (pdb_HealthcareResearch for now)
**************************************************************************/

--Run stored Procedure:
exec RA_Commercial_2014.dbo.spRAFDiagInput
	 @InputPersonTable = '#MemberTable'											--Requires fully qualifie v  vd name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = 'pdb_AllSaversResearch..ALSMotion_DiagTable'			--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_AllSaversResearch'
	,@OutputSuffix = 'RAF_Scores_ALS'

--select * from pdb_HealthcareResearch..RA_Com_P_MetalScores_RAF_Scores_ALS
--where modelversion = 'Bronze' 
--select * from pdb_HealthcareResearch..RA_Com_Q_MetalScoresPivoted_RAF_Scores_ALS
--select * from pdb_HealthcareResearch..RA_Com_R_ModelTerms_RAF_Scores_ALS
--where UniqueMemberID = 66816
--and ModelVersion = 'Bronze'

-- Final MemberTable with  RAF (ALL SAVERS INDIVIDUAL)
if object_id('pdb_HealthcareResearch..ALSMotion_MemberTable') is not null
drop table pdb_HealthcareResearch..ALSMotion_MemberTable

select a.UniqueMemberID
	, a.PolicyID
	, a.BirthDate
	, a.GenderCd
	, b.TotalScore as RAF
into pdb_HealthcareResearch..ALSMotion_MemberTable
from #MemberTable														as a
inner join pdb_HealthcareResearch..RA_Com_P_MetalScores_RAF_Scores_ALS	as b on a.UniqueMemberID = b.UniqueMemberID 
where b.ModelVersion = 'Bronze' 
--(39,195 row(s) affected)

--select avg(raf) from pdb_HealthcareResearch..ALSMotion_MemberTable
--where UniqueMemberID = 66816