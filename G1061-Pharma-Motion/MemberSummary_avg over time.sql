/*** 
GP 1062 - T2D Adherence --aggregrate table for the per DMC

Input databases:	SMA, pdb_CGMType2

Date Created: 13 June 2017
***/

--utilization
If (object_id('tempdb..#ipconf') Is Not Null)
Drop Table #ipconf
go

select a.SavvyMRN, d.Year_Mo
	, Confinement_ID = row_number() over(partition by a.SavvyMRN order by c.ServiceBeginDateSysID)
	, Day_Cnt = case when datediff(dd, d.Full_Dt, d1.Full_Dt) = 0	then 1	else datediff(dd, d.Full_Dt, d1.Full_Dt) end
	, AdmitDt = d.Full_Dt
	, DischargeDt = d1.Full_Dt
	--, c.LengthOfStay, c.UtilizationCategory, e.POSDescription
into #ipconf
from	(
			select SavvyMRN	--, Year_Mo
			from pdb_CGMType2..GP1062_MemberSummary_DMC
			group by SavvyMRN	--, Year_Mo
		)	a
inner join SMA..Dim_Member					b	on	a.SavvyMRN = b.SavvyMRN
inner join SMA..Fact_Medical				c	on	b.SavvyID = c.SavvyID
inner join SMA..Dim_Date					d	on	c.ServiceBeginDateSysID = d.DT_SYS_ID	--admission date
												--and a.Year_Mo = d.YEAR_MO
inner join SMA..Dim_Date					d1	on	c.ServiceEndDateSysID = d1.DT_SYS_ID	--discharge date
inner join SMA..Dim_POS						e	on	c.PlaceOfServiceSysID = e.POSSysID
where d.YEAR_MO between 201110 and 201509
	and c.UtilizationCategory = 'IP'
	and e.POSDescription = 'INPATIENT HOSPITAL'	--280
	--and a.SavvyMRN = 118106
group by a.SavvyMRN, d.Year_Mo, c.ServiceBeginDateSysID, d.Full_Dt, d1.Full_Dt	--, c.LengthOfStay, c.UtilizationCategory, e.POSDescription
--(8,086 row(s) affected)
create index Ix_SavvyMRN_YM on #ipconf (SavvyMRN, Year_Mo);
create index Ix_Dates on #ipconf (AdmitDt, DischargeDt);

select * from #ipconf where SavvyMRN = 118106 order by Year_Mo, Confinement_ID
select max(Confinement_ID) from #ipconf
/*select distinct UtilizationCategory  from SMA..Fact_Medical
IP
OP
OTH
PHY
*/

If (object_id('tempdb..#utilization2') Is Not Null)
Drop Table #utilization2
go

select a.SavvyMRN	--, Year_Mo
	, IP_Stays	= max(case when Derived_Srvc_Type_cd = 'IP'	then Confinement_ID	else 0	end)
	, IP_Days	= max(case when Derived_Srvc_Type_cd = 'IP' and b.SavvyMRN is not null	then b.Day_Cnt else 0	end)
	, ER_Visits	= count(distinct case when Derived_Srvc_Type_cd = 'ER'	then ServiceDateSysID	end)
	, DR_Visits = count(distinct case when Derived_Srvc_Type_cd = 'PHY'	then ServiceDateSysID	end)
	, OP_Visits = count(distinct case when Derived_Srvc_Type_cd = 'OP'	then ServiceDateSysID	end)
	, Aprox_TotalSpend = sum(Med_AllwAmt)
	--, count(distinct YEAR_MO)
into #utilization2
from	(
			select a.SavvyMRN, c.ClaimNumber	--, c.LineNumber	--, d.Year_Mo
				, Derived_Srvc_Type_cd = case when h.SavvyMRN is not null	and UtilizationCategory <> 'IP'	then 'IP'
												when g.POSDescription = 'EMERGENCY ROOM - HOSPITAL'		then 'ER'
												when UtilizationCategory = 'PHY' and g.POSDescription in ('OFFICE', 'OUTPATIENT HOSPITAL', 'INDEPENDENT LAB')	then 'PHY'	else UtilizationCategory end
				, c.ServiceDateSysID, d.FULL_DT
				, f.Med_AllwAmt
				, Confinement_ID	--, Day_Cnt
				,UtilizationCategory, POSDescription
			--select distinct POSDescription
			from	( --6,820
						select SavvyMRN
						from pdb_CGMType2..GP1062_MemberSummary_DMC
						group by SavvyMRN
					)	a
			inner join SMA..Dim_Member					b	on	a.SavvyMRN = b.SavvyMRN
			inner join SMA..Fact_Medical				c	on	b.SavvyID = c.SavvyID
			inner join SMA..Dim_Date					d	on	c.ServiceDateSysID = d.DT_SYS_ID
															--and d.YEAR_MO between 201110 and 201509
			inner join SMA..Dim_Procedure_Code			e	on	c.ProcedureCodeSysID = e.PROC_CD_SYS_ID
			inner join pdb_CGMType2..UHC_proc_median	f	on	e.PROC_CD = f.PROC_CD
			inner join SMA..Dim_POS						g	on	c.PlaceOfServiceSysID = g.POSSysID
			left join #ipconf							h	on	a.SavvyMRN = h.SavvyMRN
															and d.FULL_DT between h.AdmitDt and h.DischargeDt 
			where d.YEAR_MO between '201110' and '201509'
				--and a.SavvyMRN = 118106
				--and UtilizationCategory = 'PHY'
				--and (case when h.SavvyMRN is not null	and UtilizationCategory <> 'IP'	then 'IP'
				--								when  g.POSDescription = 'EMERGENCY ROOM - HOSPITAL'		then 'ER'	else UtilizationCategory end)  = 'PHY'
			group by a.SavvyMRN, c.ClaimNumber, c.ServiceDateSysID, f.Med_AllwAmt, Confinement_ID, h.SavvyMRN, g.POSDescription, UtilizationCategory, d.FULL_DT
		) a
left join	(
				select SavvyMRN , Day_Cnt = sum(Day_Cnt)
				from #ipconf
				--where SavvyMRN = 118106
				group by SavvyMRN
			)	b	on	a.SavvyMRN = b.SavvyMRN
group by a.SavvyMRN	--, Year_Mo
--(211,582 row(s) affected); 5.05 mintues
--(6819 row(s) affected)
create unique index uIx_SavvyMRN_YM on #utilization2 (SavvyMRN);

/*
select *
from #utilization2
where SavvyMRN = 118106

select avg(Aprox_TotalSpend)
from #utilization2
where SavvyMRN = 18036

select SavvyMRN, Year_Mo, DMC, count(*)
from pdb_CGMType2..GP1062_MemberSummary_DMC
group by SavvyMRN, Year_Mo, DMC
having count(*) > 1
*/

update pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
set IP_Stays		= isnull(b.IP_Stays, 0)
	, IP_Days		= isnull(b.IP_Days, 0)
	, ER_Visits		= isnull(b.ER_Visits, 0)
	, DR_Visits		= isnull(b.DR_Visits, 0)
	, OP_Visits		= isnull(b.OP_Visits, 0)
	, Aprox_TotalSpend = isnull(b.Aprox_TotalSpend, 0)
from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT	a
left join #utilization2								b	on	a.SavvyMRN = b.SavvyMRN


If (object_id('pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT') Is Not Null)
Drop Table pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
go

select a.SavvyMRN, a.DMC
	, b.GNRC_NM
	, Stage = ''
	, Avg_Aprox_Rx_Spend = cast(avg(a.Aprox_Rx_Spend) as decimal(9,2))
	, Adherence1 = NULL
	, Adherence2 = NULL
	, Adherence3 = NULL
	, Adherence4 = NULL
	, Adherence5 = NULL
	, IP_Stays		= max(c.IP_Stays)
	, IP_Days		= max(c.IP_Days)
	, ER_Visits		= max(c.ER_Visits)
	, DR_Visits		= max(c.DR_Visits)
	, OP_Visits		= max(c.OP_Visits)
	, MM			= max(d.MM)
	, Age			= max(d.Age) - 6	--age is based on recent month refresh
	, Gdr_Cd		= max(d.Gender)
	, Zip			= max(d.ZipCode)
	, BMI			= NULL
	, A1C			= NULL
	, Aprox_TotalSpend = max(cast(c.Aprox_TotalSpend as decimal(9,2)))
	, Depression	= 1
into pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
from	(
			select SavvyMRN, DMC, Aprox_Rx_Spend = cast(Aprox_Rx_Spend as decimal(9,2))
			from pdb_CGMType2..GP1062_MemberSummary_DMC
			group by SavvyMRN, DMC, Aprox_Rx_Spend
		)	a
left join (
				select SavvyMRN, DMC, GNRC_NM
					, RN = row_number() over(partition by SavvyMRN, DMC order by Year_Mo desc)
				from pdb_CGMType2..GP1062_MemberSummary_DMC
				--where SavvyMRN = 930
			)						b	on	a.SavvyMRN = b.SavvyMRN
										and a.DMC = b.DMC
										and b.RN = 1
left join #utilization2				c	on	a.SavvyMRN = c.SavvyMRN
left join	(
				select a.SavvyMRN
					--, YearNbr	= left(a.Year_Mo, 4)
					, MM		= count(distinct a.Year_Mo)
					, b.Gender, b.Age, b.ZipCode
				from pdb_CGMType2..GP1062_MemberSummary_DMC	a
				inner join SMA..Dim_Member					b	on	a.SavvyMRN = b.SavvyMRN
				inner join SMA..Dim_Member_Detail			c	on	b.SavvyID = c.SavvyID
																and a.Year_Mo = c.Year_Mo
				--where a.SavvyMRN = 930
				group by a.SavvyMRN, b.Gender, b.Age, b.ZipCode	--, left(a.Year_Mo, 4)
			)	d	on	a.SavvyMRN = d.SavvyMRN
--where b.RN = 1
where a.DMC is not null
group by a.SavvyMRN, a.DMC, b.GNRC_NM
--(9,256 row(s) affected); 4.33 minutes

select count(distinct SavvyMRN) from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT where Depression = 1

--recent A1C
alter table pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
	alter column A1C decimal (9,2)
go

update pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
set A1C = b.A1C
from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT	a
left join	(
				select b.SavvyMRN, b.Year_Mo, a.A1C
					, OID = row_number() over(partition by b.SavvyMRN order by b.Year_Mo desc)
				from pdb_CGMType2..Stage2_RSKC_SMA_MemberSummary_201110_201509_Px_clnx	a
				inner join pdb_CGMType2..GP1062_MemberSummary_DMC						b	on	a.SavvyMRN = b.SavvyMRN
																							and a.Year_Mo = b.Year_Mo
				where a.A1C is not null
			) b	on	a.SavvyMRN = b.SavvyMRN
where OID = 1

--BMI recent
alter table pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
	alter column BMI decimal (9,2)
go

update pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
set BMI = b.BMI
from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT	a
left join	(
				select a.SavvyMRN	--, a.Year_Mo
					, BMI = c.NormalizedValue
					, OID = row_number() over(partition by a.SavvyMRN order by c.VitalTakenDate desc)
				from	(
							select SavvyMRN
							from pdb_CGMType2..GP1062_MemberSummary_DMC
							group by SavvyMRN
						)	a
				inner join SMA..Dim_Member					b	on	a.SavvyMRN = b.SavvyMRN
				inner join SMA..Fact_TW_Vital				c	on	b.SavvyID = c.SavvyID
				inner join SMA..Dim_Date					d	on	c.VitalTakenDate = d.FULL_DT
				where d.YEAR_MO between '201110' and '201509'
					and c.Vital = 'BMI Calculated'
			) b	on	a.SavvyMRN = b.SavvyMRN
where OID = 1
--(9,249 row(s) affected)

--Depression flags
update pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT
set Depression = case when b.SavvyMRN is not null then 1	else 0	end
from pdb_CGMType2..GP1062_MemberSummary_DMC_avgOT	a
left join	(--763
				select a.SavvyMRN, Depression = 1
				--into #temp
				from (
							select SavvyMRN
							from pdb_CGMType2..GP1062_MemberSummary_DMC
							group by SavvyMRN
						)	a
				inner join SMA..Dim_Member					b	on	a.SavvyMRN = b.SavvyMRN
				inner join SMA..Fact_Medical				c	on	b.SavvyID = c.SavvyID
				inner join SMA..Dim_Date					d	on	c.ServiceDateSysID = d.DT_SYS_ID
				inner join SMA..Dim_Diagnosis_Code			e	on	c.PrimaryDiagCodeSysID = e.DIAG_CD_SYS_ID
				inner join Charlson..Charlson_Diag_List		f	on	e.DIAG_CD = f.Diagnosis_Code
				where d.YEAR_MO between '201110' and '201509'
					and f.Chrnc_Cond_Nm = 'Depression'
					--and e.ICD_VER_CD <> 0			--exclude ICD10 versions
				group by a.SavvyMRN
			)	b	on	a.SavvyMRN = b.SavvyMRN

