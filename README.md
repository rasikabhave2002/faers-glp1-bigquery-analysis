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
