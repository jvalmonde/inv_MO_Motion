USE [pdb_DermReporting]
GO


/****** Script for SelectTopNRows command from SSMS  ******/

/***Set up the Policy years based on the effective date from ses_prod.dbo.Customer for each rule group******/

Set Transaction Isolation Level Read uncommitted

Drop table #Ses_PolicyYear
select
			 a.LOOKUPRuleGroupID
                                                        ,a.LookupClientid
			,State
			,Zipcode
			,a.RuleGroupName
			,a.OfferCode
			,PeriodPolicyYear			= datepart(year,dateadd(year,b.number ,a.EffectiveStartDate)) 
			,PeriodPolicyNumber		= b.number + 1
			,isIntialPeriod				= case when dateadd(year,b.number ,a.EffectiveStartDate) = a.EffectiveStartDate then 1 else 0 end 
			,PolicyYearStartdate		= dateadd(year,b.number,a.EffectiveStartDate)
			,PolicyYearEnddate		= IIF(dateadd(day,-1,dateadd(year,b.number ,a.EffectiveStartDate)) > EffectiveEndDate, EffectiveEndDate, dateadd(day,-1,dateadd(year,b.number + 1,a.EffectiveStartDate)))
			,EffectiveStartDate
			,EffectiveEndDate
into #Ses_PolicyYear
	from
		(
			select distinct LC.LookupClientid, a.LOOKUPRuleGroupID,a.OfferCode, a.RuleGroupName,b.EffectiveStartDate, ld.State,ld.Zipcode,EffectiveEndDate = NULL
			 -- EffectiveEndDate = iif( EffectiveEndDate > '20500101' , NULL , EffectiveEndDate) ---Skip group effective end date, the data is corrupted, group inelligibility is based on presence of individual eligibles.
				from Dermsl_prod.dbo.LOOKUPRuleGroup a
				inner join (Ses_Prod.dbo.Customer b Left join	(	Select c.Customerid, State = Max(StateCode), Zipcode = Max(am.ZipCode)  --This subquery is for getting stat and zip of the group.
																	FROM Ses_prod.dbo.Customer c 
																	inner join ses_prod.dbo.Customeraddress  ca on c.customerid = ca.Customerid 
																	inner join ses_prod.dbo.AddressMaster am on ca.AddressMasterID = am.AddressMasterID
																	Where  c.CustomerType = 'BTB' and AddressType = 'ShipTo' 
																	Group by c.Customerid 
														        )	 ld on b.Customerid = ld.Customerid)   
									ON pdb_DermReporting.dbo.ufn_TrimLeadingZeros(a.OfferCode) = pdb_DermReporting.dbo.ufn_TrimLeadingZeros(b.GroupID)  --Lookuprulegroup has leading zeros...
			    inner join Dermsl_prod.dbo.LookupClient LC on a.LookupClientid = lc.LookupClientid and lc.Clientname in( 'All Savers Motion','Key Accounts') and b.CustomerType = 'BTB'
				
		) a
	left join Dermsl_prod.dbo.Number b on b.Number between 0 and Datediff(Year,a.EffectiveStartdate ,isnull(a.EffectiveendDate,getdate())) 
	Where dateadd(year,b.number,a.EffectiveStartDate) <= isnull(a.EffectiveendDate,getdate()) --and a.lookupclientid = 147 
	and a.lookuprulegroupid = 883 
GO




/***Create a template with all the Registered or eligible dates that a person has and fill in if the activity is not present**/
--1.  Find the points possible per day for each lookupgroup.



Drop table #PossiblePointsByDay

 Select LookupRuleGroupid
 , Date 
 ,Fpoints = Max(Fpoints) 
 ,Ipoints = Max(Ipoints)
 ,Tpoints = Max(Tpoints)
 ,Allpoints = 
 Max(Fpoints) +
 Max(Ipoints) +
 Max(Tpoints)
 into  #PossiblePointsByDay
 FROM 
 (
	 Select LookupRuleid, LRG.LookupRuleGroupid, Date = Convert(date,Dateadd(Day,Number,Startdate)), 
	 Fpoints = Max(Case when Rulename = 'Frequency' then IIF(LRG.PointsFlag = 1 , LR.IncentivePoints,LR.IncentiveAmount) else Null end)
	 ,Ipoints = Max(Case when Rulename = 'Intensity' then IIF(LRG.PointsFlag = 1 , LR.IncentivePoints,LR.IncentiveAmount) else Null end)
	 ,Tpoints = Max(Case when Rulename = 'Tenacity' then IIF(LRG.PointsFlag = 1 , LR.IncentivePoints,LR.IncentiveAmount) else Null end)
	 ,AllPoints = Max( IIF(LRG.PointsFlag = 1 , LR.IncentivePoints,LR.IncentiveAmount))
	  FROM (Dermsl_prod.dbo.LookupRule LR inner join Dermsl_prod.dbo.lookupRuleGroup LRG on Lr.LOOKUPRuleGroupID = LrG.LOOKUPRuleGroupID) 
			 Cross JOin Number 
	where number between 0 and Datediff(Day,Startdate,IIF(EndDate > Getdate(),Getdate(),EndDate))   --Creates one row for each date between Lookuprule start and end Date
	and exists(Select * FROM #Ses_PolicyYear s where lr.LOOKUPRuleGroupID = s.Lookuprulegroupid)
	Group by LookupRuleid, LRG.LookupRuleGroupid,  Dateadd(Day,Number,Startdate)

) a
Group by LookupRuleGroupid, Date
order by lookupRuleGroupId,  Date

Create unique Clustered index idxdate on #PossiblePointsByDay(Lookuprulegroupid,Date)

GO

----Select * FROM #PossiblePointsByDay



--2.  Find, for each member, the points possible for all days from programstartdate till enddate/today.
   ---To make it faster(create an itermediate table to handle null cancelleddatetimes
   Declare @Date date = Convert(Date,Dateadd(month, -3,Getdate()) ) print(@date)
   Declare @currentDate date = Convert(date, Getdate())

Drop table #MemberDate
Select msd.Clientmemberid, msd.Customerid, m.Memberid, LookupRuleGroupid, Date = Full_Dt, RegisteredDate = Case when Full_dt between isnull(m.RowCreatedDateTime,'29990101') and Coalesce(M.CancelledDateTime,msd.CancelledDatetime,getdate()) then 1 else 0 end
Into #MemberDate
FROM 
 Dermsl_Prod.dbo.Membersignupdata Msd  
	Left JOIN Dermsl_prod.dbo.Member M  on m.Clientmemberid = MSD.ClientMemberid 
	Inner Join Dim_Date dd on  dd.full_dt between msd.ProgramStartDate and  isnull(msd.CancelledDateTime,Getdate() )     ---Only works if a date dimension is available, otherwise use a number table like in the query above.
	INNER JOIN Dermsl_Prod.dbo.LookupClient LC on Msd.Lookupclientid = LC.LOOKUPClientID 
Where Full_Dt between  @Date and @currentDate
and exists ( Select * FROM #PossiblePointsByDay P  Where msd.LOOKUPRuleGroupID = p.LookupRuleGroupid and dd.Full_Dt = p.Date)

Create clustered index tempidxmem  on #memberdate(Customerid)
Create  index tempidxdate on #memberdate(Date, LookupruleGroupid)
GO
--3. Combine memberdates and total possible goals.



Drop table #MemberDatesandGoals
Select md.Memberid, md.Customerid, md.LookupRuleGroupid, md.Date, PossibleFPoints = pbd.Fpoints, PossibleIPoints = pbd.Ipoints
, PossibleTpoints = pbd.Tpoints, TotalPossiblePoints = pbd.Allpoints , RegisteredDate
INTO #MemberDatesandGoals
FROM #MemberDate md 
	Inner join #PossiblePointsByDay pbd 
		ON md.LookupRuleGroupid = pbd.lookupruleGroupid
		and md.Date = pbd.Date
Where md.Date <= Getdate()	 

Create unique Clustered index idxcl on #MemberDatesandgoals(Customerid, Date)
Create index idxmem  on #MemberDatesandGoals (Customerid)
Create index idxdate on #MemberDatesandGoals (Date)



GO





/******table of exclusions for Key Accounts***********************/

---Rules for Key accounts state that the data for the term month is excluded from Activity report and also, if the member is not part of the initial cohort of eligibles then the first month also does not count.
Drop table #Exclusions
Select x.customerid, dd.Full_dt 
into #Exclusions
FROM 
(    
		Select ka.*, de.CustomerID, de.ProgramStartDate, de.CancelledDatetime, dbo.Yearmonth(ProgramStartDate) as ExcludeMonth  --exclude all dates for member and month.
		   FROM 
				 (
			 Select LRG.LookupRuleGroupID, GroupMotionEffectiveDate = Min(EffectiveStartDate) ----This is the GroupmotionEffective Date, any person in the given group starting later than this date is a new hire.
				FROM Ses_prod.dbo.Customer ds 
				Left join (Select lrg.LookupruleGroupid, lrg.Offercode  FROM Dermsl_prod.dbo.LookupRuleGroup lrg inner join dermsl_prod.dbo.LookupClient    lc on lrg.LOOKUPClientID = lc.LookupClientid Where lc.Clientname = 'Key Accounts' ) lrg
				 on dbo.Pad(ds.GroupID,15,'0','L') = dbo.Pad(lrg.offercode,15,'0','L') and ds.CustomerType = 'BTB'
				 Group by LRG.LookupRuleGroupid
				 ) ka
				Inner join Dermsl_prod.dbo.MemberSignupdata de 
					On Ka.LookupRuleGroupid = de.LookupRuleGroupid
					and ( ProgramStartDate > GroupMotionEffectiveDate )     --if member programstart date is after the group startdate.
		
			UNION
		Select ka.*, de.Customerid, de.ProgramStartDate, de.CancelledDatetime, dbo.Yearmonth(CancelledDatetime) as ExcludeDenominatorMonth  --exclude the term month dates.
		   FROM  
				 (
			 Select LRG.LookupRuleGroupID, GroupMotionEffectiveDate = Min(EffectiveStartDate) ----This is the GroupmotionEffective Date, any person in the given group starting later than this date is a new hire.
				FROM Ses_prod.dbo.Customer ds 
				Left join (Select lrg.LookupruleGroupid, lrg.Offercode  FROM Dermsl_prod.dbo.LookupRuleGroup lrg inner join dermsl_prod.dbo.LookupClient    lc on lrg.LOOKUPClientID = lc.LookupClientid Where lc.Clientname = 'Key Accounts' ) lrg
				 on dbo.Pad(ds.GroupID,15,'0','L') = dbo.Pad(lrg.offercode,15,'0','L') and ds.CustomerType = 'BTB'
				 Group by LRG.LookupRuleGroupid
				 ) ka
				Inner join Dermsl_prod.dbo.Membersignupdata de 
					On Ka.LookupRuleGroupid = de.LookupRuleGroupid
					and (  CancelledDatetime is not null ) 
) x 
	Inner join Dim_Date dd 
		ON x.Excludemonth = dd.YEAR_MO
		and dd.full_Dt <= Getdate()
Create Clustered index idxExclude on #Exclusions(Customerid)

GO

 --4.Create final Fact activity extract.(figure out conversion) +++++++++++++++++++++

 Drop table #Activity
 		Select Mei.memberid,lr.LOOKUPRuleGroupID, IncentiveDate 
						 ,FGoalsEarned				 =  Sum(case when LR.Rulename = 'Frequency' and MEI.TotalBouts >= LR.TotalBouts then 1 else 0 end 										 )
					 ,IGoalsEarned				 =  Sum(case when LR.Rulename = 'Intensity' and MEI.totalSteps >= LR.TotalStepsMin then 1 else 0 end 										 )
					 ,TGoalsEarned				 =  Sum(case when LR.Rulename = 'Tenacity' and MEI.totalSteps >= LR.TotalStepsMin then 1 else 0 end  )
					
					 ,Fpoints        =  ISNULL(SUM(case when LR.Rulename = 'Frequency' and lrg.PointsFlag = 1 then MEI.IncentivePoints 
														when LR.Rulename = 'Frequency' and lrg.PointsFlag = 0 then MEI.IncentiveAmount end ),0)
					 ,Ipoints        =  isnull(SUM(case when LR.Rulename = 'Intensity' and lrg.PointsFlag = 1 then MEI.IncentivePoints 
														when LR.Rulename = 'Intensity' and lrg.PointsFlag = 0 then MEI.IncentiveAmount end ) ,0 )
					 ,Tpoints        =  ISNULL(SUM(case when LR.Rulename = 'Tenacity' and lrg.PointsFlag = 1 then MEI.IncentivePoints 
														when LR.Rulename = 'Tenacity' and lrg.PointsFlag = 0 then MEI.IncentiveAmount end ),0)
					 ,TotalAwards    = isnull(SUM(IIF(lrg.PointsFLag = 1 , MEI.IncentivePoints,MEI.IncentiveAmount)),0)
					 ,ActiveDays     = isnull(Sum(case when LR.Rulename = 'Tenacity' and TotalSteps >= 300 then 1 else 0 end) ,0)
					Into #Activity
						FROM 
						Dermsl_Prod.dbo.MEmberEarnedIncentives MEI 
						INNER JOIN Dermsl_Prod.dbo.LookupRule LR on MEi.LOOKUPRuleID = LR.LookupRuleId 
						Inner join Dermsl_Prod.dbo.LookupRUleGroup LRG ON LR.LookupRUleGroupid = LRG.LookupRuleGroupid
						Inner join #MemberDatesandGoals mdg on mei.memberid = mdg.memberid and mei.IncentiveDate = mdg.Date
					Where exists(Select * FROM #MemberDatesandGoals mdg where mei.memberid = mdg.memberid and mdg.Date = mei.incentivedate)
						Group by Mei.memberid,lr.LOOKUPRuleGroupID, IncentiveDate 


Create unique clustered index idxmemberdate on #Activity( Memberid, IncentiveDate)
Create nonclustered index idxRuleGroup on #Activity( LookupRuleGroupid)



 --Drop table Derm_Dw.dbo.TestActivityReport
 Select  
 PolicyYearStartdate
 ,PolicyYearEndDate
 ,YearMonth =  dbo.Yearmonth(date)
  ,LookupRuleGroupid = M.LookupRuleGroupid
  ,Eligibles = Count(Distinct m.Customerid) 
  ,Registered = Count(Distinct case when m.RegisteredDate = 1 then  m.Memberid  else null end)
 ,FGoalsEarned			= 	sum(FGoalsEarned	)						
 ,IGoalsEarned			= 	sum(IGoalsEarned	)						
 ,TGoalsEarned			= 	sum(TGoalsEarned	)
 ,FGoalsAvailable				 =  Convert(int,Sum(isnull(PossibleFPoints,1)/isnull(PossibleFPoints,1)	 ))
 ,IGoalsAvailable				 =  Convert(int,Sum(isnull(PossibleFPoints,1)/isnull(PossibleFPoints,1)	) )
 ,TGoalsAvailable				 =  Convert(int,Sum(isnull(PossibleFPoints,1)/isnull(PossibleFPoints,1)	 )) 
 ,Fpoints				= 	sum(Fpoints			)				
 ,Ipoints				= 	sum(Ipoints			)			
 ,Tpoints				= 	sum(Tpoints			)				
 ,TotalAwards			= 	sum(TotalAwards		)
  ,PossibleFPoints = Sum(m.PossibleFPoints     ) 
 ,PossibleIPoints = Sum(m.PossibleIPoints	 )
 ,PossiblTePoints = Sum(m.PossibleTpoints	 )
 ,PossiblePoints = Sum(m.TotalPossiblePoints )
 ,TotalDays = count(*)
 ,ActiveDays = sum(a.ActiveDays) 
 --into Derm_Dw.dbo.TestActivityReport
FROM #MemberDatesandGoals m
	Left JOIN #Activity a
		ON M.Memberid = a.memberid
		and m.Date = a.IncentiveDate 
		and m.LookupRuleGroupid = a.LookupRuleGroupid	 
	Left Join #Ses_PolicyYear spy on spy.LOOKUPRuleGroupID = m.LOOKUPRuleGroupID and m.Date between spy.PolicyYearStartdate and spy.PolicyYearEnddate
Where not exists(Select * FROM #Exclusions e where e.customerid = m.CustomerID and e.FULL_DT = m.Date) --and m.CustomerID = 47988
Group by
 PolicyYearStartdate
 ,PolicyYearEndDate,  dbo.Yearmonth(date),	 
M.LookupRuleGroupid
order by YearMonth
GO

Select * FROM Motion_by_Group_by_Month where lookuprulegroupid = 883 order by YearMonth
