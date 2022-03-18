/*** 
GP 1062 - T2D Adherence

Input databases:	SMA, pdb_CGMType2

Date Created: 05 June 2017
***/

--pull for the diabetes drugs
If Object_ID('tempdb..#DiabetesMeds') is not null
drop table #DiabetesMeds;

select *,
	DMC_Categories = case when GNRC_NM like '%chlorpropamide%'	or GNRC_NM like '%glipizide%'
	 						or GNRC_NM like '%glyburide%'		or GNRC_NM like '%glimepiride%'
	 						or GNRC_NM like '%gliclazide%'		or GNRC_NM like '%tolazamide%'
	 						or GNRC_NM like '%tolbutamide%'																		then 'DMC_Sulfonylureas'
						when GNRC_NM like '%repaglinide%'		or GNRC_NM like '%nateglinide%'									then 'DMC_Meglitinides'
						when GNRC_NM like '%metformin%'																			then 'DMC_Biguanides'
						when GNRC_NM like '%rosiglitazone%'		or GNRC_NM like '%pioglitazone%'								then 'DMC_Thiazolidinediones'
						when GNRC_NM like '%sitagliptin%'		or GNRC_NM like '%saxagliptin%'
	 						or GNRC_NM like '%linagliptin%'		or GNRC_NM like '%alogliptin%'									then 'DMC_DPP4'
						when GNRC_NM like '%acarbose%'			or GNRC_NM like '%miglitol%'									then 'DMC_AlphaGlucosidase'
						when GNRC_NM like '%canagliflozin%'     or GNRC_NM like '%dapagliflozin%'
	 						or GNRC_NM like '%empagliflozin%'																	then 'DMC_SGLT2'
						when GNRC_NM like '%Colesevelam%'																		then 'DMC_BileAcidSequestrants'
						when GNRC_NM like '%Bromocriptine%'																		then 'DMC_DopamineAgonist'
						when GNRC_NM like '%Pramlintide%'																		then 'DMC_AmylinAnalogue'
						when GNRC_NM like '%liraglutide%'		or GNRC_NM like '%albiglutide%'
	 						or GNRC_NM like '%dulaglutide%'		or GNRC_NM like '%exenatide%'									then 'DMC_GLP1_Receptor_Agonist'
						when GNRC_NM like '%insulin glulisine%'			  or GNRC_NM like '%insulin lispro%'									
							or GNRC_NM like '%insulin aspart%'			  or GNRC_NM like 'insulin regular%'		
							or GNRC_NM like 'insulin nph & regular%'	  or GNRC_NM like 'insulin nph isophane & regular%'
							or GNRC_NM like 'insulin isophane & regular%' or GNRC_NM like '%insulin nph%reg%'					then 'DMC_Short_Acting_Insulin'
						when GNRC_NM like 'insulin isophane (%'			  or GNRC_NM like '%(isophane)%' 
							or GNRC_NM like '%insulin isophane%'		  or GNRC_NM like '%insulin nph%' 
							or GNRC_NM like '%insulin zinc%'																	then 'DMC_Intermediate_Acting_Insulin'
						when GNRC_NM like '%insulin detemir%'	or GNRC_NM like '%insulin glargine%'
							or GNRC_NM like '%insulin degludec%'																then 'DMC_Long_Acting_Insulin'			else null	end
into #DiabetesMeds
from SMA..Dim_NDC_Drug
where   
	-- Short-acting
		GNRC_NM like '%insulin glulisine%'			or 
		GNRC_NM like '%insulin lispro%'				or
		GNRC_NM like '%insulin aspart%'				or 
		GNRC_NM like '%insulin regular%'			or
	-- Intermediate-acting
		GNRC_NM like '%insulin isophane%'			or
		GNRC_NM like '%insulin nph%'				or
		GNRC_NM like '%insulin zinc%'				or 
	-- Long-acting
		GNRC_NM like '%insulin detemir%'			or 
		GNRC_NM like '%insulin glargine%'			or 
		GNRC_NM like '%insulin degludec%'			or
	-- Non-insulin injectibles
		GNRC_NM like '%pramlintide%'				or
		GNRC_NM like '%liraglutide%'				or
		GNRC_NM like '%albiglutide%'				or
		GNRC_NM like '%dulaglutide%'				or
		GNRC_NM like '%exenatide%'					or
		GNRC_NM like '%exenatide extended release%'	or
	-- Oral anti-hyperglycemics
		GNRC_NM like '%chlorpropamide%'				or
		GNRC_NM like '%glipizide%'					or
		GNRC_NM like '%glyburide%'					or
		GNRC_NM like '%glimepiride%'				or
		GNRC_NM like '%gliclazide%'					or
		GNRC_NM like '%tolazamide%'					or
		GNRC_NM like '%tolbutamide%'				or
		GNRC_NM like '%repaglinide%'				or
		GNRC_NM like '%nateglinide%'				or
		GNRC_NM like '%metformin%'					or
		GNRC_NM like '%rosiglitazone%'				or
		GNRC_NM like '%pioglitazone%'				or
		GNRC_NM like '%sitagliptin%'				or
		GNRC_NM like '%saxagliptin%'				or
		GNRC_NM like '%linagliptin%'				or
		GNRC_NM like '%alogliptin%'					or
		GNRC_NM like '%acarbose%'					or
		GNRC_NM like '%miglitol%'					or
		GNRC_NM like '%canagliflozin%'				or
		GNRC_NM like '%dapagliflozin%'				or
		GNRC_NM like '%empagliflozin%'				or
		GNRC_NM like '%colesevelam%'				or
		GNRC_NM like '%bromocriptine%'
--(4,293 row(s) affected)
Create unique clustered index ucix_DrugSysID on #DiabetesMeds(NDC_Drg_Sys_ID);
create index Ix_GnrcNm on #DiabetesMeds (GNRC_NM);

If Object_ID('tempdb..#member_dmc_daysupply') is not null
drop table #member_dmc_daysupply;

select SavvyMRN, Year_Mo
	, DaysSupply_DMC_AlphaGlucosidase
    , DaysSupply_DMC_AmylinAnalogue
    , DaysSupply_DMC_Biguanides
    , DaysSupply_DMC_BileAcidSequestrants
    , DaysSupply_DMC_DopamineAgonist
    , DaysSupply_DMC_DPP4
    , DaysSupply_DMC_GLP1_Receptor_Agonist
    , DaysSupply_DMC_Intermediate_Acting_Insulin
    , DaysSupply_DMC_Long_Acting_Insulin
    , DaysSupply_DMC_Meglitinides
    , DaysSupply_DMC_SGLT2
    , DaysSupply_DMC_Short_Acting_Insulin
    , DaysSupply_DMC_Sulfonylureas
    , DaysSupply_DMC_Thiazolidinediones
    , RxDaysSupply_DMC_AlphaGlucosidase
    , RxDaysSupply_DMC_AmylinAnalogue
    , RxDaysSupply_DMC_Biguanides
    , RxDaysSupply_DMC_BileAcidSequestrants
    , RxDaysSupply_DMC_DopamineAgonist
    , RxDaysSupply_DMC_DPP4
    , RxDaysSupply_DMC_GLP1_Receptor_Agonist
    , RxDaysSupply_DMC_Intermediate_Acting_Insulin
    , RxDaysSupply_DMC_Long_Acting_Insulin
    , RxDaysSupply_DMC_Meglitinides
    , RxDaysSupply_DMC_SGLT2
    , RxDaysSupply_DMC_Short_Acting_Insulin
    , RxDaysSupply_DMC_Sulfonylureas
    , RxDaysSupply_DMC_Thiazolidinediones
into #member_dmc_daysupply
from pdb_CGMType2..Stage2_RSKC_SMA_MemberSummary_201110_201509_Px_clnx
where Classification_Types = 'T2'
--(327,360 row(s) affected)
create unique index uIx_MRN_YrMo on #member_dmc_daysupply (SavvyMRN, Year_Mo);

select count(distinct SavvyMRN) from #member_dmc_daysupply	--6820
select * from #member_dmc_daysupply

--unpivot base table
If (object_id('pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot') Is Not Null)
Drop Table pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot
go

DECLARE @query AS NVARCHAR(MAX);

DECLARE @cols AS NVARCHAR(MAX);

select @cols = STUFF(--identify columns to unpivot
								(SELECT distinct ',' + QUOTENAME(name)
								  from  tempdb.sys.columns where object_id = object_id('tempdb..#member_dmc_daysupply')
								  	AND name <> 'SavvyMRN' 
									AND name <> 'Year_Mo'
								  FOR XML PATH(''), TYPE
								 ).value('.', 'NVARCHAR(MAX)') 
							, 1, 1, ''
							);

SELECT @query = '
select SavvyMRN, Year_Mo, DMC, DaySupply
into pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot
from (
		select SavvyMRN, Year_Mo, ' + @cols + '
		from #member_dmc_daysupply
		--where SavvyHICN = 986
	) as sub1
unpivot
(
	DaySupply 
	for DMC in (' + @cols + ')
) as unpiv';

EXECUTE(@query);
--(9166080 row(s) affected)

--exclude day supply with 0
delete from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot
where DaySupply = 0
--(8642619 row(s) affected); 10.08 minutes
create clustered index ucIx_SavvyHICN_Dt on pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot (SavvyMRN, Year_Mo); 

/* test queries
select savvyMRN, sum(Daysupply) from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot  group by savvyMRN having sum(Daysupply) = 0	--1846 rows
select * from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot where SavvyMRN = 150
select count(distinct SavvyMRN) from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot	--6820
select * from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot
select count(distinct SavvyMRN) from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot	--4974
*/

--create index Ix_GnrcNm on pdb_CGMType2..tmp_RS_FactDrug_SMA_201110_201509_Px_clnx (GNRC_NM);

--pull for generic names
If Object_ID('tempdb..#fills') is not null
drop table #fills;

select a.SavvyMRN
	, DMC = substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC))
	, c.GNRC_NM
	, Diab_Med_Stage_v3 = null
	, RxSupply		= max(case when a.DMC like 'RxDaysSupply%'	then DaySupply	else 0	end)
	, FillSupply	= max(case when a.DMC like 'DaysSupply%'	then DaySupply	else 0	end)
	, a.Year_Mo
	, Adj_Rx_Spend	= null
into #fills
from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot	a
inner join pdb_CGMType2..tmp_RS_FactDrug_SMA_201110_201509_Px_clnx	b	on	a.SavvyMRN = b.SavvyMRN
																		and a.Year_Mo = format(FULL_DT, 'yyyyMM')
inner join #DiabetesMeds											c	on	b.GNRC_NM = c.GNRC_NM
																		and substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC)) = c.DMC_Categories
where ClaimStatus = 'P'
group by  a.SavvyMRN, a.Year_Mo, substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC)), c.GNRC_NM
--(129,024 row(s) affected)

If Object_ID('tempdb..#prescriptions') is not null
drop table #prescriptions;

select a.SavvyMRN
	, DMC = substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC))
	, c.GNRC_NM
	, Diab_Med_Stage_v3 = null
	, RxSupply		= max(case when a.DMC like 'RxDaysSupply%'	then DaySupply	else 0	end)
	, FillSupply	= max(case when a.DMC like 'DaysSupply%'	then DaySupply	else 0	end)
	, a.Year_Mo
	, Aprox_Rx_Spend	= null
into #prescriptions
from	(
			select a.*
			from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot	a
			left join pdb_CGMType2..tmp_RS_FactDrug_SMA_201110_201509_Px_clnx	b	on	a.SavvyMRN = b.SavvyMRN	
			where b.SavvyMRN is null
			--where a.SavvyMRN = 180757
		) a
inner join pdb_CGMType2..tmp_RS_FactDrug_SMA_TW_201110_201509_wRefill_clnx	b	on	a.SavvyMRN = b.SavvyMRN
																				and a.Year_Mo = format(FULL_DT, 'yyyyMM')
inner join #DiabetesMeds													c	on	b.GNRC_NM = c.GNRC_NM
																				and substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC)) = c.DMC_Categories
--where a.SavvyMRN = 9919
group by a.SavvyMRN, a.Year_Mo, substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC)), c.GNRC_NM
--(282 row(s) affected)

select *
from pdb_CGMType2..tmp_RS_FactDrug_SMA_TW_201110_201509_wRefill_clnx
where SavvyMRN = 200889

If (object_id('pdb_CGMType2..tmpGP1062_MemberSummary_DMC') Is Not Null)
Drop Table pdb_CGMType2..tmpGP1062_MemberSummary_DMC
go

select SavvyMRN, DMC, GNRC_NM, Diab_Med_Stage_v3, RxSupply, FillSupply
	, Year_Mo, Aprox_Rx_Spend
into pdb_CGMType2..tmpGP1062_MemberSummary_DMC
from 	(--129,306
			select *
			from #fills
			union all
			select *
			from #prescriptions
		) z
order by SavvyMRN, Year_Mo
--(129306 row(s) affected)


select count(distinct SavvyMRN) from pdb_CGMType2..tmpGP1062_MemberSummary_DMC	--4972; 4974
--count(distinct a.SAvvyMRN)	--2
select * from  pdb_CGMType2..Stage2_RSKC_SMA_MemberSummary_201110_201509_Px_clnx where SavvyMRN = 150

--handling of the missing 2 members
--manually pull for their claims & use their generic names; day supply were more than 90 days...this has something to do with on-hand possession logic
/*
select *
from pdb_CGMType2..tmp_RS_FactDrug_SMA_201110_201509_Px_clnx
where SavvyMRN = 200889	--180757

select *
from pdb_CGMType2..tmp_RS_FactDrug_SMA_TW_201110_201509_wRefill_clnx
where SavvyMRN = 200889	--180757
*/

insert into pdb_CGMType2..tmpGP1062_MemberSummary_DMC
select SavvyMRN, DMC, GNRC_NM, Diab_Med_Stage_v3, RxSupply, FillSupply
	, Year_Mo, Aprox_Rx_Spend
from	(	
			select a.SavvyMRN
				, DMC = substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC))
				, GNRC_NM = case when a.SavvyMRN = 180757	then 'METFORMIN HCL'	else 'PIOGLITAZONE HCL'	end
				, Diab_Med_Stage_v3 = null
				, RxSupply		= max(case when a.DMC like 'RxDaysSupply%'	then DaySupply	else 0	end)
				, FillSupply	= max(case when a.DMC like 'DaysSupply%'	then DaySupply	else 0	end)
				, a.Year_Mo
				, Aprox_Rx_Spend	= null
			--select a.*
			from pdb_CGMType2.dbo.tmp_DMC_DaySupply_unpivot	a
			left join pdb_CGMType2..tmpGP1062_MemberSummary_DMC	b	on	a.SavvyMRN = b.SavvyMRN
			where b.SavvyMRN is null
			group by a.SavvyMRN, a.Year_Mo, substring(a.DMC, (patindex('%_DMC%', a.DMC)+1), len(a.DMC))
		) z
--(6 row(s) affected)

--pull for the final table
If (object_id('pdb_CGMType2..GP1062_MemberSummary_DMC') Is Not Null)
Drop Table pdb_CGMType2..GP1062_MemberSummary_DMC
go

select a.SavvyMRN, b.DMC, b.GNRC_NM, b.Diab_Med_Stage_v3, b.RxSupply, b.FillSupply
	, a.Year_Mo, b.Aprox_Rx_Spend
into pdb_CGMType2..GP1062_MemberSummary_DMC
from pdb_CGMType2..Stage2_RSKC_SMA_MemberSummary_201110_201509_Px_clnx	a
left join pdb_CGMType2..tmpGP1062_MemberSummary_DMC						b	on	a.SavvyMRN = b.SavvyMRN
																			and a.Year_Mo = b.Year_Mo
where a.Classification_Types = 'T2'
--a.SavvyMRN = 150
--355646
create index uIx_SavvyMRN_YrMo on pdb_CGMType2..GP1062_MemberSummary_DMC (SavvyMRN, Year_Mo);

------------------------
--add spend, utilization approximations
--use UHC Medicare data
------------------------
--alter table pdb_CGMType2..GP1062_MemberSummary_DMC
--	alter column Aprox_Rx_Spend	decimal(9,2)
--go

update pdb_CGMType2..GP1062_MemberSummary_DMC
set Aprox_Rx_Spend = b.Med_AllwAmt
from pdb_CGMType2..GP1062_MemberSummary_DMC	a
left join	(--129,312 rows
				select SavvyMRN, DMC, GNRC_NM, RxSupply, FillSupply, Year_Mo, Med_AllwAmt
				from pdb_CGMType2..GP1062_MemberSummary_DMC	a
				inner join pdb_CGMType2..UHC_RxDiabMeds_median_DMC	b	on	a.DMC	= b.DMC_Categories
				--where a.SavvyMRN = 150
				group by SavvyMRN, DMC, GNRC_NM, RxSupply, FillSupply, Year_Mo, Med_AllwAmt
			) b on a.SavvyMRN = b.SavvyMRN
				and a.Year_Mo = b.Year_Mo
--(355,646 row(s) affected)

/*------------------------
--Diag_Med_Stage_v3
------------------------
If (object_id('tempdb..#StageIND') Is Not Null)
Drop Table #StageIND
go

select b.SavvyMRN, b.Year_Mo
	, Stage_IND = right(Diab_Med_Stage, 1)
	, Stage_IND2 = right(Diab_Med_Stage_V2, 1)
into #StageIND
from pdb_CGMType2..Stage2_RSKC_SMA_MemberSummary_201110_201509_Px_clnx	a
inner join pdb_CGMType2..GP1062_MemberSummary_DMC						b	on	a.SavvyMRN = b.SavvyMRN
																			and a.Year_Mo = b.Year_Mo
--where a.SavvyMRN = 560
group by b.SavvyMRN, b.Year_Mo, a.Diab_Med_Stage, a.Diab_Med_Stage_V2
--(327,360 row(s) affected)
create unique index uIx_SavvyMRN_YM on #StageIND (SavvyMRN, Year_Mo);
select * from #StageIND where SavvyMRN = 630674 order by 1, 2

select SavvyMRN, Year_Mo
	, Stage_IND, Stage_IND2
	, Stage_grp = sum((case when (lead(Stage_IND, 1) over(partition by SavvyMRN order by Year_Mo)) = Stage_IND	then 1	else 0 end)) over(partition by SavvyMRN order by year_mo rows between current row and unbounded following)
from #StageIND

select SavvyMRN, Grp, Stage_IND, GapStartYM
	, MinYM_stage = min(Year_Mo)
	, MaxYM_stage = max(Year_Mo)
	--, Gaps = datediff(mm, cast(cast(min(Year_Mo) as varchar) + '01' as date), cast(cast(max(Year_Mo) as varchar) + '01' as date))
	, OID = row_number() over(partition by SavvyMRN, Grp, Stage_IND order by min(Year_Mo))
into #temp
from	(				
			select a.SavvyMRN, a.Year_Mo, a.Stage_IND, GapStartYM, DownStageFlag	--, UpStageFlag
				, sum(case when GapStartYM is not null and DownStageFlag is null /*and UpStageFlag is null*/	then 1	else 0 end) over(partition by a.SavvyMRN order by a.Year_Mo rows unbounded preceding) as grp
			from	(
						select SavvyMRN, Year_Mo,Stage_IND
							, DownStageFlag = case when (lead(Stage_IND, 1) over(partition by SavvyMRN order by Year_Mo)) < Stage_IND  then 1 end
							--, UpStageFlag	= case when (lead(Stage_IND, 1) over(partition by SavvyMRN order by Year_Mo)) > Stage_IND  then 1 end
							, GapStartYM = case when (case when (lead(Stage_IND, 1) over(partition by SavvyMRN order by Year_Mo)) < Stage_IND  then 1 end) = 1
												or (case when (lag(Stage_IND, 1) over(partition by SavvyMRN order by Year_Mo)) > Stage_IND  then 1 end) = 1
												then Year_Mo	end
							from #StageIND
						where SavvyMRN = 65741	--560, 630674
					) a
			--where a.SavvyMRN = 65741
			--order by 2
		) a
--where Grp = 3
group by SavvyMRN, Grp, Stage_IND, GapStartYM


If (object_id('tempdb..#Stagev3') Is Not Null)
Drop Table #Stagev3
go

select b.SavvyMRN, b.Year_Mo, b.Stage_IND, b.Stage_IND2
	, Stage_IND3 = case when lead(DownFlag_wGap, 1) over(partition by b.SavvyMRN order by b.Year_Mo) = 0
						and Gaps >= 6
						and UpFlag_wGap = 1	then b.Stage_IND	else b.Stage_IND2	end
--into #Stagev3
select *
from	(
			select *
				, DownFlag_wGap = case when (lead(Stage_IND,1) over(partition by SavvyMRN order by MinYM_stage)) < Stage_IND	then 1	else 0 end
				, UpFlag_wGap	= case when (lead(Stage_IND,1) over(partition by SavvyMRN order by MinYM_stage)) > Stage_IND	then 1	else 0 end
			from	(
						select SavvyMRN, Grp, Stage_IND	--, GapStartYM
							, MinYM_stage = min(a.MinYM_stage)
							, MaxYM_stage = max(MaxYM_stage)
							, Gaps = datediff(mm, cast(cast(min(MinYM_stage) as varchar) + '01' as date), cast(cast(max(MaxYM_stage) as varchar) + '01' as date))
							--, OID = row_number() over(partition by SavvyMRN, Grp, Stage_IND order by GapStartYM)
						--select *
						from #temp	a
						left join #temp	b	on	a.SavvyMRN = b.SavvyMRN
												and a.grp = b.grp
												and a.OID = (b.OID + 1)
						group by SavvyMRN, Grp, Stage_IND, GapStartYM
						--order by grp, MinYM_stage
					) z
		)	a
inner join	#StageIND	b	on	a.SavvyMRN = b.SavvyMRN
							and b.Year_Mo between MinYM_stage and MaxYM_stage
--group by b.SavvyMRN, b.Year_Mo, b.Stage_IND, b.Stage_IND2
--	, a.DownFlag_wGap, a.Gaps, a.UpFlag_wGap
order by b.SavvyMRN, b.Year_Mo
--(327360 row(s) affected)
create unique index uxIx_SavvyMRN_YM on #Stagev3 (SavvyMRN, Year_Mo);

select *
from #Stagev3
where SavvyMRN = 630674	--201402
order by 1,2
*/

alter table pdb_CGMType2..GP1062_MemberSummary_DMC
	alter column Diab_Med_Stage_v3 varchar(7)
go

update pdb_CGMType2..GP1062_MemberSummary_DMC
set Diab_Med_Stage_v3 = 'Stage ' + b.Stage_IND3
from pdb_CGMType2..GP1062_MemberSummary_DMC	a
left join #Stagev3							b	on	a.SavvyMRN = b.SavvyMRN
												and a.Year_Mo = b.Year_Mo
--(355,646 row(s) affected)

--select * from pdb_CGMType2..GP1062_MemberSummary_DMC order by 1, Year_Mo

-------------------------------
--Diabetes Medication Stage v3
--use Mark & Tin's versions
-------------------------------
update pdb_CGMType2..GP1062_MemberSummary_DMC
set Diab_Med_Stage_v3 = 'Stage ' + b.Diab_Med_Stage_V3
from pdb_CGMType2..GP1062_MemberSummary_DMC	a
inner join pdb_CGMType2..ETL_sma_version3_stage	b	on	a.SavvyMRN = b.SavvyMRN
													and a.Year_Mo = b.Year_Mo
--(355646 row(s) affected)