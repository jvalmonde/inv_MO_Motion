/*** 
GP 1062 - T2D Adherence

Input databases:	MiniPAPI, MiniOV, pdb_CGMType2

Date Created: 12 July 2017
***/

--check how many members we're losing if any
select count(distinct a.SAvvyHICN)	
from pdb_CGMType2..Stage2_RS_MemberDemo_4yrs	a	--170,032
--inner join MiniOV..SavvyID_to_SavvyHICN			b	on	a.SavvyHICN = b.SavvyHICN	--169,874
inner join MiniPAPI..SavvyID_to_SavvyHICN			b	on	a.SavvyHICN = b.SavvyHICN	--169,989

--------------------------------------------
--compute for metric 5 adherence
--------------------------------------------
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
			select a.SavvyHICN, e.DMC_Categories, c.Day_Supply, d.FULL_DT
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
			group by a.SavvyHICN, e.DMC_Categories, c.Day_Supply, d.FULL_DT
		) z
--(4,492,371 row(s) affected)
create index Ix_SavvyHICN_DMC on #DaySupply (SavvyHICN, DMC_Categories);


If Object_ID('tempdb..#Adherence') is not null
drop table #Adherence
go

select a.SavvyHICN, a.DMC_Categories
	, Adh = (Ttl_DaySupply - b.Day_Supply)*1.0 / nullif(Ttl_Gaps, 0)
into #Adherence
from	(
			select SavvyHICN, DMC_Categories
				, Ttl_DaySupply = sum(Day_Supply)
				, Max_OID =	 max(OID)
				, Ttl_Gaps = sum(Gaps)
			from #DaySupply
			--where SavvyHICN =	91495	--18333
			group by SavvyHICN, DMC_Categories
		) a
inner join #DaySupply	b	on	a.SavvyHICN = b.SavvyHICN
							and a.DMC_Categories = b.DMC_Categories
							and Max_OID = b.OID
--(272,837 row(s) affected)
create unique index uIx_SavvyHICN_DMC on #Adherence (SavvyHICN, DMC_Categories);

select * from #Adherence
select count(distinct SavvyHICN)  from #Adherence	--127,495

--build final table
If Object_ID('pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc') is not null
drop table pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc
go

select a.SavvyHICN, b.DMC_Categories
	, Stage = ''
	, IP_Stays	= ceiling(sum(a.IP_visits)*1.0 / count(*))
	, IP_Days	= ceiling(sum(a.Total_IP_Days)*1.0 / count(*))
	, ER_visits	= ceiling(sum(a.ER_visits)*1.0 / count(*))
	, DR_visits	= ceiling(sum(a.DR_visits)*1.0 / count(*))
	, OP_visits	= ceiling(sum(a.OP_visits)*1.0 / count(*))
	, Cnt_DME	= ceiling(sum(a.Cnt_DME)*1.0 / count(*))
	--spend
	, IP_Allow	= sum(a.IP_Spend) / count(*)
	, ER_Allow	= sum(a.ER_Spend) / count(*)
	, DR_Allow	= sum(a.DR_Spend) / count(*)
	, OP_Allow	= sum(a.OP_Spend) / count(*)
	, RX_Allow	= sum(a.RX_Spend) / count(*)	--all RX claims, not just diabetes drugs
	, DME_Allow	= sum(a.DME_Spend) / count(*)
	, Total_Allow	= sum(a.Total_Spend) / count(*)
	, Adhrence5 = max(b.Adh)
into pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc
from pdb_CGMType2..RSKC_MemberSummary_4yrs_GW	a
inner join #Adherence							b	on	a.SavvyHICN = b.SavvyHICN
--where a.SavvyHICN =	368
group by a.SavvyHICN, b.DMC_Categories

create index Ix_SavvyHICN on pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc (SavvyHICN);

select * from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc order by 1, 2

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

select * from #StageIND order by 1, 2

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
--(6119760 row(s) affected)
create unique index uIx_SavvyHICN_YM on #StageIND_v3_YM (SavvyHICN, Year_Mo);


select * from #StageIND_v3_YM where savvyhicn	= 368 order by 2

If (object_id('tempdb..#avg_stagev3') Is Not Null)
Drop Table #avg_stagev3
go

select SavvyHICN, Avg_Stage_IND3 = avg(cast(Stage_IND3 as tinyint))
into #avg_stagev3
from #StageIND_v3_YM
--where savvyhicn	= 368
group by SavvyHICN
--(127,495 row(s) affected)
create unique index uIx_SavvyHICN on #avg_stagev3 (SavvyHICN);

select distinct Avg_Stage_IND3  from #avg_stagev3

update pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc
set Stage = b.Avg_Stage_IND3
from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc	a
left join #avg_stagev3									b	on	a.SavvyHICN = b.SavvyHICN
--(272,837 row(s) affected)

select * from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT_uhc