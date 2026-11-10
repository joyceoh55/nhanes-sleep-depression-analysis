-- Every query returns interpretable evidence; duplicate and orphan counts must be zero.
SELECT 'demographics' AS source,COUNT(*) AS rows_n,COUNT(DISTINCT SEQN) AS unique_ids
FROM demographics
UNION ALL SELECT 'depression',COUNT(*),COUNT(DISTINCT SEQN) FROM depression
UNION ALL SELECT 'sleep',COUNT(*),COUNT(DISTINCT SEQN) FROM sleep;

SELECT 'depression_without_demographics' AS check_name,COUNT(*) AS failures
FROM depression p LEFT JOIN demographics d ON p.SEQN=d.SEQN WHERE d.SEQN IS NULL
UNION ALL
SELECT 'sleep_without_demographics',COUNT(*)
FROM sleep s LEFT JOIN demographics d ON s.SEQN=d.SEQN WHERE d.SEQN IS NULL;

SELECT cohort_status,COUNT(*) AS sample_n
FROM cohort_audit GROUP BY cohort_status ORDER BY cohort_status;

SELECT
  COUNT(*) AS joined_rows,
  COUNT(DISTINCT SEQN) AS joined_unique_ids,
  SUM(CASE WHEN has_depression_file=0 THEN 1 ELSE 0 END) AS no_depression_file,
  SUM(CASE WHEN has_sleep_file=0 THEN 1 ELSE 0 END) AS no_sleep_file,
  SUM(CASE WHEN age>=20 AND phq9_total IS NULL THEN 1 ELSE 0 END) AS adult_missing_phq9,
  SUM(CASE WHEN age>=20 AND sleep_category IS NULL THEN 1 ELSE 0 END) AS adult_missing_sleep
FROM cohort_audit;

