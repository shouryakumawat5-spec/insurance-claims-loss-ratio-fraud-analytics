/* ============================================================================
   PROJECT      : Insurance Claims Loss Ratio and Fraud Risk Analytics
   FILE         : Schema.sql
   PURPOSE      : Creates the staging (raw) layer used to load the CSV files
                  in /Dataset, and the clean star schema layer that the rest
                  of the SQL scripts and the Power BI model are built on.
   DIALECT      : T-SQL (Microsoft SQL Server / Azure SQL Database).
                  Minor syntax changes are needed for PostgreSQL, noted inline.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   1. STAGING LAYER  (raw, as-extracted data, loaded directly from /Dataset)
   ---------------------------------------------------------------------------- */

DROP TABLE IF EXISTS stg_customers;
CREATE TABLE stg_customers (
    customer_id            INT,
    first_name              VARCHAR(50),
    last_name               VARCHAR(50),
    gender                   VARCHAR(5),
    dob                       VARCHAR(20),
    state                     VARCHAR(10),
    city                      VARCHAR(50),
    zip                       VARCHAR(10),
    customer_since_date       VARCHAR(20),
    segment                   VARCHAR(20)
);

DROP TABLE IF EXISTS stg_agents;
CREATE TABLE stg_agents (
    agent_id        INT,
    agent_name       VARCHAR(100),
    region            VARCHAR(20),
    hire_date         VARCHAR(20),
    agent_tier        VARCHAR(10)
);

DROP TABLE IF EXISTS stg_adjusters;
CREATE TABLE stg_adjusters (
    adjuster_id       INT,
    adjuster_name      VARCHAR(100),
    experience_years    INT,
    region               VARCHAR(20)
);

DROP TABLE IF EXISTS stg_policies;
CREATE TABLE stg_policies (
    policy_id           INT,
    customer_id          INT,
    policy_type           VARCHAR(20),
    policy_start_date      VARCHAR(20),
    policy_end_date        VARCHAR(20),
    annual_premium          DECIMAL(12,2),
    agent_id                 INT,
    region                     VARCHAR(20),
    renewed_flag                VARCHAR(5)
);

DROP TABLE IF EXISTS stg_claims;
CREATE TABLE stg_claims (
    claim_id            INT,
    policy_id             INT,
    customer_id            INT,
    adjuster_id              INT,
    claim_date                 VARCHAR(20),
    claim_type                   VARCHAR(20),
    claim_amount                   DECIMAL(12,2),
    claim_status                     VARCHAR(20),
    days_to_settle                     INT,
    fraud_flag                           INT,
    fraud_score                            DECIMAL(4,2),
    region                                    VARCHAR(20)
);

/* Load with BULK INSERT / bcp / Import Wizard, for example:
   BULK INSERT stg_customers FROM 'Dataset\customers_raw.csv'
   WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);
   Repeat for stg_agents, stg_adjusters, stg_policies, stg_claims. */

/* ----------------------------------------------------------------------------
   2. CLEAN STAR SCHEMA LAYER  (populated by Data_Cleaning.sql and
      Data_Transformation.sql, this is the layer Power BI connects to)
   ---------------------------------------------------------------------------- */

DROP TABLE IF EXISTS fact_claims;
DROP TABLE IF EXISTS fact_policies;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_agents;
DROP TABLE IF EXISTS dim_adjusters;
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_customers (
    customer_id         INT           NOT NULL,
    first_name           VARCHAR(50)   NOT NULL,
    last_name             VARCHAR(50)   NOT NULL,
    gender                 VARCHAR(5),
    dob                     DATE,
    state                     CHAR(2)       NOT NULL,
    city                       VARCHAR(50),
    zip                         VARCHAR(5),
    customer_since_date           DATE          NOT NULL,
    segment                         VARCHAR(20)   NOT NULL DEFAULT 'Unclassified',
    CONSTRAINT pk_dim_customers PRIMARY KEY (customer_id)
);

CREATE TABLE dim_agents (
    agent_id        INT             NOT NULL,
    agent_name       VARCHAR(100)    NOT NULL,
    region             VARCHAR(20)     NOT NULL,
    hire_date            DATE            NOT NULL,
    agent_tier             VARCHAR(10)     NOT NULL,
    CONSTRAINT pk_dim_agents PRIMARY KEY (agent_id)
);

CREATE TABLE dim_adjusters (
    adjuster_id       INT            NOT NULL,
    adjuster_name       VARCHAR(100)   NOT NULL,
    experience_years       INT            NOT NULL,
    region                    VARCHAR(20)    NOT NULL,
    CONSTRAINT pk_dim_adjusters PRIMARY KEY (adjuster_id)
);

CREATE TABLE dim_date (
    date_key       INT           NOT NULL,
    full_date        DATE          NOT NULL,
    year               INT           NOT NULL,
    quarter              INT           NOT NULL,
    month                  INT           NOT NULL,
    month_name               VARCHAR(15)   NOT NULL,
    day_of_month                INT           NOT NULL,
    day_of_week                    VARCHAR(15)   NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
);

CREATE TABLE fact_policies (
    policy_id           INT            NOT NULL,
    customer_id           INT            NOT NULL,
    agent_id                INT            NOT NULL,
    policy_type                VARCHAR(20)    NOT NULL,
    policy_start_date             DATE           NOT NULL,
    policy_end_date                  DATE           NOT NULL,
    annual_premium                      DECIMAL(12,2)  NOT NULL CHECK (annual_premium > 0),
    region                                  VARCHAR(20)    NOT NULL,
    renewed_flag                              CHAR(1)        NOT NULL DEFAULT 'N',
    CONSTRAINT pk_fact_policies PRIMARY KEY (policy_id),
    CONSTRAINT fk_policies_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT fk_policies_agent    FOREIGN KEY (agent_id)    REFERENCES dim_agents(agent_id)
);

CREATE TABLE fact_claims (
    claim_id           INT             NOT NULL,
    policy_id            INT             NOT NULL,
    customer_id             INT             NOT NULL,
    adjuster_id                INT,
    date_key                      INT             NOT NULL,
    claim_type                       VARCHAR(20)     NOT NULL,
    claim_amount                        DECIMAL(12,2)   NOT NULL CHECK (claim_amount >= 0),
    claim_status                           VARCHAR(20)     NOT NULL,
    days_to_settle                            INT,
    fraud_flag                                   BIT             NOT NULL DEFAULT 0,
    fraud_score                                     DECIMAL(4,2),
    region                                             VARCHAR(20)     NOT NULL,
    CONSTRAINT pk_fact_claims PRIMARY KEY (claim_id),
    CONSTRAINT fk_claims_policy    FOREIGN KEY (policy_id)   REFERENCES fact_policies(policy_id),
    CONSTRAINT fk_claims_customer  FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT fk_claims_adjuster  FOREIGN KEY (adjuster_id) REFERENCES dim_adjusters(adjuster_id),
    CONSTRAINT fk_claims_date      FOREIGN KEY (date_key)    REFERENCES dim_date(date_key)
);

CREATE INDEX ix_fact_claims_policy   ON fact_claims(policy_id);
CREATE INDEX ix_fact_claims_customer ON fact_claims(customer_id);
CREATE INDEX ix_fact_claims_date     ON fact_claims(date_key);
CREATE INDEX ix_fact_policies_agent  ON fact_policies(agent_id);
