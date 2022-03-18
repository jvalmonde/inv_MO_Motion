-------------------------------------------------------------
--1) Get Enrollment Data based on UGAP and MMR Enrollment
-------------------------------------------------------------
--Get members in 10% sample and their UGAP enrollment data
-- drop table #members
select distinct a.SavvyHICN, b.SavvyID
into #members
from pdb_WalkandWin..CMS_MMR_Subset_20170727					as a
join MiniOV..SavvyID_to_SavvyHICN				as b	on a.SavvyHICN = b.SavvyHICN
-- 45,468

create unique index ix_hicn on #members(SavvyHICN)


--MAPD flags broken for 2017, use derived MAPD indicator from MMR instead
-- drop table #mapd
select ContractNumber, PlanBenefitPackageID, left(PaymentAdjustmentStartDate, 4) as Yr,
	   case when sum(TotalPartDPayment) > 0 then 1 else 0 end as MAPDFlag
into #mapd
from pdb_WalkandWin..CMS_MMR_Subset_20170727
group by ContractNumber, PlanBenefitPackageID, left(PaymentAdjustmentStartDate, 4)
-- 2,679

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
-- 2,484,200



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
			   a.TotalMAPaymentAmount, 
			   a.TotalPartDPayment, 
			   a.LowIncomeSubsidyCostSharingAmount, 
			   a.ReinsuranceSubsidyAmount,
			   a.HospiceFlag,
			   a.PaymentAdjustmentStartDate, a.PaymentAdjustmentEndDate, 
			   cast(left(replace(a.PaymentAdjustmentStartDate, '-', ''), 6) as int) as Start_Year_Mo,
			   cast(left(replace(a.PaymentAdjustmentEndDate, '-', ''), 6) as int) as End_Year_Mo
		from pdb_WalkandWin..CMS_MMR_Subset_20170727	as a
		join #members					as b	on a.SavvyHICN = b.SavvyHICN
		)				as a 
	join #year_mo		as b	on b.Year_Mo between a.Start_Year_Mo and a.End_Year_Mo
	where b.Year_Mo between 200601 and 201703
	) as a
group by a.SavvyHICN, a.YEAR_MO, a.ContractNumber, a.PlanBenefitPackageID
having cast(sum(Adjusted_MA_Amt) as money) > 0	--Has MA benefit (resolves retroactive reversals)
   and cast(sum(Adjusted_D_Amt) as money) > 0	--Has Part D benefit
order by 1, 2
-- 2,786,949



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
-- 2,444,506

create unique index ix_x on #enrollment(SavvyHICN, Year_Mo)


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



---------------------------------------------------------------
--3) Get Acquisition and Marketing Costs
---------------------------------------------------------------
/*
--summary of acquisition channel
-- drop table #channel
select a.SavvyHICN, b.Lifetime_ID,
       max(case when CHNL_DESC in('EASE - FMO', 'FMO') then 1 else 0 end) as Chnl_FMO,
	   max(case when CHNL_DESC in('EASE - ICA', 'ICA') then 1 else 0 end) as Chnl_ICA,
	   max(case when CHNL_DESC in('EASE - ISR', 'ISR') then 1 else 0 end) as Chnl_ISR,
	   max(case when CHNL_DESC in('EASE - Telesales', 'Phone') then 1 else 0 end) as Chnl_Phone,
	   max(case when CHNL_DESC in('Internet', 'Web') then 1 else 0 end) as Chnl_Web
into #channel
from(
	select SavvyHICN,
		   case when Mnth = 'Jan' then Yr+'01' 
				when Mnth = 'Feb' then Yr+'02' 
				when Mnth = 'Mar' then Yr+'03' 
				when Mnth = 'Apr' then Yr+'04' 
				when Mnth = 'May' then Yr+'05' 
				when Mnth = 'Jun' then Yr+'06' 
				when Mnth = 'Jul' then Yr+'07' 
				when Mnth = 'Aug' then Yr+'08' 
				when Mnth = 'Sep' then Yr+'09' 
				when Mnth = 'Oct' then Yr+'10' 
				when Mnth = 'Nov' then Yr+'11' 
				when Mnth = 'Dec' then Yr+'12' end as Year_Mo,
			CHNL_DESC
	from(
		select a.SavvyHICN,
				right(left(a.MEMBERSHIP_EFFECTIVE_DATE, 9), 4) as Yr,
				left(right(left(a.MEMBERSHIP_EFFECTIVE_DATE, 9), 7), 3) as Mnth,
				CHNL_DESC
		from pdb_WalkandWin..TK_MR2765_PDP_MA_Member_Clean	as a 
		join #members								as b	on a.SavvyHICN = b.SavvyHICN
		where a.CHNL_DESC <> 'missing'
		) as a
	) as a 
join(
	select SavvyHICN, Lifetime_ID, min(Year_Mo) as Start_Year_Mo, max(Year_Mo) as End_Year_Mo
	from #enrollment
	group by  SavvyHICN, Lifetime_ID
	) as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo between b.Start_Year_Mo and b.End_Year_Mo
group by a.SavvyHICN, b.Lifetime_ID
-- 23,933

--Acquisition Costs
-- drop table #acquisition_costs
select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, 
		case when b.Chnl_FMO = 1 or b.Chnl_ICA = 1 and a.RN in(1, 13, 25, 37, 49) then 400 --400 each year for 5 years
			when b.Chnl_ISR = 1 and a.RN = 1 then 1000
			when b.Chnl_Phone = 1 and a.RN = 1 then 150
			when b.Chnl_Web = 1 and a.RN = 1 then 50
			else null end as Acquisition_Cost
into #acquisition_costs
from(
	select SavvyHICN, Lifetime_ID, Year_Mo, left(Year_Mo, 4) as Yr, 
			row_number() over(partition by SavvyHICN, Lifetime_ID order by Year_Mo) as RN
	from #enrollment
	)			as a 
join #channel	as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
-- 959,927

--Marketing Costs
-- drop table #marketing_costs
select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, 
		case when RN = 1 and Yr between 2006 and 2011 then 479.32
			when RN = 1 and Yr = 2012 then 458.02
			when RN = 1 and Yr = 2013 then 392.41
			when RN = 1 and Yr = 2014 then 538.65
			when RN = 1 and Yr = 2015 then 484.41
			when RN = 1 and Yr = 2016 then 523.08 
			else null end as Marketing_Cost
into #marketing_costs
from(
	select SavvyHICN, Lifetime_ID, Year_Mo, left(Year_Mo, 4) as Yr, 
			row_number() over(partition by SavvyHICN, Lifetime_ID order by Year_Mo) as RN
	from #enrollment
	)				as a 
-- 2,444,506
*/

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
from pdb_WalkandWin..CMS_Plan_Benefits_CD_Premiums
group by Plan_Year, Contr_Nbr, PBP
-- 44,503





-------------------------------------------------------------
--6) Gather it all together into primary member-month table
-------------------------------------------------------------
-- drop table #results
select a.*, 
       a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0) as Total_Revenue,
	   (a.Total_Claims_Cost-a.Rx_Rebate_Amt)/*+Marketing_Cost+Acquisition_Cost*/ as Total_Cost,
	   (a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0))
		- ((a.Total_Claims_Cost-a.Rx_Rebate_Amt)/*+Marketing_Cost+Acquisition_Cost*/) as Total_Value
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
		   isnull(c.Net_Pd_Amt,0) Total_MA_Cost,
		   isnull(d.Net_Pd_Amt,0) as Total_D_Cost,
		   isnull(c.Net_Pd_Amt,0)+isnull(d.Net_Pd_Amt,0) as Total_Claims_Cost,

		   case when isnull(d.Net_Pd_Amt,0)-b.LICS_Amt-b.Reinsurance_Amt > 0
				then (isnull(d.Net_Pd_Amt,0)-b.LICS_Amt-b.Reinsurance_Amt)*0.4
				else 0 end as Rx_Rebate_Amt, --40% of plan paid if plan paid > 0, else 0
		   b.LICS_Amt,
		   b.Reinsurance_Amt,

		   --isnull(e.Acquisition_Cost,0) as Acquisition_Cost,
		   --isnull(f.Marketing_Cost,0) as Marketing_Cost,

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
	left join #rx_claims			as d	on a.SavvyHICN = d.SavvyHICN and a.Year_Mo = d.Year_Mo
	--left join #acquisition_costs	as e	on a.SavvyHICN = e.SavvyHICN and a.Year_Mo = e.Year_Mo
	--left join #marketing_costs		as f	on a.SavvyHICN = f.SavvyHICN and a.Year_Mo = f.Year_Mo
	left join #premiums				as g	on a.Contr_Nbr = g.Contr_Nbr and a.PBP = g.PBP
										   and left(a.Year_Mo, 4) = g.Plan_Year
	) as a
-- 2,444,506


--select count(*) from #mmr			--11,749,074
--select count(*) from #enrollment	--10,571,800
--select count(*) from #results		--10,391,028


-------------------------------------------------------------
--7) Adjust all dollars based on CPI
-------------------------------------------------------------
-- drop table pdb_WalkandWin..LTV_Member_Month
create table pdb_WalkandWin..LTV_Member_Month(
	[SavvyHICN] [int] NOT NULL,
	[Lifetime_ID] [int] NOT NULL,
	[Year_Mo] [int] NOT NULL,
	[Contr_Nbr] [char](5) NOT NULL,
	[PBP] [char](3) NULL,
	[Total_MA_Amt] [decimal](19, 4) NULL,
	[Total_D_Amt] [decimal](19, 4) NULL,
	[Total_CMS_Amt] [decimal](19, 4) NULL,
	
	[Total_MA_IP_Cost] [decimal](19, 4) NULL,
	[Total_MA_OP_Cost] [decimal](19, 4) NULL,
	[TotaL_MA_DR_Cost] [decimal](19, 4) NULL,
	[Total_MA_Cost] [decimal](19, 4) NULL,
	[Total_D_Cost] [decimal](19, 4) NULL,
	[Total_Claims_Cost] [decimal](19, 4) NULL,

	[Total_MA_OOP] [decimal](19, 4) NULL,
	[Total_D_OOP] [decimal](19, 4) NULL,
	[Total_OOP] [decimal](19, 4) NULL,

	[Rx_Rebate_Amt] [decimal](19, 4) NULL,
	[LICS_Amt] [decimal](19, 4) NULL,
	[Reinsurance_Amt] [decimal](19, 4) NULL,

	--[Acquisition_Cost] [decimal](19, 4) NULL,
	--[Marketing_Cost] [decimal](19, 4) NULL,
	[Premium_C_Amt] [decimal](19, 4) NULL,
	[Premium_D_Amt] [decimal](19, 4) NULL,
	[Total_Premium_Amt] [decimal](19, 4) NULL,

	[MA_RAF] [decimal](19, 4) NULL,
	[D_RAF] [decimal](19, 4) NULL,
	[Year_Mo_Rank] [int] NULL,
	[Total_Revenue] [decimal](19, 4) NULL,
	[Total_Cost] [decimal](19, 4) NULL,
	[Total_Value] [decimal](19, 4) NULL,
	[HospiceFlag] [varchar](1) NULL)


insert into pdb_WalkandWin..LTV_Member_Month
select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, a.Contr_Nbr, a.PBP,
	   a.Total_MA_Amt*b.CPI_Ratio as Total_MA_Amt,
	   a.Total_D_Amt*b.CPI_Ratio as Total_D_Amt,
	   a.Total_CMS_Amt*b.CPI_Ratio as Total_CMS_Amt,
	   
	   a.Total_MA_IP_Cost*b.CPI_Ratio as Total_MA_IP_Cost,
	   a.Total_MA_OP_Cost*b.CPI_Ratio as Total_MA_OP_Cost,
	   a.Total_MA_DR_Cost*b.CPI_Ratio as Total_MA_DR_Cost, 
	   a.Total_MA_Cost*b.CPI_Ratio as Total_MA_Cost,
	   a.Total_D_Cost*b.CPI_Ratio as Total_D_Cost,
	   a.Total_Claims_Cost*b.CPI_Ratio as Total_Claims_Cost,

	   a.Total_MA_OOP*b.CPI_Ratio as Total_MA_OOP,
	   a.Total_D_OOP*b.CPI_Ratio as Total_D_OOP,
	   a.Total_OOP*b.CPI_Ratio as Total_OOP,

	   a.Rx_Rebate_Amt*b.CPI_Ratio as Rx_Rebate_Amt,
	   a.LICS_Amt*b.CPI_Ratio as LICS_Amt,
	   a.Reinsurance_Amt*b.CPI_Ratio as Reinsurance_Amt,

	   --a.Acquisition_Cost*b.CPI_Ratio as Acquisition_Cost,
	   --a.Marketing_Cost*b.CPI_Ratio as Marketing_Cost,
	   a.Premium_C_Amt*b.CPI_Ratio as Premium_C_Amt, 
	   a.Premium_D_Amt*b.CPI_Ratio as Premium_D_Amt,
	   a.Total_Premium_Amt*b.CPI_Ratio as TotaL_Premium_Amt,

	   a.MA_RAF,
	   a.D_RAF,
	   a.Year_Mo_Rank,
	   a.Total_Revenue*b.CPI_Ratio as Total_Revenue,
	   a.Total_Cost*b.CPI_Ratio as Total_Cost,
	   a.Total_Value*b.CPI_Ratio as Total_Value,
	   a.HospiceFlag
from #results						as a
join pdb_WalkandWin..CPI_Adjustment			as b	on left(a.Year_Mo, 4) = b.Yr
-- 2,400,108


create unique index ix_x on pdb_WalkandWin..LTV_Member_Month(SavvyHICN, Year_Mo)


select * from pdb_WalkandWin..LTV_Member_Month

