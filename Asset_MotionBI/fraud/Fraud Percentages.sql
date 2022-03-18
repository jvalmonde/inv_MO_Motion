use Dermsl_Prod; 



Select 
TotalDates            = count(*) 
,totalTier1Dates	  = Count( Case when MaxScore = 5 then           f.memberid else null end ) 
,totalTier2Dates	  = Count( Case when MaxScore = 10 then          f.memberid else null end ) 
,totalSamePocketDates = Count( Case when FraudMetricIScore >= 5 then f.memberid else null end ) 
 FROM FraudRollup F 
	iNNER JOIN MemberRuleGroup mrg on f.Memberid = mrg.Memberid 
	inner join lookupRuleGroup lrg on mrg.LookupRuleGroupid = lrg.LookupRuleGroupid
Where Logdate > '20160601' 

order by TotalSamePocketDates desc



Select RuleGroupName,
TotalDates            = count(*) 
,totalTier1Dates	  = Count( Case when MaxScore = 5 then           f.memberid else null end ) 
,totalTier2Dates	  = Count( Case when MaxScore = 10 then          f.memberid else null end ) 
,totalSamePocketDates = Count( Case when FraudMetricIScore >= 5 then f.memberid else null end ) 
 FROM FraudRollup F 
	iNNER JOIN MemberRuleGroup mrg on f.Memberid = mrg.Memberid 
	inner join lookupRuleGroup lrg on mrg.LookupRuleGroupid = lrg.LookupRuleGroupid
Where Logdate > '20160601' 
Group by RuleGroupName
order by RuleGroupname desc


Select Distinct P1, date FROM FraudMetricI_SamePocket Where Score >= 5  and date > '20160601' 