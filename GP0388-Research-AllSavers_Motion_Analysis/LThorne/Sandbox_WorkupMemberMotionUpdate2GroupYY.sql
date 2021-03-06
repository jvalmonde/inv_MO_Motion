use pdb_Allsavers_Research;

declare @year     char(4) = year(getdate());  -- use
declare @Month    char(2) = month(getdate()); -- simulate EOM
declare @YearMo   char(6) = @Year+@Month;     -- date where value is null
declare @MonthEnd date    = (select max(FullDt) from allsavers_prod..dim_date where YearMo = @YearMo);

with mbrBasis as (  -- only working with those folks we can xwalk
SELECT a.Memberid, a.StartDate, EndDate = isnull(a.EndDate,@MonthEnd), PolicyID = left(m.ClientMEMBERID,10)
  FROM ETL.AS_DERM_MemberEnrollment a
  join ETL.AS_DERM_Members          m on a.memberid = m.memberid             -- use
  join etl.DERM_xwalk_Member        x on m.ClientMemberID = x.ClientMemberID -- to filter out
                                     and x.aSystemID <> 0                    -- the unidentified
),   expandIT as (  -- blow up the dates to a simulated MM countable item, but only for months in policy
select distinct a.MemberID, a.PolicyID, dt.YearMo, p1.PolicyYr
  from mbrBasis                            a                                                 -- begin w basis
  join allsavers_prod..dim_date           dt on dt.FullDt between a.StartDate and a.EndDate  -- expand it
  join AllSavers_Prod..Dim_Policy (nolock) p on a.PolicyID = p.PolicyID and p.YearMo = dt.YearMo -- controlled expansion
 cross apply (select PolicyYR = p0.YearMo/100 from AllSavers_Prod..Dim_Policy (nolock) p0    -- figures out
               where p0.PolicyID = p.PolicyID and p0.PolicyYear = p.PolicyYear               -- the proper
			     and p0.PolicyMonth = ((p.PolicyYear-1)*12)+1                                -- policy year
			 ) p1
),   synthesizeIT as (  -- now synthesize to policy and year in prep for update
select z.PolicyID, z.PolicyYr, Mbrs=count(distinct z.MemberID), MM = sum(z.MM)
  from (
select a.PolicyID, a.MemberID, a.PolicyYr, MM = count(a.YearMO)
  from expandIT a
 group by a.PolicyID, a.MemberID, a.PolicyYr
       ) z
 group by z.PolicyID, z.PolicyYr
)

select * 
  from synthesizeIT a
--  left join GroupDetailYY yy on yy.PolicyID = a.policyid and yy.PolicyYear = a.PolicyYr
-- where yy.PolicyID is null
 order by 1,2

update yy
   set EnrolledMotionMbr = a.Mbrs
     , EnrolledMotionMM  = a.MM
  from GroupDetailYY yy
  join synthesizeIT   a on yy.PolicyID = a.policyid and yy.PolicyYear = a.PolicyYr
;