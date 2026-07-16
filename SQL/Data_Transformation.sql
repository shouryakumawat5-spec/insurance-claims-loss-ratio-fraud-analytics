/* ============================================================================
   PROJECT      : Insurance Claims Loss Ratio and Fraud Risk Analytics
   FILE         : Data_Transformation.sql
   PURPOSE      : Builds the clean star schema (dim_customers, dim_agents,
                  dim_adjusters, dim_date, fact_policies, fact_claims) from
                  the cleaned staging tables. This is the layer Power BI
                  connects to.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   1. dim_date : generate a full calendar date dimension covering the
      claim history window, using a recursive CTE
   ---------------------------------------------------------------------------- */

WITH date_range AS (
    SELECT CAST('2021-01-01' AS DATE) AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM date_range
    WHERE full_date < '2025-12-31'
)
INSERT INTO dim_date (date_key, full_date, year, quarter, month, month_name, day_of_month, day_of_week)
SELECT
    CONVERT(INT, FORMAT(full_date, 'yyyyMMdd'))                AS date_key,
    full_date,
    YEAR(full_date)                                             AS year,
    DATEPART(QUARTER, full_date)                                AS quarter,
    MONTH(full_date)                                             AS month,
    DATENAME(MONTH, full_date)                                    AS month_name,
    DAY(full_date)                                                 AS day_of_month,
    DATENAME(WEEKDAY, full_date)                                    AS day_of_week
FROM date_range
OPTION (MAXRECURSION 0);

/* ----------------------------------------------------------------------------
   2. dim_customers : cast and load from the cleaned staging table
   ---------------------------------------------------------------------------- */

INSERT INTO dim_customers (customer_id, first_name, last_name, gender, dob, state, city, zip, customer_since_date, segment)
SELECT
    customer_id,
    TRIM(first_name),
    TRIM(last_name),
    gender,
    CAST(dob AS DATE),
    state,
    TRIM(city),
    zip,
    CAST(customer_since_date AS DATE),
    segment
FROM stg_customers;

/* ----------------------------------------------------------------------------
   3. dim_agents and dim_adjusters
   ---------------------------------------------------------------------------- */

INSERT INTO dim_agents (agent_id, agent_name, region, hire_date, agent_tier)
SELECT agent_id, TRIM(agent_name), region, CAST(hire_date AS DATE), agent_tier
FROM stg_agents;

INSERT INTO dim_adjusters (adjuster_id, adjuster_name, experience_years, region)
SELECT adjuster_id, TRIM(adjuster_name), experience_years, region
FROM stg_adjusters;

/* ----------------------------------------------------------------------------
   4. fact_policies
   ---------------------------------------------------------------------------- */

INSERT INTO fact_policies (policy_id, customer_id, agent_id, policy_type, policy_start_date,
                            policy_end_date, annual_premium, region, renewed_flag)
SELECT
    p.policy_id,
    p.customer_id,
    p.agent_id,
    p.policy_type,
    CAST(p.policy_start_date AS DATE),
    CAST(p.policy_end_date AS DATE),
    p.annual_premium,
    p.region,
    CASE WHEN p.renewed_flag = 'Yes' THEN 'Y' ELSE 'N' END
FROM stg_policies p
INNER JOIN stg_customers c ON c.customer_id = p.customer_id;   -- drop orphan policies

/* ----------------------------------------------------------------------------
   5. fact_claims : join to dim_date on the claim date, keep adjuster_id
      nullable for unassigned claims
   ---------------------------------------------------------------------------- */

INSERT INTO fact_claims (claim_id, policy_id, customer_id, adjuster_id, date_key, claim_type,
                          claim_amount, claim_status, days_to_settle, fraud_flag, fraud_score, region)
SELECT
    cl.claim_id,
    cl.policy_id,
    cl.customer_id,
    cl.adjuster_id,
    CONVERT(INT, FORMAT(CAST(cl.claim_date AS DATE), 'yyyyMMdd')) AS date_key,
    cl.claim_type,
    cl.claim_amount,
    cl.claim_status,
    cl.days_to_settle,
    cl.fraud_flag,
    cl.fraud_score,
    cl.region
FROM stg_claims cl
INNER JOIN fact_policies fp ON fp.policy_id = cl.policy_id;   -- claim must belong to a valid policy

/* ----------------------------------------------------------------------------
   6. VIEW: a clean claims analysis layer joining fact_claims to every
      dimension, used as the base for KPI and Power BI queries so that
      no report author has to repeat the same five-way join by hand
   ---------------------------------------------------------------------------- */

CREATE OR ALTER VIEW vw_claims_360 AS
SELECT
    cl.claim_id,
    cl.claim_type,
    cl.claim_amount,
    cl.claim_status,
    cl.days_to_settle,
    cl.fraud_flag,
    cl.fraud_score,
    cl.region,
    d.full_date        AS claim_date,
    d.year              AS claim_year,
    d.quarter             AS claim_quarter,
    d.month_name            AS claim_month,
    p.policy_id,
    p.policy_type,
    p.annual_premium,
    p.renewed_flag,
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.segment,
    c.state,
    a.agent_id,
    a.agent_name,
    a.agent_tier,
    adj.adjuster_id,
    adj.adjuster_name
FROM fact_claims cl
JOIN dim_date d          ON d.date_key = cl.date_key
JOIN fact_policies p      ON p.policy_id = cl.policy_id
JOIN dim_customers c        ON c.customer_id = cl.customer_id
JOIN dim_agents a             ON a.agent_id = p.agent_id
LEFT JOIN dim_adjusters adj      ON adj.adjuster_id = cl.adjuster_id;
