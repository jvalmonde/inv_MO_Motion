use pdb_DermFraud;



/****Table created above******/

/*****Updates needed:

1. Enable run on pdb_DermFraud.
2. Search past survey responses for results like 'marathon, ultra, cyclist, cycling, cycle, runner, etc and exclude those members from lockout.
3. Create table of members that have been locked out in the past and the date of lockout so that we can see when that occurred.  Reconsider them for lockout only based on data received at least one month after lockout date.
4. --Need to include K score in calc for max score.
5. Create stored proc for Jason's team that will pull only those members that are eligible for a lockout.
6.  Reorganize query so that first check is whether the step data qualifies for lockout.  Nex step is to check email



---Updated 12/9/2016 - using non-replicated survey table from pdb_DermFraud instead of dermsl-prod.dbo.Fraud_surveyRespondents from prd-02.  Line 111
****/

/****pull a list of people that have tripped the teir 2 fraud at least three times in the last 30 days****/
If object_Id('tempdb.dbo.#Offenders') is not null
Drop table #Offenders

Select * 
Into #Offenders 
FROM 
(
Select  Memberid, Logdate,Offenses = Count(*)over(partition by Memberid), firstOffence = min(Logdate)over(partition by Memberid)
FROM FraudRollup  f
where logdate >= dateadd(day,-32,getdate()) and lookupClientid in (50,175) and MaxScore = 10
and not exists (select * FROM LockoutQualifications lq where  f.memberid = lq.memberid and f.Logdate <= dateadd(day,30, Lockoutdate))
) a 
where offenses >= 3




--Need to include K score in calc for max score.

/*******Emails by Member****/


If Object_Id('tempdb.dbo.#EmailsByMember') is not null 
Drop table #EmailsByMember

Select e.Memberid, Emails = Count(*) , FirstEmail = Min(Convert(date,EmailSent)) ,  LastEmail = Max(Convert(date,EmailSent))
Into #EmailsByMember
FROM pdb_DermReporting.dbo.EmailLog e
	Inner join dermsl_prod.dbo.Email e2 
		on e.Emailid = e2.Emailid
Where  e2.EmailDescription like  ('Fraud Tier 2%') and emailsent >= dateadd(day,-32,getdate())
and not exists( Select * from #Offenders o where e.Memberid = o.memberid and e.emailSent < o.firstOffence)
group by e.Memberid

Create  clustered index idxemailid on #EmailsByMember(Memberid,Emails)
Create nonclustered index idxmulti on #EmailsByMember(Memberid) include(FirstEmail,  LastEmail)


/***Email records*****/
If Object_Id('tempdb.dbo.#EmailLog') is not null 
Drop table #EmailLog

Select e.* ,  EmailSentDate = Convert(date,EmailSent)
Into #EmailLog
FROM Dermsl_Prod.dbo.EmailLog e
	Inner join dermsl_prod.dbo.Email e2 
		on e.Emailid = e2.Emailid
Where  e2.EmailDescription like  ('Fraud Tier 2%') and emailsent >= dateadd(day,-32,getdate())
and not exists( Select * from #Offenders o where e.Memberid = o.memberid and e.emailSent < o.firstOffence)
Create  clustered index idxemailid on #EmailLog(Emailid,EmailSent)
Create nonclustered index idxmulti on #Emaillog(Memberid) include(EmailId,  EmailSent, Emailto)



If Object_id('tempdb.dbo.#Survey') is not null 
Drop table #Survey

Select s.Memberid
, SurveySentDate = Convert(date,s.RowCreatedDateTime)
, SurveyCustomDataid = dbo.pad(Convert(Varchar(30),s.SurveyCode ),10,'0','l') + 'E' + Convert(Varchar(5),s.EmailiD) 
Into #Survey
FROM  Dermsl_prod.dbo.Survey S Where 1 = 1 -- and isnumeric(s.surveycode) = 1 
and s.rowCreatedDateTime >= dateadd(day,-60,Convert(date,Getdate()))

Create clustered index idxMID on #Survey( Memberid)
Create nonclustered index idx on #Survey( SurveySentDate) include(SurveyCustomDataid)


/**************************/


If object_Id('tempdb.dbo.#Responses') is not null
Drop table #Responses

Select Memberid, SurveysSent = Count(*), Responses = Count(respondentid)
into  #Responses 
FROM 
(
Select   Distinct  e.Memberid, s.SurveySentDate,h.RespondentID

FROM #EmailLog e	/******Filter B:this filters out the users who have already been sent an email in the past two weeks.*****/
			INNER JOIN  Dermsl_Prod.dbo.Email f
				ON e.EmailID = f.EmailID 
				and EmailDescription like ('%Fraud Tier 2%')
			INNER JOIN Dermsl_Prod.dbo.Member g 
				ON e.Memberid = g.Memberid
			INNER JOIN   #Survey S
				ON g.Memberid = S.Memberid 
				--and   E.EmailSentDate  =  s.SurveySentDate
			Left JOIN pdb_DermFraud.dbo.[Fraud_SurveyRespondent] h
				ON SurveyCustomDataid = Left(h.CustomData,14)
Where 1 = 1 --and Datepart(DW,Getdate()) not in (1,7)
and exists (Select * FROM Dermsl_Prod.dbo.LookupClient LC Where Lc.LookupClientid = g.LOOKUPClientID and lc.lookupClientid in (50,175) and LC.EnableFraudServicesFlag = 1 )
) a 
group by Memberid


/****Check for marathoners and ultra runners*****/

Select * 
FROM 



If Object_Id('tempdb.dbo.#exempt') is not null 
Drop table #exempt

Select Distinct surv.memberid
Into #exempt
FROM (Select CustomData FROM  Fact_SurveyResponse union  S Inner join Dermsl_prod.dbo.Survey surv on left(s.Customdata,14) = dbo.pad(Convert(Varchar(30),surv.SurveyCode ),10,'0','l') + 'E' + Convert(Varchar(5),surv.EmailiD)  
Where 1 = 1 and OthersSpecify is not null 
and  (OthersSpecify like '%Marathon%'
or OthersSpecify like '%Distance%'
or OthersSpecify like '%Ultra%'
or OthersSpecify like '%Cyclist%'
or OthersSpecify like '%Cycling%')





/*****The results*************************************************/

If Object_Id('tempdb.dbo.#Lockouts') is not null 
Drop table #Lockouts

Select lrg.LookupRulegroupid,lrg.RuleGroupname, s.Email, m.Memberid,m.Firstname, m.Lastname, m.Gender, m.City, m.Statecode 
Into #Lockouts
FROM Dermsl_Prod.dbo.Member m 
	Inner join Dermsl_Prod.dbo.sysuser s on m.Sysuserid = s.Sysuserid 
	inner join Dermsl_Prod.dbo.memberruleGroup mrg on m.memberid = mrg.memberid 
	inner join Dermsl_Prod.dbo.lookupRuleGroup lrg on mrg.lookupRuleGroupid = lrg.lookupRuleGroupid
Where m.memberid in (
						
										Select a.memberid FROM #Offenders a
											Where 1 = 1 
											and (Exists(Select * FROM #EmailsByMember b where a.memberid = b.Memberid and b.LastEmail <= Dateadd(day,-3,getdate()) and b.Emails > 1 )
													or Exists(Select * FROM #EmailsByMember b where a.memberid = b.Memberid and b.LastEmail <= Dateadd(day,-1,getdate()) and b.Emails > 3 ))
											and Not exists(Select * FROM #Responses c where a.Memberid = c.Memberid  and responses > 0 )
										and Offenses >= 3 
										and not exists(Select * FROM #Exempt e where e.memberid = a.memberid) 
									) 

 
and m.ActiveMemberFlag = 1 
and lrg.LookupClientid = 50 


use pdb_DermFraud;
Insert Into LockoutQualifications
(LookupRuleGroupid, Email, Memberid,Firstname, Lastname, Gender, City, Statecode, Lockoutdate )
Select Distinct  LookupRulegroupid, Email, Memberid,Firstname, Lastname, Gender, City, Statecode, LockoutDate = convert(Date,getdate())  
FROM #Lockouts l 
	Where not exists(Select * FROM LockoutQualifications lq where l.Memberid = lq.memberid and lq.Lockoutdate = Convert(Date,getdate()))

	Select 
	lq.Memberid,
	LockoutDate,
	Email = Lower(lq.email),
	Firstname = dbo.Propercase(lq.firstname),
	Lastname  = dbo.Propercase(lq.Lastname), 
	Gender,
	City        = dbo.Propercase(lq.city),
	StateCode,
	RuleGroupName = dbo.Propercase(Rulegroupname)
	,LookupClientid
	FROM pdb_DermFraud..LockoutQualifications lq
			inner join Dermsl_Prod.dbo.memberruleGroup mrg on lq.memberid = mrg.memberid 
			inner join Dermsl_Prod.dbo.lookupRuleGroup lrg on mrg.lookupRuleGroupid = lrg.lookupRuleGroupid 
where lockoutdate = Convert(Date,getdate())

/****Improvements for Automation

1. Reliable coding for Survey Monkey Ids.


******/
select m.Memberid, Lockoutdate = '20161206', email, Firstname, Lastname, Gender, City, Statecode,ruleGroupname FROM Dermsl_Prod.dbo.sysuser s
	Inner join dermsl_prod.dbo.member m 
		on s.Sysuserid = m.Sysuserid 
				inner join Dermsl_Prod.dbo.memberruleGroup mrg on m.memberid = mrg.memberid 
			inner join Dermsl_Prod.dbo.lookupRuleGroup lrg on mrg.lookupRuleGroupid = lrg.lookupRuleGroupid 
where email in('kim.alcoseba+striiv2@gmail.com','kim.alcoseba+astg1003@gmail.com')


Select * FROM LockoutQualifications order by Lockoutdate Desc

/****Inspect the data and show the distribution of members across rule groups, also show what percentage of the group****/
use dermsl_prod;
Select 
msd.Lookuprulegroupid,
lrg.Rulegroupname
,[Total in Group] = Count(*)
,[Total For Lockout] = Count(m.memberid)
 FROM Membersignupdata msd 
	Left join (Select * FROM Member m 
				Where m.memberid in (
										Select a.memberid  From pdb_DermFraud..LockoutQualifications a Where a.lockoutdate = Convert(Date,getdate())
									) 
				)  m
		On m.clientmemberid = msd.clientmemberid 
		and m.Lookupclientid = msd.LookupClientid
Inner join Dermsl_Prod.dbo.LookupRulegroup lrg 
	On msd.LookupRuleGroupid = lrg.LookupRuleGroupid 
Where msd.activeflag = 1 
Group by msd.Lookuprulegroupid,
lrg.Rulegroupname
Having Count(m.Memberid) > 0 

Select * FROM #EmailsByMember where memberid = 13896

--Select * FROM Member Where lastname like '%lanners%'
--Select * FROM lookupTenant
--Select * FROM lookupClient
Select * FROM  #Offenders where memberid = 13896

/*****


Outstanding:
---Remove anyone that has exception qualification.


Resolved:
 
---What companies have lots of people, do we contact an admin?
---How much time should they have to answer the surveys.  --Make sure that the most recent survey is at least 3 days old.
---Multi-device fraud.
---At least 3 days since last communication.
---What is the distribution across companies. Break out by All savers and key accts.
---Responses
---Add setser to the list                              
---Lock out on Monday.  Not Thursday(send the list on Friday morning)
---Remove anyone that has exception qualification.
---What companies have lots of people, do we contact an admin?




******/
use pdb_Dermfraud;

select * FROM FraudRollup where fraudmetricIscore > 4  and Memberid = 13896
Select * FROM FraudMetricI_SamePocket where Date >= '20161115'
order by P1, date

--Select Memberid, Logdate  FROM FraudRollup 
--where FraudmetricIScore = 5 



--SELECT Distinct 
--		ds.SurveyName,
--		--,a.[SurveyID]
--  --    ,[CollectorID]
--  --    ,[RespondentID]
--  --    ,[CustomData]
--  --    ,[StartDate]
--  --    ,[EndDate]
--  --    ,[IPAddress]
--  --    ,[EmailAddress]
--  --    ,[FirstName]
--  --    ,[LastName]
--  --    ,[PromptID]
--  --    ,[ResponseID]
--  --    ,[Prompt]
--  --    ,[ResponseText]
--    customdata, [OthersSpecify]
--  FROM [Survey_Prod].[dbo].[vwFact_Survey] a
--	Inner join Dim_Survey ds on a.Surveyid = ds.Surveyid
--Where (surveyName like '%activity%' or surveyname like '%Fraud%') and OthersSpecify is not null and othersSpecify is not null and (othersSpecify like '%marathon%' or othersSpecify like '%bike%' or othersSpecify like '%run%' or othersSpecify like '%Ultra%')
----and  othersSpecify like '%Retarded%'




Select 1043 * 3 FROM FraudRollup 
Where Logdate >= dateadd(day,-30,getdate()) and maxScore > 3 and  Memberid in (
20007
,20041
,19806
,13896
,13885
,19797
,19537
,32504
,13956
,16998
,17221
,17223
,19162
,23922
,23000
,25685
,51427
,51579
,74082
,28064
,35253
,72217
,31898
,29684
,29348
,29268
,46405
,43891
,32676
,36006
,32060
,66841
,66830
,40927
,40896
,43219
,39900
,54105
,54445
,43961
,43973
,49596
,49597
,57511
,57465
,55584
,65092
,54529
,54527
,54471
,54444
,54469
,54547
,69479
,69153
,66683
,60551
,66776
,66571
,66731
,75936
,72845
,76235
,73372
,75057
,74944)

select (3126 *1.00)/ 66 


