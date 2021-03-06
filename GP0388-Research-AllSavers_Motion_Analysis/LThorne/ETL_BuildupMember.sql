use AllSavers_Prod;

-- ASM_YearMo establishes the time box of the study; will need 2B extended as necessary with 
--            additional years

/*  only required when needs to change (annually) & Remember to push to pdb_DermReporting in cloud

-- ASM_YearMo establishes the time box of the study; will need 2B extended as necessary with 
--            additional years

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'ASM_YearMo')
   drop table pdb_Allsavers_Research.dbo.ASM_YearMo;

create table  pdb_Allsavers_Research..ASM_YearMo (OrderID int identity(1,1),
                                                  YearMo         char(6),
			  Year_Name      char(4),
			  Month_Name  varchar(16),
			  Year_Mo     int,
			  Quarter_Nbr int,
			  DaysInMonth int
			  );

-- Establish the basis for number of years for establishing YearMo

declare @ProjectYears table (pYear int);
declare @CurrentYear  int = year(getdate());  -- Current year is end of list
declare @ProjectYear  int = 2014;             -- Project start basis year

while @ProjectYear <= @CurrentYear
begin
insert into @ProjectYears
select @ProjectYear    
set @ProjectYear = @ProjectYear + 1;          -- Bump up the year to while limit
end
;
with ProjectTimeBrackets as ( -- create the YearMo for @ProjectYears

select distinct YearMo from AllSavers_Prod..Dim_Date (nolock) where YearNbr in (select pYear from @ProjectYears)

)

insert into pdb_Allsavers_Research..ASM_YearMo
select dt.YearMo
	 , Year_Name  = max(cast(dt.Yearnbr as char(4)))
     , Month_Name = max(dt.MonthNM)
	 , Year_Mo    = max(cast(dt.YearMo as int))
	 , Quarter_Nbr= max(dt.QuarterNbr)
	 , DaysInMonth= count(dtSysID)
  from ProjectTimeBrackets               ym
  join AllSavers_Prod..Dim_Date (nolock) dt on ym.YearMo = dt.YearMo
 group by dt.YearMo
 order by 1
;									

create unique clustered index ucix_yearmo on pdb_Allsavers_Research..ASM_YearMo (YearMo);
select * from pdb_Allsavers_Research..ASM_YearMo order by 2;

*/


-- ASM_xwalk_Member establishes a DIMID for ASM members


-- ASM_xwalk_Member is used to assign a DIMID to the member, which is used throughout the data.
-- The DIMID is based on concatenation of the member's SSN + Birthdate
-- Only members with a Policy are considered

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'ASM_xwalk_Member')
   drop table pdb_Allsavers_Research.dbo.ASM_xwalk_Member;

with mbrBasis as (
select distinct md.MemberID
  from AllSavers_Prod..Dim_MemberDetail   md
  join pdb_Allsavers_Research..ASM_YearMo ym on md.YearMo = ym.YearMo  -- Filter to project time box
 where isnull(md.PolicyID,0) > 0                                       -- must have a policy
),   mbrRanking as (   -- need to filter out occasional mixup of SystemID shared by multiple people
select Member_Hash  = cast(hashbytes('MD5',m.SSN+cast(m.birthdate as varchar(10))) as binary(16))
     , Member_DIMID = convert(varchar(32), cast(hashbytes('MD5',m.SSN+cast(m.birthdate as varchar(10))) as binary(16)),2)
	 , m.SystemID
	 , DependentCode = cast(right(m.systemid,2) as char(2))
	 , oid = ROW_NUMBER() over(partition by cast(hashbytes('MD5',m.SSN+cast(m.birthdate as varchar(10))) as binary(16))
	                               order by m.SystemID desc)
  FROM mbrBasis                   mb
  join AllSavers_Prod..Dim_Member  m on mb.MemberID = m.MemberID
                                    and m.MemberID > 0
)

select Member_Hash, Member_DIMID, SystemID, DependentCode
  into pdb_Allsavers_Research..ASM_xwalk_Member
  from mbrRanking
 where oid = 1
;

-- add some indexes to speed ol'SQL up

create clustered index ucix_SID   on pdb_Allsavers_Research..ASM_xwalk_Member (SystemID);
create           index ucix_Hash  on pdb_Allsavers_Research..ASM_xwalk_Member (Member_Hash);
create           index ucix_DIMID on pdb_Allsavers_Research..ASM_xwalk_Member (Member_DIMID);
;

--  And with the basis established above, build the MemberSummary table
--  Dynamic SQL is used in order to dynamically insure the columns for the MMYM accumulators

if exists(select a.OBJECT_ID 
            from pdb_Allsavers_Research.sys.objects a
			join pdb_Allsavers_Research.sys.schemas b on a.schema_id = b.schema_id and b.name = 'ETL'
           where a.name = 'MemberSummary')
   drop table pdb_Allsavers_Research.etl.MemberSummary;

declare @dynSQL nvarchar(max);  -- need a place to acrete SQL statement parts

-- header code
set @dynSQL = '
declare @minYearMo int = (select min(YearMo) from pdb_Allsavers_Research..ASM_YearMo);
declare @maxYearMo int = (select max(YearMo) from pdb_Allsavers_Research..ASM_YearMo);

with mbrBasis as (
SELECT xm.Member_DIMID
	 , md.YearMo
     , md.FamilyID, md.PolicyID
	 , md.Sbscr_Ind, md.InsuredFlag
     , CanSelectionMotion = Case when mp.GroupState  in (''Pa'',''De'',''Mo'',''Wi'') then 0  ---These are motion exempt states
	                             else case when right(xm.SystemID,2) in (''00'',''01'') then 1 else 0 end 
							 end
     , md.Gender, md.State, md.Zip
     , Age     = datediff(yy,md.BirthDate, 
	             cast(convert(char(4), md.YearMo/100)+''-''+convert(char(2), format(md.YearMo%100,''00''))+''-01'' as date))
	 , YM_Date = cast(convert(char(4), md.YearMo/100)+''-''+convert(char(2), format(md.YearMo%100,''00''))+''-01'' as date)
  FROM Dim_MemberDetail                         md
  join pdb_Allsavers_Research..ASM_xwalk_Member xm on md.SystemID = xm.SystemID       -- filter on the member basis for project
  join pdb_Allsavers_Research..ASM_YearMo       ym on md.YearMo   = ym.YearMo         -- filter on the YearMo spread for project
  join Dim_Policy                               mp on md.PolicyID = mp.PolicyID and md.YearMo = mp.YearMo
 where isnull(md.PolicyID,0) > 0                                                      -- must have a policy, and for the YearMo
)

select --top 1000
       Member_DIMID, FamilyID, PolicyID, Sbscr_Ind, InsuredFlag, CanSelectionMotion, Gender, State, Zip
	 , Enrollment_DT  = min(ym_date)
     , Age            = min(Age)
	 , EnrolledMotion = 0
	 , MM             = sum(case when YearMo between @minYearMo and @maxYearMo then 1 else 0 end)
'
-- insert MMyyyy lines for project years as defined in ASM_YearMo
select @dynSQL = ltrim(@dynSQL) + '     , MM'+Year_Name+' = sum(case when YearMo between '+BegYM+' and '+EndYM+' then 1 else 0 end)'+char(010)
  from (SELECT Year_Name, BegYM = min(YearMo), EndYM = max(YearMo)
               FROM pdb_Allsavers_Research..ASM_YearMo
              group by Year_Name) a
 order by a.Year_Name

-- footer code
set @dynSQL = ltrim(@dynSQL) + '
  into pdb_Allsavers_Research.ETL.MemberSummary
  from mbrBasis mb
 group by Member_DIMID, FamilyID, PolicyID, Sbscr_Ind, InsuredFlag, CanSelectionMotion, Gender, State, Zip
order by 2,1
'
exec (@dynSQL)  -- execute and build the table

go -- reset namespace

-- Now generate the policy Year addendum and acrete
-- There are two sets of accumlator buckets, the MM are calendar year based,
--       and the PYMM are policy year based
--
-- This gets kind of involved, and there might be an easier way. 
-- The attempt is to be dynamic and not buildout a maintence requirement Y/Y

declare @minYear int = (select min(Year_Name)-1 from pdb_Allsavers_Research..ASM_YearMo);
declare @maxYear int = (select max(Year_Name)   from pdb_Allsavers_Research..ASM_YearMo);

if object_id(N'tempdb..#PolicyYearBasis') is not null
   drop table #PolicyYearBasis;

with policyBasis as (  -- build up a list of policy year column names
SELECT PolicyID, PolicyYear, minYM = min(YearMo), maxYM = max(YearMo)
  FROM AllSavers_Prod..Dim_Policy 
 where PolicyID > 0
 group by PolicyID, PolicyYear
)
select PolicyID, PolicyYear = minYM/100, minYM, maxYM, ColName = 'PYMM'+format(minYM/100,'####')
  into #PolicyYearBasis
  from policyBasis
 where minYM/100 between @minYear and @maxYear
;

if object_id(N'tempdb..#colNames') is not null
   drop table #colNames;

-- order the column names to insert in a meaningful order
select ColName, oid = ROW_NUMBER() over( order by Colname)
  into #colNames
  from (select distinct ColName from #PolicyYearBasis) a
;

create clustered index ix_PID on #PolicyYearBasis (PolicyID);

--TP:  select top 100 * from #PolicyYearBasis order by 1,2

if object_id(N'tempdb..#MemberYearBasis') is not null
   drop table #MemberYearBasis;

-- Count'em up
select xm.Member_DIMID, mp.ColName, MM = count(md.YearMo)
  into #MemberYearBasis
  FROM AllSavers_Prod..Dim_MemberDetail (nolock) md
  join pdb_Allsavers_Research..ASM_xwalk_Member  xm on md.SystemID = xm.SystemID       -- filter on the member basis for project
  join pdb_Allsavers_Research..ASM_YearMo        ym on md.YearMo   = ym.YearMo         -- filter on the YearMo spread for project
  join #PolicyYearBasis                          mp on md.PolicyID = mp.PolicyID and md.YearMo between mp.minYM and mp.maxYM
 where isnull(md.PolicyID,0) > 0                                                      -- must have a policy, and for the YearMo
 group by xm.Member_DIMID, mp.ColName
 order by 1,2
;

--TP:  select top 100 * from #MemberYearBasis order by 1,2

if object_id(N'tempdb..#MM') is not null
   drop table #MM;

select tempDIMID = t.Member_DIMID, cn.ColName, MM = isnull(t1.MM,0)
  into #MM
  from (select distinct Member_DIMID from #MemberYearBasis) t
  join #colNames cn on 1=1
  left join #MemberYearBasis t1 on t.Member_DIMID = t1.Member_DIMID and cn.ColName = t1.ColName
 order by 1,2
;

if object_id(N'tempdb..#XM1') is not null
   drop table #XM1;

DECLARE @cols  NVARCHAR(2000), @query NVARCHAR(4000);
declare @maxIX smallint;

SELECT  @cols = STUFF(( SELECT '],[' + t.ColName 
                          FROM #colNames AS t 
						 order by t.oid
                           FOR XML PATH('') 
                      ), 1, 2, '') + ']' 
;
/*
SELECT  @cols
*/

set @maxIX = (select max(oid) from #colNames);

create table #XM1 (tempDIMID varchar(32));
set @query = 'alter table #XM1 add';

select @query = rtrim(@query) + ' '+ ColName + ' int' + case when oid <> @maxIX then ', ' else ';' end
  from #colNames
 order by oid
;
exec (@query)

SET @query = N'
insert into #XM1
select * from (select * from #mm) a
 pivot (max(MM) for colname in ('+@cols+')) p
'
; 
exec(@query)

-- ok, put it all together, and then drop the stiching columns

if exists(select a.OBJECT_ID 
            from pdb_Allsavers_Research.sys.objects a
			join pdb_Allsavers_Research.sys.schemas b on a.schema_id = b.schema_id and b.name = 'dbo'
           where a.name = 'MemberSummary')
   drop table pdb_Allsavers_Research.dbo.MemberSummary;

select ms.*, xm.* , DateLastGeneration = GETDATE()
  into pdb_Allsavers_Research.dbo.MemberSummary
  from pdb_Allsavers_Research.etl.MemberSummary ms 
  left join #XM1 xm on xm.tempDIMID = ms.Member_DIMID
;

alter table pdb_Allsavers_Research.dbo.MemberSummary drop column tempDimid;

-- Add some indexes to speed ol'SQL up

create           index ucix_DIMID on pdb_Allsavers_Research.dbo.MemberSummary (Member_DIMID);
create           index ucix_FID   on pdb_Allsavers_Research.dbo.MemberSummary (FamilyID);
create           index ucix_PID   on pdb_Allsavers_Research.dbo.MemberSummary (PolicyID);


/* Update the EnrolledMotion flag once the longitudinal day is set
update ms
  set EnrolledMotion = 1
select count(distinct ms.Member_Dimid)
  from pdb_Allsavers_Research..MemberSummary ms
  join (select distinct Member_DIMID
          from pdb_Allsavers_Research..Longitudinal_Day
	   ) dd on ms.Member_DIMID = dd.Member_DIMID
;




update ms  -- moved into group logic ....
   set EnrolledMotion = case when isnull(me.MemberID,0) = 0 then 0 else 1 end
  from pdb_Allsavers_Research..MemberSummary                 ms
  join pdb_Allsavers_Research..ASM_xwalk_Member     (nolock) ax on ms.member_dimid   = ax.member_dimid   -- DIMID
  join pdb_Allsavers_Research.etl.DERM_xwalk_Member (nolock) dx on ax.SystemID       = dx.aSystemID      -- xwalk to
  join pdb_Allsavers_Research.etl.AS_DERM_Members   (nolock) dm on dx.ClientMemberid = dm.clientMEMBERID -- Memberid
  left join pdb_Allsavers_Research.ETL.AS_DERM_MemberEnrollment (nolock) me on dm.MemberID = me.MemberID
;

--TP:  select count(member_dimid) from pdb_Allsavers_Research..MemberSummary where enrolledmotion = 1

select sum(enrolledmotionmbr) from pdb_Allsavers_Research..GroupSummary
*/
