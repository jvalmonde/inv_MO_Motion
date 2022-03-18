USE pdb_WalkandWin /*...on DBSEP3832*/
GO

-------------------------------------------------------------
--1) Get member details for distinct SavvyHICNs
-------------------------------------------------------------
--get MMR flags (OREC)
IF object_id('wkg_mmr_flags','U') IS NOT NULL
	DROP TABLE wkg_mmr_flags;
select a.SavvyHICN, max(a.OriginalReasonForEntitlement) as OriginalReasonForEntitlement
into wkg_mmr_flags
from CmsMMR_Subset_20180313			a
group by a.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_mmr_flags(SavvyHICN)
go

--get Median household income at ZIP level
IF object_id('wkg_census_zip','U') IS NOT NULL
	DROP TABLE wkg_census_zip;
select b.Zip, a.ZCTA, 
	   c.B19013_001 as Median_Household_Income
into wkg_census_zip
from Census.dbo.ACS_Geography			as a
join Census.dbo.Zip_Census				as b	on a.ZCTA = b.ZCTA
join Census.dbo.ACS_MedianIncome		as c	on a.StateCode = c.StateCode 
												and a.LogRecNo = c.LogRecNo
												and a.[Year] = c.[Year]
where a.GeographyType = 'ZCTA Level'
  and c.StatisticsID = 1
  and c.Year = 2015			--latest we've got
go
create clustered index cixZip on wkg_census_zip(Zip)
go



-- drop table pdb_WalkandWin..LTV_Member_Demographics_2016_Pilot
IF object_id('LTV_Member_Demographics_2016_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Demographics_2016_Pilot;
select a.SavvyHICN, c.Age, c.Gender, c.ZIP, g.OriginalReasonForEntitlement,
	   d.St_Cd, 
       d.MSA,
	   d.FIPS,
	   e.USR_Class,
	   f.Median_Household_Income
into LTV_Member_Demographics_2016_Pilot
from CombinedMember_sg							as a 
left join MiniOV..SavvyID_to_SavvyHICN			as b	on a.SavvyHICN = b.SavvyHICN
left join MiniOV..Dim_Member					as c	on b.SavvyID = c.SavvyID
left join Census.dbo.Zip_Census					as d	on c.ZIP = d.ZIP
left join Census.dbo.ZCTA						as e	on d.ZCTA = e.ZCTA
left join wkg_census_zip						as f	on c.ZIP = f.ZIP
left join wkg_mmr_flags							as g	on a.SavvyHICN = g.SavvyHICN
where a.is2016 = 1

create unique index ix_savvyHICN on pdb_WalkandWin..LTV_Member_Demographics_2016_Pilot(SavvyHICN)

IF object_id('LTV_Member_Demographics_2017_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Demographics_2017_Pilot;
select a.SavvyHICN, c.Age, c.Gender, c.ZIP, g.OriginalReasonForEntitlement,
	   d.St_Cd, 
       d.MSA,
	   d.FIPS,
	   e.USR_Class,
	   f.Median_Household_Income
into LTV_Member_Demographics_2017_Pilot
from CombinedMember_sg							as a 
left join MiniOV..SavvyID_to_SavvyHICN			as b	on a.SavvyHICN = b.SavvyHICN
left join MiniOV..Dim_Member					as c	on b.SavvyID = c.SavvyID
left join Census.dbo.Zip_Census					as d	on c.ZIP = d.ZIP
left join Census.dbo.ZCTA						as e	on d.ZCTA = e.ZCTA
left join wkg_census_zip						as f	on c.ZIP = f.ZIP
left join wkg_mmr_flags							as g	on a.SavvyHICN = g.SavvyHICN
where a.is2017 = 1

create unique index ix_savvyHICN on pdb_WalkandWin..LTV_Member_Demographics_2017_Pilot(SavvyHICN)

--select * from pdb_WalkandWin..LTV_Member_Demographics_2016_Pilot
--select * from pdb_WalkandWin..LTV_Member_Demographics_2017_Pilot
