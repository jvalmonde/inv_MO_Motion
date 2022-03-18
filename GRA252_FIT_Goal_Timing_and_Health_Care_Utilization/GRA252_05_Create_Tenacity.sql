CREATE OR REPLACE TABLE INV_motion.GRA252_Tenacity AS

SELECT 
 tl.enrolled_id
,tl.steps_date
,MAX(CASE WHEN tl.hour_nbr = 0 THEN tl.ttlsteps END) AS steps00
,MAX(CASE WHEN tl.hour_nbr = 1 THEN tl.ttlsteps END) AS steps01
,MAX(CASE WHEN tl.hour_nbr = 2 THEN tl.ttlsteps END) AS steps02
,MAX(CASE WHEN tl.hour_nbr = 3 THEN tl.ttlsteps END) AS steps03
,MAX(CASE WHEN tl.hour_nbr = 4 THEN tl.ttlsteps END) AS steps04
,MAX(CASE WHEN tl.hour_nbr = 5 THEN tl.ttlsteps END) AS steps05
,MAX(CASE WHEN tl.hour_nbr = 6 THEN tl.ttlsteps END) AS steps06
,MAX(CASE WHEN tl.hour_nbr = 7 THEN tl.ttlsteps END) AS steps07
,MAX(CASE WHEN tl.hour_nbr = 8 THEN tl.ttlsteps END) AS steps08
,MAX(CASE WHEN tl.hour_nbr = 9 THEN tl.ttlsteps END) AS steps09
,MAX(CASE WHEN tl.hour_nbr = 10 THEN tl.ttlsteps END) AS steps10
,MAX(CASE WHEN tl.hour_nbr = 11 THEN tl.ttlsteps END) AS steps11
,MAX(CASE WHEN tl.hour_nbr = 12 THEN tl.ttlsteps END) AS steps12
,MAX(CASE WHEN tl.hour_nbr = 13 THEN tl.ttlsteps END) AS steps13
,MAX(CASE WHEN tl.hour_nbr = 14 THEN tl.ttlsteps END) AS steps14
,MAX(CASE WHEN tl.hour_nbr = 15 THEN tl.ttlsteps END) AS steps15
,MAX(CASE WHEN tl.hour_nbr = 16 THEN tl.ttlsteps END) AS steps16
,MAX(CASE WHEN tl.hour_nbr = 17 THEN tl.ttlsteps END) AS steps17
,MAX(CASE WHEN tl.hour_nbr = 18 THEN tl.ttlsteps END) AS steps18
,MAX(CASE WHEN tl.hour_nbr = 19 THEN tl.ttlsteps END) AS steps19
,MAX(CASE WHEN tl.hour_nbr = 20 THEN tl.ttlsteps END) AS steps20
,MAX(CASE WHEN tl.hour_nbr = 21 THEN tl.ttlsteps END) AS steps21
,MAX(CASE WHEN tl.hour_nbr = 22 THEN tl.ttlsteps END) AS steps22
,MAX(CASE WHEN tl.hour_nbr = 23 THEN tl.ttlsteps END) AS steps23
,MIN(tl.tenacity_met_hr) AS tenacity_met_hr
,SUM(tl.ttlsteps) ttlsteps
,CASE WHEN SUM(tl.ttlsteps)>=tl.rqd_tncty_steps THEN SUM(tl.ttlsteps) - tl.rqd_tncty_steps ELSE NULL END AS tenacity_steps_over

FROM INV_motion.GRA252_Tenacity_List tl

GROUP BY tl.enrolled_id,tl.steps_date,tl.rqd_tncty_steps
