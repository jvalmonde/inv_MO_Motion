/*
gather data to report on United members with Fitbits. 

Need to run analyzeFitbitMatchdata_final.sql first to prepare Member_Continuous_2017_HPDM_Summary.
*/

use pdb_UHCEmails
go

IF object_id('FitbitMasterStats_Total_Cube','U') IS NOT NULL
	DROP TABLE FitbitMasterStats_Total_Cube;
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
into FitbitMasterStats_Total_Cube
from Member_Continuous_2017_HPDM_Summary
group by CUBE(Insurance, HaveEmail, HaveFitbit, Gdr_Cd, AgeBand) 
go

IF object_id('FitbitMasterStats_ASO_FI_Cube','U') IS NOT NULL
	DROP TABLE FitbitMasterStats_ASO_FI_Cube;
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
into FitbitMasterStats_ASO_FI_Cube
from Member_Continuous_2017_HPDM_Summary
where Insurance <> 'Other'
group by CUBE(Insurance, HaveEmail, HaveFitbit, Gdr_Cd, AgeBand) 
go



--everything
select *
from FitbitMasterStats_Total_Cube

--only types I want
select *
from FitbitMasterStats_ASO_FI_Cube

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
		FitbitMasterStats_ASO_FI_Cube
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
	from FitbitMasterStats_ASO_FI_Cube		
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
	(select Gdr_Cd, HaveFitbit,	
			MbrCnt, AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin
	from FitbitMasterStats_ASO_FI_Cube
	where
		Gdr_Cd is not null
		and HaveFitbit is not null
		and AgeBand is null
		and Insurance is null
		and HaveEmail = 'Yes'
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt

--By AgeBand
select * from 
	(select AgeBand, HaveFitbit, 	
			MbrCnt, AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin
	from FitbitMasterStats_ASO_FI_Cube
	where
		Gdr_Cd is null
		and HaveFitbit is not null
		and AgeBand is not null
		and Insurance is null
		and HaveEmail = 'Yes'
	) a
	unpivot (Rate for Condition in (AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, HTN, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression, Skin)) unpvt



