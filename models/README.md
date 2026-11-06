# Models

## Selected model: Random Forest

| Setting | Value |
|---|---|
| Algorithm | `RandomForestClassifier` (scikit-learn) |
| `n_estimators` | 200 |
| `max_depth` | 10 |
| `min_samples_leaf` | 50 |
| `class_weight` | `balanced` (handles the 22% default share; no resampling) |
| `random_state` | 42 |
| Trained on | the 24,000-customer training set (`train_set.csv`) |
| Input | the 28 features below, raw (no scaling or encoding needed) |

**Input features, in order:** `LIMIT_BAL`, `SEX`, `EDUCATION`, `MARRIAGE`, `AGE`, `PAY_1` to `PAY_6`, `BILL_AMT1` to `BILL_AMT6`, `PAY_AMT1` to `PAY_AMT6`, and five engineered features: `months_late`, `zero_pay_months`, `avg_bill`, `avg_payment`, `utilisation`.

## Performance

Cross-validated (5-fold, training set only), used to choose the model:

| Model | ROC-AUC | Recall | Precision | F1 | Accuracy |
|---|---|---|---|---|---|
| Random Forest | 0.7851 | 0.6287 | 0.4723 | 0.5394 | 0.7623 |
| Decision Tree (depth 5) | 0.7688 | 0.6092 | 0.4649 | 0.5268 | 0.7577 |
| Logistic Regression | 0.7596 | 0.5997 | 0.4677 | 0.5255 | 0.7605 |

Final test set (6,000 customers, used once): ROC-AUC 0.7762, recall 0.6225, precision 0.4750, F1 0.5388, accuracy 0.7643. Confusion matrix: 3,760 true negatives, 913 false positives, 501 false negatives, 826 true positives.

## The model file

The trained model is saved as `random_forest_final.joblib` by `notebooks/05_machine_learning.ipynb`. The file is not committed to GitHub. To recreate it, run notebook 05 from the top with `train_set.csv` and `test_set.csv`, which notebook 04 produces. Every random step uses `random_state=42`, so the results are reproducible.

To load a saved model:

```python
import joblib
model = joblib.load("random_forest_final.joblib")
probabilities = model.predict_proba(X_new)[:, 1]   # X_new needs the 28 columns above
```

## Where the results are stored

The model comparison, test results, feature importance and test-set predictions are in the PostgreSQL tables `model_comparison`, `model_test_results`, `feature_importance` and `model_predictions` (see `database/`).
