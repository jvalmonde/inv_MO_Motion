use DermSL_Prod;

-- This script is a hodge-poge of small ETL imports in the .dtsx package.
-- there is one section of the package that pulls back a bunch of DERM data
-- reformulated, and these are the extract scripts to that effort.
-- Note the prettiest of code - ugly ducklings B4 swans.

-- musta used an import step with this to create ETL.AS_DERM_Members

SELECT *
  FROM MEMBER
 where LOOKUPClientID = 50 and ClientMEMBERID <> ''
   and LastName <> 'Admin'
   and len(ClientMemberID) >= 17
;

-- part of package to pull rule groups to ETL.AS_DERM_RuleGroups

Select *
     , StartYearmo = pdb_DermReporting.dbo.Yearmonth(GroupStartDatetime)
	 , EndYearmo   = pdb_DermReporting.dbo.Yearmonth(isnull(GroupEndDateTime,getdate()))
	 , policyid    = replace(offercode,'-','00') 
  FROM DERMSL_Prod..LookupRuleGroup
 Where lookupClientid = 50                   -- this is All Savers Motion ClientID for motion
   and lookupRulegroupid not in (92,880,881) -- R/O AS Admin and (2) test groups
;

-- pull enrollment to etl.AS_DERM_MemberEnrollment

use DermSL_Prod;

with mbrBasis as (
SELECT distinct Memberid FROM MEMBER (nolock)
 where lookupclientID = 50 and ClientMEMBERID <> '' and LastName <> 'Admin' and len(ClientMemberID) >= 17
)

SELECT me.*
  FROM mbrBasis          mb
  join Member_Enrollment me on mb.MEMBERID = me.Memberid
;

--  MemberAction (ttlSteps for MM period)

use DERMSL_Prod;

with mbrBasis as (
SELECT distinct Memberid FROM MEMBER (nolock)
 where lookupclientID = 50 and ClientMEMBERID <> '' and LastName <> 'Admin' and len(ClientMemberID) >= 17
)

SELECT ma.MEMBERID, dt.Year_Mo
     , NbrDayWalked = count(ma.QueryDate)
	 , AvgDaySteps  = avg(ma.TotalSteps)
--	 , NbrManualAwardFlag        = sum(case when ma.ManualAwardFlag        = 1 then 1 else 0 end)
     , TotalSteps                = sum(ma.TotalSteps)
  FROM mbrBasis     mb
  join MEMBERAction ma on mb.MEMBERID = ma.Memberid
  join pdb_DermReporting..dim_Date dt on ma.QueryDate = dt.Full_Dt
 group by ma.MEMBERID, dt.Year_Mo
 order by 1,2
;

--  MemberIncentives for MM period

use DERMSL_Prod;

with mbrBasis as (
SELECT distinct Memberid FROM MEMBER (nolock)
 where lookupclientID = 50 and ClientMEMBERID <> '' and LastName <> 'Admin' and len(ClientMemberID) >= 17
)

SELECT mi.MEMBERID, dt.Year_Mo, mi.LOOKUPRuleID
     , IncentiveAmount = sum(mi.IncentiveAmount)
	 , IncentivePoints = sum(mi.IncentivePoints)
     , TotalSteps      = sum(mi.TotalSteps)
	 , TotalBouts      = sum(mi.TotalBouts)
  FROM mbrBasis                             mb
  join MEMBEREarnedIncentives      (nolock) mi on mb.MEMBERID = mi.Memberid
  join pdb_DermReporting..dim_Date (nolock) dt on mi.IncentiveDate = dt.Full_Dt
 group by mi.MEMBERID, dt.Year_Mo, mi.LOOKUPRuleID
having sum(mi.IncentiveAmount) <> 0.00 
   and sum(mi.IncentivePoints)+sum(mi.TotalSteps)+sum(mi.TotalBouts) <> 0
 order by 1,2
;

-- And the rules by which the goose is awarded grain for good behavior

use DERMSL_Prod;

with ruleBasis as (
SELECT distinct mi.LookupRuleID
  FROM MEMBER (nolock)                  m
  join MEMBEREarnedIncentives (nolock) mi on m.MEMBERID = mi.Memberid
 where m.lookupclientID = 50 and m.ClientMEMBERID <> ''
   and m.LastName <> 'Admin' and len(m.ClientMemberID) >= 17
)

SELECT lr.LOOKUPRuleID, lr.LOOKUPRuleGroupID, lr.RuleName, lr.RuleDescription
     , lr.ActiveFlag, lr.RuleGroupID, lr.TotalStepsMin, lr.TotalStepsMax, lr.TotalMinutes
     , lr.IncentiveAmount, lr.IncentivePoints, lr.TotalBouts
  FROM ruleBasis           rb
  join LookupRule (nolock) lr on rb.LookupRuleID = lr.LookupRuleID
                             and Rulegroupid not in (92,880,881) -- R/O AS Admin and (2) test groups
order by 2,1
;

-- and the incentive labels

USE [DERMSL_Prod]

SELECT [LOOKUPIncentiveLabelID]
      ,[LabelName]
      ,[LabelAlias]
  FROM [dbo].[LOOKUPIncentiveLabel]
;


