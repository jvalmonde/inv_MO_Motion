> #### Author: Susan Mehle
> #### Description: Creates input tables that are used to calculate RAF scores for 2015
> * Diagnosis		
>   * Unique Member ID: Unique member identifier	
>   * ICDCd:	Diagnosis code (ICD-10)
>   * DiagnosisServiceDate: Date diagnosis appears on claim	
> * Person: (one row per member)			
>   * Unique Member ID: unique member identifier		
>   * GenderCd: M or F		
>   * BirthDate:		
>   * AgeLast:  Age on last date of enrollment in the year for which the RAF score is calculated
> ####  Other Code
>   * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spRAFDiagInput]
> 
> #####  Input
>   * research-00: INV_motion.GRA252_raf_Claims - Created in previous step
>   * research-00: INV_motion.raf_ProcCd2016 - These are codes from a table created in the stored procedure on NGIS
>   * research-00: INV_motion.GRA252_Dim_Participants
> 
> ####  Output
>   * research-00: INV_motion.GRA252_raf_Person
>   * research-00: INV_motion.GRA252_raf_diagnosis

```SQL
--============ raf_Person
#standardSQL

CREATE TEMP FUNCTION var(str STRING)
RETURNS STRING
LANGUAGE js AS """
  var result = {
    'theyear': '2015',
    'begindate': '2015-01-01',
    'enddate': '2015',
    'default': 'undefined'
  };
  return result[str] || result['default'];
""";

-- CREATE OR REPLACE TABLE INV_motion.GRA252_raf_Person AS
-- SELECT  p.indv_sys_id AS UniqueMemberID, p.gender, SAFE_CAST(var("theyear") AS INT64) - EXTRACT(YEAR FROM birth_date) age, "S" AS Metal, 0 AS CSR_INDICATOR, birth_date
-- FROM INV_motion.GRA252_Dim_Participants p

--============ raf_diagnosis	
CREATE OR REPLACE TABLE INV_motion.GRA252_raf_diagnosis AS 

	SELECT DISTINCT a.UniqueMemberID, IcdCd, IcdVerCd, DiagnosisServiceDate
	FROM INV_motion.GRA252_raf_Claims a
		LEFT JOIN INV_motion.raf_ProcCd2016 b ON a.ProcCd = b.ProcCd
	WHERE a.DiagnosisServiceDate BETWEEN CAST(var("begindate") AS DATE) AND CAST(var("enddate") AS DATE)
		AND (a.BillTypeCode IN ("111","117") --Inpatient
		OR (a.BillTypeCode IN ("131","137","711","717","761","767","771","777","851","857") AND b.ProcCd IS NOT NULL) --Outpatient
		OR (a.BillTypeCode IS NULL AND b.ProcCd IS NOT NULL)) --Professional

```
