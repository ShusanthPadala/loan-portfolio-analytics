"""Retail Loan Portfolio Analytics: run SQL queries, validate data, make charts.
Usage: python analysis.py
Needs: pandas, matplotlib (sqlite3 is built in to Python).
"""
import re, sqlite3
from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path(__file__).parent
(BASE / "results").mkdir(exist_ok=True)
(BASE / "charts").mkdir(exist_ok=True)

# 1. Load + validate
df = pd.read_csv(BASE / "data" / "german_credit.csv")
print("Rows, columns:", df.shape)
print("Missing values:", int(df.isna().sum().sum()), "| Duplicate rows:", int(df.duplicated().sum()))
assert df["credit_risk"].isin([0, 1]).all(), "unexpected credit_risk values"
assert (df["amount"] > 0).all() and df["age"].between(18, 100).all()

# In this dataset credit_risk 1 = good loan, 0 = bad loan. Define default = bad loan.
df["is_default"] = (df["credit_risk"] == 0).astype(int)

# 2. Load into SQLite and run every query in sql/queries.sql
con = sqlite3.connect(":memory:")
df.to_sql("loans", con, index=False)
text = (BASE / "sql" / "queries.sql").read_text()
parts = re.split(r"-- name: (\w+)\n", text)
res = {}
for name, sql in zip(parts[1::2], parts[2::2]):
    out = pd.read_sql_query(sql, con)
    out.to_csv(BASE / "results" / f"{name}.csv", index=False)
    res[name] = out
    print(f"\n== {name} ==\n{out.to_string(index=False)}")

# 3. Charts
overall = res["q01_portfolio_overview"]["default_rate_pct"].iloc[0]

def bar(name, xcol, title, fname, rot=30):
    d = res[name]
    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.bar(d[xcol].astype(str), d["default_rate_pct"], color="#1F3A5F")
    ax.axhline(overall, color="#C0392B", ls="--", lw=1.2, label=f"Portfolio avg {overall}%")
    for i, v in enumerate(d["default_rate_pct"]):
        ax.text(i, v + 0.6, f"{v}%", ha="center", fontsize=8)
    ax.set_title(title); ax.set_ylabel("Default rate (%)")
    ax.legend(); plt.xticks(rotation=rot, ha="right"); plt.tight_layout()
    fig.savefig(BASE / "charts" / fname, dpi=150); plt.close(fig)

bar("q02_default_by_purpose", "purpose", "Default rate by loan purpose", "default_by_purpose.png")
bar("q03_default_by_checking_status", "checking_account_status", "Default rate by checking account status", "default_by_checking.png")
bar("q06_default_by_duration_band", "duration_band", "Default rate by loan duration", "default_by_duration.png", rot=0)
bar("q05_default_by_amount_band", "amount_band", "Default rate by loan amount (DM)", "default_by_amount.png", rot=0)
print("\nDone. Results in results/, charts in charts/.")
