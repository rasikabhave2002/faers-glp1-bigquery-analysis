# 💊 GLP-1 Weight Loss Drugs Safety & Market Signals Analysis

An end-to-end SQL analytical project examining safety profiles, adverse events, demographic distributions, and market signals for GLP-1 receptor agonist drugs using **Google BigQuery** and **Looker Studio** (formerly Data Studio).

---

## 📌 Project Overview
GLP-1 receptor agonists (e.g., Semaglutide, Tirzepatide, Liraglutide) have transformed diabetes management and anti-obesity care. This repository analyzes real-world adverse event reporting, demographic breakdowns, and longitudinal trend data across major commercial GLP-1 therapies (e.g., Ozempic, Wegovy, Mounjaro, Zepbound).

* **GCP Project:** `rasikatest`
* **BigQuery Dataset:** `rasikatest.faers_glp1`
* **Visualization:** Google Looker Studio (Data Studio)
* **Data Sources:** 
  * [Kaggle: GLP-1 Weight Loss Drugs - EDA](https://www.kaggle.com/code/devtayyabsajjad/glp-1-weight-loss-drugs-eda) by *Dev Tayyab Sajjad*
  * FDA Adverse Event Reporting System (FAERS), Google Search Trends, Financial Stock Data, and Clinical Trial Records.
* **Tech Stack:** Google BigQuery (Standard SQL), BigQuery ML, Looker Studio, GitHub, Markdown.

---

## 🎯 Project Objectives

### 1. Clinical & Business Objectives
* **Quantify Safety Profiles:** Evaluate real-world safety signals and compare adverse reaction rates (e.g., gastrointestinal vs. systemic events) across first-generation and next-generation GLP-1 therapies.
* **Demographic Risk Mapping:** Analyze how patient age, gender, and geographic region influence outcome severity, such as hospitalization rates or life-threatening events.
* **Assess Real-World vs. Trial Data:** Compare post-marketing adverse event frequencies against Phase 3 clinical trial disclosures to identify unexpected real-world signals.
* **Correlate External Market Signals:** Evaluate how public interest (Google Search Trends), news media spikes, and manufacturer financial volatility (Eli Lilly / Novo Nordisk stocks) align with adverse event filing surges.

### 2. Technical & Data Engineering Objectives
* **Cloud Data Ingestion & Modeling:** Ingest high-volume raw Kaggle datasets into **Google BigQuery** (`rasikatest.faers_glp1`) and build an optimized relational warehouse structure.
* **Query Optimization:** Utilize table partitioning and clustering to optimize execution speed and cost when running analytical queries across millions of records.
* **Interactive Dashboarding:** Connect BigQuery directly to **Looker Studio** to build automated, interactive visual dashboards for stakeholders.
* **Predictive Modeling with BigQuery ML:** Train and evaluate classification models (`LOGISTIC_REGRESSION` / `BOOSTED_TREE_CLASSIFIER`) inside BigQuery ML to predict hospitalization risk based on patient features.

---

## 📁 Repository Structure

```text
├── README.md                 # Project Overview, Objectives, Analytical Schema & Insights
├── sql/                      # Modular SQL Queries
│   ├── 01_comparative_safety.sql
│   ├── 02_demographic_stratification.sql
│   ├── 03_temporal_trends.sql
│   └── 04_predictive_modeling_bqml.sql
├── data/                     # Exported query results (CSVs)
│   └── query_outputs/
└── dashboards/               # Looker Studio Report links, embedded views, and dashboard exports
    ├── screenshots/          # Static snapshots of dashboard pages
    └── looker_studio_link.md # Link to interactive Looker Studio report

```

### Q1: Proportional Adverse Event Severity (Overall vs. First 3 Years Post-Approval)

#### Business / Clinical Question
Which specific GLP-1 drug (e.g., *Semaglutide*, *Tirzepatide*, *Liraglutide*) has the highest proportion of adverse event reports flagged as **Serious** vs. **Non-Serious**, and how does this change when controlling for the drug's age/market release date?

---

#### BigQuery SQL Code
```sql
WITH drug_info AS (
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
    DATE_DIFF(a.receive_date, d.fda_first_approval_date, YEAR) AS years_since_approval
  FROM `rasikatest.faers_glp1.adverse_events` a
  JOIN drug_info d
    ON a.generic_name = d.generic_name
)
SELECT
  generic_name,
  ROUND(COUNTIF(serious = TRUE) / COUNT(*) * 100, 2) AS overall_serious_rate,
  ROUND(COUNTIF(serious = FALSE) / COUNT(*) * 100, 2) AS overall_non_serious_rate,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(serious = TRUE AND years_since_approval <= 3),
      COUNTIF(years_since_approval <= 3)
    ) * 100, 
    2
  ) AS first_3_year_serious_rate
FROM events_with_age
GROUP BY generic_name
ORDER BY first_3_year_serious_rate DESC;

```
#### Analytical Insights & Takeaways:
1. Lifecycle Bias Adjustment (Weber Effect): Looking only at overall numbers makes lixisenatide (61.40%) and liraglutide (51.87%) appear to have the highest severity profiles. However, isolating the first 3 years post-approval shows semaglutide held the highest initial severity rate at 49.88%, compared to liraglutide's early 24.69%. Liraglutide's overall severity rose over time as milder reports decreased and late-lifecycle reporting skewed toward severe institutional cases.
2. Consumer-Driven Volume Dilution: Tirzepatide exhibits a substantially lower serious rate (17.12%), driven by high consumer adoption and high-volume reporting of non-serious side effects (e.g., mild nausea, GI discomfort, injection-site issues) that expand the non-serious denominator.
3. Data Boundary Note: Exenatide returns null for its 3-year post-approval metric because its initial FDA approval date (2005) precedes the timeframe of the dataset records.

### Q2: GI vs. Systemic Adverse Event Signals

#### Business / Clinical Question
What percentage of adverse event reports per drug are Gastrointestinal (GI) — nausea, vomiting, gastroparesis — compared to Pancreatic/Endocrine or Psychiatric systemic signals — pancreatitis, thyroid-related events, suicidal ideation?

---
#### BigQuery SQL Code
``` sql
SELECT 
  generic_name,

  ROUND(
    COUNT(DISTINCT CASE 
      WHEN LOWER(reaction) IN ('nausea', 'vomiting', 'gastroparesis')
      THEN safetyreportid 
    END)
    / COUNT(DISTINCT safetyreportid) * 100,
    2
  ) AS GI_adverse_events,

  ROUND(
    COUNT(DISTINCT CASE 
      WHEN LOWER(reaction) = 'pancreatitis'
        OR LOWER(reaction) LIKE '%thyroid%'
        OR LOWER(reaction) = 'suicidal ideation'
      THEN safetyreportid 
    END)
    / COUNT(DISTINCT safetyreportid) * 100,
    2
  ) AS systemic_adverse_events,

  COUNT(DISTINCT safetyreportid) AS total_reports

FROM `rasikatest.faers_glp1.adverse_events`
GROUP BY generic_name
ORDER BY GI_adverse_events DESC;
```

#### Analytical Insights & Takeaways:
1. Dulaglutide has the highest proportion of GI signals: GI-related events appear in 25.71% of dulaglutide reports, followed by semaglutide (20.14%) and liraglutide (18.74%). This indicates that GI reactions represent a prominent component of the reported safety profile for these therapies.
2. Liraglutide has the highest proportion of systemic signals: At 7.58%, liraglutide has the highest systemic adverse-event proportion among the drugs with substantial reporting volume. This is more than twice the systemic proportion observed for semaglutide (3.38%) and dulaglutide (3.44%).
3. GI signals are more prevalent than systemic signals across most drugs: The difference is particularly pronounced for tirzepatide, where GI signals occur in approximately 16 times as many reports as systemic signals. Semaglutide also shows a substantial difference, with GI signals occurring approximately 6 times as often.
4. Lixisenatide results should be interpreted cautiously: While lixisenatide shows a systemic signal proportion of 5.26%, this is based on only 19 total reports. Its small sample size makes the percentage highly unstable and unsuitable for direct comparison with drugs having thousands of reports.

#### Q3: Off-Label Brand Differences — Ozempic vs. Wegovy

#### Business / Clinical Question
Is there a difference in reported adverse-event outcome severity between Ozempic (Type 2 Diabetes indication) and Wegovy (Obesity indication), despite both sharing the same active molecule, semaglutide?

---
#### BigQuery SQL Code
``` sql
SELECT
  brand_queried,
  ROUND(
    COUNT(DISTINCT CASE 
      WHEN serious = TRUE THEN safetyreportid 
    END)
    / COUNT(DISTINCT safetyreportid)
    * 100,
    2
  ) AS severity_rate,
  COUNT(DISTINCT safetyreportid) AS report_ct
FROM `rasikatest.faers_glp1.adverse_events`
WHERE
  LOWER(generic_name) = 'semaglutide'
  AND LOWER(brand_queried) IN ('wegovy', 'ozempic')
GROUP BY brand_queried
ORDER BY report_ct DESC, severity_rate DESC;
```

#### Analytical Insights & Takeaways:
1. Ozempic has a higher reported severity proportion: 39.42% of Ozempic reports were classified as serious compared with 34.48% for Wegovy, resulting in a 4.94 percentage-point difference.
The comparison uses equal report volumes: Both brands contain exactly 5,000 unique adverse-event reports in the analyzed dataset. This provides a balanced reporting sample for comparing the observed proportion of serious reports between the two brands.
2. Same molecule, different reported safety profile: Although both products contain semaglutide, Ozempic shows a higher proportion of serious reports than Wegovy. This difference may reflect variations in indication, underlying patient population, comorbidities, treatment patterns, or adverse-event reporting behavior.
3. Indication may be an important confounding factor: Ozempic is primarily associated with Type 2 Diabetes treatment, whereas Wegovy is indicated for chronic weight management. Patients using the two products may therefore differ substantially in baseline health status and comorbidities, which could influence the severity of reported outcomes.
4. The result does not establish causation or that Ozempic is inherently less safe: FAERS is a spontaneous reporting database and does not provide a denominator for total drug exposure. A higher proportion of serious reports does not necessarily mean a higher underlying risk of serious adverse events.
5. Statistical significance requires an additional test: The 4.94 percentage-point difference demonstrates an observed difference in the dataset, but the current SQL does not test whether that difference is statistically significant. A chi-square test or two-proportion z-test would be required to determine whether the observed difference is unlikely to have occurred by chance.

#### Q4: Injection Site & Administration Error Signals

#### Business / Clinical Question
Did the rate of user-administration errors (e.g., pen failure, injection site reaction, wrong dosage) spike during periods of known national supply shortages (2022–2024) compared to normal supply periods? 

---
#### BigQuery SQL Code
``` sql
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
```
#### Analytical Insights & Takeaways:
1. Administration-related safety signals were slightly more prevalent during documented GLP-1 shortage periods. The signal rate was 29.95% during shortage periods compared with 27.67% during normal supply periods, representing a 2.28 percentage-point difference (approximately 8.2% relative increase). This suggests a potential association between supply shortages and increased reporting of injection-site/administration-related safety signals. However, the increase was relatively modest and should not be interpreted as evidence that shortages directly caused administration errors.
2. FAERS is a spontaneous adverse-event reporting system, so these results reflect reporting patterns rather than true population-level incidence. Additional statistical testing and adjustment for product, reporting volume, and other confounders would be needed to establish whether the difference is statistically meaningful.

#### Q5: Age-Group Risk Mapping

#### Business / Clinical Question
How does the breakdown of top reported side effects differ across age brackets (e.g., under 18 pediatric/adolescent, 18–45, 46–65, and 65+ elderly) 

---
#### BigQuery SQL Code
``` sql
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
```

#### Analytical Insights & Takeaways:
1. Age groups show distinct adverse-event profiles. Nausea is consistently among the top reported reactions across all age groups, but the secondary signals differ. 18–45 stands out for Incorrect dose administered (1,064 reports), while 65+ shows Blood glucose increased (861) and Weight decreased (532) among its top reactions.
2. Administration-related issues are particularly prominent among adults aged 18–45. Incorrect dose administered is the #1 reported reaction for the 18–45 group (1,064 reports), ahead of nausea (959). In contrast, nausea ranks first among both the 46–65 and 65+ groups. This may indicate a stronger reporting signal around medication administration among younger adult users.
3. Pediatric reports are substantially fewer and should be interpreted cautiously. The Under-18 group has very few reports compared with older age groups (only 14 nausea and 10 vomiting reports among the top reactions). This likely reflects the much smaller number of pediatric reports in the dataset, so the results should not be interpreted as evidence of lower pediatric risk without accounting for the underlying population/report volume.

#### Q6: Gender Skew & Serious Outcomes

#### Business / Clinical Question
Females account for a large majority of weight-loss drug prescriptions; controlling for total report volume, do male patients show a higher or lower probability of experiencing hospitalization or life-threatening outcomes?

---
#### BigQuery SQL Code
``` sql
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
GROUP BY patient_sex;
```

#### Analytical Insights & Takeaways:
1. Gender-based severity skew: Male patients had a higher proportion of reported serious outcomes than female patients. 15.46% of male reports involved hospitalization or life-threatening outcomes, compared with 10.08% of female reports—a difference of 5.38 percentage points and approximately a 53% higher proportion among male reports.
2. This suggests a notable gender skew in the severity of reported adverse events. However, because FAERS is a spontaneous reporting system, this should be interpreted as a difference in reported-event severity, not evidence that male patients have a 53% higher clinical risk. Differences in drug utilization, patient characteristics, reporting behavior, and other confounders may contribute to the observed pattern.

#### Q7: Global Geographic Discrepancies

#### Business / Clinical Question
What are the top 5 countries originating reports outside the US, and do international safety reports show a different primary reaction signature compared to US-based FDA FAERS reports?

---
#### BigQuery SQL Code
``` sql
WITH country_counts AS (
  SELECT
    country,
    COUNT(DISTINCT safetyreportid) AS report_count
  FROM `faers_glp1.adverse_events`
  WHERE LOWER(country) != 'us'
  GROUP BY country
),

top5_countries AS (
  SELECT
    country,
    report_count
  FROM country_counts
  ORDER BY report_count DESC
  LIMIT 5
),

us_reactions AS (
  SELECT
    reaction,
    COUNT(DISTINCT safetyreportid) AS report_count
  FROM `faers_glp1.adverse_events`
  WHERE LOWER(country) = 'us'
  GROUP BY reaction
),

international_reactions AS (
  SELECT
    reaction,
    COUNT(DISTINCT safetyreportid) AS report_count
  FROM `faers_glp1.adverse_events`
  WHERE country IN (
    SELECT country
    FROM top5_countries
  )
  GROUP BY reaction
),

us_total AS (
  SELECT SUM(report_count) AS total_reports
  FROM us_reactions
),

international_total AS (
  SELECT SUM(report_count) AS total_reports
  FROM international_reactions
)

SELECT
  'US' AS region,
  reaction,
  report_count,
  ROUND(report_count / total_reports * 100, 2) AS reaction_share_pct
FROM us_reactions
CROSS JOIN us_total
QUALIFY ROW_NUMBER() OVER (ORDER BY report_count DESC) = 1

UNION ALL

SELECT
  'Top 5 International Countries' AS region,
  reaction,
  report_count,
  ROUND(report_count / total_reports * 100, 2) AS reaction_share_pct
FROM international_reactions
CROSS JOIN international_total
QUALIFY ROW_NUMBER() OVER (ORDER BY report_count DESC) = 1;
```

#### Analytical Insights & Takeaways:
The primary reaction signature is consistent across US and international reports, with Nausea ranking as the most frequently reported reaction in both groups. However, Nausea represents a smaller share of reports from the top 5 international countries (3.46%) compared with US reports (5.34%), suggesting some variation in the distribution of secondary reactions across geographic regions.

#### Q8: Post-Marketing Surveillance Velocity

#### Business / Clinical Question
What is the growth rate (month-over-month) of FAERS adverse event submissions following major FDA regulatory approvals (e.g., Zepbound approval in late 2023 vs. Wegovy in 2021)?

---
#### BigQuery SQL Code
``` sql
WITH
  monthly_reports AS (
    SELECT
      FORMAT_DATE('%Y-%m', receive_date) AS report_month,
      COUNT(DISTINCT safetyreportid) AS report_count
    FROM `rasikatest.faers_glp1.adverse_events`
    GROUP BY report_month
    ORDER BY report_month
  )
SELECT
  report_month,
  report_count,
  LAG(report_count) OVER (ORDER BY report_month) AS prev_report_count,
  ROUND(
    (report_count - LAG(report_count) OVER (ORDER BY report_month))
      / NULLIF(LAG(report_count) OVER (ORDER BY report_month), 0)
      * 100,
    2) AS growth_rate
FROM monthly_reports
WHERE report_month >= '2021-01'
ORDER BY report_month;
```

#### Analytical Insights & Takeaways:
FAERS reporting showed high month-over-month volatility around major GLP-1 regulatory milestones. Following the late-2023 Zepbound approval period, reports surged 878.62% MoM in January 2024 (145 → 1,419) and reached 1,488 reports by July 2024. In comparison, the 2021 Wegovy period showed smaller but intermittent spikes, including 403.92% in March and 436.67% in July. Overall, the post-2023 period demonstrated substantially higher reporting activity, although the fluctuations suggest that factors beyond approval timing also influenced submission volume.


#### Q9: Search Interest vs. Adverse Event Spikes

#### Business / Clinical Question
Is there a statistically significant lead/lag correlation between spikes in Google Search Trends (e.g., global search volume for "Ozempic side effects") and official FAERS report submission volumes over time?

---
#### BigQuery SQL Code
``` sql
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
```

#### Analytical Insights & Takeaways:
1. The annual trends suggest that GLP-1-related search interest and FAERS reporting volumes can move in the same direction during certain periods, particularly in 2022 and 2024, but the relationship is not consistently aligned. The divergence in 2023 demonstrates that increasing public search interest does not necessarily correspond to an immediate increase in adverse-event reporting.
2. Because this analysis uses annual observations and the current lead/lag fields represent year-over-year changes rather than Pearson correlation coefficients or p-values, the results should be interpreted as a descriptive lead/lag analysis rather than evidence of statistically significant correlation or causation.

#### Q10: Media Anomaly Detection

#### Business / Clinical Question
Using rolling averages (e.g., 30-day moving average), can we isolate temporary "anomalies" or sudden surges in reporting for specific reactions (like Diarrhoea or Constipation) following major news or social media trends?

---
#### BigQuery SQL Code
``` sql
WITH
  daily_reports AS (
    SELECT
      receive_date,
      COUNT(DISTINCT safetyreportid) AS report_count
    FROM `rasikatest.faers_glp1.adverse_events`
    WHERE LOWER(reaction) IN ('diarrhoea', 'constipation')
    GROUP BY receive_date
  ),
  rolling_avg AS (
    SELECT
      d.receive_date AS report_date,
      d.report_count,
      ROUND(
        (
          SELECT AVG(d2.report_count)
          FROM daily_reports d2
          WHERE
            d2.receive_date
            BETWEEN DATE_SUB(d.receive_date, INTERVAL 29 DAY)
            AND d.receive_date
        ),
        2) AS rolling_30_day_avg
    FROM daily_reports d
  ),
  daily_searches AS (
    SELECT
      date AS search_date,
      SUM(search_interest) AS search_interests
    FROM `rasikatest.faers_glp1.search_trends`
    WHERE term IS NOT NULL
    GROUP BY search_date
  )
SELECT
  r.report_date,
  r.report_count,
  r.rolling_30_day_avg,
  ROUND(
    (r.report_count - r.rolling_30_day_avg)
      / NULLIF(r.rolling_30_day_avg, 0)
      * 100,
    2) AS anomaly_pct,
  CASE
    WHEN r.report_count > r.rolling_30_day_avg * 2
      THEN 'Anomaly'
    WHEN r.report_count > r.rolling_30_day_avg * 1.5
      THEN 'Elevated'
    ELSE 'Normal'
    END AS anomaly_status,
  COALESCE(s.search_interests, 0) AS search_interests
FROM rolling_avg r
LEFT JOIN daily_searches s
  ON r.report_date = s.search_date
ORDER BY report_date ASC;
```
#### Analytical Insights & Takeaways:
1. Single-day spikes dominate and they look administrative, not media-driven: The dataset contains dozens of single-day report count spikes that are 5–17x the rolling 30-day average, then revert to baseline the very next reporting day. This "spike-then-immediate-reversion" shape (no multi-day ramp-up or gradual decay) is the classic signature of batch/bulk case entry into FAERS (e.g., a manufacturer or law firm submitting a backlog of reports on one date) rather than an organic surge in real-world adverse events triggered by news coverage. A genuine media-driven anomaly would typically show a sustained elevation across several days to weeks as public awareness builds and fades.
2. Search interest data is sparse and monthly, not daily: search_interests is populated almost exclusively on the 1st of each month , with 0 on all other days. This means the LEFT JOIN only aligns search data with report anomalies roughly once a month it cannot support day-level correlation claims. Any "search spike coincided with report spike" conclusion should be caveated: we're really comparing monthly search snapshots to daily report data.
3. Search interest shows a clear structural break around 2022: From 2013–2021, search_interests is 0 almost everywhere, with only a few small non-zero blips (e.g., 3, 5, 9, 21, 22, 37, 56, 76).
Starting 2022-08-01, values jump into the hundreds and grow steadily. This growth pattern tracks the well-documented public/media surge in interest around GLP‑1 drugs (Ozempic/Wegovy/semaglutide) from 2022 onwards consistent with the dataset being GLP‑1-drug-related adverse events.
4. No clear causal link between the search-interest ramp and report anomalies: The largest, most extreme report anomalies (787%–1,722% spikes) occurred before search interest data even registers above zero (2014–2020). Meanwhile, in 2022–2025 — when search interest is at its highest and growing — the anomaly spikes are still present but generally less extreme in percentage terms (mostly 300–800% vs. the >1000% outliers from the pre-2022 period), likely because the baseline (rolling average) itself is higher by then.

#### Q11: Manufacturer Financial Impact vs. Safety Events

#### Business / Clinical Question
Joining the stock price table for Eli Lilly (LLY) and Novo Nordisk (NVO) with quarterly FAERS data, did stock price volatility correlate with sudden increases in serious adverse event report filings?

---
#### BigQuery SQL Code
``` sql
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
```

#### Analytical Insights & Takeaways:
1. Eli Lilly: FAERS reporting increased sharply from 2022 onward, often during periods of strong stock growth.
2. Novo Nordisk: Stock prices rose substantially through 2024, but FAERS reporting did not consistently follow the same trend.
3. Overall: FAERS reporting volume and stock performance show some periods of alignment but no consistent direct relationship, suggesting that reporting activity is influenced by factors beyond market performance, such as product adoption, regulatory events, and public attention.

#### Q12: Manufacturer Financial Impact vs. Safety Events

#### Business / Clinical Question 
Joining trial metadata with safety reports, how do real-world post-marketing reported adverse events compare in frequency to the safety signals reported during Phase 3 clinical trial filings?

---
#### BigQuery SQL Code
``` sql
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
```

#### Analytical Insights & Takeaways:
1. Semaglutide had the largest Phase 3 footprint (140 trials; 125,956 participants) and the highest post-marketing FAERS volume (14,956 reports), but its normalized reporting rate was only 11.87 per 100 participants.
2. Albiglutide had the highest normalized reporting rate at 333.02 per 100 participants, followed by exenatide (48.49) and tirzepatide (30.91).
3. Lixisenatide had the lowest rate among approved drugs (0.50 per 100 participants).
4. Overall, greater Phase 3 enrollment did not consistently correspond to higher post-marketing reporting rates, indicating substantial variation in real-world reporting across drugs.

#### Q13: Clinical Conditions & Serious Outcomes

#### Business / Clinical Question 
Which conditions represented in GLP-1 clinical trials are associated with the highest volume of serious real-world FAERS reports?

---
#### BigQuery SQL Code
``` sql
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
```

#### Analytical Insights & Takeaways:
Type 2 diabetes-related conditions dominated serious FAERS reports, with Diabetes Mellitus, Type 2 recording the highest volume at 1,293 reports.
Other closely related Type 2 diabetes labels followed closely: Diabetes Mellitus (1,286) and Type 2 Diabetes / Type 2 Diabetes Mellitus (1,285 each).
Type 1 diabetes also showed substantial reporting, with 1,235 reports for Diabetes Mellitus, Type 1.
Obesity was associated with 1,234 serious reports, while the combined Type 2 Diabetes + Obesity category also recorded 1,234 reports.
Overall, the results indicate that diabetes—particularly Type 2 diabetes—and obesity are the most prominent clinical conditions represented in the serious-event reporting analysis.