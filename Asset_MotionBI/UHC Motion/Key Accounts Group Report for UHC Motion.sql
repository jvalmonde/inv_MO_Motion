

  /*****Actively Logging users*****/
  If object_Id('tempdb.dbo.#ActiveMembers') is not null 
  Drop table #ActiveMembers
  Select de.LookupRuleGroupid , Cnt = Count(distinct De.EligibleID) 
  into #ActiveMembers FROM Dim_Eligibles de 
	Inner join  Fact_PreloadActivity fpa 
		On de.EligibleId = fpa.EligibleiD
	Inner join Dim_Date dd 
		On fpa.Dt_Sys_id = dd.Dt_Sys_Id 
		and dd.Full_Dt > dateadd(Day,-30,Getdate())
	Where de.Clientname = 'Key Accounts UHCM' and de.ActiveFlag = 1  and Fpa.TotalSteps > 299
Group by de.LookupRuleGroupid




Select RuleGroupName, PolicyID, NewBusinessEffectiveDate, PolicyEnddate = BusinessEndDate, Registered, Eligibles, RegistrationPercent = Registered*1.00/Eligibles
, ActivelyLoggingUsers = isnull(Cnt,0), PrevTwoMonths_PercentofPointsEarned = PreviousTwoMonthEarnings *1.00/PreviousTwoMonthPossibleEarnings
FROM 
(
 Select 
 lookupRuleGroupid, RuleGroupName, OfferCode as PolicyID
 ,NewBusinessEffectiveDate = Min(PeriodPolicyStartdate) over(Partition by OfferCode)
  ,BusinessEndDate = Max(PeriodPolicyEnddate) over(Partition by OfferCode)
 ,YearMonth
 ,Registered
 ,Eligibles
 ,Sum(Case when Yearmonth > dbo.Yearmonth(Dateadd(Month,-2,Getdate())) then F + I + T Else NULL END) as PreviousTwoMonthEarnings
 ,Sum(Case when Yearmonth > dbo.Yearmonth(Dateadd(Month,-2,Getdate())) then PossibleF + PossibleI + PossibleT Else NULL END) as PreviousTwoMonthPossibleEarnings
 ,Rn = Row_Number()Over(Partition by Offercode order by Yearmonth desc)
   FROM [DERMSL_Reporting].[dbo].[Motion_by_Group_by_Month]
   Where Clientname = 'Key Accounts UHCM' 
   Group by
   lookupRuleGroupid
   , RuleGroupName
   , Offercode
   ,Yearmonth
   ,Registered
   ,Eligibles
   ,PeriodPolicyStartdate
   ,PeriodPolicyEndDate
   ) a 
	Left join #ActiveMembers b 
		ON a.LookupRuleGroupid = b.LookupRuleGroupid
   Where Rn = 1 and BusinessEndDate >= Getdate()