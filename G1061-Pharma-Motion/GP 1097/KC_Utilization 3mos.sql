/*** 
GP 1097 - Polypharmacy Utilization

Input databases:	MiniPAPI, MiniOV

Date Created: 13 July 2017
***/

--pull for RX Spend
If (object_id('tempdb..#rx_spend') Is Not Null)
Drop Table #rx_spend
go

select b.SavvyHICN, d.YEAR_MO
	, RX_Allow = sum(c.Allowed)
into #rx_spend
from pdb_PharmaMotion..G1097Members_3mos	a
inner join MiniPAPI..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims			c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date				d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
where d.YEAR_MO in (201610, 201611, 201612)
	and c.Claim_Status = 'P'
group by b.SavvyHICN, d.YEAR_MO
--(4,728,690 row(s) affected); 
create unique index uIx_SavvyHICN_YM on #rx_spend (SavvyHICN, YEAR_MO);

If (object_id('tempdb..#ip_days') Is Not Null)
Drop Table #ip_days
go

select a.SavvyHICN, a.SavvyID, b.DT_SYS_ID
into #ip_days
from	(
			select b.SavvyHICN, b.SavvyID
				, Admit_DtSys		= c.DT_SYS_ID
				, Discharge_DtSys	= e.DT_SYS_ID
				, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
			--into #ip_conf
			from pdb_PharmaMotion..G1097Members_3mos	a
			inner join MiniOV..SavvyID_to_SavvyHICN	b	on	a.SavvyHICN = b.SavvyHICN
			inner join MiniOV..Fact_Claims			c	on	b.SavvyID = c.SavvyId
			inner join MiniOV..Dim_Date				d	on	c.Dt_Sys_Id = d.DT_SYS_ID
			inner join MiniOV..Dim_Date				e	on	(c.Dt_Sys_Id + c.Day_Cnt) = e.DT_SYS_ID
			where d.YEAR_MO in (201610, 201611, 201612)
				and c.Admit_Cnt = 1
			group by b.SavvyHICN, b.SavvyID, c.DT_SYS_ID, e.DT_SYS_ID
		) a
inner join MiniOV..Dim_Date		b	on	b.DT_SYS_ID between Admit_DtSys and Discharge_DtSys
group by a.SavvyHICN, a.SavvyID, b.DT_SYS_ID
--(131,995 row(s) affected); 
create unique index uIx_SavvyID_DtSys on #ip_days (SavvyID, DT_SYS_ID);


If (object_id('pdb_PharmaMotion..G1097_utilization_3mos') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_utilization_3mos
go

select a.SavvyHICN, a.YEAR_MO, a.Cnt_AHFS, a.Prov_Cnt_AHFS
	, IP_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	end), 0)
	, OP_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	end), 0)
	, DR_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	end), 0)
	, ER_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	end), 0)
	, RX_Allow = max(isnull(c.RX_Allow, 0))
	, Total_Allow = sum(isnull(Allw_Amt, 0)) + max(isnull(c.RX_Allow, 0))
	, IP_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Dt_Sys_Id	end), 0)
	, IP_Days	= isnull(sum(case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Day_Cnt	end), 0)
	, OP_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'OP' then Dt_Sys_Id	end), 0)
	, DR_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'DR' then Dt_Sys_Id	end), 0)
	, ER_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'ER' then Dt_Sys_Id	end), 0)
into pdb_PharmaMotion..G1097_utilization_3mos
from	(--assign year months
			select distinct a.SavvyHICN
				, b.YEAR_MO
				, Cnt_AHFS		= case when b.YEAR_MO = 201610	then a.Cnt_AHFS_Oct2016
										when b.YEAR_MO = 201611	then a.Cnt_AHFS_Nov2016	else a.Cnt_AHFS_Dec2016	end
				, Prov_Cnt_AHFS = case when b.YEAR_MO = 201610	then a.Prov_Cnt_Oct2016
										when b.YEAR_MO = 201611	then a.Prov_Cnt_Nov2016	else a.Prov_Cnt_Dec2016	end
			from pdb_PharmaMotion..G1097Members_3mos	a
			inner join MiniOV..Dim_Date					b	on b.YEAR_MO in (201610, 201611, 201612)
		)	a
left join	(
				select b.SavvyHICN, c.Clm_Aud_Nbr, c.Admit_Cnt, c.Day_Cnt, c.Dt_Sys_Id, c.Allw_Amt
					, Derived_Srvc_Type_cd = case when h.SavvyID is not null and f.Srvc_Typ_Cd <> 'IP'		then 'IP'  
												  when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'	else 	f.Srvc_Typ_Cd	end
					, d.YEAR_MO
				from pdb_PharmaMotion..G1097Members_3mos	a
				inner join MiniOV..SavvyID_to_SavvyHICN				b	on	a.SavvyHICN = b.SavvyHICN
				inner join MiniOV..Fact_Claims						c	on	b.SavvyID = c.SavvyId
				inner join MiniOV..Dim_Date							d	on	c.Dt_Sys_Id = d.DT_SYS_ID
				inner join MiniOV..Dim_HP_Service_Type_Code			e	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = e.HLTH_PLN_SRVC_TYP_CD_SYS_ID
				inner join MiniOV..Dim_Service_Type					f	on	c.Srvc_Typ_Sys_Id = f.Srvc_Typ_Sys_Id
				inner join MiniOV..Dim_Procedure_Code				g	on	c.Proc_Cd_Sys_Id = g.PROC_CD_SYS_ID
				left join #ip_days									h	on	b.SavvyID = h.SavvyID
																		and c.Dt_Sys_Id = h.DT_SYS_ID
				where d.YEAR_MO in (201610, 201611, 201612)
				group by b.SavvyHICN, c.Clm_Aud_Nbr, c.Admit_Cnt, c.Day_Cnt, c.Dt_Sys_Id, c.Allw_Amt
					, h.SavvyID, f.Srvc_Typ_Cd, e.HCE_SRVC_TYP_DESC
			) b	on	a.SavvyHICN = b.SavvyHICN
				and a.YEAR_MO = b.YEAR_MO
left join #rx_spend	c	on	a.SavvyHICN = c.SavvyHICN
						and a.YEAR_MO = c.YEAR_MO
--where a.SavvyHICN = 406452
group by a.SavvyHICN, a.YEAR_MO, a.Cnt_AHFS, a.Prov_Cnt_AHFS
--(6,519,798 row(s) affected); 46.34 minutes

select *
from pdb_PharmaMotion..G1097_utilization_3mos
order by 1, 2

select avg(IP_Visits), avg(IP_Days), avg(IP_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where IP_Visits > 0

select avg(OP_Visits), avg(OP_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where OP_Visits > 0

select avg(DR_Visits), avg(DR_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where DR_Visits > 0

select avg(ER_Visits), avg(ER_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where ER_Visits > 0

select avg(RX_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where RX_Allow > 0


----------------------------------
--utilization for AHFS with no exclusions
----------------------------------
--pull for RX Spend
If (object_id('tempdb..#rx_spend_w_unk') Is Not Null)
Drop Table #rx_spend_w_unk
go

select b.SavvyHICN, d.YEAR_MO
	, RX_Allow = sum(c.Allowed)
into #rx_spend_w_unk
from pdb_PharmaMotion..G1097Members_3mos_w_unk	a
inner join MiniPAPI..SavvyID_to_SavvyHICN		b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniPAPI..Fact_Claims				c	on	b.SavvyID = c.SavvyId
inner join MiniPAPI..Dim_Date					d	on	c.Date_Of_Service_DtSysId = d.DT_SYS_ID
where d.YEAR_MO in (201610, 201611, 201612)
	and c.Claim_Status = 'P'
group by b.SavvyHICN, d.YEAR_MO
--(4,728,690 row(s) affected); 
create unique index uIx_SavvyHICN_YM on #rx_spend_w_unk (SavvyHICN, YEAR_MO);

If (object_id('tempdb..#ip_conf_w_unk') Is Not Null)
Drop Table #ip_conf_w_unk
go

select b.SavvyHICN, b.SavvyID
	, Admit_DtSys		= c.DT_SYS_ID
	, Discharge_DtSys	= e.DT_SYS_ID
	, Conf_ID			= row_number() over (partition by b.SavvyHICN	order by c.Dt_Sys_ID)
into #ip_conf_w_unk
from pdb_PharmaMotion..G1097Members_3mos_w_unk	a
inner join MiniOV..SavvyID_to_SavvyHICN			b	on	a.SavvyHICN = b.SavvyHICN
inner join MiniOV..Fact_Claims					c	on	b.SavvyID = c.SavvyId
inner join MiniOV..Dim_Date						d	on	c.Dt_Sys_Id = d.DT_SYS_ID
inner join MiniOV..Dim_Date						e	on	(c.Dt_Sys_Id + c.Day_Cnt) = e.DT_SYS_ID
where d.YEAR_MO in (201610, 201611, 201612)
	and c.Admit_Cnt = 1
group by b.SavvyHICN, b.SavvyID, c.DT_SYS_ID, e.DT_SYS_ID
--(131,995 row(s) affected); 
create unique index uIx_SavvyID_DtSys on #ip_conf_w_unk (SavvyID, Admit_DtSys, Discharge_DtSys);


If (object_id('pdb_PharmaMotion..G1097_utilization_3mos_w_unk') Is Not Null)
Drop Table pdb_PharmaMotion..G1097_utilization_3mos_w_unk
go

select a.SavvyHICN, a.YEAR_MO, a.Cnt_AHFS, a.Prov_Cnt_AHFS
	, IP_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'IP'	then Allw_Amt	end), 0)
	, OP_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'OP'	then Allw_Amt	end), 0)
	, DR_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'DR'	then Allw_Amt	end), 0)
	, ER_Allow = isnull(sum(case when Derived_Srvc_Type_cd = 'ER'	then Allw_Amt	end), 0)
	, RX_Allow = max(isnull(c.RX_Allow, 0))
	, Total_Allow = sum(isnull(Allw_Amt, 0)) + max(isnull(c.RX_Allow, 0))
	, IP_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Dt_Sys_Id	end), 0)
	, IP_Days	= isnull(sum(case when Derived_Srvc_Type_cd = 'IP' and Admit_Cnt = 1	then Day_Cnt	end), 0)
	, OP_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'OP' then Dt_Sys_Id	end), 0)
	, DR_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'DR' then Dt_Sys_Id	end), 0)
	, ER_Visits = isnull(count(distinct case when Derived_Srvc_Type_cd = 'ER' then Dt_Sys_Id	end), 0)
into pdb_PharmaMotion..G1097_utilization_3mos_w_unk
from	(--assign year months
			select distinct a.SavvyHICN
				, b.YEAR_MO
				, Cnt_AHFS		= case when b.YEAR_MO = 201610	then a.Cnt_AHFS_Oct2016
										when b.YEAR_MO = 201611	then a.Cnt_AHFS_Nov2016	else a.Cnt_AHFS_Dec2016	end
				, Prov_Cnt_AHFS = case when b.YEAR_MO = 201610	then a.Prov_Cnt_Oct2016
										when b.YEAR_MO = 201611	then a.Prov_Cnt_Nov2016	else a.Prov_Cnt_Dec2016	end
			from pdb_PharmaMotion..G1097Members_3mos_w_unk	a
			inner join MiniOV..Dim_Date						b	on b.YEAR_MO in (201610, 201611, 201612)
		)	a
left join	(
				select b.SavvyHICN, c.*
					, Derived_Srvc_Type_cd = case when h.SavvyID is not null and f.Srvc_Typ_Cd <> 'IP'		then 'IP'  
												  when e.HCE_SRVC_TYP_DESC in ('ER', 'Emergency Room')		then 'ER'	else 	f.Srvc_Typ_Cd	end
					, d.YEAR_MO
				from pdb_PharmaMotion..G1097Members_3mos_w_unk	a
				inner join MiniOV..SavvyID_to_SavvyHICN				b	on	a.SavvyHICN = b.SavvyHICN
				inner join MiniOV..Fact_Claims						c	on	b.SavvyID = c.SavvyId
				inner join MiniOV..Dim_Date							d	on	c.Dt_Sys_Id = d.DT_SYS_ID
				inner join MiniOV..Dim_HP_Service_Type_Code			e	on	c.Hlth_Pln_Srvc_Typ_Cd_Sys_ID = e.HLTH_PLN_SRVC_TYP_CD_SYS_ID
				inner join MiniOV..Dim_Service_Type					f	on	c.Srvc_Typ_Sys_Id = f.Srvc_Typ_Sys_Id
				inner join MiniOV..Dim_Procedure_Code				g	on	c.Proc_Cd_Sys_Id = g.PROC_CD_SYS_ID
				left join #ip_conf									h	on	b.SavvyID = h.SavvyID
																		and c.Dt_Sys_Id between h.Admit_DtSys and h.Discharge_DtSys
				where d.YEAR_MO in (201610, 201611, 201612)
			) b	on	a.SavvyHICN = b.SavvyHICN
				and a.YEAR_MO = b.YEAR_MO
left join #rx_spend	c	on	a.SavvyHICN = c.SavvyHICN
						and a.YEAR_MO = c.YEAR_MO
where a.SavvyHICN = 406452
group by a.SavvyHICN, a.YEAR_MO, a.Cnt_AHFS, a.Prov_Cnt_AHFS
--(6,519,798 row(s) affected); 47.10 minutes


select *
from pdb_PharmaMotion..G1097_utilization_3mos
where SavvyHICN = 406452
order by 1, 2

select *
from pdb_PharmaMotion..G1097_utilization_3mos_w_unk
where SavvyHICN = 406452
order by 1, 2

select avg(IP_Visits), avg(IP_Days), avg(IP_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos_w_unk
where IP_Visits > 0

select avg(OP_Visits), avg(OP_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where OP_Visits > 0

select avg(DR_Visits), avg(DR_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where DR_Visits > 0

select avg(ER_Visits), avg(ER_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where ER_Visits > 0

select avg(RX_Allow)
from pdb_PharmaMotion..G1097_utilization_3mos
where RX_Allow > 0