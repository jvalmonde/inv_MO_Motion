/*** 
GP 1097 - Polypharmacy - Charlson Characterization

Input databases:	MiniPAPI, MiniOV, Charlson

Date Created: 05 July 2017
***/

--create index uIx_ChrncCondNm_ICD on Charlson..[Charlson Codes List w ICD10] (Chrnc_Cond_Nm, ICD_CD);

If (object_id('tempdb..#charlson') Is Not Null)
Drop Table #charlson
go

select a.SavvyHICN, f.Chrnc_Cond_Nm, e.DIAG_CD, d.FULL_DT
into #charlson
from pdb_PharmaMotion..G1097Members					a
inner join MiniOV..SavvyID_to_SavvyHICN				b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Fact_Diagnosis					c	on	b.SavvyID = c.SavvyId
														and c.Diag_Type in (1, 2, 3)
inner join MiniOV..Dim_Date							d	on	c.Dt_Sys_Id = d.DT_SYS_ID
inner join MiniOV..Dim_Diagnosis_Code				e	on	c.Diag_Cd_Sys_Id = e.Diag_Cd_Sys_Id
inner join Charlson..[Charlson Codes List w ICD10]	f	on	e.DIAG_CD = f.ICD_CD
where d.YEAR_NBR = 2016
group by a.SavvyHICN, f.Chrnc_Cond_Nm, e.DIAG_CD, d.FULL_DT
--(31,212,321 row(s) affected)
create index Ix_SavvyHICN on #charlson (SavvyHICN);


Exec Charlson.dbo.Charlson_Computation
	@Input_Table_Location  = '#charlson'
	,@Unique_Member_Id = 'SavvyHICN'
	,@Diagnosis_Code = 'DIAG_CD'
	,@Full_date = 'FULL_DT'
	,@Start_YearMo	= 201601
	,@End_YearMo	= 201612
	,@Output_Prefix = 'G1097'
	,@Output_Database = 'pdb_PharmaMotion'
	,@Output_Suffix = '2016' 
go
--(1782633 row(s) affected); 5.44 hours


--unpivot charlson flags
--create unique index uIx_MemberID on pdb_PharmaMotion..G1097_Charlson_2016_20170705 (Unique_Member_Id);

If (object_id('tempdb..#mbr_charlson') Is Not Null)
Drop Table #mbr_charlson
go

select a.SavvyHICN, a.Cnt_AHFS_201612
	, Charlson_Var_1
	, AIDS_HIV_1
	, AMI_1
	, Angina_1
	, Cancer_1
	, CEVD_1
	, CHF_1
	, COPD_1
	, Dementia_1
	, Diabetes_1
	, Hypertension_1
	, Liver_1
	, Paralysis_1
	, PVD_1
	, Renal_Failure_1
	, Rheumatic_1
	, Ulcers_1
	, Depression_1
	, Skin_1
into #mbr_charlson
from pdb_PharmaMotion..G1097Members	a
left join pdb_PharmaMotion..G1097_Charlson_2016_20170719	b	on	a.SavvyHICN = b.Unique_Member_Id
--(2,173,266 row(s) affected)
create unique index uIx_SavvyHICN on #mbr_charlson (SavvyHICN);

If (object_id('pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt') Is Not Null)
Drop Table pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt
go

DECLARE @query AS NVARCHAR(MAX);

DECLARE @cols AS NVARCHAR(MAX);

select @cols = STUFF(--identify columns to unpivot
								(SELECT distinct ',' + QUOTENAME(name)
								  from  tempdb.sys.columns where object_id = object_id('tempdb..#mbr_charlson')
								  	AND name <> 'SavvyHICN' 
									AND name <> 'Cnt_AHFS_201612' 
									AND name <> 'Charlson_Var_1'
								  FOR XML PATH(''), TYPE
								 ).value('.', 'NVARCHAR(MAX)') 
							, 1, 1, ''
							);

SELECT @query = '
select SavvyHICN, Cnt_AHFS_201612, Charlson_Var_1, Charlson_Var, Charlson
into pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt
from (
		select SavvyHICN, Cnt_AHFS_201612, Charlson_Var_1, ' + @cols + '
		from #mbr_charlson
	) as sub1
unpivot
(
	Charlson 
	for Charlson_Var in (' + @cols + ')
) as unpiv';

EXECUTE(@query);
--(32,087,394 row(s) affected)

delete from pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt
where Charlson = 0
--(27,340,404 row(s) affected)

select count(*) from pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt	--4,746,990
select * from pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt where SavvyHICN = 133516
select * from #mbr_charlson where SavvyHICN = 133516

select Charlson_Var
	, AHFS_0 = count(distinct case when Cnt_AHFS_201612 = 0	then SavvyHICN	end)
	, AHFS_1 = count(distinct case when Cnt_AHFS_201612 = 1	then SavvyHICN	end)
	, AHFS_2 = count(distinct case when Cnt_AHFS_201612 = 2	then SavvyHICN	end)
	, AHFS_3 = count(distinct case when Cnt_AHFS_201612 = 3	then SavvyHICN	end)
	, AHFS_4 = count(distinct case when Cnt_AHFS_201612 = 4	then SavvyHICN	end)
	, AHFS_5 = count(distinct case when Cnt_AHFS_201612 >= 5	then SavvyHICN	end)
	--, [AHFS_6+] = count(distinct case when Cnt_AHFS_201612 >= 6	then SavvyHICN	end)
from pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt
--where SavvyHICN = 16454853
group by Charlson_Var
order by 1

select AHFS_0 = avg(case when Cnt_AHFS_201612 = 0	then Charlson_Var_1	end)
	, AHFS_1 = avg(case when Cnt_AHFS_201612 = 1	then Charlson_Var_1	end)
	, AHFS_2 = avg(case when Cnt_AHFS_201612 = 2	then Charlson_Var_1	end)
	, AHFS_3 = avg(case when Cnt_AHFS_201612 = 3	then Charlson_Var_1	end)
	, AHFS_4 = avg(case when Cnt_AHFS_201612 = 4	then Charlson_Var_1	end)
	, AHFS_5 = avg(case when Cnt_AHFS_201612 >= 5	then Charlson_Var_1	end)
	--, [AHFS_6+] = avg(case when Cnt_AHFS_201612 >= 6	then Charlson_Var_1	end)
	, Ttl_Mbrs = avg(Charlson_Var_1)
from	(
			select SavvyHICN, Charlson_Var_1, Cnt_AHFS_201612
				--, Cnt_AHFS_201612 = max(Cnt_AHFS_201612), Charlson_Var_1 = max(Charlson_Var_1)
			from pdb_PharmaMotion.dbo.GP1097_MbrCharlsonCntAHFS_upvt
			--where SavvyHICN = 133516
			group by SavvyHICN, Charlson_Var_1, Cnt_AHFS_201612
		) x
--where SavvyHICN = 16454853
--group by Charlson_Var
order by 1