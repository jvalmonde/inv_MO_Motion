/*UHC FitBit RAF Score Preparation and Calculations
Author: Lindsay Nelson
Initiative: Motion
Sprint: UHC Fitbit Exploration and Analysis
Nov 2018 */

--In order to execute the RAF calculator program, you need to create two 
--input tables: one with cleaned claims data and the other with person level info
--the code below runs through creating both input tables for 2016 and 2017 separately to 
--use for later RAF calculator stored procedure execution.

--SECTION 1 Create tables for and execute the Eligible Encounter Claims stored procedure program
--NOTE: 2016 AND 2017 Claims Data were done separately

--2016 START
--Step 1: Creating temp table to store Mem_Cont_2017_HPDM_NewPop with 12 months continuous
--membership in 2016

SELECT a.*
,b.MM_2016
INTO #TempContinuous2016
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
JOIN MiniHPDM.dbo.Dim_Member b
ON a.Indv_Sys_Id = b.Indv_Sys_Id
WHERE b.MM_2016 = 12
ORDER BY a.Indv_Sys_Id

CREATE UNIQUE INDEX ixInd_Sys_ID on #TempContinuous2016(Indv_Sys_Id)

--Step 2 = Pull claims for Primary Diagnosis codes for 2016 MM population
--(for later union to other diagnosis code tables)

SELECT
	a.Indv_Sys_Id AS UniqueMemberID
	,d.DIAG_CD AS ICDCd
	,d.ICD_VER_CD AS IcdVerCd
	,c.FULL_DT AS DiagnosisServiceDate
	,e.PROC_CD AS ProcCd
	,case when (f.Bil_Typ_Cd) IS NOT NULL then f.Bil_Typ_Cd 
		else NULL 
		end as BillTypeCode
	INTO pdb_UHCEmails.dbo.NewPop_Diag1_2016
	FROM #TempContinuous2016 a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN MiniHPDM..Dim_Diagnosis_Code d
	ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
	JOIN MiniHPDM..Dim_Procedure_Code e
	ON b.Proc_Cd_Sys_Id = e.PROC_CD_SYS_ID
	JOIN MiniHPDM..Dim_Bill_Type_Code f
	ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id 
	WHERE c.YEAR_NBR = '2016'
	AND d.ICD_VER_CD >= '0'

	ORDER BY a.Indv_Sys_Id, d.DIAG_CD, c.FULL_DT

--Step 3  = Pull claims for Secondary Diagnosis codes for 2016 MM population
--(for later union to other diagnosis code tables)

SELECT
	a.Indv_Sys_Id AS UniqueMemberID
	,d.DIAG_CD AS ICDCd
	,d.ICD_VER_CD AS IcdVerCd
	,c.FULL_DT AS DiagnosisServiceDate
	,e.PROC_CD AS ProcCd
	,case when (f.Bil_Typ_Cd) IS NOT NULL then f.Bil_Typ_Cd 
		else NULL 
		end as BillTypeCode
	INTO pdb_UHCEmails.dbo.NewPop_Diag2_2016
	FROM #TempContinuous2016 a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN MiniHPDM..Dim_Diagnosis_Code d
	ON d.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
	JOIN MiniHPDM..Dim_Procedure_Code e
	ON b.Proc_Cd_Sys_Id = e.PROC_CD_SYS_ID
	JOIN MiniHPDM..Dim_Bill_Type_Code f
	ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id 
	WHERE c.YEAR_NBR = '2016'
	AND d.ICD_VER_CD >= '0'
	ORDER BY a.Indv_Sys_Id, d.DIAG_CD, c.FULL_DT

--Step 4  = Pull claims for Tertiary Diagnosis codes for 2016 MM population
--(for later union to other diagnosis code tables)	

SELECT
	a.Indv_Sys_Id AS UniqueMemberID
	,d.DIAG_CD AS ICDCd
	,d.ICD_VER_CD AS IcdVerCd
	,c.FULL_DT AS DiagnosisServiceDate
	,e.PROC_CD AS ProcCd
	,case when (f.Bil_Typ_Cd) IS NOT NULL then f.Bil_Typ_Cd 
		else NULL 
		end as BillTypeCode
	INTO pdb_UHCEmails.dbo.NewPop_Diag3_2016
	FROM #TempContinuous2016 a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN MiniHPDM..Dim_Diagnosis_Code d
	ON d.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
	JOIN MiniHPDM..Dim_Procedure_Code e
	ON b.Proc_Cd_Sys_Id = e.PROC_CD_SYS_ID
	JOIN MiniHPDM..Dim_Bill_Type_Code f
	ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id 
	WHERE c.YEAR_NBR = '2016'
	AND d.ICD_VER_CD >= '0'

	ORDER BY a.Indv_Sys_Id, c.FULL_DT

--JOINING ALL 2016 Claims Diagnosis Data for Claims Cleaning Program---

SELECT *
INTO pdb_UHCEmails.dbo.NewPop_AllUniqDiag_2016
FROM pdb_UHCEmails..NewPop_Diag1_2016

UNION

SELECT *
FROM pdb_UHCEmails..NewPop_Diag2_2016

UNION
SELECT *
FROM pdb_UHCEmails..NewPop_Diag3_2016


SELECT * FROM
pdb_UHCEmails..NewPop_AllUniqDiag_2016
ORDER BY UniqueMemberID,  ICDCd, DiagnosisServiceDate 

--Used the following stored procedure on both 'NewPop_AllUniq_Diag_YYYY' files 
--to "clean" the diagnosis tables for 2016 and 2017 to prep
--them for the RAF score calculator
EXEC [RA_Commercial_2016].[dbo].[spEligEncounterLogic_TEST]
	 @InputClaimsTable = 'pdb_UHCEmails.dbo.NewPop_AllUniqDiag_2016'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase ='pdb_UHCEmails'
	,@OutputSuffix ='NewPop_Clean2016'

--New table produced = pdb_UHCEmails.dbo.Diagnosis_NewPop_Clean2016


--SECTION 2 Create tables for Person Level input file in preparation for
--use in the RAF stored procedure program
--NOTE: 2016 AND 2017 Person_Level tables were created separately

--Since I didn't have access to DOB, I created a variable based on today's date minus age to 
--get an estimated DOB for the RAF calculator
--AgeLast reflects the approx. age of individual at the time of diagnosis/claim

--Step 1) Creating 2016 Person table for RAF calculator
SELECT
	P.Indv_Sys_Id AS UniqueMemberID
	,P.Gdr_Cd AS GenderCd
	,(DATEADD(YEAR,-P.Age,CONVERT(DATE,GETDATE()))) AS BirthDate
	--,(DATEADD(YEAR,-P.Age,CONVERT(DATE,'2018-01-01'))) AS BirthDate2
	,P.Age-1 AS AgeLast
	,'S' AS Metal
	, 0 AS CSR_INDICATOR

INTO pdb_UHCEmails.dbo.PersonRAF2016

FROM #TempContinuous2016 P
ORDER BY P.Indv_Sys_Id

--SECTION 3 --Executing RAF calculator on 2016 Claims and Person tables
--In this section I took the two new tables
--pdb_UHCEmails.dbo.Diagnosis_NewPop_Clean2016 AND 
--pdb_UHCEmails.dbo.PersonRAF2016
--And executed the RAF Commercial 2016 stored procedure to calculate RAF Scores

EXEC [RA_Commercial_2016].[dbo].[spRAFDiagInput]
	 @InputPersonTable = 'pdb_UHCEmails.dbo.PersonRAF2016'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = 'pdb_UHCEmails.dbo.Diagnosis_NewPop_Clean2016'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_UHCEmails'
	,@OutputSuffix = 'LN2_2016'

--This produced the following output tables containing the RAF scores:
--pdb_UHCEmails..RA_Com_I_Metal_Scores_LN2_2016
--pdb_UHCEmails..RA_Com_J_MetalScoresPivoted_LN2_2016
--pdb_UHCEmails..RA_Com_K_ModelTerams_LN2_2016

--SECTION 4 --Final step for RAF was to create a new table for the RAF scores and HCC 
--fields per data requirements. FINAL TABLE = pdb_UHCEmails.dbo.MM2016_RAF

SELECT 
a.Indv_Sys_Id
,b.UniqueMemberID
,b.SilverTotalScore
INTO #TempRAFTable
FROM [dbo].[Mem_Cont_2017_HPDM_NewPop_MM2016] a
LEFT JOIN [dbo].[RA_Com_J_MetalScoresPivoted_LN2_2016] b 
ON b.UniqueMemberID = a.Indv_Sys_Id
ORDER BY a.Indv_Sys_Id

SELECT * FROM #TempRAFTable


SELECT
 a.Indv_Sys_Id
 ,a.SilverTotalScore
,HCC001 = max(case when b.Term = 'HCC001' then 1 else 0 end)
,HCC002= MAX(CASE WHEN b.Term = 'HCC002' then 1 else 0 end)
,HCC003= MAX(CASE WHEN b.Term = 'HCC003' then 1 else 0 end)
,HCC004= MAX(CASE WHEN b.Term = 'HCC004' then 1 else 0 end)
,HCC006= MAX(CASE WHEN b.Term = 'HCC006' then 1 else 0 end)
,HCC008= MAX(CASE WHEN b.Term = 'HCC008' then 1 else 0 end)
,HCC009= MAX(CASE WHEN b.Term = 'HCC009' then 1 else 0 end)
,HCC010= MAX(CASE WHEN b.Term = 'HCC010' then 1 else 0 end)
,HCC011= MAX(CASE WHEN b.Term = 'HCC011' then 1 else 0 end)
,HCC012= MAX(CASE WHEN b.Term = 'HCC012' then 1 else 0 end)
,HCC013= MAX(CASE WHEN b.Term = 'HCC013' then 1 else 0 end)
,HCC018= MAX(CASE WHEN b.Term = 'HCC018' then 1 else 0 end)
,HCC019= MAX(CASE WHEN b.Term = 'HCC019' then 1 else 0 end)
,HCC020= MAX(CASE WHEN b.Term = 'HCC020' then 1 else 0 end)
,HCC021= MAX(CASE WHEN b.Term = 'HCC021' then 1 else 0 end)
,HCC023= MAX(CASE WHEN b.Term = 'HCC023' then 1 else 0 end)
,HCC026= MAX(CASE WHEN b.Term = 'HCC026' then 1 else 0 end)
,HCC027= MAX(CASE WHEN b.Term = 'HCC027' then 1 else 0 end)
,HCC028= MAX(CASE WHEN b.Term = 'HCC028' then 1 else 0 end)
,HCC029= MAX(CASE WHEN b.Term = 'HCC029' then 1 else 0 end)
,HCC030= MAX(CASE WHEN b.Term = 'HCC030' then 1 else 0 end)
,HCC034= MAX(CASE WHEN b.Term = 'HCC034' then 1 else 0 end)
,HCC035= MAX(CASE WHEN b.Term = 'HCC035' then 1 else 0 end)
,HCC036= MAX(CASE WHEN b.Term = 'HCC036' then 1 else 0 end)
,HCC037= MAX(CASE WHEN b.Term = 'HCC037' then 1 else 0 end)
,HCC038= MAX(CASE WHEN b.Term = 'HCC038' then 1 else 0 end)
,HCC041= MAX(CASE WHEN b.Term = 'HCC041' then 1 else 0 end)
,HCC042= MAX(CASE WHEN b.Term = 'HCC042' then 1 else 0 end)
,HCC045= MAX(CASE WHEN b.Term = 'HCC045' then 1 else 0 end)
,HCC046= MAX(CASE WHEN b.Term = 'HCC046' then 1 else 0 end)
,HCC047= MAX(CASE WHEN b.Term = 'HCC047' then 1 else 0 end)
,HCC048= MAX(CASE WHEN b.Term = 'HCC048' then 1 else 0 end)
,HCC054= MAX(CASE WHEN b.Term = 'HCC054' then 1 else 0 end)
,HCC055= MAX(CASE WHEN b.Term = 'HCC055' then 1 else 0 end)
,HCC056= MAX(CASE WHEN b.Term = 'HCC056' then 1 else 0 end)
,HCC057= MAX(CASE WHEN b.Term = 'HCC057' then 1 else 0 end)
,HCC061= MAX(CASE WHEN b.Term = 'HCC061' then 1 else 0 end)
,HCC062= MAX(CASE WHEN b.Term = 'HCC062' then 1 else 0 end)
,HCC063= MAX(CASE WHEN b.Term = 'HCC063' then 1 else 0 end)
,HCC064= MAX(CASE WHEN b.Term = 'HCC064' then 1 else 0 end)
,HCC066= MAX(CASE WHEN b.Term = 'HCC066' then 1 else 0 end)
,HCC067= MAX(CASE WHEN b.Term = 'HCC067' then 1 else 0 end)
,HCC068= MAX(CASE WHEN b.Term = 'HCC068' then 1 else 0 end)
,HCC069= MAX(CASE WHEN b.Term = 'HCC069' then 1 else 0 end)
,HCC070= MAX(CASE WHEN b.Term = 'HCC070' then 1 else 0 end)
,HCC071= MAX(CASE WHEN b.Term = 'HCC071' then 1 else 0 end)
,HCC073= MAX(CASE WHEN b.Term = 'HCC073' then 1 else 0 end)
,HCC074= MAX(CASE WHEN b.Term = 'HCC074' then 1 else 0 end)
,HCC075= MAX(CASE WHEN b.Term = 'HCC075' then 1 else 0 end)
,HCC081= MAX(CASE WHEN b.Term = 'HCC081' then 1 else 0 end)
,HCC082= MAX(CASE WHEN b.Term = 'HCC082' then 1 else 0 end)
,HCC087= MAX(CASE WHEN b.Term = 'HCC087' then 1 else 0 end)
,HCC088= MAX(CASE WHEN b.Term = 'HCC088' then 1 else 0 end)
,HCC089= MAX(CASE WHEN b.Term = 'HCC089' then 1 else 0 end)
,HCC090= MAX(CASE WHEN b.Term = 'HCC090' then 1 else 0 end)
,HCC094= MAX(CASE WHEN b.Term = 'HCC094' then 1 else 0 end)
,HCC096= MAX(CASE WHEN b.Term = 'HCC096' then 1 else 0 end)
,HCC097= MAX(CASE WHEN b.Term = 'HCC097' then 1 else 0 end)
,HCC102= MAX(CASE WHEN b.Term = 'HCC102' then 1 else 0 end)
,HCC103= MAX(CASE WHEN b.Term = 'HCC103' then 1 else 0 end)
,HCC106= MAX(CASE WHEN b.Term = 'HCC106' then 1 else 0 end)
,HCC107= MAX(CASE WHEN b.Term = 'HCC107' then 1 else 0 end)
,HCC108= MAX(CASE WHEN b.Term = 'HCC108' then 1 else 0 end)
,HCC109= MAX(CASE WHEN b.Term = 'HCC109' then 1 else 0 end)
,HCC110= MAX(CASE WHEN b.Term = 'HCC110' then 1 else 0 end)
,HCC111= MAX(CASE WHEN b.Term = 'HCC111' then 1 else 0 end)
,HCC112= MAX(CASE WHEN b.Term = 'HCC112' then 1 else 0 end)
,HCC113= MAX(CASE WHEN b.Term = 'HCC113' then 1 else 0 end)
,HCC114= MAX(CASE WHEN b.Term = 'HCC114' then 1 else 0 end)
,HCC115= MAX(CASE WHEN b.Term = 'HCC115' then 1 else 0 end)
,HCC117= MAX(CASE WHEN b.Term = 'HCC117' then 1 else 0 end)
,HCC118= MAX(CASE WHEN b.Term = 'HCC118' then 1 else 0 end)
,HCC119= MAX(CASE WHEN b.Term = 'HCC119' then 1 else 0 end)
,HCC120= MAX(CASE WHEN b.Term = 'HCC120' then 1 else 0 end)
,HCC121= MAX(CASE WHEN b.Term = 'HCC121' then 1 else 0 end)
,HCC122= MAX(CASE WHEN b.Term = 'HCC122' then 1 else 0 end)
,HCC125= MAX(CASE WHEN b.Term = 'HCC125' then 1 else 0 end)
,HCC126= MAX(CASE WHEN b.Term = 'HCC126' then 1 else 0 end)
,HCC127= MAX(CASE WHEN b.Term = 'HCC127' then 1 else 0 end)
,HCC128= MAX(CASE WHEN b.Term = 'HCC128' then 1 else 0 end)
,HCC129= MAX(CASE WHEN b.Term = 'HCC129' then 1 else 0 end)
,HCC130= MAX(CASE WHEN b.Term = 'HCC130' then 1 else 0 end)
,HCC131= MAX(CASE WHEN b.Term = 'HCC131' then 1 else 0 end)
,HCC132= MAX(CASE WHEN b.Term = 'HCC132' then 1 else 0 end)
,HCC135= MAX(CASE WHEN b.Term = 'HCC135' then 1 else 0 end)
,HCC137= MAX(CASE WHEN b.Term = 'HCC137' then 1 else 0 end)
,HCC138= MAX(CASE WHEN b.Term = 'HCC138' then 1 else 0 end)
,HCC139= MAX(CASE WHEN b.Term = 'HCC139' then 1 else 0 end)
,HCC142= MAX(CASE WHEN b.Term = 'HCC142' then 1 else 0 end)
,HCC145= MAX(CASE WHEN b.Term = 'HCC145' then 1 else 0 end)
,HCC146= MAX(CASE WHEN b.Term = 'HCC146' then 1 else 0 end)
,HCC149= MAX(CASE WHEN b.Term = 'HCC149' then 1 else 0 end)
,HCC150= MAX(CASE WHEN b.Term = 'HCC150' then 1 else 0 end)
,HCC151= MAX(CASE WHEN b.Term = 'HCC151' then 1 else 0 end)
,HCC153= MAX(CASE WHEN b.Term = 'HCC153' then 1 else 0 end)
,HCC154= MAX(CASE WHEN b.Term = 'HCC154' then 1 else 0 end)
,HCC156= MAX(CASE WHEN b.Term = 'HCC156' then 1 else 0 end)
,HCC158= MAX(CASE WHEN b.Term = 'HCC158' then 1 else 0 end)
,HCC159= MAX(CASE WHEN b.Term = 'HCC159' then 1 else 0 end)
,HCC160= MAX(CASE WHEN b.Term = 'HCC160' then 1 else 0 end)
,HCC161= MAX(CASE WHEN b.Term = 'HCC161' then 1 else 0 end)
,HCC162= MAX(CASE WHEN b.Term = 'HCC162' then 1 else 0 end)
,HCC163= MAX(CASE WHEN b.Term = 'HCC163' then 1 else 0 end)
,HCC183= MAX(CASE WHEN b.Term = 'HCC183' then 1 else 0 end)
,HCC184= MAX(CASE WHEN b.Term = 'HCC184' then 1 else 0 end)
,HCC187= MAX(CASE WHEN b.Term = 'HCC187' then 1 else 0 end)
,HCC188= MAX(CASE WHEN b.Term = 'HCC188' then 1 else 0 end)
,HCC203= MAX(CASE WHEN b.Term = 'HCC203' then 1 else 0 end)
,HCC204= MAX(CASE WHEN b.Term = 'HCC204' then 1 else 0 end)
,HCC205= MAX(CASE WHEN b.Term = 'HCC205' then 1 else 0 end)
,HCC207= MAX(CASE WHEN b.Term = 'HCC207' then 1 else 0 end)
,HCC208= MAX(CASE WHEN b.Term = 'HCC208' then 1 else 0 end)
,HCC209= MAX(CASE WHEN b.Term = 'HCC209' then 1 else 0 end)
,HCC217= MAX(CASE WHEN b.Term = 'HCC217' then 1 else 0 end)
,HCC226= MAX(CASE WHEN b.Term = 'HCC226' then 1 else 0 end)
,HCC227= MAX(CASE WHEN b.Term = 'HCC227' then 1 else 0 end)
,HCC242= MAX(CASE WHEN b.Term = 'HCC242' then 1 else 0 end)
,HCC243= MAX(CASE WHEN b.Term = 'HCC243' then 1 else 0 end)
,HCC244= MAX(CASE WHEN b.Term = 'HCC244' then 1 else 0 end)
,HCC245= MAX(CASE WHEN b.Term = 'HCC245' then 1 else 0 end)
,HCC246= MAX(CASE WHEN b.Term = 'HCC246' then 1 else 0 end)
,HCC247= MAX(CASE WHEN b.Term = 'HCC247' then 1 else 0 end)
,HCC248= MAX(CASE WHEN b.Term = 'HCC248' then 1 else 0 end)
,HCC249= MAX(CASE WHEN b.Term = 'HCC249' then 1 else 0 end)
,HCC251= MAX(CASE WHEN b.Term = 'HCC251' then 1 else 0 end)
,HCC253= MAX(CASE WHEN b.Term = 'HCC253' then 1 else 0 end)
,HCC254= MAX(CASE WHEN b.Term = 'HCC254' then 1 else 0 end)
,AGE1_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY1' then 1 else 0 end)
,AGE1_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY2' then 1 else 0 end)
,AGE1_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY3' then 1 else 0 end)
,AGE1_X_SEVERITY4 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY4' then 1 else 0 end)
,AGE1_X_SEVERITY5 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY5' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY1' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY2' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY3' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY4 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY4' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY5 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY5' then 1 else 0 end)
,G01= MAX(CASE WHEN b.Term = 'G01' then 1 else 0 end)
,G02= MAX(CASE WHEN b.Term = 'G02' then 1 else 0 end)
,G02A= MAX(CASE WHEN b.Term = 'G02A' then 1 else 0 end)
,G03= MAX(CASE WHEN b.Term = 'G03' then 1 else 0 end)
,G04= MAX(CASE WHEN b.Term = 'G04' then 1 else 0 end)
,G06= MAX(CASE WHEN b.Term = 'G06' then 1 else 0 end)
,G07= MAX(CASE WHEN b.Term = 'G07' then 1 else 0 end)
,G08= MAX(CASE WHEN b.Term = 'G08' then 1 else 0 end)
,G09= MAX(CASE WHEN b.Term = 'G09' then 1 else 0 end)
,G10= MAX(CASE WHEN b.Term = 'G10' then 1 else 0 end)
,G11= MAX(CASE WHEN b.Term = 'G11' then 1 else 0 end)
,G12= MAX(CASE WHEN b.Term = 'G12' then 1 else 0 end)
,G13= MAX(CASE WHEN b.Term = 'G13' then 1 else 0 end)
,G14= MAX(CASE WHEN b.Term = 'G14' then 1 else 0 end)
,G15= MAX(CASE WHEN b.Term = 'G15' then 1 else 0 end)
,G16= MAX(CASE WHEN b.Term = 'G16' then 1 else 0 end)
,G17= MAX(CASE WHEN b.Term = 'G17' then 1 else 0 end)
,G18= MAX(CASE WHEN b.Term = 'G18' then 1 else 0 end)
,IHCC_AGE1= MAX(CASE WHEN b.Term = 'IHCC_AGE1' then 1 else 0 end)
,IHCC_EXTREMELY_IMMATURE= MAX(CASE WHEN b.Term = 'IHCC_EXTREMELY_IMMATURE' then 1 else 0 end)
,IHCC_IMMATURE= MAX(CASE WHEN b.Term = 'IHCC_IMMATURE' then 1 else 0 end)
,IHCC_PREMATURE_MULTIPLES= MAX(CASE WHEN b.Term = 'IHCC_PREMATURE_MULTIPLES' then 1 else 0 end)
,IHCC_SEVERITY1= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY1' then 1 else 0 end)
,IHCC_SEVERITY2= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY2' then 1 else 0 end)
,IHCC_SEVERITY3= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY3' then 1 else 0 end)
,IHCC_SEVERITY4= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY4' then 1 else 0 end)
,IHCC_SEVERITY5= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY5' then 1 else 0 end)
,IHCC_TERM = MAX(CASE WHEN b.Term = 'IHCC_TERM ' then 1 else 0 end)
,IMMATURE_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY1' then 1 else 0 end)
,IMMATURE_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY2' then 1 else 0 end)
,IMMATURE_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY3' then 1 else 0 end)
,IMMATURE_X_SEVERITY4  = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY4' then 1 else 0 end)
,IMMATURE_X_SEVERITY5  = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY5' then 1 else 0 end)
,INT_GROUP_H= MAX(CASE WHEN b.Term = 'INT_GROUP_H' then 1 else 0 end)
,INT_GROUP_M= MAX(CASE WHEN b.Term = 'INT_GROUP_M' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY1= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY1' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY2= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY2' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY3= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY3' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY4= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY4' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY5= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY5' then 1 else 0 end)
,SEVERE_V3= MAX(CASE WHEN b.Term = 'SEVERE_V3' then 1 else 0 end)
,SEVERE_V3_X_G03 = MAX(CASE WHEN b.Term = 'SEVERE_V3_X_G03' then 1 else 0 end)
,SEVERE_V3_X_G06 = MAX(CASE WHEN b.Term = 'SEVERE_V3_X_G06' then 1 else 0 end)
,SEVERE_V3_X_G08 = MAX(CASE WHEN b.Term = 'SEVERE_V3_X_G08' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC006= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC006' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC008= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC008' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC009= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC009' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC010= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC010' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC035= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC035' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC038= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC038' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC115= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC115' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC135= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC135' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC145= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC145' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC153= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC153' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC154= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC154' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC163= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC163' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC253= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC253' then 1 else 0 end)
,TERM_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY1' then 1 else 0 end)
,TERM_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY2' then 1 else 0 end)
,TERM_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY3' then 1 else 0 end)
,TERM_X_SEVERITY4 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY4' then 1 else 0 end)
,TERM_X_SEVERITY5 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY5' then 1 else 0 end)

INTO pdb_UHCEmails.dbo.MM2016_RAF
FROM #TempRAFTable a
	LEFT JOIN pdb_UHCEmails.dbo.RA_Com_K_ModelTerms_LN2_2016 b
	ON a.Indv_Sys_ID = b.UniqueMemberID
	--WHERE a.Indv_Sys_ID = 16972016
	AND b.ModelVersion = 'Silver'
	AND b.UsedInCalc = 1
GROUP BY a.Indv_Sys_Id, a.SilverTotalScore
ORDER BY a.Indv_Sys_Id, a.SilverTotalScore

SELECT * FROM pdb_UHCEmails.dbo.MM2016_RAF
ORDER BY Indv_Sys_ID

--n = 366472

--2017 START

--Step 1 = Joining claims for Primary Diagnosis codes (for later union to other diagnosis code tables)
	SELECT
	a.Indv_Sys_Id AS UniqueMemberID
	,d.DIAG_CD AS ICDCd
	,d.ICD_VER_CD AS IcdVerCd
	,c.FULL_DT AS DiagnosisServiceDate
	,e.PROC_CD AS ProcCd
	,case when (f.Bil_Typ_Cd) IS NOT NULL then f.Bil_Typ_Cd 
		else NULL 
		end as BillTypeCode
    INTO pdb_UHCEmails.dbo.NewPop_Diag1_2017
	FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN MiniHPDM..Dim_Diagnosis_Code d
	ON d.DIAG_CD_SYS_ID = b.Diag_1_Cd_Sys_Id
	JOIN MiniHPDM..Dim_Procedure_Code e
	ON b.Proc_Cd_Sys_Id = e.PROC_CD_SYS_ID
	JOIN MiniHPDM..Dim_Bill_Type_Code f
	ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id 
	WHERE c.YEAR_NBR = '2017'
	AND d.ICD_VER_CD >= '0'
	ORDER BY a.Indv_Sys_Id, d.DIAG_CD, c.FULL_DT

--Step 2  = Joining claims for Secondary Diagnosis codes (for later union to other diagnosis code tables)
	SELECT
	a.Indv_Sys_Id AS UniqueMemberID
	,d.DIAG_CD AS ICDCd
	,d.ICD_VER_CD AS IcdVerCd
	,c.FULL_DT AS DiagnosisServiceDate
	,e.PROC_CD AS ProcCd
	,case when (f.Bil_Typ_Cd) IS NOT NULL then f.Bil_Typ_Cd 
		else NULL 
		end as BillTypeCode
	INTO pdb_UHCEmails.dbo.NewPop_Diag2_2017
	FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN MiniHPDM..Dim_Diagnosis_Code d
	ON d.DIAG_CD_SYS_ID = b.Diag_2_Cd_Sys_Id
	JOIN MiniHPDM..Dim_Procedure_Code e
	ON b.Proc_Cd_Sys_Id = e.PROC_CD_SYS_ID
	JOIN MiniHPDM..Dim_Bill_Type_Code f
	ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id 
	WHERE c.YEAR_NBR = '2017'
	AND d.ICD_VER_CD  >= '0'
	ORDER BY a.Indv_Sys_Id, d.DIAG_CD, c.FULL_DT
	
--Step 3  = Joining claims for Tertiary Diagnosis codes (for later union to other diagnosis code tables)	

	SELECT
	a.Indv_Sys_Id AS UniqueMemberID
	,d.DIAG_CD AS ICDCd
	,d.ICD_VER_CD AS IcdVerCd
	,c.FULL_DT AS DiagnosisServiceDate
	,e.PROC_CD AS ProcCd
	,case when (f.Bil_Typ_Cd) IS NOT NULL then f.Bil_Typ_Cd 
		else NULL 
		end as BillTypeCode
	INTO pdb_UHCEmails.dbo.NewPop_Diag3_2017
	FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop a
	JOIN MiniHPDM..Fact_Claims b
	ON a.Indv_Sys_Id = b.Indv_Sys_Id
	JOIN MiniHPDM..Dim_Date c
	ON c.DT_SYS_ID = b.Dt_Sys_Id
	JOIN MiniHPDM..Dim_Diagnosis_Code d
	ON d.DIAG_CD_SYS_ID = b.Diag_3_Cd_Sys_Id
	JOIN MiniHPDM..Dim_Procedure_Code e
	ON b.Proc_Cd_Sys_Id = e.PROC_CD_SYS_ID
	JOIN MiniHPDM..Dim_Bill_Type_Code f
	ON b.Bil_Typ_Cd_Sys_Id = f.Bil_Typ_Cd_Sys_Id 
	WHERE c.YEAR_NBR = '2017'
	AND d.ICD_VER_CD  >= '0'

	ORDER BY a.Indv_Sys_Id, c.FULL_DT


--Step 4 - JOINING ALL 2017 Claims Diagnosis Data for Cleaning Program---


SELECT *
INTO pdb_UHCEmails.dbo.NewPop_AllUniqDiag_2017
FROM pdb_UHCEmails..NewPop_Diag1_2017

UNION

SELECT *
FROM pdb_UHCEmails..NewPop_Diag2_2017

UNION
SELECT *
FROM pdb_UHCEmails..NewPop_Diag3_2017

SELECT * 
FROM pdb_UHCEmails..NewPop_AllUniqDiag_2017
ORDER BY UniqueMemberID,  ICDCd, DiagnosisServiceDate


--Used the following stored procedure on both 'NewPop_AllUniq_Diag_YYYY' files to "clean" the diagnosis tables for 2016 and 2017 to prep
--them for the RAF score calculator
EXEC [RA_Commercial_2016].[dbo].[spEligEncounterLogic_TEST]
	 @InputClaimsTable = 'pdb_UHCEmails.dbo.NewPop_AllUniqDiag_2017'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase ='pdb_UHCEmails'
	,@OutputSuffix ='NewPop_Clean2017'


--New table produced = pdb_UHCEmails.dbo.Diagnosis_NewPop_Clean2017


--SECTION 2 Create tables for Person Level input file in preparation for
--use in the RAF stored procedure program
--NOTE: 2016 AND 2017 Person_Level tables were created separately

--Since I didn't have access to DOB, I created a variable based on today's date minus age to 
--get an estimated DOB for the RAF calculator
--AgeLast reflects the approx. age of individual at the time of diagnosis/claim

--Step 1) Creating 2017 Person table for RAF calculator

SELECT
	P.Indv_Sys_Id AS UniqueMemberID
	,P.Gdr_Cd AS GenderCd
	,(DATEADD(YEAR,-P.Age,CONVERT(DATE,GETDATE()))) AS BirthDate
	--,(DATEADD(YEAR,-P.Age,CONVERT(DATE,'2018-01-01'))) AS BirthDate2
	,P.Age AS AgeLast
	,'S' AS Metal
	, 0 AS CSR_INDICATOR

INTO pdb_UHCEmails.dbo.PersonRAF2017

FROM pdb_UHCEmails.dbo.Mem_Cont_2017_HPDM_NewPop P
ORDER BY P.Indv_Sys_Id

--SECTION 3 --Executing RAF calculator on 2016 Claims and Person tables
--In this section I took the two new tables
--pdb_UHCEmails.dbo.Diagnosis_NewPop_Clean2017 AND 
--pdb_UHCEmails.dbo.PersonRAF2017
--And executed the RAF Commercial 2016 stored procedure to calculate RAF Scores

EXEC [RA_Commercial_2016].[dbo].[spRAFDiagInput]
	 @InputPersonTable = 'pdb_UHCEmails.dbo.PersonRAF2017'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = 'pdb_UHCEmails.dbo.Diagnosis_NewPop_Clean2017'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_UHCEmails'
	,@OutputSuffix = 'LN2_2017'


--This produced the following output tables containing the RAF scores:
--pdb_UHCEmails..RA_Com_I_Metal_Scores_LN2_2017
--pdb_UHCEmails..RA_Com_J_MetalScoresPivoted_LN2_2017
--pdb_UHCEmails..RA_Com_K_ModelTerams_LN2_2017

--SECTION 4 --Final step for RAF was to create a new table for the RAF scores and HCC 
--fields per data requirements. FINAL TABLE = pdb_UHCEmails.dbo.MM2017_RAF


SELECT 
a.Indv_Sys_Id
,b.UniqueMemberID
,b.SilverTotalScore
INTO #TempRAFTable2017
FROM pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop a
LEFT JOIN pdb_UHCEmails..RA_Com_J_MetalScoresPivoted_LN2_2017 b 
ON b.UniqueMemberID = a.Indv_Sys_Id
ORDER BY a.Indv_Sys_Id

SELECT * FROM #TempRAFTable2017
ORDER BY Indv_Sys_Id



SELECT
 a.Indv_Sys_Id
 ,a.SilverTotalScore
,HCC001 = max(case when b.Term = 'HCC001' then 1 else 0 end)
,HCC002= MAX(CASE WHEN b.Term = 'HCC002' then 1 else 0 end)
,HCC003= MAX(CASE WHEN b.Term = 'HCC003' then 1 else 0 end)
,HCC004= MAX(CASE WHEN b.Term = 'HCC004' then 1 else 0 end)
,HCC006= MAX(CASE WHEN b.Term = 'HCC006' then 1 else 0 end)
,HCC008= MAX(CASE WHEN b.Term = 'HCC008' then 1 else 0 end)
,HCC009= MAX(CASE WHEN b.Term = 'HCC009' then 1 else 0 end)
,HCC010= MAX(CASE WHEN b.Term = 'HCC010' then 1 else 0 end)
,HCC011= MAX(CASE WHEN b.Term = 'HCC011' then 1 else 0 end)
,HCC012= MAX(CASE WHEN b.Term = 'HCC012' then 1 else 0 end)
,HCC013= MAX(CASE WHEN b.Term = 'HCC013' then 1 else 0 end)
,HCC018= MAX(CASE WHEN b.Term = 'HCC018' then 1 else 0 end)
,HCC019= MAX(CASE WHEN b.Term = 'HCC019' then 1 else 0 end)
,HCC020= MAX(CASE WHEN b.Term = 'HCC020' then 1 else 0 end)
,HCC021= MAX(CASE WHEN b.Term = 'HCC021' then 1 else 0 end)
,HCC023= MAX(CASE WHEN b.Term = 'HCC023' then 1 else 0 end)
,HCC026= MAX(CASE WHEN b.Term = 'HCC026' then 1 else 0 end)
,HCC027= MAX(CASE WHEN b.Term = 'HCC027' then 1 else 0 end)
,HCC028= MAX(CASE WHEN b.Term = 'HCC028' then 1 else 0 end)
,HCC029= MAX(CASE WHEN b.Term = 'HCC029' then 1 else 0 end)
,HCC030= MAX(CASE WHEN b.Term = 'HCC030' then 1 else 0 end)
,HCC034= MAX(CASE WHEN b.Term = 'HCC034' then 1 else 0 end)
,HCC035= MAX(CASE WHEN b.Term = 'HCC035' then 1 else 0 end)
,HCC036= MAX(CASE WHEN b.Term = 'HCC036' then 1 else 0 end)
,HCC037= MAX(CASE WHEN b.Term = 'HCC037' then 1 else 0 end)
,HCC038= MAX(CASE WHEN b.Term = 'HCC038' then 1 else 0 end)
,HCC041= MAX(CASE WHEN b.Term = 'HCC041' then 1 else 0 end)
,HCC042= MAX(CASE WHEN b.Term = 'HCC042' then 1 else 0 end)
,HCC045= MAX(CASE WHEN b.Term = 'HCC045' then 1 else 0 end)
,HCC046= MAX(CASE WHEN b.Term = 'HCC046' then 1 else 0 end)
,HCC047= MAX(CASE WHEN b.Term = 'HCC047' then 1 else 0 end)
,HCC048= MAX(CASE WHEN b.Term = 'HCC048' then 1 else 0 end)
,HCC054= MAX(CASE WHEN b.Term = 'HCC054' then 1 else 0 end)
,HCC055= MAX(CASE WHEN b.Term = 'HCC055' then 1 else 0 end)
,HCC056= MAX(CASE WHEN b.Term = 'HCC056' then 1 else 0 end)
,HCC057= MAX(CASE WHEN b.Term = 'HCC057' then 1 else 0 end)
,HCC061= MAX(CASE WHEN b.Term = 'HCC061' then 1 else 0 end)
,HCC062= MAX(CASE WHEN b.Term = 'HCC062' then 1 else 0 end)
,HCC063= MAX(CASE WHEN b.Term = 'HCC063' then 1 else 0 end)
,HCC064= MAX(CASE WHEN b.Term = 'HCC064' then 1 else 0 end)
,HCC066= MAX(CASE WHEN b.Term = 'HCC066' then 1 else 0 end)
,HCC067= MAX(CASE WHEN b.Term = 'HCC067' then 1 else 0 end)
,HCC068= MAX(CASE WHEN b.Term = 'HCC068' then 1 else 0 end)
,HCC069= MAX(CASE WHEN b.Term = 'HCC069' then 1 else 0 end)
,HCC070= MAX(CASE WHEN b.Term = 'HCC070' then 1 else 0 end)
,HCC071= MAX(CASE WHEN b.Term = 'HCC071' then 1 else 0 end)
,HCC073= MAX(CASE WHEN b.Term = 'HCC073' then 1 else 0 end)
,HCC074= MAX(CASE WHEN b.Term = 'HCC074' then 1 else 0 end)
,HCC075= MAX(CASE WHEN b.Term = 'HCC075' then 1 else 0 end)
,HCC081= MAX(CASE WHEN b.Term = 'HCC081' then 1 else 0 end)
,HCC082= MAX(CASE WHEN b.Term = 'HCC082' then 1 else 0 end)
,HCC087= MAX(CASE WHEN b.Term = 'HCC087' then 1 else 0 end)
,HCC088= MAX(CASE WHEN b.Term = 'HCC088' then 1 else 0 end)
,HCC089= MAX(CASE WHEN b.Term = 'HCC089' then 1 else 0 end)
,HCC090= MAX(CASE WHEN b.Term = 'HCC090' then 1 else 0 end)
,HCC094= MAX(CASE WHEN b.Term = 'HCC094' then 1 else 0 end)
,HCC096= MAX(CASE WHEN b.Term = 'HCC096' then 1 else 0 end)
,HCC097= MAX(CASE WHEN b.Term = 'HCC097' then 1 else 0 end)
,HCC102= MAX(CASE WHEN b.Term = 'HCC102' then 1 else 0 end)
,HCC103= MAX(CASE WHEN b.Term = 'HCC103' then 1 else 0 end)
,HCC106= MAX(CASE WHEN b.Term = 'HCC106' then 1 else 0 end)
,HCC107= MAX(CASE WHEN b.Term = 'HCC107' then 1 else 0 end)
,HCC108= MAX(CASE WHEN b.Term = 'HCC108' then 1 else 0 end)
,HCC109= MAX(CASE WHEN b.Term = 'HCC109' then 1 else 0 end)
,HCC110= MAX(CASE WHEN b.Term = 'HCC110' then 1 else 0 end)
,HCC111= MAX(CASE WHEN b.Term = 'HCC111' then 1 else 0 end)
,HCC112= MAX(CASE WHEN b.Term = 'HCC112' then 1 else 0 end)
,HCC113= MAX(CASE WHEN b.Term = 'HCC113' then 1 else 0 end)
,HCC114= MAX(CASE WHEN b.Term = 'HCC114' then 1 else 0 end)
,HCC115= MAX(CASE WHEN b.Term = 'HCC115' then 1 else 0 end)
,HCC117= MAX(CASE WHEN b.Term = 'HCC117' then 1 else 0 end)
,HCC118= MAX(CASE WHEN b.Term = 'HCC118' then 1 else 0 end)
,HCC119= MAX(CASE WHEN b.Term = 'HCC119' then 1 else 0 end)
,HCC120= MAX(CASE WHEN b.Term = 'HCC120' then 1 else 0 end)
,HCC121= MAX(CASE WHEN b.Term = 'HCC121' then 1 else 0 end)
,HCC122= MAX(CASE WHEN b.Term = 'HCC122' then 1 else 0 end)
,HCC125= MAX(CASE WHEN b.Term = 'HCC125' then 1 else 0 end)
,HCC126= MAX(CASE WHEN b.Term = 'HCC126' then 1 else 0 end)
,HCC127= MAX(CASE WHEN b.Term = 'HCC127' then 1 else 0 end)
,HCC128= MAX(CASE WHEN b.Term = 'HCC128' then 1 else 0 end)
,HCC129= MAX(CASE WHEN b.Term = 'HCC129' then 1 else 0 end)
,HCC130= MAX(CASE WHEN b.Term = 'HCC130' then 1 else 0 end)
,HCC131= MAX(CASE WHEN b.Term = 'HCC131' then 1 else 0 end)
,HCC132= MAX(CASE WHEN b.Term = 'HCC132' then 1 else 0 end)
,HCC135= MAX(CASE WHEN b.Term = 'HCC135' then 1 else 0 end)
,HCC137= MAX(CASE WHEN b.Term = 'HCC137' then 1 else 0 end)
,HCC138= MAX(CASE WHEN b.Term = 'HCC138' then 1 else 0 end)
,HCC139= MAX(CASE WHEN b.Term = 'HCC139' then 1 else 0 end)
,HCC142= MAX(CASE WHEN b.Term = 'HCC142' then 1 else 0 end)
,HCC145= MAX(CASE WHEN b.Term = 'HCC145' then 1 else 0 end)
,HCC146= MAX(CASE WHEN b.Term = 'HCC146' then 1 else 0 end)
,HCC149= MAX(CASE WHEN b.Term = 'HCC149' then 1 else 0 end)
,HCC150= MAX(CASE WHEN b.Term = 'HCC150' then 1 else 0 end)
,HCC151= MAX(CASE WHEN b.Term = 'HCC151' then 1 else 0 end)
,HCC153= MAX(CASE WHEN b.Term = 'HCC153' then 1 else 0 end)
,HCC154= MAX(CASE WHEN b.Term = 'HCC154' then 1 else 0 end)
,HCC156= MAX(CASE WHEN b.Term = 'HCC156' then 1 else 0 end)
,HCC158= MAX(CASE WHEN b.Term = 'HCC158' then 1 else 0 end)
,HCC159= MAX(CASE WHEN b.Term = 'HCC159' then 1 else 0 end)
,HCC160= MAX(CASE WHEN b.Term = 'HCC160' then 1 else 0 end)
,HCC161= MAX(CASE WHEN b.Term = 'HCC161' then 1 else 0 end)
,HCC162= MAX(CASE WHEN b.Term = 'HCC162' then 1 else 0 end)
,HCC163= MAX(CASE WHEN b.Term = 'HCC163' then 1 else 0 end)
,HCC183= MAX(CASE WHEN b.Term = 'HCC183' then 1 else 0 end)
,HCC184= MAX(CASE WHEN b.Term = 'HCC184' then 1 else 0 end)
,HCC187= MAX(CASE WHEN b.Term = 'HCC187' then 1 else 0 end)
,HCC188= MAX(CASE WHEN b.Term = 'HCC188' then 1 else 0 end)
,HCC203= MAX(CASE WHEN b.Term = 'HCC203' then 1 else 0 end)
,HCC204= MAX(CASE WHEN b.Term = 'HCC204' then 1 else 0 end)
,HCC205= MAX(CASE WHEN b.Term = 'HCC205' then 1 else 0 end)
,HCC207= MAX(CASE WHEN b.Term = 'HCC207' then 1 else 0 end)
,HCC208= MAX(CASE WHEN b.Term = 'HCC208' then 1 else 0 end)
,HCC209= MAX(CASE WHEN b.Term = 'HCC209' then 1 else 0 end)
,HCC217= MAX(CASE WHEN b.Term = 'HCC217' then 1 else 0 end)
,HCC226= MAX(CASE WHEN b.Term = 'HCC226' then 1 else 0 end)
,HCC227= MAX(CASE WHEN b.Term = 'HCC227' then 1 else 0 end)
,HCC242= MAX(CASE WHEN b.Term = 'HCC242' then 1 else 0 end)
,HCC243= MAX(CASE WHEN b.Term = 'HCC243' then 1 else 0 end)
,HCC244= MAX(CASE WHEN b.Term = 'HCC244' then 1 else 0 end)
,HCC245= MAX(CASE WHEN b.Term = 'HCC245' then 1 else 0 end)
,HCC246= MAX(CASE WHEN b.Term = 'HCC246' then 1 else 0 end)
,HCC247= MAX(CASE WHEN b.Term = 'HCC247' then 1 else 0 end)
,HCC248= MAX(CASE WHEN b.Term = 'HCC248' then 1 else 0 end)
,HCC249= MAX(CASE WHEN b.Term = 'HCC249' then 1 else 0 end)
,HCC251= MAX(CASE WHEN b.Term = 'HCC251' then 1 else 0 end)
,HCC253= MAX(CASE WHEN b.Term = 'HCC253' then 1 else 0 end)
,HCC254= MAX(CASE WHEN b.Term = 'HCC254' then 1 else 0 end)
,AGE1_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY1' then 1 else 0 end)
,AGE1_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY2' then 1 else 0 end)
,AGE1_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY3' then 1 else 0 end)
,AGE1_X_SEVERITY4 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY4' then 1 else 0 end)
,AGE1_X_SEVERITY5 = MAX(CASE WHEN b.Term = 'AGE1_X_SEVERITY5' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY1' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY2' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY3' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY4 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY4' then 1 else 0 end)
,EXTREMELY_IMMATURE_X_SEVERITY5 = MAX(CASE WHEN b.Term = 'EXTREMELY_IMMATURE_X_SEVERITY5' then 1 else 0 end)
,G01= MAX(CASE WHEN b.Term = 'G01' then 1 else 0 end)
,G02= MAX(CASE WHEN b.Term = 'G02' then 1 else 0 end)
,G02A= MAX(CASE WHEN b.Term = 'G02A' then 1 else 0 end)
,G03= MAX(CASE WHEN b.Term = 'G03' then 1 else 0 end)
,G04= MAX(CASE WHEN b.Term = 'G04' then 1 else 0 end)
,G06= MAX(CASE WHEN b.Term = 'G06' then 1 else 0 end)
,G07= MAX(CASE WHEN b.Term = 'G07' then 1 else 0 end)
,G08= MAX(CASE WHEN b.Term = 'G08' then 1 else 0 end)
,G09= MAX(CASE WHEN b.Term = 'G09' then 1 else 0 end)
,G10= MAX(CASE WHEN b.Term = 'G10' then 1 else 0 end)
,G11= MAX(CASE WHEN b.Term = 'G11' then 1 else 0 end)
,G12= MAX(CASE WHEN b.Term = 'G12' then 1 else 0 end)
,G13= MAX(CASE WHEN b.Term = 'G13' then 1 else 0 end)
,G14= MAX(CASE WHEN b.Term = 'G14' then 1 else 0 end)
,G15= MAX(CASE WHEN b.Term = 'G15' then 1 else 0 end)
,G16= MAX(CASE WHEN b.Term = 'G16' then 1 else 0 end)
,G17= MAX(CASE WHEN b.Term = 'G17' then 1 else 0 end)
,G18= MAX(CASE WHEN b.Term = 'G18' then 1 else 0 end)
,IHCC_AGE1= MAX(CASE WHEN b.Term = 'IHCC_AGE1' then 1 else 0 end)
,IHCC_EXTREMELY_IMMATURE= MAX(CASE WHEN b.Term = 'IHCC_EXTREMELY_IMMATURE' then 1 else 0 end)
,IHCC_IMMATURE= MAX(CASE WHEN b.Term = 'IHCC_IMMATURE' then 1 else 0 end)
,IHCC_PREMATURE_MULTIPLES= MAX(CASE WHEN b.Term = 'IHCC_PREMATURE_MULTIPLES' then 1 else 0 end)
,IHCC_SEVERITY1= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY1' then 1 else 0 end)
,IHCC_SEVERITY2= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY2' then 1 else 0 end)
,IHCC_SEVERITY3= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY3' then 1 else 0 end)
,IHCC_SEVERITY4= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY4' then 1 else 0 end)
,IHCC_SEVERITY5= MAX(CASE WHEN b.Term = 'IHCC_SEVERITY5' then 1 else 0 end)
,IHCC_TERM = MAX(CASE WHEN b.Term = 'IHCC_TERM ' then 1 else 0 end)
,IMMATURE_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY1' then 1 else 0 end)
,IMMATURE_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY2' then 1 else 0 end)
,IMMATURE_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY3' then 1 else 0 end)
,IMMATURE_X_SEVERITY4  = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY4' then 1 else 0 end)
,IMMATURE_X_SEVERITY5  = MAX(CASE WHEN b.Term = 'IMMATURE_X_SEVERITY5' then 1 else 0 end)
,INT_GROUP_H= MAX(CASE WHEN b.Term = 'INT_GROUP_H' then 1 else 0 end)
,INT_GROUP_M= MAX(CASE WHEN b.Term = 'INT_GROUP_M' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY1= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY1' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY2= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY2' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY3= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY3' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY4= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY4' then 1 else 0 end)
,PREMATURE_MULTIPLES_X_SEVERITY5= MAX(CASE WHEN b.Term = 'PREMATURE_MULTIPLES_X_SEVERITY5' then 1 else 0 end)
,SEVERE_V3= MAX(CASE WHEN b.Term = 'SEVERE_V3' then 1 else 0 end)
,SEVERE_V3_X_G03 = MAX(CASE WHEN b.Term = 'SEVERE_V3_X_G03' then 1 else 0 end)
,SEVERE_V3_X_G06 = MAX(CASE WHEN b.Term = 'SEVERE_V3_X_G06' then 1 else 0 end)
,SEVERE_V3_X_G08 = MAX(CASE WHEN b.Term = 'SEVERE_V3_X_G08' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC006= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC006' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC008= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC008' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC009= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC009' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC010= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC010' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC035= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC035' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC038= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC038' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC115= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC115' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC135= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC135' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC145= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC145' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC153= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC153' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC154= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC154' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC163= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC163' then 1 else 0 end)
,SEVERE_V3_X_HHS_HCC253= MAX(CASE WHEN b.Term = 'SEVERE_V3_X_HHS_HCC253' then 1 else 0 end)
,TERM_X_SEVERITY1 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY1' then 1 else 0 end)
,TERM_X_SEVERITY2 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY2' then 1 else 0 end)
,TERM_X_SEVERITY3 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY3' then 1 else 0 end)
,TERM_X_SEVERITY4 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY4' then 1 else 0 end)
,TERM_X_SEVERITY5 = MAX(CASE WHEN b.Term = 'TERM_X_SEVERITY5' then 1 else 0 end)

INTO pdb_UHCEmails.dbo.MM2017_RAF
FROM #TempRAFTable2017 a
	LEFT JOIN pdb_UHCEmails.dbo.RA_Com_K_ModelTerms_LN2_2017 b
	ON a.Indv_Sys_ID = b.UniqueMemberID
	--WHERE a.Indv_Sys_ID = 16972016
	AND b.ModelVersion = 'Silver'
	AND b.UsedInCalc = 1
GROUP BY a.Indv_Sys_Id, a.SilverTotalScore
ORDER BY a.Indv_Sys_Id, a.SilverTotalScore

SELECT * FROM pdb_UHCEmails.dbo.MM2017_RAF
ORDER BY Indv_Sys_ID
--n = 609276