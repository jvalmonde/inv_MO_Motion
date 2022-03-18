--FI KA members with continuous enrollment in 2017

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_2017 AS (
SELECT dm.Indv_Sys_Id
	, cs.cust_seg_nbr
	, gsi.grp_size_desc
FROM dm_minihpdm.dim_member AS dm
JOIN dm_minihpdm.dim_customer_segment AS cs
	ON cs.cust_seg_sys_id = dm.cust_seg_sys_id
JOIN dm_minihpdm.dim_custsegsysid AS cssi
	ON cs.cust_seg_sys_id = cssi.cust_seg_sys_id
JOIN dm_minihpdm.dim_group_indicator AS c
	ON cs.mkt_seg_cd = c.mkt_seg_cd
JOIN dm_minihpdm.dim_group_size_indicator AS gsi
	ON cs.grp_size_ind_sys_id = gsi.grp_size_ind_sys_id
WHERE mkt_seg_rllp_desc = 'KEY ACCOUNTS        '
	AND cssi.hlth_pln_fund_cd = 'FI '
  AND dm.MM_2017 = 12
)


--FI KA members with continuous enrollment in 2018

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_2018 AS (
SELECT dm.Indv_Sys_Id
	, cs.cust_seg_nbr
	, gsi.grp_size_desc
FROM dm_minihpdm.dim_member AS dm
JOIN dm_minihpdm.dim_customer_segment AS cs
	ON cs.cust_seg_sys_id = dm.cust_seg_sys_id
JOIN dm_minihpdm.dim_custsegsysid AS cssi
	ON cs.cust_seg_sys_id = cssi.cust_seg_sys_id
JOIN dm_minihpdm.dim_group_indicator AS c
	ON cs.mkt_seg_cd = c.mkt_seg_cd
JOIN dm_minihpdm.dim_group_size_indicator AS gsi
	ON cs.grp_size_ind_sys_id = gsi.grp_size_ind_sys_id
WHERE mkt_seg_rllp_desc = 'KEY ACCOUNTS        '
	AND cssi.hlth_pln_fund_cd = 'FI '
  AND dm.MM_2018 = 12
)


-- KA Members that were eligible for Motion in 2018

CREATE OR REPLACE TABLE INV_motion.NZ_ka_me_2018 AS (
SELECT CAST(Indv_Sys_Id AS INT64) AS indv_sys_id
FROM INV_motion.dim_crosswalk_members_new
WHERE TRIM(LOWER(clientname)) = "key accounts uhcm"
  AND programstartdate < '2018-07-01' AND (cancelleddatetime IS NULL OR cancelleddatetime > '2018-12-31')
GROUP BY Indv_Sys_Id
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_me_2018 AS (
SELECT a.*
FROM INV_motion.NZ_ka_fi_ce_2018 AS a
JOIN INV_motion.NZ_ka_me_2018 AS b
  ON a.indv_sys_id = b.indv_sys_id
)


CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_nme_2018 AS (
SELECT a.*
--  , rand() AS r
FROM INV_motion.NZ_ka_fi_ce_2018 AS a
LEFT JOIN INV_motion.NZ_ka_me_2018 AS b
  ON a.indv_sys_id = b.indv_sys_id
WHERE b.indv_sys_id IS NULL
ORDER BY rand()
LIMIT 500000
)


-- Combined sample

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018 AS (
SELECT a.*
	, dm.Age
	, dm.Gdr_Cd
	, dm.Sbscr_Ind
	, dm.Zip
  , dm.MM_2018
	, dm.MM_2002 + dm.MM_2003 + dm.MM_2004 + dm.MM_2005 + dm.MM_2006 + dm.MM_2007 + dm.MM_2008 + dm.MM_2009 + dm.MM_2010 + 
		dm.MM_2011 + dm.MM_2012 + dm.MM_2013 + dm.MM_2014 + dm.MM_2015 + dm.MM_2016 + dm.MM_2017 + dm.MM_2018 AS MM
	, c.ST_ABBR_CD
FROM 
(
	SELECT *
    , 1 AS MotionElig
	FROM INV_motion.NZ_ka_fi_ce_me_2018
  UNION ALL
	SELECT *
    , 0 AS MotionElig
	FROM INV_motion.NZ_ka_fi_ce_nme_2018
) AS a
	JOIN dm_minihpdm.dim_member AS dm
		ON a.Indv_Sys_Id = dm.Indv_Sys_Id
  LEFT JOIN dm_minihpdm.dim_zip AS c
    ON dm.zip = c.ZIP_CD
)


-- Utilization data in 2018

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_util AS (
SELECT mbr.Indv_Sys_Id
	, IFNULL(fc2.allw_amt, 0) AS total_allw
	, IFNULL(fc2.admit_cnt, 0) AS admit_cnt
	, IFNULL(fc2.vst_cnt, 0) AS vst_cnt
	, IFNULL(fc2.scrpt_cnt,0) AS scrpt_cnt
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018 AS mbr
LEFT JOIN (
	SELECT fc.Indv_Sys_Id 
    , SUM(fc.allw_amt) AS allw_amt
    , SUM(fc.admit_cnt) AS admit_cnt
    , SUM(fc.vst_cnt) AS vst_cnt
    , SUM(fc.scrpt_cnt) AS scrpt_cnt
	FROM dm_minihpdm.fact_claims AS fc
		JOIN dm_minihpdm.dim_date as dt
			ON fc.Dt_Sys_Id = dt.DT_SYS_ID
	WHERE dt.YEAR_NBR = 2018
  GROUP BY fc.Indv_Sys_Id
) AS fc2
	ON mbr.Indv_Sys_Id = fc2.Indv_Sys_Id
)


-- Member step data in 2018

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_steps AS (
SELECT mbr.indv_sys_id
	, IFNULL(SUM(mei.total_steps), 0) AS TotalSteps
	, IFNULL(SUM(mei.active_days), 0) AS ActiveDays
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018 AS mbr
	LEFT JOIN INV_motion.dim_crosswalk_members_new AS cm
		ON mbr.indv_sys_id = CAST(cm.indv_sys_id AS INT64)
  LEFT JOIN Motion.dim_participant AS dm
    ON cm.membersignupdataid = dm.src_member_signup_data_id
	LEFT JOIN (
		SELECT a1.savvy_id
      , SUM(a1.total_steps) AS total_steps
      , SUM(CASE WHEN a1.total_steps > 0 THEN 1 ELSE 0 END) AS active_days
		FROM Motion.fact_step_day AS a1
			JOIN Motion.dim_incentive_rule AS lr
				ON a1.incentive_rule_id = lr.incentive_rule_id
      JOIN Motion.dim_date AS dt
        ON a1.dt_id = dt.dt_id
		WHERE lr.rule_name = 'Tenacity'
			AND dt.year_nbr = 2018
    GROUP BY a1.savvy_id
	) AS mei
		ON dm.savvy_id = mei.savvy_id
GROUP BY mbr.indv_sys_id
)

SELECT DISTINCT indv_sys_id FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018


--RUN ka_mbrs_raf.sql here

CREATE OR REPLACE TABLE INV_motion.NZ_ka_fi_ce_cmbnd_2018_join AS (
SELECT a.*
  , b.total_allw
  , b.admit_cnt
  , b.vst_cnt
  , b.scrpt_cnt
  , c.TotalSteps
  , c.ActiveDays
  , d.SilverTotalScore
FROM INV_motion.NZ_ka_fi_ce_cmbnd_2018 AS a
JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_util AS b
  ON a.indv_sys_id = b.Indv_Sys_Id
JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_steps AS c
  ON a.indv_sys_id = c.indv_sys_id
LEFT JOIN INV_motion.NZ_ka_fi_ce_cmbnd_2018_raf_scores AS d
  ON a.indv_sys_id = d.UniqueMemberID
)


