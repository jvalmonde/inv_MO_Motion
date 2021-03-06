use pdb_Allsavers_Research;

if object_id(N'tempdb..#ASM') is not null
   drop table #ASM;

select distinct m.SystemID, m.LastName, m.FirstName, m.Gender, m.Birthdate, m.Phone
     , Age=DATEDIFF(yy,BirthDate, '2016-10-01')  -- current policy year (?) as basis for member age
  into #ASM 
  from AllSavers_Prod..Dim_Member m                             -- Current state of data
  join asm_xwalk_member           a on a.SystemID = m.SystemID  -- filtered by those we're interested in
 where m.SystemID > 0                                           -- created in ETL_BuildupMember
;

create unique clustered index ucix_SID  on #ASM(SystemID);
create                  index uxix_Name on #ASM (LastName, FirstName);


if object_id(N'tempdb..#POI') is not null
   drop table #POI;

SELECT m.*
  into #POI
  FROM ETL.AS_DERM_MemberEnrollment a
  join etl.AS_DERM_Members          m on a.Memberid = m.MEMBERID
  join etl.AS_DERM_ElapsedQtrDays   d on a.Memberid = d.MEMBERID
  join etl.DERM_xwalk_Member        x on m.ClientMEMBERID = x.dSystemID
--  join     ASM_xwalk_Member         w on x.aSystemid      = w.SystemID
--  join     MemberSummary           ms on w.Member_DIMID   = ms.Member_DIMID
 where EndDate is null --StartDate < '2015-10-01'
   and x.aSystemid = 0
;

with nameComparative as (

select dSystemID  = cast(a.ClientMemberID as bigint)
     , dLastName  = a.LastName, dFirstName = a.FirstName, dGender = a.Gender
     , dBirthdate = convert(date,a.BirthDate,126), dPhone = a.HomePhone
	 , dAddress1  = a.Address1, dZIP = a.ZipCode
	 , mSystemID  = m.SystemID, mLastName = m.LastName, mFirstName = m.FirstName
	 , mBirthdate = m.BirthDate, mGender = m.Gender, mPhone = m.Phone
	 , mAddress1  = m.Address1, mZIP = m.Zip
	 , AgeDiffDD  = datediff(dd,a.Birthdate, m.birthdate)
  from ETL.DERM_xwalk_Member           (nolock) xm
  join ETL.AS_DERM_Members             (nolock)  a on xm.ClientMEMBERID = a.ClientMEMBERID
  join #POI                                      p on a.MEMBERID = p.MEMBERID
  left join ASM_xwalk_Member           (nolock)  b on a.clientMemberid  = cast(b.SystemID as varchar(32))
  left join AllSavers_Prod..Dim_Member (nolock)  m on b.SystemID        = m.SystemID	
 where xm.aSystemid = 0
   and isnull(m.SystemID,0) > 0

)--,   nameFilter as (

select *   -- filter data from current state of nameComparative according to SQLFilters iteration
  from nameComparative
