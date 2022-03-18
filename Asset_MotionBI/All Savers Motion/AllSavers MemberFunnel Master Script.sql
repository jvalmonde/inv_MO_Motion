/*********************************************************************************************

THIS IS THE MASTER SCRIPT FOR POPULATING THE ALL SAVERS MEMBER FUNNEL REPORT.
THIS IS A COMPILATION OF STORED PROCEDURES STORED IN DIFFERENT SERVERS AND DATABASES.
	- DEVSQL10.pdb_ABW
	- DEVSQL14.pdb_DermReporting

*********************************************************************************************/

/***** STORED PROC [dbo].[DSelect_AllSaversInsured] *****/
-- DEVSQL10
-- ALLSAVERS_PROD

--Actual/New/Established LivesCovered
IF object_ID('tempdb.dbo.#temp1') is not null
Drop table #temp1
Select YearMo
	, ActualLivesCovered		=	Count(*)
	, NewLivesCovered			=	SUM(Case When OID <= 3 Then 1 Else 0 End)
	, EstablishedLivesCovered	=	SUM(Case When OID > 3 Then 1 Else 0 End)
  Into #temp1
From
(
SELECT *
	, OID	=	ROW_NUMBER() over(partition by MEMBERID order by YearMo)
  FROM [AllSavers_Prod].[dbo].[Dim_MemberDetail]
  where MemberID > 0 and InsuredFlag = 1
	and YearMo between 201404 and 201602
)	a
Group By YearMo
Order By YearMo

--- CycleTerms/OffCycleTerms
IF object_ID('tempdb.dbo.#temp2') is not null
Drop table #temp2
select YearMo
	, CycleTerms	=	SUM(Case When modulo = 0 and leadyearmo is null Then 1 Else 0 End)
	, OffCycleTerms	=	SUM(Case When modulo > 0 and leadyearmo is null Then 1 Else 0 End)
  Into #temp2
From
(
SELECT MEMBERID
      ,a.[YearMo]
	  ,b.PolicyMonth
	  ,PolicyMonth % 12 as modulo
	  , lead(a.YearMo, 1, NULL) Over(Partition By MEMBERID Order By a.YearMo) as leadyearmo
  FROM [AllSavers_Prod].[dbo].[Dim_MemberDetail]	a
	Join DEVSQL10.[AllSavers_Prod].[dbo].[Dim_Policy]		b	on	a.PolicyID	=	b.PolicyID
															and a.YearMo	=	b.YearMo
  where a.YearMo between 201404 and 201602
	--and MemberID = 6476
)	a
Where (modulo = 0
	or leadyearmo is null)
	and YearMo <= 201602
Group By YearMo
Order By YearMo

--- GroupsRenewed/UpforRenewal/RenewalRate
IF object_ID('tempdb.dbo.#temp3') is not null
Drop table #temp3
select YearMo
	, GroupsRenewed			=	SUM(Case When modulo = 0 and leadyearmo is not null Then 1 Else 0 End)
	, GroupsUpforRenewal	=	SUM(Case When modulo = 0 and leadyearmo is not null Then 1 Else 0 End) + SUM(Case When modulo = 0 and leadyearmo is null Then 1 Else 0 End)
	, RenewalRate			=	SUM(Case When modulo = 0 and leadyearmo is not null Then 1 Else 0 End) * 1.0 / (SUM(Case When modulo = 0 and leadyearmo is not null Then 1 Else 0 End) + SUM(Case When modulo = 0 and leadyearmo is null Then 1 Else 0 End))
  Into #temp3
From
(
SELECT [PolicyID]
      ,[YearMo]
	  ,PolicyMonth
	  ,PolicyMonth % 12 as modulo
	  , lead(YearMo, 1, NULL) Over(Partition By PolicyID Order By YearMo) as leadyearmo
  FROM [AllSavers_Prod].[dbo].[Dim_Policy]
  where YearMo between 201404 and 201602
)	a
Where (modulo = 0
	or leadyearmo is null)
	and YearMo <= 201602
Group By YearMo
Order By YearMo


/*Final Table for Insured*/
IF object_ID('pdb_ABW.dbo.AllSavers_Insured') is not null
Drop table pdb_ABW.dbo.AllSavers_Insured
Select a.*
	, b.CycleTerms, b.OffCycleTerms
	, c.GroupsRenewed, c.GroupsUpforRenewal, c.RenewalRate
  Into pdb_ABW.dbo.AllSavers_Insured
From #temp1	a
	Join #temp2	b	On	a.YearMo	=	b.YearMo
	Join #temp3	c	On	a.YearMo	=	c.YearMo
Order By a.Yearmo


/***** AFTER EXECUTING ABOVE QUERY, TRANSFER FINAL TABLE TO DEVSQL14.pdb_DermReporting *****/

/*********************************************************************************************************************/

/***** STORED PROC [dbo].[DSelect_AllSaversMotion] *****/

-- DEVSQL14
--Use pdb_DermReporting
--Go

--- TotalMotionEligibles and TotalMembers
If Object_Id('tempdb..#t1') is not null 
DROP TABLE #t1
Select YearMonth
	, TotalMotionEligibles	=	SUM(Eligibles)
	, TotalMembers			=	SUM(Registered)
  Into #t1
FROM [pdb_DermReporting].[dbo].[Motion_by_Group_by_Month]
Where clientname = 'All Savers Motion'
	and YearMonth between 201404 and 201603
Group By YearMonth
Order By YearMonth

--- NewEligibles, Cancellations, NewRegistrants
If Object_Id('tempdb..#t2') is not null 
DROP TABLE #t2
Select ne.*
	, Cancellations		=	ISNULL(Cancellations, 0)
	, NewRegistrants	=	ISNULL(NewRegistrants, 0)
  Into #t2
From	(
		Select YearMonth	=	dbo.YearMonth(ProgramStartDate)
			, NewEligibles	=	COUNT(DISTINCT EligibleID)
		From [pdb_DermReporting].[dbo].Dim_Eligibles	a
		Where clientname = 'All Savers Motion'
			and isnull(CancelledDatetime,'20990101') > ProgramStartdate
			and exists (Select * From [pdb_DermReporting].[dbo].Dim_SESAllsaversPolicyYear	b Where a.LOOKUPRuleGroupID = b.LOOKUPRuleGroupID and dbo.YearMonth(a.ProgramStartDate) between dbo.YearMonth(b.PeriodPolicyStartDate) and dbo.YearMonth(b.PeriodPolicyEndDate))
		Group By dbo.YearMonth(ProgramStartDate)
		)	ne
Left Join	(
			Select YearMonth	=	dbo.YearMonth(CancelledDatetime)
				, Cancellations	=	COUNT(DISTINCT EligibleID)
			From [pdb_DermReporting].[dbo].Dim_Eligibles	a
			Where clientname = 'All Savers Motion'
				and isnull(CancelledDatetime,'20990101') > ProgramStartdate
				and exists (Select * From [pdb_DermReporting].[dbo].Dim_SESAllsaversPolicyYear	b Where a.LOOKUPRuleGroupID	=	b.LOOKUPRuleGroupID and dbo.YearMonth(a.CancelledDatetime) between dbo.YearMonth(b.PeriodPolicyStartDate) and dbo.YearMonth(b.PeriodPolicyEndDate))
				and CancelledDatetime Is Not Null
			Group By dbo.YearMonth(CancelledDatetime)
			)	c	On	ne.YearMonth	=	c.YearMonth
Left Join	(
			Select YearMonth		=	dbo.YearMonth(AccountVerifiedDateTime)
				, NewRegistrants	=	COUNT(DISTINCT EligibleID)
			From [pdb_DermReporting].[dbo].Dim_Eligibles	a
			Where clientname = 'All Savers Motion'
				and isnull(CancelledDatetime,'20990101') > ProgramStartdate
				and exists (Select * From [pdb_DermReporting].[dbo].Dim_SESAllsaversPolicyYear	b Where a.LOOKUPRuleGroupID	=	b.LOOKUPRuleGroupID and dbo.YearMonth(a.AccountVerifiedDateTime) between dbo.YearMonth(b.PeriodPolicyStartDate) and dbo.YearMonth(b.PeriodPolicyEndDate))
				and AccountVerifiedDateTime Is Not Null
			Group By dbo.YearMonth(AccountVerifiedDateTime)
			)	nr	On	ne.YearMonth	=	nr.YearMonth
Order By ne.YearMonth


--- Logging
If Object_Id('tempdb..#t3') is not null 
DROP TABLE #t3
Select YEAR_MO
	, Logging	=	SUM(Case When Status = 3 Then 1 ELse 0 End)
  Into #t3
From
(
	Select a.Account_ID
		, c.YEAR_MO
		, Status	=	MAX(Case	When TotalSteps >= 300 Then 3
									When ActiveFlag = 1 Then 2
									ELse 0
							End)
	From [pdb_DermReporting].[dbo].Dim_Eligibles	a
	Join [pdb_DermReporting].[dbo].Fact_Activity	b	On	a.Account_ID	=	b.Account_ID
	Join [pdb_DermReporting].[dbo].Dim_Date			c	On	b.DT_SYS_ID		=	c.Dt_Sys_ID
	Group By a.Account_ID, YEAR_MO
)	sub
Group By Year_MO
Order By Year_MO

--- FIT Compliance
If Object_Id('tempdb..#t4') is not null 
DROP TABLE #t4
Select c.Year_mo
	, FCompliance	=	SUM(F) * 1.0/ Count(*)
	, ICompliance	=	SUM(I) * 1.0/ Count(*)
	, TCompliance	=	SUM(T) * 1.0/ Count(*)
  Into #t4
From [pdb_DermReporting].[dbo].Dim_Eligibles	a
Join [pdb_DermReporting].[dbo].Fact_Activity	b	On	a.Account_ID	=	b.Account_ID
Join [pdb_DermReporting].[dbo].Dim_Date			c	On	b.DT_SYS_ID		=	c.Dt_Sys_ID
Where clientname = 'All Savers Motion'
Group By c.YEAR_MO
Order By c.YEAR_MO


/*Final Table for Motion*/
If Object_Id('pdb_DermReporting.dbo.AllSavers_Motion') is not null 
DROP TABLE pdb_DermReporting.dbo.AllSavers_Motion
Select a.*
	, b.NewEligibles, b.Cancellations, b.NewRegistrants
	, c.Logging
	, d.FCompliance, d.ICompliance, d.TCompliance
  Into pdb_DermReporting.dbo.AllSavers_Motion
From #t1	a
Join #t2	b	on	a.YearMonth	=	b.YearMonth
Join #t3	c	on	a.YearMonth	=	c.YEAR_MO
Join #t4	d	on	a.YearMonth	=	d.YEAR_MO
Order By a.YearMonth


/***** STORED PROC [dbo].[DSelect_AllSaversMetrics_MemberFunnel] *****/
-- DEVSQL14
--Use pdb_DermReporting
--Go

If Object_Id('pdb_DermReporting.[dbo].[AllSavers_MemberFunnel]') is not null 
DROP TABLE pdb_DermReporting.[dbo].[AllSavers_MemberFunnel]
Select a.*
	, b.TotalMotionEligibles, b.NewEligibles, b.Cancellations, b.NewRegistrants, b.TotalMembers
	, b.Logging, b.FCompliance, b.ICompliance, b.TCompliance
  Into pdb_DermReporting.[dbo].[AllSavers_MemberFunnel]
From pdb_DermReporting.dbo.AllSavers_Insured	a
	Join pdb_DermReporting.dbo.AllSavers_Motion	b	On	a.YearMo	=	b.YearMonth
Order By a.YearMo
