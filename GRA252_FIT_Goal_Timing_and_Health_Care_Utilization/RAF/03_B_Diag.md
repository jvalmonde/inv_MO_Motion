> #### Author: Susan Mehle
> #### Description: Prepare dataset for Diagnosis Lookup for the appropriate ModelCategoryID for a member based on input.
> ####  Other Code
>   * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spRAFDiagInput]
> 
> #####  Input
>   * research-00: INV_motion.tmp_A_IdentifyModelCategory
>   * research-00: INV_motion.GRA252_raf_diagnosis
>   * research-00: INV_motion.GRA252_raf_Person
> 
> ####  Output
>   * research-00: INV_motion.tmp_B_Diag

```SQL
CREATE OR REPLACE TABLE INV_motion.tmp_B_Diag AS

WITH b AS (SELECT DISTINCT UniqueMemberID, ICDCd FROM INV_motion.GRA252_raf_diagnosis)

SELECT DISTINCT							
       a.UniqueMemberID							
      ,a.ModelCategoryID							
      ,b.ICDCd
      ,c.age AgeAtDiagnosis						
      ,c.age + 1 AgeLast							
      ,c.gender GenderCd				

      FROM INV_motion.tmp_A_IdentifyModelCategory a							
          INNER JOIN b on a.UniqueMemberID = b.UniqueMemberID				
          INNER JOIN INV_motion.GRA252_raf_Person c on c.UniqueMemberID = a.UniqueMemberID				
      WHERE TRIM(UPPER(c.gender)) IN ("M","F");    
```
