# Q9 (Search Interest vs. Adverse Event Spikes): Is there a statistically significant lead/lag correlation between spikes in Google Search Trends (e.g., global search volume for "Ozempic side effects") and official FAERS report submission volumes over time?

WITH
  annual_reports AS (
    SELECT
      FORMAT_DATE('%Y', receive_date) AS report_year,
      COUNT(DISTINCT safetyreportid) AS report_count
    FROM `rasikatest.faers_glp1.adverse_events`
    GROUP BY report_year
    ORDER BY report_year ASC
  ),
  lead_lag_correlation AS (
    SELECT
      report_year,
      report_count,
      LAG(report_count) OVER (ORDER BY report_year ASC) AS prev_report_count,
      ROUND(
        (report_count - LAG(report_count) OVER (ORDER BY report_year ASC))
          / NULLIF(LAG(report_count) OVER (ORDER BY report_year ASC), 0),
        2) AS lag_correlation,
      LEAD(report_count) OVER (ORDER BY report_year ASC) AS next_report_count,
      ROUND(
        (report_count - LEAD(report_count) OVER (ORDER BY report_year ASC))
          / NULLIF(LEAD(report_count) OVER (ORDER BY report_year ASC), 0),
        2) AS lead_correlation
    FROM annual_reports
  ),
  annual_searches AS (
    SELECT
      FORMAT_DATE('%Y', date) AS search_year,
      SUM(search_interest) AS search_interests
    FROM `rasikatest.faers_glp1.search_trends`
    WHERE term IS NOT NULL
    GROUP BY search_year
  )
SELECT
  r.report_year,
  r.report_count,
  s.search_interests,
  r.prev_report_count,
  r.lag_correlation,
  r.next_report_count,
  r.lead_correlation
FROM lead_lag_correlation r
JOIN annual_searches s
  ON r.report_year = s.search_year
ORDER BY report_year ASC;
