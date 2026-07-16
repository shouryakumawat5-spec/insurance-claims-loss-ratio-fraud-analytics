/* ============================================================================
   PROJECT      : Insurance Claims Loss Ratio and Fraud Risk Analytics
   FILE         : Data_Generation.sql (SQLite dialect)
   PURPOSE      : This is the actual script used to synthesize the raw
                  dataset shipped in /Dataset. Included for transparency.
                  It is a build utility, not part of the analytics layer.
                  Run it with any SQLite client to reproduce the dataset.
   ============================================================================ */

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS seed_first_names;
DROP TABLE IF EXISTS seed_last_names;
DROP TABLE IF EXISTS seed_states;
DROP TABLE IF EXISTS seed_cities;
DROP TABLE IF EXISTS raw_customers;
DROP TABLE IF EXISTS raw_agents;
DROP TABLE IF EXISTS raw_adjusters;
DROP TABLE IF EXISTS raw_policies;
DROP TABLE IF EXISTS raw_claims;

CREATE TABLE seed_first_names (id INTEGER PRIMARY KEY, name TEXT);
INSERT INTO seed_first_names (id, name) VALUES
(0,'James'),(1,'Mary'),(2,'Robert'),(3,'Patricia'),(4,'John'),(5,'Jennifer'),(6,'Michael'),(7,'Linda'),
(8,'William'),(9,'Elizabeth'),(10,'David'),(11,'Barbara'),(12,'Richard'),(13,'Susan'),(14,'Joseph'),(15,'Jessica'),
(16,'Thomas'),(17,'Sarah'),(18,'Charles'),(19,'Karen'),(20,'Christopher'),(21,'Nancy'),(22,'Daniel'),(23,'Lisa'),
(24,'Matthew'),(25,'Betty'),(26,'Anthony'),(27,'Margaret'),(28,'Mark'),(29,'Sandra'),(30,'Donald'),(31,'Ashley'),
(32,'Steven'),(33,'Kimberly'),(34,'Paul'),(35,'Emily'),(36,'Andrew'),(37,'Donna'),(38,'Joshua'),(39,'Michelle');

CREATE TABLE seed_last_names (id INTEGER PRIMARY KEY, name TEXT);
INSERT INTO seed_last_names (id, name) VALUES
(0,'Smith'),(1,'Johnson'),(2,'Williams'),(3,'Brown'),(4,'Jones'),(5,'Garcia'),(6,'Miller'),(7,'Davis'),
(8,'Rodriguez'),(9,'Martinez'),(10,'Hernandez'),(11,'Lopez'),(12,'Gonzalez'),(13,'Wilson'),(14,'Anderson'),(15,'Thomas'),
(16,'Taylor'),(17,'Moore'),(18,'Jackson'),(19,'Martin'),(20,'Lee'),(21,'Perez'),(22,'Thompson'),(23,'White'),
(24,'Harris'),(25,'Sanchez'),(26,'Clark'),(27,'Ramirez'),(28,'Lewis'),(29,'Robinson'),(30,'Walker'),(31,'Young'),
(32,'Allen'),(33,'King'),(34,'Wright'),(35,'Scott'),(36,'Torres'),(37,'Nguyen'),(38,'Hill'),(39,'Flores');

CREATE TABLE seed_states (id INTEGER PRIMARY KEY, code TEXT, name TEXT, region TEXT);
INSERT INTO seed_states (id, code, name, region) VALUES
(0,'CA','California','West'),(1,'TX','Texas','South'),(2,'NY','New York','Northeast'),(3,'FL','Florida','South'),
(4,'IL','Illinois','Midwest'),(5,'PA','Pennsylvania','Northeast'),(6,'OH','Ohio','Midwest'),(7,'GA','Georgia','South'),
(8,'NC','North Carolina','South'),(9,'MI','Michigan','Midwest'),(10,'AZ','Arizona','West'),(11,'WA','Washington','West'),
(12,'MA','Massachusetts','Northeast'),(13,'CO','Colorado','West'),(14,'VA','Virginia','South');

CREATE TABLE seed_cities (id INTEGER PRIMARY KEY, city TEXT, state_id INTEGER);
INSERT INTO seed_cities (id, city, state_id) VALUES
(0,'Los Angeles',0),(1,'San Diego',0),(2,'Houston',1),(3,'Austin',1),(4,'New York City',2),(5,'Buffalo',2),
(6,'Miami',3),(7,'Orlando',3),(8,'Chicago',4),(9,'Springfield',4),(10,'Philadelphia',5),(11,'Pittsburgh',5),
(12,'Columbus',6),(13,'Cleveland',6),(14,'Atlanta',7),(15,'Savannah',7),(16,'Charlotte',8),(17,'Raleigh',8),
(18,'Detroit',9),(19,'Ann Arbor',9),(20,'Phoenix',10),(21,'Tucson',10),(22,'Seattle',11),(23,'Spokane',11),
(24,'Boston',12),(25,'Worcester',12),(26,'Denver',13),(27,'Boulder',13),(28,'Richmond',14),(29,'Norfolk',14);

CREATE TABLE raw_customers (
  customer_id INTEGER, first_name TEXT, last_name TEXT, gender TEXT, dob TEXT,
  state TEXT, city TEXT, zip TEXT, customer_since_date TEXT, segment TEXT
);

WITH RECURSIVE tally(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM tally WHERE n < 5000
)
INSERT INTO raw_customers
SELECT
  n,
  (SELECT name FROM seed_first_names WHERE id = ABS(RANDOM()) % 40),
  (SELECT name FROM seed_last_names WHERE id = ABS(RANDOM()) % 40),
  CASE WHEN ABS(RANDOM()) % 2 = 0 THEN 'M' ELSE 'F' END,
  date('1945-01-01', '+' || (ABS(RANDOM()) % 27740) || ' days'),
  CASE
    WHEN n % 37 = 0 THEN LOWER((SELECT code FROM seed_states WHERE id = ABS(RANDOM()) % 15))
    WHEN n % 53 = 0 THEN '  ' || (SELECT code FROM seed_states WHERE id = ABS(RANDOM()) % 15) || '  '
    ELSE (SELECT code FROM seed_states WHERE id = ABS(RANDOM()) % 15)
  END,
  (SELECT city FROM seed_cities WHERE id = ABS(RANDOM()) % 30),
  CASE WHEN n % 61 = 0 THEN '0000' ELSE printf('%05d', 10000 + ABS(RANDOM()) % 89999) END,
  date('2010-01-01', '+' || (ABS(RANDOM()) % 5570) || ' days'),
  CASE
    WHEN n % 23 = 0 THEN NULL
    ELSE (CASE ABS(RANDOM()) % 4 WHEN 0 THEN 'Standard' WHEN 1 THEN 'Preferred' WHEN 2 THEN 'High Value' ELSE 'New' END)
  END
FROM tally;

INSERT INTO raw_customers
SELECT customer_id, first_name, last_name, gender, dob, state, city, zip, customer_since_date, segment
FROM raw_customers WHERE customer_id % 125 = 0;

CREATE TABLE raw_agents (
  agent_id INTEGER, agent_name TEXT, region TEXT, hire_date TEXT, agent_tier TEXT
);

WITH RECURSIVE tally(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM tally WHERE n < 120
)
INSERT INTO raw_agents
SELECT
  n,
  (SELECT name FROM seed_first_names WHERE id = ABS(RANDOM()) % 40) || ' ' || (SELECT name FROM seed_last_names WHERE id = ABS(RANDOM()) % 40),
  (SELECT region FROM seed_states WHERE id = ABS(RANDOM()) % 15),
  date('2008-01-01', '+' || (ABS(RANDOM()) % 6209) || ' days'),
  CASE ABS(RANDOM()) % 3 WHEN 0 THEN 'Bronze' WHEN 1 THEN 'Silver' ELSE 'Gold' END
FROM tally;

CREATE TABLE raw_adjusters (
  adjuster_id INTEGER, adjuster_name TEXT, experience_years INTEGER, region TEXT
);

WITH RECURSIVE tally(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM tally WHERE n < 40
)
INSERT INTO raw_adjusters
SELECT
  n,
  (SELECT name FROM seed_first_names WHERE id = ABS(RANDOM()) % 40) || ' ' || (SELECT name FROM seed_last_names WHERE id = ABS(RANDOM()) % 40),
  1 + ABS(RANDOM()) % 22,
  (SELECT region FROM seed_states WHERE id = ABS(RANDOM()) % 15)
FROM tally;

CREATE TABLE raw_policies (
  policy_id INTEGER, customer_id INTEGER, policy_type TEXT, policy_start_date TEXT,
  policy_end_date TEXT, annual_premium REAL, agent_id INTEGER, region TEXT, renewed_flag TEXT
);

WITH RECURSIVE tally(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM tally WHERE n < 8000
),
typed AS (
  SELECT n,
    CASE
      WHEN ABS(RANDOM()) % 100 < 45 THEN 'Auto'
      WHEN ABS(RANDOM()) % 100 < 75 THEN 'Home'
      WHEN ABS(RANDOM()) % 100 < 90 THEN 'Life'
      ELSE 'Health'
    END AS policy_type,
    date('2021-01-01', '+' || (ABS(RANDOM()) % 1461) || ' days') AS pstart
  FROM tally
)
INSERT INTO raw_policies
SELECT
  t.n,
  1 + ABS(RANDOM()) % 5000,
  t.policy_type,
  t.pstart,
  date(t.pstart, '+365 days'),
  ROUND(
    CASE t.policy_type
      WHEN 'Auto' THEN 900 + ABS(RANDOM()) % 1600
      WHEN 'Home' THEN 1200 + ABS(RANDOM()) % 2400
      WHEN 'Life' THEN 400 + ABS(RANDOM()) % 2000
      ELSE 2500 + ABS(RANDOM()) % 4500
    END, 2),
  1 + ABS(RANDOM()) % 120,
  (SELECT region FROM seed_states WHERE id = ABS(RANDOM()) % 15),
  CASE WHEN ABS(RANDOM()) % 100 < 78 THEN 'Yes' ELSE 'No' END
FROM typed t;

CREATE INDEX idx_raw_policies_pid ON raw_policies(policy_id);

CREATE TABLE raw_claims (
  claim_id INTEGER, policy_id INTEGER, customer_id INTEGER, adjuster_id INTEGER,
  claim_date TEXT, claim_type TEXT, claim_amount REAL, claim_status TEXT,
  days_to_settle INTEGER, fraud_flag INTEGER, fraud_score REAL, region TEXT
);

WITH RECURSIVE tally(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM tally WHERE n < 15000
),
picked AS (
  SELECT n, 1 + ABS(RANDOM()) % 8000 AS pid FROM tally
)
INSERT INTO raw_claims
SELECT
  p.n,
  p.pid,
  (SELECT customer_id FROM raw_policies WHERE policy_id = p.pid),
  CASE WHEN p.n % 41 = 0 THEN NULL ELSE 1 + ABS(RANDOM()) % 40 END,
  date((SELECT policy_start_date FROM raw_policies WHERE policy_id = p.pid), '+' || (ABS(RANDOM()) % 360) || ' days'),
  (SELECT policy_type FROM raw_policies WHERE policy_id = p.pid),
  ROUND(
    CASE WHEN p.n % 977 = 0 THEN -1 * (500 + ABS(RANDOM()) % 4000)
    ELSE (300 + ABS(RANDOM()) % 18000) END, 2),
  CASE
    WHEN p.n % 89 = 0 THEN ''
    WHEN ABS(RANDOM()) % 100 < 68 THEN 'Approved'
    WHEN ABS(RANDOM()) % 100 < 85 THEN 'Denied'
    ELSE 'Pending'
  END,
  3 + ABS(RANDOM()) % 60,
  CASE WHEN ABS(RANDOM()) % 100 < 6 THEN 1 ELSE 0 END,
  ROUND(ABS(RANDOM()) % 100 / 100.0, 2),
  (SELECT region FROM raw_policies WHERE policy_id = p.pid)
FROM picked p;

INSERT INTO raw_claims
SELECT claim_id, policy_id, customer_id, adjuster_id, claim_date, claim_type, claim_amount, claim_status, days_to_settle, fraud_flag, fraud_score, region
FROM raw_claims WHERE claim_id % 733 = 0;
