/*** 
GP 1061 Pharmacy & Motion -- Member Table
Input databases:	AllSavers_Prod, pdb_AllSavers_Research
Date Created: 17 April 2017
***/

--pull for all members enrolled in motion
If (object_id('tempdb..#members_motion') Is Not Null)
Drop Table #members_motion
go

select d.MemberID, EnrolledMotion_YrMo = b.Year_Mo, DisenrolledMotion = b.LastEnrolled, d.Age, d.Gender, d.MM_2014, d.MM_2015, d.MM_2016
into #members_motion
from pdb_Allsavers_Research..MemberSummary				a
inner join pdb_Allsavers_Research..DERMEnrollmentBasis	b	on	a.Member_DIMID = b.Member_DIMID
inner join pdb_Allsavers_Research..ASM_xwalk_Member		c	on	a.Member_DIMID = c.Member_DIMID
inner join Allsavers_Prod..Dim_Member					d	on	c.SystemID = d.SystemID
where a.EnrolledMotion = 1
--(52396 row(s) affected)
create unique index uIx_MemberID on #members_motion (MemberID);

--pull for the 20% sample of members not enrolled in motion
If (object_id('tempdb..#members_nonmotion') Is Not Null)
Drop Table #members_nonmotion
go

select top 20 percent a.MemberID, a.Age, a.Gender, a.MM_2014, a.MM_2015, a.MM_2016
into #members_nonmotion
from	(
			select a.MemberID, a.Age, a.Gender, a.MM_2014, a.MM_2015, a.MM_2016
			from Allsavers_Prod..Dim_Member	a
			inner join AllSavers_Prod..Dim_Policy	c	on	a.PolicyID = c.PolicyID
			where (a.MM_2014 = 12
				or a.MM_2015 = 12
				or a.MM_2016 = 12)
				and c.ProductCode = 'SI'
				and left(c.YearMo, 4) in ('2014', '2015', '2016')
			group by a.MemberID, a.Age, a.Gender, a.MM_2014, a.MM_2015, a.MM_2016
		)			a
left join #members_motion				b	on	a.MemberID = b.MemberID
where b.MemberID is null
order by newid()
--(20753 row(s) affected)

--final member table
If (object_id('pdb_PharmaMotion..Member') Is Not Null)
Drop Table pdb_PharmaMotion..Member
go

select MemberID, EnrolledMotion_YrMo, DisenrolledMotion, Age = Age - 1, Gender, MM_2014, MM_2015, MM_2016
into pdb_PharmaMotion..Member
from #members_motion
union
select MemberID, EnrolledMotion_YrMo = '', DisenrolledMotion = '', Age = Age - 1, Gender, MM_2014, MM_2015, MM_2016
from #members_nonmotion
--(73,149 row(s) affected)
create unique index uIx_MemberID on pdb_PharmaMotion..Member (MemberID);

-----------------------------------
--add Member's address data
--Date Created: 27 April  2017
-----------------------------------
--total members: 73,148
If (object_id('tempdb..#mbr_location') Is Not Null)
Drop Table #mbr_location
go

select a.MemberID, b.Zip, c.St_Cd, c.MSA, c.County, d.CTY_NM
into #mbr_location
from pdb_PharmaMotion..Member	a
inner join AllSavers_Prod..Dim_Member	b	on	a.MemberID = b.MemberID
inner join pdb_Rally..Zip_Census		c	on	b.Zip = c.Zip
inner join MiniHPDM..Dim_Zip			d	on	b.Zip = d.ZIP_CD
--(73064 row(s) affected)
create unique index uIx_MemberID on #mbr_location (MemberID);

alter table pdb_PharmaMotion..Member
	add Zip			varchar(5)
		, Cty_Nm	varchar(28)
		, County	varchar(25)
		, MSA		varchar(60)
		, St_Cd		varchar(2)
go

update pdb_PharmaMotion..Member
set Zip			= b.Zip	
	, Cty_Nm	= b.Cty_Nm
	, County	= b.County
	, MSA		= b.MSA	
	, St_Cd		= b.St_Cd	
from pdb_PharmaMotion..Member	a
left join #mbr_location			b	on	a.MemberID = b.MemberID

-----------------------------------
--add Member's subscriber indicator
--Date Created: 03 May  2017
-----------------------------------
If (object_id('tempdb..#mbr_sbscrind') Is Not Null)
Drop Table #mbr_sbscrind
go

select a.MemberID, b.Sbscr_Ind
into #mbr_sbscrind
from pdb_PharmaMotion..Member	a
inner join AllSavers_Prod..Dim_Member	b	on	a.MemberID = b.MemberID
--(73148 row(s) affected)
create unique index uIx_MemberID on #mbr_sbscrind (MemberID);

alter table pdb_PharmaMotion..Member
	add Sbscr_Ind smallint
go

update pdb_PharmaMotion..Member
set Sbscr_Ind = b.Sbscr_Ind
from pdb_PharmaMotion..Member	a
inner join #mbr_sbscrind		b	on	a.MemberID = b.MemberID