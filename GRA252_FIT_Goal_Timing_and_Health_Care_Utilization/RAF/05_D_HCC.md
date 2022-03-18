> #### Author: Susan Mehle
> #### Description: 
> * HCCHierarchy Processing: Build a list of HCC's that remain for each member after excluding those that are children.
> ####  Other Code
>   * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spRAFDiagInput]
> 
> #####  Input
>   * research-00: INV_motion.raf_HCCHierarchy
>   * research-00: INV_motion.tmp_C_HCC
> 
> ####  Output
>   * research-00: INV_motion.tmp_D_HCC

```SQL

CREATE OR REPLACE TABLE INV_motion.tmp_D_HCC AS

WITH Remove AS --Identify the Child HCC(s) that would need to be excluded for each member.
		(SELECT b.UniqueMemberID, b.ModelCategoryID, a.ChildModelHCCID
			FROM INV_motion.raf_HCCHierarchy a
			INNER JOIN INV_motion.tmp_C_HCC b ON a.ParentModelHCCID = b.ModelHCCID)

SELECT a.*	
	FROM INV_motion.tmp_C_HCC a							
		LEFT OUTER JOIN Remove ON  a.UniqueMemberID = Remove.UniqueMemberID				
			AND a.ModelHCCID = Remove.ChildModelHCCID				
	WHERE Remove.UniqueMemberID IS NULL
