/*UHC FitBit CHOS Data
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */


--Pulling Consumer Health Ownership Segmentation (CHOS) fields
--matching to our main population
--(Not shown here is the update to the main table of each field)

SELECT
	a.Indv_Sys_Id
	,a.MM_2016
	,a.MM_2017
	,b.HEALTH_CONTINUUM_RANK
	,b.HEALTH_CONTINUUM_NAME
	,b.ENGAGEMENT_SCORE
	,b.NBR_MONTHS_UHC_INSURED
	,b.NOTSCOREDREASON
	,b.HEALTH_CONTINUUM_PRED
	,b.ENGAGEMENT_SCORE_PRED
	,b.ENGAGEMENT_BUCKET_2X2
	,b.VALUE_BUCKET_2X2
	,b.ADHERENCE_SCORE
	,b.LIFESTYLE_SCORE
	,b.OPTUM_ENGAGEMENT_SCORE
	,b.[ALGORITHM]
	INTO pdb_UHCEmails..CHOS_Data
	FROM CHOS..VW_CHOS_V2 b
	RIGHT JOIN pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
	ON a.Indv_Sys_Id = b.Indv_Id
	ORDER BY a.Indv_Sys_Id