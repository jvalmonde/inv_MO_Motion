-------------------------------------------------------------
--1) Get Enrollment Data based on UGAP and MMR Enrollment
-------------------------------------------------------------
--Get members in 10% sample and their UGAP enrollment data
-- drop table #members
select distinct a.SavvyHICN, b.SavvyID
into #members
from (
	select distinct savvyhicn from  LTV..CMS_MMR_Sub_201709 
	union
	select distinct savvyhicn from LTV..MMR_Lost
	union
	select distinct savvyhicn from LTV..MMR )					as a
join MiniOV..SavvyID_to_SavvyHICN				as b	on a.SavvyHICN = b.SavvyHICN


create unique index ix_hicn on #members(SavvyHICN)
-- 5,168,028

--MAPD flags broken for 2017, use derived MAPD indicator from MMR instead
-- drop table #mapd
select ContractNumber, PlanBenefitPackageID, year(PaymentAdjustmentStartDate) as Yr,
	   case when sum(convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-','')))) > 0 then 1 else 0 end as MAPDFlag
into #mapd
from (
	select ContractNumber, PlanBenefitPackageID, convert(datetime,PaymentAdjustmentStartDate) as PaymentAdjustmentStartDate, convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-',''))) as TotalPartDPayment from  LTV..CMS_MMR_Sub_201709 
	union
	select ContractNumber, PlanBenefitPackageID, convert(datetime,PaymentAdjustmentStartDate) as PaymentAdjustmentStartDate, convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-',''))) as TotalPartDPayment from LTV..MMR_Lost
	union
	select ContractNumber, PlanBenefitPackageID, PaymentAdjustmentStartDate, convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-',''))) as TotalPartDPayment from LTV..MMR 
	) as a
group by ContractNumber, PlanBenefitPackageID, year(PaymentAdjustmentStartDate)
-- 6,259


--Get member-month level enrollment data for COSMOS MAPD
-- drop table #ugap_enrollment
select distinct b.SavvyHICN, a.Year_Mo, c.Contr_Nbr, c.PBP
into #ugap_enrollment
from MiniOV..Fact_MemberContract		as a 
join MiniOV..SavvyID_to_SavvyHICN		as b	on a.SavvyID = b.SavvyID
join MiniOV..Dim_Contract				as c	on a.Contr_Sys_Id = c.Contr_Sys_ID
join #members							as d	on b.SavvyHICN = d.SavvyHICN
join #mapd								as e	on c.Contr_Nbr = e.ContractNumber 
											   and c.PBP = e.PlanBenefitPackageID 
											   and c.Contr_Yr = e.Yr	
where a.Year_Mo between 200601 and 201703
  and a.Src_Sys_Cd = 'CO'		--COSMOS only
  and e.MAPDFlag = 1			--MAPD only
  --and c.MAPDFlag = 'Y'		--MAPD only  BROKEN!
 -- and c.PBP not like '8%'	--exclude group retiree contracts
-- 164,998,169

select * from #ugap_enrollment where SavvyHICN = 4

--Get MMR enrollment and revenue data, adjusting for retrospecitve adjustments
--by attributing dollars to service month (not payment month).
-- drop table #year_mo
select distinct Year_Mo
into #year_mo
from MiniOV..Dim_Date
-- 2,113
create unique index ix_year_mo on #year_mo(Year_Mo)


-- drop table #mmr_enrollment
select a.SavvyHICN, a.Year_Mo, a.ContractNumber, a.PlanBenefitPackageID,
	   max(a.PartDRAFactor) as D_RAF, 
	   max(a.RiskAdjusterFactorA) as MA_RAF,
	   cast(sum(Adjusted_MA_Amt) as money) as Total_MA_Amt, 
	   cast(sum(Adjusted_D_Amt) as money) as Total_D_Amt, 
	   cast(sum(LowIncomeSubsidyCostSharingAmount) as money) as LICS_Amt,
	   cast(sum(ReinsuranceSubsidyAmount) as money) as Reinsurance_Amt,
	   max(a.HospiceFlag) as HospiceFlag
into #mmr_enrollment
from(
	select a.SavvyHICN, b.Year_Mo, a.ContractNumber, a.PlanBenefitPackageID,
		   a.PartDRAFactor, a.RiskAdjusterFactorA, 
		   a.LowIncomeSubsidyCostSharingAmount, 
		   a.ReinsuranceSubsidyAmount,
		   a.HospiceFlag,
		   a.TotalMAPaymentAmount/(a.End_Year_Mo-a.Start_Year_Mo+1) as Adjusted_MA_Amt, --distribute multi-month costs 
		   a.TotalPartDPayment/(a.End_Year_Mo-a.Start_Year_Mo+1) as Adjusted_D_Amt
	from(
		select a.SavvyHICN, a.ContractNumber, a.PlanBenefitPackageID,
			   a.PartDRAFactor, a.RiskAdjusterFactorA, 
			  [TotalMAPaymentAmount], 
			   TotalPartDPayment, 
			   LowIncomeSubsidyCostSharingAmount,
			   ReinsuranceSubsidyAmount,
			   a.HospiceFlag,
			   a.PaymentAdjustmentStartDate, a.PaymentAdjustmentEndDate, 
			   Start_Year_Mo,
			   End_Year_Mo
		from 
			(
				select convert(varchar,SavvyHICN) as SavvyHICN, ContractNumber, PlanBenefitPackageID,
						PartDRAFactor, RiskAdjusterFactorA, 
						convert(money,(replace(replace([TotalMAPaymentAmount],'','0'),'E-',''))) as [TotalMAPaymentAmount], 
						convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-',''))) as TotalPartDPayment, 
						convert(money,(replace(replace(LowIncomeSubsidyCostSharingAmount,'','0'),'E-',''))) as LowIncomeSubsidyCostSharingAmount,
						convert(money,(replace(replace(ReinsuranceSubsidyAmount,'','0'),'E-','')))as ReinsuranceSubsidyAmount,
						HospiceFlag,
						PaymentAdjustmentStartDate, PaymentAdjustmentEndDate, 
						cast(left(replace(PaymentAdjustmentStartDate, '-', ''), 6) as int) as Start_Year_Mo,
						cast(left(replace(PaymentAdjustmentEndDate, '-', ''), 6) as int) as End_Year_Mo
				from ltv..CMS_MMR_Sub_201709
				union
				select SavvyHICN, ContractNumber, PlanBenefitPackageID,
						PartDRAFactor, RiskAdjusterFactorA, 
						convert(money,(replace(replace([TotalMAPaymentAmount],'','0'),'E-',''))) as [TotalMAPaymentAmount], 
						convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-',''))) as TotalPartDPayment, 
						convert(money,(replace(replace(LowIncomeSubsidyCostSharingAmount,'','0'),'E-',''))) as LowIncomeSubsidyCostSharingAmount,
						convert(money,(replace(replace(ReinsuranceSubsidyAmount,'','0'),'E-','')))as ReinsuranceSubsidyAmount,
						HospiceFlag,
						PaymentAdjustmentStartDate, PaymentAdjustmentEndDate, 
						cast(left(replace(convert(varchar,PaymentAdjustmentStartDate), '-', ''), 6) as int) as Start_Year_Mo,
						cast(left(replace(convert(varchar,PaymentAdjustmentEndDate), '-', ''), 6) as int) as End_Year_Mo
				from LTV..MMR_Lost
				union
				select SavvyHICN, ContractNumber, PlanBenefitPackageID,
						convert(varchar,PartDRAFactor) as PartDRAFactor, convert(varchar,RiskAdjusterFactorA) as RiskAdjusterFactorA, 
						convert(money,(replace(replace([TotalMAPaymentAmount],'','0'),'E-',''))) as [TotalMAPaymentAmount], 
						convert(money,(replace(replace(TotalPartDPayment,'','0'),'E-',''))) as TotalPartDPayment, 
						convert(money,(replace(replace(LowIncomeSubsidyCostSharingAmount,'','0'),'E-',''))) as LowIncomeSubsidyCostSharingAmount,
						convert(money,(replace(replace(ReinsuranceSubsidyAmount,'','0'),'E-','')))as ReinsuranceSubsidyAmount,
						HospiceFlag,
						PaymentAdjustmentStartDate, PaymentAdjustmentEndDate, 
						convert(varchar,year(PaymentAdjustmentStartDate) * 100 + MONTH(PaymentAdjustmentStartDate)) as Start_Year_Mo,
						convert(varchar,year(PaymentAdjustmentEndDate) * 100 + MONTH(PaymentAdjustmentEndDate)) as End_Year_Mo
				from LTV..MMR  )	as a
		join #members					as b	on a.SavvyHICN = b.SavvyHICN
		)				as a 
	join #year_mo		as b	on b.Year_Mo between a.Start_Year_Mo and a.End_Year_Mo
	where b.Year_Mo between 200601 and 201703
	) as a
group by a.SavvyHICN, a.YEAR_MO, a.ContractNumber, a.PlanBenefitPackageID
having cast(sum(Adjusted_MA_Amt) as money) > 0	--Has MA benefit (resolves retroactive reversals)
   and cast(sum(Adjusted_D_Amt) as money) > 0	--Has Part D benefit
-- 61,750,155



--Summarize into master enrollment table
--Requires both UGAP + MMR agreement (98% of MM)
-- drop table #enrollment
select a.SavvyHICN, a.Year_Mo, a.Contr_Nbr, a.PBP,
	   (left(a.Year_Mo, 4)-2006)*12+right(a.Year_Mo, 2) as Year_Mo_Rank,
	   0 as Lifetime_ID --Will be updated later
into #enrollment
from #ugap_enrollment		as a 
join #mmr_enrollment		as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
								   and a.Contr_Nbr = b.ContractNumber and a.PBP = b.PlanBenefitPackageID
-- 43,598,062

create unique index ix_x on #enrollment(SavvyHICN, Year_Mo)

select * from #enrollment where savvyhicn = 4

---------------------------------------------------------------
--2) Add lifetime IDs based on blocks of continuous enrollment
---------------------------------------------------------------
--Start by identifying "new enollment" months (i.e. not enrolled in the previous month)
-- drop table #new_enrolls
select a.SavvyHICN, a.Year_Mo, row_number() over(partition by a.SavvyHICN order by a.Year_Mo) as RN
into #new_enrolls
from #enrollment		as a 
left join #enrollment	as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo_Rank = b.Year_Mo_Rank+1
where b.SavvyHICN is null --No previous month = new enroll
order by 1
-- 50,942

--Identify start and end dates for the lifetime (start = new enroll month, end = next enrollment month - 1)
-- drop table #lifetimes
select a.SavvyHICN, a.Year_Mo as Start_Year_Mo, isnull(b.Year_Mo-1, '999999') as End_Year_Mo, a.RN as Lifetime_ID
into #lifetimes
from #new_enrolls		as a 
left join #new_enrolls	as b	on a.SavvyHICN = b.SavvyHICN and a.RN+1 = b.RN
-- 50,942

create unique index ix_x on #lifetimes(SavvyHICN, Start_Year_Mo)

--Update the Lifetime_ID
update #enrollment
set #enrollment.Lifetime_ID = b.Lifetime_ID  
from #enrollment		as a 
join #lifetimes			as b	on a.SavvyHICN = b.SavvyHICN 
where a.Year_Mo between b.Start_Year_Mo and b.End_Year_Mo
-- 2,444,506



-------------------------------------------------------------
--4) Get claims costs
-------------------------------------------------------------
--Medical claims
-- drop table #med_claims
select b.SavvyHICN, c.Year_Mo, 
		sum(a.Allw_Amt) as Allw_Amt,
		sum(a.Net_Pd_Amt) as Net_Pd_Amt, 
		sum(a.OOP_Amt) as OOP_Amt,
		sum(case when a.Srvc_Typ_Sys_Id = 1 then a.Net_Pd_Amt else 0 end) as IP_Amt,
		sum(case when a.Srvc_Typ_Sys_Id = 2 then a.Net_Pd_Amt else 0 end) as OP_Amt,
		sum(case when a.Srvc_Typ_Sys_Id = 3 then a.Net_Pd_Amt else 0 end) as DR_Amt
into #med_claims
from MiniOV..Fact_Claims			as a 
join MiniOV..SavvyID_to_SavvyHICN	as b	on a.SavvyId = b.SavvyID
join MiniOV..Dim_Date				as c	on a.Dt_Sys_Id = c.DT_SYS_ID
join #members						as d	on b.SavvyHICN = d.SavvyHICN
where c.Year_Mo between 200601 and 201703
group by b.SavvyHICN, c.Year_Mo
-- 1,360,079

create unique index uix on #med_claims(savvyhicn,year_mo)

-- drop table #IP_Days
select distinct a.SavvyId
	, b.SavvyHICN
	, a.Dt_Sys_Id as Admit_Dt_sys_Id 
	, a.Dt_Sys_Id + a.Day_Cnt as Discharge_Dt_Sys_Id 
into #IP_Days
from MiniOV..Fact_Claims			as a 
join MiniOV..SavvyID_to_SavvyHICN	as b	on a.SavvyId = b.SavvyID
join MiniOV..Dim_Date				as c	on a.Dt_Sys_Id = c.DT_SYS_ID
join #members						as d	on b.SavvyHICN = d.SavvyHICN
where c.Year_Mo between 200601 and 201703 and a.Admit_Cnt = 1

-- drop table #Distinct_IP_Days
select distinct a.SavvyHICN, a.SavvyId, b.DT_SYS_ID as IP_Dt_Sys_Id
into #Distinct_IP_Days
from #IP_Days as a
join  MiniOV..Dim_Date as b on b.DT_SYS_ID between a.Admit_Dt_sys_Id and a.Discharge_Dt_Sys_Id


-- drop table #med_claims_2
select a.SavvyHICN
	, d.Year_Mo		
	, Derived_IP			= isnull(sum(case when (case when h.SavvyHICN is not null and f.Srvc_Typ_Cd <> 'IP'	then 'IP'  
											   when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'
											   when g.AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'		then 'DME'	else 	f.Srvc_Typ_Cd	end	) = 'IP' 	then Net_Pd_Amt else 0 end),0)
	, Derived_OP			= isnull(sum(case when (case when h.SavvyHICN is not null and f.Srvc_Typ_Cd <> 'IP'	then 'IP'  
											   when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'
											   when g.AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'		then 'DME'	else 	f.Srvc_Typ_Cd	end	) = 'OP' 	then Net_Pd_Amt else 0 end),0)
	, Derived_DR			= isnull(sum(case when (case when h.SavvyHICN is not null and f.Srvc_Typ_Cd <> 'IP'	then 'IP'  
											   when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'
											   when g.AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'		then 'DME'	else 	f.Srvc_Typ_Cd	end	) = 'DR' 	then Net_Pd_Amt else 0 end),0)	
	, Derived_ER			= isnull(sum(case when (case when h.SavvyHICN is not null and f.Srvc_Typ_Cd <> 'IP'	then 'IP'  
											   when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'
											   when g.AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'		then 'DME'	else 	f.Srvc_Typ_Cd	end	) = 'ER' 	then Net_Pd_Amt else 0 end),0)
	, Derived_DME			= isnull(sum(case when (case when h.SavvyHICN is not null and f.Srvc_Typ_Cd <> 'IP'	then 'IP'  
											   when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'
											   when g.AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'		then 'DME'	else 	f.Srvc_Typ_Cd	end	) = 'DME' then Net_Pd_Amt else 0 end),0)
into #med_claims_2
from #members										a					
inner join MiniOV..Fact_Claims						c	on	a.SavvyID = c.SavvyID
left join MiniOV..Dim_Date							d	on	c.Dt_Sys_Id = d.DT_SYS_ID 
left join MiniOV..Dim_HP_Service_Type_Code			e	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = e.HLTH_PLN_SRVC_TYP_CD_SYS_ID
left join MiniOV..Dim_Service_Type					f	on	c.Srvc_Typ_Sys_Id = f.Srvc_Typ_Sys_Id
left join MiniOV..Dim_Procedure_Code				g	on	c.Proc_Cd_Sys_Id = g.PROC_CD_SYS_ID
left join #Distinct_IP_Days							h	on	a.SavvyHICN = h.SavvyHICN and c.Dt_Sys_Id = h.IP_Dt_Sys_Id	
where d.Year_Mo between 200601 and 201703
group by a.SavvyHICN
	, d.Year_Mo
--23001

create unique index uix on #med_claims_2(savvyhicn,year_mo)
-- select * from #med_claims_2

--Pharmacy claims
-- drop table #rx_claims
select b.SavvyHICN, c.YEAR_MO, 
		sum(a.Allowed) as Allw_Amt,
		sum(a.Total_Amount_Billed) as Net_Pd_Amt, 
		sum(a.Patient_Pay_Amount) as OOP_Amt
		--sum(a.Covered_D_Plan_Paid_Amount) as Covered_D_Plan_Paid_Amount
into #rx_claims
from MiniPAPI..Fact_Claims			as a 
join MiniPAPI..SavvyID_to_SavvyHICN	as b	on a.SavvyId = b.SavvyID
join MiniPAPI..Dim_Date				as c	on a.Date_Of_Service_DtSysId = c.DT_SYS_ID
join #members						as d	on b.SavvyHICN = d.SavvyHICN
where c.YEAR_MO between 200601 and 201703
  and a.Claim_Status = 'P'
group by b.SavvyHICN, c.Year_Mo
-- 1,853,486




-------------------------------------------------------------
--5) Get member-paid premium amounts
-------------------------------------------------------------
--average accross counties, typically very little variation
-- drop table #premiums
select Plan_Year, Contr_Nbr, PBP,
       avg(Premium_C) as Premium_C,
	   avg(Premium_D) as Premium_D
into #premiums
from LTV..CMS_Plan_Benefits_CD_Premiums
group by Plan_Year, Contr_Nbr, PBP
-- 44,503





-------------------------------------------------------------
--6) Gather it all together into primary member-month table
-------------------------------------------------------------
-- drop table #results
select a.*, 

       a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0) as Total_Revenue,


	   (a.Total_Claims_Cost-a.Rx_Rebate_Amt_40Percent) as Total_Cost_40Percent_Rebate,

	   (a.Total_Claims_Cost-a.Rx_Rebate_Amt_Full) as Total_Cost_Full_Rebate,

	   (a.Total_Claims_Cost) as Total_Cost_NoRebate,


	   (a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0))
		- ((a.Total_Claims_Cost-a.Rx_Rebate_Amt_40Percent)) as Total_Value_40Percent_Rebate,

		(a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0))
		- ((a.Total_Claims_Cost-a.Rx_Rebate_Amt_Full)) as Total_Value_Full_Rebate,

		(a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0))
		- ((a.Total_Claims_Cost)) as Total_Value_NoRebate
into #results
from(
	select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, a.Contr_Nbr, a.PBP,
		   b.HospiceFlag,
		   b.Total_MA_Amt, 
		   b.Total_D_Amt, 
		   b.Total_MA_Amt + b.Total_D_Amt as Total_CMS_Amt,
		   
		   isnull(c.OOP_Amt,0) as Total_MA_OOP,
		   isnull(d.OOP_Amt,0) as Total_D_OOP,
		   isnull(c.OOP_Amt,0)+isnull(d.OOP_Amt,0) as Total_OOP,

		   
		   isnull(c.IP_Amt,0) as Total_MA_IP_Cost,
		   isnull(c.OP_Amt,0) as Total_MA_OP_Cost,
		   isnull(c.DR_Amt,0) as Total_MA_DR_Cost,
		   
		   isnull(c2.Derived_IP,0) as Total_MA_Derived_IP_Cost,
		   isnull(c2.Derived_OP,0) as Total_MA_Derived_OP_Cost,
		   isnull(c2.Derived_DR,0) as Total_MA_Derived_DR_Cost,
		   isnull(c2.Derived_ER,0) as Total_MA_Derived_ER_Cost,
		   isnull(c2.Derived_DME,0) as Total_MA_Derived_DME_Cost,

		   isnull(c.Net_Pd_Amt,0) Total_MA_Cost,
		   isnull(d.Net_Pd_Amt,0) as Total_D_Cost,
		   isnull(c.Net_Pd_Amt,0)+isnull(d.Net_Pd_Amt,0) as Total_Claims_Cost,

		   case when isnull(d.Net_Pd_Amt,0)-b.LICS_Amt-b.Reinsurance_Amt > 0
				then (isnull(d.Net_Pd_Amt,0)-b.LICS_Amt-b.Reinsurance_Amt) -- removed 0.4 computation
				else 0 end as Rx_Rebate_Amt_Full, --40% of plan paid if plan paid > 0, else 0
				
		   case when isnull(d.Net_Pd_Amt,0)-b.LICS_Amt-b.Reinsurance_Amt > 0
				then (isnull(d.Net_Pd_Amt,0)-b.LICS_Amt-b.Reinsurance_Amt) * 0.4
				else 0 end as Rx_Rebate_Amt_40Percent, 
		   b.LICS_Amt,
		   b.Reinsurance_Amt,


		   g.Premium_C as Premium_C_Amt,
		   g.Premium_D as Premium_D_Amt,
		   g.Premium_C+g.Premium_D as Total_Premium_Amt,

		   TRY_CAST(case when b.MA_RAF = '' then null else MA_RAF end as decimal(19,4)) as MA_RAF, 
		   TRY_CAST(case when b.D_RAF = '' then null else D_RAF end as decimal(19,4)) as D_RAF,
		   a.Year_Mo_Rank
	from #enrollment				as a 
	join #mmr_enrollment			as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
										   and a.Contr_Nbr = b.ContractNumber and a.PBP = b.PlanBenefitPackageID
	left join #med_claims			as c	on a.SavvyHICN = c.SavvyHICN and a.Year_Mo = c.Year_Mo
	left join #med_claims_2			as c2	on a.SavvyHICN = c2.SavvyHICN and a.Year_Mo = c2.Year_Mo
	left join #rx_claims			as d	on a.SavvyHICN = d.SavvyHICN and a.Year_Mo = d.Year_Mo
	left join #premiums				as g	on a.Contr_Nbr = g.Contr_Nbr and a.PBP = g.PBP
										   and left(a.Year_Mo, 4) = g.Plan_Year
	) as a
-- 2,444,506


--select count(*) from #mmr			--11,749,074
--select count(*) from #enrollment	--10,571,800
--select count(*) from #results		--10,391,028

---- OUTLIER FLAGGING
-- drop table #Total_Year_Cost
select left(year_mo,4) as YR, sum(Total_Claims_Cost) as Grand_Total
into #Grand_Total
from #results as a
where left(year_mo,4) in (2014,2015,2016)
group by left(year_mo,4) 

-- drop table #Total_Per_Member_Cost
select a.SavvyHICN, left(year_mo,4) as YR, sum(Total_Claims_Cost) as Total_Year_Cost
into #Total_Per_Member_Cost
from #results as a
where left(year_mo,4) in (2014,2015,2016)
group by a.SavvyHICN, left(year_mo,4)


-- drop table #Cost_Outlier
select a.savvyhicn
,a.yr
,a.Total_Year_Cost
,max(b.Grand_Total) as Grand_Total
,sum(a.Total_Year_Cost)over(partition by a.yr 
							order by sum(a.Total_Year_Cost) desc rows unbounded preceding) as Moving_Total
,(sum(a.Total_Year_Cost)over(partition by a.yr 
							order by sum(a.Total_Year_Cost) desc rows unbounded preceding) / max(b.Grand_Total)) * 100 as Percentage_of_Grand_Total
,case when (sum(a.Total_Year_Cost)over(partition by a.yr 
							order by sum(a.Total_Year_Cost) desc rows unbounded preceding) / max(b.Grand_Total)) * 100 <= 5 then 1 else 0 end as Outlier_Flag
into #Cost_Outlier
from #Total_Per_Member_Cost as a
join #Grand_Total as b on a.yr = b.yr
group by a.savvyhicn
,a.yr
,a.Total_Year_Cost

create unique index uix on #Cost_Outlier(savvyhicn,yr)

-- drop table #Plan_Info
select distinct a.SavvyHICN
,a.Year_Mo
,d.LegacyOrganization
,d.PBPDescription
,d.Contr_Desc
,d.ProductCategory
,d.ContractType
into #Plan_Info
from #results as a
join MiniOV..SavvyID_to_SavvyHICN as b on a.SavvyHICN = b.SavvyHICN
join MiniOV..Fact_MemberContract as c on b.SavvyID = c.SavvyID and a.Year_Mo = c.Year_Mo
join MiniOV..Dim_Contract as d on c.Contr_Sys_Id = d.Contr_Sys_ID and a.Contr_Nbr = d.Contr_Nbr and a.PBP = d.PBP

create unique index uix on #Plan_Info(savvyhicn,Year_Mo)


-- drop table #results_2
select a.*
,c.LegacyOrganization
,c.PBPDescription
,c.Contr_Desc
,c.ProductCategory
,c.ContractType
,CASE WHEN b.yr = 2014 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2014
,CASE WHEN b.yr = 2015 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2015
,CASE WHEN b.yr = 2016 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2016
into #results_2 
from #results as a
left join #Cost_Outlier as b on a.SavvyHICN = b.SavvyHICN and left(a.Year_Mo,4) = b.YR
left join #Plan_Info as c on a.SavvyHICN = c.SavvyHICN and a.Year_Mo = c.Year_Mo




-------------------------------------------------------------
--7) Adjust all dollars based on CPI
-------------------------------------------------------------
-- drop table pdb_WalkandWin..LTV_Member_Month_092017
select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, a.Contr_Nbr, a.PBP,
	   a.LegacyOrganization,
	   a.PBPDescription,
	   a.Contr_Desc,
	   a.ProductCategory,
	   a.ContractType,
	   a.Total_MA_Amt*b.CPI_Ratio as Total_MA_Amt,
	   a.Total_D_Amt*b.CPI_Ratio as Total_D_Amt,
	   a.Total_CMS_Amt*b.CPI_Ratio as Total_CMS_Amt,
	   
	   a.Total_MA_IP_Cost*b.CPI_Ratio as Total_MA_IP_Cost,
	   a.Total_MA_OP_Cost*b.CPI_Ratio as Total_MA_OP_Cost,
	   a.Total_MA_DR_Cost*b.CPI_Ratio as Total_MA_DR_Cost, 
	   a.Total_MA_Derived_IP_Cost * b.CPI_Ratio as Total_MA_Derived_IP_Cost,
	   a.Total_MA_Derived_OP_Cost * b.CPI_Ratio as Total_MA_Derived_OP_Cost,
	   a.Total_MA_Derived_DR_Cost * b.CPI_Ratio as Total_MA_Derived_DR_Cost,
	   a.Total_MA_Derived_ER_Cost * b.CPI_Ratio as Total_MA_Derived_ER_Cost,
	   a.Total_MA_Derived_DME_Cost * b.CPI_Ratio as Total_MA_Derived_DME_Cost,
	   a.Total_MA_Cost*b.CPI_Ratio as Total_MA_Cost,
	   a.Total_D_Cost*b.CPI_Ratio as Total_D_Cost,
	   a.Total_Claims_Cost*b.CPI_Ratio as Total_Claims_Cost,

	   a.Total_MA_OOP*b.CPI_Ratio as Total_MA_OOP,
	   a.Total_D_OOP*b.CPI_Ratio as Total_D_OOP,
	   a.Total_OOP*b.CPI_Ratio as Total_OOP,
	   
	   a.Rx_Rebate_Amt_Full*b.CPI_Ratio as Rx_Rebate_Amt_Full,
	   a.Rx_Rebate_Amt_40Percent *b.CPI_Ratio as Rx_Rebate_Amt_40Percent,
	   a.LICS_Amt*b.CPI_Ratio as LICS_Amt,
	   a.Reinsurance_Amt*b.CPI_Ratio as Reinsurance_Amt,
	   
	   a.Premium_C_Amt*b.CPI_Ratio as Premium_C_Amt, 
	   a.Premium_D_Amt*b.CPI_Ratio as Premium_D_Amt,
	   a.Total_Premium_Amt*b.CPI_Ratio as TotaL_Premium_Amt,

	   a.MA_RAF,
	   a.D_RAF,
	   a.Year_Mo_Rank,
	   a.Total_Revenue*b.CPI_Ratio as Total_Revenue,
	   a.Total_Cost_40Percent_Rebate*b.CPI_Ratio as Total_Cost_40Percent_Rebate,
	   a.Total_Cost_Full_Rebate*b.CPI_Ratio as Total_Cost_Full_Rebate,
	   a.Total_Cost_NoRebate*b.CPI_Ratio as Total_Cost_NoRebate,
	   a.Total_Value_40Percent_Rebate*b.CPI_Ratio as Total_Value_40Percent_Rebate,
	   a.Total_Value_Full_Rebate*b.CPI_Ratio as Total_Value_Full_Rebate,
	   a.Total_Value_NoRebate*b.CPI_Ratio as Total_Value_NoRebate,
	   a.HospiceFlag,

	   a.Top5_Prcnt_2014,
	   a.Top5_Prcnt_2015,
	   a.Top5_Prcnt_2016
into pdb_WalkandWin..LTV_Member_Month_092017_v2
from #results_2						as a
join pdb_WalkandWin..CPI_Adjustment			as b	on left(a.Year_Mo, 4) = b.Yr
-- 2,400,108


create unique clustered index ix_x on pdb_WalkandWin..LTV_Member_Month_092017(SavvyHICN, Year_Mo)


---- select * from pdb_WalkandWin..LTV_Member_Month_092017
