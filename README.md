# Retail Loan Portfolio Analytics (SQL + Python)

## Objective
Analyse a consumer loan portfolio the way a retail-finance analyst would: measure default risk across customer and loan segments, find the riskiest segments, and recommend actions.

## Dataset
German Credit dataset: 1,000 loans, 20 customer and loan attributes, and a good/bad outcome flag (`credit_risk`: 1 = good, 0 = bad). A "bad" loan is treated as a **default**. Loan amounts are in Deutsche Marks (DM). No missing values or duplicate rows were found during validation.

## Method
1. **Validate and load (Python/Pandas):** check missing values, duplicates and value ranges, then define `is_default`.
2. **Metrics in SQL (12 queries in `sql/queries.sql`):** GROUP BY, CASE WHEN banding, HAVING, a RANK() window function and CTEs. The main metrics are default rate, average loan amount and duration, share of total defaults, and lift versus the portfolio average.
3. **Visualize (Matplotlib):** default-rate charts by segment in `charts/`.

## Key findings
- **Portfolio default rate is 30.0%** (300 of 1,000 loans).
- **Longer loans are riskier:** default rate rises from 21.2% for loans of 12 months or less to 39.9% for 25-36 months and 51.7% for 37+ months.
- **Checking account balance is the strongest signal:** 49.3% default for balances under 100 DM, against 11.7% for customers with no checking account.
- **Highest-risk segment:** customers with a checking balance under 100 DM and loans of 25+ months default at **65.6%** (64 loans), more than double the portfolio rate. The lowest-risk segment (no checking account, 12 months or less) defaults at 7.5%.
- **By purpose:** retraining (44.0%) and new-car loans (38.0%) are riskiest; used-car loans are lowest (16.5%). New-car loans are 23.4% of loans but 29.7% of defaults.
- **Larger loans:** loans of 6,000 DM or more default at 45.6%, against 24.8% for 1,500-2,999 DM.
- **Customer profile:** applicants under 25 default at 40.9% (22.6% for ages 35-49), and renters at 39.1% (26.1% for owners).

## Recommendations
1. **Add stricter review for long-term loans (25+ months) to customers with low checking balances.** Consider shorter terms, lower amounts or additional security for this segment.
2. **Use risk-based limits and pricing for new-car, retraining and very large (6,000+ DM) loans,** which carry above-average default rates.
3. **Fast-track low-risk segments** (short loans, customers with established checking accounts) to grow volume where losses are lowest.

## Limitations
- This is a 1,000-loan historical sample, so small segments (for example fewer than 50 loans) are noisy. Segments under 20 loans were excluded from purpose results.
- Findings show association, not cause. For example, "no checking account" shows the lowest default rate, which probably reflects a different customer type in this data and should not be read as a rule.
- The dataset has no interest rate, loan grade or income field, so those metrics are not covered.

## How to run
```
pip install -r requirements.txt
python analysis.py
```
Query results are saved to `results/` and charts to `charts/`. The SQL in `sql/queries.sql` runs on SQLite as written. For MySQL or PostgreSQL, import `data/german_credit.csv` into a table named `loans`, add an `is_default` column (`credit_risk = 0`), and run the queries (change `ROUND(100.0 * AVG(...))` syntax only if your engine complains).
