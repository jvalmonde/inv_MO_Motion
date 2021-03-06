USE [pdb_WalkandWin]
GO
/****** Object:  StoredProcedure [dbo].[GP1026_WnW_Update_Member_Subset]    Script Date: 10/4/2017 3:15:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GP1026_WnW_Update_Member_Subset]
AS

/*-----------------------------------------------------------------------------------------------------------
Connect to: DEVSQL10

Updated by: Mira San Juan
Last updated on: 6/6/17
Updates: 


									*****IMPORTANT NOTE*****
To keep all the changes in one place, please do not edit the stored procedure directly from the object explorer
in Management Studio. Instead, you may find, edit and execute it from the ff. location:
R:\GP0000-Pilot Operations\GP1027-WalkandWin Pilot Ops\GP1026 WnW Research Dataset Loads\SQL Scripts

Please send an email to Edson Semorio, Sam Kapfhamer and Ikel Querouz if the updates in the script result to a
change in the structure of the final table output/s, e.g. addition/removal of column/s, change in data type, etc.
This is important since it will require recreation of the copy/ies of that table in the other server/s.
-----------------------------------------------------------------------------------------------------------*/

If (object_id('pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset') Is Not Null)
	Drop Table pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset

select
	a.*
	, OV_MM_2017 = m.MM_2017
	, OV_MM_2016 = m.MM_2016
	, OV_MM_2015 = m.MM_2015
	, OV_MM_2014 = m.MM_2014
	, OV_MM_2013 = m.MM_2013
	, OV_MM = case when m.SavvyID is not null then (m.MM_2013 + m.MM_2014 + m.MM_2015 + m.MM_2016) else null end
	, OV_COSMOS_MM_2017 = sub.COSMOS_MM_2017
	, OV_COSMOS_MM_2016 = sub.COSMOS_MM_2016
	, OV_COSMOS_MM_2015 = sub.COSMOS_MM_2015
	, OV_COSMOS_MM_2014 = sub.COSMOS_MM_2014
	, OV_COSMOS_MM_2013 = sub.COSMOS_MM_2013
	, OV_COSMOS_MM = case when m.SavvyID is not null then (sub.COSMOS_MM_2013 + sub.COSMOS_MM_2014 + sub.COSMOS_MM_2015 + sub.COSMOS_MM_2016) else null end
	, PAPI_MM_2017 = p.MM_2017
	, PAPI_MM_2016 = p.MM_2016
	, PAPI_MM_2015 = p.MM_2015
	, PAPI_MM_2014 = p.MM_2014
	, PAPI_MM_2013 = p.MM_2013
	, PAPI_MM = case when p.SavvyID is not null then (p.MM_2013 + p.MM_2014 + p.MM_2015 + p.MM_2016) else 0 end
INTO pdb_WalkandWin.dbo.GP1026_WnW_Member_Subset
from pdb_WalkandWin.dbo.GP1026_WnW_AllMembers	a
LEFT JOIN MiniOV.dbo.Dim_Member		m on a.MiniOV_SavvyID = m.SavvyID
LEFT JOIN MiniPAPI.dbo.Dim_Member	p on a.MiniPAPI_SavvyID = p.SavvyID
LEFT JOIN pdb_WalkandWin.dbo.GP1026_WnW_Call_Details AS cd ON a.IndividualSysID = cd.IndividualSysID
LEFT JOIN (
		select a.SavvyHICN
			,count(distinct case when left(b.Year_Mo,4) = 2013 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2013
			,count(distinct case when left(b.Year_Mo,4) = 2014 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2014
			,count(distinct case when left(b.Year_Mo,4) = 2015 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2015
			,count(distinct case when left(b.Year_Mo,4) = 2016 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2016
			,count(distinct case when left(b.Year_Mo,4) = 2017 and c.SRC_SYS_DESC = 'COSMOS' then b.Year_Mo else null end) as COSMOS_MM_2017
		from pdb_WalkandWin.dbo.GP1026_WnW_AllMembers as a
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
		) as sub on a.SavvyHICN = sub.SavvyHICN
where 1 = 1
	and a.SavvyHicn is not null										--only get those with SavvyHICNs
	and (
		a.PilotType LIKE '%Lifetime Value%'							--all LTV
		or a.PilotType = 'Alternative'								--all alternative
		or (a.PilotType like '%New Diabetics%' and a.Diabetes_Ind = 1)	--newly diagnosed with diabetes in New Diabetics pilot
		or (a.PilotType = 'New Age-ins' AND cd.Called_Flag = 1)		--member-reached filter to be added)
	)

	

create unique index uix_SavvyHICN	on pdb_WalkandWin..GP1026_WnW_Member_Subset (SavvyHICN);
create index ix_IndividualSysID		on pdb_WalkandWin..GP1026_WnW_Member_Subset (IndividualSysID);
create index ix_MiniOV_SavvyID		on pdb_WalkandWin..GP1026_WnW_Member_Subset (MiniOV_SavvyID);
create index ix_MiniPapi_SavvyID	on pdb_WalkandWin..GP1026_WnW_Member_Subset (MiniPapi_SavvyID);
create index ix_DERMSL_MemberID		on pdb_WalkandWin..GP1026_WnW_Member_Subset (DERMSL_MemberID);