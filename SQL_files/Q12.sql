# Q12 (Clinical Trial Status to Real-World Outcomes): Joining trial metadata with safety reports, how do real-world post-marketing reported adverse events compare in frequency to the safety signals reported during Phase 3 clinical trial filings?

WITH
  phase3_trials AS (
    SELECT
      LOWER(TRIM(drug_query)) AS generic_name,
      COUNT(DISTINCT nct_id) AS phase3_trial_count,
      SUM(enrollment) AS phase3_total_enrollment,
      MAX(completion_date) AS latest_phase3_completion_date
    FROM `rasikatest.faers_glp1.clinical_trials`
    WHERE
      phase LIKE '%PHASE3%'
      AND completion_date IS NOT NULL
    GROUP BY LOWER(TRIM(drug_query))
  ),
  drug_info AS (
    SELECT
      LOWER(TRIM(generic_name)) AS generic_name,
      fda_first_approval_date
    FROM `rasikatest.faers_glp1.drugs_overview`
  ),
  post_marketing AS (
    SELECT
      LOWER(TRIM(a.generic_name)) AS generic_name,
      COUNT(DISTINCT a.safetyreportid) AS post_marketing_report_count
    FROM `rasikatest.faers_glp1.adverse_events` a
    JOIN drug_info d
      ON LOWER(TRIM(a.generic_name)) = d.generic_name
    WHERE a.receive_date > d.fda_first_approval_date
    GROUP BY LOWER(TRIM(a.generic_name))
  )
SELECT
  p.generic_name,
  p.phase3_trial_count,
  p.phase3_total_enrollment,
  p.latest_phase3_completion_date,
  d.fda_first_approval_date,
  COALESCE(m.post_marketing_report_count, 0) AS post_marketing_report_count,
  COALESCE(
    ROUND(
      SAFE_DIVIDE(
        m.post_marketing_report_count,
        p.phase3_total_enrollment)
        * 100,
      2),
    0) AS post_marketing_reports_rate
FROM phase3_trials p
LEFT JOIN drug_info d
  ON p.generic_name = d.generic_name
LEFT JOIN post_marketing m
  ON p.generic_name = m.generic_name
ORDER BY post_marketing_report_count DESC;
