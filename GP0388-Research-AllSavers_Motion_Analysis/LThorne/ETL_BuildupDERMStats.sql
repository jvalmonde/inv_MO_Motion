use pdb_Allsavers_Research;

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'DERMEnrollmentBasis')
   drop table pdb_Allsavers_Research.dbo.DERMEnrollmentBasis;

with mbrEnrollBasis as (
select MemberID, EnrollDT = min(StartDate), DisenrollDt = max(EndDate)
  from etl.AS_DERM_MemberEnrollment (nolock) me
 group by Memberid
)
 
 select ax.Member_DIMID, FirstEnrolled = eb.EnrollDT, LastEnrolled = isnull(eb.disenrolldt,'2999-12-31')
      , Year_Mo = dt.YearMo, dt.YearNbr
  into DERMEnrollmentBasis
  from mbrEnrollBasis                    eb
  join AllSavers_Prod..Dim_Date (Nolock) dt on dt.FullDt         = eb.EnrollDT
  join etl.AS_DERM_Members      (nolock) dm on eb.Memberid       = dm.MEMBERID   -- Memberid
  join etl.DERM_xwalk_Member    (nolock) dx on dm.ClientMEMBERID = dx.dSystemID  -- xwalk to
  join ASM_xwalk_Member         (nolock) ax on dx.aSystemid      = ax.SystemID   -- DIMID
 order by 1
;

create clustered index ucix_DIMID on pdb_Allsavers_Research..DERMEnrollmentBasis (Member_DIMID);

----- Now that this is accomplished, the new fact can be replicated

update cd  -- Claims
   set [Year] = case when eb.FirstEnrolled is null then 9999 else cd.ClaimYear - year(eb.FirstEnrolled) end
  from MemberClaimDetailYY      cd
  left join DERMEnrollmentBasis eb on cd.Member_DIMID = eb.Member_DIMID
;

update md
   set [Month] = case when eb.Member_DIMID is null then 9999
                      else DATEDIFF(mm,convert(date,eb.year_mo+'01'),convert(date,md.yearmo+'01',126))
				  end
  from Longitudinal_Month md
  left join DERMEnrollmentBasis eb on md.Member_DIMID = eb.Member_DIMID
;