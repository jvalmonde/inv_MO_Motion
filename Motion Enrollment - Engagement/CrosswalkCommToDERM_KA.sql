/*
Developer - Prajakta Patil
This script prepares a motion dataset for Key Accounts with employee and employer information 
Database - pdb_MotionEnrollmentEngagement 
table - KA_Motion
*/

use pdb_MotionEnrollmentEngagement;

-- 0.2% of the members present in Summary_Indv_Demographic are not present in MiniHPDM.dim_Member. Excluding those members. 
select * from 
(select distinct Indv_Sys_Id from Summary_Indv_Demographic a
where CUST_SEG_SYS_ID IN (  select distinct a.Cust_Seg_Sys_Id 
							from minihpdm_phi.dbo.dim_member a
							join dim_customer_segment b on a.cust_seg_sys_id = b.cust_Seg_Sys_id
							join Dim_Group_Indicator c on c.mkt_seg_cd = b.mkt_seg_cd
							where mkt_seg_rllp_desc = 'KEY ACCOUNTS' ))A
left join minihpdm_phi.dbo.dim_member b
on a.indv_sys_id = b.indv_sys_id
where b.Indv_Sys_Id IS NULL

select distinct a.Cust_Seg_Sys_Id into #all_emp
							from minihpdm_phi.dbo.dim_member a
							join dim_customer_segment b on a.cust_seg_sys_id = b.cust_Seg_Sys_id
							join Dim_Group_Indicator c on c.mkt_seg_cd = b.mkt_seg_cd
							where mkt_seg_rllp_desc = 'KEY ACCOUNTS'

-- Take Member Employee History into account
drop table KA_Emp
select					distinct Indv_Sys_Id,
						sid.Cust_Seg_Sys_Id,
						CUST_SEG_NBR,
						DENSE_RANK() OVER (PARTITION BY INDV_SYS_ID ORDER BY sid.CUST_SEG_SYS_ID) as cnt_emp 
into KA_Emp--#emp_hist
from minihpdm.dbo.Summary_Indv_Demographic						sid
join minihpdm.dbo.Dim_Customer_Segment							cs						on sid.Cust_Seg_Sys_Id = cs.CUST_SEG_SYS_ID
where sid.CUST_SEG_SYS_ID IN (  select Cust_Seg_Sys_Id from #all_emp
							 )

select top 100 * from pdb_motionenrollmentengagement..KA_Emp where cnt_emp = 16

select distinct cnt_emp,count(*) from pdb_motionenrollmentengagement..KA_emp group by cnt_emp order by cnt_emp desc


-- Pivot the table
drop table #pvt_emp_hist
select					 Indv_Sys_Id,
						 [1] as comp1,
						 [2] as comp2,
						 [3] as comp3,
						 [4] as comp4,
						 [5] as comp5,
						 [6] as comp6,
						 [7] as comp7,
						 [8] as comp8,
						 [9] as comp9,
						 [10] as comp10,
						 [11] as comp11,
						 [12] as comp12,
						 [13] as comp13,
						 [14] as comp14,
						 [15] as comp15,
						 [16] as comp16,
						 [17] as comp17

into pvt_KA_EMP--#pvt_emp_hist
from (select Indv_Sys_Id,CUST_SEG_NBR,cnt_emp from KA_Emp)query
PIVOT(
		MIN(CUST_SEG_NBR) for cnt_emp in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17])
	  ) as P1

select top 1 a.Indv_Sys_Id as SID,b.indv_sys_id as minihpdm into #tmp from pvt_KA_EMP a
left join KA_mem b
on a.Indv_Sys_Id = b.Indv_Sys_Id
where b.indv_sys_id is null
order by newid()

select * from MiniHPDM..Dim_Member a join #tmp b on a.Indv_Sys_Id = b.SID where Indv_Sys_Id = '641339730'
select * from MiniHPDM..Summary_Indv_Demographic where Indv_Sys_Id = '641339730'

select count(*) from  pvt_KA_emp --where Indv_Sys_Id = '904067186'
select count(*) from KA_mem


select * from MiniHPDM_PHI.dbo.Dim_Member where Indv_Sys_Id = '240097736'
select * from Summary_Indv_Demographic where Indv_Sys_Id = '240097736'
select * from MiniHPDM_PHI.dbo.Dim_Member where SavvySbscr_Nbr = '69952159'
select * from dermsl_prod.dbo.MEMBERSignupData
select * from #pvt_emp_hist where indv_sys_id = '904067186'
select * from MiniHPDM..Dim_Customer_Segment where CUST_SEG_NBR like '%PNX%'
select * from MiniHPDM..Dim_Group_Indicator where mkt_seg_cd = 'S'


--- collect all the members
drop table KA_mem
select					m.*,
						emp_hist.comp1,
						emp_hist.comp2,
						emp_hist.comp3,
						emp_hist.comp4,
						emp_hist.comp5,--cs.CUST_SEG_NBR,cs.CUST_SEG_NM,gi.MKT_SEG_CD,gi.MKT_SEG_RLLP_DESC 
						emp_hist.comp6,
						emp_hist.comp7,
						emp_hist.comp8,
						emp_hist.comp9,
						emp_hist.comp10,
						emp_hist.comp11,
						emp_hist.comp12,
						emp_hist.comp13,
						emp_hist.comp14,
						emp_hist.comp15,
						emp_hist.comp16,
						emp_hist.comp17

into KA_mem
from pvt_KA_EMP emp_hist join MiniHPDM_PHI.dbo.Dim_Member							m      on emp_hist.Indv_Sys_Id = m.Indv_Sys_Id

select * from MiniHPDM_PHI..Dim_Member where indv_sys_id in ('53421757',
'380608157',
'802724897',
'656423896')--comp16 is not null
--Difference of 102 members due to data discrepancy
select count(*) from #KA_mem --43589 members
select count(*) from #emp_hist --43692 members

select * from pdb_motionenrollmentengagement..KA_mem where Indv_Sys_Id = '904067186'
select * from #pvt_emp_hist where indv_sys_id = '81081918'
select * from #KA_mem where Indv_Sys_Id = '1404787885'
select * from #pvt_emp_hist where Indv_Sys_Id = '904067186'
select *--count(*)--Indv_Sys_Id,count(distinct cust_seg_nbr),count(distinct orig_eff_dt) 
from Summary_Indv_Demographic a
join Dim_Customer_Segment b 
on a.cust_seg_sys_id = b.CUST_SEG_SYS_ID 
where Indv_Sys_Id = '1404787885'



------------------Joining condition 1
drop table join1
select mem.Indv_Sys_Id,A.*,
CASE WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp1)),6)+'%' THEN mem.comp1 
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp2)),6)+'%' THEN mem.comp2
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp3)),6)+'%' THEN mem.comp3
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp4)),6)+'%' THEN mem.comp4
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp5)),6)+'%' THEN mem.comp5 
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp6)),6)+'%' THEN mem.comp1 
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp7)),6)+'%' THEN mem.comp2
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp8)),6)+'%' THEN mem.comp3
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp9)),6)+'%' THEN mem.comp4
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp10)),6)+'%' THEN mem.comp5 
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp11)),6)+'%' THEN mem.comp1 
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp12)),6)+'%' THEN mem.comp2
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp13)),6)+'%' THEN mem.comp3
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp14)),6)+'%' THEN mem.comp4
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp15)),6)+'%' THEN mem.comp5 
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp16)),6)+'%' THEN mem.comp4
	 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp17)),6)+'%' THEN mem.comp5 END AS CUST_SEG_NBR_join
into join1
from KA_mem															mem
inner join DERMSL_Prod.dbo.MEMBERSignupData								A				on (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp1)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp2)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp3)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp4)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp5)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp6)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp7)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp8)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp9)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp10)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp11)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp12)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp13)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp14)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp15)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																												   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp16)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp17)),6)+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'P' AND Sbscr_Ind = 0 THEN 'SP' 
																																													   WHEN DependentCode = 'P' AND Sbscr_Ind = 1 THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp1)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp2)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp3)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp4)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp5)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp6)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp7)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp8)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp9)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp10)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp11)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp12)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp13)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp14)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp15)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp16)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							OR  (ClientMEMBERID like RIGHT(convert(varchar,RTRIM(mem.comp17)),6)+RIGHT(mem.SSN,9)+CASE WHEN DependentCode = 'P' THEN 'EE' ELSE DependentCode END
																							   AND Bth_dt = BirthDate)
																							

select * from #join1 where Indv_Sys_Id = '904067186'-- firstname = 'VICTOR' and LastName = 'LAKIN' 
select * from #join1 where ClientMEMBERID like '%5474776%'
--select * from #KA_mem where Fst_Nm = 'VICTOR' and Lst_Nm = 'LAKIN' 
select * from #KA_mem where Indv_Sys_Id in ('1459703524','466198904')
select * from DERMSL_Prod.dbo.membersignupdata where firstname = 'VICTOR' and LastName = 'LAKIN' 

------------------Joining condition 2
drop table join2
select							mem.Indv_Sys_Id,
								A.*,
								CASE WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp1)),6)+'%' THEN mem.comp1 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp2)),6)+'%' THEN mem.comp2
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp3)),6)+'%' THEN mem.comp3
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp4)),6)+'%' THEN mem.comp4
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp5)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp6)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp7)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp8)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp9)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp10)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp11)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp12)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp13)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp14)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp15)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp16)),6)+'%' THEN mem.comp5 
									 WHEN A.clientmemberid like '%'+RIGHT(convert(varchar,RTRIM(mem.comp17)),6)+'%' THEN mem.comp5 END AS CUST_SEG_NBR_join
into join2
from KA_mem													mem
inner join DERMSL_Prod.dbo.MEMBERSignupData						A						on (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp1)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp2)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp3)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp4)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp5)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp6)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp7)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp8)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp9)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp10)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp11)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp12)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp13)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp14)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp15)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp16)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																														        WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)
																							OR (ClientMEMBERID like '0'+RIGHT(convert(varchar,RTRIM(mem.comp17)),6)+'00'+RIGHT(sbscr_Nbr,9)+CASE WHEN DependentCode = 'EE' THEN '00' 
																																															WHEN DependentCode <> 'EE' THEN '01' END
																								AND Bth_dt = BirthDate)

select * from #join2 where Indv_Sys_Id = '904067186'

select count(*) from DERMSL_Prod.dbo.membersignupdata where LOOKUPClientID = 175

------------------Combine the data from both conditions
drop table morerec
SELECT						M.*,
							A.ClientMEMBERID,
							A.DependentCode,
							A.BirthDate,
							A.FirstName,
							A.LastName,
							A.OfferCode,
							A.ParentClientMemberID,
							A.LOOKUPClientID,
							A.ProgramStartDate,
							A.LOOKUPRuleGroupID,
							A.RuleID, 
							A.CUST_SEG_NBR_join,
							CASE WHEN CUST_SEG_NBR_join IS NULL THEN cs.CUST_SEG_NBR ELSE CUST_SEG_NBR_join END as cust_seg_nbr_combined
INTO morerec
FROM KA_mem																				M
LEFT JOIN	(select * from join1 union select * from join2)								A		ON M.Indv_Sys_Id = A.Indv_Sys_Id
LEFT JOIN		MiniHPDM..Dim_Customer_Segment											cs		on M.comp1 = cs.CUST_SEG_NBR 


select * from pdb_motionenrollmentengagement..morerec where clientmemberid is not null
select count(*) from dermsl_prod..membersignupdata where lookupclientid = 175
select * from #morerec where Indv_Sys_Id in ('1459703524','466198904')


---------------Final Member List with additional fields
DROP TABLE KA_Motion
SELECT						A.Indv_Sys_Id AS INDV_SYS_ID, 
							A.Cust_Seg_Sys_Id,
							A.cust_seg_nbr_combined,
							cs.CUST_SEG_NM,
							A.ClientMEMBERID,A.Sbscr_Ind,gi.MKT_SEG_RLLP_DESC,A.Bth_dt,A.DependentCode,
							zip.zip, A.gdr_Cd, zip.St_Cd,
							A.Fst_Nm,A.Lst_Nm,
							A.LOOKUPRuleGroupID,
							rg.LOOKUPRuleGroupID as RuleGroupID,
							rg.RuleGroupName,
							CASE WHEN A.ClientMEMBERID IS NOT NULL THEN 1 ELSE 0 END as MotionEligFlag,
							CASE WHEN DERM_Member.ClientMEMBERID IS NOT NULL THEN 1 ELSE 0 END as MotionRegFlag,
							min(firstactivedate) OVER(PARTITION BY A.cust_seg_nbr_combined order by A.cust_seg_nbr_combined)  as EmployerMotionStartDate,
							max(LastActiveDate) OVER(PARTITION BY A.cust_seg_nbr_combined order by A.cust_seg_nbr_combined)  as EmployerMotionEndDate,
							A.ProgramStartDate,m.RowCreatedDateTime,
							A.Fst_Dt as InsuranceEnrollmentStartDate,A.End_Dt as InsuranceEnrollmentEndDate,
							m.FirstActiveDate,
							m.LastActiveDate
INTO    KA_Motion
FROM	morerec																A
join minihpdm..Dim_Customer_Segment														cs			on RTRIM(A.cust_seg_nbr_combined) = cs.CUST_SEG_NBR
join minihpdm..Dim_Group_Indicator														gi			on gi.MKT_SEG_CD = cs.MKT_SEG_CD
left join  (select a.MemberID,
				   a.ClientMemberID,
				   a.RowCreatedDateTime,
		           min(incentiveDate) as FirstActiveDate, 
		           max(IncentiveDate) as LastActiveDate
           from	dermsl_prod.dbo.MEMBER                                           a
		   left join dermsl_prod.dbo.[MEMBEREarnedIncentives]                    b			on a.MEMBERID = b.MEMBERID
           where TotalSteps>0
           and   a.LOOKUPClientID in (175)
           group by a.MemberID,a.ClientMemberID,a.RowCreatedDateTime)			 m			on m.ClientMEMBERID			=	A.ClientMemberID
left join DERMSL_Prod.dbo.MEMBER DERM_Member												on A.ClientMEMBERID			=	DERM_Member.ClientMEMBERID
left join DERMSL_Prod.dbo.LOOKUPRuleGroup										 rg			on A.LOOKUPRuleGroupID      =   rg.LOOKUPRuleGroupID
--left join [DERMSL_Prod].[dbo].[LOOKUPRule]										 r  on r.LOOKUPRuleGroupID		=   A.LOOKUPRuleGroupID
left join Census.dbo.Zip_Census													zip			on zip.Zip					=	A.Zip

select count(*) from pdb_motionenrollmentengagement.[dbo].KA_Motion where clientmemberid is not null
select * from minihpdm..Dim_Customer_Segment where CUST_SEG_NBR = '000713885           '

--exclude duplicate members due to error introduced in joins
drop table #excludemembers
select A.indv_sys_id,A.clientmemberid,A.dependentcode,A.fst_nm,A.lst_nm,A.bth_Dt--,B.ClientMEMBERID,B.FirstName,B.LastName,B.BirthDate,B.DependentCode,B.ParentClientMemberID 
into #excludemembers
from
(select * from #KA_Motion emp
 --left join #excludemembers exmem
 --on emp.ClientMEMBERID = exmem.clientmemberid
where emp.indv_sys_id in (
select indv_sys_id from #KA_Motion
group by indv_sys_id
having count(*)>2)
--and exmem.clientmemberid IS NULL
)A
left join dermsl_prod.dbo.membersignupdata B
on A.ClientMEMBERID=B.ClientMEMBERID
where A.Fst_Nm <> B.FirstName

--select * from #excludemembers

select emp.* 
into #final_final 
from #KA_Motion emp
left join #excludemembers exmem
on emp.ClientMEMBERID = exmem.clientmemberid
where exmem.clientmemberid IS NULL

select indv_sys_id,count(*) from #final_final
group by indv_sys_id
having count(*)>2


--Multiple Rule Groups for same member. 14,586 members have 2 different RuleGroups
select indv_sys_id,fst_nm,lst_nm,bth_dt,count(distinct RuleGroupName) from #final_final
group by indv_sys_id,fst_nm,lst_nm,bth_dt
having count(distinct RuleGroupName) >1

select * from #final_final where INDV_SYS_ID= '22088168'

--Company wise motion enrolled members
select CUST_SEG_NM,counT(*) as total_emp,
		sum(motioneligflag) as cnt_motion_elig,
		ROUND((sum(motioneligflag)*1.0/count(*))*100,1) as per_motion_elig,
		sum(MotionRegFlag) as cnt_motion_reg,
		ROUND((sum(MotionRegFlag)*1.0/sum(motioneligflag))*100,1) as per_motion_reg
from #final_final
group by CUST_SEG_NM
order by per_motion_elig,per_motion_reg

-- 6.7% members from member not present in membersignupdata.
select count(*) from DERMSL_Prod.dbo.membersignupdata A
right join DERMSL_Prod.dbo.MEMBER B
on A.ClientMEMBERID = B.ClientMEMBERID
where A.ClientMEMBERID IS NULL
and B.FirstName not like '%Admin%' 
and B.FirstName not like '%test%'
and B.ClientMEMBERID not in ('')

--- 21 members have different indv_sys_ID but seem to be the same person
select a.Fst_Nm,a.lst_nm,a.Bth_dt,count(*) as tot_emp,min(a.indv_sys_id) as indv_sys_id1,max(a.indv_sys_id) as indv_sys_id2, 
		min(b.ssn) as ssn1,max(b.ssn)as ssn2, case when min(b.ssn)=max(b.ssn) THEN 0 ELSE 1 END as same_ssn,
		case when min(a.indv_sys_id)=max(a.indv_sys_id) THEN 0 ELSE 1 END as same_mem
from #final_final a
inner join MiniHPDM_PHI.dbo.Dim_Member b
on a.INDV_SYS_ID = b.Indv_Sys_Id
group by  a.fst_nm,a.lst_nm,a.Bth_dt 
having case when min(a.indv_sys_id)=max(a.indv_sys_id) THEN 0 ELSE 1 END =1

select * from #final_final where Lst_Nm = 'SUTTERFIELD         ' and Bth_dt = '1967-04-24'
select * from MiniHPDM_PHI.dbo.Dim_Member where Indv_Sys_Id in ('1211191726','1216770777')

----IMP QUERY----
select distinct left(A.clientmemberid,7) from
(select * from dermsl_prod..membersignupdata where left(clientmemberid,6) in (
select A.clnt from (select distinct left(clientmemberid,6) as clnt from dermsl_prod..membersignupdata
where lookupclientid = 175)A
left join (select distinct left(clientmemberid,6) as clnt from (
select * from join1
union
select * from join2) A)B
on A.clnt = b.clnt
where B.clnt IS NULL)) A
left join dermsl_prod..member  B
on A.clientmemberid = B.clientmemberid
where B.clientmemberid is null


-----------Understand data

--4179 members have more than 1 motion accounts but none have been registered. Retain just one record. 
select indv_sys_id
	,count(*) as no_dup_rec
	,sum(motioneligflag) as no_motion_elig
	,sum(motionregflag) as no_motion_reg
from #final_final
group by Indv_Sys_Id
having sum(motionregflag) =0 and count(*)>1 
order by count(*) desc


-- 10353 members with more than 1 motion account but only 1 registered. Retain the one that's registered.
select indv_sys_id,count(*) as num_dup_rec,sum(motioneligflag) as num_motion_elig,sum(motionregflag) as num_motion_reg 
from #final_final
group by Indv_Sys_Id
having count(*)>1 and sum(motionregflag)=1
order by count(*) desc

--56 records having more than 1 motion account and more than one account registerd in motion. Ask Steve to use the most used motion account. 
select indv_sys_id,count(*) as no_dup_rec,sum(motioneligflag) as no_motion_elig,sum(motionregflag) as no_motion_reg 
from #final_final
group by Indv_Sys_Id
having count(*)>1 and sum(MotionRegFlag) >1

--6543 members as subscribers but not motion eligible. Check for Rule Group
select * from #final_final
where Sbscr_Ind = 1 and MotionEligFlag = 0

-- Percentage of subscribers without motion eligible employee wise
select CUST_SEG_NM,sum(CASE WHEN Sbscr_Ind = 1 and MotionEligFlag = 0 THEN 1 ELSE 0 END) as num_emp_without_motion_elig,
				   count(*) as total_emp ,
				   ROUND((SUM(CASE WHEN Sbscr_Ind = 1 and MotionEligFlag = 0 THEN 1 ELSE 0 end)/(count(*)*1.0))*100,0) as per
from #final_final
group by CUST_SEG_NM
order by ROUND((SUM(CASE WHEN Sbscr_Ind = 1 and MotionEligFlag = 0 THEN 1 ELSE 0 end)/(count(*)*1.0))*100,0) desc


select CUST_SEG_NM,count(*) as total_emp from #KA_Motion group by CUST_SEG_NM order by count(*) desc

select									CUST_SEG_NM,
										count(*) as cnt_emp,
										count(firstactivedate) as cnt_walkers,
										sum(motioneligflag) as motion_elig_members,
										sum(MotionRegFlag) as motion_reg_members,
										EmployerMotionStartDate,
										EmployerMotionEndDate,
										datediff(year,EmployerMotionStartDate,EmployerMotionEndDate) as EnrolledinMotion_YY
from #final_final 
group by cust_seg_nm,EmployerMotionStartDate,EmployerMotionEndDate
ORDER BY datediff(year,EmployerMotionStartDate,EmployerMotionEndDate),CUST_SEG_NM desc


----------------------------------------IGNORE CODE----------------------------------------------------------
-------------------------------------------------------------------------------DATA CHECK AND VALIDATION------------------------------------------------------
select indv_sys_id,count(*) from #KA_Motion
group by indv_sys_id
having count(*)>2

select * from KA_Motion where indv_sys_id in ('1459703524','466198904')
select * from #join1 where indv_sys_id in ('1459703524','466198904')
select * from dermsl_prod.dbo.membersignupdata where clientmemberid like '%243552808%'
select * from #KA_Motion
where INDV_SYS_ID = '895435036'



select count(*) from DERMSL_Prod.dbo.MEMBER -- 150,000 members
select count(*) from DERMSL_Prod.dbo.MEMBERSignupData --406,579 members

select * from DERMSL_Prod.dbo.membersignupdata where FirstName = 'LYNN' and LastName = 'CROMPTON' and BirthDate = ''










select distinct cust_seg_nbr_combined from #KA_Motion
where CUST_SEG_NM = 'GRACE MANAGEMENT  INC.                                                                                                  '





--Check if members are found in DERM by their last name and bth_dt. Only 35 possible results. 
select CUST_SEG_NM,count(*) from 
(select * from DERMSL_Prod.dbo.membersignupdata)A
inner join 
(select * from #KA_Motion
where Sbscr_Ind = 1 and MotionEligFlag = 0 )B
on Lst_Nm = LastName AND BTH_DT = BIRTHDATE
--and A.ClientMEMBERID like '%75555%'
group by cust_seg_nm
order by count(*) desc 

--Check if members are found in DERM by their last name and FIRST NAME. 
select B.INDV_SYS_ID,B.Cust_Seg_Sys_Id,C.CUST_SEG_NM,C.CUST_SEG_NBR
	  ,A.LOOKUPClientID,B.Fst_Nm,B.Lst_Nm,B.Bth_dt
	  ,A.FirstName,A.LastName,A.BirthDate,A.SSN,D.Sbscr_Nbr,A.ClientMEMBERID
from (select * from DERMSL_Prod.dbo.membersignupdata)A
inner join 
(select * from #KA_Motion
where Sbscr_Ind = 1 and MotionEligFlag = 0 )B
on Lst_Nm = LastName
AND FirstName = Fst_Nm
INNER JOIN Dim_Customer_Segment C
ON C.CUST_SEG_SYS_ID = B.Cust_Seg_Sys_Id
INNER JOIN MiniHPDM_PHI.DBO.Dim_Member D
ON D.Indv_Sys_Id = B.INDV_SYS_ID
WHERE LOOKUPClientID = 175
ORDER BY FirstName,LastName
AND B.Bth_dt = A.BirthDate
--group by B.cust_seg_nm
--order by count(*) desc 

--ONE E.G WHERE BIRTHDATES DON'T MATCH
SELECT * FROM DERMSL_Prod.DBO.MEMBERSignupData
WHERE FirstName = 'ROBERT' AND LastName = 'PEERY'
SELECT * FROM MiniHPDM_PHI.DBO.Dim_Member A
INNER JOIN Dim_Customer_Segment B
ON A.Cust_Seg_Sys_Id = B.CUST_SEG_SYS_ID
WHERE Fst_Nm =  'ROBERT' AND Lst_Nm = 'PEERY' AND CUST_SEG_NBR LIKE '%91089%'

SELECT * FROM #KA_Motion
WHERE Fst_Nm =  'ROBERT' AND Lst_Nm = 'PEERY'
AND Sbscr_Ind = 1 AND MotionEligFlag = 0

SELECT * FROM Summary_Indv_Demographic A
INNER JOIN Dim_Customer_Segment B
ON A.Cust_Seg_Sys_Id = B.CUST_SEG_SYS_ID
WHERE Indv_Sys_Id = '150598786'
ORDER BY Year_Mo

--ONE E.G WHERE BIRTHDATES MATCH
SELECT * FROM DERMSL_Prod.DBO.MEMBERSignupData
WHERE FirstName = 'YVROSE' AND LastName = 'CIVIL'
SELECT * FROM MiniHPDM_PHI.DBO.Dim_Member A
INNER JOIN Dim_Customer_Segment B
ON A.Cust_Seg_Sys_Id = B.CUST_SEG_SYS_ID
WHERE Fst_Nm =  'YVROSE' AND Lst_Nm = 'CIVIL' AND CUST_SEG_NBR LIKE '%907138%'

SELECT * FROM #KA_Motion
WHERE Fst_Nm =  'YVROSE' AND Lst_Nm = 'CIVIL'
AND Sbscr_Ind = 1 AND MotionEligFlag = 0

SELECT * FROM Summary_Indv_Demographic A
INNER JOIN Dim_Customer_Segment B
ON A.Cust_Seg_Sys_Id = B.CUST_SEG_SYS_ID
WHERE Indv_Sys_Id = '150598786'
ORDER BY Year_Mo

--ONE MORE E.G WHERE FIRST NAME AND Last name match
SELECT * FROM DERMSL_Prod.DBO.MEMBERSignupData
WHERE FirstName = 'ADAM' AND LastName = 'JOHNSON'
/*SELECT * FROM MiniHPDM_PHI.DBO.Dim_Member A
INNER JOIN Dim_Customer_Segment B
ON A.Cust_Seg_Sys_Id = B.CUST_SEG_SYS_ID
WHERE Fst_Nm =  'ADAM' AND Lst_Nm = 'JOHNSON' AND CUST_SEG_NBR LIKE '%9101%'*/

select * from MiniHPDM_PHI.dbo.Dim_Member where Indv_Sys_Id = '82718228'
where Bth_dt = '1974-10-11' and Lst_Nm = 'JOHNSON             '  and Fst_Nm = 'ADAM'

SELECT * FROM #KA_Motion
WHERE Fst_Nm =  'ADAM' AND Lst_Nm = 'JOHNSON'
AND Sbscr_Ind = 1 AND MotionEligFlag = 0

SELECT * FROM Summary_Indv_Demographic A
INNER JOIN Dim_Customer_Segment B
ON A.Cust_Seg_Sys_Id = B.CUST_SEG_SYS_ID
WHERE Indv_Sys_Id = '150598786'
ORDER BY Year_Mo


select CUST_SEG_NM, DependentCode, Sbscr_Ind, 
	count(*) Mbrs,										ShrOfCo = (count(*) / sum(count(*)) over(partition by cust_seg_nm))*1.0,
	sum(MotionEligFlag) MotionEligFlag, 				Shr = 1. * sum(MotionEligFlag) / count(*)--, 
	--sum(isMember) isMember, 							Shr = 1. * sum(isMember) / count(*), 
	--sum(isMemberSignupData) isMemberSignupData,			Shr = 1. * sum(isMemberSignupData) / count(*)
from #KA_Motion
where CUST_SEG_SYS_ID		in (1001126569, 1001180645)
group by grouping sets (
	( CUST_SEG_NM, DependentCode, Sbscr_Ind),
	( CUST_SEG_NM)
	)
order by  CUST_SEG_NM, Mbrs desc

select CUST_SEG_NM,DependentCode,Sbscr_Ind,count(*) as total_mem
,sum(CASE WHEN Sbscr_Ind = 1 and MotionEligFlag = 0 THEN 1 ELSE 0 END) as num_emp_without_motion_elig
from #KA_Motion
where CUST_SEG_SYS_ID		in (1001126569, 1001180645)
group by CUST_SEG_NM,DependentCode,Sbscr_Ind

select CUST_SEG_NM,DependentCode,Sbscr_Ind,count(*) as total_mem
,sum(CASE WHEN Sbscr_Ind = 1 and MotionEligFlag = 0 THEN 1 ELSE 0 END) as num_emp_without_motion_elig
from pdb_MotionEnrollmentEngagement.dbo.MotionProgramMembers
where CUST_SEG_SYS_ID		in (1001126569, 1001180645)
group by CUST_SEG_NM,DependentCode,Sbscr_Ind

select A.Cust_Seg_Sys_Id,A.INDV_SYS_ID,A.CUST_SEG_NM,A.Fst_Nm,A.Lst_Nm,A.Bth_dt,B.Cust_Seg_Sys_Id,C.CUST_SEG_NM,max(year_mo) from #KA_Motion A
inner join Summary_Indv_Demographic B
on A.INDV_SYS_ID = B.Indv_Sys_Id
inner join MiniHPDM.dbo.Dim_Customer_Segment C
on B.Cust_Seg_Sys_Id = C.CUST_SEG_SYS_ID
 where 
A.CUST_SEG_SYS_ID		in ( 1001180645)
and A.Sbscr_Ind = 1 and MotionEligFlag = 0
and C.CUST_SEG_NM like '%MUKILTEO SCHOOL DISTRICT #6                                                                                             %'
group by A.Cust_Seg_Sys_Id,A.INDV_SYS_ID,A.CUST_SEG_NM,A.Fst_Nm,A.Lst_Nm,A.Bth_dt,B.Cust_Seg_Sys_Id, C.CUST_SEG_NM
order by A.INDV_SYS_ID,B.Cust_Seg_Sys_Id,max(year_mo) desc

select count(distinct clientmemberid) from 
(select Indv_Sys_Id,max(year_mo) as year_mo
from MiniHPDM.dbo.Summary_Indv_Demographic
where Cust_Seg_Sys_Id in (1001180645)
group by Indv_Sys_Id
having max(year_mo) = 201710)A
inner join #KA_Motion B
on A.Indv_Sys_Id = B.INDV_SYS_ID

select A.INDV_SYS_ID,A.Fst_Nm,A.Lst_Nm,A.Bth_dt,DATEDIFF(year,A.Bth_dt,GETDATE())
,A.Cust_Seg_Sys_Id,B.Cust_Seg_Sys_Id
,min(B.year_mo) as start_of_emp,max(B.year_mo) as end_of_emp,max(C.Year_Mo) as employers_lastMonth from #KA_Motion A
inner join Summary_Indv_Demographic B
on A.INDV_SYS_ID = B.Indv_Sys_Id
inner join Dim_CustSegSysId_Detail C
on B.Cust_Seg_Sys_Id = C.Cust_Seg_Sys_Id
where A.Cust_Seg_Sys_Id = B.Cust_Seg_Sys_Id
and A.Sbscr_Ind = 1 and MotionEligFlag = 0
group by A.INDV_SYS_ID,A.Fst_Nm,A.Lst_Nm,A.Bth_dt,A.Cust_Seg_Sys_Id,B.Cust_Seg_Sys_Id,DATEDIFF(year,A.Bth_dt,GETDATE())
order by A.Bth_dt--A.Cust_Seg_Sys_Id,max(B.Year_Mo),max(C.Year_Mo)

select * from (
select *,CASE WHEN count(CUST_SEG_NM) OVER (PARTITION BY grouping ORDER BY grouping) >0 THEN 1 ELSE 0 END as groups from (
select B.CUST_SEG_NM,B.LOOKUPRuleGroupID as LOOKUPRuleGroupID1,A.RuleGroupName,A.LOOKUPRuleGroupID as LOOKUPRuleGroupID2,
 LEFT(UPPER(A.RuleGroupName),5) as grouping
 from 
DERMSL_Prod.dbo.LOOKUPRuleGroup A left join 
(select distinct CUST_SEG_NM,LOOKUPRuleGroupID from #KA_Motion A
inner join MiniHPDM_PHI.dbo.Dim_Member B
on A.INDV_SYS_ID = B.Indv_Sys_Id
inner join DERMSL_Prod.dbo.MEMBERSignupData C
on A.ClientMEMBERID = C.ClientMEMBERID
where A.Sbscr_Ind = 1 and A.MotionEligFlag = 1) B
on A.LOOKUPRuleGroupID = B.LOOKUPRuleGroupID)A
)B
where groups>0
order by rulegroupname


select * from DERMSL_Prod.dbo.LOOKUPRuleGroup where RuleGroupName like '%ACES POWER MARKETING%'

select FirstName,LastName,BirthDate,A.ClientMEMBERID,A.LOOKUPRuleGroupID,m.FirstActiveDate,m.LastActiveDate,C.GroupStartDatetime,C.GroupEndDatetime--,RuleGroup1Flag,RuleGroup2Flag,RuleGroup3Flag, 
from DERMSL_Prod.dbo.MEMBERSignupData A
inner join (select a.MemberID,
				   a.ClientMemberID,
		           min(incentiveDate) as FirstActiveDate, 
		           max(IncentiveDate) as LastActiveDate
           from	dermsl_prod.dbo.MEMBER                                           a
		   left join dermsl_prod.dbo.[MEMBEREarnedIncentives]                    b	on a.MEMBERID = b.MEMBERID
           where TotalSteps>0
           and   a.LOOKUPClientID in (175)
           group by a.MemberID,a.ClientMemberID)								 m  on m.ClientMEMBERID			=	A.ClientMemberID
inner join DERMSL_Prod.dbo.LOOKUPRuleGroup C
on C.lookupRuleGroupID = A.LOOKUPRuleGroupID
where A.LOOKUPRuleGroupID in (5518,10091,10092,10093,10094,10095,10096)
--group by firstname,lastname,birthdate,LOOKUPRuleGroupID
order by firstname,lastname,birthdate,LOOKUPRuleGroupID

select * from DERMSL_Prod.dbo.LOOKUPRuleGroup

select * from INFORMATION_SCHEMA.COLUMNS
where column_name like '%rulegroup%'
order by table_name

select * from
(select * from #KA_Motion where indv_sys_id in (select indv_sys_id--,count(*) as no_dup_rec,sum(motioneligflag) as no_motion_elig,sum(motionregflag) as no_motion_reg 
														from #KA_Motion group by Indv_Sys_Id
														having count(*)>1 and sum(MotionRegFlag) >1)
) A
left join (select a.MemberID,
				   a.ClientMemberID,
		           min(incentiveDate) as FirstActiveDate, 
		           max(IncentiveDate) as LastActiveDate
           from	dermsl_prod.dbo.MEMBER                                           a
		   left join dermsl_prod.dbo.[MEMBEREarnedIncentives]                    b	on a.MEMBERID = b.MEMBERID
           where TotalSteps>0
           and   a.LOOKUPClientID in (175)
           group by a.MemberID,a.ClientMemberID)								 m  on m.ClientMEMBERID			=	A.ClientMemberID
		   order by LOOKUPRuleGroupID,Fst_Nm,Lst_Nm,Bth_dt

--CHECK IF RULE GROUP IS CONSISTENT
select CUST_SEG_NM,LOOKUPRuleGroupID,RuleGroupName,GroupStartDatetime,GroupEndDatetime,count(*) from #KA_Motion
group by CUST_SEG_NM,LOOKUPRuleGroupID,RuleGroupName,GroupStartDatetime,GroupEndDatetime
ORDER BY CUST_SEG_NM,LOOKUPRuleGroupID,RuleGroupName,GroupStartDatetime,GroupEndDatetime

 

select * from MEMBER where FirstName = 'PRAJAKTA' and lastname = 'PATIL              ' and BirthDate = '1990-12-15'
select * from MEMBEREarnedIncentives where memberid in (82649) 
select * from #KA_Motion
select * from [pdb_MotionEnrollmentEngagement].[dbo].[MotionProgramMembers]

select iq.CUST_SEG_NBR,iq.CUST_SEG_NM,count(*)
from DERMSL_Prod.dbo.MEMBERSignupData msd
join (select distinct RIGHT(RTRIM(a.CUST_SEG_NBR),6) as  CUST_SEG_NBR,a.CUST_SEG_NM
from #KA_Motion a
inner join dim_customer_segment cs on a.Cust_Seg_Sys_Id = cs.CUST_SEG_SYS_ID) iq
on msd.ClientMEMBERID like '%'+CUST_SEG_NBR+'%'
group by iq.CUST_SEG_NBR,iq.CUST_SEG_NM
order by CUST_SEG_NM

select cust_seg_nm,count(*) from #KA_Motion
where ClientMEMBERID IS NOT NULL
group by cust_seg_nm
order by CUST_SEG_NM

select * from #KA_Motion
where CUST_SEG_NM like '%AMERICAN METAL TECHNOLOGIES  LLC                                                                                        %'
and clientmemberid is not null
order by ClientMEMBERID

select * from DERMSL_Prod.dbo.MEMBERSignupData
where ClientMEMBERID like '%910132%'
order by ClientMEMBERID

select * from MiniHPDM_PHI.dbo.Dim_Member where fst_nm = 'CRAIG' and lst_nm = 'BAYER' and bth_dt = '1958-09-16'
select * from Dim_Customer_Segment where CUST_SEG_SYS_ID = '1001368497'
select * from Dim_Group_Indicator where MKT_SEG_RLLP_DESC like '%KEY%'--MKT_SEG_CD = 'M'
select *--count(*)--Indv_Sys_Id,count(distinct cust_seg_nbr),count(distinct orig_eff_dt) 
from Summary_Indv_Demographic a
join Dim_Customer_Segment b 
on a.cust_seg_sys_id = b.CUST_SEG_SYS_ID 
where Indv_Sys_Id = '904067186'



select Indv_Sys_Id,count(distinct Cust_Seg_Sys_Id) 
from #emp_hist 
group by Indv_Sys_Id
order by count(distinct Cust_Seg_Sys_Id) desc

drop table #pvt_emp_hist
select *,[1] as comp1,[2] as comp2,[3] as comp3,[4] as comp4,[5] as comp5
into #pvt_emp_hist
from (select *
			from 
			(select Indv_Sys_Id,CAST(CUST_SEG_NBR as VARCHAR(20)) as CUST_SEG_NBR,CAST(Cust_Seg_Sys_Id as VARCHAR(20)) as Cust_Seg_Sys_Id,cnt_emp from #emp_hist)query
			unpivot 
			(Customer for customers in (cust_seg_sys_id,cust_seg_nbr))p )A
PIVOT(
MIN(Customer) for customers in ([Cust_Seg_Sys_Id],[CUST_SEG_NBR])
) as P1
PIVOT(
MIN(Customer) FOR cnt_emp in ([1],[2],[3],[4],[5])
) as P2

select * from #tmp where comp3 is not null--Indv_Sys_Id = '1022026286'
select * from  #emp_hist order by cnt_emp desc,Indv_Sys_Id
select * from #emp_hist where Indv_Sys_Id = '1022026286'
select * from #pvt_emp_hist


select *
from 
(select Indv_Sys_Id,CAST(CUST_SEG_NBR as VARCHAR(20)) as CUST_SEG_NBR,CAST(Cust_Seg_Sys_Id as VARCHAR(20)) as Cust_Seg_Sys_Id,cnt_emp from #emp_hist)query
unpivot 
(Customer for customers in (cust_seg_sys_id,cust_seg_nbr))p

select * from #t where Indv_Sys_Id = '1022026286'



select * from #pvt_emp_hist where comp2 is not null



---------------------------------------------------------------
--1600(2.7%) records out of 58330 records not found in MiniHPDM
select mq.CUST_SEG_NM,mq.count,DERM.cust_seg_nm,DERM.count,DERM.count-mq.count from 
(select CUST_SEG_NM,count(*) as count from #KA_Motion my_query
where ClientMEMBERID IS NOT NULL
group by CUST_SEG_NM)mq
join (select CUST_SEG_NM,count(*) as count from dermsl_prod.dbo.MEMBERSignupData DERM
									join Dim_Customer_Segment b
									on ClientMEMBERID like '%'+RIGHT(convert(varchar,RTRIM(cust_seg_nbr)),6)+'%'
									where CUST_SEG_SYS_ID IN (1001448566,1001369883,1001432591,1001301130,1001126569,1001432588,1001441834,1001410596,1001330628,1001416828,1001359155,1001247016,1001366492,1001442267,1001436820,1001361294,
									1001431021,1001367463,1001412501,1001345737,1001171325,1001300276,1001334219,1001365457,1001298089,1001405700,1001441847,1001411016,1001368497,1001441845,1001340042,1001414603,1001412499,1001426780,1001374818,1001357011,
									1001360280,1001412497,1001374827,1001430531,1001431015,1001317387,1001411218,1001379648,1001426521,1001373225,1001376617,1001180645,1001365451,1001368468,1000930227,1001335863,1001405037,1001298986,1001423446,
									1001414604,1001368487,1001428215,1001382273,1001450752,1001423444,1001367008,1001334711,1001291591,1001365852,1001363244,1001410592,1001346525,1001249502,1001362383,1001410590,1001381407,1001247974,1001427550,
									1001296192,1001424728,1001237512,1001332574,1001423706,1001346729,1001370462,1001333376,1001249712,1001346280,1001345441,1001436293,1001335449,1001347715,1001410838,1001414983,1001442076,1001357611,1001364930,
									1001418879)
group by CUST_SEG_NM)DERM
on mq.cust_seg_nm = DERM.cust_seg_nm
where mq.count<> DERM.count
order by DERM.count-mq.count
 --where CUST_SEG_NM = 'AMERICAN METAL TECHNOLOGIES  LLC                                                                                        '

 select * from #KA_Motion

select * from Dim_Customer_Segment where CUST_SEG_NM = 'MORTGAGE CONNECT  LP                                                                                                    '

drop table #checkmem
select top 1 B.* into #checkmem from (select * from DERMSL_Prod.dbo.MEMBERSignupData where ClientMEMBERID like '%910129%')B
left join (
			select * from #KA_Motion where CUST_SEG_NM = 'MORTGAGE CONNECT  LP                                                                                                    '
			and clientmemberid is not null
			)A
on A.clientmemberid = B.clientmemberid
where A.ClientMEMBERID IS NULL
ORDER BY NEWID()

select * from #checkmem



select * from MiniHPDM_PHI.dbo.Dim_Member join #checkmem
on Fst_Nm = FirstName and Lst_Nm = LastName and Bth_dt = BirthDate
 --where fst_nm = 'ELIZABETH' and Lst_Nm = 'RECESKI' and Bth_dt = '1982-02-04'

 select * from #KA_Motion where INDV_SYS_ID = '904067186'--firstname = 'LYNN' and Lst_Nm = 'LITALIEN' and Bth_dt = '1967-12-09'

 select * from Summary_Indv_Demographic where Indv_Sys_Id = '904067186' order by Year_Mo

 select * from DERMSL_Prod.dbo.MEMBERSignupData where ClientMEMBERID like '%911145%' order by ClientMEMBERID

 select Fst_Nm,Lst_Nm,Bth_dt,count(*) from #KA_Motion group by Fst_Nm,Lst_Nm,Bth_dt having count(*)>1
 select * from #KA_Motion



 ---Galaxy table ------
 select A.indv_sys_id,A.cust_seg_sys_id,A.sbscr_ind,dependentcode,lookuprulegroupid,rulegroupid,rulegroupname,
motioneligflag, motionregflag, B.indv_sys_id,B.cust_seg_sys_id,
B.Eff_dt,B.end_dt, B.med_prdct_1_cd,pln_var_subdiv_cd,rpt_cd_br_cd,'', *
 from pdb_motionenrollmentengagement.[dbo].KA_Motion A 
left join [DBSEP3859].[GALAXY].[dbo].[Member_Coverage_Month]  B
on A.indv_sys_id = B.indv_sys_id
where cust_seg_nm like 'BRAVO! GROUP SERVICES'
and A.sbscr_ind = 1 and motioneligflag = 1
--and B.cust_seg_sys_id = '1000930227'
order by A.indv_sys_id

select A.cust_Seg_nm,A.sbscr_ind as sbscr_ind_A,A.motionEligFlag,A.motionRegFlag,B.*  into #a
 from [DBSEP3832].[pdb_motionenrollmentengagement].[dbo].KA_Motion A 
left join [DBSEP3859].[GALAXY].[dbo].[Member_Coverage_Month]  B
on A.indv_sys_id = B.indv_sys_id


select cust_seg_nm,sum(sbscr_ind),sum(motioneligflag) from KA_Motion
group by cust_seg_nm
having sum(motioneligflag)>0

select sum(sbscr_ind),sum(motioneligflag) from KA_Motion
having sum(motioneligflag)>0

select case when sbscr_ind = 1 and motioneligflag = 0 then INDV_SYS_ID end as sbscr_notmotion,
case when sbscr_ind = 1 and motioneligflag = 1 then 1 else 0 end as sbscr_motion
from KA_Motion
where cust_Seg_nm in (
select cust_seg_nm from KA_Motion
group by cust_seg_nm
having sum(motioneligflag)>1)
group by INDV_SYS_ID
having count(*)>1
order by count(*) desc


select cust_seg_nm,count(Sbscr_Ind),sum(motioneligflag) from KA_Motion
group by cust_seg_nm
having sum(motioneligflag)=1


