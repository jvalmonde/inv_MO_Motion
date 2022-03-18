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
	and exists (Select * From AllSavers_Prod.dbo.Dim_MemberDetail	c Where a.AllSavers_familyID = c.FamilyID and REPLACE(LEFT(Consult_Date, 7), '-', '') = c.YearMo)


	/***update the member withconsult flag if they had a consult but its not inthe member consult table which has been filtered for concurrent enrollment.**/
update m set m.WithConsult = 0 
FROM pdb_abw.dbo.HealthiestYou_Member m
	Left join pdb_Abw.dbo.Healthiestyou_MemberConsults2015 mc 
		On m.AllSavers_Familyid = mc.AllSavers_familyID
Where m.WithConsult = 1 and mc.AllSavers_familyID is  null 

if object_id ('pdb_ABW.dbo.HealthiestYou_MemberConsults2016') is not null
drop table pdb_ABW.dbo.HealthiestYou_MemberConsults2016
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
  Into pdb_ABW.dbo.HealthiestYou_MemberConsults2016
from pdb_ABW.dbo.HealthiestYou_Member		a
join pdb_ABW.dbo.HealthiestYou_Consults2016	b	on	a.HY_ID = b.HY_ID
where InAllSavers = 1
	and exists (Select * From AllSavers_Prod.dbo.Dim_MemberDetail	c Where a.AllSavers_familyID = c.FamilyID and REPLACE(LEFT(Consult_Date, 7), '-', '') = c.YearMo)

if object_id ('pdb_ABW.dbo.HealthiestYou_MemberConsults201501_201602') is not null
drop table pdb_ABW.dbo.HealthiestYou_MemberConsults201501_201602
Select Distinct AllSavers_SystemID, Age, Gender, Role, Consult_Date, ConsultYearMonth
  Into pdb_ABW.dbo.HealthiestYou_MemberConsults201501_201602
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015
	Union
Select Distinct AllSavers_SystemID, Age, Gender, Role, Consult_Date, ConsultYearMonth
From pdb_ABW.dbo.HealthiestYou_MemberConsults2016

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


/*****************************************************************************************************************************************************************
																			RECREATE POWERPOINT DECK
*****************************************************************************************************************************************************************/

/*** HY to AllSavers MatchRate ***/
-- Distinct count of members
Select Distinct a.First, a.Last, a.DOB, a.State
	--, b.FirstName, b.LastName, b.BirthDate, b.State
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a
-- 129,297

-- matching with Name, Dob, State
Select Distinct a.First, a.Last, a.DOB, a.State
	, b.FirstName, b.LastName, b.BirthDate, b.State
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a
Inner Join AllSavers_Prod.dbo.Dim_Member	b	on	a.First	=	b.FirstName
												and	a.Last	=	b.LastName
												and a.DOB	=	b.BirthDate
												and a.State	=	b.State
Order By a.Last, a.First
-- 127,441

-- with atleast 1 membership month in 2015
Select Distinct a.First, a.Last, a.DOB, a.State
	, b.FirstName, b.LastName, b.BirthDate, b.State
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]	a
Inner Join AllSavers_Prod.dbo.Dim_Member	b	on	a.First	=	b.FirstName
												and	a.Last	=	b.LastName
												and a.DOB	=	b.BirthDate
												and a.State	=	b.State
Where MM_2015 > 0
Order By a.Last, a.First
-- 104,373

-- Employee MM and Member MM by YearMonth
-- Drop Table #MM2015
select YearMonth	=	 YearMo
	, EnrolleeMM	=	Count(Distinct Case When MemberType = 'Primary' Then MEMBERID Else Null End)
	, DependentMM	=	Count(Distinct Case When MemberType = 'Dependent' Then MEMBERID Else Null End)
	, MemberMM		=	Count(Distinct MEMBERID)
  into #MM2015
From
(
	Select Distinct MemberType	=	Case	When right(y.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary'
											When right(y.SystemID, 1) = 0 and x.MemberID = y.MemberID Then 'Primary' 
											Else 'Dependent' End
		, y.MemberID, y.YearMo
	From
	(
		Select Distinct b.MemberID, b.SystemID
		From
		(
			Select Distinct AllSavers_MemberID, AllSavers_familyID
			From pdb_ABW.dbo.HealthiestYou_Member
			where InAllSavers = 1
		)	a
			Join AllSavers_Prod.dbo.Dim_Member	b	on	a.AllSavers_familyID	=	b.FamilyID
	)	x
		Join AllSavers_Prod.dbo.Dim_MemberDetail	y	on	x.MemberID	=	y.MemberID
	Where y.YearMo between 201501 and 201512
)	c
Group By YearMo
Order By YearMo

Select SUM(MemberMM) From #MM2015

-- 2016 MM
--Drop Table #MM2016
Select YearMonth	=	 YearMo
	, PrimaryMM		=	Count(Distinct Case When MemberType = 'Primary' Then MEMBERID Else Null End)
	, DependentMM	=	Count(Distinct Case When MemberType = 'Dependent' Then MEMBERID Else Null End)
	, TotalMM		=	Count(Distinct MEMBERID)
  Into #MM2016
From
(
	Select Distinct d.MemberID, d.YearMo
		, MemberType	=	Case When right(d.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary' Else 'Dependent' End
	From
	(-- 99,424 distinct members (name + DOB + state)
		Select Distinct b.FamilyID
		From pdb_ABW.dbo.HealthiestYou_HYUHG_SAVVY	a
		Inner Join AllSavers_Prod.dbo.Dim_Member	b	On	a.First	=	b.FirstName
														and	a.Last	=	b.LastName
														and	a.DOB	=	b.BirthDate
														and	a.State	=	b.State
		Where b.MM_2016 > 0
	)	c
		Inner Join AllSavers_Prod.dbo.Dim_MemberDetail	d	On	c.FamilyID	=	d.FamilyID
	Where d.YearMo between 201601 and 201602
)	e
Group By YearMo
Order By YearMonth


-- AVerage MMs
Select AVG(EnrolleeMM), AVG(MemberMM)
From #MM2015

Select AVG(EnrolleeMM), AVG(MemberMM)
From #MM2016


Select MemberType, Count(*) Cnt
From pdb_ABW.dbo.HealthiestYou_Member_MasterTable
Where MM_2015 > 0
Group By MemberType

/*** Consult Rate ***/
Select WithConsult, Count(Distinct NameDOBState)
From
(
Select NameDOBState, Max(WithConsult) as WithConsult, Max(InAllSavers) as InAllSavers
From Dbo.HealthiestYou_Member
Group By NameDOBState
)	a
WHere InAllSavers = 1
Group BY WithConsult With Rollup


/*** Number of Consults ***/

Drop table #consult_dates2
 sELECT  AllSavers_familyID, AllSavers_SystemID, Gender
 , Consult_date as call_Start_date
 , Role
 , Icd9_Code_1 = case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end
,dc.AHRQDiagDtlCatgyCd
,dc.AHRQDiagGenlCatgyCd
, dc.AHRQDiagDtlCatgyNm, dc.AHRQDiagGenlCatgyNm, dc.DiagDesc
into #consult_dates2
from pdb_abw.dbo.HealthiestYou_MemberConsults2015 a 
	Left join (Select Distinct DiagDecmCd, AHRQDiagDtlCatgyCd ,AHRQDiagGenlCatgyCd, AHRQDiagDtlCatgyNm, AHRQDiagGenlCatgyNm, DiagDesc   From  Allsavers_prod.dbo.Dim_DiagnosisCode )  dc 
		ON case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end = dc.DiagDecmCd 
		and Icd9Code <> ''

Select Role, Count(*)
From (Select distinct AllSavers_FamilyId,  Call_Start_Date, Role from #consult_dates2 b)	a
Group By Role


/*** Consults by Month (graph) ***/

Select ConsultYearMonth, Count(*) As Cnt
From (Select Distinct ConsultYearMonth, AllSavers_SystemID, Gender, Role, Consult_Date From pdb_ABW.dbo.HealthiestYou_MemberConsults201501_201602) a
Group By ConsultYearMonth
Order By ConsultYearMonth

--Drop Table #monthlyconsults
Select a.*
	, b.DependentConsults
	, TotalConsults			=	a.PrimaryConsults + b.DependentConsults
	, PrimaryMM				=	c.EnrolleeMM
	, c.DependentMM
	, TotalMM				=	c.MemberMM
	, PrimaryConsultRate	=	(a.PrimaryConsults * 1.0 / c.MemberMM)* 100
	, DependentConsultRate	=	(b.DependentConsults * 1.0 / c.MemberMM) * 100
	, TotalConsultRate		=	((a.PrimaryConsults + b.DependentConsults) * 1.0 / c.MemberMM) * 100
  Into #monthlyconsults
From
(
	Select ConsultYearMonth, Count(*) as PrimaryConsults
	From pdb_ABW.dbo.HealthiestYou_MemberConsults201501_201602
	Where Role = 'Primary'
	Group By ConsultYearMonth, Role
)	a
Inner Join	(
			Select ConsultYearMonth, Count(*) as DependentConsults
			From pdb_ABW.dbo.HealthiestYou_MemberConsults201501_201602
			Where Role = 'Dependent'
			Group By ConsultYearMonth, Role
			)	b
	on	a.ConsultYearMonth	=	b.ConsultYearMonth
Inner Join	(
			Select * From #MM2015	Union
			Select * From #MM2016
			)	c
	on	a.ConsultYearMonth	=	c.YearMonth
Order By a.ConsultYearMonth

Select * From #monthlyconsults

--Drop Table pdb_ABW.dbo.HY_MonthlyConsults
Select YearMonth	=	ConsultYearMonth
	, Role	=	'Primary'
	, ConsultRate	=	PrimaryConsultRate
  Into pdb_ABW.dbo.HY_MonthlyConsults
From #monthlyconsults
	Union
Select YearMonth	=	ConsultYearMonth
	, Role	=	'Dependent'
	, ConsultRate	=	DependentConsultRate
From #monthlyconsults
	Union
Select YearMonth	=	ConsultYearMonth
	, Role	=	'Total'
	, ConsultRate	=	TotalConsultRate
From #monthlyconsults


/*** Care Utilization following Consults ***/

-- consults
Drop table #consult_dates2
 sELECT  AllSavers_familyID, AllSavers_SystemID, Gender
 , Consult_date as call_Start_date
 , Role
 , Icd9_Code_1 = case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end
,dc.AHRQDiagDtlCatgyCd
,dc.AHRQDiagGenlCatgyCd
, dc.AHRQDiagDtlCatgyNm, dc.AHRQDiagGenlCatgyNm, dc.DiagDesc
into #consult_dates2
from pdb_abw.dbo.HealthiestYou_MemberConsults2015 a 
	Left join (Select Distinct DiagDecmCd, AHRQDiagDtlCatgyCd ,AHRQDiagGenlCatgyCd, AHRQDiagDtlCatgyNm, AHRQDiagGenlCatgyNm, DiagDesc   From  Allsavers_prod.dbo.Dim_DiagnosisCode )  dc 
		ON case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end = dc.DiagDecmCd 
		and Icd9Code <> ''

-- Claim flags
Drop table #claims_flags
select  b.AllSavers_familyID,b.Call_Start_Date,Role ,
       max(case when d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%' then 1 else 0 end) as ER,
       max(case when d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%' then 1 else 0 end) as UC,
       max(case when e.ProcCd like '992%' then 1 else 0 end) as EM,
 
          max(case when(d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%')
                             and left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as ER_Fst3,
       max(case when(d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%')
                             and left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as UC_Fst3,
       max(case when e.ProcCd like '992%'
                    and left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as EM_Fst3,
 
          max(case when(d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%')
                             and b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as ER_AHRQ_Dtl,
       max(case when(d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%')
                             and b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as UC_AHRQ_Dtl,
       max(case when e.ProcCd like '992%'
                             and b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as EM_AHRQ_Dtl,
 
          max(case when(d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%')
                             and b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as ER_AHRQ_Genl,
       max(case when(d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%')
                             and b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as UC_AHRQ_Genl,
       max(case when e.ProcCd like '992%'
                             and b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as EM_AHRQ_Genl,
         
          max(case when left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as Fst3,
          max(case when b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as AHRQ_Dtl,
          max(case when b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as AHRQ_Genl
into #claims_flags
from (Allsavers_Prod..Fact_Claims       as a inner join allsavers_prod..Dim_Member dm on a.Memberid = dm.Memberid) 
join #consult_dates2                                    as b   on dm.Familyid = b.AllSavers_familyID --and dm.Gender = b.Gender
join Allsavers_Prod..Dim_Date                   as c   on a.FromDtSysID = c.DtSysId
join Allsavers_Prod..Dim_ServiceCode     as d   on a.ServiceCodeSysID = d.ServiceCodeSysID
join Allsavers_Prod..Dim_ProcedureCode   as e   on a.ProcCdSysID = e.ProcCdSysId
join Allsavers_Prod..Dim_DiagnosisCode   as f   on a.DiagCdSysID = f.DiagCdSysId
where c.FullDt between b.Call_Start_Date and dateadd(day, 7, b.Call_Start_Date)
group by AllSavers_familyID, b.Call_Start_Date,Role
--2246

update #claims_flags
set UC = 0
where ER = 1
 
update #claims_flags
set EM = 0
where ER = 1 or UC = 1

 
--Summarize
select Role,
          count(*) as Consults,
          sum(ER) as ER,
          sum(UC) as UC,
          sum(EM) as EM,
          sum(Total) as Total,
          sum(Total)*1.0/count(*) as FD_Rate
from(
       --Flag consults with visits within 7 days by 
       select a.*,
                 isnull(b.ER,0) as ER,
                 isnull(b.UC,0) as UC,
                 isnull(b.EM,0) as EM,
                 case when b.ER + b.UC + b.EM > 0 then 1 else 0 end as Total
from(
              --Distinct consults
              select distinct AllSavers_FamilyId,  Call_Start_Date, Role
              from #consult_dates2 b
              ) as a
       left join #claims_flags           as b   on a.AllSavers_FamilyId = b.AllSavers_familyID
													
                                                                 and a.Call_Start_Date = b.Call_Start_Date
                                                                 and a.Role = b.Role
																 --and a.Gender = b.Gender
																 --and b.Fst3 = 1 
       ) as a
--
group by Role
with rollup
order by 1 desc

-- same diagnosis
 select count(*) as Cnt, 
          sum(case when False_Diversion_Flag = 1 then ER end) as ER,
          sum(case when False_Diversion_Flag = 1 then UC end) as UC,
          sum(case when False_Diversion_Flag = 1 then EM end) as EM
from(
       select *, case when AHRQ_Genl + AHRQ_Dtl + Fst3 > 0 then 1 else 0 end as False_Diversion_Flag
       from #claims_flags
       where ER + UC + EM > 0
       ) as a


-- by yearmonth
 select replace(left(call_start_date, 7), '-', '') as YearMonth, count(*) as Cnt, 
          sum(case when False_Diversion_Flag = 1 then ER end) as ER,
          sum(case when False_Diversion_Flag = 1 then UC end) as UC,
          sum(case when False_Diversion_Flag = 1 then EM end) as EM
from(
       select *, case when AHRQ_Genl + AHRQ_Dtl + Fst3 > 0 then 1 else 0 end as False_Diversion_Flag
       from #claims_flags
       where ER + UC + EM > 0
       ) as a
Group By replace(left(call_start_date, 7), '-', '')
Order By YearMonth


/*****Households by Number of Consults.******/
Select * , Share = Households * 1.00/Sum(Households) over (Partition by Null) 
FROM 
(		
		Select [Number of Consults], Households = Count(distinct AllSavers_familyid)
		From 
		( 
		Select AllSavers_familyid, Count(*) as [Number of Consults] From pdb_abw.dbo.HealthiestYou_MemberConsults2015  group by AllSavers_familyid
		) a 
		Group by [Number of Consults]
) x 
order by [Number of Consults]


/********************************************************************** DATA REQUEST 1 *************************************************************************************/
/***********************************************************************************************************************************************************

The numbers we need for the break even analysis:
-	Figure 3 from attached document for 2015
-	Figure 4 from attached document for 2015
-	Total Employee Member Months Jan 2015 to Dec 2015 (primaries)
-	Total Member Months Jan 2015 to Dec 2015 (primaries and dependents)
-	Total Number of Consults in 2015
-	Number of Scripts written in 2015
-	Number of Scripts filled in 2015
-	Based on survey data, an estimate of the number of visits that would have been PCP, urgent care, emergency department, and other.


INPUT TABLES:	pdb_ABW.dbo.HealthiestYou_MemberConsults2015
				pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult
				pdb_ABW.dbo.HealthiestYou_Member
				AllSavers_Prod.dbo.Dim_Member
				AllSavers_Prod.dbo.Dim_MemberDetail
				pdb_ABW.dbo.HealthiestYou_DrugCrosswalk

Script for input tables in Github: https://code.savvysherpa.com/SavvysherpaResearch/Asset_MotionBI/blob/master/Healthiest%20You/HY%20Input%20Tables.sql

***********************************************************************************************************************************************************/ 
Use pdb_ABW
Go


/*********************************************
FIGURE 2
**********************************************/

-- Total Consults
Select Role, Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015	
Group By Role
Order By Role Desc
Go

-- Visits within 7 days from consult, by service
Select Role, AS_Service, Count(*)
From
(
	Select Distinct a.*
		, c.MemberID, c.AS_SrvcDt, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 7, a.Consult_Date)
	Where AS_Service in ('UC', 'DR', 'ER')
)	sub
Group By Role, AS_Service
Order By Role Desc
Go


/*********************************************
FIGURE 3
**********************************************/

-- match same diagnosis
--Drop Table #DiagMatch
Select AS_Service, Count(*)
From
(	
	-- Match by ICD 9 Code
	Select Distinct a.*
		, c.MemberID, c.AS_SrvcDt, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 7, a.Consult_Date)
	Where LEFT(a.Icd9Code, 3) = c.AS_ICD9_DiagFst3
		and a.Icd9Code <> ''
	
		UNION
	
	-- Match by ICD 10 Code
	Select Distinct a.*
		, c.MemberID, c.AS_SrvcDt, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 7, a.Consult_Date)
	Where a.ICd10Code = c.AS_ICD10_DiagCd
		and a.Icd10Code <> ''

)	sub
--Where AS_Service in ('UC', 'DR', 'ER')
Group By AS_Service
Go


/*********************************************
MEMBER MONTHS
**********************************************/

-- Employee MM and Member MM by YearMonth
select YearMonth	=	 YearMo
	, EnrolleeMM	=	Count(Distinct Case When MemberType = 'Primary' Then MEMBERID Else Null End)
	, MemberMM		=	Count(Distinct MEMBERID)
  into #MM
From
(
	Select Distinct MemberType	=	Case	When right(y.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary'
											When right(y.SystemID, 1) = 0 and x.MemberID = y.MemberID Then 'Primary' 
											Else 'Dependent' End
		, y.MemberID, y.YearMo
	From
	(
		Select Distinct b.MemberID, b.SystemID
		From
		(
			Select Distinct AllSavers_MemberID, AllSavers_familyID
			From pdb_ABW.dbo.HealthiestYou_Member
			where InAllSavers = 1
		)	a
			Join AllSavers_Prod.dbo.Dim_Member	b	on	a.AllSavers_familyID	=	b.FamilyID
	)	x
		Join AllSavers_Prod.dbo.Dim_MemberDetail	y	on	x.MemberID	=	y.MemberID
	Where y.YearMo between 201501 and 201512
)	c
Group By YearMo
Order By YearMo

Select AVG(EnrolleeMM), AVG(MemberMM)
From #MM

-- Member Count and TOtal Member Months per MemberType
select MemberType
	, MemberCount	=	Count(Distinct MemberID)
	, MemberMonths	=	Count(YearMO)
From
(
	Select Distinct MemberType	=	Case	When right(y.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary'
											When right(y.SystemID, 1) = 0 and x.MemberID = y.MemberID Then 'Primary' 
											Else 'Dependent' End
		, y.MemberID, y.YearMo
	From
	(
		Select Distinct b.MemberID, b.SystemID
		From
		(
			Select Distinct AllSavers_MemberID, AllSavers_familyID
			From pdb_ABW.dbo.HealthiestYou_Member
			where InAllSavers = 1
		)	a
			Join AllSavers_Prod.dbo.Dim_Member	b	on	a.AllSavers_familyID	=	b.FamilyID
	)	x
		Join AllSavers_Prod.dbo.Dim_MemberDetail	y	on	x.MemberID	=	y.MemberID
	Where y.YearMo between 201501 and 201512
)	c
Group By MemberType
Order By MemberType


/*********************************************
# OF CONSULTS 2015
**********************************************/

-- Total Consults by Role
Select Role, Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015	
Group By Role
Order By Role Desc
Go

-- Total Consults by YearMonth
Select ConsultYearMonth, Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015	
Group By ConsultYearMonth
Order By ConsultYearMonth
Go

/*********************************************
SCRIPTS WRITTEN and FILLED
**********************************************/

-- Prescriptions Written
Select Role, Count(*)
From
(
	Select Distinct a.*
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015			a
	Where PrescriptionGiven = 'Yes'
)	sub
Group By Role
Order By Role Desc

-- Scripts Filled within 14 days from consult by Role
Select Role, Count(*)
From
(
	Select a.*
		, c.MemberID, c.AS_RX_NDC, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Left Join pdb_ABW.dbo.HealthiestYou_DrugCrosswalk				d	on	a.PrescriptionNames	=	d.HY_Rx_1
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	a.Gender 	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 14, a.Consult_Date)
																			and d.NDC	=	c.AS_Rx_NDC
	Where PrescriptionGiven = 'Yes'
)	sub
Group By ROle
Order By Role Desc

-- Scripts Filled within 14 days from consult by Service
Select AS_Service, Count(*)
From
(
	Select a.*
		, c.MemberID, c.AS_RX_NDC, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Left Join pdb_ABW.dbo.HealthiestYou_DrugCrosswalk				d	on	a.PrescriptionNames	=	d.HY_Rx_1
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	a.Gender 	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 14, a.Consult_Date)
																			and d.NDC	=	c.AS_Rx_NDC
	Where PrescriptionGiven = 'Yes'
)	sub
Group By AS_Service
Order By AS_Service Desc

--Select *
--From pdb_ABW.dbo.HealthiestYou_MemberConsults2015
--where PrescriptionGiven = 'YES'
--
--Select *
--From pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult
--Where AS_Service in ('ER', 'UC', 'DR')



/*********************************************
Survey Data Visits
**********************************************/

Select [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
	, Total	=	Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015
--Where [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)] in
--	(
--	'Primary Care Physician',
--	'Urgent Care',
--	'Other',
--	'Emergency Room'
--	)
Group By [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
Order By Total Desc



/********************************************************************** DATA REQUEST 2 *************************************************************************************/
/***********************************************************************************************************************************************************

Who are the people using the consults?
	-	Are they different or distinguishable from people who are not making any consult?
	-	Are they more sickly, costly, etc?

	1) Member demographic table (one row per individual)
		-	gender, age, state, consult flag, median income, RAF
	
	2) Utilization pattern
		-	2014 and 2015 claims for members with consults and members with no consults

***********************************************************************************************************************************************************/ 


/************* Temporary Member Table *************/
--Drop Table #Mbrs
Select b.MemberID, b.PolicyID, b.SystemID, b.FamilyID, b.Gender, b.BirthDate
	, Age	=	DATEDIFF(YEAR, b.BirthDate, '2016-01-01')
	, b.MM_2014, b.MM_2015, b.Zip, b.State
	, MemberType	=	Case When Right(b.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary' Else 'Dependent' End
  Into #Mbrs
From (Select Distinct AllSavers_familyID From dbo.HealthiestYou_Member)	a
	Inner Join AllSavers_Prod.dbo.Dim_Member	b	on	a.AllSavers_familyID	=	b.FamilyID
--	177,810 distinct


/*------------------------
CALCULATE 2015 RAF SCORES
------------------------*/

-- Member Table
If (object_id('tempdb..#mbr_2015') Is Not Null)
Drop Table #mbr_2015
select UniqueMemberID = MemberID
	, PolicyID
	, GenderCd = Gender
	, BirthDate
	, AgeLast = Age
  into #mbr_2015
from #Mbrs
where MM_2015 > 0
--176,602
create unique clustered index ucIx_ID on #mbr_2015 (UniqueMemberID);

-- Diagnosis Table
if object_id('pdb_abw.dbo.HealthiestYou_DiagTable2015') is not null
drop table pdb_abw.dbo.HealthiestYou_DiagTable2015
Go
with FC_Date as (
	--choose one record per ClaimNumber, MemberID, SubNumber, ClaimSet based on ClaimSeq to get one date per combo
	--these fields are used to join to Fact_Diagnosis
	select ClaimNumber, MemberID, SubNumber, ClaimSet, 
		FromDate,
		FromYearMo
	from (
		select ClaimNumber, MemberID, SubNumber, ClaimSet,
			FromDate	=	dd.FullDt,
			FromYearMo	=	dd.YearMo, 
			RN = ROW_NUMBER() over (partition by ClaimNumber, MemberID, SubNumber, ClaimSet order by ClaimSeq desc)	--pick one
		from AllSavers_Prod..Fact_Claims	fc
		join AllSavers_Prod..Dim_Date		dd	on	fc.FromDtSysID	=	dd.DtSysId
		join #mbr_2015						mt	on	fc.MemberID		=	mt.UniqueMemberID
												--and dd.YearMo	between	mt.BeginYearMo	and	mt.EndYearMo
		where ServiceTypeSysID	< 4  --exclude pharmacy
			and dd.YearNbr = 2015
			and RecordTypeSysID = 1
		)			a
	where a.rn = 1
	),
FD_Diag as (
	--grab top 3 diag for each claim combo
	select ClaimNumber, MemberID, SubNumber, ClaimSet, DiagDecmCd, FromDate
	from (
		select distinct ClaimNumber, MemberID, SubNumber, ClaimSet, DiagDecmCd, FromDate,
				RN = ROW_NUMBER() over (partition by ClaimNumber, MemberID, SubNumber, ClaimSet order by ClaimNumber desc)
		from (
			select distinct fd.ClaimNumber, fd.MemberID, fd.SubNumber, fd.ClaimSet, dc.DiagDecmCd, a.FromDate
			from FC_Date							a
			join AllSavers_Prod..Fact_Diagnosis		fd	on	a.ClaimNumber	=	fd.ClaimNumber	
														and	a.ClaimSet		=	fd.ClaimSet
														and	a.MemberID		=	fd.MemberID
														and a.SubNumber		=	fd.SubNumber
			join AllSavers_Prod..Dim_DiagnosisCode	dc	on	fd.DiagCdSysID	=	dc.DiagCdSysId
			where DiagDecmCd	<> ''
			)	b
		)	c
	where RN <=3
	)
select distinct UniqueMemberID = m.UniqueMemberID
	, ICDCd					= fd.DiagDecmCd
	, DiagnosisServiceDate	= fd.FromDate
  into pdb_abw.dbo.HealthiestYou_DiagTable2015
from #mbr_2015						as m 
inner join FD_Diag					as fd	on	m.UniqueMemberID	= fd.MemberID
--1,137,666



/******************************************
-- Run RAF stored proc located in DEVSQL10
******************************************/

--Run stored Procedure:
exec RA_Commercial_2014.dbo.spRAFDiagInput
	 @InputPersonTable = '#Mbr_2015'											--Requires fully qualifie v  vd name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = 'pdb_abw.dbo.HealthiestYou_DiagTable2015'			--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_abw'
	,@OutputSuffix = 'HY_2015'


/************** MEMBER TABLE **************/

if object_id('pdb_abw.dbo.HealthiestYou_Member_MasterTable') is not null
drop table pdb_abw.dbo.HealthiestYou_Member_MasterTable
Go
Select Distinct a.MemberID, a.PolicyID, a.SystemID, a.FamilyID
	, a.Gender, a.BirthDate, a.Age, a.MM_2014, a.MM_2015
	, a.Zip, a.State
	, WithConsult		=	IIF(d.AllSavers_FamilyID is null, 0, 1)
	, With2015Claims	=	IIF(e.MEMBERID is null, 0, 1)
	, [2013SocioeconomicScore]	=	Case	when b.SicioEconomicScore > 110 then 110
											when b.SicioEconomicScore > 100 then 100
											when b.SicioEconomicScore > 90 then 90
											when b.SicioEconomicScore > 80 then 80
											when b.SicioEconomicScore > 70 then 70
											when b.SicioEconomicScore > 60 then 60
											when b.SicioEconomicScore > 50 then 50
											when b.SicioEconomicScore > 40 then 40
											when b.SicioEconomicScore > 30 then 30
											when b.SicioEconomicScore > 20 then 20
											when b.SicioEconomicScore > 10 then 10
											when b.SicioEconomicScore >  0 then  0
									End
	, [2013IncomePercentile]	=	Case	when b.incomepercentile > 90 then 90
											when b.incomepercentile > 80 then 80
											when b.incomepercentile > 70 then 70
											when b.incomepercentile > 60 then 60
											when b.incomepercentile > 50 then 50
											when b.incomepercentile > 40 then 40
											when b.incomepercentile > 30 then 30
											when b.incomepercentile > 20 then 20
											when b.incomepercentile > 10 then 10
											when b.incomepercentile >  0 then  0
									End
	, RAF						=	c.SilverTotalScore
	, a.MemberType
  Into pdb_abw.dbo.HealthiestYou_Member_MasterTable
From #Mbrs														a
Left Join [pdb_ABW].[dbo].AllSaversKBM_ZipCOde					b	on	a.Zip		=	b.Zip
Left Join [pdb_ABW].[dbo].[RA_Com_Q_MetalScoresPivoted_HY_2015]	c	on	a.MemberID	=	c.UniqueMEMBERID
Left Join (Select Distinct AllSavers_familyID, Age, Gender
			From pdb_ABW.dbo.HealthiestYou_MemberConsults2015)	d	on	a.FamilyID	=	d.AllSavers_familyID
																	and	a.Gender	=	d.Gender
																	and d.Age between a.Age - 1 and a.Age + 1
Left Join (Select Distinct MEMBERID, POLICYID, SYSTEMID
			FROM AllSavers_Prod.dbo.Fact_Claims	fc
			Join AllSavers_Prod.dbo.Dim_Date	dd
				On	fc.FromDtSysID	=	dd.DtSysId
			Where dd.YearNbr = 2015)							e	On	a.MemberID	=	e.MemberID
																	and	a.PolicyID	=	e.PolicyID
																	and	a.SystemID	=	e.SystemID
Go
-- 177,810

Select MemberID, PolicyID, SystemID, FamilyID, Count(*)
From pdb_abw.dbo.HealthiestYou_Member_MasterTable
Group By MemberID, PolicyID, SystemID, FamilyID
Having Count(*) > 1

--Select * From pdb_abw.dbo.HealthiestYou_Member_MasterTable


/************** 2014 and 2015 CLAIMS **************/

-- Members with Consult
if object_id ('pdb_ABW.dbo.HealthiestYou_Claims2014and2015_MemberswConsult') is not null
drop table pdb_ABW.dbo.HealthiestYou_Claims2014and2015_MemberswConsult
Select a.MemberID, a.PolicyID, a.SystemID, a.FamilyID, a.BirthDate, a.Gender, a.Age
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
	,MemberType		=	Case When right(a.SystemID, 1) = 0 Then 'Primary' Else 'Dependent' End
  Into pdb_ABW.dbo.HealthiestYou_Claims2014and2015_MemberswConsult
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
	and dd.YearNbr in (2014, 2015)
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
-- 2015: 73,452
-- 2014and2015: 78,284


-- Members with no Consult
if object_id ('pdb_ABW.dbo.HealthiestYou_Claims2014and2015_MemberswNoConsult') is not null
drop table pdb_ABW.dbo.HealthiestYou_Claims2014and2015_MemberswNoConsult
Select m.MemberID, m.PolicyID, m.SystemID, m.FamilyID
	,fc.ClaimNumber
	,AS_SrvcDt				=	dd.FullDt
	,AS_DiagCd				=	dc.DiagDecmCd
	,AS_DiagFst3			=	left(rtrim(ltrim(dc.DiagDecmCd)),3)	
	,AS_DiagDesc			=	dc.DiagDesc
	,AS_DiagDtl				=	dc.AHRQDiagDtlCatgyNm
	,AS_DiagGnl				=	dc.AHRQDiagGenlCatgyNm
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
	,MemberType		=	Case When right(m.SystemID, 1) = 0 Then 'Primary' Else 'Dependent' End
  Into pdb_ABW.dbo.HealthiestYou_Claims2014and2015_MemberswNoConsult
From
(-- 4,230 Distinct Indivs
	select b.MemberID, b.PolicyID, b.SystemID, b.FamilyID
	From	(-- 100,719
			Select Distinct AllSavers_familyID
			from pdb_ABW.dbo.HealthiestYou_Member
			Where InAllSavers = 1
				and WithConsult = 0
			)							a
	join AllSavers_Prod.dbo.Dim_Member	b	On	a.AllSavers_familyID	=	b.FamilyID
		
)											m
join Allsavers_Prod.dbo.Fact_Claims			fc	on	m.MemberID			=	fc.MemberID
												and	m.PolicyID			=	fc.PolicyID
												and	m.SystemID			=	fc.SystemID
join Allsavers_Prod.dbo.Dim_Date			dd	on	fc.FromDtSysID		=	dd.DtSysId
join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc	on	fc.DiagCdSysId		=	dc.DiagCdSysId
join Allsavers_Prod.dbo.Dim_ProcedureCode	pc	on	fc.ProcCdSysID		=	pc.procCdsysid
join allsavers_prod.dbo.Dim_ServiceCode		sc	on	fc.ServiceCodeSysID	=	sc.ServiceCodeSysID
join Allsavers_Prod.dbo.Dim_NDCDrug			ndc on	fc.NDCDrugSysID		=	ndc.NDCDrugSysID
Where fc.RecordTypeSysID = 1
	and dd.YearNbr in (2014, 2015)
Group by m.MemberID, m.PolicyID, m.SystemID, m.FamilyID
	, fc.ClaimNumber
	, dd.FullDt
	, dc.DiagDecmCd
	, left(rtrim(ltrim(dc.DiagDecmCd)),3)
	, dc.DiagDesc
	, dc.AHRQDiagDtlCatgyNm
	, dc.AHRQDiagGenlCatgyNm
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
-- 2015: 1,588,014
-- 2014 and 2015: 1,724,450


-- All HY and AllSavers 2015 Claims
if object_id ('pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers') is not null
drop table pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers
Select a.MemberID, a.PolicyID, a.SystemID, a.FamilyID
	,fc.ClaimNumber
	,AS_SrvcDt		=	dd.FullDt
	,AS_DiagCd		=	dc.DiagDecmCd
	,AS_DiagFst3	=	left(rtrim(ltrim(dc.DiagDecmCd)),3)	
	,AS_DiagDesc	=	dc.DiagDesc
	,AS_DiagDtl		=	dc.AHRQDiagDtlCatgyNm
	,AS_DiagGnl		=	dc.AHRQDiagGenlCatgyNm
	,AS_Service		=	case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
								when ServiceCodeLongDescription like '%urgent%'			then	'UC'
								when (
									ProcDesc like '%office%visit%'  
									or srvccatgydesc like '%evaluation%management%'
									)													then	'DR'
								when ServiceTypeSysID = 4								then	'RX'
								else 'Others'
						end 
	,AS_Rx_Brnd		=	ndc.BrndNm
	,AS_Rx_Gnrc		=	ndc.GnrcNm
	,AllwAmt		=	Sum(fc.AllwAmt)
	,AS_Rx_NDC		=	ndc.NDC
	,a.MemberType		
  Into pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers
From pdb_ABW.dbo.HealthiestYou_Member_MasterTable	a
	Inner join Allsavers_Prod.dbo.Fact_Claims		fc	on	a.MemberID			=	fc.MemberID
		 												and	a.PolicyID			=	fc.PolicyID
		 												and	a.SystemID			=	fc.SystemID
	Inner join Allsavers_Prod.dbo.Dim_Date			dd	on	fc.FromDtSysID		=	dd.DtSysId
	Inner join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc	on	fc.DiagCdSysId		=	dc.DiagCdSysId
	Inner join Allsavers_Prod.dbo.Dim_ProcedureCode	pc	on	fc.ProcCdSysID		=	pc.procCdsysid
	Inner join allsavers_prod.dbo.Dim_ServiceCode	sc	on	fc.ServiceCodeSysID	=	sc.ServiceCodeSysID
	Inner join Allsavers_Prod.dbo.Dim_NDCDrug		ndc on	fc.NDCDrugSysID		=	ndc.NDCDrugSysID
Where fc.RecordTypeSysID = 1
	and dd.YearNbr = 2015
Group by a.MemberID, a.PolicyID, a.SystemID, a.FamilyID
	, fc.ClaimNumber
	, dd.FullDt
	, dc.DiagDecmCd
	, left(rtrim(ltrim(dc.DiagDecmCd)),3)
	, dc.DiagDesc
	, dc.AHRQDiagDtlCatgyNm
	, dc.AHRQDiagGenlCatgyNm
	, case	when sc.ServiceCodeLongDescription like '%emerg%'		then	'ER'
	 		when sc.ServiceCodeLongDescription like '%urgent%'		then	'UC'
	 		when (
	 			pc.ProcDesc like '%office%visit%'  
	 			or pc.srvccatgydesc like '%evaluation%management%'
	 			)													then	'DR'
			when ServiceTypeSysID = 4								then	'RX'
	 		else 'Others'
	 end 
	, ndc.BrndNm
	, ndc.GnrcNm
	, ndc.NDC
	, a.MemberType
Go
-- 1,702,376