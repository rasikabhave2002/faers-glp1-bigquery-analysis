# Q4 (Injection Site & Administration Error Signals): Did the rate of user-administration errors (e.g., pen failure, injection site reaction, wrong dosage) spike during periods of known national supply shortages (2022–2024) compared to normal supply periods?

WITH classified_reports AS (
  SELECT
    safetyreportid,
    receive_date,

    CASE
      WHEN receive_date BETWEEN DATE '2022-12-01' AND DATE '2024-12-31'
        THEN 'Shortage Period'
      ELSE 'Normal Supply Period'
    END AS supply_period,

    CASE
      WHEN
        (
          LOWER(reaction) LIKE '%injection site%'
          OR LOWER(reaction) LIKE '%infusion site%'
          OR LOWER(reaction) LIKE '%error%'
          OR LOWER(reaction) LIKE '%wrong%'
          OR LOWER(reaction) LIKE '%incorrect%'
        )
        AND LOWER(reaction) NOT LIKE '%terror%'
      THEN 1
      ELSE 0
    END AS admin_error_signal

  FROM `rasikatest.faers_glp1.adverse_events`
)

SELECT
  supply_period,

  COUNT(DISTINCT safetyreportid) AS overall_report_count,

  COUNT(
    DISTINCT CASE
      WHEN admin_error_signal = 1
      THEN safetyreportid
    END
  ) AS admin_error_report_count,

  ROUND(
    COUNT(
      DISTINCT CASE
        WHEN admin_error_signal = 1
        THEN safetyreportid
      END
    )
    / COUNT(DISTINCT safetyreportid) * 100,
    2
  ) AS admin_error_rate

FROM classified_reports
GROUP BY supply_period
ORDER BY supply_period;