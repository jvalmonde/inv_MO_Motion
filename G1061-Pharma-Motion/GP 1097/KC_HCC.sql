/*** 
GP 1097 - Polypharmacy top HCCs

Input databases:	MiniPAPI, MiniOV, RA_Medicare

Date Created: 03 July 2017
***/

--select count(*), count(distinct SavvyHICN) from pdb_PharmaMotion..G1097Members	--1,846,983

--pull for ESRD diagnosis & flag members with ESRD
If (object_id('tempdb..#mmr') Is Not Null)
Drop Table #mmr
go

select a.SavvyHICN, ESRDFlag = max(case when b.ESRDFlag = 'Y'	then 1	else 0	end)
	, OREC = max(OriginalReasonForEntitlement)
	, MCAID = max(MedicaidStatusFlag)
into #mmr
from pdb_PharmaMotion..G1097Members	a
inner join CmsMMR..CmsMMR				b	on	a.SavvyHICN = b.SavvyHICN
--where b.ESRDFlag = 'Y'
group by a.SavvyHICN
--(2,088,133 row(s) affected); 5.23 minutes
create unique index uIx_SavvyHICN on #mmr (SavvyHICN);

select * from #mmr where ESRDFlag = 1	--9,463
select * from #mmr where SavvyHICN = 18729764	--OREC = 1
select OREC, count(distinct SavvyHICN)
from #mmr
group by OREC


--pull for those members who were diagnosed in 2016
If (object_id('tempdb..#esrd_diag') Is Not Null)
Drop Table #esrd_diag
go

select *
into #esrd_diag
from MiniOV..Dim_Diagnosis_Code
where (DIAG_CD = '5856'
	and DIAG_DESC not like 'unk%'
	and ICD_VER_CD = 9)
	or (DIAG_CD = 'N186'
	and DIAG_DESC not like 'unk%'
	and ICD_VER_CD = 0)
--2
create unique index uIx_DiagSys on #esrd_diag (Diag_Cd_Sys_Id);

If (object_id('tempdb..#esrd_flag') Is Not Null)
Drop Table #esrd_flag
go

select a.SavvyHICN, ESRDFlag = 1
into #esrd_flag
from	(
			select a.*
			from pdb_PharmaMotion..G1097Members	a
			left join #mmr						b	on	a.SavvyHICN = b.SavvyHICN
													and b.ESRDFlag = 1
			where b.SavvyHICN is null
		) a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Fact_Diagnosis		c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID
inner join #esrd_diag					e	on	c.Diag_Cd_Sys_Id = e.Diag_Cd_Sys_Id
where d.YEAR_NBR = 2016
group by a.SavvyHICN
--(8992 row(s) affected)
create unique index uIx_SavvyHICN on #esrd_flag (SavvyHICN);

--select * from #esrd_flag where SavvyHICN = 18729764

--member input table
If (object_id('tempdb..#member') Is Not Null)
Drop Table #member
go

select UniqueMemberID = a.SavvyHICN
	, GenderCd = a.Gender
	, Age = a.Age_2016
	, MCAID = case when d.SavvyHICN is not null then d.MCAID	else c.MedicaidFlag	end
	, NEMCAID = null
	, OREC = case when (d.SavvyHICN is not null and d.ESRDFlag = 1)
					or (e.SavvyHICN is not null and e.ESRDFlag = 1)					then 2
				when d.OREC = 9 or (d.SavvyHICN is null and e.SavvyHICN is null)	then 0	else d.OREC	end
	--, d.OREC
into #member
from pdb_PharmaMotion..G1097Members	a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Dim_Member			c	on	b.SavvyID = c.SavvyID
left join #mmr							d	on	a.SavvyHICN = d.SavvyHICN
left join #esrd_flag					e	on	a.SavvyHICN = e.SavvyHICN
--where a.SavvyHICN in (9649676, 1503277, 1984857, 18325205, 18729764)
--(2173266 row(s) affected)
create unique index uIx_MemberID on #member (UniqueMemberID);

select OREC, count(*)
from #member
group by OREC


--diagnosis input table
If (object_id('tempdb..#ip_conf') Is Not Null)
Drop Table #ip_conf
go

select a.SavvyHICN, b.SavvyID
	, Admit_DtSys		= c.DT_SYS_ID
	, Discharge_DtSys	= e.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by a.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf
from pdb_PharmaMotion..G1097Members		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID
inner join MiniOV..Dim_Date				e	on	(c.Dt_Sys_Id + c.Day_Cnt) = e.DT_SYS_ID
where d.YEAR_NBR = 2016
	and c.Admit_Cnt = 1
group by a.SavvyHICN, b.SavvyID, c.DT_SYS_ID, e.DT_SYS_ID
--(485,294 row(s) affected); 16.04 minutes
create unique index uIx_SavvyID_DtSys on #ip_conf (SavvyID, Admit_DtSys, Discharge_DtSys);


If (object_id('tempdb..#diag') Is Not Null)
Drop Table #diag
go

select UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, IcdVerCd = c.ICD_VER_CD
into #diag
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #member	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2016				--Year of Interest	
	  and(
				--CMS-1500 claims with an eligible CPT codes
				   (a.Srvc_Typ_Sys_Id in (2, 3)	--OP or DR Service Type
				and a.Rvnu_Cd_Sys_Id <= 2)		--CMS-1500 Claim Form
		   or
				--CMS-1450 claims with eligible Bill Type and CPT codes
				   (a.Srvc_Typ_Sys_Id = 2		--OP Service Type
				and a.Bil_Typ_Cd in ('131', '132', '133', '134', '136', '137', 
									 '710', '711', '712', '713', '714', '715', '716', '717', '718', '719',
									 '760', '761', '762', '763', '764', '765', '766', '767', '768', '769',
									 '770', '771', '772', '773', '774', '775', '776', '777', '778', '779'))
		 )
	UNION
	--IP (not perfect, consecutive IP stays can result in one claim duplicated in multiple confinements)
	select a.SavvyId, b.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims	as a 
	join #ip_conf				as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Diagnosis		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
									   and b.Diag_Type in (1, 2, 3)	--first 3 diags only
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID
where d.YEAR_NBR = 2016
group by a.SavvyHICN, c.DIAG_CD, c.ICD_VER_CD
--(34,933,014 row(s) affected); 31.24 minutes
create clustered index cIx_ID_DiagCd on #diag (UniqueMemberID, DiagCd);

/*--takes a lot of time
Exec [RA_Medicare].dbo.spRAFDiagnosisDemographicInput				--use this if there are ICD10s
	  @ModelID = 28	--community 2015 RAF calculator
	, @InputDiagnosisTableLocation 		= '#diag'	
	, @InputDemographicsTableLocation	= '#member'	
	, @OutputDatabase					= 'pdb_PharmaMotion'
	, @OutputSuffix						= 'G1097_2016'
*/

--------------------------------
--use these scripts instead
--------------------------------
--1	--Identify the list of ModelID's that we would like to process based on parameter passed.
If Object_Id('#TempTableLkupModelID') is not null
	Drop Table #TempTableLkupModelID ;

Select distinct ModelID
into #TempTableLkupModelID
From RA_Medicare.dbo.Model a
Where ModelID = 31			--2016 RAF calculator (Community)
or BlendedModelID = 31

--********************************************************************************************************************************
--Start to build the stored procedure logic that will be used to calculate RAF for a dataset as well as provide an audit trail.
--********************************************************************************************************************************
--A	--Find the HCC's that map to this individuals Diagnosis Codes.
If Object_Id('#TempTableA') is not null
	Drop Table #TempTableA;

Select distinct 
 b.ModelID
,UniqueMemberID
,HCCNbr
,Coefficient
into #TempTableA
From #diag a
inner join RA_Medicare.dbo.vwIdentifyHCC b	on replace(a.DiagCd,'.','') = b.ICDCd
											and a.IcdVerCd = b.IcdVerCd
inner join #TempTableLkupModelID		c	on c.ModelID = b.ModelID
--(3221383 row(s) affected)
Create Index ix_ModelID        on #TempTableA(ModelID);
Create Index ix_UniqueMemberID on #TempTableA(UniqueMemberID);
Create Index ix_HCCNbr         on #TempTableA(HCCNbr);

--B	--Identify the remaining HCC's after referencing the Hierarchy.
If Object_Id('#TempTableB') is not null
	Drop Table #TempTableB;

Select a.ModelID, a.UniqueMemberID, a.HCCNbr, a.Coefficient
into #TempTableB
From #TempTableA a
	left outer join
			(--Check to see if you have any of the parents included, we ultimately want to exclude the children from our new table.
			Select a.ModelID, UniqueMemberID, ChildHCCNbr
			From RA_Medicare.dbo.vwIdentifyHCCHierarchy a
			inner join #TempTableA b	on  a.ModelID = b.ModelID
										and a.ParentHCCNbr = b.HCCNbr
			) Remove
		on  a.ModelID = Remove.ModelID
		and a.UniqueMemberID = Remove.UniqueMemberID
		and a.HCCNbr = Remove.ChildHCCNbr
Where Remove.ModelID is null
--(2787596 row(s) affected)
Create Index ix_ModelID         on #TempTableB(ModelID);
Create Index ix_HCCNbr          on #TempTableB(HCCNbr);
Create Index ix_UniqueMemberID  on #TempTableB(UniqueMemberID);

--C	--Map each of the HCC's to the InteractionCategory
If Object_Id('#TempTableC') is not null
	Drop Table #TempTableC;

Select distinct a.ModelID, UniqueMemberID, InteractionCategory
into #TempTableC
From #TempTableB a
inner join RA_Medicare.dbo.vwIdentifyHCCInteractionCategory b	on  a.ModelID = b.ModelID
																and a.HCCNbr = b.HCCNbr
--(2036470 row(s) affected)
Create Index ix_InteractionCategory on #TempTableC(InteractionCategory);
Create Index ix_ModelID             on #TempTableC(ModelID);

--D	--Tie each InteractionCategory to an InteractionTerm
If Object_Id('#TempTableD') is not null
	Drop Table #TempTableD;

Select distinct a.ModelID, a.UniqueMemberID, a.InteractionCategory, b.InteractionTerm
into #TempTableD
From #TempTableC a
		inner join RA_Medicare.dbo.vwIdentifyInteractionTerm b
			on  a.InteractionCategory = b.InteractionCategory
			and a.ModelID = b.ModelID
--(2962900 row(s) affected)	
Create Index ix_Grouping on #TempTableD(ModelID, UniqueMemberID, InteractionTerm, InteractionCategory);

--E	--Check to see the proper count of distinct InteractionCategory is found to qualify for an InteractionTerm.
If Object_Id('#TempTableE') is not null
	Drop Table #TempTableE;

Select a.ModelID, a.UniqueMemberID, a.InteractionTerm, b.Coefficient
into #TempTableE
From 
		(--Compare the results of our member data to the vwIdentifyInteractionTermRequiredCnt view to confirm the counts meet business rules for keeping the InteractionTerm.
		Select ModelID, UniqueMemberID, InteractionTerm
		,ReqDistinctInteractionCategoryCnt = count(distinct InteractionCategory)
		From #TempTableD
		Group By ModelID, UniqueMemberID, InteractionTerm
		) a
Inner Join RA_Medicare.[dbo].[vwIdentifyInteractionTermRequiredCnt] b	on  a.ModelID = b.ModelID
																		and a.InteractionTerm = b.[InteractionTerm]
																		and a.ReqDistinctInteractionCategoryCnt = b.[ReqDistinctInteractionCategoryCnt]
--(260667 row(s) affected)
Create Index ix_ModelID         on #TempTableE(ModelID)
Create Index ix_InteractionTerm on #TempTableE(InteractionTerm)
Create Index ix_UniqueMemberID  on #TempTableE(UniqueMemberID)
				
--F	--Identify the remaining InteractionTerms after referencing vwIdentifyTermHierarchy
If Object_Id('#TempTableF') is not null
	Drop Table #TempTableF;

Select a.ModelID, a.UniqueMemberID, a.InteractionTerm, a.Coefficient
into #TempTableF
From #TempTableE a
left outer join
			(--Check to see if you have any of the parents included, we ultimately want to exclude the children from our new table.
			Select a.ModelID, UniqueMemberID, ChildInteractionTerm
			From RA_Medicare.dbo.vwIdentifyInteractionTermHierarchy a
			inner join #TempTableE b	on  a.ModelID = b.ModelID
										and a.ParentInteractionTerm = b.InteractionTerm
			) Remove	on  a.ModelID = Remove.ModelID
						and a.UniqueMemberID = Remove.UniqueMemberID
						and a.InteractionTerm = Remove.ChildInteractionTerm
Where Remove.ModelID is null
--(260667 row(s) affected)
Create Index ix_UniqueMemberID on #TempTableF(UniqueMemberID)
Create Index ix_InteractionTerm on #TempTableF(InteractionTerm)

--G	--Now combine the coefficients from table B and F.  This will be used to calculate RAF and returns the HCCFactor: sum(coefficients).
If Object_Id('#TempTableG') is not null
	Drop Table #TempTableG;

Select ModelID, UniqueMemberID
,RAF = Sum(Coefficient)
into #TempTableG
From
		(--Combine the final datasets that will serve as coefficient inputs.
			Select ModelID, UniqueMemberID, Term = cast(HCCNbr as varchar(50)), Coefficient
			From #TempTableB
		union all
			Select ModelID, UniqueMemberID, Term = cast(InteractionTerm as varchar(50)), Coefficient
			From #TempTableF
		) a
Group By ModelID, UniqueMemberID
--(1250432 row(s) affected)
Create Index ix_ModelID        on #TempTableG(ModelID) with FillFactor = 80
Create Index ix_UniqueMemberID on #TempTableG(UniqueMemberID) with FillFactor = 80

--Insert a record with a 0.000 RAF score if a record is not present in the existing output via process above.
Insert #TempTableG
Select a.ModelID
	,a.UniqueMemberID
	,RAF = 0.000
From 
		(--Create one record for every member and Model combination we need a record in the final output for
		Select distinct a.UniqueMemberID, AllModels.ModelID
		From #diag a
			Cross Join
				(--Get a list of all the version Models that a record needs to be present for provided the ModelID passed as a parameter.
				Select distinct a.ModelID
				FROM #TempTableLkupModelID a
				inner join RA_Medicare.dbo.Model b	on a.ModelID = b.ModelID
				Where b.BlendedModelID is not null
				) AllModels
		) a
left outer join #TempTableG b	on  a.UniqueMemberID = b.UniqueMemberID
								and a.ModelID = b.ModelID
Where b.UniqueMemberID is null
--(0 row(s) affected)
go

--H	--Update the input demographics table and derive DISABL and ORIGDS variables
If Object_Id('#TempTableH') is not null
	Drop Table #TempTableH;

Select a.*
	,ORIGDS = case when ModelVersion = 12 and a.DISABL = 0 and a.OREC in (1,3) then 1 
				   when ModelVersion = 22 and a.DISABL = 0 and a.OREC = 1 then 1
				   else 0 end
Into #TempTableH
From (
	Select a.*
		,DISABL = case when Age between 0 and 64 and OREC between 1 and 3 then 1 else 0 end 
		,c.ModelID
		,c.ModelVersion
	From #member a
	  CROSS JOIN #TempTableLkupModelID b
	  JOIN RA_Medicare.dbo.Model c	ON b.ModelID = c.ModelID
	Where ModelVersion IS NOT NULL
	) a
--(1846983 row(s) affected)
go

--I	--Identify the demographic terms
If Object_Id('#TempTableI') is not null
	Drop Table #TempTableI;

Select 
	 b.ModelID
	,a.UniqueMemberID
	,b.ModelDemographicTerm
	,b.Coefficient
into #TempTableI
From #TempTableH					a
Inner join RA_Medicare.dbo.ModelDemographicTerm	b	on	a.GenderCd	= b.GenderCd
													and	a.Age between b.AgeStart and b.AgeEnd
													and a.ModelID = b.ModelID
Where b.Type = 'AgeGender'
Union
Select 
	 b.ModelID
	,a.UniqueMemberID
	,b.ModelDemographicTerm
	,b.Coefficient
From #TempTableH					a
Inner join RA_Medicare.dbo.ModelDemographicTerm		b	on	a.GenderCd	= b.GenderCd
														and	a.Age between b.AgeStart and b.AgeEnd
														and	a.OREC	= b.OREC
														and	a.MCAID	= b.MCAID
														and	a.DISABL= b.DISABL
														and	a.ORIGDS= b.ORIGDS
														and a.NEMCAID = b.NEMCAID
														and	a.ModelID = b.ModelID
Where b.Type = 'Other' 
--(1846983 row(s) affected)
Create Index ix_ModelID			on #TempTableI(ModelID);
Create Index ix_UniqueMemberID	on #TempTableI(UniqueMemberID);
Create Index ix_Term			on #TempTableI(ModelDemographicTerm);

--J	--Identify the disabled x HCC interaction terms
If Object_Id('#TempTableJ') is not null
	Drop Table #TempTableJ;

Select distinct  
	 d.ModelID
	,a.UniqueMemberID
	,c.Term
	,c.Coefficient
into #TempTableJ
From #TempTableH								a
Inner join #TempTableB							b	on	a.UniqueMemberID= b.UniqueMemberID
Inner join RA_Medicare.dbo.vwIdentifyDisabledHCCInteractionTerm	c	on	b.ModelID		= c.ModelID
																	and	b.HCCNbr		= c.HCCNbr
Inner join #TempTableLkupModelID				d	on c.ModelID		= d.ModelID
Where a.DISABL = 1
--(62408 row(s) affected)
Create Index ix_ModelID			on #TempTableJ(ModelID);
Create Index ix_UniqueMemberID	on #TempTableJ(UniqueMemberID);
Create Index ix_Term			on #TempTableJ(Term);

-- K	--Now combine the coefficients from tables G, I, and J.  This will be used to calculate RAF and returns the HCCFactor: sum(coefficients).
If Object_Id('pdb_PharmaMotion.dbo.G1097_RAF_2016') is not null
	Drop Table pdb_PharmaMotion.dbo.G1097_RAF_2016;

If Object_Id('#a') is not null
	Drop Table #a;
Select ModelID, UniqueMemberID
	, Demographic_RAF = SUM(Coefficient)
into #a
From #TempTableI
Group by ModelID, UniqueMemberID
--(1846983 row(s) affected)
create clustered index cix on #a(UniqueMemberID)
	
If Object_Id('#b') is not null
	Drop Table #b;
Select ModelID, UniqueMemberID
	, DemographicXHCC_RAF = SUM(Coefficient)
into #b
From #TempTableJ
Group by ModelID, UniqueMemberID
--(52067 row(s) affected)
create clustered index cix on #b(UniqueMemberID)

;WITH cteMembers AS
	(select ModelID, UniqueMemberID from #a
	union
	select ModelID, UniqueMemberID from #b
	union
	select ModelID, UniqueMemberID from #TempTableG
	)
Select 
	ModelID					=	m.ModelID
	,UniqueMemberID			=	m.UniqueMemberID
	,Demographic_RAF		=	ISNULL(a.Demographic_RAF, 0)
	,HCC_RAF				=	ISNULL(c.RAF, 0)
	,DemographicXHCC_RAF	=	case when a.Demographic_RAF+c.RAF is not NULL then ISNULL(b.DemographicXHCC_RAF,0) else b.DemographicXHCC_RAF end
	,TotalRAF				=	ISNULL(a.Demographic_RAF,0)+ISNULL(c.RAF,0)+ISNULL(b.DemographicXHCC_RAF,0)
Into pdb_PharmaMotion.dbo.G1097_RAF_2016
From cteMembers				m	
	left join #a			a	on	m.ModelID			=	a.ModelID
								and	m.UniqueMemberID	=	a.UniqueMemberID
	left join #b			b	on	m.ModelID			=	b.ModelID
								and m.UniqueMemberID	=	b.UniqueMemberID
	left join #TempTableG	c	on	m.ModelID			=	c.ModelID
								and m.UniqueMemberID	=	c.UniqueMemberID
--(1846983 row(s) affected)
Create Index ix_ModelID        on pdb_PharmaMotion.dbo.G1097_RAF_2016(ModelID) with FillFactor = 80;
Create Index ix_UniqueMemberID on pdb_PharmaMotion.dbo.G1097_RAF_2016(UniqueMemberID) with FillFactor = 80;

--Insert a record with a 0.000 RAF score if a record is not present in the existing output via process above.
Insert pdb_PharmaMotion.dbo.G1097_RAF_2016
Select 
	 a.ModelID
	,a.UniqueMemberID
	,Demographic_RAF		= NULL
	,HCC_RAF				= NULL
	,DemographicXHCC_RAF	= NULL
	,TotalRAF				= 0.0000
From 
		(--Create one record for every member and Model combination we need a record in the final output for
		Select distinct a.UniqueMemberID, AllModels.ModelID
		From ( 
			Select UniqueMemberID From  #diag
			Union
			Select UniqueMemberID From  #member
			)	a
			Cross Join
				(--Get a list of all the version Models that a record needs to be present for provided the ModelID passed as a parameter.
				Select distinct a.ModelID
				FROM #TempTableLkupModelID a
				inner join RA_Medicare.dbo.Model b	on a.ModelID = b.ModelID
				Where b.BlendedModelID is not null OR b.PaymentYear NOT IN (2014,2015)
				) AllModels
		) a
left outer join pdb_PharmaMotion.dbo.G1097_RAF_2016 b	on  a.UniqueMemberID = b.UniqueMemberID
														and a.ModelID = b.ModelID
Where b.UniqueMemberID is null
--(0 row(s) affected)

--L	--Build Output Table that will store the ModelTerms in the specified location (per parameter).
If Object_Id('pdb_PharmaMotion.dbo.G1097_RA_ModelTerms_2016') is not null
	Drop Table pdb_PharmaMotion.dbo.G1097_RA_ModelTerms_2016

Select *
into pdb_PharmaMotion.dbo.G1097_RA_ModelTerms_2016
From
	(--This subquery combines the complete list of HCCs and InteractionTerms identified for a user and then sets a flag if used in the model calc.
		--Returns all the HCCs this individual has and sets a flag if it was actually used in the HCCFactor calc.
		Select a.ModelID
			, a.UniqueMemberID
			, Term = 'HCC'+cast(a.HCCNbr as varchar(50))
			, a.Coefficient
			,UsedInCalcFlag = Case When b.ModelID is not null Then 1 Else 0 End
		From #TempTableA a
		left outer join #TempTableB b	on  a.ModelID = b.ModelID
										and a.UniqueMemberID = b.UniqueMemberID
										and a.HCCNbr = b.HCCNbr

	Union ALL

		--Returns all the InteractionTerms this individual has and sets a flag if it was actually used in the HCCFactor calc.
		Select a.ModelID
			, a.UniqueMemberID
			, Term = cast(a.InteractionTerm as varchar(50))
			, a.Coefficient
			,UsedInCalcFlag = Case When b.ModelID is not null Then 1 Else 0 End
		From  #TempTableE a
		left outer join #TempTableF b	on  a.UniqueMemberID = b.UniqueMemberID
										and a.InteractionTerm = b.InteractionTerm
	
	Union all
	
		Select 			 
			ModelID
			,UniqueMemberID
			,Term = ModelDemographicTerm
			,Coefficient
			,UsedInCalcFlag = 1
		From #TempTableI
				
	Union all

		Select *,UsedInCalcFlag = 1
		From #TempTableJ

	) sub
Order By 1,2,3
--(5391441 row(s) affected)

--M	--Do the additional processing needed for adding a Blended Score record, if one is needed.
Insert pdb_PharmaMotion.dbo.G1097_RAF_2016
Select 
	 MbrCalc.ModelID
	,MbrCalc.UniqueMemberID
	,Demographic_RAF		= MbrCalc.Demographic_RAF * (1-CIF.CodingIntensityFactor)
	,HCC_RAF				= MbrCalc.HCC_RAF * (1-CIF.CodingIntensityFactor)
	,DemographicXHCC_RAF	= MbrCalc.DemographicXHCC_RAF * (1-CIF.CodingIntensityFactor)
	,TotalRAF				= MbrCalc.TotalRAF * (1-CIF.CodingIntensityFactor)
From
		(--This dataset does all the calculation required at the version level.  But, needs to join to the Model record to get CodingIntensity value and subtract that value.
		Select b.UniqueMemberID
			,ModelID				= 31
			,Demographic_RAF		= sum((b.Demographic_RAF/a.NormalizationFactor)*a.BlendedShare)
			,HCC_RAF				= sum((b.HCC_RAF/a.NormalizationFactor)*a.BlendedShare)
			,DemographicXHCC_RAF	= sum((b.DemographicXHCC_RAF/a.NormalizationFactor)*a.BlendedShare)
			,TotalRAF				= sum((b.TotalRAF/a.NormalizationFactor)*a.BlendedShare)
		From
				(--Subquery A is the check to determine if we need to do a Blended Processing and pulls the necessary attributes for doing the blending if needed.
				Select distinct *
				From RA_Medicare.dbo.Model
				Where BlendedModelID =

					(--Return a record if blended processing is required.
					Select ModelID
					From RA_Medicare.dbo.Model
					Where BlendedModelId is null 
						and ModelVersion is null 
						and ModelID = 31
					)
				) a
		inner join pdb_PharmaMotion.dbo.G1097_RAF_2016 b	on a.ModelID = b.ModelID
		Group By b.UniqueMemberID
		) MbrCalc
inner join RA_Medicare.dbo.Model CIF	on MbrCalc.ModelID = CIF.ModelID
--(0 row(s) affected)

-----------------------------
--top HCC per AHFS Category
-----------------------------
--create index Ix_MemberID on pdb_PharmaMotion..G1097_RA_ModelTerms_2016 (UniqueMemberID);

select b.Term, c.TermLabel
	, AHFS_0 = count(distinct case when Cnt_AHFS_201612 = 0	then SavvyHICN	end)
	, AHFS_1 = count(distinct case when Cnt_AHFS_201612 = 1	then SavvyHICN	end)
	, AHFS_2 = count(distinct case when Cnt_AHFS_201612 = 2	then SavvyHICN	end)
	, AHFS_3 = count(distinct case when Cnt_AHFS_201612 = 3	then SavvyHICN	end)
	, AHFS_4 = count(distinct case when Cnt_AHFS_201612 = 4	then SavvyHICN	end)
	, [AHFS_5+] = count(distinct case when Cnt_AHFS_201612 >= 5	then SavvyHICN	end)
	--, [AHFS_6+] = count(distinct case when Cnt_AHFS_201612 >= 6	then SavvyHICN	end)
from pdb_PharmaMotion..G1097Members	a
inner join pdb_PharmaMotion..G1097_RA_ModelTerms_2016		b	on	a.SavvyHICN = b.UniqueMemberID
inner join RA_Medicare..ModelTerm							c	on	b.Term = c.Term
where c.ModelID = 31
--where a.SavvyHICN = 3817409
and b.Term like 'HCC%'
group by b.Term, c.TermLabel


--HCC
if OBJECT_ID ('tempdb..#HCC') is not null begin drop table #HCC	End;

Select	a.ModelID ,UniqueMemberID, a.Coefficient , a.USedInCalcFlag 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC
From	(Select	* 
		From	pdb_PharmaMotion..G1097_RA_ModelTerms_2016
		)										as	a
left join	RA_Medicare..ModelTerm			as	b	on	a.Term = b.Term
where b.ModelID = 31
--(3747868 row(s) affected)
create index Ix_MemberID on #HCC (UniqueMemberID);

select UniqueMemberID
	, count(distinct Term)
from pdb_PharmaMotion..G1097_RA_ModelTerms_2016
group by UniqueMemberID
having count(distinct Term) > 2


------------------------------------------------------------------------------------------------------------------
--Dynamic Pivot:
if OBJECT_ID ('pdb_PharmaMotion..G1097_HCC_2016') is not null begin drop table pdb_PharmaMotion..G1097_HCC_2016	End;

declare @listcol varchar (max)			--provide dynamic DiagCdSysId_ConCat column list based on pivot base tbl
declare @listcolisnull varchar (max)	--provide isnull validation to pivot result
declare @query1 varchar (max)			--Pivot data with dynamic DiagCdSysId_ConCat


select @listcol =							--provide dynamic DiagCdSysId_ConCat column list based on #HCC
STUFF((select 
			'],[' + HCC
		from  ( select distinct HCC
				from #HCC
			)		as	a
			order by '],[' + HCC
			for XML path('')
				),1,2,'') + ']'

select @listcolisnull =						--provide isnull validation to pivot result
STUFF((select 
			', isnull([' +ltrim(HCC)+ '],0) as [' +ltrim(HCC)+ '] '
		From (select distinct HCC
				from #HCC
				)	as	b
		Order by HCC
			for XML path('')
				),1,2,'') 
				

--Set variable to pivot data based on #HCC using DiagCdSysId_ConCatcolumns in @listcol and @listcolisnull validation. 
		
set @query1 = 

'select UniqueMemberID, '+ @listcolisnull +'
into pdb_PharmaMotion..G1097_HCC_2016
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol+'))				as pvt	'
	
	execute (@query1)
--(1347878 row(s) affected)
create unique index uIx_Member on pdb_PharmaMotion..G1097_HCC_2016 (UniqueMemberID);

-----------------------------
--permutations
-----------------------------
If (object_id('tempdb..#HCC_pmt') Is Not Null)
Drop Table #HCC_pmt
go

select RN = cast(row_number() over(order by HCC) as varchar(max))
	, HCC = cast(HCC as varchar(max))
into #HCC_pmt
from	(
			select distinct HCC
			from #HCC
			where HCC like 'HCC%'
		) z
--(79 row(s) affected)
--create unique index uIx_RN on #HCC_pmt (RN);

If (object_id('tempdb..#HCC_pairs') Is Not Null)
Drop Table #HCC_pairs
go

with permute as (
	select rn = dense_rank() over(order by HCC), HCC
	from #HCC_pmt
)
select rn_1 = p1.rn, HCC_1 = p1.HCC
	, rn_2 = p2.rn, HCC_2 = p2.HCC
	, Combi = p1.HCC + ' + ' + p2.HCC
	, RN_id = cast(p1.rn as varchar) + ';' + cast(p2.rn as varchar)
into #HCC_pairs
from permute p1, permute p2
where p1.rn < p2.rn
order by p1.rn, p2.rn
-- 3,081
create unique index uIx_RnID on #HCC_pairs (RN_id);

select * from #HCC_pairs where Combi = 'ARTIF_OPENINGS_PRESSURE_ULCER + CANCER_IMMUNE' 

If (object_id('tempdb..#HCC_mbrpairs') Is Not Null)
Drop Table #HCC_mbrpairs
go

with mbr_permute as (
	select a.UniqueMemberID, b.HCC, z.RN
		, OID = dense_rank() over(partition by a.UniqueMemberID order by cast(z.RN as int))
	from	(
				select UniqueMemberID
				from #HCC
				group by UniqueMemberID
				having count(distinct HCC) >= 2
			)	a
	inner join #HCC	b	on	a.UniqueMemberID = b.UniqueMemberID
		cross apply (--assigning of pair combination id
						select *
						from #HCC_pmt	rn
						where b.HCC = rn.HCC
						)	z
	--where a.UniqueMemberID in (11995)
	)

select p1.UniqueMemberID
	, RN_id = cast(p1.RN as varchar) + ';' + cast(p2.RN as varchar)
into #HCC_mbrpairs
from mbr_permute p1, mbr_permute p2
where p1.UniqueMemberID = p2.UniqueMemberID
	and p1.OID < p2.OID
--where p1.OID < p2.OID
order by p1.OID, p2.OID
--(7,747,943 row(s) affected)
create unique index uIx_MbrID_RnID on #HCC_mbrpairs (UniqueMemberID, RN_id);

select * from #HCC_mbrpairs where --RN_id = '37;8' 
UniqueMemberID = 11995

-----------------------------
--top HCC pairings per AHFS Category
-----------------------------
If (object_id('pdb_PharmaMotion..G1097_PairsHCC') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_PairsHCC
go

select c.Combi
	, Mbr_Cnt = count(distinct a.SavvyHICN)
	, AHFS_0 = count(distinct case when a.Cnt_AHFS_201612 = 0	then a.SavvyHICN	end)
	, AHFS_1 = count(distinct case when a.Cnt_AHFS_201612 = 1	then a.SavvyHICN	end)
	, AHFS_2 = count(distinct case when a.Cnt_AHFS_201612 = 2	then a.SavvyHICN	end)
	, AHFS_3 = count(distinct case when a.Cnt_AHFS_201612 = 3	then a.SavvyHICN	end)
	, AHFS_4 = count(distinct case when a.Cnt_AHFS_201612 = 4	then a.SavvyHICN	end)
	, AHFS_5 = count(distinct case when a.Cnt_AHFS_201612 >= 5	then a.SavvyHICN	end)
	--, [AHFS_6+] = count(distinct case when a.Cnt_AHFS_201612 >= 6	then a.SavvyHICN	end)
	, OID = row_number() over(order by count(distinct a.SavvyHICN) desc)
into pdb_PharmaMotion..G1097_PairsHCC
--select *
from pdb_PharmaMotion..G1097Members	a
inner join #HCC_mbrpairs	b	on	a.SavvyHICN = b.UniqueMemberID
inner join #HCC_pairs		c	on	b.RN_id = c.RN_id
---where a.SavvyHICN = 2161187
--where c.Combi = 'ASP_SPEC_BACT_PNEUM_PRES_ULCER + CANCER_IMMUNE' 
group by c.Combi
--(4455 row(s) affected); 5 minutes

select * 
from pdb_PharmaMotion..G1097_PairsHCC
where OID <= 100

select Pair_HCC = 'OTHERS'
	, Mbr_Cnt = sum(Mbr_Cnt)
	, AHFS_0 = sum(AHFS_0)
	, AHFS_1 = sum(AHFS_1)
	, AHFS_2 = sum(AHFS_2)
	, AHFS_3 = sum(AHFS_3)
	, AHFS_4 = sum(AHFS_4)
	, AHFS_5 = sum(AHFS_5)
--	, [AHFS_6+] = sum([AHFS_6+])
	, Pair_Cnt = count(distinct Combi)
from pdb_PharmaMotion..G1097_PairsHCC
--where OID <= 100
where OID > 100

--triplicates
If (object_id('tempdb..#HCC_triplicates') Is Not Null)
Drop Table #HCC_triplicates
go

with permute as (
	select rn = dense_rank() over(order by HCC), HCC
	from #HCC_pmt
)
select rn_1 = p1.rn, HCC_1 = p1.HCC
	, rn_2 = p2.rn, HCC_2 = p2.HCC
	, rn_3 = p3.rn, HCC_3 = p3.HCC
	, Combi = p1.HCC + ' + ' + p2.HCC + ' + ' + p3.HCC
	, RN_id = cast(p1.rn as varchar) + ';' + cast(p2.rn as varchar) + ';' + cast(p3.rn as varchar)
into #HCC_triplicates
from permute p1, permute p2, permute p3
where p1.rn < p2.rn
	and p2.rn < p3.rn
order by p1.rn, p2.rn, p3.rn
--(192,920 row(s) affected)
create unique index uIx_RnID on #HCC_triplicates (RN_id);

--select * from #HCC_triplicates order by RN_id
--select * from #HCC_pairs where Combi = 'ARTIF_OPENINGS_PRESSURE_ULCER + CANCER_IMMUNE' 

If (object_id('pdb_PharmaMotion..tmp_HCC_mbrtriplicates') Is Not Null)
Drop Table pdb_PharmaMotion..tmp_HCC_mbrtriplicates
go

with mbr_permute as (
	select a.UniqueMemberID, b.HCC, z.RN
		, OID = dense_rank() over(partition by a.UniqueMemberID order by cast(z.RN as int))
	from	(
				select UniqueMemberID
				from #HCC
				group by UniqueMemberID
				having count(distinct HCC) >= 3
			)	a
	inner join #HCC	b	on	a.UniqueMemberID = b.UniqueMemberID
		cross apply (--assigning of pair combination id
						select *
						from #HCC_pmt	rn
						where b.HCC = rn.HCC
						)	z
	--where a.UniqueMemberID in (18696777, 364671)	--(2161187, 6944544)
	)
select p1.UniqueMemberID
	, RN_id = cast(p1.RN as varchar) + ';' + cast(p2.RN as varchar) + ';' + cast(p3.RN as varchar)
into pdb_PharmaMotion..tmp_HCC_mbrtriplicates
from mbr_permute p1, mbr_permute p2, mbr_permute p3
where p1.UniqueMemberID = p2.UniqueMemberID
	and p2.UniqueMemberID = p3.UniqueMemberID
	and p1.OID < p2.OID
	and p2.OID < p3.OID
--where p1.OID < p2.OID
order by p1.OID, p2.OID, p3.OID
--order by 1
-- 8,785,740
create unique index uIx_MbrID_RnID on pdb_PharmaMotion..tmp_HCC_mbrtriplicates (UniqueMemberID, RN_id);

If (object_id('pdb_PharmaMotion..G1097_TriplicatesHCC') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_TriplicatesHCC
go

select c.Combi
	, Mbr_Cnt = count(distinct a.SavvyHICN)
	, AHFS_0 = count(distinct case when a.Cnt_AHFS_201612 = 0	then a.SavvyHICN	end)
	, AHFS_1 = count(distinct case when a.Cnt_AHFS_201612 = 1	then a.SavvyHICN	end)
	, AHFS_2 = count(distinct case when a.Cnt_AHFS_201612 = 2	then a.SavvyHICN	end)
	, AHFS_3 = count(distinct case when a.Cnt_AHFS_201612 = 3	then a.SavvyHICN	end)
	, AHFS_4 = count(distinct case when a.Cnt_AHFS_201612 = 4	then a.SavvyHICN	end)
	, AHFS_5 = count(distinct case when a.Cnt_AHFS_201612 >= 5	then a.SavvyHICN	end)
	--, [AHFS_6+] = count(distinct case when a.Cnt_AHFS_201612 >= 6	then a.SavvyHICN	end)
	, OID = row_number() over(order by count(distinct a.SavvyHICN) desc)
into pdb_PharmaMotion..G1097_TriplicatesHCC
--select *
from pdb_PharmaMotion..G1097Members	a
inner join pdb_PharmaMotion..tmp_HCC_mbrtriplicates	b	on	a.SavvyHICN = b.UniqueMemberID
inner join #HCC_triplicates		c	on	b.RN_id = c.RN_id
---where a.SavvyHICN = 2161187
--where c.Combi = 'ASP_SPEC_BACT_PNEUM_PRES_ULCER + CANCER_IMMUNE' 
group by c.Combi
--(102,915 row(s) affected); 29.21 minutes

select *
from pdb_PharmaMotion..G1097_TriplicatesHCC
where OID <= 100
order by OID


select Triplicate_HCC = 'OTHERS'
	, Mbr_Cnt = sum(Mbr_Cnt)
	, AHFS_0 = sum(AHFS_0)
	, AHFS_1 = sum(AHFS_1)
	, AHFS_2 = sum(AHFS_2)
	, AHFS_3 = sum(AHFS_3)
	, AHFS_4 = sum(AHFS_4)
	, [AHFS_5+] = sum(AHFS_5)
	--, [AHFS_6+] = sum([AHFS_6+])
	--, Pair_Cnt = count(distinct Combi)
--select *
from pdb_PharmaMotion..G1097_TriplicatesHCC
--where OID <= 100
where OID > 100


------------------------------
--updates to the member table
--Date: 12 July 2017
------------------------------
alter table pdb_PharmaMotion..G1097Members
	--add OREC		tinyint
		alter column RAF_2016	decimal(9,3)
go

update pdb_PharmaMotion..G1097Members
set RAF_2016 = b.TotalRAF
from pdb_PharmaMotion..G1097Members	a
left join pdb_PharmaMotion..G1097_RAF_2016	b	on	a.SavvyHICN = b.UniqueMemberID


update pdb_PharmaMotion..G1097Members
set OREC = b.OREC
from pdb_PharmaMotion..G1097Members	a
left join #member					b	on	a.SavvyHICN = b.UniqueMemberID

select * from pdb_PharmaMotion..G1097Members
select min(Age_2016), max(Age_2016) from pdb_PharmaMotion..G1097Members
select Age_2016, count(*) from pdb_PharmaMotion..G1097Members group by Age_2016 order by 1

select OREC = case when OREC = 0	then 'OREC_0'	else 'OREC_n0'	end
	, AHFS_0 = count(distinct case when Cnt_AHFS_201612 = 0	then SavvyHICN	end) 
	, AHFS_1 = count(distinct case when Cnt_AHFS_201612 = 1	then SavvyHICN	end) 
	, AHFS_2 = count(distinct case when Cnt_AHFS_201612 = 2	then SavvyHICN	end) 
	, AHFS_3 = count(distinct case when Cnt_AHFS_201612 = 3	then SavvyHICN	end) 
	, AHFS_4 = count(distinct case when Cnt_AHFS_201612 = 4	then SavvyHICN	end) 
	, [AHFS_5+] = count(distinct case when Cnt_AHFS_201612 >= 5	then SavvyHICN	end) 
--	, [AHFS_6+] = count(distinct case when Cnt_AHFS_201612 >= 6	then SavvyHICN	end) 
from pdb_PharmaMotion..G1097Members
group by case when OREC = 0	then 'OREC_0'	else 'OREC_n0'	end

select OREC = case when OREC = 0	then 'OREC_0'	else 'OREC_n0'	end
	, AgeGrp
	, AHFS_0 = count(distinct case when Cnt_AHFS_201612 = 0	then SavvyHICN	end) 
	, AHFS_1 = count(distinct case when Cnt_AHFS_201612 = 1	then SavvyHICN	end) 
	, AHFS_2 = count(distinct case when Cnt_AHFS_201612 = 2	then SavvyHICN	end) 
	, AHFS_3 = count(distinct case when Cnt_AHFS_201612 = 3	then SavvyHICN	end) 
	, AHFS_4 = count(distinct case when Cnt_AHFS_201612 = 4	then SavvyHICN	end) 
	, AHFS_5 = count(distinct case when Cnt_AHFS_201612 >= 5	then SavvyHICN	end) 
	--, [AHFS_6+] = count(distinct case when Cnt_AHFS_201612 >= 6	then SavvyHICN	end) 
from pdb_PharmaMotion..G1097Members
group by (case when OREC = 0	then 'OREC_0'	else 'OREC_n0'	end), AgeGrp
order by 1, 2