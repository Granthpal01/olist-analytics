# Olist E-Commerce Analytics

End-to-end analytics project on the 
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) 
— 100K+ orders, 9 tables, 2016–2018.

## Business Questions Answered

1. **What does Olist's revenue trajectory look like, and which categories drive it?**
2. **How bad is the customer retention problem, and which cohorts are most at risk?**
3. **What is driving negative reviews — and can we quantify it?**
4. **Which customer segments exist, and where should marketing focus?**
5. **Which product categories have unsustainable freight economics?**

## Key Findings

- **Near-zero retention:** Average M1 retention rate of ~0.5% vs industry benchmark of 20–30%. 
  Almost every customer buys once and never returns.
- **Late delivery is the #1 satisfaction driver:** Orders arriving late score 2.57/5 vs 4.29/5 
  for on-time — a 40% drop. 1-star orders had a 37.77% late rate vs 3.01% for 5-star orders.
- **Geographic logistics gap:** Northeastern states (Alagoas 24%, Maranhão 20% late rate) 
  significantly underperform the national 8.11% average due to infrastructure gaps.
- **Broken freight economics:** Office furniture (3.52 avg review, 25% freight burden) and 
  food & drink (30% freight-to-price ratio) represent categories with poor unit economics.
- **RFM segmentation:** Champions (6.48% of customers) generate disproportionate revenue 
  at BRL 398 avg spend. Potential Loyalists (12.67%) represent the highest-ROI 
  re-engagement target.

## Tech Stack

- **Python** (pandas, matplotlib, sqlite3)
- **SQL** (SQLite — 8 analytical queries)
- **Tableau Public** (dashboard — link below)
- **GitHub** for version control

## Project Structure
olist-analytics/
├── data/
│   └── raw/          # CSVs from Kaggle (not tracked in git)
├── notebooks/
│   └── 01_sql_analysis.ipynb
├── scripts/
│   ├── load_to_sqlite.py
│   └── smoke_test.py
├── sql/
│   └── analysis/     # 8 analytical SQL queries
├── screenshots/      # Chart exports
└── requirements.txt

## Setup

1. Download dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Unzip CSVs into `data/raw/`
3. Build the database:
```bash
   python scripts/load_to_sqlite.py
```
4. Verify:
```bash
   python scripts/smoke_test.py
```
5. Open `notebooks/01_sql_analysis.ipynb` and run all cells

## Dashboard

*Tableau Public link — coming soon*