use Fitbit_Match
go

/*
			select 'Fitbit_Match.dbo.Member_List' FromSource,			count(*) Records, count(distinct Indv_Sys_Id) Indv_Sys_Ids, 0 OtherIds,							case when count(*) = count(distinct Indv_Sys_Id) then 1 else 0 end isSame	from Fitbit_Match.dbo.Member_List
UNION ALL	select 'MiniHPDM.dbo.Dim_Member' FromSource,				count(*) Records, count(distinct Indv_Sys_Id) Indv_Sys_Ids, 0 OtherIds,							case when count(*) = count(distinct Indv_Sys_Id) then 1 else 0 end isSame	from MiniHPDM.dbo.Dim_Member
UNION ALL	select 'MiniOV.dbo.SavvyHICN_to_Indv_Sys_ID' FromSource,	count(*) Records, count(distinct Indv_Sys_Id) Indv_Sys_Ids, count(distinct SavvyHICN) OtherIds, case when count(*) = count(distinct Indv_Sys_Id) then 1 else 0 end isSame	from MiniOV.dbo.SavvyHICN_to_Indv_Sys_ID
UNION ALL	select 'MiniOV.dbo.SavvyID_to_Indv_Sys_ID' FromSource,		count(*) Records, count(distinct Indv_Sys_Id) Indv_Sys_Ids, count(distinct SavvyID) OtherIds,	case when count(*) = count(distinct Indv_Sys_Id) then 1 else 0 end isSame	from MiniOV.dbo.SavvyID_to_Indv_Sys_ID
UNION ALL	select 'MiniOV_PHI.dbo.HICN_to_Indv_Sys_ID' FromSource,		count(*) Records, count(distinct Indv_Sys_Id) Indv_Sys_Ids, count(distinct HICN) OtherIds,		case when count(*) = count(distinct Indv_Sys_Id) then 1 else 0 end isSame	from MiniOV_PHI.dbo.HICN_to_Indv_Sys_ID

--FromSource							Records		Indv_Sys_Ids	OtherIds	isSame
--Fitbit_Match.dbo.Member_List			1549341		1549341			0			1
--MiniHPDM.dbo.Dim_Member				94507706	94507706		0			1
--MiniOV.dbo.SavvyHICN_to_Indv_Sys_ID	8889232		8740947			8762291		0
--MiniOV.dbo.SavvyID_to_Indv_Sys_ID		8975203		8975008			8850958		0
--MiniOV_PHI.dbo.HICN_to_Indv_Sys_ID	8958997		8740947			8832034		0

*/

--only duplicate Indv_Sys_Id in MiniOV.dbo.SavvyID_to_Indv_Sys_ID is -1
--SELECT * FROM MiniOV.dbo.SavvyID_to_Indv_Sys_ID GROUP BY Indv_Sys_Id HAVING COUNT(*) > 1

--select *
--from MiniOV.dbo.SavvyID_to_Indv_Sys_ID
--where Indv_Sys_Id in 
--	(SELECT Indv_Sys_Id FROM MiniOV.dbo.SavvyID_to_Indv_Sys_ID GROUP BY Indv_Sys_Id HAVING COUNT(*) > 1)


select 
	count(*), 
	Indv_Sys_Id_FB			=	count(distinct ml.Indv_Sys_Id), 
	Indv_Sys_Id_HPDM		=	count(distinct hp.Indv_Sys_Id), 
	Indv_Sys_Id_OV			=	count(distinct ov.Indv_Sys_Id), 
	SavvyID_OV				=	count(distinct ovm.SavvyID),
	HPDM_2017				=	count(distinct case when hp.MM_2017 = 12 then hp.Indv_Sys_Id end),
	HPDM_2016_2017			=	count(distinct case when hp.MM_2016 = 12 and hp.MM_2017 = 12 then hp.Indv_Sys_Id end),
	OV_2017					=	count(distinct case when ovm.MM_2017 = 12 then ovm.SavvyID end),
	HPDM_2016_2017			=	count(distinct case when ovm.MM_2016 = 12 and ovm.MM_2017 = 12 then ovm.SavvyID end)
from 
	Fitbit_Match.dbo.Member_List					ml
	left join MiniHPDM.dbo.Dim_Member				hp	on	ml.Indv_Sys_Id		=	hp.Indv_Sys_Id
	left join MiniOV.dbo.SavvyID_to_Indv_Sys_ID		ov	on	ml.Indv_Sys_Id		=	ov.Indv_Sys_Id
	left join MiniOV.dbo.Dim_Member					ovm	on	ov.SavvyID			=	ovm.SavvyID
;


select 
	isHPDM					=	case when hp.Indv_Sys_Id is not null then 1 else 0 end,
	isOV					=	case when ov.Indv_Sys_Id is not null then 1 else 0 end,
	isOVM					=	case when ovm.SavvyID is not null then 1 else 0 end,
	count(*)
from 
	Fitbit_Match.dbo.Member_List					ml
	left join MiniHPDM.dbo.Dim_Member				hp	on	ml.Indv_Sys_Id		=	hp.Indv_Sys_Id
	left join MiniOV.dbo.SavvyID_to_Indv_Sys_ID		ov	on	ml.Indv_Sys_Id		=	ov.Indv_Sys_Id
	left join MiniOV.dbo.Dim_Member					ovm	on	ov.SavvyID			=	ovm.SavvyID
group by
	case when hp.Indv_Sys_Id is not null then 1 else 0 end,
	case when ov.Indv_Sys_Id is not null then 1 else 0 end,
	case when ovm.SavvyID is not null then 1 else 0 end
;



select 
	ml.Indv_Sys_Id,
	hp.Fst_Dt, hp.End_Dt, hp.MM, hp.Fst_Nm, hp.Lst_Nm, hp.Bth_dt, hp.Zip, zc.St_Cd,
	ovm.MAPDFlag, ovm.Sbscr_St_Abbr_Cd, ovm.MemberFirstName, ovm.MemberLastName, ovm.Birthdate, ovm.Cust_Seg_Nm, ovm.Year_Mo, ovm.MM, ovm.Year_Mo
from 
	(select top 20 * 
	from MiniOV.dbo.SavvyID_to_Indv_Sys_ID	
	where Indv_Sys_Id in (382550198, 350940659, 583714074, 852227722, 240196013, 217126079, 906671983, 787266058, 53002325, 396079999, 219391967, 383425930, 652276544, 185961054, 166601969, 243752312, 642195020, 631946066, 692960655, 206960686)
	order by NEWID()
	)												ml
	join MiniHPDM_PHI.dbo.Dim_Member				hp	on	ml.Indv_Sys_Id		=	hp.Indv_Sys_Id
	join pdb_HF.dbo.Zip_Census						zc	on	hp.Zip				=	zc.Zip
	join MiniOV.dbo.SavvyID_to_Indv_Sys_ID			ov	on	ml.Indv_Sys_Id		=	ov.Indv_Sys_Id
	join MiniOV_PHI.dbo.Dim_Member					ovm	on	ov.SavvyID			=	ovm.SavvyID
;

--does every member in MiniOV (or at least every member with an Indv_Sys_Id) appear in MiniHPDM?
select 
	ov.Indv_Sys_Id,
	hp.Fst_Dt, hp.End_Dt, hp.MM, hp.Fst_Nm, hp.Lst_Nm, hp.Bth_dt, hp.Zip, zc.St_Cd, hp.Cust_Seg_Sys_Id,
	ovm.MAPDFlag, ovm.Sbscr_St_Abbr_Cd, ovm.MemberFirstName, ovm.MemberLastName, ovm.Birthdate, ovm.Cust_Seg_Nm, ovm.Year_Mo, ovm.MM, ovm.Year_Mo, ovm.Src_Sys_Cd
from 
	(select top 20 * 
	from MiniOV.dbo.SavvyID_to_Indv_Sys_ID	
	where Indv_Sys_Id in (830323920, 797246130, 1349140576, 1032427171, 901051598, 182314601, 1350738126, 1016937996, 529055304, 63179354, 907728808, 441661120, 940743188, 530528280, 922344992, 711048598, 1203795504, 684382218, 652842711, 394888293)
	order by NEWID()
	)												ov
	join MiniOV_PHI.dbo.Dim_Member					ovm	on	ov.SavvyID			=	ovm.SavvyID 
	left join MiniHPDM_PHI.dbo.Dim_Member			hp	on	ov.Indv_Sys_Id		=	hp.Indv_Sys_Id
	left join pdb_HF.dbo.Zip_Census					zc	on	hp.Zip				=	zc.Zip
