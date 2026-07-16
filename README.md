# Insurance Claims Loss Ratio and Fraud Risk Analytics

A consulting style, end to end analytics engagement built entirely with SQL and Power BI. This project analyzes a multi line insurance carrier's claims, policy, and agent data to answer three questions underwriting leadership actually asks: where is the business losing money, which claims deserve a second look before payout, and which customer segments are worth protecting.

## Project Overview

This repository contains a complete analytics build, from raw data to executive dashboard, structured the way a Bain, ZS Associates, or Fractal Analytics team would hand off a client deliverable. It uses only SQL and Power BI. No Python, no R, no Tableau, and no machine learning libraries anywhere in the codebase.

## Business Problem

Loss ratio has been drifting upward, a subset of claims looks statistically unusual, and renewal behavior has never been connected back to loss experience. Full context is in [`Documentation/Business_Problem.md`](Documentation/Business_Problem.md).

## Architecture

```
Raw CSV extract (Dataset/)
        |
        v
Staging tables  ---->  Data_Cleaning.sql   (null handling, dedup, standardization, validation)
        |
        v
Data_Transformation.sql  ---->  Star schema (dim_customers, dim_agents, dim_adjusters, dim_date, fact_policies, fact_claims)
        |
        v
KPI_Queries.sql  +  Advanced_Analysis.sql  (loss ratio, fraud risk, cohort, retention, funnel, ranking)
        |
        v
Power BI  (star schema model, DAX measures, executive dashboard)
```

See the full entity relationship diagram at [`Documentation/ER_Diagram.png`](Documentation/ER_Diagram.png).

## Dataset

The dataset is synthetic, generated with pure SQL (recursive CTEs and randomized distributions, see [`SQL/Data_Generation.sql`](SQL/Data_Generation.sql) for full transparency on how it was built) because real carrier claims data is confidential. It is deliberately seeded with realistic data quality issues, inconsistent state code casing, invalid zip codes, duplicate rows, negative claim amount typos, and blank claim status values, so that `Data_Cleaning.sql` has real problems to solve rather than a spreadsheet that is already perfectly clean.

| Table | Rows | Description |
|---|---|---|
| customers_raw.csv | 5,040 | Policy holders across 15 US states |
| agents_raw.csv | 120 | Sales agents, three performance tiers |
| adjusters_raw.csv | 40 | Claims adjusters with experience level |
| policies_raw.csv | 8,000 | Auto, Home, Life, and Health policies |
| claims_raw.csv | 15,020 | Claims with status, fraud score, and settlement time |

Full column level detail is in [`Documentation/Data_Dictionary.md`](Documentation/Data_Dictionary.md).

## SQL Concepts Used

Complex multi table joins, CTEs, window functions (RANK, NTILE, rolling averages), a stored procedure for rules based fraud triage, views for reusable reporting layers, temporary tables for staged retention analysis, cohort analysis by policy start year, a claims approval funnel, customer value and risk segmentation, and time series loss ratio trending.

## Power BI Features Used

Star schema data modeling, DAX measures and calculated columns, drill through pages, bookmarks with toggle buttons, a What If parameter for fraud score threshold simulation, built in forecasting on the loss ratio trend, row level security by region, custom tooltip pages, and dynamic titles that respond to slicer selection. Full build steps, with every DAX formula included, are in [`PowerBI/Dashboard_Build_Guide.md`](PowerBI/Dashboard_Build_Guide.md).

A note on the `.pbix` file: this repository was built in an environment without Power BI Desktop installed, so the binary `.pbix` is not included. Everything needed to build it, the data model, every DAX measure, and the page by page layout, is fully specified in the build guide so it is a copy and paste build, typically under an hour.

## Key Insights

Health policies in the South region carry the highest loss ratio in the book of business. A small cluster of agents show loss ratios more than double the network average. Fraud flagged claims cluster around adjusters in the lowest experience band. The "High Value High Risk" customer segment renews at nearly the same rate as low risk customers, meaning the business is currently retaining exactly the accounts it should be re-pricing. Full findings are in [`Documentation/Recommendations.md`](Documentation/Recommendations.md).

## Dashboard Pages

Executive Summary, KPI Dashboard, Customer Analytics, Geographic Analysis, Trend Analysis with forecasting, Deep Dive: Fraud Risk, Deep Dive: Agent Performance, and a Recommendation Dashboard styled as an executive storytelling page. Layout wireframe: [`PowerBI/Dashboard_Screenshots/Executive_Summary_Wireframe.png`](PowerBI/Dashboard_Screenshots/Executive_Summary_Wireframe.png).

## Business Recommendations

See [`Documentation/Recommendations.md`](Documentation/Recommendations.md) for the full memo, including key findings, revenue opportunities, cost reduction areas, risk factors, and a four point action plan.

## Installation Steps

1. Clone this repository.
2. Load the CSV files in `/Dataset` into a SQL Server, Azure SQL, or PostgreSQL database (adjust minor T-SQL syntax for PostgreSQL, mainly `TOP` to `LIMIT` and `DATEADD` to `+ INTERVAL`).
3. Run `SQL/Schema.sql`, then `SQL/Data_Cleaning.sql`, then `SQL/Data_Transformation.sql`, in that order.
4. Run `SQL/KPI_Queries.sql` and `SQL/Advanced_Analysis.sql` to validate the numbers.
5. Open Power BI Desktop, connect to the database, and follow `PowerBI/Dashboard_Build_Guide.md` to build the model and every page.

## Future Improvements

Add a Power Query based incremental refresh pattern so the dashboard updates daily without a full reload. Extend the fraud triage stored procedure with a second signal, claim to policy inception gap, since claims filed very soon after a policy starts are statistically more likely to be fraudulent. Add a what if pricing simulator for the Health line specifically, since that is the product line flagged as the biggest margin opportunity.

## Repository Structure

```
Insurance_Claims_Loss_Ratio_Fraud_Analytics/
├── Dataset/                         Raw CSV extracts (with intentional data quality issues)
├── SQL/
│   ├── Schema.sql                   Staging and star schema DDL
│   ├── Data_Generation.sql          How the synthetic dataset was built (SQLite dialect)
│   ├── Data_Cleaning.sql            Null handling, dedup, standardization, validation
│   ├── Data_Transformation.sql      Star schema load logic and reusable views
│   ├── KPI_Queries.sql              Ten core business KPI queries
│   └── Advanced_Analysis.sql        Window functions, cohort, funnel, stored procedure
├── PowerBI/
│   ├── Dashboard_Build_Guide.md     Full model, DAX, and page build instructions
│   └── Dashboard_Screenshots/       Layout wireframe
├── Documentation/
│   ├── Business_Problem.md
│   ├── Recommendations.md
│   ├── Data_Dictionary.md
│   └── ER_Diagram.png
├── Presentation/
│   └── Executive_Summary_Deck.md
└── README.md
```

## Resume Bullet Points

* Engineered a full SQL data pipeline (staging, cleaning, star schema transformation) processing 28,000+ synthetic insurance records across 5 relational tables, reducing data quality defects to zero through automated deduplication and validation logic.
* Built a stored procedure driven fraud risk triage system in T-SQL using window functions and regional benchmarking, and designed a Power BI executive dashboard with What If simulation, forecasting, and row level security across 8 report pages.
* Delivered a consulting style loss ratio and agent performance analysis identifying a 3 to 5 point underwriting margin improvement opportunity, translating SQL KPI calculations directly into a prioritized business action plan.

ATS friendly one line description: Built an end to end SQL and Power BI analytics solution for insurance claims loss ratio and fraud risk, covering data cleaning, star schema modeling, KPI calculation, and executive dashboard design.
