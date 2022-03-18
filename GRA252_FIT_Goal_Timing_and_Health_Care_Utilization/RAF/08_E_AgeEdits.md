> #### Author: Susan Mehle
> #### Description: 
>  * Check for Group Assignment against GroupTier6
>  * Must run after the F table has been created
> ####  Other Code
>   * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spRAFDiagInput]
> 
> #####  Input
>   * research-00: INV_motion.tmp_E_Age
>   * research-00: INV_motion.tmp_F_Group
>   * research-00: INV_motion.raf_GroupTier9
>   * research-00: NV_motion.raf_ModelAge
> 
> ####  Output
>   * research-00: INV_motion.tmp_E_AgeEdits

```SQL
CREATE OR REPLACE TABLE INV_motion.tmp_E_AgeEdits AS

SELECT DISTINCT 
		 a.UniqueMemberID
		,a.ModelCategoryID
		,a.ModelAgeID AS ModelAgeID
		,a.TERM
		,a.Coefficient
		,IFNULL(d.Coefficient, a.Coefficient) AS EditedCoefficient 
		,IFNULL(c.GETModelAgeID, a.ModelAgeID) AS EditedModelAgeID
		,CASE WHEN c.GETModelAgeID IS NULL THEN 0 ELSE 1 END AS AgeEditFlag
	FROM INV_motion.tmp_E_Age a
		LEFT JOIN INV_motion.tmp_F_Group b ON a.UniqueMemberID = b.UniqueMemberID AND a.ModelCategoryID = b.ModelCategoryID
		LEFT JOIN INV_motion.raf_GroupTier9 c ON a.ModelAgeID = c.HAVEModelAgeID AND b.GETModelGroupID = c.HAVEModelGroupID
		LEFT JOIN INV_motion.raf_ModelAge d ON c.GETModelAgeID = d.ModelAgeID	
 ```
