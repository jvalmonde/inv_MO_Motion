
SELECT distinct mbr.SavvyID, SavvyHICN, Gender, Age-1 as [Age_2016]
 into  #Mbrs   
  FROM MiniOV..Dim_Member        					mbr
 join MiniOV..SavvyID_to_SavvyHICN					OVId   on  mbr.SavvyID = ovId.SavvyID
 where MAPDFlag = 1 
  and MedicaidFlag = 0
  and Src_Sys_Cd = 'CO'
  and MM_2016 = 12
  group by mbr.SavvyID, SavvyHICN, Gender, Age-1 
  
 -- 2,176,251

create unique clustered index uix_id on #Mbrs(SavvyHICN)

select mbr.SavvyHICN, Gender, [Age_2016], papi.SavvyID as PapiID
into  #PapiMbrs
from #Mbrs								mbr
join MiniPAPI..SavvyID_to_SavvyHICN     Papi on  mbr.SavvyHICN = Papi.SavvyHICN
--- 2,173,266



create unique clustered index uix_id on #PapiMbrs(PapiID)


select  mbr.SavvyHICN,
        age_2016,
		case when Age_2016 < 65 then '<65'
		     when Age_2016 between 65 and 74 then '65-74'
			 when Age_2016 between 75 and 84 then '75-84'
			 else '85+' end    as Age,
		Gender,
		FULL_DT,
		Savvy_Claim_Number,
		Product_Service_ID,
		Day_Supply, 
		Generic_Product_Index,
		AHFS_Code,
		Fill_Number,
		 Num_Refills_Authorized,
		 NPI
into pdb_PharmaMotion..G1097RxClaims
from #PapiMbrs					mbr
join MiniPAPI..Fact_Claims		fc		on mbr.PapiID								= fc.SavvyId
join MiniPAPI..Dim_Date			dd		on fc.Date_Of_Service_DtSysId				= dd.DT_SYS_ID
join MiniPAPI..Dim_Drug			drg		on fc.Drug_Sys_Id							= drg.Drug_Sys_ID
join MiniPAPI..Dim_Prescriber	dp		on fc.Prescriber_Sys_Id                     = dp.Prescriber_Sys_Id
left join NPI..NPI				npi		on dp.Prescriber_ID							= cast(npi.npi as varchar)
--join MiniHPDM..Dim_NDC_Drug ndrg	on ltrim(rtrim(drg.Product_Service_ID))		= ltrim(rtrim(ndrg.NDC))
	where YEAR_MO in (201610, 201611, 201612)
	and Maint_Drug_Code = 'X'
	and [Claim_Status] = 'P'
--- 15,427,277

create clustered index uix_id on pdb_PharmaMotion..G1097RxClaims (SavvyHICN, FULL_DT, Product_Service_ID)




select *, case when datepart(Month,ScriptThruDt) = 12 then 1 else 0 end as Flag
--into pdb_PharmaMotion..G1097ClaimsScriptThruDt
from 
(
select *, ScriptThruDt = Dateadd(day, Day_Supply, Full_Dt)
from pdb_PharmaMotion..G1097RxClaims
)x
where SavvyHICN = 18468040
order by ScriptThruDt

create clustered index uix_id on pdb_PharmaMotion..G1097ClaimsScriptThruDt (SavvyHICN, FULL_DT, Product_Service_ID)



select Day_Supply, count(distinct Savvy_Claim_Number) claims --- about 99.95% claims
from pdb_PharmaMotion..G1097ClaimsScriptThruDt
group by Day_Supply
order by 1 

--------- Characterize member population 

select  SavvyHICN, 
		 Age, 
		 Gender,
		 count(distinct NPI) CntProvs,
	--	count(distinct ltrim(rtrim(Product_Service_ID))) CntNDC,
		--count(distinct ltrim(rtrim(Generic_Product_Index))) CntGPI,
		count(distinct ltrim(rtrim(AHFS_Code))) CntAHFS
into  #drugCnts
from pdb_PharmaMotion..G1097ClaimsScriptThruDt a
where Flag = 1 --and Fill_Number >=  Num_Refills_Authorized                    -- 2,830,331
group by  SavvyHICN, 
		   Age,
		    Gender
-- 1,063,624


select count(distinct SavvyHICN)              --- 783,359
from  pdb_PharmaMotion..G1097ClaimsScriptThruDt
where SavvyHICN not in (select SavvyHICN from #drugCnts)




--- Age group


select AgeGrp, 
      cast((count(distinct case when CntAHFS is NULL then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '0AHFS',
      cast((count(distinct case when CntAHFS=1 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '1AHFS',
	 -- avg(case when CntAHFS=1 then CntNDC else NULL end) over(partition by SavvyHICN) as '1AHFS_NDC',
	   cast((count(distinct case when CntAHFS=2 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '2AHFS',
	   cast((count(distinct case when CntAHFS=3 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '3AHFS',
	   cast((count(distinct case when CntAHFS=4 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '4AHFS',
	   cast((count(distinct case when CntAHFS=5 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '5AHFS',
	  cast((count(distinct case when CntAHFS>5 then  SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
	--   cast((count(distinct case when CntAHFS>6 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
from
(
select mbr.*, CntAHFS
from pdb_PharmaMotion..G1097Members mbr
--left join #drugCnts                 Rx  on mbr.SavvyHICN = Rx.SavvyHICN
) x
group by AgeGrp
order by 1


--- Gender


select Gender, 
      cast((count(distinct case when CntAHFS is NULL then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '0AHFS',
      cast((count(distinct case when CntAHFS=1 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '1AHFS',
	 -- avg(case when CntAHFS=1 then CntNDC else NULL end) over(partition by SavvyHICN) as '1AHFS_NDC',
	   cast((count(distinct case when CntAHFS=2 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '2AHFS',
	   cast((count(distinct case when CntAHFS=3 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '3AHFS',
	   cast((count(distinct case when CntAHFS=4 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '4AHFS',
	   cast((count(distinct case when CntAHFS=5 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '5AHFS',
	  cast((count(distinct case when CntAHFS>5 then  SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
	--   cast((count(distinct case when CntAHFS>6 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
from
(
select mbr.*, CntAHFS
from pdb_PharmaMotion..G1097Members mbr
left join #drugCnts                 Rx  on mbr.SavvyHICN = Rx.SavvyHICN
) x
group by Gender
order by 1

--rerun scripts
--excluding NULL & UNK AHFS
select count(*) from pdb_PharmaMotion..G1097Members	--2,173,266

select AgeGrp
	, AHFS_0 = count(distinct case when Cnt_AHFS_201612 = 0	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_1 = count(distinct case when Cnt_AHFS_201612 = 1	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_2 = count(distinct case when Cnt_AHFS_201612 = 2	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_3 = count(distinct case when Cnt_AHFS_201612 = 3	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_4 = count(distinct case when Cnt_AHFS_201612 = 4	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, [AHFS_5+] = count(distinct case when Cnt_AHFS_201612 >= 5	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	--, [AHFS_6+] = count(distinct case when Cnt_AHFS_201612 >= 6	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
from pdb_PharmaMotion..G1097Members	--
group by AgeGrp
order by 1

select Gender
	, AHFS_0 = count(distinct case when Cnt_AHFS_201612 = 0	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_1 = count(distinct case when Cnt_AHFS_201612 = 1	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_2 = count(distinct case when Cnt_AHFS_201612 = 2	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_3 = count(distinct case when Cnt_AHFS_201612 = 3	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_4 = count(distinct case when Cnt_AHFS_201612 = 4	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	, AHFS_5 = count(distinct case when Cnt_AHFS_201612 >= 5	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
	--, [AHFS_6+] = count(distinct case when Cnt_AHFS_201612 >= 6	then SavvyHICN	end) * 100.0 / (select count(*) from pdb_PharmaMotion..G1097Members)
from pdb_PharmaMotion..G1097Members	--
group by Gender


-- Unique provider(NPI)

select case when CntProvs = 1 then '1'
		     when CntProvs = 2 then '2'
			 when CntProvs = 3 then '3'
			 when CntProvs = 4 then '4'
			 when CntProvs = 5 then '5'
			 else '5+' end    as ProvGrp, 
      cast((count(distinct case when CntAHFS=1 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '1AHFS',
	   cast((count(distinct case when CntAHFS=2 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '2AHFS',
	   cast((count(distinct case when CntAHFS=3 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '3AHFS',
	   cast((count(distinct case when CntAHFS=4 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '4AHFS',
	   cast((count(distinct case when CntAHFS=5 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '5AHFS',
	  cast((count(distinct case when CntAHFS>5 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
	--   cast((count(distinct case when CntAHFS>6 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
from #drugCnts
group by case when CntProvs = 1 then '1'
		     when CntProvs = 2 then '2'
			 when CntProvs = 3 then '3'
			 when CntProvs = 4 then '4'
			 when CntProvs = 5 then '5'
			 else '5+' end  
order by 1


--added: 07/11/2017
select a.SavvyHICN, a.Cnt_AHFS_201612
	, Prov_Cnt = count(distinct g.Prescriber_ID)
into #mbr_provcnt
from pdb_PharmaMotion..G1097Members	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
inner join MiniPAPI..Dim_Drug				e	on	c.Drug_Sys_Id = e.Drug_Sys_ID
inner join MiniHPDM..Dim_Drug_Class			f	on	e.Product_Service_ID = f.NDC
inner join MiniPAPI..Dim_Prescriber			g	on	c.Prescriber_Sys_Id = g.Prescriber_Sys_ID
where d.YEAR_MO in (201610, 201611, 201612)
	and c.Claim_Status = 'P'
	and e.Maint_Drug_Code = 'X'
	and (f.AHFS_Therapeutic_Clss_Desc is not null
	and f.AHFS_Therapeutic_Clss_Desc <> 'UNKNOWN')
	and (case when datepart(month, dateadd(dd, c.Day_Supply, d.FULL_DT)) = 12	then 1	else 0	end) = 1
group by a.SavvyHICN, a.Cnt_AHFS_201612
--(744,726 row(s) affected); 15.27 minutes
create unique index uIx_SavvyHICN on #mbr_provcnt (SavvyHICN);

select Mbr_AHFSCatgy = case when Cnt_AHFS_201612 = 1	then 'AHFS_1'
							when Cnt_AHFS_201612 = 2	then 'AHFS_2'
							when Cnt_AHFS_201612 = 3	then 'AHFS_3'
							when Cnt_AHFS_201612 = 4	then 'AHFS_4'
							when Cnt_AHFS_201612 >= 5	then 'AHFS_5+'	
							end	
	, Prov_Cnt1 = count(distinct case when Prov_Cnt = 1	then SavvyHICN	end) *100.0 / count(distinct SavvyHICN)
	, Prov_Cnt2 = count(distinct case when Prov_Cnt = 2	then SavvyHICN	end) *100.0 / count(distinct SavvyHICN)
	, Prov_Cnt3 = count(distinct case when Prov_Cnt = 3	then SavvyHICN	end) *100.0 / count(distinct SavvyHICN)
	, Prov_Cnt4 = count(distinct case when Prov_Cnt = 4	then SavvyHICN	end) *100.0 / count(distinct SavvyHICN)
	, Prov_Cnt5 = count(distinct case when Prov_Cnt >= 5 then SavvyHICN	end) *100.0 / count(distinct SavvyHICN)
	--, [Prov_Cnt6+] = count(distinct case when Prov_Cnt >= 6	then SavvyHICN	end) *100.0 / count(distinct SavvyHICN)
	, Mbr_Cnt = count(distinct SavvyHICN)
from pdb_PharmaMotion..G1097Members
--where Cnt_AHFS_201612 = 1
group by case when Cnt_AHFS_201612 = 1	then 'AHFS_1'
							when Cnt_AHFS_201612 = 2	then 'AHFS_2'
							when Cnt_AHFS_201612 = 3	then 'AHFS_3'
							when Cnt_AHFS_201612 = 4	then 'AHFS_4'
							when Cnt_AHFS_201612 >= 5	then 'AHFS_5+'	
							end	
order by 1


alter table pdb_PharmaMotion..G1097Members
	add Prov_Cnt smallint
go

select Prov_Cnt, count(distinct SavvyHICN)
from pdb_PharmaMotion..G1097Members
where Cnt_AHFS_201612 = 4
group by Prov_Cnt
order by 1

update pdb_PharmaMotion..G1097Members
set Prov_Cnt = b.Prov_Cnt
from pdb_PharmaMotion..G1097Members	a
left join #mbr_provcnt				b	on	a.SavvyHICN = b.SavvyHICN

-- Pull primary Dx for members w/ Rx claims
select mbr.*,
		FULL_DT,
		Clm_Aud_Nbr,
	   DIAG_CD,
	   Diag_Desc,
	   AHRQ_DIAG_GENL_CATGY_NM,
       AHRQ_DIAG_DTL_CATGY_NM
into  pdb_PharmaMotion..Claims
from pdb_PharmaMotion..G1097Members					mbr
join MiniOV..SavvyID_to_SavvyHICN					OVId	on  mbr.SavvyHICN = ovId.SavvyHICN
join MiniOV..Fact_Claims							fc		on  ovID.SavvyID = fc.SavvyId
join MiniOV..Dim_Date								dd		on	fc.Dt_Sys_Id = dd.DT_SYS_ID
join MiniOV..Dim_Diagnosis_Code						ddc		on	fc.Diag_1_Cd_Sys_Id = ddc.Diag_Cd_Sys_Id
where YEAR_NBR = 2016
-- 142,141,257

create clustered index uix_id on pdb_PharmaMotion..Claims (SavvyHICN, Clm_Aud_Nbr)


select Diag_Cd, Diag_Desc,  count(distinct SavvyHICN) Mbrs
into #TopDx
from pdb_PharmaMotion..Claims
group by Diag_Cd, Diag_Desc
-- 33,940

select *
from #TopDx
order by 3 desc 


select  SavvyHICN, 
		CntAHFS
	    
into  #DxCnts
from pdb_PharmaMotion..Claims
where Diag_Cd = 'I10    '  --- ESSENTIAL PRIMARY HYPERTENSION                                         
group by  SavvyHICN, 
		  CntAHFS
-- 550,967

select 
cast((count(distinct case when CntAHFS=1 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '1AHFS',
	 -- avg(case when CntAHFS=1 then CntNDC else NULL end) over(partition by SavvyHICN) as '1AHFS_NDC',
	   cast((count(distinct case when CntAHFS=2 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '2AHFS',
	   cast((count(distinct case when CntAHFS=3 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '3AHFS',
	   cast((count(distinct case when CntAHFS=4 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '4AHFS',
	   cast((count(distinct case when CntAHFS=5 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '5AHFS',
	  cast((count(distinct case when CntAHFS=6 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6AHFS',
	   cast((count(distinct case when CntAHFS>6 then SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
from #DxCnts


---- Find most common diagnosis pairs

select distinct SavvyHICN, Diag_Cd
into #Dx
from pdb_PharmaMotion..Claims
-- 15,897,634

create unique clustered index uix_id on #Dx(SavvyHICN, Diag_Cd)

select  c1.SavvyHICN, c1.Diag_Cd as Diag_Cd1, c2.Diag_Cd as Diag_Cd2
into #PairDx
from #Dx  c1, #Dx c2
where c1.SavvyHICN = c2.SavvyHICN  and c1.Diag_Cd <> c2.Diag_CD and c1.Diag_Cd < c2.Diag_Cd
-- 178,485,722

select *
from #PairDx
where SavvyHICN = '7809'

create unique clustered index uix_id on #PairDx(SavvyHICN, Diag_Cd1, Diag_Cd2)


select distinct SavvyHICN
into #PairDxMbrs
from #PairDx
where  Diag_Cd1 = 'E119   ' and Diag_Cd2 =  'I10    ' 
-- 159,457



select 
cast((count(distinct case when CntAHFS=1 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '1AHFS',
	 -- avg(case when CntAHFS=1 then CntNDC else NULL end) over(partition by SavvyHICN) as '1AHFS_NDC',
	   cast((count(distinct case when CntAHFS=2 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '2AHFS',
	   cast((count(distinct case when CntAHFS=3 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '3AHFS',
	   cast((count(distinct case when CntAHFS=4 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '4AHFS',
	   cast((count(distinct case when CntAHFS=5 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '5AHFS',
	  cast((count(distinct case when CntAHFS=6 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6AHFS',
	   cast((count(distinct case when CntAHFS>6 then a.SavvyHICN else NULL end)*100.0/sum(count(*))over()) as decimal(10,2)) as '6+AHFS'
from  #PairDxMbrs a
join  #drugCnts   b on a.SavvyHICN = b.SavvyHICN


select distinct Diag_Cd
from pdb_PharmaMotion..Claims
where SavvyHICN = 256898 and( Diag_Cd = 'I10    ' or Diag_Cd = 'E119   ')

select AgeGrp, Cnt_AHFS_201612, count(distinct SavvyHICN) Mbrs
from pdb_PharmaMotion..G1097Members
group by AgeGrp, Cnt_AHFS_201612
