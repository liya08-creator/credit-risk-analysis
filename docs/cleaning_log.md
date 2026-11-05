## Cleaning Log

**1. Missing values**
Checked all 25 columns. Total missing values: 0. No action needed.

**2. Duplicates**
- ID is unique (no repeated customer IDs).
- No rows are fully identical (ID included).
- 35 pairs (70 rows) are identical on every column except ID.
- Investigation: most are inactive accounts (all-zero bills and payments, PAY status -2) with matching demographics, which is plausible by coincidence.
- Decision: KEEP. They have different IDs, cannot be proven to be the same customer, and are only about 0.1% of the data.
  **3. Invalid / undocumented category codes**

EDUCATION
- Documented codes are 1-4. Found undocumented codes: 0 (14 rows), 5 (280 rows), 6 (51 rows). Total 345 rows (1.15%).
- Their default rates (0%, 6.4%, 15.7%) were similar to or lower than the documented "others" group (code 4: 5.7%, 123 rows).
- Decision: MERGE codes 0, 5 and 6 into 4 ("others"). Code 4 now has 468 rows.

MARRIAGE
- Documented codes are 1-3. Found undocumented code 0 (54 rows, 0.18%).
- Its default rate (9.3%) differs strongly from the documented "others" group (code 3: 26.0%), so merging would distort that group.
- Decision: KEEP code 0 as its own category ("unknown"). Rows are not removed because they cannot be proven wrong.
  **4. Repayment status columns (PAY_0 to PAY_6)**

- Documented values: -1 (paid on time) and 1-9 (months of delay). Found additional undocumented values: -2 and 0, which are very common (0 is the most common value in every month; -2 appears for 2,700-4,900 customers per month).
- Observed range is -2 to 8; no impossible values.
- Default rates for PAY_0: -2: 13.2%, -1: 16.8%, 0: 12.8% (low and similar), 1: 33.9%, 2: 69.1%, 3: 75.8%. The codes -2, -1 and 0 therefore behave like one group of customers paying without problems.
- -2 and 0 are commonly interpreted in the dataset's community as "no consumption" and "revolving credit / minimum payment made". This is an interpretation, not part of the official documentation.
- Notes: PAY_0 values 5-8 have very few customers (9-26) so their rates are unreliable. The value 1 is frequent in PAY_0 (3,688) but almost absent in PAY_2 to PAY_6 (0-28), a recording inconsistency that cannot be corrected from the data.
- Decision: KEEP all values unchanged. They are valid categories, and removing or merging them would lose information.
**5. Numeric columns: sanity checks and negative bills**

- AGE ranges from 21 to 79 and LIMIT_BAL from 10,000 to 1,000,000. All values are plausible; no action needed.
- PAY_AMT1-6 contain no negative values.
- BILL_AMT1-6 contain negative values: 3,932 values across 1,930 customers (6.4%).
- Most negative bills are small (median -158; 75% are between -18 and 0). Negative bills are plausible: they represent credit balances from overpayment or refunds.
- A few are extreme (minimum -339,603; one customer's credit balance is 1.5x their credit limit). These cannot be proven wrong and will be reviewed with the other outliers in Activity 4.
- Customers with at least one negative bill have a lower default rate (16.5%) than the rest (22.5%), so these rows carry useful information.
- Decision: KEEP all negative bill values unchanged.
  **6. Outliers**

- IQR rule flagged: LIMIT_BAL 0.6%, AGE 0.9%, BILL_AMT1-6 about 8-9% each, PAY_AMT1-6 about 9-10% each. The high percentages in the money columns reflect right-skewed data (most customers have small amounts, a minority have very large ones), not errors.
- 8,274 bill values exceed the customer's credit limit, across 3,931 customers (13.1%). These customers have a higher default rate (30.1% vs 22.1% overall). This is plausible (interest, fees, over-limit spending) and informative.
- The largest bill (BILL_AMT3 = 1,664,089) and the largest payment (PAY_AMT2 = 1,684,259) belong to the same customer (ID 5297, limit 500,000). Their payments match the previous month's bills closely (including 121,757 billed and 121,831 paid the following month), so the extreme values are consistent, not errors.
- Decision: KEEP all outliers unchanged. They are real and informative. Skewness will be handled at the feature engineering / modelling stage (scaling, possible log transforms) instead of by deleting customers.
- **7. Data types**

- 13 columns (LIMIT_BAL, BILL_AMT1-6, PAY_AMT1-6) were loaded as float64. Checked each: none contain fractional values (0 non-whole values in every column).
- Decision: CONVERT all 13 to int64. Amounts are whole currency units, so no information is lost, and integer types match the planned PostgreSQL schema.
- SEX, EDUCATION, MARRIAGE and PAY_0 to PAY_6 are stored as integer codes representing categories. Kept as integers for now; encoding for modelling is handled in the next step (categorical variables).
- **8. Column renaming**

- PAY_0 renamed to PAY_1, so repayment status columns are numbered 1-6 like BILL_AMT1-6 and PAY_AMT1-6 (PAY_1 = September, the most recent month).
- default.payment.next.month renamed to default_next_month. The original name contains dots, which are awkward in Python and invalid in SQL column names. The bare name "default" was avoided because DEFAULT is a reserved SQL keyword.
- Data values were not changed, only the names.
- **9. Categorical variables**

- Added readable label columns next to the original codes: SEX_label (1=Male, 2=Female), EDUCATION_label (1=Graduate school, 2=University, 3=High school, 4=Others), MARRIAGE_label (0=Unknown, 1=Married, 2=Single, 3=Others).
- Verified: no unmapped values; counts and default rates match the earlier checks (e.g. Others education = 468 customers).
- Original numeric codes are kept. Labels are for analysis, SQL and Power BI readability.
- Encoding for machine learning (one-hot encoding of SEX, EDUCATION, MARRIAGE) is postponed to the modelling phase, after the train/test split, to avoid data leakage.
- **10. Removing irrelevant variables from the modelling features**

- ID is only a row identifier. Correlation with the target is -0.014, and default rates are flat across ID blocks (19.1% to 25.8%, no trend). It carries no information about credit behaviour.
- Created two datasets:
  - df_clean (30,000 x 28): full cleaned dataset, with ID and label columns. Used for EDA, PostgreSQL and Power BI.
  - df_model (30,000 x 24): ID and label columns removed. 23 features + target. Used for machine learning.
- ID is kept in df_clean because it is needed as the database primary key and to link predictions back to customers in Power BI.
**11. Validation**

Automated checks (assert statements) all passed:
- Shapes: df_clean 30,000 x 28; df_model 30,000 x 24 (no ID).
- No missing values; ID unique; all modelling columns are integers.
- Target contains only 0/1; default count unchanged at 6,636 (rate 22.12%).
- Category codes are as decided: SEX 1-2, EDUCATION 1-4, MARRIAGE 0-3. PAY_1 to PAY_6 range from -2 to 8.
- No negative payments, all credit limits positive, ages between 21 and 79.
