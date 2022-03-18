


select 
d.MM_2006
,d.MM_2007
,d.MM_2008
,d.MM_2009
,d.MM_2010
,d.MM_2011
,d.MM_2012
,d.MM_2013
,d.MM_2014
,d.MM_2015
,d.MM_2016
,d.MM_2017
,d.Age
,d.Gender
,b.* 
from [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset] as a
left join pdb_WalkandWin.dbo.GP1026_WnW_RAF as b on a.SavvyHICN = b.SavvyHICN
left join MiniOV..SavvyID_to_SavvyHICN as c on a.SavvyHICN = convert(varchar,c.SavvyHICN)
left join MiniOV.dbo.Dim_Member as d on c.SavvyID = d.SavvyID
where b.RAFDemo_2013 is null 
	and b.RAFDemo_2014 is null 
	and b.RAFDemo_2015 is null 
	and b.RAFDemo_2016 is null
-- 5054

select 
d.MM_2006
,d.MM_2007
,d.MM_2008
,d.MM_2009
,d.MM_2010
,d.MM_2011
,d.MM_2012
,d.MM_2013
,d.MM_2014
,d.MM_2015
,d.MM_2016
,d.MM_2017
,d.Age
,d.Gender
,b.* 
from [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset] as a
left join pdb_WalkandWin.dbo.GP1026_WnW_RAF as b on a.SavvyHICN = b.SavvyHICN
left join MiniOV..SavvyID_to_SavvyHICN as c on a.SavvyHICN = convert(varchar,c.SavvyHICN)
left join MiniOV.dbo.Dim_Member as d on c.SavvyID = d.SavvyID
where b.RAFDemo_2013 is null 
	and b.RAFDemo_2014 is null 
	and b.RAFDemo_2015 is null 
	and b.RAFDemo_2016 is null
	and d.MM_2016 is null
-- 167



select 
d.MM_2006
,d.MM_2007
,d.MM_2008
,d.MM_2009
,d.MM_2010
,d.MM_2011
,d.MM_2012
,d.MM_2013
,d.MM_2014
,d.MM_2015
,d.MM_2016
,d.MM_2017
,b.* 
from [pdb_WalkandWin].[dbo].[GP1026_WnW_Member_Subset] as a
left join pdb_WalkandWin.dbo.GP1026_WnW_RAF as b on a.SavvyHICN = b.SavvyHICN
left join MiniOV..SavvyID_to_SavvyHICN as c on a.SavvyHICN = convert(varchar,c.SavvyHICN)
left join MiniOV.dbo.Dim_Member as d on c.SavvyID = d.SavvyID
where b.RAFCompute_2013 is null 
	and b.RAFCompute_2014 is null 
	and b.RAFCompute_2015 is null 
	and b.RAFCompute_2016 is null