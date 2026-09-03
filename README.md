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