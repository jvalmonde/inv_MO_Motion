USE pdb_WalkandWin /*...on DBSEP3832*/
GO

IF object_id('wkg_Cost_Outlier_2016_Pilot','U') IS NOT NULL
	DROP TABLE wkg_Cost_Outlier_2016_Pilot;
select 
	a.SavvyHICN,
	a.Yr,
	a.Total_Year_Cost,
	GrandTotal						=	sum(a.Total_Year_Cost) over	(partition by a.Yr),
	Moving_Total					=	sum(a.Total_Year_Cost) over	(partition by a.Yr
																	order by sum(a.Total_Year_Cost) desc rows unbounded preceding),
	Percentage_of_Grand_Total		=	100. * sum(a.Total_Year_Cost) over	(partition by a.yr 
																			order by sum(a.Total_Year_Cost) desc rows unbounded preceding) 
										/ sum(a.Total_Year_Cost) over (partition by a.Yr),
	Outlier_Flag					=	case when sum(a.Total_Year_Cost) over	(partition by a.yr 
																				order by sum(a.Total_Year_Cost) desc rows unbounded preceding) 
													/ sum(a.Total_Year_Cost) over (partition by a.Yr) <= .05 
											then 1 
											else 0 
										end
into wkg_Cost_Outlier_2016_Pilot
from wkg_Total_Per_Member_Cost	a
	join CombinedMember_sg		b	on	a.SavvyHICN		=	b.SavvyHICN
where
	b.is2016				=	1
group by
	a.SavvyHICN, a.Yr, a.Total_Year_Cost
go
create clustered index cixSavvyHICN on wkg_Cost_Outlier_2016_Pilot(SavvyHICN)
go

IF object_id('wkg_Cost_Outlier_2017_Pilot','U') IS NOT NULL
	DROP TABLE wkg_Cost_Outlier_2017_Pilot;
select 
	a.SavvyHICN,
	a.Yr,
	a.Total_Year_Cost,
	GrandTotal						=	sum(a.Total_Year_Cost) over	(partition by a.Yr),
	Moving_Total					=	sum(a.Total_Year_Cost) over	(partition by a.Yr
																	order by sum(a.Total_Year_Cost) desc rows unbounded preceding),
	Percentage_of_Grand_Total		=	100. * sum(a.Total_Year_Cost) over	(partition by a.yr 
																			order by sum(a.Total_Year_Cost) desc rows unbounded preceding) 
										/ sum(a.Total_Year_Cost) over (partition by a.Yr),
	Outlier_Flag					=	case when sum(a.Total_Year_Cost) over	(partition by a.yr 
																				order by sum(a.Total_Year_Cost) desc rows unbounded preceding) 
													/ sum(a.Total_Year_Cost) over (partition by a.Yr) <= .05 
											then 1 
											else 0 
										end
into wkg_Cost_Outlier_2017_Pilot
from wkg_Total_Per_Member_Cost	a
	join CombinedMember_sg		b	on	a.SavvyHICN		=	b.SavvyHICN
where
	b.is2017				=	1
group by
	a.SavvyHICN, a.Yr, a.Total_Year_Cost
go
create clustered index cixSavvyHICN on wkg_Cost_Outlier_2017_Pilot(SavvyHICN)
go

IF object_id('wkg_results2_2016_Pilot','U') IS NOT NULL
	DROP TABLE wkg_results2_2016_Pilot;
select a.*
,c.LegacyOrganization
,c.PBPDescription
,c.Contr_Desc
,c.ProductCategory
,c.ContractType
,CASE WHEN b.yr = 2014 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2014
,CASE WHEN b.yr = 2015 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2015
,CASE WHEN b.yr = 2016 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2016
,CASE WHEN b.yr = 2017 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2017
into wkg_results2_2016_Pilot
from wkg_results as a
left join wkg_Cost_Outlier_2016_Pilot as b on a.SavvyHICN = b.SavvyHICN and a.Yr = b.Yr
left join wkg_Plan_Info as c on a.SavvyHICN = c.SavvyHICN and a.Year_Mo = c.Year_Mo
join CombinedMember_sg	d	on	a.SavvyHICN		=	d.SavvyHICN
where
	d.is2016				=	1
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_results2_2016_Pilot(SavvyHICN, Year_Mo)
go

IF object_id('wkg_results2_2017_Pilot','U') IS NOT NULL
	DROP TABLE wkg_results2_2017_Pilot;
select a.*
,c.LegacyOrganization
,c.PBPDescription
,c.Contr_Desc
,c.ProductCategory
,c.ContractType
,CASE WHEN b.yr = 2014 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2014
,CASE WHEN b.yr = 2015 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2015
,CASE WHEN b.yr = 2016 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2016
,CASE WHEN b.yr = 2017 and b.SavvyHICN is not null then isnull(b.Outlier_Flag,0) else 0 end as Top5_Prcnt_2017
into wkg_results2_2017_Pilot 
from wkg_results as a
left join wkg_Cost_Outlier_2017_Pilot as b on a.SavvyHICN = b.SavvyHICN and a.Yr = b.Yr
left join wkg_Plan_Info as c on a.SavvyHICN = c.SavvyHICN and a.Year_Mo = c.Year_Mo
join CombinedMember_sg	d	on	a.SavvyHICN		=	d.SavvyHICN
where
	d.is2017				=	1
go
create clustered index cix_SavvyHICN_Year_Mo on wkg_results2_2017_Pilot(SavvyHICN, Year_Mo)
go

IF object_id('LTV_Member_Month_2016_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Month_2016_Pilot;
select 
	a.SavvyHICN, 
	a.Lifetime_ID, 
	a.Year_Mo, 
	a.Contr_Nbr, a.PBP,
	a.LegacyOrganization,
	a.PBPDescription,
	a.Contr_Desc,
	a.ProductCategory,
	a.ContractType,
	
	Total_MA_Amt								=	a.Total_MA_Amt * b.CPI_Ratio,
	Total_D_Amt									=	a.Total_D_Amt * b.CPI_Ratio,
	Total_CMS_Amt								=	a.Total_CMS_Amt * b.CPI_Ratio,
	   
	Total_MA_IP_Cost							=	a.Total_MA_IP_Cost * b.CPI_Ratio,
	Total_MA_OP_Cost							=	a.Total_MA_OP_Cost * b.CPI_Ratio,
	Total_MA_DR_Cost							=	a.Total_MA_DR_Cost * b.CPI_Ratio, 
	Total_MA_Derived_IP_Cost					=	a.Total_MA_Derived_IP_Cost * b.CPI_Ratio,
	Total_MA_Derived_OP_Cost					=	a.Total_MA_Derived_OP_Cost * b.CPI_Ratio,
	Total_MA_Derived_DR_Cost					=	a.Total_MA_Derived_DR_Cost * b.CPI_Ratio,
	Total_MA_Derived_ER_Cost					=	a.Total_MA_Derived_ER_Cost * b.CPI_Ratio,
	Total_MA_Derived_DME_Cost					=	a.Total_MA_Derived_DME_Cost * b.CPI_Ratio,
	Total_MA_Cost								=	a.Total_MA_Cost * b.CPI_Ratio,
	Total_D_Cost								=	a.Total_D_Cost * b.CPI_Ratio,
	Total_Claims_Cost							=	a.Total_Claims_Cost * b.CPI_Ratio,

	Total_MA_OOP								=	a.Total_MA_OOP*b.CPI_Ratio,
	Total_D_OOP									=	a.Total_D_OOP*b.CPI_Ratio,
	Total_OOP									=	a.Total_OOP*b.CPI_Ratio,
	   
	Rx_Rebate_Amt_Full							=	a.Rx_Rebate_Amt_Full*b.CPI_Ratio,
	Rx_Rebate_Amt_40Percent						=	a.Rx_Rebate_Amt_40Percent *b.CPI_Ratio,
	LICS_Amt									=	a.LICS_Amt*b.CPI_Ratio,
	Reinsurance_Amt								=	a.Reinsurance_Amt*b.CPI_Ratio,
	   
	Premium_C_Amt								=	a.Premium_C_Amt*b.CPI_Ratio, 
	Premium_D_Amt								=	a.Premium_D_Amt*b.CPI_Ratio,
	Total_Premium_Amt							=	a.Total_Premium_Amt*b.CPI_Ratio,

	a.MA_RAF,
	a.D_RAF,
	Year_Mo_Rank								=	a.Year_Mo_Rnk,
	Total_Revenue								=	a.Total_Revenue*b.CPI_Ratio,
	Total_Cost_40Percent_Rebate					=	a.Total_Cost_40Percent_Rebate*b.CPI_Ratio,
	Total_Cost_Full_Rebate						=	a.Total_Cost_Full_Rebate*b.CPI_Ratio,
	Total_Cost_NoRebate							=	a.Total_Cost_NoRebate*b.CPI_Ratio,
	Total_Value_40Percent_Rebate				=	a.Total_Value_40Percent_Rebate*b.CPI_Ratio,
	Total_Value_Full_Rebate						=	a.Total_Value_Full_Rebate*b.CPI_Ratio,
	Total_Value_NoRebate						=	a.Total_Value_NoRebate*b.CPI_Ratio,
	a.HospiceFlag,

	a.Top5_Prcnt_2014,
	a.Top5_Prcnt_2015,
	a.Top5_Prcnt_2016,
	a.Top5_Prcnt_2017
into LTV_Member_Month_2016_Pilot
from wkg_results2_2016_Pilot		as a
join CPI_Adjustment_sg2016			as b	on a.Year_Mo = b.Year_Mo
-- 2,400,108
go
create clustered index cixSavvyHICN_Year_Mo on LTV_Member_Month_2016_Pilot(SavvyHICN, Year_Mo)
go


IF object_id('LTV_Member_Month_2017_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Month_2017_Pilot;
select 
	a.SavvyHICN, 
	a.Lifetime_ID, 
	a.Year_Mo, 
	a.Contr_Nbr, a.PBP,
	a.LegacyOrganization,
	a.PBPDescription,
	a.Contr_Desc,
	a.ProductCategory,
	a.ContractType,
	
	Total_MA_Amt								=	a.Total_MA_Amt * b.CPI_Ratio,
	Total_D_Amt									=	a.Total_D_Amt * b.CPI_Ratio,
	Total_CMS_Amt								=	a.Total_CMS_Amt * b.CPI_Ratio,
	   
	Total_MA_IP_Cost							=	a.Total_MA_IP_Cost * b.CPI_Ratio,
	Total_MA_OP_Cost							=	a.Total_MA_OP_Cost * b.CPI_Ratio,
	Total_MA_DR_Cost							=	a.Total_MA_DR_Cost * b.CPI_Ratio, 
	Total_MA_Derived_IP_Cost					=	a.Total_MA_Derived_IP_Cost * b.CPI_Ratio,
	Total_MA_Derived_OP_Cost					=	a.Total_MA_Derived_OP_Cost * b.CPI_Ratio,
	Total_MA_Derived_DR_Cost					=	a.Total_MA_Derived_DR_Cost * b.CPI_Ratio,
	Total_MA_Derived_ER_Cost					=	a.Total_MA_Derived_ER_Cost * b.CPI_Ratio,
	Total_MA_Derived_DME_Cost					=	a.Total_MA_Derived_DME_Cost * b.CPI_Ratio,
	Total_MA_Cost								=	a.Total_MA_Cost * b.CPI_Ratio,
	Total_D_Cost								=	a.Total_D_Cost * b.CPI_Ratio,
	Total_Claims_Cost							=	a.Total_Claims_Cost * b.CPI_Ratio,

	Total_MA_OOP								=	a.Total_MA_OOP*b.CPI_Ratio,
	Total_D_OOP									=	a.Total_D_OOP*b.CPI_Ratio,
	Total_OOP									=	a.Total_OOP*b.CPI_Ratio,
	   
	Rx_Rebate_Amt_Full							=	a.Rx_Rebate_Amt_Full*b.CPI_Ratio,
	Rx_Rebate_Amt_40Percent						=	a.Rx_Rebate_Amt_40Percent *b.CPI_Ratio,
	LICS_Amt									=	a.LICS_Amt*b.CPI_Ratio,
	Reinsurance_Amt								=	a.Reinsurance_Amt*b.CPI_Ratio,
	   
	Premium_C_Amt								=	a.Premium_C_Amt*b.CPI_Ratio, 
	Premium_D_Amt								=	a.Premium_D_Amt*b.CPI_Ratio,
	Total_Premium_Amt							=	a.Total_Premium_Amt*b.CPI_Ratio,

	a.MA_RAF,
	a.D_RAF,
	Year_Mo_Rank								=	a.Year_Mo_Rnk,
	Total_Revenue								=	a.Total_Revenue*b.CPI_Ratio,
	Total_Cost_40Percent_Rebate					=	a.Total_Cost_40Percent_Rebate*b.CPI_Ratio,
	Total_Cost_Full_Rebate						=	a.Total_Cost_Full_Rebate*b.CPI_Ratio,
	Total_Cost_NoRebate							=	a.Total_Cost_NoRebate*b.CPI_Ratio,
	Total_Value_40Percent_Rebate				=	a.Total_Value_40Percent_Rebate*b.CPI_Ratio,
	Total_Value_Full_Rebate						=	a.Total_Value_Full_Rebate*b.CPI_Ratio,
	Total_Value_NoRebate						=	a.Total_Value_NoRebate*b.CPI_Ratio,
	a.HospiceFlag,

	a.Top5_Prcnt_2014,
	a.Top5_Prcnt_2015,
	a.Top5_Prcnt_2016,
	a.Top5_Prcnt_2017
into LTV_Member_Month_2017_Pilot
from wkg_results2_2017_Pilot		as a
join CPI_Adjustment_sg2016			as b	on a.Year_Mo = b.Year_Mo
-- 2,400,108
go
create clustered index cixSavvyHICN_Year_Mo on LTV_Member_Month_2017_Pilot(SavvyHICN, Year_Mo)
go

