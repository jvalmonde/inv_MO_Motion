/*** 
PCP Selection (Commercial population) version 2

Input databases:	MiniHPDM, pdb_PCPSelection

Date Created: 21 October 2016
***/

if object_id('tempdb..#member') is not null
drop table #member
go

Select distinct a.Indv_Sys_ID, b.Age, b.Gdr_Cd
INto #member					--627701
From pdb_PCPSelection..Com_MbrProv_10	a
left join MiniHPDM..Dim_Member			b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
--(627701 row(s) affected)
create unique clustered index ucIx_Indv on #member (Indv_Sys_ID);


if object_id('tempdb..#pcpflag') is not null
drop table #pcpflag
go

select MPIN, PCP_Flag = Case when SpecTypeCd in ('001','008','011','019','037','038','041','077','230','236','251','258'
                                                                            ,'272','273','274','275','276','281','282','338','339','375','384','506')  Then 1 Else 0 End           --codes used where taken from PAM project
into #pcpflag					--2716708
from NDB..Prov_Specialties
where PrimaryInd = 'P'
--(2662283 row(s) affected) with the primary indicator
create clustered index ucIx_MPIN on #pcpflag (MPIN);

if object_id('tempdb..#specialty') is not null
drop table #specialty
go

select MPIN, NPI, SpecTypeCd, ShortDesc, LongDesc
into #specialty					--2110083
from   (      
			select a.MPIN, NPI = d.NatlProvID, c.SpecTypeCd, c.ShortDesc, c.LongDesc
			       , OID = row_number() over(partition by a.MPIN order by (case when b.PrimaryInd = 'P'     then 1 else 0 end) desc) --not all MPINs have Primary specialties; assign a specialty
			from NDB..Provider				  a
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
into #ip_conf					--24535; 7.17 minutes
from #member						a
inner join MiniHPDM..Fact_Claims	b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
inner join MiniHPDM..Dim_Date		c	on	b.Dt_Sys_Id = c.DT_SYS_ID
where c.YEAR_NBR = 2014
	and b.Srvc_Typ_Sys_Id = 1
	and b.Admit_Cnt = 1
group by a.Indv_Sys_Id, b.Dt_Sys_Id, b.Day_Cnt
--(24533 row(s) affected)
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
into #premium_designation	--850409
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
left join Galaxy_Research..NDB_Efficiency_Outcome_Code		  as b on a.EFNCY_OTCOME_CD = b.EFNCY_OTCOME_CD
left join Galaxy_Research..NDB_Quality_Outcome_Code           as c on a.QLTY_OTCOME_CD = c.QLTY_OTCOME_CD
where a.RN = 1 --Get most recent record per MPIN
--(850409 row(s) affected)
create unique clustered index ucIx_MPIN on #premium_designation (MPIN);


if object_id('pdb_PCPSelection..Com_Prov_Claims_10') is not null
drop table pdb_PCPSelection..Com_Prov_Claims_10
go

select a.Indv_Sys_Id, Provider_MPIN = a.MPIN, Provider_TIN = a.TIN, EFNCY_FLAG = max(a.EFNCY_FLAG), QLTY_FLAG = max(a.QLTY_FLAG)
	, PCP_Flag	= max(isnull(a.PCP_Flag,0))		--added 1/11/2017
	, Specialty = a.LongDesc
	--spend
	, IP_Spend	= sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	else 0	end)
	, OP_Spend	= sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	else 0	end)
	, DR_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	else 0	end)
	, ER_Spend	= sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	else 0	end)
	, UC_Spend	= sum(case when Derived_Srvc_Type_cd = 'UC'	then Allw_Amt	else 0	end)		--added on 10-21-16
	, PCP_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Allw_Amt	else 0	end)
	, RX_Spend	= sum(case when Derived_Srvc_Type_cd = 'RX'	then Allw_Amt	else 0	end)	
	
	--visit counts
	, IP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'IP'	and Admit_Cnt = 1	then Dt_Sys_Id	end)
	, OP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'OP'	then Dt_Sys_Id	end)
	, DR_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR'	then Dt_Sys_Id	end)
	, ER_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'ER'	then Dt_Sys_Id	end)
	, UC_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'UC'	then Dt_Sys_Id	end) --added on 10-21-16
	, PCP_VstCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Dt_Sys_Id	end)
	
	, RX_Scripts	= sum(case when Derived_Srvc_Type_cd = 'RX'	then Scrpt_Cnt	else 0	end)
	, StartDate = min(Full_Dt)
	, EndDate	= max(Full_Dt)
--into pdb_PCPSelection..Com_Prov_Claims_10				--2,245,576 rows; 28:09mins
from	(		
			select c.*
				, Derived_Srvc_Type_cd = case when j.Indv_Sys_ID is not null and g.Srvc_Typ_Cd <> 'IP'  then 'IP'  
											  when f.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then 'ER' 
											  when AMA_PL_OF_SRVC_DESC = 'URGENT CARE FACILITY' And g.Srvc_Typ_Cd <>'IP' then 'UC' else g.Srvc_Typ_Cd end
				, d.FULL_DT, e.MPIN, e.TIN
				, PCP_Flag = isnull(case when j.Indv_Sys_Id is not null and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys	then 0	else h.PCP_Flag	end, 0)	--Don't flag PCPs if the visit occurred during an IP stay (Matt's email 05/19/2016)
				, i.LongDesc, k.EFNCY_FLAG, k.QLTY_FLAG
			--into #temp
			from #member									a
			inner join MiniHPDM..Fact_Claims				c	on	a.Indv_Sys_Id = c.Indv_Sys_Id
			inner join MiniHPDM..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			inner join MiniHPDM..Dim_Provider				e	on	c.Prov_Sys_Id = e.Prov_Sys_Id
			inner join MiniHPDM..Dim_HP_Service_Type_Code	f	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = f.HLTH_PLN_SRVC_TYP_CD_SYS_ID
			inner join MiniHPDM..Dim_Service_Type			g	on	c.Srvc_Typ_Sys_Id = g.Srvc_Typ_Sys_Id
			inner Join MiniHPDM..Dim_Place_of_Service_Code	l	on  l.PL_OF_SRVC_SYS_ID = c.Pl_of_Srvc_Sys_Id
			left join #pcpflag								h	on	e.MPIN = h.MPIN
			left join #specialty							i	on	e.MPIN = i.MPIN
			left join #ip_conf								j	on	a.Indv_Sys_Id = j.Indv_Sys_Id
																and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys
			left join #premium_designation					k	on	e.MPIN = k.MPIN
			where d.YEAR_NBR = 2014
				--and e.MPIN <> 0
				and e.MPIN = 2399850 and a.Indv_Sys_ID = 659287615
				--and a.Indv_Sys_Id in (32133786, 854332796, 908304601)
		) a
group by a.Indv_Sys_Id, a.MPIN, a.TIN, a.PCP_Flag, a.LongDesc
--(2248744 row(s) affected); 16.43 minutes
--(2245576 row(s) affected); 46.19 minutes
create clustered index cIx_Indv_MPIN on pdb_PCPSelection..Com_Prov_Claims_10 (Indv_Sys_Id, Provider_MPIN);

/*
Don't run this block of code on a normal refresh/run
select Indv_Sys_Id, Provider_MPIN, Provider_TIN
	, EFNCY_FLAG	= max(EFNCY_FLAG)
	, QLTY_FLAG		= max(QLTY_FLAG)
	, PCP_Flag		= max(PCP_Flag)
	, Specialty		= max(Specialty)
	, IP_Spend		= sum(IP_Spend)
	, OP_Spend		= sum(OP_Spend)
	, DR_Spend		= sum(DR_Spend)
	, ER_Spend		= sum(ER_Spend)
	, UC_Spend		= sum(UC_Spend)
	, PCP_Spend		= sum(PCP_Spend)
	, RX_Spend		= sum(RX_Spend)
	, IP_SrvcCnt	= sum(IP_SrvcCnt)
	, OP_SrvcCnt	= sum(OP_SrvcCnt)
	, DR_SrvcCnt	= sum(DR_SrvcCnt)
	, ER_SrvcCnt	= sum(ER_SrvcCnt)
	, UC_SrvcCnt	= sum(UC_SrvcCnt)
	, PCP_VstCnt	= sum(PCP_VstCnt)
	, RX_Scripts	= sum(RX_Scripts)
	, StartDate		= min(StartDate)
	, EndDate		= max(EndDate)
into pdb_PCPSelection..Com_Prov_Claims_10_v2
from pdb_PCPSelection..Com_Prov_Claims_10
--where Indv_Sys_Id = 16697852
group by Indv_Sys_Id, Provider_MPIN, Provider_TIN
--(2,236,188 row(s) affected)
*/

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
						from pdb_PCPSelection..Com_Prov_Claims_10_v2
						where PCP_Flag = 1
						group by Indv_Sys_Id, Provider_MPIN, StartDate, EndDate
					)	a
			left join (	
						select Indv_Sys_Id, Provider_MPIN, StartDate, EndDate, OID = row_number() over (partition by Indv_Sys_Id order by StartDate)
						from pdb_PCPSelection..Com_Prov_Claims_10_v2
						where PCP_Flag = 1 --and Indv_Sys_Id = 17081833
						group by Indv_Sys_Id, Provider_MPIN, StartDate, EndDate
					) b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
						and a.OID = (b.OID + 1)
			--where a.Indv_Sys_Id = 20488834
		) x
group by Indv_Sys_Id
--(353763 row(s) affected)
create unique clustered index ucIx_HICN on #class (Indv_Sys_Id);


-----------
--RAF & HCC
-----------
If (object_id('tempdb..#member_hcc') Is Not Null)
Drop Table #member_hcc
go

select UniqueMemberID = Indv_Sys_Id, GenderCd = Gdr_Cd, BirthDate = dateadd(yy, -(Age), '12-31-2014') , AgeLast = Age
into #member_hcc
from #member
--(627701 row(s) affected)
create unique clustered index ucIx_ID on #member_hcc (UniqueMemberID);


If (object_id('tempdb..#ip_claims_2014') Is Not Null)
Drop Table #ip_claims_2014
go

select distinct a.UniqueMemberID
	,c.Indv_Sys_Id
	,Diag1	= e1.Diag_Cd
	,Diag2	= e2.Diag_Cd
	,Diag3	= e3.Diag_Cd
	,DiagnosisServiceDate	= d.FULL_DT
into #ip_claims_2014
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
--(23208 row(s) affected)
create clustered index cIx_Indv on #ip_claims_2014 (Indv_Sys_Id);

If (object_id('tempdb..#OP_DR_Claims_2014') Is Not Null)
Drop Table #OP_DR_Claims_2014
go

select distinct  a.UniqueMemberID
	,b.Indv_Sys_Id 
	,Diag1 = e1.Diag_Cd
	,Diag2 = e2.Diag_Cd
	,Diag3 = e3.Diag_Cd
	,DiagnosisServiceDate	= c.FULL_DT
into	#OP_DR_Claims_2014
From	#member_hcc										as	a
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
	and c.Year_Nbr = 2014
--(2895502 row(s) affected)
create clustered index cIx_Indv on #OP_DR_Claims_2014 (Indv_Sys_Id);

If (object_id('tempdb..#IP_OP_DR_Claims_2014') Is Not Null)
Drop Table #IP_OP_DR_Claims_2014
go

Select * 
into #IP_OP_DR_Claims_2014	
from #ip_claims_2014	
union 
Select * 
from #OP_DR_Claims_2014
--(2917571 row(s) affected)

If (object_id('tempdb..#diag_2014') Is Not Null)
Drop Table #diag_2014
go

Select UniqueMemberID	
	,ICDCd
	,DiagnosisServiceDate
Into	#diag_2014
From	( Select a.UniqueMemberID, DiagnosisServiceDate, Diag1, Diag2, Diag3
		from #IP_OP_DR_Claims_2014 as	a
		)	as	p
unpivot
(
	ICDCd
	for Diag in (Diag1, Diag2, Diag3)	
 )	as unpvt
Where ICDCd not like '' 
--(5486854 row(s) affected)
create clustered index cIx_ID on #diag_2014 (UniqueMemberID);

exec RA_Commercial_2014.dbo.spRAFDiagInput
	 @InputPersonTable = '#member_hcc'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = '#diag_2014'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_PCPSelection'
	,@OutputSuffix = '2014'
go


if object_id('tempdb..#memberclass') is not null
drop table #memberclass
go

select a.Indv_Sys_ID
	, Switcher	= isnull(b.Switcher, 0)
	, Splitter	= isnull(b.Splitter, 0)
	, Sticker	= isnull(b.Sticker, 0)
	, Total_IP_Spend	
	, Total_OP_Spend	
	, Total_DR_Spend	
	, Total_ER_Spend
	, Total_UC_Spend --added on 10-21-16
	, Total_PCP_Spend
	, Total_RX_Spend
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
	, Total_UC_SrvcCnt --added on 10-21-16
	, Total_PCP_SrvcCnt
	, Total_RX_Scripts
	, RAF		= isnull(d.SilverTotalScore, 0)
into #memberclass				--
from #member		a
left join #class	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
left join	(
				select Indv_Sys_ID
					, Total_IP_Spend	= sum(IP_Spend)
					, Total_OP_Spend	= sum(OP_Spend)
					, Total_DR_Spend	= sum(DR_Spend)
					, Total_ER_Spend	= sum(ER_Spend)
					, Total_UC_Spend	= sum(UC_Spend) --added on 10-21-16
					, Total_PCP_Spend	= sum(PCP_Spend)
					, Total_RX_Spend	= sum(RX_Spend)
					, Total_IP_SrvcCnt	= sum(IP_SrvcCnt)
					, Total_OP_SrvcCnt	= sum(OP_SrvcCnt)
					, Total_DR_SrvcCnt	= sum(DR_SrvcCnt)
					, Total_ER_SrvcCnt	= sum(ER_SrvcCnt)
					, Total_UC_SrvcCnt	= sum(UC_SrvcCnt) --added on 10-21-16
					, Total_PCP_SrvcCnt	= sum(PCP_VstCnt)
					, Total_RX_Scripts	= sum(RX_Scripts)
				from pdb_PCPSelection..Com_Prov_Claims_10_v2
				group by Indv_Sys_ID
			)	c	on	a.Indv_Sys_ID = c.Indv_Sys_ID
left join pdb_PCPSelection..RA_Com_Q_MetalScoresPivoted_2014	d	on	a.Indv_Sys_ID = d.UniqueMemberID
group by  a.Indv_Sys_ID
	, b.Switcher
	, b.Splitter
	, b.Sticker
	, Total_IP_Spend	
	, Total_OP_Spend	
	, Total_DR_Spend	
	, Total_ER_Spend
	, Total_UC_Spend
	, Total_PCP_Spend
	, Total_RX_Spend
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
	, Total_UC_SrvcCnt
	, Total_PCP_SrvcCnt
	, Total_RX_Scripts
	, d.SilverTotalScore
--(627701 row(s) affected); 
create unique clustered index ucIx_HICN on #memberclass (Indv_Sys_ID);
--Select * From #memberclass 


--HCC pivot
if OBJECT_ID ('tempdb..#HCC') is not null begin drop table #HCC	End;

Select	UniqueMemberID, a.Coefficient , a.UsedInCalc 
	,b.Term			as	HCC
	,b.TermLabel	as	HCCLabel
	,HCC_Flag = case when b.Term is not null Then 1 Else 0 End
Into	#HCC
From	(Select	* 
		From	pdb_PCPSelection..RA_Com_R_ModelTerms_2014
		where ModelVersion = 'Silver'
		)										as	a
left join	RA_Commercial_2014..ModelHCC			as	b	on	a.Term = b.Term
where b.modelcategoryid = 9
--(151237 row(s) affected)

------------------------------------------------------------------------------------------------------------------
--Dynamic Pivot:
if OBJECT_ID ('pdb_PCPSelection..Com_HCC_2014') is not null begin drop table pdb_PCPSelection..Com_HCC_2014	End;

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
into pdb_PCPSelection..Com_HCC_2014
from

(select distinct UniqueMemberID
	,HCC
	,HCC_Flag
	from #HCC
	)	as s
	
	pivot(max(HCC_Flag) for HCC	
	in ( '+@listcol+'))				as pvt	'
	
	execute (@query1)
--(97317 row(s) affected)

--add weight
if object_id('pdb_PCPSelection..Com_MbrClass_10') is not null
drop table pdb_PCPSelection..Com_MbrClass_10
go

select a.Indv_Sys_ID
	, c.Age
	, c.Gdr_Cd
	, Switcher	
	, Splitter	
	, Sticker
	, Weight = (1 - b.Percnt)	
	, Total_IP_Spend	
	, Total_OP_Spend	
	, Total_DR_Spend	
	, Total_ER_Spend
	, Total_UC_Spend	--added on 10-21-16
	, Total_PCP_Spend
	, Total_RX_Spend
	, Total_Spend		= (Total_IP_Spend + Total_OP_Spend + Total_DR_Spend + Total_ER_Spend + Total_UC_Spend + Total_RX_Spend)	--added on 10-21-16 (UC_Spend)
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
	, Total_UC_SrvcCnt	--added on 10-21-16
	, Total_PCP_SrvcCnt
	, Total_RX_Scripts
	, RAF	
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
    , HCC106	= isnull(d.HCC106, 0)
    , HCC107	= isnull(d.HCC107, 0)
    , HCC108	= isnull(d.HCC108, 0)
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
    , HCC242	= isnull(d.HCC242, 0)
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
into pdb_PCPSelection..Com_MbrClass_10
from #memberclass							a
inner join	(
				select a.Indv_Sys_ID, b.PCP_VstCnt, Percnt = PCP_VstCnt * 1.0 / nullif(Ttl_PCP_Vst, 0) , RN = row_number() over(partition by a.Indv_Sys_ID	order by b.PCP_VstCnt desc)
				from	(
							select a.Indv_Sys_ID, Ttl_PCP_Vst = sum(PCP_VstCnt)
							from #memberclass	a
							left join pdb_PCPSelection..Com_Prov_Claims_10_v2	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
							group by a.Indv_Sys_ID
						) a
				left join pdb_PCPSelection..Com_Prov_Claims_10_v2	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
			)								b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
left join #member							c	on	a.Indv_Sys_ID = c.Indv_Sys_ID
left join pdb_PCPSelection..Com_HCC_2014	d	on	a.Indv_Sys_ID = d.UniqueMemberID
where b.RN = 1
--(627701 row(s) affected)
create unique clustered index ucIx_HICN on pdb_PCPSelection..Com_MbrClass_10	(Indv_Sys_ID);

/* No need to run this block of code upon refresh
update pdb_PCPSelection..Com_MbrClass_10
set Total_IP_Spend	= b.Total_IP_Spend
	, Total_OP_Spend	= b.Total_OP_Spend
	, Total_DR_Spend	= b.Total_DR_Spend
	, Total_ER_Spend	= b.Total_ER_Spend
	, Total_UC_Spend	= b.Total_UC_Spend
	, Total_PCP_Spend	= b.Total_PCP_Spend
	, Total_RX_Spend	= b.Total_RX_Spend
	, Total_Spend		= (b.Total_IP_Spend + b.Total_OP_Spend + b.Total_DR_Spend + b.Total_ER_Spend + b.Total_UC_Spend + b.Total_RX_Spend)
	, Total_IP_SrvcCnt	= b.Total_IP_SrvcCnt
	, Total_OP_SrvcCnt	= b.Total_OP_SrvcCnt
	, Total_DR_SrvcCnt	= b.Total_DR_SrvcCnt
	, Total_ER_SrvcCnt	= b.Total_ER_SrvcCnt
	, Total_UC_SrvcCnt	= b.Total_UC_SrvcCnt
	, Total_PCP_SrvcCnt	= b.Total_PCP_SrvcCnt
	, Total_RX_Scripts	= b.Total_RX_Scripts
from pdb_PCPSelection..Com_MbrClass_10	a
left join #memberclass				b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
*/


if object_id('pdb_PCPSelection..Com_MbrProv_10') is not null
drop table pdb_PCPSelection..Com_MbrProv_10
go

select a.Indv_Sys_ID, b.Provider_MPIN, b.Provider_TIN, b.PCP_Flag, b.Specialty, b.EFNCY_FLAG, b.QLTY_FLAG
	, b.IP_Spend
	, b.OP_Spend
	, b.DR_Spend
	, b.ER_Spend
	, b.UC_Spend	--added on 10-21-16
	, b.PCP_Spend
	, b.RX_Spend
	, b.IP_SrvcCnt
	, b.OP_SrvcCnt
	, b.DR_SrvcCnt
	, b.ER_SrvcCnt
	, b.UC_SrvcCnt	--added on 10-21-16
	, b.PCP_VstCnt
	, b.RX_Scripts
	, b.StartDate 
	, b.EndDate	
	, a.Switcher
	, a.Splitter
	, a.Sticker
	, TotalSpend	= (b.IP_Spend + b.OP_Spend + b.DR_Spend + b.ER_Spend + b.UC_Spend + b.RX_Spend)	--added on 10-21-16 (UC_Spend)
	, TotalSrvcCnt	= (b.IP_SrvcCnt + b.OP_SrvcCnt + b.DR_SrvcCnt + b.ER_SrvcCnt + b.UC_SrvcCnt)	--added on 10-21-16 (UC_Visit)
into pdb_PCPSelection..Com_MbrProv_10
from pdb_PCPSelection..Com_MbrClass_10			a
left join pdb_PCPSelection..Com_Prov_Claims_10_v2	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
--where a.INdv_Sys_ID = 16697852
	--and b.PCP_Flag = 1
--(2449682 row(s) affected)

Create Clustered Index CIX_Provider_MPIN_Provider_TIN On pdb_PCPSelection..Com_MbrProv_10 (Provider_MPIN, Provider_TIN);

update pdb_PCPSelection..Com_MbrProv_10
set Switcher = isnull(b.Switcher, 0)
	, Splitter = isnull(b.Splitter, 0)
	, Sticker = isnull(b.Sticker, 0)
from pdb_PCPSelection..Com_MbrProv_10	a
left join #class						b	on	a.Indv_Sys_ID = b.Indv_Sys_ID



/* No need to run this block of code upon refresh
update pdb_PCPSelection..Com_MbrProv_10
set	IP_Spend = b.IP_Spend
	, OP_Spend = b.OP_Spend
	, DR_Spend = b.DR_Spend
	, ER_Spend = b.ER_Spend
	, UC_Spend = b.UC_Spend
	, PCP_Spend = b.PCP_Spend
	, RX_Spend  = b.RX_Spend
	, IP_SrvcCnt = b.IP_SrvcCnt
	, OP_SrvcCnt = b.OP_SrvcCnt
	, DR_SrvcCnt = b.DR_SrvcCnt
	, ER_SrvcCnt = b.ER_SrvcCnt
	, UC_SrvcCnt = b.UC_SrvcCnt
	, PCP_VstCnt = b.PCP_VstCnt
	, RX_Scripts = b.RX_Scripts
	, TotalSpend	= (b.IP_Spend + b.OP_Spend + b.DR_Spend + b.ER_Spend + b.UC_Spend + b.RX_Spend)
	, TotalSrvcCnt	= (b.IP_SrvcCnt + b.OP_SrvcCnt + b.DR_SrvcCnt + b.ER_SrvcCnt + b.UC_SrvcCnt)	--exclude RX_Scripts 01/10/17
from pdb_PCPSelection..Com_MbrProv_10	a
left join pdb_PCPSelection..Com_Prov_Claims_10		b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
														and a.Provider_MPIN = b.Provider_MPIN		--added 01/10/17
														and a.Provider_TIN = b.Provider_TIN			--added 01/10/17
*/

------------------
--add Date Switch
------------------
/* this block of code need not be executed if a rerun of the previous block of codes is made

if object_id('tempdb..#ip_conf') is not null
drop table #ip_conf
go

select a.Indv_Sys_ID
	, Admt_DtSys = b.Dt_Sys_Id
	, Discharge_DtSys = (b.Dt_Sys_Id + b.Day_Cnt)
into #ip_conf
from pdb_PCPSelection..Com_MbrClass_10	a
inner join MiniHPDM..Fact_Claims		b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
inner join MiniHPDM..Dim_Date			c	on	b.Dt_Sys_Id = c.DT_SYS_ID
where c.YEAR_NBR = 2014
	and b.Srvc_Typ_Sys_Id = 1
	and b.Admit_Cnt = 1
group by a.Indv_Sys_ID, b.Dt_Sys_Id, b.Day_Cnt
--(2791 row(s) affected)
create clustered index cIx_SavvyID on #ip_conf (Indv_Sys_ID);
create nonclustered index ncIx_Dt on #ip_conf (Admt_DtSys, Discharge_DtSys);
*/

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
						from pdb_PCPSelection..Com_MbrProv_10
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
--(65078 row(s) affected)
create unique clustered index ucIx_HICN on #dateswitch (Indv_Sys_ID);

select * from #dateswitch where CloseIPConf > 365

alter table pdb_PCPSelection..Com_MbrClass_10
	add DateSwitch	date
		, SwitchCnt	smallint
		, DaysToFrom_IPConf	int
go

update pdb_PCPSelection..Com_MbrClass_10
set	DateSwitch = b.DateSwitch
	, SwitchCnt = isnull(b.SwitchCnt, 0)
	, DaysToFrom_IPConf = isnull(b.CloseIPConf, 0)
from pdb_PCPSelection..Com_MbrClass_10	a
left join #dateswitch					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID

select *
from pdb_PCPSelection..Com_MbrClass_10


/******************
PCP In/Out of network flags as requested by Dan H. on 06/22/2016

Date: 23 June 2016
******************/
If (object_id('tempdb..#ntwrk_sts') Is Not Null)
Drop Table #ntwrk_sts
go

select a.*, Network_Flag = case when b.ProvStatus = 'P'	then 1	else 0	end
into #ntwrk_sts
from	(--471340	
			select distinct Provider_MPIN
			from pdb_PCPSelection..Com_MbrProv_10
		)	a
inner join NDB..Provider	b	on	a.Provider_MPIN = b.MPIN
--(466635 row(s) affected); 4705 lost MPINs
--(462776 row(s) affected)
create unique clustered index ucIx_MPIN on #ntwrk_sts (Provider_MPIN);

alter table pdb_PCPSelection..Com_MbrProv_10
	add Network_Flag	smallint
go

update pdb_PCPSelection..Com_MbrProv_10
set Network_Flag = isnull(b.Network_Flag, 0)
from pdb_PCPSelection..Com_MbrProv_10	a
left join #ntwrk_sts					b	on	a.Provider_MPIN = b.Provider_MPIN
--(2449682 row(s) affected)


/******************
Add OOP amounts & plan contracts as requested by Dan H. on 06/28/2016

Date: 29 June 2016
******************/
If (object_id('tempdb..#OOP') Is Not Null)
Drop Table #OOP
go

select b.Indv_Sys_Id, Total_OOP = sum(b.OOP_Amt)
into #OOP
from pdb_PCPSelection..Com_MbrClass_10	a
inner join MiniHPDM..Fact_Claims		b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
inner join MiniHPDM..Dim_Date			c	on	b.Dt_Sys_Id = c.DT_SYS_ID
where c.YEAR_NBR = 2014
group by b.Indv_Sys_Id
--(423554 row(s) affected); 6.22 minutes
create unique clustered index ucIx_HICN on #OOP (Indv_Sys_Id);


alter table pdb_PCPSelection..Com_MbrClass_10
	add Total_OOP	decimal(38,2)
go

update pdb_PCPSelection..Com_MbrClass_10
set Total_OOP = isnull(b.Total_OOP, 0)
from pdb_PCPSelection..Com_MbrClass_10	a
left join #OOP							b	on	a.Indv_Sys_Id = b.Indv_Sys_Id


/******************
Add these:
	Urgent Care utilization (visit and spend)	--refer to updated codes above
	Distance from member to provider zip
	Provider specialty - done above codes (Specialty col in pdb_PCPSelection..Com_Prov_Claims_10)
	Premium designation - done above codes (EFNCY_FLAG & QLTY_FLAG cols in pdb_PCPSelection..Com_Prov_Claims_10)
	Assigned PCP from Galaxy (cleanroom)

Date: 17 Oct 2016
******************/
--Get the zip codes per member, PCP & compute distance
--member zip
If (object_id('tempdb..#Member_Zip') Is Not Null)
Drop Table #Member_Zip
go

Select A.Indv_Sys_Id, C.Zip, Zip_Lat, Zip_Lng, St_Cd
Into #Member_Zip							
from pdb_PCPSelection..Com_MbrClass_10		A
Join MiniHPDM..Dim_Member					B ON A.Indv_Sys_Id = B.Indv_Sys_Id
Join pdb_HealthcareResearch..Zip_Census		C On B.Zip = C.Zip
group by A.Indv_Sys_Id, C.Zip, Zip_Lat, Zip_Lng, St_Cd
--(627,059 row(s) affected)
create unique clustered index ucIx_Indv_Zip on #Member_Zip (Indv_Sys_Id, Zip);

--investigate lost Indv_Sys
select a.*--b.Zip, count(distinct a.Indv_Sys_ID)
from	(--642
select a.*
from pdb_PCPSelection..Com_MbrClass_10	a
left join #Member_Zip					b	on	 a.Indv_Sys_ID = b.Indv_Sys_ID
where b.Indv_Sys_ID is null
		)	a
left join MiniHPDM..Dim_Member	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID	--98 Indv_Sys_ID not in Dim_Member
--left join pdb_HealthcareResearch..Zip_Census	c	on	b.Zip = c.Zip	--544 Indv_Sys_ID with Zips that are not in Zip_Census or are weird
where b.Indv_Sys_ID is null
where c.Zip is null
group by b.Zip


--Provider zip
--pull for the Zips where the Provider is associated with. otherwise pull for the Provider's Zip
select count(distinct Provider_MPIN), count(distinct Provider_TIN)	--470,815	177,424
from pdb_PCPSelection..Com_MbrProv_10

select *
from pdb_PCPSelection..Com_MbrProv_10
where Provider_TIN is null
--213,494 rows

If (object_id('tempdb..#TIN_Zip') Is Not Null)
Drop Table #TIN_Zip
go

select a.Provider_MPIN, a.Provider_TIN, TIN_Zip = e.ZipCd, TIN_St = e.State
into #TIN_Zip
from pdb_PCPSelection..Com_MbrProv_10	a
inner join NDB..PROV_MPIN_TAXID			b	on	a.Provider_TIN = b.TaxID
inner join NDB..Provider				c	on	b.MPIN = c.MPIN
inner join NDB..MPIN_Location			d	on	c.MPIN = d.MPIN
											and b.TaxID = d.TaxID
inner join NDB..Prov_Address			e	on	d.AddressID = e.AddressID
where a.Provider_TIN is not null
	and c.ProvType = 'O'
	and d.PrimAdrInd = 'P'
group by a.Provider_MPIN, a.Provider_TIN, e.ZipCd, e.State
--(2562568 row(s) affected)
create clustered index cIx_MPIN_TIN_St on #TIN_Zip (Provider_MPIN, Provider_TIN, TIN_St);


If (object_id('tempdb..#ProvMPIN_Zip') Is Not Null)
Drop Table #ProvMPIN_Zip
go

select a.Provider_MPIN, a.Provider_TIN, ProvMPIN_Zip = d.ZipCd, ProvMPIN_St = d.State
into #ProvMPIN_Zip
from pdb_PCPSelection..Com_MbrProv_10	a
inner join NDB..Provider				b	on	a.Provider_MPIN = b.MPIN
inner join NDB..MPIN_Location			c	on	b.MPIN = c.MPIN
inner join NDB..Prov_Address			d	on	c.AddressID = d.AddressID
where a.Provider_MPIN is not null
	and c.PrimAdrInd = 'P'
group by a.Provider_MPIN, a.Provider_TIN, d.ZipCd, d.State
--(497,947 row(s) affected)
create unique clustered index cIx_MPIN_TIN_St on #ProvMPIN_Zip (Provider_MPIN, Provider_TIN, ProvMPIN_Zip);


If (object_id('tempdb..#fnl_zip') Is Not Null)
Drop Table #fnl_zip
go

select c.Indv_Sys_ID, a.*, b.Zip_Lat, b.Zip_Lng
into #fnl_zip
from	(--1,914,593
			select a.Provider_MPIN, a.Provider_TIN
				, ZipCd = case when a.TIN_Zip = b.ProvMPIN_Zip	then b.ProvMPIN_Zip	else a.TIN_Zip	end
				, StCd	= a.TIN_St
			from #TIN_Zip				a
			inner join #ProvMPIN_Zip	b	on	a.Provider_MPIN = b.Provider_MPIN
											and a.Provider_TIN = b.Provider_TIN
											and a.TIN_St = b.ProvMPIN_St
		) a
inner join pdb_HealthcareResearch..Zip_Census	b	on	a.ZipCd = b.Zip
inner join	(--2,459,070
				select Indv_Sys_ID, Provider_MPIN, Provider_TIN
					, OID = row_number() over(partition by Indv_Sys_ID, Provider_MPIN, Provider_TIN order by StartDate)
				from pdb_PCPSelection..Com_MbrProv_10
			)	c	on	a.Provider_MPIN = c.Provider_MPIN
					and a.Provider_TIN = c.Provider_TIN
where a.Provider_TIN <> '000000000'
	and c.OID = 1
--(1,907,146 row(s) affected)
--8255968
create clustered index cIx_Zip on #fnl_zip (ZipCd);

select * from #fnl_zip where Zip_Lat is null and Zip_Lng is null	order by 1,2,3

select count(distinct Provider_MPIN) from #fnl_zip where Provider_TIN = '000000000'	--331
select count(distinct Provider_MPIN) from #fnl_zip	--416,613


If (object_id('tempdb..#Mbr_Prov_Zip_LatLong') Is Not Null)
Drop Table #Mbr_Prov_Zip_LatLong
go

select a.Indv_Sys_ID, a.Provider_MPIN, a.Provider_TIN, Mbr_Zip = b.Zip, Prov_Zip = c.ZipCd
	, Mbr_Lat = case when b.Zip_Lat is not null		then cast(b.Zip_Lat as float)	else 0	end
	, Mbr_Lng = case when b.Zip_Lng is not null		then cast(b.Zip_Lng as float)	else 0	end
	, Prov_Lat = case when c.Zip_Lat is not null	then cast(c.Zip_Lat as float)	else 0	end
	, Prov_Lng = case when c.Zip_Lng is not null	then cast(c.Zip_Lng as float)	else 0	end
into #Mbr_Prov_Zip_LatLong
from pdb_PCPSelection..Com_MbrProv_10	a
inner join #Member_Zip					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
inner join #fnl_zip						c	on	a.Indv_Sys_ID = c.Indv_Sys_ID
											and a.Provider_MPIN = c.Provider_MPIN
											and a.Provider_TIN = c.Provider_TIN
											and b.St_Cd = c.StCd					--Member & Provider should be in the same state	
where a.Provider_MPIN is not null
	and a.Provider_TIN is not null
	and a.Provider_TIN <> '000000000'
group by a.Indv_Sys_ID, a.Provider_MPIN, a.Provider_TIN, b.Zip_Lat, b.Zip_Lng, c.Zip_Lat, c.Zip_Lng, b.Zip, c.ZipCd
--(7187334 row(s) affected)
create clustered index cIx_Lat_Lng on #Mbr_Prov_Zip_LatLong (Mbr_Lat, Mbr_Lng, Prov_Lat, Prov_Lng);


If (object_id('tempdb..#Distance') Is Not Null)
Drop Table #Distance
go

Select distinct Indv_Sys_Id, Provider_MPIN, Provider_TIN, Mbr_Zip, Prov_Zip
	, Distance = (pdb_PCPSelection.dbo.CoordinateDistanceMiles(Mbr_Lat, Mbr_Lng, Prov_Lat, Prov_Lng))
Into #Distance									
From #Mbr_Prov_Zip_LatLong
Where (Mbr_Lat <> Prov_Lat 
	OR  Mbr_Lng <> Prov_Lng)
--(6929041 row(s) affected); 4.52 minutes
create clustered index cIx_Provider_MPIN_Indv_SYS_ID on #Distance (Provider_MPIN, Indv_SYS_ID, Provider_TIN);


If (object_id('tempdb..#MbrProv_ZipDistance') Is Not Null)
Drop Table #MbrProv_ZipDistance
go

select Indv_Sys_ID, Provider_MPIN, Provider_TIN
	, MbrProv_ZipDistance = avg(Distance)
	, ProvZip_Cnt = count(distinct Prov_Zip)
into #MbrProv_ZipDistance
from #Distance
group by Indv_Sys_ID, Provider_MPIN, Provider_TIN
--(1581308 row(s) affected)
create unique clustered index ucIx_Indv_Prov on #MbrProv_ZipDistance (Indv_Sys_ID, Provider_MPIN, Provider_TIN);


alter table pdb_PCPSelection..Com_MbrProv_10 	
	add MbrProv_ZipDistance	decimal(38,2)
		, ProvZip_Cnt int
go

update pdb_PCPSelection..Com_MbrProv_10 
set MbrProv_ZipDistance		= isnull(b.MbrProv_ZipDistance, 0)
	, ProvZip_Cnt			= isnull(b.ProvZip_Cnt, 0)
from pdb_PCPSelection..Com_MbrProv_10		a
left join #MbrProv_ZipDistance				b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
												and a.Provider_MPIN = b.Provider_MPIN 
												and a.Provider_TIN = b.Provider_TIN
go


-- QA Check for mbr-prov distance
Select min(MbrProv_ZipDistance), max(MbrProv_ZipDistance), avg(MbrProv_ZipDistance)		--0.00	7960.01	37.196787
From pdb_PCPSelection..Com_MbrProv_10

Select * From pdb_PCPSelection..Com_MbrProv_10 WHere MbrProv_ZipDistance > '100' Order by MbrProv_ZipDistance	--104,209 (4.23%)		--489,825 (19.9%)

/******************
Member Type version 2.0

Date:	02 November 2016
******************/
--pull for the ER, IP, UC claims & dates
If (object_id('tempdb..#er_ip_uc') Is Not Null)
Drop Table #er_ip_uc
go

select a.Indv_Sys_ID, a.MPIN, a.TIN, a.Derived_Srvc_Type_cd, Service_Dt = a.Full_Dt
into #er_ip_uc
from	(
			select c.*
				, Derived_Srvc_Type_cd = case when j.Indv_Sys_ID is not null and g.Srvc_Typ_Cd <> 'IP'  then 'IP'  
											  when f.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then 'ER' 
											  when AMA_PL_OF_SRVC_DESC = 'URGENT CARE FACILITY' And g.Srvc_Typ_Desc<>'IP' then 'UC' else g.Srvc_Typ_Cd end
				, d.FULL_DT, e.MPIN, e.TIN
			from #member									a
			inner join MiniHPDM..Fact_Claims				c	on	a.Indv_Sys_Id = c.Indv_Sys_Id
			inner join MiniHPDM..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			inner join MiniHPDM..Dim_Provider				e	on	c.Prov_Sys_Id = e.Prov_Sys_Id
			inner join MiniHPDM..Dim_HP_Service_Type_Code	f	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = f.HLTH_PLN_SRVC_TYP_CD_SYS_ID
			inner join MiniHPDM..Dim_Service_Type			g	on	c.Srvc_Typ_Sys_Id = g.Srvc_Typ_Sys_Id
			inner Join MiniHPDM..Dim_Place_of_Service_Code	l	on  l.PL_OF_SRVC_SYS_ID = c.Pl_of_Srvc_Sys_Id
			left join #ip_conf								j	on	a.Indv_Sys_Id = j.Indv_Sys_Id
																and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys
			where d.YEAR_NBR = 2014
				and e.MPIN <> 0
		) a
where a.Derived_Srvc_Type_cd in ('IP', 'ER', 'UC')
group by a.Indv_Sys_ID, a.MPIN, a.TIN, a.Derived_Srvc_Type_cd, a.Full_Dt
--(459920 row(s) affected); 5.56 minutes
create clustered index cIx_Indv_MPIN on #er_ip_uc (Indv_Sys_ID, MPIN);


If (object_id('tempdb..#event_flag') Is Not Null)
Drop Table #event_flag
go

select	a.*, b.Derived_Srvc_Type_cd, b.Service_Dt
	, Distance_Flag = case when MbrProv_ZipDistance > 100	then	1	else 0	end										--don't classify a member if the distance to the PCP is far away
	, Event_Flag	= case when b.Indv_Sys_Id is not null and a.StartDate = b.Service_Dt	then	1	else 0	end		--don't classify a member if his dividing or moving event occurred in an ER/IP/UC
	, Event			= case when b.Indv_Sys_Id is not null and a.StartDate = b.Service_Dt	then	Derived_Srvc_Type_cd	end
into #event_flag
from	(
			select Indv_Sys_ID, Provider_MPIN, Provider_TIN, Sticker, Splitter, Switcher, StartDate, EndDate, MbrProv_ZipDistance
			from pdb_PCPSelection..Com_MbrProv_10
			where PCP_Flag = 1
			group by Indv_Sys_ID, Provider_MPIN, Provider_TIN, Sticker, Splitter, Switcher, StartDate, EndDate, MbrProv_ZipDistance
		)	a
left join #er_ip_uc					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
										and a.Provider_MPIN = b.MPIN
										and a.Provider_TIN = b.TIN
--(699833 row(s) affected)
create clustered index ucIx_Indv_MPIN on #event_flag (Indv_Sys_ID, Provider_MPIN);


If (object_id('tempdb..#mbr_fnl') Is Not Null)
Drop Table #mbr_fnl
go

select a.*
into #mbr_fnl
from #event_flag	a
left join	(--40,823; when classifying member in the new version exclude those UC,ER or "long distance" events
				select *
				from #event_flag
				where Distance_Flag = 1
					or Event_Flag = 1
			) b		on	a.Indv_Sys_ID = b.Indv_Sys_ID
					and a.Provider_MPIN = b.Provider_MPIN
where b.Indv_Sys_ID is null
--(646720 row(s) affected)
create clustered index cIx_Indv_MPIN	on #mbr_fnl	(Indv_Sys_ID, Provider_MPIN);
select * from #mbr_fnl	where Indv_sys_id = 18517638

If (object_id('tempdb..#mbr_class2') Is Not Null)
Drop Table #mbr_class2
go

select Indv_Sys_ID
	, Divider	= max(a.Splitter)
	, Mover		= case when max(a.Splitter) = 0	and max(a.RN) <> 1	then	1				else  0		end
	, Sticker2	= case when max(RN) = 1								then	1				else  0		end
into #mbr_class2
from	(
			select a.*
				, Splitter = (case when a.StartDate between b.StartDAte and b.EndDate	then 1	else 0 end)
			from	(
						select Indv_Sys_ID, Provider_MPIN, Provider_TIN, StartDate, EndDate
							, RN = row_number() over(partition by Indv_Sys_ID order by StartDate)
						from #mbr_fnl
						group by Indv_Sys_ID, Provider_MPIN, Provider_TIN, StartDate, EndDate
					) a
			left join	(
							select Indv_Sys_ID, Provider_MPIN, Provider_TIN, StartDate, EndDate
								, RN = row_number() over(partition by Indv_Sys_ID order by StartDate)
							from #mbr_fnl
							group by Indv_Sys_ID, Provider_MPIN, Provider_TIN, StartDate, EndDate
						)	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
								and a.RN = (b.RN + 1)
		) a
group by Indv_Sys_ID
--(342471 row(s) affected)
create unique clustered index ucIx_Indv on #mbr_class2 (Indv_Sys_ID);

--select * from #mbr_class2 where (Divider + Mover + Sticker2) > 1
select * from #mbr_class2 where Indv_Sys_ID = 18517638

alter table pdb_PCPSelection..Com_MbrClass_10
	add	Divider smallint
		, Mover	smallint
		, Sticker2	smallint
go

update pdb_PCPSelection..Com_MbrClass_10
set Divider = isnull(b.Divider, 0)
	, Mover	= isnull(b.Mover, 0)
	, Sticker2	= isnull(b.Sticker2, 0)
from pdb_PCPSelection..Com_MbrClass_10	a
left join #mbr_class2					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID

alter table pdb_PCPSelection..Com_MbrProv_10
	add	Divider smallint
		, Mover	smallint
		, Sticker2	smallint
go

update pdb_PCPSelection..Com_MbrProv_10
set Divider = isnull(b.Divider, 0)
	, Mover	= isnull(b.Mover, 0)
	, Sticker2	= isnull(b.Sticker2, 0)
from pdb_PCPSelection..Com_MbrProv_10	a
left join #mbr_class2					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID


--added: 12 December 2016
if object_id('tempdb..#event_flag_fnl') is not null
drop table #event_flag_fnl
go

select Indv_Sys_ID
	, Provider_MPIN
	, Provider_TIN
	, Distance_Flag = max(Distance_Flag)
	, IP_Flag = max(case when Event_Flag = 1 and Event = 'IP'	then 1	else 0	end)
	, UC_Flag = max(case when Event_Flag = 1 and Event = 'UC'	then 1	else 0	end)
	, ER_Flag = max(case when Event_Flag = 1 and Event = 'ER'	then 1	else 0	end)
into #event_flag_fnl
from #event_flag
where Distance_Flag = 1 or Event_Flag = 1
group by Indv_Sys_ID
	, Provider_MPIN
	, Provider_TIN
--(43026 row(s) affected)
create clustered index cIx_SavvyHICN on #event_flag_fnl (Indv_Sys_ID);


alter table pdb_PCPSelection..Com_MbrClass_10
	add Distance_Flag	smallint
		, IP_Flag		smallint
		, UC_Flag		smallint
		, ER_Flag		smallint
go

update pdb_PCPSelection..Com_MbrClass_10
set Distance_Flag = Isnull(b.Distance_Flag, 0)
	, IP_Flag	= isnull(b.IP_Flag, 0)
	, UC_Flag	= isnull(b.UC_Flag, 0)
	, ER_Flag	= isnull(b.ER_Flag, 0)
from pdb_PCPSelection..Com_MbrClass_10	a
left join	(
				select Indv_Sys_ID
					, Distance_Flag = max(Distance_Flag), IP_Flag = max(IP_Flag), UC_Flag = max(UC_Flag), ER_Flag = max(ER_Flag)	--added 01/11/2017
				from #event_flag_fnl	
				group by Indv_Sys_ID
			)	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID

alter table pdb_PCPSelection..Com_MbrProv_10
	add Distance_Flag	smallint
		, IP_Flag		smallint
		, UC_Flag		smallint
		, ER_Flag		smallint
go

update pdb_PCPSelection..Com_MbrProv_10
set Distance_Flag	= isnull(b.Distance_Flag, 0)
	, IP_Flag = isnull(b.IP_Flag, 0)
	, UC_Flag = isnull(b.UC_Flag, 0)
	, ER_Flag = isnull(b.ER_Flag, 0)
from pdb_PCPSelection..Com_MbrProv_10	a
left join #event_flag_fnl	b	on	a.Indv_Sys_ID = b.Indv_Sys_ID
								and a.Provider_MPIN = b.Provider_MPIN
								and a.Provider_TIN = b.Provider_TIN



/******************
TIN flags

Date:	08 December 2016
******************/
--identify member classification using TIN
if object_id('tempdb..#class_v2') is not null
drop table #class_v2
go

select Indv_Sys_Id
	, TIN_Split = max(Splitter)
	, TIN_Switch = case when max(Splitter) = 0 and max(x.RN) <> 1	then 1	else 0	end
	, TIN_Stick = case when max(x.RN) = 1	then 1	else 0 end
into #class_v2		--353763
from	(	
			select a.*, Prov2 = b.Provider_TIN, StrtDt2 = b.StartDate, EndDt2 = b.EndDate, RN2 = b.RN
				, Splitter = (case when a.StartDate between b.StartDAte and b.EndDate	then 1	else 0 end)
			from	(	
						select Indv_Sys_Id, Provider_TIN, StartDate, EndDate, RN = row_number() over (partition by Indv_Sys_Id  order by StartDate)
						from	(
									select Indv_Sys_Id, Provider_TIN = case when Provider_TIN = '000000000'	then Provider_MPIN	else Provider_TIN	end
										, StartDate, EndDate, OID = row_number() over (partition by Indv_Sys_Id, (case when Provider_TIN = '000000000'	then Provider_MPIN	else Provider_TIN	end)  order by StartDate)
									from pdb_PCPSelection..Com_Prov_Claims_10_v2
									where PCP_Flag = 1 --and INdv_Sys_ID = 16083771
									--where Indv_Sys_Id = 16002089 and PCP_Flag = 1
								) a
						where OID = 1
					)	a
			left join (	
						select Indv_Sys_Id, Provider_TIN, StartDate, EndDate, RN = row_number() over (partition by Indv_Sys_Id  order by StartDate)
						from	(
									select Indv_Sys_Id, Provider_TIN = case when Provider_TIN = '000000000'	then Provider_MPIN	else Provider_TIN	end
										, StartDate, EndDate, OID = row_number() over (partition by Indv_Sys_Id, (case when Provider_TIN = '000000000'	then Provider_MPIN	else Provider_TIN	end)  order by StartDate)
									from pdb_PCPSelection..Com_Prov_Claims_10_v2
									where PCP_Flag = 1
								) a
						where OID = 1
					) b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
						and a.RN = (b.RN + 1)
		) x
group by Indv_Sys_Id
--(353763 row(s) affected)
create unique clustered index ucIx_HICN on #class_v2 (Indv_Sys_Id);


alter table pdb_PCPSelection..Com_MbrClass_10
	add	TIN_Split		smallint
		, TIN_Switch	smallint
		, TIN_Stick		smallint
go

update pdb_PCPSelection..Com_MbrClass_10
set TIN_Split = isnull(b.TIN_Split, 0)
	, TIN_Switch	= isnull(b.TIN_Switch, 0)
	, TIN_Stick		= isnull(b.TIN_Stick, 0)
from pdb_PCPSelection..Com_MbrClass_10	a
left join #class_v2					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID

alter table pdb_PCPSelection..Com_MbrProv_10
	add	TIN_Split		smallint
		, TIN_Switch	smallint
		, TIN_Stick		smallint
go

update pdb_PCPSelection..Com_MbrProv_10
set TIN_Split = isnull(b.TIN_Split, 0)
	, TIN_Switch	= isnull(b.TIN_Switch, 0)
	, TIN_Stick		= isnull(b.TIN_Stick, 0)
from pdb_PCPSelection..Com_MbrProv_10	a
left join #class_v2					b	on	a.Indv_Sys_ID = b.Indv_Sys_ID