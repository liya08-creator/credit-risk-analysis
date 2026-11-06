-- =====================================================================
-- views.sql | Phase 5 | Views for analysis and Power BI
-- Run after schema.sql and after the data has been imported.
-- vw_default_by_segment reads from vw_customer_profile, so the order matters.
-- =====================================================================

-- ---------------------------------------------------------------------
-- View 1: one row per customer with labels and derived columns
--   (age_group, limit_band, pay_1_group, months_late, zero_pay_months,
--    pay_ratio, risk_tier, default_label)
-- ---------------------------------------------------------------------
CREATE VIEW vw_customer_profile AS
WITH base AS (
    SELECT
        c.*,
        s.sex_label,
        e.education_label,
        m.marriage_label,
        CASE
            WHEN c.age <= 29 THEN '21-29'
            WHEN c.age <= 39 THEN '30-39'
            WHEN c.age <= 49 THEN '40-49'
            WHEN c.age <= 59 THEN '50-59'
            ELSE '60-79'
        END AS age_group,
        CASE
            WHEN c.limit_bal <= 50000  THEN '1: up to 50,000'
            WHEN c.limit_bal <= 100000 THEN '2: 50,001-100,000'
            WHEN c.limit_bal <= 180000 THEN '3: 100,001-180,000'
            WHEN c.limit_bal <= 270000 THEN '4: 180,001-270,000'
            ELSE                            '5: above 270,000'
        END AS limit_band,
        CASE
            WHEN c.pay_1 <= 0 THEN 'On time / no use'
            WHEN c.pay_1 = 1  THEN '1 month late'
            WHEN c.pay_1 = 2  THEN '2 months late'
            ELSE                   '3+ months late'
        END AS pay_1_group,
        (c.pay_1 >= 1)::int + (c.pay_2 >= 1)::int + (c.pay_3 >= 1)::int +
        (c.pay_4 >= 1)::int + (c.pay_5 >= 1)::int + (c.pay_6 >= 1)::int
            AS months_late,
        (c.pay_amt1 = 0)::int + (c.pay_amt2 = 0)::int + (c.pay_amt3 = 0)::int +
        (c.pay_amt4 = 0)::int + (c.pay_amt5 = 0)::int + (c.pay_amt6 = 0)::int
            AS zero_pay_months,
        CASE
            WHEN (c.bill_amt2 + c.bill_amt3 + c.bill_amt4 + c.bill_amt5 + c.bill_amt6) > 0
            THEN (c.pay_amt1 + c.pay_amt2 + c.pay_amt3 + c.pay_amt4 + c.pay_amt5)::numeric
                 / (c.bill_amt2 + c.bill_amt3 + c.bill_amt4 + c.bill_amt5 + c.bill_amt6)
        END AS pay_ratio
    FROM customers c
    JOIN dim_sex       s ON c.sex       = s.sex_code
    JOIN dim_education e ON c.education = e.education_code
    JOIN dim_marriage  m ON c.marriage  = m.marriage_code
)
SELECT
    base.*,
    CASE
        WHEN pay_1 >= 2 THEN '1: High'
        WHEN pay_1 = 1 OR months_late >= 2 THEN '2: Medium'
        ELSE '3: Low'
    END AS risk_tier,
    CASE WHEN default_next_month = 1 THEN 'Default' ELSE 'No default' END
        AS default_label
FROM base;

-- ---------------------------------------------------------------------
-- View 2: default rate for every customer segment (feeds Power BI charts)
-- ---------------------------------------------------------------------
CREATE VIEW vw_default_by_segment AS
SELECT 'Age group' AS dimension, age_group AS segment,
       COUNT(*) AS customers,
       SUM(default_next_month) AS defaults,
       ROUND(100.0 * AVG(default_next_month), 1) AS default_rate_pct
FROM vw_customer_profile
GROUP BY age_group

UNION ALL
SELECT 'Gender', sex_label, COUNT(*), SUM(default_next_month),
       ROUND(100.0 * AVG(default_next_month), 1)
FROM vw_customer_profile
GROUP BY sex_label

UNION ALL
SELECT 'Education', education_label, COUNT(*), SUM(default_next_month),
       ROUND(100.0 * AVG(default_next_month), 1)
FROM vw_customer_profile
GROUP BY education_label

UNION ALL
SELECT 'Marital status', marriage_label, COUNT(*), SUM(default_next_month),
       ROUND(100.0 * AVG(default_next_month), 1)
FROM vw_customer_profile
GROUP BY marriage_label

UNION ALL
SELECT 'Credit limit band', limit_band, COUNT(*), SUM(default_next_month),
       ROUND(100.0 * AVG(default_next_month), 1)
FROM vw_customer_profile
GROUP BY limit_band

UNION ALL
SELECT 'Latest repayment status', pay_1_group, COUNT(*), SUM(default_next_month),
       ROUND(100.0 * AVG(default_next_month), 1)
FROM vw_customer_profile
GROUP BY pay_1_group

UNION ALL
SELECT 'Risk tier', risk_tier, COUNT(*), SUM(default_next_month),
       ROUND(100.0 * AVG(default_next_month), 1)
FROM vw_customer_profile
GROUP BY risk_tier;
