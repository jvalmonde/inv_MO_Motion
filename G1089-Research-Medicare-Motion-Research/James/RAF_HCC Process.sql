--- Fixed RAF for WnW GP1026

/*************
**** 2013 ****
**************/

---- RAF ----
If (object_id('tempdb..#mbr_2013') Is Not Null)
Drop Table #mbr_2013

select UniqueMemberID = a.SavvyHICN, GenderCd = b.Gender, b.Age, case when c.OREC = 9 then 0 else c.OREC end as OREC, MCAID = b.MedicaidFlag, null as NEMCAID
into #mbr_2013
from pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset		a
inner join MiniOV..Dim_Member	b	on	a.MiniOV_SavvyID = b.SavvyID
left join [pdb_WalkandWin].[dbo].[GP1026_WnW_MMRRAF_FromCR]		c	on	a.SavvyHICN = c.SavvyHICN
where a.OV_MM_2013 > 0

create unique index ucIx_ID on #mbr_2013 (UniqueMemberID);

If (object_id('tempdb..#ip_conf_2013') Is Not Null)
Drop Table #ip_conf_2013

select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= d.DT_SYS_ID
	, Discharge_DtSys	= d1.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf_2013
from #mbr_2013		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID					--admit
inner join MiniOV..Dim_Date				d1	on	(c.Dt_Sys_Id + c.Day_Cnt) = d1.DT_SYS_ID	--discharge
where d.YEAR_NBR = 2013
	and c.Admit_Cnt = 1

create clustered index cIx_SavvyIDs on #ip_conf_2013 (SavvyHICN, SavvyID);
create nonclustered index nIx_Dt on #ip_conf_2013 (Admit_DtSys, Discharge_DtSys);

--- because FACT_DIAGNOSIS is not archived far back (only 3 years back) this portion had to be done differently
If (object_id('tempdb..#diag_2013') Is Not Null)
Drop Table #diag_2013

---- DIAG LEVEL 1
select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
into #diag_2013
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2013	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2013				--Year of Interest	
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
	join #ip_conf_2013			as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Claims		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_1_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID

union 
---- DIAG LEVEL 2
select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2013	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2013				--Year of Interest	
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
	join #ip_conf_2013			as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Claims		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_2_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID

union
---- DIAG LEVEL 3
select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2013	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2013				--Year of Interest	
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
	join #ip_conf_2013			as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Claims		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_3_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID



Exec RA_Medicare.dbo.spRAFDiagnosisDemographicInput
  @ModelID = 31
, @InputDiagnosisTableLocation 		= '#diag_2013'
, @InputDemographicsTableLocation 	= '#mbr_2013'
, @OutputDatabase 					= 'pdb_WalkandWin'
, @OutputSuffix 					= 'GP1026_RAFScore_2013'



---- HCC ----
if OBJECT_ID ('tempdb..#HCC_2013') is not null begin 
drop table #HCC_2013	End;

Select	a.ModelID ,UniqueMemberID, a.Coefficient , a.USedInCalcFlag 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC_2013
From	(Select	* 
		From	pdb_WalkandWin..RA_ModelTerms_GP1026_RAFScore_2013
		)										as	a
left join	RA_Medicare..ModelTerm			as	b	on	a.Term = b.Term
where b.ModelID = 31


--Dynamic Pivot:
if OBJECT_ID ('pdb_WalkandWin..GP1026_HCC_2013') is not null begin 
drop table pdb_WalkandWin..GP1026_HCC_2013	End;

declare @listcol_2013 varchar (max)			--provide dynamic DiagCdSysId_ConCat column list based on pivot base tbl
declare @listcolisnull_2013 varchar (max)	--provide isnull validation to pivot result
declare @query1_2013 varchar (max)			--Pivot data with dynamic DiagCdSysId_ConCat


select @listcol_2013 =							--provide dynamic DiagCdSysId_ConCat column list based on #HCC
STUFF((select 
			'],[' + HCC
		from  ( select distinct HCC
				from #HCC_2013
			)		as	a
			order by '],[' + HCC
			for XML path('')
				),1,2,'') + ']'

select @listcolisnull_2013 =						--provide isnull validation to pivot result
STUFF((select 
			', isnull([' +ltrim(HCC)+ '],0) as [' +ltrim(HCC)+ '] '
		From (select distinct HCC
				from #HCC_2013
				)	as	b
		Order by HCC
			for XML path('')
				),1,2,'') 
				

--Set variable to pivot data based on #HCC using DiagCdSysId_ConCatcolumns in @listcol and @listcolisnull validation. 
		
set @query1_2013 = 

'select UniqueMemberID, '+ @listcolisnull_2013 +'
into pdb_WalkandWin..GP1026_HCC_2013
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC_2013
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol_2013+'))				as pvt	'

execute (@query1_2013)



/*************
**** 2014 ****
**************/

---- RAF ----
If (object_id('tempdb..#mbr_2014') Is Not Null)
Drop Table #mbr_2014

select UniqueMemberID = a.SavvyHICN, GenderCd = b.Gender, b.Age, case when c.OREC = 9 then 0 else c.OREC end as OREC, MCAID = b.MedicaidFlag, null as NEMCAID
into #mbr_2014
from pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset		a
inner join MiniOV..Dim_Member	b	on	a.MiniOV_SavvyID = b.SavvyID
left join [pdb_WalkandWin].[dbo].[GP1026_WnW_MMRRAF_FromCR]		c	on	a.SavvyHICN = c.SavvyHICN
where a.OV_MM_2014 > 0

create unique index ucIx_ID on #mbr_2014 (UniqueMemberID);

If (object_id('tempdb..#ip_conf_2014') Is Not Null)
Drop Table #ip_conf_2014


select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= d.DT_SYS_ID
	, Discharge_DtSys	= d1.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf_2014
from #mbr_2014		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID					--admit
inner join MiniOV..Dim_Date				d1	on	(c.Dt_Sys_Id + c.Day_Cnt) = d1.DT_SYS_ID	--discharge
where d.YEAR_NBR = 2014
	and c.Admit_Cnt = 1

create clustered index cIx_SavvyIDs on #ip_conf_2014 (SavvyHICN, SavvyID);
create nonclustered index nIx_Dt on #ip_conf_2014 (Admit_DtSys, Discharge_DtSys);

--- because FACT_DIAGNOSIS is not archived far back (only 3 years back) this portion had to be done differently
If (object_id('tempdb..#diag_2014') Is Not Null)
Drop Table #diag_2014

---- DIAG LEVEL 1
select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
into #diag_2014
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2014	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2014				--Year of Interest	
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
	join #ip_conf_2014			as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Claims		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_1_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID

union 
---- DIAG LEVEL 2
select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2014	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2014				--Year of Interest	
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
	join #ip_conf_2014			as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Claims		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_2_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID

union
---- DIAG LEVEL 3
select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2014	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2014				--Year of Interest	
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
	join #ip_conf_2014			as b	on a.SavvyId = b.SavvyId
										   and a.Dt_Sys_Id between b.Admit_DtSys and b.Discharge_DtSys
	where a.Srvc_Typ_Sys_Id = 1		--IP
	  and a.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
	)							as a 
join MiniOV..Fact_Claims		as b	on a.SavvyId = b.SavvyId
                                       and a.Mbr_Sys_Id = b.Mbr_Sys_Id
                                       and a.Clm_Aud_Nbr = b.Clm_Aud_Nbr
join MiniOV..Dim_Diagnosis_Code	as c	on b.Diag_3_Cd_Sys_Id = c.Diag_Cd_Sys_Id
join MiniOV..Dim_Date			as d	on b.Dt_Sys_Id = d.DT_SYS_ID


Exec RA_Medicare.dbo.spRAFDiagnosisDemographicInput
  @ModelID = 31
, @InputDiagnosisTableLocation 		= '#diag_2014'
, @InputDemographicsTableLocation 	= '#mbr_2014'
, @OutputDatabase 					= 'pdb_WalkandWin'
, @OutputSuffix 					= 'GP1026_RAFScore_2014'



---- HCC ----
if OBJECT_ID ('tempdb..#HCC_2014') is not null begin 
drop table #HCC_2014	End;

Select	a.ModelID ,UniqueMemberID, a.Coefficient , a.USedInCalcFlag 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC_2014
From	(Select	* 
		From	pdb_WalkandWin..RA_ModelTerms_GP1026_RAFScore_2014
		)										as	a
left join	RA_Medicare..ModelTerm			as	b	on	a.Term = b.Term
where b.ModelID = 31


--Dynamic Pivot:
if OBJECT_ID ('pdb_WalkandWin..GP1026_HCC_2014') is not null begin 
drop table pdb_WalkandWin..GP1026_HCC_2014	End;

declare @listcol_2014 varchar (max)			--provide dynamic DiagCdSysId_ConCat column list based on pivot base tbl
declare @listcolisnull_2014 varchar (max)	--provide isnull validation to pivot result
declare @query1_2014 varchar (max)			--Pivot data with dynamic DiagCdSysId_ConCat


select @listcol_2014 =							--provide dynamic DiagCdSysId_ConCat column list based on #HCC
STUFF((select 
			'],[' + HCC
		from  ( select distinct HCC
				from #HCC_2014
			)		as	a
			order by '],[' + HCC
			for XML path('')
				),1,2,'') + ']'

select @listcolisnull_2014 =						--provide isnull validation to pivot result
STUFF((select 
			', isnull([' +ltrim(HCC)+ '],0) as [' +ltrim(HCC)+ '] '
		From (select distinct HCC
				from #HCC_2014
				)	as	b
		Order by HCC
			for XML path('')
				),1,2,'') 
				

--Set variable to pivot data based on #HCC using DiagCdSysId_ConCatcolumns in @listcol and @listcolisnull validation. 
		
set @query1_2014 = 

'select UniqueMemberID, '+ @listcolisnull_2014 +'
into pdb_WalkandWin..GP1026_HCC_2014
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC_2014
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol_2014+'))				as pvt	'

execute (@query1_2014)



/*************
**** 2015 ****
**************/

---- RAF ----
If (object_id('tempdb..#mbr_2015') Is Not Null)
Drop Table #mbr_2015

select UniqueMemberID = a.SavvyHICN, GenderCd = b.Gender, b.Age, case when c.OREC = 9 then 0 else c.OREC end as OREC, MCAID = b.MedicaidFlag, null as NEMCAID
into #mbr_2015
from pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset		a
inner join MiniOV..Dim_Member	b	on	a.MiniOV_SavvyID = b.SavvyID
left join [pdb_WalkandWin].[dbo].[GP1026_WnW_MMRRAF_FromCR]		c	on	a.SavvyHICN = c.SavvyHICN
where a.OV_MM_2015 > 0

create unique index ucIx_ID on #mbr_2015 (UniqueMemberID);

If (object_id('tempdb..#ip_conf_2015') Is Not Null)
Drop Table #ip_conf_2015


select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= d.DT_SYS_ID
	, Discharge_DtSys	= d1.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf_2015
from #mbr_2015		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID					--admit
inner join MiniOV..Dim_Date				d1	on	(c.Dt_Sys_Id + c.Day_Cnt) = d1.DT_SYS_ID	--discharge
where d.YEAR_NBR = 2015
	and c.Admit_Cnt = 1

create clustered index cIx_SavvyIDs on #ip_conf_2015 (SavvyHICN, SavvyID);
create nonclustered index nIx_Dt on #ip_conf_2015 (Admit_DtSys, Discharge_DtSys);


If (object_id('tempdb..#diag_2015') Is Not Null)
Drop Table #diag_2015


select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
into #diag_2015
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2015	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
			)															as e	on a.SavvyId = e.SavvyID
	where d.YEAR_NBR = 2015				--Year of Interest	
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
	join #ip_conf_2015			as b	on a.SavvyId = b.SavvyId
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


Exec RA_Medicare.dbo.spRAFDiagnosisDemographicInput
  @ModelID = 31
, @InputDiagnosisTableLocation 		= '#diag_2015'
, @InputDemographicsTableLocation 	= '#mbr_2015'
, @OutputDatabase 					= 'pdb_WalkandWin'
, @OutputSuffix 					= 'GP1026_RAFScore_2015'



---- HCC ----
if OBJECT_ID ('tempdb..#HCC_2015') is not null begin 
drop table #HCC_2015	End;

Select	a.ModelID ,UniqueMemberID, a.Coefficient , a.USedInCalcFlag 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC_2015
From	(Select	* 
		From	pdb_WalkandWin..RA_ModelTerms_GP1026_RAFScore_2015
		)										as	a
left join	RA_Medicare..ModelTerm			as	b	on	a.Term = b.Term
where b.ModelID = 31


--Dynamic Pivot:
if OBJECT_ID ('pdb_WalkandWin..GP1026_HCC_2015') is not null begin 
drop table pdb_WalkandWin..GP1026_HCC_2015	End;

declare @listcol_2015 varchar (max)			--provide dynamic DiagCdSysId_ConCat column list based on pivot base tbl
declare @listcolisnull_2015 varchar (max)	--provide isnull validation to pivot result
declare @query1_2015 varchar (max)			--Pivot data with dynamic DiagCdSysId_ConCat


select @listcol_2015 =							--provide dynamic DiagCdSysId_ConCat column list based on #HCC
STUFF((select 
			'],[' + HCC
		from  ( select distinct HCC
				from #HCC_2015
			)		as	a
			order by '],[' + HCC
			for XML path('')
				),1,2,'') + ']'

select @listcolisnull_2015 =						--provide isnull validation to pivot result
STUFF((select 
			', isnull([' +ltrim(HCC)+ '],0) as [' +ltrim(HCC)+ '] '
		From (select distinct HCC
				from #HCC_2015
				)	as	b
		Order by HCC
			for XML path('')
				),1,2,'') 
				

--Set variable to pivot data based on #HCC using DiagCdSysId_ConCatcolumns in @listcol and @listcolisnull validation. 
		
set @query1_2015 = 

'select UniqueMemberID, '+ @listcolisnull_2015 +'
into pdb_WalkandWin..GP1026_HCC_2015
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC_2015
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol_2015+'))				as pvt	'

execute (@query1_2015)



/*************
**** 2016 ****
**************/

---- RAF ----
If (object_id('tempdb..#mbr_2016') Is Not Null)
Drop Table #mbr_2016

select UniqueMemberID = a.SavvyHICN, GenderCd = b.Gender, b.Age, case when c.OREC = 9 then 0 else c.OREC end as OREC, MCAID = b.MedicaidFlag, null as NEMCAID
into #mbr_2016
from pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset		a
inner join MiniOV..Dim_Member	b	on	a.MiniOV_SavvyID = b.SavvyID
left join [pdb_WalkandWin].[dbo].[GP1026_WnW_MMRRAF_FromCR]		c	on	a.SavvyHICN = c.SavvyHICN
where a.OV_MM_2016 > 0

create unique index ucIx_ID on #mbr_2016 (UniqueMemberID);

If (object_id('tempdb..#ip_conf_2016') Is Not Null)
Drop Table #ip_conf_2016


select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= d.DT_SYS_ID
	, Discharge_DtSys	= d1.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf_2016
from #mbr_2016		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID					--admit
inner join MiniOV..Dim_Date				d1	on	(c.Dt_Sys_Id + c.Day_Cnt) = d1.DT_SYS_ID	--discharge
where d.YEAR_NBR = 2016
	and c.Admit_Cnt = 1

create clustered index cIx_SavvyIDs on #ip_conf_2016 (SavvyHICN, SavvyID);
create nonclustered index nIx_Dt on #ip_conf_2016 (Admit_DtSys, Discharge_DtSys);


If (object_id('tempdb..#diag_2016') Is Not Null)
Drop Table #diag_2016


select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD, c.ICD_VER_CD as IcdVerCd
into #diag_2016
from(
	--DR and OP
	select a.SavvyId, e.SavvyHICN, a.Mbr_Sys_Id, a.Clm_Aud_Nbr
	from MiniOV..Fact_Claims											as a 
	join MiniOV..Dim_Procedure_Code										as b	on a.Proc_Cd_Sys_Id = b.PROC_CD_SYS_ID
	join [RA_Medicare_2014_v2 ]..Reportable_PhysicianProcedureCodes		as c	on b.PROC_CD = c.Procedure_Code
	join MiniOV..Dim_Date												as d	on a.Dt_Sys_Id = d.DT_SYS_ID
	join	(
				select b.*
				from #mbr_2016	a
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
	join #ip_conf_2016			as b	on a.SavvyId = b.SavvyId
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


Exec RA_Medicare.dbo.spRAFDiagnosisDemographicInput
  @ModelID = 31
, @InputDiagnosisTableLocation 		= '#diag_2016'
, @InputDemographicsTableLocation 	= '#mbr_2016'
, @OutputDatabase 					= 'pdb_WalkandWin'
, @OutputSuffix 					= 'GP1026_RAFScore_2016'



---- HCC ----
if OBJECT_ID ('tempdb..#HCC_2016') is not null begin 
drop table #HCC_2016	End;

Select	a.ModelID ,UniqueMemberID, a.Coefficient , a.USedInCalcFlag 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC_2016
From	(Select	* 
		From	pdb_WalkandWin..RA_ModelTerms_GP1026_RAFScore_2016
		)										as	a
left join	RA_Medicare..ModelTerm			as	b	on	a.Term = b.Term
where b.ModelID = 31


--Dynamic Pivot:
if OBJECT_ID ('pdb_WalkandWin..GP1026_HCC_2016') is not null begin 
drop table pdb_WalkandWin..GP1026_HCC_2016	End;

declare @listcol_2016 varchar (max)			--provide dynamic DiagCdSysId_ConCat column list based on pivot base tbl
declare @listcolisnull_2016 varchar (max)	--provide isnull validation to pivot result
declare @query1_2016 varchar (max)			--Pivot data with dynamic DiagCdSysId_ConCat


select @listcol_2016 =							--provide dynamic DiagCdSysId_ConCat column list based on #HCC
STUFF((select 
			'],[' + HCC
		from  ( select distinct HCC
				from #HCC_2016
			)		as	a
			order by '],[' + HCC
			for XML path('')
				),1,2,'') + ']'

select @listcolisnull_2016 =						--provide isnull validation to pivot result
STUFF((select 
			', isnull([' +ltrim(HCC)+ '],0) as [' +ltrim(HCC)+ '] '
		From (select distinct HCC
				from #HCC_2016
				)	as	b
		Order by HCC
			for XML path('')
				),1,2,'') 
				

--Set variable to pivot data based on #HCC using DiagCdSysId_ConCatcolumns in @listcol and @listcolisnull validation. 
		
set @query1_2016 = 

'select UniqueMemberID, '+ @listcolisnull_2016 +'
into pdb_WalkandWin..GP1026_HCC_2016
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC_2016
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol_2016+'))				as pvt	'

execute (@query1_2016)


/****

Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2013]
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2014]
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2015]
Drop Table [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2016]

****/



/*****************/
/*** RAF Table ***/
/*****************/

If Object_Id ('[pdb_WalkandWin]..GP1026_WnW_RAF')is not null
       Drop Table [pdb_WalkandWin]..GP1026_WnW_RAF;

Select ms.SavvyHICN
	, Case when mt.[OREC] = 9 then 0 Else mt.[OREC] End		as OREC
    , mt.[RAF_2013]											as RAFMMR_2013
    , mt.[RAF_2014]											as RAFMMR_2014
    , mt.[RAF_2015]											as RAFMMR_2015
    , mt.[RAF_2016]											as RAFMMR_2016

	, r13.Demographic_RAF									as RAFDemo_2013
	, r14.Demographic_RAF									as RAFDemo_2014
	, r15.Demographic_RAF									as RAFDemo_2015
	, r16.Demographic_RAF									as RAFDemo_2016

	, r13.TotalRAF											as RAFCompute_2013
	, r14.TotalRAF											as RAFCompute_2014
	, r15.TotalRAF											as RAFCompute_2015
	, r16.TotalRAF											as RAFCompute_2016

Into [pdb_WalkandWin].dbo.GP1026_WnW_RAF

From [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset] ms
Left Join [pdb_WalkandWin].[dbo].[GP1026_WnW_MMRRAF_FromCR]		mt	on mt.SavvyHICN							=	ms.SavvyHICN
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2013]	r13	on convert(varchar,r13.UniqueMemberID)	=	ms.SavvyHICN
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2014]	r14	on convert(varchar,r14.UniqueMemberID)	=	ms.SavvyHICN
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2015]	r15	on convert(varchar,r15.UniqueMemberID)	=	ms.SavvyHICN
Left Join [pdb_WalkandWin].[dbo].[RA_RAF_GP1026_RAFScore_2016]	r16	on convert(varchar,r16.UniqueMemberID)	=	ms.SavvyHICN


create unique clustered index ucix on [pdb_WalkandWin].dbo.GP1026_WnW_RAF(SavvyHICN)


/*****************/
/*** HCC Table ***/
/*****************/

/****** TOP 20 HCC for 2016 ******/
/* This is based from the HCC output from the RAF calculator 
(pdb_WalkandWin..GP1026_HCC_2016) for the year 2016, ModelID 31
Count is based of distinct member counts:
--------------------
HCC19			9305
HCC18			5489
HCC96			3980
HCC111			3741
HCC85			3128
HCC108			2909
HCC12			2117
HCC40			1671
HCC58			1446
DIABETES_CHF	1405
HCC135			1339
HCC84			1141
HCC22			1037
HCC88			895
HCC48			852
CHF_COPD		835
HCC100			795
HCC2			765
HCC23			747
HCC11			677
-------------------- */

If Object_Id ('pdb_WalkandWin.dbo.GP1026_WnW_HCC')is not null
Drop Table pdb_WalkandWin.dbo.GP1026_WnW_HCC;

select a.SavvyHICN
-- 2013
,case when b.HCC19			is null then 0 else b.HCC19				end as [2013_HCC19]
,case when b.HCC18			is null then 0 else b.HCC18				end as [2013_HCC18]		   
,case when b.HCC96			is null then 0 else b.HCC96				end as [2013_HCC96]		   
,case when b.HCC111			is null then 0 else b.HCC111			end as [2013_HCC111]		   
,case when b.HCC85			is null then 0 else b.HCC85				end as [2013_HCC85]		   
,case when b.HCC108			is null then 0 else b.HCC108			end as [2013_HCC108]		   
,case when b.HCC12			is null then 0 else b.HCC12				end as [2013_HCC12]		   
,case when b.HCC40			is null then 0 else b.HCC40				end as [2013_HCC40]		   
,case when b.HCC58			is null then 0 else b.HCC58				end as [2013_HCC58]		   
,case when b.DIABETES_CHF	is null then 0 else b.DIABETES_CHF		end as [2013_DIABETES_CHF]		   
,case when b.HCC135			is null then 0 else b.HCC135			end as [2013_HCC135]		   
,case when b.HCC84			is null then 0 else b.HCC84				end as [2013_HCC84]		   
,case when b.HCC22			is null then 0 else b.HCC22				end as [2013_HCC22]		   
,case when b.HCC88			is null then 0 else b.HCC88				end as [2013_HCC88]		   
,case when b.HCC48			is null then 0 else b.HCC48				end as [2013_HCC48]		   
,case when b.CHF_COPD		is null then 0 else b.CHF_COPD			end as [2013_CHF_COPD]		   
,case when b.HCC100			is null then 0 else b.HCC100			end as [2013_HCC100]		   
,case when b.HCC2			is null then 0 else b.HCC2				end as [2013_HCC2]		   
,case when b.HCC23			is null then 0 else b.HCC23				end as [2013_HCC23]		   
,case when b.HCC11			is null then 0 else b.HCC11				end as [2013_HCC11]

-- 2014
,case when c.HCC19			is null then 0 else c.HCC19				end as [2014_HCC19]
,case when c.HCC18			is null then 0 else c.HCC18				end as [2014_HCC18]		   
,case when c.HCC96			is null then 0 else c.HCC96				end as [2014_HCC96]		   
,case when c.HCC111			is null then 0 else c.HCC111			end as [2014_HCC111]		   
,case when c.HCC85			is null then 0 else c.HCC85				end as [2014_HCC85]		   
,case when c.HCC108			is null then 0 else c.HCC108			end as [2014_HCC108]		   
,case when c.HCC12			is null then 0 else c.HCC12				end as [2014_HCC12]		   
,case when c.HCC40			is null then 0 else c.HCC40				end as [2014_HCC40]		   
,case when c.HCC58			is null then 0 else c.HCC58				end as [2014_HCC58]		   
,case when c.DIABETES_CHF	is null then 0 else c.DIABETES_CHF		end as [2014_DIABETES_CHF]		   
,case when c.HCC135			is null then 0 else c.HCC135			end as [2014_HCC135]		   
,case when c.HCC84			is null then 0 else c.HCC84				end as [2014_HCC84]		   
,case when c.HCC22			is null then 0 else c.HCC22				end as [2014_HCC22]		   
,case when c.HCC88			is null then 0 else c.HCC88				end as [2014_HCC88]		   
,case when c.HCC48			is null then 0 else c.HCC48				end as [2014_HCC48]		   
,case when c.CHF_COPD		is null then 0 else c.CHF_COPD			end as [2014_CHF_COPD]		   
,case when c.HCC100			is null then 0 else c.HCC100			end as [2014_HCC100]		   
,case when c.HCC2			is null then 0 else c.HCC2				end as [2014_HCC2]		   
,case when c.HCC23			is null then 0 else c.HCC23				end as [2014_HCC23]		   
,case when c.HCC11			is null then 0 else c.HCC11				end as [2014_HCC11]

-- 2015
,case when d.HCC19			is null then 0 else d.HCC19				end as [2015_HCC19]
,case when d.HCC18			is null then 0 else d.HCC18				end as [2015_HCC18]		   
,case when d.HCC96			is null then 0 else d.HCC96				end as [2015_HCC96]		   
,case when d.HCC111			is null then 0 else d.HCC111			end as [2015_HCC111]		   
,case when d.HCC85			is null then 0 else d.HCC85				end as [2015_HCC85]		   
,case when d.HCC108			is null then 0 else d.HCC108			end as [2015_HCC108]		   
,case when d.HCC12			is null then 0 else d.HCC12				end as [2015_HCC12]		   
,case when d.HCC40			is null then 0 else d.HCC40				end as [2015_HCC40]		   
,case when d.HCC58			is null then 0 else d.HCC58				end as [2015_HCC58]		   
,case when d.DIABETES_CHF	is null then 0 else d.DIABETES_CHF		end as [2015_DIABETES_CHF]		   
,case when d.HCC135			is null then 0 else d.HCC135			end as [2015_HCC135]		   
,case when d.HCC84			is null then 0 else d.HCC84				end as [2015_HCC84]		   
,case when d.HCC22			is null then 0 else d.HCC22				end as [2015_HCC22]		   
,case when d.HCC88			is null then 0 else d.HCC88				end as [2015_HCC88]		   
,case when d.HCC48			is null then 0 else d.HCC48				end as [2015_HCC48]		   
,case when d.CHF_COPD		is null then 0 else d.CHF_COPD			end as [2015_CHF_COPD]		   
,case when d.HCC100			is null then 0 else d.HCC100			end as [2015_HCC100]		   
,case when d.HCC2			is null then 0 else d.HCC2				end as [2015_HCC2]		   
,case when d.HCC23			is null then 0 else d.HCC23				end as [2015_HCC23]		   
,case when d.HCC11			is null then 0 else d.HCC11				end as [2015_HCC11]

-- 2016
,case when e.HCC19			is null then 0 else e.HCC19				end as [2016_HCC19]
,case when e.HCC18			is null then 0 else e.HCC18				end as [2016_HCC18]		   
,case when e.HCC96			is null then 0 else e.HCC96				end as [2016_HCC96]		   
,case when e.HCC111			is null then 0 else e.HCC111			end as [2016_HCC111]		   
,case when e.HCC85			is null then 0 else e.HCC85				end as [2016_HCC85]		   
,case when e.HCC108			is null then 0 else e.HCC108			end as [2016_HCC108]		   
,case when e.HCC12			is null then 0 else e.HCC12				end as [2016_HCC12]		   
,case when e.HCC40			is null then 0 else e.HCC40				end as [2016_HCC40]		   
,case when e.HCC58			is null then 0 else e.HCC58				end as [2016_HCC58]		   
,case when e.DIABETES_CHF	is null then 0 else e.DIABETES_CHF		end as [2016_DIABETES_CHF]		   
,case when e.HCC135			is null then 0 else e.HCC135			end as [2016_HCC135]		   
,case when e.HCC84			is null then 0 else e.HCC84				end as [2016_HCC84]		   
,case when e.HCC22			is null then 0 else e.HCC22				end as [2016_HCC22]		   
,case when e.HCC88			is null then 0 else e.HCC88				end as [2016_HCC88]		   
,case when e.HCC48			is null then 0 else e.HCC48				end as [2016_HCC48]		   
,case when e.CHF_COPD		is null then 0 else e.CHF_COPD			end as [2016_CHF_COPD]		   
,case when e.HCC100			is null then 0 else e.HCC100			end as [2016_HCC100]		   
,case when e.HCC2			is null then 0 else e.HCC2				end as [2016_HCC2]		   
,case when e.HCC23			is null then 0 else e.HCC23				end as [2016_HCC23]		   
,case when e.HCC11			is null then 0 else e.HCC11				end as [2016_HCC11]		   

into pdb_WalkandWin.dbo.GP1026_WnW_HCC

from [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset] as a
left join pdb_WalkandWin..GP1026_HCC_2013 as b on a.SavvyHICN = convert(varchar,b.UniqueMemberID)
left join pdb_WalkandWin..GP1026_HCC_2014 as c on a.SavvyHICN = convert(varchar,c.UniqueMemberID)
left join pdb_WalkandWin..GP1026_HCC_2015 as d on a.SavvyHICN = convert(varchar,d.UniqueMemberID)
left join pdb_WalkandWin..GP1026_HCC_2016 as e on a.SavvyHICN = convert(varchar,e.UniqueMemberID)


create unique clustered index ucix on pdb_WalkandWin.dbo.GP1026_WnW_HCC(SavvyHICN)

