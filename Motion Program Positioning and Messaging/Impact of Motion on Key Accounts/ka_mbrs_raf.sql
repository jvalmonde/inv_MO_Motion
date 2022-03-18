-- RAF calculation

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS (
SELECT Indv_Sys_Id AS UniqueMemberID
  , CASE WHEN Gdr_Cd = 'M' THEN 'M' WHEN Gdr_Cd = 'F' THEN 'F' ELSE NULL END AS gendercode
  , Age - 1 AS age_first 
  , Age AS age_last
  , 0 AS CSR_INDICATOR 
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Claims AS (
WITH DX1 AS (
  SELECT a.UniqueMemberID
    , b.Dt_Sys_Id
    , b.Diag_1_Cd_Sys_Id AS DIAG_CD_SYS_ID
    , b.Proc_Cd_Sys_Id
    , b.Bil_Typ_Cd_Sys_Id
    , a.age_first
    , a.age_last
    , a.gendercode
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS a 
  JOIN dm_minihpdm.fact_claims AS b 
    ON a.UniqueMemberID = b.Indv_Sys_Id
)
, DX2 AS (
  SELECT a.UniqueMemberID
    , b.Dt_Sys_Id
    , b.Diag_2_Cd_Sys_Id AS DIAG_CD_SYS_ID
    , b.Proc_Cd_Sys_Id
    , b.Bil_Typ_Cd_Sys_Id
    , a.age_first
    , a.age_last
    , a.gendercode
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS a 
  JOIN dm_minihpdm.fact_claims AS b 
    ON a.UniqueMemberID = b.Indv_Sys_Id
)
, DX3 AS (
  SELECT a.UniqueMemberID
    , b.Dt_Sys_Id
    , b.Diag_3_Cd_Sys_Id AS DIAG_CD_SYS_ID
    , b.Proc_Cd_Sys_Id
    , b.Bil_Typ_Cd_Sys_Id
    , a.age_first
    , a.age_last
    , a.gendercode
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS a 
  JOIN dm_minihpdm.fact_claims AS b 
    ON a.UniqueMemberID = b.Indv_Sys_Id
)
, DX AS (
  SELECT * 
  FROM DX1 
  UNION DISTINCT 
  SELECT * 
  FROM DX2 
  UNION DISTINCT 
  SELECT * FROM DX3
)
SELECT b.UniqueMemberID
  , TRIM(d.DIAG_CD) AS ICDCd
  , TRIM(d.ICD_VER_CD) AS IcdVerCd
  , c.FULL_DT AS DiagnosisServiceDate
  , TRIM(e.PROC_CD) AS ProcCd
  , b.age_first
  , b.age_last
  , TRIM(b.gendercode) gendercode
  , CASE WHEN TRIM(Bil_Typ_Cd) = "UNK" OR TRIM(Bil_Typ_Cd) = "" OR TRIM(Bil_Typ_Cd) IS NULL 
    OR TRIM(Bil_Typ_Cd) = "NULL" THEN NULL ELSE TRIM(Bil_Typ_Cd) END AS BillTypeCode
FROM DX AS b
JOIN dm_minihpdm.dim_date AS c 
  ON c.DT_SYS_ID = b.Dt_Sys_Id
JOIN dm_minihpdm.dim_diagnosis_code AS d 
  ON d.DIAG_CD_SYS_ID = b.DIAG_CD_SYS_ID
JOIN dm_minihpdm.dim_procedure_code AS e 
  ON e.PROC_CD_SYS_ID = b.Proc_Cd_Sys_Id
LEFT JOIN dm_minihpdm.dim_bill_type_code AS f 
  ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id
LEFT JOIN dm_minihpdm.summary_indv_mm AS g 
  ON b.UniqueMemberID = g.Indv_Sys_Id
WHERE (TRIM(d.ICD_VER_CD) = "0" OR TRIM(d.ICD_VER_CD) = "9") 
  AND TRIM(d.DIAG_CD) <> "" 
  AND TRIM(d.DIAG_CD) IS NOT NULL
  AND c.FULL_DT BETWEEN "2018-01-01" AND "2018-12-31"
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_diagnosis AS (
SELECT DISTINCT a.UniqueMemberID
  , IcdCd
  , IcdVerCd
  , DiagnosisServiceDate
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Claims AS a
LEFT JOIN INV_motion.raf_ProcCd2016 AS b 
  ON a.ProcCd = b.ProcCd
WHERE a.BillTypeCode IN ("111","117")
  OR (a.BillTypeCode IN ("131","137","711","717","761","767","771","777","851","857") AND b.ProcCd IS NOT NULL)
  OR (a.BillTypeCode IS NULL AND b.ProcCd IS NOT NULL)
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_A_IdentifyModelCategory AS (
WITH vwIdentifyModelCategory AS (
  SELECT a.ModelID
    , b.ModelCategoryID
    , b.AgeStart
    , b.AgeEnd
  FROM INV_motion.raf_Model AS a 
  INNER JOIN INV_motion.raf_ModelCategory AS b 
    ON a.ModelID = b.ModelID
)
SELECT DISTINCT UniqueMemberID
  , ModelID
  , ModelCategoryID							
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS a 
INNER JOIN vwIdentifyModelCategory AS b 
  ON a.age_last BETWEEN b.AgeStart AND b.AgeEnd
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_B_Diag AS (
WITH b AS (
  SELECT DISTINCT UniqueMemberID
    , ICDCd 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_diagnosis
)
SELECT DISTINCT	a.UniqueMemberID							
  , a.ModelCategoryID							
  , b.ICDCd
  , c.age_first AS AgeAtDiagnosis						
  , c.age_last AS AgeLast							
  , c.gendercode AS GenderCd				
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_A_IdentifyModelCategory AS a							
INNER JOIN b 
  ON a.UniqueMemberID = b.UniqueMemberID				
INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS c
  ON c.UniqueMemberID = a.UniqueMemberID				
WHERE c.gendercode IN ("M","F")  
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_C_HCC AS (
SELECT DISTINCT a.UniqueMemberID
  , a.ModelCategoryID
  , c.ModelHCCID
  , Term
  , HCCNbr
  , Coefficient
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_B_Diag AS a
INNER JOIN INV_motion.raf_HCCDiagnosis AS b 
  ON TRIM(a.ICDCd) =TRIM(b.ICDCd)
INNER JOIN INV_motion.raf_ModelHCC AS c 
  ON c.ModelHCCID = b.ModelHCCID AND a.ModelCategoryID = c.ModelCategoryID
WHERE IFNULL(TRIM(b.MCEGenderCondition), TRIM(a.GenderCd)) = TRIM(a.GenderCd)
		      AND a.AgeAtDiagnosis Between MCEDiagnosisAgeStart AND MCEDiagnosisAgeEnd
		      AND IFNULL(TRIM(b.HCCNbrGenderCondition), TRIM(a.GenderCd)) = TRIM(a.GenderCd)
		      AND a.AgeLast Between HCCNbrLastAgeStart AND HCCNbrLastAgeEnd
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS (
WITH Remove AS (
  SELECT b.UniqueMemberID
    , b.ModelCategoryID
    , b.ModelHCCID
    , a.ChildModelHCCID
	FROM INV_motion.raf_HCCHierarchy AS a
	INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_C_HCC AS b 
    ON a.ParentModelHCCID = b.ModelHCCID
)
SELECT a.*	
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_C_HCC a							
LEFT OUTER JOIN Remove 
  ON a.UniqueMemberID = Remove.UniqueMemberID				
	 AND a.ModelHCCID = Remove.ChildModelHCCID				
WHERE Remove.UniqueMemberID IS NULL
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_Age AS (
SELECT DISTINCT a.UniqueMemberID
  , a.ModelCategoryID
  , ModelAgeID
  , CONCAT("Age Between ", CAST(c.AgeStart AS STRING), "-", CAST(c.AgeEnd AS STRING)) AS Term
  , Coefficient
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_A_IdentifyModelCategory AS a
INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS b 
  ON a.UniqueMemberID = b.UniqueMemberID
INNER JOIN INV_motion.raf_ModelAge AS c 
  ON a.ModelCategoryID = c.ModelCategoryID
	AND b.age_first BETWEEN c.AgeStart AND c.AgeEnd AND TRIM(b.gendercode) = TRIM(c.GenderCD)
)

     
CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS (
SELECT DISTINCT a.UniqueMemberID
  , a.ModelCategoryID
  , b.GETModelGroupID
  , c.Term
  , c.Coefficient
  , "GroupTier6" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_Age AS a
INNER JOIN INV_motion.raf_GroupTier6 b 
  ON a.ModelAgeID = b.HAVEModelAgeID
INNER JOIN INV_motion.raf_ModelGroup c 
  ON c.ModelGroupID = b.GETModelGroupId
WHERE a.UniqueMemberID NOT IN (
  SELECT DISTINCT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE1ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE2ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE3ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE4ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE5ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE6ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE7ModelHCCID
  UNION DISTINCT 
  SELECT a.UniqueMemberID 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a 
  INNER JOIN INV_motion.raf_GroupTier6 AS b 
    ON a.ModelHCCID = b.DONOTHAVE8ModelHCCID
)
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_AgeEdits AS (
SELECT DISTINCT a.UniqueMemberID
  , a.ModelCategoryID
  , a.ModelAgeID AS ModelAgeID
  , a.TERM
  , a.Coefficient
  , IFNULL(d.Coefficient, a.Coefficient) AS EditedCoefficient 
  , IFNULL(c.GETModelAgeID, a.ModelAgeID) AS EditedModelAgeID
	, CASE WHEN c.GETModelAgeID IS NULL THEN 0 ELSE 1 END AS AgeEditFlag
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_Age AS a
LEFT JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS b 
  ON a.UniqueMemberID = b.UniqueMemberID 
    AND a.ModelCategoryID = b.ModelCategoryID
LEFT JOIN INV_motion.raf_GroupTier9 AS c
  ON a.ModelAgeID = c.HAVEModelAgeID 
    AND b.GETModelGroupID = c.HAVEModelGroupID
LEFT JOIN INV_motion.raf_ModelAge AS d 
  ON c.GETModelAgeID = d.ModelAgeID	
)


INSERT INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src) (
SELECT DISTINCT	a.UniqueMemberID				
  , a.ModelCategoryID				
  , GETModelGroupID				
  , d.Term				
  , d.Coefficient				
  , "GroupTier8" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a				
INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_AgeEdits AS b 
  ON a.UniqueMemberID = b.UniqueMemberID AND a.ModelCategoryID = b.ModelCategoryID	
INNER JOIN INV_motion.raf_GroupTier8 AS c 
  ON c.HAVEModelAgeID = b.EditedModelAgeID AND c.HAVEModelHCCID = a.ModelHCCID	
INNER JOIN INV_motion.raf_ModelGroup AS d 
  ON d.ModelGroupID = c.GETModelGroupID
)


INSERT INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src) (
SELECT DISTINCT	a.UniqueMemberID				
  , a.ModelCategoryID				
  , GETModelGroupID				
  , c.Term				
  , c.Coefficient				
  , "GroupTier7" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_AgeEdits AS a
INNER JOIN INV_motion.raf_GroupTier7 AS b 
  ON a.EditedModelAgeID = b.HaveModelAgeID 
INNER JOIN INV_motion.raf_ModelGroup AS c 
  ON c.ModelGroupID = b.GETModelGroupID
)


INSERT INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src) (
SELECT DISTINCT	a.UniqueMemberID				
  , a.ModelCategoryID				
  , GETModelGroupID				
  , c.Term				
  , c.Coefficient				
  , "GroupTier1" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a
INNER JOIN INV_motion.raf_GroupTier1 AS b 
  ON a.ModelHCCID = b.HAVEModelHCCID 
INNER JOIN INV_motion.raf_ModelGroup AS c 
  ON c.ModelGroupID = b.GETModelGroupID
)


INSERT INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src) (
SELECT DISTINCT a.UniqueMemberID				
  , a.ModelCategoryID				
  , c.GETModelGroupID				
  , d.Term				
  , d.Coefficient				
  , "GroupTier3" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS a
INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS b 
  ON a.UniqueMemberID = b.UniqueMemberID 
    AND a.ModelCategoryID = b.ModelCategoryID 
    AND a.GETModelGroupID <> b.GETModelGroupID
INNER JOIN INV_motion.raf_GroupTier3 AS c 
  ON c.HAVE1ModelGroupID = a.GETModelGroupID 
    AND c.HAVE2ModelGroupID = b.GETModelGroupID
INNER JOIN INV_motion.raf_ModelGroup AS d 
  ON d.ModelGroupID = c.GETModelGroupID
)


INSERT INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src) (
SELECT DISTINCT	a.UniqueMemberID				
  , a.ModelCategoryID				
  , c.GETModelGroupID				
  , d.Term				
  , d.Coefficient				
  , "GroupTier4" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS a
INNER JOIN INV_motion.raf_GroupTier4 AS c 
  ON c.HAVEModelGroupID = a.GETModelGroupID 
INNER JOIN INV_motion.raf_ModelGroup AS d 
  ON d.ModelGroupID = c.GETModelGroupID
)


INSERT INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src) (
SELECT DISTINCT	a.UniqueMemberID				
  , a.ModelCategoryID				
  , b.GETModelGroupID				
  , c.Term				
  , c.Coefficient				
  , "GroupTier5" AS Src
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS a
INNER JOIN INV_motion.raf_GroupTier5 AS b 
  ON a.GETModelGroupID = b.HAVEModelGroupID		
INNER JOIN INV_motion.raf_ModelGroup AS c 
  ON c.ModelGroupID = b.GETModelGroupID		
WHERE a.UniqueMemberID NOT IN	(
		SELECT a.UniqueMemberID			
		FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS a		
		INNER JOIN INV_motion.raf_GroupTier5 AS b	
		  ON a.GETModelGroupID = b.DONOTHAVEModelGroupID
) 	
)    
 
 
CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_G_HCC AS (
WITH Remove AS (
  SELECT b.UniqueMemberID
    , b.ModelCategoryID
    , a.ChildModelHCCID			
  FROM INV_motion.raf_GroupHierarchy1 AS a			
  INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS b 
    ON a.ParentModelGroupID = b.GETModelGroupID
)
SELECT a.*
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC AS a
LEFT OUTER JOIN Remove 
  ON a.UniqueMemberID = Remove.UniqueMemberID 
    AND a.ModelHCCID = Remove.ChildModelHCCID				
WHERE Remove.UniqueMemberID IS NULL
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_H_Group AS (
WITH Remove AS (
  SELECT DISTINCT b.UniqueMemberID, b.ModelCategoryID, a.ChildModelGroupID
  FROM INV_motion.raf_GroupHierarchy2 AS a			
  INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS b 
    ON a.ParentModelGroupID = b.GETModelGroupID
)
SELECT DISTINCT a.*
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group AS a
LEFT OUTER JOIN Remove 
  ON a.UniqueMemberID = Remove.UniqueMemberID 
    AND a.GETModelGroupID = Remove.ChildModelGroupID
WHERE Remove.UniqueMemberID IS NULL
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_I_MetalScores AS (
WITH a AS (
  SELECT UniqueMemberID
    , ModelCategoryID
    , Coefficient 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC
  UNION ALL 
  SELECT UniqueMemberID
    , ModelCategoryID
    , Coefficient 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_H_Group
  UNION ALL 
  SELECT UniqueMemberID
    , ModelCategoryID
    , EditedCoefficient 
  FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_AgeEdits
)
SELECT a.UniqueMemberID
  , b.ModelCategory
  , c.ModelVersion
  , SUM(Coefficient) AS TotalScore
FROM a
INNER JOIN INV_motion.raf_ModelCategory AS b 
  ON a.ModelCategoryID = b.ModelCategoryID 
INNER JOIN INV_motion.raf_Model AS c 
  ON c.ModelID = b.ModelID
INNER JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person AS d 
  ON a.UniqueMemberID = d.UniqueMemberID
WHERE TRIM(d.GenderCode) IN ("M","F")
GROUP BY a.UniqueMemberID
  , b.ModelCategory
  , c.ModelVersion
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_J_MetalScoresPivoted AS (
SELECT UniqueMemberID
  , ModelCategory
  , SUM(CASE WHEN ModelVersion = "Platinum"     THEN TotalScore ELSE 0 END) AS PlatinumTotalScore
  , SUM(CASE WHEN ModelVersion = "Gold"         THEN TotalScore ELSE 0 END) AS GoldTotalScore
  , SUM(CASE WHEN ModelVersion = "Silver"       THEN TotalScore ELSE 0 END) AS SilverTotalScore
  , SUM(CASE WHEN ModelVersion = "Bronze"       THEN TotalScore ELSE 0 END) AS BronzeTotalScore
  , SUM(CASE WHEN ModelVersion = "Catastrophic" THEN TotalScore ELSE 0 END) AS CatastrophicTotalScore
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_I_MetalScores
GROUP BY UniqueMemberID
  , ModelCategory
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_scores AS (
SELECT * 
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_J_MetalScoresPivoted
)


SELECT AVG(SilverTotalScore)
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_scores


DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Claims
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_diagnosis
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_Person
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_A_IdentifyModelCategory
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_B_Diag
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_C_HCC
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_D_HCC
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_Age
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_F_Group
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_E_AgeEdits
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_G_HCC
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_H_Group
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_I_MetalScores
DROP TABLE IF EXISTS INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_tmp_J_MetalScoresPivoted

