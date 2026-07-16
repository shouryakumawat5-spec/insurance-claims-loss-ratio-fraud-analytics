# Power BI Dashboard Build Guide

## A Note Before You Start

This build environment cannot run Power BI Desktop, so no `.pbix` binary is included in this folder. What is included instead is everything needed to build the exact dashboard in about an hour: the data model, every DAX measure written and ready to paste, the page by page layout, and the setup steps for every advanced feature requested (drill through, bookmarks, RLS, what if, forecasting, custom tooltips). Point Power BI Desktop at the CSV files in `/Dataset`, or better, at the SQL Server database built from the `/SQL` scripts, and follow this guide top to bottom.

## 1. Data Model (Star Schema)

Import these tables and set the relationships exactly as listed. All relationships are one to many, single direction, from dimension to fact.

* `dim_customers` (1) to `fact_policies` (many) on `customer_id`
* `dim_agents` (1) to `fact_policies` (many) on `agent_id`
* `dim_customers` (1) to `fact_claims` (many) on `customer_id`
* `dim_adjusters` (1) to `fact_claims` (many) on `adjuster_id`
* `dim_date` (1) to `fact_claims` (many) on `date_key`
* `fact_policies` (1) to `fact_claims` (many) on `policy_id`

Mark `dim_date` as a Date Table in Power BI (Modeling tab, Mark as Date Table, using `full_date`).

## 2. Calculated Columns

```
Customer Full Name = dim_customers[first_name] & " " & dim_customers[last_name]

Claim Age Band =
SWITCH(
    TRUE(),
    fact_claims[days_to_settle] <= 15, "0-15 days",
    fact_claims[days_to_settle] <= 30, "16-30 days",
    fact_claims[days_to_settle] <= 60, "31-60 days",
    "60+ days"
)

Policy Tenure Years =
DATEDIFF(dim_customers[customer_since_date], fact_policies[policy_start_date], YEAR)
```

## 3. Core DAX Measures

```
Total Premium = SUM(fact_policies[annual_premium])

Total Claims Paid =
CALCULATE(SUM(fact_claims[claim_amount]), fact_claims[claim_status] = "Approved")

Loss Ratio =
DIVIDE([Total Claims Paid], [Total Premium], 0)

Claim Count = COUNTROWS(fact_claims)

Policy Count = COUNTROWS(fact_policies)

Claim Frequency = DIVIDE([Claim Count], [Policy Count], 0)

Average Claim Severity = AVERAGE(fact_claims[claim_amount])

Fraud Flagged Claims = CALCULATE([Claim Count], fact_claims[fraud_flag] = 1)

Fraud Flag Rate % = DIVIDE([Fraud Flagged Claims], [Claim Count], 0) * 100

Denied Claims = CALCULATE([Claim Count], fact_claims[claim_status] = "Denied")

Denied Rate % = DIVIDE([Denied Claims], [Claim Count], 0) * 100

Renewed Policies = CALCULATE([Policy Count], fact_policies[renewed_flag] = "Y")

Renewal Rate % = DIVIDE([Renewed Policies], [Policy Count], 0) * 100

Avg Days to Settle = AVERAGE(fact_claims[days_to_settle])

Underwriting Margin % =
DIVIDE([Total Premium] - [Total Claims Paid], [Total Premium], 0) * 100

Loss Ratio LY =
CALCULATE([Loss Ratio], SAMEPERIODLASTYEAR(dim_date[full_date]))

Loss Ratio YoY Change = [Loss Ratio] - [Loss Ratio LY]

Agent Rank by Loss Ratio =
RANKX(ALL(dim_agents[agent_name]), CALCULATE([Loss Ratio]), , ASC)
```

## 4. What If Parameter: Fraud Score Threshold

Modeling tab, New Parameter, Numeric range, name it `Fraud Score Threshold`, minimum 0, maximum 1, increment 0.05, default 0.75. This creates a slicer and a `[Fraud Score Threshold Value]` measure automatically. Add this measure:

```
Claims Above Threshold =
CALCULATE(
    [Claim Count],
    fact_claims[fraud_score] >= [Fraud Score Threshold Value]
)

Premium at Risk if Threshold Changes =
CALCULATE(
    SUM(fact_claims[claim_amount]),
    fact_claims[fraud_score] >= [Fraud Score Threshold Value]
)
```

Use these two measures with the parameter slicer on the Fraud Risk page so a reviewer can drag the threshold and watch the flagged claim count and dollar exposure update live.

## 5. Forecasting

On the Trend Analysis page, build a line chart of `Loss Ratio` by `dim_date[full_date]` (month granularity). Select the visual, open the Analytics pane, add a Forecast, set forecast length to 6 periods, confidence interval 95 percent. This uses Power BI's built in exponential smoothing forecast engine, no external model needed.

## 6. Row Level Security (RLS)

Modeling tab, Manage Roles, create a role named `Regional Manager` with this table filter on `fact_policies`:

```
[region] = USERPRINCIPALNAME()
```

In practice this requires a mapping table (`region_access`) linking each viewer's email to their region; add that table, relate it to `fact_policies[region]`, and use `LOOKUPVALUE` in the role filter so each regional manager only sees their own region's policies and claims when the report is published and RLS is enforced through the Power BI Service.

## 7. Bookmarks

Create two bookmarks on the Executive Summary page named `View: Loss Ratio` and `View: Fraud Risk`. Each bookmark should capture a different visual state (one showing the loss ratio KPI cards and trend, the other showing fraud flagged claims and the threshold slicer). Add two buttons wired to these bookmarks using the Bookmarks pane so a presenter can toggle the story mid meeting without changing pages.

## 8. Drill Through

Create a hidden page named `Agent Detail`. Add `dim_agents[agent_id]` to the Drill through filters well. On the Agent Performance page, right click any agent in the table visual and select Drill Through to jump to the filtered detail page showing that agent's full policy and claims history.

## 9. Custom Tooltips

Create a small tooltip page (Page Information, set as a tooltip, canvas size 300 by 200). Add a card showing `Fraud Flag Rate %` and `Average Claim Severity` for the hovered claim type. Assign this tooltip page to the claim type bar chart on the KPI Dashboard page under Format, Tooltip.

## 10. Dynamic Titles

```
Dynamic Page Title =
"Loss Ratio and Fraud Risk — " &
SELECTEDVALUE(dim_agents[region], "All Regions") &
" | " & SELECTEDVALUE(dim_date[year], "All Years")
```

Bind this measure to a Card visual placed at the top of each page.

## 11. Dashboard Pages

**Page 1, Executive Summary.** KPI cards for Total Premium, Total Claims Paid, Loss Ratio, Underwriting Margin %, Renewal Rate %. A regional map colored by loss ratio. A trend line of loss ratio over the last twelve months. Bookmarks toggle buttons in the top right.

**Page 2, KPI Dashboard.** A full grid of every KPI in `KPI_Queries.sql`, laid out as cards and small multiples, filterable by year, region and policy type.

**Page 3, Customer Analytics.** Segmentation matrix (value versus risk, from `Advanced_Analysis.sql` section 5), renewal rate by segment, top 20 customers by lifetime premium table.

**Page 4, Geographic Analysis.** Filled map of loss ratio and fraud flag rate by state and region, with a slicer for policy type.

**Page 5, Trend Analysis.** Monthly loss ratio line chart with the six month forecast described above, plus a rolling three month moving average line for comparison.

**Page 6, Deep Dive: Fraud Risk.** The What If fraud score threshold slicer, a table of claims above threshold, and the tooltip enabled claim type bar chart.

**Page 7, Deep Dive: Agent Performance.** Agent scorecard table built from `vw_agent_scorecard`, ranked by loss ratio, with drill through enabled to the hidden Agent Detail page.

**Page 8, Recommendation Dashboard.** A text heavy executive storytelling page summarizing the findings and action plan from `Recommendations.md`, styled with large callout numbers (loss ratio improvement opportunity, revenue at risk, top three action items).

## 12. Suggested Visual Theme

Use a dark navy and white corporate theme (Format, Themes, Browse for themes, or use the built in "Executive" theme) to match the consulting deck look referenced throughout this repository.
