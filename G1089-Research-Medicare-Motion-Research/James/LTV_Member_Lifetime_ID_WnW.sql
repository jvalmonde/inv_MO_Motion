
-- drop table pdb_WalkandWin..LTV_Member_Lifetime_ID
select SavvyHICN, Lifetime_ID, 
        min(Year_Mo) as Enroll_Year_Mo,
        max(Year_Mo) as Disenroll_Year_Mo,
        count(distinct Year_Mo) as Total_MM,
        count(distinct Contr_Nbr+'-'+PBP) as Plan_Cnt,
        sum(Total_Revenue) as Total_Revenue,
        sum(Total_Cost) as Total_Cost,
        sum(Total_Value) as Total_Value,
        case when min(Year_Mo) > 200601 then 1 else 0 end as Enroll_Flag,
        case when max(Year_Mo) < 201703 then 1 else 0 end as Disenroll_Flag,		--MMR through 201707
        case when min(Year_Mo) > 200601 and max(Year_Mo) < 201703 then 1 else 0 end as Lifetime_Flag
into pdb_WalkandWin..LTV_Member_Lifetime_ID
from pdb_WalkandWin..LTV_Member_Month               as a
group by SavvyHICN, Lifetime_ID
-- 50,901

select * from pdb_WalkandWin..LTV_Member_Lifetime_ID

