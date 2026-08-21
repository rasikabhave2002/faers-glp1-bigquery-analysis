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
