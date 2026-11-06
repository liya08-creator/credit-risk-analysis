# Phase 5: PostgreSQL database

**Database:** `credit_risk_db` (PostgreSQL 18, managed with pgAdmin 4)

## Files
- `schema.sql`: lookup tables (`dim_sex`, `dim_education`, `dim_marriage`), the main `customers` table, and four machine learning result tables (`model_comparison`, `model_test_results`, `feature_importance`, `model_predictions`)
- `views.sql`: `vw_customer_profile` (labels plus derived columns) and `vw_default_by_segment` (default rate by customer group, for Power BI)
- `analysis_queries.sql`: verification queries, the business-question queries, and checks for the views and the model result tables

## Design decisions
- One main `customers` table (one row per customer, 25 columns). Splitting bills and payments into other tables would only add joins.
- Three lookup tables store the meaning of the coded columns. `customers` keeps only the numeric codes, with foreign keys that reject invalid codes.
- Column names are lowercase with underscores, so queries need no quotes.
- Negative bills are allowed (credit balances). `default_next_month` is limited to 0 or 1.
- Derived values (age group, credit limit band, months late, payment ratio, risk tier) live in a view, not in the base table, so they always match the data.

## How the data was loaded
1. In Google Colab, `credit_card_clean.csv` was converted to `customers_for_db.csv`: column names lowercased, `ID` renamed to `customer_id`, and the three label columns dropped.
2. The file was imported into `customers` with pgAdmin's Import/Export tool (CSV, header = Yes).
3. The load was verified against the notebook figures: 30,000 rows, 6,636 defaults (22.12%), average limit 167,484.32, 1,930 customers with a negative bill.

## How to rebuild
1. Create the database `credit_risk_db`.
2. Run `schema.sql`, then import `customers_for_db.csv`, then run `views.sql`.
3. Run `analysis_queries.sql` one statement at a time and compare with the expected results in its comments and with `docs/findings.md`.

## Machine learning result tables (Phase 6)
The notebook `05_machine_learning.ipynb` exports four CSV files that are imported into PostgreSQL with pgAdmin, so Power BI can read the model results from the same database:
- `model_comparison`: cross-validated scores of the three models (3 rows)
- `model_test_results`: final test-set scores and confusion matrix of the selected Random Forest (1 row)
- `feature_importance`: importance of all 28 features (28 rows)
- `model_predictions`: actual label, predicted probability, predicted class and outcome for the 6,000 test customers, linked to `customers` by `customer_id`

## Key results from the SQL queries
- Default rate by latest repayment status: on time / no use 13.8%, 1 month late 33.9%, 2 months late 69.1%, 3+ months late 71.9%.
- Default rate by credit limit band: 31.8% (up to 50,000) falling to 13.8% (above 270,000).
- Defaulters skipped payments in 1.76 of 6 months on average, against 1.08 for non-defaulters, while their September bills were similar (48,509 vs 51,994).
- Rule-based risk tiers: High 69.6%, Medium 34.0%, Low 12.7%. The Low tier still holds 42.2% of all defaulters, which motivates the machine learning in Phase 6.

## Security
No passwords or connection details are stored in this repository. The data files are not committed.
