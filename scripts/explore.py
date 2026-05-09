"""
Quick eyeballing of the Olist data.
Run: python scripts/explore.py
"""
import sqlite3
import pandas as pd
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "olist.db"
conn = sqlite3.connect(DB_PATH)

tables = ["orders", "customers", "order_items", "order_payments",
          "order_reviews", "products", "sellers", "category_translation"]

for t in tables:
    print(f"\n{'='*70}")
    print(f"TABLE: {t}")
    print('='*70)
    df = pd.read_sql(f"SELECT * FROM {t} LIMIT 3", conn)
    print(df.to_string())
    print(f"\nColumns: {list(df.columns)}")

conn.close()