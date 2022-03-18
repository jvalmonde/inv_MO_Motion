/* Create AMI members drug usage data set to measure adherence. 
   We used the datasets for GP 1062 */






select mbr.SavvyID, OVId.SavvyHICN, Gender, Age
into #Mbrs   
from MiniOV..Dim_Member        					mbr
inner join MiniOV..SavvyID_to_SavvyHICN			OVId	on  mbr.SavvyID = ovId.SavvyID
inner join MiniPAPI..SavvyID_to_SavvyHICN		pp		on	OVId.SavvyHICN = pp.SavvyHICN	--to ensure we have PAPI data
where MAPDFlag = 1 
	and MedicaidFlag = 0
	and Src_Sys_Cd = 'CO'
	and (MM_2012 > 0 or MM_2013 > 0 or MM_2014 > 0 or MM_2015 > 0 or MM_2016 > 0)
group by mbr.SavvyID, OVId.SavvyHICN, Gender, Age
-- 3,789,293
-- 1,122,745
-- 1,627,248 (only 2015)


create unique index uIx_SavvyHICN on #Mbrs (SavvyHICN);

--Get AMI disgnosis codes

Select Distinct DIAG_CD_SYS_ID,
	 AHRQ_DIAG_DTL_CATGY_NM,
	 DIAG_DECM_CD
Into #DiagAMI
From MiniOV..Dim_Diagnosis_Code
Where DIAG_DECM_CD in ('410','410.01','410.02','410.1','410.1','410.11','410.12','410.2'	
					,'410.2','410.21','410.22','410.3','410.3','410.31'	,'410.32','410.4','410.4'	
					,'410.41','410.42','410.5','410.5','410.51','410.52','410.6','410.6','410.61'	
					,'410.62','410.7','410.7','410.71','410.72','410.8'	,'410.8','410.81','410.82'	
					,'410.9','410.9','410.91','410.92','I21','I21.0','I21.01','I21.02','I21.09'	
					,'I21.1','I21.11','I21.19','I21.2','I21.21','I21.29','I21.3','I21.4','I22'	
					,'I22.0','I22.1','I22.2','I22.8','I22.9')


				
---  Members with AMI

select SavvyID, 
	   SavvyHICN,
	   Age,
	   Gender,
		min(Full_Dt) FstDiagDt
into  pdb_PharmaMotion..AMI_Members_5yrs
from 

(
Select  fc.SavvyID,
	  mbr.SavvyHICN,
	  Age,
	  Gender,
	  Clm_Aud_Nbr,
	  Full_dt

from #Mbrs										mbr
join MiniOV..Fact_Claims						fc  on mbr.SavvyID			=	fc.SavvyID
join MiniOV..Dim_Date							dd	on dd.Dt_Sys_Id			=	fc.Dt_Sys_Id
join MiniOV..Dim_Diagnosis_Code					d1	on d1.DIAG_CD_SYS_ID	=	fc.Diag_1_Cd_Sys_Id	
join MiniOV..Dim_Diagnosis_Code					d2	on d2.DIAG_CD_SYS_ID	=	fc.Diag_2_Cd_Sys_Id
join MiniOV..Dim_Diagnosis_Code					d3	on d3.DIAG_CD_SYS_ID	=	fc.Diag_3_Cd_Sys_Id
where  dd.YEAR_NBR	in 	(2012,2013, 2014, 2015, 2016) and 

(d1.DIAG_DECM_CD in ('410','410.01','410.02','410.1','410.1','410.11','410.12','410.2'	
					,'410.2','410.21','410.22','410.3','410.3','410.31'	,'410.32','410.4','410.4'	
					,'410.41','410.42','410.5','410.5','410.51','410.52','410.6','410.6','410.61'	
					,'410.62','410.7','410.7','410.71','410.72','410.8'	,'410.8','410.81','410.82'	
					,'410.9','410.9','410.91','410.92','I21','I21.0','I21.01','I21.02','I21.09'	
					,'I21.1','I21.11','I21.19','I21.2','I21.21','I21.29','I21.3','I21.4','I22'	
					,'I22.0','I22.1','I22.2','I22.8','I22.9') 
					or d2.DIAG_DECM_CD in ('410','410.01','410.02','410.1','410.1','410.11','410.12','410.2'	
					,'410.2','410.21','410.22','410.3','410.3','410.31'	,'410.32','410.4','410.4'	
					,'410.41','410.42','410.5','410.5','410.51','410.52','410.6','410.6','410.61'	
					,'410.62','410.7','410.7','410.71','410.72','410.8'	,'410.8','410.81','410.82'	
					,'410.9','410.9','410.91','410.92','I21','I21.0','I21.01','I21.02','I21.09'	
					,'I21.1','I21.11','I21.19','I21.2','I21.21','I21.29','I21.3','I21.4','I22'	
					,'I22.0','I22.1','I22.2','I22.8','I22.9') 
					or d3.DIAG_DECM_CD in ('410','410.01','410.02','410.1','410.1','410.11','410.12','410.2'	
					,'410.2','410.21','410.22','410.3','410.3','410.31'	,'410.32','410.4','410.4'	
					,'410.41','410.42','410.5','410.5','410.51','410.52','410.6','410.6','410.61'	
					,'410.62','410.7','410.7','410.71','410.72','410.8'	,'410.8','410.81','410.82'	
					,'410.9','410.9','410.91','410.92','I21','I21.0','I21.01','I21.02','I21.09'	
					,'I21.1','I21.11','I21.19','I21.2','I21.21','I21.29','I21.3','I21.4','I22'	
					,'I22.0','I22.1','I22.2','I22.8','I22.9') )
) x

group by SavvyID, 
	   SavvyHICN,
	   Age,
	   Gender
-- 118,916

create unique clustered index uix_id on   pdb_PharmaMotion..AMI_Members_5yrs(SavvyHICN)

-- Get enrollment months after their first AMI diagnosis

select SavvyHICN, 
       fmc.SavvyID, 
      (left(convert(varchar(7), FstDiagDt, 126),4)+ right(convert(varchar(7), FstDiagDt, 126),2)) as AMIFstYrMo,
       fmc.Year_Mo, MAPDFlag, MedicaidFlag, Src_Sys_Cd
into  #enrollment
from pdb_PharmaMotion..AMI_Members_5yrs  mbr
join MiniOV..Fact_MemberContract         fmc on mbr.SavvyId = fmc.SavvyID
where (Year_Mo) >= (left(convert(varchar(7), FstDiagDt, 126),4)+ right(convert(varchar(7), FstDiagDt, 126),2)) 
and left(Year_Mo, 4) in (2012, 2013, 2014, 2015, 2016)
-- 1,753,343

create clustered index uix_id on  #enrollment (SavvyHICN, Year_Mo)

select SavvyHICN, min(Year_Mo) DisenrollYrMo
into #disenrollYrMo
from #enrollment
where  Src_Sys_Cd <> 'CO' --or MedicaidFlag = 1
group by SavvyHICN
--821

select SavvyHICN, min(Year_Mo) MAPDYrMo
into #MAPDYrMo
from #enrollment
where  Src_Sys_Cd = 'CO' and MAPDFlag = 0
group by SavvyHICN
-- 522


select enrl.SavvyHICN,
       SavvyID,
	   AMIFstYrMo,
	   max(Year_Mo) DisenrlYrMo,
	   min(case when Src_Sys_Cd <> 'CO' then DisenrollYrMo else NULL end) as NonCOYrMo,
	   min(case when Src_Sys_Cd = 'CO' and MAPDFlag = 0 then Year_Mo else NULL end) as NonMAPDYrMo
into #enrlYrMo
from #enrollment   enrl
left join #disenrollYrMo disenrl    on enrl.SavvyHICN = disenrl.SavvyHICN
group by enrl.SavvyHICN,
       SavvyID,
	   AMIFstYrMo
-- 118,883


select mbr.*,
       AMIFstYrMo,
	   case when NonCOYrMo < DisenrlYrMo then 
	   (left(convert(varchar(7), dateadd(month, -1, NonCOYrMo+'01'), 126),4)+ right(convert(varchar(7), dateadd(month, -1, NonCOYrMo+'01'), 126),2))  else DisenrlYrMo end as DisenrlYrMo,
	   
	   NonMAPDYrMo
into pdb_PharmaMotion..AMI_Members_5yrs_enrl
from pdb_PharmaMotion..AMI_Members_5yrs mbr
join #enrlYrMo                          enrl on mbr.SavvyHICN = enrl.SavvyHICN 


create unique clustered index uix_id on  pdb_PharmaMotion..AMI_Members_5yrs_enrl (SavvyHICN)

alter table pdb_PharmaMotion..AMI_Mbrs_5yrs 
	add Enrl_Mnths int
		
update pdb_PharmaMotion..AMI_Mbrs_5yrs 
set Enrl_Mnths = DATEDIFF(month,AMIFstYrMo+'01', DisenrlYrMo+'01')


--- Compute days supply to measure adherence
select *
	, Gaps = datediff(dd, FULL_DT, lead(FULL_DT, 1) over(partition by SavvyHICN, EXT_AHFS_THRPTC_CLSS_DESC order by OID))
into #DaySupply
from	(
			select mbr.SavvyHICN, 
			       EXT_AHFS_THRPTC_CLSS_DESC,
				   fc.Day_Supply,
				    ddt.FULL_DT, 
					ddt.YEAR_MO
				, OID = row_number() over(partition by mbr.SavvyHICN, EXT_AHFS_THRPTC_CLSS_DESC order by ddt.FULL_DT)
			--select count(distinct a.SavvyHICN)	--162,281
            from  pdb_PharmaMotion..AMI_Members_5yrs_enrl      mbr	
			join MiniPAPI..SavvyID_to_SavvyHICN				   papiID	on mbr.SavvyHICN = papiID.SavvyHICN
			join MiniPAPI..Fact_Claims							fc		on papiID.SavvyID = fc.SavvyId
			join MiniPAPI..Dim_Date								ddt		on ddt.DT_SYS_ID	= fc.Date_Of_Service_DtSysId
			Join MiniPAPI..Dim_Drug								drug	on fc.Drug_Sys_Id = drug.Drug_Sys_ID
			join MiniHPDM..Dim_NDC_Drug							dnd		on	drug.Product_Service_ID = dnd.NDC
		
			where ddt.YEAR_NBR	in (2012, 2013, 2014, 2015, 2016)
			    and ddt.FULL_DT >= FstDiagDt 
				and ddt.YEAR_MO <= DisenrlYrMo
				and Claim_Status = 'P'
			--	and mbr.SavvyHICN = 4111678
				and EXT_AHFS_THRPTC_CLSS_DESC in ('BETA-ADRENERGIC BLOCKING AGENTS',
													'HMG-COA REDUCTASE INHIBITORS',
													'PLATELET-AGGREGATION INHIBITORS',
													'ANGIOTENSIN-CONVERTING ENZYME INHIBITORS',
													'LOOP DIURETICS')
			group by mbr.SavvyHICN, 
			       EXT_AHFS_THRPTC_CLSS_DESC,
				   fc.Day_Supply,
				    ddt.FULL_DT, 
					ddt.YEAR_MO
			
		) x
-- 2,517,656

create index Ix_SavvyHICN_AHFS on #DaySupply (SavvyHICN, EXT_AHFS_THRPTC_CLSS_DESC);
select * from #DaySupply where SavvyHICN = 4111678


select a.SavvyHICN, a.EXT_AHFS_THRPTC_CLSS_DESC
	, Adherence = (Ttl_DaySupply - b.Day_Supply)*1.0 / nullif(Ttl_Gaps, 0)
into  pdb_PharmaMotion..AMI_Mbrs_5yrs_Adherence
from	(
			select SavvyHICN, EXT_AHFS_THRPTC_CLSS_DESC
				, Ttl_DaySupply = sum(Day_Supply)
				, Max_OID =	 max(OID)
				, Ttl_Gaps = sum(Gaps)
			from #DaySupply
		--	where SavvyHICN = 4111678
		    group by SavvyHICN, EXT_AHFS_THRPTC_CLSS_DESC
		) a
join #DaySupply			b	on	a.SavvyHICN = b.SavvyHICN
							and a.EXT_AHFS_THRPTC_CLSS_DESC = b.EXT_AHFS_THRPTC_CLSS_DESC
							and Max_OID = b.OID
-- 296,491


create unique index uIx_SavvyHICN_AHFS on pdb_PharmaMotion..AMI_Mbrs_5yrs_Adherence(SavvyHICN, EXT_AHFS_THRPTC_CLSS_DESC)

--pull for the utilization


select mbr.SavvyHICN,
	  ddt.YEAR_MO,
	  RX_Spend = sum(fc.Allowed),
	  Cnt_NDC = count(distinct drug.NDC)
into #rxclaims
from  pdb_PharmaMotion..AMI_Members_5yrs_enrl     mbr
join MiniPAPI..SavvyID_to_SavvyHICN				  papiID	on mbr.SavvyHICN = papiID.SavvyHICN
join MiniPAPI..Fact_Claims						  fc		on papiID.SavvyID = fc.SavvyId
join MiniPAPI..Dim_Date							  ddt		on ddt.DT_SYS_ID	= fc.Date_Of_Service_DtSysId
Join MiniPAPI..Dim_Drug							  drug		on fc.Drug_Sys_Id = drug.Drug_Sys_ID
join MiniHPDM..Dim_NDC_Drug						  dnd		on	drug.Product_Service_ID = dnd.NDC
where  ddt.YEAR_NBR	in (2012, 2013, 2014, 2015, 2016)
 and ddt.FULL_DT >= FstDiagDt 
 and ddt.YEAR_MO <= DisenrlYrMo
 and Claim_Status = 'P'
group by mbr.SavvyHICN,
		 ddt.YEAR_MO
-- 1,460,356
create unique clustered index ucIx_SavvyHICN_YearMo on #rxclaims (SavvyHICN, YEAR_MO);



select SavvyHICN, 
       SavvyID,
	   Dt_Sys_Id,
	   Full_Dt
--into #test
into #ip_days
from
(
select mbr.SavvyHICN,
       fc.SavvyID,
	   Admit_DtSys		= dd.DT_SYS_ID,
	   Discharge_DtSys	= dd1.DT_SYS_ID,
	   Conf_ID			= row_number() over (partition by mbr.SavvyHICN	order by dd.Dt_Sys_ID)
--into #ip_conf
from pdb_PharmaMotion..AMI_Members_5yrs_enrl	mbr
join MiniOV..SavvyID_to_SavvyHICN				OVID	on	mbr.SavvyHICN = OVID.SavvyHICN
join MiniOV..Fact_Claims						fc		on	OVID.SavvyID  =	fc.SavvyID
join MiniOV..Dim_Date							dd		on	fc.Dt_Sys_Id  =	dd.Dt_Sys_ID	--admit
join MiniOV..Dim_Date						   dd1		on	(fc.Dt_Sys_Id + fc.Day_Cnt) = dd1.DT_SYS_ID	--discharge
where dd.YEAR_NBR	in (2012, 2013, 2014, 2015, 2016)
 and dd.FULL_DT >= FstDiagDt 
 and dd1.YEAR_MO <= DisenrlYrMo
	and fc.Admit_Cnt = 1
group by mbr.SavvyHICN,
		 fc.SavvyID, 
		 dd.DT_SYS_ID,
		 dd1.DT_SYS_ID
--214518
)x 
join MiniOV..Dim_Date  y  on y.DT_SYS_ID between Admit_DtSys and Discharge_DtSys
group by SavvyHICN, 
       SavvyID,
	   Dt_Sys_Id,
	   Full_Dt
-- 391,599
create unique index uIx_SavvyID_DtSys on #ip_days (SavvyHICN, SavvyID, DT_SYS_ID);

select *
from #ip_days
where SavvyHICN = 14280961
order by Full_Dt





select b.SavvyHICN
	, b.YEAR_MO
	, IP_Spend = sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	end)
	, OP_Spend = sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	end)
	, DR_Spend = sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	end)
	, ER_Spend = sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	end)
	, DME_Spend = sum(case when AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'	then Allw_Amt	end)
	, RX_Spend = max(isnull(c.RX_Spend, 0))
	, IP_visits = count(distinct case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Dt_Sys_ID end)
	, OP_visits = count(distinct case when Derived_Srvc_Type_cd = 'OP' 						then Dt_Sys_ID end)
	, DR_visits = count(distinct case when Derived_Srvc_Type_cd = 'DR' 						then Dt_Sys_ID end)
	, ER_visits = count(distinct case when Derived_Srvc_Type_cd = 'ER' 						then Dt_Sys_ID end)
	, Cnt_DME	= count(distinct case when AHRQ_PROC_DTL_CATGY_DESC = 'DME AND SUPPLIES'	then Dt_Sys_ID end)
	, Cnt_NDC	= max(isnull(c.Cnt_NDC, 0))
	, Total_IP_Days = sum(case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Day_Cnt end)
into  pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM
from 	
(
select a.SavvyHICN, c.*,
	Derived_Srvc_Type_cd = case when h.SavvyID is not null and f.Srvc_Typ_Cd <> 'IP'		then 'IP'  
								when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'	else 	f.Srvc_Typ_Cd	end,
	d.YEAR_MO, d.Full_Dt,
	g.AHRQ_PROC_DTL_CATGY_DESC
--into #Claims
from pdb_PharmaMotion..AMI_Members_5yrs_enrl	        a
join MiniOV..SavvyID_to_SavvyHICN						b	on	a.SavvyHICN = b.SavvyHICN
join MiniOV..Fact_Claims								c	on	b.SavvyID = c.SavvyId
join MiniOV..Dim_Date									d	on	c.Dt_Sys_Id = d.DT_SYS_ID
join MiniOV..Dim_HP_Service_Type_Code					e	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = e.HLTH_PLN_SRVC_TYP_CD_SYS_ID
join MiniOV..Dim_Service_Type							f	on	c.Srvc_Typ_Sys_Id = f.Srvc_Typ_Sys_Id
join MiniOV..Dim_Procedure_Code							g	on	c.Proc_Cd_Sys_Id = g.PROC_CD_SYS_ID
left join #ip_days										h	on	b.SavvyID = h.SavvyID
															and c.Dt_Sys_Id = h.DT_SYS_ID

where  d.YEAR_NBR	in (2012, 2013, 2014, 2015, 2016)
 and d.FULL_DT >= FstDiagDt 
 and d.YEAR_MO <= DisenrlYrMo
) b
left join #rxclaims		c	on	b.SavvyHICN = c.SavvyHICN
							and b.YEAR_MO = c.YEAR_MO
group by b.SavvyHICN,
         b.YEAR_MO
-- 1,333,901
create unique clustered index ucIx_SavvyHICN_YearMo on pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM (SavvyHICN, YEAR_MO);

alter table pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM 
	add Total_Spend	decimal(38,2)
		
update pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM 
set Total_Spend = (isnull(IP_Spend, 0) + isnull(OP_Spend, 0) + isnull(DR_Spend, 0) + isnull(ER_Spend, 0) + isnull(DME_Spend, 0) + isnull(RX_Spend, 0))
	



update  pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM 
set IP_Spend							= isnull(IP_Spend, 0)	
	, OP_Spend							= isnull(OP_Spend, 0)	
	, DR_Spend							= isnull(DR_Spend, 0)	
	, ER_Spend							= isnull(ER_Spend, 0)	
	, DME_Spend							= isnull(DME_Spend, 0)	
	, RX_Spend							= isnull(RX_Spend, 0)	
	
	, IP_visits							= isnull(IP_visits	, 0)
	, OP_visits							= isnull(OP_visits	, 0)
	, DR_visits							= isnull(DR_visits	, 0)
	, ER_visits							= isnull(ER_visits	, 0)
	, Cnt_DME							= isnull(Cnt_DME	, 0)
	, Cnt_NDC							= isnull(Cnt_NDC	, 0)
	, Total_IP_Days						= isnull(Total_IP_Days, 0)

	
	---- create a table with 60 rows for each member
	select distinct Year_Mo
	into #months
	from MIniOV..Dim_Date
	where YEAR_NBR in (2012, 2013, 2014, 2015, 2016)



	select distinct SavvyHICN, YEAR_MO
	into  #MbrYrMo
	from pdb_PharmaMotion..AMI_Members_5yrs_enrl	a
	cross join #months								b



select	a.*,
		IP_Spend,						
		OP_Spend,	
		DR_Spend,		
		ER_Spend,
		DME_Spend,	
		RX_Spend,			
		IP_visits,					
		OP_visits,						
		DR_visits,							
		ER_visits,							
		Cnt_DME,							
		Cnt_NDC,							
		Total_IP_Days,
		Total_Spend						
into pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM_v1
from #MbrYrMo									               a
left join pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM    b on a.YEAR_MO = b.YEAR_MO and a.SavvyHICN = b.SavvyHICN


create unique clustered index uix_id on  pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM_v1 (SavvyHICN, Year_Mo)

select *
from pdb_PharmaMotion..AMI_Members_5yrs_utilizationYM_v1
	