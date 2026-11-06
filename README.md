
# Credit Risk Analysis and Credit Card Default Prediction

An end-to-end data science project that analyses credit card customer data to understand why customers default and builds machine learning models to predict default on the next payment. It combines Python, PostgreSQL and Power BI, and was completed as a group project for the data science mentorship programme.

**Team:** [Djou kenne Belviane Manuelle, Liya Eshetu , Sandra Keya]

## Dataset

Default of Credit Card Clients Dataset (Kaggle / UCI): 30,000 credit card customers in Taiwan, April to September 2005, with a 22.1% default rate. Source: https://www.kaggle.com/datasets/uciml/default-of-credit-card-clients-dataset

Conclusions apply to this dataset only and should not be read as a representation of current credit behaviour elsewhere.

## Tools

Python (pandas, numpy, matplotlib, seaborn, scipy, scikit-learn) in Google Colab, PostgreSQL 18 (pgAdmin), Power BI, GitHub.

## Repository structure

| Folder | Contents |
|---|---|
| `docs/` | Business understanding, objectives, data dictionary, cleaning log, findings |
| `data/` | Where to get the dataset (the file itself is not stored here) |
| `notebooks/` | 01 data understanding, 02 data cleaning, 03 EDA and statistics, 04 feature engineering, 05 machine learning |
| `database/` | PostgreSQL schema and analysis queries |
| `models/` | Model documentation |
| `powerbi/` | Dashboard file and documentation |
| `reports/` | Final report |

## Key findings

- **Repayment history is the strongest signal.** Default rate by repayment status: on time / no use 13.8%, 1 month late 33.9%, 2 months late 69.1%, 3+ months late 71.9% (Cramér's V = 0.42). Customers never late in six months default at 11.7%; those late in all six at 70.3%.
- **Credit limit matters.** Default falls from 31.8% (limit up to NT$50,000) to 13.8% (above NT$270,000). This is an association, not a cause.
- **Payments matter more than bills.** Defaulters pay a median 6.2% of the bills they are paying, against 13.3% for non-defaulters, while their bills are similar in size.
- **Demographics are weak signals.** Age, gender, education and marital status are statistically significant but weak (Cramér's V below 0.08).
- **A simple rule is not enough.** Risk tiers built from repayment status separate customers well (High 69.6%, Medium 34.0%, Low 12.7% default), but the Low tier still holds 42.2% of all defaulters. This motivated the machine learning models.

## Machine learning results

Three models were compared with 5-fold stratified cross-validation: Logistic Regression, Decision Tree and Random Forest. The Random Forest was best on every metric (cross-validated ROC-AUC 0.7851, against 0.7688 for the Decision Tree and 0.7596 for Logistic Regression).

| Final test result (Random Forest) | |
|---|---|
| ROC-AUC | 0.7762 |
| Recall (default class) | 0.6225 |
| Precision (default class) | 0.4750 |
| F1-score | 0.5388 |
| Accuracy | 0.7643 |

On the 6,000-customer test set, the model caught 826 of the 1,327 real defaulters. A baseline that predicts "no default" for everyone scores 77.9% accuracy with zero recall, so accuracy alone is misleading and models were judged on recall, precision, F1 and ROC-AUC.

**Method:** 80/20 stratified split, preprocessing fitted on training data only (no leakage), class imbalance handled with balanced class weights, and five engineered features added to the 23 cleaned columns.

**What drives the predictions:** repayment history. `months_late` and `PAY_1` each have importance of about 0.206, and repayment variables together hold most of the importance. Demographic variables do not appear in the top ten.

**Limitations:** precision is 0.475, so about half of the customers flagged would not default; the cut-off can be tuned depending on the cost of a missed defaulter against a false alarm. The data is from Taiwan in 2005, and feature importance describes what the model used, not what causes default.

## Reproducing the work

1. Download the dataset (see `data/README.md`).
2. Run the notebooks in order, 01 to 05.
3. Create the database tables with `database/schema.sql` and load the cleaned data (see `database/README.md`).
4. Open the dashboard in `powerbi/`.

Database credentials are not stored in this repository.
