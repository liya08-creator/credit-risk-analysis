# Findings: Phase 5 (SQL analysis) and Phase 6 (machine learning)

## Phase 5: findings from the PostgreSQL queries

The SQL results reproduce the Phase 3-4 notebook figures exactly (30,000 customers, 6,636 defaults, 22.12% default rate), which confirms the database was loaded correctly.

1. **Repayment status is the strongest signal.** Default rate by status in the latest month: on time / no use 13.8%, 1 month late 33.9%, 2 months late 69.1%, 3+ months late 71.9%.
2. **Credit limit matters.** Default rate falls from 31.8% for limits up to 50,000 to 13.8% above 270,000. Defaulters have a median limit of 90,000 against 150,000 for non-defaulters.
3. **Defaulters pay less and skip payments.** Average September payment 3,397 against 6,307, and 1.76 zero-payment months against 1.08, while their September bills are similar (48,509 against 51,994).
4. **Share of bills paid.** Customers who paid nothing of their previous bills default at 72.7%, falling to 11.3% for those who paid more than 100%.
5. **Late and low payment are not additive.** Among customers already late, those with a low September payment default less (47.8%) than those with a higher one (56.5%). A single payment amount is a weak signal next to repayment status.
6. **A simple rule works only partly.** Risk tiers built from repayment status give default rates of 69.6% (High), 34.0% (Medium) and 12.7% (Low), but the Low tier still holds 42.2% of all defaulters. This motivates the machine learning models.

## Phase 6: machine learning

### Method
- **Features:** the 23 cleaned columns plus five engineered features (`months_late`, `zero_pay_months`, `avg_bill`, `avg_payment`, `utilisation`), each calculated from a customer's own row. `pay_ratio` was left out because it has no valid value for 1,512 customers.
- **Split:** 80/20, stratified on the target, `random_state=42`. Training set 24,000 customers (5,309 defaults), test set 6,000 customers (1,327 defaults), both at a 22.12% default rate.
- **No leakage:** scaling and encoding were fitted on the training data only, inside a pipeline. The test set was used once, for the final evaluation.
- **Class imbalance:** handled with `class_weight="balanced"` (weights 0.642 for no default and 2.260 for default, a ratio of 3.52), so no synthetic data was created.
- **Comparison:** 5-fold stratified cross-validation on the training set. Decision Tree depth (3, 4, 5, 6, 8, none) and Random Forest depth (6, 8, 10) were chosen by validation ROC-AUC.

### Results
- A baseline that predicts "no default" for everyone scores 77.9% accuracy with recall 0 and ROC-AUC 0.5, so accuracy is a misleading measure here. Models were judged on recall, precision, F1 and ROC-AUC.
- An unrestricted decision tree overfits: ROC-AUC 1.0 on training folds against about 0.61 on validation folds.
- **Random Forest is the best model on every metric** (cross-validated ROC-AUC 0.7851, against 0.7688 for the Decision Tree and 0.7596 for Logistic Regression). The differences between models are modest.
- **Final test result for the Random Forest:** ROC-AUC 0.7762, recall 0.6225, precision 0.4750, F1 0.5388, accuracy 0.7643. It caught 826 of the 1,327 real defaulters, missed 501, and wrongly flagged 913 of 4,673 non-defaulters.
- The test score is close to the cross-validated score, so the model generalises to customers it has not seen.

### What drives the predictions
- Repayment history dominates. `months_late` and `PAY_1` each have importance of about 0.206, followed by `PAY_2` (0.091), `PAY_3` (0.051), `utilisation` and `PAY_4` (0.037 each), `avg_payment` (0.034), `PAY_5` (0.032), `LIMIT_BAL` (0.027) and `zero_pay_months` (0.026).
- `months_late`, `PAY_1` to `PAY_4` together hold about 59% of the total importance. `months_late` is built from the `PAY` columns, so their importance is shared and should be read as one group, repayment history.
- Demographic variables (age, sex, education, marriage) do not appear in the top ten, which agrees with their weak effects in the EDA.

### Limitations
- **Precision of 0.475:** about half of the customers the model flags would not default. Balanced class weights raise recall at the cost of precision. A different cut-off could trade these differently, depending on the cost of a missed defaulter against a false alarm.
- **ROC-AUC of 0.776** is useful but not strong. Most of the available signal is in repayment history, and a more complex model was not tried.
- The data covers 30,000 credit card customers in Taiwan over April to September 2005, so the findings may not transfer to other markets or periods.
- Feature importance from a Random Forest describes what the model used, not what causes default.
