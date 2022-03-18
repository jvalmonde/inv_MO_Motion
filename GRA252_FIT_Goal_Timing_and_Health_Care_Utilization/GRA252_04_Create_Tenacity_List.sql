CREATE OR REPLACE TABLE INV_motion.GRA252_Tenacity_List AS

SELECT 
 fsm.enrolled_id
,fsm.steps_date
,fsm.hour_nbr
,fsd.rqd_tncty_steps
,SUM(fsm.steps) AS ttlsteps
,MIN(CASE WHEN fsm.steps_running_ttl >= fsd.rqd_tncty_steps THEN fsm.hour_nbr ELSE NULL END) AS tenacity_met_hr

FROM INV_motion.GRA252_Fact_Step_Day fsd
     JOIN INV_motion.GRA252_Fact_Step_Minute fsm ON fsd.enrolled_id = fsm.enrolled_id AND fsd.full_date = fsm.steps_date

GROUP BY fsm.enrolled_id,fsm.steps_date,fsm.hour_nbr,fsd.rqd_tncty_steps
