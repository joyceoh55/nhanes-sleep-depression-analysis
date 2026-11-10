-- All rows are explicit filter combinations, never additive across All and subgroups.
-- Point estimates only: SQL does not pretend ordinary binomial CIs are survey CIs.
WITH sleep_levels AS (
  SELECT 'All' AS sleep_filter UNION ALL SELECT 'Normal sleep'
  UNION ALL SELECT 'Short sleep' UNION ALL SELECT 'Long sleep'
), sex_levels AS (
  SELECT 'All' AS sex_filter UNION ALL SELECT 'Female' UNION ALL SELECT 'Male'
), age_levels AS (
  SELECT 'All' AS age_filter UNION ALL SELECT '20-39'
  UNION ALL SELECT '40-59' UNION ALL SELECT '60+'
), combinations AS (
  SELECT * FROM sleep_levels CROSS JOIN sex_levels CROSS JOIN age_levels
), summaries AS (
  SELECT c.sleep_filter, c.sex_filter, c.age_filter,
         COUNT(a.SEQN) AS sample_n,
         COALESCE(SUM(a.depression),0) AS cases_n,
         SUM(a.mec_weight) AS weight_sum,
         SUM(a.mec_weight*a.depression) AS weighted_cases,
         SUM(a.mec_weight*a.depression)/NULLIF(SUM(a.mec_weight),0) AS prevalence
  FROM combinations c LEFT JOIN analysis_ready a
    ON (c.sleep_filter='All' OR a.sleep_category=c.sleep_filter)
   AND (c.sex_filter='All' OR a.sex=c.sex_filter)
   AND (c.age_filter='All' OR a.age_group=c.age_filter)
  GROUP BY c.sleep_filter,c.sex_filter,c.age_filter
)
SELECT *,
       -- Window benchmark compares sleep groups within the same sex/age scope.
       prevalence-MAX(CASE WHEN sleep_filter='Normal sleep' THEN prevalence END)
         OVER (PARTITION BY sex_filter,age_filter) AS difference_from_normal
FROM summaries
ORDER BY sex_filter,age_filter,
  CASE sleep_filter WHEN 'All' THEN 0 WHEN 'Normal sleep' THEN 1
                    WHEN 'Short sleep' THEN 2 ELSE 3 END;

