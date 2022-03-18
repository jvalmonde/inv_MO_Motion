/*** 
GP 1062 - T2D Adherence Member Table

Input databases:	SMA, pdb_CGMType2, Census

Date Created: 07 June 2017
***/

/*
select *
from pdb_CGMType2.INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'Stage2_LH_SMA_MemberDemo_201110_201509'
*/

If (object_id('pdb_CGMType2.dbo.GP1062_MemberDemo') Is Not Null)
Drop Table pdb_CGMType2.dbo.GP1062_MemberDemo
go

select a.SavvyMRN, b.Age, b.Gender
	, b.Businessline, b.CoverageType, b.ProductID, b.GroupName
	, a.ZipCode, c.MSA, c.ZCTA, c.St_Cd
	, B19013_001
	, B19083_001
	, B17020_001
	, B17020_002
	, B17020_010
	, B15003_001
	, B15003_002
	, B15003_003
	, B15003_004
	, B15003_005
	, B15003_006
	, B15003_007
	, B15003_008
	, B15003_009
	, B15003_010
	, B15003_011
	, B15003_012
	, B15003_013
	, B15003_014
	, B15003_015
	, B15003_016
	, B15003_017
	, B15003_018
	, B15003_019
	, B15003_020
	, B15003_021
	, B15003_022
	, B15003_023
	, B15003_024
	, B15003_025
	, B02001_001
	, B02001_002
	, B02001_003
	, B02001_004
	, B02001_005
	, B02001_006
	, B02001_007
	, B02001_008
--select d.PLAN_NUMBER, d.COVERAGE_TYPE, count(distinct a.savvyMRN)
into pdb_CGMType2.dbo.GP1062_MemberDemo
from pdb_CGMType2..Stage2_LH_SMA_MemberDemo_201110_201509	a
inner join SMA..Dim_Member									b	on	a.SavvyMRN = b.SavvyMRN
inner join pdb_Rally..Zip_Census							c	on	a.ZipCode = c.Zip
--inner join SMA..Dim_Coverage_Type							d	on	b.Businessline = d.BUSINESS_LINE
--																and b.CoverageType = d.COVERAGE_TYPE
where Classification_Types = 'T2'
--group by d.PLAN_NUMBER, d.COVERAGE_TYPE
--(6,819 row(s) affected)

select count(*), count(distinct SavvyMRN)
from pdb_CGMType2.dbo.GP1062_MemberDemo