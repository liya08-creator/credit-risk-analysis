## EDA Finding 1: Customer demographics

- Customers are fairly young: mean age 35.5, median 34, with half between 28 and 41. The age distribution is right-skewed (skewness 0.73), peaking around 28-30 with few customers over 60.
- 60.4% of customers are women and 39.6% men.
- The customer base is highly educated: 46.8% university and 35.3% graduate school, 16.4% high school, 1.6% others.
- 53.2% are single and 45.5% married. "Others" (1.1%) and "Unknown" (0.2%) are very small groups, so any default rates calculated for them are unreliable.
- Because groups differ so much in size, later comparisons use default rates (percentages), not raw counts.
  ## EDA Finding 2: Credit limits

- LIMIT_BAL is right-skewed (skewness 0.99): median NT$140,000, mean NT$167,484. Half of customers have limits between 50,000 and 240,000.
- Default rate decreases steadily as the credit limit increases: 31.8% in the lowest band (up to 50,000) down to 13.8% in the highest band (above 270,000).
- Defaulters have lower limits on average (mean 130,110, median 90,000) than non-defaulters (mean 178,100, median 150,000).
- Note: this is an association, not a cause. Banks likely assigned lower limits to customers they considered riskier.
  ## EDA Finding 3: Repayment history

- Repayment status is strongly associated with default. Customers with status -2, -1 or 0 (no consumption, paid on time, or paying minimum) default at only 13-20% in every month.
- Default rises sharply with delay: 1 month late = 33.9% (PAY_1), 2 months late = 51-69%, 3 months late = 57-76%.
- The most recent month (PAY_1, September) is the strongest signal: 2 months late = 69% and 3 months late = 76%, compared with 51-64% when the same delay appears in older months.
- Status values 4-8 have fewer than 100 customers in every month, so their rates are too unreliable to interpret. The value 1 is only common in PAY_1 (recording inconsistency noted in cleaning log entry 4).
- ## EDA Finding 4: Number of months late

- 66.4% of customers (19,931) were never late in any of the six months; their default rate is only 11.7%.
- Default rate rises with each additional late month: 1 month = 29.8%, 2 = 38.8%, 3 = 50.9%, 4 = 57.3%, 5 = 57.4%, 6 = 70.3%.
- Customers late in all six months default about six times as often as customers never late.
- The 5-month group is small (298 customers), so the near-identical rates for 4 and 5 months are likely noise. The overall upward trend is clear.
- The count only includes delays of 1+ months and may slightly undercount lateness in older months because of the PAY_1 recording quirk (cleaning log entry 4).
- This count is a candidate engineered feature for the modelling phase.
- ## EDA Finding 5: Bills and payments

- Bill amounts are similar for defaulters and non-defaulters. Mean September bill: 51,994 (no default) vs 48,509 (default); medians are close in every month and sometimes higher for defaulters (April: 18,028 vs 16,679).
- Payment amounts differ clearly. Non-defaulters' median payment is about 1.5-1.8 times higher than defaulters' in every month (e.g. September: 2,460 vs 1,636; June: 1,734 vs 1,000). Mean payments show the same gap (about 1.6-2.0 times).
- Conclusion: how much a customer owes does not separate the two groups much; how much they pay does. A payment-to-bill ratio is a candidate engineered feature for modelling.
- Medians were used alongside means because bill and payment amounts are strongly right-skewed. In the charts, defaulters' median payment is exactly 1,000 in April, May and June (a very common round amount). By September non-defaulters' median bill (23,120) is higher than defaulters' (20,185), but the gap is small compared with the payment gap. Chart axes do not start at zero, so visual gaps look larger than they are.
- ## EDA Finding 6: Payment relative to bills

- Defined pay_ratio = payments (September-May) / the bills they were paying (August-April). Calculated for 28,488 of 30,000 customers; 1,512 (5%) were excluded because their bills total zero or less.
- Median share of bills paid: 13.3% (no default) vs 6.2% (default).
- Defaulters averaged 1.76 months with zero payment (out of 6) vs 1.08 for non-defaulters.
- Default rate falls as the share paid rises: paid nothing 72.7% (only 227 customers), 0-5% 27.4%, 5-20% 24.2%, 20-100% 16.4%, over 100% 11.3%.
- Payment behaviour separates defaulters from non-defaulters much more than bill size does (Finding 5). pay_ratio and zero_pay_months are candidate features for modelling.
- ## EDA Finding 7: Default rate by customer group

- Age: default rate is lowest for ages 30-39 (20.3%) and rises with age: 40-49 = 23.0%, 50-59 = 24.9%, 60-79 = 28.3%. Ages 21-29 are at 22.8%. The 60-79 group is small (339 customers, 1.1%), so its rate is imprecise.
- Gender: men 24.2% vs women 20.8% (gap of 3.4 points).
- Education: graduate school 19.2%, university 23.7%, high school 25.2%. "Others" (7.1%, 468 customers) is small.
- Marital status: married 23.5%, single 20.9%, others 26.0%. "Unknown" (9.3%, 54 customers) is too small to interpret.
- All demographic gaps (up to about 8 points for age) are much smaller than the gaps for repayment history (11.7% to 70.3%) and credit limit (13.8% to 31.8%). Whether the demographic differences are statistically significant is tested in Activity 8.
- ## EDA Finding 8: Correlation with default

- Strongest correlations with default_next_month: months_late 0.398 (engineered), PAY_1 0.325, PAY_2 0.264, PAY_3 0.235, PAY_4 0.217, PAY_5 0.204, PAY_6 0.187, zero_pay_months 0.163.
- LIMIT_BAL is negative (-0.154): higher limits go with lower default. It is the strongest non-repayment variable.
- Payment amounts have weak negative correlations (-0.053 to -0.073). Bill amounts (-0.020 to -0.005) and demographics (|r| < 0.04) are close to zero.
- Repayment status is most strongly related to default, and the most recent month (PAY_1) is the strongest of the six.
- Caution: Pearson correlation only captures linear relationships. AGE (r = 0.014) and pay_ratio (r = -0.020) have clear non-linear patterns shown in Findings 6 and 7 that correlation understates. Correlations for category codes (SEX, EDUCATION, MARRIAGE) are only loosely meaningful.
- ## EDA Finding 9: Relationships among the features (multicollinearity)

- BILL_AMT1-6 are highly correlated with each other (average r = 0.89; September vs August r = 0.95; September vs April r = 0.80). A customer's bill barely changes from month to month.
- PAY_1-6 are strongly correlated (average r = 0.66): a customer late in one month tends to be late in neighbouring months.
- PAY_AMT1-6 are only weakly related to each other (average r = 0.19), so each month's payment carries fairly independent information.
- LIMIT_BAL is negatively correlated with the repayment status columns (higher limit goes with better status). AGE is weakly related to all other features.
- Modelling implication: the strong overlap among bill columns will make Logistic Regression coefficients unstable. We plan summary features (e.g. average bill) and regularisation in Phase 6. Tree-based models are less affected, but their feature importance will be split across the correlated columns.
- ## EDA Finding 10: Descriptive statistics

- Amount variables are strongly right-skewed. PAY_AMT1: mean 5,664 vs median 2,100, skewness 14.67. BILL_AMT1: mean 51,223 vs median 22,382, skewness 2.66. LIMIT_BAL (skewness 0.99) and AGE (0.73) are mildly skewed. Medians describe the typical customer better than means for these variables.
- months_late and zero_pay_months have median 0: most customers were never late and never skipped a payment.
- Most unevenly distributed (coefficient of variation): PAY_AMT1 2.92, months_late 1.86, BILL_AMT1 1.44, zero_pay_months 1.40, LIMIT_BAL 0.77, AGE 0.26.
- Defaulters vs non-defaulters (mean): months_late 2.0 vs 0.5, LIMIT_BAL 130,110 vs 178,100, PAY_AMT1 3,397 vs 6,307, zero_pay_months 1.8 vs 1.1. AGE (35.7 vs 35.4) and BILL_AMT1 (48,509 vs 51,994) differ little.
- Modelling implication: skewed amount columns call for scaling and possibly log transformation for Logistic Regression; tree models are unaffected.
- ## EDA Finding 11: Chi-square tests of independence (categorical variables vs default)

- All five tested variables are significantly associated with default (all p < 0.001), but the strength differs enormously (Cramér's V):
  - SEX: V = 0.040 (weak)
  - MARRIAGE: V = 0.034 (weak)
  - age_group: V = 0.039 (weak)
  - EDUCATION: V = 0.073 (weak)
  - PAY_1 (repayment status): V = 0.423 (strong)
- With 30,000 customers even tiny differences are statistically significant, so effect size (Cramér's V) is more informative than the p-value. Demographics are real but weak signals; repayment status is a strong one.
- The original PAY_1 test had a minimum expected count of 2.0 (below the guideline of 5) because of very small status groups. Rerunning with grouped statuses (on time/no use, 1 month late, 2 months late, 3+ months late) gave a valid test (minimum expected count 102.4) and the same result: V = 0.421, p < 0.001.
- Default rate by grouped PAY_1: on time/no use 13.8%, 1 month late 33.9%, 2 months late 69.1%, 3+ months late 71.9%.
## EDA Finding 12: Mann-Whitney U tests (numeric variables, defaulters vs non-defaulters)

- Mann-Whitney U was used instead of the t-test because most variables are strongly skewed (Finding 10). Effect size = rank-biserial correlation (below 0.1 negligible, 0.1-0.3 small, 0.3-0.5 medium, above 0.5 large; rough convention).
- months_late: r = +0.452 (medium); median 1 for defaulters vs 0 for non-defaulters, p < 0.001. The strongest numeric variable.
- Small effects (p < 0.001): zero_pay_months r = +0.254; LIMIT_BAL r = -0.236 (median 90,000 vs 150,000); PAY_AMT1 r = -0.223 (1,636 vs 2,460); pay_ratio r = -0.217 (median 0.062 vs 0.133); PAY_AMT2 r = -0.209.
- Negligible: BILL_AMT1 r = -0.035 (significant, p = 1.15e-5, but negligible) and AGE r = +0.007 (not significant, p = 0.373; identical medians of 34).
- All signs are consistent with earlier findings: defaulters have more late months and more zero-payment months, and lower limits, payments and payment ratios.
- AGE: the test finds no overall difference, yet default rates differ by age group (Finding 7, chi-square p < 0.001). The pattern is non-linear (lowest in the 30s, higher on both sides), which a rank test comparing the two groups as a whole cannot detect. Age has a weak, non-linear relationship with default.
- pay_ratio is much more informative here (r = -0.217) than its Pearson correlation (-0.020, Finding 8), because extreme
  ## Summary

1. Which age groups have higher default rates?
Ages 30-39 have the lowest rate (20.3%). Rates rise with age: 40-49 = 23.0%, 50-59 = 24.9%, 60-79 = 28.3% (only 339 customers, so imprecise). Ages 21-29 are at 22.8%. The relationship is statistically significant but weak (Cramér's V = 0.039) and non-linear (Findings 7, 11, 12).

2. Is default associated with repayment history?
Yes, strongly. This is the strongest relationship in the dataset. PAY_1 has Cramér's V = 0.423. Default is 13.8% for customers on time / not using the card, 33.9% for 1 month late and 69.1% for 2 months late. Customers never late in six months default at 11.7%, and those late in all six months at 70.3%. The most recent month matters most (Findings 3, 4, 8, 11).

3. Do customers with different credit limits show different default patterns?
Yes. Default falls from 31.8% (limit up to NT$50,000) to 13.8% (limit above NT$270,000). Correlation -0.154, effect size -0.236 (small). This is an association, not a cause: banks likely gave lower limits to riskier customers (Findings 2, 8, 12).

4. How do payment behaviours differ between defaulting and non-defaulting customers?
Defaulters pay less and skip payments more often. Median payment is about 1.5-1.8 times lower every month (e.g. September 1,636 vs 2,460). They paid a median 6.2% of the bills they were paying vs 13.3%, and averaged 1.76 months with no payment vs 1.08. Customers who paid nothing had a 72.7% default rate. Bill amounts barely differ between the groups (Findings 5, 6, 12).

5. Which variables appear most strongly associated with default?
Repayment status and history (months_late, PAY_1 to PAY_6, zero_pay_months) are strongest, followed by credit limit and payment behaviour (PAY_AMT columns, pay_ratio). Demographics (gender, education, marital status, age) are statistically significant but weak (V below 0.08). Bill amounts are negligible. Bill columns are highly correlated with each other (average r = 0.89), which matters for modelling (Findings 8, 9, 11, 12).
