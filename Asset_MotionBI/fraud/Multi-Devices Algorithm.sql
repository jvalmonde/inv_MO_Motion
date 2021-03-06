USE [pdb_DermFraud]
GO
/****** Object:  StoredProcedure [dbo].[dselectFraud_I_SamePocket_v2]    Script Date: 10/21/2016 11:10:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Garrett Hyatt
-- Create date: 20160913
-- Description:
-- =============================================
ALTER PROCEDURE [dbo].[dselectFraud_I_SamePocket_v2]
AS
BEGIN

	SET NOCOUNT ON;



/*****Prepare a table into which to pull all the steps for newly logged dates or for dates wherein the total steps have changed since we last ran the process***/
IF object_id('tempdb.dbo.#steps') is not null 
Drop  table #Steps	

Select a.Memberid,a.Logdate, a.MinuteofthedayIndex, a.LogValue, mrg.LOOKUPRuleGroupID, MinutesForP1 =Count(*) over(Partition by a.Memberid, a.Logdate), pc.Steps
into  #Steps
FROM  [pdb_DermFraud].[dbo].StepsbyMinuteIndex_ETL a  
inner join Dermsl_Prod.dbo.Member m on a.memberid = m.Memberid 
inner join Dermsl_Prod.dbo.MemberRuleGroup mrg on m.Memberid = mrg.memberid
Inner join pdb_DermFraud.dbo.Process_ThreeHundredStepDays_ETL pc on a.Memberid = pc.Memberid and a.Logdate = pc.Logdate and Steps >= 6000


--Create Clustered index idxmemberdate on #Steps(Minuteofthedayindex)
--Create index idxmember on #Steps(Memberid) include (Steps)
--Create index idxLookupRuleGroup on #Steps(LookupRuleGroupid)
/********Pull pairs where the step difference is less than 5%************/

If object_id('tempdb.dbo.#Pairs') is not null 
Drop table #Pairs

Select Distinct P1 = a.Memberid, a.Logdate, P2 = b.Memberid, StepsDiff = ((a.steps - b.steps)*1.00 /a.steps)
Into #Pairs
FROM (pdb_DermFraud.dbo.Process_ThreeHundredStepDays_ETL a inner join Dermsl_PRod.dbo.MemberRuleGroup mrg1 on a.memberid = mrg1.memberid)
	Inner join (pdb_DermFraud.dbo.Process_ThreeHundredStepDays_ETL b inner join Dermsl_prod.dbo.MemberRuleGroup mrg2 on b.memberid = mrg2.memberid)
		ON a.Memberid <> b.Memberid 
		and mrg1.LookupRulegroupid = mrg2.LookupRuleGroupid 
		and a.LogDate = b.Logdate
		and ((a.steps - b.steps)*1.00 /a.steps) between -.05 and .05


/*****filter days prior to running query to days that have at least 6000 steps, then filter this query for Steps walked the same at least 30% f Minutes where both walked****/
/****Need to update the insert to be a merge statement***************/

If object_Id('tempdb.dbo.#MetricI_temp') is not null 
Drop table #MetricI_temp

Select * 
,PercentofDayTheSame = (MinutesinaDay - MaxNotWalkingTogether) *1.00/1440
Into #MetricI_temp
FROM 
(
		
		Select LookupRulegroupid,
		P1, MinutesforP1,MinutesforP2
		,MinutesWhereBothWalked = Count(*)                                 ---Join condition makes one row for each minute that both members took steps.
		,MinutesinaDay = 1440,
		MaxNotWalkingTogether = ((MinutesForP1 - Count(*) )	+ (MinutesForP2 - Count(*) ))  ---- The difference of each person's total minutes walked less the minutes where they walked at the same time.
									+(Count(*) - sum(IIF(ABS((P1steps - P2Steps)*1.00/P1Steps) *1.0<= .15,1,0)*1.00)) ---Add the total minutes where the members walked at the same time but subtract out the minutes where the minute totals were > 15% different. 
		, P2, Logdate
		, StepsWalkedSame = sum(IIF(ABS((P1steps - P2Steps)*1.00/P1Steps) *1.0<= .15,1,0)*1.00)   ----Calculates the number of minutes in a day where steps > 0 and the two members' step minute totals were within 15% of each others. 
	
		
		FROM
		(      /*********Pull the information for the person and the persons that they are matched to, along with step details for each minute***/
			 Select a.LookupRuleGroupid, P1 = a.Memberid,P2 = b.Memberid, a.Logdate												---Member comparison data
			 , a.MinuteofthedayIndex, P1Steps = a.Logvalue, P2Steps = b.Logvalue, a.MinutesForP1, MinutesforP2 = b.MinutesForP1 ---Steps broken down by minute
					, P1TotSteps = a.Steps, P2TotSteps = b.Steps																---Total Steps over the whole day.
		  FROM #Steps a
			Left join #Steps  b on a.Logdate = b.Logdate 
			and a.MinuteofthedayIndex = b.MinuteofthedayIndex /****For each person in the steps table, match up to all the other members' steps at the date and minute level.******/
			and a.Memberid <> b.Memberid																						---Don't compare the person to themself(gender neutral cuz I'm not Trump).
			and a.LookupruleGroupid = b.LOOKUPRuleGroupID
		  ) a
		  --Where P1 = 32060
		 --Where (P1TotSteps - P2TotSteps) *1.00/P1TotSteps between -.05 and .05											----Only calculate for members with total steps of the day within 5% of each other.  
		  Where exists(Select * FROM #Pairs p where p.P1 = a.P1 and p.P2 = a.P2 and a.Logdate =p.LogDate	)	
		Group by a.LookupRuleGroupid,P1,MinutesforP1,MinutesforP2, P2, Logdate
) a
Where (MinutesinaDay - MaxNotWalkingTogether) *1.00/1440  > .92 and StepsWalkedSame*1.00 / MinutesFOrP1 > .30					 ---filter for days where the two people had 92% of minutes in a day that were within 15% the same AND where 30% of the minutes walked by person 1 closely matched person 2.
and MinutesforP1 >= 30																											 ---The 6,000 step limit should make this filter redundant , but I added this here anyway, so that people that are inactive almost all day don't get flagged.
--and Not exists(Select * FROM MetricI_Dev b where a.P1 = b.P1 and a.Logdate = b.Logdate)											 ---table is cumulative, dont add in a record that already exists.(no longer cumulative as of 10/20...
order by Logdate, PercentofDayTheSame


/***************************Update the metricI_Dev table that calculates the scores by date.*******************************************************/


merge into MetricI_Dev as tgt 
	Using #MetricI_temp as src 
		on tgt.p1 = src.p1 
		and tgt.p2 = src.p2
		and tgt.Logdate = src.Logdate 
When matched then update set 
       tgt.[LookupRulegroupid]		 = src.[LookupRulegroupid]		
      ,tgt.[P1]						 = src.[P1]						
      ,tgt.[MinutesforP1]			 = src.[MinutesforP1]			
      ,tgt.[MinutesforP2]			 = src.[MinutesforP2]			
      ,tgt.[MinutesWhereBothWalked]	 = src.[MinutesWhereBothWalked]	
      ,tgt.[MinutesinaDay]			 = src.[MinutesinaDay]			
      ,tgt.[MaxNotWalkingTogether]	 = src.[MaxNotWalkingTogether]	
      ,tgt.[P2]						 = src.[P2]						
      ,tgt.[Logdate]				 = src.[Logdate]				
      ,tgt.[StepsWalkedSame]		 = src.[StepsWalkedSame]		
      ,tgt.[PercentofDayTheSame]	 = src.[PercentofDayTheSame]	
when not matched then insert 
(
 [LookupRulegroupid]		
,[P1]						
,[MinutesforP1]			
,[MinutesforP2]			
,[MinutesWhereBothWalked]	
,[MinutesinaDay]			
,[MaxNotWalkingTogether]	
,[P2]						
,[Logdate]				
,[StepsWalkedSame]		
,[PercentofDayTheSame]	
)
Values(src.[LookupRulegroupid]		
,[P1]						
,[MinutesforP1]			
,[MinutesforP2]			
,[MinutesWhereBothWalked]	
,[MinutesinaDay]			
,[MaxNotWalkingTogether]	
,[P2]						
,[Logdate]				
,[StepsWalkedSame]		
,[PercentofDayTheSame]	
) ;



/*****Update/Insert the table that will generate updates in prod for email distribution  --****/
If object_ID('tempdb.dbo.#FraudMetricI_SamePocket' ) is not null 
Drop table #FraudMetricI_SamePocket
Select * 
,Score = Case when Row_Number()Over(Partition by P1,P2, Grouper order by date) > 9 then 5 
			  when Row_Number()Over(Partition by P1,P2, Grouper order by date) > 3 then 5 
else Row_Number()Over(Partition by P1,P2, Grouper order by date) end   ----if more than three days in a row are flagged, then send email.  More testing to determine tier 2 level emails.
Into #FraudMetricI_SamePocket
FROM 
(
		Select Distinct
		m.LookupClientid
		,a.LookupRuleGroupid
		,LRG.RuleGroupName
		,a.P1,
		 a.P2,
		 P1Name = m.Firstname + ' ' + M.lastname,
		 P2Name = m2.firstname  + ' ' + M2.Lastname,
		 a.Logdate as Date
		 ,Grouper = (Row_Number()over(Partition By a.P1,a.P2 order by a.LogDate) + Row_Number()over(Partition By a.P1,a.P2  order by a.LogDate Desc)) - 1   ---use this function to identify consecutive days of suspicious dates.
		,NewData = case when pt.memberid is not null then 1 else 0 end 
		FROM MetricI_Dev a 
			Inner join Dermsl_prod.dbo.Member m on a.P1 = m.Memberid 
			Inner join dermsl_prod.dbo.Member m2 on a.P2 = m2.memberid
			Inner Join Dermsl_prod.dbo.LookupRuleGroup lrg on a.LookupRulegroupid = lrg.LookupruleGroupid 
			Left Join  pdb_DermFraud.dbo.Process_ThreeHundredStepDays_ETL pt on a.p1 = pt.Memberid and pt.logdate = a.Logdate 
) a 
			order by P1Name, P2Name,Date

Create unique Clustered index idxmemberdate on #FraudMetricI_SamePocket(P1,P2,Date)    ---use unique index to avoid dupes.

/****Update the scores in the final table or add new rows if needed.*******/

merge into FraudMetricI_SamePocket as tgt 
	Using #FraudMetricI_SamePocket as src 
		on  tgt.p1 = src.p1 
		and tgt.p2 = src.p2
		and tgt.date = src.date 
When matched and tgt.Score <> src.Score then update set 
       tgt.[LookupClientid]   = src.[LookupClientid]   
      ,tgt.[LookupRuleGroupid]= src.[LookupRuleGroupid]
      ,tgt.[RuleGroupName]	  = src.[RuleGroupName]	  
      ,tgt.[P1]				  = src.[P1]				  
      ,tgt.[P2]				  = src.[P2]				  
      ,tgt.[P1Name]			  = src.[P1Name]			  
      ,tgt.[P2Name]			  = src.[P2Name]			  
      ,tgt.[Date]			  = src.[Date]			  
      ,tgt.[Grouper]		  = src.[Grouper]		  
      ,tgt.[NewData]		  = 1		  
      ,tgt.[Score]			  = src.[Score]			  
when not matched then insert 
(
[LookupClientid]   
,[LookupRuleGroupid]
,[RuleGroupName]	  
,[P1]				  
,[P2]				  
,[P1Name]			  
,[P2Name]			  
,[Date]			  
,[Grouper]		  
,[NewData]		  
,[Score]			  
)
Values(
[LookupClientid]   
,[LookupRuleGroupid]
,[RuleGroupName]	  
,[P1]				  
,[P2]				  
,[P1Name]			  
,[P2Name]			  
,[Date]			  
,[Grouper]		  
,[NewData]		  
,[Score]			  
) ;


------Select RuleGroupName, Count(*) FROM FraudMetricI_SamePocket Where Grouper >= 3  Group by RuleGroupName order by 2

--------Select * FROM FraudMetricI_SamePocket order by Date where P1Name = 'Garrett Hyatt'  = 'Rhino'

------Select * FROM Dermsl_Prod.dbo.LookupRulegroup where RuleGroupname like '%Rhino%'

--------Select * FROM pdb_DermFraud.dbo.StepsbyMinuteIndex Where Memberid = 6014 and logdate = '20160920'


END
