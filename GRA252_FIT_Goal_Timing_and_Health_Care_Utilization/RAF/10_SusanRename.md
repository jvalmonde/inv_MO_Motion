```sql
--================ GroupHierarchy Processing
CREATE OR REPLACE TABLE INV_motion.tmp_G_HCC AS

WITH Remove AS (SELECT b.UniqueMemberID, b.ModelCategoryID, a.ChildModelHCCID			
                FROM INV_motion.raf_GroupHierarchy1 a			
                INNER JOIN INV_motion.tmp_F_Group b ON a.ParentModelGroupID = b.GETModelGroupID)

SELECT a.*
FROM INV_motion.tmp_D_HCC a
  LEFT OUTER JOIN Remove ON a.UniqueMemberID = Remove.UniqueMemberID AND a.ModelHCCID = Remove.ChildModelHCCID				
Where Remove.UniqueMemberID IS NULL

--================ Identify remaining ModelGroup(s) after excluding those that are children to specific ModelGroup/Terms.  GroupHierarchy2 Filter.
CREATE OR REPLACE TABLE INV_motion.tmp_H_Group AS

WITH Remove AS (SELECT DISTINCT b.UniqueMemberID, b.ModelCategoryID, a.ChildModelGroupID
                FROM INV_motion.raf_GroupHierarchy2 a			
                INNER JOIN INV_motion.tmp_F_Group b ON a.ParentModelGroupID = b.GETModelGroupID)

SELECT DISTINCT a.*
FROM INV_motion.tmp_F_Group a
  LEFT OUTER JOIN Remove ON a.UniqueMemberID = Remove.UniqueMemberID AND a.GETModelGroupID = Remove.ChildModelGroupID
Where Remove.UniqueMemberID IS NULL


--================ Create Output table that will be consumed by user to review a total score for each model.
--=========Create a normalized/relational dataset that has one record per member per metal.
CREATE OR REPLACE TABLE INV_motion.tmp_I_MetalScores AS

WITH a AS (SELECT UniqueMemberID, ModelCategoryID, Coefficient FROM INV_motion.tmp_D_HCC
UNION ALL SELECT UniqueMemberID, ModelCategoryID, Coefficient FROM INV_motion.tmp_H_Group
UNION ALL SELECT UniqueMemberID, ModelCategoryID, EditedCoefficient FROM INV_motion.tmp_E_AgeEdits)

SELECT
 a.UniqueMemberID
,b.ModelCategory
,c.ModelVersion
,Sum(Coefficient) TotalScore

FROM a
    INNER JOIN INV_motion.raf_ModelCategory b ON a.ModelCategoryID = b.ModelCategoryID 
    INNER JOIN INV_motion.raf_Model c ON c.ModelID = b.ModelID
    INNER JOIN INV_motion.GRA252_raf_Person d ON a.UniqueMemberID = d.UniqueMemberID
WHERE TRIM(d.Gender) IN ("M","F")
GROUP BY a.UniqueMemberID, b.ModelCategory, c.ModelVersion

--================ -Create a pivoted dataset of table I that will will have one record per member.
CREATE OR REPLACE TABLE INV_motion.tmp_J_MetalScoresPivoted AS

Select UniqueMemberID, ModelCategory
,Sum(Case When ModelVersion = "Platinum"     Then TotalScore Else 0 End) PlatinumTotalScore
,Sum(Case When ModelVersion = "Gold"         Then TotalScore Else 0 End) GoldTotalScore
,Sum(Case When ModelVersion = "Silver"       Then TotalScore Else 0 End) SilverTotalScore
,Sum(Case When ModelVersion = "Bronze"       Then TotalScore Else 0 End) BronzeTotalScore
,Sum(Case When ModelVersion = "Catastrophic" Then TotalScore Else 0 End) CatastrophicTotalScore

From INV_motion.tmp_I_MetalScores
Group By UniqueMemberID, ModelCategory

--================ Saves as final table
CREATE OR REPLACE TABLE INV_motion.GRA252_raf_2015 AS SELECT * FROM INV_motion.tmp_J_MetalScoresPivoted
