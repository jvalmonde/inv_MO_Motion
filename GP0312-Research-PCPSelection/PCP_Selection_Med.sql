/*** 
PCP Selection (Medicare - Stars population)
Reference: Yihan's email to Matt (18 April 2016)

Input databases:	MiniOV, pdb_Stars..Master_Extract_Data_Mart_201502_Clean

Date Created: 25 April 2016
***/

--pull for the members
if object_id('tempdb..#member') is not null
drop table #member
go

select top 10 percent SavvyHICN, ASGN_PROV_MPIN_NUM, ASSOC_PROV_MPIN_NUM
into #member
from pdb_Stars..Master_Extract_Data_Mart_201502_Clean
where SRC_SYS = 'CO'
order by newid()
--(155766 row(s) affected)
create unique clustered index ucIx_HICN on #member (SavvyHICN);


if object_id('tempdb..#pcpflag') is not null
drop table #pcpflag
go

select MPIN, PCP_Flag = Case when SpecTypeCd in ('001','008','011','019','037','038','041','077','230','236','251','258'
                                                                            ,'272','273','274','275','276','281','282','338','339','375','384','506')  Then 1 Else 0 End           --codes used where taken from PAM project
into #pcpflag
from NDB..Prov_Specialties
where PrimaryInd = 'P'
--(2652529 row(s) affected) with the primary indicator
create clustered index ucIx_MPIN on #pcpflag (MPIN);

if object_id('tempdb..#specialty') is not null
drop table #specialty
go

select MPIN, NPI, SpecTypeCd, ShortDesc, LongDesc
into #specialty
from   (      
			select a.MPIN, NPI = d.NatlProvID, c.SpecTypeCd, c.ShortDesc, c.LongDesc
			       , OID = row_number() over(partition by a.MPIN order by (case when b.PrimaryInd = 'P'     then 1 else 0 end) desc) --not all MPINs have Primary specialties; assign a specialty
			from NDB..Provider   a
			inner join NDB..Prov_Specialties  b      on     a.MPIN = b.MPIN
			left join NDB..Specialty_Types    c      on     b.SpecTypeCd = c.SpecTypeCd
			inner join NDB..NPI               d      on     a.MPIN = d.MPIN
		) x
where OID = 1
--(2051828 row(s) affected)
create unique clustered index ucIx_MPIN on #specialty (MPIN);

if object_id('tempdb..#ip_conf') is not null
drop table #ip_conf
go

select b.SavvyID, Admt_DtSys = c.Dt_Sys_Id, Discharge_DtSys = (c.Dt_Sys_Id + c.Day_Cnt)
into #ip_conf
from #member	a
inner join MiniOV..SavvyID_to_SavvyHICN		b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Fact_Claims				c	on	b.SavvyID = c.SavvyID
inner join MiniOV..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
where d.YEAR_NBR = 2014
	and c.Srvc_Typ_Sys_Id = 1
	and c.Admit_Cnt = 1
group by b.SavvyID, c.Dt_Sys_Id, c.Day_Cnt
--(37765 row(s) affected); 
create clustered index cIx_SavvyID on #ip_conf (SavvyID);
create nonclustered index ncIx_Dt on #ip_conf (Admt_DtSys, Discharge_DtSys);

if object_id('pdb_PCPSelection..Prov_Claims_10') is not null
drop table pdb_PCPSelection..Prov_Claims_10
go

select SavvyHICN, Providers = MPIN
	, PCP_Flag	= isnull(PCP_Flag,0)
	, Specialty = LongDesc
	--spend
	, IP_Spend	= sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	else 0	end)
	, OP_Spend	= sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	else 0	end)
	, DR_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	else 0	end)
	, ER_Spend	= sum(case when HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then Allw_Amt	else 0	end)
	, PCP_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Allw_Amt	else 0	end)

	--visit counts
	, IP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'IP'	and Admit_Cnt = 1	then Dt_Sys_Id	end)
	, OP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'OP'	then Dt_Sys_Id	end)
	, DR_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR'	then Dt_Sys_Id	end)
	, ER_SrvcCnt	= count(distinct case when HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then Dt_Sys_Id	end)
	, PCP_VstCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Dt_Sys_Id	end)

	, StartDate = cast(min(Full_Dt) as date)
	, EndDate	= cast(max(Full_Dt) as date)
	, OID = row_number() over(partition by SavvyHICN order by min(Full_Dt))
into pdb_PCPSelection..Prov_Claims_10
from	(		
			select a.SavvyHICN, c.*, Derived_Srvc_Type_cd = case when j.SavvyID is not null and g.Srvc_Typ_Cd <> 'IP'  then 'IP'  else g.Srvc_Typ_Cd end
				, d.FULL_DT, f.HCE_SRVC_TYP_DESC, e.MPIN
				, PCP_Flag = case when j.SavvyID is not null and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys	then 0	else h.PCP_Flag	end
				, i.LongDesc
			from #member	a
			inner join MiniOV..SavvyID_to_SavvyHICN		b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniOV..Fact_Claims				c	on	b.SavvyID = c.SavvyID
			inner join MiniOV..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			inner join MiniOV..Dim_OVA_Provider			e	on	c.Prov_Sys_Id = e.Prov_Sys_Id
			inner join MiniOV..Dim_HP_Service_Type_Code	f	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = f.HLTH_PLN_SRVC_TYP_CD_SYS_ID
			inner join MiniOV..Dim_Service_Type			g	on	c.Srvc_Typ_Sys_Id = g.Srvc_Typ_Sys_Id
			left join #pcpflag							h	on	e.MPIN = h.MPIN
			left join #specialty						i	on	e.MPIN = i.MPIN
			left join #ip_conf							j	on	b.SavvyID = j.SavvyID
															and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys
			where d.YEAR_NBR = 2014
				and e.MPIN <> 0
		) z
group by SavvyHICN, MPIN, PCP_Flag, LongDesc
--(1346270 row(s) affected); 25.09 minutes
create clustered index cIx_HICN_MPIN on pdb_PCPSelection..Prov_Claims_10 (SavvyHICN, Providers);

--RX Claims
if object_id('tempdb..#rxclaims') is not null
drop table #rxclaims
go

select a.SavvyHICN
	, RX_Spend		= sum(c.Allowed)
	, RX_Scripts	= sum(c.Script_Cnt)
into #rxclaims
from pdb_PCPSelection..MbrClass_10	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
where c.Claim_Status <> 'X'
	and d.YEAR_NBR = 2014
group by a.SavvyHICN
--(135384 row(s) affected)
create unique clustered index ucIx_HICN on #rxclaims (SavvyHICN);


if object_id('pdb_PCPSelection..Prov_Claims_10_v2') is not null
drop table pdb_PCPSelection..Prov_Claims_10_v2
go

select a.SavvyHICN, a.Providers, a.PCP_Flag, a.Specialty, c.TIN
	, a.IP_Spend, a.OP_Spend, a.DR_Spend, a.ER_Spend, a.PCP_Spend, RX_Spend = isnull(b.RX_Spend, 0)
	, a.IP_SrvcCnt, a.OP_SrvcCnt, a.DR_SrvcCnt, a.ER_SrvcCnt, a.PCP_VstCnt, RX_Scripts = isnull(b.RX_Scripts, 0)
	, a.StartDate, a.EndDate, a.OID
--into pdb_PCPSelection..Prov_Claims_10_v2
from pdb_PCPSelection..Prov_Claims_10	a
left join #rxclaims						b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Dim_OVA_Provider		c	on	a.Providers = c.MPIN
--(1346270 row(s) affected)
create clustered index cIx_HICN_MPIN on pdb_PCPSelection..Prov_Claims_10_v2 (SavvyHICN, Providers);

select * from pdb_PCPSelection..Prov_Claims_10


/* 
drop table pdb_PCPSelection..Prov_Claims_10
rename tables back to original
*/

--identify member classification
if object_id('tempdb..#class') is not null
drop table #class
go

select SavvyHICN
	, Splitter = max(Splitter)
	, Switcher = case when max(Splitter) = 0 and max(x.OID) <> 1	then 1	else 0	end
	, Sticker = case when max(x.OID) = 1	then 1	else 0 end
into #class
from	(	
			select a.*, Prov2 = b.Providers, StrtDt2 = b.StartDate, EndDt2 = b.EndDate, OID2 = b.OID
				, Splitter = (case when a.StartDate between b.StartDAte and b.EndDate	then 1	else 0 end)
			from	(	
						select SavvyHICN, Providers, StartDate, EndDate, OID = row_number() over (partition by SavvyHICN order by StartDate)
						from pdb_PCPSelection..Prov_Claims_10
						where PCP_Flag = 1
					)	a
			left join (	
						select SavvyHICN, Providers, StartDate, EndDate, OID = row_number() over (partition by SavvyHICN order by StartDate)
						from pdb_PCPSelection..Prov_Claims_10
						where PCP_Flag = 1
					) b	on	a.SavvyHICN = b.SavvyHICN
						and a.OID = (b.OID + 1)
		) x
group by SavvyHICN
--(124568 row(s) affected)
create unique clustered index ucIx_HICN on #class (SavvyHICN);

/*
if object_id('pdb_PCPSelection..MbrClass_20160425') is not null
drop table pdb_PCPSelection..MbrClass_20160425
go
*/

if object_id('tempdb..#memberclass') is not null
drop table #memberclass
go

select a.SavvyHICN
	, Assigned_MPIN		= a.ASGN_PROV_MPIN_NUM
	, Associated_MPIN	= a.ASSOC_PROV_MPIN_NUM
	, Match	= case when a.ASGN_PROV_MPIN_NUM = a.ASSOC_PROV_MPIN_NUM	then 1	else 0	end
	, Switcher	= isnull(b.Switcher, 0)
	, Splitter	= isnull(b.Splitter, 0)
	, Sticker	= isnull(b.Sticker, 0)
	, Total_IP_Spend	
	, Total_OP_Spend	
	, Total_DR_Spend	
	, Total_ER_Spend	
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
	, RAF		= sum(c.RiskAdjusterFactorA)
into #memberclass
from #member	a
left join #class	b	on	a.SavvyHICN = b.SavvyHICN
left join	CmsMMR..CmsMMR	c	on	a.SavvyHICN = c.SavvyHICN
left join	(
				select SavvyHICN
					, Total_IP_Spend	= sum(IP_Spend)
					, Total_OP_Spend	= sum(OP_Spend)
					, Total_DR_Spend	= sum(DR_Spend)
					, Total_ER_Spend	= sum(ER_Spend)
					, Total_IP_SrvcCnt	= sum(IP_SrvcCnt)
					, Total_OP_SrvcCnt	= sum(OP_SrvcCnt)
					, Total_DR_SrvcCnt	= sum(DR_SrvcCnt)
					, Total_ER_SrvcCnt	= sum(ER_SrvcCnt)
				from pdb_PCPSelection..Prov_Claims_10
				group by SavvyHICN
			)	d	on	a.SavvyHICN = d.SavvyHICN

where year(c.PaymentAdjustmentStartDate) = 2014
group by  a.SavvyHICN
	, a.ASGN_PROV_MPIN_NUM
	, a.ASSOC_PROV_MPIN_NUM
	, b.Switcher
	, b.Splitter
	, b.Sticker
	, Total_IP_Spend	
	, Total_OP_Spend	
	, Total_DR_Spend	
	, Total_ER_Spend	
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
--(155766 row(s) affected); 1.23 hours
create unique clustered index ucIx_HICN on #memberclass (SavvyHICN);

select count(distinct SAvvyHICN)
from pdb_PCPSelection..MbrClass_10

--add weight
if object_id('pdb_PCPSelection..MbrClass_10') is not null
drop table pdb_PCPSelection..MbrClass_10
go

select a.SavvyHICN
	, Assigned_MPIN		
	, Associated_MPIN	
	, Match	
	, Switcher	
	, Splitter	
	, Sticker
	, Weight = (1 - b.Percnt)	
	, Total_IP_Spend	
	, Total_OP_Spend	
	, Total_DR_Spend	
	, Total_ER_Spend	
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
	, RAF	
into pdb_PCPSelection..MbrClass_10
from #memberclass	a
inner join	(
				select a.SavvyHICN, b.PCP_VstCnt, Percnt = PCP_VstCnt * 1.0 / Ttl_PCP_Vst, RN = row_number() over(partition by a.SavvyHICN	order by b.PCP_VstCnt desc)
				from	(
							select a.SavvyHICN, Ttl_PCP_Vst = sum(PCP_VstCnt)
							from #memberclass	a
							left join pdb_PCPSelection..Prov_Claims_10	b	on	a.SavvyHICN = b.SavvyHICN
							group by a.SavvyHICN
						) a
				left join pdb_PCPSelection..Prov_Claims_10	b	on	a.SavvyHICN = b.SavvyHICN
			)	b	on	a.SavvyHICN = b.SavvyHICN
where b.RN = 1
--(155766 row(s) affected)

/*
if object_id('pdb_PCPSelection..MbrProv_20160425') is not null
drop table pdb_PCPSelection..MbrProv_20160425
go
*/

if object_id('pdb_PCPSelection..MbrProv_10') is not null
drop table pdb_PCPSelection..MbrProv_10
go

select a.SavvyHICN, b.Providers, b.PCP_Flag, b.Specialty
	, b.IP_Spend
	, b.OP_Spend
	, b.DR_Spend
	, b.ER_Spend
	, b.PCP_Spend
	, b.IP_SrvcCnt
	, b.OP_SrvcCnt
	, b.DR_SrvcCnt
	, b.ER_SrvcCnt
	, b.PCP_VstCnt
	, b.StartDate 
	, b.EndDate	
	, a.Switcher
	, a.Splitter
	, a.Sticker
	, TotalSpend	= (b.IP_Spend + b.OP_Spend + b.DR_Spend + b.ER_Spend)
	, TotalSrvcCnt	= (b.IP_SrvcCnt + b.OP_SrvcCnt + b.DR_SrvcCnt + b.ER_SrvcCnt)
into pdb_PCPSelection..MbrProv_10
from pdb_PCPSelection..MbrClass_10			a
left join pdb_PCPSelection..Prov_Claims_10	b	on	a.SavvyHICN = b.SavvyHICN
--(1360598 row(s) affected)

select * from pdb_PCPSelection..MbrProv_10

select count(distinct SAvvyHICN)
from  pdb_PCPSelection..MbrProv_10

select count(distinct SAvvyHICN)	--155766
from pdb_PCPSelection..MbrClass_10	

--------
--HCC
--------
if object_id('tempdb..#esrd') is not null
drop table #esrd
go

select a.SavvyHICN, ESRDFlag
into #esrd
from pdb_PCPSelection..MbrClass_10	a
inner join CmsMMR..CmsMMR				b	on	a.SavvyHICN = b.SavvyHICN
where b.ESRDFlag = 'Y'
	and year(b.PaymentAdjustmentStartDate) = 2014
group by a.SavvyHICN, ESRDFlag
--(729 row(s) affected); 6.14 minutes
create unique clustered index ucIx_HICN on #esrd (SavvyHICN);


if object_id('tempdb..#member_hcc') is not null
drop table #member_hcc
go

select UniqueMemberID = a.SavvyHICN, GenderCd = c.Gender, c.Age, OREC = (case when d.SavvyHICN is not null then 2	else 0	end), MCAID = c.MedicaidFlag
into #member_hcc
from pdb_PCPSelection..MbrClass_10	a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Dim_Member			c	on	b.SavvyID = c.SavvyID
left join #esrd							d	on	a.SavvyHICN = d.SavvyHICN
--(150241 row(s) affected)
create unique clustered index ucIx_ID on #member_hcc (UniqueMemberID);

select count(distinct a.SavvyHICN)
from pdb_PCPSelection..MbrClass_10	a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Dim_Member			c	on	b.SavvyID = c.SavvyID

select *
from pdb_PCPSelection..MbrClass_10	a
left join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
where b.SavvyHICN is null

If (object_id('tempdb..#ip_conf') Is Not Null)
Drop Table #ip_conf
go

select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= d.DT_SYS_ID
	, Discharge_DtSys	= d1.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf
from #member_hcc		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID					--admit
inner join MiniOV..Dim_Date				d1	on	(c.Dt_Sys_Id + c.Day_Cnt) = d1.DT_SYS_ID	--discharge
where d.YEAR_NBR = 2014
	and c.Admit_Cnt = 1
--(37765 row(s) affected)
create clustered index cIx_SavvyIDs on #ip_conf (SavvyHICN, SavvyID);
create nonclustered index nIx_Dt on #ip_conf (Admit_DtSys, Discharge_DtSys);

If (object_id('tempdb..#diag') Is Not Null)
Drop Table #diag
go

select distinct UniqueMemberID = a.SavvyHICN, DiagCd = c.DIAG_CD	--, d.FULL_DT
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
				from #member_hcc	a
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
where d.YEAR_NBR = 2014
--(1578828 row(s) affected)
create clustered index cIx_ID_DiagCd on #diag (UniqueMemberID, DiagCd);


Exec  [RA_Medicare_2014_v2 ].dbo.spRAFDiagnosisDemographicInput
  @ModelID = 6
, @InputDiagnosisTableLocation 		='#diag'
, @InputDemographicsTableLocation 	='#member_hcc'
, @OutputDatabase 					= 'pdb_PCPSelection'
, @OutputSuffix 					= '2014'
go
--12.22 minutes

if OBJECT_ID ('tempdb..#HCC') is not null begin drop table #HCC	End;

Select	a.ModelID ,UniqueMemberID, a.Coefficient , a.USedInCalcFlag 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC
From	(Select	* 
		From	pdb_PCPSelection..RA_ModelTerms_2014
		)										as	a
left join	[RA_Medicare_2014_v2 ]..ModelTerm			as	b	on	a.Term = b.Term
where b.ModelID = 6
--(180762 row(s) affected)


------------------------------------------------------------------------------------------------------------------
--Dynamic Pivot:
if OBJECT_ID ('pdb_PCPSelection..HCC_2014') is not null begin drop table pdb_PCPSelection..HCC_2014	End;

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
into pdb_PCPSelection..HCC_2014
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol+'))				as pvt	'
	
		
	
	execute (@query1)
--(70830 row(s) affected)


alter table pdb_PCPSelection..MbrClass_10
	add [ARTIF_OPENINGS_PRESSURE_ULCER]	smallint
      ,[ASP_SPEC_BACT_PNEUM_PRES_ULCER]	smallint
      ,[CANCER_IMMUNE]					smallint
      ,[CHF_COPD]						smallint
      ,[CHF_RENAL]						smallint
      ,[COPD_ASP_SPEC_BACT_PNEUM]		smallint
      ,[COPD_CARD_RESP_FAIL]			smallint
      ,[DIABETES_CHF]					smallint
      ,[DISABLED_HCC161]				smallint
      ,[DISABLED_HCC176]				smallint
      ,[DISABLED_HCC34]					smallint
      ,[DISABLED_HCC39]					smallint
      ,[DISABLED_HCC54]					smallint
      ,[DISABLED_HCC55]					smallint
      ,[DISABLED_HCC6]					smallint
      ,[DISABLED_HCC85]					smallint
      ,[DISABLED_PRESSURE_ULCER]		smallint
      ,[HCC1]							smallint
      ,[HCC10]							smallint
      ,[HCC100]							smallint
      ,[HCC103]							smallint
      ,[HCC104]							smallint
      ,[HCC106]							smallint
      ,[HCC107]							smallint
      ,[HCC108]							smallint
      ,[HCC11]							smallint
      ,[HCC110]							smallint
      ,[HCC111]							smallint
      ,[HCC112]							smallint
      ,[HCC114]							smallint
      ,[HCC115]							smallint
      ,[HCC12]							smallint
      ,[HCC122]							smallint
      ,[HCC124]							smallint
      ,[HCC134]							smallint
      ,[HCC135]							smallint
      ,[HCC136]							smallint
      ,[HCC137]							smallint
      ,[HCC157]							smallint
      ,[HCC158]							smallint
      ,[HCC161]							smallint
      ,[HCC162]							smallint
      ,[HCC166]							smallint
      ,[HCC167]							smallint
      ,[HCC169]							smallint
      ,[HCC17]							smallint
      ,[HCC170]							smallint
      ,[HCC173]							smallint
      ,[HCC176]							smallint
      ,[HCC18]							smallint
      ,[HCC186]							smallint
      ,[HCC188]							smallint
      ,[HCC189]							smallint
      ,[HCC19]							smallint
      ,[HCC2]							smallint
      ,[HCC21]							smallint
      ,[HCC22]							smallint
      ,[HCC23]							smallint
      ,[HCC27]							smallint
      ,[HCC28]							smallint
      ,[HCC29]							smallint
      ,[HCC33]							smallint
      ,[HCC34]							smallint
      ,[HCC35]							smallint
      ,[HCC39]							smallint
      ,[HCC40]							smallint
      ,[HCC46]							smallint
      ,[HCC47]							smallint
      ,[HCC48]							smallint
      ,[HCC54]							smallint
      ,[HCC55]							smallint
      ,[HCC57]							smallint
      ,[HCC58]							smallint
      ,[HCC6]							smallint
      ,[HCC70]							smallint
      ,[HCC71]							smallint
      ,[HCC72]							smallint
      ,[HCC73]							smallint
      ,[HCC74]							smallint
      ,[HCC75]							smallint
      ,[HCC76]							smallint
      ,[HCC77]							smallint
      ,[HCC78]							smallint
      ,[HCC79]							smallint
      ,[HCC8]							smallint
      ,[HCC80]							smallint
      ,[HCC82]							smallint
      ,[HCC83]							smallint
      ,[HCC84]							smallint
      ,[HCC85]							smallint
      ,[HCC86]							smallint
      ,[HCC87]							smallint
      ,[HCC88]							smallint
      ,[HCC9]							smallint
      ,[HCC96]							smallint
      ,[HCC99]							smallint
      ,[SCHIZOPHRENIA_CHF]				smallint
      ,[SCHIZOPHRENIA_COPD]				smallint
      ,[SCHIZOPHRENIA_SEIZURES]			smallint
      ,[SEPSIS_ARTIF_OPENINGS]			smallint
      ,[SEPSIS_ASP_SPEC_BACT_PNEUM]		smallint
      ,[SEPSIS_CARD_RESP_FAIL]			smallint
      ,[SEPSIS_PRESSURE_ULCER]			smallint
go

update pdb_PCPSelection..MbrClass_10
set ARTIF_OPENINGS_PRESSURE_ULCER		= isnull(b.ARTIF_OPENINGS_PRESSURE_ULCER, 0)
      ,ASP_SPEC_BACT_PNEUM_PRES_ULCER	= isnull(b.ASP_SPEC_BACT_PNEUM_PRES_ULCER, 0)
      ,CANCER_IMMUNE					= isnull(b.CANCER_IMMUNE				, 0)
      ,CHF_COPD							= isnull(b.CHF_COPD						, 0)
      ,CHF_RENAL						= isnull(b.CHF_RENAL					, 0)
      ,COPD_ASP_SPEC_BACT_PNEUM			= isnull(b.COPD_ASP_SPEC_BACT_PNEUM		, 0)
      ,COPD_CARD_RESP_FAIL				= isnull(b.COPD_CARD_RESP_FAIL			, 0)
      ,DIABETES_CHF						= isnull(b.DIABETES_CHF					, 0)
      ,DISABLED_HCC161					= isnull(b.DISABLED_HCC161				, 0)
      ,DISABLED_HCC176					= isnull(b.DISABLED_HCC176				, 0)
      ,DISABLED_HCC34					= isnull(b.DISABLED_HCC34				, 0)
      ,DISABLED_HCC39					= isnull(b.DISABLED_HCC39				, 0)
      ,DISABLED_HCC54					= isnull(b.DISABLED_HCC54				, 0)
      ,DISABLED_HCC55					= isnull(b.DISABLED_HCC55				, 0)
      ,DISABLED_HCC6					= isnull(b.DISABLED_HCC6				, 0)
      ,DISABLED_HCC85					= isnull(b.DISABLED_HCC85				, 0)
      ,DISABLED_PRESSURE_ULCER			= isnull(b.DISABLED_PRESSURE_ULCER		, 0)
      ,HCC1								= isnull(b.HCC1							, 0)
      ,HCC10							= isnull(b.HCC10						, 0)
      ,HCC100							= isnull(b.HCC100						, 0)
      ,HCC103							= isnull(b.HCC103						, 0)
      ,HCC104							= isnull(b.HCC104						, 0)
      ,HCC106							= isnull(b.HCC106						, 0)
      ,HCC107							= isnull(b.HCC107						, 0)
      ,HCC108							= isnull(b.HCC108						, 0)
      ,HCC11							= isnull(b.HCC11						, 0)
      ,HCC110							= isnull(b.HCC110						, 0)
      ,HCC111							= isnull(b.HCC111						, 0)
      ,HCC112							= isnull(b.HCC112						, 0)
      ,HCC114							= isnull(b.HCC114						, 0)
      ,HCC115							= isnull(b.HCC115						, 0)
      ,HCC12							= isnull(b.HCC12						, 0)
      ,HCC122							= isnull(b.HCC122						, 0)
      ,HCC124							= isnull(b.HCC124						, 0)
      ,HCC134							= isnull(b.HCC134						, 0)
      ,HCC135							= isnull(b.HCC135						, 0)
      ,HCC136							= isnull(b.HCC136						, 0)
      ,HCC137							= isnull(b.HCC137						, 0)
      ,HCC157							= isnull(b.HCC157						, 0)
      ,HCC158							= isnull(b.HCC158						, 0)
      ,HCC161							= isnull(b.HCC161						, 0)
      ,HCC162							= isnull(b.HCC162						, 0)
      ,HCC166							= isnull(b.HCC166						, 0)
      ,HCC167							= isnull(b.HCC167						, 0)
      ,HCC169							= isnull(b.HCC169						, 0)
      ,HCC17							= isnull(b.HCC17						, 0)
      ,HCC170							= isnull(b.HCC170						, 0)
      ,HCC173							= isnull(b.HCC173						, 0)
      ,HCC176							= isnull(b.HCC176						, 0)
      ,HCC18							= isnull(b.HCC18						, 0)
      ,HCC186							= isnull(b.HCC186						, 0)
      ,HCC188							= isnull(b.HCC188						, 0)
      ,HCC189							= isnull(b.HCC189						, 0)
      ,HCC19							= isnull(b.HCC19						, 0)
      ,HCC2								= isnull(b.HCC2							, 0)
      ,HCC21							= isnull(b.HCC21						, 0)
      ,HCC22							= isnull(b.HCC22						, 0)
      ,HCC23							= isnull(b.HCC23						, 0)
      ,HCC27							= isnull(b.HCC27						, 0)
      ,HCC28							= isnull(b.HCC28						, 0)
      ,HCC29							= isnull(b.HCC29						, 0)
      ,HCC33							= isnull(b.HCC33						, 0)
      ,HCC34							= isnull(b.HCC34						, 0)
      ,HCC35							= isnull(b.HCC35						, 0)
      ,HCC39							= isnull(b.HCC39						, 0)
      ,HCC40							= isnull(b.HCC40						, 0)
      ,HCC46							= isnull(b.HCC46						, 0)
      ,HCC47							= isnull(b.HCC47						, 0)
      ,HCC48							= isnull(b.HCC48						, 0)
      ,HCC54							= isnull(b.HCC54						, 0)
      ,HCC55							= isnull(b.HCC55						, 0)
      ,HCC57							= isnull(b.HCC57						, 0)
      ,HCC58							= isnull(b.HCC58						, 0)
      ,HCC6								= isnull(b.HCC6							, 0)
      ,HCC70							= isnull(b.HCC70						, 0)
      ,HCC71							= isnull(b.HCC71						, 0)
      ,HCC72							= isnull(b.HCC72						, 0)
      ,HCC73							= isnull(b.HCC73						, 0)
      ,HCC74							= isnull(b.HCC74						, 0)
      ,HCC75							= isnull(b.HCC75						, 0)
      ,HCC76							= isnull(b.HCC76						, 0)
      ,HCC77							= isnull(b.HCC77						, 0)
      ,HCC78							= isnull(b.HCC78						, 0)
      ,HCC79							= isnull(b.HCC79						, 0)
      ,HCC8								= isnull(b.HCC8							, 0)
      ,HCC80							= isnull(b.HCC80						, 0)
      ,HCC82							= isnull(b.HCC82						, 0)
      ,HCC83							= isnull(b.HCC83						, 0)
      ,HCC84							= isnull(b.HCC84						, 0)
      ,HCC85							= isnull(b.HCC85						, 0)
      ,HCC86							= isnull(b.HCC86						, 0)
      ,HCC87							= isnull(b.HCC87						, 0)
      ,HCC88							= isnull(b.HCC88						, 0)
      ,HCC9								= isnull(b.HCC9							, 0)
      ,HCC96							= isnull(b.HCC96						, 0)
      ,HCC99							= isnull(b.HCC99						, 0)
      ,SCHIZOPHRENIA_CHF				= isnull(b.SCHIZOPHRENIA_CHF			, 0)
      ,SCHIZOPHRENIA_COPD				= isnull(b.SCHIZOPHRENIA_COPD			, 0)
      ,SCHIZOPHRENIA_SEIZURES			= isnull(b.SCHIZOPHRENIA_SEIZURES		, 0)
      ,SEPSIS_ARTIF_OPENINGS			= isnull(b.SEPSIS_ARTIF_OPENINGS		, 0)
      ,SEPSIS_ASP_SPEC_BACT_PNEUM		= isnull(b.SEPSIS_ASP_SPEC_BACT_PNEUM	, 0)
      ,SEPSIS_CARD_RESP_FAIL			= isnull(b.SEPSIS_CARD_RESP_FAIL		, 0)
      ,SEPSIS_PRESSURE_ULCER			= isnull(b.SEPSIS_PRESSURE_ULCER		, 0)
from pdb_PCPSelection..MbrClass_10	a
left join pdb_PCPSelection..HCC_2014	b	on	a.SavvyHICN = b.UniqueMemberID


select *
from pdb_PCPSelection..MbrClass_10