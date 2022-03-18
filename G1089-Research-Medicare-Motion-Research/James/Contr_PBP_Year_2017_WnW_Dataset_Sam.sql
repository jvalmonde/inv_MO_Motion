select Contr_Nbr, PBP, left(Year_Mo, 4) as Plan_Year, count(distinct SavvyHICN) as Mbr_Cnt
into #contr
from pdb_WalkandWin..LTV_Member_Month_2016_Pilot
group by Contr_Nbr, PBP, left(Year_Mo, 4)
--1102



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
--1102




select a.Contr_Nbr, a.PBP, a.Plan_Year, b.Premium_C_Amt, b.Premium_D_Amt
into #contr_premium
from #contr		as a 
left join(
	select Contr_Nbr, PBP, Plan_Year, 
		   avg(Premium_C) as Premium_C_Amt,
		   avg(Premium_D) as Premium_D_Amt
	from LTV..CMS_Plan_Benefits_CD_Premiums
	group by Contr_Nbr, PBP, Plan_Year
	) as b	on a.Contr_Nbr = b.Contr_Nbr and a.PBP = b.PBP and a.Plan_Year = b.Plan_Year
--1102
-- drop table pdb_WalkandWin..Contr_PBP_Year_2016_Pilot
select a.Contr_Nbr, a.PBP, cast(a.Plan_Year as int) as Plan_Year, a.Mbr_Cnt,
	   b.Brand, b.PBPDescription as Plan_Desc, b.Product, b.SubProduct, b.ContractType, b.Derived_Product,
	   c.Premium_C_Amt, c.Premium_D_Amt
into pdb_WalkandWin..Contr_PBP_Year_2016_Pilot
from #contr			as a 
join #contr_details	as b	on a.Contr_Nbr = b.Contr_Nbr and a.PBP = b.PBP and a.Plan_Year = b.Plan_Year
join #contr_premium	as c	on a.Contr_Nbr = c.Contr_Nbr and a.PBP = c.PBP and a.Plan_Year = c.Plan_Year
--1102



create unique index ix_contr_pbp_yr on pdb_WalkandWin..Contr_PBP_Year_2016_Pilot(Contr_Nbr, PBP, Plan_Year)