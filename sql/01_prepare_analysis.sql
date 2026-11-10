-- SQLite 3.25+; one source row per SEQN in each imported table.
-- Preserve all demographic rows so exclusion and join coverage remain auditable.
DROP VIEW IF EXISTS analysis_ready;
DROP VIEW IF EXISTS cohort_audit;
DROP VIEW IF EXISTS participant_derivations;
DROP VIEW IF EXISTS phq_scores;

CREATE VIEW phq_scores AS
WITH phq_items AS (
  SELECT SEQN, 'DPQ010' AS item, DPQ010 AS response FROM depression
  UNION ALL SELECT SEQN, 'DPQ020', DPQ020 FROM depression
  UNION ALL SELECT SEQN, 'DPQ030', DPQ030 FROM depression
  UNION ALL SELECT SEQN, 'DPQ040', DPQ040 FROM depression
  UNION ALL SELECT SEQN, 'DPQ050', DPQ050 FROM depression
  UNION ALL SELECT SEQN, 'DPQ060', DPQ060 FROM depression
  UNION ALL SELECT SEQN, 'DPQ070', DPQ070 FROM depression
  UNION ALL SELECT SEQN, 'DPQ080', DPQ080 FROM depression
  UNION ALL SELECT SEQN, 'DPQ090', DPQ090 FROM depression
), scored AS (
  -- 7=refused, 9=don't know, and NULL do not contribute a valid item.
  SELECT SEQN, item,
         CASE WHEN response IN (0,1,2,3) THEN response END AS score
  FROM phq_items
)
SELECT SEQN, COUNT(score) AS valid_phq_items,
       CASE WHEN COUNT(score)=9 THEN SUM(score) END AS phq9_total
FROM scored GROUP BY SEQN;

CREATE VIEW participant_derivations AS
SELECT d.SEQN, d.RIDAGEYR AS age, d.RIAGENDR AS sex_code,
       CASE d.RIAGENDR WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' END AS sex,
       d.RIDRETH3 AS race_code,
       CASE WHEN d.RIDAGEYR BETWEEN 20 AND 39 THEN '20-39'
            WHEN d.RIDAGEYR BETWEEN 40 AND 59 THEN '40-59'
            WHEN d.RIDAGEYR>=60 THEN '60+' END AS age_group,
       d.SDMVSTRA AS stratum, d.SDMVPSU AS psu,
       d.WTMEC2YR AS mec_weight, d.WTINT2YR AS interview_weight,
       p.valid_phq_items, p.phq9_total,
       CASE WHEN p.phq9_total IS NULL THEN NULL
            WHEN p.phq9_total>=10 THEN 1 ELSE 0 END AS depression,
       s.SLD012 AS sleep_hours_code,
       CASE WHEN s.SLD012>=2 AND s.SLD012<7 THEN 'Short sleep'
            WHEN s.SLD012 BETWEEN 7 AND 9 THEN 'Normal sleep'
            WHEN s.SLD012>9 AND s.SLD012<=12 THEN 'Long sleep' END AS sleep_category,
       CASE WHEN p.SEQN IS NULL THEN 0 ELSE 1 END AS has_depression_file,
       CASE WHEN s.SEQN IS NULL THEN 0 ELSE 1 END AS has_sleep_file
FROM demographics d
LEFT JOIN phq_scores p ON d.SEQN=p.SEQN
LEFT JOIN sleep s ON d.SEQN=s.SEQN;

CREATE VIEW cohort_audit AS
SELECT *,
       CASE WHEN age IS NULL OR age<20 THEN '1 Under 20 or missing age'
            WHEN phq9_total IS NULL THEN '2 Incomplete PHQ-9'
            WHEN sleep_category IS NULL THEN '3 Missing or invalid sleep'
            WHEN sex IS NULL OR race_code NOT IN (1,2,3,4,6,7) OR race_code IS NULL
              THEN '4 Missing demographics'
            WHEN mec_weight IS NULL OR mec_weight<=0 THEN '5 No positive MEC weight'
            WHEN stratum IS NULL OR psu IS NULL THEN '6 Missing survey design'
            ELSE '7 Included' END AS cohort_status
FROM participant_derivations;

CREATE VIEW analysis_ready AS
SELECT SEQN, age, age_group, sex, race_code, stratum, psu,
       mec_weight, interview_weight, phq9_total, depression,
       sleep_hours_code, sleep_category
FROM cohort_audit WHERE cohort_status='7 Included';

