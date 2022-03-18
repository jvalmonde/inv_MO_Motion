-------------------------------------------------------------
--1) Get member details for distinct SavvyHICNs
-------------------------------------------------------------
select distinct SavvyHICN
into #members
from pdb_WalkandWin..LTV_Member_Lifetime_ID

--get MMR flags (OREC)
select a.SavvyHICN, max(a.OriginalReasonForEntitlement) as OriginalReasonForEntitlement
into #mmr_flags
from pdb_WalkandWin..CMS_MMR_Subset_20170727		as a 
join #members						as b	on a.SavvyHICN = b.SavvyHICN
group by a.SavvyHICN
--45,403


--get Median household income at ZIP level
select b.Zip, a.ZCTA, 
	   c.B19013_001 as Median_Household_Income
into #census_zip
from DEVSQL15.Census.dbo.ACS_Geography			as a	
join DEVSQL15.Census.dbo.Zip_Census				as b	on a.ZCTA = b.ZCTA
join DEVSQL15.Census.dbo.ACS_MedianIncome       as c	on a.StateCode = c.StateCode 
													   and a.LogRecNo = c.LogRecNo
													  and a.[Year] = c.[Year]
where a.GeographyType = 'ZCTA Level'
  and c.StatisticsID = 1
  and c.Year = 2015
--41,361

-- drop table pdb_WalkandWin..LTV_Member_Demographics
select a.SavvyHICN, c.Age, c.Gender, c.ZIP, g.OriginalReasonForEntitlement,
	   d.St_Cd, 
       d.MSA,
	   d.FIPS,
	   e.USR_Class,
	   f.Median_Household_Income
into pdb_WalkandWin..LTV_Member_Demographics
from #members									as a 
left join MiniOV..SavvyID_to_SavvyHICN			as b	on a.SavvyHICN = b.SavvyHICN
left join MiniOV..Dim_Member					as c	on b.SavvyID = c.SavvyID
left join DEVSQL15.Census.dbo.Zip_Census		as d	on c.ZIP = d.ZIP
left join DEVSQL15.Census.dbo.ZCTA				as e	on d.ZCTA = e.ZCTA
left join #census_zip							as f	on c.ZIP = f.ZIP
left join #mmr_flags							as g	on a.SavvyHICN = g.SavvyHICN
--45366

create unique index ix_savvyHICN on pdb_WalkandWin..LTV_Member_Demographics(SavvyHICN)

select * from pdb_WalkandWin..LTV_Member_Demographics