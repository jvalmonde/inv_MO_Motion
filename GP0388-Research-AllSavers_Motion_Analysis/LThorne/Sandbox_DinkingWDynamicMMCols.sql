use pdb_Allsavers_Research;

declare @minYear int = (select min(Year_Name)-1 from pdb_Allsavers_Research..ASM_YearMo);
declare @maxYear int = (select max(Year_Name) from pdb_Allsavers_Research..ASM_YearMo);

if object_id(N'tempdb..#PolicyYearBasis') is not null
   drop table #PolicyYearBasis;

with policyBasis as (
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

select ColName, oid = ROW_NUMBER() over( order by Colname)
  into #colNames
  from (select distinct ColName from #PolicyYearBasis) a
;

create clustered index ix_PID on #PolicyYearBasis (PolicyID);

--TP:  select top 100 * from #PolicyYearBasis order by 1,2

if object_id(N'tempdb..#MemberYearBasis') is not null
   drop table #MemberYearBasis;

select top 1000 xm.Member_DIMID, mp.ColName, MM = count(md.YearMo)
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

drop table #xm2

select ms.*, xm.*
  into #xm2
  from #XM1 xm
  join MemberSummary ms on xm.tempDIMID = ms.Member_DIMID
;

alter table #xm2 drop column tempDimid;

select * from #xm2