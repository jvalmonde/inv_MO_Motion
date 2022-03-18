
select distinct a.SavvyHICN, b.SavvyID
into #members
from pdb_WalkandWin..CMS_MMR_Subset_20170727					as a
join MiniOV..SavvyID_to_SavvyHICN				as b	on a.SavvyHICN = b.SavvyHICN
-- 45,468

create unique index ix_hicn on #members(SavvyHICN)

-- drop table #member_List_initial
select a.SavvyHICN, a.SavvyID as MiniOV_SavvyID
,MM_2006 ,MM_2007 ,MM_2008 ,MM_2009 ,MM_2010 ,MM_2011 ,MM_2012 ,MM_2013 ,MM_2014 ,MM_2015 ,MM_2016 , MM_2017
into #member_List_initial
from #members as a
join MiniOV..Dim_Member as b on a.SavvyID = b.SavvyID
where (MM_2014 + MM_2015) < 24
and (MM_2006 + MM_2007 + MM_2008 + MM_2009 + MM_2010 + MM_2011 + MM_2012 + MM_2013) = 0
-- 13909

select a.SavvyHICN
	,count(distinct case when left(b.Year_Mo,4) = 2014 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2014
	,count(distinct case when left(b.Year_Mo,4) = 2015 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2015
	,count(distinct case when left(b.Year_Mo,4) = 2016 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2016
	,count(distinct case when left(b.Year_Mo,4) = 2017 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2017
into #member_List_initial_Cosmos_Info
from pdb_WalkandWin.dbo.GP1026_WnW_AllMembers as a
join #member_List_initial as mli on a.SavvyHICN = mli.SavvyHICN
LEFT JOIN pdb_WalkandWin.dbo.GP1026_WnW_Call_Details AS cd ON a.IndividualSysID = cd.IndividualSysID
LEFT JOIN MiniOV..Dim_MemberDetail as b on a.MiniOV_SavvyID = b.SavvyID
LEFT JOIN MiniOV..Dim_Source_System_Combo as c on b.Src_Sys_Cd = c.SRC_SYS_CD
where 1 = 1
	and a.SavvyHicn is not null										--only get those with SavvyHICNs
	and (
		a.PilotType LIKE '%Lifetime Value%'							--all LTV
		or a.PilotType = 'Alternative'								--all alternative
		or (a.PilotType like '%New Diabetics%' and a.Diabetes_Ind = 1)	--newly diagnosed with diabetes in New Diabetics pilot
		or (a.PilotType = 'New Age-ins' AND cd.Called_Flag = 1)		--member-reached filter to be added)
	)
group by a.SavvyHICN
-- 13909


----------------------------------------------------------------
--Check for PDP enrollment
-- drop table #pdp
select c.SavvyHICN,
	   min(a.ServiceMonth) as Min_Year_Mo,
	   max(a.ServiceMonth) as Max_Year_Mo,
	   count(distinct a.ServiceMonth) as Year_Mo_Count
into #pdp
from MiniPAPI..Dim_Member_Detail				as a 
join MiniPAPI..Dim_Plan_Benefit					as b	on a.Plan_Benefit_Sys_ID = b.Plan_Benefit_Sys_ID
join #member_List_initial					as c	on a.SavvyHICN = c.SavvyHICN
where b.Is_PDPOnly = 1
  and a.ServiceMonth between 200601	and 201512	--in period of interest, before lifetime's enrollment date
group by c.SavvyHICN
-- 1772

-- select * from #pdp

--Check for Commercial enrollment
-- drop table #com
select d.SavvyHICN,
	   min(a.Year_Mo) as Min_Year_Mo, 
	   max(a.Year_Mo) as Max_Year_Mo,
	   count(distinct a.year_Mo) as Year_Mo_Count
into #com
from MiniHPDM..Summary_Indv_Demographic			as a 
join MiniHPDM..Dim_CustSegSysId					as b	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
join MiniHPDM..Dim_Customer_Segment				as b2	on a.Cust_Seg_Sys_Id = b2.Cust_Seg_Sys_Id
join MiniOV..SavvyHICN_to_Indv_Sys_ID			as c	on a.Indv_Sys_Id = c.Indv_Sys_ID
join #member_List_initial					as d	on c.SavvyHICN = d.SavvyHICN
where b.Co_Nm not in ('Ovations', 'Americhoice', 'Oxford')	--Not M&R
  and a.Year_Mo between 200601 and 201512			--in period of interest, before lifetime's enrollment date
group by d.SavvyHICN
-- 825

-- select * from #com


select a.* 
,b.COSMOS_MM_2014
,b.COSMOS_MM_2015
,b.COSMOS_MM_2016
,b.COSMOS_MM_2017
,case when c.SavvyHICN is not null then 1 else 0 end as PartD_Flag
,c.Year_Mo_Count as PartD_MM_Count
,case when d.SavvyHICN is not null then 1 else 0 end as Commercial_Flag
,d.Year_Mo_Count as Commercial_MM_Count
into pdb_WalkandWin..New_Member_Information
from #member_List_initial as a
left join #member_List_initial_Cosmos_Info as b on a.SavvyHICN = b.SavvyHICN
left join #pdp as c on a.SavvyHICN = c.SavvyHICN
left join #com as d on a.SavvyHICN = d.SavvyHICN

create unique index uix on  pdb_WalkandWin..New_Member_Information(savvyhicn)