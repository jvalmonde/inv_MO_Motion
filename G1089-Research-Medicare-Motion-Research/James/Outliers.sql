


select * from pdb_WalkandWin..LTV_Member_Month as a



select left(a.Year_Mo,4) as yr,  sum(Total_Claims_Cost) as Grand_Total -- 236777821.2493
into #GrandTotal
from pdb_WalkandWin..LTV_Member_Month as a
where left(a.Year_Mo,4) in (2014,2015,2016)
group by left(a.Year_Mo,4)

-- select * from #GrandTotal


select a.savvyhicn
,left(a.Year_Mo,4) as yr
,sum(Total_Claims_Cost) as Total_Year_Cost 
into #perMember
from pdb_WalkandWin..LTV_Member_Month as a
where left(a.Year_Mo,4) in (2014,2015,2016)
group by a.savvyhicn
,left(a.Year_Mo,4)

-- select * from #perMember


select a.savvyhicn
,a.yr
,a.Total_Year_Cost
,max(b.Grand_Total) as Grand_Total
,sum(a.Total_Year_Cost)over(partition by a.yr 
							order by sum(a.Total_Year_Cost) desc rows unbounded preceding) as Moving_Total
,(sum(a.Total_Year_Cost)over(partition by a.yr 
							order by sum(a.Total_Year_Cost) desc rows unbounded preceding) / max(b.Grand_Total)) * 100 as Percentage_of_Grand_Total
,case when (sum(a.Total_Year_Cost)over(partition by a.yr 
							order by sum(a.Total_Year_Cost) desc rows unbounded preceding) / max(b.Grand_Total)) * 100 <= 5 then 1 else 0 end as Outlier_Flag
from #perMember as a
join #GrandTotal as b on a.yr = b.yr
group by a.savvyhicn
,a.yr
,a.Total_Year_Cost