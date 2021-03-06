
-- drop table #SavvyHICN_Sample
select top 10 percent SavvyHICN, NEWID()as RND
into #SavvyHICN_Sample
from
(
select distinct SavvyHICN
from pdb_WalkandWin..CMS_MMR_Subset_20170727
) as a
order by RND
-- 4,571

create unique index uix on #SavvyHICN_Sample(SavvyHICN)



select a.SavvyHICN
, b.SavvyID as MiniOV_SavvyID, max(e.DT_SYS_ID) as MiniOV_Latest_Dt_Sys_ID, max(convert(date,e.FULL_DT)) as MiniOV_Latest_Dt 
, c.SavvyID as MiniPapi_SavvyID , max(g.DT_SYS_ID) as MiniPapi_Latest_Dt_Sys_ID, max(g.FULL_DT) as MiniPapi_Latest_Dt 
from #SavvyHICN_Sample as a
join MiniOV..SavvyID_to_SavvyHICN as b on a.SavvyHICN = b.SavvyHICN
join MiniOV..Fact_Claims as d on b.SavvyID = d.SavvyId
join MiniOV..Dim_Date as  e on d.Dt_Sys_Id = e.DT_SYS_ID

join MiniPAPI..SavvyID_to_SavvyHICN as c on a.SavvyHICN = c.SavvyID
join MiniPapi..Fact_Claims as f on c.SavvyID = f.SavvyId
join MiniPapi..Dim_Date as  g on f.Date_Of_Service_DtSysId = g.DT_SYS_ID
where e.YEAR_NBR in (2016, 2017)
or g.YEAR_NBR in (2016, 2017)
group by a.SavvyHICN
,b.SavvyID
,c.SavvyID
-- 3,776