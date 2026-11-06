-- =====================================================================
-- schema.sql | Phase 5 | Credit Risk Analysis project
-- Database: credit_risk_db (PostgreSQL 18)
-- Creates the three lookup tables and the main customers table.
-- Run order for a rebuild: schema.sql -> import customers_for_db.csv -> views.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Lookup tables (meaning of the coded columns) and their contents
--    EDUCATION: codes 0, 5, 6 were merged into 4 ("Others") in Phase 3
--    MARRIAGE: code 0 kept as its own category ("Unknown")
-- ---------------------------------------------------------------------
CREATE TABLE dim_sex (
    sex_code  SMALLINT PRIMARY KEY,
    sex_label VARCHAR(10) NOT NULL
);

CREATE TABLE dim_education (
    education_code  SMALLINT PRIMARY KEY,
    education_label VARCHAR(20) NOT NULL
);

CREATE TABLE dim_marriage (
    marriage_code  SMALLINT PRIMARY KEY,
    marriage_label VARCHAR(20) NOT NULL
);

INSERT INTO dim_sex (sex_code, sex_label) VALUES
    (1, 'Male'),
    (2, 'Female');

INSERT INTO dim_education (education_code, education_label) VALUES
    (1, 'Graduate school'),
    (2, 'University'),
    (3, 'High school'),
    (4, 'Others');

INSERT INTO dim_marriage (marriage_code, marriage_label) VALUES
    (0, 'Unknown'),
    (1, 'Married'),
    (2, 'Single'),
    (3, 'Others');

-- ---------------------------------------------------------------------
-- 2. Main table: one row per customer, 25 columns.
--    Codes in sex/education/marriage must exist in the lookup tables.
--    Bill columns allow negative values (credit balances).
--    default_next_month is limited to 0 or 1.
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id        INTEGER PRIMARY KEY,
    limit_bal          INTEGER NOT NULL,
    sex                SMALLINT NOT NULL REFERENCES dim_sex(sex_code),
    education          SMALLINT NOT NULL REFERENCES dim_education(education_code),
    marriage           SMALLINT NOT NULL REFERENCES dim_marriage(marriage_code),
    age                SMALLINT NOT NULL,
    pay_1              SMALLINT NOT NULL,
    pay_2              SMALLINT NOT NULL,
    pay_3              SMALLINT NOT NULL,
    pay_4              SMALLINT NOT NULL,
    pay_5              SMALLINT NOT NULL,
    pay_6              SMALLINT NOT NULL,
    bill_amt1          INTEGER NOT NULL,
    bill_amt2          INTEGER NOT NULL,
    bill_amt3          INTEGER NOT NULL,
    bill_amt4          INTEGER NOT NULL,
    bill_amt5          INTEGER NOT NULL,
    bill_amt6          INTEGER NOT NULL,
    pay_amt1           INTEGER NOT NULL,
    pay_amt2           INTEGER NOT NULL,
    pay_amt3           INTEGER NOT NULL,
    pay_amt4           INTEGER NOT NULL,
    pay_amt5           INTEGER NOT NULL,
    pay_amt6           INTEGER NOT NULL,
    default_next_month SMALLINT NOT NULL CHECK (default_next_month IN (0, 1))
);

-- ---------------------------------------------------------------------
-- 3. Machine learning result tables (Phase 6), read by Power BI (Phase 7)
--    Filled from the CSV files exported by notebook 05_machine_learning.
--    Import order: model_comparison, model_test_results,
--    feature_importance, model_predictions.
-- ---------------------------------------------------------------------

-- Cross-validated performance of the three models (5-fold, training set)
CREATE TABLE model_comparison (
    model_name       VARCHAR(30) PRIMARY KEY,
    roc_auc          NUMERIC(6,4),
    recall           NUMERIC(6,4),
    precision_score  NUMERIC(6,4),
    f1_score         NUMERIC(6,4),
    accuracy         NUMERIC(6,4)
);

-- Final test-set performance of the selected model, with confusion matrix
CREATE TABLE model_test_results (
    model_name       VARCHAR(30) PRIMARY KEY,
    roc_auc          NUMERIC(6,4),
    recall           NUMERIC(6,4),
    precision_score  NUMERIC(6,4),
    f1_score         NUMERIC(6,4),
    accuracy         NUMERIC(6,4),
    true_negatives   INTEGER,
    false_positives  INTEGER,
    false_negatives  INTEGER,
    true_positives   INTEGER
);

-- Importance of each of the 28 features in the selected Random Forest
CREATE TABLE feature_importance (
    feature_name     VARCHAR(30) PRIMARY KEY,
    importance       NUMERIC(8,6),
    importance_rank  INTEGER
);

-- Predictions for the 6,000 test-set customers
-- (customer_id = row number + 1 in the modelling data)
CREATE TABLE model_predictions (
    customer_id            INTEGER PRIMARY KEY REFERENCES customers(customer_id),
    actual_default         SMALLINT CHECK (actual_default IN (0, 1)),
    predicted_probability  NUMERIC(7,6),
    predicted_default      SMALLINT CHECK (predicted_default IN (0, 1)),
    outcome                VARCHAR(20)
);
