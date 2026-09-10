# Q13 (Clinical Conditions & Serious Outcomes): Which conditions represented in GLP-1 clinical trials are associated with the highest volume of serious real-world FAERS reports?
WITH
  drug_conditions AS (
    SELECT DISTINCT
      LOWER(TRIM(drug_query)) AS generic_name,
      conditions
    FROM `rasikatest.faers_glp1.clinical_trials`
    WHERE
      drug_query IS NOT NULL
      AND conditions IS NOT NULL
  ),
  serious_reports AS (
    SELECT
      LOWER(TRIM(generic_name)) AS generic_name,
      safetyreportid
    FROM `rasikatest.faers_glp1.adverse_events`
    WHERE
      seriousness_death = TRUE
      AND generic_name IS NOT NULL
    GROUP BY generic_name, safetyreportid
  ),
  condition_summary AS (
    SELECT
      dc.conditions,
      COUNT(DISTINCT sr.safetyreportid) AS serious_report_count
    FROM drug_conditions dc
    JOIN serious_reports sr
      ON dc.generic_name = sr.generic_name
    GROUP BY dc.conditions
  )
SELECT
  conditions,
  serious_report_count
FROM condition_summary
ORDER BY serious_report_count DESC
LIMIT 10;
