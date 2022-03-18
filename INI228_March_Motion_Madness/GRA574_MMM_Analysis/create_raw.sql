CREATE OR REPLACE TABLE INV_motion.GRA574MMM_raw AS 

SELECT 
 mmbr.src_member_signup_data_id
,mmbr.savvy_id
,mmbr.src_member_id 
,mmbr.gender
,EXTRACT(YEAR FROM mmbr.birth_date) birth_year
,mmbr.zip_cd
,ps.full_dt program_start_dt
,pe.full_dt program_end_dt
,g.program_name
,g.program_rule_name
,g.company_name
,g.group_name
,fg.dependent_cd
,rl.incentive_rule_id
,rl.rule_name
,rl.rule_desc
,rl.reqd_steps_min
,rl.reqd_minutes
,rl.incentive_amount pot_incentive_amount
,rl.incentive_points pot_incentive_points
,rl.reqd_bouts
,rl.mins_between_bouts
,dt.full_dt step_day
,CASE WHEN EXTRACT(DAYOFWEEK FROM dt.full_dt) = 1 THEN 6
      WHEN EXTRACT(DAYOFWEEK FROM dt.full_dt) = 2 THEN 7 
      ELSE EXTRACT(DAYOFWEEK FROM dt.full_dt) -2 END tmp_dow
,fsd.earned_amount
,fsd.earned_points
,fsd.total_steps
,fsd.total_bouts
,fsd.achieved_flag
,fsd.counted_flag
,fsd.miles

FROM Motion.dim_participant mmbr
  LEFT JOIN Motion.fact_group fg ON mmbr.savvy_id = fg.savvy_id
    JOIN Motion.dim_group g ON fg.group_id = g.group_id
    JOIN Motion.dim_date ps ON mmbr.program_start_dt_id = ps.dt_id
    JOIN Motion.dim_date pe ON mmbr.program_end_dt_id = pe.dt_id
  LEFT JOIN Motion.fact_step_day fsd ON mmbr.savvy_id = fsd.savvy_id
    JOIN Motion.dim_incentive_rule rl ON fsd.incentive_rule_id = rl.incentive_rule_id
    JOIN Motion.dim_date dt ON fsd.dt_id = dt.dt_id
    
WHERE lower(g.program_rule_name) LIKE '%savvy%' --fg.group_id IN (44, 72)    
