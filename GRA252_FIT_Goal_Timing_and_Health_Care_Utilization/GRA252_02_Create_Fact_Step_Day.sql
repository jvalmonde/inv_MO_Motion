CREATE OR REPLACE TABLE INV_motion.GRA252_Fact_Step_Day AS 

WITH ttlsteps AS (SELECT motion_id enrolled_id, DATE(steps_datetime) steps_date, SUM(steps) AS steps_ttl
                  FROM INV_motion.fact_step_intraday fsi 
                  WHERE motion_id IN (SELECT enrolled_id FROM INV_motion.GRA252_Dim_Participants) AND DATE(steps_datetime) BETWEEN '2015-01-01' AND '2018-12-31'
                  GROUP BY motion_id, DATE(steps_datetime)),

     cleanfsd AS (SELECT fsd.MEMBERID enrolled_id
                        ,CAST(fsd.IncentiveDate AS DATE) IncentiveDate
                        ,SUM(CASE WHEN dir.rule_name = "Adjustment" THEN IncentiveAmount END) AS adjustment_amt
                        ,MAX(CASE WHEN dir.rule_name = "Tenacity" THEN dir.reqd_steps_min END) AS rqd_tncty_steps
                        ,MAX(CASE WHEN dir.rule_name = "Intensity" THEN dir.reqd_steps_min END) AS rqd_itnsty_steps
                        ,MAX(CASE WHEN dir.rule_name = "Intensity" THEN dir.reqd_minutes END) AS rqd_itnsty_minutes
                        ,MAX(CASE WHEN dir.rule_name = "Frequency" THEN dir.reqd_steps_min END) AS rqd_frqncy_steps
                        ,MAX(CASE WHEN dir.rule_name = "Frequency" THEN dir.reqd_minutes END) AS rqd_frqncy_minutes
                        ,MAX(CASE WHEN dir.rule_name = "Frequency" THEN dir.reqd_bouts END) AS rqd_frqncy_bouts
                        ,MAX(CASE WHEN dir.rule_name = "Frequency" THEN dir.mins_between_bouts END) AS rqd_frqncy_interval
                   FROM INV_motion.fact_member_earned_incentives fsd 
                        JOIN Motion.dim_incentive_rule dir ON fsd.LOOKUPRuleID = dir.incentive_rule_id
                   GROUP BY fsd.MEMBERID,fsd.IncentiveDate)


   SELECT mbr.enrolled_id
         ,DATE_DIFF(fsd.IncentiveDate,mbr.birth_date, DAY)/365.25 AS age
         ,mbr.gender
         ,mbr.st_cd
         ,mbr.zip_cd
         ,dt.full_date
         ,dt.year_nbr
         ,dt.month_nbr
         ,dt.day_nbr
         ,dt.year_mo
         ,dt.month_nm
         ,dt.day_nm
         ,dt.weekend_ind weekend_flag
         ,dt.holiday_ind holiday_flag
         ,fsd.adjustment_amt
         ,fsd.rqd_tncty_steps
         ,fsd.rqd_itnsty_steps
         ,fsd.rqd_itnsty_minutes
         ,fsd.rqd_frqncy_steps
         ,fsd.rqd_frqncy_minutes
         ,fsd.rqd_frqncy_bouts
         ,fsd.rqd_frqncy_interval
         ,ttlsteps.steps_ttl
         ,CASE WHEN SUM(fsd.adjustment_amt) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo) = 0
                    OR SUM(fsd.adjustment_amt) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo) > 40
                    OR SUM(fsd.adjustment_amt) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo) IS NULL 
               THEN true ELSE false END AS adj_flag
         ,CASE WHEN MAX(ttlsteps.steps_ttl) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo)>=100 THEN true ELSE false END AS dailysteps_flag
         ,CASE WHEN dt.full_date BETWEEN mbr.program_start_dt AND mbr.program_end_dt  THEN true ELSE false END AS enrolled_flag
         
          ,CASE WHEN (SUM(fsd.adjustment_amt) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo) = 0
                         OR SUM(fsd.adjustment_amt) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo) > 40
                         OR SUM(fsd.adjustment_amt) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo) IS NULL)
                     AND MAX(ttlsteps.steps_ttl) OVER (PARTITION BY mbr.enrolled_id, dt.year_mo)>=100 
                     AND dt.full_date BETWEEN mbr.program_start_dt AND mbr.program_end_dt 
                THEN true ELSE false END AS active_flag
                          
   FROM INV_motion.GRA252_Dim_Participants mbr
        JOIN cleanfsd fsd ON mbr.enrolled_id = fsd.enrolled_id
        JOIN INV_motion.GRA252_Dim_Date dt ON dt.full_date = fsd.IncentiveDate
        JOIN ttlsteps ON fsd.enrolled_id = ttlsteps.enrolled_id AND fsd.IncentiveDate = ttlsteps.steps_date
        
   WHERE fsd.IncentiveDate BETWEEN '2015-01-01' AND '2018-12-31'
