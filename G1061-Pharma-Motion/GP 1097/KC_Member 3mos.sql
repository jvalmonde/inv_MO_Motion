/*** 
GP 1097 - Polypharmacy Member Population looking at 3 months time (Oct- Dec 2016)
	--revisions to Bijaya's script

Input databases:	MiniPAPI, MiniOV

Date Created: 21 July 2017
***/

--count AHFS & Prescriber per member
If (object_id('tempdb..#Mbr_provcnt_ahfscnt') Is Not Null)
Drop Table #Mbr_provcnt_ahfscnt
go

select a.SavvyHICN
	, Cnt_AHFS = count(distinct f.AHFS_Therapeutic_Clss_Cd)
	, Cnt_AHFS_Oct2016	=  count(distinct case when d.YEAR_MO = 201610	then f.AHFS_Therapeutic_Clss_Cd	end)
	, Cnt_AHFS_Nov2016	=  count(distinct case when d.YEAR_MO = 201611	then f.AHFS_Therapeutic_Clss_Cd	end)
	, Cnt_AHFS_Dec2016	=  count(distinct case when d.YEAR_MO = 201612	then f.AHFS_Therapeutic_Clss_Cd	end)
	, Prov_Cnt = count(distinct g.Prescriber_ID)
	, Prov_Cnt_Oct2016	= count(distinct case when d.YEAR_MO = 201610	then g.Prescriber_ID end)
	, Prov_Cnt_Nov2016	= count(distinct case when d.YEAR_MO = 201611	then g.Prescriber_ID end)
	, Prov_Cnt_Dec2016	= count(distinct case when d.YEAR_MO = 201612	then g.Prescriber_ID end)
into #Mbr_provcnt_ahfscnt
from pdb_PharmaMotion..G1097Members	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
inner join MiniPAPI..Dim_Prescriber			g	on	c.Prescriber_Sys_Id = g.Prescriber_Sys_ID
where d.YEAR_MO between 201607 and 201612
	and c.Claim_Status = 'P'
	and e.Maint_Drug_Code = 'X'
	and (f.AHFS_Therapeutic_Clss_Desc is not null
	and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN')
	and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) in (10, 11, 12)
				or datepart(year, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 2017	then 1	else 0	end) = 1	--added 07/21/2017: to handle those fills with day supply crossing over the following year; they have drugs in possession / on hand as of 201612
group by a.SavvyHICN
--(1,659,864 row(s) affected)
create unique index uIx_SavvyHICN on #Mbr_provcnt_ahfscnt (SavvyHICN);


If (object_id('tempdb..#Mbr_provcnt_ahfscnt_wf') Is Not Null)
Drop Table #Mbr_provcnt_ahfscnt_wf
go

select a.SavvyHICN
	, Cnt_AHFS = count(distinct f.AHFS_Therapeutic_Clss_Cd)
	, Cnt_AHFS_Oct2016	=  count(distinct case when d.YEAR_MO = 201610	then f.AHFS_Therapeutic_Clss_Cd	end)
	, Cnt_AHFS_Nov2016	=  count(distinct case when d.YEAR_MO = 201611	then f.AHFS_Therapeutic_Clss_Cd	end)
	, Cnt_AHFS_Dec2016	=  count(distinct case when d.YEAR_MO = 201612	then f.AHFS_Therapeutic_Clss_Cd	end)
	, Prov_Cnt = count(distinct g.Prescriber_ID)
	, Prov_Cnt_Oct2016	= count(distinct case when d.YEAR_MO = 201610	then g.Prescriber_ID end)
	, Prov_Cnt_Nov2016	= count(distinct case when d.YEAR_MO = 201611	then g.Prescriber_ID end)
	, Prov_Cnt_Dec2016	= count(distinct case when d.YEAR_MO = 201612	then g.Prescriber_ID end)
into #Mbr_provcnt_ahfscnt_wf
from pdb_PharmaMotion..G1097Members	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
inner join MiniPAPI..Dim_Prescriber			g	on	c.Prescriber_Sys_Id = g.Prescriber_Sys_ID
where d.YEAR_MO between 201607 and 201612
	and c.Claim_Status = 'P'
	and e.Maint_Drug_Code = 'X'
	--and (f.AHFS_Therapeutic_Clss_Desc is not null
	--and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN')
	and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) in (10, 11, 12)
				or datepart(year, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 2017	then 1	else 0	end) = 1	--added 07/21/2017: to handle those fills with day supply crossing over the following year; they have drugs in possession / on hand as of 201612
group by a.SavvyHICN
--(1,898,721 row(s) affected); 37.23 minutes (2 block of codes)
create unique index uIx_SavvyHICN on #Mbr_provcnt_ahfscnt_wf (SavvyHICN);


--build the Member table
If (object_id('pdb_PharmaMotion..G1097Members_3mos') Is Not Null)
Drop Table pdb_PharmaMotion..G1097Members_3mos
go

select a.SavvyHICN, a.Age_2016, a.Gender
	, a.AgeGrp
	, Cnt_AHFS = isnull(b.Cnt_AHFS, 0)
	, Cnt_AHFS_Oct2016	= isnull(b.Cnt_AHFS_Oct2016, 0)
	, Cnt_AHFS_Nov2016	= isnull(b.Cnt_AHFS_Nov2016, 0)
	, Cnt_AHFS_Dec2016	= isnull(b.Cnt_AHFS_Dec2016, 0)
	, Prov_Cnt = isnull(b.Prov_Cnt, 0)
	, Prov_Cnt_Oct2016	= isnull(b.Prov_Cnt_Oct2016, 0)
	, Prov_Cnt_Nov2016	= isnull(b.Prov_Cnt_Nov2016, 0)
	, Prov_Cnt_Dec2016	= isnull(b.Prov_Cnt_Dec2016, 0)
	, a.OREC
	, a.RAF_2016
	, a.HCC_Cnt
into pdb_PharmaMotion..G1097Members_3mos
from pdb_PharmaMotion..G1097Members	a
left join #Mbr_provcnt_ahfscnt		b	on	a.SavvyHICN = b.SavvyHICN
--(2,173,266 row(s) affected)
create unique index uIx_SavvyHICN on pdb_PharmaMotion..G1097Members_3mos (SavvyHICN);


If (object_id('pdb_PharmaMotion..G1097Members_3mos_w_unk') Is Not Null)
Drop Table pdb_PharmaMotion..G1097Members_3mos_w_unk
go

select a.SavvyHICN, a.Age_2016, a.Gender
	, a.AgeGrp
	, Cnt_AHFS = isnull(b.Cnt_AHFS, 0)
	, Cnt_AHFS_Oct2016	= isnull(b.Cnt_AHFS_Oct2016, 0)
	, Cnt_AHFS_Nov2016	= isnull(b.Cnt_AHFS_Nov2016, 0)
	, Cnt_AHFS_Dec2016	= isnull(b.Cnt_AHFS_Dec2016, 0)
	, Prov_Cnt = isnull(b.Prov_Cnt, 0)
	, Prov_Cnt_Oct2016	= isnull(b.Prov_Cnt_Oct2016, 0)
	, Prov_Cnt_Nov2016	= isnull(b.Prov_Cnt_Nov2016, 0)
	, Prov_Cnt_Dec2016	= isnull(b.Prov_Cnt_Dec2016, 0)
	, a.OREC
	, a.RAF_2016
	, a.HCC_Cnt
into pdb_PharmaMotion..G1097Members_3mos_w_unk
from pdb_PharmaMotion..G1097Members		a
left join #Mbr_provcnt_ahfscnt_wf		b	on	a.SavvyHICN = b.SavvyHICN
--(2,173,266 row(s) affected)
create unique index uIx_SavvyHICN on pdb_PharmaMotion..G1097Members_3mos_w_unk (SavvyHICN);

