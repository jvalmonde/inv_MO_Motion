use pdb_Allsavers_Research;

-- This process builds a xwalk from the derm data to the Allsavers data,
--  as not all SystemIDs are ==

--  Only do this step when recreating the xwalk table

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'DERM_xwalk_Member')
   drop table pdb_Allsavers_Research.etl.DERM_xwalk_Member;

select distinct dSystemID = cast(a.ClientMemberID as bigint), a.ClientMEMBERID
     , a.LastName, a.FirstName, a.Gender
     , Birthdate = convert(date,a.BirthDate,126), a.HomePhone
	 , aSystemid = cast(0 as bigint)
  into etl.DERM_xwalk_Member
  from ETL.AS_DERM_Members   a       -- from downloaded ETL_DermMembers (1st pull)
 where a.lastname <> 'Admin'
   and len(a.ClientMemberID) >= 17
;

create unique clustered index ucix_SID  on pdb_Allsavers_Research.etl.DERM_xwalk_Member(dSystemID);
create                  index uxix_Name on pdb_Allsavers_Research.etl.DERM_xwalk_Member (LastName, FirstName);

-- Temp table to serve as reference

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

---

---
--- Looking @ members who have same id, but some other tuple not match (LN, FN, BD)
---

if object_id(N'tempdb..#SQLFilters') is not null
   drop table #SQLFilters;

create table #SQLFilters ( ID        int identity(1,1), Described varchar(1024), SqlWhere  varchar(2048));

insert into #SQLFilters
select Described = '-- 1st filter names (LN, FN) and BD =='
     , SqlWhere  = '   and dLastName = mLastName and dFirstName = mFirstName and dBirthdate = mBirthdate'              union all
select Described = '-- 2nd filter names (LN, FN) == and BD delta +/-9 days to account for transpositions'
     , SqlWhere  = '   and dLastName = mLastName and dFirstName = mFirstName and AgeDiffDD between -9 and 9'           union all
select Described = '-- 3rd filter LN and BD == with 1-2 char delta in firstname'
     , SqlWhere  = '   and dLastName = mLastName and dBirthdate = mBirthdate and dbo.Levenshtein_Distance (dfirstname, mFirstname) in (1,2)'  union all
select Described = '-- 4th filter firstname, BD and phone number =='
     , SqlWhere  = '   and dFirstName = mFirstName and dBirthdate = mBirthdate and right(dphone,8) = right(mphone,8)'  union all
select Described = '-- 5th filter lastname, BD and phone number =='
     , SqlWhere  = '   and dLastName = mLastName and dBirthdate = mBirthdate and right(dphone,8) = right(mphone,8)'    union all
select Described = '-- 6th filter - names (LN, FN), A1, ZIP =='
     , SqlWhere  = '   and ltrim(rtrim(dLastName)) = ltrim(rtrim(mLastName)) and ltrim(rtrim(dFirstName)) = ltrim(rtrim(mFirstName))' +
                   '   and dAddress1 = mAddress1 and dZIP = mZIP'                                                      union all
select Described = '-- 6th filter - lastname within 2 char == and FN, A1, Zip =='
     , SqlWhere  = '   and dbo.Levenshtein_Distance (dLastName, mLastName) in (1,2) and ltrim(rtrim(dFirstName)) = ltrim(rtrim(mFirstName))' +
                   '   and dAddress1 = mAddress1 and dZIP = mZIP'                                                      union all
select Described = '-- 6th filter - BD, A1, Zip =='
     , SqlWhere  = '   and dBirthdate = mBirthdate and dAddress1 = mAddress1 and dZIP = mZIP'                          union all
select Described = '-- 6th filter - LN, A1, Zip =='
     , SqlWhere  = '   and ltrim(rtrim(dLastName)) = ltrim(rtrim(mLastName)) and dAddress1 = mAddress1 and dZIP = mZIP' union all
select Described = '-- 6th filter - LN, ZIP ==, A1 within 2 char =='
     , SqlWhere  = '   and ltrim(rtrim(dLastName))  = ltrim(rtrim(mLastName))' +
                   '   and dbo.Levenshtein_Distance (dAddress1, mAddress1) in (1,2) and dZIP = mZIP'                   union all
select Described = '-- 6th filter - LN, BD, G, ZIP ==, left 6 of A1  =='
     , SqlWhere  = '   and ltrim(rtrim(dLastName))  = ltrim(rtrim(mLastName)) and dBirthdate = mBirthdate' +
                   '   and dGender = mGender and dZIP = dZIP and (left(daddress1,6) = left(maddress1,6)'   +
                   '    or right(dphone,8) = right(mphone,8))'                                                         --union all
;
create unique clustered index tpix_ID on #SQLFilters (ID);

--TP:  select * from #sqlfilters order by 1

set nocount on
declare @SQLWhere varchar(2048);

declare c1 cursor for
select SQLWhere from #SQLFilters order by id

open c1
fetch next from c1 into @SQLWhere

while @@FETCH_STATUS = 0
begin

exec ('
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
  left join ASM_xwalk_Member           (nolock)  b on a.clientMemberid  = cast(b.SystemID as varchar(32))
  left join AllSavers_Prod..Dim_Member (nolock)  m on b.SystemID        = m.SystemID	
 where xm.aSystemid = 0
   and isnull(m.SystemID,0) > 0

),   nameFilter as (

select *   -- filter data from current state of nameComparative according to SQLFilters iteration
  from nameComparative
 where 1=1 -- dummy where clause to facilitate SQLFilters
 '+@SQLWhere+'
)

--TP:  select * from namefilter --Comparative

update xm
   set aSystemid = nc.mSystemID
  from ETL.DERM_xwalk_Member xm
  join nameFilter            nc on xm.dSystemID = nc.dSystemID
     ')

fetch next from c1 into @SQLWhere
end

close c1
deallocate c1
;
set nocount off

/*  Original basis of above
select *     -- 1st filter names and BD ==
  from nameComparative
 where 1=1
   and dLastName  = mLastName
   and dFirstName = mFirstName
   and dBirthdate = mBirthdate

select *     -- 2nd filter names and BD delta +_9 days to account for transpositions
  from nameComparative
 where 1=1
   and dLastName  = mLastName
   and dFirstName = mFirstName
   and AgeDiffDD between -9 and 9

select *     -- 3rd filter lastname and BD with 1-2 char delta in firstname
     , dist = dbo.Levenshtein_Distance (dfirstname, mFirstname)
  from nameComparative
 where 1=1
   and dLastName  = mLastName
   and dBirthdate = mBirthdate
   and dbo.Levenshtein_Distance (dfirstname, mFirstname) in (1,2)

select *     -- 4th filter firstname, BD and phone number
  from nameComparative
 where 1=1
   and dFirstName  = mFirstName
   and dBirthdate = mBirthdate
   and right(dphone,8) = right(mphone,8)

select *     -- 5th filter lastname, BD and phone number
  from nameComparative
 where 1=1
   and dLastName  = mLastName
   and dBirthdate = mBirthdate
   and right(dphone,8) = right(mphone,8)

select *     -- 6th filter - various, see notes; 5 iterations
  from nameComparative
 where 1=1
   and ltrim(rtrim(dLastName))  = ltrim(rtrim(mLastName))
   and ltrim(rtrim(dFirstName)) = ltrim(rtrim(mFirstName))
   and dbo.Levenshtein_Distance (dLastName, mLastName) in (1,2)
   and dBirthdate = mBirthdate
   and dAddress1  = mAddress1
   and dbo.Levenshtein_Distance (dAddress1, mAddress1) in (1,2)
   and dZIP       = mZIP
*/


/*
---
--- This attempts to look @ where the SystemID does not match

with nonalignedMembers as (

select dSystemID = cast(a.ClientMemberID as bigint), a.LastName, a.FirstName, a.Gender
     , Birthdate = convert(date,a.BirthDate,126), a.HomePhone
  from ETL.DERM_xwalk_Member      (nolock) xm
  join ETL.AS_DERM_Members        (nolock)  a on xm.ClientMEMBERID = a.ClientMEMBERID
  left join ASM_xwalk_Member      (nolock)  b on a.clientMemberid = cast(b.SystemID as varchar(32))
 where xm.asystemid = 0
   and b.SystemID is null
),   filter as (

select distinct a.*, mSystemid = m.SystemID, mLastName = m.LastName, mFirstName = m.FirstName
     , mBirthDate = m.BirthDate, dd = DATEDIFF(dd,a.birthdate, m.birthdate)	 , mPhone = m.Phone
     , dist = dbo.Levenshtein_Distance (a.firstname, m.Firstname)
  from nonalignedMembers a
  join #ASM              m on a.lastname  = m.LastName 
--                          and a.firstname = m.FirstName
--                          and a.Birthdate <> m.BirthDate
						  and right(a.HomePhone,8) = right(m.phone,8)
--						  and DATEDIFF(dd,a.birthdate, m.birthdate) between -9 and 9
) 

--select * from filter

update xm
   set aSystemid = nc.mSystemID
  from ETL.DERM_xwalk_Member xm
  join filter                nc on xm.dSystemID = nc.dSystemID and nc.dd = -1
;
*/
