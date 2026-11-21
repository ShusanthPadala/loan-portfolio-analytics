-- Retail Loan Portfolio Analytics: SQL queries
-- Table: loans (1 row per loan). is_default = 1 when credit_risk = 0 (bad loan), else 0.
-- Amounts are in Deutsche Marks (DM) as in the source dataset.

-- name: q01_portfolio_overview
SELECT COUNT(*) AS total_loans,
       SUM(is_default) AS defaulted_loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct,
       ROUND(AVG(amount), 0) AS avg_loan_amount,
       ROUND(AVG(duration), 1) AS avg_duration_months,
       ROUND(AVG(age), 1) AS avg_age
FROM loans;

-- name: q02_default_by_purpose
SELECT purpose,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct,
       ROUND(AVG(amount), 0) AS avg_loan_amount
FROM loans
GROUP BY purpose
HAVING COUNT(*) >= 20
ORDER BY default_rate_pct DESC;

-- name: q03_default_by_checking_status
SELECT status AS checking_account_status,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY status
ORDER BY default_rate_pct DESC;

-- name: q04_default_by_savings
SELECT savings,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY savings
ORDER BY default_rate_pct DESC;

-- name: q05_default_by_amount_band
SELECT CASE WHEN amount < 1500 THEN '1. <1,500'
            WHEN amount < 3000 THEN '2. 1,500-2,999'
            WHEN amount < 6000 THEN '3. 3,000-5,999'
            ELSE '4. 6,000+' END AS amount_band,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY amount_band
ORDER BY amount_band;

-- name: q06_default_by_duration_band
SELECT CASE WHEN duration <= 12 THEN '1. <=12 months'
            WHEN duration <= 24 THEN '2. 13-24 months'
            WHEN duration <= 36 THEN '3. 25-36 months'
            ELSE '4. 37+ months' END AS duration_band,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY duration_band
ORDER BY duration_band;

-- name: q07_default_by_age_band
SELECT CASE WHEN age < 25 THEN '1. <25'
            WHEN age < 35 THEN '2. 25-34'
            WHEN age < 50 THEN '3. 35-49'
            ELSE '4. 50+' END AS age_band,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY age_band
ORDER BY age_band;

-- name: q08_default_by_housing
SELECT housing,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY housing
ORDER BY default_rate_pct DESC;

-- name: q09_default_by_employment
SELECT employment_duration,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct
FROM loans
GROUP BY employment_duration
ORDER BY default_rate_pct DESC;

-- name: q10_riskiest_segments_ranked
-- Segments = checking account status x duration band, at least 30 loans. RANK() orders by risk.
SELECT status AS checking_account_status,
       CASE WHEN duration <= 12 THEN '<=12 months'
            WHEN duration <= 24 THEN '13-24 months'
            ELSE '25+ months' END AS duration_band,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(is_default), 1) AS default_rate_pct,
       RANK() OVER (ORDER BY AVG(is_default) DESC) AS risk_rank
FROM loans
GROUP BY status, duration_band
HAVING COUNT(*) >= 30
ORDER BY risk_rank;

-- name: q11_purpose_share_of_defaults
-- CTE + window function: each purpose's share of all defaulted loans vs its share of all loans.
WITH p AS (
  SELECT purpose, COUNT(*) AS loans, SUM(is_default) AS defaults
  FROM loans GROUP BY purpose
), s AS (
  SELECT purpose, loans, defaults,
         ROUND(100.0 * loans / SUM(loans) OVER (), 1) AS pct_of_loans,
         ROUND(100.0 * defaults / SUM(defaults) OVER (), 1) AS pct_of_defaults
  FROM p
)
SELECT * FROM s WHERE loans >= 20 ORDER BY defaults DESC;

-- name: q12_segment_lift_vs_portfolio
-- CTE: lift = segment default rate / portfolio default rate (>1 means riskier than average).
WITH overall AS (SELECT AVG(is_default) AS r FROM loans)
SELECT l.status AS checking_account_status,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(l.is_default), 1) AS default_rate_pct,
       ROUND(AVG(l.is_default) / o.r, 2) AS lift_vs_portfolio
FROM loans l CROSS JOIN overall o
GROUP BY l.status, o.r
ORDER BY lift_vs_portfolio DESC;
