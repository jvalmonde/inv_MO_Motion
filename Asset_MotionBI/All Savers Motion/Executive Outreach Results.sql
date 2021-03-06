/****** Script for SelectTopNRows command from SSMS  ******/
If object_Id('pdb_DermReporting.dbo.ExecutiveOutreachresults_Tx') is not null 
Drop table pdb_DermReporting.dbo.ExecutiveOutreachresults_Tx


Select * ,
AvgAgeTicker = Dense_rank()Over(Partition by outreachflag,daysFromEligibility, AvgAge, CountofLivesbin order by LookupRuleGroupid)
Into pdb_DermReporting.dbo.ExecutiveOutreachresults_Tx
FROM 
(SELECT  [Start], GroupStartDateTime
      ,[ASSN]
      ,[CLTNBR]
      ,[GROUP]
	  ,lrg.LOOKUPRuleGroupID
	  ,lrg.RuleGroupname
      ,[Lives]
      ,v.StateCode as State
      ,[CallDate]
	  ,v.Date
      ,[Voicemail_Email]
      ,[ParsedResult]
	  ,OutreachFlag  = IIF(h.Assn is null,0,1)
      ,[TwoCallInd]
	  ,DaysFromEligibility = datediff(Day,GroupStartdateTime, v.Date) 
	  ,v.isRegistered
	  ,v.TotalSteps
	  ,v.EligibleID
	  ,Age = Datediff(Year,Birthdate,Getdate())
	  ,GenderCode
	  ,Count0fLives = Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility)
	  ,CountofLivesbin = Case when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) >= 50 then '50+'
							  when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) >= 25 then '25+'
							  when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) >= 10 then '10+' 
							  when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) > 0 then  '1+' else null end
	  ,OutreachDate = Case when v.date = h.CallDate then 1 else 0 end 
	  ,AvgAge= Avg(Datediff(Year,Birthdate,Getdate())) over(Partition by v.LookupRuleGroupid, DaysFromEligibility)
  FROM dermsl_reporting.dbo.vwActivityForPreloadGroups v
	Inner join Dermsl_Prod.dbo.LookupRuleGroup lrg	on v.LookupRuleGroupid = lrg.LookupRuleGroupid 
	Left join [pdb_DermReporting].[dbo].[HYExecOutreachResults] h  on h.ASSN + '-' + CLTNBR = lrg.OfferCode
Where  v.ClientName = 'All Savers motion'
and exists(Select * FROM pdb_DermReporting.dbo.ASIC_Wellness_Group_Motion asic where lrg.OfferCode = asic.PolicyID and asic.StateCode = 'Tx')
) a

If object_Id('pdb_DermReporting.dbo.ExecutiveOutreachresults') is not null 
Drop table pdb_DermReporting.dbo.ExecutiveOutreachresults


Select * ,
AvgAgeTicker = Dense_rank()Over(Partition by outreachflag,daysFromEligibility, AvgAge, CountofLivesbin order by LookupRuleGroupid)
Into pdb_DermReporting.dbo.ExecutiveOutreachresults
FROM 
(SELECT  [Start]
      ,[ASSN]
      ,[CLTNBR]
      ,[GROUP]
	  ,lrg.LOOKUPRuleGroupID
	  ,lrg.RuleGroupname
      ,[Lives]
      ,v.StateCode as State
      ,[CallDate]
	  ,v.Date
      ,[Voicemail_Email]
      ,[ParsedResult]
	  ,OutreachFlag  = IIF(h.Assn is null,0,1)
      ,[TwoCallInd]
	  ,DaysFromEligibility = datediff(Day,GroupStartdateTime, v.Date) 
	  ,v.isRegistered
	  ,v.TotalSteps
	  ,v.EligibleID
	  ,Age = Datediff(Year,Birthdate,Getdate())
	  ,GenderCode
	  ,Count0fLives = Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility)
	  ,CountofLivesbin = Case when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) >= 50 then '50+'
							  when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) >= 25 then '25+'
							  when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) >= 10 then '10+' 
							  when Count( EligibleID) over(Partition by v.LookupRuleGroupid, DaysFromEligibility) > 0 then  '1+' else null end
	  ,OutreachDate = Case when v.date = h.CallDate then 1 else 0 end 
	  ,AvgAge= Avg(Datediff(Year,Birthdate,Getdate())) over(Partition by v.LookupRuleGroupid, DaysFromEligibility)
  FROM dermsl_reporting.dbo.vwActivityForPreloadGroups v
	Inner join Dermsl_Prod.dbo.LookupRuleGroup lrg	on v.LookupRuleGroupid = lrg.LookupRuleGroupid 
	Left join [pdb_DermReporting].[dbo].[HYExecOutreachResults] h  on h.ASSN + '-' + CLTNBR = lrg.OfferCode
Where  lrg.GroupStartDatetime = '20161001' and v.ClientName = 'All Savers motion'
) a


Select * FROM pdb_DermReporting.dbo.ExecutiveOutreachresults where  


/********Sample matching***********/
Drop table pdb_DermReporting.dbo.ExecutiveOutreachresultswithParity
Select *
Into pdb_DermReporting.dbo.ExecutiveOutreachresultswithParity
 FROM pdb_DermReporting.dbo.ExecutiveOutreachresults
Where LookupRuleGroupid in 
(
Select Distinct a.LookupRulegroupid FROM pdb_DermReporting.dbo.ExecutiveOutreachresults a
Where exists (Select * FROM pdb_DermReporting.dbo.ExecutiveOutreachresults b Where a.DaysFromEligibility = b.DaysFromEligibility and a.LOOKUPRuleGroupID <> b.LOOKUPRuleGroupID and a.AvgAgeTicker = b.AvgAgeTicker and a.AvgAge = b.AvgAge and a.CountofLivesbin = b.CountofLivesbin)
and a.DaysFromEligibility = 0 and a.OutreachFlag = 0
union
Select Distinct a.LookupRulegroupid FROM pdb_DermReporting.dbo.ExecutiveOutreachresults a Where a.DaysFromEligibility = 0 and OutreachFlag = 1
) 

Select ruleGroupname, lookupRuleGroupid, lives, count(eligibleID) 
FROM pdb_DermReporting.dbo.ExecutiveOutreachresults 
where  DaysFromEligibility = 0  Group by ruleGroupname, lookupRuleGroupid, lives
order by count(eligibleID) desc

Drop table pdb_DermReporting.dbo.ExecutiveOutreachresultswithParity_GroupLevel
Select outreachflag, lookupRulegroupid, DaysFromEligibility, Outreaches = Sum(Outreachdate), ProportionRegistered = sum(isregistered)*1.00/Count(Isregistered)
Into pdb_DermReporting.dbo.ExecutiveOutreachresultswithParity_GroupLevel
 FROM pdb_DermReporting.dbo.ExecutiveOutreachresultswithParity 
 Group by outreachflag,LookupRuleGroupid,DaysFromEligibility
 Order by OutreachFlag,DaysFromEligibility,callDate

 use dermsl_reporting;

 Select Statecode, sum(isregistered), Count(*) FROM vwActivityForPreloadGroups where DaysFromEligibility = 50 Group by Statecode

Select OutreachFlag * FRom Dermsl_prod.dbo.membersignupdata where lookupRulegroupid = 5032

Select Distinct [GROUP] FROM pdb_DermReporting.dbo.[HYExecOutreachResults] a 
except
Select Distinct RuleGroupname  FROM pdb_DermReporting.dbo.ExecutiveOutreachresults where OutreachFlag = 1 


Select * FROM Dermsl_Prod.dbo.LookupRuleGroup where ruleGroupname = 'GALAXY AIR SERVICES FBD LLC'
