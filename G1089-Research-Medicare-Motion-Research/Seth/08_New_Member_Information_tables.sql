USE pdb_WalkandWin /*...on DBSEP3832*/
GO

-- drop table #member_List_initial
IF object_id('wkg_member_List_initial_2016_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_2016_Pilot;
select 
	a.SavvyHICN, 
	a.SavvyID_OV,
	a.is2016,
	a.is2017,
	b.MM_2007,
	b.MM_2008,
	b.MM_2009,
	b.MM_2010,
	b.MM_2011,
	b.MM_2012,
	b.MM_2013,
	b.MM_2014,
	b.MM_2015,
	b.MM_2016, 
	b.MM_2017
into wkg_member_List_initial_2016_Pilot
from 
	CombinedMember_sg		as a
	join MiniOV..Dim_Member	as b on a.SavvyID_OV = b.SavvyID
where 
	(MM_2014 + MM_2015) < 24
	and (MM_2006 + MM_2007 + MM_2008 + MM_2009 + MM_2010 + MM_2011 + MM_2012 + MM_2013) = 0
	and a.is2016		=	1
go
create clustered index cixSavvyHICN on wkg_member_List_initial_2016_Pilot(SavvyHICN)
go

IF object_id('wkg_member_List_initial_2017_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_2017_Pilot;
select 
	a.SavvyHICN, 
	a.SavvyID_OV,
	a.is2016,
	a.is2017,
	b.MM_2007,
	b.MM_2008,
	b.MM_2009,
	b.MM_2010,
	b.MM_2011,
	b.MM_2012,
	b.MM_2013,
	b.MM_2014,
	b.MM_2015,
	b.MM_2016, 
	b.MM_2017
into wkg_member_List_initial_2017_Pilot
from 
	CombinedMember_sg		as a
	join MiniOV..Dim_Member	as b on a.SavvyID_OV = b.SavvyID
where 
	(MM_2015 + MM_2016) < 24
	and (MM_2006 + MM_2007 + MM_2008 + MM_2009 + MM_2010 + MM_2011 + MM_2012 + MM_2013 + MM_2014) = 0
	and a.is2017		=	1
go
create clustered index cixSavvyHICN on wkg_member_List_initial_2017_Pilot(SavvyHICN)
go

IF object_id('wkg_member_List_initial_Cosmos_Info_2016_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_Cosmos_Info_2016_Pilot;
select mli.SavvyHICN
	,count(distinct case when left(b.Year_Mo,4) = 2014 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2014
	,count(distinct case when left(b.Year_Mo,4) = 2015 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2015
	,count(distinct case when left(b.Year_Mo,4) = 2016 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2016
	,count(distinct case when left(b.Year_Mo,4) = 2017 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2017
into wkg_member_List_initial_Cosmos_Info_2016_Pilot
from 
	wkg_member_List_initial_2016_Pilot as mli 
	LEFT JOIN MiniOV..Dim_MemberDetail as b on mli.SavvyID_OV = b.SavvyID
	LEFT JOIN MiniOV..Dim_Source_System_Combo as c on b.Src_Sys_Cd = c.SRC_SYS_CD
group by mli.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_member_List_initial_Cosmos_Info_2016_Pilot(SavvyHICN)
go
-- 13909

IF object_id('wkg_member_List_initial_Cosmos_Info_2017_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_Cosmos_Info_2017_Pilot;
select mli.SavvyHICN
	,count(distinct case when left(b.Year_Mo,4) = 2014 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2014
	,count(distinct case when left(b.Year_Mo,4) = 2015 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2015
	,count(distinct case when left(b.Year_Mo,4) = 2016 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2016
	,count(distinct case when left(b.Year_Mo,4) = 2017 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2017
into wkg_member_List_initial_Cosmos_Info_2017_Pilot
from 
	pdb_WalkandWin.dbo.GP1026_WnW_AllMembers as a
	join wkg_member_List_initial_2017_Pilot as mli on a.SavvyHICN = convert(varchar, mli.SavvyHICN)
	LEFT JOIN pdb_WalkandWin.dbo.GP1026_WnW_Call_Details AS cd ON a.IndividualSysID = cd.IndividualSysID
	LEFT JOIN MiniOV..Dim_MemberDetail as b on mli.SavvyID_OV = b.SavvyID
	LEFT JOIN MiniOV..Dim_Source_System_Combo as c on b.Src_Sys_Cd = c.SRC_SYS_CD
where 1 = 1
	and (
		a.PilotType LIKE '%Lifetime Value%'							--all LTV
		or a.PilotType = 'Alternative'								--all alternative
		or (a.PilotType like '%New Diabetics%' and a.Diabetes_Ind = 1)	--newly diagnosed with diabetes in New Diabetics pilot
		or (a.PilotType = 'New Age-ins' AND cd.Called_Flag = 1)		--member-reached filter to be added)
	)
group by mli.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_member_List_initial_Cosmos_Info_2017_Pilot(SavvyHICN)
go
-- 13909


----------------------------------------------------------------
--Check for PDP enrollment
IF object_id('wkg_member_List_initial_pdp_2016_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_pdp_2016_Pilot;
select c.SavvyHICN,
	   min(a.ServiceMonth) as Min_Year_Mo,
	   max(a.ServiceMonth) as Max_Year_Mo,
	   count(distinct a.ServiceMonth) as Year_Mo_Count
into wkg_member_List_initial_pdp_2016_Pilot
from MiniPAPI..Dim_Member_Detail				as a 
join MiniPAPI..Dim_Plan_Benefit					as b	on a.Plan_Benefit_Sys_ID = b.Plan_Benefit_Sys_ID
join wkg_member_List_initial_2016_Pilot			as c	on a.SavvyHICN = c.SavvyHICN
where b.Is_PDPOnly = 1
  and a.ServiceMonth between 200601	and 201512	--in period of interest, before lifetime's enrollment date
group by c.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_member_List_initial_pdp_2016_Pilot(SavvyHICN)
go-- 1772

IF object_id('wkg_member_List_initial_pdp_2017_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_pdp_2017_Pilot;
select c.SavvyHICN,
	   min(a.ServiceMonth) as Min_Year_Mo,
	   max(a.ServiceMonth) as Max_Year_Mo,
	   count(distinct a.ServiceMonth) as Year_Mo_Count
into wkg_member_List_initial_pdp_2017_Pilot
from MiniPAPI..Dim_Member_Detail				as a 
join MiniPAPI..Dim_Plan_Benefit					as b	on a.Plan_Benefit_Sys_ID = b.Plan_Benefit_Sys_ID
join wkg_member_List_initial_2017_Pilot			as c	on a.SavvyHICN = c.SavvyHICN
where b.Is_PDPOnly = 1
  and a.ServiceMonth between 200601	and 201612	--in period of interest, before lifetime's enrollment date
group by c.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_member_List_initial_pdp_2017_Pilot(SavvyHICN)
go-- 1772

-- select * from #pdp

--Check for Commercial enrollment
IF object_id('wkg_member_List_initial_com_2016_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_com_2016_Pilot;
select d.SavvyHICN,
	   min(a.Year_Mo) as Min_Year_Mo, 
	   max(a.Year_Mo) as Max_Year_Mo,
	   count(distinct a.Year_Mo) as Year_Mo_Count
into wkg_member_List_initial_com_2016_Pilot
from MiniHPDM..Summary_Indv_Demographic			as a 
join MiniHPDM..Dim_CustSegSysId					as b	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
join MiniHPDM..Dim_Customer_Segment				as b2	on a.Cust_Seg_Sys_Id = b2.Cust_Seg_Sys_Id
join MiniOV..SavvyHICN_to_Indv_Sys_ID			as c	on a.Indv_Sys_Id = c.Indv_Sys_ID
join wkg_member_List_initial_2016_Pilot			as d	on c.SavvyHICN = d.SavvyHICN
where b.Co_Nm not in ('Ovations', 'Americhoice', 'Oxford')	--Not M&R
  and a.Year_Mo between 200601 and 201512			--in period of interest, before lifetime's enrollment date
group by d.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_member_List_initial_com_2016_Pilot(SavvyHICN)
go

IF object_id('wkg_member_List_initial_com_2017_Pilot','U') IS NOT NULL
	DROP TABLE wkg_member_List_initial_com_2017_Pilot;
select d.SavvyHICN,
	   min(a.Year_Mo) as Min_Year_Mo, 
	   max(a.Year_Mo) as Max_Year_Mo,
	   count(distinct a.Year_Mo) as Year_Mo_Count
into wkg_member_List_initial_com_2017_Pilot
from MiniHPDM..Summary_Indv_Demographic			as a 
join MiniHPDM..Dim_CustSegSysId					as b	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
join MiniHPDM..Dim_Customer_Segment				as b2	on a.Cust_Seg_Sys_Id = b2.Cust_Seg_Sys_Id
join MiniOV..SavvyHICN_to_Indv_Sys_ID			as c	on a.Indv_Sys_Id = c.Indv_Sys_ID
join wkg_member_List_initial_2017_Pilot			as d	on c.SavvyHICN = d.SavvyHICN
where b.Co_Nm not in ('Ovations', 'Americhoice', 'Oxford')	--Not M&R
  and a.Year_Mo between 200601 and 201612			--in period of interest, before lifetime's enrollment date
group by d.SavvyHICN
go
create clustered index cixSavvyHICN on wkg_member_List_initial_com_2017_Pilot(SavvyHICN)
go

-- select * from #com

IF object_id('New_Member_Information_2016_Pilot','U') IS NOT NULL
	DROP TABLE New_Member_Information_2016_Pilot;
select a.* 
,b.COSMOS_MM_2014
,b.COSMOS_MM_2015
,b.COSMOS_MM_2016
,b.COSMOS_MM_2017
,case when c.SavvyHICN is not null then 1 else 0 end as PartD_Flag
,c.Year_Mo_Count as PartD_MM_Count
,case when d.SavvyHICN is not null then 1 else 0 end as Commercial_Flag
,d.Year_Mo_Count as Commercial_MM_Count
into New_Member_Information_2016_Pilot
from wkg_member_List_initial_2016_Pilot as a
left join wkg_member_List_initial_Cosmos_Info_2016_Pilot as b on a.SavvyHICN = b.SavvyHICN
left join wkg_member_List_initial_pdp_2016_Pilot as c on a.SavvyHICN = c.SavvyHICN
left join wkg_member_List_initial_com_2016_Pilot as d on a.SavvyHICN = d.SavvyHICN
go
create clustered index cixSavvyHICN on New_Member_Information_2016_Pilot(SavvyHICN)
go

IF object_id('New_Member_Information_2017_Pilot','U') IS NOT NULL
	DROP TABLE New_Member_Information_2017_Pilot;
select a.* 
,b.COSMOS_MM_2014
,b.COSMOS_MM_2015
,b.COSMOS_MM_2016
,b.COSMOS_MM_2017
,case when c.SavvyHICN is not null then 1 else 0 end as PartD_Flag
,c.Year_Mo_Count as PartD_MM_Count
,case when d.SavvyHICN is not null then 1 else 0 end as Commercial_Flag
,d.Year_Mo_Count as Commercial_MM_Count
into New_Member_Information_2017_Pilot
from wkg_member_List_initial_2017_Pilot as a
left join wkg_member_List_initial_Cosmos_Info_2017_Pilot as b on a.SavvyHICN = b.SavvyHICN
left join wkg_member_List_initial_pdp_2017_Pilot as c on a.SavvyHICN = c.SavvyHICN
left join wkg_member_List_initial_com_2017_Pilot as d on a.SavvyHICN = d.SavvyHICN
go
create clustered index cixSavvyHICN on New_Member_Information_2017_Pilot(SavvyHICN)
go
