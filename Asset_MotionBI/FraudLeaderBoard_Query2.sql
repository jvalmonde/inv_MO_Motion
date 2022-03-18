USE [pdb_DermFraud]

Declare @Startdate Date = '20160601'
,@Enddate Date = Convert(Date,Getdate())
,@LookupClientid Varchar(Max) = 50 
--as 
--Begin
--set nocount on;

If Object_ID('tempdb.dbo.#LeaderBoard') is not null 
Drop table #LeaderBoard
Select * 
INTO #LeaderBoard
FROM 
(
Select Top 25
 a.Memberid
 ,a.LookupClientId
 ,ClientName
,LeaderboardRank = b.StepsRank
,ActiveMemberFlag = isnull(ActiveMemberFlag,0)
,FraudMetricA = Count(Distinct Case when  FraudMetricAScore >= 5 then Logdate else NULL end)
,FraudMetricB = Count(Distinct Case when  FraudMetricBScore >= 5 then Logdate else NULL end)
,FraudMetricC = Count(Distinct Case when  FraudMetricCScore >= 5 then Logdate else NULL end)
,FraudMetricD = Count(Distinct Case when  FraudMetricDScore >= 5 then Logdate else NULL end)
,FraudMetricE = Count(Distinct Case when  FraudMetricEScore >= 5 then Logdate else NULL end)
,FraudMetricF = Count(Distinct Case when  FraudMetricFScore >= 5 then Logdate else NULL end)
,FraudMetricG = Count(Distinct Case when  FraudMetricGScore >= 5 then Logdate else NULL end)
,FraudMetricH = Count(Distinct Case when  FraudMetricHScore >= 5 then Logdate else NULL end)
,FraudMetricI = Count(Distinct Case when  FraudMetricIScore >= 5 then Logdate else NULL end)
,FraudMetricJ = Count(Distinct Case when  FraudMetricJScore >= 5 then Logdate else NULL end)
,FraudMetricK = Count(Distinct Case when  FraudMetricKScore >= 5 then Logdate else NULL end)
,FraudMetricL = Count(Distinct Case when  FraudMetricLScore >= 5 then Logdate else NULL end)
,TotalScore   = Sum(FraudMetricAScore+
					FraudMetricBScore+
					FraudMetricCScore+
					FraudMetricDScore+
					FraudMetricEScore+
					FraudMetricFScore+
					FraudMetricGScore+
					FraudMetricHScore+
					FraudMetricIScore+
					FraudMetricJScore+
					FraudMetricKScore
					)
,FlaggedDays = Count(Distinct 	Case when  MaxScore >= 5 then LogDate else NULL end )

FROM   pdb_DermFraud.dbo.FraudRollup a 
	Left JOIN  pdb_DermFraud.dbo.StepsLeaderBoard b
		ON a.Memberid = b.memberid
		and a.LookupClientid = b.LookupClientid
	Left JOIN Dermsl_prod.dbo.member c
		ON a.Memberid = c.Memberid	  and a.LookupClientid = c.LookupClientid
	INNER JOIN pdb_Dermfraud.dbo.Delimitedsplit8k(@LookupClientid,',') d ON Convert(varchar(5),a.Lookupclientid) = d.Item
		Left JOIN Dermsl_Prod.dbo.LookupClient e
		ON c.LookupClientid = e.LookupClientid
Where Logdate  between @startdate and @endDate
Group by a.LookupClientid, a.Memberid, Clientname, b.StepsRank	,isnull(ActiveMemberFlag,0)
Order BY FlaggedDays Desc , TotalScore Desc 
) a 
union

Select 
 a.Memberid
 ,a.LookupClientId
 ,ClientName
,LeaderboardRank = b.StepsRank
,ActiveMemberFlag = isnull(ActiveMemberFlag,0)
,FraudMetricA = Count(Distinct Case when  FraudMetricAScore >= 5 then Logdate else NULL end)
,FraudMetricB = Count(Distinct Case when  FraudMetricBScore >= 5 then Logdate else NULL end)
,FraudMetricC = Count(Distinct Case when  FraudMetricCScore >= 5 then Logdate else NULL end)
,FraudMetricD = Count(Distinct Case when  FraudMetricDScore >= 5 then Logdate else NULL end)
,FraudMetricE = Count(Distinct Case when  FraudMetricEScore >= 5 then Logdate else NULL end)
,FraudMetricF = Count(Distinct Case when  FraudMetricFScore >= 5 then Logdate else NULL end)
,FraudMetricG = Count(Distinct Case when  FraudMetricGScore >= 5 then Logdate else NULL end)
,FraudMetricH = Count(Distinct Case when  FraudMetricHScore >= 5 then Logdate else NULL end)
,FraudMetricI = Count(Distinct Case when  FraudMetricIScore >= 5 then Logdate else NULL end)
,FraudMetricJ = Count(Distinct Case when  FraudMetricJScore >= 5 then Logdate else NULL end)
,FraudMetricK = Count(Distinct Case when  FraudMetricKScore >= 5 then Logdate else NULL end)
,FraudMetricL = Count(Distinct Case when  FraudMetricLScore >= 5 then Logdate else NULL end)
,TotalScore   = Sum(FraudMetricAScore+
					FraudMetricBScore+
					FraudMetricCScore+
					FraudMetricDScore+
					FraudMetricEScore+
					FraudMetricFScore+
					FraudMetricGScore+
					FraudMetricHScore+
					FraudMetricIScore+
					FraudMetricJScore+
					FraudMetricKScore
					)
,FlaggedDays = Count(Distinct 	Case when  MaxScore >= 5 then LogDate else NULL end )
FROM   pdb_DermFraud.dbo.FraudRollup a 
	Left JOIN  pdb_DermFraud.dbo.StepsLeaderBoard b
		ON a.Memberid = b.memberid
		and a.LookupClientid = b.LookupClientid
	Left JOIN Dermsl_prod.dbo.member c
		ON a.Memberid = c.Memberid	  and a.LookupClientid = c.LookupClientid
	INNER JOIN pdb_Dermfraud.dbo.Delimitedsplit8k(@LookupClientid,',') d ON Convert(varchar(5),a.Lookupclientid) = d.Item
		Left JOIN Dermsl_Prod.dbo.LookupClient e
		ON c.LookupClientid = e.LookupClientid
Where Logdate  between @startdate and @endDate and a.memberid = 62404
Group by a.LookupClientid, a.Memberid, Clientname, b.StepsRank	,isnull(ActiveMemberFlag,0)
Order BY FlaggedDays Desc , TotalScore Desc

Create Unique Clustered Index idxMember on #LeaderBoard(MemberID)





/****calculate the total Earnings From Fraudulent days***********/

Drop table #AwardsEarned
Select lb.Memberid
, AwardsEarned =  Sum(IIF(lrg.PointsFlag = 0 ,mei.IncentiveAmount, mei.IncentivePoints)) 
,AwardsEarnedFromFraud = Sum(IIF(lrg.PointsFlag = 0  ,IIF( fr.Logdate is not null,mei.IncentiveAmount, 0), IIF(Fr.Logdate is not null, mei.IncentivePoints,0))) 
Into #AwardsEarned 
FROM #LeaderBoard lb
	Inner join Dermsl_prod.dbo.Memberearnedincentives mei 
		On lb.memberid = mei.Memberid 
	Inner join Dermsl_prod.dbo.LOOKUPRule lr 
		ON mei.LookupRuleid = lr.LOOKUPRuleID
	Inner join Dermsl_prod.dbo.LookupRuleGroup lrg 
		ON lr.LookupRuleGroupid = lrg.lookupRuleGroupid
	Left join Fraudrollup fr 
		On fr.Memberid = lb.Memberid and fr.Logdate = mei.Incentivedate and maxscore >= 5
Where mei.IncentiveDate between @Startdate and @Enddate
Group by lb.Memberid




IF Object_ID('Tempdb.dbo.#Emails') is not null
Drop table #Emails

 Select Distinct  a.Memberid, a.Logdate, Emailsent = b.emailsent, RN = Row_number()over(Partition by a.memberid, a.Logdate order by b.emailsent)
 Into #Emails
 FROM pdb_Dermfraud.dbo.FraudRollup a
	INNER JOIN (Dermsl_prod.dbo.EmailLog b
				  INNER JOIN Dermsl_prod.dbo.Email c
					ON b.EmailID = c.Emailid 
				  INNER JOIN Dermsl_prod.dbo.EmailType d
					ON c.EmailtypeID = d.EmailTypeID
					and  d.EmailtypeDescription = 'Fraud Deterrent')
		On 	a.Memberid = b.Memberid
		and b.Emailsent between a.Logdate and Dateadd(day,5,a.Logdate)
		and a.MaxScore >= 5
	--INNER JOIN Dermsl_prod.dbo.Survey e
	--	ON b.Memberid = e.Memberid and b.Emailid = c.Emailid and Convert(Date,e.RowCreatedDateTime) between b.Emailsent and Dateadd(day,5,b.EmailSent)
	


If Object_ID('tempdb.dbo.#FraudDates') is not null 
Drop table #FraudDates

Select 
 a.LookupClientid,
 a.Memberid
 ,ClientName
,LeaderboardRank
,ActiveMemberFlag
,a.FraudMetricA
,a.FraudMetricB
,a.FraudMetricC
,a.FraudMetricD
,a.FraudMetricE
,a.FraudMetricF
,a.FraudMetricG
,a.FraudMetricH
,a.FraudMetricI
,a.FraudMetricJ
,a.FraudMetricK
,a.FraudMetricL
,a.TotalScore  
,a.FlaggedDays 
,b.Steps
,Metrics = Ltrim(Rtrim(
						Case when  FraudMetricAScore >= 5 then 'A' Else '' end + ' ' + 
						Case when  FraudMetricBScore >= 5 then 'B' Else '' end + ' ' + 
						Case when  FraudMetricCScore >= 5 then 'C' Else '' end + ' ' + 
						Case when  FraudMetricDScore >= 5 then 'D' Else '' end + ' ' + 
						Case when  FraudMetricEScore >= 5 then 'E' Else '' end + ' ' + 
						Case when  FraudMetricFScore >= 5 then 'F' Else '' end + ' ' + 
						Case when  FraudMetricGScore >= 5 then 'G' Else '' end + ' ' + 
						Case when  FraudMetricHScore >= 5 then 'H' Else '' end + ' ' + 
						Case when  FraudMetricIScore >= 5 then 'I' Else '' end + ' ' + 
						Case when  FraudMetricJScore >= 5 then 'J' Else '' end + ' ' + 
						Case when  FraudMetricKScore >= 5 then 'K' Else '' end + ' ' +
						Case when  FraudMetricLScore >= 5 then 'L' Else '' End 				
				))
,Rank					= Row_Number()over(order by a.FlaggedDays Desc)
,FlaggeddaysToDate		= Count( b.LogDate) Over(Partition by a.Memberid, ClientName)
,Logdate				= Convert(datetime,b.Logdate)
,EmailSent				= Convert(Date,EmailSent)
,FraudDayCount          = Dense_rank() Over(Partition by a.Memberid, Clientname Order by b.Logdate Desc)
,EgregiousDates			= Count( Case when MaxScore = 10 then b.logdate else null end)over(Partition by a.Memberid,Clientname)
,SuspicionLevel			= Case when MaxScore = 5 then 'Moderate' when MaxScore = 10 then 'Severe' Else 'Normal' end
Into #FraudDates 
FROM  #LeaderBoard a
	INNER JOIN 	  FraudRollup b
		On a.Memberid = b.Memberid 
		and b.MaxScore >= 5 
	Left Join #Emails	 c
		ON b.Logdate = Convert(Date,c.Logdate)
		and b.memberid = c.Memberid
		and c.Rn =   1 

 Create  Clustered index idxuserdate on #FraudDates(Memberid,Logdate)

If Object_Id('tempdb.dbo.#Template') is not null
Drop table #Template
Select
a.LookupClientid,
 a.Memberid
 ,ClientName
,LeaderboardRank
,ActiveMemberFlag
,a.FraudMetricA
,a.FraudMetricB
,a.FraudMetricC
,a.FraudMetricD
,a.FraudMetricE
,a.FraudMetricF
,a.FraudMetricG
,a.FraudMetricH
,a.FraudMetricI
,a.FraudMetricJ
,a.FraudMetricK
,a.FraudMetricL
,a.TotalScore  
,a.FlaggedDays 
,Steps					
,FlaggeddaysToDate		
,Logdate
,EmailSent
,Rank	
,Metrics			
,Logdatetime = Dateadd(Minute,Number,Logdate)
,EgregiousDates		
,SuspicionLevel	
INTO #Template 
FROM #FraudDates a
	Cross JOIN Number b
Where b.Number between 0 and 1439 and a.FraudDayCount <= 25 



Create  Clustered index idxFBMinute on #Template(Memberid,Logdate,Logdatetime)
Create nonclustered index idxFBsysuser on #Template(Logdatetime)




If Object_Id('tempdb.dbo.#SignatureDateTime') is not null 
Drop table #SignatureDateTime

Select Distinct b.Customerid, SampleDate, SampleDateTime = Dateadd(Minute,DateDiff(Minute,'19000101',SampleTime),Convert(DateTime,SampleDate)),c.Memberid
Into #SignatureDateTime
 FROM SignatureSample b
	INNER JOIN Dim_Member c
		ON b.Customerid = c.CustomerID
	INNER JOIN #FraudDates FD
		ON C.Memberid = Fd.memberid 
Where c.Customerid not in ( 15131, 15136)

Create unique clustered index idxCustdate on #SignatureDateTime(Customerid, SampleDateTime)




/********************************************/
 If Object_Id('tempdb.dbo.#FraudOutput') is not null 
Drop table #FraudOutput

Select 
a.LookupClientid,
 a.Memberid
 ,ClientName
,LeaderboardRank
,EgregiousDates		
,SuspicionLevel	
,ActiveMember = ActiveMemberFlag
,a.FraudMetricA
,a.FraudMetricB
,a.FraudMetricC
,a.FraudMetricD
,a.FraudMetricE
,a.FraudMetricF
,a.FraudMetricG
,a.FraudMetricH
,a.FraudMetricI
,a.FraudMetricJ
,a.FraudMetricK
,a.FraudMetricL
,a.TotalScore  
,a.FlaggedDays 
,Rank = Convert(Int,Rank)
,ActiveMemberFlag  = 1					
,RankingScore = sum(Case when a.TotalScore >= 5 then a.TotalScore else 0 end) over(Partition by a.Lookupclientid, a.memberid) 
,FlaggeddaysToDate		
,a.Logdate
,EmailSent
,Metrics
,TotalSteps = a.Steps
,Minute = Left(Convert(Time(0),a.Logdatetime) ,5)
,Steps = isnull(convert(Int,Steps.Logvalue),0)
,SignatureRead = Case when smpltime.Memberid is not null then 1 else NULL end
,Rn = Row_Number()Over(Partition by a.Memberid, a.Logdate order by  a.Logdatetime)
INTO #FraudOutput
FROM #Template a Inner join Dermsl_prod.dbo.MemberRulegroup mrg on a.Memberid = mrg.memberid 
	Left JOin Dermsl_prod.dbo.MemberIntradayData Steps
		On  a.Memberid = steps.Memberid
		and a.Logdatetime = steps.Logdatetime
	Left JOIN #SignatureDateTime SmplTime
		On a.Memberid = smpltime.memberid
		and a.Logdate = smplTime.SampleDate
		and a.LogdateTime = smplTime.sampleDateTime
Order by Rank,Memberid,Lookupclientid,Logdate desc, minute

Drop table #FraudOutput2
Select * ,LeaderboardPos = Dense_Rank()Over(Order by RankingScore desc, memberid)
into #FraudOutput2
FROM #FraudOutput




GO
Drop table pdb_DermFraud.dbo.AllSaversMotion_FraudLeaderboard
Select 
EgregiousDates		
,SuspicionLevel
, f.Memberid
,ClientName
,LeaderboardRank
,ActiveMember
,FraudMetricA
,FraudMetricB
,FraudMetricC
,FraudMetricD
,FraudMetricE
,FraudMetricF
,FraudMetricG
,FraudMetricH
,FraudMetricI
,FraudMetricJ
,FraudMetricK
,FraudMetricL
,TotalScore  
,FlaggedDays 
,Rank
,ActiveMemberFlag					
,LeaderBoardPos 
,FlaggeddaysToDate		
,f.Logdate
,EmailSent
,[EmailSent?] = Case when emailsent is not null then 1 else 0 end
,Metrics
,TotalSteps
,Minute
,f.Steps
,SignatureRead
,Rn 
,Prompt
,ResponseText
,OthersSpecify
,AwardsEarned = ae.AwardsEarned
,AwardsEarnedFromFraud = ae.AwardsEarnedFromFraud
into pdb_DermFraud.dbo.AllSaversMotion_FraudLeaderboard
 FROM (#FraudOutput2	f inner join Dermsl_prod.dbo.memberRuleGroup mrg on f.Memberid = mrg.memberid ) 
	Left JOIN FraudSurveyResponses fsr on f.memberid = fsr.Memberid and fsr.Logdate = f.Logdate
		left join #AwardsEarned ae on f.Memberid = ae.Memberid 


Drop table pdb_DermFraud.dbo.KAFraudLeaderboard
 Select *
 INTO pdb_DermFraud.dbo.KAFraudLeaderboard FROM pdb_DermFraud.dbo.AllSaversMotion_FraudLeaderboard

 union

 Select * FROM pdb_DermFraud.dbo.KeyAccountsFraudLeaderBoard

Select * FROM pdb_DermFraud.dbo.KAFraudLeaderboard where Memberid = 62404
 --Select Distinct memberid from pdb_DermFraud.dbo.KAFraudLeaderboard
 --Select * FROM Pdb_Dermreporting.dbo.vwProgramSync ps inner join pdb_DermReporting.dbo.Dim_Member dm on ps.Account_ID = dm.Account_id where Firstname = 'Jessica' and lastname = 'Brown' order by syncdate desc