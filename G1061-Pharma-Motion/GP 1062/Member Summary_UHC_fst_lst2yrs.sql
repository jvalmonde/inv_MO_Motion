/*** 
GP 1062 - T2D Adherence (UHC population)
	- create table for the first 2 years adherence per month & last 2 years per month with their corresponding utilization

Input databases:	MiniPAPI, MiniOV, pdb_CGMType2

Date Created: 17 July 2017
***/

--pull for the diabetes drugs
If Object_ID('tempdb..#DiabetesMeds') is not null
drop table #DiabetesMeds;

select *,
	DMC_Categories = case when Drug_Generic_Name like '%chlorpropamide%'	or Drug_Generic_Name like '%glipizide%'
	 						or Drug_Generic_Name like '%glyburide%'		or Drug_Generic_Name like '%glimepiride%'
	 						or Drug_Generic_Name like '%gliclazide%'		or Drug_Generic_Name like '%tolazamide%'
	 						or Drug_Generic_Name like '%tolbutamide%'																	then 'DMC_Sulfonylureas'
						when Drug_Generic_Name like '%repaglinide%'		or Drug_Generic_Name like '%nateglinide%'						then 'DMC_Meglitinides'
						when Drug_Generic_Name like '%metformin%'																		then 'DMC_Biguanides'
						when Drug_Generic_Name like '%rosiglitazone%'		or Drug_Generic_Name like '%pioglitazone%'					then 'DMC_Thiazolidinediones'
						when Drug_Generic_Name like '%sitagliptin%'		or Drug_Generic_Name like '%saxagliptin%'
	 						or Drug_Generic_Name like '%linagliptin%'		or Drug_Generic_Name like '%alogliptin%'					then 'DMC_DPP4'
						when Drug_Generic_Name like '%acarbose%'			or Drug_Generic_Name like '%miglitol%'						then 'DMC_AlphaGlucosidase'
						when Drug_Generic_Name like '%canagliflozin%'     or Drug_Generic_Name like '%dapagliflozin%'
	 						or Drug_Generic_Name like '%empagliflozin%'																	then 'DMC_SGLT2'
						when Drug_Generic_Name like '%Colesevelam%'																		then 'DMC_BileAcidSequestrants'
						when Drug_Generic_Name like '%Bromocriptine%'																	then 'DMC_DopamineAgonist'
						when Drug_Generic_Name like '%Pramlintide%'																		then 'DMC_AmylinAnalogue'
						when Drug_Generic_Name like '%liraglutide%'		or Drug_Generic_Name like '%albiglutide%'
	 						or Drug_Generic_Name like '%dulaglutide%'		or Drug_Generic_Name like '%exenatide%'						then 'DMC_GLP1_Receptor_Agonist'
						when Drug_Generic_Name like '%insulin glulisine%'			  or Drug_Generic_Name like '%insulin lispro%'									
							or Drug_Generic_Name like '%insulin aspart%'			  or Drug_Generic_Name like 'insulin regular%'		
							or Drug_Generic_Name like 'insulin nph & regular%'	  or Drug_Generic_Name like 'insulin nph isophane & regular%'
							or Drug_Generic_Name like 'insulin isophane & regular%' or Drug_Generic_Name like '%insulin nph%reg%'					then 'DMC_Short_Acting_Insulin'
						when Drug_Generic_Name like 'insulin isophane (%'			  or Drug_Generic_Name like '%(isophane)%' 
							or Drug_Generic_Name like '%insulin isophane%'		  or Drug_Generic_Name like '%insulin nph%' 
							or Drug_Generic_Name like '%insulin zinc%'																	then 'DMC_Intermediate_Acting_Insulin'
						when Drug_Generic_Name like '%insulin detemir%'	or Drug_Generic_Name like '%insulin glargine%'
							or Drug_Generic_Name like '%insulin degludec%'																then 'DMC_Long_Acting_Insulin'			else null	end
into #DiabetesMeds
from MiniPAPI..Dim_Drug
where   
	-- Short-acting
		Drug_Generic_Name like '%insulin glulisine%'			or 
		Drug_Generic_Name like '%insulin lispro%'				or
		Drug_Generic_Name like '%insulin aspart%'				or 
		Drug_Generic_Name like '%insulin regular%'			or
	-- Intermediate-acting
		Drug_Generic_Name like '%insulin isophane%'			or
		Drug_Generic_Name like '%insulin nph%'				or
		Drug_Generic_Name like '%insulin zinc%'				or 
	-- Long-acting
		Drug_Generic_Name like '%insulin detemir%'			or 
		Drug_Generic_Name like '%insulin glargine%'			or 
		Drug_Generic_Name like '%insulin degludec%'			or
	-- Non-insulin injectibles
		Drug_Generic_Name like '%pramlintide%'				or
		Drug_Generic_Name like '%liraglutide%'				or
		Drug_Generic_Name like '%albiglutide%'				or
		Drug_Generic_Name like '%dulaglutide%'				or
		Drug_Generic_Name like '%exenatide%'					or
		Drug_Generic_Name like '%exenatide extended release%'	or
	-- Oral anti-hyperglycemics
		Drug_Generic_Name like '%chlorpropamide%'				or
		Drug_Generic_Name like '%glipizide%'					or
		Drug_Generic_Name like '%glyburide%'					or
		Drug_Generic_Name like '%glimepiride%'				or
		Drug_Generic_Name like '%gliclazide%'					or
		Drug_Generic_Name like '%tolazamide%'					or
		Drug_Generic_Name like '%tolbutamide%'				or
		Drug_Generic_Name like '%repaglinide%'				or
		Drug_Generic_Name like '%nateglinide%'				or
		Drug_Generic_Name like '%metformin%'					or
		Drug_Generic_Name like '%rosiglitazone%'				or
		Drug_Generic_Name like '%pioglitazone%'				or
		Drug_Generic_Name like '%sitagliptin%'				or
		Drug_Generic_Name like '%saxagliptin%'				or
		Drug_Generic_Name like '%linagliptin%'				or
		Drug_Generic_Name like '%alogliptin%'					or
		Drug_Generic_Name like '%acarbose%'					or
		Drug_Generic_Name like '%miglitol%'					or
		Drug_Generic_Name like '%canagliflozin%'				or
		Drug_Generic_Name like '%dapagliflozin%'				or
		Drug_Generic_Name like '%empagliflozin%'				or
		Drug_Generic_Name like '%colesevelam%'				or
		Drug_Generic_Name like '%bromocriptine%'
--(6,761 row(s) affected)
Create unique clustered index ucix_DrugSysID on #DiabetesMeds(Drug_Sys_ID);
create index Ix_GnrcNm on #DiabetesMeds (Drug_Generic_Name);

--day supply
If Object_ID('tempdb..#DaySupply') is not null
drop table #DaySupply
go

select *
	, Gaps = datediff(dd, FULL_DT, lead(FULL_DT, 1) over(partition by SavvyHICN, DMC_Categories order by OID))
into #DaySupply
from	(
			select a.SavvyHICN, e.DMC_Categories, c.Day_Supply, d.FULL_DT, d.YEAR_MO
				, OID = row_number() over(partition by a.SavvyHICN, e.DMC_Categories order by d.FULL_DT)
			--select count(distinct a.SavvyHICN)	--162,281
			from pdb_CGMType2..Stage2_RS_MemberDemo_4yrs	a	
			inner join MiniPAPI..SavvyID_to_SavvyHICN		b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniPAPI..Fact_Claims				c	on	b.SavvyID = c.SavvyId
			inner join MiniPAPI..Dim_Date					d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
			inner join #DiabetesMeds						e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
			where d.YEAR_NBR between 2012 and 2015
				and c.Claim_Status = 'P'
				--and a.SavvyHICN = 18333
			group by a.SavvyHICN, e.DMC_Categories, c.Day_Supply, d.FULL_DT, d.YEAR_MO
			--order by FULL_DT
		) z
--(4,492,371 row(s) affected)
create index Ix_SavvyHICN_DMC on #DaySupply (SavvyHICN, DMC_Categories);
select * from #DaySupply where SavvyHICN = 18333

If Object_ID('tempdb..#Adherence_fst2yrs') is not null
drop table #Adherence_fst2yrs
go

select a.SavvyHICN, a.DMC_Categories
	, Adh = (Ttl_DaySupply - b.Day_Supply)*1.0 / nullif(Ttl_Gaps, 0)
into #Adherence_fst2yrs
from	(
			select SavvyHICN, DMC_Categories
				, Ttl_DaySupply = sum(Day_Supply)
				, Max_OID =	 max(OID)
				, Ttl_Gaps = sum(Gaps)
			from #DaySupply
			where YEAR_MO between 201201 and 201312	--first 2 years
				--and SavvyHICN =	18333	--18333
			group by SavvyHICN, DMC_Categories
		) a
inner join #DaySupply	b	on	a.SavvyHICN = b.SavvyHICN
							and a.DMC_Categories = b.DMC_Categories
							and Max_OID = b.OID
--(223,479 row(s) affected)
create unique index uIx_SavvyHICN_DMC on #Adherence_fst2yrs (SavvyHICN, DMC_Categories);

If Object_ID('tempdb..#Adherence_lst2yrs') is not null
drop table #Adherence_lst2yrs
go

select a.SavvyHICN, a.DMC_Categories
	, Adh = (Ttl_DaySupply - b.Day_Supply)*1.0 / nullif(Ttl_Gaps, 0)
into #Adherence_lst2yrs
from	(
			select SavvyHICN, DMC_Categories
				, Ttl_DaySupply = sum(Day_Supply)
				, Max_OID =	 max(OID)
				, Ttl_Gaps = sum(Gaps)
			from #DaySupply
			where YEAR_MO between 201401 and 201512	--first 2 years
				--and SavvyHICN =	18333	--18333
			group by SavvyHICN, DMC_Categories
		) a
inner join #DaySupply	b	on	a.SavvyHICN = b.SavvyHICN
							and a.DMC_Categories = b.DMC_Categories
							and Max_OID = b.OID
--(231,316 row(s) affected)
create unique index uIx_SavvyHICN_DMC on #Adherence_lst2yrs (SavvyHICN, DMC_Categories);


If Object_ID('tempdb..#AdherenceYM') is not null
drop table #AdherenceYM
go

select a.SavvyHICN, a.YEAR_MO, a.DMC_Categories
	, Adherence = max(case when (a.YEAR_MO between 201201 and 201312)	then b.Adh
							when (a.YEAR_MO between 201401 and 201512) then c.Adh	else 0	end)
into #AdherenceYM
from #DaySupply	a
left join #Adherence_fst2yrs	b	on	a.SavvyHICN = b.SavvyHICN
									and a.DMC_Categories = b.DMC_Categories
left join #Adherence_lst2yrs	c	on	a.SavvyHICN = c.SavvyHICN
									and a.DMC_Categories = c.DMC_Categories
--where a.SavvyHICN =	18333
group by a.SavvyHICN, a.YEAR_MO, a.DMC_Categories, b.Adh
order by 2, 3
--(4,241,187 row(s) affected)
create unique index uIx_SavvyHICN_YM_DMC on #AdherenceYM (SavvyHICN, YEAR_MO, DMC_Categories);

------------------------
--Diag_Med_Stage_v3
------------------------
If (object_id('tempdb..#StageIND') Is Not Null)
Drop Table #StageIND
go

select a.SavvyHICN, a.Year_Mo
	, Stage_IND = right(Diab_Med_Stage, 1)
	, Stage_IND2 = right(Diab_Med_Stage_V2, 1)
into #StageIND
from pdb_CGMType2..RSKC_MemberSummary_4yrs_GW	a
inner join pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc	b	on	a.SavvyHICN = b.SavvyHICN
--where a.SavvyHICN = 300889
group by a.SavvyHICN, a.Year_Mo, Diab_Med_Stage, Diab_Med_Stage_V2
--(6,119,760 row(s) affected)
create index Ix_SavvyHICN on #StageIND (SavvyHICN);

If (object_id('tempdb..#StageIND_v3_YM') Is Not Null)
Drop Table #StageIND_v3_YM
go

with Tbl as (
	select SavvyHICN
		, Year_Mo
		, Stage_IND
		, Stage_IND2
		, compare
		, count(GrpInd) over (partition by SavvyHICN,GrpInd) as cnt
		, max(Stage_IND) over (partition by SavvyHICN,GrpInd order by year_mo rows unbounded preceding) as max_val
	From (
			Select *
				,sum(case when compare=Prev_val then 0 else 1 end) over (partition by SavvyHICN order by Year_mo) as GrpInd
			From (
					select * 
					         ,Lag(compare,1,compare) over (partition by SavvyHICN order by Year_mo) as Prev_val
					from(
							SELECT SavvyHICN
							      ,Year_Mo
							      ,Stage_IND
							      ,Stage_IND2
							      ,case when Stage_IND < max(Stage_IND2) over (partition by SavvyHICN order by Year_mo) then 1 else 0 end as compare --1 for decrease 0 for increase/same    
							FROM #StageIND   --source table
							--where savvyhicn	= 368	--100133	--in (123456)
					) A
			) AA
	) AAA
	--order by savvyhicn,year_mo
)
select SavvyHICN
	, Year_Mo
	, Stage_IND
	, Stage_IND2
	--,compare
	--,cnt
	, case when Compare=1 and cnt>=6 then max_val  else Stage_IND2 end as Stage_IND3
into #StageIND_v3_YM
from  tbl 
order by savvyhicn,year_mo
--(6,119,760 row(s) affected)
create unique index uIx_SavvyHICN_YM on #StageIND_v3_YM (SavvyHICN, Year_Mo);


If (object_id('pdb_CGMType2..GP1062_MemberSummary_DMC_YM_uhc') Is Not Null)
Drop Table pdb_CGMType2..GP1062_MemberSummary_DMC_YM_uhc
go

select a.SavvyHICN, a.Year_Mo
	, b.DMC_Categories
	, b.Adherence
	, Total_IP_Days 
	, IP_visits		
	, OP_visits, DR_visits, ER_visits, Cnt_NDC, Cnt_DME, Nbr_Hypo_Events
	, IP_Spend, OP_Spend, DR_Spend, ER_Spend, RX_Spend, RX_Spend_Diab, RX_Spend_NonDiab, DME_Spend, Total_Spend_Hypo_Events
	, Total_Spend
	, Diab_Med_Stage, Diab_Med_Stage_V2
	, Diab_Med_Stage_v3 = 'Stage ' + c.Stage_IND3
	, A1C, A1C_V2
into pdb_CGMType2..GP1062_MemberSummary_DMC_YM_uhc
from	(
			select a.SavvyHICN, a.Year_Mo
				, Total_IP_Days, IP_visits, OP_visits, DR_visits, ER_visits, Cnt_NDC, Cnt_DME, Nbr_Hypo_Events
				, IP_Spend, OP_Spend, DR_Spend, ER_Spend, RX_Spend, RX_Spend_Diab, RX_Spend_NonDiab, DME_Spend, Total_Spend_Hypo_Events
				, Total_Spend
				, Diab_Med_Stage, Diab_Med_Stage_V2, A1C, A1C_V2
			from pdb_CGMType2..RSKC_MemberSummary_4yrs_GW	a
			inner join	(--127,495
							select SavvyHICN
							from #AdherenceYM
							group by SavvyHICN
						) 	b	on	a.SavvyHICN = b.SavvyHICN
			--where a.SavvyHICN =	18333
		) a
left join #AdherenceYM		b	on	a.SavvyHICN = b.SavvyHICN
								and a.Year_Mo = b.YEAR_MO
left join #StageIND_v3_YM	c	on	a.SavvyHICN = c.SavvyHICN
								and a.Year_Mo = c.Year_Mo
--(7246570 row(s) affected)

--select count(distinct SavvyHICN)	--127,495
--select *
select avg(OP_visits), avg(OP_Spend)	--, avg(IP_Spend)
from pdb_CGMType2..GP1062_MemberSummary_DMC_YM_uhc
where OP_visits > 0

select SavvyHICN, count(distinct Year_Mo)
from pdb_CGMType2..GP1062_MemberSummary_DMC_YM_uhc
group by SavvyHICN
having count(distinct Year_Mo) < 48