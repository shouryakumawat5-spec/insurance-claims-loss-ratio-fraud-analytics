# Data Dictionary

## dim_customers

| Column | Type | Description |
|---|---|---|
| customer_id | INT, PK | Unique identifier for the policy holder |
| first_name | VARCHAR(50) | Customer first name |
| last_name | VARCHAR(50) | Customer last name |
| gender | VARCHAR(5) | M or F |
| dob | DATE | Date of birth |
| state | CHAR(2) | Two letter US state code, standardized during cleaning |
| city | VARCHAR(50) | City of residence |
| zip | VARCHAR(5) | Five digit zip code, invalid codes set to NULL during cleaning |
| customer_since_date | DATE | Date the customer first became a policy holder |
| segment | VARCHAR(20) | Standard, Preferred, High Value, New, or Unclassified |

## dim_agents

| Column | Type | Description |
|---|---|---|
| agent_id | INT, PK | Unique identifier for the sales agent |
| agent_name | VARCHAR(100) | Full name of the agent |
| region | VARCHAR(20) | Sales region the agent operates in |
| hire_date | DATE | Date the agent joined the company |
| agent_tier | VARCHAR(10) | Bronze, Silver, or Gold performance tier |

## dim_adjusters

| Column | Type | Description |
|---|---|---|
| adjuster_id | INT, PK | Unique identifier for the claims adjuster |
| adjuster_name | VARCHAR(100) | Full name of the adjuster |
| experience_years | INT | Years of claims handling experience |
| region | VARCHAR(20) | Region the adjuster primarily handles |

## dim_date

| Column | Type | Description |
|---|---|---|
| date_key | INT, PK | Integer date key in YYYYMMDD format |
| full_date | DATE | Calendar date |
| year | INT | Calendar year |
| quarter | INT | Calendar quarter, 1 to 4 |
| month | INT | Calendar month, 1 to 12 |
| month_name | VARCHAR(15) | Month name, for example January |
| day_of_month | INT | Day number within the month |
| day_of_week | VARCHAR(15) | Day name, for example Monday |

## fact_policies

| Column | Type | Description |
|---|---|---|
| policy_id | INT, PK | Unique identifier for the policy |
| customer_id | INT, FK | References dim_customers |
| agent_id | INT, FK | References dim_agents |
| policy_type | VARCHAR(20) | Auto, Home, Life, or Health |
| policy_start_date | DATE | Policy inception date |
| policy_end_date | DATE | Policy term end date, one year after start |
| annual_premium | DECIMAL(12,2) | Annual premium charged to the customer |
| region | VARCHAR(20) | Region the policy was written in |
| renewed_flag | CHAR(1) | Y if the policy was renewed at term end, otherwise N |

## fact_claims

| Column | Type | Description |
|---|---|---|
| claim_id | INT, PK | Unique identifier for the claim |
| policy_id | INT, FK | References fact_policies |
| customer_id | INT, FK | References dim_customers |
| adjuster_id | INT, FK, nullable | References dim_adjusters, NULL if unassigned |
| date_key | INT, FK | References dim_date, the date the claim was filed |
| claim_type | VARCHAR(20) | Matches the related policy_type |
| claim_amount | DECIMAL(12,2) | Dollar amount of the claim |
| claim_status | VARCHAR(20) | Approved, Denied, or Pending Review |
| days_to_settle | INT | Number of days between filing and settlement, capped at 1 to 180 |
| fraud_flag | BIT | 1 if the claim was flagged for potential fraud, otherwise 0 |
| fraud_score | DECIMAL(4,2) | Composite fraud risk score between 0 and 1 |
| region | VARCHAR(20) | Region the claim was filed in |

## Derived Objects

`vw_claims_360` is a view joining fact_claims to every dimension table, used as the base layer for reporting so no query has to repeat the same five way join.

`vw_agent_scorecard` is a view combining agent productivity, loss ratio, and renewal rate into a single row per agent, used directly by the agent performance page in Power BI.

`usp_FlagHighRiskClaims` is a stored procedure that returns claims above a caller supplied fraud score threshold and above the regional average claim amount, used as a rules based fraud triage tool.
