USE [DERMSL_Prod]
GO
/****** Object:  StoredProcedure [dbo].[dsStreamlinesManagementReport]    Script Date: 9/9/2016 10:33:47 AM ******/



Set transaction isolation level read uncommitted



/******************Template************************************/
If Object_ID('tempdb.dbo.#LookupRuleGroup') is not null
Drop table #LookupRuleGroup
SELECT  [LOOKUPRuleGroupID]
      ,[LOOKUPClientID]
      ,[RuleGroupName]
      ,[RuleGroupDescription]
      ,[PointsFlag]
      ,[DefaultGroupFlag]
      ,[LOOKUPIncentiveLabelID]
      ,[IntensityStepThreshold]
      ,[IntensityRestMinute]
      ,[FrequencyCycleInterval]
      ,[RowCreatedSysUserID]
      ,[RowModifiedSysUserID]
      ,[RowCreatedDateTime]
      ,[RowModifiedDateTime]
      ,[OfferCode]
      ,[ScreenNameEnable]
      ,[GroupStartDatetime] = Case when GroupStartdatetime is null then  IIF(RowCreatedDatetime <= '20130101','20130101',RowCreatedDatetime) else IIF(GroupstartdateTime <= '20130101','20130101',GroupStartdatetime) end
      ,[GroupEndDatetime]    = case when groupendDatetime > getdate() then getdate() when groupendDatetime is null then getdate() else groupendDatetime end
	   Into #LookupRuleGroup
  FROM [DERMSL_Prod].[dbo].[LOOKUPRuleGroup]


If OBJECT_ID('tempdb.dbo.#Reporttemplate') is not null
Drop table #Reporttemplate
---Builds a template for each date from start until today

select *
into #Reporttemplate
from (
Select 
  Unit = 'Month'
, lc.LookupTenantid 
, lrg.Lookupclientid 
, lrg.LookupRuleGroupid

, Display  = Convert(varchar(2),DatePart(Month,Dateadd(day,Number,Convert(Date,GroupstartDatetime))) )   + '/' +  Convert(Varchar(4),DatePart(Year,Dateadd(day,Number,Convert(Date,GroupStartDateTime)))   )
, BeginDate = Min(Dateadd(day,Number,Convert(Date,GroupstartDatetime)))
, EndDate   = Max(Dateadd(day,Number,Convert(Date,GroupstartDatetime)))      
--,rn = row_number() over (partition by lrg.LookupClientid order by Min(Dateadd(day,Number,Convert(Date,GroupstartDatetime))) desc) -1
FROM Number n
	Inner join #LookupRuleGroup lrg on n.number between 0 and  Datediff(day,GroupStartDateTime,GroupEndDatetime)
	Inner join LookupClient    lc on  lrg.LookupClientid = lc.LookupClientid 
Group by   lc.LookupTenantid 
, lrg.Lookupclientid 
 ,lrg.LookupRuleGroupid
,Convert(varchar(2),DatePart(Month,Dateadd(day,Number,Convert(Date,GroupstartDatetime))) )   + '/' +  Convert(Varchar(4),DatePart(Year,Dateadd(day,Number,Convert(Date,GroupStartDateTime))))

UNION


Select 
  Unit = 'Week'
, lc.LookupTenantid 
, lrg.Lookupclientid 
, lrg.LookupRuleGroupid
, Display  = Convert(varchar(3),Datediff(Week,GroupstartDatetime,Dateadd(day,Number, GroupStartDateTime)) )
, BeginDate = Min(Dateadd(day,Number,Convert(Date,GroupstartDatetime)))
, EndDate   = Max(Dateadd(day,Number,Convert(Date,GroupstartDatetime)))      
--,rn = row_number() over (partition by lrg.LookupClientid order by Min(Dateadd(day,Number,Convert(Date,GroupstartDatetime))) desc) -1
FROM Number n
	Inner join #LookupRuleGroup lrg on n.number between 0 and  Datediff(day,GroupStartDateTime,GroupEndDatetime)
	Inner join LookupClient    lc on  lrg.LookupClientid = lc.LookupClientid 
Group by   lc.LookupTenantid 
, lrg.Lookupclientid 
, lrg.LookupRuleGroupid
,Convert(varchar(3),Datediff(Week,GroupstartDatetime,Dateadd(day,Number, GroupStartDateTime)) )
)a


Create Unique Clustered Index idxclstr on  #ReportTemplate(Unit,LookupRuleGroupid,BeginDate,EndDate)
Create Index idxDisplay on #ReportTemplate (Display)
Create Index idxClientid on #ReportTemplate (LookupClientid)
Create Index idxendDate on #ReportTemplate (Enddate)
Create Index idxBegindate on #ReportTemplate (Begindate)




--select * from #Reporttemplate where lookupRuleGroupid = 105 order by unit, BeginDate
--where display = '*'


/***RegisteredDays****************/

If OBJECT_ID('tempdb.dbo.#RegisteredDays') is not null
Drop table #RegisteredDays
        ---counts how many days the person was eligible to earn incentives during the period

Select a.LookupTenantid
,a.Lookupclientid
,b.memberid  --added on test
,Display
,b.Location
/*******Removed 9/15/2016 by GHyatt, don't need team name functionality anymore*****
,TeamName = ---b.Location
case when @Group = 'None' then null when @Group = 'GroupName' then c1.RuleGroupName when @Group = 'Location' then iif( b.Location is null or b.Location = '' , 'Unknown',b.Location) end  --)
 ****************/
,CancelledDatetime
,ActiveMemberFlag
,b.BirthDate
,c.LOOKUPRuleGroupID
-- updated based on logic taht some people can deactivate and reactivate thier account and cancelleddatetime is not always reset to null
,DaysInProgram =  SUM(Case when b.RowCreatedDateTime >= a.Begindate and b.RowCreatedDateTime <= a.EndDate and ActiveMemberFlag = 1 then DateDiff(Day,b.RowCreatedDateTime,a.EndDate) + 1
                                            when b.RowCreatedDateTime >= a.Begindate and b.RowCreatedDateTime <= a.EndDate and (CancelledDateTime is not null and ActiveMemberFlag = 0) and Convert(date,b.CancelledDateTime) between a.Begindate and a.Enddate then DateDiff(Day,b.RowCreatedDateTime,b.CancelledDateTime) + 1      ---Added ActivememberFlag to requirement for not registered.
                                            when b.RowCreatedDateTime >= a.Begindate and b.RowCreatedDateTime <= a.EndDate and (CancelledDateTime is not null and ActiveMemberFlag = 0) and Convert(date,b.CancelledDateTime) not between a.Begindate and a.Enddate then DateDiff(Day,b.RowCreatedDateTime,a.EndDate) + 1
                                            when b.RowCreatedDateTime < a.Begindate and ActiveMemberFlag = 1 then DateDiff(Day,a.Begindate,a.EndDate) + 1
                                            when b.RowCreatedDateTime < a.Begindate and (CancelledDateTime is not null and ActiveMemberFlag = 0)  and Convert(date,b.CancelledDateTime) between a.Begindate and a.Enddate then DateDiff(Day,a.Begindate,b.CancelledDateTime) + 1 
                                            when b.RowCreatedDateTime < a.Begindate and (CancelledDateTime is not null and ActiveMemberFlag = 0) and Convert(date,b.CancelledDateTime) not between a.Begindate and a.Enddate then DateDiff(Day,a.Begindate,a.ENDDate) + 1 END
                                            ) 

,NewEnrollment = iif(Convert(date,b.RowCreatedDatetime) between a.Begindate and a.EndDate,1,0)
,Gender
Into #RegisteredDays 
FROM #Reporttemplate a
       INNER join (vMember b INNER JOIN MEMBERRuleGroup c ON b.memberid = c.memberid)
                     ON a.LOOKUPRulegroupID = c.LOOKUPRulegroupID
                     and b.rowCreatedDateTime <= a.Enddate
                     and (isnull(b.CancelleddateTime,getdate()) >= a.BeginDate  )
        
       left JOIN LOOKUPRuleGroup c1
			  on c.LOOKUPRuleGroupID = c1.LOOKUPRuleGroupID 
Where a.lookupClientid = 50  --and a.Lookuprulegroupid < 120
Group by a.LookupTenantid
,a.Lookupclientid,b.memberid
,Display
,b.Location
,b.BirthDate
,CancelledDatetime
,ActiveMemberFlag
,C.Lookuprulegroupid
,iif(Convert(date,b.RowCreatedDatetime) between a.Begindate and a.EndDate,1,0)
,Gender
Order by memberid,Display


--select * from #RegisteredDays



If Object_Id('tempdb.dbo.#GroupMembers') is not null
Drop table #GroupMembers

Select m.*, mrg.LookupRuleGroupid Into #GroupMembers
FROM vmember m 
	Inner join Dermsl_prod.dbo.MEMBERRuleGroup mrg on m.memberid = mrg.memberid 


Create Clustered index idxlrg on #GroupMembers(LookupRuleGroupid)
/****Caluculates the number of    steps*****/

If OBJECT_ID('tempdb.dbo.#StepsforTheGroup') is not null
Drop table #StepsforTheGroup
              ---Aggregates the steps, loggeddays and # of members logging in a period.

Select a.LookupClientid, mei.memberid
, a.Display
,MembersLogging = Count(Distinct iif(TotalSteps >= 300,mei.Memberid,null))
       ,DaysLogged = Count(iif(TotalSteps >= 300,mei.Incentivedate,null))
       ,TotalSteps --per log day  ;did not change the name reduce report update
            = SUM(iif(TotalSteps >= 300,TotalSteps,null))
       ,AvgStepsPerLogDay = AVG(iif(TotalSteps >= 300,TotalSteps,null)) --per log day
INTO #StepsforTheGroup
--Select COUNt(*)
FROM #Reporttemplate a
       INNER JOIN  Dermsl_Prod.dbo.MemberEarnedIncentives mei  ON mei.Incentivedate >= a.BeginDate and mei.Incentivedate <= a.EndDate
	   inner join Dermsl_prod.dbo.LookupRule lr                on mei.LOOKUPRuleID = lr.LOOKUPRuleID and Lr.RuleName = 'Tenacity' 
 
Group by a.LookupClientid,mei.memberid
,  a.Display
Order by memberid,display

--select * from #StepsforTheGroup



/****Incentives************************/

If OBJECT_ID('tempdb.dbo.#IncentivesFortheGroup') is not null          ----Aggregates the incentives earned during a period
Drop table #IncentivesFortheGroup


Select 
a.LookupClientid,c.memberid,  a.Display
,Frequency 
= SUM(
Case when d.RuleName = 'Frequency' and e.PointsFlag = 1 then b.IncentivePoints 
        when d.RuleName = 'Frequency' and e.PointsFlag = 0 then b.IncentiveAmount 
       End)

,Intensity 
= SUM(
Case when d.RuleName = 'Intensity' and e.PointsFlag = 1 then b.IncentivePoints 
        when d.RuleName = 'Intensity' and e.PointsFlag = 0 then b.IncentiveAmount 
       End)

,Tenacity 
= SUM(
Case when d.RuleName = 'Tenacity' and e.PointsFlag = 1 then b.IncentivePoints 
        when d.RuleName = 'Tenacity' and e.PointsFlag = 0 then b.IncentiveAmount 
       End)
,AllPoints = SUM(
Case when  e.PointsFlag = 1 then b.IncentivePoints 
        when e.PointsFlag = 0 then b.IncentiveAmount 
       End)


INTO #IncentivesFortheGroup
FROM #Reporttemplate a
       INNER JOIN MEMBEREarnedIncentives b 
              ON b.Incentivedate >= a.BeginDate and b.Incentivedate <= a.EndDate
       INNER join (vMember c inner join memberrulegroup mrg on c.memberid = mrg.memberid)
                     ON a.LOOKUPRulegroupid = mrg.LOOKUPRulegroupid
                     and b.Memberid = c.Memberid 
                     and b.IncentiveDate >= c.ProgramStartDate
       INNER JOIN LookupRule d
              On b.LOOKUPRuleID = d.LOOKUPRuleID
       INNER JOIN LookupRuleGroup e
              on d.LOOKUPRuleGroupID = e.LOOKUPRuleGroupID
Group by 
a.LookupClientid,c.memberid, a.Display
Order by memberid,display

--Select * FROM #IncentivesFortheGroup-----------------------------------------------------///////////-----------//////////
/****Put all queries together in one temp table****/

If OBJECT_ID('tempdb.dbo.#DaysStepsandIncentives') is not null          ----Aggregates the incentives earned during a period
Drop table #DaysStepsandIncentives


Select a.LookupTenantid, a.LookupClientid ,Lookuprulegroupid, ActiveMEMBERFlag, CancelledDatetime
,AgeRng = 
       Case when Datediff(Year,Birthdate,getdate()) between 18 and 30 then '18-30'
              when Datediff(Year,Birthdate,getdate()) between 31 and 50  then '31-50'
              when Datediff(Year,Birthdate,getdate()) > 50 then 'Over50'
              else 'Below18' end ,
                a.Location, a.Display, a.DaysInProgram, a.NewEnrollment, a.Gender, a.memberid
, b.AvgStepsPerLogDay, b.DaysLogged, b.MembersLogging, b.TotalSteps
,c.Frequency, c.Intensity , c.Tenacity
Into #DaysStepsandIncentives
FROM #RegisteredDays a
       Left JOin #StepsforTheGroup b
              ON a.Memberid = b.memberid 
              and a.Display = b.Display 
   Left JOIN  #IncentivesFortheGroup  c
              ON a.memberid = c.Memberid 
              and a.Display = c.display 


Create Unique Clustered Index idxMemberidDisplay on #DaysStepsandIncentives(memberid,Display)


/****Compute the eligible members********/

If OBJECT_ID('tempdb.dbo.#EligibilityTemplate') is not null          ----Aggregates the incentives earned during a period
Drop table #EligibilityTemplate


Select a.LookupTenantid
,a.Lookupclientid
,a.LookupRuleGroupid
,a.BeginDate
,a.EndDate
,a.Display
,a.Unit
,EligibleMembers = Count(b.Clientmemberid)
INTO #EligibilityTemplate
FROM #ReportTemplate   a
       Left Join Membersignupdata  b --Edit Lyle 20140814 filters Membersignup table based on rulegroup defined  
              ON a.LookupRuleGroupid = b.LookupRuleGroupid 
              and Convert(Date,b.ProgramStartDate) <= a.Enddate 			  --Edit Ghyatt changed rowcreatedDateTime to programstartdate 20150226
			  and (ActiveFlag = 1 or isnull(CancelledDateTime,Getdate()) >= a.BeginDate)    ---Edit Garrett Hyatt on 20140502   /added isnull statement on 2/26
			  and  (CancelledDateTime > b.ProgramStartDate or CancelledDateTime is null )	 --Edit GH On '20150504.
--Where b.clientmemberid  = 1125
Group by a.LookupTenantid
,a.Lookupclientid
,a.LookupRuleGroupid
,a.BeginDate
,a.EndDate
,a.Display
,a.Unit


Create Unique Clustered Index idxDisplay on #EligibilityTemplate(LookupRuleGroupid,Display)


--select * from #EligibilityTemplate where lookupRulegroupid is null

/*******************Participation, steps and Earnings Report**************************/

--drop table #temp
If OBJECT_ID ('tempdb.dbo.#StepDetails') is not null
Drop table #StepDetails
select
TeamRank_Client = dense_rank() over(partition by a.Display order by SumMetrics desc)
--,TeamColor = dense_rank() over(order by TeamName )
/*
,AgeColor     = dense_rank() over(order by AgeRng)     
,GenderColor  = dense_rank() over(order by Gender)
,SteprngColor = dense_rank() over(order by case when avgstepsperlogday < 3000                                 then 1
                                                                               when avgstepsperlogday between 3001 and 6000      then 2
                                                                               when avgstepsperlogday between 6001 and 8000      then 3
                                                                               when avgstepsperlogday between 8001 and 10000     then 4
                                                                               when avgstepsperlogday > 10000                             then 5 end
  */                                                     
,*
INTO #StepDetails

from (

       Select 
       a.LookupTenantID
       , a.Lookupclientid
       ,d.LOOKUPRuleGroupID 
       ,d.MEMBERID
       ,d.AgeRng
	   --calculation for Team and NULL values
------       ,TeamName --= d.TeamName

------	   = case when --count(distinct g.TeamName) = 0 --null column

------(SELECT count(distinct TeamName)
------from  #RegisteredDays) = 0
------      then 'AllMembers'
------	  when d.TeamName is null
------	  then 'zNoTeam'
------else d.TeamName end

       , a.Display
       ,a.BeginDate
	   ,a.EndDate
       ,daysLogged = isnull(daysLogged,0)
       ,DaysInProgram
       ,NewEnrollment
       ,d.Gender
       ,MembersLogging
       ,Frequency 
       ,Intensity 
       ,Tenacity  
       ,SumMetrics = isnull(sum( isnull(frequency,0)+isnull(intensity,0)+isnull(tenacity,0) ) over (partition by a.Display),0)
       ,totalSteps = isnull(totalSteps,0)
       ,AvgStepsPerLogDay  = isnull(AvgStepsPerLogDay,0) --avg steps per active day
       ,AvgStepsPerDay            = sum(totalSteps) / DaysInProgram --updated 12/4/13 to reflect avg steps per registered days
       , EligibleMembers    
       , registeredMembers = isnull(count(Distinct d.Memberid) ,0)
	   ,Unit
       --into #temp
       FROM #EligibilityTemplate a
              Left JOIN  #DaysStepsandIncentives d
                     On a.Display = d.display
					 and a.LOOKUPRuleGroupID = d.Lookuprulegroupid

       Group by a.LookupTenantId
       , a.Lookupclientid
       , d.LOOKUPRuleGroupID
       ,d.MEMBERID
       ,d.AgeRng
       --,d.TeamName
       , a.display 
       ,MembersLogging 
       ,totalSteps 
       ,AvgStepsPerLogDay
       ,a.BeginDate
	   ,a.EndDate  
       ,DaysLogged
       ,DaysInProgram
       ,NewEnrollment
       ,d.Gender
       ,Frequency
       ,Intensity
       ,Tenacity
       ,EligibleMembers
       ,datediff(day, a.Begindate, a.Enddate) + 1 
	   ,unit) a


--select * from #StepDetails

If OBJECT_ID ('pdb_DermReporting.dbo.ManagementReport') is not null
Drop table pdb_DermReporting.dbo.ManagementReport

select 
--TeamColorCd
TeamRank_Client
--,TeamColor
,LookupTenantID
,Lookupclientid
,LOOKUPRuleGroupID
,MEMBERID
,AgeRng
,unit
--,TeamName
,Display
,BeginDate
,EndDate
,DaysInProgram
,NewEnrollment
,Gender
,MembersLogging
,Frequency
,Intensity
,Tenacity
,SumMetrics
,totalSteps
,AvgStepsPerLogDay
,AvgStepsPerDay
,EligibleMembers
,registeredMembers
--,TeamDaysLogged = iif(SumDaysLogged = 0,0,daysLogged)
into pdb_DermReporting.dbo.ManagementReport
from  #StepDetails a 
order by Display, memberid




 --@DisplayType varchar(10) ,  = 'All'
Declare @Tenantid int = 9
,@Clientid  int = 50
,@Unit varchar(5) = 'Week'
,@RuleGroup int      = 3153 --change rulegroup for cashman trio
,@Group varchar(20) = 'Group'
,@LastxUnits int = 3




Select * 
FROM 
(
Select *, Rn = row_Number()over(Partition by Memberid Order by Display desc) FROM pdb_DermReporting.dbo.ManagementReport 
Where LookupTenantid = @Tenantid and Lookupclientid = @Clientid 
and @Unit = Unit and @Rulegroup = LookupRuleGroupid
 ) a 
 Where Rn <= @LastxUnits
