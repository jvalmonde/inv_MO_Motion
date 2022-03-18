/*** 
GP 1097 - Polypharmacy Prescription pairing

Input databases:	MiniPAPI, MiniOV

Date Created: 30 June 2017
***/

--create unique index uIx_SavvyHICN on pdb_PharmaMotion..G1097Members (SavvyHICN);

/*--pull for their pharmacy claims per AHFS
If (object_id('tempdb..#mbr_ahfscnt') Is Not Null)
Drop Table #mbr_ahfscnt
go

select SavvyHICN
	, Cnt_AHFS = count(distinct AHFS_Therapeutic_Clss_Cd)
into #mbr_ahfscnt
from	(
			select a.SavvyHICN, f.AHFS_Therapeutic_Clss_Cd
				, ScriptThruDt = dateadd(dd, c.Day_Supply, d.FULL_DT)
				, Flag_asofDec = case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 12	then 1	else 0	end
			from pdb_PharmaMotion..G1097Members	a
			inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
			inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
			inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
			inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
			where d.YEAR_MO in (201610, 201611, 201612)
				and c.Claim_Status = 'P'
				and e.Maint_Drug_Code = 'X'
				and (f.AHFS_Therapeutic_Clss_Desc is not null
				and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN')
			group by a.SavvyHICN, f.AHFS_Therapeutic_Clss_Cd, c.Day_Supply, d.FULL_DT
	) z
where Flag_asofDec = 1 
group by SavvyHICN
--(744,726 row(s) affected); 23.21 minutes
create unique index uIx_SavvyHICN on #mbr_ahfscnt (SavvyHICN);

select Cnt_AHFS_201612
	, Mbr_Cnt = count(*)
from pdb_PharmaMotion..G1097Members
group by Cnt_AHFS_201612
order by 1

--update member table with AHFS counts
alter table pdb_PharmaMotion..G1097Members
	add Cnt_AHFS_201612 smallint
go

update pdb_PharmaMotion..G1097Members
set Cnt_AHFS_201612 = isnull(b.Cnt_AHFS, 0)
from pdb_PharmaMotion..G1097Members	a
left join #mbr_ahfscnt				b	on	a.SavvyHICN = b.SavvyHICN
--(1846983 row(s) affected)

select count(*) from #mbr_ahfscnt where Cnt_AHFS = 2	--178,370
select count(*) from #mbr_ahfscnt where Cnt_AHFS = 3	--87,003
*/
--pull for the most common pairings
If (object_id('tempdb..#mbr_2pairs') Is Not Null)
Drop Table #mbr_2pairs
go

select SavvyHICN, AHFS_Therapeutic_Clss_Desc
	, RN = row_number() over(partition by SavvyHICN order by AHFS_Therapeutic_Clss_Desc)
	--, AHFS_Flag = 1
into #mbr_2pairs
from	(
			select a.SavvyHICN, a.Cnt_AHFS_201612, f.AHFS_Therapeutic_Clss_Desc
				, OID = row_Number() over(partition by a.SavvyHICN, f.AHFS_Therapeutic_Clss_Desc order by c.Date_Of_Service_DtSysId desc)
			from pdb_PharmaMotion..G1097Members	a
			inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
			inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
			inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
			inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
			where d.YEAR_MO in (201610, 201611, 201612)
				and c.Claim_Status = 'P'
				and e.Maint_Drug_Code = 'X'
				and a.Cnt_AHFS_201612 >= 2
				--and a.SavvyHICN = 2074603
				and f.AHFS_Therapeutic_Clss_Desc is not null
				and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN'
				and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 12
							or datepart(year, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 2017	then 1	else 0	end) = 1	--added 07/21/2017: to handle those fills with day supply crossing over the following year; they have drugs in possession / on hand as of 201612
			group by a.SavvyHICN, a.Cnt_AHFS_201612, f.AHFS_Therapeutic_Clss_Desc, c.Date_Of_Service_DtSysId 
		) z
where OID = 1
--(1,002,592 row(s) affected); 10.35 minutes
--(3,088,293 row(s) affected); 12.41 minutes
create unique index uIx_SavvyHICN_RN on #mbr_2pairs (SavvyHICN, RN);

select * from #mbr_2pairs where SavvyHICN = 53658 order by RN

-----------------------------
--permutations
-----------------------------
If (object_id('tempdb..#AHFS_pmt') Is Not Null)
Drop Table #AHFS_pmt
go

select RN = row_number() over(order by AHFS_Therapeutic_Clss_Desc)
	, AHFS = AHFS_Therapeutic_Clss_Desc
into #AHFS_pmt
from	(
			select distinct b.AHFS_Therapeutic_Clss_Desc
			from MiniPAPI..Dim_Drug	a
			inner join MiniHPDM..Dim_Drug_Class	b	on	a.NDC = b.NDC
			where a.Maint_Drug_Code = 'X'
				and b.AHFS_Therapeutic_Clss_Desc is not null
				and b.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN'
		) z
--(143 row(s) affected)

If (object_id('tempdb..#AHFS_pairs') Is Not Null)
Drop Table #AHFS_pairs
go

with permute as (
	select rn = dense_rank() over(order by AHFS), AHFS
	from #AHFS_pmt
)
select rn_1 = p1.rn, AHFS_1 = p1.AHFS
	, rn_2 = p2.rn, AHFS_2 = p2.AHFS
	, Combi = rtrim(p1.AHFS) + ' + ' + rtrim(p2.AHFS)
	, RN_id = cast(p1.rn as varchar) + ';' + cast(p2.rn as varchar)
into #AHFS_pairs
from permute p1, permute p2
where p1.rn < p2.rn
order by p1.rn, p2.rn
--(1,224,510 row(s) affected)
create unique index uIx_RnID on #AHFS_pairs (RN_id);

select * from #AHFS_pairs

If (object_id('tempdb..#AHFS_mbrpairs') Is Not Null)
Drop Table #AHFS_mbrpairs
go

with mbr_permute as (
	select a.SavvyHICN, AHFS = b.AHFS_Therapeutic_Clss_Desc, z.RN
		, OID = dense_rank() over(partition by a.SavvyHICN order by z.RN)
	--select *
	from pdb_PharmaMotion..G1097Members	a
	inner join #mbr_2pairs	b	on	a.SavvyHICN = b.SavvyHICN
		cross apply (--assigning of pair combination id
						select *
						from #AHFS_pmt	rn
						where b.AHFS_Therapeutic_Clss_Desc = rn.AHFS
						)	z
	where a.Cnt_AHFS_201612 >= 2
	--where a.SavvyHICN = 224	--in (2161187, 6944544)
	)
select p1.SavvyHICN
	, RN_id = cast(p1.RN as varchar) + ';' + cast(p2.RN as varchar)
	--, *
into #AHFS_mbrpairs
from mbr_permute p1, mbr_permute p2
where p1.SavvyHICN = p2.SavvyHICN
	and p1.OID < p2.OID
--where p1.OID < p2.OID
order by p1.OID, p2.OID
--(1,224,510 row(s) affected)
--(4,201,760 row(s) affected)
create unique index uIx_MbrID_RnID on #AHFS_mbrpairs (SavvyHICN, RN_id);

--select * from #AHFS_mbrpairs where SavvyHICN = 224

-----------------------------
--top prescription pairings per AHFS Category
-----------------------------
If (object_id('pdb_PharmaMotion..G1097_PairsAHFS') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_PairsAHFS
go

select c.Combi
	, Mbr_Cnt = count(distinct a.SavvyHICN)
	, AHFS_0 = count(distinct case when a.Cnt_AHFS_201612 = 0	then a.SavvyHICN	end)
	, AHFS_1 = count(distinct case when a.Cnt_AHFS_201612 = 1	then a.SavvyHICN	end)
	, AHFS_2 = count(distinct case when a.Cnt_AHFS_201612 = 2	then a.SavvyHICN	end)
	, AHFS_3 = count(distinct case when a.Cnt_AHFS_201612 = 3	then a.SavvyHICN	end)
	, AHFS_4 = count(distinct case when a.Cnt_AHFS_201612 = 4	then a.SavvyHICN	end)
	, AHFS_5 = count(distinct case when a.Cnt_AHFS_201612 = 5	then a.SavvyHICN	end)
	, [AHFS_6+] = count(distinct case when a.Cnt_AHFS_201612 >= 6	then a.SavvyHICN	end)
	, OID = row_number() over(order by count(distinct a.SavvyHICN) desc)
into pdb_PharmaMotion..G1097_PairsAHFS
--select *
from pdb_PharmaMotion..G1097Members	a
inner join #AHFS_mbrpairs	b	on	a.SavvyHICN = b.SavvyHICN
inner join #AHFS_pairs		c	on	b.RN_id = c.RN_id
---where a.SavvyHICN = 2161187
--where c.Combi = 'ASP_SPEC_BACT_PNEUM_PRES_ULCER + CANCER_IMMUNE' 
group by c.Combi
--(4839 row(s) affected)
--(5415 row(s) affected)

select * 
from pdb_PharmaMotion..G1097_PairsAHFS
where OID <= 100

select Pair_AHFS = 'OTHERS'
	, Mbr_Cnt = sum(Mbr_Cnt)
	, AHFS_0 = sum(AHFS_0)
	, AHFS_1 = sum(AHFS_1)
	, AHFS_2 = sum(AHFS_2)
	, AHFS_3 = sum(AHFS_3)
	, AHFS_4 = sum(AHFS_4)
	, AHFS_5 = sum(AHFS_5)
	, [AHFS_6+] = sum([AHFS_6+])
	, Pair_Cnt = count(distinct Combi)
from pdb_PharmaMotion..G1097_PairsAHFS
where OID > 100


If (object_id('tempdb..#mbr_3pairs') Is Not Null)
Drop Table #mbr_3pairs
go

select SavvyHICN, AHFS_Therapeutic_Clss_Desc
	, RN = row_number() over(partition by SavvyHICN order by AHFS_Therapeutic_Clss_Desc)
into #mbr_3pairs
from	(
			select a.SavvyHICN, a.Cnt_AHFS_201612, f.AHFS_Therapeutic_Clss_Desc
				, OID = row_Number() over(partition by a.SavvyHICN, f.AHFS_Therapeutic_Clss_Desc order by c.Date_Of_Service_DtSysId desc)
			from pdb_PharmaMotion..G1097Members	a
			inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
			inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
			inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
			inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
			where d.YEAR_MO in (201610, 201611, 201612)
				and c.Claim_Status = 'P'
				and e.Maint_Drug_Code = 'X'
				and a.Cnt_AHFS_201612 >= 3
				--and a.SavvyHICN = 2074603
				and f.AHFS_Therapeutic_Clss_Desc is not null
				and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN'
				and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 12	then 1	else 0	end) = 1
			group by a.SavvyHICN, a.Cnt_AHFS_201612, f.AHFS_Therapeutic_Clss_Desc, c.Date_Of_Service_DtSysId 
		) z
where OID = 1
--(645,852 row(s) affected);
--(949,159 row(s) affected)
create unique index uIx_SavvyHICN_RN on #mbr_3pairs (SavvyHICN, RN);

If (object_id('tempdb..#AHFS_triplicates') Is Not Null)
Drop Table #AHFS_triplicates
go

with permute as (
	select rn = dense_rank() over(order by AHFS), AHFS
	from #AHFS_pmt
)
select rn_1 = p1.rn, AHFS_1 = p1.AHFS
	, rn_2 = p2.rn, AHFS_2 = p2.AHFS
	, rn_3 = p3.rn, AHFS_3 = p3.AHFS
	, Combi = rtrim(p1.AHFS) + ' + ' + rtrim(p2.AHFS) + ' + ' + rtrim(p3.AHFS)
	, RN_id = cast(p1.rn as varchar) + ';' + cast(p2.rn as varchar) + ';' + cast(p3.rn as varchar)
into #AHFS_triplicates
from permute p1, permute p2, permute p3
where p1.rn < p2.rn
	and p2.rn < p3.rn
order by p1.rn, p2.rn
--(477,191 row(s) affected)
create unique index uIx_RnID on #AHFS_triplicates (RN_id);

If (object_id('pdb_PharmaMotion..tmp_AHFS_mbrtriplicates') Is Not Null)
Drop Table pdb_PharmaMotion..tmp_AHFS_mbrtriplicates
go

with mbr_permute as (
	select a.SavvyHICN, AHFS = b.AHFS_Therapeutic_Clss_Desc, z.RN
		, OID = dense_rank() over(partition by a.SavvyHICN order by z.RN)
	--select *
	from pdb_PharmaMotion..G1097Members	a
	inner join #mbr_2pairs	b	on	a.SavvyHICN = b.SavvyHICN
		cross apply (--assigning of pair combination id
						select *
						from #AHFS_pmt	rn
						where b.AHFS_Therapeutic_Clss_Desc = rn.AHFS
						)	z
	where a.Cnt_AHFS_201612 >= 3
	--where a.SavvyHICN = 224	--in (2161187, 6944544)
	)
select p1.SavvyHICN
	, RN_id = cast(p1.RN as varchar) + ';' + cast(p2.RN as varchar) + ';' + cast(p3.RN as varchar)
	--, *
into pdb_PharmaMotion..tmp_AHFS_mbrtriplicates
from mbr_permute p1, mbr_permute p2, mbr_permute p3
where p1.SavvyHICN = p2.SavvyHICN
	and p2.SavvyHICN = p3.SavvyHICN
	and p1.OID < p2.OID
	and p2.OID < p3.OID
--where p1.OID < p2.OID
order by p1.OID, p2.OID, p3.OID
--(1,009,573 row(s) affected)
--(3,833,512 row(s) affected)
create unique index uIx_MbrID_RnID on pdb_PharmaMotion..tmp_AHFS_mbrtriplicates (SavvyHICN, RN_id);

If (object_id('pdb_PharmaMotion..G1097_TriplicatesAHFS') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_TriplicatesAHFS
go

select c.Combi
	, Mbr_Cnt = count(distinct a.SavvyHICN)
	, AHFS_0 = count(distinct case when a.Cnt_AHFS_201612 = 0	then a.SavvyHICN	end)
	, AHFS_1 = count(distinct case when a.Cnt_AHFS_201612 = 1	then a.SavvyHICN	end)
	, AHFS_2 = count(distinct case when a.Cnt_AHFS_201612 = 2	then a.SavvyHICN	end)
	, AHFS_3 = count(distinct case when a.Cnt_AHFS_201612 = 3	then a.SavvyHICN	end)
	, AHFS_4 = count(distinct case when a.Cnt_AHFS_201612 = 4	then a.SavvyHICN	end)
	, AHFS_5 = count(distinct case when a.Cnt_AHFS_201612 = 5	then a.SavvyHICN	end)
	, [AHFS_6+] = count(distinct case when a.Cnt_AHFS_201612 >= 6	then a.SavvyHICN	end)
	, OID = row_number() over(order by count(distinct a.SavvyHICN) desc)
into pdb_PharmaMotion..G1097_TriplicatesAHFS
--select *
from pdb_PharmaMotion..G1097Members	a
inner join pdb_PharmaMotion..tmp_AHFS_mbrtriplicates	b	on	a.SavvyHICN = b.SavvyHICN
inner join #AHFS_triplicates		c	on	b.RN_id = c.RN_id
---where a.SavvyHICN = 2161187
--where c.Combi = 'ASP_SPEC_BACT_PNEUM_PRES_ULCER + CANCER_IMMUNE' 
group by c.Combi
--(51,438 row(s) affected)
--(76,844 row(s) affected)

select *
from pdb_PharmaMotion..G1097_TriplicatesAHFS
where OID <= 100

select Pair_AHFS = 'OTHERS'
	, Mbr_Cnt = sum(Mbr_Cnt)
	, AHFS_0 = sum(AHFS_0)
	, AHFS_1 = sum(AHFS_1)
	, AHFS_2 = sum(AHFS_2)
	, AHFS_3 = sum(AHFS_3)
	, AHFS_4 = sum(AHFS_4)
	, AHFS_5 = sum(AHFS_5)
	, [AHFS_6+] = sum([AHFS_6+])
	, Pair_Cnt = count(distinct Combi)
from pdb_PharmaMotion..G1097_TriplicatesAHFS
where OID > 100
