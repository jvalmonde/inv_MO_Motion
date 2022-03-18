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