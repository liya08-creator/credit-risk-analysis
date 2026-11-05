# Data Dictionary

Source: Default of Credit Card Clients Dataset (Kaggle / UCI). 30,000 customers, 25 columns. Amounts are in New Taiwan dollars.

| Column | Type | Description |
|---|---|---|
| ID | Integer | Customer identifier (not used for modelling) |
| LIMIT_BAL | Decimal | Credit limit given to the customer |
| SEX | Category | 1 = male, 2 = female |
| EDUCATION | Category | 1 = graduate school, 2 = university, 3 = high school, 4 = others (0, 5, 6 also appear but are undocumented) |
| MARRIAGE | Category | 1 = married, 2 = single, 3 = others (0 also appears but is undocumented) |
| AGE | Integer | Age in years (21 to 79) |
| PAY_0, PAY_2 to PAY_6 | Category | Repayment status for September, August, July, June, May, April 2005. -1 = paid on time, 1 to 9 = months of payment delay. -2 and 0 also appear and are undocumented |
| BILL_AMT1 to BILL_AMT6 | Decimal | Bill statement amount for September back to April 2005 |
| PAY_AMT1 to PAY_AMT6 | Decimal | Amount paid in September back to April 2005 |
| default.payment.next.month | Binary (target) | 1 = defaulted next month, 0 = did not default |
