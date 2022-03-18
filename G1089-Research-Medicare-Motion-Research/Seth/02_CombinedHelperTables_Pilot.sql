USE pdb_WalkandWin /*...on DBSEP3832*/
GO

/*
Create tables re-created as temp tables in several of the WnW scripts.
*/

/*
--Only run this once:
IF object_id('Dim_Year_Mo','U') IS NOT NULL
	DROP TABLE Dim_Year_Mo;
select 
	Year_Mo_Rnk			=	ROW_NUMBER() over (order by YEAR_MO),
	Year_Mo				=	convert(int, YEAR_MO),
	YearNbr				=	convert(int, YEAR_NBR), 
	StartDate			=	convert(date, min(FULL_DT)), 
	EndDate				=	convert(date, max(FULL_DT)), 
	StartDtSysId		=	min(DT_SYS_ID), 
	EndDtSysId			=	max(DT_SYS_ID),
	indCompleteClaims	=	case when YEAR_MO between 200701 and 201709 then 1 else 0 end
into Dim_Year_Mo
from MiniOV.dbo.Dim_Date
where YEAR_NBR between 2007 and 2020
group by YEAR_NBR, YEAR_MO
order by YEAR_MO
go
create clustered index cixYear_Mo on Dim_Year_Mo(Year_Mo)
create index ix_StartEndDate on Dim_Year_Mo(StartDate, EndDate) include(YearNbr, Year_Mo_Rnk, StartDtSysId, EndDtSysId) 
create index ix_rnk on Dim_Year_Mo(Year_Mo_Rnk) include(YearNbr, StartDate, EndDate, StartDtSysId, EndDtSysId) 
go
*/


--MAPD flags broken for 2017, use derived MAPD indicator from MMR instead
IF object_id('wkg_mapd','U') IS NOT NULL
	DROP TABLE wkg_mapd;
select 
	ContractNumber, 
	PlanBenefitPackageID, 
	ContrPBP				=	ContractNumber + '-' + PlanBenefitPackageID, 
	Contr_Yr				=	YEAR(PaymentAdjustmentStartDate),
	MAPDFlag				=	case when sum(TotalPartDPayment) > 0 then 1 else 0 end
into wkg_mapd
from CmsMMR_Subset_20180313
group by 
	ContractNumber, 
	PlanBenefitPackageID, 
	YEAR(PaymentAdjustmentStartDate)
go
create clustered index cixContrPBP on wkg_mapd(ContrPBP)
go

--Get member-month level enrollment data for COSMOS MAPD
IF object_id('wkg_ugap_enrollment','U') IS NOT NULL
	DROP TABLE wkg_ugap_enrollment;
select distinct d.SavvyID_OV, d.SavvyHICN, b.Year_Mo, c.Contr_Nbr, c.PBP
into wkg_ugap_enrollment
from 
	MiniOV.dbo.Fact_MemberContract			a 
	join Dim_Year_Mo						b	on	a.Year_Mo		=	b.Year_Mo
	join MiniOV.dbo.Dim_Contract			c	on	a.Contr_Sys_Id	=	c.Contr_Sys_ID
	join CombinedMember_sg					d	on	a.SavvyID		=	d.SavvyID_OV
	join wkg_mapd							e	on	c.Contr_Nbr		=	e.ContractNumber 
												and c.PBP			=	e.PlanBenefitPackageID 
												and c.Contr_Yr		=	e.Contr_Yr	
where 
	--a.Year_Mo				>=	200701	--was (between 200601 and 201703). Not sure how far the data has been updated, but that shouldn't matter
	--									--we probably should exclude 2006, though, since we don't have 2006 Rx claims...
	b.indCompleteClaims		=	1
	and a.Src_Sys_Cd		=	'CO'		--COSMOS only
	and e.MAPDFlag			=	1			--MAPD only
--	and c.MAPDFlag			=	'Y'			--MAPD only  BROKEN!
--	and c.PBP				not like '8%'	--exclude group retiree contracts
go
create clustered index cixSavvyHICN_Year_Mo on wkg_ugap_enrollment(SavvyHICN, Year_Mo)
go

--Get MMR enrollment and revenue data, adjusting for retrospecitve adjustments
--by attributing dollars to service month (not payment month).
IF object_id('wkg_mmr_enrollment_step1','U') IS NOT NULL
	DROP TABLE wkg_mmr_enrollment_step1;
select a.SavvyHICN, b.SavvyID_OV, a.ContractNumber, a.PlanBenefitPackageID,
		a.PartDRAFactor, a.RiskAdjusterFactorA, 
		a.TotalMAPaymentAmount, 
		a.TotalPartDPayment, 
		a.LowIncomeSubsidyCostSharingAmount, 
		a.ReinsuranceSubsidyAmount,
		a.HospiceFlag,
		a.PaymentAdjustmentStartDate, a.PaymentAdjustmentEndDate, 
		--100 * YEAR(a.PaymentAdjustmentStartDate) + MONTH(a.PaymentAdjustmentStartDate) as Start_Year_Mo,
		--100 * YEAR(a.PaymentAdjustmentEndDate) + MONTH(a.PaymentAdjustmentEndDate) as End_Year_Mo,
		st.Year_Mo_Rnk as StartYear_Mo_Rnk,
		ed.Year_Mo_Rnk as EndYear_Mo_Rnk
into wkg_mmr_enrollment_step1
from CmsMMR_Subset_20180313				a
join CombinedMember_sg					b	on a.SavvyHICN = b.SavvyHICN --that's what the subset is...
join Dim_Year_Mo						st	on a.PaymentAdjustmentStartDate = st.StartDate --st.Year_Mo =  100 * YEAR(a.PaymentAdjustmentStartDate) + MONTH(a.PaymentAdjustmentStartDate)
join Dim_Year_Mo						ed	on a.PaymentAdjustmentEndDate = ed.EndDate	--ed.Year_Mo =  100 * YEAR(a.PaymentAdjustmentEndDate) + MONTH(a.PaymentAdjustmentEndDate)
--they're all month start/end dates...
--join Dim_Year_Mo						st	on a.PaymentAdjustmentStartDate between st.StartDate and st.EndDate	--st.Year_Mo =  100 * YEAR(a.PaymentAdjustmentStartDate) + MONTH(a.PaymentAdjustmentStartDate)
--join Dim_Year_Mo						ed	on a.PaymentAdjustmentEndDate between ed.StartDate and ed.EndDate	--ed.Year_Mo =  100 * YEAR(a.PaymentAdjustmentEndDate) + MONTH(a.PaymentAdjustmentEndDate)
go
create clustered index cixSavvyHICN on wkg_mmr_enrollment_step1(SavvyHICN)
go

IF object_id('wkg_mmr_enrollment','U') IS NOT NULL
	DROP TABLE wkg_mmr_enrollment;
select a.SavvyHICN, a.SavvyID_OV, a.Year_Mo, a.Year_Mo_Rnk, a.indCompleteClaims, a.ContractNumber, a.PlanBenefitPackageID,
	   max(a.PartDRAFactor) as D_RAF, 
	   max(a.RiskAdjusterFactorA) as MA_RAF,
	   cast(sum(Adjusted_MA_Amt) as money) as Total_MA_Amt, 
	   cast(sum(Adjusted_D_Amt) as money) as Total_D_Amt, 
	   cast(sum(LowIncomeSubsidyCostSharingAmount) as money) as LICS_Amt,
	   cast(sum(ReinsuranceSubsidyAmount) as money) as Reinsurance_Amt,
	   max(a.HospiceFlag) as HospiceFlag
into wkg_mmr_enrollment
from(
	select a.SavvyHICN, a.SavvyID_OV, b.Year_Mo, b.Year_Mo_Rnk, b.indCompleteClaims, a.ContractNumber, a.PlanBenefitPackageID,
		   a.PartDRAFactor, a.RiskAdjusterFactorA, 
		   a.LowIncomeSubsidyCostSharingAmount, 
		   a.ReinsuranceSubsidyAmount,
		   a.HospiceFlag,
		   --a.TotalMAPaymentAmount/(a.End_Year_Mo-a.Start_Year_Mo+1) as Adjusted_MA_Amt, --distribute multi-month costs 
		   --a.TotalPartDPayment/(a.End_Year_Mo-a.Start_Year_Mo+1) as Adjusted_D_Amt,
		   a.TotalMAPaymentAmount/(a.EndYear_Mo_Rnk - a.StartYear_Mo_Rnk + 1) as Adjusted_MA_Amt, --distribute multi-month costs, adjusted to account for periods that span multiple years
		   a.TotalPartDPayment/(a.EndYear_Mo_Rnk - a.StartYear_Mo_Rnk + 1) as Adjusted_D_Amt
	from
		wkg_mmr_enrollment_step1	as a 
		join Dim_Year_Mo			as b	on b.Year_Mo_Rnk between a.StartYear_Mo_Rnk and a.EndYear_Mo_Rnk
	--where b.indCompleteClaims = 1			--want to include mmr enrollment from after our "complete claims" period
	) as a
group by a.SavvyHICN, a.SavvyID_OV, a.Year_Mo, a.Year_Mo_Rnk, a.indCompleteClaims, a.ContractNumber, a.PlanBenefitPackageID
having cast(sum(Adjusted_MA_Amt) as money) > 0	--Has MA benefit (resolves retroactive reversals)
   and cast(sum(Adjusted_D_Amt) as money) > 0	--Has Part D benefit
order by 1, 2
go
create clustered index cixSavvyHICN_Year_Mo on wkg_mmr_enrollment(SavvyHICN, Year_Mo)
go

--Summarize into master enrollment table
--Requires both UGAP + MMR agreement (98% of MM)
IF object_id('wkg_enrollment','U') IS NOT NULL
	DROP TABLE wkg_enrollment;
select 
	a.SavvyHICN,
	a.SavvyID_OV, 
	a.Year_Mo, 
	a.Contr_Nbr, 
	a.PBP, 
	ContrPBP	=	a.Contr_Nbr + '-' + a.PBP,
	--(left(a.Year_Mo, 4)-2006)*12 + right(a.Year_Mo, 2) as Year_Mo_Rank,
	b.Year_Mo_Rnk,
	0 as Lifetime_ID --Will be updated later
into wkg_enrollment
from wkg_ugap_enrollment					a
join wkg_mmr_enrollment						b	on	a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
												--will it cause too many problems to leave this out? 
												--leave it in like before, and don't restrict MMR to active records like before...
												and a.Contr_Nbr = b.ContractNumber and a.PBP = b.PlanBenefitPackageID 
go

insert into wkg_enrollment (SavvyHICN, SavvyID_OV, Year_Mo, Contr_Nbr, PBP, ContrPBP, Year_Mo_Rnk, Lifetime_ID)
--verified that there are no duplicate member/months
select a.SavvyHICN,
	a.SavvyID_OV, 
	a.Year_Mo, 
	a.ContractNumber, 
	a.PlanBenefitPackageID, 
	a.ContractNumber + '-' + a.PlanBenefitPackageID,
	--(left(a.Year_Mo, 4)-2006)*12 + right(a.Year_Mo, 2) as Year_Mo_Rank,
	a.Year_Mo_Rnk,
	0  --Will be updated later
from wkg_mmr_enrollment						a
--join Dim_Year_Mo							c	on	a.Year_Mo	=	c.Year_Mo
where indCompleteClaims = 0
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_enrollment(SavvyHICN, Year_Mo)
go

-----------------------------------------------------------------
----2) Add lifetime IDs based on blocks of continuous enrollment
-----------------------------------------------------------------
--Start by identifying "new enollment" months (i.e. not enrolled in the previous month)
IF object_id('wkg_new_enrolls','U') IS NOT NULL
	DROP TABLE wkg_new_enrolls;
select a.SavvyHICN, a.SavvyID_OV, a.Year_Mo, a.Year_Mo_Rnk, row_number() over(partition by a.SavvyHICN order by a.Year_Mo) as RN
into wkg_new_enrolls
from wkg_enrollment				a 
left join wkg_enrollment		b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo_Rnk = b.Year_Mo_Rnk + 1
where b.SavvyHICN is null --No previous month = new enroll
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_new_enrolls(SavvyHICN, Year_Mo)
go

--Identify start and end dates for the lifetime (start = new enroll month, end = next enrollment month - 1)
IF object_id('wkg_lifetimes','U') IS NOT NULL
	DROP TABLE wkg_lifetimes;
select 
	a.SavvyHICN, a.SavvyID_OV, 
	a.Year_Mo as StartYear_Mo, 
	--isnull(b.Year_Mo - 1, '999999') as EndYear_Mo,	--doesn't handle end of year transitions...there is no '201600', for example...
	isnull(c.Year_Mo, '999999') as EndYear_Mo, 
	a.RN as Lifetime_ID
into wkg_lifetimes
from wkg_new_enrolls			a 
left join wkg_new_enrolls		b	on	a.SavvyHICN = b.SavvyHICN and a.RN + 1 = b.RN
left join Dim_Year_Mo						c	on	c.Year_Mo_Rnk = b.Year_Mo_Rnk - 1
go
create clustered index cix_SavvyHICN_StartYear_Mo on wkg_lifetimes(SavvyHICN, StartYear_Mo)
go

--select * from wkg_enrollment where SavvyHICN = 3197
--select * from wkg_new_enrolls where SavvyHICN = 3197
--select * from wkg_lifetimes where SavvyHICN = 3197

--Update the Lifetime_ID
update a
set a.Lifetime_ID = b.Lifetime_ID  
from wkg_enrollment		a 
join wkg_lifetimes			b	on a.SavvyHICN = b.SavvyHICN 
where a.Year_Mo between b.StartYear_Mo and b.EndYear_Mo


---------------------------------------------------------------
----4) Get claims costs
---------------------------------------------------------------
--Medical claims
IF object_id('wkg_Fact_Claims','U') IS NOT NULL
	DROP TABLE wkg_Fact_Claims;
select
	a.SavvyHICN,
	c.SavvyID,
	c.Admit_Cnt,
	c.Day_Cnt,
	c.Dt_Sys_ID,
	c.Allw_Amt, c.Net_Pd_Amt, c.OOP_Amt, c.Srvc_Typ_Sys_Id,
	d.YEAR_MO,
	e.HCE_SRVC_TYP_DESC, 
	g.AHRQ_PROC_DTL_CATGY_DESC, 
	f.Srvc_Typ_Cd
into wkg_Fact_Claims
from 
	CombinedMember_sg									a
	join MiniOV.dbo.Fact_Claims							c	on	a.SavvyId_OV = c.SavvyId	
	join MiniOV.dbo.Dim_Date							d	on	c.Dt_Sys_Id = d.DT_SYS_ID 
	join MiniOV.dbo.Dim_HP_Service_Type_Code			e	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = e.HLTH_PLN_SRVC_TYP_CD_SYS_ID
	join MiniOV.dbo.Dim_Service_Type					f	on	c.Srvc_Typ_Sys_Id = f.Srvc_Typ_Sys_Id
	join MiniOV.dbo.Dim_Procedure_Code					g	on	c.Proc_Cd_Sys_Id = g.PROC_CD_SYS_ID
	join Dim_Year_Mo									h	on	d.YEAR_MO = h.Year_Mo 
															and h.indCompleteClaims = 1
where
	c.Srvc_Typ_Sys_Id < 4 --since Rx is included now...
	--and a.SavvyHICN < 10000
go
create clustered index cixSavvyHICN on wkg_Fact_Claims(SavvyHICN)
go

IF object_id('wkg_Fact_Claims_Rx','U') IS NOT NULL
	DROP TABLE wkg_Fact_Claims_Rx;
select
	b.SavvyHICN, 
	c.YEAR_MO, 
	Allw_Amt				=	b.Allowed, 
	Net_Pd_Amt				=	b.Total_Amount_Billed,		--almost certainly wrong, but it's what we used before
	OOP_Amt					=	b.Patient_Pay_Amount		--almost certainly wrong, but it's what we used before
into wkg_Fact_Claims_Rx
from
	CombinedMember_sg					a
	join MiniPAPI.dbo.Fact_Claims		b	on	a.SavvyHICN = b.SavvyHICN
	join MiniPAPI.dbo.Dim_Date			c	on	b.Date_Of_Service_DtSysId = c.DT_SYS_ID
	join Dim_Year_Mo					h	on	c.YEAR_MO = h.Year_Mo 
											and h.indCompleteClaims = 1
where 
	b.Claim_Status = 'P'
	and c.YEAR_MO <= 201703
		
union all

select 
	a.SavvyHICN, 
	c.YEAR_MO,
	b.Allw_Amt,
	b.Net_Pd_Amt,
	b.OOP_Amt
from 
	CombinedMember_sg					a
	join MiniOV.dbo.Fact_Claims			b	on	a.SavvyID_OV	=	b.SavvyID
	join MiniOV.dbo.Dim_Date			c	on	b.Dt_Sys_Id		=	c.DT_SYS_ID
	join Dim_Year_Mo					h	on	c.YEAR_MO = h.Year_Mo 
											and h.indCompleteClaims = 1
where
	c.YEAR_MO >= 201704
	and b.Srvc_Typ_Sys_Id = 4 
go
create clustered index cixSavvyHICN on wkg_Fact_Claims_Rx(SavvyHICN)
go			


IF object_id('wkg_med_claims','U') IS NOT NULL
	DROP TABLE wkg_med_claims;
select 
	d.SavvyHICN, d.SavvyID_OV, d.Year_Mo, 
	ISNULL(sum(a.Allw_Amt), 0) as Allw_Amt,
	ISNULL(sum(a.Net_Pd_Amt), 0) as Net_Pd_Amt, 
	ISNULL(sum(a.OOP_Amt), 0) as OOP_Amt,
	ISNULL(sum(case when a.Srvc_Typ_Sys_Id = 1 then a.Net_Pd_Amt else 0 end), 0) as IP_Amt,
	ISNULL(sum(case when a.Srvc_Typ_Sys_Id = 2 then a.Net_Pd_Amt else 0 end), 0) as OP_Amt,
	ISNULL(sum(case when a.Srvc_Typ_Sys_Id = 3 then a.Net_Pd_Amt else 0 end), 0) as DR_Amt
into wkg_med_claims
from wkg_enrollment				d
left join wkg_Fact_Claims		a	on	d.SavvyHICN		=	a.SavvyHICN
									and d.Year_Mo		=	a.YEAR_MO
group by d.SavvyHICN, d.SavvyID_OV, d.Year_Mo
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_med_claims(SavvyHICN, Year_Mo)
go

IF object_id('wkg_IP_days','U') IS NOT NULL
	DROP TABLE wkg_IP_days;
select distinct d.SavvyHICN
	, d.SavvyID_OV
	, IP_Dt_Sys_Id		=	ip.DT_SYS_ID
into wkg_IP_days
from wkg_Fact_Claims			a
join wkg_enrollment				d	on a.SavvyHICN = d.SavvyHICN and a.YEAR_MO = d.Year_Mo
join MiniOV.dbo.Dim_Date		ip	on ip.DT_SYS_ID between a.Dt_Sys_Id and a.Dt_Sys_Id + a.Day_Cnt
where 
	a.Admit_Cnt = 1 
go
create clustered index cixSavvyHICN_IP_Dt_Sys_Id on wkg_IP_days(SavvyHICN, IP_Dt_Sys_Id)
go

IF object_id('wkg_med_claims2','U') IS NOT NULL
	DROP TABLE wkg_med_claims2;
;WITH
	cteClaims as
		(select
			a.SavvyHICN,
			a.YEAR_MO,
			Net_Pd_Amt,
			DerivedSrvcTyp						=	case 
														when b.SavvyHICN is not null and a.Srvc_Typ_Cd <> 'IP'	then 'IP'  
														when a.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then 'ER'
														when a.AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'	then 'DME'	
														else a.Srvc_Typ_Cd	
													end
		from 
			wkg_Fact_Claims								a
			left join wkg_IP_days						b	on	a.SavvyHICN = b.SavvyHICN and a.Dt_Sys_Id = b.IP_Dt_Sys_Id	
		)
select a.SavvyHICN
	, a.SavvyID_OV		
	, a.Year_Mo		
	, Derived_IP			= isnull(sum(case when DerivedSrvcTyp = 'IP' 	then Net_Pd_Amt else 0 end),0)
	, Derived_OP			= isnull(sum(case when DerivedSrvcTyp = 'OP' 	then Net_Pd_Amt else 0 end),0)
	, Derived_DR			= isnull(sum(case when DerivedSrvcTyp = 'DR' 	then Net_Pd_Amt else 0 end),0)	
	, Derived_ER			= isnull(sum(case when DerivedSrvcTyp = 'ER' 	then Net_Pd_Amt else 0 end),0)
	, Derived_DME			= isnull(sum(case when DerivedSrvcTyp = 'DME'	then Net_Pd_Amt else 0 end),0)
into wkg_med_claims2
from wkg_enrollment					a					
left join cteClaims									c	on	a.SavvyHICN		=	c.SavvyHICN
														and a.Year_Mo		=	c.YEAR_MO
group by a.SavvyHICN, a.SavvyID_OV, a.Year_Mo
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_med_claims2(SavvyHICN, Year_Mo)
go

---- select * from #med_claims_2

--Pharmacy claims
IF object_id('wkg_rx_claims','U') IS NOT NULL
	DROP TABLE wkg_rx_claims;
select a.SavvyHICN, a.Year_Mo, 
		ISNULL(sum(b.Allw_Amt), 0) as Allw_Amt,
		ISNULL(sum(b.Net_Pd_Amt), 0) as Net_Pd_Amt, 
		ISNULL(sum(b.OOP_Amt), 0) as OOP_Amt
		--sum(a.Covered_D_Plan_Paid_Amount) as Covered_D_Plan_Paid_Amount
into wkg_rx_claims
from 
	wkg_enrollment						a
	left join wkg_Fact_Claims_Rx		b	on	a.SavvyHICN		=	b.SavvyHICN
											and a.Year_Mo		=	b.YEAR_MO
group by a.SavvyHICN, a.Year_Mo
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_rx_claims(SavvyHICN, Year_Mo)
go

-------------------------------------------------------------
--5) Get member-paid premium amounts
-------------------------------------------------------------
--average accross counties, typically very little variation
--this data may come from https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovGenIn/index.html, for example. Currently updated through 2017.
-- drop table #premiums
IF object_id('wkg_premiums','U') IS NOT NULL
	DROP TABLE wkg_premiums;
select Plan_Year, Contr_Nbr, PBP,
       avg(Premium_C) as Premium_C,
	   avg(Premium_D) as Premium_D
into wkg_premiums
from CMS_Plan_Benefits_CD_Premiums
group by Plan_Year, Contr_Nbr, PBP
go
create clustered index cix_Contr_Nbr_PBP on wkg_premiums(Contr_Nbr, PBP)
go
---- 44,503

-------------------------------------------------------------
--6) Gather it all together into primary member-month table
-------------------------------------------------------------
-- drop table #results
IF object_id('wkg_results','U') IS NOT NULL
	DROP TABLE wkg_results;
select a.*,
	   a.Year_Mo / 100 as Yr, 

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
into wkg_results
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
		   a.Year_Mo_Rnk
	from wkg_enrollment				as a 
	join wkg_mmr_enrollment			as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
															and a.Contr_Nbr = b.ContractNumber and a.PBP = b.PlanBenefitPackageID
	left join wkg_med_claims			as c	on a.SavvyHICN = c.SavvyHICN and a.Year_Mo = c.Year_Mo
	left join wkg_med_claims2			as c2	on a.SavvyHICN = c2.SavvyHICN and a.Year_Mo = c2.Year_Mo
	left join wkg_rx_claims			as d	on a.SavvyHICN = d.SavvyHICN and a.Year_Mo = d.Year_Mo
	left join wkg_premiums				as g	on a.Contr_Nbr = g.Contr_Nbr and a.PBP = g.PBP
															and a.Year_Mo / 100 = g.Plan_Year
	) as a
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_results(SavvyHICN, Year_Mo)
go
-- 2,444,506

IF object_id('wkg_Plan_Info','U') IS NOT NULL
	DROP TABLE wkg_Plan_Info;
select distinct 
	a.SavvyHICN
	,a.Year_Mo
	,d.LegacyOrganization
	,d.PBPDescription
	,d.Contr_Desc
	,d.ProductCategory
	,d.ContractType
into wkg_Plan_Info
from wkg_results as a
join MiniOV.dbo.SavvyID_to_SavvyHICN	as b on a.SavvyHICN = b.SavvyHICN
join MiniOV.dbo.Fact_MemberContract		as c on b.SavvyID = c.SavvyID and a.Year_Mo = c.Year_Mo
join MiniOV.dbo.Dim_Contract			as d on c.Contr_Sys_Id = d.Contr_Sys_ID and a.Contr_Nbr = d.Contr_Nbr and a.PBP = d.PBP
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_Plan_Info(SavvyHICN, Year_Mo)
go

IF object_id('wkg_Total_Per_Member_Cost','U') IS NOT NULL
	DROP TABLE wkg_Total_Per_Member_Cost;
select a.SavvyHICN, a.Yr, sum(Total_Claims_Cost) as Total_Year_Cost
into wkg_Total_Per_Member_Cost
from wkg_results 				a
where a.Yr in (2014,2015,2016,2017)
group by a.SavvyHICN, a.Yr, a.Yr
go
create clustered index cixSavvyHICN_Yr on wkg_Total_Per_Member_Cost(SavvyHICN, Yr)
go

/*************************** Can keep combined up to here. ***************************/ 
--Now, separate versions for 2016Pilot and 2017...

------ OUTLIER FLAGGING
--IF object_id('wkg_Grand_Total','U') IS NOT NULL
--	DROP TABLE wkg_Grand_Total;
--select 
--	a.Yr, sum(Total_Claims_Cost) as Grand_Total
--into wkg_Grand_Total
--from wkg_results				a		
--where a.Yr in (2014,2015,2016,2017)
--group by a.Yr
--go
--create clustered index cixYR on wkg_Grand_Total(Yr)
--go

--IF object_id('wkg_Cost_Outlier','U') IS NOT NULL
--	DROP TABLE wkg_Cost_Outlier;
--select 
--	a.SavvyHICN
--	,a.Yr
--	,a.Total_Year_Cost
--	,Grand_Total					=	max(b.Grand_Total)
--	,Moving_Total					=	sum(a.Total_Year_Cost) over (partition by a.yr 
--																	order by sum(a.Total_Year_Cost) desc rows unbounded preceding) 
--	,Percentage_of_Grand_Total		=	(sum(a.Total_Year_Cost)over(partition by a.yr 
--																	order by sum(a.Total_Year_Cost) desc rows unbounded preceding) / max(b.Grand_Total)) * 100
--	,Outlier_Flag					=	case when (sum(a.Total_Year_Cost)over(partition by a.yr 
--																			order by sum(a.Total_Year_Cost) desc rows unbounded preceding) / max(b.Grand_Total)) * 100 <= 5 
--											then 1 
--											else 0 
--										end
--into wkg_Cost_Outlier
--from wkg_Total_Per_Member_Cost		as a
--join wkg_Grand_Total				as b on a.Yr = b.Yr 
--group by 
--	a.SavvyHICN
--	,a.Yr
--	,a.Total_Year_Cost
--go
--create clustered index cixSavvyHICN on wkg_Cost_Outlier(SavvyHICN)
--go

--IF object_id('wkg_results2','U') IS NOT NULL
--	DROP TABLE wkg_results2;
--select a.*
--,c.LegacyOrganization
--,c.PBPDescription
--,c.Contr_Desc
--,c.ProductCategory
--,c.ContractType
--,CASE WHEN b.yr = 2014 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2014
--,CASE WHEN b.yr = 2015 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2015
--,CASE WHEN b.yr = 2016 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2016
--,CASE WHEN b.yr = 2017 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2017
--into wkg_results2 
--from wkg_results as a
--left join wkg_Cost_Outlier as b on a.SavvyHICN = b.SavvyHICN and a.Yr = b.Yr
--left join wkg_Plan_Info as c on a.SavvyHICN = c.SavvyHICN and a.Year_Mo = c.Year_Mo
--go
--create clustered index cix_SavvyHICN_Year_Mo on wkg_results2(SavvyHICN, Year_Mo)
--go


-------------------------------------------------------------
--7) Adjust all dollars based on CPI
-------------------------------------------------------------
--use https://www.bls.gov/regions/midwest/data/consumerpriceindexhistorical_us_table.pdf to update CPI_Adjustment
--2017 figure seems to be from April, others figures are from Yearly Average
/*
--drop table CPI_Adjustment_sg2016_Pilot
select --*, 195.3*1.252043, 244.524 / CPI , 245.120 / CPI,
	Yr, 
	CPI = case when Yr = 2017 then 245.120 else CPI end,
	CPI_Ratio = 245.120/case when Yr = 2017 then 245.120 else CPI end
into CPI_Adjustment_sg2016_Pilot
from CPI_Adjustment a 
go
create clustered index cixYr on CPI_Adjustment_sg2016_Pilot(Yr)
go
*/

---- drop table pdb_WalkandWin..LTV_Member_Month_2016_Pilot
--select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, a.Contr_Nbr, a.PBP,
--	   a.LegacyOrganization,
--	   a.PBPDescription,
--	   a.Contr_Desc,
--	   a.ProductCategory,
--	   a.ContractType,
--	   a.Total_MA_Amt*b.CPI_Ratio as Total_MA_Amt,
--	   a.Total_D_Amt*b.CPI_Ratio as Total_D_Amt,
--	   a.Total_CMS_Amt*b.CPI_Ratio as Total_CMS_Amt,
	   
--	   a.Total_MA_IP_Cost*b.CPI_Ratio as Total_MA_IP_Cost,
--	   a.Total_MA_OP_Cost*b.CPI_Ratio as Total_MA_OP_Cost,
--	   a.Total_MA_DR_Cost*b.CPI_Ratio as Total_MA_DR_Cost, 
--	   a.Total_MA_Derived_IP_Cost * b.CPI_Ratio as Total_MA_Derived_IP_Cost,
--	   a.Total_MA_Derived_OP_Cost * b.CPI_Ratio as Total_MA_Derived_OP_Cost,
--	   a.Total_MA_Derived_DR_Cost * b.CPI_Ratio as Total_MA_Derived_DR_Cost,
--	   a.Total_MA_Derived_ER_Cost * b.CPI_Ratio as Total_MA_Derived_ER_Cost,
--	   a.Total_MA_Derived_DME_Cost * b.CPI_Ratio as Total_MA_Derived_DME_Cost,
--	   a.Total_MA_Cost*b.CPI_Ratio as Total_MA_Cost,
--	   a.Total_D_Cost*b.CPI_Ratio as Total_D_Cost,
--	   a.Total_Claims_Cost*b.CPI_Ratio as Total_Claims_Cost,

--	   a.Total_MA_OOP*b.CPI_Ratio as Total_MA_OOP,
--	   a.Total_D_OOP*b.CPI_Ratio as Total_D_OOP,
--	   a.Total_OOP*b.CPI_Ratio as Total_OOP,
	   
--	   a.Rx_Rebate_Amt_Full*b.CPI_Ratio as Rx_Rebate_Amt_Full,
--	   a.Rx_Rebate_Amt_40Percent *b.CPI_Ratio as Rx_Rebate_Amt_40Percent,
--	   a.LICS_Amt*b.CPI_Ratio as LICS_Amt,
--	   a.Reinsurance_Amt*b.CPI_Ratio as Reinsurance_Amt,
	   
--	   a.Premium_C_Amt*b.CPI_Ratio as Premium_C_Amt, 
--	   a.Premium_D_Amt*b.CPI_Ratio as Premium_D_Amt,
--	   a.Total_Premium_Amt*b.CPI_Ratio as TotaL_Premium_Amt,

--	   a.MA_RAF,
--	   a.D_RAF,
--	   a.Year_Mo_Rank,
--	   a.Total_Revenue*b.CPI_Ratio as Total_Revenue,
--	   a.Total_Cost_40Percent_Rebate*b.CPI_Ratio as Total_Cost_40Percent_Rebate,
--	   a.Total_Cost_Full_Rebate*b.CPI_Ratio as Total_Cost_Full_Rebate,
--	   a.Total_Cost_NoRebate*b.CPI_Ratio as Total_Cost_NoRebate,
--	   a.Total_Value_40Percent_Rebate*b.CPI_Ratio as Total_Value_40Percent_Rebate,
--	   a.Total_Value_Full_Rebate*b.CPI_Ratio as Total_Value_Full_Rebate,
--	   a.Total_Value_NoRebate*b.CPI_Ratio as Total_Value_NoRebate,
--	   a.HospiceFlag,

--	   a.Top5_Prcnt_2014,
--	   a.Top5_Prcnt_2015,
--	   a.Top5_Prcnt_2016
--into LTV_Member_Month_2016_Pilot_sg2016_Pilot
--from #results_2						as a
--join CPI_Adjustment_sg2016_Pilot			as b	on left(a.Year_Mo, 4) = b.Yr
---- 2,400,108


--create unique clustered index ix_x on LTV_Member_Month_2016_Pilot_sg2016_Pilot(SavvyHICN, Year_Mo)


------ select * from pdb_WalkandWin..LTV_Member_Month_2016_Pilot
/* 
--run this on DBSEP3858.pdb_RenewMotion, then copy the data into DBSEP0230.pdb_MMR
--On 3858
use pdb_RenewMotion
go
IF object_id('OVMemberMAPD_201711','U') IS NOT NULL
	DROP TABLE OVMemberMAPD_201711;
select a.SavvyHICN, a.HICN, b.SavvyID
into OVMemberMAPD_201711
from 
	MiniOV_PHI.dbo.Lookup_HICN a
	join MiniOV.dbo.SavvyID_to_SavvyHICN b on a.SavvyHICN = b.SavvyHICN
	join MiniOV.dbo.Dim_Member c on b.SavvyID = c.SavvyID
where
	c.MAPDFlag = 1 --and c.SavvyID % 100000 = 123

--move it to 230 

*/