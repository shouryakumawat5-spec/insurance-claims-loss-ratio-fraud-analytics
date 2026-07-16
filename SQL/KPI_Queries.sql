/* ============================================================================
   PROJECT      : Insurance Claims Loss Ratio and Fraud Risk Analytics
   FILE         : KPI_Queries.sql
   PURPOSE      : Business KPI queries used to power the Power BI dashboard
                  and to sanity check the numbers before they hit a slide.
   ============================================================================ */

/* 1. Loss ratio = total claims paid / total premium earned, overall and by year */
SELECT
    d.year,
    SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END) AS total_claims_paid,
    SUM(p.annual_premium)                                                       AS total_premium_earned,
    ROUND(
        SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END) * 1.0
        / NULLIF(SUM(p.annual_premium), 0), 4
    ) AS loss_ratio
FROM fact_claims cl
JOIN dim_date d      ON d.date_key = cl.date_key
JOIN fact_policies p ON p.policy_id = cl.policy_id
GROUP BY d.year
ORDER BY d.year;

/* 2. Claim frequency = claims per policy, by policy type */
SELECT
    p.policy_type,
    COUNT(DISTINCT p.policy_id)                        AS policy_count,
    COUNT(cl.claim_id)                                    AS claim_count,
    ROUND(COUNT(cl.claim_id) * 1.0 / COUNT(DISTINCT p.policy_id), 3) AS claim_frequency
FROM fact_policies p
LEFT JOIN fact_claims cl ON cl.policy_id = p.policy_id
GROUP BY p.policy_type
ORDER BY claim_frequency DESC;

/* 3. Average claim severity, overall and by claim type */
SELECT
    claim_type,
    COUNT(*)                          AS claim_count,
    ROUND(AVG(claim_amount), 2)         AS avg_claim_severity,
    ROUND(SUM(claim_amount), 2)           AS total_claim_amount
FROM fact_claims
GROUP BY claim_type
ORDER BY avg_claim_severity DESC;

/* 4. Fraud flagged claim percentage, by region */
SELECT
    region,
    COUNT(*)                                            AS total_claims,
    SUM(fraud_flag)                                       AS fraud_flagged_claims,
    ROUND(SUM(CAST(fraud_flag AS FLOAT)) / COUNT(*) * 100, 2) AS fraud_flag_pct
FROM fact_claims
GROUP BY region
ORDER BY fraud_flag_pct DESC;

/* 5. Claims processing time (average days_to_settle), by adjuster experience band */
SELECT
    CASE
        WHEN adj.experience_years < 3   THEN '0-2 years'
        WHEN adj.experience_years < 7   THEN '3-6 years'
        WHEN adj.experience_years < 12  THEN '7-11 years'
        ELSE '12+ years'
    END AS experience_band,
    COUNT(cl.claim_id)                    AS claims_handled,
    ROUND(AVG(cl.days_to_settle), 1)        AS avg_days_to_settle
FROM fact_claims cl
JOIN dim_adjusters adj ON adj.adjuster_id = cl.adjuster_id
GROUP BY CASE
        WHEN adj.experience_years < 3   THEN '0-2 years'
        WHEN adj.experience_years < 7   THEN '3-6 years'
        WHEN adj.experience_years < 12  THEN '7-11 years'
        ELSE '12+ years'
    END
ORDER BY avg_days_to_settle;

/* 6. Premium to claim ratio, by agent (top 20 agents by premium written) */
SELECT TOP 20
    a.agent_id,
    a.agent_name,
    a.agent_tier,
    SUM(p.annual_premium)                                       AS total_premium_written,
    SUM(ISNULL(cl.claim_amount, 0))                                AS total_claims_paid,
    ROUND(SUM(p.annual_premium) * 1.0 / NULLIF(SUM(ISNULL(cl.claim_amount, 0)), 0), 2) AS premium_to_claim_ratio
FROM fact_policies p
JOIN dim_agents a          ON a.agent_id = p.agent_id
LEFT JOIN fact_claims cl      ON cl.policy_id = p.policy_id AND cl.claim_status = 'Approved'
GROUP BY a.agent_id, a.agent_name, a.agent_tier
ORDER BY total_premium_written DESC;

/* 7. Policy renewal rate, by customer segment */
SELECT
    c.segment,
    COUNT(*)                                              AS total_policies,
    SUM(CASE WHEN p.renewed_flag = 'Y' THEN 1 ELSE 0 END)   AS renewed_policies,
    ROUND(SUM(CASE WHEN p.renewed_flag = 'Y' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2) AS renewal_rate_pct
FROM fact_policies p
JOIN dim_customers c ON c.customer_id = p.customer_id
GROUP BY c.segment
ORDER BY renewal_rate_pct DESC;

/* 8. Claims denied percentage, overall and trended by quarter */
SELECT
    d.year,
    d.quarter,
    COUNT(*)                                                       AS total_claims,
    SUM(CASE WHEN cl.claim_status = 'Denied' THEN 1 ELSE 0 END)      AS denied_claims,
    ROUND(SUM(CASE WHEN cl.claim_status = 'Denied' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2) AS denied_pct
FROM fact_claims cl
JOIN dim_date d ON d.date_key = cl.date_key
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

/* 9. Average settlement amount for approved claims, by state */
SELECT
    c.state,
    COUNT(*)                                    AS approved_claims,
    ROUND(AVG(cl.claim_amount), 2)                AS avg_settlement_amount
FROM fact_claims cl
JOIN dim_customers c ON c.customer_id = cl.customer_id
WHERE cl.claim_status = 'Approved'
GROUP BY c.state
ORDER BY avg_settlement_amount DESC;

/* 10. Underwriting profit margin proxy = (premium - claims paid) / premium, by region */
SELECT
    p.region,
    SUM(p.annual_premium)                                              AS total_premium,
    SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END) AS total_claims_paid,
    ROUND(
        (SUM(p.annual_premium) - SUM(CASE WHEN cl.claim_status = 'Approved' THEN cl.claim_amount ELSE 0 END))
        * 1.0 / NULLIF(SUM(p.annual_premium), 0) * 100, 2
    ) AS underwriting_margin_pct
FROM fact_policies p
LEFT JOIN fact_claims cl ON cl.policy_id = p.policy_id
GROUP BY p.region
ORDER BY underwriting_margin_pct DESC;
