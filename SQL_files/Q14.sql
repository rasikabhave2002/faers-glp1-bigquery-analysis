# Q14 (Discontinuation & Outcome Time-Series): What is the median time elapsed between the drug's initial receipt date and report outcome, and does "Time-to-Report" vary significantly by generation of GLP-1 drug (1st gen Exenatide/Liraglutide vs 2nd/3rd gen Semaglutide/Tirzepatide)?
WITH drug_dates AS (
  SELECT
    d.generic_name,
    d.fda_first_approval_date
  FROM `rasikatest.faers_glp1.drugs_overview` d
  WHERE d.generic_name IN (
    'exenatide',
    'liraglutide',
    'semaglutide',
    'tirzepatide'
  )
    AND d.fda_first_approval_date IS NOT NULL
),

reports AS (
  SELECT DISTINCT
    a.safetyreportid,
    a.generic_name,
    a.receive_date,
    d.fda_first_approval_date,

    DATE_DIFF(
      a.receive_date,
      d.fda_first_approval_date,
      DAY
    ) AS time_to_report_days,

    CASE
      WHEN a.generic_name IN ('exenatide', 'liraglutide')
        THEN '1st Gen'
      WHEN a.generic_name IN ('semaglutide', 'tirzepatide')
        THEN '2nd/3rd Gen'
    END AS generation

  FROM `rasikatest.faers_glp1.adverse_events` a
  JOIN drug_dates d
    ON a.generic_name = d.generic_name

  WHERE a.receive_date IS NOT NULL
    AND a.receive_date >= d.fda_first_approval_date
)

SELECT
  generic_name,
  generation,
  COUNT(*) AS report_count,
  APPROX_QUANTILES(time_to_report_days, 100)[OFFSET(25)] AS p25_days,
  APPROX_QUANTILES(time_to_report_days, 100)[OFFSET(50)] AS median_days,
  APPROX_QUANTILES(time_to_report_days, 100)[OFFSET(75)] AS p75_days,
  ROUND(AVG(time_to_report_days), 1) AS mean_days
FROM reports
GROUP BY generic_name, generation
ORDER BY generation, median_days;