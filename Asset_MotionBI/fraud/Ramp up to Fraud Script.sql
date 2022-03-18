use pdb_DermFraud; 
Drop table #tier2firstOffense
Select a.Memberid,b.ProgramStartDate, Min(Logdate) as firsttierTwoOffense, enrolledDates = count(Distinct c.Full_Dt)
,Count(Distinct a.logdate) as offenses
Into #tier2firstOffense
FROM fraudRollup  a 
	Inner join pdb_DermReporting.dbo.Dim_member b
		On a.Memberid = b.Dermsl_memberid
	Inner join pdb_DermReporting.dbo.vwProgramActivity_EnrolledDates c
		On b.Account_ID = c.Account_ID
where lookupClientid = 50 and MaxScore = 10 
Group by a.Memberid, b.ProgramStartDate
Having Count(Distinct a.logdate) > 3 

go
Drop table #Template
Select Distinct Memberid,firsttierTwoOffense, number, a.enrolledDates, a.ProgramStartDate
Into #Template
FROM #tier2firstOffense a
Inner join number b
	On b.Number between 0 and 100 
Where a.enrolledDates >= 50
go 

Drop table udb_Ghyatt.dbo.LeaduptoFraud

Select a.Memberid, b.Logdate, Date = Dateadd(day,-number,FirsttierTwoOffense)
, LeadupDate = DateDiff(day,Dateadd(day,-number,firsttierTwoOffense),a.FirstTierTwoOffense)
,LeadupWeek = DateDiff(week,Dateadd(day,-number,firsttierTwoOffense),a.FirstTierTwoOffense)
, number
, tier1 = case when b.MaxScore >= 5 then 1 else 0 end 
, TotalDays = a.enrolledDates
,dd.* 
Into udb_Ghyatt.dbo.LeaduptoFraud
FROM 
#Template a 
	Left join FraudRollup b
		On a.Memberid  = b.memberid 
		and b.LogDate < a.firsttierTwoOffense 
		and Number = Datediff(Day, b.Logdate, firsttierTwoOffense)
	Left join pdb_DermReporting.dbo.dim_Date dd
		On Dateadd(day,-number,firsttierTwoOffense) = dd.full_dt
Where Dateadd(day,-number,FirsttierTwoOffense) > ProgramStartdate
order by a.memberid, Logdate

Select * FROM udb_Ghyatt.dbo.LeaduptoFraud order by memberid, Number

/*****Look for members with 6 + Tier 1 incidents in a month/week and see what % end up committing Tier 2*********/

Drop table #EpisodeofFraud
Select Memberid, Logdate = min(Logdate)
into #EpisodeofFraud
FROM 
( 
Select Memberid, Logdate, maxScore
,LeadScore =  Lead(maxScore,6,null) over(partition by memberid order by logdate)
,Lead_Logdate =  Lead(Logdate,6,null) over(partition by memberid order by logdate) 

FROM fraudRollup Where MaxScore >= 5 
) a 
where Lead_Logdate <= dateadd(day,14,Logdate)
Group by Memberid


Select Sum(Case when tier2 >= 3 then 1 else 0 end )*1.00/count(*)
FROM 
(
Select a.memberid,a.logdate,tier2 =  sum(Case when b.Maxscore = 10 then 1 else 0 end)  FROM #EpisodeofFraud a 
	Left join FraudRollup b
		ON a.Memberid = b.memberid 
		and b.Logdate > a.Logdate 
		and b.MaxScore = 10 
Group by a.memberid, a.Logdate
) a