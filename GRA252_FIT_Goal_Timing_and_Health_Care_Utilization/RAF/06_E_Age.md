> #### Author: Susan Mehle
> #### Description: Identify the Age Coefficient associated with each member
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
>   * research-00: INV_motion.tmp_E_Age

```SQL
--TableE
CREATE OR REPLACE TABLE INV_motion.tmp_E_Age AS
	SELECT DISTINCT
			 a.UniqueMemberID
			,a.ModelCategoryID
			,ModelAgeID
			,CONCAT("Age Between ", CAST(c.AgeStart AS STRING), "-", CAST(c.AgeEnd AS STRING)) AS Term
			,Coefficient
		FROM INV_motion.tmp_A_IdentifyModelCategory a
			INNER JOIN INV_motion.GRA252_raf_Person b ON a.UniqueMemberID = b.UniqueMemberID
			INNER JOIN INV_motion.raf_ModelAge c ON a.ModelCategoryID = c.ModelCategoryID
				AND b.age Between c.AgeStart AND c.AgeEnd AND TRIM(b.gender) = TRIM(c.GenderCD)
```
