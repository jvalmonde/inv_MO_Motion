> #### Author: Susan Mehle
> #### Description: Check the Diagnosis dataset for the individual to see what HCC should be assigned after checking MCE criteria as well as other Age/Gender criteria for HCC assignment.
> ####  Other Code
>   * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spRAFDiagInput]
> 
> #####  Input
>   * research-00: INV_motion.raf_Model
>   * research-00: INV_motion.raf_ModelCategory
>   * research-00: INV_motion.raf_Model
>   * research-00: NV_motion.GRA252_raf_Person
> 
> ####  Output
>   * research-00: INV_motion.tmp_C_HCC

```SQL

CREATE OR REPLACE TABLE INV_motion.tmp_C_HCC AS
	SELECT DISTINCT
		 a.UniqueMemberID
		,a.ModelCategoryID
		,c.ModelHCCID
		,Term
		,HCCNbr
		,Coefficient

		FROM INV_motion.tmp_B_Diag a
				INNER JOIN INV_motion.raf_HCCDiagnosis b on TRIM(a.ICDCd) =TRIM(b.ICDCd)
				INNER JOIN INV_motion.raf_ModelHCC c on  c.ModelHCCID = b.ModelHCCID AND a.ModelCategoryID = c.ModelCategoryID
		WHERE IFNULL(TRIM(b.MCEGenderCondition), TRIM(a.GenderCd)) = TRIM(a.GenderCd) --Checks MCE criteria
		      AND a.AgeAtDiagnosis Between MCEDiagnosisAgeStart AND MCEDiagnosisAgeEnd --Checks MCE criteria
		      AND IFNULL(TRIM(b.HCCNbrGenderCondition), TRIM(a.GenderCd)) = TRIM(a.GenderCd) --Check HSS criteria
		      AND a.AgeLast Between HCCNbrLastAgeStart AND HCCNbrLastAgeEnd --Check HSS criteria
```
