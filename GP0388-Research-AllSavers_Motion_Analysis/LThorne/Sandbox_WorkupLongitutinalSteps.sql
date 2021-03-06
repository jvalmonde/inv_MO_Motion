use pdb_Allsavers_Research;

-- dinking around

if object_id(N'tempdb..#IncentiveBasis') is not null
   drop table #IncentiveBasis;

select MemberID, Year_Mo, IncentiveUOM, TotalStepsForMonth, NbrDayWalked, AvgDaySteps
     , ttlIncentiveEarnedForMonth   = sum(TotalIncentiveEarned)
	 , maxPossibleIncentiveForMonth = sum(maxPossibleIncentiveForMonth)
     , ttlIncentiveEarned_Frequency = max(case when IncentiveType = 'Frequency' then TotalIncentiveEarned else 0.00 end)
     , ttlIncentiveSteps_Frequency  = max(case when IncentiveType = 'Frequency' then TotalSteps else 0 end)
     , ttlIncentiveBouts_Frequency  = max(case when IncentiveType = 'Frequency' then TotalBouts else 0 end)
     , maxPossible4Month_Frequency  = max(case when IncentiveType = 'Frequency' then maxPossibleIncentiveForMonth else 0.00 end)
     , reqSteps2Earn_Frequency      = max(case when IncentiveType = 'Frequency' then RequiredToEarnIncentive_Steps else 0 end)
     , reqMinutes2Earn_Frequency    = max(case when IncentiveType = 'Frequency' then RequiredToEarnIncentive_Minutes else 0 end)
     , reqBouts2Earn_Frequency      = max(case when IncentiveType = 'Frequency' then RequiredToEarnIncentive_Bouts else 0 end)
     , ttlIncentiveEarned_Intensity = max(case when IncentiveType = 'Intensity' then TotalIncentiveEarned else 0.00 end)
     , ttlIncentiveSteps_Intensity  = max(case when IncentiveType = 'Intensity' then TotalSteps else 0 end)
     , ttlIncentiveBouts_Intensity  = max(case when IncentiveType = 'Intensity' then TotalBouts else 0 end)
     , maxPossible4Month_Intensity  = max(case when IncentiveType = 'Intensity' then maxPossibleIncentiveForMonth else 0.00 end)
     , reqSteps2Earn_Intensity      = max(case when IncentiveType = 'Intensity' then RequiredToEarnIncentive_Steps else 0 end)
     , reqMinutes2Earn_Intensity    = max(case when IncentiveType = 'Intensity' then RequiredToEarnIncentive_Minutes else 0 end)
     , reqBouts2Earn_Intensity      = max(case when IncentiveType = 'Intensity' then RequiredToEarnIncentive_Bouts else 0 end)
     , ttlIncentiveEarned_Tenacity  = max(case when IncentiveType = 'Tenacity'  then TotalIncentiveEarned else 0.00 end)
     , ttlIncentiveSteps_Tenacity   = max(case when IncentiveType = 'Tenacity'  then TotalSteps else 0 end)
     , ttlIncentiveBouts_Tenacity   = max(case when IncentiveType = 'Tenacity'  then TotalBouts else 0 end)
     , maxPossible4Month_Tenacity   = max(case when IncentiveType = 'Tenacity'  then maxPossibleIncentiveForMonth else 0.00 end)
     , reqSteps2Earn_Tenacity       = max(case when IncentiveType = 'Tenacity'  then RequiredToEarnIncentive_Steps else 0 end)
     , reqMinutes2Earn_Tenacity     = max(case when IncentiveType = 'Tenacity'  then RequiredToEarnIncentive_Minutes else 0 end)
     , reqBouts2Earn_Tenacity       = max(case when IncentiveType = 'Tenacity'  then RequiredToEarnIncentive_Bouts else 0 end)
     , DateLastGeneration = GETDATE()
  into #IncentiveBasis
  from (select distinct a.MEMBERID, a.Year_Mo, IncentiveType = r.RuleName, IncentiveUOM = i.LabelName
             , TotalStepsForMonth = ma.TotalSteps, ma.NbrDayWalked, ma.AvgDaySteps     
        	 , TotalIncentiveEarned = a.IncentiveAmount, a.TotalSteps,a.TotalBouts
        	 , maxPossibleIncentiveForMonth = ym.DaysInMonth * r.IncentiveAmount
        	 , RequiredToEarnIncentive_Steps = r.TotalStepsMin,  RequiredToEarnIncentive_Minutes = r.TotalMinutes
        	 , RequiredToEarnIncentive_Bouts = r.TotalBouts
          FROM ETL.AS_DERM_MemberEarnedIncentives a
          join ASM_YearMo                        ym on a.Year_Mo            = ym.Year_Mo
          join etl.AS_DERM_MemberAction          ma on a.MEMBERID           = ma.MEMBERID
                                                   and a.Year_Mo            = ma.Year_Mo
          join etl.AS_DERM_LookupRule             r on a.LOOKUPRuleID       = r.LOOKUPRuleID
                                                   and r.RuleName in ('Frequency','Intensity','Tenacity')
          join DERM_RuleGroup                     g on r.LOOKUPRuleGroupID  = g.LOOKUPRuleGroupID
          join ETL.AS_DERM_IncentiveLabel         i on g.LOOKUPIncentiveLabelID = i.LookupIncentiveLabelID
       ) IncentiveBasis
 group by MemberID, Year_Mo, IncentiveUOM, TotalStepsForMonth, NbrDayWalked, AvgDaySteps