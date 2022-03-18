CREATE OR REPLACE TABLE INV_motion.GRA252_Fact_Step_Minute AS

SELECT  fsi.motion_id enrolled_id 
       ,DATE(fsi.steps_datetime) steps_date
       ,fsi.steps_datetime
       ,fsi.steps
       ,CAST(FORMAT_DATETIME("%H", fsi.steps_datetime) AS INT64) hour_nbr
       ,CAST(FORMAT_DATETIME("%M", fsi.steps_datetime) AS INT64) minute_nbr
       ,SUM (fsi.steps) 
        OVER (PARTITION BY fsi.motion_id, DATE(fsi.steps_datetime) 
                  ORDER BY fsi.motion_id, fsi.steps_datetime ROWS UNBOUNDED PRECEDING) 
        AS steps_running_ttl

 FROM INV_motion.fact_step_intraday fsi
