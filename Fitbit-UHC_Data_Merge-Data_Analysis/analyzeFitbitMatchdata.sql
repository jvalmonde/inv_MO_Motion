use pdb_UHCEmails
go

--1549341	Indv_Sys_Id on Fitbit Member List
--1546557 members in MiniHPDM, 750489	with 12 months in 2017 and 608616 with 12 months in 2016/2017
--28958 members in MiniOV (all of them also in MiniHPDM. Why? Something to do with having email addresses?) 19395	with 12 months in 2017 and 13129 with 12 months in 2016/2017

--Indv_Sys_Id_FB	Indv_Sys_Id_HPDM	Indv_Sys_Id_OV	SavvyID_OV	HPDM_2017	HPDM_2016_2017	OV_2017	HPDM_2016_2017
--1549341	1546557	29099	28958	750489	608616	19395	13129

IF object_id('MemberWithEmail','U') IS NOT NULL
	DROP TABLE MemberWithEmail;
select distinct Indv_Sys_Id
into MemberWithEmail
from pdb_UHCEmails_DS.dbo.DistinctEmails
go
create clustered index cixIndv_Sys_Id on MemberWithEmail(Indv_Sys_Id)
go


--let's start by identifying members with continuous, -unchanging- enrollment for 2017
IF object_id('dbo.Member_Continuous_2017_HPDM','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM;
select		
	a.Indv_Sys_Id, 
	a.Mbr_Sys_Id, 
	a.Cust_Seg_Sys_Id, 
	Insurance = case 
					when b.Co_Id_Rllp = 'UNITED HEALTHCARE' and b.Hlth_Pln_Fund_Cd = 'FI' then 'FI'
					when b.Co_Id_Rllp = 'UNIPRISE' and b.Hlth_Pln_Fund_Cd = 'ASO' then 'ASO'
					else 'Other' 
				end,
	b.Co_Nm, 
	b.Co_Id_Rllp,
	b.Hlth_Pln_Fund_Cd--,  
	--isEmail = case when c.Indv_Sys_Id is not null then 1 else 0 end, 
	--isFitbit = case when d.Indv_Sys_Id is not null then 1 else 0 end
into		dbo.Member_Continuous_2017_HPDM
from		MiniHPDM.dbo.Summary_Indv_Demographic				a
  left join MiniHPDM.dbo.Dim_CustSegSysId_Detail				b	on	a.Cust_Seg_Sys_Id		=	b.Cust_Seg_Sys_Id
																	and b.Year_Mo				=	'201712'
  --left join pdb_UHCEmails.dbo.MemberWithEmail					c	on	a.Indv_Sys_Id			=	c.Indv_Sys_Id
  --left join Fitbit_Match.dbo.Member_List						d	on	a.Indv_Sys_Id			=	d.Indv_Sys_Id
where		a.Year_Mo			like '2017%'
group by	a.Indv_Sys_Id, a.Mbr_Sys_Id, a.Cust_Seg_Sys_Id, b.Co_Nm, b.Co_Id_Rllp, b.Hlth_Pln_Fund_Cd--, c.Indv_Sys_Id, d.Indv_Sys_Id
having		count(distinct a.Year_Mo)  =	12
go
create clustered index cixIndv_Sys_Id on dbo.Member_Continuous_2017_HPDM(Indv_Sys_Id)
go

IF object_id('dbo.Member_Continuous_2017_HPDM_Include','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_Include;
select 
	a.Indv_Sys_Id,
	a.Cust_Seg_Sys_Id,
	a.Insurance,
	a.Co_Nm, 
	a.Co_Id_Rllp,
	a.Hlth_Pln_Fund_Cd,
	isEmail						=	case when c.Indv_Sys_Id is not null then 1 else 0 end,
	isFitbit					=	case when d.Indv_Sys_Id is not null then 1 else 0 end,
	isFemale					=	case when m.Gdr_Cd = 'F' then 1 else 0 end,
	m.Gdr_Cd,
	m.Age
into Member_Continuous_2017_HPDM_Include
from 
	Member_Continuous_2017_HPDM									a
	left join pdb_UHCEmails.dbo.MemberWithEmail					c	on	a.Indv_Sys_Id			=	c.Indv_Sys_Id
	left join Fitbit_Match.dbo.Member_List						d	on	a.Indv_Sys_Id			=	d.Indv_Sys_Id
	--left join MemberWithEmail									z	on	a.Indv_Sys_Id		=	z.Indv_Sys_Id
	join MiniHPDM_PHI.dbo.Dim_Member							mp	on	a.Indv_Sys_Id		=	mp.Indv_Sys_Id	--to restrict on birth date
	join MiniHPDM.dbo.Dim_Member								m	on	a.Indv_Sys_Id		=	m.Indv_Sys_Id	--to include age without needing to think through the calculation because it is late and I am tired
where 1=1
	--and a.Indv_Sys_Id % 10000			=	0
	--and a.Insurance						<>	'Other'
	and m.Gdr_Cd						<>	'U'
	and mp.Bth_dt						<=	'1998-12-31'
go
create clustered index cixIndv_Sys_Id on dbo.Member_Continuous_2017_HPDM_Include(Indv_Sys_Id)
go


IF object_id('dbo.Member_Continuous_2017_HPDM_CharlsonDiag','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_CharlsonDiag;
select distinct  mc.Indv_Sys_Id, cd.Chrnc_Cond_Nm, FULL_DATE = convert(date, dt.FULL_DT)
into Member_Continuous_2017_HPDM_CharlsonDiag
from dbo.Member_Continuous_2017_HPDM					mc
	join MiniHPDM.dbo.Fact_Claims						fc	on	mc.Indv_Sys_Id			=	fc.Indv_Sys_Id
	join MiniHPDM.dbo.Dim_Date							dt	on	fc.Dt_Sys_Id			=	dt.DT_SYS_ID
															and dt.YEAR_NBR				=	2017
	join MiniHPDM.dbo.Dim_Diagnosis_Code				dc1	on	fc.Diag_1_Cd_Sys_Id		=	dc1.DIAG_CD_SYS_ID
	join Charlson.dbo.[Charlson Codes List w ICD10]		cd	on	dc1.DIAG_CD				=	cd.ICD_CD 
															and cd.ICD_VER_CD			=	10
union --will be distinct 
select distinct  mc.Indv_Sys_Id, cd.Chrnc_Cond_Nm, FULL_DATE = convert(date, dt.FULL_DT)
from dbo.Member_Continuous_2017_HPDM					mc
	join MiniHPDM.dbo.Fact_Claims						fc	on	mc.Indv_Sys_Id			=	fc.Indv_Sys_Id
	join MiniHPDM.dbo.Dim_Date							dt	on	fc.Dt_Sys_Id			=	dt.DT_SYS_ID
															and dt.YEAR_NBR				=	2017
	join MiniHPDM.dbo.Dim_Diagnosis_Code				dc2	on	fc.Diag_2_Cd_Sys_Id		=	dc2.DIAG_CD_SYS_ID
	join Charlson.dbo.[Charlson Codes List w ICD10]		cd	on	dc2.DIAG_CD				=	cd.ICD_CD 
															and cd.ICD_VER_CD			=	10
union --will be distinct 
select distinct  mc.Indv_Sys_Id, cd.Chrnc_Cond_Nm, FULL_DATE = convert(date, dt.FULL_DT)
from dbo.Member_Continuous_2017_HPDM					mc
	join MiniHPDM.dbo.Fact_Claims						fc	on	mc.Indv_Sys_Id			=	fc.Indv_Sys_Id
	join MiniHPDM.dbo.Dim_Date							dt	on	fc.Dt_Sys_Id			=	dt.DT_SYS_ID
															and dt.YEAR_NBR				=	2017
	join MiniHPDM.dbo.Dim_Diagnosis_Code				dc3	on	fc.Diag_3_Cd_Sys_Id		=	dc3.DIAG_CD_SYS_ID
	join Charlson.dbo.[Charlson Codes List w ICD10]		cd	on	dc3.DIAG_CD				=	cd.ICD_CD 
															and cd.ICD_VER_CD			=	10
go
create clustered index cixIndv_Sys_Id_Chrnc_Cond_Nm on dbo.Member_Continuous_2017_HPDM_CharlsonDiag(Indv_Sys_Id, Chrnc_Cond_Nm)
go



IF object_id('dbo.Member_Continuous_2017_HPDM_Charlson','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_Charlson;
select 
	a.Indv_Sys_Id,
	Charlson_Var_1		= IsNull(Var_1,0),
	AIDS_HIV_1			= IsNull(AIDS_HIV_1,0),
	AMI_1				= IsNull(AMI_1,0),
	Angina_1			= IsNull(Angina_1,0),
	Cancer_1			= IsNull(Cancer_1,0),
	CEVD_1				= IsNull(CEVD_1,0),
	CHF_1				= IsNull(CHF_1,0),
	COPD_1				= IsNull(COPD_1,0),
	Dementia_1			= IsNull(Dementia_1,0),
	Diabetes_1			= IsNull(Diabetes_1,0),
	Hypertension_1		= IsNull(Hypertension_1,0),
	Liver_1				= IsNull(Liver_1,0),
	Paralysis_1			= IsNull(Paralysis_1,0),
	PVD_1				= IsNull(PVD_1,0),
	Renal_Failure_1		= IsNull(Renal_Failure_1,0),
	Rheumatic_1			= IsNull(Rheumatic_1,0),
	Ulcers_1			= IsNull(Ulcers_1,0),
	Depression_1		= IsNull(Depression_1,0),
	Skin_1				= IsNull(Skin_1,0),
	Charlson_Var_2		= IsNull(Var_2,0),
	AIDS_HIV_2			= IsNull(AIDS_HIV_2,0),
	AMI_2				= IsNull(AMI_2,0),
	Angina_2			= IsNull(Angina_2,0),
	Cancer_2			= IsNull(Cancer_2,0),
	CEVD_2				= IsNull(CEVD_2,0),
	CHF_2				= IsNull(CHF_2,0),
	COPD_2				= IsNull(COPD_2,0),
	Dementia_2			= IsNull(Dementia_2,0),
	Diabetes_2			= IsNull(Diabetes_2,0),
	Hypertension_2		= IsNull(Hypertension_2,0),
	Liver_2				= IsNull(Liver_2,0),
	Paralysis_2			= IsNull(Paralysis_2,0),
	PVD_2				= IsNull(PVD_2,0),
	Renal_Failure_2		= IsNull(Renal_Failure_2,0),
	Rheumatic_2			= IsNull(Rheumatic_2,0),
	Ulcers_2			= IsNull(Ulcers_2,0),
	Depression_2		= IsNull(Depression_2,0),
	Skin_2				= IsNull(Skin_2,0)
into dbo.Member_Continuous_2017_HPDM_Charlson
from 
	Member_Continuous_2017_HPDM a
	left join (
		select Indv_Sys_Id,
			-- Var_1 is calculated using weights defined by Elif and using the _1 CC flags (see _1 flag descriptions above)
			Var_1 = convert(decimal(9,1),AIDS_HIV_1)		* 6 +	
					convert(decimal(9,1),AMI_1)				* 1 +	
					convert(decimal(9,1),Angina_1)			* 0 +	
					convert(decimal(9,1),Cancer_1)			* 3 +	
					convert(decimal(9,1),CEVD_1)			* 1 +	
					convert(decimal(9,1),CHF_1)				* 1 +	
					convert(decimal(9,1),COPD_1)			* 1 +
					convert(decimal(9,1),Dementia_1)		* 1 +
					convert(decimal(9,1),Diabetes_1)		* 1.5 +
					convert(decimal(9,1),Hypertension_1)	* 1 +	
					convert(decimal(9,1),Liver_1)			* 2 +	
					convert(decimal(9,1),Paralysis_1)		* 2 +	
					convert(decimal(9,1),PVD_1)				* 1 +	
					convert(decimal(9,1),Renal_Failure_1)	* 2 +	
					convert(decimal(9,1),Rheumatic_1)		* 1 +
					convert(decimal(9,1),Ulcers_1)			* 1 +
					convert(decimal(9,1),Depression_1)		* 1 +
					convert(decimal(9,1),Skin_1)			* 2,
			AIDS_HIV_1,		
			AMI_1,			
			Angina_1,			
			Cancer_1,			
			CEVD_1,			
			CHF_1,			
			COPD_1,			
			Dementia_1,		
			Diabetes_1,		
			Hypertension_1,	
			Liver_1,			
			Paralysis_1,		
			PVD_1,			
			Renal_Failure_1,	
			Rheumatic_1,		
			Ulcers_1,			
			Depression_1,		
			Skin_1,
			-- Var_2 is calculated using weights defined by Elif and using the _2 CC flags (see _2 flag descriptions above)
			Var_2 = convert(decimal(9,1),AIDS_HIV_2)		* 6 +	
					convert(decimal(9,1),AMI_2)				* 1 +	
					convert(decimal(9,1),Angina_2)			* 0 +	
					convert(decimal(9,1),Cancer_2)			* 3 +	
					convert(decimal(9,1),CEVD_2)			* 1 +	
					convert(decimal(9,1),CHF_2)				* 1 +	
					convert(decimal(9,1),COPD_2)			* 1 +
					convert(decimal(9,1),Dementia_2)		* 1 +
					convert(decimal(9,1),Diabetes_2)		* 1.5 +
					convert(decimal(9,1),Hypertension_2)	* 1 +	
					convert(decimal(9,1),Liver_2)			* 2 +	
					convert(decimal(9,1),Paralysis_2)		* 2 +	
					convert(decimal(9,1),PVD_2)				* 1 +	
					convert(decimal(9,1),Renal_Failure_2)	* 2 +	
					convert(decimal(9,1),Rheumatic_2)		* 1 +
					convert(decimal(9,1),Ulcers_2)			* 1 +
					convert(decimal(9,1),Depression_2)		* 1 +
					convert(decimal(9,1),Skin_2)			* 2,
			AIDS_HIV_2,		
			AMI_2,			
			Angina_2,			
			Cancer_2,			
			CEVD_2,			
			CHF_2,			
			COPD_2,			
			Dementia_2,		
			Diabetes_2,		
			Hypertension_2,	
			Liver_2,			
			Paralysis_2,		
			PVD_2,			
			Renal_Failure_2,	
			Rheumatic_2,		
			Ulcers_2,			
			Depression_2,		
			Skin_2

		from(	
			select Indv_Sys_Id,
				   AIDS_HIV_1		= Max(Case When Chrnc_Cond_Nm = 'AIDS/HIV'		Then 1 Else 0 End),	
				   AMI_1			= Max(Case When Chrnc_Cond_Nm = 'AMI'			Then 1 Else 0 End),	
				   Angina_1			= Max(Case When Chrnc_Cond_Nm = 'Angina'		Then 1 Else 0 End), 
				   Cancer_1			= Max(Case When Chrnc_Cond_Nm = 'Cancer'		Then 1 Else 0 End), 
				   CEVD_1			= Max(Case When Chrnc_Cond_Nm = 'CEVD'			Then 1 Else 0 End), 
				   CHF_1			= Max(Case When Chrnc_Cond_Nm = 'CHF'			Then 1 Else 0 End), 
				   COPD_1			= Max(Case When Chrnc_Cond_Nm = 'COPD'			Then 1 Else 0 End), 
				   Dementia_1		= Max(Case When Chrnc_Cond_Nm = 'Dementia'		Then 1 Else 0 End),	
				   Diabetes_1		= Max(Case When Chrnc_Cond_Nm = 'Diabetes'		Then 1 Else 0 End),	
				   Hypertension_1	= Max(Case When Chrnc_Cond_Nm = 'Hypertension'	Then 1 Else 0 End), 
				   Liver_1			= Max(Case When Chrnc_Cond_Nm = 'Liver'			Then 1 Else 0 End),	
				   Paralysis_1		= Max(Case When Chrnc_Cond_Nm = 'Paralysis'		Then 1 Else 0 End),	
				   PVD_1			= Max(Case When Chrnc_Cond_Nm = 'PVD'			Then 1 Else 0 End),	
				   Renal_Failure_1	= Max(Case When Chrnc_Cond_Nm = 'Renal Failure'	Then 1 Else 0 End),	
				   Rheumatic_1		= Max(Case When Chrnc_Cond_Nm = 'Rheumatic'		Then 1 Else 0 End),	
				   Ulcers_1			= Max(Case When Chrnc_Cond_Nm = 'Ulcers'		Then 1 Else 0 End),	
				   Depression_1		= Max(Case When Chrnc_Cond_Nm = 'Depression'	Then 1 Else 0 End),	
				   Skin_1			= Max(Case When Chrnc_Cond_Nm = 'Skin'			Then 1 Else 0 End),
			   
				   AIDS_HIV_2		= Max(Case When Chrnc_Cond_Nm = 'AIDS/HIV'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   AMI_2			= Max(Case When Chrnc_Cond_Nm = 'AMI'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Angina_2			= Max(Case When Chrnc_Cond_Nm = 'Angina'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End), 
				   Cancer_2			= Max(Case When Chrnc_Cond_Nm = 'Cancer'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End), 
				   CEVD_2			= Max(Case When Chrnc_Cond_Nm = 'CEVD'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End), 
				   CHF_2			= Max(Case When Chrnc_Cond_Nm = 'CHF'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End), 
				   COPD_2			= Max(Case When Chrnc_Cond_Nm = 'COPD'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End), 
				   Dementia_2		= Max(Case When Chrnc_Cond_Nm = 'Dementia'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Diabetes_2		= Max(Case When Chrnc_Cond_Nm = 'Diabetes'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Hypertension_2	= Max(Case When Chrnc_Cond_Nm = 'Hypertension'	and Chrnc_Cond_Freq > 1	Then 1 Else 0 End), 
				   Liver_2			= Max(Case When Chrnc_Cond_Nm = 'Liver'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Paralysis_2		= Max(Case When Chrnc_Cond_Nm = 'Paralysis'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   PVD_2			= Max(Case When Chrnc_Cond_Nm = 'PVD'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Renal_Failure_2	= Max(Case When Chrnc_Cond_Nm = 'Renal Failure'	and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Rheumatic_2		= Max(Case When Chrnc_Cond_Nm = 'Rheumatic'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Ulcers_2			= Max(Case When Chrnc_Cond_Nm = 'Ulcers'		and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Depression_2		= Max(Case When Chrnc_Cond_Nm = 'Depression'	and Chrnc_Cond_Freq > 1	Then 1 Else 0 End),	
				   Skin_2			= Max(Case When Chrnc_Cond_Nm = 'Skin'			and Chrnc_Cond_Freq > 1	Then 1 Else 0 End)		
			from(
				select distinct Indv_Sys_Id, Chrnc_Cond_Nm, Chrnc_Cond_Freq = count(distinct FULL_DATE)
				from Member_Continuous_2017_HPDM_CharlsonDiag
				group by Indv_Sys_Id, Chrnc_Cond_Nm
				) sub2
			group By Indv_Sys_Id
			)sub3
		) b on a.Indv_Sys_Id = b.Indv_Sys_Id
go
create clustered index cixIndv_Sys_Id on dbo.Member_Continuous_2017_HPDM_Charlson(Indv_Sys_Id)
go

IF object_id('dbo.Member_Continuous_2017_HPDM_IpDate','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_IpDate;
select distinct
	m.Indv_Sys_Id,
	--AdmitDate										=	convert(date, dt.Full_Dt),
	--DischargeDate									=	DATEADD(DAY, fc.Day_Cnt, convert(date, dt.FULL_DT)),
	--fc.Day_Cnt,
	IpDate											=	convert(date, ip.Full_Dt)
into Member_Continuous_2017_HPDM_IpDate
from 
	Member_Continuous_2017_HPDM								m
	join MiniHPDM.dbo.Fact_Claims							fc	on	m.Indv_Sys_Id					=	fc.Indv_Sys_Id
	join MiniHPDM.dbo.Dim_Date								dt	on	fc.Dt_Sys_Id					=	dt.DT_SYS_ID
																and dt.YEAR_NBR						=	2017
	join MiniHPDM.dbo.Dim_Place_of_Service_Code				pos	on	fc.Pl_of_Srvc_Sys_Id			=	pos.PL_OF_SRVC_SYS_ID
	join MiniHPDM.dbo.Dim_Date								ip	on	ip.FULL_DT						between dt.FULL_DT and DATEADD(DAY, fc.Day_Cnt, dt.FULL_DT)
where 
	fc.Srvc_Typ_Sys_Id				=	1
	and fc.Admit_Cnt				=	1
	--and m.Indv_Sys_Id % 10000		=	123
	and pos.AMA_PL_OF_SRVC_DESC		=	'INPATIENT HOSPITAL'
go
create clustered index cixIndv_Sys_Id_IpDate on dbo.Member_Continuous_2017_HPDM_IpDate(Indv_Sys_Id, IpDate)
go

IF object_id('dbo.Member_Continuous_2017_HPDM_Claim','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_Claim;
select 
	m.Indv_Sys_Id,
	ServiceDate							=	convert(date, dt.Full_Dt),
	MemberDate							=	convert(varchar, m.Indv_Sys_Id) + ' . ' + convert(varchar, dt.FULL_DT),
	fc.Deriv_Amt,
	fc.Allw_Amt,
	fc.Day_Cnt,
	Admit_Cnt_IPH						=	case when pos.AMA_PL_OF_SRVC_DESC in ('INPATIENT HOSPITAL') then fc.Admit_Cnt else 0 end,
	fc.Vst_Cnt,
	DerivedSrvcTyp						=	case 
												when ip.Indv_Sys_Id is not null	then 'IP'  
												when stc.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then 'ER'
												else st.Srvc_Typ_Cd	
											end
into dbo.Member_Continuous_2017_HPDM_Claim
from 
	Member_Continuous_2017_HPDM								m
	join MiniHPDM.dbo.Fact_Claims							fc	on	m.Indv_Sys_Id					=	fc.Indv_Sys_Id
	join MiniHPDM.dbo.Dim_Date								dt	on	fc.Dt_Sys_Id					=	dt.DT_SYS_ID
																and dt.YEAR_NBR						=	2017
	join MiniHPDM.dbo.Dim_Place_of_Service_Code				pos	on	fc.Pl_of_Srvc_Sys_Id			=	pos.PL_OF_SRVC_SYS_ID
	join MiniHPDM.dbo.Dim_Service_Type						st	on	fc.Srvc_Typ_Sys_Id				=	st.Srvc_Typ_Sys_Id
	join MiniHPDM.dbo.DIM_HP_SERVICE_TYPE_CODE				stc	on	fc.Hlth_Pln_Srvc_Typ_Cd_Sys_ID	=	stc.HLTH_PLN_SRVC_TYP_CD_SYS_ID
	left join Member_Continuous_2017_HPDM_IpDate			ip	on	m.Indv_Sys_Id					=	ip.Indv_Sys_Id
																and dt.FULL_DT						=	ip.IpDate
--where 
--	m.Indv_Sys_Id % 100000 = 0
go
create clustered index cixIndv_Sys_Id on dbo.Member_Continuous_2017_HPDM_Claim(Indv_Sys_Id)
go

IF object_id('dbo.Member_Continuous_2017_HPDM_ClaimSummary','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_ClaimSummary;
select 
	a.Indv_Sys_Id, 
	Admit_Cnt_IPH			=	ISNULL(sum(Admit_Cnt_IPH) 														, 0),
	ERVisits				=	ISNULL(count(distinct case when DerivedSrvcTyp = 'ER' then MemberDate end)		, 0),
	TotalAllw				=	ISNULL(sum(Allw_Amt)															, 0),
	Total_Ip				=	ISNULL(sum(case when DerivedSrvcTyp = 'IP' then Allw_Amt else 0 end)			, 0),
	Total_Op				=	ISNULL(sum(case when DerivedSrvcTyp = 'Op' then Allw_Amt else 0 end)			, 0),
	Total_Dr				=	ISNULL(sum(case when DerivedSrvcTyp = 'Dr' then Allw_Amt else 0 end)			, 0),
	Total_Rx				=	ISNULL(sum(case when DerivedSrvcTyp = 'Rx' then Allw_Amt else 0 end)			, 0),
	Total_Er				=	ISNULL(sum(case when DerivedSrvcTyp = 'ER' then Allw_Amt else 0 end)			, 0)
into dbo.Member_Continuous_2017_HPDM_ClaimSummary
from 
	Member_Continuous_2017_HPDM								a
	left join Member_Continuous_2017_HPDM_Claim				b	on	a.Indv_Sys_Id					=	b.Indv_Sys_Id
--where 
--	a.Indv_Sys_Id % 100000 = 0
group by 
	a.Indv_Sys_Id 
go
create clustered index cixIndv_Sys_Id on dbo.Member_Continuous_2017_HPDM_ClaimSummary(Indv_Sys_Id)
go


--for efficiency of calculation pull it all togethers 
IF object_id('dbo.Member_Continuous_2017_HPDM_Summary','U') IS NOT NULL
	DROP TABLE dbo.Member_Continuous_2017_HPDM_Summary;
select 
	a.Indv_Sys_Id,
	a.Cust_Seg_Sys_Id,
	d.CUST_SEG_NBR,
	d.CUST_SEG_NM,
	Insurance			=	'Other',
	a.Co_Id_Rllp,
	a.Co_Nm,
	a.Hlth_Pln_Fund_Cd,
	a.isEmail,
	HaveEmail			=	case when isEmail = 1 then 'Yes' else 'No' end,
	a.isFitbit,
	HaveFitbit			=	case when isFitbit = 1 then 'Yes' else 'No' end,
	isMotionGroup		=	case when e.CUST_SEG_NBR is not null then 1 else 0 end,
	a.isFemale,
	a.Gdr_Cd,
	a.Age,
	AgeBand				=	case
								when Age between 18 and 44 then '18-44'
								when Age between 45 and 64 then '45-64'
								when Age >= 65 then '65+'
								else 'Ruh roh!'
							end, 
	b.Admit_Cnt_IPH,
	b.ERVisits,
	b.TotalAllw,
	b.Total_Ip,
	b.Total_Op,
	b.Total_Dr,
	b.Total_Rx,
	b.Total_Er,
	Charlson_Var			=	c.Charlson_Var_1, 
	AIDS_HIV				=	c.AIDS_HIV_1, 
	AMI						=	c.AMI_1, 
	Angina					=	c.Angina_1, 
	Cancer					=	c.Cancer_1, 
	CEVD					=	c.CEVD_1, 
	CHF						=	c.CHF_1, 
	COPD					=	c.COPD_1, 
	Dementia				=	c.Dementia_1, 
	Diabetes				=	c.Diabetes_1, 
	Hypertension			=	c.Hypertension_1, 
	Liver					=	c.Liver_1, 
	Paralysis				=	c.Paralysis_1, 
	PVD						=	c.PVD_1, 
	Renal_Failure			=	c.Renal_Failure_1, 
	Rheumatic				=	c.Rheumatic_1, 
	Ulcers					=	c.Ulcers_1, 
	Depression				=	c.Depression_1, 
	Skin					=	c.Skin_1			
into Member_Continuous_2017_HPDM_Summary
from 
	Member_Continuous_2017_HPDM_Include						a
	join Member_Continuous_2017_HPDM_ClaimSummary			b	on	a.Indv_Sys_Id		=	b.Indv_Sys_Id
	join Member_Continuous_2017_HPDM_Charlson				c	on	a.Indv_Sys_Id		=	c.Indv_Sys_Id
	join MiniHPDM.dbo.Dim_Customer_Segment					d	on	a.Cust_Seg_Sys_Id	=	d.CUST_SEG_SYS_ID
	left join GroupWithMotion								e	on	d.CUST_SEG_NBR		=	e.CUST_SEG_NBR
go
create clustered index cixIndv_Sys_Id on Member_Continuous_2017_HPDM_Summary(Indv_Sys_Id)

alter table Member_Continuous_2017_HPDM_Summary alter column Insurance varchar(20)

update Member_Continuous_2017_HPDM_Summary set Insurance = 'UHC-FI' where Co_Id_Rllp = 'United Healthcare' and Hlth_Pln_Fund_Cd = 'FI'
--update Member_Continuous_2017_HPDM_Summary set Insurance = 'UHC-ASO' where Co_Id_Rllp = 'United Healthcare' and Hlth_Pln_Fund_Cd = 'ASO'
--update Member_Continuous_2017_HPDM_Summary set Insurance = 'Uni-FI' where Co_Id_Rllp = 'Uniprise' and Hlth_Pln_Fund_Cd = 'FI'
update Member_Continuous_2017_HPDM_Summary set Insurance = 'Uni-ASO' where Co_Id_Rllp = 'Uniprise' and Hlth_Pln_Fund_Cd = 'ASO'

--this will be ~biggish, but should be what we're typically using and streamline performance (about 1/3 of total table) pretty well
create index fixInsurance on Member_Continuous_2017_HPDM_Summary(Insurance) 
	include (isEmail, HaveEmail, isFitbit, HaveFitbit, isFemale, Gdr_Cd, Age, AgeBand, Admit_Cnt_IPH, ERVisits, TotalAllw, Total_Ip, Total_Op, Total_Dr, Total_Rx, Total_Er, Charlson_Var, AIDS_HIV, AMI, Angina, Cancer, CEVD, CHF, COPD, Dementia, Diabetes, Hypertension, Liver, Paralysis, PVD, Renal_Failure, Rheumatic, Ulcers, Depression) 
	where Insurance <> 'Other'
go



--get the results to report
--select 
--	a.Insurance, 
--	a.isFitbit,
--	MbrCnt						=	count(*), 
--	AvgAge						=	AVG(1. * m.Age										),
--	PctFemale					=	AVG(1. * case when m.Gdr_Cd = 'F' then 1 else 0 end	),
--	Avg_IPH_Admit				=	avg(1. * b.Admit_Cnt_IPH							),
--	Avg_cnt_ERVisits			=	avg(1. * b.ERVisits									),
--	PMPM						=	avg(1. * b.TotalAllw	/ 12						),
--	PMPM_Ip						=	avg(1. * b.Total_Ip		/ 12						),
--	PMPM_Op						=	avg(1. * b.Total_Op		/ 12						),
--	PMPM_Dr						=	avg(1. * b.Total_Dr		/ 12						),
--	PMPM_Rx						=	avg(1. * b.Total_Rx		/ 12						),
--	PMPM_Er						=	avg(1. * b.Total_Er		/ 12						),
--	avgCharlson_Var_1			=	avg(1. * c.Charlson_Var_1							),
--	avgAIDS_HIV_1				=	avg(1. * c.AIDS_HIV_1								),
--	avgAMI_1					=	avg(1. * c.AMI_1									),
--	avgAngina_1					=	avg(1. * c.Angina_1									),
--	avgCancer_1					=	avg(1. * c.Cancer_1									),
--	avgCEVD_1					=	avg(1. * c.CEVD_1									),
--	avgCHF_1					=	avg(1. * c.CHF_1									),
--	avgCOPD_1					=	avg(1. * c.COPD_1									),
--	avgDementia_1				=	avg(1. * c.Dementia_1								),
--	avgDiabetes_1				=	avg(1. * c.Diabetes_1								),
--	avgHypertension_1			=	avg(1. * c.Hypertension_1							),
--	avgLiver_1					=	avg(1. * c.Liver_1									),
--	avgParalysis_1				=	avg(1. * c.Paralysis_1								),
--	avgPVD_1					=	avg(1. * c.PVD_1									),
--	avgRenal_Failure_1			=	avg(1. * c.Renal_Failure_1							),
--	avgRheumatic_1				=	avg(1. * c.Rheumatic_1								),
--	avgUlcers_1					=	avg(1. * c.Ulcers_1									),
--	avgDepression_1				=	avg(1. * c.Depression_1								),
--	avgSkin_1					=	avg(1. * c.Skin_1									),
--	avgCharlson_Var_2			=	avg(1. * c.Charlson_Var_2							),
--	avgAIDS_HIV_2				=	avg(1. * c.AIDS_HIV_2								),
--	avgAMI_2					=	avg(1. * c.AMI_2									),
--	avgAngina_2					=	avg(1. * c.Angina_2									),
--	avgCancer_2					=	avg(1. * c.Cancer_2									),
--	avgCEVD_2					=	avg(1. * c.CEVD_2									),
--	avgCHF_2					=	avg(1. * c.CHF_2									),
--	avgCOPD_2					=	avg(1. * c.COPD_2									),
--	avgDementia_2				=	avg(1. * c.Dementia_2								),
--	avgDiabetes_2				=	avg(1. * c.Diabetes_2								),
--	avgHypertension_2			=	avg(1. * c.Hypertension_2							),
--	avgLiver_2					=	avg(1. * c.Liver_2									),
--	avgParalysis_2				=	avg(1. * c.Paralysis_2								),
--	avgPVD_2					=	avg(1. * c.PVD_2									),
--	avgRenal_Failure_2			=	avg(1. * c.Renal_Failure_2							),
--	avgRheumatic_2				=	avg(1. * c.Rheumatic_2								),
--	avgUlcers_2					=	avg(1. * c.Ulcers_2									),
--	avgDepression_2 			=	avg(1. * c.Depression_2 							),
--	avgSkin_2					=	avg(1. * c.Skin_2									)
--from 
--	Member_Continuous_2017_HPDM								a
--	join MiniHPDM_PHI.dbo.Dim_Member						mp	on	a.Indv_Sys_Id		=	mp.Indv_Sys_Id	--to restrict on birth date
--																and mp.Bth_dt			<=	'1998-12-31'
--	join MiniHPDM.dbo.Dim_Member							m	on	a.Indv_Sys_Id		=	m.Indv_Sys_Id	--to include age without needing to think through the calculation because it is late and I am tired
--	join Member_Continuous_2017_HPDM_ClaimSummary			b	on	a.Indv_Sys_Id		=	b.Indv_Sys_Id
--	join Member_Continuous_2017_HPDM_Charlson				c	on	a.Indv_Sys_Id		=	c.Indv_Sys_Id
----where a.Indv_Sys_Id % 100000 = 0
--group by a.Insurance, a.isFitbit
--order by a.Insurance, a.isFitbit

--select 
--	a.Insurance, 
--	a.isFitbit,
--	m.Gdr_Cd,
--	MbrCnt						=	count(*), 
--	AvgAge						=	AVG(1. * m.Age										),
--	PctFemale					=	AVG(1. * case when m.Gdr_Cd = 'F' then 1 else 0 end	),
--	Avg_IPH_Admit				=	avg(1. * b.Admit_Cnt_IPH							),
--	Avg_cnt_ERVisits			=	avg(1. * b.ERVisits									),
--	PMPM						=	avg(1. * b.TotalAllw	/ 12						),
--	PMPM_Ip						=	avg(1. * b.Total_Ip		/ 12						),
--	PMPM_Op						=	avg(1. * b.Total_Op		/ 12						),
--	PMPM_Dr						=	avg(1. * b.Total_Dr		/ 12						),
--	PMPM_Rx						=	avg(1. * b.Total_Rx		/ 12						),
--	PMPM_Er						=	avg(1. * b.Total_Er		/ 12						),
--	avgCharlson_Var_1			=	avg(1. * c.Charlson_Var_1							),
--	avgAIDS_HIV_1				=	avg(1. * c.AIDS_HIV_1								),
--	avgAMI_1					=	avg(1. * c.AMI_1									),
--	avgAngina_1					=	avg(1. * c.Angina_1									),
--	avgCancer_1					=	avg(1. * c.Cancer_1									),
--	avgCEVD_1					=	avg(1. * c.CEVD_1									),
--	avgCHF_1					=	avg(1. * c.CHF_1									),
--	avgCOPD_1					=	avg(1. * c.COPD_1									),
--	avgDementia_1				=	avg(1. * c.Dementia_1								),
--	avgDiabetes_1				=	avg(1. * c.Diabetes_1								),
--	avgHypertension_1			=	avg(1. * c.Hypertension_1							),
--	avgLiver_1					=	avg(1. * c.Liver_1									),
--	avgParalysis_1				=	avg(1. * c.Paralysis_1								),
--	avgPVD_1					=	avg(1. * c.PVD_1									),
--	avgRenal_Failure_1			=	avg(1. * c.Renal_Failure_1							),
--	avgRheumatic_1				=	avg(1. * c.Rheumatic_1								),
--	avgUlcers_1					=	avg(1. * c.Ulcers_1									),
--	avgDepression_1				=	avg(1. * c.Depression_1								),
--	avgSkin_1					=	avg(1. * c.Skin_1									),
--	avgCharlson_Var_2			=	avg(1. * c.Charlson_Var_2							),
--	avgAIDS_HIV_2				=	avg(1. * c.AIDS_HIV_2								),
--	avgAMI_2					=	avg(1. * c.AMI_2									),
--	avgAngina_2					=	avg(1. * c.Angina_2									),
--	avgCancer_2					=	avg(1. * c.Cancer_2									),
--	avgCEVD_2					=	avg(1. * c.CEVD_2									),
--	avgCHF_2					=	avg(1. * c.CHF_2									),
--	avgCOPD_2					=	avg(1. * c.COPD_2									),
--	avgDementia_2				=	avg(1. * c.Dementia_2								),
--	avgDiabetes_2				=	avg(1. * c.Diabetes_2								),
--	avgHypertension_2			=	avg(1. * c.Hypertension_2							),
--	avgLiver_2					=	avg(1. * c.Liver_2									),
--	avgParalysis_2				=	avg(1. * c.Paralysis_2								),
--	avgPVD_2					=	avg(1. * c.PVD_2									),
--	avgRenal_Failure_2			=	avg(1. * c.Renal_Failure_2							),
--	avgRheumatic_2				=	avg(1. * c.Rheumatic_2								),
--	avgUlcers_2					=	avg(1. * c.Ulcers_2									),
--	avgDepression_2 			=	avg(1. * c.Depression_2 							),
--	avgSkin_2					=	avg(1. * c.Skin_2									)
--from 
--	Member_Continuous_2017_HPDM								a
--	join MiniHPDM_PHI.dbo.Dim_Member						mp	on	a.Indv_Sys_Id		=	mp.Indv_Sys_Id	--to restrict on birth date
--																and mp.Bth_dt			<=	'1998-12-31'
--	join MiniHPDM.dbo.Dim_Member							m	on	a.Indv_Sys_Id		=	m.Indv_Sys_Id	--to include age without needing to think through the calculation because it is late and I am tired
--	join Member_Continuous_2017_HPDM_ClaimSummary			b	on	a.Indv_Sys_Id		=	b.Indv_Sys_Id
--	join Member_Continuous_2017_HPDM_Charlson				c	on	a.Indv_Sys_Id		=	c.Indv_Sys_Id
----where a.Indv_Sys_Id % 100000 = 0
--group by a.Insurance, a.isFitbit, m.Gdr_Cd
--order by a.Insurance, a.isFitbit

--select * from Member_Continuous_2017_HPDM where Indv_Sys_Id % 10000000 = 0 order by Indv_Sys_Id
--select * from Member_Continuous_2017_HPDM_Diag where Indv_Sys_Id % 10000000 = 0 order by Indv_Sys_Id

--What's the average family size? Or just a count of numbers of individuals vs families in the data and in the match?

