use pdb_Allsavers_Research;

--Buildout of dbo.Longitudinal_Day; Step 2
--    Step 1 is ETL_DermElapsedQtrDays, which is etl step run in cloud

--    but wait, there's more: Incentives!

if object_id(N'tempdb..#IncentiveBasis') is not null
   drop table #IncentiveBasis;

select MemberID, Year_Mo, IncentiveUOM
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
  into #IncentiveBasis
  from (select distinct a.MEMBERID, a.Year_Mo, IncentiveType = r.RuleName, IncentiveUOM = i.LabelName
        	 , TotalIncentiveEarned = a.IncentiveAmount, a.TotalSteps,a.TotalBouts
        	 , maxPossibleIncentiveForMonth = ym.DaysInMonth * r.IncentiveAmount
        	 , RequiredToEarnIncentive_Steps = r.TotalStepsMin,  RequiredToEarnIncentive_Minutes = r.TotalMinutes
        	 , RequiredToEarnIncentive_Bouts = r.TotalBouts
          FROM ETL.AS_DERM_MemberEarnedIncentives a
          join ASM_YearMo                        ym on a.Year_Mo            = ym.Year_Mo
          join etl.AS_DERM_LookupRule             r on a.LOOKUPRuleID       = r.LOOKUPRuleID
                                                   and r.RuleName in ('Frequency','Intensity','Tenacity')
          join ETL.AS_DERM_RuleGroups             g on r.LOOKUPRuleGroupID  = g.LOOKUPRuleGroupID
          join ETL.AS_DERM_IncentiveLabel         i on g.LOOKUPIncentiveLabelID = i.LookupIncentiveLabelID
       ) IncentiveBasis
 group by MemberID, Year_Mo, IncentiveUOM
;
create clustered index ucix_MemberID on #IncentiveBasis (MemberID);

--TP:  select top 100 * from #IncentiveBasis order by 1;

-- Now, deal with the utilization stuff (claims, etc.)

declare @ModelVersion varchar(32) = 'Silver';     -- default to silver values

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'Longitudinal_Month')
   drop table pdb_Allsavers_Research.dbo.Longitudinal_Month;
 
select ax.Member_DIMID, ClaimYear = ym.YearMo/100
     , [Month] = 0
	 , ym.YearMo
	 , ym.Month_Name, ym.DaysInMonth, ym.Quarter_Nbr
	 -- insert the steps stuff
	 , TotalStepsForMonth = ma.TotalSteps, ma.NbrDayWalked, ma.AvgDaySteps
	 , IncentiveUOM                 = isnull(IncentiveUOM                ,'NoIncentiveEarned')
     , ttlIncentiveEarnedForMonth   = isnull(ttlIncentiveEarnedForMonth   ,0) 
	 , maxPossibleIncentiveForMonth = isnull(maxPossibleIncentiveForMonth ,0) 
     , ttlIncentiveEarned_Frequency = isnull(ttlIncentiveEarned_Frequency ,0) 
     , ttlIncentiveSteps_Frequency  = isnull(ttlIncentiveSteps_Frequency  ,0) 
     , ttlIncentiveBouts_Frequency  = isnull(ttlIncentiveBouts_Frequency  ,0) 
     , maxPossible4Month_Frequency  = isnull(maxPossible4Month_Frequency  ,0) 
     , reqSteps2Earn_Frequency      = isnull(reqSteps2Earn_Frequency      ,0) 
     , reqMinutes2Earn_Frequency    = isnull(reqMinutes2Earn_Frequency    ,0) 
     , reqBouts2Earn_Frequency      = isnull(reqBouts2Earn_Frequency      ,0) 
     , ttlIncentiveEarned_Intensity = isnull(ttlIncentiveEarned_Intensity ,0) 
     , ttlIncentiveSteps_Intensity  = isnull(ttlIncentiveSteps_Intensity  ,0) 
     , ttlIncentiveBouts_Intensity  = isnull(ttlIncentiveBouts_Intensity  ,0) 
     , maxPossible4Month_Intensity  = isnull(maxPossible4Month_Intensity  ,0) 
     , reqSteps2Earn_Intensity      = isnull(reqSteps2Earn_Intensity      ,0) 
     , reqMinutes2Earn_Intensity    = isnull(reqMinutes2Earn_Intensity    ,0) 
     , reqBouts2Earn_Intensity      = isnull(reqBouts2Earn_Intensity      ,0) 
     , ttlIncentiveEarned_Tenacity  = isnull(ttlIncentiveEarned_Tenacity  ,0) 
     , ttlIncentiveSteps_Tenacity   = isnull(ttlIncentiveSteps_Tenacity   ,0) 
     , ttlIncentiveBouts_Tenacity   = isnull(ttlIncentiveBouts_Tenacity   ,0) 
     , maxPossible4Month_Tenacity   = isnull(maxPossible4Month_Tenacity   ,0) 
     , reqSteps2Earn_Tenacity       = isnull(reqSteps2Earn_Tenacity       ,0) 
     , reqMinutes2Earn_Tenacity     = isnull(reqMinutes2Earn_Tenacity     ,0) 
     , reqBouts2Earn_Tenacity       = isnull(reqBouts2Earn_Tenacity       ,0) 
	 -- insert the claims utilization stuff
	 , RAF                = cast(ra.TotalScore as decimal(7,3))
     , RX_AllwAmt         = cast(0.0 as decimal(11,2))
     , RX_PaidAmt         = cast(0.0 as decimal(11,2))
     , IP_AllwAmt         = cast(0.0 as decimal(11,2))
     , IP_PaidAmt         = cast(0.0 as decimal(11,2))
     , OP_AllwAmt         = cast(0.0 as decimal(11,2))
     , OP_PaidAmt         = cast(0.0 as decimal(11,2))
     , ER_AllwAmt         = cast(0.0 as decimal(11,2))
     , ER_PaidAmt         = cast(0.0 as decimal(11,2))
     , MD_AllwAmt         = cast(0.0 as decimal(11,2))
     , MD_PaidAmt         = cast(0.0 as decimal(11,2))
     , OtherAllwAmt       = cast(0.0 as decimal(11,2))
     , OtherPaidAmt       = cast(0.0 as decimal(11,2))
     , PaidAmt            = cast(0.0 as decimal(11,2))
     , AllwAmt            = cast(0.0 as decimal(11,2))
	 , IP_Visits          = 0
	 , IP_Days            = 0
	 , OP_Visits          = 0
	 , MD_Visits          = 0
	 , ER_Visits          = 0
     , DateLastGeneration = GETDATE()
  into Longitudinal_Month
  from etl.AS_DERM_MemberAction          ma
  join ASM_YearMo                        ym on ma.Year_Mo        = ym.Year_Mo
  join etl.AS_DERM_Members      (nolock) dm on ma.Memberid       = dm.MEMBERID   -- Memberid
  join etl.DERM_xwalk_Member    (nolock) dx on dm.ClientMEMBERID = dx.dSystemID  -- xwalk to
  join ASM_xwalk_Member         (nolock) ax on dx.aSystemid      = ax.SystemID   -- DIMID
  join RA_Com_I_MetalScores_RAF          ra on ax.Member_DIMID   = left(ra.UniqueMemberID,32)
                                           and ym.YearMo/100     = cast(right(ra.UniqueMemberID,4) as int)
								           and ra.ModelVersion   = @ModelVersion
  left join #IncentiveBasis              ib on ma.MEMBERID       = ib.MEMBERID
                                           and ma.Year_Mo        = ib.Year_Mo
 order by 1,2
;

create clustered index ucix_DIMID on pdb_Allsavers_Research..Longitudinal_Month (Member_DIMID);

----- Update the claims data with yet another clone from claimsdetailyy
----- Each version of this is slightly different, so, be mindful of what you change

if object_id(N'tempdb..#CLMMembers') is not null
   drop table #CLMMembers;

select distinct --top 100
       lm.Member_DIMID, lm.YearMo, EffDtSysID = d1.DtSysId, EndDtSysID = d2.DtSysId
     , xm.SystemID
  into #CLMMembers
  from Longitudinal_Month       lm
  join ASM_xwalk_Member         xm on lm.Member_DIMID = xm.Member_DIMID
  join ASM_YearMo               ym on lm.YearMo       = ym.YearMo
  join AllSavers_Prod..Dim_Date d1 on lm.YearMo = d1.YearMo and d1.DayNbr =  1
  join AllSavers_Prod..Dim_Date d2 on lm.YearMo = d2.YearMo and d2.DayNbr = ym.DaysInMonth
;

create clustered index ucix_SystemID on #CLMMembers (SystemID);
create           index ucix_DIMID    on #CLMMembers (Member_DIMID);

--TP: select top 100 * from #CLMMembers  

update lm
   set RX_AllwAmt   = clm.RX_AllwAmt, RX_PaidAmt     = clm.RX_PaidAmt  
     , IP_AllwAmt   = clm.IP_AllwAmt, IP_PaidAmt     = clm.IP_PaidAmt 
     , OP_AllwAmt   = clm.OP_AllwAmt, OP_PaidAmt     = clm.OP_PaidAmt
	 , ER_AllwAmt   = clm.ER_AllwAmt, ER_PaidAmt     = clm.ER_PaidAmt
     , MD_AllwAmt   = clm.MD_AllwAmt, MD_PaidAmt     = clm.MD_PaidAmt
     , OtherAllwAmt = clm.OtherAllwAmt, OtherPaidAmt = clm.OtherPaidAmt
     , PaidAmt      = clm.PaidAmt, AllwAmt           = clm.AllwAmt
	 , IP_Visits    = clm.IP_Visits, IP_Days         = clm.IP_Days
	 , OP_Visits    = clm.OP_Visits
	 , MD_Visits    = clm.MD_Visits
	 , ER_Visits    = clm.ER_Visits
  from Longitudinal_Month lm
  join (
SELECT cg.Member_DIMID, cg.YearMo
     , RX_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Pharmacy'   then AllwAmt else 0 end)
     , RX_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Pharmacy'   then PaidAmt else 0 end)
     , IP_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then AllwAmt else 0 end)
     , IP_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then PaidAmt else 0 end)
     , OP_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService <> '23'         then AllwAmt else 0 end
								 else 0 end)
     , OP_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService <> '23'         then PaidAmt else 0 end
								 else 0 end)
     , ER_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient'
	                             then case when PlaceOfService = '23'          then AllwAmt else 0 end
								 else 0 end)
     , ER_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                             then case when PlaceOfService = '23'          then PaidAmt else 0 end
					             else 0 end)
     , MD_AllwAmt     = Sum(Case when st.ServiceTypeDescription = 'Physician'  then AllwAmt else 0 end)
     , MD_PaidAmt     = Sum(Case when st.ServiceTypeDescription = 'Physician'  then PaidAmt else 0 end)
     , OtherAllwAmt        = Sum(Case when st.ServiceTypeDescription Not in ('Pharmacy','Inpatient','Outpatient','Physician') then AllwAmt else 0 end )
     , OtherPaidAmt        = Sum(Case when st.ServiceTypeDescription Not in ('Pharmacy','Inpatient','Outpatient','Physician') then PaidAmt else 0 end)
     , PaidAmt             = SUM(isnull(fc.PaidAmt,0))
     , AllwAmt             = SUM(isnull(fc.AllwAmt,0))
     , IP_Visits           = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then AdmitCnt else 0 end)
     , IP_Days             = Sum(Case when st.ServiceTypeDescription = 'Inpatient'  then DayCnt  else 0 end)
     , OP_Visits           = Sum(Case when st.ServiceTypeDescription = 'Outpatient' then VisitCnt else 0 end)
     , MD_Visits           = Sum(Case when st.ServiceTypeDescription = 'Physician'  then VisitCnt else 0 end)
     , ER_Visits           = Sum(Case when st.ServiceTypeDescription = 'Outpatient' 
	                                  then case when PlaceOfService = '23' then VisitCnt else 0 end
									  else 0 end)
  FROM #CLMMembers                                     cg
  JOIN allsavers_Prod.dbo.Fact_Claims         (nolock) fc on cg.SystemID = fc.SystemID
                                                         and fc.FromDtSysID between cg.EffDtSysID and cg.EndDtSysID
  join  allsavers_prod.dbo.Dim_ServiceType    (nolock) st on fc.ServiceTypeSysID = st.ServiceTypeSysID
 Group by cg.Member_DIMID, cg.YearMo
       ) clm on lm.Member_DIMID = clm.Member_DIMID and lm.YearMo = clm.YearMo
;

