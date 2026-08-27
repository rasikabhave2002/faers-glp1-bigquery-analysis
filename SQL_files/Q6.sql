# Q6 (Gender Skew & Serious Outcomes): Females account for a large majority of weight-loss drug prescriptions; controlling for total report volume, do male patients show a higher or lower probability of experiencing hospitalization or life-threatening outcomes?

SELECT
  LOWER(patient_sex) AS patient_sex,
  COUNT(DISTINCT safetyreportid) AS report_count,
  COUNT(
    DISTINCT (
      CASE
        WHEN
          seriousness_hospitalization = TRUE
          OR seriousness_lifethreatening = TRUE
          THEN safetyreportid
        END)) AS serious_outcome_count,
  ROUND(
    COUNT(
      DISTINCT (
        CASE
          WHEN
            seriousness_hospitalization = TRUE
            OR seriousness_lifethreatening = TRUE
            THEN safetyreportid
          END))
      / COUNT(DISTINCT safetyreportid) * 100,
    2) AS serious_rate
FROM `rasikatest.faers_glp1.adverse_events`
WHERE patient_sex IS NOT NULL AND LOWER(patient_sex) IN ('male', 'female')
GROUP BY patient_sex
