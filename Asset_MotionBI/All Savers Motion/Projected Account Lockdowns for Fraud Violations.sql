use pdb_DermFraud; 




Select dbo.Yearmonth(logdate), Count(distinct Memberid) 
FROM
(
Select * 
,Count( Logdate) Over(Partition by Memberid Order by Logdate Rows Between current Row and 1 Following) as Emails
,Max( Response) Over(Partition by Memberid Order by Logdate Rows Between current Row and 1 Following) as ResponseFinal
FROM 
(
Select  F.memberid, f.Logdate, f.Steps, f.MaxScore, EmailTypeSent = EmailDescription, SurveyCode, Response = Max(Case when fs.Surveyid is not null then 1 else 0 end) 
 FROM (Devsql14.pdb_DerMFraud.dbo.Fraudrollup	f 
	inner join Devsql14.Dermsl_prod.dbo.memberRuleGroup mrg on f.Memberid = mrg.memberid )  
	Left JOIN (Devsql14.Dermsl_prod.dbo.Survey s INNER JOIN Devsql14.Dermsl_Prod.dbo.Email e on s.EmailID = e.EmailID inner join Devsql14.Dermsl_prod.dbo.emailtype et on e.Emailtypeid = et.emailtypeid) 		 
							ON f.Memberid = s.Memberid 
							and s.rowCreatedDateTime between f.Logdate and dateadd(day,5, f.logdate) 
							and et.emailtypedescription like '%Fraud%'
							and e.EmailDescription like '%Tier 2%'
	Left JOIN pdb_Dermreporting.dbo.Fact_Survey fs   ON  Convert(BigInt,Convert(Varchar(30),s.SurveyCode ) + Convert(Varchar(5),s.EmailiD)) = Convert(BigInt,pdb_DermReporting.[dbo].[RemoveNonNumericCharacters](CustomData))
	
   Where MaxScore >= 10 and f.LookupClientID = 50 and Logdate >='20160101'--and f.memberid = 13811 
   Group by F.memberid, f.Logdate, f.Steps, f.MaxScore,  EmailDescription,SurveyCode

) a
) a
Where EmailTypeSent is not null  and Emails = 2  and ResponseFinal = 0 
Group by dbo.Yearmonth(logdate)



use pdb_DermFraud; 




Select Count(distinct Memberid) 
FROM
(
Select * 
,Count( Logdate) Over(Partition by Memberid Order by Logdate Rows Between current Row and 1 Following) as Emails
,Max( Response) Over(Partition by Memberid Order by Logdate Rows Between current Row and 1 Following) as ResponseFinal
FROM 
(
Select  F.memberid, f.Logdate, f.Steps, f.MaxScore, EmailTypeSent = EmailDescription, SurveyCode, Response = Max(Case when fs.Surveyid is not null then 1 else 0 end) 
 FROM (Devsql14.pdb_DerMFraud.dbo.Fraudrollup	f 
	inner join Devsql14.Dermsl_prod.dbo.memberRuleGroup mrg on f.Memberid = mrg.memberid )  
	Left JOIN (Devsql14.Dermsl_prod.dbo.Survey s INNER JOIN Devsql14.Dermsl_Prod.dbo.Email e on s.EmailID = e.EmailID inner join Devsql14.Dermsl_prod.dbo.emailtype et on e.Emailtypeid = et.emailtypeid) 		 
							ON f.Memberid = s.Memberid 
							and s.rowCreatedDateTime between f.Logdate and dateadd(day,5, f.logdate) 
							and et.emailtypedescription like '%Fraud%'
							and e.EmailDescription like '%Tier 2%'
	Left JOIN pdb_Dermreporting.dbo.Fact_Survey fs   ON  Convert(BigInt,Convert(Varchar(30),s.SurveyCode ) + Convert(Varchar(5),s.EmailiD)) = Convert(BigInt,pdb_DermReporting.[dbo].[RemoveNonNumericCharacters](CustomData))
	
   Where MaxScore >= 10 and f.LookupClientID = 50 and Logdate >='20160101'--and f.memberid = 13811 
   Group by F.memberid, f.Logdate, f.Steps, f.MaxScore,  EmailDescription,SurveyCode

) a
) a
Where EmailTypeSent is not null  and Emails = 2  and ResponseFinal = 0 


/***How many People are responsible for all the tier 2 violations****/

Select Yearmonth
,  OneIncident = Count(Case when count = 1 then memberid else null end)
,  TwoIncidents = Count(Case when count = 2  then memberid else null end)
,  [3-5Incidents] = Count(Case when count between 3 and 5 then memberid else null end)
,  [6-10Incidents] = Count(Case when count between 6 and 10  then memberid else null end)
,  MoreThan10incidents = Count(Case when count > 10  then memberid else null end)
,TotalMembers = Count(*) 
,TotalDays = Sum(Count)
FROM 
(

Select Yearmonth = dbo.Yearmonth(Logdate), Memberid, Count = Count(*)
FROM FraudRollup Where maxScore = 10 and logdate >= '20160101' and LookupClientID = 50 
group by dbo.Yearmonth(Logdate),Memberid
) a
Group by Yearmonth

Select * FROM FrauDrollup where memberid = 13811 and Logdate = '20150226'
Select * FROM Dermsl_prod.dbo.member where memberid = 13811