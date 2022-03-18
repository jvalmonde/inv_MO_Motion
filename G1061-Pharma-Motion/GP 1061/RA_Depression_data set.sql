/*** 
GP 1061 Pharmacy & Motion -- RA & Depression

Input databases:	AllSavers_Prod, pdb_AllSavers_Research

Date Created: 14 July 2017
***/

--identify depression members
If (object_id('tempdb..#depressants') Is Not Null)
Drop Table #depressants
go

select NDCDrugSysID, NDC	--, b.AHFS_Therapeutic_Clss_Desc
into #Depressants
from AllSavers_Prod..Dim_NDCDrug	a
--inner join MiniHPDM..Dim_Drug_Class		b	on	a.NDC = b.NDC
where BrndNm in ('SERTRALINE HCL','ZOLOFT','PAROXETINE HCL','PAXIL','PAXIL CR','LUVOX','FLUVOXAMINE MALEATE',
			'SARAFEM','PROZAC','FLUOXETINE HCL','PROZAC WEEKLY','CITALOPRAM','CELEXA','CITALOPRAM HBR','LEXAPRO',
			'VIVACTIL','PROTRIPTYLINE HCL','AVENTYL HCL','PAMELOR','NORTRIPTYLIHNE HCL','NORTRIPTYLINE HCL',
			'TOFRANIL','TOFRANIL-PM','IMIPRAMINE HCL','IMIPRAMINE PAMOATE','DOXEPIN HCL','ZONALON','PRUDOXIN',
			'ADAPIN','SINEQUAN','NORPRAMIN','DESIPRAMINE','DESIPRAMINE HCL','CLOMIPRAMINE HCL','ANAFRANIL','ASENDIN',
			'AMOXAPINE','AMITRIPTYLINE HCL','VANATRIP','ENDEP','ELAVIL','EFFEXOR','EFFEXOR XR','SYMBYAX','PARNATE',
			'PHENELZINE SULFATE','NARDIL','MARPLAN','TRAZODONE','TRAZODONE HCL','DESYREL','NEFAZODONE HCL',
			'NEFAZODONE HC','NEFAZODONEHCL','SERZONE','BUPROPION HCL','WELLBUTRIN SR','WELLBUTRIN','WELLBUTRIN XL',
			'BUPROPION SR','BUPROPION HYDROCHLORIDE','CYMBALTA','ESKALITH','ESKALITH CR','LITHONATE','LITHOTABS',
			'LUDIOMIL','MAPROTILINE HCL','REMERON','MIRTAZAPINE','NEFAZODONE HC','NEFAZODONE HCL','NEFAZODONEHCL',
			'SERZONE','TRAZODONE','TRAZODONE HCL','DESYREL','TRAZAMINE','MARPLAN','NARDIL','PHENELZINE SULFATE',
			'TRANYLCYPROMINE SULFATE','PARNATE','EFFEXOR XR','EFFEXOR','VENLAFAXINE HCL','ENDEP',
			'AMITRIPTYLINE-PERPHENAZINE','TRIAVIL 4-25','ELAVIL','AMITRIPTYLINE W/PERPHENAZINE','TRIAVIL 2-10',
			'TRIAVIL 25-2','TRIAVIL 2-25','ETRAFON 2-25','AMITRIPTYLINE HCL','ETRAFON FORTE 4-25','VANATRIP',
			'TRIAVIL 10-2','ETRAFON 2-10','TRIAVIL 4-50','TRIAVIL 25-4','AMOXAPINE','ASENDIN','ANAFRANIL',
			'CLOMIPRAMINE HCL','NORPRAMIN','DESIPRAMINE','DESIPRAMINE HCL','ZONALON','ADAPIN','PRUDOXIN','SINEQUAN',
			'DOXEPIN HCL','TOFRANIL-PM','IMIPRAMINE HCL','SURMONTIL','TOFRANIL','IMIPRAMINE PAMOATE',
			'TRIMIPRAMINE MALEATE','AVENTYL HCL','PAMELOR','NORTRIPTYLINE HCL','NORTRIPTYLIHNE HCL','VIVACTIL',
			'PROTRIPTYLINE HCL')
--(8,374 row(s) affected)
--8360
create unique clustered index uix_id on #Depressants (NDCDrugSysID, NDC);


If (object_id('tempdb..#mbr_dep1') Is Not Null)
Drop Table #mbr_dep1
go

select a.MemberID
into #mbr_dep1
from pdb_PharmaMotion..Member_updt	a
inner join AllSavers_Prod..Fact_Claims	b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date		c	on	b.FromDtSysID = c.DtSysId
inner join #Depressants					d	on	b.NDCDrugSysID = d.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class		e	on	d.NDC = e.NDC
where e.Gnrc_Therapeutic_Clss_Desc is not null
	and e.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
	and b.ServiceTypeSysID = 4
	and c.YearNbr in (2014, 2015, 2016)
group by a.MemberID
having sum(b.AllwAmt) > 0
--(11,158 row(s) affected)--without the year filter
--(10,080 row(s) affected)



If (object_id('tempdb..#depressed_mbrs') Is Not Null)
Drop Table #depressed_mbrs
go

select MemberID, Depressed_Flag = 1
into #depressed_mbrs
from #mbr_dep1
union
select UniqueMemberID, Depressed_Flag = 1	--38
from pdb_PharmaMotion..RA_Com_R_ModelTerms_2014
where Term in ('HCC081', 'HCC082', 'HCC087', 'HCC088', 'HCC089', 'HCC090', 'HCC094', 'HCC102', 'HCC103')
group by UniqueMemberID
union
select UniqueMemberID, Depressed_Flag = 1	--1283; 1286
from pdb_PharmaMotion..RA_Com_K_ModelTerms_2015
where Term in ('HCC081', 'HCC082', 'HCC087', 'HCC088', 'HCC089', 'HCC090', 'HCC094', 'HCC102', 'HCC103')
group by UniqueMemberID
union
select UniqueMemberID, Depressed_Flag = 1	--1545; 1572
from pdb_PharmaMotion..RA_Com_K_ModelTerms_2016
where Term in ('HCC081', 'HCC082', 'HCC087', 'HCC088', 'HCC089', 'HCC090', 'HCC094', 'HCC102', 'HCC103')
group by UniqueMemberID
--(12,433 row(s) affected); 9.4% out of total population in the data set (google 6.7%)
--(11,429 row(s) affected) with the year filter
--11,436
create unique index uIx_SysID on #depressed_mbrs (MemberID);

--depression drugs costs
If (object_id('tempdb..#depression_costs') Is Not Null)
Drop Table #depression_costs
go

select a.MemberID, a.SystemID, a.YearMo, a.Enrl_Motion, a.Step_Cnt, a.NoDays_wSteps
	, b.Depressed_Flag, b.RxDepression_Allow, Cnt_NDCDepression = b.Cnt_NDC
into #depression_costs
from pdb_PharmaMotion..MemberSummary_v2	a
inner join	(--70,389
				select a.MemberID, a.Depressed_Flag, d.YearMo
					, RxDepression_Allow = sum(c.AllwAmt)
					, Cnt_NDC = count(distinct e.NDC)
				--select c.*, d.YearMo
				--select count(distinct a.SystemID)	--10,119; member might not be taking depression drugs but was diagnosed with Depression
				from #depressed_mbrs	a
				inner join AllSavers_Prod..Fact_Claims			c	on	a.MemberID = c.MemberID
				inner join AllSavers_Prod..Dim_Date				d	on	c.FromDtSysID = d.DtSysId
				inner join #Depressants							e	on	c.NDCDrugSysID = e.NDCDrugSysID	--
				inner join MiniHPDM..Dim_Drug_Class				f	on	e.NDC = f.NDC
				where d.YearNbr in (2014, 2015, 2016)
					and c.ServiceTypeSysID = 4
					and f.Gnrc_Therapeutic_Clss_Desc is not null
					and f.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
					--and c.ServiceTypeSysID = 4
					--and d.YearNbr in (2014, 2015, 2016)
					--and c.SystemID = 54000032550004500
				group by a.MemberID, a.Depressed_Flag, d.YearMo
				having sum(c.AllwAmt) > 0
			) b	on	a.MemberID = b.MemberID
				and a.YearMo = b.YearMo
--(70,166 row(s) affected)
--70110
create unique index uIx_MemberID_YM on #depression_costs (MemberID, YearMo);

select count(distinct MemberID) from #depression_costs	--10,080; 10067

--to flag for members but are not taking drugs
alter table pdb_PharmaMotion..MemberSummary_v2
	add Depressed_Flag	tinyint
		, RA_Flag		tinyint
go

update pdb_PharmaMotion..MemberSummary_v2
set Depressed_Flag = isnull(b.Depressed_Flag, 0)
from pdb_PharmaMotion..MemberSummary_v2	a
left join #depressed_mbrs				b	on	a.MemberID  = b.MemberID

--select count(distinct SystemID) from pdb_PharmaMotion..MemberSummary_v2 where Depressed_Flag = 1	--11429; 11436

----------------------------------------
--identify RA members
--from Brandon's logic
--NOTE: As a side note, it is important to mention, that these drugs treat Rheumatoid arthritis and may also treat other conditions.
If (object_id('tempdb..#ra') Is Not Null)
Drop Table #ra
go

select NDCDrugSysID, NDC	--, b.AHFS_Therapeutic_Clss_Desc
into #ra
from AllSavers_Prod..Dim_NDCDrug	a
--inner join MiniHPDM..Dim_Drug_Class		b	on	a.NDC = b.NDC
where rtrim(GnrcNm) in ('ETANERCEPT','ADALIMUMAB','CERTOLIZUMAB PEGOL','ABATACEPT','GOLIMUMAB','TOCILIZUMAB'	--Biologic medications (RX gnrc_nms used to treat RA, and other conditions)
						, 'METHOTREXATE SODIUM','HYDROXYCHLOROQUINE SULFATE','LEFLUNOMIDE','SULFASALAZINE','AZATHIOPRINE','TOFACITINIB CITRATE')	--Tradition oral medications (RX gnrc_nms used to treat RA)
	--added: 07/18/2017; source: webmd
	or rtrim(BrndNm) in ('KINERET', 'RITUXAN', 'INFLECTRA'	--Biologic response modifiers
	, 'CELESTONE', 'RAYOS'	--Glucocorticoids
	)	
--(497 row(s) affected)
--517
create unique clustered index uix_id on #ra (NDCDrugSysID, NDC);

If (object_id('tempdb..#mbr_ra1') Is Not Null)
Drop Table #mbr_ra1
go

select a.MemberID
into #mbr_ra1
from pdb_PharmaMotion..Member_updt	a
inner join AllSavers_Prod..Fact_Claims	b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date		c	on	b.FromDtSysID = c.DtSysId
inner join AllSavers_Prod..Dim_ProcedureCode	f	on	b.ProcCdSysID = f.ProcCdSysId
inner join #ra							d	on	b.NDCDrugSysID = d.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class		e	on	d.NDC = e.NDC
--where b.NDCDrugSysID in (295374
--, 295375
--, 296301)
where (e.Gnrc_Therapeutic_Clss_Desc is not null
	and e.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS'))
	--and b.ServiceTypeSysID = 4
	and c.YearNbr in (2014, 2015, 2016)
	or rtrim(f.ProcCd) in ('J1745','J0129','J9310','J3262','J1602','J0717') --Injection J-codes (CPT codes) that are used for treating RA, as well as other conditions
group by a.MemberID
having sum(b.AllwAmt) > 0
--(1,063 row(s) affected)
--969

If (object_id('tempdb..#ra_mbrs') Is Not Null)
Drop Table #ra_mbrs
go

select MemberID, RA_Flag = 1
into #ra_mbrs
from #mbr_ra1
union
select UniqueMemberID, RA_Flag = 1	--15
from pdb_PharmaMotion..RA_Com_R_ModelTerms_2014
where Term = 'HCC056'
group by UniqueMemberID
union
select UniqueMemberID, RA_Flag = 1	--360; 361
from pdb_PharmaMotion..RA_Com_K_ModelTerms_2015
where Term = 'HCC056'
group by UniqueMemberID
union
select UniqueMemberID, RA_Flag = 1	--684; 657
from pdb_PharmaMotion..RA_Com_K_ModelTerms_2016
where Term = 'HCC056'
group by UniqueMemberID
--(1,353 row(s) affected); 1.02% out of total population in the data set (google 1% word population 1995)
--1,302
create unique index uIx_SystemID on #ra_mbrs (MemberID);

update pdb_PharmaMotion..MemberSummary_v2
set RA_Flag = isnull(b.RA_Flag, 0)
from pdb_PharmaMotion..MemberSummary_v2	a
left join #ra_mbrs						b	on	a.MemberID  = b.MemberID

--ra drugs costs
If (object_id('tempdb..#ra_cost') Is Not Null)
Drop Table #ra_cost
go

select a.MemberID, a.SystemID, a.YearMo, a.Enrl_Motion, a.Step_Cnt, a.NoDays_wSteps
	, b.RA_Flag, b.RxRA_Allow, Cnt_NDCRA = b.Cnt_NDC
into #ra_cost
from pdb_PharmaMotion..MemberSummary_v2	a
inner join	(--8,455
				select a.MemberID, a.RA_Flag, d.YearMo
					, RxRA_Allow = sum(c.AllwAmt)
					, Cnt_NDC = count(distinct e.NDC)
				--select c.*, d.YearMo
				--select count(distinct a.SystemID)	--970
				from #ra_mbrs	a
				inner join AllSavers_Prod..Fact_Claims			c	on	a.MemberID = c.MemberID
				inner join AllSavers_Prod..Dim_Date				d	on	c.FromDtSysID = d.DtSysId
				inner join AllSavers_Prod..Dim_ProcedureCode	g	on	c.ProcCdSysID = g.ProcCdSysId
				inner join #ra									e	on	c.NDCDrugSysID = e.NDCDrugSysID
				inner join MiniHPDM..Dim_Drug_Class				f	on	e.NDC = f.NDC
				where (d.YearNbr in (2014, 2015, 2016)
					--and c.ServiceTypeSysID = 4
					and f.Gnrc_Therapeutic_Clss_Desc is not null
					and f.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS'))
					--and c.SystemID = 54000032550004500
					or rtrim(g.ProcCd) in ('J1745','J0129','J9310','J3262','J1602','J0717')		--Injection J-codes (CPT codes) that are used for treating RA, as well as other conditions
				group by a.MemberID, a.RA_Flag, d.YearMo
				having sum(c.AllwAmt) > 0
			) b	on	a.MemberID = b.MemberID
				and a.YearMo = b.YearMo
--(8427 row(s) affected)
--8445
create unique index uIx_SystemID_YM on #ra_cost (SystemID, YearMo);

select count(distinct SystemID) from #ra_cost	--966; 967


--build the final table; combine the 2
If (object_id('pdb_PharmaMotion..MemberSummary_Depression_RA') Is Not Null)
Drop Table pdb_PharmaMotion..MemberSummary_Depression_RA
go

select MemberID, SystemID, YearMo
	, Enrl_Motion		= max(Enrl_Motion)
	, Step_Cnt			= max(Step_Cnt)
	, NoDays_wSteps		= max(NoDays_wSteps)
	, Depressed_Flag	= max(Depressed_Flag)
	, RxDepression_Allow	= max(RxDepression_Allow)
	, Cnt_NDCDepression	= max(Cnt_NDCDepression)
	, RA_Flag		= max(RA_Flag)
	, RxRA_Allow	= max(RxRA_Allow)
	, Cnt_NDCRA		= max(Cnt_NDCRA)
--into pdb_PharmaMotion..MemberSummary_Depression_RA
from	(
			select MemberID, SystemID, YearMo, Enrl_Motion, Step_Cnt, NoDays_wSteps, Depressed_Flag, RxDepression_Allow, Cnt_NDCDepression
				, RA_Flag = 0
				, RxRA_Allow = 0.0
				, Cnt_NDCRA = 0
			from #depression_costs	
			union all
			select MemberID, SystemID, YearMo, Enrl_Motion, Step_Cnt, NoDays_wSteps, Depressed_Flag = 0, RxDepression_Allow = 0.0, Cnt_NDCDepression = 0
				, RA_Flag
				, RxRA_Allow
				, Cnt_NDCRA
			from #ra_cost			
		) z
---where MemberID = 261594	--240795
group by MemberID, SystemID, YearMo
order by 1, YearMo
--(77,669 row(s) affected)
--77,631

select count(distinct SystemID) from pdb_PharmaMotion..MemberSummary_Depression_RA where Depressed_Flag = 1	--10,080; 10,067
select count(distinct SystemID) from pdb_PharmaMotion..MemberSummary_Depression_RA where RA_Flag = 1	--966; 967

-------------------------------
--Pull for the first diagnosis & build Month_Ind
--Date Created: 01 August 2017
-------------------------------
--pull for the diagnoses in the HCC
--depression
If (object_id('tempdb..#depressed_dx') Is Not Null)
Drop Table #depressed_dx
go

select b.*
--into #depressed_dx
from	(
			select ICDCd, ICD_VER_CD = 9
			--select *
			from RA_Commercial_2014..ModelHCC	a
			inner join RA_Commercial_2014..HCCDiagnosis	b	on	a.ModelHCCID = b.ModelHCCID
			where a.ModelCategoryID between 7 and 9
				and a.Term in ('HCC081', 'HCC082', 'HCC087', 'HCC088', 'HCC089', 'HCC090', 'HCC094', 'HCC102', 'HCC103')
			group by ICDCd
			
			union
			select ICDCd, ICD_VER_CD
			from RA_Commercial_2015..ModelHCC	a
			inner join RA_Commercial_2015..HCCDiagnosis	b	on	a.ModelHCCID = b.ModelHCCID
			where a.ModelCategoryID between 7 and 9
				and a.Term in ('HCC081', 'HCC082', 'HCC087', 'HCC088', 'HCC089', 'HCC090', 'HCC094', 'HCC102', 'HCC103')
			group by ICDCd, ICD_VER_CD
		) a
inner join AllSavers_Prod..Dim_DiagnosisCode	b	on	a.ICDCd = b.DiagCd
													and a.ICD_VER_CD = b.ICD_ver_cd
where a.ICDCd = 'F840'
--(1,609 row(s) affected)
create unique index uIx_ICD_vrCD on #depressed_dx (DiagCdSysId);

If (object_id('tempdb..#depressed_mindtdx') Is Not Null)
Drop Table #depressed_mindtdx
go

select a.SystemID, a.MemberID
	, Min_DiagDt = min(c.FullDt)
into #depressed_mindtdx
from	(--11,436
			select SystemID, MemberID
			from pdb_PharmaMotion..MemberSummary_v2	a
			--inner join AllSavers_Prod..Dim_Member				b	on	a.SystemID = b.SystemID
			where Depressed_Flag = 1
			--where MemberID = 261594
			group by SystemID, MemberID
		) a
inner join AllSavers_Prod..Fact_Claims			b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date				c	on	b.FromDtSysID = c.DtSysId
inner join AllSavers_Prod..Fact_Diagnosis		d	on	b.MemberID = d.MemberID
													and d.ClaimNumber = b.ClaimNumber
													and d.ClaimSet = b.ClaimSet
													and d.SubNumber = b.SubNumber
inner join #depressed_dx						e	on	d.DiagCdSysId = e.DiagCdSysId	
where c.YearNbr in (2014, 2015, 2016)
	and d.DiagnosisNbr in (1,2,3)
--where YearNbr = 2016
--	and b.MemberID = 261594
group by a.SystemID, a.MemberID
--(1049 row(s) affected)
--2685
create unique index uIx_SystemID on #depressed_mindtdx (SystemID);

--proxy
If (object_id('tempdb..#depressed_mindtrx') Is Not Null)
Drop Table #depressed_mindtrx
go

select a.SystemID, a.MemberID
	, Min_DiagDt = min(d.FullDt)
into #depressed_mindtrx
from	(--10,080
			select SystemID, MemberID
			from pdb_PharmaMotion..MemberSummary_v2	a
			where Depressed_Flag = 1
			group by SystemID, MemberID
		) a
left join #depressed_mindtdx			b	on	a.SystemID = b.SystemID
inner join AllSavers_Prod..Fact_Claims	c	on	a.MemberID = c.MemberID
inner join AllSavers_Prod..Dim_Date		d	on	c.FromDtSysID = d.DtSysId
inner join #Depressants					e	on	c.NDCDrugSysID = e.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class		f	on	e.NDC = f.NDC
where b.SystemID is null
	and f.Gnrc_Therapeutic_Clss_Desc is not null
	and f.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
	and c.ServiceTypeSysID = 4
	and d.YearNbr in (2014, 2015, 2016)
group by a.SystemID, a.MemberID
having sum(c.AllwAmt) > 0
--(8, 751 row(s) affected)

If (object_id('tempdb..#depression_monthIND') Is Not Null)
Drop Table #depression_monthIND
go

select distinct a.SystemID, a.MemberID, a.Min_DiagDt
	, b.YearMo
	, Month_IND_Depression = datediff(mm, a.Min_DiagDt, cast(cast(b.YearMo as varchar) + '01' as date))
into #depression_monthIND
from	(
			select *
			from #depressed_mindtdx
			union
			select *
			from #depressed_mindtrx
		) a
inner join AllSavers_Prod..Dim_Date	b	on	YearNbr in (2014, 2015, 2016)
--where SystemID = 54000040140003400
--(411,696 row(s) affected)
create unique index uIx_SysID_YM on #depression_monthIND (SystemID, YearMo);

alter table pdb_PharmaMotion..MemberSummary_Depression_RA
	add Min_DiagDt_Depression	date
		, Month_IND_Depression smallint
go

update pdb_PharmaMotion..MemberSummary_Depression_RA
set Min_DiagDt_Depression = isnull(b.Min_DiagDt, '')
	, Month_IND_Depression = isnull(b.Month_IND_Depression, 0)
from pdb_PharmaMotion..MemberSummary_Depression_RA	a
left join #depression_monthIND						b	on	a.SystemID = b.SystemID
														and a.YearMo = b.YearMo


--pull for the diagnoses in the HCC
--RA
If (object_id('tempdb..#ra_dx') Is Not Null)
Drop Table #ra_dx
go

select b.*
into #ra_dx
from	(
			select ICDCd, ICD_VER_CD = 9
			from RA_Commercial_2014..ModelHCC	a
			inner join RA_Commercial_2014..HCCDiagnosis	b	on	a.ModelHCCID = b.ModelHCCID
			where a.ModelCategoryID between 7 and 9
				and a.Term = 'HCC056'
			group by ICDCd
			
			union
			select ICDCd, ICD_VER_CD
			from RA_Commercial_2015..ModelHCC	a
			inner join RA_Commercial_2015..HCCDiagnosis	b	on	a.ModelHCCID = b.ModelHCCID
			where a.ModelCategoryID between 7 and 9
				and a.Term = 'HCC056'
			group by ICDCd, ICD_VER_CD
		) a
inner join AllSavers_Prod..Dim_DiagnosisCode	b	on	a.ICDCd = b.DiagCd
													and a.ICD_VER_CD = b.ICD_ver_cd
--(1,016 row(s) affected)
create unique index uIx_ICD_vrCD on #ra_dx (DiagCdSysId);

If (object_id('tempdb..#ra_mindtdx') Is Not Null)
Drop Table #ra_mindtdx
go

select a.SystemID, a.MemberID
	, Min_DiagDt = min(c.FullDt)
into #ra_mindtdx
from	(--966
			select SystemID, MemberID
			from pdb_PharmaMotion..MemberSummary_v2	a
			where RA_Flag = 1
			group by SystemID, MemberID
		) a
inner join AllSavers_Prod..Fact_Claims			b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date				c	on	b.FromDtSysID = c.DtSysId
inner join AllSavers_Prod..Fact_Diagnosis		d	on	a.MemberID = d.MemberID
													and d.ClaimNumber = b.ClaimNumber
													and d.ClaimSet = b.ClaimSet
													and d.SubNumber = b.SubNumber
inner join #ra_dx								e	on	b.DiagCdSysId = e.DiagCdSysId	
where c.YearNbr in (2014, 2015, 2016)
group by a.SystemID, a.MemberID
--(676 row(s) affected)
create unique index uIx_SystemID on #ra_mindtdx (SystemID);

--proxy
If (object_id('tempdb..#ra_mindtrx') Is Not Null)
Drop Table #ra_mindtrx
go

select a.SystemID, a.MemberID
	, Min_DiagDt = min(d.FullDt)
into #ra_mindtrx
--select *
from	(--966
			select SystemID, MemberID
			from pdb_PharmaMotion..MemberSummary_v2	a
			where RA_Flag = 1
			group by SystemID, MemberID
		) a
left join #ra_mindtdx					b	on	a.SystemID = b.SystemID
inner join AllSavers_Prod..Fact_Claims	c	on	a.MemberID = c.MemberID
inner join AllSavers_Prod..Dim_Date		d	on	c.FromDtSysID = d.DtSysId
inner join #ra							e	on	c.NDCDrugSysID = e.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class		f	on	e.NDC = f.NDC
where b.SystemID is null
	and f.Gnrc_Therapeutic_Clss_Desc is not null
	and f.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
	and c.ServiceTypeSysID = 4
	and d.YearNbr in (2014, 2015, 2016)
group by a.SystemID, a.MemberID
having sum(c.AllwAmt) > 0
--(522 row(s) affected)

If (object_id('tempdb..#ra_monthIND') Is Not Null)
Drop Table #ra_monthIND
go

select distinct a.SystemID, a.MemberID, a.Min_DiagDt
	, b.YearMo
	, Month_IND_RA = datediff(mm, a.Min_DiagDt, cast(cast(b.YearMo as varchar) + '01' as date))
into #ra_monthIND
from	(
			select *
			from #ra_mindtdx
			union
			select *
			from #ra_mindtrx
		) a
inner join AllSavers_Prod..Dim_Date	b	on	YearNbr in (2014, 2015, 2016)
--where SystemID = 54000040140003400
--(43,128 row(s) affected)
create unique index uIx_SysID_YM on #ra_monthIND (SystemID, YearMo);

alter table pdb_PharmaMotion..MemberSummary_Depression_RA
	add Min_DiagDt_RA	date
		, Month_IND_RA smallint
go

update pdb_PharmaMotion..MemberSummary_Depression_RA
set Min_DiagDt_RA = isnull(b.Min_DiagDt, '')
	, Month_IND_RA = isnull(b.Month_IND_RA, 0)
from pdb_PharmaMotion..MemberSummary_Depression_RA	a
left join #ra_monthIND								b	on	a.SystemID = b.SystemID
														and a.YearMo = b.YearMo												

select * 
from pdb_PharmaMotion..MemberSummary_Depression_RA
where RA_Flag = 1
order by 1, YearMo