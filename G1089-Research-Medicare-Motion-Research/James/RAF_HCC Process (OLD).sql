--USE [pdb_WalkandWin]
--GO
--/****** Object:  StoredProcedure [dbo].[GP1026_WnW_Update_RAF_HCC]    Script Date: 8/22/2017 6:30:35 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER PROCEDURE [dbo].[GP1026_WnW_Update_RAF_HCC]
--AS

/*-----------------------------------------------------------------------------------------------------------
Connect to: DEVSQL10

Updated by: Edson Semorio
Last updated on: 6/26/17
Updates: Integrated new RAF update process into the script.


									*****IMPORTANT NOTE*****
To keep all the changes in one place, please do not edit the stored procedure directly from the object explorer
in Management Studio. Instead, you may find, edit and execute it from the ff. location:
R:\GP0000-Pilot Operations\GP1027-WalkandWin Pilot Ops\GP1026 WnW Research Dataset Loads\SQL Scripts

Please send an email to Edson Semorio, Sam Kapfhamer and Ikel Querouz if the updates in the script result to a
change in the structure of the final table output/s, e.g. addition/removal of column/s, change in data type, etc.
This is important since it will require recreation of the copy/ies of that table in the other server/s.
-----------------------------------------------------------------------------------------------------------*/
--/*-----------------------------------------------------------------------------------------------------------
-- Confinement Table
if object_id('pdb_WalkandWin..GP1026_WnW_IPConfinement') is not null
drop table  pdb_WalkandWin..GP1026_WnW_IPConfinement

select cl.SavvyID
	, cl.DT_SYS_ID	as AdmitDtSys
	, dt.DT_SYS_ID	as DischargeDtSys
	, cl.FULL_DT	as AdmitDate
	, dt.FULL_DT	as DischargeDate
	, cl.Day_Cnt	as LengthofStay
	, ConfirementID		= Row_Number() over (partition by cl.SavvyId order by cl.Dt_Sys_Id)
	, cl.YEAR_NBR
into pdb_WalkandWin..GP1026_WnW_IPConfinement
from [pdb_WalkandWin]..[GP1026_WnW_Claims]	cl
Join MiniOV..Dim_Date					dt	on	dt.DT_SYS_ID = (cl.DT_SYS_ID + cl.Day_Cnt) 
where cl.[SRVC_TYP_CD] = 'IP'
	and cl.Admit_Cnt = 1
order by 1

create clustered index cIx_SavvyID on pdb_WalkandWin..GP1026_WnW_IPConfinement (SavvyID);
create nonclustered index nIx_Dt on pdb_WalkandWin..GP1026_WnW_IPConfinement(AdmitDtSys, DischargeDtSys, Year_NBR);

-------------------------------------------------------------------------------------------------------------

-- Create Diag Table
if object_id('pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags') is not null
drop table pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags;

With CTE_A as (
	Select cl.SavvyId
		, cl.Clm_Aud_Nbr
	From [pdb_WalkandWin]..[GP1026_WnW_Claims] cl
	where 1=1
		and (	--1500 Claims with eligible CPT Codes
				(cl.Srvc_Typ_Cd in ('OP', 'DR')	--still considered OP since we are filtering the Claim Type to CMS 1500 - Physician Claim
				and cl.[Rvnu_Cd_Sys_Id] <= 2 
				and cl.Proc_Cd in (select * from RA_Medicare_2014_v2..Reportable_PhysicianProcedureCodes )								--CMS 1500 Claim  Physician CLaim
				)
			or --1450 Claims with Eligible Bill Type & CPT COde
				(cl.Srvc_Typ_Cd = 'OP'
				and cl.[Rvnu_Cd_Sys_Id] in (Select distinct Rvnu_Cd_Sys_Id  from RA_Medicare_2014_v2..Reportable_OutpatientRevenueCodes)	--List of Eligible REvenue codes
				)
			)
	
	Union 
	
	Select cl.SavvyId
		, cl.Clm_Aud_Nbr
	From [pdb_WalkandWin]..[GP1026_WnW_Claims]		cl
	Join pdb_WalkandWin..GP1026_WnW_IPConfinement	ip	on ip.SavvyId	=	cl.SavvyId
														and	cl.DT_SYS_ID between ip.AdmitDtSys and ip.DischargeDtSys
	Where cl.Srvc_Typ_Cd = 'IP'
	)
Select Distinct cl.SavvyId as UniqueMemberID
	, cl.Diag_Cd_1 as DiagCd
	, cl.YEAR_NBR
	, cl.ICD_VER_CD_1 as IcdVerCd
Into pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags
From [pdb_WalkandWin]..[GP1026_WnW_Claims]	cl
Join CTE_A									dg	on dg.Clm_Aud_Nbr	=	cl.Clm_Aud_Nbr
Where cl.Diag_Cd_1 <> ' '

Union 

Select Distinct cl.SavvyId
	, cl.Diag_Cd_2
	, cl.YEAR_NBR
	, cl.ICD_VER_CD_2
From [pdb_WalkandWin]..[GP1026_WnW_Claims]	cl
Join CTE_A									dg	on dg.Clm_Aud_Nbr	=	cl.Clm_Aud_Nbr
Where cl.Diag_Cd_2 <> ' '

Union
 
Select Distinct cl.SavvyId
	, cl.Diag_Cd_3
	, cl.YEAR_NBR
	, cl.ICD_VER_CD_3
From [pdb_WalkandWin]..[GP1026_WnW_Claims]	cl
Join CTE_A									dg	on dg.Clm_Aud_Nbr	=	cl.Clm_Aud_Nbr
Where cl.Diag_Cd_3 <> ' '

-- Demographic info Table
if object_id('[pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members]') is not null
		drop table[pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members];
Select mt.MiniOV_SavvyID 
	, dm.Gender
	, dm.Age
	, Left(cm.PaymentDateYM , 4) as YEARS
	, Max(cm.OriginalReasonForEntitlement) as Orec
	, Max(cm.[RiskAdjusterFactorA]) as RAF
	, '0'					as MCAID
	, '0'					as NEMCAID
Into [pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members]
From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset]	mt
Join MiniOV..Dim_Member									dm	on dm.SavvyID	=	mt.MiniOV_SavvyID
Join [CmsMMR].[dbo].[CmsMMR]							cm	on Cast (cm.SavvyHICN as varchar)	=	mt.SavvyHICN
Where 1=1
	and cm.SavvyHICN is not Null
	and Left(cm.PaymentDateYM , 4) in ('2013','2014', '2015', '2016')
Group By mt.MiniOV_SavvyID 
	, dm.Gender
	, dm.Age
	, Left(cm.PaymentDateYM , 4)

-- Raf MEmber Table Per YEar
if object_id('Tempdb..#RafMember2013') is not null
		drop table  #RafMember2013;
Select MiniOV_SavvyID as UniqueMemberID, Gender as GenderCd
	, Age, Orec	as OREC, MCAID, NEMCAID
Into #RafMember2013
From [pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members]
Where YEARS = 2013

if object_id('Tempdb..#RafMember2014') is not null
		drop table  #RafMember2014;
Select MiniOV_SavvyID as UniqueMemberID, Gender as GenderCd
	, Age, Orec	as OREC, MCAID, NEMCAID
Into #RafMember2014
From [pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members]
Where YEARS = 2014

if object_id('Tempdb..#RafMember2015') is not null
		drop table  #RafMember2015;
Select MiniOV_SavvyID as UniqueMemberID, Gender as GenderCd
	, Age, Orec	as OREC, MCAID, NEMCAID
Into #RafMember2015
From [pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members]
Where YEARS = 2015

if object_id('Tempdb..#RafMember2016') is not null
		drop table  #RafMember2016;
Select MiniOV_SavvyID as UniqueMemberID, Gender as GenderCd
	, Age, Orec	as OREC, MCAID, NEMCAID
Into #RafMember2016
From [pdb_WalkandWin].[dbo].[GP1026_WnW_RAF_Members]
Where YEARS = 2016

-- RAF Diag Table Per Year
if object_id('Tempdb..#Diag_2013') is not null
drop table #Diag_2013
Select UniqueMemberID, DiagCd, IcdVerCd
Into #Diag_2013
From pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags
Where YEAR_NBR = 2013

if object_id('Tempdb..#Diag_2014') is not null
drop table #Diag_2014
Select UniqueMemberID, DiagCd, IcdVerCd
Into #Diag_2014
From pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags
Where YEAR_NBR = 2014

if object_id('Tempdb..#Diag_2015') is not null
drop table #Diag_2015
Select dg.UniqueMemberID, IsNull(ic.ICD9, dg.DiagCd) as DiagCd
	, Case When ic.ICD9 is not Null Then 9 Else dg.IcdVerCd end as IcdVerCd
Into #Diag_2015
From pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags		dg
Left Join [pdb_ICD10].[dbo].[ICD10_to_ICD9_GEM]		ic	on ic.ICD10	=	dg.DiagCd	
Where YEAR_NBR = 2015

if object_id('Tempdb..#Diag_2016') is not null
drop table #Diag_2016
Select dg.UniqueMemberID, IsNull(ic.ICD9, dg.DiagCd) as DiagCd
	, Case When ic.ICD9 is not Null Then 9 Else dg.IcdVerCd end as IcdVerCd
Into #Diag_2016
From pdb_WalkandWin.dbo.GP1026_WnW_RAF_Diags		dg
Left Join [pdb_ICD10].[dbo].[ICD10_to_ICD9_GEM]		ic	on ic.ICD10	=	dg.DiagCd	
Where YEAR_NBR = 2016

-- RAF Computation 

-- Diagnosis and Demographic inputs
	Exec RA_Medicare.dbo.[spRAFDiagnosisDemographicInput]
	 @ModelID = 16
	,@InputDiagnosisTableLocation = '#Diag_2013'
	,@InputDemographicsTableLocation = '#RafMember2013'	
	,@OutputDatabase = '[pdb_WalkandWin]'
	,@OutputSuffix = 'GP1062_RAFScore_2013'

	Exec RA_Medicare.dbo.[spRAFDiagnosisDemographicInput]
	 @ModelID = 16
	,@InputDiagnosisTableLocation = '#Diag_2014'
	,@InputDemographicsTableLocation = '#RafMember2014'	
	,@OutputDatabase = '[pdb_WalkandWin]'
	,@OutputSuffix = 'GP1062_RAFScore_2014'	

	Exec RA_Medicare.dbo.[spRAFDiagnosisDemographicInput]
	 @ModelID = 16
	,@InputDiagnosisTableLocation = '#Diag_2015'
	,@InputDemographicsTableLocation = '#RafMember2015'	
	,@OutputDatabase = '[pdb_WalkandWin]'
	,@OutputSuffix = 'GP1062_RAFScore_2015'

	Exec RA_Medicare.dbo.[spRAFDiagnosisDemographicInput]
	 @ModelID = 16
	,@InputDiagnosisTableLocation = '#Diag_2016'
	,@InputDemographicsTableLocation = '#RafMember2016'	
	,@OutputDatabase = '[pdb_WalkandWin]'
	,@OutputSuffix = 'GP1062_RAFScore_2016'

/*
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2013]
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2014]
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2015]
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2016]


SElect Top 1000 *
From [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2013]

SElect Top 1000 *
From [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2014]

SElect Top 1000 *
From [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2015]

SElect Top 1000 *
From [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2016]

*/

-- Get RAF For Each Member, Use CMS MMR
/*
If Object_Id ('[pdb_WalkandWin]..GP1026_WnW_RAF')is not null
       Drop Table [pdb_WalkandWin]..GP1026_WnW_RAF;
With CTE_A as ( -- RAF Scores
	Select mt.SavvyHICN, mt.MiniOV_SavvyID , cm.PaymentDateYM, cm.RiskAdjusterFactorA, cm.OriginalReasonForEntitlement
		, ROW_NUMBER() Over (Partition By mt.SavvyHICN Order by cm.PaymentDateYM desc) as RN
	From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset]			mt
	Left Join CmsMMR..CmsMMR												cm	on Cast(cm.SavvyHicn as varchar)	=	mt.SavvyHICN
	Where Left(PaymentDateYM, 4) in (2013, 2014, 2015, 2016)
		and cm.OriginalReasonForEntitlement <> 9
	)
Select ms.SavvyHICN
	, Max(mt.OriginalReasonForEntitlement) as OREC
	, Max(Case When Left(PaymentDateYM, 4) = 2013 Then RiskAdjusterFactorA Else Null End) as RAFMMR_2013
	, Max(Case When Left(PaymentDateYM, 4) = 2014 Then RiskAdjusterFactorA Else Null End) as RAFMMR_2014
	, Max(Case When Left(PaymentDateYM, 4) = 2015 Then RiskAdjusterFactorA Else Null End) as RAFMMR_2015
	, Max(Case When Left(PaymentDateYM, 4) = 2016 Then RiskAdjusterFactorA Else Null End) as RAFMMR_2016
	, MAX(r13.Demographic_RAF) as RAFDemo_2013
	, MAX(r14.Demographic_RAF) as RAFDemo_2014
	, MAX(r15.Demographic_RAF) as RAFDemo_2015
	, MAX(r16.Demographic_RAF) as RAFDemo_2016
	, MAX(r13.TotalRAF) as RAFCompute_2013
	, MAX(r14.TotalRAF) as RAFCompute_2014
	, MAX(r15.TotalRAF) as RAFCompute_2015
	, MAX(r16.TotalRAF) as RAFCompute_2016
Into [pdb_WalkandWin]..GP1026_WnW_RAF
From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset]			ms
Left Join CTE_A													mt	on mt.SavvyHICN	=	ms.SavvyHICN
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2013]	r13	on Cast(r13.UniqueMEmberID as Varchar)	=	mt.MiniOV_SavvyID
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2014]	r14	on Cast(r14.UniqueMEmberID as Varchar)	=	mt.MiniOV_SavvyID
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2015]	r15	on Cast(r15.UniqueMEmberID as Varchar)	=	mt.MiniOV_SavvyID
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2016]	r16	on Cast(r16.UniqueMEmberID as varchar)	=	mt.MiniOV_SavvyID
Group By ms.SavvyHICN
*/

If Object_Id ('[pdb_WalkandWin]..GP1026_WnW_RAF')is not null
       Drop Table [pdb_WalkandWin]..GP1026_WnW_RAF;
Select ms.SavvyHICN
	, Max(Case When mt.[OREC] = 'NULL'		Then Null Else mt.[OREC] End )		as OREC
    , Max(Case When mt.[RAF_2013] = 'NULL'	Then Null Else mt.[RAF_2013] End)	as RAFMMR_2013
    , Max(Case When mt.[RAF_2014] = 'NULL'	Then Null Else mt.[RAF_2014] End)	as RAFMMR_2014
    , Max(Case When mt.[RAF_2015] = 'NULL'	Then Null Else mt.[RAF_2015] End)	as RAFMMR_2015
    , Max(Case When mt.[RAF_2016] = 'NULL'	Then Null Else mt.[RAF_2016] End)	as RAFMMR_2016
	, MAX(r13.Demographic_RAF) as RAFDemo_2013
	, MAX(r14.Demographic_RAF) as RAFDemo_2014
	, MAX(r15.Demographic_RAF) as RAFDemo_2015
	, MAX(r16.Demographic_RAF) as RAFDemo_2016
	, MAX(r13.TotalRAF) as RAFCompute_2013
	, MAX(r14.TotalRAF) as RAFCompute_2014
	, MAX(r15.TotalRAF) as RAFCompute_2015
	, MAX(r16.TotalRAF) as RAFCompute_2016
Into [pdb_WalkandWin].dbo.GP1026_WnW_RAF
From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset] ms
Left Join [pdb_WalkandWin].[dbo].[GP1026_WnW_MMRRAF_FromCR]	mt on mt.SavvyHICN	=	ms.SavvyHICN
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2013]	r13	on Cast(r13.UniqueMEmberID as Varchar)	=	ms.MiniOV_SavvyID
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2014]	r14	on Cast(r14.UniqueMEmberID as Varchar)	=	ms.MiniOV_SavvyID
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2015]	r15	on Cast(r15.UniqueMEmberID as Varchar)	=	ms.MiniOV_SavvyID
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1062_RAFScore_2016]	r16	on Cast(r16.UniqueMEmberID as varchar)	=	ms.MiniOV_SavvyID
Group By ms.SavvyHICN

-----------------------------------------------------------------------------------------------------------*/

-- Select * From [pdb_WalkandWin]..WnW_RAF13to16
-------------------------------------------------------------------------------------------------------------

-- Create HCCs

-- Create Fact Table
If Object_Id ('[pdb_WalkandWin]..GP1026_WnW_HCC')is not null
       Drop Table [pdb_WalkandWin]..GP1026_WnW_HCC;
With CTE_A as (
	Select Distinct mt.SavvyHICN, mt.MiniOV_SavvyID , fc.Diag_Cd_1 as DiagCd , dd.YEAR_NBR
	From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset]	mt
	Join [pdb_WalkandWin]..[GP1026_WnW_Claims]								fc	on fc.SavvyId			=	mt.MiniOV_SavvyID
	Join MiniOV..Dim_Date									dd	on dd.DT_SYS_ID			=	fc.Dt_Sys_Id
	Where dd.YEAR_NBR in (2016, 2015, 2014 , 2013)
	Union 
	Select Distinct mt.SavvyHICN, mt.MiniOV_SavvyID , fc.Diag_Cd_2	, dd.YEAR_NBR			
	From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset]	mt
	Join [pdb_WalkandWin]..[GP1026_WnW_Claims]								fc	on fc.SavvyId			=	mt.MiniOV_SavvyID
	Join MiniOV..Dim_Date									dd	on dd.DT_SYS_ID			=	fc.Dt_Sys_Id
	Where dd.YEAR_NBR in (2016, 2015, 2014 , 2013)
	Union 
	Select Distinct mt.SavvyHICN, mt.MiniOV_SavvyID , fc.Diag_Cd_3 , dd.YEAR_NBR
	From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset]	mt
	Join [pdb_WalkandWin]..[GP1026_WnW_Claims]								fc	on fc.SavvyId			=	mt.MiniOV_SavvyID
	Join MiniOV..Dim_Date									dd	on dd.DT_SYS_ID			=	fc.Dt_Sys_Id
	Where dd.YEAR_NBR in (2016, 2015, 2014 , 2013)
	)
, CTE_B as (
	Select Distinct fc.SavvyHICN, fc.MiniOV_SavvyID, fc.YEAR_NBR, fc.DiagCd, ml.HCCNbr, mh.Term, mh.TermLabel, mh.Coefficient
	From CTE_A										fc
	Join [RA_Medicare].[dbo].[HCCDiagnosis]			hc	on hc.ICDCd				= fc.DiagCd
	Join [RA_Medicare].[dbo].[ModelTerm]			ml	on ml.ModelTermID		=	hc.ModelTermID
	Join [RA_Commercial_2016].[dbo].[ModelHCC]		mh	on mh.HCCNbr		=	ml.HCCNbr
	Where ml.HCCNbr is not Null
		and mh.Term in ('HCC008','HCC011','HCC055','HCC054','HCC145','HCC122','HCC001','HCC113','HCC112','HCC120'
				,'HCC121','HCC097','HCC096','HCC187','HCC226','HCC125','HCC042','HCC161','HCC009','HCC132')
	)
Select SavvyHICN
	, Max(Case When Term = 'HCC008' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC008]
	, Max(Case When Term = 'HCC011' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC011]
	, Max(Case When Term = 'HCC055' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC055]
	, Max(Case When Term = 'HCC054' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC054]
	, Max(Case When Term = 'HCC145' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC145]
	, Max(Case When Term = 'HCC122' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC122]
	, Max(Case When Term = 'HCC001' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC001]
	, Max(Case When Term = 'HCC113' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC113]
	, Max(Case When Term = 'HCC112' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC112]
	, Max(Case When Term = 'HCC120' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC120]
	, Max(Case When Term = 'HCC121' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC121]
	, Max(Case When Term = 'HCC097' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC097]
	, Max(Case When Term = 'HCC096' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC096]
	, Max(Case When Term = 'HCC187' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC187]
	, Max(Case When Term = 'HCC226' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC226]
	, Max(Case When Term = 'HCC125' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC125]
	, Max(Case When Term = 'HCC042' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC042]
	, Max(Case When Term = 'HCC161' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC161]
	, Max(Case When Term = 'HCC009' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC009]
	, Max(Case When Term = 'HCC132' and YEAR_NBR = '2013' then 1 Else 0 End) as [2013_HCC132]

-- 2014
	, Max(Case When Term = 'HCC008' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC008]
	, Max(Case When Term = 'HCC011' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC011]
	, Max(Case When Term = 'HCC055' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC055]
	, Max(Case When Term = 'HCC054' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC054]
	, Max(Case When Term = 'HCC145' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC145]
	, Max(Case When Term = 'HCC122' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC122]
	, Max(Case When Term = 'HCC001' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC001]
	, Max(Case When Term = 'HCC113' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC113]
	, Max(Case When Term = 'HCC112' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC112]
	, Max(Case When Term = 'HCC120' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC120]
	, Max(Case When Term = 'HCC121' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC121]
	, Max(Case When Term = 'HCC097' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC097]
	, Max(Case When Term = 'HCC096' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC096]
	, Max(Case When Term = 'HCC187' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC187]
	, Max(Case When Term = 'HCC226' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC226]
	, Max(Case When Term = 'HCC125' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC125]
	, Max(Case When Term = 'HCC042' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC042]
	, Max(Case When Term = 'HCC161' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC161]
	, Max(Case When Term = 'HCC009' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC009]
	, Max(Case When Term = 'HCC132' and YEAR_NBR = '2014' then 1 Else 0 End) as [2014_HCC132]

-- 2015
	, Max(Case When Term = 'HCC008' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC008]
	, Max(Case When Term = 'HCC011' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC011]
	, Max(Case When Term = 'HCC055' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC055]
	, Max(Case When Term = 'HCC054' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC054]
	, Max(Case When Term = 'HCC145' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC145]
	, Max(Case When Term = 'HCC122' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC122]
	, Max(Case When Term = 'HCC001' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC001]
	, Max(Case When Term = 'HCC113' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC113]
	, Max(Case When Term = 'HCC112' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC112]
	, Max(Case When Term = 'HCC120' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC120]
	, Max(Case When Term = 'HCC121' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC121]
	, Max(Case When Term = 'HCC097' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC097]
	, Max(Case When Term = 'HCC096' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC096]
	, Max(Case When Term = 'HCC187' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC187]
	, Max(Case When Term = 'HCC226' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC226]
	, Max(Case When Term = 'HCC125' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC125]
	, Max(Case When Term = 'HCC042' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC042]
	, Max(Case When Term = 'HCC161' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC161]
	, Max(Case When Term = 'HCC009' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC009]
	, Max(Case When Term = 'HCC132' and YEAR_NBR = '2015' then 1 Else 0 End) as [2015_HCC132]

--2016
	, Max(Case When Term = 'HCC008' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC008]
	, Max(Case When Term = 'HCC011' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC011]
	, Max(Case When Term = 'HCC055' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC055]
	, Max(Case When Term = 'HCC054' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC054]
	, Max(Case When Term = 'HCC145' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC145]
	, Max(Case When Term = 'HCC122' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC122]
	, Max(Case When Term = 'HCC001' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC001]
	, Max(Case When Term = 'HCC113' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC113]
	, Max(Case When Term = 'HCC112' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC112]
	, Max(Case When Term = 'HCC120' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC120]
	, Max(Case When Term = 'HCC121' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC121]
	, Max(Case When Term = 'HCC097' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC097]
	, Max(Case When Term = 'HCC096' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC096]
	, Max(Case When Term = 'HCC187' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC187]
	, Max(Case When Term = 'HCC226' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC226]
	, Max(Case When Term = 'HCC125' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC125]
	, Max(Case When Term = 'HCC042' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC042]
	, Max(Case When Term = 'HCC161' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC161]
	, Max(Case When Term = 'HCC009' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC009]
	, Max(Case When Term = 'HCC132' and YEAR_NBR = '2016' then 1 Else 0 End) as [2016_HCC132]
Into [pdb_WalkandWin]..GP1026_WnW_HCC
From CTE_B
Group By SavvyHICN