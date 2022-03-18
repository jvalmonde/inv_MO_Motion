use pdb_WalkandWin
go

--use https://www.bls.gov/regions/midwest/data/consumerpriceindexhistorical_us_table.pdf to update CPI_Adjustment
--2017 figure seems to be from April, others figures are from Yearly Average

IF object_id('Dim_Adjustment_Reason','U') IS NOT NULL
	DROP TABLE Dim_Adjustment_Reason;
WITH 
	cteData(AdjustmentReasonCode, AdjustmentReasonDescription) as
		(		select '01', 'Notification of Death of Beneficiary'
		union	select '02', 'Retroactive Enrollment'
		union	select '03', 'Retroactive Disenrollment'
		union	select '04', 'Correction to Enrollment Date'
		union	select '05', 'Correction to Disenrollment Date'
		union	select '06', 'Correction to Part A Entitlement'
		union	select '07', 'Retroactive Hospice Status'
		union	select '08', 'Retroactive ESRD Status'
		union	select '09', 'Retroactive Institutional Status'
		union	select '10', 'Retroactive Medicaid Status'
		union	select '11', 'Retroactive Change to State County Code'
		union	select '12', 'Date of Death Correction'
		union	select '13', 'Date of Birth Correction'
		union	select '14', 'Correction to Sex Code'
		union	select '15', 'Obsolete'
		union	select '16', 'Obsolete'
		union	select '17', 'For APPS use only'
		union	select '18', 'Part C Rate Change'
		union	select '19', 'Correction to Part B Entitlement'
		union	select '20', 'Retroactive Working Aged Status'
		union	select '21', 'Retroactive NHC Status'
		union	select '22', 'Disenrolled Due to Prior ESRD'
		union	select '23', 'Demo Factor Adjustment'
		union	select '24', 'Retroactive Change to Bonus Payment'
		union	select '25', 'Part C Risk Adj Factor Change/Recon'
		union	select '26', 'Mid-year Part C Risk Adj Factor Change'
		union	select '27', 'Retroactive Change to Congestive Heart Failure (CHF) Payment'
		union	select '28', 'Retroactive Change to BIPA Part B Premium Reduction Amount'
		union	select '29', 'Retroactive Change to Hospice Rate'
		union	select '30', 'Retroactive Change to Basic Part D Premium'
		union	select '31', 'Retroactive Change to Part D Low Income Status'
		union	select '32', 'Retroactive Change to Estimated Cost-Sharing Amount'
		union	select '33', 'Retroactive Change to Estimated Reinsurance Amount'
		union	select '34', 'Retroactive Change Basic Part C Premium '
		union	select '35', 'Retroactive Change to Rebate Amount'
		union	select '36', 'Part D Rate Change'
		union	select '37', 'Part D Risk Adjustment Factor Change'
		union	select '38', 'Part C Segment ID Change'
		union	select '41', 'Part D Risk Adjustment Factor Change (ongoing)'
		union	select '42', 'Retroactive MSP Status'
		union	select '44', 'Retroactive correction of previously failed Payment (affects Part C and D)'
		union	select '45', 'Disenroll for Failure to Pay Part D IRMAA Premium – Reported for Pt C and Pt D'
		union	select '46', 'Correction of Part D Eligibility – Reported for Pt D'
		union	select '50', 'Payment adjustment due to Beneficiary Merge'
		union	select '60', 'Part C Payment Adjustments created as a result of the RAS overpayment file processing'
		union	select '61', 'Part D Payment Adjustments created as a result of the RAS overpayment file processing'
		union	select '65', 'Confirmed Incarceration – Reported for Pt C and Pt D'
		union	select '66', 'Not Lawfully Present'
		union	select '90', 'System of Record History Alignment'
		union	select '94',  'Special Payment Adjustment Due to Clean-Up'
		)
select --*, 195.3*1.252043, 244.524 / CPI , 245.120 / CPI,
	AdjustmentReasonCode				, 
	AdjustmentReasonDescription
into Dim_Adjustment_Reason
from cteData
go
create clustered index cixAdjustmentReasonCode on Dim_Adjustment_Reason(AdjustmentReasonCode)
go
