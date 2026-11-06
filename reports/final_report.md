# Credit Risk Analysis and Credit Card Default Prediction Using Machine Learning

**Final Project Report**

**Team:** Djou kenne Belviane Manuelle, Liya Eshetu, Sandra Keya

**Tools:** Python, Google Colab, PostgreSQL, Power BI, GitHub

---

## 1. Introduction

Credit plays an important role in financial institutions and the economy. Banks provide credit facilities to customers, who repay them over an agreed period. Not all customers repay as expected: some delay payments and others fail to repay at all. This creates a financial risk for lenders, known as credit risk.

This project analyses credit card customer data to understand repayment behaviour, identify the factors associated with default, and build a machine learning model that predicts whether a customer will default on their next payment. It follows an end-to-end data workflow: business understanding, data understanding, cleaning, exploratory and statistical analysis, database management, machine learning, dashboard development and documentation.

## 2. Problem Statement and Objectives

**Problem.** Financial institutions need to identify customers who may fail to meet their credit card repayment obligations. Customer records contain valuable information about demographics, credit limits, billing and repayment history, but this information must be analysed to find useful patterns and support informed decisions.

**Aim.** To analyse credit card customer data to identify patterns and factors associated with payment default, and to develop a machine learning model for predicting the likelihood of default.

**Objectives.**

1. Understand the credit risk problem and the structure of the dataset.
2. Inspect, clean and prepare the dataset for analysis.
3. Perform exploratory data analysis to discover patterns and relationships.
4. Apply statistical techniques to understand customer characteristics and repayment behaviour.
5. Identify variables associated with credit card default.
6. Store and manage the prepared dataset in PostgreSQL.
7. Develop machine learning models to predict default.
8. Evaluate and compare model performance.
9. Build an interactive Power BI dashboard to communicate findings.
10. Document the process and publish the work on GitHub.

## 3. Data

**Source.** Default of Credit Card Clients Dataset (Kaggle / UCI Machine Learning Repository): https://www.kaggle.com/datasets/uciml/default-of-credit-card-clients-dataset

**Contents.** 30,000 credit card customers in Taiwan, with information from April to September 2005, in 25 columns:

- Customer demographics: age, gender, education level, marital status.
- Credit information: credit limit (`LIMIT_BAL`).
- Repayment history: repayment status for six months (`PAY_1` to `PAY_6`).
- Billing information: monthly bill amounts for six months (`BILL_AMT1` to `BILL_AMT6`).
- Payment information: monthly payment amounts for six months (`PAY_AMT1` to `PAY_AMT6`).
- Target: `default_next_month` (1 = default, 0 = no default). There are 6,636 defaulters, a default rate of 22.1%.

The full column descriptions are in `docs/data_dictionary.md`.

**Limitation.** The data represents Taiwanese customers in 2005. Conclusions apply to this dataset and should not be presented as a representation of current credit behaviour elsewhere.

## 4. Data Cleaning and Preparation

Every cleaning decision was investigated first and documented in `docs/cleaning_log.md`. Nothing was removed automatically.

| Issue | Finding | Decision |
|---|---|---|
| Missing values | None in any column | No action |
| Duplicates | IDs are unique; 35 pairs (70 rows) match on every column except ID, mostly inactive accounts with all-zero bills and payments | Kept: different IDs, cannot be proven to be the same customer, about 0.1% of the data |
| Undocumented `EDUCATION` codes | Codes 0, 5 and 6 (345 rows) not in the documentation; default rates similar to or lower than the documented "others" group | Merged into code 4 ("Others") |
| Undocumented `MARRIAGE` code | Code 0 (54 rows), default rate 9.3% against 26.0% for the documented "others" group | Kept as its own category ("Unknown") |
| Repayment status values -2 and 0 | Not in the documentation but very common, and with low default rates like -1 | Kept: valid categories, commonly read as "no consumption" and "revolving credit" |
| Negative bill amounts | 3,932 values across 1,930 customers (6.4%); mostly small credit balances from overpayment or refunds | Kept: plausible and informative (default rate 16.5% against 22.5%) |
| Outliers | IQR rule flagged 8-10% of bill and payment values because the data is right-skewed; extreme cases checked were internally consistent | Kept; skewness handled at modelling stage |
| Data types | 13 amount columns stored as floats held only whole numbers | Converted to integers |
| Column names | `PAY_0` breaks the 1-6 numbering; the target name contains dots | Renamed to `PAY_1` and `default_next_month` |
| Categorical codes | Numeric codes are hard to read | Added label columns for analysis and the dashboard; codes kept |
| Customer ID | Carries no information about default (correlation with the target -0.014) | Removed from the modelling dataset, kept for the database |

The cleaned data was validated with automated checks (shapes, no missing values, valid codes, no negative payments, target count unchanged at 6,636) and saved in two versions: a full cleaned dataset (30,000 rows, 28 columns) and a modelling dataset (30,000 rows, 24 columns).

## 5. Exploratory Data Analysis and Statistics

### 5.1 Who the customers are

Customers are fairly young (mean age 35.5, median 34) and the age distribution is right-skewed. 60.4% are women and 39.6% men. The customer base is highly educated (46.8% university, 35.3% graduate school, 16.4% high school) and 53.2% are single against 45.5% married.

### 5.2 Answers to the five project questions

**1. Which age groups have higher default rates?**
Ages 30-39 have the lowest rate (20.3%). Rates rise with age: 40-49 = 23.0%, 50-59 = 24.9% and 60-79 = 28.3%, though the 60-79 group has only 339 customers. Ages 21-29 are at 22.8%. The relationship is statistically significant but weak (Cramér's V = 0.039) and non-linear.

**2. Is default associated with repayment history?**
Yes, strongly. It is the strongest relationship in the dataset (Cramér's V = 0.423 for the latest repayment status). Default is 13.8% for customers on time or not using the card, 33.9% for one month late, 69.1% for two months late and 71.9% for three or more months late. Customers never late in six months default at 11.7%; those late in all six months default at 70.3%. The most recent month is the strongest signal.

**3. Do customers with different credit limits show different default patterns?**
Yes. Default falls steadily from 31.8% for limits up to NT$50,000 to 13.8% for limits above NT$270,000. Defaulters have a median limit of 90,000 against 150,000. This is an association, not a cause: banks likely gave lower limits to customers they considered riskier.

**4. How do payment behaviours differ between defaulting and non-defaulting customers?**
Defaulters pay less and skip payments more often. Their median monthly payment is about 1.5-1.8 times lower (for example, September 1,636 against 2,460). They paid a median 6.2% of the bills they were paying against 13.3%, and averaged 1.76 months with no payment against 1.08. Customers who paid nothing had a 72.7% default rate. Bill amounts barely differ between the groups, so how much a customer pays matters more than how much they owe.

**5. Which variables are most strongly associated with default?**
Repayment status and history are strongest (`months_late` correlation 0.398, `PAY_1` 0.325), followed by credit limit (-0.154) and payment behaviour. Demographics are statistically significant but weak (Cramér's V below 0.08), and bill amounts are negligible.

### 5.3 Statistical tests

- **Chi-square tests of independence** showed that gender, education, marital status, age group and repayment status are all significantly associated with default (p < 0.001), but with very different strengths: Cramér's V is 0.034-0.073 (weak) for the demographic variables and 0.42 (strong) for repayment status. The repayment test was rerun with grouped statuses because some original groups were too small for a valid test; the result was unchanged.
- **Mann-Whitney U tests** (used instead of the t-test because the amount variables are strongly skewed) showed that defaulters have more late months (effect size 0.452, medium) and more zero-payment months, and lower credit limits, payments and payment ratios (small effects of about 0.21-0.25). Bill amount (0.035) and age (0.007) are negligible.
- With 30,000 customers even tiny differences are statistically significant, so effect sizes were used to judge importance.

### 5.4 Relationships among features

The six bill columns are almost the same variable (average correlation 0.89), repayment status columns are strongly related (0.66), and payment amounts are only weakly related to each other (0.19). The overlap among bill columns makes Logistic Regression coefficients unstable, which shaped the modelling approach.

## 6. Database Management with PostgreSQL

The cleaned data was stored in a PostgreSQL database (`credit_risk_db`):

- A main table `customers` (30,000 rows, 25 columns) with a primary key on the customer ID and a check that the target is 0 or 1.
- Three lookup tables (`dim_sex`, `dim_education`, `dim_marriage`) holding the meaning of each category code, linked to `customers` by foreign keys so the database rejects invalid codes.
- Data types chosen for size and meaning (`SMALLINT` for codes and repayment status, `INTEGER` for amounts).

The data was loaded with pgAdmin's Import/Export tool and verified against the notebook figures: 30,000 rows, 30,000 distinct IDs, 6,636 defaults (22.12%), the same average limit and age, the same extreme values, and the same category counts after joining to the lookup tables.

SQL queries answered the business questions directly from the database (default rate by education, age group, repayment status and credit limit band, payment behaviour, and share of bills paid), reproducing the notebook results exactly. Views were created for reporting and for Power BI. The scripts are in `database/`.

A simple rule-based risk tiering from repayment status gave default rates of 69.6% (High), 34.0% (Medium) and 12.7% (Low), but the Low tier still held 42.2% of all defaulters. A simple rule therefore misses many defaulters, which motivated the machine learning models.

## 7. Machine Learning

### 7.1 Method

- **Features:** the 23 cleaned columns plus five engineered features (`months_late`, `zero_pay_months`, `avg_bill`, `avg_payment`, `utilisation`), each calculated from a customer's own row. `pay_ratio` was left out because it has no valid value for 1,512 customers.
- **Split:** 80/20, stratified on the target, `random_state=42`. The training set has 24,000 customers (5,309 defaults) and the test set 6,000 (1,327 defaults), both at a 22.12% default rate.
- **No data leakage:** scaling and encoding were fitted on training data only, inside a pipeline. The test set was used once, for the final evaluation. The customer ID was not used as a feature.
- **Class imbalance:** handled with balanced class weights (0.642 for no default and 2.260 for default), so no synthetic data was created.
- **Models and tuning:** Logistic Regression, Decision Tree and Random Forest, compared with 5-fold stratified cross-validation on the training set. Tree depths were chosen by validation ROC-AUC.

### 7.2 Results

A baseline that predicts "no default" for everyone scores 77.9% accuracy with recall 0 and ROC-AUC 0.5, so accuracy is misleading here. Models were judged on recall, precision, F1-score and ROC-AUC. An unrestricted decision tree overfits (ROC-AUC 1.0 on training folds against about 0.61 on validation folds).

The **Random Forest was the best model on every metric**: cross-validated ROC-AUC 0.7851, against 0.7688 for the Decision Tree and 0.7596 for Logistic Regression. The differences between models are modest.

**Final test result for the Random Forest:**

| Metric | Value |
|---|---|
| ROC-AUC | 0.7762 |
| Recall (default class) | 0.6225 |
| Precision (default class) | 0.4750 |
| F1-score | 0.5388 |
| Accuracy | 0.7643 |

On the test set the model caught 826 of the 1,327 real defaulters, missed 501, and wrongly flagged 913 of 4,673 non-defaulters. The test score is close to the cross-validated score, so the model generalises to customers it has not seen.

### 7.3 What drives the predictions

Repayment history dominates. `months_late` and `PAY_1` each have an importance of about 0.206, followed by `PAY_2` (0.091), `PAY_3` (0.051), `utilisation` and `PAY_4` (0.037 each), `avg_payment` (0.034), `PAY_5` (0.032), `LIMIT_BAL` (0.027) and `zero_pay_months` (0.026). Demographic variables do not appear in the top ten, which agrees with their weak effects in the EDA. `months_late` is built from the `PAY` columns, so their importance is shared and is best read as one group, repayment history.

## 8. Power BI Dashboard

An interactive dashboard connects to the PostgreSQL database and model result tables. It has three pages:

1. **Credit Risk Overview:** total customers, defaulting customers, overall default rate, default against non-default split, and a demographic overview.
2. **Customer Risk Analysis:** default rate by age group, education, marital status, repayment status and credit limit, plus other risk patterns found in the analysis.
3. **Machine Learning Performance:** model comparison, accuracy, precision, recall, F1-score, ROC-AUC, confusion matrix and important predictive variables.

The dashboard file and its documentation are in `powerbi/`.

## 9. Conclusions

1. **Repayment history is the key to predicting default.** Recent repayment status and the number of late months separate low-risk from high-risk customers far better than any other information in the data.
2. **Credit limit and payment behaviour add useful signal.** Lower limits, smaller payments and skipped payments go with higher default, while bill amounts and demographics add little.
3. **A machine learning model beats a simple rule.** The Random Forest identifies about 62% of defaulters (recall 0.6225) with a ROC-AUC of 0.776, a useful improvement over a rule that misses 42.2% of defaulters in its low-risk tier.
4. **The work is a complete, documented pipeline** from raw data to cleaned data, statistical findings, a database, models and a dashboard.

## 10. Limitations and Further Work

- **Precision of 0.475:** about half of the customers the model flags would not default. Balanced class weights raise recall at the cost of precision, and the cut-off can be tuned depending on the cost of a missed defaulter against a false alarm.
- **ROC-AUC of 0.776** is useful but not strong. Most of the available signal is in repayment history, and a more complex model was not tried.
- **Association, not cause.** Findings such as the link between credit limit and default describe patterns, and feature importance describes what the model used, not what causes default.
- **Scope of the data.** It covers 30,000 credit card customers in Taiwan between April and September 2005, so the findings may not transfer to other markets or periods.
- **Data quirks.** The meanings of repayment status values -2 and 0 and the education and marriage codes outside the documentation are interpretations, not official definitions, and a one-month delay is almost never recorded after the latest month.
- **Further work:** tune the decision threshold, try gradient boosting, test on data from other periods or markets, and apply the cost of missed defaults to choose the final cut-off.

## 11. Repository and Reproducibility

All code, documentation and results are in the project GitHub repository (see `README.md` for the structure). Notebooks 01 to 05 reproduce the analysis in order, `database/` holds the schema and queries, and `powerbi/` holds the dashboard. Database credentials are not stored in the repository, and the dataset itself is downloaded from Kaggle (see `data/README.md`).
