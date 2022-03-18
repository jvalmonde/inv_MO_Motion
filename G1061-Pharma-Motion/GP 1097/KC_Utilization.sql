/*** 
GP 1097 - Polypharmacy Utilization

Input databases:	MiniPAPI, MiniOV

Date Created: 13 July 2017
***/

--pull for RX Spend
If (object_id('tempdb..#rx_spend') Is Not Null)
Drop Table #rx_spend
go

select b.SavvyHICN
	, RX_Allow = sum(c.Allowed)
into #rx_spend
from pdb_PharmaMotion..G1097_RAF_2016		a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
where d.YEAR_MO = 201612
	and c.Claim_Status = 'P'
group by b.SavvyHICN
--(1,559,359 row(s) affected); 15.32 minutes
create unique index uIx_SavvyHICN on #rx_spend (SavvyHICN);

If (object_id('tempdb..#ip_conf') Is Not Null)
Drop Table #ip_conf
go

select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= c.DT_SYS_ID
	, Discharge_DtSys	= e.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf
from pdb_PharmaMotion..G1097_RAF_2016		a
inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.UniqueMemberID = b.SavvyHICN
inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID
inner join MiniOV..Dim_Date				e	on	(c.Dt_Sys_Id + c.Day_Cnt) = e.DT_SYS_ID
where d.YEAR_MO = 201612
	and c.Admit_Cnt = 1
group by b.SavvyHICN, b.SavvyID, c.DT_SYS_ID, e.DT_SYS_ID
--(47,027 row(s) affected); 36.07 minutes
create unique index uIx_SavvyID_DtSys on #ip_conf (SavvyID, Admit_DtSys, Discharge_DtSys);


If (object_id('pdb_PharmaMotion..G1097_utilization') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_utilization
go

select a.SavvyHICN, a.Cnt_AHFS_201612
	, IP_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	end), 0)
	, OP_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	end), 0)
	, DR_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	end), 0)
	, ER_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	end), 0)
	, RX_Allow = max(isnull(c.RX_Allow, 0))
	, Total_Allow = sum(isnull(Allw_Amt, 0)) + max(isnull(c.RX_Allow, 0))
	--, Total_Allow2 = (
	--					isnull(sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	end),0)	+
	--					isnull(sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	end),0)	+
	--					isnull(sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	end),0)	+
	--					isnull(sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	end),0)	+
	--					max(isnull(c.RX_Allow, 0))
	--				)
	, IP_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Dt_Sys_Id	end), 0)
	, IP_Days	= isnull(sum(case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Day_Cnt	end), 0)
	, OP_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'OP' then Dt_Sys_Id	end), 0)
	, DR_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'DR' then Dt_Sys_Id	end), 0)
	, ER_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'ER' then Dt_Sys_Id	end), 0)
into pdb_PharmaMotion..G1097_utilization
from pdb_PharmaMotion..G1097Members	a
left join	(
				select b.SavvyHICN, c.Clm_Aud_Nbr, c.Admit_Cnt, c.Day_Cnt, c.Dt_Sys_Id, c.Allw_Amt
					, Derived_Srvc_Type_cd = case when h.SavvyID is not null and f.Srvc_Typ_Cd <> 'IP'		then 'IP'  
												  when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'	else 	f.Srvc_Typ_Cd	end
				from pdb_PharmaMotion..G1097_RAF_2016	a
				inner join MiniOV..SavvyID_to_SavvyHICN				b	on	a.UniqueMemberID = b.SavvyHICN
				inner join MiniOV..Fact_Claims						c	on	b.SavvyID = c.SavvyId
				inner join MiniOV..Dim_Date							d	on	c.Dt_Sys_Id = d.DT_SYS_ID
				inner join MiniOV..Dim_HP_Service_Type_Code			e	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = e.HLTH_PLN_SRVC_TYP_CD_SYS_ID
				inner join MiniOV..Dim_Service_Type					f	on	c.Srvc_Typ_Sys_Id = f.Srvc_Typ_Sys_Id
				inner join MiniOV..Dim_Procedure_Code				g	on	c.Proc_Cd_Sys_Id = g.PROC_CD_SYS_ID
				left join #ip_conf									h	on	b.SavvyID = h.SavvyID
																		and c.Dt_Sys_Id between h.Admit_DtSys and h.Discharge_DtSys
				where d.YEAR_MO = 201612
					--and b.SavvyHICN = 3615397
				group by b.SavvyHICN, c.Clm_Aud_Nbr, c.Admit_Cnt, c.Day_Cnt, c.Dt_Sys_Id, c.Allw_Amt
					, h.SavvyID, f.Srvc_Typ_Cd, e.HCE_SRVC_TYP_DESC
			) b	on	a.SavvyHICN = b.SavvyHICN
left join #rx_spend	c	on	a.SavvyHICN = c.SavvyHICN
--where a.SavvyHICN = 3615397
group by a.SavvyHICN, a.Cnt_AHFS_201612
--(2,173,266 row(s) affected); 1.17 hours

select count(*) from pdb_PharmaMotion..G1097Members	--2,173,266

--test queries
select *
from pdb_PharmaMotion..G1097_utilization

select avg(IP_Visits), avg(IP_Allow)
from pdb_PharmaMotion..G1097_utilization
where IP_Visits > 0

select avg(OP_Visits), avg(OP_Allow)
from pdb_PharmaMotion..G1097_utilization
where OP_Visits > 0

select avg(DR_Visits), avg(DR_Allow)
from pdb_PharmaMotion..G1097_utilization
where DR_Visits > 0

select avg(ER_Visits), avg(ER_Allow)
from pdb_PharmaMotion..G1097_utilization
where ER_Visits > 0

/* when Mbr table was updated, this was not updated
update pdb_PharmaMotion..G1097_utilization	
set Cnt_AHFS_201612 = b.Cnt_AHFS_201612
from pdb_PharmaMotion..G1097_utilization	a
left join pdb_PharmaMotion..G1097Members	b	on	a.SavvyHICN = b.SavvyHICN
*/