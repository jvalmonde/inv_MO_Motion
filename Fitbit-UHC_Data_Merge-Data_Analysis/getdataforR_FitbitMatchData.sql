/****** Script for SelectTopNRows command from SSMS  ******/
SELECT count(*), count(distinct [Indv_Sys_Id]), count(distinct [HashedEmail]), count(distinct EmailAddress), count(distinct LowerEmailAddress)
  FROM [pdb_UHCEmails_DS].[dbo].[DistinctEmails]
--18348890	16904419	17046696	17046730	17046730

select 
	InDimCS				=	case when c.CUST_SEG_SYS_ID is not null then 1 else 0 end, 
	Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd,
	MbrCnt				=	count(*), 
	Age					=	AVG(1. * Age), 
	PctFemale			=	AVG(1. * isFemale),
	HaveEmail			=	AVG(1. * isEmail),
	HaveFitbit			=	AVG(1. * isFitbit), 
	AvgIPHAdmit			=	avg(1. * Admit_Cnt_IPH), 
	AvgERVisit			=	avg(1. * ERVisits),
	PMPM				=	AVG(1. * TotalAllw / 12), 
	PMPM_Med			=	AVG(1. * (Total_Ip + Total_Op + Total_Dr + Total_Er) / 12), 
	PMPM_Rx				=	AVG(1. * Total_Rx / 12), 
	Charlson			=	AVG(1. * Charlson_Var),
	Diabetes			=	AVG(1. * Diabetes),
	Hypertension		=	AVG(1. * Hypertension),
	Depression			=	AVG(1. * Depression)
from Member_Continuous_2017_HPDM_Summary						a
	left join MiniHPDM.dbo.Dim_Customer_Segment					c	on	a.Cust_Seg_Sys_Id		=	c.CUST_SEG_SYS_ID
group by Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd, case when c.CUST_SEG_SYS_ID is not null then 1 else 0 end

--find top 10 customer segments for each company/funding
select 
	*
from 
	(select		
		c.CUST_SEG_NM,
		Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd,
		MbrCnt				=	count(*), 
		Age					=	AVG(1. * Age), 
		PctFemale			=	AVG(1. * isFemale),
		HaveEmail			=	AVG(1. * isEmail),
		HaveFitbit			=	AVG(1. * isFitbit), 
		AvgIPHAdmit			=	avg(1. * Admit_Cnt_IPH), 
		AvgERVisit			=	avg(1. * ERVisits),
		PMPM				=	AVG(1. * TotalAllw / 12), 
		PMPM_Med			=	AVG(1. * (Total_Ip + Total_Op + Total_Dr + Total_Er) / 12), 
		PMPM_Rx				=	AVG(1. * Total_Rx / 12), 
		Charlson			=	AVG(1. * Charlson_Var),
		Diabetes			=	AVG(1. * Diabetes),
		Hypertension		=	AVG(1. * Hypertension),
		Depression			=	AVG(1. * Depression),
		Rnk = row_number() over (partition by a.Co_Id_Rllp, a.Co_Nm, a.Hlth_Pln_Fund_Cd order by count(*) desc)
	from Member_Continuous_2017_HPDM_Summary						a
		left join MiniHPDM.dbo.Dim_Customer_Segment					c	on	a.Cust_Seg_Sys_Id		=	c.CUST_SEG_SYS_ID
		left join MiniHPDM.dbo.Dim_Group_Indicator					g	on	c.MKT_SEG_CD			=	g.MKT_SEG_CD
	group by c.CUST_SEG_NM, Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd
	) a
where Rnk <= 10
order by Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd, Rnk

--Now, find the same things by market segment
	select 
		InDimCS				=	case when c.CUST_SEG_SYS_ID is not null then 1 else 0 end, 
		Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd,
		Segment				=	g.MKT_SEG_RLLP_DESC,
		MbrCnt				=	count(*), 
		Age					=	AVG(1. * Age), 
		PctFemale			=	AVG(1. * isFemale),
		HaveEmail			=	AVG(1. * isEmail),
		HaveFitbit			=	AVG(1. * isFitbit), 
		AvgIPHAdmit			=	avg(1. * Admit_Cnt_IPH), 
		AvgERVisit			=	avg(1. * ERVisits),
		PMPM				=	AVG(1. * TotalAllw / 12), 
		PMPM_Med			=	AVG(1. * (Total_Ip + Total_Op + Total_Dr + Total_Er) / 12), 
		PMPM_Rx				=	AVG(1. * Total_Rx / 12), 
		Charlson			=	AVG(1. * Charlson_Var),
		Diabetes			=	AVG(1. * Diabetes),
		Hypertension		=	AVG(1. * Hypertension),
		Depression			=	AVG(1. * Depression)
	from Member_Continuous_2017_HPDM_Summary						a
		left join MiniHPDM.dbo.Dim_Customer_Segment					c	on	a.Cust_Seg_Sys_Id		=	c.CUST_SEG_SYS_ID
		left join MiniHPDM.dbo.Dim_Group_Indicator					g	on	c.MKT_SEG_CD			=	g.MKT_SEG_CD
	group by Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd, case when c.CUST_SEG_SYS_ID is not null then 1 else 0 end, g.MKT_SEG_RLLP_DESC

	--find top 10 customer segments for each company/funding
	select 
		*
	from 
		(select		
			Rnk = row_number() over (partition by a.Co_Id_Rllp, a.Co_Nm, a.Hlth_Pln_Fund_Cd, g.MKT_SEG_RLLP_DESC order by count(*) desc),
			c.CUST_SEG_NM,
			Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd,
			Segment				=	g.MKT_SEG_RLLP_DESC,
			MbrCnt				=	count(*), 
			Age					=	AVG(1. * Age), 
			PctFemale			=	AVG(1. * isFemale),
			HaveEmail			=	AVG(1. * isEmail),
			HaveFitbit			=	AVG(1. * isFitbit), 
			AvgIPHAdmit			=	avg(1. * Admit_Cnt_IPH), 
			AvgERVisit			=	avg(1. * ERVisits),
			PMPM				=	AVG(1. * TotalAllw / 12), 
			PMPM_Med			=	AVG(1. * (Total_Ip + Total_Op + Total_Dr + Total_Er) / 12), 
			PMPM_Rx				=	AVG(1. * Total_Rx / 12), 
			Charlson			=	AVG(1. * Charlson_Var),
			Diabetes			=	AVG(1. * Diabetes),
			Hypertension		=	AVG(1. * Hypertension),
			Depression			=	AVG(1. * Depression)
		from Member_Continuous_2017_HPDM_Summary						a
			left join MiniHPDM.dbo.Dim_Customer_Segment					c	on	a.Cust_Seg_Sys_Id		=	c.CUST_SEG_SYS_ID
			left join MiniHPDM.dbo.Dim_Group_Indicator					g	on	c.MKT_SEG_CD			=	g.MKT_SEG_CD
		group by c.CUST_SEG_NM, Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd, g.MKT_SEG_RLLP_DESC
		) a
	where Rnk <= 10
	order by Co_Id_Rllp, Co_Nm, Hlth_Pln_Fund_Cd, Segment, Rnk


--give Dave some results for Motion Groups. Overall, their impact seems small so we won't take this into account in my analysis.
select * from 
	(select top 15 WhatItIs = 'Motion Groups',
		Co_Id_Rllp, Hlth_Pln_Fund_Cd, CUST_SEG_NM, 
		CntMbr = count(*), 
		isMotionGroup = avg(1. * isMotionGroup), 
		isFitbit = avg(1. * isFitbit)
	from Member_Continuous_2017_HPDM_Summary
	where isMotionGroup = 1
	group by Co_Id_Rllp, Hlth_Pln_Fund_Cd, CUST_SEG_NM
	order by CntMbr desc
	) k
union all
select * from 
	(select top 15 WhatItIs = 'Overall UHC-FI groups',
		Co_Id_Rllp, Hlth_Pln_Fund_Cd, CUST_SEG_NM, 
		CntMbr = count(*), 
		isMotionGroup = avg(1. * isMotionGroup), 
		isFitbit = avg(1. * isFitbit)
	from Member_Continuous_2017_HPDM_Summary
	where Insurance = 'FI'
	group by Co_Id_Rllp, Hlth_Pln_Fund_Cd, CUST_SEG_NM
	order by CntMbr desc
	) k
union all
select * from 
	(select TOP 15 WhatItIs = 'Members with Fitbits',
		Co_Id_Rllp, Hlth_Pln_Fund_Cd, CUST_SEG_NM = '-TOTAL-', 
		CntMbr = count(*), 
		isMotionGroup = avg(1. * isMotionGroup), 
		isFitbit = avg(1. * isFitbit)
	from Member_Continuous_2017_HPDM_Summary
	where isFitbit = 1
	group by Co_Id_Rllp, Hlth_Pln_Fund_Cd
	order by CntMbr desc
	) k





select Insurance, HaveEmail, Gdr_Cd, 
	MemberCnt			=	count(*),
	MemberCnt_18_44		=	count(case when Age between 18 and 44 then Indv_Sys_Id end), 
	MemberCnt_45_64		=	count(case when Age between 45 and 64 then Indv_Sys_Id end), 
	MemberCnt_65plus	=	count(case when Age >= 65 then Indv_Sys_Id end)
from Member_Continuous_2017_HPDM_Summary
--where Indv_Sys_Id % 10000000 = 123
group by Insurance, isEmail, Gdr_Cd

select Insurance, HaveEmail = case when isEmail = 1 then 'Yes' else 'No' end, Gdr_Cd, AgeBand, 
	MemberCnt			=	count(*),
	TotalAllw			=	avg(1. * TotalAllw),
	Total_Ip			=	avg(1. * Total_Ip),
	Total_Op			=	avg(1. * Total_Op),
	Total_Dr			=	avg(1. * Total_Dr),
	Total_Rx			=	avg(1. * Total_Rx),
	Total_Er			=	avg(1. * Total_Er),
	ERv				=	avg(1. * ERVisits),
	Total_Er			=	avg(1. * Total_Er)
from Member_Continuous_2017_HPDM_Summary
--where Indv_Sys_Id % 10000000 = 123
group by Insurance, isEmail, Gdr_Cd, AgeBand


IF object_id('tempdb..#FitbitMasterStats','U') IS NOT NULL
	DROP TABLE #FitbitMasterStats;
select 
	Insurance, HaveEmail, HaveFitbit, Gdr_Cd, AgeBand, 
	MbrCnt				=	count(*),
	Age					=	avg(1. * Age), 
	Female				=	avg(1. * isFemale),
	HasEmail			=	avg(1. * isEmail),
	HasFitbit			=	avg(1. * isFitbit),
	[IP Admit]			=	avg(1. * Admit_Cnt_IPH), 
	[ER Visit]			=	avg(1. * ERVisits),
	PMPM				=	avg(1. * TotalAllw / 12), 
	Med					=	avg(1. * (Total_Ip + Total_Op + Total_Dr + Total_Er) / 12), 
	Ip					=	avg(1. * Total_Ip / 12		),
	Op					=	avg(1. * Total_Op / 12		),
	Dr					=	avg(1. * Total_Dr / 12		),
	Er					=	avg(1. * Total_Er / 12		),
	Rx					=	avg(1. * Total_Rx / 12		),
	Charlson			=	avg(1. * Charlson_Var		),
	AIDS_HIV			=	avg(1. * AIDS_HIV			),
	AMI					=	avg(1. * AMI				),
	Angina				=	avg(1. * Angina				),
	Cancer				=	avg(1. * Cancer				),
	CEVD				=	avg(1. * CEVD				),
	CHF					=	avg(1. * CHF				),
	COPD				=	avg(1. * COPD				),
	Dementia			=	avg(1. * Dementia			),
	Diabetes			=	avg(1. * Diabetes			),
	HTN					=	avg(1. * Hypertension		),
	Liver				=	avg(1. * Liver				),
	Paralysis			=	avg(1. * Paralysis			),
	PVD					=	avg(1. * PVD				),
	Renal_Failure		=	avg(1. * Renal_Failure		),
	Rheumatic			=	avg(1. * Rheumatic			),
	Ulcers				=	avg(1. * Ulcers				),
	Depression			=	avg(1. * Depression			),
	Skin				=	avg(1. * Skin				)
into #FitbitMasterStats
from Member_Continuous_2017_HPDM_Summary
where Insurance in ('UHC-FI', 'Uni-ASO')
group by grouping sets (
	(Insurance, HaveEmail, HaveFitbit, Gdr_Cd, AgeBand),
	(Insurance, HaveEmail, Gdr_Cd, AgeBand),
	(Insurance, HaveEmail, HaveFitbit, Gdr_Cd),
	(Insurance, HaveEmail, HaveFitbit, AgeBand),
	(Insurance, HaveEmail, HaveFitbit),
	(Insurance, HaveEmail, Gdr_Cd),
	(Insurance, HaveEmail, AgeBand),
	(Insurance, HaveEmail),
	(Insurance, Gdr_Cd),
	(Insurance, AgeBand),
	(HaveEmail, HaveFitbit, Gdr_Cd, AgeBand),
	(HaveEmail, Gdr_Cd, AgeBand),
	(HaveEmail, HaveFitbit, AgeBand),
	(HaveEmail, HaveFitbit, Gdr_Cd),
	(HaveEmail, HaveFitbit),
	(HaveEmail, Gdr_Cd),
	(HaveEmail, AgeBand),
	(Gdr_Cd, AgeBand),
	(Insurance),
	(HaveEmail),
	(HaveFitbit),
	(Gdr_Cd),
	(AgeBand), 
	()
	)

select 
	Insurance, HaveEmail, Gdr_Cd, AgeBand, 
	MemberCnt			=	count(*)
from Member_Continuous_2017_HPDM_Summary
where Insurance <> 'Other'
group by grouping sets (
	(Insurance, HaveEmail, Gdr_Cd, AgeBand)
	)

select 
	Insurance,
	HaveEmail,
	Gdr_Cd,
	CostCategory,
	CostCategoryRank =	case CostCategory 
							when 'Inpatient' then 1 
							when 'Outpatient' then 2
							when 'Physician' then 3
							when 'Pharmacy' then 4
							when 'ER' then 5
						end,
	AllwAmt
from 
	(
	select Insurance, HaveEmail, Gdr_Cd, --AgeBand, 
		Inpatient					=	avg(1. * Total_Ip / 12),
		Outpatient					=	avg(1. * Total_Op / 12),
		Physician					=	avg(1. * Total_Dr / 12),
		Pharmacy					=	avg(1. * Total_Rx / 12),
		ER							=	avg(1. * Total_Er / 12)
	from Member_Continuous_2017_HPDM_Summary
	group by Insurance, HaveEmail, Gdr_Cd--, AgeBand
	)		a
	unpivot (AllwAmt for CostCategory in (Inpatient, Outpatient, Physician, Pharmacy, ER)) unpvt

--total
select *
from #FitbitMasterStats

--only types I want



select *
from 
	(select 
		Insurance,
		HaveEmail,
		--HaveFitbit,
		--Gdr_Cd,
		--AgeBand,
		MbrCnt			,
		AIDS_HIV		,
		AMI				,
		Angina			,
		Cancer			,
		CEVD			,
		CHF				,
		COPD			,
		Dementia		,
		Diabetes		,
		HTN	,
		Liver			,
		Paralysis		,
		PVD				,
		Renal_Failure	,
		Rheumatic		,
		Ulcers			,
		Depression		,
		Skin			
	from
		#FitbitMasterStats		
	where
		Gdr_Cd is null
		and HaveFitbit is null
		and AgeBand is null
		and Insurance is not null
		and HaveEmail is not null
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt

--By Insurance
select * from 
	(select Insurance, HaveFitbit,	
			MbrCnt, AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin
	from #FitbitMasterStats		
	where
		Gdr_Cd is null
		and HaveFitbit is not null
		and AgeBand is null
		and Insurance is not null
		and HaveEmail = 'Yes'
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt

--By Gender
select * from 
	(select Gdr_Cd,	
			MbrCnt, AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin
	from #FitbitMasterStats		
	where
		Gdr_Cd is not null
		and HaveFitbit is null
		and AgeBand is null
		and Insurance is null
		and HaveEmail = 'Yes'
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt

--By AgeBand
select * from 
	(select AgeBand,	
			MbrCnt, AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin
	from #FitbitMasterStats		
	where
		Gdr_Cd is null
		and HaveFitbit is null
		and AgeBand is not null
		and Insurance is null
		and HaveEmail = 'Yes'
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt



select Insurance, HaveEmail, MemberCnt, Age, Female = PctFemale, IPH, ER, PMPM, PMPM_Med, PMPM_Rx, Charlson
from #FitbitMasterStats
where coalesce(gdr_cd, havefitbit, ageband) is null and insurance + haveemail is not null
order by Insurance, Haveemail


select * 
from Member_Continuous_2017_HPDM_Summary
where Insurance = 'Uni-ASO'

select 
	CUST_SEG_NM, 
	MemberCnt			=	count(*), 
	MemberShr			=	2. * count(*) / sum(count(*)) over(),
	Age					=	avg(1. * Age), 
	PctFemale			=	avg(1. * isFemale),
	PctEmail			=	avg(1. * isEmail),
	PctFitbit			=	avg(1. * isFitbit),
	IPH					=	avg(1. * Admit_Cnt_IPH), 
	ER					=	avg(1. * ERVisits),
	PMPM				=	avg(1. * TotalAllw / 12), 
	PMPM_Med			=	avg(1. * (Total_Ip + Total_Op + Total_Dr + Total_Er) / 12), 
	PMPM_Ip				=	avg(1. * Total_Ip / 12		),
	PMPM_Op				=	avg(1. * Total_Op / 12		),
	PMPM_Dr				=	avg(1. * Total_Dr / 12		),
	PMPM_Er				=	avg(1. * Total_Er / 12		),
	PMPM_Rx				=	avg(1. * Total_Rx / 12		),
	Charlson			=	avg(1. * Charlson_Var		),
	AIDS_HIV			=	avg(1. * AIDS_HIV			),
	AMI					=	avg(1. * AMI				),
	Angina				=	avg(1. * Angina				),
	Cancer				=	avg(1. * Cancer				),
	CEVD				=	avg(1. * CEVD				),
	CHF					=	avg(1. * CHF				),
	COPD				=	avg(1. * COPD				),
	Dementia			=	avg(1. * Dementia			),
	Diabetes			=	avg(1. * Diabetes			),
	Hypertension		=	avg(1. * Hypertension		),
	Liver				=	avg(1. * Liver				),
	Paralysis			=	avg(1. * Paralysis			),
	PVD					=	avg(1. * PVD				),
	Renal_Failure		=	avg(1. * Renal_Failure		),
	Rheumatic			=	avg(1. * Rheumatic			),
	Ulcers				=	avg(1. * Ulcers				),
	Depression			=	avg(1. * Depression			),
	Skin				=	avg(1. * Skin				)
from Member_Continuous_2017_HPDM_Summary
where Insurance in ('Uni-ASO')
group by CUST_SEG_NM with rollup
order by MemberCnt desc


select *
from 
	(select 
		Insurance,
		HaveEmail,
		MemberCnt				=	count(*),
		AIDS_HIV				=	avg(1. * AIDS_HIV			),
		AMI						=	avg(1. * AMI				),
		Angina					=	avg(1. * Angina				),
		Cancer					=	avg(1. * Cancer				),
		CEVD					=	avg(1. * CEVD				),
		CHF						=	avg(1. * CHF				),
		COPD					=	avg(1. * COPD				),
		Dementia				=	avg(1. * Dementia			),
		Diabetes				=	avg(1. * Diabetes			),
		Hypertension			=	avg(1. * Hypertension		),
		Liver					=	avg(1. * Liver				),
		Paralysis				=	avg(1. * Paralysis			),
		PVD						=	avg(1. * PVD				),
		Renal_Failure			=	avg(1. * Renal_Failure		),
		Rheumatic				=	avg(1. * Rheumatic			),
		Ulcers					=	avg(1. * Ulcers				),
		Depression				=	avg(1. * Depression			),
		Skin					=	avg(1. * Skin				)
	from
		Member_Continuous_2017_HPDM_Summary		
	group by 
		Insurance,
		HaveEmail
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, Hypertension, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt

--By Insurance

select *
from 
	(select 
		Insurance,
		HaveEmail,
		MemberCnt				=	count(*),
		AIDS_HIV				=	avg(1. * AIDS_HIV			),
		AMI						=	avg(1. * AMI				),
		Angina					=	avg(1. * Angina				),
		Cancer					=	avg(1. * Cancer				),
		CEVD					=	avg(1. * CEVD				),
		CHF						=	avg(1. * CHF				),
		COPD					=	avg(1. * COPD				),
		Dementia				=	avg(1. * Dementia			),
		Diabetes				=	avg(1. * Diabetes			),
		Hypertension			=	avg(1. * Hypertension		),
		Liver					=	avg(1. * Liver				),
		Paralysis				=	avg(1. * Paralysis			),
		PVD						=	avg(1. * PVD				),
		Renal_Failure			=	avg(1. * Renal_Failure		),
		Rheumatic				=	avg(1. * Rheumatic			),
		Ulcers					=	avg(1. * Ulcers				),
		Depression				=	avg(1. * Depression			),
		Skin					=	avg(1. * Skin				)
	from
		Member_Continuous_2017_HPDM_Summary		
	group by 
		Insurance,
		HaveEmail
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, Hypertension, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt


select *
from 
	(select 
		--Gdr_Cd,
		HaveEmail,
		AIDS_HIV				=	avg(1. * AIDS_HIV			),
		AMI						=	avg(1. * AMI				),
		Angina					=	avg(1. * Angina				),
		Cancer					=	avg(1. * Cancer				),
		CEVD					=	avg(1. * CEVD				),
		CHF						=	avg(1. * CHF				),
		COPD					=	avg(1. * COPD				),
		Dementia				=	avg(1. * Dementia			),
		Diabetes				=	avg(1. * Diabetes			),
		Hypertension			=	avg(1. * Hypertension		),
		Liver					=	avg(1. * Liver				),
		Paralysis				=	avg(1. * Paralysis			),
		PVD						=	avg(1. * PVD				),
		Renal_Failure			=	avg(1. * Renal_Failure		),
		Rheumatic				=	avg(1. * Rheumatic			),
		Ulcers					=	avg(1. * Ulcers				),
		Depression				=	avg(1. * Depression			),
		Skin					=	avg(1. * Skin				)
	from
		Member_Continuous_2017_HPDM_Summary		
	group by 
		--Gdr_Cd,
		HaveEmail
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, Hypertension, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt


select Insurance, HaveEmail, Gdr_Cd, AgeBand, HaveFitbit, 
	MemberCnt			=	count(*),
	AllwAmt				=	avg(1. * TotalAllw / 12),
	ERv					=	avg(1. * ERVisits),
	IPHAdmit			=	avg(1. * Admit_Cnt_IPH)
from Member_Continuous_2017_HPDM_Summary
where isEmail = 1
group by Insurance, HaveEmail, Gdr_Cd, AgeBand, HaveFitbit

select Insurance, HaveEmail, Gdr_Cd, AgeBand, HaveFitbit, 
	MemberCnt			=	count(*),
	AllwAmt				=	avg(1. * TotalAllw / 12),
	ERv					=	avg(1. * ERVisits),
	IPHAdmit			=	avg(1. * Admit_Cnt_IPH)
from Member_Continuous_2017_HPDM_Summary
where isEmail = 1
group by grouping sets (
	(Insurance, HaveEmail, Gdr_Cd, AgeBand, HaveFitbit),
	(Insurance, HaveEmail, Gdr_Cd, HaveFitbit)
	)

select *
from #FitbitMasterStats

select *
from #FitbitMasterStats
where HasEmail = 1
