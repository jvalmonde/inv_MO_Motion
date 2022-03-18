> #### Author: Susan Mehle
> #### Description: Create a table in the following format, used to calculate RAF scores:
> 1. UniqueMemberID (Person identification code). As noted, the UniqueMemberID is the name of the common person identifier variable.
>     * Character or numeric type, any length, not missing. 
>     * Unique to an individual. 
> 2. ICDCd (ICD-9-CM and ICD-10-CM diagnosis codes). 
>     * Character type, 7 byte field, no periods or embedded blanks, left justified. 
>     * Codes should be to the greatest level of available specificity.
>     * Invalid diagnoses are ignored
>     * A valid ICD-9 diagnosis must have a IcdVerCd indicating ICD-9 and a valid DiagnosisServiceDate.
>     * A valid ICD-10 diagnosis must have a IcdVerCd indicating ICD-10 and a valid DiagnosisServiceDate. 
> 3. IcdVerCd
>     * Character type, 1 byte field, 9=ICD-9, 0=ICD-10, not missing.
> 4. DiagnosisServiceDate
>     * Date data type, valid calendar date, not missing, provides the diagnosis’s service date.
> 5. ProcCd 
>     * CPT/HCPCS code associated with the claim line where the ICDCd and service date were sourced
> 6. BillTypeCode
>     * Bill type code, for professional claims where there is no bill type code the value here MUST BE NULL or the process will not work
> #### Language: SQL
> ####  Other Code
> * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spEligEncounterLogic_TEST]
> 
> #####  Input
> * research-00: INV_motion.GRA252_Key_Accounts_Characteristics
> * research-00: dm_minihpdm.fact_claims
> * research-00: dm_minihpdm.dim_date
> * research-00: dm_minihpdm.dim_diagnosis_code
> * research-00: dm_minihpdm.dim_procedure_code
> * research-00: dm_minihpdm.dim_bill_type_code
> * research-00: dm_minihpdm.summary_indv_mm
> 
> ####  Output
> * research-00: INV_motion.GRA252_raf_Claims

```SQL

CREATE OR REPLACE TABLE INV_motion.GRA252_raf_Claims AS

WITH DX1 AS (SELECT a.Indv_Sys_Id,b.Dt_Sys_Id,b.Diag_1_Cd_Sys_Id DIAG_CD_SYS_ID,b.Proc_Cd_Sys_Id,b.Bil_Typ_Cd_Sys_Id, a.birth_date dob, a.gender
             FROM INV_motion.GRA252_Dim_Participants a LEFT JOIN dm_minihpdm.fact_claims b ON a.Indv_Sys_Id = b.Indv_Sys_Id),
             
     DX2 AS (SELECT a.Indv_Sys_Id,b.Dt_Sys_Id ,b.Diag_2_Cd_Sys_Id,b.Proc_Cd_Sys_Id,b.Bil_Typ_Cd_Sys_Id, a.birth_date, a.gender
             FROM INV_motion.GRA252_Dim_Participants a LEFT JOIN dm_minihpdm.fact_claims b ON a.Indv_Sys_Id = b.Indv_Sys_Id),
             
     DX3 AS (SELECT a.Indv_Sys_Id,b.Dt_Sys_Id,b.Diag_3_Cd_Sys_Id DIAG_CD_SYS_ID,b.Proc_Cd_Sys_Id,b.Bil_Typ_Cd_Sys_Id, a.birth_date, a.gender
             FROM INV_motion.GRA252_Dim_Participants a LEFT JOIN dm_minihpdm.fact_claims b ON a.Indv_Sys_Id = b.Indv_Sys_Id),
             
     DX  AS (SELECT * FROM DX1 UNION DISTINCT SELECT * FROM DX2 UNION DISTINCT SELECT * FROM DX3)
            
     
SELECT b.Indv_Sys_Id AS UniqueMemberID
      ,TRIM(d.DIAG_CD) AS ICDCd
      ,TRIM(d.ICD_VER_CD) AS IcdVerCd
      ,b.DIAG_CD_SYS_ID
      ,c.FULL_DT AS DiagnosisServiceDate
      ,b.Proc_Cd_Sys_Id
      ,TRIM(e.PROC_CD) AS ProcCd
      ,b.dob
      ,FLOOR(DATE_DIFF(c.FULL_DT, b.dob, DAY)/365.25) age
      ,TRIM(b.gender) gender
      ,CASE WHEN TRIM(Bil_Typ_Cd) = "UNK" OR TRIM(Bil_Typ_Cd) = "" OR TRIM(Bil_Typ_Cd) IS NULL THEN NULL ELSE TRIM(Bil_Typ_Cd) END AS BillTypeCode
      ,g.mm_2015
      ,g.mm_2016
      ,g.mm_2017
      ,g.mm_2018

FROM DX b
                JOIN dm_minihpdm.dim_date c ON c.DT_SYS_ID = b.Dt_Sys_Id
                JOIN dm_minihpdm.dim_diagnosis_code d ON d.DIAG_CD_SYS_ID = b.DIAG_CD_SYS_ID
                JOIN dm_minihpdm.dim_procedure_code e ON e.PROC_CD_SYS_ID = b.Proc_Cd_Sys_Id
                LEFT JOIN dm_minihpdm.dim_bill_type_code f ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id
                LEFT JOIN dm_minihpdm.summary_indv_mm g ON b.Indv_Sys_Id = g.Indv_Sys_Id
                
WHERE (d.ICD_VER_CD = "0" OR d.ICD_VER_CD = "9") AND TRIM(d.DIAG_CD) <> ""
```
