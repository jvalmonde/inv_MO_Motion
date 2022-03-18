SELECT [SavvyHICN]
      ,[ContractNumber]
      ,[PaymentDateYM]
      ,[SCC]
      ,[OutOfAreaFlag]
      ,[PartAEntitlementFlag]
      ,[PartBEntitlementFlag]
      ,[HospiceFlag]
      ,[ESRDFlag]
      ,[InstitutionalFlag]
      ,[NHCFlag]
      ,[MedicaidStatusFlag]
      ,[LTIFlag]
      ,[MedicaidAddOnFlag]
      ,[RiskAdjusterFactorA]
      ,[RiskAdjusterFactorB]
      ,[AdjustmentReasonCode]
      ,[PaymentAdjustmentStartDate]
      ,[PaymentAdjustmentEndDate]
      ,[PreviousDisableRatio]
      ,[PlanBenefitPackageID]
      ,[RaceCode]
      ,[RAFactorTypeCode]
      ,[PreviouslyDisabledFlagSource]
      ,[OriginalReasonForEntitlement]
      ,[EnrollmentSource]
      ,[EGHPFlag]
      ,[TotalPartAMAPayment]
      ,[TotalPartBMAPayment]
      ,[TotalMAPaymentAmount]
      ,[PartDRAFactor]
      ,[PartDLowIncomeIndicator]
      ,[PartDLongTermInstitutionalIndicator]
      ,[ReinsuranceSubsidyAmount]
      ,[LowIncomeSubsidyCostSharingAmount]
      ,[TotalPartDPayment]
      ,[MedicaidDualStatusCode]
  FROM [LTV].[dbo].[CMS_MMR_Sub_20170522]


SELECT [Plan_Year]
      ,[State]
      ,[County]
      ,[Contr_Nbr]
      ,[PBP]
      ,[Premium_C]
      ,[Premium_D_Basic]
      ,[Premium_D_Supplemental]
      ,[Premium_D]
  FROM [LTV].[dbo].[CMS_Plan_Benefits_CD_Premiums]


SELECT [SavvyHICN]
      ,[ContractNumber]
      ,[RunDate]
      ,[PaymentDateYM]
      ,[Gender]
      ,[MedicaidFemaleDisabled]
      ,[MedicaidFemaleAged]
      ,[MedicaidMaleDisabled]
      ,[MedicaidMaleAged]
      ,[OriginallyDisabledFemale]
      ,[OriginallyDisabledMale]
      ,[DiseaseCoefficientsHCC1]
      ,[DiseaseCoefficientsHCC2]
      ,[DiseaseCoefficientsHCC5]
      ,[DiseaseCoefficientsHCC7]
      ,[DiseaseCoefficientsHCC8]
      ,[DiseaseCoefficientsHCC9]
      ,[DiseaseCoefficientsHCC10]
      ,[DiseaseCoefficientsHCC15]
      ,[DiseaseCoefficientsHCC16]
      ,[DiseaseCoefficientsHCC17]
      ,[DiseaseCoefficientsHCC18]
      ,[DiseaseCoefficientsHCC19]
      ,[DiseaseCoefficientsHCC21]
      ,[DiseaseCoefficientsHCC25]
      ,[DiseaseCoefficientsHCC26]
      ,[DiseaseCoefficientsHCC27]
      ,[DiseaseCoefficientsHCC31]
      ,[DiseaseCoefficientsHCC32]
      ,[DiseaseCoefficientsHCC33]
      ,[DiseaseCoefficientsHCC37]
      ,[DiseaseCoefficientsHCC38]
      ,[DiseaseCoefficientsHCC44]
      ,[DiseaseCoefficientsHCC45]
      ,[DiseaseCoefficientsHCC51]
      ,[DiseaseCoefficientsHCC52]
      ,[DiseaseCoefficientsHCC54]
      ,[DiseaseCoefficientsHCC55]
      ,[DiseaseCoefficientsHCC67]
      ,[DiseaseCoefficientsHCC68]
      ,[DiseaseCoefficientsHCC69]
      ,[DiseaseCoefficientsHCC70]
      ,[DiseaseCoefficientsHCC71]
      ,[DiseaseCoefficientsHCC72]
      ,[DiseaseCoefficientsHCC73]
      ,[DiseaseCoefficientsHCC74]
      ,[DiseaseCoefficientsHCC75]
      ,[DiseaseCoefficientsHCC77]
      ,[DiseaseCoefficientsHCC78]
      ,[DiseaseCoefficientsHCC79]
      ,[DiseaseCoefficientsHCC80]
      ,[DiseaseCoefficientsHCC81]
      ,[DiseaseCoefficientsHCC82]
      ,[DiseaseCoefficientsHCC83]
      ,[DiseaseCoefficientsHCC92]
      ,[DiseaseCoefficientsHCC95]
      ,[DiseaseCoefficientsHCC96]
      ,[DiseaseCoefficientsHCC100]
      ,[DiseaseCoefficientsHCC101]
      ,[DiseaseCoefficientsHCC104]
      ,[DiseaseCoefficientsHCC105]
      ,[DiseaseCoefficientsHCC107]
      ,[DiseaseCoefficientsHCC108]
      ,[DiseaseCoefficientsHCC111]
      ,[DiseaseCoefficientsHCC112]
      ,[DiseaseCoefficientsHCC119]
      ,[DiseaseCoefficientsHCC130]
      ,[DiseaseCoefficientsHCC131]
      ,[DiseaseCoefficientsHCC132]
      ,[DiseaseCoefficientsHCC148]
      ,[DiseaseCoefficientsHCC149]
      ,[DiseaseCoefficientsHCC150]
      ,[DiseaseCoefficientsHCC154]
      ,[DiseaseCoefficientsHCC155]
      ,[DiseaseCoefficientsHCC157]
      ,[DiseaseCoefficientsHCC158]
      ,[DiseaseCoefficientsHCC161]
      ,[DiseaseCoefficientsHCC164]
      ,[DiseaseCoefficientsHCC174]
      ,[DiseaseCoefficientsHCC176]
      ,[DiseaseCoefficientsHCC177]
      ,[DisabledDiseaseHCC5]
      ,[DisabledDiseaseHCC44]
      ,[DisabledDiseaseHCC51]
      ,[DisabledDiseaseHCC52]
      ,[DisabledDiseaseHCC107]
      ,[DiseaseInteractionsINT1]
      ,[DiseaseInteractionsINT2]
      ,[DiseaseInteractionsINT3]
      ,[DiseaseInteractionsINT4]
      ,[DiseaseInteractionsINT5]
      ,[DiseaseInteractionsINT6]
      ,[RASESRDIndicatorSwitch]
  FROM [LTV].[dbo].[CMS_MOR_Sub_20170522]


SELECT TOP (1000) [SavvyHICN]
      ,[ContractNumber]
      ,[PlanBenefitPackageID]
      ,[EnrollmentSource]
      ,[MedicaidStatus]
      ,[Disability]
      ,[Hospice]
      ,[InstitutionalNHC]
      ,[ESRD]
      ,[TransactionReplyCode]
      ,[TransactionTypeCode]
      ,[EntitlementTypeCode]
      ,[TransactionEffectiveDateCode]
      ,[TransactionDate]
      ,[PreviousPartDContractPBP]
      ,[SourceID]
      ,[PriorPlanBenefitPackageID]
      ,[OutofAreaFlag]
      ,[DisenrollmentReasonCode]
      ,[DateInFileName]
      ,[WeeklyMonthlyIndicator]
      ,[DerivedDisenrollmentEffectiveDate]
      ,[DerivedDateOfDeath]
      ,[ElectionType]
  FROM [LTV].[dbo].[CMS_TRR_Sub_20170522]


---- "Clean up"
SELECT [SavvyHICN]
      ,[ContractNumber]
      ,[PaymentDateYM]
      ,[SCC]
      ,[OutOfAreaFlag]
      ,[PartAEntitlementFlag]
      ,[PartBEntitlementFlag]
      ,[HospiceFlag]
      ,[ESRDFlag]
      ,[InstitutionalFlag]
      ,[NHCFlag]
      ,[MedicaidStatusFlag]
      ,[LTIFlag]
      ,[MedicaidAddOnFlag]
      ,[RiskAdjusterFactorA]
      ,[RiskAdjusterFactorB]
      ,[AdjustmentReasonCode]
      ,[PaymentAdjustmentStartDate]
      ,[PaymentAdjustmentEndDate]
      ,[PreviousDisableRatio]
      ,[PlanBenefitPackageID]
      ,[RaceCode]
      ,[RAFactorTypeCode]
      ,[PreviouslyDisabledFlagSource]
      ,[OriginalReasonForEntitlement]
      ,[EnrollmentSource]
      ,[EGHPFlag]
      ,isnull(try_cast([TotalPartAMAPayment] as decimal(19,4)),0) as [TotalPartAMAPayment]
      ,isnull(try_cast([TotalPartBMAPayment]  as decimal(19,4)),0) as [TotalPartBMAPayment]
      ,isnull(try_cast([TotalMAPaymentAmount]  as decimal(19,4)),0) as [TotalMAPaymentAmount]
      ,[PartDRAFactor]
      ,[PartDLowIncomeIndicator]
      ,[PartDLongTermInstitutionalIndicator]
      ,isnull(try_cast([ReinsuranceSubsidyAmount] as decimal(19,4)),0) as [ReinsuranceSubsidyAmount]
      ,isnull(try_cast([LowIncomeSubsidyCostSharingAmount] as decimal(19,4)),0) as [LowIncomeSubsidyCostSharingAmount]
      ,isnull(try_cast([TotalPartDPayment] as decimal(19,4)),0) as [TotalPartDPayment]
      ,[MedicaidDualStatusCode]
  INTO [LTV].[dbo].[CMS_MMR_Sub_20170522]
  FROM [LTV].[dbo].[CMS_MMR_Sub_20170522_Raw]




---- Sample of tables being used
select SavvyHICN, 	   
       year(RunDate) as Yr,
	   cast(year(RunDate) as varchar)+right('00'+cast(month(RunDate) as varchar),2) as Year_Mo, 
	   cast(RunDate as date) as Event_Date,
	   HCC, Flag
into #mor_unpivot
from LTV..CMS_MOR_Sub_20170522 unpivot(Flag for HCC in(
       [DiseaseCoefficientsHCC1]
      ,[DiseaseCoefficientsHCC2]
      ,[DiseaseCoefficientsHCC5]
      ,[DiseaseCoefficientsHCC7]
      ,[DiseaseCoefficientsHCC8]
      ,[DiseaseCoefficientsHCC9]
      ,[DiseaseCoefficientsHCC10]
      ,[DiseaseCoefficientsHCC15]
      ,[DiseaseCoefficientsHCC16]
      ,[DiseaseCoefficientsHCC17]
      ,[DiseaseCoefficientsHCC18]
      ,[DiseaseCoefficientsHCC19]
      ,[DiseaseCoefficientsHCC21]
      ,[DiseaseCoefficientsHCC25]
      ,[DiseaseCoefficientsHCC26]
      ,[DiseaseCoefficientsHCC27]
      ,[DiseaseCoefficientsHCC31]
      ,[DiseaseCoefficientsHCC32]
      ,[DiseaseCoefficientsHCC33]
      ,[DiseaseCoefficientsHCC37]
      ,[DiseaseCoefficientsHCC38]
      ,[DiseaseCoefficientsHCC44]
      ,[DiseaseCoefficientsHCC45]
      ,[DiseaseCoefficientsHCC51]
      ,[DiseaseCoefficientsHCC52]
      ,[DiseaseCoefficientsHCC54]
      ,[DiseaseCoefficientsHCC55]
      ,[DiseaseCoefficientsHCC67]
      ,[DiseaseCoefficientsHCC68]
      ,[DiseaseCoefficientsHCC69]
      ,[DiseaseCoefficientsHCC70]
      ,[DiseaseCoefficientsHCC71]
      ,[DiseaseCoefficientsHCC72]
      ,[DiseaseCoefficientsHCC73]
      ,[DiseaseCoefficientsHCC74]
      ,[DiseaseCoefficientsHCC75]
      ,[DiseaseCoefficientsHCC77]
      ,[DiseaseCoefficientsHCC78]
      ,[DiseaseCoefficientsHCC79]
      ,[DiseaseCoefficientsHCC80]
      ,[DiseaseCoefficientsHCC81]
      ,[DiseaseCoefficientsHCC82]
      ,[DiseaseCoefficientsHCC83]
      ,[DiseaseCoefficientsHCC92]
      ,[DiseaseCoefficientsHCC95]
      ,[DiseaseCoefficientsHCC96]
      ,[DiseaseCoefficientsHCC100]
      ,[DiseaseCoefficientsHCC101]
      ,[DiseaseCoefficientsHCC104]
      ,[DiseaseCoefficientsHCC105]
      ,[DiseaseCoefficientsHCC107]
      ,[DiseaseCoefficientsHCC108]
      ,[DiseaseCoefficientsHCC111]
      ,[DiseaseCoefficientsHCC112]
      ,[DiseaseCoefficientsHCC119]
      ,[DiseaseCoefficientsHCC130]
      ,[DiseaseCoefficientsHCC131]
      ,[DiseaseCoefficientsHCC132]
      ,[DiseaseCoefficientsHCC148]
      ,[DiseaseCoefficientsHCC149]
      ,[DiseaseCoefficientsHCC150]
      ,[DiseaseCoefficientsHCC154]
      ,[DiseaseCoefficientsHCC155]
      ,[DiseaseCoefficientsHCC157]
      ,[DiseaseCoefficientsHCC158]
      ,[DiseaseCoefficientsHCC161]
      ,[DiseaseCoefficientsHCC164]
      ,[DiseaseCoefficientsHCC174]
      ,[DiseaseCoefficientsHCC176]
      ,[DiseaseCoefficientsHCC177]
	)) as Unpiv
where Flag = 'True'



select a.*
into #trr
from(
	select a.SavvyHICN,
			a.ContractNumber as Contr_Nbr,
			a.PlanBenefitPackageID as PBP,
			a.TransactionEffectiveDateCode,
			left(a.TransactionEffectiveDateCode, 6) as Year_Mo,
			a.TransactionTypeCode, c.TransactionTypeDescription,
			a.TransactionReplyCode, b.Title as TransactionReplyDescription,
			a.EnrollmentSource, d.EnrollmentSourceDescription,
			a.ElectionType, e.ElectionTypeDesc,
			a.DisenrollmentReasonCode, f.DisenrollmentReasonDesc,
			--a.MedicaidStatus, a.Disability, a.Hospice, a.InstitutionalNHC, a.ESRD, 
			ROW_NUMBER() over(partition by a.SavvyHICN, a.ContractNumber, a.PlanBenefitPackageID, a.TransactionTypeCode, a.TransactionEffectiveDateCode order by b.TransactionReplyCodeType, a.DateInFileName desc, a.TransactionReplyCode) as RN
	from LTV..CMS_TRR_Sub_20170522				as a 
	left join LTV..TRR_TransactionReplyCode		as b	on a.TransactionReplyCode = b.TransactionReplyCode
	left join LTV..TRR_TransactionTypeCode		as c	on a.TransactionTypeCode = c.TransactionTypeCode
	left join LTV..TRR_EnrollmentSource			as d	on a.EnrollmentSource = d.EnrollmentSourceCode
	left join LTV..TRR_ElectionType				as e	on a.ElectionType = e.ElectionTypeCode
	left join LTV..TRR_DisenrollmentReasonCode	as f	on a.DisenrollmentReasonCode = f.DisenrollmentReasonCode
	where a.TransactionTypeCode in('01','51','53','54','60','61','62','71','74','80','81','82')
		and b.TransactionReplyCodeType in('A') --Accepted (not Rejected, Informational, Maintenance, or Failed)
	) as a
where a.RN = 1
--1,616,970
-- TRR tables are just Dimension tables



select a.SavvyHICN, a.Year_Mo, a.ContractNumber, a.PlanBenefitPackageID,
	   max(a.PartDRAFactor) as D_RAF, 
	   max(a.RiskAdjusterFactorA) as MA_RAF,
	   cast(sum(Adjusted_MA_Amt) as money) as Total_MA_Amt, 
	   cast(sum(Adjusted_D_Amt) as money) as Total_D_Amt, 
	   cast(sum(LowIncomeSubsidyCostSharingAmount) as money) as LICS_Amt,
	   cast(sum(ReinsuranceSubsidyAmount) as money) as Reinsurance_Amt,
	   max(a.HospiceFlag) as HospiceFlag
into #mmr_enrollment
from(
	select a.SavvyHICN, b.Year_Mo, a.ContractNumber, a.PlanBenefitPackageID,
		   a.PartDRAFactor, a.RiskAdjusterFactorA, 
		   a.LowIncomeSubsidyCostSharingAmount, 
		   a.ReinsuranceSubsidyAmount,
		   a.HospiceFlag,
		   a.TotalMAPaymentAmount/(a.End_Year_Mo-a.Start_Year_Mo+1) as Adjusted_MA_Amt, --distribute multi-month costs 
		   a.TotalPartDPayment/(a.End_Year_Mo-a.Start_Year_Mo+1) as Adjusted_D_Amt
	from(
		select a.SavvyHICN, a.ContractNumber, a.PlanBenefitPackageID,
			   a.PartDRAFactor, a.RiskAdjusterFactorA, 
			   a.TotalMAPaymentAmount, 
			   a.TotalPartDPayment, 
			   a.LowIncomeSubsidyCostSharingAmount, 
			   a.ReinsuranceSubsidyAmount,
			   a.HospiceFlag,
			   a.PaymentAdjustmentStartDate, a.PaymentAdjustmentEndDate, 
			   cast(left(replace(a.PaymentAdjustmentStartDate, '-', ''), 6) as int) as Start_Year_Mo,
			   cast(left(replace(a.PaymentAdjustmentEndDate, '-', ''), 6) as int) as End_Year_Mo
		from LTV..CMS_MMR_Sub_20170522	as a
		join #members					as b	on a.SavvyHICN = b.SavvyHICN
		)				as a 
	join #year_mo		as b	on b.Year_Mo between a.Start_Year_Mo and a.End_Year_Mo
	where b.Year_Mo between 200601 and 201703
	--order by 6, 2, 3, 4
	) as a
group by a.SavvyHICN, a.YEAR_MO, a.ContractNumber, a.PlanBenefitPackageID
having cast(sum(Adjusted_MA_Amt) as money) > 0	--Has MA benefit (resolves retroactive reversals)
   and cast(sum(Adjusted_D_Amt) as money) > 0	--Has Part D benefit
order by 1, 2
--18,847,600