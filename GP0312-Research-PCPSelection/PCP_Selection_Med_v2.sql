/*
PCP Selection for Medicare version 2 scripts
*/

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

select a.SavvyHICN
	, Admt_DtSys = c.Dt_Sys_Id
	, Discharge_DtSys = (c.Dt_Sys_Id + c.Day_Cnt)
into #ip_conf
from pdb_PCPSelection..MbrClass_10	a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID
where d.YEAR_NBR = 2014
	and c.Srvc_Typ_Sys_Id = 1
	and c.Admit_Cnt = 1
group by a.SavvyHICN, c.Dt_Sys_Id, c.Day_Cnt
--(37755 row(s) affected)
create clustered index cIx_SavvyID on #ip_conf (SavvyHICN);
create nonclustered index ncIx_Dt on #ip_conf (Admt_DtSys, Discharge_DtSys);


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


if object_id('pdb_PCPSelection..Prov_Claims_10_v2') is not null
drop table pdb_PCPSelection..Prov_Claims_10_v2
go

select a.SavvyHICN, Provider_MPIN = a.MPIN, Provider_TIN = TIN, EFNCY_FLAG, QLTY_FLAG
	, PCP_Flag	= isnull(PCP_Flag,0)
	, Specialty = LongDesc
	--spend
	, IP_Spend	= sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	else 0	end)
	, OP_Spend	= sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	else 0	end)
	, DR_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	else 0	end)
	, ER_Spend	= sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	else 0	end)
	, PCP_Spend	= sum(case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Allw_Amt	else 0	end)
	, RX_Spend	= isnull(max(RX_Spend), 0)

	--visit counts
	, IP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'IP'	and Admit_Cnt = 1	then Dt_Sys_Id	end)
	, OP_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'OP'	then Dt_Sys_Id	end)
	, DR_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR'	then Dt_Sys_Id	end)
	, ER_SrvcCnt	= count(distinct case when Derived_Srvc_Type_cd = 'ER'	then Dt_Sys_Id	end)
	, PCP_VstCnt	= count(distinct case when Derived_Srvc_Type_cd = 'DR' and PCP_Flag = 1		then Dt_Sys_Id	end)

	, RX_Scripts	= isnull(max(RX_Scripts), 0)
	, StartDate = min(Full_Dt)
	, EndDate	= max(Full_Dt)
	--, OID = row_number() over(partition by SavvyHICN order by min(Full_Dt))
into pdb_PCPSelection..Prov_Claims_10_v2
from	(		
			select a.SavvyHICN, c.*
				, Derived_Srvc_Type_cd = case when j.SavvyHICN is not null and g.Srvc_Typ_Cd <> 'IP'  then 'IP'  
												when f.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')	then 'ER' else g.Srvc_Typ_Cd end
				, d.FULL_DT, e.MPIN, e.TIN
				, PCP_Flag = isnull(case when j.SavvyHICN is not null and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys	then 0	else h.PCP_Flag	end, 0)
				, i.LongDesc
			from pdb_PCPSelection..MbrClass_10	a
			inner join MiniOV..SavvyID_to_SavvyHICN		b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniOV..Fact_Claims				c	on	b.SavvyID = c.SavvyID
			inner join MiniOV..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			inner join MiniOV..Dim_OVA_Provider			e	on	c.Prov_Sys_Id = e.Prov_Sys_Id
			inner join MiniOV..Dim_HP_Service_Type_Code	f	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = f.HLTH_PLN_SRVC_TYP_CD_SYS_ID
			inner join MiniOV..Dim_Service_Type			g	on	c.Srvc_Typ_Sys_Id = g.Srvc_Typ_Sys_Id
			left join #pcpflag							h	on	e.MPIN = h.MPIN
			left join #specialty						i	on	e.MPIN = i.MPIN
			left join #ip_conf							j	on	b.SavvyHICN = j.SavvyHICN
															and c.Dt_Sys_Id between j.Admt_DtSys and j.Discharge_DtSys
			where d.YEAR_NBR = 2014
				and e.MPIN <> 0
				--and a.SavvyHICN = 178
		) a
left join #rxclaims				b	on	a.SavvyHICN = b.SavvyHICN
left join #premium_designation	c	on	a.MPIN = c.MPIN
group by a.SavvyHICN, a.MPIN, TIN, PCP_Flag, LongDesc, EFNCY_FLAG, QLTY_FLAG
--(1322451 row(s) affected); 43.16 minutes
create clustered index cIx_HICN_MPIN on pdb_PCPSelection..Prov_Claims_10_v2 (SavvyHICN, Provider_MPIN);

select *
from pdb_PCPSelection..Prov_Claims_10_v2
where IP_Spend = 0
	and IP_SrvcCnt > 0


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
			select a.*, Prov2 = b.Provider_MPIN, StrtDt2 = b.StartDate, EndDt2 = b.EndDate, OID2 = b.OID
				, Splitter = (case when a.StartDate between b.StartDAte and b.EndDate	then 1	else 0 end)
			from	(	
						select SavvyHICN, Provider_MPIN, StartDate, EndDate, OID = row_number() over (partition by SavvyHICN order by StartDate)
						from pdb_PCPSelection..Prov_Claims_10_v2
						where PCP_Flag = 1
					)	a
			left join (	
						select SavvyHICN, Provider_MPIN, StartDate, EndDate, OID = row_number() over (partition by SavvyHICN order by StartDate)
						from pdb_PCPSelection..Prov_Claims_10_v2
						where PCP_Flag = 1
					) b	on	a.SavvyHICN = b.SavvyHICN
						and a.OID = (b.OID + 1)
		) x
group by SavvyHICN
--(123871 row(s) affected)
create unique clustered index ucIx_HICN on #class (SavvyHICN);


if object_id('tempdb..#memberclass') is not null
drop table #memberclass
go

select a.SavvyHICN
	, Assigned_MPIN		= a.Assigned_MPIN
	, Associated_MPIN	= a.Associated_MPIN
	, Match	= case when a.Assigned_MPIN = a.Associated_MPIN	then 1	else 0	end
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
	, RAF		= isnull(d.TotalRAF, 0)
into #memberclass
from pdb_PCPSelection..MbrClass_10	a
left join #class	b	on	a.SavvyHICN = b.SavvyHICN
left join	(
				select SavvyHICN
					, Total_IP_Spend	= sum(IP_Spend)
					, Total_OP_Spend	= sum(OP_Spend)
					, Total_DR_Spend	= sum(DR_Spend)
					, Total_ER_Spend	= sum(ER_Spend)
					, Total_PCP_Spend	= sum(PCP_Spend)
					, Total_RX_Spend	= max(RX_Spend)
					, Total_IP_SrvcCnt	= sum(IP_SrvcCnt)
					, Total_OP_SrvcCnt	= sum(OP_SrvcCnt)
					, Total_DR_SrvcCnt	= sum(DR_SrvcCnt)
					, Total_ER_SrvcCnt	= sum(ER_SrvcCnt)
					, Total_PCP_SrvcCnt	= sum(PCP_VstCnt)
					, Total_RX_Scripts	= max(RX_Scripts)
				from pdb_PCPSelection..Prov_Claims_10_v2
				group by SavvyHICN
			)	c	on	a.SavvyHICN = c.SavvyHICN
left join pdb_PCPSelection..RA_RAF_2014	d	on	a.SavvyHICN = d.UniqueMemberID
--(155766 row(s) affected); 1.23 hours
create unique clustered index ucIx_HICN on #memberclass (SavvyHICN);

--add weight
if object_id('pdb_PCPSelection..MbrClass_10_v2') is not null
drop table pdb_PCPSelection..MbrClass_10_v2
go

select a.SavvyHICN
	, c.Age
	, c.Gender
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
	, Total_PCP_Spend
	, Total_RX_Spend
	, Total_Spend		= (Total_IP_Spend + Total_OP_Spend + Total_DR_Spend + Total_ER_Spend + Total_RX_Spend)
	, Total_IP_SrvcCnt
	, Total_OP_SrvcCnt
	, Total_DR_SrvcCnt
	, Total_ER_SrvcCnt
	, Total_PCP_SrvcCnt
	, Total_RX_Scripts
	, RAF	
	, ARTIF_OPENINGS_PRESSURE_ULCER		= isnull(d.ARTIF_OPENINGS_PRESSURE_ULCER, 0)
    , ASP_SPEC_BACT_PNEUM_PRES_ULCER	= isnull(d.ASP_SPEC_BACT_PNEUM_PRES_ULCER, 0)
    , CANCER_IMMUNE						= isnull(d.CANCER_IMMUNE				, 0)
    , CHF_COPD							= isnull(d.CHF_COPD						, 0)
    , CHF_RENAL							= isnull(d.CHF_RENAL					, 0)
    , COPD_ASP_SPEC_BACT_PNEUM			= isnull(d.COPD_ASP_SPEC_BACT_PNEUM		, 0)
    , COPD_CARD_RESP_FAIL				= isnull(d.COPD_CARD_RESP_FAIL			, 0)
    , DIABETES_CHF						= isnull(d.DIABETES_CHF					, 0)
    , DISABLED_HCC161					= isnull(d.DISABLED_HCC161				, 0)
    , DISABLED_HCC176					= isnull(d.DISABLED_HCC176				, 0)
    , DISABLED_HCC34					= isnull(d.DISABLED_HCC34				, 0)
    , DISABLED_HCC39					= isnull(d.DISABLED_HCC39				, 0)
    , DISABLED_HCC54					= isnull(d.DISABLED_HCC54				, 0)
    , DISABLED_HCC55					= isnull(d.DISABLED_HCC55				, 0)
    , DISABLED_HCC6						= isnull(d.DISABLED_HCC6				, 0)
    , DISABLED_HCC85					= isnull(d.DISABLED_HCC85				, 0)
    , DISABLED_PRESSURE_ULCER			= isnull(d.DISABLED_PRESSURE_ULCER		, 0)
    , HCC1								= isnull(d.HCC1							, 0)
    , HCC10								= isnull(d.HCC10						, 0)
    , HCC100							= isnull(d.HCC100						, 0)
    , HCC103							= isnull(d.HCC103						, 0)
    , HCC104							= isnull(d.HCC104						, 0)
    , HCC106							= isnull(d.HCC106						, 0)
    , HCC107							= isnull(d.HCC107						, 0)
    , HCC108							= isnull(d.HCC108						, 0)
    , HCC11								= isnull(d.HCC11						, 0)
    , HCC110							= isnull(d.HCC110						, 0)
    , HCC111							= isnull(d.HCC111						, 0)
    , HCC112							= isnull(d.HCC112						, 0)
    , HCC114							= isnull(d.HCC114						, 0)
    , HCC115							= isnull(d.HCC115						, 0)
    , HCC12								= isnull(d.HCC12						, 0)
    , HCC122							= isnull(d.HCC122						, 0)
    , HCC124							= isnull(d.HCC124						, 0)
    , HCC134							= isnull(d.HCC134						, 0)
    , HCC135							= isnull(d.HCC135						, 0)
    , HCC136							= isnull(d.HCC136						, 0)
    , HCC137							= isnull(d.HCC137						, 0)
    , HCC157							= isnull(d.HCC157						, 0)
    , HCC158							= isnull(d.HCC158						, 0)
    , HCC161							= isnull(d.HCC161						, 0)
    , HCC162							= isnull(d.HCC162						, 0)
    , HCC166							= isnull(d.HCC166						, 0)
    , HCC167							= isnull(d.HCC167						, 0)
    , HCC169							= isnull(d.HCC169						, 0)
    , HCC17								= isnull(d.HCC17						, 0)
    , HCC170							= isnull(d.HCC170						, 0)
    , HCC173							= isnull(d.HCC173						, 0)
    , HCC176							= isnull(d.HCC176						, 0)
    , HCC18								= isnull(d.HCC18						, 0)
    , HCC186							= isnull(d.HCC186						, 0)
    , HCC188							= isnull(d.HCC188						, 0)
    , HCC189							= isnull(d.HCC189						, 0)
    , HCC19								= isnull(d.HCC19						, 0)
    , HCC2								= isnull(d.HCC2							, 0)
    , HCC21								= isnull(d.HCC21						, 0)
    , HCC22								= isnull(d.HCC22						, 0)
    , HCC23								= isnull(d.HCC23						, 0)
    , HCC27								= isnull(d.HCC27						, 0)
    , HCC28								= isnull(d.HCC28						, 0)
    , HCC29								= isnull(d.HCC29						, 0)
    , HCC33								= isnull(d.HCC33						, 0)
    , HCC34								= isnull(d.HCC34						, 0)
    , HCC35								= isnull(d.HCC35						, 0)
    , HCC39								= isnull(d.HCC39						, 0)
    , HCC40								= isnull(d.HCC40						, 0)
    , HCC46								= isnull(d.HCC46						, 0)
    , HCC47								= isnull(d.HCC47						, 0)
    , HCC48								= isnull(d.HCC48						, 0)
    , HCC54								= isnull(d.HCC54						, 0)
    , HCC55								= isnull(d.HCC55						, 0)
    , HCC57								= isnull(d.HCC57						, 0)
    , HCC58								= isnull(d.HCC58						, 0)
    , HCC6								= isnull(d.HCC6							, 0)
    , HCC70								= isnull(d.HCC70						, 0)
    , HCC71								= isnull(d.HCC71						, 0)
    , HCC72								= isnull(d.HCC72						, 0)
    , HCC73								= isnull(d.HCC73						, 0)
    , HCC74								= isnull(d.HCC74						, 0)
    , HCC75								= isnull(d.HCC75						, 0)
    , HCC76								= isnull(d.HCC76						, 0)
    , HCC77								= isnull(d.HCC77						, 0)
    , HCC78								= isnull(d.HCC78						, 0)
    , HCC79								= isnull(d.HCC79						, 0)
    , HCC8								= isnull(d.HCC8							, 0)
    , HCC80								= isnull(d.HCC80						, 0)
    , HCC82								= isnull(d.HCC82						, 0)
    , HCC83								= isnull(d.HCC83						, 0)
    , HCC84								= isnull(d.HCC84						, 0)
    , HCC85								= isnull(d.HCC85						, 0)
    , HCC86								= isnull(d.HCC86						, 0)
    , HCC87								= isnull(d.HCC87						, 0)
    , HCC88								= isnull(d.HCC88						, 0)
    , HCC9								= isnull(d.HCC9							, 0)
    , HCC96								= isnull(d.HCC96						, 0)
    , HCC99								= isnull(d.HCC99						, 0)
    , SCHIZOPHRENIA_CHF					= isnull(d.SCHIZOPHRENIA_CHF			, 0)
    , SCHIZOPHRENIA_COPD				= isnull(d.SCHIZOPHRENIA_COPD			, 0)
    , SCHIZOPHRENIA_SEIZURES			= isnull(d.SCHIZOPHRENIA_SEIZURES		, 0)
    , SEPSIS_ARTIF_OPENINGS				= isnull(d.SEPSIS_ARTIF_OPENINGS		, 0)
    , SEPSIS_ASP_SPEC_BACT_PNEUM		= isnull(d.SEPSIS_ASP_SPEC_BACT_PNEUM	, 0)
    , SEPSIS_CARD_RESP_FAIL				= isnull(d.SEPSIS_CARD_RESP_FAIL		, 0)
    , SEPSIS_PRESSURE_ULCER				= isnull(d.SEPSIS_PRESSURE_ULCER		, 0)
into pdb_PCPSelection..MbrClass_10_v2
from #memberclass	a
inner join	(
				select a.SavvyHICN, b.PCP_VstCnt, Percnt = PCP_VstCnt * 1.0 / nullif(Ttl_PCP_Vst, 0) , RN = row_number() over(partition by a.SavvyHICN	order by b.PCP_VstCnt desc)
				from	(
							select a.SavvyHICN, Ttl_PCP_Vst = sum(PCP_VstCnt)
							from #memberclass	a
							left join pdb_PCPSelection..Prov_Claims_10_v2	b	on	a.SavvyHICN = b.SavvyHICN
							group by a.SavvyHICN
						) a
				left join pdb_PCPSelection..Prov_Claims_10_v2	b	on	a.SavvyHICN = b.SavvyHICN
			)	b	on	a.SavvyHICN = b.SavvyHICN
left join	(
				select a.SavvyHICN, c.Age, c.Gender
				from pdb_PCPSelection..MbrClass_10	a
				inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
				inner join MiniOV..Dim_Member			c	on	b.SavvyID = c.SavvyID
			)	c	on	a.SavvyHICN = c.SavvyHICN
left join pdb_PCPSelection..HCC_2014	d	on	a.SavvyHICN = d.UniqueMemberID
where b.RN = 1
--(155766 row(s) affected)
create unique clustered index ucIx_HICN on pdb_PCPSelection..MbrClass_10_v2	(SavvyHICN);


if object_id('pdb_PCPSelection..MbrProv_10_v2') is not null
drop table pdb_PCPSelection..MbrProv_10_v2
go

select a.SavvyHICN, b.Provider_MPIN, b.Provider_TIN, b.PCP_Flag, b.Specialty, b.EFNCY_FLAG, b.QLTY_FLAG
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
into pdb_PCPSelection..MbrProv_10_v2
from pdb_PCPSelection..MbrClass_10_v2			a
left join pdb_PCPSelection..Prov_Claims_10_v2	b	on	a.SavvyHICN = b.SavvyHICN
--(1359044 row(s) affected)

select *--count(distinct SAvvyHICN)	--155766
from  pdb_PCPSelection..MbrProv_10_v2

select count(distinct SAvvyHICN)	--155766
from pdb_PCPSelection..MbrClass_10_v2

/*clean up
drop table pdb_PCPSelection..MbrClass_10
drop table pdb_PCPSelection..MbrProv_10
drop table pdb_PCPSelection..Prov_Claims_10

rename _v2 back to able table names
*/

--date of switch
If (object_id('tempdb..#dateswitch') Is Not Null)
Drop Table #dateswitch
go

select SavvyHICN
	, DateSwitch	= (case when OID = 2	then StartDate	end)
	, SwitchCnt		= (MaxOID - 1)
	, CloseIPConf	= (datediff(dd, StartDate, AdmitDt))
into #dateswitch
from	(	
			select a.SavvyHICN, StartDate = cast(a.StartDate as date), a.OID, AdmitDt = max(case when RN = 1	then b.AdmitDt	end) over(partition by a.SavvyHICN)
				, MaxOID = max(a.OID) over(partition by a.SavvyHICN)
			from	(	
						select SavvyHICN, Provider_MPIN, Specialty, StartDate, EndDate
							, OID = row_number() over(partition by SavvyHICN	order by StartDate)
						from pdb_PCPSelection..MbrProv_10
						where Switcher = 1 
							and PCP_Flag = 1
					) a
			left join	(
							select a.*, AdmitDt = cast(b.FULL_DT as date), RN = row_number() over(partition by a.SavvyHICN	order by a.Admt_DtSys)
							from #ip_conf	a
							inner join MiniOV..Dim_Date	b	on	a.Admt_DtSys = b.DT_SYS_ID
						)	b	on	a.SavvyHICN = b.SavvyHICN	and a.OID = b.RN
			--where a.SavvyHICN = 2484
		) x
where (case when OID = 2	then StartDate	end) is not null
--(22319 row(s) affected)
create unique clustered index ucIx_HICN on #dateswitch (SavvyHICN);

alter table pdb_PCPSelection..MbrClass_10
	add DateSwitch	date
		, SwitchCnt	smallint
		, DaysToFrom_IPConf	int
go

update pdb_PCPSelection..MbrClass_10
set	DateSwitch = b.DateSwitch
	, SwitchCnt = isnull(b.SwitchCnt, 0)
	, DaysToFrom_IPConf = isnull(b.CloseIPConf, 0)
from pdb_PCPSelection..MbrClass_10	a
left join #dateswitch				b	on	a.SavvyHICN = b.SavvyHICN

select *
from pdb_PCPSelection..MbrClass_10


/******************
PCP In/Out of network flags as requested by Dan H. on 06/22/2016

Date: 23 June 2016
******************/
If (object_id('tempdb..#ntwrk_sts') Is Not Null)
Drop Table #ntwrk_sts
go

select a.*, Network_Flag = case when b.ProvStatus = 'P'	then 1	else 0	end
into #ntwrk_sts
from	(--240907	
			select distinct Provider_MPIN
			from pdb_PCPSelection..MbrProv_10
		)	a
inner join NDB..Provider	b	on	a.Provider_MPIN = b.MPIN
--(240792 row(s) affected); 115 lost MPIN
create unique clustered index ucIx_MPIN on #ntwrk_sts (Provider_MPIN);

/* test query
select distinct a.Provider_MPIN, c.FULL_NM
from	(	
			select distinct a.Provider_MPIN
			from	(
						select distinct Provider_MPIN
						from pdb_PCPSelection..MbrProv_10
					)	a
			left join NDB..Provider	b	on	a.Provider_MPIN = b.MPIN
			where b.MPIN is null
		) a
inner join MiniOV..Dim_OVA_Provider	c	on	a.Provider_MPIN = c.MPIN
where Provider_MPIN is not null
*/

alter table pdb_PCPSelection..MbrProv_10
	add Network_Flag	smallint
go

update pdb_PCPSelection..MbrProv_10
set Network_Flag = isnull(b.Network_Flag, 0)
from pdb_PCPSelection..MbrProv_10	a
left join #ntwrk_sts				b	on	a.Provider_MPIN = b.Provider_MPIN

/* test queries
select *
from pdb_PCPSelection..MbrClass_10
where SavvyHICN = 2286

select *
from pdb_PCPSelection..MbrClass_10_2015
where SavvyHICN = 2286
*/


/******************
Add OOP amounts & plan contracts as requested by Dan H. on 06/28/2016

Date: 29 June 2016
******************/
If (object_id('tempdb..#OOP') Is Not Null)
Drop Table #OOP
go

select SavvyHICN, Total_OOP = sum(Total_OOP)
into #OOP
from	(--medical claims
			select b.SavvyHICN, Total_OOP = sum(c.OOP_Amt)
			from pdb_PCPSelection..MbrClass_10	a
			inner join MiniOV..SavvyID_to_SavvyHICN		b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniOV..Fact_Claims				c	on	b.SavvyID = c.SavvyID
			inner join MiniOV..Dim_Date					d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			where d.YEAR_NBR = 2014
			group by b.SavvyHICN
			
			union all
		 --rx claims
			select b.SavvyHICN, Total_OOP = sum(c.Patient_Pay_Amount)
			from pdb_PCPSelection..MbrClass_10	a
			inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
			inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
			where c.Claim_Status <> 'X'
				and d.YEAR_NBR = 2014
			group by b.SavvyHICN
		) z
group by SavvyHICN
--(150341 row(s) affected)
create unique clustered index ucIx_HICN on #OOP (SavvyHICN);


alter table pdb_PCPSelection..MbrClass_10
	add Total_OOP	decimal(38,2)
go

update pdb_PCPSelection..MbrClass_10
set Total_OOP = isnull(b.Total_OOP, 0)
from pdb_PCPSelection..MbrClass_10	a
left join #OOP						b	on	a.SavvyHICN = b.SavvyHICN

select * from pdb_PCPSelection..MbrClass_10