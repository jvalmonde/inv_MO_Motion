USE pdb_WalkandWin /*...on DBSEP3832*/
GO

----------------------------------------------------------------
--1) Check for previous enrollments (MAPD, PDP, and Commercial)
----------------------------------------------------------------
--Check for PDP enrollment
IF object_id('wkg_pdp_2016','U') IS NOT NULL
	DROP TABLE wkg_pdp_2016;
select c.SavvyHICN, c.Lifetime_ID,
	   min(a.ServiceMonth) as Min_Year_Mo,
	   max(a.ServiceMonth) as Max_Year_Mo
into wkg_pdp_2016
from MiniPAPI..Dim_Member_Detail				as a 
join MiniPAPI..Dim_Plan_Benefit					as b	on a.Plan_Benefit_Sys_ID = b.Plan_Benefit_Sys_ID
join LTV_Member_Enrollment_2016_Pilot			as c	on a.SavvyHICN = c.SavvyHICN
where b.Is_PDPOnly = 1
  and a.ServiceMonth between 200701	and c.Enroll_Year_Mo	--in period of interest, before lifetime's enrollment date
group by c.SavvyHICN, c.Lifetime_ID
go
create clustered index cixSavvyHICN on wkg_pdp_2016(SavvyHICN)
go

--Check for Commercial enrollment
IF object_id('wkg_com_2016','U') IS NOT NULL
	DROP TABLE wkg_com_2016;
select d.SavvyHICN, d.Lifetime_ID,
	   min(a.Year_Mo) as Min_Year_Mo, 
	   max(a.Year_Mo) as Max_Year_Mo
	   --a.Year_Mo, b.Co_Nm, b.Co_Id_Rllp, b.Hlth_Pln_Fund_Cd, b2.CUST_SEG_NBR, b2.CUST_SEG_NM
into wkg_com_2016
from MiniHPDM..Summary_Indv_Demographic			as a 
join MiniHPDM..Dim_CustSegSysId					as b	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
join MiniHPDM..Dim_Customer_Segment				as b2	on a.Cust_Seg_Sys_Id = b2.Cust_Seg_Sys_Id
join MiniOV..SavvyHICN_to_Indv_Sys_ID			as c	on a.Indv_Sys_Id = c.Indv_Sys_ID
join LTV_Member_Enrollment_2016_Pilot			as d	on c.SavvyHICN = d.SavvyHICN
where b.Co_Nm not in ('Ovations', 'Americhoice', 'Oxford')	--Not M&R
  and a.Year_Mo between 200701 and d.Enroll_Year_Mo			--in period of interest, before lifetime's enrollment date
group by d.SavvyHICN, d.Lifetime_ID
go
create clustered index cixSavvyHICN on wkg_com_2016(SavvyHICN)
go

--Build New_Member_Status
IF object_id('wkg_previous_enrollment_2016','U') IS NOT NULL
	DROP TABLE wkg_previous_enrollment_2016;
select a.SavvyHICN, a.Lifetime_ID,
	   case when a.Lifetime_ID > 1 then 'Prior MAPD'
		    when b.SavvyHICN is not null then 'Prior Commercial'
			when c.SavvyHICN is not null then 'Prior PDP Only'
			else 'New UHC Member' end as New_Member_Status
into wkg_previous_enrollment_2016
from LTV_Member_Enrollment_2016_Pilot	as a 
left join wkg_com_2016					as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
left join wkg_pdp_2016					as c	on a.SavvyHICN = c.SavvyHICN and a.Lifetime_ID = c.Lifetime_ID
go
create clustered index cixSavvyHICN on wkg_previous_enrollment_2016(SavvyHICN)
go


--Check for PDP enrollment
IF object_id('wkg_pdp_2017','U') IS NOT NULL
	DROP TABLE wkg_pdp_2017;
select c.SavvyHICN, c.Lifetime_ID,
	   min(a.ServiceMonth) as Min_Year_Mo,
	   max(a.ServiceMonth) as Max_Year_Mo
into wkg_pdp_2017
from MiniPAPI..Dim_Member_Detail				as a 
join MiniPAPI..Dim_Plan_Benefit					as b	on a.Plan_Benefit_Sys_ID = b.Plan_Benefit_Sys_ID
join LTV_Member_Enrollment_2017_Pilot			as c	on a.SavvyHICN = c.SavvyHICN
where b.Is_PDPOnly = 1
  and a.ServiceMonth between 200701	and c.Enroll_Year_Mo	--in period of interest, before lifetime's enrollment date
group by c.SavvyHICN, c.Lifetime_ID
go
create clustered index cixSavvyHICN on wkg_pdp_2017(SavvyHICN)
go

--Check for Commercial enrollment
IF object_id('wkg_com_2017','U') IS NOT NULL
	DROP TABLE wkg_com_2017;
select d.SavvyHICN, d.Lifetime_ID,
	   min(a.Year_Mo) as Min_Year_Mo, 
	   max(a.Year_Mo) as Max_Year_Mo
	   --a.Year_Mo, b.Co_Nm, b.Co_Id_Rllp, b.Hlth_Pln_Fund_Cd, b2.CUST_SEG_NBR, b2.CUST_SEG_NM
into wkg_com_2017
from MiniHPDM..Summary_Indv_Demographic			as a 
join MiniHPDM..Dim_CustSegSysId					as b	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
join MiniHPDM..Dim_Customer_Segment				as b2	on a.Cust_Seg_Sys_Id = b2.Cust_Seg_Sys_Id
join MiniOV..SavvyHICN_to_Indv_Sys_ID			as c	on a.Indv_Sys_Id = c.Indv_Sys_ID
join LTV_Member_Enrollment_2017_Pilot			as d	on c.SavvyHICN = d.SavvyHICN
where b.Co_Nm not in ('Ovations', 'Americhoice', 'Oxford')	--Not M&R
  and a.Year_Mo between 200701 and d.Enroll_Year_Mo			--in period of interest, before lifetime's enrollment date
group by d.SavvyHICN, d.Lifetime_ID
go
create clustered index cixSavvyHICN on wkg_com_2017(SavvyHICN)
go

--Build New_Member_Status
IF object_id('wkg_previous_enrollment_2017','U') IS NOT NULL
	DROP TABLE wkg_previous_enrollment_2017;
select a.SavvyHICN, a.Lifetime_ID,
	   case when a.Lifetime_ID > 1 then 'Prior MAPD'
		    when b.SavvyHICN is not null then 'Prior Commercial'
			when c.SavvyHICN is not null then 'Prior PDP Only'
			else 'New UHC Member' end as New_Member_Status
into wkg_previous_enrollment_2017
from LTV_Member_Enrollment_2017_Pilot	as a 
left join wkg_com_2017					as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
left join wkg_pdp_2017					as c	on a.SavvyHICN = c.SavvyHICN and a.Lifetime_ID = c.Lifetime_ID
go
create clustered index cixSavvyHICN on wkg_previous_enrollment_2017(SavvyHICN)
go



-------------------------------------------------------------
--2) Summarize lifetimes
-------------------------------------------------------------
IF object_id('LTV_Member_Lifetime_2016_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Lifetime_2016_Pilot;
select a.*, 
       case when a.Enroll_Flag = 1 and a.Disenroll_Flag = 1 then 'Completed Lifetime'
	        when a.Enroll_Flag = 1 and a.Disenroll_Flag = 0 then 'Current Member'
			when a.Enroll_Flag = 0 and a.Disenroll_Flag = 0 then 'Long-term Member'
			when a.Enroll_Flag = 0 and a.Disenroll_Flag = 1 then 'Long-gone Member'
			end as Lifetime_Type
into LTV_Member_Lifetime_2016_Pilot
from(
	select a.*, b.New_Member_Status
	from LTV_Member_Lifetime_ID_2016_Pilot	as a
	join wkg_previous_enrollment_2016		as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
	) as a
	-- 50901

create unique index ix_SH_LI on LTV_Member_Lifetime_2016_Pilot(SavvyHICN, Lifetime_ID)
create unique index ix_SH_EY on LTV_Member_Lifetime_2016_Pilot(SavvyHICN, Enroll_Year_Mo)
create unique index ix_SH_DY on LTV_Member_Lifetime_2016_Pilot(SavvyHICN, Disenroll_Year_Mo)


IF object_id('LTV_Member_Lifetime_2017_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Lifetime_2017_Pilot;
select a.*, 
       case when a.Enroll_Flag = 1 and a.Disenroll_Flag = 1 then 'Completed Lifetime'
	        when a.Enroll_Flag = 1 and a.Disenroll_Flag = 0 then 'Current Member'
			when a.Enroll_Flag = 0 and a.Disenroll_Flag = 0 then 'Long-term Member'
			when a.Enroll_Flag = 0 and a.Disenroll_Flag = 1 then 'Long-gone Member'
			end as Lifetime_Type
into LTV_Member_Lifetime_2017_Pilot
from(
	select a.*, b.New_Member_Status
	from LTV_Member_Lifetime_ID_2017_Pilot	as a
	join wkg_previous_enrollment_2017		as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
	) as a
	-- 50901

create unique index ix_SH_LI on LTV_Member_Lifetime_2017_Pilot(SavvyHICN, Lifetime_ID)
create unique index ix_SH_EY on LTV_Member_Lifetime_2017_Pilot(SavvyHICN, Enroll_Year_Mo)
create unique index ix_SH_DY on LTV_Member_Lifetime_2017_Pilot(SavvyHICN, Disenroll_Year_Mo)



--select distinct savvyhicn from pdb_WalkandWin..LTV_Member_Lifetime_2016_Pilot


--select * from pdb_WalkandWin..LTV_Member_Lifetime_2016_Pilot as a

-- drop table [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime2_2016_Pilot]

/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT  a.[SavvyHICN]
--	  ,b.[PilotType]
--	  ,b.Incentive_Group
--      ,[Invite_Flag]
--      ,[Welcome_Flag]
--      ,[Registered_Flag]
--      ,[ActivatedTrio_Flag]
--      ,[Lifetime_ID]
--      ,[Enroll_Year_Mo]
--      ,[Disenroll_Year_Mo]
--      ,[Total_MM]
--      ,[Plan_Cnt]
--      ,[Total_Revenue]
--      ,[Total_Cost]
--      ,[Total_Value]
--      ,[Enroll_Flag]
--      ,[Disenroll_Flag]
--      ,[Lifetime_Flag]
--      ,[New_Member_Status]
--      ,[Lifetime_Type]
--into  [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime2_2016_Pilot]

--  FROM [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime_2016_Pilot] as a
--  left join [pdb_GP1026_WalkandWin_Research].[final].[GP1026_WnW_Member_Details] as b on convert(varchar,a.savvyhicn) = b.savvyhicn


--  select distinct savvyhicn from [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime_2016_Pilot]