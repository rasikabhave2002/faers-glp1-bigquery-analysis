# Q2 (GI vs. Systemic Adverse Events): What percentage of adverse events per drug are Gastrointestinal (nausea, vomiting, gastroparesis) compared to Pancreatic/Endocrine or Psychiatric signals (pancreatitis, thyroid, suicidal ideation)?

SELECT
  generic_name,
  ROUND(
    COUNT(
      DISTINCT
        CASE
          WHEN LOWER(reaction) IN ('nausea', 'vomiting', 'gastroparesis')
            THEN safetyreportid
          END)
      / COUNT(DISTINCT safetyreportid) * 100,
    2) AS GI_adverse_events,
  ROUND(
    COUNT(
      DISTINCT
        CASE
          WHEN
            LOWER(reaction)
            IN ('pancreatitis', 'thyroid', 'suicidal ideation')
            THEN safetyreportid
          END)
      / COUNT(DISTINCT safetyreportid) * 100,
    2) AS systemic_adverse_events,
    COUNT(DISTINCT safetyreportid) AS total_reports
FROM `rasikatest.faers_glp1.adverse_events`
GROUP BY generic_name
ORDER BY total_reports DESC;
