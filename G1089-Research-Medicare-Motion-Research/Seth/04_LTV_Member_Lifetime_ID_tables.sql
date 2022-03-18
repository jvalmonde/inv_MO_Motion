USE pdb_WalkandWin /*...on DBSEP3832*/
GO

IF object_id('LTV_Member_Lifetime_ID_2016_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Lifetime_ID_2016_Pilot;
select 
	SavvyHICN, 
	Lifetime_ID, 
	Enroll_Year_Mo					=	min(Year_Mo),
	Disenroll_Year_Mo				=	max(Year_Mo),
	Total_MM						=	count(distinct Year_Mo),
	Plan_Cnt						=	count(distinct Contr_Nbr+'-'+PBP),
	Total_Revenue					=	sum(Total_Revenue),
	--Total_Cost						=	sum(Total_Cost),
	Total_Cost_40Percent_Rebate		=	sum(Total_Cost_40Percent_Rebate),
	Total_Cost_Full_Rebate			=	sum(Total_Cost_Full_Rebate),
	Total_Cost_NoRebate				=	sum(Total_Cost_NoRebate),
	--Total_Value						=	sum(Total_Value),
	Total_Value_40Percent_Rebate	=	sum(Total_Value_40Percent_Rebate),
	Total_Value_Full_Rebate			=	sum(Total_Value_Full_Rebate),
	Total_Value_NoRebate			=	sum(Total_Value_NoRebate),
	Enroll_Flag						=	case when min(Year_Mo) > 200701 then 1 else 0 end,
	Disenroll_Flag					=	case when max(Year_Mo) < 201803 then 1 else 0 end,		--MMR through 201803
	Lifetime_Flag					=	case when min(Year_Mo) > 200701 and max(Year_Mo) < 201803 then 1 else 0 end
into LTV_Member_Lifetime_ID_2016_Pilot
from LTV_Member_Month_2016_Pilot               as a
group by SavvyHICN, Lifetime_ID
-- 50,901
go
create clustered index cixSavvyHICN on LTV_Member_Lifetime_ID_2016_Pilot(SavvyHICN)
go

IF object_id('LTV_Member_Lifetime_ID_2017_Pilot','U') IS NOT NULL
	DROP TABLE LTV_Member_Lifetime_ID_2017_Pilot;
select 
	SavvyHICN, 
	Lifetime_ID, 
	Enroll_Year_Mo					=	min(Year_Mo),
	Disenroll_Year_Mo				=	max(Year_Mo),
	Total_MM						=	count(distinct Year_Mo),
	Plan_Cnt						=	count(distinct Contr_Nbr+'-'+PBP),
	Total_Revenue					=	sum(Total_Revenue),
	--Total_Cost						=	sum(Total_Cost),
	Total_Cost_40Percent_Rebate		=	sum(Total_Cost_40Percent_Rebate),
	Total_Cost_Full_Rebate			=	sum(Total_Cost_Full_Rebate),
	Total_Cost_NoRebate				=	sum(Total_Cost_NoRebate),
	--Total_Value						=	sum(Total_Value),
	Total_Value_40Percent_Rebate	=	sum(Total_Value_40Percent_Rebate),
	Total_Value_Full_Rebate			=	sum(Total_Value_Full_Rebate),
	Total_Value_NoRebate			=	sum(Total_Value_NoRebate),
	Enroll_Flag						=	case when min(Year_Mo) > 200701 then 1 else 0 end,
	Disenroll_Flag					=	case when max(Year_Mo) < 201803 then 1 else 0 end,		--MMR through 201707
	Lifetime_Flag					=	case when min(Year_Mo) > 200701 and max(Year_Mo) < 201803 then 1 else 0 end
into LTV_Member_Lifetime_ID_2017_Pilot
from LTV_Member_Month_2017_Pilot               as a
group by SavvyHICN, Lifetime_ID
-- 50,901
go
create clustered index cixSavvyHICN on LTV_Member_Lifetime_ID_2017_Pilot(SavvyHICN)
go
