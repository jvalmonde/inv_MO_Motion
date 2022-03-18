use pdb_abw
go

/*
select distinct AllSavers_familyID, Role, Consult_Date--, [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
from dbo.HealthiestYou_MemberConsults2015
-- 5,705

select distinct AllSavers_familyID, Role, Consult_Date, [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
from dbo.HealthiestYou_MemberConsults2015
-- 5,720


select AllSavers_familyID, Role, Consult_Date, Count(Distinct [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)])
from dbo.HealthiestYou_MemberConsults2015
Group By AllSavers_familyID, Role, Consult_Date
Having Count(Distinct [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]) > 1


select * From dbo.HealthiestYou_MemberConsults2015
Where AllSavers_familyID = 540000282300013
	and ROle = 'Dependent'
	and Consult_Date = '2015-04-21'
*/


/***************** Table 1 and 2 *****************/

Drop Table #cons
Select AllSavers_familyID, Role,  Consult_date,
	Case when MaxResponse like '%Emergency%' or MinResponse Like   '%Emergency%' then  'Emergency Room'
       when MaxResponse like '%Urgent%' or MinResponse Like   '%Urgent Care%' then  'Urgent Care'
              when MaxResponse =  'Primary Care Physician' or MinResponse =   'Primary Care Physician' 
              or MaxResponse like '%provider%' or MinResponse like '%provider%' then  'Primary Care Physician'
			  when MaxResponse =  'Other' or MinResponse =   'Other' 
              or MaxResponse = 'Done Nothing' or MinResponse = 'Done Nothing' then  'Other'
                     Else MaxResponse End																as SurveyResponse
  Into #Cons
FROM 
       (select  AllSavers_familyID, Role,  Consult_date, 
       MaxResponse = Min(distinct  [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)] )
       ,MinResponse = Max(distinct  [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)] )
       from dbo.HealthiestYou_MemberConsults2015
       group by AllSavers_familyID, Role, Consult_Date

       ) a


Drop table #consult_dates2
 sELECT  AllSavers_familyID, AllSavers_SystemID, Gender
 , Consult_date as call_Start_date
 , Role
 ,age
 , Icd9_Code_1 = case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end
,dc.AHRQDiagDtlCatgyCd
,dc.AHRQDiagGenlCatgyCd
, dc.AHRQDiagDtlCatgyNm, dc.AHRQDiagGenlCatgyNm, dc.DiagDesc
into #consult_dates2
from pdb_ABW.dbo.HealthiestYou_MemberConsults2015 a 
	Left join (Select Distinct DiagDecmCd, AHRQDiagDtlCatgyCd ,AHRQDiagGenlCatgyCd, AHRQDiagDtlCatgyNm, AHRQDiagGenlCatgyNm, DiagDesc   From  Allsavers_prod.dbo.Dim_DiagnosisCode )  dc 
		ON case when charindex(';',Icd9Code,0) > 0 then substring(Icd9Code,0,charindex(';',Icd9Code,0)) else Icd9code end = dc.DiagDecmCd 
		and Icd9Code <> ''


-- Claim flags
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
          max(case when b.AHRQDiagGenlCatgyCd = f.AHRQDiagGenlCatgyCd then 1 else 0 end) as AHRQ_Genl,
		  Max(Case when a.ServicetypeSysId = 4 then 1 else 0 end)  as RxClaim 
into #claims_flags
--Select * 
from (Allsavers_Prod..Fact_Claims       as a inner join allsavers_prod..Dim_Member dm on a.Memberid = dm.Memberid) 
join #consult_dates2                                    as b   on dm.Familyid = b.AllSavers_familyID --and dm.Gender = b.Gender
join Allsavers_Prod..Dim_Date                   as c   on a.FromDtSysID = c.DtSysId
join Allsavers_Prod..Dim_ServiceCode     as d   on a.ServiceCodeSysID = d.ServiceCodeSysID
join Allsavers_Prod..Dim_ProcedureCode   as e   on a.ProcCdSysID = e.ProcCdSysId
join Allsavers_Prod..Dim_DiagnosisCode   as f   on a.DiagCdSysID = f.DiagCdSysId
where c.FullDt between b.Call_Start_Date and dateadd(day, 7, b.Call_Start_Date)
group by AllSavers_familyID, b.Call_Start_Date,Role
-- 4,615


Select * 


update #claims_flags
set UC = 0
where ER = 1
 
update #claims_flags
set EM = 0
where ER = 1 or UC = 1

 
--Summarize
select SurveyResponse,	
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
              select distinct cd.AllSavers_FamilyId,  cd.Call_Start_Date, cd.Role, c.SurveyResponse
              from #consult_dates2 cd
			  Join	#Cons	c	on	cd.AllSavers_FamilyID	=	c.AllSavers_FamilyID
								and	cd.Call_Start_Date		=	c.Consult_Date
								and	cd.Role					=	c.Role
              ) as a
       left join #claims_flags           as b   on a.AllSavers_FamilyId = b.AllSavers_familyID
													
                                                                 and a.Call_Start_Date = b.Call_Start_Date
                                                                 and a.Role = b.Role
																 --and a.Gender = b.Gender
																 --and b.Fst3 = 1 
       ) as a
--
group by SurveyResponse	
with rollup
order by 1 desc

-- same diagnosis
 select SurveyResponse,
		count(*) as Cnt, 
          sum(case when False_Diversion_Flag = 1 then ER end) as ER,
          sum(case when False_Diversion_Flag = 1 then UC end) as UC,
          sum(case when False_Diversion_Flag = 1 then EM end) as EM,
		  sum(case when False_Diversion_Flag = 1 then ER end) + sum(case when False_Diversion_Flag = 1 then UC end) + sum(case when False_Diversion_Flag = 1 then EM end) as Total
from(
       select cf.*, case when AHRQ_Genl + AHRQ_Dtl + Fst3 > 0 then 1 else 0 end as False_Diversion_Flag, c.SurveyResponse
       from #claims_flags	cf
	   Left Join	#Cons	c	on	cf.AllSavers_FamilyID	=	c.AllSavers_FamilyID
								and	cf.Call_Start_Date		=	c.Consult_Date
								and	cf.Role					=	c.Role
       where ER + UC + EM > 0
       ) as a
Group By SurveyResponse
Order by 1 desc



/***************** Table 3 *****************/
/*** Rx Fills per survey response bucket ***/

Drop table #Rxs
Select dm.Systemid, Familyid, a.NDCDrugSysID, c.Fulldt, dm.Gender, dm.BirthDate, ndc.ExtAHFSThrptcClssDesc, Role
into #Rxs
from (Allsavers_Prod..Fact_Claims       as a inner join allsavers_prod..Dim_Member dm on a.Memberid = dm.Memberid) 
join #consult_dates2                                    as b   on dm.Familyid = b.AllSavers_familyID 															
														--and	IIF(b.Gender = 'Male', 'M', 'F')	=	dm.Gender
														--and b.Age between DATEDIFF(YEAR, dm.BirthDate, Convert(date, getdate())) - 1 and DATEDIFF(YEAR, dm.BirthDate, Convert(date, getdate())) + 1
	
join Allsavers_Prod..Dim_Date                   as c   on a.FromDtSysID = c.DtSysId
join Allsavers_Prod..Dim_ServiceCode     as d   on a.ServiceCodeSysID = d.ServiceCodeSysID
join allsavers_prod.dbo.Dim_ServiceType as st   on st.ServiceTypeSysID = a.ServiceTypeSysID and st.ServiceTypeDescription = 'Pharmacy'
join Allsavers_Prod..Dim_ProcedureCode   as e   on a.ProcCdSysID = e.ProcCdSysId
join Allsavers_Prod..Dim_DiagnosisCode   as f   on a.DiagCdSysID = f.DiagCdSysId
join allsavers_prod.dbo.Dim_NDCDrug      as ndc on a.NDCDrugSysID = ndc.NDCDrugSysID 
where c.FullDt between b.Call_Start_Date and dateadd(day, 14, b.Call_Start_Date)
and 1 =1 




/***************** Table 4 *****************/
/*** RX FILLS FOR ALL ALLSAVERS CLAIMS FOR 2015, BY SERVICETYPE BUCKET ***/

--Drop Table #claims
Select Distinct fc.SystemID, fc.MemberID, fc.PolicyID
	, fc.FromDtSysID, dd.FullDT as ServiceDate
	, ServiceType	=	case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
								when ServiceCodeLongDescription like '%urgent%'			then	'UC'
								when (
									ProcDesc like '%office%visit%'  
									or srvccatgydesc like '%evaluation%management%'
									)													then	'DR'
								else 'Others'
						end
  Into #claims
From Allsavers_Prod.dbo.Fact_Claims				fc	
join Allsavers_Prod.dbo.Dim_Date				dd	on	fc.FromDtSysID		=	dd.DtSysId
join allsavers_prod.dbo.dim_member				dm  on  dm.SystemID = fc.SystemID
left join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc1	on	fc.DiagCdSysId		=	dc1.DiagCdSysId
left join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc2	on	fc.DiagCdICD10SysID	=	dc2.DiagCdSysId
join Allsavers_Prod.dbo.Dim_ProcedureCode		pc	on	fc.ProcCdSysID		=	pc.procCdsysid
join allsavers_prod.dbo.Dim_ServiceCode			sc	on	fc.ServiceCodeSysID	=	sc.ServiceCodeSysID
join Allsavers_Prod.dbo.Dim_NDCDrug				ndc on	fc.NDCDrugSysID		=	ndc.NDCDrugSysID
Where fc.RecordTypeSysID = 1
	and dd.YearNbr = 2015
	and MemberID > 0
	and 
-- 1,540,143


--select top 1000 * From #claims Order By SysteMID


Select SurveyResponse,Count(Distinct ConsultID) as Consults, Count(Distinct NDCDrugSysid) as DistinctDrugScripts-- Count(Distinct AS_rx_NDC)
,Ratio = Count(Distinct NDCDrugSysid)*1.00/Count(Distinct ConsultID)
From
(
	Select distinct *
	From	(
			Select a.*, ConsultID = Dense_rank()Over(Order by a.AllSavers_FamilyId,  a.Role,  a.consult_Date)  , c.NDCDrugSysID  
			From #cons									a
	Left Join #Rxs	c	On	a.AllSavers_familyID	=	c.FamilyID
																		and a.Role = c.role 
																		--and	a.Age	=	c.Age
																		and c.fullDt between a.Consult_Date and DATEADD(DAY, 14, a.Consult_Date)
	--Order By a.Allsavers_familyID, a.Role, a.Consult_Date, a.SurveyResponse
	)	sub
) a
Group By SurveyResponse with rollup 

Select SurveyResponse, Count(*) as Visits,Sum( DistinctRx )as rxcount ,Ratio = Sum( DistinctRx )*1.00/Count(*)
From
(
	Select a.AllSavers_familyID
	, a.call_Start_date, a.SurveyResponse
		,Count(Distinct b.NDCDrugSysID) DistinctRx
	From 
(				




					select a.*,
					                 isnull(b.ER,0) as ER,
					                 isnull(b.UC,0) as UC,
					                 isnull(b.EM,0) as EM,
					                 case when b.ER + b.UC + b.EM > 0 then 1 else 0 end as Total
					from(
					              --Distinct consults
					              select distinct cd.AllSavers_FamilyId,  cd.Call_Start_Date, cd.Role, c.SurveyResponse, Gender, Age
					              from #consult_dates2 cd
								  Join	#Cons	c	on	cd.AllSavers_FamilyID	=	c.AllSavers_FamilyID
													and	cd.Call_Start_Date		=	c.Consult_Date
													and	cd.Role					=	c.Role
					              ) as a
					       left join #claims_flags           as b   on a.AllSavers_FamilyId = b.AllSavers_familyID
																		
					                                                                 and a.Call_Start_Date = b.Call_Start_Date
					                                                                 and a.Role = b.Role
																					 --and a.Gender = b.Gender
																					 --and b.Fst3 = 1 
Where case when b.ER + b.UC + b.EM > 0 then 1 else 0 end = 1 
					

				
)a						---This is the distinct service dates
	left Join (Allsavers_Prod.dbo.Fact_Claims		b 
				inner join AllSavers_prod.dbo.Dim_member dm on dm.SystemID = b.SystemID 
				inner join allsavers_prod.dbo.Dim_Date dd on dd.DtSysId = b.FromDtSysID) 
											on	a.AllSavers_familyID	=	dm.FamilyID
											and a.Gender = dm.Gender 
											and a.Age  between datediff(year, dm.BirthDate, getdate()) - 1 and  datediff(year, dm.BirthDate, getdate()) + 1
											and	dd.FullDt between a.call_Start_date	and dateadd(day,14,call_start_date)
											and b.ServiceTypeSysID = 4	-- RX
Group by a.AllSavers_familyID
	, a.call_Start_date, a.SurveyResponse
	--Order By SystemID, ServiceDate
)	sub
Group By SurveyResponse with rollup

--select top 100 *
--From Allsavers_Prod.dbo.Fact_Claims

