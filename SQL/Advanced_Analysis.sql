/* ============================================================================
   PROJECT      : Insurance Claims Loss Ratio and Fraud Risk Analytics
   FILE         : Advanced_Analysis.sql
   PURPOSE      : Demonstrates advanced SQL, ranking with window functions,
                  cohort and retention analysis, a claims funnel, a stored
                  procedure, a reusable view, and temp table staging.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   1. WINDOW FUNCTIONS: rank agents by loss ratio within their own region,
      so a regional manager only sees agents compared against local peers
   ---------------------------------------------------------------------------- */

WITH agent_loss AS (
    SELECT
        a.agent_id,
        a.agent_name,
        a.region,
        SUM(p.annual_premium)                                              AS total_premium,
        SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END) AS total_claims_paid
    FROM fact_policies p
    JOIN dim_agents a          ON a.agent_id = p.agent_id
    LEFT JOIN fact_claims cl      ON cl.policy_id = p.policy_id
    GROUP BY a.agent_id, a.agent_name, a.region
)
SELECT
    agent_id,
    agent_name,
    region,
    total_premium,
    total_claims_paid,
    ROUND(total_claims_paid * 1.0 / NULLIF(total_premium, 0), 4)                       AS loss_ratio,
    RANK() OVER (PARTITION BY region ORDER BY total_claims_paid * 1.0 / NULLIF(total_premium, 0) ASC) AS rank_in_region,
    NTILE(4) OVER (ORDER BY total_claims_paid * 1.0 / NULLIF(total_premium, 0))         AS loss_ratio_quartile
FROM agent_loss
ORDER BY region, rank_in_region;

/* ----------------------------------------------------------------------------
   2. TIME SERIES: month over month loss ratio trend with a rolling
      three month moving average, using window functions
   ---------------------------------------------------------------------------- */

WITH monthly AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END) AS claims_paid,
        SUM(p.annual_premium) / 12.0                                                  AS premium_earned_in_month
    FROM fact_claims cl
    JOIN dim_date d      ON d.date_key = cl.date_key
    JOIN fact_policies p ON p.policy_id = cl.policy_id
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    year,
    month,
    month_name,
    claims_paid,
    ROUND(claims_paid / NULLIF(premium_earned_in_month, 0), 4)                                            AS monthly_loss_ratio,
    ROUND(AVG(claims_paid / NULLIF(premium_earned_in_month, 0)) OVER (
        ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 4)                                                                                                  AS rolling_3mo_avg_loss_ratio
FROM monthly
ORDER BY year, month;

/* ----------------------------------------------------------------------------
   3. COHORT ANALYSIS: group customers by the year their policy started,
      and track claim rate for each cohort over subsequent policy years
   ---------------------------------------------------------------------------- */

WITH cohort_base AS (
    SELECT
        p.customer_id,
        MIN(YEAR(p.policy_start_date)) AS cohort_year
    FROM fact_policies p
    GROUP BY p.customer_id
),
cohort_claims AS (
    SELECT
        cb.cohort_year,
        YEAR(d.full_date)                                     AS claim_year,
        COUNT(DISTINCT cl.customer_id)                          AS customers_with_claims,
        COUNT(cl.claim_id)                                        AS total_claims
    FROM cohort_base cb
    JOIN fact_claims cl ON cl.customer_id = cb.customer_id
    JOIN dim_date d       ON d.date_key = cl.date_key
    GROUP BY cb.cohort_year, YEAR(d.full_date)
)
SELECT
    cohort_year,
    claim_year,
    claim_year - cohort_year AS years_since_acquisition,
    customers_with_claims,
    total_claims
FROM cohort_claims
ORDER BY cohort_year, claim_year;

/* ----------------------------------------------------------------------------
   4. CLAIMS FUNNEL: submitted -> under review -> approved / denied, with
      drop off percentage at each stage
   ---------------------------------------------------------------------------- */

WITH funnel AS (
    SELECT
        COUNT(*)                                                     AS submitted,
        SUM(CASE WHEN claim_status IN ('Approved','Denied') THEN 1 ELSE 0 END) AS reviewed,
        SUM(CASE WHEN claim_status = 'Approved' THEN 1 ELSE 0 END)              AS approved,
        SUM(CASE WHEN claim_status = 'Denied' THEN 1 ELSE 0 END)                  AS denied
    FROM fact_claims
)
SELECT
    submitted,
    reviewed,
    approved,
    denied,
    ROUND(reviewed * 100.0 / submitted, 2) AS pct_reviewed,
    ROUND(approved * 100.0 / submitted, 2) AS pct_approved,
    ROUND(denied  * 100.0 / submitted, 2)  AS pct_denied
FROM funnel;

/* ----------------------------------------------------------------------------
   5. CUSTOMER SEGMENTATION: classify customers into a simple risk and
      value matrix using a CTE and CASE logic, ready to feed a Power BI
      segmentation matrix visual
   ---------------------------------------------------------------------------- */

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.segment                                                          AS declared_segment,
        SUM(p.annual_premium)                                                AS lifetime_premium,
        COUNT(cl.claim_id)                                                     AS lifetime_claims,
        SUM(CASE WHEN cl.fraud_flag = 1 THEN 1 ELSE 0 END)                      AS fraud_flagged_claims
    FROM dim_customers c
    JOIN fact_policies p     ON p.customer_id = c.customer_id
    LEFT JOIN fact_claims cl    ON cl.customer_id = c.customer_id
    GROUP BY c.customer_id, c.segment
)
SELECT
    customer_id,
    declared_segment,
    lifetime_premium,
    lifetime_claims,
    fraud_flagged_claims,
    CASE
        WHEN lifetime_premium >= 5000 AND lifetime_claims <= 1 THEN 'High Value Low Risk'
        WHEN lifetime_premium >= 5000 AND lifetime_claims > 1  THEN 'High Value High Risk'
        WHEN lifetime_premium <  5000 AND lifetime_claims <= 1 THEN 'Standard Low Risk'
        ELSE 'Standard High Risk'
    END AS value_risk_segment
FROM customer_metrics;

/* ----------------------------------------------------------------------------
   6. RETENTION ANALYSIS: policy renewal rate by tenure band, using a
      temp table for staged intermediate results
   ---------------------------------------------------------------------------- */

DROP TABLE IF EXISTS #tenure_staging;

SELECT
    p.policy_id,
    p.customer_id,
    p.renewed_flag,
    DATEDIFF(YEAR, c.customer_since_date, p.policy_start_date) AS tenure_years
INTO #tenure_staging
FROM fact_policies p
JOIN dim_customers c ON c.customer_id = p.customer_id;

SELECT
    CASE
        WHEN tenure_years < 1  THEN '0. New (< 1 year)'
        WHEN tenure_years < 3  THEN '1. 1-2 years'
        WHEN tenure_years < 6  THEN '2. 3-5 years'
        ELSE '3. 6+ years'
    END AS tenure_band,
    COUNT(*)                                                    AS policy_count,
    SUM(CASE WHEN renewed_flag = 'Y' THEN 1 ELSE 0 END)           AS renewed_count,
    ROUND(SUM(CASE WHEN renewed_flag = 'Y' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2) AS retention_rate_pct
FROM #tenure_staging
GROUP BY CASE
        WHEN tenure_years < 1  THEN '0. New (< 1 year)'
        WHEN tenure_years < 3  THEN '1. 1-2 years'
        WHEN tenure_years < 6  THEN '2. 3-5 years'
        ELSE '3. 6+ years'
    END
ORDER BY tenure_band;

DROP TABLE IF EXISTS #tenure_staging;

/* ----------------------------------------------------------------------------
   7. STORED PROCEDURE: flags claims as high fraud risk when the fraud
      score exceeds a caller supplied threshold and the claim amount is
      above the regional average, then returns the flagged set
   ---------------------------------------------------------------------------- */

CREATE OR ALTER PROCEDURE usp_FlagHighRiskClaims
    @FraudScoreThreshold DECIMAL(4,2) = 0.80
AS
BEGIN
    SET NOCOUNT ON;

    WITH regional_avg AS (
        SELECT region, AVG(claim_amount) AS avg_claim_amount
        FROM fact_claims
        GROUP BY region
    )
    SELECT
        cl.claim_id,
        cl.customer_id,
        cl.region,
        cl.claim_amount,
        ra.avg_claim_amount,
        cl.fraud_score,
        cl.fraud_flag
    FROM fact_claims cl
    JOIN regional_avg ra ON ra.region = cl.region
    WHERE cl.fraud_score >= @FraudScoreThreshold
      AND cl.claim_amount > ra.avg_claim_amount
    ORDER BY cl.fraud_score DESC;
END;
GO

-- Example call:
-- EXEC usp_FlagHighRiskClaims @FraudScoreThreshold = 0.75;

/* ----------------------------------------------------------------------------
   8. VIEW: agent scorecard, combining productivity and loss ratio into a
      single reusable object for both ad hoc SQL analysis and Power BI
   ---------------------------------------------------------------------------- */

CREATE OR ALTER VIEW vw_agent_scorecard AS
SELECT
    a.agent_id,
    a.agent_name,
    a.region,
    a.agent_tier,
    COUNT(DISTINCT p.policy_id)                                                AS policies_sold,
    SUM(p.annual_premium)                                                        AS total_premium_written,
    SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END)     AS total_claims_paid,
    ROUND(
        SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END) * 1.0
        / NULLIF(SUM(p.annual_premium), 0), 4
    )                                                                                 AS loss_ratio,
    ROUND(SUM(CASE WHEN p.renewed_flag = 'Y' THEN 1.0 ELSE 0 END) / COUNT(DISTINCT p.policy_id) * 100, 2) AS renewal_rate_pct
FROM dim_agents a
JOIN fact_policies p     ON p.agent_id = a.agent_id
LEFT JOIN fact_claims cl    ON cl.policy_id = p.policy_id
GROUP BY a.agent_id, a.agent_name, a.region, a.agent_tier;
