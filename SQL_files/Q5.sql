# Q5 (Age-Group Risk Mapping): How does the breakdown of top reported side effects differ across age brackets (e.g., under 18 pediatric/adolescent, 18–45, 46–65, and 65+ elderly)?
WITH
  report_count AS (
    SELECT
      CASE
        WHEN patient_age < 18 THEN 'Under 18'
        WHEN patient_age BETWEEN 18 AND 45 THEN '18-45'
        WHEN patient_age BETWEEN 46 AND 65 THEN '46-65'
        WHEN patient_age > 65 THEN '65+'
        ELSE 'Unknown Age'
        END
        AS age_bracket,
      reaction,
      COUNT(DISTINCT safetyreportid) AS reaction_count
    FROM `rasikatest.faers_glp1.adverse_events`
    WHERE reaction IS NOT NULL
    GROUP BY age_bracket, reaction
  ),
  ranked AS (
    SELECT
      age_bracket,
      reaction,
      reaction_count,
      RANK()
        OVER (PARTITION BY age_bracket ORDER BY reaction_count DESC)
        AS reaction_rank
    FROM report_count
    ORDER BY age_bracket, reaction_rank ASC
  )
SELECT
  age_bracket,
  reaction,
  reaction_count
FROM ranked
WHERE reaction_rank <= 5
ORDER BY age_bracket, reaction_rank ASC;
