

/****
AreaDeprivationIndex_CountryLevel -- https://www.hipxchange.org/ADI
Contr_PBP_Year
ContrPbpYear
FIPSYear
LTV_Member_Demographics
LTV_Member_Disenrollment
LTV_Member_Enrollment
LTV_Member_Events
LTV_Member_Lifetime
LTV_Member_Month
Tmp_Member_Events_2
****/






------ Member Months -------

--Get member-month level enrollment data for COSMOS MAPD
-- drop table #ugap_enrollment
select distinct b.SavvyHICN, a.Year_Mo, c.Contr_Nbr, c.PBP
into #ugap_enrollment
from MiniOV..Fact_MemberContract		as a 
join MiniOV..SavvyID_to_SavvyHICN		as b	on a.SavvyID = b.SavvyID
join MiniOV..Dim_Contract				as c	on a.Contr_Sys_Id = c.Contr_Sys_ID
join pdb_WalkandWin.final.GP1026_WnW_Member_Details_20170712							as d	on convert(varchar,b.SavvyHICN) = d.SavvyHicn
where a.Year_Mo between 200601 and 201508
  and a.Src_Sys_Cd = 'CO'	--COSMOS only
  and c.MAPDFlag = 'Y'		--MAPD only
 -- and c.PBP not like '8%'	--exclude group retiree contracts	
--10,571,800



--Get MMR enrollment and revenue data, adjusting for retrospecitve adjustments
--by attributing dollars to service month (not payment month).
select distinct Year_Mo
into #year_mo
from MiniOV..Dim_Date

create unique index ix_year_mo on #year_mo(Year_Mo)

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
		from CmsMMR..MMR_Sub_10Percent	as a
		join #members					as b	on a.SavvyHICN = b.SavvyHICN
		)				as a 
	join #year_mo		as b	on b.Year_Mo between a.Start_Year_Mo and a.End_Year_Mo
	where b.Year_Mo between 200601 and 201508
	--order by 6, 2, 3, 4
	) as a
group by a.SavvyHICN, a.YEAR_MO, a.ContractNumber, a.PlanBenefitPackageID
having cast(sum(Adjusted_MA_Amt) as money) > 0	--Has MA benefit (resolves retroactive reversals)
   and cast(sum(Adjusted_D_Amt) as money) > 0	--Has Part D benefit
order by 1, 2
--11,749,074



--Summarize into master enrollment table
--Requires both UGAP + MMR agreement (98% of MM)
select a.SavvyHICN, a.Year_Mo, a.Contr_Nbr, a.PBP,
	   (left(a.Year_Mo, 4)-2006)*12+right(a.Year_Mo, 2) as Year_Mo_Rank,
	   0 as Lifetime_ID --Will be updated later
into #enrollment
from #ugap_enrollment		as a 
join #mmr_enrollment		as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
								   and a.Contr_Nbr = b.ContractNumber and a.PBP = b.PlanBenefitPackageID
--10,391,028

create unique index ix_x on #enrollment(SavvyHICN, Year_Mo)


---------------------------------------------------------------
--2) Add lifetime IDs based on blocks of continuous enrollment
---------------------------------------------------------------
--Start by identifying "new enollment" months (i.e. not enrolled in the previous month)
select a.SavvyHICN, a.Year_Mo, row_number() over(partition by a.SavvyHICN order by a.Year_Mo) as RN
into #new_enrolls
from #enrollment		as a 
left join #enrollment	as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo_Rank = b.Year_Mo_Rank+1
where b.SavvyHICN is null --No previous month = new enroll
order by 1

--Identify start and end dates for the lifetime (start = new enroll month, end = next enrollment month - 1)
select a.SavvyHICN, a.Year_Mo as Start_Year_Mo, isnull(b.Year_Mo-1, '999999') as End_Year_Mo, a.RN as Lifetime_ID
into #lifetimes
from #new_enrolls		as a 
left join #new_enrolls	as b	on a.SavvyHICN = b.SavvyHICN and a.RN+1 = b.RN
--330,811

create unique clustered index ix_x on #lifetimes(SavvyHICN, Start_Year_Mo)

--Update the Lifetime_ID
update #enrollment
set #enrollment.Lifetime_ID = b.Lifetime_ID  
from #enrollment		as a 
join #lifetimes			as b	on a.SavvyHICN = b.SavvyHICN 
where a.Year_Mo between b.Start_Year_Mo and b.End_Year_Mo




---------------------------------------------------------------
--3) Get Acquisition and Marketing Costs
---------------------------------------------------------------
--summary of acquisition channel
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
		from pdb_LTV..TK_MR2765_PDP_MA_Member_Clean	as a 
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
--155,071

--Acquisition Costs
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


--Marketing Costs
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




-------------------------------------------------------------
--4) Get claims costs
-------------------------------------------------------------
--Medical claims
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
where c.Year_Mo between 200601 and 201508
group by b.SavvyHICN, c.Year_Mo
--6,273,865


--Pharmacy claims
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
where c.YEAR_MO between 200601 and 201508
  and a.Claim_Status = 'P'
group by b.SavvyHICN, c.Year_Mo
--8,962,289




-------------------------------------------------------------
--5) Get member-paid premium amounts
-------------------------------------------------------------
--average accross counties, typically very little variation
select Plan_Year, Contr_Nbr, PBP,
       avg(Premium_C) as Premium_C,
	   avg(Premium_D) as Premium_D
into #premiums
from pdb_LTV..CMS_Plan_Benefits_CD_Premiums
group by Plan_Year, Contr_Nbr, PBP





-------------------------------------------------------------
--6) Gather it all together into primary member-month table
-------------------------------------------------------------
select a.*, 
       a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0) as Total_Revenue,
	   (a.Total_Claims_Cost-a.Rx_Rebate_Amt)+Marketing_Cost/*+Acquisition_Cost*/ as Total_Cost,
	   (a.Total_CMS_Amt+isnull(a.Premium_C_Amt,0)+isnull(a.Premium_D_Amt,0))
		- ((a.Total_Claims_Cost-a.Rx_Rebate_Amt)+Marketing_Cost/*+Acquisition_Cost*/) as Total_Value
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

		   isnull(e.Acquisition_Cost,0) as Acquisition_Cost,
		   isnull(f.Marketing_Cost,0) as Marketing_Cost,

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
	left join #acquisition_costs	as e	on a.SavvyHICN = e.SavvyHICN and a.Year_Mo = e.Year_Mo
	left join #marketing_costs		as f	on a.SavvyHICN = f.SavvyHICN and a.Year_Mo = f.Year_Mo
	left join #premiums				as g	on a.Contr_Nbr = g.Contr_Nbr and a.PBP = g.PBP
										   and left(a.Year_Mo, 4) = g.Plan_Year
	) as a
--10,391,028
--drop table #results

--select count(*) from #mmr			--11,749,074
--select count(*) from #enrollment	--10,571,800
--select count(*) from #results		--10,391,028


-------------------------------------------------------------
--7) Adjust all dollars based on CPI
-------------------------------------------------------------
create table #cpi(Yr int, CPI decimal(5, 3))

insert into #cpi values
	(2006, 0.918),
	(2007, 0.949),
	(2008, 0.973),
	(2009, 1.000),
	(2010, 1.027),
	(2011, 1.048),
	(2012, 1.068),
	(2013, 1.084),
	(2014, 1.099),
	(2015, 1.119)

create table pdb_LTV.. Member_Month(
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

	[Acquisition_Cost] [decimal](19, 4) NULL,
	[Marketing_Cost] [decimal](19, 4) NULL,
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


insert into pdb_LTV..Member_Month
select a.SavvyHICN, a.Lifetime_ID, a.Year_Mo, a.Contr_Nbr, a.PBP,
	   a.Total_MA_Amt/b.CPI as Total_MA_Amt,
	   a.Total_D_Amt/b.CPI as Total_D_Amt,
	   a.Total_CMS_Amt/b.CPI as Total_CMS_Amt,
	   
	   a.Total_MA_IP_Cost/b.CPI as Total_MA_IP_Cost,
	   a.Total_MA_OP_Cost/b.CPI as Total_MA_OP_Cost,
	   a.Total_MA_DR_Cost/b.CPI as Total_MA_DR_Cost, 
	   a.Total_MA_Cost/b.CPI as Total_MA_Cost,
	   a.Total_D_Cost/b.CPI as Total_D_Cost,
	   a.Total_Claims_Cost/b.CPI as Total_Claims_Cost,

	   a.Total_MA_OOP/b.CPI as Total_MA_OOP,
	   a.Total_D_OOP/b.CPI as Total_D_OOP,
	   a.Total_OOP/b.CPI as Total_OOP,

	   a.Rx_Rebate_Amt/b.CPI as Rx_Rebate_Amt,
	   a.LICS_Amt/b.CPI as LICS_Amt,
	   a.Reinsurance_Amt/b.CPI as Reinsurance_Amt,

	   a.Acquisition_Cost/b.CPI as Acquisition_Cost,
	   a.Marketing_Cost/b.CPI as Marketing_Cost,
	   a.Premium_C_Amt/b.CPI as Premium_C_Amt, 
	   a.Premium_D_Amt/b.CPI as Premium_D_Amt,
	   a.Total_Premium_Amt/b.CPI as TotaL_Premium_Amt,

	   a.MA_RAF,
	   a.D_RAF,
	   a.Year_Mo_Rank,
	   a.Total_Revenue/b.CPI as Total_Revenue,
	   a.Total_Cost/b.CPI as Total_Cost,
	   a.Total_Value/b.CPI as Total_Value,
	   a.HospiceFlag
from #results		as a
join #cpi			as b	on left(a.Year_Mo, 4) = b.Yr



create unique index ix_x on pdb_LTV..Member_Month(SavvyHICN, Year_Mo)







------------ LTV_Lifetimes  ------------

alter table pdb_LTV..Prelim_10Percent_Results_Adjusted_2006
add Year_Mo_Rank int

update pdb_LTV..Prelim_10Percent_Results_Adjusted_2006
set Year_Mo_Rank = (left(Year_Mo, 4)-2006)*12+right(Year_Mo, 2)

create unique index ix_shmr on pdb_LTV..Prelim_10Percent_Results_Adjusted_2006(SavvyHICN, Year_Mo_Rank)


select a.*, ROW_NUMBER() over(partition by a.SavvyHICN order by a.Year_Mo) as RN
into #temp
from pdb_LTV..Prelim_10Percent_Results_Adjusted_2006			as a 
left join pdb_LTV..Prelim_10Percent_Results_Adjusted_2006	as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo_Rank = b.Year_Mo_Rank+1
where b.SavvyHICN is null --No previous month = new enroll
order by 1, 2



select a.SavvyHICN, a.Year_Mo as Start_Year_Mo, isnull(b.Year_Mo, 999999)-1 as End_Year_Mo, a.RN as Lifetime_ID
into #lifetimes
from #temp		as a 
left join #temp as b	on a.SavvyHICN = b.SavvyHICN and a.RN+1 = b.RN


create unique index ix_start on #lifetimes(SavvyHICN, Start_Year_Mo)
create unique index ix_end on #lifetimes(SavvyHICN, End_Year_Mo)



alter table pdb_LTV..Prelim_10Percent_Results_Adjusted_2006
add Lifetime_ID int


update pdb_LTV..Prelim_10Percent_Results_Adjusted_2006
set pdb_LTV..Prelim_10Percent_Results_Adjusted_2006.Lifetime_ID = b.Lifetime_ID
from pdb_LTV..Prelim_10Percent_Results_Adjusted_2006 as a 
join #lifetimes	as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo between b.Start_Year_Mo and b.End_Year_Mo


select Lifetime_ID, *
from pdb_LTV..Prelim_10Percent_Results_Adjusted_2006
where SavvyHICN = 28789
order by 2, 3

select Lifetime_ID, *
from pdb_LTV..Prelim_10Percent_Results_Adjusted_2006
where Lifetime_ID = 4


----------- LTV_Member_Lifetime -------------
----------------------------------------------------------------
--1) Check for previous enrollments (MAPD, PDP, and Commercial)
----------------------------------------------------------------
--Check for PDP enrollment
select c.SavvyHICN, c.Lifetime_ID,
	   min(a.ServiceMonth) as Min_Year_Mo,
	   max(a.ServiceMonth) as Max_Year_Mo
into #pdp
from MiniPAPI..Dim_Member_Detail				as a 
join MiniPAPI..Dim_Plan_Benefit					as b	on a.Plan_Benefit_Sys_ID = b.Plan_Benefit_Sys_ID
join pdb_LTV..Member_Enrollment					as c	on a.SavvyHICN = c.SavvyHICN
where b.Is_PDPOnly = 1
  and a.ServiceMonth between 200601	and c.Enroll_Year_Mo	--in period of interest, before lifetime's enrollment date
group by c.SavvyHICN, c.Lifetime_ID
--41,790


--Check for Commercial enrollment
select d.SavvyHICN, d.Lifetime_ID,
	   min(a.Year_Mo) as Min_Year_Mo, 
	   max(a.Year_Mo) as Max_Year_Mo
	   --a.Year_Mo, b.Co_Nm, b.Co_Id_Rllp, b.Hlth_Pln_Fund_Cd, b2.CUST_SEG_NBR, b2.CUST_SEG_NM
into #com
from MiniHPDM..Summary_Indv_Demographic			as a 
join MiniHPDM..Dim_CustSegSysId					as b	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
join MiniHPDM..Dim_Customer_Segment				as b2	on a.Cust_Seg_Sys_Id = b2.Cust_Seg_Sys_Id
join MiniOV..SavvyHICN_to_Indv_Sys_ID			as c	on a.Indv_Sys_Id = c.Indv_Sys_ID
join pdb_LTV..Member_Enrollment					as d	on c.SavvyHICN = d.SavvyHICN
where b.Co_Nm not in ('Ovations', 'Americhoice', 'Oxford')	--Not M&R
  and a.Year_Mo between 200601 and d.Enroll_Year_Mo			--in period of interest, before lifetime's enrollment date
group by d.SavvyHICN, d.Lifetime_ID
--19,778


--Build New_Member_Status
select a.SavvyHICN, a.Lifetime_ID,
	   case when a.Lifetime_ID > 1 then 'Prior MAPD'
		    when b.SavvyHICN is not null then 'Prior Commercial'
			when c.SavvyHICN is not null then 'Prior PDP Only'
			else 'New UHC Member' end as New_Member_Status
into #previous_enrollment
from pdb_LTV..Member_Enrollment	as a 
left join #com					as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
left join #pdp					as c	on a.SavvyHICN = c.SavvyHICN and a.Lifetime_ID = c.Lifetime_ID
--330,811



-------------------------------------------------------------
--2) Summarize lifetimes
-------------------------------------------------------------
insert into pdb_LTV..Member_Lifetime
select a.*, 
       case when a.Enroll_Flag = 1 and a.Disenroll_Flag = 1 then 'Completed Lifetime'
	        when a.Enroll_Flag = 1 and a.Disenroll_Flag = 0 then 'Current Member'
			when a.Enroll_Flag = 0 and a.Disenroll_Flag = 0 then 'Long-term Member'
			when a.Enroll_Flag = 0 and a.Disenroll_Flag = 1 then 'Long-gone Member'
			end as Lifetime_Type
from(
	select a.*, b.New_Member_Status
	from(
		select SavvyHICN, Lifetime_ID, 
			   min(Year_Mo) as Enroll_Year_Mo,
			   max(Year_Mo) as Disenroll_Year_Mo,
			   count(distinct Year_Mo) as Total_MM,
			   count(distinct Contr_Nbr+'-'+PBP) as Plan_Cnt,
			   sum(Total_Revenue) as Total_Revenue,
			   sum(Total_Cost) as Total_Cost,
			   sum(Total_Value) as Total_Value,
			   case when min(Year_Mo) > 200601 then 1 else 0 end as Enroll_Flag,
			   case when max(Year_Mo) < 201508 then 1 else 0 end as Disenroll_Flag,
			   case when min(Year_Mo) > 200601 and max(Year_Mo) < 201508 then 1 else 0 end as Lifetime_Flag
		from pdb_LTV..Member_Month			as a
		group by SavvyHICN, Lifetime_ID
		)						as a 
	join #previous_enrollment	as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
	--330811
	) as a


create unique index ix_SH_LI on pdb_LTV..Member_Lifetime(SavvyHICN, Lifetime_ID)
create unique index ix_SH_EY on pdb_LTV..Member_Lifetime(SavvyHICN, Enroll_Year_Mo)
create unique index ix_SH_DY on pdb_LTV..Member_Lifetime(SavvyHICN, Disenroll_Year_Mo)



--------- Contr PBP Year ---------

select Contr_Nbr, PBP, left(Year_Mo, 4) as Plan_Year, count(distinct SavvyHICN) as Mbr_Cnt
into #contr
from pdb_LTV..Member_Month
group by Contr_Nbr, PBP, left(Year_Mo, 4)
--1722

select * 
from #contr		as a 
join MiniOV..Dim_Contract	as b	on a.Contr_Nbr = b.Contr_Nbr and a.PBP = b.PBP
where a.PBP like '8%'


select a.Contr_Nbr, a.PBP, a.Plan_Year,
       Brand, PBPDescription, 
	   Product, SubProduct, ContractType,
	   case when Product = 'SNP' and (SpecialNeedsPlanTypeKey = 1 
								      or SubProduct = 'Institutional (SNP)'
									  or TADMSNPType = 'INSTITUTIONAL'
									  or PBPDescription like 'Erickson Advantage Guardian%') then 'I-SNP'
	        when Product = 'SNP' and (SpecialNeedsPlanTypeKey = 2 
								      or SubProduct = 'Dual (SNP)'
									  or SubProduct = 'MASCO'
									  or TADMSNPType = 'DUAL - ELIGIBLE') then 'D-SNP'
			when Product = 'SNP' and (SpecialNeedsPlanTypeKey = 3 
									  or SubProduct = 'Chronic (SNP)'
									  or SubProduct = 'ESRD (SNP)'
									  or TADMSNPType = 'CHRONIC OR DISABLING CONDITION'
									  or PBPDescription like 'Erickson Advantage Champion%') then 'C-SNP'
			when a.PBP like '8%' then 'EGHP'
			else Product end as Derived_Product 
into #contr_details
from #contr						as a 
left join MiniOV..Dim_Contract	as b	on a.Contr_Nbr = b.Contr_Nbr and a.PBP = b.PBP and a.Plan_Year = b.Contr_Yr
--1722


select a.Contr_Nbr, a.PBP, a.Plan_Year, b.Premium_C_Amt, b.Premium_D_Amt
into #contr_premium
from #contr		as a 
left join(
	select Contr_Nbr, PBP, Plan_Year, 
		   avg(Premium_C) as Premium_C_Amt,
		   avg(Premium_D) as Premium_D_Amt
	from pdb_LTV..CMS_Plan_Benefits_CD_Premiums
	group by Contr_Nbr, PBP, Plan_Year
	) as b	on a.Contr_Nbr = b.Contr_Nbr and a.PBP = b.PBP and a.Plan_Year = b.Plan_Year
--1722

select a.Contr_Nbr, a.PBP, cast(a.Plan_Year as int) as Plan_Year, a.Mbr_Cnt,
	   b.Brand, b.PBPDescription as Plan_Desc, b.Product, b.SubProduct, b.ContractType, b.Derived_Product,
	   c.Premium_C_Amt, c.Premium_D_Amt
into pdb_LTV..Contr_PBP_Year
from #contr			as a 
join #contr_details	as b	on a.Contr_Nbr = b.Contr_Nbr and a.PBP = b.PBP and a.Plan_Year = b.Plan_Year
join #contr_premium	as c	on a.Contr_Nbr = c.Contr_Nbr and a.PBP = c.PBP and a.Plan_Year = c.Plan_Year
--1722



create unique index ix_contr_pbp_yr on pdb_LTV..Contr_PBP_Year(Contr_Nbr, PBP, Plan_Year)




------------- LTV_Member_Events --------------

select SavvyHICN, 	   
       year(RunDate) as Yr,
	   cast(year(RunDate) as varchar)+right('00'+cast(month(RunDate) as varchar),2) as Year_Mo, 
	   cast(RunDate as date) as Event_Date,
	   HCC, Flag
into #mor_unpivot
from pdb_LTV..LTV_Mbrs_MOR unpivot(Flag for HCC in(
       [DiseaseCoefficientsHCC1]
      ,[DiseaseCoefficientsHCC2]
      ,[DiseaseCoefficientsHCC5]
      ,[DiseaseCoefficientsHCC7]
      ,[DiseaseCoefficientsHCC8]
      ,[DiseaseCoefficientsHCC9]
      ,[DiseaseCoefficientsHCC10]
      ,[DiseaseCoefficientsHCC15]
      ,[DiseaseCoefficientsHCC16]
      ,[DiseaseCoefficientsHCC17]
      ,[DiseaseCoefficientsHCC18]
      ,[DiseaseCoefficientsHCC19]
      ,[DiseaseCoefficientsHCC21]
      ,[DiseaseCoefficientsHCC25]
      ,[DiseaseCoefficientsHCC26]
      ,[DiseaseCoefficientsHCC27]
      ,[DiseaseCoefficientsHCC31]
      ,[DiseaseCoefficientsHCC32]
      ,[DiseaseCoefficientsHCC33]
      ,[DiseaseCoefficientsHCC37]
      ,[DiseaseCoefficientsHCC38]
      ,[DiseaseCoefficientsHCC44]
      ,[DiseaseCoefficientsHCC45]
      ,[DiseaseCoefficientsHCC51]
      ,[DiseaseCoefficientsHCC52]
      ,[DiseaseCoefficientsHCC54]
      ,[DiseaseCoefficientsHCC55]
      ,[DiseaseCoefficientsHCC67]
      ,[DiseaseCoefficientsHCC68]
      ,[DiseaseCoefficientsHCC69]
      ,[DiseaseCoefficientsHCC70]
      ,[DiseaseCoefficientsHCC71]
      ,[DiseaseCoefficientsHCC72]
      ,[DiseaseCoefficientsHCC73]
      ,[DiseaseCoefficientsHCC74]
      ,[DiseaseCoefficientsHCC75]
      ,[DiseaseCoefficientsHCC77]
      ,[DiseaseCoefficientsHCC78]
      ,[DiseaseCoefficientsHCC79]
      ,[DiseaseCoefficientsHCC80]
      ,[DiseaseCoefficientsHCC81]
      ,[DiseaseCoefficientsHCC82]
      ,[DiseaseCoefficientsHCC83]
      ,[DiseaseCoefficientsHCC92]
      ,[DiseaseCoefficientsHCC95]
      ,[DiseaseCoefficientsHCC96]
      ,[DiseaseCoefficientsHCC100]
      ,[DiseaseCoefficientsHCC101]
      ,[DiseaseCoefficientsHCC104]
      ,[DiseaseCoefficientsHCC105]
      ,[DiseaseCoefficientsHCC107]
      ,[DiseaseCoefficientsHCC108]
      ,[DiseaseCoefficientsHCC111]
      ,[DiseaseCoefficientsHCC112]
      ,[DiseaseCoefficientsHCC119]
      ,[DiseaseCoefficientsHCC130]
      ,[DiseaseCoefficientsHCC131]
      ,[DiseaseCoefficientsHCC132]
      ,[DiseaseCoefficientsHCC148]
      ,[DiseaseCoefficientsHCC149]
      ,[DiseaseCoefficientsHCC150]
      ,[DiseaseCoefficientsHCC154]
      ,[DiseaseCoefficientsHCC155]
      ,[DiseaseCoefficientsHCC157]
      ,[DiseaseCoefficientsHCC158]
      ,[DiseaseCoefficientsHCC161]
      ,[DiseaseCoefficientsHCC164]
      ,[DiseaseCoefficientsHCC174]
      ,[DiseaseCoefficientsHCC176]
      ,[DiseaseCoefficientsHCC177]
	)) as Unpiv
where Flag = 'True'
--18735485

select SavvyHICN, Year_Mo, Event_Date, 
	   case when RN_Global = 1 then 'HCC Diagnosed' 
		    when RN_Year = 1 then 'HCC Documented' end as Event_Type,
	   b.HCCNbr as HCC_Nbr, b.TermLabel as HCC_Desc
into pdb_LTV..Member_Events_v2
from(
	select SavvyHICN, Year_Mo, Event_Date, HCC, 
		   row_number() over(partition by SavvyHICN, HCC, Yr order by Event_Date) as RN_Year,
		   row_number() over(partition by SavvyHICN, HCC order by Event_Date) as RN_Global
	from #mor_unpivot
	) as a
left join(
  select HCCNbr, TermLabel
  from RA_Medicare_2014_v2..ModelTerm
  where ModelID = 3
    and HCCNbr is not null
	) as b	on right(HCC, len(HCC)-len('DiseaseCoefficientsHCC')) = b.HCCNbr
where RN_Year = 1 or RN_Global = 1
--2692354

drop table pdb_LTV..Member_Events_v2

select * 
from  pdb_LTV..Member_Events_v2



create unique index ix_x on pdb_LTV..Member_Events(SavvyHICN, Year_Mo, EventType)
create index ix_y on pdb_LTV..Member_Events(SavvyHICN, Year_Mo)






--------- LTV_Member_Enrollment ---------
-------------------------------------------------------------
--1) Get acquisition channel for the lifetime
-------------------------------------------------------------
--summary of acquisition channel
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
		from pdb_LTV..TK_MR2765_PDP_MA_Member_Clean	as a 
		where a.CHNL_DESC <> 'missing'
		) as a
	) as a 
join pdb_LTV..Member_Lifetime	as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo between b.Enroll_Year_Mo and b.Disenroll_Year_Mo
group by a.SavvyHICN, b.Lifetime_ID
--155,071



-------------------------------------------------------------
--2) Get TRR enrollment reasons
-------------------------------------------------------------
--use M&R Finance order-of-operations logic to select the most relevant record for each transaction type and date
select a.*
into #trr
from(
	select a.SavvyHICN,
			a.ContractNumber as Contr_Nbr,
			a.PlanBenefitPackageID as PBP,
			a.TransactionEffectiveDateCode,
			left(a.TransactionEffectiveDateCode, 6) as Year_Mo,
			a.TransactionTypeCode, c.TransactionTypeDescription,
			a.TransactionReplyCode, b.Title as TransactionReplyDescription,
			a.EnrollmentSource, d.EnrollmentSourceDescription,
			a.ElectionType, e.ElectionTypeDesc,
			a.DisenrollmentReasonCode, f.DisenrollmentReasonDesc,
			--a.MedicaidStatus, a.Disability, a.Hospice, a.InstitutionalNHC, a.ESRD, 
			ROW_NUMBER() over(partition by a.SavvyHICN, a.ContractNumber, a.PlanBenefitPackageID, a.TransactionTypeCode, a.TransactionEffectiveDateCode order by b.TransactionReplyCodeType, a.DateInFileName desc, a.TransactionReplyCode) as RN
	from CmsMMR..TRR_Sub_10Percent					as a 
	left join pdb_LTV..TRR_TransactionReplyCode		as b	on a.TransactionReplyCode = b.TransactionReplyCode
	left join pdb_LTV..TRR_TransactionTypeCode		as c	on a.TransactionTypeCode = c.TransactionTypeCode
	left join pdb_LTV..TRR_EnrollmentSource			as d	on a.EnrollmentSource = d.EnrollmentSourceCode
	left join pdb_LTV..TRR_ElectionType				as e	on a.ElectionType = e.ElectionTypeCode
	left join pdb_LTV..TRR_DisenrollmentReasonCode	as f	on a.DisenrollmentReasonCode = f.DisenrollmentReasonCode
	where a.TransactionTypeCode in('01','51','53','54','60','61','62','71','74','80','81','82')
		and b.TransactionReplyCodeType in('A') --Accepted (not Rejected, Informational, Maintenance, or Failed)
	) as a
where a.RN = 1
--916,728



select * 
into #trr_enrollment
from(
	select *, ROW_NUMBER() over(partition by a.SavvyHICN, a.Year_Mo order by a.TransactionEffectiveDateCode asc, a.TransactionReplyCode) as RN2
	from #trr	as a
	where a.TransactionTypeCode in('60','61','62')
	) as a
where a.RN2 = 1
--449,248


select a.*, isnull(b.Death_Flag, 0) as Death_Flag
into #trr_disenrollment
from(
	select *, ROW_NUMBER() over(partition by a.SavvyHICN, a.Year_Mo order by a.TransactionEffectiveDateCode desc, a.TransactionReplyCode) as RN2
	from #trr	as a
	where a.TransactionTypeCode in('51','53','54')
	) as a
left join(
	select distinct SavvyHICN, left(TransactionEffectiveDateCode, 6) as Year_Mo, 1 as Death_Flag
	from CmsMMR..TRR_Sub_10Percent
	where TransactionReplyCode in ('090', '092')
	) as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
where a.RN2 = 1
--352,019



--drop table #trr, #trr_disenrollment, #trr_enrollment



select a.SavvyHICN, a.Lifetime_ID, a.Enroll_Year_Mo,
       x.Contr_Nbr, x.PBP,
       case when b.Chnl_FMO = 1		then 'FMO/ICA'
	        when b.Chnl_ICA = 1		then 'FMO/ICA'
			when b.Chnl_ISR = 1		then 'ISR'
			when b.Chnl_Phone = 1	then 'Telesales'
			when b.Chnl_Web = 1		then 'Web' end as Acquisition_Channel,
	   c.TransactionTypeDescription as TransactionTypeDesc,
	   c.TransactionReplyDescription as TransactionReplyDesc,
	   c.EnrollmentSourceDescription as EnrollmentSourceDesc,
	   c.ElectionTypeDesc,
	   e.Age-(2016-left(a.Enroll_Year_Mo, 4)) as Estimated_Age
into pdb_LTV..Member_Enrollment
from pdb_LTV..Member_Lifetime				as a 
join pdb_LTV..Member_Month					as x	on a.SavvyHICN = x.SavvyHICN and a.Enroll_Year_Mo = x.Year_Mo
left join #channel							as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
left join #trr_enrollment					as c	on a.SavvyHICN = c.SavvyHICN and a.Enroll_Year_Mo = c.Year_Mo
left join MiniOV..SavvyID_to_SavvyHICN		as d	on a.SavvyHICN = d.SavvyHICN
left join MiniOV..Dim_Member				as e	on d.SavvyID = e.SavvyID
--330811

create unique index ix_x on pdb_LTV..Member_Enrollment(SavvyHICN, Lifetime_ID)
create unique index ix_y on pdb_LTV..Member_Enrollment(SavvyHICN, Enroll_Year_Mo)





select a.SavvyHICN, a.Lifetime_ID, a.Disenroll_Year_Mo,
       x.Contr_Nbr, x.PBP,
	   c.TransactionTypeDescription as TransactionTypeDesc,
	   c.TransactionReplyDescription as TransactionReplyDesc,
	   c.DisenrollmentReasonDesc,
	   case when c.Death_Flag = 1 then 'Death'
	        when c.DisenrollmentReasonCode in('05', '06', '61', '64', '65', '93') then 'Loss of Eligibility'
			when c.DisenrollmentReasonCode in('07') then 'For Cause'
			--when c.DisenrollmentReasonCode in('08') then 'Death'
			when c.DisenrollmentReasonCode in('09') then 'CMS Initiated Termination'
			when c.DisenrollmentReasonCode in('11', '63') then 'Voluntary Disenrollment or Opt-Out'
			when c.DisenrollmentReasonCode in('13', '18', '50') then 'Switched Plans or Rollover'
			when c.DisenrollmentReasonCode in('62', '91') then 'Failure to Pay'
			when c.DisenrollmentReasonCode in('92') then 'Relocation' 
			when c.TransactionReplyCode in('014') then 'Switched Plans or Rollover'
			when c.TransactionReplyCode in('018') then 'Automatic Disenrollment'
			when c.TransactionReplyCode in ('090', '092') then 'Death'
			when c.TransactionReplyCode in ('131') then 'Voluntary Disenrollment or Opt-Out'
			when c.TransactionReplyCode in ('197') then 'Loss of Eligibility'
			when c.TransactionReplyCode in ('293') then 'Failure to Pay'
			else 'Other/Unknown'
			end as DerivedDisenrollmentReason,	
	   c.Death_Flag,
	   e.Age-(2016-left(a.Disenroll_Year_Mo, 4)) as Estimated_Age
into pdb_LTV..Member_Disenrollment
from pdb_LTV..Member_Lifetime				as a 
join pdb_LTV..Member_Month					as x	on a.SavvyHICN = x.SavvyHICN and a.Disenroll_Year_Mo = x.Year_Mo
left join #trr_disenrollment				as c	on a.SavvyHICN = c.SavvyHICN and a.Disenroll_Year_Mo = c.Year_Mo
left join MiniOV..SavvyID_to_SavvyHICN		as d	on a.SavvyHICN = d.SavvyHICN
left join MiniOV..Dim_Member				as e	on d.SavvyID = e.SavvyID

create unique index ix_x on pdb_LTV..Member_Disenrollment(SavvyHICN, Lifetime_ID)
create unique index ix_y on pdb_LTV..Member_Disenrollment(SavvyHICN, Disenroll_Year_Mo)




--Validation
select left(Enroll_Year_Mo, 4) as Yr,
	   count(*),
       sum(case when Acquisition_Channel is not null then 1 else 0 end)*1.0/count(*) as AC_Rate,
	   sum(case when TransactionTypeDesc is not null then 1 else 0 end)*1.0/count(*) as TType_Rate,
	   sum(case when ElectionTypeDesc is not null then 1 else 0 end)*1.0/count(*) as ET_Rate,
	   sum(case when Estimated_Age is not null then 1 else 0 end)*1.0/count(*) as Age_Rate
from pdb_LTV..Member_Enrollment
group by left(Enroll_Year_Mo, 4)
order by 1


select left(Disenroll_Year_Mo, 4) as Yr,
	   count(*),
	   sum(case when TransactionTypeDesc is not null then 1 else 0 end)*1.0/count(*) as TType_Rate,
	   sum(case when DisenrollmentReasonDesc is not null then 1 else 0 end)*1.0/count(*) as DR_Rate,
	   sum(case when Estimated_Age is not null then 1 else 0 end)*1.0/count(*) as Age_Rate
from pdb_LTV..Member_Disenrollment
group by left(Disenroll_Year_Mo, 4)
order by 1


----------------- LTV_Member_Demographics -------------------
-------------------------------------------------------------
--1) Get member details for distinct SavvyHICNs
-------------------------------------------------------------
select distinct SavvyHICN
into #members
from pdb_LTV..Member_Lifetime

--get MMR flags (OREC)
select a.SavvyHICN, max(a.OriginalReasonForEntitlement) as OriginalReasonForEntitlement
into #mmr_flags
from CMSMmr..MMR_Sub_10Percent		as a 
join #members						as b	on a.SavvyHICN = b.SavvyHICN
group by a.SavvyHICN


select a.SavvyHICN, c.Age, c.Gender, c.ZIP, g.OriginalReasonForEntitlement,
	   d.St_Cd, 
       d.MSA,
	   d.FIPS,
	   e.USR_Class,
	   f.[MedianHouseholdIncomeInThePast12Months (2011 Inflation-Adjusted Dollars)] as Median_Household_Income
into pdb_LTV..Member_Demographics
from #members									as a 
left join MiniOV..SavvyID_to_SavvyHICN			as b	on a.SavvyHICN = b.SavvyHICN
left join MiniOV..Dim_Member					as c	on b.SavvyID = c.SavvyID
left join DEVSQL15.Census.dbo.Zip_Census		as d	on c.ZIP = d.ZIP
left join DEVSQL15.Census.dbo.ZCTA				as e	on d.ZCTA = e.ZCTA
left join DEVSQL15.Census.dbo.Census_ZCTA_Data	as f	on d.ZCTA = f.GeoId2
left join #mmr_flags							as g	on a.SavvyHICN = g.SavvyHICN


create unique index ix_savvyHICN on pdb_LTV..Member_Demographics(SavvyHICN)

