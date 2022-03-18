### Claims
```sql
SELECT 
 EXTRACT(YEAR FROM DiagnosisServiceDate) AS svyYr
,SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS MalesCnt
,SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS FemalesCnt
,AVG(age) AS avgAge
,AVG(CASE WHEN EXTRACT(YEAR FROM DiagnosisServiceDate) = 2015 THEN mm_2015
          WHEN EXTRACT(YEAR FROM DiagnosisServiceDate) = 2016 THEN mm_2016
          WHEN EXTRACT(YEAR FROM DiagnosisServiceDate) = 2017 THEN mm_2017
          WHEN EXTRACT(YEAR FROM DiagnosisServiceDate) = 2018 THEN mm_2018
     END) AS avgMM
,COUNT(*) cntDx
,COUNT (DISTINCT UniqueMemberID) cntMmbr

FROM INV_motion.GRA252_raf_Claims

GROUP BY EXTRACT(YEAR FROM DiagnosisServiceDate)


SELECT * FROM _9b84f9500c61ddde6764beb586f83241bc840d67.anonfed37be6dc6c2fe8eebc4ca42476b3fae4ca2951 WHERE svcyr>2014
```

### Participants
```sql
SELECT 
CASE WHEN PlanMM2015>0 THEN 2015
     WHEN PlanMM2016>0 THEN 2016
     WHEN PlanMM2017>0 THEN 2017
     WHEN PlanMM2018>0 THEN 2018
END AS theYr

,AVG(CASE WHEN PlanMM2015>0 THEN PlanMM2015
      WHEN PlanMM2016>0 THEN PlanMM2016
      WHEN PlanMM2017>0 THEN PlanMM2017
      WHEN PlanMM2018>0 THEN PlanMM2018
     END) AS AvgMM
,SUM(has_mm_match) AS matched
,COUNT(eligible_id) AS eligible
,COUNT(enrolled_id) AS enrolled
FROM INV_motion.GRA252_Dim_Participants
GROUP BY CASE WHEN PlanMM2015>0 THEN 2015
              WHEN PlanMM2016>0 THEN 2016
              WHEN PlanMM2017>0 THEN 2017
              WHEN PlanMM2018>0 THEN 2018
         END
```

### Single RAF Files
```sql
SELECT COUNT(DISTINCT UniqueMemberID) distinct_n, COUNT(*) n, AVG(SilverTotalScore) avgRAF, 2015 AS theYr FROM INV_motion.GRA252_raf_2015
UNION ALL SELECT COUNT(DISTINCT UniqueMemberID) distinct_n, COUNT(*) n, AVG(SilverTotalScore) avgRAF, 2016 AS theYr FROM INV_motion.GRA252_raf_2016
UNION ALL SELECT COUNT(DISTINCT UniqueMemberID) distinct_n, COUNT(*) n, AVG(SilverTotalScore) avgRAF, 2017 AS theYr FROM INV_motion.GRA252_raf_2017
UNION ALL SELECT COUNT(DISTINCT UniqueMemberID) distinct_n, COUNT(*) n, AVG(SilverTotalScore) avgRAF, 2018 AS theYr FROM INV_motion.GRA252_raf_2018

SELECT * FROM US.bquxjob_79357002_16ac6b3aaae
```
