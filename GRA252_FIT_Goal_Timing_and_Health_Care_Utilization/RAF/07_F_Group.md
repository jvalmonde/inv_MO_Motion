
> #### Author: Susan Mehle
> #### Description: 
>   * Identify the Groups/Interactions that This member qualifies for
>     * Check for Group Assignments against GroupTier8
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
>   * research-00: INV_motion.tmp_F_Group

```SQL

CREATE OR REPLACE TABLE INV_motion.tmp_F_Group AS

SELECT DISTINCT
		 a.UniqueMemberID
		,a.ModelCategoryID
		,b.GETModelGroupID
		,c.Term
		,c.Coefficient
		,"GroupTier6" Src
	FROM INV_motion.tmp_E_Age a
		INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelAgeID = b.HAVEModelAgeID
		INNER JOIN INV_motion.raf_ModelGroup c ON c.ModelGroupID = b.GETModelGroupId
	WHERE a.UniqueMemberID NOT IN --Identifies members that have an HCCID that will disqualify them FROM receiving this ModelGroupID (Group Tier 6)
(
 SELECT DISTINCT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE1ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE2ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE3ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE4ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE5ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE6ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE7ModelHCCID
UNION DISTINCT SELECT a.UniqueMemberID FROM INV_motion.tmp_D_HCC a INNER JOIN INV_motion.raf_GroupTier6 b ON a.ModelHCCID = b.DONOTHAVE8ModelHCCID
)
```
