/****** Script for SelectTopNRows command from SSMS  ******/

 Drop table #consult_dates2
 sELECT  AllSavers_familyID, AllSavers_SystemID, Gender
 , Consult_date as call_Start_date
 , Role
 , Icd9_Code_1 = case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end
,dc.AHRQDiagDtlCatgyCd
,dc.AHRQDiagGenlCatgyCd
, dc.AHRQDiagDtlCatgyNm, dc.AHRQDiagGenlCatgyNm, dc.DiagDesc
into #consult_dates2
from pdb_abw.dbo.HealthiestYou_MemberConsults2015 a 
	Left join (Select Distinct DiagDecmCd, AHRQDiagDtlCatgyCd ,AHRQDiagGenlCatgyCd, AHRQDiagDtlCatgyNm, AHRQDiagGenlCatgyNm, DiagDesc   From  Allsavers_prod.dbo.Dim_DiagnosisCode )  dc 
		ON case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end = dc.DiagDecmCd 
		and Icd9Code <> ''
--Where Consult_Date between '20150101' and '20150630'


--Select Distinct AllSavers_familyID, Call_Start_date FROM #consult_dates2 Where call_Start_date between '20150101' and '20150630'

--Select * FROM pdb_abw.dbo.HealthiestYou_MemberConsults2015 Where Consult_date between '20150101' and '20150630'

 Drop table #claims_flags
select  b.AllSavers_familyID,b.Call_Start_Date,Role ,
       max(case when d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%' then 1 else 0 end) as ER,
       max(case when d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%' then 1 else 0 end) as UC,
       max(case when e.ProcCd like '992%' then 1 else 0 end) as EM,
 
          max(case when(d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%')
                             and left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as ER_Fst3,
       max(case when(d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%')
                             and left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as UC_Fst3,
       max(case when e.ProcCd like '992%'
                    and left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as EM_Fst3,
 
          max(case when(d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%')
                             and b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as ER_AHRQ_Dtl,
       max(case when(d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%')
                             and b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as UC_AHRQ_Dtl,
       max(case when e.ProcCd like '992%'
                             and b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as EM_AHRQ_Dtl,
 
          max(case when(d.ServiceCodeLongDescription like '%emerg%'
                  or e.SrvcCatgyDEsc like '%emerg%')
                             and b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as ER_AHRQ_Genl,
       max(case when(d.ServiceCodeLongDescription like '%urgent%'
                  or e.ProcDesc like '%urgent%')
                             and b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as UC_AHRQ_Genl,
       max(case when e.ProcCd like '992%'
                             and b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as EM_AHRQ_Genl,
         
          max(case when left(b.ICD9_Code_1,3) = f.DiagFst3Cd then 1 else 0 end) as Fst3,
          max(case when b.AHRQDiagDtlCatgyCd = f.AHRQDiagDtlCatgyCd then 1 else 0 end) as AHRQ_Dtl,
          max(case when b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as AHRQ_Genl
into #claims_flags
from (Allsavers_Prod..Fact_Claims       as a inner join allsavers_prod..Dim_Member dm on a.Memberid = dm.Memberid) 
join #consult_dates2                                    as b   on dm.Familyid = b.AllSavers_familyID --and dm.Gender = b.Gender
join Allsavers_Prod..Dim_Date                   as c   on a.FromDtSysID = c.DtSysId
join Allsavers_Prod..Dim_ServiceCode     as d   on a.ServiceCodeSysID = d.ServiceCodeSysID
join Allsavers_Prod..Dim_ProcedureCode   as e   on a.ProcCdSysID = e.ProcCdSysId
join Allsavers_Prod..Dim_DiagnosisCode   as f   on a.DiagCdSysID = f.DiagCdSysId
where c.FullDt between b.Call_Start_Date and dateadd(day, 7, b.Call_Start_Date)
group by AllSavers_familyID, b.Call_Start_Date,Role
--2246



update #claims_flags
set UC = 0
where ER = 1
 
update #claims_flags
set EM = 0
where ER = 1 or UC = 1

 
  
 
 
--Summarize
select Role,
          count(*) as Consults,
          sum(ER) as ER,
          sum(UC) as UC,
          sum(EM) as EM,
          sum(Total) as Total,
          sum(Total)*1.0/count(*) as FD_Rate
from(
       --Flag consults with visits within 7 days by 
       select a.*,
                 isnull(b.ER,0) as ER,
                 isnull(b.UC,0) as UC,
                 isnull(b.EM,0) as EM,
                 case when b.ER + b.UC + b.EM > 0 then 1 else 0 end as Total
from(
              --Distinct consults
              select distinct AllSavers_FamilyId,  Call_Start_Date, Role
              from #consult_dates2 b
              ) as a
       left join #claims_flags           as b   on a.AllSavers_FamilyId = b.AllSavers_familyID
													
                                                                 and a.Call_Start_Date = b.Call_Start_Date
                                                                 and a.Role = b.Role
																 --and a.Gender = b.Gender
																 --and b.Fst3 = 1 
       ) as a
--
group by Role
order by 1 desc



 select count(*) as Cnt, 
          sum(case when False_Diversion_Flag = 1 then ER end) as ER,
          sum(case when False_Diversion_Flag = 1 then UC end) as UC,
          sum(case when False_Diversion_Flag = 1 then EM end) as EM
from(
       select *, case when AHRQ_Genl + AHRQ_Dtl + Fst3 > 0 then 1 else 0 end as False_Diversion_Flag
       from #claims_flags
       where ER + UC + EM > 0
       ) as a
