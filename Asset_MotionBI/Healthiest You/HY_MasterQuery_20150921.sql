--------------------------------------------
----	CREATE MASTER MEMBER TABLE		----
--------------------------------------------

-- Member Table at Name + DOB + IDs + MemberType + Name --
if object_id ('tempdb..#mem') is not null
drop table #mem

Select Distinct Member	=	Replace(a.First,'|',' ') + ' ' + Replace(a.Last,'|',' ')	 + ' ' + convert(varchar,DOB2) + ' ' + ExigoID
	,First				=	Replace(a.First,'|',' ')	
	,Last				=	Replace(a.Last,'|',' ')	
	,DOB2				=	convert(date,DOB2)
	,NameDOB			=	First + ' ' + Last + ' ' + convert(varchar,convert(date,DOB2))
	,ExigoID
	,ID2
	,MemberType
Into #mem
From pdb_HealthiestYou..hyuhg_members		a
Where First + ' ' + Last + ' ' + convert(varchar,DOB2) + ' ' + ExigoID in (
	Select First + ' ' + Last + ' ' + convert(varchar,DOB2) + ' ' + ExigoID
	From pdb_HealthiestYou..hyuhg_members
	Where First <> ''
		or Last <> ''
	Group by First + ' ' + Last + ' ' + convert(varchar,DOB2) + ' ' + ExigoID
	Having Count(Distinct MemberType) = 1
	)											
UNION
Select Distinct Member	=	Replace(a.First,'|',' ')	 + ' ' + Replace(a.Last,'|',' ')	 + ' ' + convert(varchar,DOB2) + ' ' + ExigoID
	,First				=	Replace(a.First,'|',' ')	
	,Last				=	Replace(a.Last,'|',' ')
	,DOB2				=	convert(date,DOB2)
	,NameDOB			=	First + ' ' + Last + ' ' + convert(varchar,convert(date,DOB2))
	,ExigoID
	,ID2
	,MemberType = 'Dependent'
From pdb_HealthiestYou..hyuhg_members			a
Where First + ' ' + Last + ' ' + convert(varchar,DOB2) + ' ' + ExigoID in (
	Select First + ' ' + Last + ' ' + convert(varchar,DOB2) + ' ' + ExigoID
	From pdb_HealthiestYou..hyuhg_members
	Where First <> ''
		or Last <> ''
		--and MemberType in ('Dependent','Spouse')
	Group by First + ' ' + Last + ' ' + convert(varchar,DOB2) + ' ' + ExigoID
	Having Count(Distinct MemberType) > 1
	)
-- 141156 Only 1 record was excluded from above code: First = '' and Last = ''

-- Members with AllSavers in 2015--
if object_id ('tempdb..#als') is not null
drop table #als

Select Distinct FirstName
	,LastName
	,Birthdate
	,NameDOB				=	 FirstName + ' ' + LastName	 + ' ' + convert(varchar,Birthdate) 
	,ExigoID
	,MemberID
	,PolicyID
	,MM_2015
Into #als
From #mem							a
join AllSavers_Prod..Dim_Member		c	on	a.First		=	c.FirstName
										and	a.Last		=	c.LastName	
										and	a.DOB2		=	c.Birthdate
Where MM_2015 > 0
-- 128062

-- Identify individuals who are in HY but not in AllSavers -- (For exclusion in family-level aggregation)
if object_id ('tempdb..#noals') is not null
drop table #noals

Select Distinct NameDOB
Into #noals
From #mem
Except
Select Distinct NameDOB 
From #als
-- 1186

-- Create Member Names + DOB + ExigoID - level Member table --
if object_id ('pdb_HealthiestYou..hyuhg_Master_Member') is not null
drop table pdb_HealthiestYou..hyuhg_Master_Member

Select  a.Member
	,a.NameDOB
	,a.First
	,a.Last
	,a.DOB2
	,a.MemberType
	,a.ExigoID
	,Family_Claim_ID		=	case when a.ExigoID like 'c0%' and a.ExigoID <> '' then right(a.ExigoID,7) else NULL end
	,FamilyMemberCount
	,WithConsult			=	max(	case	when	b.Reporting2 is not null	then	1	else	0	end)
	,WithAllSavers			=	max(	case	when	c.FirstName is not null		then	1	else	0	end)
	,WithAllSaversClaim		=	max(	case	when	d.MemberID is not null		then	1	else	0	end)
	,WithMembersInAllSavers	=	max(	case	when	f.ExigoID is null			then	1	else	0	end)
Into pdb_HealthiestYou..hyuhg_Master_Member
From #mem												a
join (
	Select ExigoID
		,FamilyMemberCount		=	Count(Distinct Member)
	From #mem
	Group by ExigoID
	)													e	on	a.ExigoID	=	e.ExigoID
left join pdb_HealthiestYou..Raw_Consult_Export_NEW		b	on	a.ID2		=	b.Reporting2
left join #als											c	on	a.First		=	c.FirstName
															and	a.Last		=	c.LastName	
															and	a.DOB2		=	c.Birthdate
left join AllSavers_Prod..Fact_Claims					d	on	c.MemberID	=	d.MemberID
															and	c.PolicyID	=	d.PolicyID
left join (
	Select ExigoID
	From #mem
	Where NameDOB in (
		Select Distinct NameDOB
		From #noals
		)
	)													f	on	a.ExigoID	=	f.ExigoID
Group by a.Member
	,a.NameDOB
	,a.First
	,a.Last
	,a.DOB2
	,a.MemberType
	,a.ExigoID
	,case when a.ExigoID like 'c0%' and a.ExigoID <> '' then right(a.ExigoID,7) else NULL end
	,FamilyMemberCount
-- 139882

				-- Count of Members --
				Select MemberType
					,Count(Distinct Member)		--	HY Members
					,Sum(WithAllSavers)			--	HY-ALS Member match
					,Sum(WithConsult)			--	HY-MD Member match
				From pdb_HealthiestYou..hyuhg_Master_Member
				Group by MemberType
				--

						/* September 17, 2015; 11:25pm
						MemberType		(No column name)	(No column name)	(No column name)
						Dependent		40168				37827				1747
						Primary			78448				76170				1847
						Spouse			21266				20569				768
						*/

--
Select *
From pdb_HealthiestYou..hyuhg_Master_Member

/*
Sample:		AllMembersinAllSavers	Member not in AllSavers					MemberType
C05219294	0						AADHYA MALYALA 2/8/2011 C05219294		Dependent
C05190753	0						AADVIKA GAVVA 7/20/2015 C05190753		Dependent
C05197459	1						-none-
C05165577	0						AAHNA METTU 2/18/2015 C05165577			Dependent
C05140382	1						-none-
C05136886	1						-none-
*/

--------------------------------------------
--	CREATE MASTER ALLSAVERS CLAIM TABLE	  --
--------------------------------------------

-- Claims 
if object_id ('pdb_HealthiestYou..hyuhg_ASClaims') is not null
drop table pdb_HealthiestYou..hyuhg_ASClaims

Select mm.FirstName
	,mm.LastName
	,mm.Birthdate
	,mm.MemberID
	,mm.PolicyID
	,fc.ClaimNumber
	,AS_SrvcDt				=	dd.FullDt
	,AS_DiagCd				=	dc.DiagDecmCd
	,AS_DiagFst3			=	left(rtrim(ltrim(dc.DiagDecmCd)),3)	
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
Into pdb_HealthiestYou..hyuhg_ASClaims
From Allsavers_Prod.dbo.Fact_Claims				fc
join Allsavers_Prod.dbo.Dim_Date				dd	on		fc.FromDtSysID			= dd.DtSysId
join AllSavers_Prod..Dim_Member					mm	on		fc.MemberID				= mm.MemberID
													and		fc.PolicyID				= mm.PolicyID
join Allsavers_Prod.dbo.Dim_DiagnosisCode		dc	on		fc.DiagCdSysId			= dc.DiagCdSysId
join Allsavers_Prod.dbo.Dim_ProcedureCode		pc	on		fc.ProcCdSysID			= pc.procCdsysid
join allsavers_prod.dbo.Dim_ServiceCode			sc	on		fc.ServiceCodeSysID		= sc.ServiceCodeSysID
join Allsavers_Prod.dbo.Dim_NDCDrug				ndc on		fc.NDCDrugSysID			= ndc.NDCDrugSysID

Where fc.RecordTypeSysID = 1
	and Year(dd.FullDt) in ('2014','2015')
Group by mm.FirstName
	,mm.LastName
	,mm.Birthdate
	,mm.MemberID
	,mm.PolicyID
	,fc.ClaimNumber
	,dd.FullDt
	,dc.DiagDecmCd
	,left(rtrim(ltrim(dc.DiagDecmCd)),3)	
	,dc.AHRQDiagDtlCatgyNm
	,dc.AHRQDiagGenlCatgyNm
	,case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
			when ServiceCodeLongDescription like '%urgent%'			then	'UC'
			when (
				ProcDesc like '%office%visit%'  
				or srvccatgydesc like '%evaluation%management%'
				)													then	'DR'
			else 'Others'
	end 
	,ndc.BrndNm
	,ndc.GnrcNm
	,ndc.NDC
-- 1818461

--------------------------------------------
--		CREATE MASTER HY CONSULTS TABLE	  --
--------------------------------------------

-- Distinct Consults
if object_id ('pdb_HealthiestYou..hyuhg_HYConsults') is not null
drop table pdb_HealthiestYou..hyuhg_HYConsults

Select Distinct a.First
	,a.Last
	,a.DOB2
	,a.ExigoID
	,Role
	,Family_Claim_ID		=	case when a.ExigoID like 'c0%' and a.ExigoID <> '' then right(a.ExigoID,7) else NULL end
	,b.Diagnosis
	,b.ICD9_Code_1
	,b.ICD9_Code_2
	,b.ICD9_Code_3
	,b.ICD9_Code_4
	,ICD9_Fst3				=	left(rtrim(ltrim(b.ICD9_Code_1)),3)
	,b.Prescription_Names_1
	,b.Prescription_Names_2
	,b.Prescription_Names_3
	,b.Prescription_Names_4
	,Consult_Date			=	convert(date,Call_Start_Date)
	,MemberType
	,Prescription_Given
	,ID2
Into pdb_HealthiestYou..hyuhg_HYConsults
From (
	Select *                                                                                                                                                                                                       
	From pdb_HealthiestYou..Raw_Consult_Export_NEW
	)										b
join (
	Select *
	From pdb_HealthiestYou..hyuhg_members
		)									a		on	b.Reporting2	=	a.ID2
-- 7038 

--------------------------------------------
--		CREATE DRUG CROSSWALK TABLE		  --
--------------------------------------------

--
if object_id ('pdb_HealthiestYou..hyuhg_DrugCrosswalk') is not null
drop table pdb_HealthiestYou..hyuhg_DrugCrosswalk

Select Distinct HY_Rx_1 = a.Brnd_Nm, b.NDC
Into pdb_HealthiestYou..hyuhg_DrugCrosswalk
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
-- 65920

--------------------------------------------
--	CREATE FAMILY AND INDIVIDUALS TABLES  --
--------------------------------------------

----		FAMILY LEVEL	----
-- Create table of individuals with all members of family in AllSavers
if object_id ('tempdb..#family') is not null
drop table #family

Select Distinct a.Member
	,a.NameDOB
	,a.First
	,a.Last
	,a.DOB2
	,a.ExigoID
	,Family_Claim_ID		=	case when a.ExigoID like 'c0%' and a.ExigoID <> '' then right(a.ExigoID,7) else NULL end
	,b.MemberID
	,b.PolicyID
	,a.WithConsult
Into #family
From pdb_HealthiestYou..hyuhg_Master_Member		a
join #als										b	on	a.NameDOB	=	b.NameDOB
Where WithMembersInAllSavers = 1
-- 121122

----	INDIVIDUAL LEVEL	----
-- 
if object_id ('tempdb..#individuals') is not null
drop table #individuals

Select Distinct a.Member
	,a.NameDOB
	,a.First
	,a.Last
	,a.DOB2
	,a.ExigoID
	,a.WithConsult
	,Family_Claim_ID		=	case when a.ExigoID like 'c0%' and a.ExigoID <> '' then right(a.ExigoID,7) else NULL end
Into #individuals
From (
	Select *
	From #mem
	Where MemberType = 'Primary' 
	UNION
	Select *
	From #mem
	Where ExigoID not in (
		Select Distinct ExigoID
		From #mem
		Where MemberType = 'Dependent'
		)
	) a	
left join pdb_HealthiestYou..hyuhg_Master_Member	a.Member	=
-- 86633

--------------------------------------------
----				COUNTER				----
--------------------------------------------

---- All Members
Select MemberType
	,Count(Distinct Member)
	,Count(Distinct ExigoID)
	,Count(Distinct NameDOB)
	,Sum(WithConsult)
	,Sum(WithAllSavers)
	,Sum(WithAllSaversClaim)
	,Sum(WithMembersInAllSavers)
	,Count(Distinct case when WithMembersinAllSavers = 1 then exigoid else null end)
From pdb_HealthiestYou..hyuhg_Master_Member
Group by MemberType
--

---- Family
Select MemberType
	,Count(Distinct Member)
	,Count(Distinct ExigoID)
	,Count(Distinct NameDOB)
	,Sum(WithConsult)
	,Sum(WithAllSavers)
	,Sum(WithAllSaversClaim)
	,Sum(WithMembersInAllSavers)
	,Count(Distinct case when WithMembersinAllSavers = 1 then exigoid else null end)
From pdb_HealthiestYou..hyuhg_Master_Member
Where Member in (
	Select Distinct Member
	From #family
	)
Group by MemberType
--

---- Individual
Select MemberType
	,Count(Distinct Member)
	,Count(Distinct ExigoID)
	,Count(Distinct NameDOB)
	,Sum(WithConsult)
	,Sum(WithAllSavers)
	,Sum(WithAllSaversClaim)
	,Sum(WithMembersInAllSavers)
	,Count(Distinct case when WithMembersinAllSavers = 1 then exigoid else null end)
From pdb_HealthiestYou..hyuhg_Master_Member
Where Member in (
	Select Distinct Member
	From #individuals
	)
Group by MemberType
--

--------------------------------------------
----				PEPM				----
--------------------------------------------

---- FAMILY

-- PEPM
Select WithConsult
	,AvgMM2015					=	Sum(TtlMM2015)*1./Count(Distinct family_Claim_id)
	,Avg_PEPM_AllwAmt			=	Avg(PEPM_AllwAmt)		
	,Avg_PEPM_DerivedAllwAmt	=	Avg(PEPM_DerivedAllwAmt)
	,Ttl_MM2015					=	Sum(TtlMM2015)
	,Ttl_Families				=	Count(Distinct family_Claim_id)
	,Ttl_AllwAmt				=	Sum(TtlAllwAmt)
	,Ttl_DerivedAllwAmt			=	Sum(TtlDerivedAllwAmt)
From (
	Select b.family_Claim_id
		,b.WithConsult
		,TtlMM2015				=	Sum(b.MM_2015)
		,TtlAllwAmt				=	Sum(a.AllwAmt)
		,TtlDerivedAllwAmt		=	Sum(a.DerivedAllowed)
		,PEPM_AllwAmt			=	Sum(a.AllwAmt)*1./Sum(b.MM_2015)
		,PEPM_DerivedAllwAmt	=	Sum(a.DerivedAllowed)*1./Sum(b.MM_2015)
	From (
		Select ClaimNumber
			,AllwAmt		=	Sum(AllwAmt)
			,DerivedAllowed	=	Sum(DerivedAllowed)
		From AllSavers_Prod..Fact_Claims	a
		join AllSavers_Prod..Dim_Date		c on a.FromDtSysID = c.DtSysId
		Where Year(c.FullDt) = '2015'
		Group by ClaimNumber	
		)											a
	join (
		Select *
		From #Family
		)											b on a.ClaimNumber = b.family_Claim_id
	Group by b.family_Claim_id
		,b.WithConsult
	) a
Group by WithConsult
--

-- PEPM Member Count
Select b.WithConsult
	,Count(Distinct a.Member)
	,Count(Distinct a.ExigoID)
From pdb_HealthiestYou..hyuhg_Master_Member		a
join (
		Select *
		From #Family
		)											b	on	a.Family_Claim_ID	=	b.Family_Claim_ID
Group by b.WithConsult
--

-- Average PEPM (total)
Select Avg(PEPM_AllwAmt)
From (
	Select b.Family_Claim_ID
		,b.WithConsult
		,TtlMM2015				=	Sum(b.MM_2015)
		,TtlAllwAmt				=	Sum(a.AllwAmt)
		,TtlDerivedAllwAmt		=	Sum(a.DerivedAllowed)
		,PEPM_AllwAmt			=	Sum(a.AllwAmt)*1./Sum(b.MM_2015)
		,PEPM_DerivedAllwAmt	=	Sum(a.DerivedAllowed)*1./Sum(b.MM_2015)
	From (
		Select ClaimNumber
			,AllwAmt		=	Sum(AllwAmt)
			,DerivedAllowed	=	Sum(DerivedAllowed)
		From AllSavers_Prod..Fact_Claims	a
		join AllSavers_Prod..Dim_Date		c on a.FromDtSysID = c.DtSysId
		Where Year(c.FullDt) = '2015'
		Group by ClaimNumber	
		)											a
	join (
		Select *
		From #Family
		)											b on a.ClaimNumber = b.Family_Claim_ID
	Group by b.Family_Claim_ID
		,b.WithConsult
	) a
--

---- INDIVIDUALS

-- PEPM
Select WithConsult
	,AvgMM2015					=	Sum(TtlMM2015)*1./Count(Distinct family_Claim_id)
	,Avg_PEPM_AllwAmt			=	Avg(PEPM_AllwAmt)		
	,Avg_PEPM_DerivedAllwAmt	=	Avg(PEPM_DerivedAllwAmt)
	,Ttl_MM2015					=	Sum(TtlMM2015)
	,Ttl_Families				=	Count(Distinct family_Claim_id)
	,Ttl_AllwAmt				=	Sum(TtlAllwAmt)
	,Ttl_DerivedAllwAmt			=	Sum(TtlDerivedAllwAmt)
From (
	Select a.ClaimNumber
		,a.PolicyID
		,a.MemberID
		,a.WithConsult
		,TtlMM2015				=	Sum(b.MM_2015)
		,TtlAllwAmt				=	Sum(a.AllwAmt)
		,TtlDerivedAllwAmt		=	Sum(a.DerivedAllowed)
		,PEPM_AllwAmt			=	Sum(a.AllwAmt)*1./Sum(b.MM_2015)
		,PEPM_DerivedAllwAmt	=	Sum(a.DerivedAllowed)*1./Sum(b.MM_2015)
	From (
		Select MemberID
			,PolicyID
			,ClaimNumber
			,AllwAmt		=	Sum(AllwAmt)
			,DerivedAllowed	=	Sum(DerivedAllowed)
		From AllSavers_Prod..Fact_Claims	a
		join AllSavers_Prod..Dim_Date		c on a.FromDtSysID = c.DtSysId
		Where Year(c.FullDt) = '2015'
		Group by MemberID
			,PolicyID
			,ClaimNumber	
		)											a
	join (
		Select *
		From #individuals
		)											b	on	a.ClaimNumber	= b.family_Claim_id
														and	a.MemberID		=	b.MemberID
														and a.PolicyID		=	b.PolicyID	
	Group by b.ClaimNumber
		,b.PolicyID
		,b.MemberID
		,b.WithConsult
	) a
Group by WithConsult
--

-- PEPM Member Count
Select b.WithConsult
	,Count(Distinct a.Member)
	,Count(Distinct a.ExigoID)
From pdb_HealthiestYou..hyuhg_Master_Member		a
join (
		Select *
		From #individuals
		)											b	on	a.ClaimNumber	= b.family_Claim_id
														and	a.MemberID		=	b.MemberID
														and a.PolicyID		=	b.PolicyID
Group by b.WithConsult
--

-- Average PEPM (total)
Select Avg(PEPM_AllwAmt)
From (
	Select b.Family_Claim_ID
		,b.WithConsult
		,TtlMM2015				=	Sum(b.MM_2015)
		,TtlAllwAmt				=	Sum(a.AllwAmt)
		,TtlDerivedAllwAmt		=	Sum(a.DerivedAllowed)
		,PEPM_AllwAmt			=	Sum(a.AllwAmt)*1./Sum(b.MM_2015)
		,PEPM_DerivedAllwAmt	=	Sum(a.DerivedAllowed)*1./Sum(b.MM_2015)
	From (
		Select ClaimNumber
			,AllwAmt		=	Sum(AllwAmt)
			,DerivedAllowed	=	Sum(DerivedAllowed)
		From AllSavers_Prod..Fact_Claims	a
		join AllSavers_Prod..Dim_Date		c on a.FromDtSysID = c.DtSysId
		Where Year(c.FullDt) = '2015'
		Group by ClaimNumber	
		)											a
	join (
		Select *
		From #individuals
		)											b	on	a.ClaimNumber	= b.family_Claim_id
														and	a.MemberID		=	b.MemberID
														and a.PolicyID		=	b.PolicyID
	Group by b.Family_Claim_ID
		,b.WithConsultc
	) a
--