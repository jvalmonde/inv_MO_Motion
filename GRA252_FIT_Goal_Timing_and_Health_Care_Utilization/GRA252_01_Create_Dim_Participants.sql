/* ========================================
   Author: Susan Mehle
   Description:
     Identify all motion eligible key account members, their enrollment information and their demographic information.

   Input:
     INV_motion.dim_crosswalk_members_new
     Motion.dim_participant
     Motion.dim_date

   Output:
     INV_motion.GRA252_Dim_Participants (81371 records; 04/22/2019 14:53)
  ======================================== */
CREATE OR REPLACE TABLE INV_motion.GRA252_Dim_Participants AS 
 
SELECT 
   CAST(dcm.indv_sys_id AS INT64) indv_sys_id
  ,dcm.membersignupdataid eligible_id
  ,dcm.memberid enrolled_id
  ,dcm.sbscr_ind
  ,dp.gender
  ,DATE(dp.birth_date) birth_date
  ,dp.st_cd
  ,dp.zip_cd
  ,CASE WHEN program_start_dt_id<0 THEN NULL --never started
        WHEN program_start_dt_id>8401 THEN NULL --started after end of study timeframe, treat as never started
        WHEN program_end_dt_id < 0 THEN dt1.full_dt --still enrolled
        WHEN program_end_dt_id < program_start_dt_id THEN NULL --start>stop, treat as never started (known issue)
        ELSE dt1.full_dt 
     END AS program_start_dt
  ,CASE WHEN program_start_dt_id<0 THEN NULL --never started
        WHEN program_start_dt_id>8401 THEN NULL --started after end of study timeframe, treat as never started
        WHEN program_end_dt_id < 0 THEN DATE('2018-12-31') --still enrolled, treat as ended at end of study
        WHEN program_end_dt_id < program_start_dt_id THEN NULL --start>stop, treat as never started (known issue)
        ELSE dt2.full_dt 
     END AS program_end_dt
  ,CASE WHEN mm.Indv_Sys_Id IS NULL THEN 0 ELSE 1 END AS has_mm_match
  ,mm.Fst_Dt
  ,mm.End_Dt
  ,mm.mm_2015 PlanMM2015
  ,mm.mm_2016 PlanMM2016
  ,mm.mm_2017 PlanMM2017
  ,mm.mm_2018 PlanMM2018
   
FROM INV_motion.dim_crosswalk_members_new dcm
      JOIN Motion.dim_participant dp ON dcm.membersignupdataid = dp.src_member_signup_data_id
            JOIN Motion.dim_date dt1 ON dp.program_start_dt_id = dt1.dt_id
            JOIN Motion.dim_date dt2 ON dp.program_end_dt_id = dt2.dt_id
      LEFT JOIN MiniHPDM.Summary_Indv_MM mm ON CAST(dcm.indv_sys_id AS INT64) = mm.Indv_Sys_Id
            
  WHERE dcm.clientname = 'Key Accounts UHCM' AND (dp.program_start_dt_id <= 8401 OR dp.program_start_dt_id <0)
