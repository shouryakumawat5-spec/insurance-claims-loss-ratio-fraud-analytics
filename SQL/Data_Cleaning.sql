/* ============================================================================
   PROJECT      : Insurance Claims Loss Ratio and Fraud Risk Analytics
   FILE         : Data_Cleaning.sql
   PURPOSE      : Cleans the staging tables loaded from /Dataset before they
                  are transformed into the star schema. Every fix below maps
                  to a real issue deliberately present in the raw CSV extract,
                  which mirrors what a first pass on a client data pull
                  usually looks like.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   1. CUSTOMERS: standardize state code casing and spacing, fix invalid zip
      codes, remove exact duplicate customer rows, fill missing segment
   ---------------------------------------------------------------------------- */

UPDATE stg_customers
SET state = UPPER(LTRIM(RTRIM(state)));

UPDATE stg_customers
SET zip = NULL
WHERE zip = '0000' OR LEN(LTRIM(RTRIM(zip))) < 5;

UPDATE stg_customers
SET segment = 'Unclassified'
WHERE segment IS NULL OR LTRIM(RTRIM(segment)) = '';

/* remove exact duplicate customer rows, keep the first occurrence */
WITH ranked_customers AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id, first_name, last_name, dob, state
               ORDER BY customer_id
           ) AS rn
    FROM stg_customers
)
DELETE FROM ranked_customers WHERE rn > 1;

/* ----------------------------------------------------------------------------
   2. POLICIES: validate premium values, standardize region text,
      flag orphan customer references for review
   ---------------------------------------------------------------------------- */

DELETE FROM stg_policies WHERE annual_premium IS NULL OR annual_premium <= 0;

UPDATE stg_policies
SET region = UPPER(LEFT(LTRIM(RTRIM(region)), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM(region)), 2, LEN(region)));

/* orphan check: policies pointing at a customer_id that does not exist
   in the cleaned customer table are logged, not silently dropped */
SELECT p.policy_id, p.customer_id
INTO stg_policy_orphans
FROM stg_policies p
LEFT JOIN stg_customers c ON c.customer_id = p.customer_id
WHERE c.customer_id IS NULL;

/* ----------------------------------------------------------------------------
   3. CLAIMS: fix negative claim_amount data entry errors, standardize blank
      claim_status to 'Pending Review', remove exact duplicate claim rows,
      cap unrealistic days_to_settle outliers
   ---------------------------------------------------------------------------- */

UPDATE stg_claims
SET claim_amount = ABS(claim_amount)
WHERE claim_amount < 0;

UPDATE stg_claims
SET claim_status = 'Pending Review'
WHERE claim_status IS NULL OR LTRIM(RTRIM(claim_status)) = '';

WITH ranked_claims AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY claim_id, policy_id, claim_date, claim_amount
               ORDER BY claim_id
           ) AS rn
    FROM stg_claims
)
DELETE FROM ranked_claims WHERE rn > 1;

/* days_to_settle should realistically fall between 1 and 180 days,
   anything outside that range is treated as a data entry issue and
   capped rather than dropped, to preserve the claim record itself */
UPDATE stg_claims SET days_to_settle = 180 WHERE days_to_settle > 180;
UPDATE stg_claims SET days_to_settle = 1   WHERE days_to_settle < 1;

/* adjuster_id can legitimately be missing for claims that have not yet
   been assigned, so it is left as NULL rather than defaulted, and is
   handled downstream with LEFT JOIN logic and a dedicated
   "Unassigned" bucket in Power BI */

/* ----------------------------------------------------------------------------
   4. VALIDATION CHECKS
      Run these after cleaning to confirm the staging layer is ready for
      Data_Transformation.sql. Each query should return zero rows.
   ---------------------------------------------------------------------------- */

-- Check 1: no negative claim amounts remain
SELECT * FROM stg_claims WHERE claim_amount < 0;

-- Check 2: no blank claim status remains
SELECT * FROM stg_claims WHERE claim_status IS NULL OR LTRIM(RTRIM(claim_status)) = '';

-- Check 3: no duplicate customer_id remains after de-duplication
SELECT customer_id, COUNT(*) AS cnt
FROM stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check 4: every policy's customer_id exists in the customer table
SELECT COUNT(*) AS orphan_policy_count FROM stg_policy_orphans;

-- Check 5: state codes are all valid two-letter uppercase codes
SELECT DISTINCT state FROM stg_customers WHERE LEN(state) <> 2 OR state <> UPPER(state);
