/*** 
PCP Selection (Commercial)
	Pull for the claims of the same members but for 2015

Input databases:	MiniHPDM, pdb_PCPSelection

Date Created: 24 June 2016
***/

if object_id('tempdb..#pcpflag') is not null
drop table #pcpflag
go

select MPIN, PCP_Flag = Case when SpecTypeCd in ('001','008','011','019','037','038','041','077','230','236','251','258'
                                                                            ,'272','273','274','275','276','281','282','338','339','375','384','506')  Then 1 Else 0 End           --codes used where taken from PAM project
into #pcpflag
from NDB..Prov_Specialties
where PrimaryInd = 'P'
--(2662283 row(s) affected) with the primary indicator
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
--(2061139 row(s) affected)
create unique clustered index ucIx_MPIN on #specialty (MPIN);

if object_id('tempdb..#ip_conf') is not null
drop table #ip_conf
go

select a.Indv_Sys_Id, Admt_DtSys = b.Dt_Sys_Id, Discharge_DtSys = (b.DT_SYS_ID + b.Day_Cnt)
into #ip_conf
from pdb_PCPSelection..Com_MbrClass_10	a
inner join MiniHPDM..Fact_Claims		b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
inner join MiniHPDM..Dim_Date			c	on	b.Dt_Sys_Id = c.DT_SYS_ID
where c.YEAR_NBR = 2015
	and b.Srvc_Typ_Sys_Id = 1
	and b.Admit_Cnt = 1
group by a.Indv_Sys_Id, b.Dt_Sys_Id, b.Day_Cnt
--(18278 row(s) affected)
create clustered index cIx_Indv on #ip_conf (Indv_Sys_Id);
create nonclustered index ncIx_Dt on #ip_conf (Admt_DtSys, Discharge_DtSys);


--MPIN premium designation
if object_id('tempdb..#premium_designation') is not null
drop table #premium_designation
go

select a.*, 
       b.EFNCY_OTCOME_DESC,
       c.QLTY_OTCOME_DESC,
       case when b.EFNCY_OTCOME_DESC like 'COST%EFFICIENCY%' then 1 else 0 end as EFNCY_FLAG,
       case when c.QLTY_OTCOME_DESC = 'QUALITY' then 1 else 0 end as QLTY_FLAG
into #premium_designation
from(
       select a.*, row_number() over(partition by MPIN order by EFF_DT desc) as RN
       from(
              --Combine facility and physician lists
              select MPIN, QLTY_OTCOME_CD, EFNCY_OTCOME_CD, FACL_QE_DESG_ROW_EFF_DT as EFF_DT
              from Galaxy_Research..NDB_Facility_Quality_Efficiency_Designation
              union
              select MPIN, QLTY_OTCOME_CD, EFNCY_OTCOME_CD, PHYSN_QE_DESG_ROW_EFF_DT as EFF_DT
              from Galaxy_Research..NDB_Physician_Quality_Efficiency_Designation
              ) as a 
       ) as a
left join Galaxy_Research..NDB_Efficiency_Outcome_Code as b on a.EFNCY_OTCOME_CD = b.EFNCY_OTCOME_CD
left join Galaxy_Research..NDB_Quality_Outcome_Code           as c on a.QLTY_OTCOME_CD = c.QLTY_OTCOME_CD
where a.RN = 1 --Get most recent record per MPIN
--(850409 row(s) affected)
create unique clustered index ucIx_MPIN on #premium_designation (MPIN);

if object_id('pdb_PCPSelection..Com_Prov_Claims_10_2015') is not null
drop table pdb_PCPSelection..Com_Prov_Claims_10_2015
go

select a.Indv_Sys_Id, Provider_MPIN = a.MPIN, Provider_TIN = a.TIN, EFNCY_FLAG = max(a.EFNCY_FLAG), QLTY_FLAG = max(a.QLTY_FLAG)
	, PCP_Flag	= isnull(a.PCP_Flag,0)
	, Specialty = a.LongDesc
	--spend
	, IP_Spend	= sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	else 0	end)
	, OP_Spend	= sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	else 0	end)
	, DR_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	else 0	end)
	, ER_Spend	= sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	else 0	end)
	, PCP_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Allw_Amt	else 0	end)
	, RX_Spend	= sum(case when Derived_Srvc_Type_cd = 'RX'	then Allw_Amt	else 0	end)
	
	--visit counts
	, IP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'IP'	and Admit_Cnt = 1	then Dt_Sys_Id	end)
	, OP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'OP'	then Dt_Sys_Id	end)
	, DR_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR'	then Dt_Sys_Id	end)
	, ER_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'ER'	then Dt_Sys_Id	end)
	, PCP_VstCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Dt_Sys_Id	end)
	
	, RX_Scripts	= sum(case when Derived_Srvc_Type_cd = 'RX'	then Scrpt_Cnt	else 0	end)
	, StartDate = min(Full_Dt)
	, EndDate	= max(Full_Dt)
into pdb_PCPSelection..Com_Prov_Claims_10_2015
from	(		
			select c.*
				, Derived_Srvc_Type_cd = case when j.Indv_Sys_ID is not null and g.Srvc_Typ_Cd <> 'IP'  then 'IP'  
												when f.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then 'ER' else g.Srvc_Typ_Cd end
				, d.FULL_DT, e.MPIN, e.TIN
				, PCP_Flag = isnull(case when j.Indv_Sys_Id is not null and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys	then 0	else h.PCP_Flag	end, 0)
				, i.LongDesc, k.EFNCY_FLAG, k.QLTY_FLAG
			--into #temp
			from pdb_PCPSelection..Com_MbrClass_10	a
			inner join MiniHPDM..Fact_Claims				c	on	a.Indv_Sys_Id = c.Indv_Sys_Id
			inner join MiniHPDM..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			inner join MiniHPDM..Dim_Provider				e	on	c.Prov_Sys_Id = e.Prov_Sys_Id
			inner join MiniHPDM..Dim_HP_Service_Type_Code	f	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = f.HLTH_PLN_SRVC_TYP_CD_SYS_ID
			inner join MiniHPDM..Dim_Service_Type			g	on	c.Srvc_Typ_Sys_Id = g.Srvc_Typ_Sys_Id
			left join #pcpflag								h	on	e.MPIN = h.MPIN
			left join #specialty							i	on	e.MPIN = i.MPIN
			left join #ip_conf								j	on	a.Indv_Sys_Id = j.Indv_Sys_Id
																and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys
			left join #premium_designation					k	on	e.MPIN = k.MPIN
			where d.YEAR_NBR = 2015
				and e.MPIN <> 0
				--and a.Indv_Sys_Id in (32133786, 854332796, 908304601)
		) a
group by a.Indv_Sys_Id, a.MPIN, a.TIN, a.PCP_Flag, a.LongDesc
--(1733659 row(s) affected); 10.22 minutes
create clustered index cIx_Indv_MPIN on pdb_PCPSelection..Com_Prov_Claims_10_2015 (Indv_Sys_Id, Provider_MPIN);

--identify member classification
if object_id('tempdb..#class') is not null
drop table #class
go

select Indv_Sys_Id
	, Splitter = max(Splitter)
	, Switcher = case when max(Splitter) = 0 and max(x.OID) <> 1	then 1	else 0	end
	, Sticker = case when max(x.OID) = 1	then 1	else 0 end
into #class
from	(	
			select a.*, Prov2 = b.Provider_MPIN, StrtDt2 = b.StartDate, EndDt2 = b.EndDate, OID2 = b.OID
				, Splitter = (case when a.StartDate between b.StartDAte and b.EndDate	then 1	else 0 end)
			from	(	
						select Indv_Sys_Id, Provider_MPIN, StartDate, EndDate, OID = row_number() over (partition by Indv_Sys_Id order by StartDate)
						from pdb_PCPSelection..Com_Prov_Claims_10_2015
						where PCP_Flag = 1
					)	a
			left join (	
						select Indv_Sys_Id, Provider_MPIN, StartDate, EndDate, OID = row_number() over (partition by Indv_Sys_Id order by StartDate)
						from pdb_PCPSelection..Com_Prov_Claims_10_2015
						where PCP_Flag = 1
					) b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
						and a.OID = (b.OID + 1)
		) x
group by Indv_Sys_Id
--(261452 row(s) affected)
create unique clustered index ucIx_HICN on #class (Indv_Sys_Id);


-----------
--RAF & HCC
-----------
If (object_id('tempdb..#member_hcc') Is Not Null)
Drop Table #member_hcc
go

select UniqueMemberID = Indv_Sys_Id, GenderCd = Gdr_Cd, BirthDate = dateadd(yy, -(Age), '12-31-2015') , AgeLast = Age
into #member_hcc
from pdb_PCPSelection..Com_MbrClass_10
--(627701 row(s) affected)
create unique clustered index ucIx_ID on #member_hcc (UniqueMemberID);


If (object_id('tempdb..#ip_claims_2015') Is Not Null)
Drop Table #ip_claims_2015
go

select distinct a.UniqueMemberID
	,c.Indv_Sys_Id
	,Diag1	= e1.Diag_Cd
	,Diag2	= e2.Diag_Cd
	,Diag3	= e3.Diag_Cd
	,DiagnosisServiceDate	= d.FULL_DT
into #ip_claims_2015
from #member_hcc							as a
inner join MiniHPDM..Fact_Claims		as b on a.UniqueMemberID = b.Indv_Sys_Id
inner join #ip_conf						as c on b.Indv_Sys_Id = c.Indv_Sys_Id
											and b.Dt_Sys_Id between c.Admt_DtSys and c.Discharge_dtsys
left join MiniHPDM..Dim_Date			as d	on	b.Dt_Sys_Id		= d.DT_SYS_ID
inner join MiniHPDM..Dim_Bill_Type_Code	as e on b.Bil_Typ_Cd_Sys_Id = e.Bil_Typ_Cd_Sys_Id
left join MiniHPDM..Dim_Diagnosis_Code	as  e1	on	b.Diag_1_Cd_Sys_Id = e1.DIAG_CD_SYS_ID
left join MiniHPDM..Dim_Diagnosis_Code	as  e2	on	b.Diag_2_Cd_Sys_Id = e2.DIAG_CD_SYS_ID
left join MiniHPDM..Dim_Diagnosis_Code	as  e3	on	b.Diag_3_Cd_Sys_Id = e3.DIAG_CD_SYS_ID
where b.Srvc_Typ_Sys_Id = 1
and e.Bil_Typ_Cd in ('111', '112', '113', '114', '116', '117')
--(17180 row(s) affected)
create clustered index cIx_Indv on #ip_claims_2015 (Indv_Sys_Id);

If (object_id('tempdb..#OP_DR_Claims_2015') Is Not Null)
Drop Table #OP_DR_Claims_2015
go

select distinct  a.UniqueMemberID
	,b.Indv_Sys_Id 
	,Diag1 = e1.Diag_Cd
	,Diag2 = e2.Diag_Cd
	,Diag3 = e3.Diag_Cd
	,DiagnosisServiceDate	= c.FULL_DT
into	#OP_DR_Claims_2015
From	#member_hcc									as	a
join	MiniHPDM..Fact_Claims							as	b	on	a.UniqueMemberID	= b.Indv_Sys_Id
join	MiniHPDM..Dim_Date								as	c	on	b.Dt_Sys_Id			= c.DT_SYS_ID	
join	MiniHPDM..Dim_Service_Type						as	d	on	b.Srvc_Typ_Sys_Id	= d.Srvc_Typ_Sys_Id
join	MiniHPDM..Dim_Procedure_Code					as  e	on	b.Proc_Cd_Sys_Id	= e.PROC_CD_SYS_ID
join	pdb_Rally..RA_Commercial_2014_HHS_Table1_CPT	as	f	on	e.PROC_CD			= f.Proc_CD
join	MiniHPDM..Dim_Bill_Type_Code					as	g	on	b.Bil_Typ_Cd_Sys_Id = g.Bil_Typ_Cd_Sys_Id 
left join MiniHPDM..Dim_Diagnosis_Code					as  e1	on	b.Diag_1_Cd_Sys_Id = e1.DIAG_CD_SYS_ID
left join MiniHPDM..Dim_Diagnosis_Code					as  e2	on	b.Diag_2_Cd_Sys_Id = e2.DIAG_CD_SYS_ID
left join MiniHPDM..Dim_Diagnosis_Code					as  e3	on	b.Diag_3_Cd_Sys_Id = e3.DIAG_CD_SYS_ID
Where	(	--1500 Claims
			(	d.Srvc_Typ_Sys_Id  in (2, 3)
			and b.Rvnu_Cd_Sys_Id <= 2)
		or  --1450 claims
			(  d.Srvc_Typ_Sys_Id = 2
			and g.Bil_Typ_Cd in ('131', '132', '133', '134', '136', '137', 
								 '710', '711', '712', '713', '714', '715', '716', '717', '718', '719',
								 '760', '761', '762', '763', '764', '765', '766', '767', '768', '769',
								 '770', '771', '772', '773', '774', '775', '776', '777', '778', '779'))
		)
	and c.Year_Nbr = 2015
--(2248056 row(s) affected)
create clustered index cIx_Indv on #OP_DR_Claims_2015 (Indv_Sys_Id);

If (object_id('tempdb..#IP_OP_DR_Claims_2015') Is Not Null)
Drop Table #IP_OP_DR_Claims_2015
go

Select * 
into #IP_OP_DR_Claims_2015	
from #ip_claims_2015	
union 
Select * 
from #OP_DR_Claims_2015
--(2264415 row(s) affected)

If (object_id('tempdb..#diag_2015') Is Not Null)
Drop Table #diag_2015
go

Select UniqueMemberID	
	,ICDCd
	,DiagnosisServiceDate
Into	#diag_2015
From	( Select a.UniqueMemberID, DiagnosisServiceDate, Diag1, Diag2, Diag3
		from #IP_OP_DR_Claims_2015 as	a
		)	as	p
unpivot
(
	ICDCd
	for Diag in (Diag1, Diag2, Diag3)	
 )	as unpvt
Where ICDCd not like '' 
--(4338379 row(s) affected)
create clustered index cIx_ID on #diag_2015 (UniqueMemberID);

exec RA_Commercial_2014.dbo.spRAFDiagInput
	 @InputPersonTable = '#member_hcc'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = '#diag_2015'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_PCPSelection'
	,@OutputSuffix = '2015'
go

if object_id('tempdb..#memberclass') is not null
drop table #memberclass
go

select a.Indv_Sys_ID
	, Switcher	= isnull(b.Switcher, 0)
	, Splitter	= isnull(b.Splitter, 0)
	, Sticker	= isnull(b.Sticker, 0)
	, c.Total_IP_Spend	
	, c.Total_OP_Spend	
	, c.Total_DR_Spend	
	, c.Total_ER_Spend
	, c.Total_PCP_Spend
	, c.Total_RX_Spend
	, c.Total_IP_SrvcCnt
	, c.Total_OP_SrvcCnt
	, c.Total_DR_SrvcCnt
	, c.Total_ER_SrvcCnt
	, c.Total_PCP_SrvcCnt
	, c.Total_RX_Scripts
	, RAF		= isnull(d.SilverTotalScore, 0)
into #memberclass
from pdb_PCPSelection..Com_MbrClass_10	a
left join #class						b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
left join	(
				select Indv_Sys_ID
					, Total_IP_Spend	= sum(IP_Spend)
					, Total_OP_Spend	= sum(OP_Spend)
					, Total_DR_Spend	= sum(DR_Spend)
					, Total_ER_Spend	= sum(ER_Spend)
					, Total_PCP_Spend	= sum(PCP_Spend)
					, Total_RX_Spend	= sum(RX_Spend)
					, Total_IP_SrvcCnt	= sum(IP_SrvcCnt)
					, Total_OP_SrvcCnt	= sum(OP_SrvcCnt)
					, Total_DR_SrvcCnt	= sum(DR_SrvcCnt)
					, Total_ER_SrvcCnt	= sum(ER_SrvcCnt)
					, Total_PCP_SrvcCnt	= sum(PCP_VstCnt)
					, Total_RX_Scripts	= sum(RX_Scripts)
				from pdb_PCPSelection..Com_Prov_Claims_10_2015
				group by Indv_Sys_ID
			)	c	on	a.Indv_Sys_ID = c.Indv_Sys_ID
left join pdb_PCPSelection..RA_Com_Q_MetalScoresPivoted_2015	d	on	a.Indv_Sys_ID = d.UniqueMemberID
group by  a.Indv_Sys_ID
	, b.Switcher
	, b.Splitter
	, b.Sticker
	, c.Total_IP_Spend	
	, c.Total_OP_Spend	
	, c.Total_DR_Spend	
	, c.Total_ER_Spend
	, c.Total_PCP_Spend
	, c.Total_RX_Spend
	, c.Total_IP_SrvcCnt
	, c.Total_OP_SrvcCnt
	, c.Total_DR_SrvcCnt
	, c.Total_ER_SrvcCnt
	, c.Total_PCP_SrvcCnt
	, c.Total_RX_Scripts
	, d.SilverTotalScore
--(627701 row(s) affected); 
create unique clustered index ucIx_HICN on #memberclass (Indv_Sys_ID);

--HCC pivot
if OBJECT_ID ('tempdb..#HCC') is not null begin drop table #HCC	End;

Select	UniqueMemberID, a.Coefficient , a.UsedInCalc 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC
From	(Select	* 
		From	pdb_PCPSelection..RA_Com_R_ModelTerms_2015
		where ModelVersion = 'Silver'
		)										as	a
left join	RA_Commercial_2014..ModelHCC			as	b	on	a.Term = b.Term
where b.modelcategoryid = 9
--(98399 row(s) affected)

------------------------------------------------------------------------------------------------------------------
--Dynamic Pivot:
if OBJECT_ID ('pdb_PCPSelection..Com_HCC_2015') is not null begin drop table pdb_PCPSelection..Com_HCC_2015	End;

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
into pdb_PCPSelection..Com_HCC_2015
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol+'))				as pvt	'
	
	execute (@query1)
--(64238 row(s) affected)

--add weight
if object_id('pdb_PCPSelection..Com_MbrClass_10_2015') is not null
drop table pdb_PCPSelection..Com_MbrClass_10_2015
go

select a.Indv_Sys_ID
	, c.Age
	, c.Gdr_Cd
	, a.Switcher	
	, a.Splitter	
	, a.Sticker
	, Weight = (1 - b.Percnt)	
	, a.Total_IP_Spend	
	, a.Total_OP_Spend	
	, a.Total_DR_Spend	
	, a.Total_ER_Spend
	, a.Total_PCP_Spend
	, a.Total_RX_Spend
	, Total_Spend		= (a.Total_IP_Spend + a.Total_OP_Spend + a.Total_DR_Spend + a.Total_ER_Spend + a.Total_RX_Spend)
	, a.Total_IP_SrvcCnt
	, a.Total_OP_SrvcCnt
	, a.Total_DR_SrvcCnt
	, a.Total_ER_SrvcCnt
	, a.Total_PCP_SrvcCnt
	, a.Total_RX_Scripts
	, a.RAF	
	, HCC001	= isnull(d.HCC001, 0)
    , HCC002	= isnull(d.HCC002, 0)
    , HCC003	= isnull(d.HCC003, 0)
    , HCC004	= isnull(d.HCC004, 0)
    , HCC006	= isnull(d.HCC006, 0)
    , HCC008	= isnull(d.HCC008, 0)
    , HCC009	= isnull(d.HCC009, 0)
    , HCC010	= isnull(d.HCC010, 0)
    , HCC011	= isnull(d.HCC011, 0)
    , HCC012	= isnull(d.HCC012, 0)
    , HCC013	= isnull(d.HCC013, 0)
    , HCC018	= isnull(d.HCC018, 0)
    , HCC019	= isnull(d.HCC019, 0)
    , HCC020	= isnull(d.HCC020, 0)
    , HCC021	= isnull(d.HCC021, 0)
    , HCC023	= isnull(d.HCC023, 0)
    , HCC026	= isnull(d.HCC026, 0)
    , HCC027	= isnull(d.HCC027, 0)
    , HCC028	= isnull(d.HCC028, 0)
    , HCC029	= isnull(d.HCC029, 0)
    , HCC030	= isnull(d.HCC030, 0)
    , HCC034	= isnull(d.HCC034, 0)
    , HCC035	= isnull(d.HCC035, 0)
    , HCC036	= isnull(d.HCC036, 0)
    , HCC037	= isnull(d.HCC037, 0)
    , HCC038	= isnull(d.HCC038, 0)
    , HCC042	= isnull(d.HCC042, 0)
    , HCC045	= isnull(d.HCC045, 0)
    , HCC046	= isnull(d.HCC046, 0)
    , HCC047	= isnull(d.HCC047, 0)
    , HCC048	= isnull(d.HCC048, 0)
    , HCC054	= isnull(d.HCC054, 0)
    , HCC055	= isnull(d.HCC055, 0)
    , HCC056	= isnull(d.HCC056, 0)
    , HCC057	= isnull(d.HCC057, 0)
    , HCC061	= isnull(d.HCC061, 0)
    , HCC062	= isnull(d.HCC062, 0)
    , HCC063	= isnull(d.HCC063, 0)
    , HCC064	= isnull(d.HCC064, 0)
    , HCC066	= isnull(d.HCC066, 0)
    , HCC067	= isnull(d.HCC067, 0)
    , HCC068	= isnull(d.HCC068, 0)
    , HCC069	= isnull(d.HCC069, 0)
    , HCC070	= isnull(d.HCC070, 0)
    , HCC071	= isnull(d.HCC071, 0)
    , HCC073	= isnull(d.HCC073, 0)
    , HCC074	= isnull(d.HCC074, 0)
    , HCC075	= isnull(d.HCC075, 0)
    , HCC081	= isnull(d.HCC081, 0)
    , HCC082	= isnull(d.HCC082, 0)
    , HCC087	= isnull(d.HCC087, 0)
    , HCC088	= isnull(d.HCC088, 0)
    , HCC089	= isnull(d.HCC089, 0)
    , HCC090	= isnull(d.HCC090, 0)
    , HCC094	= isnull(d.HCC094, 0)
    , HCC096	= isnull(d.HCC096, 0)
    , HCC097	= isnull(d.HCC097, 0)
    , HCC102	= isnull(d.HCC102, 0)
    , HCC103	= isnull(d.HCC103, 0)
    , HCC107	= isnull(d.HCC107, 0)
    , HCC109	= isnull(d.HCC109, 0)
    , HCC110	= isnull(d.HCC110, 0)
    , HCC111	= isnull(d.HCC111, 0)
    , HCC112	= isnull(d.HCC112, 0)
    , HCC113	= isnull(d.HCC113, 0)
    , HCC114	= isnull(d.HCC114, 0)
    , HCC115	= isnull(d.HCC115, 0)
    , HCC117	= isnull(d.HCC117, 0)
    , HCC118	= isnull(d.HCC118, 0)
    , HCC119	= isnull(d.HCC119, 0)
    , HCC120	= isnull(d.HCC120, 0)
    , HCC121	= isnull(d.HCC121, 0)
    , HCC122	= isnull(d.HCC122, 0)
    , HCC125	= isnull(d.HCC125, 0)
    , HCC126	= isnull(d.HCC126, 0)
    , HCC127	= isnull(d.HCC127, 0)
    , HCC128	= isnull(d.HCC128, 0)
    , HCC129	= isnull(d.HCC129, 0)
    , HCC130	= isnull(d.HCC130, 0)
    , HCC131	= isnull(d.HCC131, 0)
    , HCC132	= isnull(d.HCC132, 0)
    , HCC135	= isnull(d.HCC135, 0)
    , HCC137	= isnull(d.HCC137, 0)
    , HCC138	= isnull(d.HCC138, 0)
    , HCC139	= isnull(d.HCC139, 0)
    , HCC142	= isnull(d.HCC142, 0)
    , HCC145	= isnull(d.HCC145, 0)
    , HCC146	= isnull(d.HCC146, 0)
    , HCC149	= isnull(d.HCC149, 0)
    , HCC150	= isnull(d.HCC150, 0)
    , HCC151	= isnull(d.HCC151, 0)
    , HCC153	= isnull(d.HCC153, 0)
    , HCC154	= isnull(d.HCC154, 0)
    , HCC156	= isnull(d.HCC156, 0)
    , HCC158	= isnull(d.HCC158, 0)
    , HCC159	= isnull(d.HCC159, 0)
    , HCC160	= isnull(d.HCC160, 0)
    , HCC161	= isnull(d.HCC161, 0)
    , HCC162	= isnull(d.HCC162, 0)
    , HCC163	= isnull(d.HCC163, 0)
    , HCC183	= isnull(d.HCC183, 0)
    , HCC184	= isnull(d.HCC184, 0)
    , HCC187	= isnull(d.HCC187, 0)
    , HCC188	= isnull(d.HCC188, 0)
    , HCC203	= isnull(d.HCC203, 0)
    , HCC204	= isnull(d.HCC204, 0)
    , HCC205	= isnull(d.HCC205, 0)
    , HCC207	= isnull(d.HCC207, 0)
    , HCC208	= isnull(d.HCC208, 0)
    , HCC209	= isnull(d.HCC209, 0)
    , HCC217	= isnull(d.HCC217, 0)
    , HCC226	= isnull(d.HCC226, 0)
    , HCC227	= isnull(d.HCC227, 0)
    , HCC243	= isnull(d.HCC243, 0)
    , HCC244	= isnull(d.HCC244, 0)
    , HCC245	= isnull(d.HCC245, 0)
	, HCC246	= isnull(d.HCC246, 0)
	, HCC247	= isnull(d.HCC247, 0)
	, HCC248	= isnull(d.HCC248, 0)
	, HCC249	= isnull(d.HCC249, 0)
	, HCC251	= isnull(d.HCC251, 0)
	, HCC253	= isnull(d.HCC253, 0)
	, HCC254	= isnull(d.HCC254, 0)
into pdb_PCPSelection..Com_MbrClass_10_2015
from #memberclass	a
inner join	(
				select a.Indv_Sys_ID, b.PCP_VstCnt, Percnt = PCP_VstCnt * 1.0 / nullif(Ttl_PCP_Vst, 0) , RN = row_number() over(partition by a.Indv_Sys_ID	order by b.PCP_VstCnt desc)
				from	(
							select a.Indv_Sys_ID, Ttl_PCP_Vst = sum(PCP_VstCnt)
							from #memberclass	a
							left join pdb_PCPSelection..Com_Prov_Claims_10_2015	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
							group by a.Indv_Sys_ID
						) a
				left join pdb_PCPSelection..Com_Prov_Claims_10_2015	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
			)	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
left join pdb_PCPSelection..Com_MbrClass_10	c	on	a.Indv_Sys_ID = c.Indv_Sys_ID
left join pdb_PCPSelection..Com_HCC_2015	d	on	a.Indv_Sys_ID = d.UniqueMemberID
where b.RN = 1
--(627701 row(s) affected)
create unique clustered index ucIx_HICN on pdb_PCPSelection..Com_MbrClass_10_2015	(Indv_Sys_ID);

if object_id('pdb_PCPSelection..Com_MbrProv_10_2015') is not null
drop table pdb_PCPSelection..Com_MbrProv_10_2015
go

select a.Indv_Sys_ID, b.Provider_MPIN, b.Provider_TIN, b.PCP_Flag, b.Specialty, b.EFNCY_FLAG, b.QLTY_FLAG
	, b.IP_Spend
	, b.OP_Spend
	, b.DR_Spend
	, b.ER_Spend
	, b.PCP_Spend
	, b.RX_Spend
	, b.IP_SrvcCnt
	, b.OP_SrvcCnt
	, b.DR_SrvcCnt
	, b.ER_SrvcCnt
	, b.PCP_VstCnt
	, b.RX_Scripts
	, b.StartDate 
	, b.EndDate	
	, a.Switcher
	, a.Splitter
	, a.Sticker
	, TotalSpend	= (b.IP_Spend + b.OP_Spend + b.DR_Spend + b.ER_Spend + b.RX_Spend)
	, TotalSrvcCnt	= (b.IP_SrvcCnt + b.OP_SrvcCnt + b.DR_SrvcCnt + b.ER_SrvcCnt + b.RX_Scripts)
into pdb_PCPSelection..Com_MbrProv_10_2015
from pdb_PCPSelection..Com_MbrClass_10_2015			a
left join pdb_PCPSelection..Com_Prov_Claims_10_2015	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
--(2060560 row(s) affected)

--date switch
If (object_id('tempdb..#dateswitch') Is Not Null)
Drop Table #dateswitch
go

select Indv_Sys_ID
	, DateSwitch	= (case when OID = 2	then StartDate	end)
	, SwitchCnt		= (MaxOID - 1)
	, CloseIPConf	= (datediff(dd, StartDate, AdmitDt))
into #dateswitch
from	(	
			select a.Indv_Sys_ID, StartDate = cast(a.StartDate as date), a.OID, AdmitDt = max(case when RN = 1	then b.AdmitDt	end) over(partition by a.Indv_Sys_ID)
				, MaxOID = max(a.OID) over(partition by a.Indv_Sys_ID)
			from	(	
						select Indv_Sys_ID, Provider_MPIN, Specialty, StartDate, EndDate
							, OID = row_number() over(partition by Indv_Sys_ID	order by StartDate)
						from pdb_PCPSelection..Com_MbrProv_10_2015
						where Switcher = 1 
							and PCP_Flag = 1
					) a
			left join	(
							select a.*, AdmitDt = cast(b.FULL_DT as date), RN = row_number() over(partition by a.Indv_Sys_ID	order by a.Admt_DtSys)
							from #ip_conf	a
							inner join MiniHPDM..Dim_Date	b	on	a.Admt_DtSys = b.DT_SYS_ID
						)	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID	and a.OID = b.RN
		) x
where (case when OID = 2	then StartDate	end) is not null
--(49888 row(s) affected)
create unique clustered index ucIx_HICN on #dateswitch (Indv_Sys_ID);


alter table pdb_PCPSelection..Com_MbrClass_10_2015
	add DateSwitch	date
		, SwitchCnt	smallint
		, DaysToFrom_IPConf	int
go

update pdb_PCPSelection..Com_MbrClass_10_2015
set	DateSwitch = b.DateSwitch
	, SwitchCnt = isnull(b.SwitchCnt, 0)
	, DaysToFrom_IPConf = isnull(b.CloseIPConf, 0)
from pdb_PCPSelection..Com_MbrClass_10_2015	a
left join #dateswitch						b	on	a.Indv_Sys_ID = b.Indv_Sys_ID


--network status
If (object_id('tempdb..#ntwrk_sts') Is Not Null)
Drop Table #ntwrk_sts
go

select a.*, Network_Flag = case when b.ProvStatus = 'P'	then 1	else 0	end
into #ntwrk_sts
from	(--417669	
			select distinct Provider_MPIN
			from pdb_PCPSelection..Com_MbrProv_10_2015
		)	a
inner join NDB..Provider	b	on	a.Provider_MPIN = b.MPIN
--(415721 row(s) affected); 1948 lost MPINs
create unique clustered index ucIx_MPIN on #ntwrk_sts (Provider_MPIN);

alter table pdb_PCPSelection..Com_MbrProv_10_2015
	add Network_Flag	smallint
go

update pdb_PCPSelection..Com_MbrProv_10_2015
set Network_Flag = isnull(b.Network_Flag, 0)
from pdb_PCPSelection..Com_MbrProv_10_2015	a
left join #ntwrk_sts						b	on	a.Provider_MPIN = b.Provider_MPIN
--(2060560 row(s) affected)

/******************
Add OOP amounts & plan contracts as requested by Dan H. on 06/28/2016

Date: 29 June 2016
******************/
If (object_id('tempdb..#OOP') Is Not Null)
Drop Table #OOP
go

select b.Indv_Sys_Id, Total_OOP = sum(b.OOP_Amt)
into #OOP
from pdb_PCPSelection..Com_MbrClass_10_2015	a
inner join MiniHPDM..Fact_Claims			b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
inner join MiniHPDM..Dim_Date				c	on	b.Dt_Sys_Id = c.DT_SYS_ID
where c.YEAR_NBR = 2015
group by b.Indv_Sys_Id
--(306799 row(s) affected)
create unique clustered index ucIx_HICN on #OOP (Indv_Sys_Id);


alter table pdb_PCPSelection..Com_MbrClass_10_2015
	add Total_OOP	decimal(38,2)
go

update pdb_PCPSelection..Com_MbrClass_10_2015
set Total_OOP = isnull(b.Total_OOP, 0)
from pdb_PCPSelection..Com_MbrClass_10_2015	a
left join #OOP								b	on	a.Indv_Sys_Id = b.Indv_Sys_Id