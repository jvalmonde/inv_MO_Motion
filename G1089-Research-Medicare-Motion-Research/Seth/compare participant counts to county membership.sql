use pdb_WalkandWin
go

--explore market share vs participant by county
--select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME like 'COUNTY%' or COLUMN_NAME like '%FIPS%'

--LTV_Member_Demographics_2017_Pilot
--LTV_Member_Demographics_2016_Pilot

--select 
--	a.StateAbbr,
--	a.CountyName,
--	a.FIPSCode,
--	a.YearNbr,
--	United	= sum(case when b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
--	Other	= sum(case when b.ParentOrg <> 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
--	UnitedShr	= 1. * sum(case when b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end) / sum(sum(a.Enrollment)) over(partition by a.StateAbbr, a.CountyName, a.YearNbr)
--from StateCountyContractPlanEnrollment_CMS	a
--	join StateCountyContractPlanInfo_CMS	b	on	a.YearMo			=	b.YearMo
--													and a.ContractNbr	=	b.ContractNbr
--													and a.PlanID		=	b.PlanID
--where a.StateAbbr = 'IN' 
--group by 
--	a.StateAbbr,
--	a.CountyName,
--	a.FIPSCode,
--	a.YearNbr
select 
	StateAbbr, CountyName,
	WhichOne					=	case when CtyMbrs_2016_New > CtyMbrs_2017_New then 2016						else 2017					end, 
	Original					=	case when CtyMbrs_2016_New > CtyMbrs_2017_New then CtyMbrs_2016_Original	else CtyMbrs_2017_Original	end, 
	New							=	case when CtyMbrs_2016_New > CtyMbrs_2017_New then CtyMbrs_2016_New			else CtyMbrs_2017_New		end, 
	United						=	case when CtyMbrs_2016_New > CtyMbrs_2017_New then United_16				else United_17				end, 
	Shr							=	case when CtyMbrs_2016_New > CtyMbrs_2017_New then UnitedShr_16				else UnitedShr_17			end,
	ParticipantShrOfCounty		=	1. * case when CtyMbrs_2016_New > CtyMbrs_2017_New then CtyMbrs_2016_Original	else CtyMbrs_2017_Original	end / case when CtyMbrs_2016_New > CtyMbrs_2017_New then United_16				else United_17				end 
from 
(select 
	a.StateAbbr,
	a.CountyName,
	a.FIPSCode,
	CtyMbrs_2016_Original,
	CtyMbrs_2016_New,
	CtyMbrs_2017_Original,
	CtyMbrs_2017_New,

	United_14				=	sum(case when		a.YearNbr = 2014 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	Other_14				=	sum(case when		a.YearNbr = 2014 and b.ParentOrg <> 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	UnitedShr_14			=	1. * sum(case when	a.YearNbr = 2014 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end) / sum(sum(case when	a.YearNbr = 2014 then a.Enrollment else 0 end)) over(partition by a.StateAbbr, a.CountyName),

	United_15				=	sum(case when		a.YearNbr = 2015 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	Other_15				=	sum(case when		a.YearNbr = 2015 and b.ParentOrg <> 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	UnitedShr_15			=	1. * sum(case when	a.YearNbr = 2015 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end) / sum(sum(case when	a.YearNbr = 2015 then a.Enrollment else 0 end)) over(partition by a.StateAbbr, a.CountyName),

	United_16				=	sum(case when		a.YearNbr = 2016 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	Other_16				=	sum(case when		a.YearNbr = 2016 and b.ParentOrg <> 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	UnitedShr_16			=	1. * sum(case when	a.YearNbr = 2016 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end) / sum(sum(case when	a.YearNbr = 2016 then a.Enrollment else 0 end)) over(partition by a.StateAbbr, a.CountyName),

	United_17				=	sum(case when		a.YearNbr = 2017 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	Other_17				=	sum(case when		a.YearNbr = 2017 and b.ParentOrg <> 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	UnitedShr_17			=	1. * sum(case when	a.YearNbr = 2017 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end) / sum(sum(case when	a.YearNbr = 2017 then a.Enrollment else 0 end)) over(partition by a.StateAbbr, a.CountyName),

	United_18				=	sum(case when		a.YearNbr = 2018 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	Other_18				=	sum(case when		a.YearNbr = 2018 and b.ParentOrg <> 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end),
	UnitedShr_18			=	1. * sum(case when	a.YearNbr = 2018 and b.ParentOrg = 'UnitedHealth Group, Inc.' then a.Enrollment else 0 end) / sum(sum(case when	a.YearNbr = 2018 then a.Enrollment else 0 end)) over(partition by a.StateAbbr, a.CountyName)
from 
	StateCountyContractPlanEnrollment_CMS	a
	join StateCountyContractPlanInfo_CMS	b	on	a.YearMo			=	b.YearMo
													and a.ContractNbr	=	b.ContractNbr
													and a.PlanID		=	b.PlanID
													and b.PlanType		<>	'Medicare Prescription Drug Plan'
	join (
		select FIPS, count(*) CtyMbrs_2017_Original
		from LTV_Member_Demographics_ORIGINAL
		group by FIPS
		)									c	on	a.FIPSCode			=	c.FIPS
	join (
		select FIPS, count(*) CtyMbrs_2017_New
		from LTV_Member_Demographics_2017_Pilot
		group by FIPS
		)									d	on	a.FIPSCode			=	d.FIPS
	join (
		select FIPS, count(*) CtyMbrs_2016_New
		from LTV_Member_Demographics_2016_Pilot 
		group by FIPS
		)									e	on	a.FIPSCode			=	e.FIPS
	join (
		select FIPS, count(*) CtyMbrs_2016_Original
		from LTV_Member_Demographics_2016_Pilot_ORIGINAL
		group by FIPS
		)									f	on	a.FIPSCode			=	f.FIPS
--where a.StateAbbr = 'IN' 
group by 
	a.StateAbbr,
	a.CountyName,
	a.FIPSCode,
	CtyMbrs_2016_Original,
	CtyMbrs_2016_New,
	CtyMbrs_2017_Original,
	CtyMbrs_2017_New
--having 
--	CtyMbrs_2016_Original + CtyMbrs_2016_New + CtyMbrs_2017_Original + CtyMbrs_2017_New > 100
) k
where .01 <= /* ParticipantShrOfCounty: */ 1. * case when CtyMbrs_2016_New > CtyMbrs_2017_New then CtyMbrs_2016_Original else CtyMbrs_2017_Original end / case when CtyMbrs_2016_New > CtyMbrs_2017_New then United_16 else United_17 end 
order by 
	ParticipantShrOfCounty desc


/*
select 'With Medicare Prescription Drug Plan', PlanType, 
	sum(case when ParentOrg = 'UnitedHealth Group, Inc.' then Enrollment else 0 end) UnitedEnrollment, 
	sum(Enrollment) TotalEnrollment, 
	1. * sum(case when ParentOrg = 'UnitedHealth Group, Inc.' then Enrollment else 0 end) / sum(Enrollment) UnitedShr,
	PlanTypeShareOfTotal = 2. * sum(Enrollment) / sum(sum(Enrollment)) over()
from StateCountyContractPlanInfo_CMS		a
	join StateCountyContractPlanEnrollment_CMS		b on a.ContractNbr = b.ContractNbr and a.PlanID = b.PlanID and a.YearMo = 201701
group by PlanType with rollup
order by TotalEnrollment desc
	
select 'Without Medicare Prescription Drug Plan', PlanType, 
	sum(case when ParentOrg = 'UnitedHealth Group, Inc.' then Enrollment else 0 end) UnitedEnrollment, 
	sum(Enrollment) TotalEnrollment, 
	1. * sum(case when ParentOrg = 'UnitedHealth Group, Inc.' then Enrollment else 0 end) / sum(Enrollment) UnitedShr,
	PlanTypeShareOfTotal = 2. * sum(Enrollment) / sum(sum(Enrollment)) over()
from StateCountyContractPlanInfo_CMS		a
	join StateCountyContractPlanEnrollment_CMS		b on a.ContractNbr = b.ContractNbr and a.PlanID = b.PlanID and a.YearMo = 201701 and PlanType <> 'Medicare Prescription Drug Plan'
group by PlanType with rollup
order by TotalEnrollment desc
	
	select *
	from StateCountyContractPlanInfo_CMS
*/
