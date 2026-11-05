# Data Dictionary

This dictionary describes the cleaned version of the Default of Credit Card Clients dataset (Kaggle / UCI Machine Learning Repository). The data covers 30,000 credit card customers in Taiwan, with information from April to September 2005. After cleaning, the dataset has 28 columns: the 25 original columns (with two renamed), plus 3 readable label columns added during cleaning. Conclusions drawn from this data apply to this dataset only and should not be presented as a direct representation of current credit behaviour elsewhere.

Months are numbered 1 to 6 across all column groups: 1 = September 2005 (most recent), 2 = August, 3 = July, 4 = June, 5 = May, 6 = April 2005.

## Customer and credit information

| Column | Description | Type | Values / notes |
|---|---|---|---|
| ID | Unique customer identifier | Integer | 1 to 30000. Not used as a modelling feature. |
| LIMIT_BAL | Credit limit granted to the customer, in NT dollars | Integer | 10,000 to 1,000,000 |
| SEX | Gender | Integer code | 1 = Male, 2 = Female |
| EDUCATION | Education level | Integer code | 1 = Graduate school, 2 = University, 3 = High school, 4 = Others. Undocumented codes 0, 5 and 6 in the original data (345 rows) were merged into 4 during cleaning. |
| MARRIAGE | Marital status | Integer code | 1 = Married, 2 = Single, 3 = Others, 0 = Unknown. Code 0 (54 rows) is undocumented in the original source and was kept as its own category. |
| AGE | Age in years | Integer | 21 to 79 |

## Repayment status (September to April 2005)

| Column | Description | Type | Values / notes |
|---|---|---|---|
| PAY_1 | Repayment status in September 2005 (renamed from PAY_0) | Integer code | -2 to 8. See the coding below. |
| PAY_2 | Repayment status in August 2005 | Integer code | -2 to 8 |
| PAY_3 | Repayment status in July 2005 | Integer code | -2 to 8 |
| PAY_4 | Repayment status in June 2005 | Integer code | -2 to 8 |
| PAY_5 | Repayment status in May 2005 | Integer code | -2 to 8 |
| PAY_6 | Repayment status in April 2005 | Integer code | -2 to 8 |

Repayment status coding: -1 = paid on time, 1 = payment delayed by one month, 2 = delayed by two months, and so on up to 8. The values -2 and 0 are not defined in the official documentation. They are commonly interpreted as "no consumption" (-2) and "revolving credit / minimum payment made" (0). Both are very common and behave like customers paying without problems, so they were kept unchanged.

## Bill statement amounts (NT dollars)

| Column | Description | Type | Values / notes |
|---|---|---|---|
| BILL_AMT1 | Bill statement amount, September 2005 | Integer | Can be negative (credit balance) |
| BILL_AMT2 | Bill statement amount, August 2005 | Integer | Can be negative |
| BILL_AMT3 | Bill statement amount, July 2005 | Integer | Can be negative |
| BILL_AMT4 | Bill statement amount, June 2005 | Integer | Can be negative |
| BILL_AMT5 | Bill statement amount, May 2005 | Integer | Can be negative |
| BILL_AMT6 | Bill statement amount, April 2005 | Integer | Can be negative |

Negative bills (about 6.4% of customers have at least one) represent credit balances from overpayment or refunds and were kept. Some bills exceed the credit limit and were also kept, since they are plausible and carry information about default.

## Payment amounts (NT dollars)

| Column | Description | Type | Values / notes |
|---|---|---|---|
| PAY_AMT1 | Amount paid in September 2005 | Integer | 0 or more |
| PAY_AMT2 | Amount paid in August 2005 | Integer | 0 or more |
| PAY_AMT3 | Amount paid in July 2005 | Integer | 0 or more |
| PAY_AMT4 | Amount paid in June 2005 | Integer | 0 or more |
| PAY_AMT5 | Amount paid in May 2005 | Integer | 0 or more |
| PAY_AMT6 | Amount paid in April 2005 | Integer | 0 or more |

## Target variable

| Column | Description | Type | Values / notes |
|---|---|---|---|
| default_next_month | Whether the customer defaulted on the payment in the following month (renamed from default.payment.next.month) | Integer | 1 = Default (6,636 customers, 22.1%), 0 = No default (23,364 customers, 77.9%) |

## Label columns added during cleaning

These columns repeat the numeric codes as readable text, for analysis, SQL and Power BI. They are not used as modelling features.

| Column | Description | Type | Values |
|---|---|---|---|
| SEX_label | Text label for SEX | Text | Male, Female |
| EDUCATION_label | Text label for EDUCATION | Text | Graduate school, University, High school, Others |
| MARRIAGE_label | Text label for MARRIAGE | Text | Married, Single, Others, Unknown |

## Datasets produced by cleaning

- credit_card_clean.csv: 30,000 rows and 28 columns. The full cleaned dataset, including ID and the label columns. Used for EDA, PostgreSQL and Power BI.
- credit_card_model.csv: 30,000 rows and 24 columns. ID and the label columns removed (23 features plus the target). Used for machine learning.
