WITH
  drug_info AS (
    SELECT
      generic_name,
      fda_first_approval_date
    FROM `rasikatest.faers_glp1.drugs_overview`
  ),
  events_with_age AS (
    SELECT
      a.generic_name,
      a.safetyreportid,
      a.serious,
      d.fda_first_approval_date,
      DATE_DIFF(
        a.receive_date,
        d.fda_first_approval_date,
        YEAR) AS years_since_approval
    FROM `rasikatest.faers_glp1.adverse_events` a
    JOIN drug_info d
      ON a.generic_name = d.generic_name
  )
SELECT
  generic_name,
  ROUND(
    COUNTIF(serious = TRUE) / COUNT(*) * 100,
    2) AS overall_serious_rate,
  ROUND(
    COUNTIF(serious = FALSE) / COUNT(*) * 100,
    2) AS overall_non_serious_rate,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        serious = TRUE
        AND years_since_approval <= 3),
      COUNTIF(years_since_approval <= 3))
      * 100,
    2) AS first_3_year_serious_rate
FROM events_with_age
GROUP BY generic_name
ORDER BY first_3_year_serious_rate DESC;
