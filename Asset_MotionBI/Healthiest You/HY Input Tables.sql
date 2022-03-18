--------------------------------------------
--	CREATE MEMBER TABLE	  --
--------------------------------------------

-- Create Member Names + DOB + ExigoID - level Member table --
if object_id ('pdb_ABW..HealthiestYou_Member') is not null
drop table pdb_ABW..HealthiestYou_Member

Select NameDOBState			=	First  + ' ' + Last	+ ' ' + convert(varchar, DOB) + ' ' + a.State
	,a.First
	,a.Last
	,a.DOB
	,a.State
	,HY_ID					=	a._id
	,HY_ExigoID				=	a.ExigoID
	,AllSavers_MemberID		=	c.MemberID
	,AlLSavers_PolicyID		=	c.PolicyID
	,AllSavers_SystemID		=	c.SystemID
	,AllSavers_familyID		=	c.familyID
	,WithConsult			=	max(	case	when	b.Reporting2 is not null	then	1	else	0	end)	/* Flag if member has consult */
	,InAllSavers			=	max(	case	when	c.FirstName is not null		then	1	else	0	end)	/* Flag if member is in AllSavers */
  Into pdb_ABW..HealthiestYou_Member
From pdb_ABW..HealthiestYou_HYUHG_SAVVY					a
left join pdb_ABW..HealthiestYou_UHG_2015_CONSULTS		b	on	a._id		=	b.Reporting2
left join	(Select * From AllSavers_Prod.dbo.Dim_Member
			Where MM_2015 > 0)							c	on	a.First		=	c.FirstName
															and	a.Last		=	c.LastName
															and a.DOB		=	c.BirthDate
															and	a.State		=	c.State
Group by First  + ' ' + Last	+ ' ' + convert(varchar, DOB) + ' ' + a.State
	,a.First,a.Last,a.DOB,a.State
	,a._id,a.ExigoID
	,c.MemberID
	,c.PolicyID
	,c.SystemID
	,c.familyID
-- 130,410


--------------------------------------------
--	CREATE MEMBER CONSULT TABLE	  --
--------------------------------------------

if object_id ('pdb_ABW.dbo.HealthiestYou_MemberConsults2015') is not null
drop table pdb_ABW.dbo.HealthiestYou_MemberConsults2015
select a.[NameDOBState]
	, a.[First]
	, a.[Last]
	, a.[DOB]
	, a.[State]
	, SubscriberAge	=	DATEDIFF(Year, a.[DOB], CONVERT(DATE, Getdate()))
	, a.[HY_ID]
	, a.[HY_ExigoID]
	, a.[AllSavers_MemberID]
	, a.[AlLSavers_PolicyID]
	, a.[AllSavers_SystemID]
	, a.[AllSavers_familyID]
	, a.[WithConsult]
	, a.[InAllSavers]
	, b.[Role]
	, b.[Age]
	, [Gender]			=	IIF(b.Gender = 'Male', 'M', 'F')
	, b.[Consult_Date]
	, b.[Diagnosis]
	, b.[Icd9Code]
	, b.[ICd10Code]
	, b.[CPTBillingCode]
	, b.[PrescriptionGiven]
	, b.[PrescriptionGivenCount]
	, b.[PrescriptionNames]
	, b.[NumberOfDiagnosisPerEncounter]
	, b.[NumberOfPrescriptionsPerEncounter]
	, b.ConsultationRatingfromSurvey
	, b.[How_likely_are_you_to_use_MDLIVE_in_the_future?]
	, b.[Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
	, b.[Referral_question_response_(How likely are you to refer a friend or colleague to MDLIVE?)]
	, ConsultYearMonth	=	REPLACE(LEFT(Consult_Date, 7), '-', '')
  Into pdb_ABW.dbo.HealthiestYou_MemberConsults2015
from pdb_ABW.dbo.HealthiestYou_Member		a
join pdb_ABW.dbo.HealthiestYou_Consults2015	b	on	a.HY_ID = b.HY_ID
where InAllSavers = 1


--------------------------------------------
--	CREATE MEMBER CLAIMS 2015 TABLE	  --
--------------------------------------------

if object_id ('pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult') is not null
drop table pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult
Select a.MemberID, a.PolicyID, a.SystemID, a.FamilyID, a.BirthDate
	, a.Gender
	, a.Age
	,fc.ClaimNumber
	,AS_SrvcDt				=	dd.FullDt
	,AS_ICD9_DiagCd			=	dc1.DiagDecmCd
	,AS_ICD9_DiagFst3		=	left(rtrim(ltrim(dc1.DiagDecmCd)),3)	
	,AS_ICD9_DiagDesc		=	dc1.DiagDesc
	,AS_ICD9_DiagDtl		=	dc1.AHRQDiagDtlCatgyNm
	,AS_ICD9_DiagGnl		=	dc1.AHRQDiagGenlCatgyNm
	,AS_ICD10_DiagCd		=	dc2.DiagDecmCd
	,AS_ICD10_DiagFst3		=	left(rtrim(ltrim(dc2.DiagDecmCd)),3)	
	,AS_ICD10_DiagDesc		=	dc2.DiagDesc
	,AS_ICD10_DiagDtl		=	dc2.AHRQDiagDtlCatgyNm
	,AS_ICD10_DiagGnl		=	dc2.AHRQDiagGenlCatgyNm
	,AS_Service				=	case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
										when ServiceCodeLongDescription like '%urgent%'			then	'UC'
										when (
											ProcDesc like '%office%visit%'  
											or srvccatgydesc like '%evaluation%management%'
											)													then	'DR'
										else 'Others'
								end 
	,AS_Rx_Brnd				=	ndc.BrndNm
	,AS_Rx_Gnrc				=	ndc.GnrcNm
	,AllwAmt				=	Sum(fc.AllwAmt)
	,AS_Rx_NDC				=	ndc.NDC
	,MemberType				=	Case When right(a.SystemID, 1) = 0 Then 'Primary' Else 'Dependent' End
  Into pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult
From
(
	select Distinct c.SystemID, c.MemberID, c.PolicyID, c.FamilyID, c.BirthDate, c.Gender, a.Age
		--, Allsavers_Age = DATEDIFF(YEAR, c.BirthDate, Convert(date, getdate()))
	from pdb_ABW.dbo.HealthiestYou_MemberConsults2015	a
	join AllSavers_Prod.dbo.Dim_Member					c	on	a.AllSavers_familyID	=	c.FamilyID			-- 5,867
															and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
															and a.Age between DATEDIFF(YEAR, c.BirthDate, Convert(date, getdate())) - 1 and DATEDIFF(YEAR, c.BirthDate, Convert(date, getdate())) + 1
	where InAllSavers = 1
)												a
join Allsavers_Prod.dbo.Fact_Claims				fc	on	a.MemberID			=	fc.MemberID
													and	a.PolicyID			=	fc.PolicyID
													and	a.SystemID			=	fc.SystemID
join Allsavers_Prod.dbo.Dim_Date				dd	on	fc.FromDtSysID		=	dd.DtSysId
left join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc1	on	fc.DiagCdSysId		=	dc1.DiagCdSysId
left join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc2	on	fc.DiagCdICD10SysID	=	dc2.DiagCdSysId
join Allsavers_Prod.dbo.Dim_ProcedureCode		pc	on	fc.ProcCdSysID		=	pc.procCdsysid
join allsavers_prod.dbo.Dim_ServiceCode			sc	on	fc.ServiceCodeSysID	=	sc.ServiceCodeSysID
join Allsavers_Prod.dbo.Dim_NDCDrug				ndc on	fc.NDCDrugSysID		=	ndc.NDCDrugSysID
Where fc.RecordTypeSysID = 1
	and dd.YearNbr = 2015
Group by a.MemberID, a.PolicyID, a.SystemID, a.FamilyID, a.BirthDate, a.Gender, a.Age
	, fc.ClaimNumber
	, dd.FullDt
	, dc1.DiagDecmCd
	, left(rtrim(ltrim(dc1.DiagDecmCd)),3)
	, dc1.DiagDesc
	, dc1.AHRQDiagDtlCatgyNm
	, dc1.AHRQDiagGenlCatgyNm
	, dc2.DiagDecmCd
	, left(rtrim(ltrim(dc2.DiagDecmCd)),3)
	, dc2.DiagDesc
	, dc2.AHRQDiagDtlCatgyNm
	, dc2.AHRQDiagGenlCatgyNm
	, case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
	 		when ServiceCodeLongDescription like '%urgent%'			then	'UC'
	 		when (
	 			ProcDesc like '%office%visit%'  
	 			or srvccatgydesc like '%evaluation%management%'
	 			)													then	'DR'
	 		else 'Others'
	 end 
	, ndc.BrndNm
	, ndc.GnrcNm
	, ndc.NDC
Go
-- 73,452


--------------------------------------------
--	CREATE DRUG CROSSWALK TABLE	  --
--------------------------------------------

if object_id ('pdb_ABW..HealthiestYou_DrugCrosswalk') is not null
drop table pdb_ABW..HealthiestYou_DrugCrosswalk
Select Distinct HY_Rx_1 = a.Brnd_Nm, b.NDC
  Into pdb_ABW..HealthiestYou_DrugCrosswalk
From MiniHPDM..Dim_NDC_Drug  a
join MiniHPDM..Dim_NDC_Drug b on a.GNRC_NM = b.Gnrc_Nm
Where a.BRND_NM in (
	Select Distinct Prescription_Names_1
	From pdb_HealthiestYou..Raw_Consult_Export_NEW
	Where Prescription_Names_1 <> ''
		and Prescription_Given = 'Yes'
	)
UNION
Select Distinct HY_Rx1 = 'Zithromax Z-Pak'
	,NDC
From AllSavers_Prod..Dim_NDCDrug
Where GnrcNm like 'Azithromycin'
	or BrndNm like 'Azithromycin'
UNION
Select Distinct HY_Rx1 = 'Medrol (Pak)'
	,NDC
From AllSavers_Prod..Dim_NDCDrug
Where GnrcNm like 'Methylprednisolone'
	or BrndNm like 'Methylprednisolone'
--67,618