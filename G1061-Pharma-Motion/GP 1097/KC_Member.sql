/*** 
GP 1097 - Polypharmacy Member Population
	--revisions to Bijaya's script

Input databases:	MiniPAPI, MiniOV

Date Created: 19 July 2017
***/

--pull for the members
If (object_id('tempdb..#Mbrs') Is Not Null)
Drop Table #Mbrs
go

select mbr.SavvyID, OVId.SavvyHICN, Gender, Age-1 as Age_2016
into #Mbrs   
from MiniOV..Dim_Member        					mbr
inner join MiniOV..SavvyID_to_SavvyHICN			OVId	on  mbr.SavvyID = ovId.SavvyID
inner join MiniPAPI..SavvyID_to_SavvyHICN		pp		on	OVId.SavvyHICN = pp.SavvyHICN	--to ensure we have PAPI data
where MAPDFlag = 1 
	and MedicaidFlag = 0
	and Src_Sys_Cd = 'CO'
	and MM_2016 = 12
	--and SavvyHICN = 18444804
group by mbr.SavvyID, OVId.SavvyHICN, Gender, Age
--(2,173,266 row(s) affected)
create unique index uIx_SavvyHICN on #Mbrs (SavvyHICN);

--count AHFS & Prescriber per member
If (object_id('tempdb..#Mbr_provcnt_ahfscnt') Is Not Null)
Drop Table #Mbr_provcnt_ahfscnt
go

select a.SavvyHICN
	, Cnt_AHFS_201612=  count(distinct f.AHFS_Therapeutic_Clss_Cd)
	, Prov_Cnt = count(distinct g.Prescriber_ID)
into #Mbr_provcnt_ahfscnt
from #Mbrs	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
inner join MiniPAPI..Dim_Prescriber			g	on	c.Prescriber_Sys_Id = g.Prescriber_Sys_ID
where d.YEAR_MO in (201610, 201611, 201612)
	and c.Claim_Status = 'P'
	and e.Maint_Drug_Code = 'X'
	and (f.AHFS_Therapeutic_Clss_Desc is not null
	and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN')
	and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 12
				or datepart(year, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 2017	then 1	else 0	end) = 1	--added 07/21/2017: to handle those fills with day supply crossing over the following year; they have drugs in possession / on hand as of 201612
group by a.SavvyHICN
--(744,726 row(s) affected); 17.05 minutes
--(1,520,213 row(s) affected); 18.26 minutes
create unique index uIx_SavvyHICN on #Mbr_provcnt_ahfscnt (SavvyHICN);

--build the Member table
If (object_id('pdb_PharmaMotion..G1097Members') Is Not Null)
Drop Table pdb_PharmaMotion..G1097Members
go

select a.SavvyHICN, a.Age_2016, a.Gender
	, AgeGrp = case when Age_2016 < 65 then '<65'
					 when Age_2016 between 65 and 74 then '65-74'
					 when Age_2016 between 75 and 84 then '75-84'	else '85+' end
	, Cnt_AHFS_201612 = isnull(b.Cnt_AHFS_201612, 0)
	, Prov_Cnt = isnull(b.Prov_Cnt, 0)
	, OREC = NULL
	, RAF_2016 = NULL
into pdb_PharmaMotion..G1097Members
from #Mbrs	a
left join #Mbr_provcnt_ahfscnt	b	on	a.SavvyHICN = b.SavvyHICN
--(2,173,266 row(s) affected)
create unique index uIx_SavvyHICN on pdb_PharmaMotion..G1097Members (SavvyHICN);

/*
update pdb_PharmaMotion..G1097Members
set Cnt_AHFS_201612 = isnull(b.Cnt_AHFS_201612, 0)
	, Prov_Cnt = isnull(b.Prov_Cnt, 0)
from pdb_PharmaMotion..G1097Members	a
left join #Mbr_provcnt_ahfscnt		b	on	a.SavvyHICN = b.SavvyHICN
*/


select Mbr_AHFSCatgy = case when Cnt_AHFS_201612 = 0	then 'AHFS_0'
							when Cnt_AHFS_201612 = 1	then 'AHFS_1'
							when Cnt_AHFS_201612 = 2	then 'AHFS_2'
							when Cnt_AHFS_201612 = 3	then 'AHFS_3'
							when Cnt_AHFS_201612 = 4	then 'AHFS_4'
								else '[AHFS_5+]'	end	
	, avg(RAF_2016)
from pdb_PharmaMotion..G1097Members
group by case when Cnt_AHFS_201612 = 0	then 'AHFS_0'
				when Cnt_AHFS_201612 = 1	then 'AHFS_1'
				when Cnt_AHFS_201612 = 2	then 'AHFS_2'
				when Cnt_AHFS_201612 = 3	then 'AHFS_3'
				when Cnt_AHFS_201612 = 4	then 'AHFS_4'
					else '[AHFS_5+]'	end	
order by 1

select avg(RAF_2016)
from pdb_PharmaMotion..G1097Members

--including AHFS nulls & unknowns
--count AHFS & Prescriber per member
If (object_id('tempdb..#Mbr_provcnt_ahfscnt_v2') Is Not Null)
Drop Table #Mbr_provcnt_ahfscnt_v2
go

select a.SavvyHICN
	, Cnt_AHFS_201612_wNULLs	=  count(distinct f.AHFS_Therapeutic_Clss_Cd)
	, Prov_Cnt_wNULLs = count(distinct g.Prescriber_ID)
into #Mbr_provcnt_ahfscnt_v2
from pdb_PharmaMotion..G1097Members	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
inner join MiniPAPI..Dim_Prescriber			g	on	c.Prescriber_Sys_Id = g.Prescriber_Sys_ID
where d.YEAR_MO in (201610, 201611, 201612)
	and c.Claim_Status = 'P'
	and e.Maint_Drug_Code = 'X'
	--and (f.AHFS_Therapeutic_Clss_Desc is not null
	--and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN')
	and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 12
				or datepart(year, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 2017	then 1	else 0	end) = 1	--added 07/21/2017: to handle those fills with day supply crossing over the following year; they have drugs in possession / on hand as of 201612
group by a.SavvyHICN
--(1,826,084 row(s) affected); 22.35 minutes
create unique index uIx_SavvyHICN on #Mbr_provcnt_ahfscnt_v2 (SavvyHICN);

alter table pdb_PharmaMotion..G1097Members
	add Cnt_AHFS_201612_wNULLs smallint
		, Prov_Cnt_wNULLs smallint
go

update pdb_PharmaMotion..G1097Members
set Cnt_AHFS_201612_wNULLs = isnull(b.Cnt_AHFS_201612_wNULLs, 0)
	, Prov_Cnt_wNULLs = isnull(b.Prov_Cnt_wNULLs, 0)
from pdb_PharmaMotion..G1097Members	a
left join #Mbr_provcnt_ahfscnt_v2	b	on	a.SavvyHICN = b.SavvyHICN

select *
from pdb_PharmaMotion..G1097Members