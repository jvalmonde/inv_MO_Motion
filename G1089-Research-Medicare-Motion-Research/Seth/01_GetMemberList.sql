use pdb_WalkandWin
go

IF object_id('tempdb..#cteCombinedSavvyHICN','U') IS NOT NULL
	DROP TABLE #cteCombinedSavvyHICN;
WITH 
	cteSavvyHICNSources as
		(select distinct SavvyHICN, is2016 = 0, is2017 = 1
		from pdb_WalkandWin.dbo.CMS_MMR_Subset_20170727
		
		union all
		
		select distinct SavvyHICN, is2016 = 0, is2017 = 1
		from pdb_WalkandWin.dbo.CMS_MMR_Subset_20170728 
		where ISNUMERIC(SavvyHICN)		=	1	--to deal with a bad row
		
		union all
		
		select distinct SavvyHICN, is2016 = 1, is2017 = 0
		from pdb_WalkandWin.dbo.WnW_Dataset_Sam
		where Outreach_Method in ('Mail','IVR')
		
		union all
		
		select distinct SavvyHICN, is2016 = 1, is2017 = 0
		from pdb_WalkandWin.dbo.WnW_Dataset_Sam_sg2016
		where Outreach_Method in ('Mail','IVR')
		)
select SavvyHICN, 
	is2016				=	max(is2016), 
	is2017				=	max(is2017)
into #cteCombinedSavvyHICN
from cteSavvyHICNSources
group by SavvyHICN
go
create clustered index cixSavvyHICN on #cteCombinedSavvyHICN(SavvyHICN)
go

--Members:
--select count(distinct SavvyHICN) from LTV.dbo.CMS_MMR_Sub_201709
IF object_id('CombinedMember_sg','U') IS NOT NULL
	DROP TABLE CombinedMember_sg;
select 
	a.SavvyHICN,
	SavvyID_OV				=	b.SavvyID,
	HICNumber				=	c.HICN,
	a.is2016,
	a.is2017
into CombinedMember_sg
from 
	#cteCombinedSavvyHICN								a
	left join MiniOV.dbo.SavvyID_to_SavvyHICN			b	on	a.SavvyHICN		=	b.SavvyHICN
	join DBSEP3858.MiniOV_PHI.dbo.Lookup_HICN			c	on	a.SavvyHICN		=	c.SavvyHICN
go
create clustered index cixSavvyHICN on CombinedMember_sg(SavvyHICN)
create index ixHICNumber on CombinedMember_sg(HICNumber)
go

/*
IF object_id('CmsMMR_Subset_20180313','U') IS NOT NULL
	DROP TABLE CmsMMR_Subset_20180313;
select 
	b.SavvyHICN, a.*
into CmsMMR_Subset_20180313
from 
	DBSEP0230.CMS.dbo.CmsMMR								a
	join DBSEP3832.pdb_WalkandWin.dbo.CombinedMember_sg		b	
			on	a.HICNumber		=	b.HICNumber
go
create clustered index cixSavvyHICN on CmsMMR_Subset_20180313(SavvyHICN)
go

IF object_id('CmsMOR_Subset_20180313','U') IS NOT NULL
	DROP TABLE CmsMOR_Subset_20180313;
select 
	b.SavvyHICN, a.*
into CmsMOR_Subset_20180313
from 
	DBSEP0230.CMS.dbo.CmsMOR								a
	join DBSEP3832.pdb_WalkandWin.dbo.CombinedMember_sg		b	
			on	a.HICNumber		=	b.HICNumber
go
create clustered index cixSavvyHICN on CmsMOR_Subset_20180313(SavvyHICN)
go

IF object_id('CmsTRR_Subset_20180313','U') IS NOT NULL
	DROP TABLE CmsTRR_Subset_20180313;
select 
	b.SavvyHICN, a.*
into CmsTRR_Subset_20180313
from 
	DBSEP0230.CMS.dbo.CmsTRR								a
	join DBSEP3832.pdb_WalkandWin.dbo.CombinedMember_sg		b	
			on	a.HICNumber		=	b.HICNumber
go
create clustered index cixSavvyHICN on CmsTRR_Subset_20180313(SavvyHICN)
go
*/

/* 
--use SQL importer/exporter to create CmsMMR_Subset_20180313 as
select 
	b.SavvyHICN, a.*
from 
	DBSEP0230.CMS.dbo.CmsMMR								a
	join DBSEP3832.pdb_WalkandWin.dbo.CombinedMember_sg		b	
			on	a.HICNumber		=	b.HICNumber

--use SQL importer/exporter to create CmsMOR_Subset_20180313 as
select 
	b.SavvyHICN, a.*
from 
	DBSEP0230.CMS.dbo.CmsMOR								a
	join DBSEP3832.pdb_WalkandWin.dbo.CombinedMember_sg		b	
			on	a.HICNumber		=	b.HICNumber

--use SQL importer/exporter to create CmsTRR_Subset_20180313 as
select 
	b.SavvyHICN, a.*
from 
	DBSEP0230.CMS.dbo.CmsTRR								a
	join DBSEP3832.pdb_WalkandWin.dbo.CombinedMember_sg		b	
			on	a.HICNumber		=	b.HICNumber


*/