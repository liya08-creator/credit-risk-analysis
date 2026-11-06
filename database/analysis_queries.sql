-- =====================================================================
-- analysis_queries.sql | Phase 5 | Verification and business-question queries
-- Run after schema.sql, the data import and views.sql.
-- Run each statement on its own in the pgAdmin Query Tool.
-- Expected results are noted in comments and come from the Phase 3-4 notebooks.
-- =====================================================================

-- ===================== A. VERIFICATION AFTER LOADING =================

-- A1. Lookup tables have the right number of rows. Expected: dim_sex 2, dim_education 4, dim_marriage 4
SELECT 'dim_sex' AS table_name, COUNT(*) AS rows FROM dim_sex
UNION ALL
SELECT 'dim_education', COUNT(*) FROM dim_education
UNION ALL
SELECT 'dim_marriage', COUNT(*) FROM dim_marriage;

-- A2. customers table has 25 columns. Expected: 25
SELECT COUNT(*) AS number_of_columns
FROM information_schema.columns
WHERE table_name = 'customers';

-- A3. Row count. Expected: 30000
SELECT COUNT(*) AS total_rows FROM customers;

-- A4. Load verified against the notebooks. Expected: 30000 | 30000 | 6636 | 22.12 | 167484.32 | 35.49 | -2 | 8 | -339603 | 1684259 | 1930
SELECT
    COUNT(*)                                   AS total_rows,
    COUNT(DISTINCT customer_id)                AS distinct_ids,
    SUM(default_next_month)                    AS defaults,
    ROUND(100.0 * AVG(default_next_month), 2)  AS default_rate_pct,
    ROUND(AVG(limit_bal), 2)                   AS avg_limit,
    ROUND(AVG(age), 2)                         AS avg_age,
    MIN(pay_1)                                 AS min_pay_1,
    MAX(pay_1)                                 AS max_pay_1,
    MIN(bill_amt6)                             AS min_bill_amt6,
    MAX(pay_amt2)                              AS max_pay_amt2,
    COUNT(*) FILTER (
        WHERE LEAST(bill_amt1, bill_amt2, bill_amt3,
                    bill_amt4, bill_amt5, bill_amt6) < 0
    )                                          AS customers_with_negative_bill
FROM customers;

-- A5. Lookup joins work and labels match the cleaning counts.
--     Expected: education University 14030, Graduate school 10585, High school 4917, Others 468;
--     marriage Single 15964, Married 13659, Others 323, Unknown 54; sex Female 18112, Male 11888
SELECT 'sex' AS variable, s.sex_label AS category, COUNT(*) AS customers
FROM customers c JOIN dim_sex s ON c.sex = s.sex_code
GROUP BY s.sex_label

UNION ALL

SELECT 'education', e.education_label, COUNT(*)
FROM customers c JOIN dim_education e ON c.education = e.education_code
GROUP BY e.education_label

UNION ALL

SELECT 'marriage', m.marriage_label, COUNT(*)
FROM customers c JOIN dim_marriage m ON c.marriage = m.marriage_code
GROUP BY m.marriage_label

ORDER BY variable, customers DESC;

-- ===================== B. BUSINESS QUESTIONS =========================

-- Query 1: default rate by education. Expected: High school 25.2, University 23.7, Graduate school 19.2, Others 7.1
SELECT
    e.education_label                              AS education,
    COUNT(*)                                       AS customers,
    SUM(c.default_next_month)                      AS defaults,
    ROUND(100.0 * AVG(c.default_next_month), 1)    AS default_rate_pct
FROM customers c
JOIN dim_education e ON c.education = e.education_code
GROUP BY e.education_label
ORDER BY default_rate_pct DESC;

-- Query 2: which age groups have higher default rates?
--     Expected: 21-29 22.8 | 30-39 20.3 | 40-49 23.0 | 50-59 24.9 | 60-79 28.3
SELECT
    CASE
        WHEN age BETWEEN 21 AND 29 THEN '21-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60-79'
    END                                            AS age_group,
    COUNT(*)                                       AS customers,
    ROUND(100.0 * AVG(default_next_month), 1)      AS default_rate_pct
FROM customers
GROUP BY age_group
ORDER BY age_group;

-- Query 3: default rate by latest repayment status (pay_1).
--     Expected: -2 13.2 | -1 16.8 | 0 12.8 | 1 33.9 | 2 69.1 | 3 75.8 (codes 4-8 are too small to interpret)
SELECT
    pay_1                                          AS repayment_status,
    COUNT(*)                                       AS customers,
    SUM(default_next_month)                        AS defaults,
    ROUND(100.0 * AVG(default_next_month), 1)      AS default_rate_pct
FROM customers
GROUP BY pay_1
ORDER BY pay_1;

-- Query 3b: same, with grouped statuses.
--     Expected: On time / no use 13.8 | 1 month late 33.9 | 2 months late 69.1 | 3+ months late 71.9
SELECT
    CASE
        WHEN pay_1 <= 0 THEN 'On time / no use'
        WHEN pay_1 = 1  THEN '1 month late'
        WHEN pay_1 = 2  THEN '2 months late'
        ELSE '3+ months late'
    END                                            AS repayment_group,
    COUNT(*)                                       AS customers,
    ROUND(100.0 * AVG(default_next_month), 1)      AS default_rate_pct
FROM customers
GROUP BY repayment_group
ORDER BY MIN(pay_1);

-- Query 4: default rate by credit limit band. Expected: 31.8 | 25.8 | 19.9 | 16.9 | 13.8
SELECT
    CASE
        WHEN limit_bal <= 50000  THEN '1: up to 50,000'
        WHEN limit_bal <= 100000 THEN '2: 50,001-100,000'
        WHEN limit_bal <= 180000 THEN '3: 100,001-180,000'
        WHEN limit_bal <= 270000 THEN '4: 180,001-270,000'
        ELSE                          '5: above 270,000'
    END                                            AS limit_band,
    COUNT(*)                                       AS customers,
    SUM(default_next_month)                        AS defaults,
    ROUND(100.0 * AVG(default_next_month), 1)      AS default_rate_pct
FROM customers
GROUP BY limit_band
ORDER BY limit_band;

-- Query 4b: average and median credit limit, defaulters vs non-defaulters.
--     Expected: non-defaulters avg 178100 / median 150000; defaulters avg 130110 / median 90000
SELECT
    default_next_month                                              AS defaulted,
    COUNT(*)                                                        AS customers,
    ROUND(AVG(limit_bal), 0)                                        AS avg_limit,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY limit_bal))::numeric, 0)
                                                                    AS median_limit
FROM customers
GROUP BY default_next_month
ORDER BY default_next_month;

-- Query 5: payment behaviour, defaulters vs non-defaulters.
--     Expected: avg Sep payment 6307 vs 3397; median 2460 vs 1636; zero-pay months 1.08 vs 1.76; months late 0.50 vs 2.00
SELECT
    default_next_month                                                  AS defaulted,
    COUNT(*)                                                            AS customers,
    ROUND(AVG(pay_amt1), 0)                                             AS avg_sep_payment,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pay_amt1))::numeric, 0)
                                                                        AS median_sep_payment,
    ROUND(AVG(bill_amt1), 0)                                            AS avg_sep_bill,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bill_amt1))::numeric, 0)
                                                                        AS median_sep_bill,
    ROUND(AVG(
        (pay_amt1 = 0)::int + (pay_amt2 = 0)::int + (pay_amt3 = 0)::int +
        (pay_amt4 = 0)::int + (pay_amt5 = 0)::int + (pay_amt6 = 0)::int
    ), 2)                                                               AS avg_zero_pay_months,
    ROUND(AVG(
        (pay_1 >= 1)::int + (pay_2 >= 1)::int + (pay_3 >= 1)::int +
        (pay_4 >= 1)::int + (pay_5 >= 1)::int + (pay_6 >= 1)::int
    ), 2)                                                               AS avg_months_late
FROM customers
GROUP BY default_next_month
ORDER BY default_next_month;

-- Query 5b: default rate by share of bills paid.
--     Expected: paid nothing 72.7 | 0-5% 27.4 | 5-20% 24.2 | 20-100% 16.4 | over 100% 11.3 (28488 customers)
WITH ratios AS (
    SELECT
        default_next_month,
        (pay_amt1 + pay_amt2 + pay_amt3 + pay_amt4 + pay_amt5)::numeric
        / (bill_amt2 + bill_amt3 + bill_amt4 + bill_amt5 + bill_amt6)  AS pay_ratio
    FROM customers
    WHERE (bill_amt2 + bill_amt3 + bill_amt4 + bill_amt5 + bill_amt6) > 0
)
SELECT
    CASE
        WHEN pay_ratio = 0    THEN '1: paid nothing'
        WHEN pay_ratio <= 0.05 THEN '2: 0-5%'
        WHEN pay_ratio <= 0.2  THEN '3: 5-20%'
        WHEN pay_ratio <= 1    THEN '4: 20-100%'
        ELSE                        '5: over 100%'
    END                                            AS ratio_band,
    COUNT(*)                                       AS customers,
    ROUND(100.0 * AVG(default_next_month), 1)      AS default_rate_pct
FROM ratios
GROUP BY ratio_band
ORDER BY ratio_band;

-- Query 6: late vs low payment in the latest month (low = 2,100 or less, the median).
--     Expected: late/higher 56.5 | late/low 47.8 | not late/higher 11.2 | not late/low 17.2
SELECT
    CASE WHEN pay_1 >= 1 THEN 'late' ELSE 'not late' END           AS september_status,
    CASE WHEN pay_amt1 <= 2100 THEN 'low payment'
         ELSE 'higher payment' END                                 AS september_payment,
    COUNT(*)                                                       AS customers,
    SUM(default_next_month)                                        AS defaults,
    ROUND(100.0 * AVG(default_next_month), 1)                      AS default_rate_pct
FROM customers
GROUP BY september_status, september_payment
ORDER BY september_status, september_payment;

-- Query 6b: rule-based risk tiers.
--     Expected: High 69.6 | Medium 34.0 | Low 12.7 (Low tier still holds 42.2% of all defaulters)
WITH tiers AS (
    SELECT
        default_next_month,
        CASE
            WHEN pay_1 >= 2 THEN '1: High'
            WHEN pay_1 = 1
              OR (pay_1 >= 1)::int + (pay_2 >= 1)::int + (pay_3 >= 1)::int +
                 (pay_4 >= 1)::int + (pay_5 >= 1)::int + (pay_6 >= 1)::int >= 2
                THEN '2: Medium'
            ELSE '3: Low'
        END AS risk_tier
    FROM customers
)
SELECT
    risk_tier,
    COUNT(*)                                                       AS customers,
    SUM(default_next_month)                                        AS defaults,
    ROUND(100.0 * AVG(default_next_month), 1)                      AS default_rate_pct,
    ROUND(100.0 * SUM(default_next_month)
          / SUM(SUM(default_next_month)) OVER (), 1)               AS share_of_all_defaults
FROM tiers
GROUP BY risk_tier
ORDER BY risk_tier;

-- ===================== C. CHECKS FOR THE VIEWS ========================

-- C1. vw_customer_profile row count. Expected: 30000 | 28488
SELECT COUNT(*) AS rows_in_view, COUNT(pay_ratio) AS customers_with_ratio
FROM vw_customer_profile;

-- C2. Spot check customer 1.
--     Expected: Female, University, Married, 21-29, 1: up to 50,000, 2 months late, 2, 5, 0.1817, 1: High, Default
SELECT customer_id, sex_label, education_label, marriage_label, age_group,
       limit_band, pay_1_group, months_late, zero_pay_months,
       ROUND(pay_ratio, 4) AS pay_ratio, risk_tier, default_label
FROM vw_customer_profile
WHERE customer_id = 1;

-- C3. Every dimension in vw_default_by_segment adds up to 30000 customers.
--     Expected segments: Age group 5, Credit limit band 5, Education 4, Gender 2, Latest repayment status 4, Marital status 4, Risk tier 3
SELECT dimension,
       COUNT(*)       AS segments,
       SUM(customers) AS total_customers
FROM vw_default_by_segment
GROUP BY dimension
ORDER BY dimension;

-- C4. Spot check gender and risk tier.
--     Expected: Female 18112/3763/20.8, Male 11888/2873/24.2; High 3130/2177/69.6, Medium 4882/1659/34.0, Low 21988/2800/12.7
SELECT dimension, segment, customers, defaults, default_rate_pct
FROM vw_default_by_segment
WHERE dimension IN ('Gender', 'Risk tier')
ORDER BY dimension, segment;

-- C5. Final inventory. Expected: 4 base tables (customers, dim_education, dim_marriage, dim_sex) and 2 views
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_type, table_name;
