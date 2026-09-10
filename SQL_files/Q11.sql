# Q11 (Manufacturer Financial Impact vs. Safety Events): Joining the stock price table for Eli Lilly (LLY) and Novo Nordisk (NVO) with quarterly FAERS data, did stock price volatility correlate with sudden increases in serious adverse event report filings?
WITH
  quarterly_stocks AS (
    SELECT
      FORMAT_DATE('%Y-Q%Q', date) AS stock_quarter,
      company,
      ROUND(AVG((open + close) / 2), 2) AS avg_price
    FROM `rasikatest.faers_glp1.stock_prices`
    WHERE company IN ('Eli Lilly & Company', 'Novo Nordisk A/S')
    GROUP BY stock_quarter, company
  ),
  stock_changes AS (
    SELECT
      stock_quarter,
      company,
      avg_price,
      LAG(avg_price)
        OVER (
          PARTITION BY company
          ORDER BY stock_quarter
        ) AS previous_avg_price,
      ROUND(
        (
          avg_price - LAG(avg_price)
            OVER (
              PARTITION BY company
              ORDER BY stock_quarter
            ))
          / NULLIF(
            LAG(avg_price)
              OVER (
                PARTITION BY company
                ORDER BY stock_quarter
              ),
            0)
          * 100,
        2) AS stock_price_change_pct
    FROM quarterly_stocks
  ),
  quarterly_reports AS (
    SELECT
      FORMAT_DATE('%Y-Q%Q', receive_date) AS report_quarter,
      CASE
        WHEN
          LOWER(brand_queried)
          IN ('ozempic', 'wegovy', 'rybelsus', 'victoza', 'saxenda')
          THEN 'Novo Nordisk A/S'
        WHEN LOWER(brand_queried) IN ('mounjaro', 'zepbound', 'trulicity')
          THEN 'Eli Lilly & Company'
        END AS company,
      COUNT(DISTINCT safetyreportid) AS report_count
    FROM `rasikatest.faers_glp1.adverse_events`
    WHERE
      LOWER(brand_queried)
      IN (
        'ozempic', 'wegovy', 'rybelsus', 'victoza', 'saxenda', 'mounjaro',
        'zepbound', 'trulicity')
    GROUP BY report_quarter, company
  ),
  report_changes AS (
    SELECT
      report_quarter,
      company,
      report_count,
      LAG(report_count)
        OVER (
          PARTITION BY company
          ORDER BY report_quarter
        ) AS previous_report_count,
      ROUND(
        (
          report_count - LAG(report_count)
            OVER (
              PARTITION BY company
              ORDER BY report_quarter
            ))
          / NULLIF(
            LAG(report_count)
              OVER (
                PARTITION BY company
                ORDER BY report_quarter
              ),
            0)
          * 100,
        2) AS report_change_pct
    FROM quarterly_reports
  )
SELECT
  s.stock_quarter,
  s.company,
  s.avg_price,
  s.stock_price_change_pct,
  COALESCE(r.report_count, 0) AS report_count,
  r.report_change_pct
FROM stock_changes s
LEFT JOIN report_changes r
  ON
    s.stock_quarter = r.report_quarter
    AND s.company = r.company
ORDER BY s.company, s.stock_quarter;
